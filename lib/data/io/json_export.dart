import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/time.dart';
import '../db/database.dart';

/// JSON の書き出し（設計書 3.9・6.9）。
///
/// どの行も UUID（id）を持ち、行が参照するもの（カテゴリ・口座・資産・イベント・家族・テンプレート・グループ・プラン）は
/// 「参照オブジェクト」として、UUID と作成に必要な内容を一緒に書き出す。
class JsonExporter {
  JsonExporter(this.db);

  final AppDatabase db;

  static const format = 'lifeplan-data';
  static const version = 1;

  final _cats = <String, CategoryRow>{};
  final _accounts = <String, AccountRow>{};
  final _assets = <String, AssetRow>{};
  final _events = <String, PlanEventRow>{};
  final _members = <String, FamilyMemberRow>{};
  final _plans = <String, PlanRow>{};
  final _templates = <String, TemplateRow>{};
  final _groups = <String, TemplateGroupRow>{};

  Future<void> _load() async {
    if (_plans.isNotEmpty || _cats.isNotEmpty) return;
    for (final c in await db.select(db.categories).get()) {
      _cats[c.id] = c;
    }
    for (final a in await db.select(db.accounts).get()) {
      _accounts[a.id] = a;
    }
    for (final a in await db.select(db.assets).get()) {
      _assets[a.id] = a;
    }
    for (final e in await db.select(db.planEvents).get()) {
      _events[e.id] = e;
    }
    for (final m in await db.select(db.familyMembers).get()) {
      _members[m.id] = m;
    }
    for (final p in await db.select(db.plans).get()) {
      _plans[p.id] = p;
    }
    for (final t in await db.select(db.templates).get()) {
      _templates[t.id] = t;
    }
    for (final g in await db.select(db.templateGroups).get()) {
      _groups[g.id] = g;
    }
  }

  // ---- 参照オブジェクト ----

  Map<String, Object?>? categoryRef(String? id) {
    final c = _cats[id];
    if (id == null) return null;
    if (c == null) return {'id': id};
    return {'id': c.id, 'name': c.name, 'kind': c.kind, 'color': c.color};
  }

  Map<String, Object?>? accountRef(String? id) {
    final a = _accounts[id];
    if (id == null) return null;
    if (a == null) return {'id': id};
    return {'id': a.id, 'name': a.name, 'kind': a.kind};
  }

  Map<String, Object?>? assetRef(String? id) {
    final a = _assets[id];
    if (id == null) return null;
    if (a == null) return {'id': id};
    return {
      'id': a.id,
      'name': a.name,
      'category': categoryRef(a.categoryId),
      'valuation': a.valuation,
      if (a.code != null) 'code': a.code,
      if (a.accountId != null) 'account': accountRef(a.accountId),
    };
  }

  Map<String, Object?>? memberRef(String? id) {
    final m = _members[id];
    if (id == null) return null;
    if (m == null) return {'id': id};
    return {
      'id': m.id,
      'name': m.name,
      'relation': m.relation,
      'birth_date': m.birthDate,
      'life_expectancy': m.lifeExpectancy,
    };
  }

  Map<String, Object?>? eventRef(String? id) {
    final e = _events[id];
    if (id == null) return null;
    if (e == null) return {'id': id};
    return {
      'id': e.id,
      'title': e.title,
      'year': e.year,
      'month': e.month,
      if (e.day != null) 'day': e.day,
      'member': memberRef(e.memberId),
    };
  }

  Map<String, Object?> planRef(String id) => {
    'id': id,
    'name': _plans[id]?.name ?? '',
  };

  static num _qty(int x1e4) => x1e4 % 10000 == 0 ? x1e4 ~/ 10000 : x1e4 / 10000;
  static num _x100(int x100) => x100 % 100 == 0 ? x100 ~/ 100 : x100 / 100;

  Map<String, Object?> actualJson(TxnRow t) => {
    'id': t.id,
    'plan': planRef(t.planId),
    'date': t.date,
    'kind': t.kind,
    'amount': t.amount,
    if (t.categoryId != null) 'category': categoryRef(t.categoryId),
    'account': accountRef(t.accountId),
    if (t.toAccountId != null) 'to_account': accountRef(t.toAccountId),
    if (t.assetId != null) 'asset': assetRef(t.assetId),
    if (t.assetAction != null) 'asset_action': t.assetAction,
    if (t.quantityX1e4 != null) 'quantity': _qty(t.quantityX1e4!),
    if (t.eventId != null) 'event': eventRef(t.eventId),
    if (t.parentTxnId != null) 'parent': t.parentTxnId,
    if (t.memo != null) 'memo': t.memo,
    if (t.groupId != null)
      'group': {'id': t.groupId, 'name': _groups[t.groupId]?.name},
    if (t.groupItemId != null) 'group_item': t.groupItemId,
    if (t.entryId != null) 'entry': t.entryId,
  };

  /// [withSource]：プラン単位・全データでは由来（registration / event）も入れ、取り込みで紐づきを復元する。
  Map<String, Object?> lineJson(PlanLineRow l, {bool withSource = false}) => {
    'id': l.id,
    'year': l.year,
    'month': l.month,
    'kind': l.kind,
    'amount': l.amount,
    if (l.categoryId != null) 'category': categoryRef(l.categoryId),
    'account': accountRef(l.accountId),
    if (l.toAccountId != null) 'to_account': accountRef(l.toAccountId),
    if (l.assetId != null) 'asset': assetRef(l.assetId),
    if (l.assetAction != null) 'asset_action': l.assetAction,
    if (l.quantityX1e4 != null) 'quantity': _qty(l.quantityX1e4!),
    if (l.eventId != null) 'event': eventRef(l.eventId),
    if (l.memo != null) 'memo': l.memo,
    'source': l.source,
    if (withSource && l.source == 'group') 'registration': l.sourceId,
    if (withSource && l.source == 'event') 'event_source': l.sourceId,
    if (withSource && l.memberId != null) 'member': memberRef(l.memberId),
    if (withSource && l.groupItemId != null) 'group_item': l.groupItemId,
  };

  Map<String, Object?> templateJson(TemplateRow t) => {
    'id': t.id,
    'name': t.name,
    'kind': t.kind,
    if (t.amount != null) 'amount': t.amount,
    if (t.quantityX1e4 != null) 'quantity': _qty(t.quantityX1e4!),
    if (t.categoryId != null) 'category': categoryRef(t.categoryId),
    if (t.accountId != null) 'account': accountRef(t.accountId),
    if (t.toAccountId != null) 'to_account': accountRef(t.toAccountId),
    if (t.assetId != null) 'asset': assetRef(t.assetId),
    if (t.assetAction != null) 'asset_action': t.assetAction,
    if (t.memo != null) 'memo': t.memo,
    'growth_mode': t.growthMode,
    if (t.growthRate != null) 'growth_rate': t.growthRate,
  };

  Future<Map<String, Object?>> groupJson(TemplateGroupRow g) async {
    final items =
        await (db.select(db.templateGroupItems)
              ..where((i) => i.groupId.equals(g.id) & i.deletedAt.isNull())
              ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
            .get();
    return {
      'id': g.id,
      'name': g.name,
      'items': [
        for (final i in items)
          {
            'id': i.id,
            'template': {
              'id': i.templateId,
              'name': _templates[i.templateId]?.name,
            },
            'amount_mode': i.amountMode,
            if (i.baseItemId != null) 'base_item': i.baseItemId,
            if (i.percent != null) 'percent': i.percent,
            if (i.frequency != null) 'frequency': i.frequency,
            if (i.intervalN != null) 'interval_n': i.intervalN,
            if (i.month != null) 'month': i.month,
            if (i.weekday != null) 'weekday': i.weekday,
            if (i.months != null) 'months': i.months,
          },
      ],
    };
  }

  Future<Map<String, Object?>> assetJson(AssetRow a) async {
    final values =
        await (db.select(db.assetValues)
              ..where((v) => v.assetId.equals(a.id) & v.deletedAt.isNull())
              ..orderBy([(v) => OrderingTerm(expression: v.valueDate)]))
            .get();
    return {
      ...assetRef(a.id)!,
      'plan': planRef(a.planId),
      'values': [
        for (final v in values)
          {'unit': v.unit, 'date': v.valueDate, 'value': _x100(v.valueX100)},
      ],
    };
  }

  Map<String, Object?> _envelope(Map<String, Object?> body) => {
    'format': format,
    'version': version,
    'exported_at': nowTimestamp(),
    ...body,
  };

  // ---- 単位ごとの書き出し ----

  /// 予定・実績（家計簿のリストで選んだもの・収支1件）：実績（actuals）と予定（plans の lines）。
  Future<Map<String, Object?>> exportRows({
    required String planId,
    List<TxnRow> txns = const [],
    List<PlanLineRow> lines = const [],
  }) async {
    await _load();
    return _envelope({
      if (txns.isNotEmpty) 'actuals': [for (final t in txns) actualJson(t)],
      if (lines.isNotEmpty)
        'plans': [
          {
            'plan': planRef(planId),
            'lines': [for (final l in lines) lineJson(l)],
          },
        ],
    });
  }

  /// テンプレート単位。
  Future<Map<String, Object?>> exportTemplates(List<String> ids) async {
    await _load();
    return _envelope({
      'templates': [
        for (final id in ids)
          if (_templates[id] != null) templateJson(_templates[id]!),
      ],
    });
  }

  /// グループ単位：グループと項目、項目が使うテンプレート。
  Future<Map<String, Object?>> exportGroups(List<String> ids) async {
    await _load();
    final groups = [
      for (final id in ids)
        if (_groups[id] != null) _groups[id]!,
    ];
    return _envelope(await _groupsAndTemplates(groups));
  }

  Future<Map<String, Object?>> _groupsAndTemplates(
    List<TemplateGroupRow> groups,
  ) async {
    final gs = [for (final g in groups) await groupJson(g)];
    final templateIds = {
      for (final g in gs)
        for (final i in g['items']! as List)
          ((i as Map)['template'] as Map)['id'] as String,
    };
    return {
      'groups': gs,
      'templates': [
        for (final id in templateIds)
          if (_templates[id] != null && _templates[id]!.deletedAt == null)
            templateJson(_templates[id]!),
      ],
    };
  }

  /// 資産単位・資産リスト：資産と価値、その資産を参照する実績・予定（それらが参照するイベントは参照オブジェクトで入る）。
  Future<Map<String, Object?>> exportAssets(
    String planId,
    List<String> assetIds,
  ) async {
    await _load();
    final assets = [
      for (final id in assetIds)
        if (_assets[id] != null && _assets[id]!.deletedAt == null) _assets[id]!,
    ];
    final ids = {for (final a in assets) a.id};
    final txns = await (db.select(
      db.txns,
    )..where((t) => t.assetId.isIn(ids) & t.deletedAt.isNull())).get();
    final lines = await (db.select(
      db.planLines,
    )..where((l) => l.assetId.isIn(ids) & l.deletedAt.isNull())).get();
    return _envelope({
      'assets': [for (final a in assets) await assetJson(a)],
      if (txns.isNotEmpty) 'actuals': [for (final t in txns) actualJson(t)],
      if (lines.isNotEmpty)
        'plans': [
          {
            'plan': planRef(planId),
            'lines': [for (final l in lines) lineJson(l)],
          },
        ],
    });
  }

  Future<Map<String, Object?>> _planJson(String planId) async {
    final p = _plans[planId]!;
    final family = await (db.select(
      db.familyMembers,
    )..where((m) => m.planId.equals(planId) & m.deletedAt.isNull())).get();
    final events = await (db.select(
      db.planEvents,
    )..where((e) => e.planId.equals(planId) & e.deletedAt.isNull())).get();
    final rates = await (db.select(
      db.planRates,
    )..where((r) => r.planId.equals(planId) & r.deletedAt.isNull())).get();
    final regs = await (db.select(
      db.planGroups,
    )..where((r) => r.planId.equals(planId) & r.deletedAt.isNull())).get();
    final lines = await (db.select(
      db.planLines,
    )..where((l) => l.planId.equals(planId) & l.deletedAt.isNull())).get();
    Map<String, Object?> target(String type, String id) => switch (type) {
      'account' => {'type': type, 'account': accountRef(id)},
      'asset' => {
        'type': type,
        'asset': {'id': id},
      },
      _ => {'type': type, 'category': categoryRef(id)},
    };
    return {
      'plan': planRef(planId),
      'settings': {
        'start_year': p.startYear,
        'default_inflation_rate': p.defaultInflationRate,
        'baseline_date': p.baselineDate,
        'protagonist': {'id': p.protagonistMemberId},
      },
      'family': [for (final m in family) memberRef(m.id)],
      'events': [
        for (final e in events)
          {
            ...eventRef(e.id)!,
            'status': e.status,
            if (e.doneDate != null) 'done_date': e.doneDate,
            if (e.memo != null) 'memo': e.memo,
          },
      ],
      'rates': [
        for (final r in rates)
          {...target(r.targetType, r.targetId), 'annual_rate': r.annualRate},
      ],
      'registrations': [
        for (final r in regs)
          {
            'id': r.id,
            'group': {'id': r.groupId, 'name': _groups[r.groupId]?.name},
            'start_ym': r.startYm,
            'end_ym': r.endYm,
            if (r.memo != null) 'memo': r.memo,
          },
      ],
      'lines': [for (final l in lines) lineJson(l, withSource: true)],
    };
  }

  /// ライフプラン単位：プランの設定・家族・イベント・率・グループの登録・予定・実績・資産と価値、
  /// 登録しているグループとそのテンプレート。
  Future<Map<String, Object?>> exportPlan(String planId) async {
    await _load();
    final regs = await (db.select(
      db.planGroups,
    )..where((r) => r.planId.equals(planId) & r.deletedAt.isNull())).get();
    final groups = {
      for (final r in regs)
        if (_groups[r.groupId] != null && _groups[r.groupId]!.deletedAt == null)
          _groups[r.groupId]!,
    }.toList();
    final txns = await (db.select(
      db.txns,
    )..where((t) => t.planId.equals(planId) & t.deletedAt.isNull())).get();
    final assets = [
      for (final a in _assets.values)
        if (a.planId == planId && a.deletedAt == null) a,
    ];
    return _envelope({
      'plans': [await _planJson(planId)],
      'actuals': [for (final t in txns) actualJson(t)],
      'assets': [for (final a in assets) await assetJson(a)],
      ...await _groupsAndTemplates(groups),
    });
  }

  /// アプリの全データ：カテゴリ・口座（使われていないものも含む）・テンプレート・グループ・全プラン。
  Future<Map<String, Object?>> exportAll() async {
    await _load();
    final plans = [
      for (final p in _plans.values)
        if (p.deletedAt == null) p,
    ];
    final groups = [
      for (final g in _groups.values)
        if (g.deletedAt == null) g,
    ];
    final txns = await (db.select(
      db.txns,
    )..where((t) => t.deletedAt.isNull())).get();
    final assets = [
      for (final a in _assets.values)
        if (a.deletedAt == null && plans.any((p) => p.id == a.planId)) a,
    ];
    final gt = await _groupsAndTemplates(groups);
    return _envelope({
      'masters': {
        'categories': [
          for (final c in _cats.values)
            if (c.deletedAt == null) categoryRef(c.id),
        ],
        'accounts': [
          for (final a in _accounts.values)
            if (a.deletedAt == null)
              {
                ...accountRef(a.id)!,
                'initial_balance': a.initialBalance,
                'initial_date': a.initialDate,
              },
        ],
      },
      'templates': [
        for (final t in _templates.values)
          if (t.deletedAt == null) templateJson(t),
      ],
      'groups': gt['groups'],
      'plans': [for (final p in plans) await _planJson(p.id)],
      'actuals': [
        for (final t in txns)
          if (plans.any((p) => p.id == t.planId)) actualJson(t),
      ],
      'assets': [for (final a in assets) await assetJson(a)],
    });
  }

  static String encode(Map<String, Object?> json) =>
      const JsonEncoder.withIndent('  ').convert(json);
}
