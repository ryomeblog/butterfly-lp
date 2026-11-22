import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/time.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'stamp.dart';

class AssetInput {
  const AssetInput({
    required this.planId,
    required this.name,
    required this.categoryId,
    required this.valuation,
    this.code,
    this.accountId,
  });

  final String planId;
  final String name;
  final String categoryId;
  final Valuation valuation;
  final String? code;
  final String? accountId;
}

/// 購入・売却・収益と一緒に入れる費用（税金・手数料など）の1行。
class CostLine {
  const CostLine({required this.categoryId, required this.amount, this.memo});

  final String categoryId;
  final int amount;
  final String? memo;
}

/// 購入・売却・収益・費用の入力（資産の画面。設計書 3.3）。
///
/// [date] があれば実績（txn）、[ym] があれば予定（手入力の計画行）として保存する。
class AssetFlowInput {
  const AssetFlowInput({
    required this.planId,
    required this.assetId,
    required this.action,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    this.date,
    this.ym,
    this.quantityX1e4,
    this.eventId,
    this.memo,
    this.costs = const [],
    this.valueAtBuyX100,
  }) : assert((date == null) != (ym == null));

  final String planId;
  final String assetId;
  final AssetAction action;
  final int amount;
  final String accountId;
  final String categoryId;
  final String? date;
  final YearMonth? ym;
  final int? quantityX1e4;
  final String? eventId;
  final String? memo;
  final List<CostLine> costs;

  /// 評価額の資産の購入：購入日の評価額として価値に記録する額（×100）
  final int? valueAtBuyX100;

  bool get isPlan => ym != null;
}

/// 資産を削除すると消える・紐づきが外れるものの件数。
class AssetDeletionImpact {
  const AssetDeletionImpact({
    required this.txns,
    required this.planLines,
    required this.values,
    required this.templates,
  });

  final int txns;
  final int planLines;
  final int values;
  final int templates;
}

/// 資産（プランごと。設計書 3.3・4.4 asset / asset_value）。
class AssetRepository {
  AssetRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  // ---- 資産 ----

  Stream<List<AssetRow>> watchAssets(String planId) =>
      (db.select(db.assets)
            ..where((a) => a.planId.equals(planId) & a.deletedAt.isNull())
            ..orderBy([
              (a) => OrderingTerm(expression: a.sortOrder),
              (a) => OrderingTerm(expression: a.createdAt),
            ]))
          .watch();

  Future<AssetRow?> getAsset(String id) =>
      (db.select(db.assets)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<String> createAsset(AssetInput input) async {
    final now = stamp.now();
    final id = newId();
    final m = db.assets.sortOrder.max();
    final q = db.selectOnly(db.assets)
      ..addColumns([m])
      ..where(
        db.assets.planId.equals(input.planId) & db.assets.deletedAt.isNull(),
      );
    final order = ((await q.getSingle()).read(m) ?? -1) + 1;
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: input.planId,
            name: input.name,
            categoryId: input.categoryId,
            valuation: input.valuation.code,
            code: Value(input.code),
            accountId: Value(input.accountId),
            sortOrder: order,
          ),
        );
    return id;
  }

  Future<void> updateAsset(String id, AssetInput input) async {
    await (db.update(db.assets)..where((a) => a.id.equals(id))).write(
      AssetsCompanion(
        name: Value(input.name),
        categoryId: Value(input.categoryId),
        valuation: Value(input.valuation.code),
        code: Value(input.code),
        accountId: Value(input.accountId),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  // ---- 価値 ----

  Stream<List<AssetValueRow>> watchValues(String assetId) =>
      (db.select(db.assetValues)
            ..where((v) => v.assetId.equals(assetId) & v.deletedAt.isNull())
            ..orderBy([
              (v) => OrderingTerm(
                expression: v.valueDate,
                mode: OrderingMode.desc,
              ),
            ]))
          .watch();

  /// プランの全資産の価値（資産一覧の評価に使う）。
  Stream<List<AssetValueRow>> watchPlanValues(String planId) {
    final q =
        db.select(db.assetValues).join([
          innerJoin(db.assets, db.assets.id.equalsExp(db.assetValues.assetId)),
        ])..where(
          db.assets.planId.equals(planId) &
              db.assets.deletedAt.isNull() &
              db.assetValues.deletedAt.isNull(),
        );
    return q.watch().map(
      (rows) => [for (final r in rows) r.readTable(db.assetValues)],
    );
  }

  /// 価値を指定する。同じ資産・同じ単位・同じ日（月）の価値は上書き（決定的ID。設計書 4.1）。
  Future<void> setValue(
    String assetId,
    String unit,
    String valueDate,
    int valueX100,
  ) async {
    final now = stamp.now();
    final id = assetValueId(assetId, valueDate);
    final existing = await (db.select(
      db.assetValues,
    )..where((v) => v.id.equals(id))).getSingleOrNull();
    await db
        .into(db.assetValues)
        .insertOnConflictUpdate(
          AssetValuesCompanion.insert(
            id: id,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            assetId: assetId,
            unit: unit,
            valueDate: valueDate,
            valueX100: valueX100,
            deletedAt: const Value(null),
          ),
        );
  }

  Future<void> deleteValue(String id) =>
      softDeleteRows(db, stamp, 'asset_value', [id]);

  // ---- 資産の動き ----

  /// その資産を指す実績（購入・売却・収益・費用）。
  Stream<List<TxnRow>> watchAssetTxns(String assetId) =>
      (db.select(db.txns)
            ..where((t) => t.assetId.equals(assetId) & t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
          .watch();

  /// その資産を指す予定。
  Stream<List<PlanLineRow>> watchAssetPlanLines(String assetId) =>
      (db.select(db.planLines)
            ..where((l) => l.assetId.equals(assetId) & l.deletedAt.isNull())
            ..orderBy([
              (l) => OrderingTerm(expression: l.year),
              (l) => OrderingTerm(expression: l.month),
            ]))
          .watch();

  /// プランの、資産を指す実績すべて（資産一覧）。
  Stream<List<TxnRow>> watchPlanAssetTxns(String planId) =>
      (db.select(db.txns)..where(
            (t) =>
                t.planId.equals(planId) &
                t.assetId.isNotNull() &
                t.deletedAt.isNull(),
          ))
          .watch();

  static AssetMove moveOf(TxnRow t) => AssetMove(
    id: t.id,
    date: t.date,
    action: AssetAction.of(t.assetAction!),
    amount: t.amount,
    quantityX1e4: t.quantityX1e4,
    parentId: t.parentTxnId,
  );

  static ValuePoint pointOf(AssetValueRow v) =>
      ValuePoint(unit: v.unit, date: v.valueDate, valueX100: v.valueX100);

  /// 購入・売却・収益・費用を、一緒に入れた費用とともに保存する。費用は元の動きを指す（parent_txn_id）。
  /// 評価額の資産の購入（実績）は、購入日の評価額として価値にも記録する（設計書 3.3）。
  Future<String> recordFlow(AssetFlowInput input) {
    return db.transaction(() async {
      final now = stamp.now();
      final kind = switch (input.action) {
        AssetAction.buy || AssetAction.cost => TxnKind.expense,
        AssetAction.sell || AssetAction.income => TxnKind.income,
      };
      final mainId = newId();
      if (input.isPlan) {
        await _insertLine(
          id: mainId,
          now: now,
          input: input,
          kind: kind,
          action: input.action,
          amount: input.amount,
          categoryId: input.categoryId,
          quantity: input.quantityX1e4,
          memo: input.memo,
        );
        for (final c in input.costs) {
          await _insertLine(
            id: newId(),
            now: now,
            input: input,
            kind: TxnKind.expense,
            action: AssetAction.cost,
            amount: c.amount,
            categoryId: c.categoryId,
            memo: c.memo,
          );
        }
        return mainId;
      }
      await _insertTxn(
        id: mainId,
        now: now,
        input: input,
        kind: kind,
        action: input.action,
        amount: input.amount,
        categoryId: input.categoryId,
        quantity: input.quantityX1e4,
        memo: input.memo,
      );
      for (final c in input.costs) {
        await _insertTxn(
          id: newId(),
          now: now,
          input: input,
          kind: TxnKind.expense,
          action: AssetAction.cost,
          amount: c.amount,
          categoryId: c.categoryId,
          memo: c.memo,
          parentId: mainId,
        );
      }
      if (input.action == AssetAction.buy && input.valueAtBuyX100 != null) {
        await setValue(
          input.assetId,
          'day',
          input.date!,
          input.valueAtBuyX100!,
        );
      }
      return mainId;
    });
  }

  Future<void> _insertTxn({
    required String id,
    required String now,
    required AssetFlowInput input,
    required TxnKind kind,
    required AssetAction action,
    required int amount,
    required String categoryId,
    int? quantity,
    String? memo,
    String? parentId,
  }) => db
      .into(db.txns)
      .insert(
        TxnsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          updatedBy: stamp.deviceId,
          planId: input.planId,
          date: input.date!,
          kind: kind.code,
          amount: amount,
          categoryId: Value(categoryId),
          accountId: input.accountId,
          assetId: Value(input.assetId),
          assetAction: Value(action.code),
          quantityX1e4: Value(quantity),
          eventId: Value(input.eventId),
          parentTxnId: Value(parentId),
          memo: Value(memo),
        ),
      );

  Future<void> _insertLine({
    required String id,
    required String now,
    required AssetFlowInput input,
    required TxnKind kind,
    required AssetAction action,
    required int amount,
    required String categoryId,
    int? quantity,
    String? memo,
  }) => db
      .into(db.planLines)
      .insert(
        PlanLinesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          updatedBy: stamp.deviceId,
          planId: input.planId,
          year: input.ym!.year,
          month: input.ym!.month,
          kind: kind.code,
          amount: amount,
          categoryId: Value(categoryId),
          accountId: input.accountId,
          assetId: Value(input.assetId),
          assetAction: Value(action.code),
          quantityX1e4: Value(quantity),
          eventId: Value(input.eventId),
          memo: Value(memo),
          source: PlanLineSource.manual.code,
        ),
      );

  // ---- 削除 ----

  Future<AssetDeletionImpact> deletionImpact(String assetId) async {
    Future<int> count(String table) async =>
        (await db
                .customSelect(
                  'SELECT COUNT(*) AS c FROM $table WHERE asset_id = ? AND deleted_at IS NULL',
                  variables: [Variable.withString(assetId)],
                )
                .getSingle())
            .read<int>('c');
    return AssetDeletionImpact(
      txns: await count('txn'),
      planLines: await count('plan_line'),
      values: await count('asset_value'),
      templates: await count('template'),
    );
  }

  /// 資産の削除（設計書 3.7）。価値は一緒に削除する。実績・予定は [deleteTxns]・[deletePlanLines] で
  /// 削除するか選び、削除しないものは資産との紐づき（asset_id・asset_action・quantity_x1e4）だけを外す。
  /// その資産を指すテンプレートは残し、資産の欄を空にする。
  Future<void> deleteAsset(
    String assetId, {
    required bool deleteTxns,
    required bool deletePlanLines,
  }) {
    return db.transaction(() async {
      final now = stamp.now();
      Future<List<String>> ids(String table) async => [
        for (final r
            in await db
                .customSelect(
                  'SELECT id FROM $table WHERE asset_id = ? AND deleted_at IS NULL',
                  variables: [Variable.withString(assetId)],
                )
                .get())
          r.read<String>('id'),
      ];
      Future<void> unlink(String table) => db.customUpdate(
        'UPDATE $table SET asset_id = NULL, asset_action = NULL, quantity_x1e4 = NULL, '
        'updated_at = ?, updated_by = ? WHERE asset_id = ? AND deleted_at IS NULL',
        variables: [
          Variable.withString(now),
          Variable.withString(stamp.deviceId),
          Variable.withString(assetId),
        ],
        updates: {db.allTables.firstWhere((t) => t.actualTableName == table)},
        updateKind: UpdateKind.update,
      );
      await softDeleteRows(db, stamp, 'asset_value', await ids('asset_value'));
      if (deleteTxns) {
        await softDeleteRows(db, stamp, 'txn', await ids('txn'));
      } else {
        await unlink('txn');
      }
      if (deletePlanLines) {
        await softDeleteRows(db, stamp, 'plan_line', await ids('plan_line'));
      } else {
        await unlink('plan_line');
      }
      await unlink('template');
      final rates =
          await (db.select(db.planRates)..where(
                (r) =>
                    r.targetType.equals(TargetType.asset) &
                    r.targetId.equals(assetId),
              ))
              .get();
      await softDeleteRows(db, stamp, 'plan_rate', [
        for (final r in rates) r.id,
      ]);
      final baselines =
          await (db.select(db.planBaselines)..where(
                (r) =>
                    r.targetType.equals(TargetType.asset) &
                    r.targetId.equals(assetId),
              ))
              .get();
      await softDeleteRows(db, stamp, 'plan_baseline', [
        for (final r in baselines) r.id,
      ]);
      await softDeleteRows(db, stamp, 'asset', [assetId]);
    });
  }
}
