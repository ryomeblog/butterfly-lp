import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../domain/calc/compare.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/charts.dart';
import '../shared/widgets.dart';

/// 支出／収入／収支の切り替え。
enum CompareKind { expense, income, net }

extension CompareKindLabel on CompareKind {
  String get label => switch (this) {
    CompareKind.expense => '支出',
    CompareKind.income => '収入',
    CompareKind.net => '収支',
  };
}

/// 予定・実績・差の表（収入・支出・収支）。差＝実績−予定。実績を「—」にするときは [noActual]。
class CompareTable extends StatelessWidget {
  const CompareTable({super.key, required this.totals, this.noActual = false});

  final CompareTotals totals;
  final bool noActual;

  @override
  Widget build(BuildContext context) {
    TableRow row(String label, PlanActual v, {bool signed = false}) => TableRow(
      children: [
        Text(label),
        Text(
          signed ? formatYenSigned(v.planned) : formatYen(v.planned),
          textAlign: TextAlign.end,
        ),
        Text(
          noActual
              ? '—'
              : (signed ? formatYenSigned(v.actual) : formatYen(v.actual)),
          textAlign: TextAlign.end,
        ),
        Text(
          noActual ? '—' : formatYenSigned(v.diff),
          textAlign: TextAlign.end,
        ),
      ],
    );
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          children: [
            Text(''),
            Text('予定', textAlign: TextAlign.end),
            Text('実績', textAlign: TextAlign.end),
            Text('差', textAlign: TextAlign.end),
          ],
        ),
        row('収入　', totals.income),
        row('支出　', totals.expense),
        row('収支　', totals.net, signed: true),
      ],
    );
  }
}

/// 予定と実績の棒グラフ（月ごと・年ごと）。棒を押すと [onTap]。
class PlanActualBars extends StatelessWidget {
  const PlanActualBars({
    super.key,
    required this.labels,
    required this.planned,
    required this.actual,
    this.showPlan = true,
    this.showActual = true,
    this.onTap,
    this.groupWidth = 26,
  });

  final List<String> labels;
  final List<int> planned;
  final List<int?> actual;
  final bool showPlan;
  final bool showActual;
  final ValueChanged<int>? onTap;
  final double groupWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chart = BarChart(
      BarChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: onTap != null,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.spot != null) {
              onTap?.call(response!.spot!.touchedBarGroupIndex);
            }
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, m) =>
                  Text(shortYen(v), style: const TextStyle(fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) =>
                  Text(labels[v.toInt()], style: const TextStyle(fontSize: 9)),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < labels.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 2,
              barRods: [
                if (showPlan)
                  BarChartRodData(
                    toY: planned[i].toDouble(),
                    color: scheme.primary.withValues(alpha: 0.35),
                    width: 7,
                  ),
                if (showActual)
                  BarChartRodData(
                    toY: (actual[i] ?? 0).toDouble(),
                    color: scheme.primary,
                    width: 7,
                  ),
              ],
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            if (showPlan)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: scheme.primary.withValues(alpha: 0.35),
                  ),
                  const Text(' 予定', style: TextStyle(fontSize: 12)),
                ],
              ),
            if (showActual)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: scheme.primary),
                  const Text(' 実績', style: TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, c) {
            final width = labels.length * groupWidth;
            if (width <= c.maxWidth) return SizedBox(height: 180, child: chart);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: width, height: 180, child: chart),
            );
          },
        ),
      ],
    );
  }
}

/// カテゴリ1つ＝1枚のカード：予定と実績を横棒・金額・ウェイトで上下に並べ、差（超過／余り）を示す（設計書 3.8）。
class CategoryCompareCard extends StatelessWidget {
  const CategoryCompareCard({
    super.key,
    required this.item,
    required this.lookup,
    required this.maxAmount,
    this.showPlan = true,
    this.showActual = true,
    this.children = const [],
  });

  final CategoryCompare item;
  final Lookup lookup;
  final int maxAmount;
  final bool showPlan;
  final bool showActual;

  /// 開いたときの中身（月ごと・明細）。空なら開けない
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diff = item.diff;
    final diffLabel = !(showPlan && showActual)
        ? ''
        : diff > 0
        ? '${formatYenSigned(diff)} 超過'
        : diff < 0
        ? '${formatYenSigned(diff)} 余り'
        : '差なし';
    Widget bar(String label, int amount, double weight, Color color) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 10,
                  width: maxAmount == 0 ? 0 : c.maxWidth * amount / maxAmount,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              formatYen(amount),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${(weight * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ColorDot(lookup.categoryColor(item.categoryId)),
            const SizedBox(width: 8),
            Expanded(child: Text(lookup.categoryName(item.categoryId))),
            Text(
              diffLabel,
              style: TextStyle(
                color: diff > 0 ? scheme.error : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (showPlan)
          bar(
            '予定',
            item.planned,
            item.plannedWeight,
            scheme.primary.withValues(alpha: 0.35),
          ),
        if (showActual)
          bar('実績', item.actual, item.actualWeight, scheme.primary),
      ],
    );
    return Card(
      key: Key('cmp-card-${lookup.categoryName(item.categoryId)}'),
      child: children.isEmpty
          ? Padding(padding: const EdgeInsets.all(12), child: header)
          : ExpansionTile(
              shape: const Border(),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: header,
              children: children,
            ),
    );
  }
}
