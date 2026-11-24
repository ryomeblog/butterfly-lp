import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import '../repositories/plan_repository.dart';
import '../repositories/stamp.dart';
import 'json_export.dart';

/// ファイルの種類（中身から自動で判別する。設計書 3.9）。
enum ImportKind {
  /// アプリの全データ：マージ（追加・上書き）
  full,

  /// ライフプラン単位：常に新しいプランとして追加（UUIDは振り直す）
  plan,

  /// 予定・実績・収支・資産・グループ・テンプレート：UUIDで追加・上書き
  rows,
}

/// 同じUUIDのグループ・テンプレートがアプリにあるときの扱い（設計書 3.9）。
enum SameIdPolicy {
  overwrite('上書きする'),
  addNew('別に追加する（新しいUUIDで、名前に「(2)」を付ける）'),
  skip('取り込まない');

  const SameIdPolicy(this.label);
  final String label;
}

class ImportIssue {
  const ImportIssue(this.section, this.row, this.reason);
  final String section;
  final int row;
  final String reason;

  @override
  String toString() => '$reason（$section $row行目）';
}

/// 取り込みの確認画面に出す内容、または取り込んだ結果。
class ImportReport {
  ImportKind kind = ImportKind.rows;
  int actualsNew = 0;
  int actualsOverwrite = 0;
  int linesNew = 0;
  int linesOverwrite = 0;
  int assetsNew = 0;
  int assetsOverwrite = 0;
  int valuesAdd = 0;
  int valuesOverwrite = 0;
  int groupsNew = 0;
  int groupsSame = 0;
  int templatesNew = 0;
  int templatesSame = 0;
  int plansNew = 0;
  int plansOverwrite = 0;
  String? periodFrom;
  String? periodTo;

  /// ファイル内のプラン（取り込み先の既定値に使う）
  String? filePlanId;
  final newRefs = <String>[];
  final invalid = <ImportIssue>[];

  /// 新しく作ったプラン（ライフプラン単位）
  String? createdPlanId;

  void _period(String ym) {
    if (periodFrom == null || ym.compareTo(periodFrom!) < 0) periodFrom = ym;
    if (periodTo == null || ym.compareTo(periodTo!) > 0) periodTo = ym;
  }
}

/// ファイルの種類。各画面の「取り込む」は、その画面に合う種類だけを受け付ける（設計書 3.9）。
enum FileUnit {
  full('アプリの全データ', '設定の「データ管理」'),
  plan('ライフプラン', 'ホームの「ライフプラン」'),
  assets('資産', '資産の画面'),
  groups('グループ', 'ホームの「グループ」'),
  templates('テンプレート', 'ホームの「テンプレート」'),
  rows('予定・実績', '家計簿のリスト');

  const FileUnit(this.label, this.where);

  final String label;

  /// 取り込める画面
  final String where;

  /// 中身から種類を決める。資産・グループのファイルには実績やテンプレートも入るので、この順に見る。
  static FileUnit of(Map<String, dynamic> json) {
    bool has(String key) => json[key] is List && (json[key] as List).isNotEmpty;
    return switch (JsonImporter.detect(json)) {
      ImportKind.full => FileUnit.full,
      ImportKind.plan => FileUnit.plan,
      ImportKind.rows when has('assets') => FileUnit.assets,
      ImportKind.rows when has('groups') => FileUnit.groups,
      ImportKind.rows when has('templates') => FileUnit.templates,
      ImportKind.rows => FileUnit.rows,
    };
  }
}

class _DryRun implements Exception {
  const _DryRun();
}

class ImportFormatError implements Exception {
  const ImportFormatError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// JSON の取り込み（設計書 3.9・6.9）。取り込みは1つのトランザクションで行い、途中で失敗したら何も変えない。
class JsonImporter {
  JsonImporter(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  static ImportKind detect(Map<String, dynamic> json) {
    if (json['format'] != JsonExporter.format) {
      throw const ImportFormatError(
        'このアプリのJSONファイルではありません（format が lifeplan-data ではない）',
      );
    }
    if (json['masters'] != null) return ImportKind.full;
    final plans = json['plans'];
    if (plans is List && plans.any((p) => p is Map && p['settings'] != null)) {
      return ImportKind.plan;
    }
    return ImportKind.rows;
  }

  /// 確認画面のための下見。実際に取り込んでから巻き戻す（件数が実際の取り込みと一致する）。
  Future<ImportReport> preview(
    Map<String, dynamic> json, {
    String? targetPlanId,
    SameIdPolicy policy = SameIdPolicy.overwrite,
  }) async {
    final report = ImportReport();
    try {
      await db.transaction(() async {
        await _run(json, report, targetPlanId: targetPlanId, policy: policy);
        throw const _DryRun();
      });
    } on _DryRun {
      // 巻き戻し済み
    }
    return report;
  }

  Future<ImportReport> apply(
    Map<String, dynamic> json, {
    String? targetPlanId,
    SameIdPolicy policy = SameIdPolicy.overwrite,
  }) async {
    final report = ImportReport();
    await db.transaction(
      () => _run(json, report, targetPlanId: targetPlanId, policy: policy),
    );
    return report;
  }

  Future<void> _run(
    Map<String, dynamic> json,
    ImportReport report, {
    required String? targetPlanId,
    required SameIdPolicy policy,
  }) async {
    final kind = detect(json);
    report.kind = kind;
    final ctx = _Ctx(db, stamp, report, kind, policy);
    final plans = (json['plans'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final actuals = (json['actuals'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    report.filePlanId =
        _str(plans.firstOrNull?['plan'], 'id') ??
        _str(actuals.firstOrNull?['plan'], 'id');

    // 取り込みの順番：masters → plans の本体 → assets → templates → groups → plans の登録・計画行 → actuals
    final masters = json['masters'];
    if (masters is Map) {
      for (final c
          in (masters['categories'] as List? ?? const []).whereType<Map>()) {
        await ctx.category(c.cast<String, dynamic>(), overwrite: true);
      }
      for (final a
          in (masters['accounts'] as List? ?? const []).whereType<Map>()) {
        await ctx.account(a.cast<String, dynamic>(), overwrite: true);
      }
    }

    // 取り込み先のプラン
    final planIds = <String, String>{};
    if (kind == ImportKind.plan || kind == ImportKind.full) {
      for (final p in plans) {
        final fileId = _str(p['plan'], 'id') ?? newId();
        planIds[fileId] = await ctx.planBody(p.cast<String, dynamic>(), fileId);
      }
    }
    String targetFor(Map? planRef) {
      final fileId = _str(planRef, 'id');
      if (fileId != null && planIds.containsKey(fileId)) {
        return planIds[fileId]!;
      }
      if (kind == ImportKind.plan) return planIds.values.first;
      final t = targetPlanId ?? fileId;
      if (t == null) throw const ImportFormatError('取り込み先のプランを選んでください');
      return t;
    }

    if (kind == ImportKind.rows) {
      final t = targetPlanId ?? report.filePlanId;
      if (t != null && !await ctx.planExists(t)) {
        if (targetPlanId != null) {
          throw const ImportFormatError('取り込み先のプランがありません');
        }
      }
    }

    for (final (i, a)
        in (json['assets'] as List? ?? const []).whereType<Map>().indexed) {
      await ctx.assetSection(
        a.cast<String, dynamic>(),
        targetFor(a['plan'] as Map?),
        i + 1,
      );
    }
    for (final t in (json['templates'] as List? ?? const []).whereType<Map>()) {
      await ctx.templateSection(t.cast<String, dynamic>(), null, json);
    }
    for (final g in (json['groups'] as List? ?? const []).whereType<Map>()) {
      await ctx.groupSection(g.cast<String, dynamic>(), json);
    }
    for (final p in plans) {
      final planId = targetFor(p['plan'] as Map?);
      if (kind != ImportKind.rows) {
        await ctx.registrations(p.cast<String, dynamic>(), planId);
      }
      for (final (i, l)
          in (p['lines'] as List? ?? const []).whereType<Map>().indexed) {
        await ctx.line(l.cast<String, dynamic>(), planId, i + 1);
      }
    }
    for (final (i, t) in actuals.indexed) {
      await ctx.actual(
        t.cast<String, dynamic>(),
        targetFor(t['plan'] as Map?),
        i + 1,
      );
    }
    // ライフプラン単位：計画線の起点は取り込んだ日の実績から計算し直す
    for (final id in planIds.values) {
      if (kind == ImportKind.plan) {
        final repo = PlanRepository(db, stamp);
        await repo.writeAccountBaselines(id, todayString());
        await repo.writeAssetBaselines(id, todayString());
      }
    }
  }
}

String? _str(Object? map, String key) {
  if (map is! Map) return null;
  final v = map[key];
  return v is String && v.isNotEmpty ? v : null;
}

int? _int(Object? v) {
  if (v is int) return v;
  if (v is double && v == v.roundToDouble()) return v.toInt();
  return null;
}

final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool _validDate(String? s) {
  if (s == null || !_dateRe.hasMatch(s)) return false;
  final d = DateTime.tryParse(s);
  return d != null && dateString(d) == s;
}

class _Ctx {
  _Ctx(this.db, this.stamp, this.report, this.kind, this.policy);

  final AppDatabase db;
  final Stamp stamp;
  final ImportReport report;
  final ImportKind kind;
  final SameIdPolicy policy;
  late final now = stamp.now();

  /// ライフプラン単位で振り直したID（ファイルのID→新しいID）
  final remap = <String, String>{};

  /// 別に追加したグループ・テンプレートのID
  final groupMap = <String, String>{};
  final templateMap = <String, String>{};
  final itemMap = <String, String>{};

  String _id(String? fileId) {
    if (kind != ImportKind.plan) return fileId ?? newId();
    if (fileId == null) return newId();
    return remap.putIfAbsent(fileId, newId);
  }

  void _newRef(String label) {
    if (!report.newRefs.contains(label)) report.newRefs.add(label);
  }

  Future<bool> planExists(String id) async =>
      await (db.select(db.plans)
            ..where((p) => p.id.equals(id) & p.deletedAt.isNull()))
          .getSingleOrNull() !=
      null;

  // ---- 参照オブジェクト ----

  /// カテゴリ。UUIDがあればそれで探し、なければ同じUUIDで作る。id がなければ同じ種類・同じ名前を使う。
  Future<String?> category(
    Map<String, dynamic>? ref, {
    bool overwrite = false,
  }) async {
    if (ref == null) return null;
    final id = _str(ref, 'id');
    final name = _str(ref, 'name');
    final kind = _str(ref, 'kind') ?? 'expense';
    if (id == null) {
      if (name == null) return null;
      final found =
          await (db.select(db.categories)..where(
                (c) =>
                    c.name.equals(name) &
                    c.kind.equals(kind) &
                    c.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (found != null) return found.id;
    }
    final cid = id ?? newId();
    final existing = await (db.select(
      db.categories,
    )..where((c) => c.id.equals(cid))).getSingleOrNull();
    if (existing != null && existing.deletedAt == null && !overwrite) {
      return cid;
    }
    if (existing == null || existing.deletedAt != null) {
      _newRef('カテゴリ「${name ?? cid}」');
    }
    final order =
        existing?.sortOrder ??
        await _nextOrder(db.categories, db.categories.sortOrder);
    await db
        .into(db.categories)
        .insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: cid,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: name ?? existing?.name ?? '名称なし',
            kind: kind,
            color: normalizePaletteColor(
              _str(ref, 'color') ?? existing?.color ?? paletteGray,
            ),
            sortOrder: order,
            defaultValuation: Value(existing?.defaultValuation),
            saleTaxDefault: Value(existing?.saleTaxDefault),
            deletedAt: const Value(null),
          ),
        );
    return cid;
  }

  Future<String?> account(
    Map<String, dynamic>? ref, {
    bool overwrite = false,
  }) async {
    if (ref == null) return null;
    final id = _str(ref, 'id');
    final name = _str(ref, 'name');
    if (id == null) {
      if (name == null) return null;
      final found = await (db.select(
        db.accounts,
      )..where((a) => a.name.equals(name) & a.deletedAt.isNull())).get();
      if (found.isNotEmpty) return found.first.id;
    }
    final aid = id ?? newId();
    final existing = await (db.select(
      db.accounts,
    )..where((a) => a.id.equals(aid))).getSingleOrNull();
    if (existing != null && existing.deletedAt == null && !overwrite) {
      return aid;
    }
    if (existing == null || existing.deletedAt != null) {
      _newRef('口座「${name ?? aid}」');
    }
    final order =
        existing?.sortOrder ??
        await _nextOrder(db.accounts, db.accounts.sortOrder);
    await db
        .into(db.accounts)
        .insertOnConflictUpdate(
          AccountsCompanion.insert(
            id: aid,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: name ?? existing?.name ?? '名称なし',
            kind: _str(ref, 'kind') ?? existing?.kind ?? AccountKind.other.code,
            // 取り込みで新しく作る口座は初期残高0円、基準日は取り込んだ日（設計書 6.9）
            initialBalance:
                _int(ref['initial_balance']) ?? existing?.initialBalance ?? 0,
            initialDate:
                _str(ref, 'initial_date') ??
                existing?.initialDate ??
                todayString(),
            sortOrder: order,
            deletedAt: const Value(null),
          ),
        );
    return aid;
  }

  Future<int> _nextOrder(
    TableInfo<Table, dynamic> table,
    GeneratedColumn<int> col,
  ) async {
    final m = col.max();
    final q = db.selectOnly(table)..addColumns([m]);
    return ((await q.getSingle()).read(m) ?? -1) + 1;
  }

  /// 家族。取り込み先のプランになければ、そのプランに作る。
  Future<String?> member(Map<String, dynamic>? ref, String planId) async {
    if (ref == null) return null;
    final fileId = _str(ref, 'id');
    final id = _id(fileId);
    final existing = await (db.select(
      db.familyMembers,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    if (existing != null &&
        existing.planId == planId &&
        existing.deletedAt == null) {
      return id;
    }
    // 別のプランに同じUUIDがあるときは、新しいUUIDで作る
    final useId = existing != null && existing.planId != planId ? newId() : id;
    if (existing != null && existing.planId != planId && fileId != null) {
      remap[fileId] = useId;
    }
    _newRef('家族「${_str(ref, 'name') ?? useId}」');
    await db
        .into(db.familyMembers)
        .insertOnConflictUpdate(
          FamilyMembersCompanion.insert(
            id: useId,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            name: _str(ref, 'name') ?? '名称なし',
            relation: _str(ref, 'relation') ?? Relation.other.code,
            birthDate: _validDate(_str(ref, 'birth_date'))
                ? _str(ref, 'birth_date')!
                : '1990-01-01',
            lifeExpectancy:
                _int(ref['life_expectancy'] ?? ref['lifespan']) ?? 90,
            sortOrder: await _nextOrder(
              db.familyMembers,
              db.familyMembers.sortOrder,
            ),
            deletedAt: const Value(null),
          ),
        );
    return useId;
  }

  /// イベント。取り込み先のプランになければ、そのプランに作る（金額の計画行は作らない）。
  Future<String?> event(Map<String, dynamic>? ref, String planId) async {
    if (ref == null) return null;
    final fileId = _str(ref, 'id');
    final id = _id(fileId);
    final existing = await (db.select(
      db.planEvents,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (existing != null &&
        existing.planId == planId &&
        existing.deletedAt == null) {
      return id;
    }
    final useId = existing != null && existing.planId != planId ? newId() : id;
    if (useId != id && fileId != null) remap[fileId] = useId;
    final plan = await (db.select(
      db.plans,
    )..where((p) => p.id.equals(planId))).getSingle();
    final memberId =
        await member(
          (ref['member'] as Map?)?.cast<String, dynamic>(),
          planId,
        ) ??
        plan.protagonistMemberId;
    _newRef('イベント「${_str(ref, 'title') ?? useId}」');
    await db
        .into(db.planEvents)
        .insertOnConflictUpdate(
          PlanEventsCompanion.insert(
            id: useId,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            memberId: memberId,
            title: _str(ref, 'title') ?? '名称なし',
            year: _int(ref['year']) ?? DateTime.now().year,
            month: (_int(ref['month']) ?? 1).clamp(1, 12),
            day: Value(_int(ref['day'])),
            status: _str(ref, 'status') ?? EventStatus.planned.code,
            doneDate: Value(_str(ref, 'done_date')),
            memo: Value(_str(ref, 'memo')),
            deletedAt: const Value(null),
          ),
        );
    return useId;
  }

  /// 資産。取り込み先のプランになければ、そのプランに作る。
  Future<String?> asset(
    Map<String, dynamic>? ref,
    String planId, {
    bool overwrite = false,
  }) async {
    if (ref == null) return null;
    final fileId = _str(ref, 'id');
    final id = _id(fileId);
    final existing = await (db.select(
      db.assets,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    final samePlan =
        existing != null &&
        existing.planId == planId &&
        existing.deletedAt == null;
    if (samePlan && !overwrite) return id;
    final useId = existing != null && existing.planId != planId ? newId() : id;
    if (useId != id && fileId != null) remap[fileId] = useId;
    final catRef = (ref['category'] as Map?)?.cast<String, dynamic>();
    final categoryId =
        await category(catRef == null ? null : {...catRef, 'kind': 'asset'}) ??
        existing?.categoryId ??
        await category({'name': 'その他の資産', 'kind': 'asset'});
    final accountId = await account(
      (ref['account'] as Map?)?.cast<String, dynamic>(),
    );
    if (!samePlan) {
      _newRef('資産「${_str(ref, 'name') ?? useId}」');
    }
    await db
        .into(db.assets)
        .insertOnConflictUpdate(
          AssetsCompanion.insert(
            id: useId,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            name: _str(ref, 'name') ?? existing?.name ?? '名称なし',
            categoryId: categoryId!,
            valuation:
                _str(ref, 'valuation') ??
                existing?.valuation ??
                Valuation.value.code,
            code: Value(_str(ref, 'code') ?? existing?.code),
            accountId: Value(accountId ?? existing?.accountId),
            sortOrder:
                existing?.sortOrder ??
                await _nextOrder(db.assets, db.assets.sortOrder),
            deletedAt: const Value(null),
          ),
        );
    return useId;
  }

  // ---- セクション ----

  /// プランの本体（設定・家族・イベント・率）。ライフプラン単位は新しいプラン、全データは同じUUIDで追加・上書き。
  Future<String> planBody(Map<String, dynamic> p, String fileId) async {
    final settings =
        (p['settings'] as Map?)?.cast<String, dynamic>() ?? const {};
    var name = _str(p['plan'], 'name') ?? '取り込んだプラン';
    final String planId;
    if (kind == ImportKind.plan) {
      planId = _id(fileId);
      final names = {
        for (final x in await db.select(db.plans).get())
          if (x.deletedAt == null) x.name,
      };
      if (names.contains(name)) name = '$name(2)';
      report.plansNew++;
    } else {
      planId = fileId;
      final exists = await (db.select(
        db.plans,
      )..where((x) => x.id.equals(planId))).getSingleOrNull();
      exists == null ? report.plansNew++ : report.plansOverwrite++;
    }
    report.createdPlanId ??= planId;
    final existing = await (db.select(
      db.plans,
    )..where((x) => x.id.equals(planId))).getSingleOrNull();
    final protagonistFile = _str(settings['protagonist'], 'id');
    await db
        .into(db.plans)
        .insertOnConflictUpdate(
          PlansCompanion.insert(
            id: planId,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: name,
            protagonistMemberId: protagonistFile == null
                ? (existing?.protagonistMemberId ?? '')
                : _id(protagonistFile),
            startYear:
                _int(settings['start_year']) ??
                existing?.startYear ??
                DateTime.now().year,
            baselineDate: kind == ImportKind.plan
                ? todayString()
                : (_str(settings, 'baseline_date') ??
                      existing?.baselineDate ??
                      todayString()),
            defaultInflationRate:
                (settings['default_inflation_rate'] as num?)?.toDouble() ??
                existing?.defaultInflationRate ??
                0,
            sortOrder:
                existing?.sortOrder ??
                await _nextOrder(db.plans, db.plans.sortOrder),
            deletedAt: const Value(null),
          ),
        );
    for (final m in (p['family'] as List? ?? const []).whereType<Map>()) {
      await _upsertMember(m.cast<String, dynamic>(), planId);
    }
    for (final e in (p['events'] as List? ?? const []).whereType<Map>()) {
      final id = _id(_str(e, 'id'));
      final memberId = await member(
        (e['member'] as Map?)?.cast<String, dynamic>(),
        planId,
      );
      await db
          .into(db.planEvents)
          .insertOnConflictUpdate(
            PlanEventsCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              planId: planId,
              memberId: memberId ?? '',
              title: _str(e, 'title') ?? '名称なし',
              year: _int(e['year']) ?? DateTime.now().year,
              month: (_int(e['month']) ?? 1).clamp(1, 12),
              day: Value(_int(e['day'])),
              status: _str(e, 'status') ?? EventStatus.planned.code,
              doneDate: Value(_str(e, 'done_date')),
              memo: Value(_str(e, 'memo')),
              deletedAt: const Value(null),
            ),
          );
    }
    for (final r in (p['rates'] as List? ?? const []).whereType<Map>()) {
      final type = _str(r, 'type');
      final rate = (r['annual_rate'] as num?)?.toDouble();
      if (type == null || rate == null) continue;
      final String? target = switch (type) {
        TargetType.account => await account(
          (r['account'] as Map?)?.cast<String, dynamic>(),
        ),
        TargetType.category => await category(
          (r['category'] as Map?)?.cast<String, dynamic>(),
        ),
        _ => _id(_str(r['asset'], 'id')),
      };
      if (target == null) continue;
      await db
          .into(db.planRates)
          .insertOnConflictUpdate(
            PlanRatesCompanion.insert(
              id: planTargetId(planId, type, target),
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              planId: planId,
              targetType: type,
              targetId: target,
              annualRate: rate,
              deletedAt: const Value(null),
            ),
          );
    }
    return planId;
  }

  Future<void> _upsertMember(Map<String, dynamic> m, String planId) async {
    final id = _id(_str(m, 'id'));
    await db
        .into(db.familyMembers)
        .insertOnConflictUpdate(
          FamilyMembersCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            name: _str(m, 'name') ?? '名称なし',
            relation: _str(m, 'relation') ?? Relation.other.code,
            birthDate: _validDate(_str(m, 'birth_date'))
                ? _str(m, 'birth_date')!
                : '1990-01-01',
            lifeExpectancy: _int(m['life_expectancy'] ?? m['lifespan']) ?? 90,
            sortOrder: await _nextOrder(
              db.familyMembers,
              db.familyMembers.sortOrder,
            ),
            deletedAt: const Value(null),
          ),
        );
  }

  /// 資産と価値：同じUUIDは上書き、価値は同じ日・同じ月を上書き、ほかは追加（価値は消さない）。
  Future<void> assetSection(
    Map<String, dynamic> a,
    String planId,
    int row,
  ) async {
    if (_str(a, 'name') == null) {
      report.invalid.add(ImportIssue('資産', row, '資産名がない'));
      return;
    }
    final id = _id(_str(a, 'id'));
    final existed =
        await (db.select(db.assets)..where(
              (x) =>
                  x.id.equals(id) &
                  x.planId.equals(planId) &
                  x.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    existed == null ? report.assetsNew++ : report.assetsOverwrite++;
    final assetId = (await asset(a, planId, overwrite: true))!;
    for (final v in (a['values'] as List? ?? const []).whereType<Map>()) {
      final unit = _str(v, 'unit');
      final date = _str(v, 'date');
      final value = v['value'];
      if ((unit != 'day' && unit != 'month') || date == null || value is! num) {
        continue;
      }
      final vid = assetValueId(assetId, date);
      final ex =
          await (db.select(db.assetValues)
                ..where((x) => x.id.equals(vid) & x.deletedAt.isNull()))
              .getSingleOrNull();
      ex == null ? report.valuesAdd++ : report.valuesOverwrite++;
      await db
          .into(db.assetValues)
          .insertOnConflictUpdate(
            AssetValuesCompanion.insert(
              id: vid,
              createdAt: ex?.createdAt ?? now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              assetId: assetId,
              unit: unit!,
              valueDate: date,
              valueX100: (value * 100).round(),
              deletedAt: const Value(null),
            ),
          );
    }
  }

  /// テンプレート。同じUUIDがあれば方針（上書き／別に追加／取り込まない）に従う。
  Future<void> templateSection(
    Map<String, dynamic> t,
    String? planId,
    Map<String, dynamic> json,
  ) async {
    await _template(_str(t, 'id'), json);
  }

  Future<String?> _template(String? fileId, Map<String, dynamic> json) async {
    if (fileId != null && templateMap.containsKey(fileId)) {
      return templateMap[fileId];
    }
    final t = (json['templates'] as List? ?? const [])
        .whereType<Map>()
        .where((x) => x['id'] == fileId)
        .firstOrNull
        ?.cast<String, dynamic>();
    final existing = fileId == null
        ? null
        : await (db.select(db.templates)
                ..where((x) => x.id.equals(fileId) & x.deletedAt.isNull()))
              .getSingleOrNull();
    if (t == null) {
      // ファイルにないテンプレートは、アプリにあれば使う
      if (existing != null) templateMap[fileId!] = fileId;
      return existing?.id;
    }
    var id = fileId ?? newId();
    var name = _str(t, 'name') ?? '名称なし';
    if (existing != null) {
      report.templatesSame++;
      switch (policy) {
        case SameIdPolicy.skip:
          templateMap[id] = id;
          return id;
        case SameIdPolicy.addNew:
          id = newId();
          name = '$name(2)';
        case SameIdPolicy.overwrite:
          break;
      }
    } else {
      report.templatesNew++;
    }
    templateMap[fileId ?? id] = id;
    final kindCode = _str(t, 'kind') ?? 'expense';
    await db
        .into(db.templates)
        .insertOnConflictUpdate(
          TemplatesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: name,
            kind: kindCode,
            amount: Value(_int(t['amount'])),
            quantityX1e4: Value(
              t['quantity'] is num
                  ? ((t['quantity'] as num) * 10000).round()
                  : null,
            ),
            categoryId: Value(
              await category((t['category'] as Map?)?.cast<String, dynamic>()),
            ),
            accountId: Value(
              await account((t['account'] as Map?)?.cast<String, dynamic>()),
            ),
            toAccountId: Value(
              await account((t['to_account'] as Map?)?.cast<String, dynamic>()),
            ),
            // 資産を参照するテンプレートは、その資産がアプリにあるときだけ資産を引き継ぐ
            assetId: Value(await _existingAssetId(_str(t['asset'], 'id'))),
            assetAction: Value(
              await _existingAssetId(_str(t['asset'], 'id')) == null
                  ? null
                  : _str(t, 'asset_action'),
            ),
            memo: Value(_str(t, 'memo')),
            growthMode: _str(t, 'growth_mode') ?? GrowthMode.category.code,
            growthRate: Value((t['growth_rate'] as num?)?.toDouble()),
            deletedAt: const Value(null),
          ),
        );
    return id;
  }

  Future<String?> _existingAssetId(String? fileId) async {
    if (fileId == null) return null;
    final id = remap[fileId] ?? fileId;
    final a = await (db.select(
      db.assets,
    )..where((x) => x.id.equals(id) & x.deletedAt.isNull())).getSingleOrNull();
    return a?.id;
  }

  /// グループと項目。項目が使うテンプレートは、同じファイルの templates にあればその内容で作る。
  Future<void> groupSection(
    Map<String, dynamic> g,
    Map<String, dynamic> json,
  ) async {
    final fileId = _str(g, 'id');
    var id = fileId ?? newId();
    var name = _str(g, 'name') ?? '名称なし';
    final existing = fileId == null
        ? null
        : await (db.select(db.templateGroups)
                ..where((x) => x.id.equals(fileId) & x.deletedAt.isNull()))
              .getSingleOrNull();
    if (existing != null) {
      report.groupsSame++;
      switch (policy) {
        case SameIdPolicy.skip:
          groupMap[id] = id;
          return;
        case SameIdPolicy.addNew:
          id = newId();
          name = '$name(2)';
        case SameIdPolicy.overwrite:
          break;
      }
    } else {
      report.groupsNew++;
    }
    groupMap[fileId ?? id] = id;
    await db
        .into(db.templateGroups)
        .insertOnConflictUpdate(
          TemplateGroupsCompanion.insert(
            id: id,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: name,
            sortOrder:
                existing?.sortOrder ??
                await _nextOrder(
                  db.templateGroups,
                  db.templateGroups.sortOrder,
                ),
            deletedAt: const Value(null),
          ),
        );
    // 項目は作り直す（上書きでは今の項目を外してからファイルの項目を入れる）
    if (existing != null && id == existing.id) {
      final old = await (db.select(
        db.templateGroupItems,
      )..where((i) => i.groupId.equals(id) & i.deletedAt.isNull())).get();
      await softDeleteRows(db, stamp, 'template_group_item', [
        for (final i in old) i.id,
      ]);
    }
    final items = (g['items'] as List? ?? const []).whereType<Map>().toList();
    for (final i in items) {
      final fid = _str(i, 'id') ?? newId();
      itemMap[fid] = id == fileId ? fid : newId();
    }
    for (final (n, i) in items.indexed) {
      final templateId = await _template(_str(i['template'], 'id'), json);
      if (templateId == null) {
        report.invalid.add(
          ImportIssue('グループ「$name」の項目', n + 1, 'テンプレートがファイルにもアプリにもない'),
        );
        continue;
      }
      final fid = _str(i, 'id');
      await db
          .into(db.templateGroupItems)
          .insertOnConflictUpdate(
            TemplateGroupItemsCompanion.insert(
              id: itemMap[fid] ?? newId(),
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              groupId: id,
              templateId: templateId,
              amountMode: _str(i, 'amount_mode') ?? AmountMode.fixed.code,
              baseItemId: Value(
                itemMap[_str(i, 'base_item')] ?? _str(i, 'base_item'),
              ),
              percent: Value((i['percent'] as num?)?.toDouble()),
              frequency: Value(_str(i, 'frequency')),
              intervalN: Value(_int(i['interval_n'])),
              month: Value(_int(i['month'])),
              weekday: Value(_int(i['weekday'])),
              months: Value(_str(i, 'months')),
              sortOrder: n,
              deletedAt: const Value(null),
            ),
          );
    }
  }

  /// グループの登録（ライフプラン単位・全データ）。
  Future<void> registrations(Map<String, dynamic> p, String planId) async {
    for (final r
        in (p['registrations'] as List? ?? const []).whereType<Map>()) {
      final groupFile = _str(r['group'], 'id');
      final groupId = groupMap[groupFile] ?? groupFile;
      if (groupId == null ||
          _str(r, 'start_ym') == null ||
          _str(r, 'end_ym') == null) {
        continue;
      }
      await db
          .into(db.planGroups)
          .insertOnConflictUpdate(
            PlanGroupsCompanion.insert(
              id: _id(_str(r, 'id')),
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              planId: planId,
              groupId: groupId,
              startYm: _str(r, 'start_ym')!,
              endYm: _str(r, 'end_ym')!,
              memo: Value(_str(r, 'memo')),
              deletedAt: const Value(null),
            ),
          );
    }
  }

  String? _checkRow(Map<String, dynamic> r) {
    final kind = _str(r, 'kind');
    if (!const ['income', 'expense', 'transfer'].contains(kind)) {
      return '種類が income / expense / transfer でない';
    }
    final amount = _int(r['amount']);
    if (amount == null) return '金額が数値でない';
    if (amount <= 0) return '金額が正の数でない';
    if (r['account'] is! Map) return '口座がない';
    if (kind != 'transfer' && r['category'] is! Map) return 'カテゴリがない';
    if (kind == 'transfer' && r['to_account'] is! Map) return '入金先口座がない';
    final action = _str(r, 'asset_action');
    if (action != null &&
        !const ['buy', 'sell', 'income', 'cost'].contains(action)) {
      return '資産の動きが不正';
    }
    if (action != null && r['asset'] is! Map) return '資産の動きがあるのに資産がない';
    return null;
  }

  Future<Map<String, Object?>> _refs(
    Map<String, dynamic> r,
    String planId,
  ) async => {
    'category': await category(
      (r['category'] as Map?)?.cast<String, dynamic>(),
    ),
    'account': await account((r['account'] as Map?)?.cast<String, dynamic>()),
    'to_account': r['kind'] == 'transfer'
        ? await account((r['to_account'] as Map?)?.cast<String, dynamic>())
        : null,
    'asset': await asset((r['asset'] as Map?)?.cast<String, dynamic>(), planId),
    'event': await event((r['event'] as Map?)?.cast<String, dynamic>(), planId),
  };

  /// 予定（計画行）。同じUUIDがあれば上書き（由来は保つ）、なければ追加。予定・実績の単位では手入力の計画行になる。
  Future<void> line(Map<String, dynamic> l, String planId, int row) async {
    final err = _checkRow(l);
    final year = _int(l['year']);
    final month = _int(l['month']);
    if (err != null ||
        year == null ||
        month == null ||
        month < 1 ||
        month > 12) {
      report.invalid.add(
        ImportIssue(
          '予定',
          row,
          err ??
              (month == null || month < 1 || month > 12 ? '月が1〜12でない' : '年がない'),
        ),
      );
      return;
    }
    final id = _id(_str(l, 'id'));
    final existing = await (db.select(
      db.planLines,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    existing == null || existing.deletedAt != null
        ? report.linesNew++
        : report.linesOverwrite++;
    report._period(
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}',
    );
    final refs = await _refs(l, planId);
    String source;
    String? sourceId;
    if (existing != null && existing.deletedAt == null) {
      source = existing.source;
      sourceId = existing.sourceId;
    } else if (kind != ImportKind.rows &&
        _str(l, 'source') == 'group' &&
        _str(l, 'registration') != null) {
      source = 'group';
      sourceId = _id(_str(l, 'registration'));
    } else if (kind != ImportKind.rows &&
        _str(l, 'source') == 'event' &&
        _str(l, 'event_source') != null) {
      source = 'event';
      sourceId = _id(_str(l, 'event_source'));
    } else {
      source = PlanLineSource.manual.code;
      sourceId = null;
    }
    await db
        .into(db.planLines)
        .insertOnConflictUpdate(
          PlanLinesCompanion.insert(
            id: id,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            year: year,
            month: month,
            kind: _str(l, 'kind')!,
            amount: _int(l['amount'])!,
            categoryId: Value(refs['category'] as String?),
            accountId: refs['account']! as String,
            toAccountId: Value(refs['to_account'] as String?),
            assetId: Value(refs['asset'] as String?),
            assetAction: Value(
              refs['asset'] == null ? null : _str(l, 'asset_action'),
            ),
            quantityX1e4: Value(
              l['quantity'] is num
                  ? ((l['quantity'] as num) * 10000).round()
                  : null,
            ),
            eventId: Value(refs['event'] as String?),
            memo: Value(_str(l, 'memo')),
            source: source,
            sourceId: Value(sourceId),
            memberId: Value(
              kind == ImportKind.rows
                  ? existing?.memberId
                  : await member(
                      (l['member'] as Map?)?.cast<String, dynamic>(),
                      planId,
                    ),
            ),
            groupItemId: Value(
              kind == ImportKind.rows
                  ? existing?.groupItemId
                  : (itemMap[_str(l, 'group_item')] ?? _str(l, 'group_item')),
            ),
            deletedAt: const Value(null),
          ),
        );
  }

  /// 実績。同じUUIDがあれば上書き、なければそのUUIDのまま追加。
  Future<void> actual(Map<String, dynamic> t, String planId, int row) async {
    final err =
        _checkRow(t) ??
        (_validDate(_str(t, 'date')) ? null : '日付が YYYY-MM-DD でない');
    if (err != null) {
      report.invalid.add(ImportIssue('実績', row, err));
      return;
    }
    final id = _id(_str(t, 'id'));
    final existing = await (db.select(
      db.txns,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    existing == null || existing.deletedAt != null
        ? report.actualsNew++
        : report.actualsOverwrite++;
    final date = _str(t, 'date')!;
    report._period(date.substring(0, 7));
    final refs = await _refs(t, planId);
    final parent = _str(t, 'parent');
    await db
        .into(db.txns)
        .insertOnConflictUpdate(
          TxnsCompanion.insert(
            id: id,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            date: date,
            kind: _str(t, 'kind')!,
            amount: _int(t['amount'])!,
            categoryId: Value(refs['category'] as String?),
            accountId: refs['account']! as String,
            toAccountId: Value(refs['to_account'] as String?),
            assetId: Value(refs['asset'] as String?),
            assetAction: Value(
              refs['asset'] == null ? null : _str(t, 'asset_action'),
            ),
            quantityX1e4: Value(
              t['quantity'] is num
                  ? ((t['quantity'] as num) * 10000).round()
                  : null,
            ),
            eventId: Value(refs['event'] as String?),
            parentTxnId: Value(parent == null ? null : _id(parent)),
            memo: Value(_str(t, 'memo')),
            groupId: Value(
              groupMap[_str(t['group'], 'id')] ??
                  _str(t['group'], 'id') ??
                  existing?.groupId,
            ),
            groupItemId: Value(
              itemMap[_str(t, 'group_item')] ??
                  _str(t, 'group_item') ??
                  existing?.groupItemId,
            ),
            entryId: Value(_str(t, 'entry') ?? existing?.entryId),
            deletedAt: const Value(null),
          ),
        );
  }
}
