import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time.dart';
import '../data/db/database.dart';
import '../data/repositories/asset_repository.dart';
import '../data/repositories/txn_repository.dart';
import '../domain/calc/asset_valuation.dart';
import '../domain/calc/balance.dart';
import '../domain/calc/simulation.dart';
import '../domain/models/enums.dart';
import '../features/shared/plan_period.dart';
import 'providers.dart';

final baselinesProvider = StreamProvider.family<List<PlanBaselineRow>, String>(
  (ref, planId) =>
      ref.watch(rateFamilyRepositoryProvider).watchBaselines(planId),
);

/// プランの計画線（設計書 6.5）。読み込み中は null。
///
/// 起点（plan_baseline）がない口座・資産（プラン作成後に追加したもの）は、
/// 起点日時点のそのプランの実績から計算した値を起点にする。
final simulationProvider = Provider.family<SimResult?, String>((ref, planId) {
  final plan = (ref.watch(plansProvider).value ?? const <PlanRow>[])
      .where((p) => p.id == planId)
      .firstOrNull;
  final members = ref.watch(membersProvider(planId)).value;
  final accounts = ref.watch(accountsProvider).value;
  final assets = ref.watch(assetsProvider(planId)).value;
  final values = ref.watch(planAssetValuesProvider(planId)).value;
  final baselines = ref.watch(baselinesProvider(planId)).value;
  final rates = ref.watch(ratesProvider(planId)).value;
  final lines = ref
      .watch(planLinesProvider((planId: planId, from: null, to: null)))
      .value;
  final txns = ref
      .watch(txnsProvider((planId: planId, from: null, to: null)))
      .value;
  if ([
    plan,
    members,
    accounts,
    assets,
    values,
    baselines,
    rates,
    lines,
    txns,
  ].contains(null)) {
    return null;
  }
  final period = planPeriod(plan!, members!);
  if (period == null) return null;
  final baselineDate = plan.baselineDate;
  final rateOf = {
    for (final r in rates!) '${r.targetType}:${r.targetId}': r.annualRate,
  };
  final baseOf = {
    for (final b in baselines!) '${b.targetType}:${b.targetId}': b,
  };
  final balanceTxns = [for (final t in txns!) balanceTxnOf(t)];

  final simAccounts = [
    for (final a in accounts!)
      SimAccount(
        id: a.id,
        balance:
            baseOf['${TargetType.account}:${a.id}']?.balance ??
            accountBalanceAt(
              BalanceAccount(
                id: a.id,
                initialBalance: a.initialBalance,
                initialDate: a.initialDate,
              ),
              balanceTxns,
              baselineDate,
            ),
        cashLike: AccountKind.of(a.kind).isCashLike,
        annualRate: rateOf['${TargetType.account}:${a.id}'] ?? 0,
      ),
  ];

  final simAssets = <SimAsset>[];
  for (final a in assets!) {
    final valuation = Valuation.of(a.valuation);
    final points = [
      for (final v in values!)
        if (v.assetId == a.id) AssetRepository.pointOf(v),
    ];
    final b = baseOf['${TargetType.asset}:${a.id}'];
    int qty;
    int? price;
    int balance;
    if (b != null) {
      qty = b.quantityX1e4 ?? 0;
      price = b.priceX100;
      balance = b.balance ?? 0;
    } else {
      final st = assetStateAt(
        valuation: valuation,
        moves: [
          for (final t in txns)
            if (t.assetId == a.id && t.assetAction != null)
              AssetRepository.moveOf(t),
        ],
        values: points,
        date: baselineDate,
      );
      qty = st.quantityX1e4;
      price =
          valueAt(points, baselineDate) ??
          (qty > 0 ? st.acquisitionCost * 1000000 ~/ qty : null);
      balance = st.valuation;
    }
    simAssets.add(
      SimAsset(
        id: a.id,
        valuation: valuation,
        quantityX1e4: qty,
        priceX100: price,
        balance: balance,
        annualRate: rateOf['${TargetType.asset}:${a.id}'] ?? 0,
        values: points,
      ),
    );
  }

  return simulatePlan(
    baselineDate: baselineDate,
    end: period.end,
    accounts: simAccounts,
    assets: simAssets,
    lines: [
      for (final l in lines!)
        SimLine(
          ym: YearMonth(l.year, l.month),
          kind: TxnKind.of(l.kind),
          amount: l.amount,
          accountId: l.accountId,
          toAccountId: l.toAccountId,
          assetId: l.assetId,
          assetAction: l.assetAction == null
              ? null
              : AssetAction.of(l.assetAction!),
          quantityX1e4: l.quantityX1e4,
        ),
    ],
  );
});
