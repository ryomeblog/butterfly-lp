import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/time.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/calc/balance.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'stamp.dart';

/// 新しいプランの入力内容。
class NewPlanInput {
  const NewPlanInput({
    required this.name,
    required this.startYear,
    required this.protagonistName,
    required this.protagonistBirthDate,
    required this.protagonistLifeExpectancy,
    this.createCashAccount = false,
  });

  final String name;
  final int startYear;
  final String protagonistName;
  final String protagonistBirthDate;
  final int protagonistLifeExpectancy;

  /// 初回起動のとき、口座「現金」（初期残高0円・基準日は作成日）を作る（設計書 7.1）。
  final bool createCashAccount;
}

class PlanRepository {
  PlanRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  Stream<List<PlanRow>> watchPlans() =>
      (db.select(db.plans)
            ..where((p) => p.deletedAt.isNull())
            ..orderBy([
              (p) => OrderingTerm(expression: p.sortOrder),
              (p) => OrderingTerm(expression: p.createdAt),
            ]))
          .watch();

  Future<PlanRow?> getPlan(String id) => (db.select(
    db.plans,
  )..where((p) => p.id.equals(id) & p.deletedAt.isNull())).getSingleOrNull();

  Stream<List<FamilyMemberRow>> watchMembers(String planId) =>
      (db.select(db.familyMembers)
            ..where((m) => m.planId.equals(planId) & m.deletedAt.isNull())
            ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]))
          .watch();

  Future<List<FamilyMemberRow>> getMembers(String planId) =>
      (db.select(db.familyMembers)
            ..where((m) => m.planId.equals(planId) & m.deletedAt.isNull())
            ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]))
          .get();

  /// プランを作る。主人公（本人）を作り、計画線の起点（設計書 4.5 plan_baseline）を計算して保存する。
  Future<String> createPlan(NewPlanInput input) {
    return db.transaction(() async {
      final now = stamp.now();
      final today = todayString();
      final planId = newId();
      final memberId = newId();

      if (input.createCashAccount) {
        final count = await _countLiveAccounts();
        await db
            .into(db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                updatedBy: stamp.deviceId,
                name: '現金',
                kind: AccountKind.cash.code,
                initialBalance: 0,
                initialDate: today,
                sortOrder: count,
              ),
            );
      }

      final maxOrder = await _maxPlanOrder();
      await db
          .into(db.plans)
          .insert(
            PlansCompanion.insert(
              id: planId,
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              name: input.name,
              protagonistMemberId: memberId,
              startYear: input.startYear,
              baselineDate: today,
              defaultInflationRate: 0,
              sortOrder: maxOrder + 1,
            ),
          );
      await db
          .into(db.familyMembers)
          .insert(
            FamilyMembersCompanion.insert(
              id: memberId,
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              planId: planId,
              name: input.protagonistName,
              relation: Relation.self.code,
              birthDate: input.protagonistBirthDate,
              lifeExpectancy: input.protagonistLifeExpectancy,
              sortOrder: 0,
            ),
          );
      await writeAccountBaselines(planId, today);
      await writeAssetBaselines(planId, today);
      return planId;
    });
  }

  /// 起点日時点の口座残高を、そのプランの実績から計算して plan_baseline に保存する。
  /// （資産の起点は資産の実装（M5）で加える）
  Future<void> writeAccountBaselines(String planId, String baselineDate) async {
    final now = stamp.now();
    final accounts = await (db.select(
      db.accounts,
    )..where((a) => a.deletedAt.isNull())).get();
    final txns =
        await (db.select(db.txns)..where(
              (t) =>
                  t.planId.equals(planId) &
                  t.deletedAt.isNull() &
                  t.date.isSmallerOrEqualValue(baselineDate),
            ))
            .get();
    final balanceTxns = txns.map(
      (t) => BalanceTxn(
        date: t.date,
        kind: TxnKind.of(t.kind),
        amount: t.amount,
        accountId: t.accountId,
        toAccountId: t.toAccountId,
      ),
    );
    for (final a in accounts) {
      final balance = accountBalanceAt(
        BalanceAccount(
          id: a.id,
          initialBalance: a.initialBalance,
          initialDate: a.initialDate,
        ),
        balanceTxns,
        baselineDate,
      );
      await db
          .into(db.planBaselines)
          .insertOnConflictUpdate(
            PlanBaselinesCompanion.insert(
              id: planTargetId(planId, TargetType.account, a.id),
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              planId: planId,
              targetType: TargetType.account,
              targetId: a.id,
              balance: Value(balance),
              deletedAt: const Value(null),
            ),
          );
    }
  }

  /// 起点日時点の資産の状態を、そのプランの実績と価値から計算して plan_baseline に保存する（設計書 4.5）。
  /// 数量×単価の資産は保有数と単価（価値がなければ取得価額÷保有数）、評価額の資産は評価額。
  Future<void> writeAssetBaselines(String planId, String baselineDate) async {
    final now = stamp.now();
    final assets = await (db.select(
      db.assets,
    )..where((a) => a.planId.equals(planId) & a.deletedAt.isNull())).get();
    for (final a in assets) {
      final moves = [
        for (final t
            in await (db.select(db.txns)..where(
                  (t) =>
                      t.assetId.equals(a.id) &
                      t.deletedAt.isNull() &
                      t.assetAction.isNotNull(),
                ))
                .get())
          AssetMove(
            id: t.id,
            date: t.date,
            action: AssetAction.of(t.assetAction!),
            amount: t.amount,
            quantityX1e4: t.quantityX1e4,
            parentId: t.parentTxnId,
          ),
      ];
      final points = [
        for (final v in await (db.select(
          db.assetValues,
        )..where((v) => v.assetId.equals(a.id) & v.deletedAt.isNull())).get())
          ValuePoint(unit: v.unit, date: v.valueDate, valueX100: v.valueX100),
      ];
      final valuation = Valuation.of(a.valuation);
      final st = assetStateAt(
        valuation: valuation,
        moves: moves,
        values: points,
        date: baselineDate,
      );
      final isQty = valuation == Valuation.quantity;
      final price = isQty
          ? (valueAt(points, baselineDate) ??
                (st.quantityX1e4 > 0
                    ? st.acquisitionCost * 1000000 ~/ st.quantityX1e4
                    : null))
          : null;
      await db
          .into(db.planBaselines)
          .insertOnConflictUpdate(
            PlanBaselinesCompanion.insert(
              id: planTargetId(planId, TargetType.asset, a.id),
              createdAt: now,
              updatedAt: now,
              updatedBy: stamp.deviceId,
              planId: planId,
              targetType: TargetType.asset,
              targetId: a.id,
              balance: Value(isQty ? null : st.valuation),
              quantityX1e4: Value(isQty ? st.quantityX1e4 : null),
              priceX100: Value(price),
              deletedAt: const Value(null),
            ),
          );
    }
  }

  Future<int> _countLiveAccounts() async {
    final c = db.accounts.id.count();
    final q = db.selectOnly(db.accounts)
      ..addColumns([c])
      ..where(db.accounts.deletedAt.isNull());
    return (await q.getSingle()).read(c) ?? 0;
  }

  Future<int> _maxPlanOrder() async {
    final m = db.plans.sortOrder.max();
    final q = db.selectOnly(db.plans)
      ..addColumns([m])
      ..where(db.plans.deletedAt.isNull());
    return (await q.getSingle()).read(m) ?? -1;
  }
}
