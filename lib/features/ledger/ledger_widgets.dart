import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/calc/ledger.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';

/// 名前を引くための表。削除済み（参照切れ）は「削除済み○○」と出す（設計書 5.4）。
class Lookup {
  Lookup(List<CategoryRow> categories, List<AccountRow> accounts)
    : _cats = {for (final c in categories) c.id: c},
      _accounts = {for (final a in accounts) a.id: a};

  final Map<String, CategoryRow> _cats;
  final Map<String, AccountRow> _accounts;

  CategoryRow? category(String? id) => id == null ? null : _cats[id];

  String categoryName(String? id) =>
      id == null ? 'カテゴリなし' : (_cats[id]?.name ?? '削除済みカテゴリ');

  String categoryColor(String? id) => _cats[id]?.color ?? paletteGray;

  String accountName(String? id) =>
      id == null ? '—' : (_accounts[id]?.name ?? '削除済み口座');
}

/// 収入・支出・収支の3つを並べる。
class TotalsRow extends StatelessWidget {
  const TotalsRow({super.key, required this.title, required this.totals});

  final String title;
  final LedgerTotals totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget cell(String label, String value, Color? color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                cell('収入', formatYen(totals.income), scheme.incomeColor),
                cell('支出', formatYen(totals.expense), scheme.expenseColor),
                cell('収支', formatYenSigned(totals.net), null),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// カテゴリ別の円グラフ。
class CategoryPie extends StatelessWidget {
  const CategoryPie({super.key, required this.totals, required this.lookup});

  final List<CategoryTotal> totals;
  final Lookup lookup;

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('この期間の実績はありません')),
      );
    }
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 1,
          centerSpaceRadius: 48,
          sections: [
            for (final c in totals)
              PieChartSectionData(
                value: c.amount.toDouble(),
                color: colorOf(lookup.categoryColor(c.categoryId)),
                radius: 48,
                title: c.ratio >= 0.08 ? lookup.categoryName(c.categoryId) : '',
                titleStyle: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 実績1件の行。押すと編集。
class TxnTile extends StatelessWidget {
  const TxnTile({
    super.key,
    required this.txn,
    required this.lookup,
    this.showDate = true,
  });

  final LedgerTxn txn;
  final Lookup lookup;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTransfer = txn.kind == TxnKind.transfer;
    final title = isTransfer
        ? '振替　${lookup.accountName(txn.accountId)} → ${lookup.accountName(txn.toAccountId)}'
        : lookup.categoryName(txn.categoryId);
    final sub = [
      if (showDate) '${txn.month}/${txn.day}',
      if (!isTransfer) lookup.accountName(txn.accountId),
      if (txn.memo != null) txn.memo!,
    ].join('・');
    final amount = switch (txn.kind) {
      TxnKind.income => formatYenSigned(txn.amount),
      TxnKind.expense => formatYenSigned(-txn.amount),
      TxnKind.transfer => formatYen(txn.amount),
    };
    return ListTile(
      dense: true,
      leading: isTransfer
          ? const Icon(Icons.swap_horiz)
          : ColorDot(lookup.categoryColor(txn.categoryId)),
      title: Text(title),
      subtitle: sub.isEmpty ? null : Text(sub),
      trailing: Text(
        amount,
        style: TextStyle(
          color: switch (txn.kind) {
            TxnKind.income => scheme.incomeColor,
            TxnKind.expense => scheme.expenseColor,
            TxnKind.transfer => null,
          },
        ),
      ),
      onTap: () => context.push('/ledger/txn/${txn.id}'),
    );
  }
}

/// 「＜ 2026年 ＞」の期間の切り替え。
class PeriodNav extends StatelessWidget {
  const PeriodNav({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        key: const Key('period-prev'),
        onPressed: onPrev,
        icon: const Icon(Icons.chevron_left),
      ),
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      IconButton(
        key: const Key('period-next'),
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}
