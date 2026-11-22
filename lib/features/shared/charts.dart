import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 折れ線1本。値が null の点は線を切る。
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.values,
    required this.color,
    this.dashed = false,
  });

  final String label;
  final List<int?> values;
  final Color color;
  final bool dashed;
}

/// 「¥1.2億」「¥3,400万」のような短い金額。
String shortYen(num v) {
  final a = v.abs();
  final sign = v < 0 ? '−' : '';
  if (a >= 100000000) return '$sign¥${(a / 100000000).toStringAsFixed(1)}億';
  if (a >= 10000) return '$sign¥${(a / 10000).round()}万';
  return '$sign¥${a.round()}';
}

/// 折れ線グラフ（ホームのカード・プラン詳細・資産詳細）。
///
/// [markers] は「点の番号→イベント名」で、縦の点線と名前を出す。点が多いときは横にスクロールする。
class SeriesChart extends StatelessWidget {
  const SeriesChart({
    super.key,
    required this.xLabels,
    required this.series,
    this.markers = const {},
    this.height = 200,
    this.pointWidth = 14,
    this.labelEvery,
  });

  final List<String> xLabels;
  final List<ChartSeries> series;
  final Map<int, String> markers;
  final double height;

  /// 1点あたりの最小の幅。全体が画面より広ければ横スクロールにする
  final double pointWidth;

  /// x軸の目盛りを何点おきに出すか（null なら自動）
  final int? labelEvery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = xLabels.length;
    if (n < 2) {
      return SizedBox(
        height: height / 2,
        child: const Center(child: Text('グラフに出す期間がありません')),
      );
    }
    final every = labelEvery ?? (n / 5).ceil().clamp(1, 1000);
    final chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: scheme.error.withValues(alpha: 0.6),
              dashArray: [4, 4],
            ),
          ],
          verticalLines: [
            for (final e in markers.entries)
              VerticalLine(
                x: e.key.toDouble(),
                color: scheme.outline,
                dashArray: [2, 3],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: TextStyle(fontSize: 10, color: scheme.onSurface),
                  labelResolver: (_) => '◇${e.value}',
                ),
              ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, meta) =>
                  Text(shortYen(v), style: const TextStyle(fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 32,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= n || i % every != 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  xLabels[i],
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          for (final s in series)
            LineChartBarData(
              spots: [
                for (var i = 0; i < s.values.length; i++)
                  s.values[i] == null
                      ? FlSpot.nullSpot
                      : FlSpot(i.toDouble(), s.values[i]!.toDouble()),
              ],
              color: s.color,
              barWidth: 2,
              dashArray: s.dashed ? [6, 4] : null,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final width = n * pointWidth;
        if (width <= c.maxWidth) return SizedBox(height: height, child: chart);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, height: height, child: chart),
        );
      },
    );
  }
}

/// 凡例。
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.series, this.withEvents = false});

  final List<ChartSeries> series;
  final bool withEvents;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    children: [
      for (final s in series)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 3, color: s.color),
            const SizedBox(width: 4),
            Text(
              '${s.label}${s.dashed ? '（破線）' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      if (withEvents)
        Text('◇ イベント', style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
