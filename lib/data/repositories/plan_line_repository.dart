import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/time.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/calc/group_registration.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'stamp.dart';
import 'template_repository.dart';

/// 手入力の予定（家計簿の予定入力。設計書 3.1）。資産・イベントの欄は M5・M6 で加える。
class PlanLineInput {
  const PlanLineInput({
    required this.planId,
    required this.ym,
    required this.kind,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.memo,
    this.assetId,
    this.assetAction,
    this.quantityX1e4,
    this.eventId,
  });

  final String planId;
  final YearMonth ym;
  final TxnKind kind;
  final int amount;
  final String accountId;
  final String? categoryId;
  final String? toAccountId;
  final String? memo;

  /// 資産の紐づけ（設計書 3.1：収入・支出に資産を紐づけられる）
  final String? assetId;
  final AssetAction? assetAction;

  /// 数量×単価の資産の購入・売却の数量×10,000
  final int? quantityX1e4;

  /// 関連するイベント（M6）
  final String? eventId;
}

/// 登録済みグループの一覧に出す情報。
class RegistrationSummary {
  const RegistrationSummary({
    required this.registration,
    required this.groupName,
    required this.lineCount,
  });

  final PlanGroupRow registration;

  /// 元のグループが削除されていれば null（設計書 3.2）
  final String? groupName;
  final int lineCount;

  bool get groupDeleted => groupName == null;
}

/// 計画行・グループの登録（設計書 4.5 plan_line / plan_group、6.3・6.4）。
class PlanLineRepository {
  PlanLineRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  // ---- 計画行 ----

  /// プランの計画行のうち [from]〜[to] の年月（含む）。null なら制限しない。
  Stream<List<PlanLineRow>> watchLines(
    String planId, {
    YearMonth? from,
    YearMonth? to,
  }) {
    final q = db.select(db.planLines)
      ..where((l) {
        var e = l.planId.equals(planId) & l.deletedAt.isNull();
        if (from != null) {
          e =
              e &
              (l.year * const Constant(12) + l.month).isBiggerOrEqualValue(
                from.year * 12 + from.month,
              );
        }
        if (to != null) {
          e =
              e &
              (l.year * const Constant(12) + l.month).isSmallerOrEqualValue(
                to.year * 12 + to.month,
              );
        }
        return e;
      })
      ..orderBy([
        (l) => OrderingTerm(expression: l.year),
        (l) => OrderingTerm(expression: l.month),
        (l) => OrderingTerm(expression: l.source),
        (l) => OrderingTerm(expression: l.createdAt),
      ]);
    return q.watch();
  }

  Future<PlanLineRow?> getLine(String id) => (db.select(
    db.planLines,
  )..where((l) => l.id.equals(id))).getSingleOrNull();

  Future<String> createManual(PlanLineInput input) async {
    final now = stamp.now();
    final id = newId();
    await db
        .into(db.planLines)
        .insert(
          PlanLinesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: input.planId,
            year: input.ym.year,
            month: input.ym.month,
            kind: input.kind.code,
            amount: input.amount,
            categoryId: Value(
              input.kind == TxnKind.transfer ? null : input.categoryId,
            ),
            accountId: input.accountId,
            toAccountId: Value(
              input.kind == TxnKind.transfer ? input.toAccountId : null,
            ),
            memo: Value(input.memo),
            assetId: Value(input.assetId),
            assetAction: Value(input.assetAction?.code),
            quantityX1e4: Value(input.quantityX1e4),
            eventId: Value(input.eventId),
            source: PlanLineSource.manual.code,
          ),
        );
    return id;
  }

  /// 更新。グループ・イベント由来の行も編集でき、由来（source・source_id）は保つ（設計書 3.1）。
  Future<void> updateLine(String id, PlanLineInput input) async {
    await (db.update(db.planLines)..where((l) => l.id.equals(id))).write(
      PlanLinesCompanion(
        year: Value(input.ym.year),
        month: Value(input.ym.month),
        kind: Value(input.kind.code),
        amount: Value(input.amount),
        categoryId: Value(
          input.kind == TxnKind.transfer ? null : input.categoryId,
        ),
        accountId: Value(input.accountId),
        toAccountId: Value(
          input.kind == TxnKind.transfer ? input.toAccountId : null,
        ),
        memo: Value(input.memo),
        assetId: Value(input.assetId),
        assetAction: Value(input.assetAction?.code),
        quantityX1e4: Value(input.quantityX1e4),
        eventId: Value(input.eventId),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  Future<void> deleteLine(String id) =>
      softDeleteRows(db, stamp, 'plan_line', [id]);

  // ---- グループの登録 ----

  Stream<List<RegistrationSummary>> watchRegistrations(String planId) {
    final q = db.customSelect(
      'SELECT pg.*, g.name AS group_name, '
      ' (SELECT COUNT(*) FROM plan_line l WHERE l.source = \'group\' '
      '   AND l.source_id = pg.id AND l.deleted_at IS NULL) AS line_count '
      'FROM plan_group pg '
      'LEFT JOIN template_group g ON g.id = pg.group_id AND g.deleted_at IS NULL '
      'WHERE pg.plan_id = ? AND pg.deleted_at IS NULL '
      'ORDER BY pg.start_ym, pg.created_at',
      variables: [Variable.withString(planId)],
      readsFrom: {db.planGroups, db.templateGroups, db.planLines},
    );
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          RegistrationSummary(
            registration: db.planGroups.map(r.data),
            groupName: r.readNullable<String>('group_name'),
            lineCount: r.read<int>('line_count'),
          ),
      ],
    );
  }

  /// 登録の中身を計算する（グループを登録の確認画面・登録・作り直しで使う）。
  Future<RegistrationResult> preview({
    required String planId,
    required String groupId,
    required YearMonth start,
    required YearMonth end,
    YearMonth? from,
  }) async {
    final items = await TemplateRepository(db, stamp).getGroupItems(groupId);
    final templates = await (db.select(
      db.templates,
    )..where((t) => t.deletedAt.isNull())).get();
    final plan = await (db.select(
      db.plans,
    )..where((p) => p.id.equals(planId))).getSingle();
    final rates =
        await (db.select(db.planRates)..where(
              (r) =>
                  r.planId.equals(planId) &
                  r.deletedAt.isNull() &
                  r.targetType.equals(TargetType.category),
            ))
            .get();
    final rateByCategory = {for (final r in rates) r.targetId: r.annualRate};
    final assets = await (db.select(
      db.assets,
    )..where((a) => a.planId.equals(planId) & a.deletedAt.isNull())).get();
    final priceAt = await _quantityAssetPricer(plan, assets);
    return generateGroupLines(
      items: items,
      templates: {for (final t in templates) t.id: regTemplateOf(t)},
      start: start,
      end: end,
      from: from,
      categoryRate: (c) => c == null ? null : rateByCategory[c],
      defaultRate: plan.defaultInflationRate,
      allowedAssetIds: {for (final a in assets) a.id},
      quantityAssetPrice: priceAt,
    );
  }

  /// 数量×単価の資産の「その月の見込み単価」を返す関数を作る（設計書 6.3 補足）。
  ///
  /// 起点の単価は plan_baseline、なければ起点日時点の価値、なければ起点日時点の取得価額÷保有数。
  /// どれもなければ、その月末までに指定した価値の最新（なければ null）。
  Future<int? Function(String, YearMonth)> _quantityAssetPricer(
    PlanRow plan,
    List<AssetRow> assets,
  ) async {
    final qty = {
      for (final a in assets)
        if (a.valuation == Valuation.quantity.code) a.id,
    };
    if (qty.isEmpty) return (_, _) => null;
    final values = await (db.select(
      db.assetValues,
    )..where((v) => v.assetId.isIn(qty) & v.deletedAt.isNull())).get();
    final baselines =
        await (db.select(db.planBaselines)..where(
              (b) =>
                  b.planId.equals(plan.id) &
                  b.targetType.equals(TargetType.asset) &
                  b.deletedAt.isNull(),
            ))
            .get();
    final rates =
        await (db.select(db.planRates)..where(
              (r) =>
                  r.planId.equals(plan.id) &
                  r.targetType.equals(TargetType.asset) &
                  r.deletedAt.isNull(),
            ))
            .get();
    final txns = await (db.select(
      db.txns,
    )..where((t) => t.assetId.isIn(qty) & t.deletedAt.isNull())).get();
    final points = <String, List<ValuePoint>>{};
    for (final v in values) {
      (points[v.assetId] ??= []).add(
        ValuePoint(unit: v.unit, date: v.valueDate, valueX100: v.valueX100),
      );
    }
    final basePrice = <String, int?>{};
    for (final id in qty) {
      final b = baselines.where((x) => x.targetId == id).firstOrNull;
      var price =
          b?.priceX100 ?? valueAt(points[id] ?? const [], plan.baselineDate);
      if (price == null) {
        final st = assetStateAt(
          valuation: Valuation.quantity,
          moves: [
            for (final t in txns)
              if (t.assetId == id && t.assetAction != null)
                AssetMove(
                  id: t.id,
                  date: t.date,
                  action: AssetAction.of(t.assetAction!),
                  amount: t.amount,
                  quantityX1e4: t.quantityX1e4,
                  parentId: t.parentTxnId,
                ),
          ],
          values: const [],
          date: plan.baselineDate,
        );
        if (st.quantityX1e4 > 0) {
          price = st.acquisitionCost * 1000000 ~/ st.quantityX1e4;
        }
      }
      basePrice[id] = price;
    }
    final rateOf = {for (final r in rates) r.targetId: r.annualRate};
    return (assetId, ym) {
      if (!qty.contains(assetId)) return null;
      final pts = points[assetId] ?? const <ValuePoint>[];
      final base = basePrice[assetId];
      if (base == null) return valueAt(pts, ym.lastDayString);
      return projectedPriceX100(
        values: pts,
        ym: ym,
        baselineDate: plan.baselineDate,
        baselinePriceX100: base,
        annualRatePercent: rateOf[assetId] ?? 0,
      );
    };
  }

  static RegTemplate regTemplateOf(TemplateRow t) => RegTemplate(
    id: t.id,
    name: t.name,
    kind: TxnKind.of(t.kind),
    amount: t.amount,
    categoryId: t.categoryId,
    accountId: t.accountId,
    toAccountId: t.toAccountId,
    assetId: t.assetId,
    assetAction: t.assetAction == null ? null : AssetAction.of(t.assetAction!),
    quantityX1e4: t.quantityX1e4,
    growthMode: GrowthMode.of(t.growthMode),
    growthRate: t.growthRate,
  );

  /// グループをプランに登録し、計画行を作る（設計書 6.3）。
  Future<String> registerGroup({
    required String planId,
    required String groupId,
    required YearMonth start,
    required YearMonth end,
    String? memo,
  }) {
    return db.transaction(() async {
      final now = stamp.now();
      final id = newId();
      await db
          .into(db.planGroups)
          .insert(
            PlanGroupsCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              planId: planId,
              groupId: groupId,
              startYm: start.toString(),
              endYm: end.toString(),
              memo: Value(memo),
            ),
          );
      final result = await preview(
        planId: planId,
        groupId: groupId,
        start: start,
        end: end,
      );
      await _insertGenerated(planId, id, result.lines, now);
      return id;
    });
  }

  /// 指定年月以降を、今のグループの内容で作り直す（設計書 6.4-1）。手で編集した行も置き換わる。
  Future<void> rebuildFrom(String registrationId, YearMonth from) {
    return db.transaction(() async {
      final reg = await _registration(registrationId);
      final now = stamp.now();
      await softDeleteRows(
        db,
        stamp,
        'plan_line',
        await _lineIds(registrationId, fromIndex: from.year * 12 + from.month),
      );
      final result = await preview(
        planId: reg.planId,
        groupId: reg.groupId,
        start: YearMonth.parse(reg.startYm),
        end: YearMonth.parse(reg.endYm),
        from: from,
      );
      await _insertGenerated(reg.planId, registrationId, result.lines, now);
    });
  }

  /// 年範囲を指定して計画行を削除する。登録は残す（設計書 6.4-2）。
  Future<void> deleteYearRange(
    String registrationId,
    int fromYear,
    int toYear,
  ) async {
    await softDeleteRows(
      db,
      stamp,
      'plan_line',
      await _lineIds(
        registrationId,
        fromIndex: fromYear * 12 + 1,
        toIndex: toYear * 12 + 12,
      ),
    );
  }

  /// 登録を取り消す：計画行ごと登録を削除する（設計書 6.4-3）。
  Future<void> cancelRegistration(String registrationId) {
    return db.transaction(() async {
      await softDeleteRows(
        db,
        stamp,
        'plan_line',
        await _lineIds(registrationId),
      );
      await softDeleteRows(db, stamp, 'plan_group', [registrationId]);
    });
  }

  Future<PlanGroupRow> _registration(String id) =>
      (db.select(db.planGroups)..where((r) => r.id.equals(id))).getSingle();

  Future<List<String>> _lineIds(
    String registrationId, {
    int? fromIndex,
    int? toIndex,
  }) async {
    final rows =
        await (db.select(db.planLines)..where((l) {
              var e =
                  l.source.equals(PlanLineSource.group.code) &
                  l.sourceId.equals(registrationId) &
                  l.deletedAt.isNull();
              final idx = l.year * const Constant(12) + l.month;
              if (fromIndex != null) {
                e = e & idx.isBiggerOrEqualValue(fromIndex);
              }
              if (toIndex != null) e = e & idx.isSmallerOrEqualValue(toIndex);
              return e;
            }))
            .get();
    return [for (final r in rows) r.id];
  }

  Future<void> _insertGenerated(
    String planId,
    String registrationId,
    List<GeneratedLine> lines,
    String now,
  ) async {
    await db.batch((b) {
      for (final l in lines) {
        final t = l.template;
        b.insert(
          db.planLines,
          PlanLinesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            year: l.ym.year,
            month: l.ym.month,
            kind: t.kind.code,
            amount: l.amount,
            categoryId: Value(t.kind == TxnKind.transfer ? null : t.categoryId),
            accountId: t.accountId!,
            toAccountId: Value(
              t.kind == TxnKind.transfer ? t.toAccountId : null,
            ),
            assetId: Value(t.assetId),
            assetAction: Value(t.assetAction?.code),
            memo: Value(t.name),
            source: PlanLineSource.group.code,
            sourceId: Value(registrationId),
            groupItemId: Value(l.itemId),
            quantityX1e4: Value(l.quantityX1e4),
          ),
        );
      }
    });
  }
}
