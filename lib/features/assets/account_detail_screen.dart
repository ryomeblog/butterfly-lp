import 'package:clock/clock.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/repositories/txn_repository.dart';
import '../../domain/calc/account_series.dart';
import '../../domain/calc/balance.dart';
import '../../domain/calc/ledger.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/widgets.dart';

/// 口座詳細（ワイヤーフレーム AccountDetail）：残高推移（月末）と口座の実績一覧。表示プランの実績で計算する。
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(selectedPlanProvider).value;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final account = accounts.where((a) => a.id == accountId).firstOrNull;
    if (plan == null || account == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('この口座は見つかりません')),
      );
    }
    final rows = ref.watch(
      txnsProvider((planId: plan.id, from: null, to: null)),
    );
    final mine = [
      for (final r in rows.value ?? const [])
        if (r.accountId == accountId || r.toAccountId == accountId) r,
    ];
    final ba = BalanceAccount(
      id: account.id,
      initialBalance: account.initialBalance,
      initialDate: account.initialDate,
    );
    final now = YearMonth.ofDate(clock.now());
    final start = YearMonth.ofDateString(account.initialDate);
    final from = now.addMonths(-11) > start ? now.addMonths(-11) : start;
    final series = monthEndBalances(
      ba,
      [for (final r in mine) balanceTxnOf(r)],
      from,
      now,
    );
    final current = series.isEmpty ? account.initialBalance : series.last.$2;
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      accounts,
    );
    final init = parseDate(account.initialDate);

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${now.year}年${now.month}月末の残高（${plan.name}の実績）'),
          Text(
            formatYen(current),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '初期残高 ${formatYen(account.initialBalance)}（${init.year}/${init.month}/${init.day} 時点）',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SectionTitle('残高推移（月末）'),
          if (series.length >= 2)
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= series.length || i % 3 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${series[i].$1.month}月',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (final (i, e) in series.indexed)
                          FlSpot(i.toDouble(), e.$2.toDouble()),
                      ],
                      color: Theme.of(context).colorScheme.primary,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text('グラフは2か月分以上の記録から表示します。'),
          const SectionTitle('この口座の実績'),
          for (final t in newestFirst([for (final r in mine) ledgerTxnOf(r)]))
            TxnTile(txn: t, lookup: lookup),
          if (mine.isEmpty) const Text('実績はまだありません'),
        ],
      ),
    );
  }
}

/// 資産タブ（M3 では口座の残高だけ。資産は M5）。
class AssetsTabM3 extends ConsumerWidget {
  const AssetsTabM3({super.key, required this.onOpenAccount});

  final void Function(String accountId) onOpenAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(selectedPlanProvider).value;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    if (plan == null) return const Center(child: CircularProgressIndicator());
    final rows = ref.watch(
      txnsProvider((planId: plan.id, from: null, to: null)),
    );
    final txns = [for (final r in rows.value ?? const []) balanceTxnOf(r)];
    final end = YearMonth.ofDate(clock.now()).lastDayString;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('今月末時点の口座残高（${plan.name}の実績で計算）'),
        for (final a in accounts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(a.name),
            trailing: Text(
              formatYen(
                accountBalanceAt(
                  BalanceAccount(
                    id: a.id,
                    initialBalance: a.initialBalance,
                    initialDate: a.initialDate,
                  ),
                  txns,
                  end,
                ),
              ),
            ),
            onTap: () => onOpenAccount(a.id),
          ),
        const SizedBox(height: 16),
        Text(
          '年・年月の切り替え、資産の評価額と合計は M5 で実装します。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
