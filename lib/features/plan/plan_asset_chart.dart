import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/simulation.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../domain/calc/simulation.dart';
import '../events/event_common.dart';
import '../shared/charts.dart';
import '../shared/plan_period.dart';
import '../shared/widgets.dart';

/// プラン詳細の資産推移（計画線のみ）。年単位と月単位を切り替える（設計書 3.6）。
class PlanAssetChart extends ConsumerStatefulWidget {
  const PlanAssetChart({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanAssetChart> createState() => _PlanAssetChartState();
}

class _PlanAssetChartState extends ConsumerState<PlanAssetChart> {
  bool _byYear = true;
  int _year = clock.now().year;

  @override
  Widget build(BuildContext context) {
    final plan = (ref.watch(plansProvider).value ?? const <PlanRow>[])
        .where((p) => p.id == widget.planId)
        .firstOrNull;
    final members =
        ref.watch(membersProvider(widget.planId)).value ??
        const <FamilyMemberRow>[];
    final events =
        ref.watch(eventsProvider(widget.planId)).value ??
        const <PlanEventRow>[];
    final sim = ref.watch(simulationProvider(widget.planId));
    if (plan == null || sim == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final period = planPeriod(plan, members)!;
    final protagonist = protagonistOf(plan, members);
    final first = sim.months.isEmpty ? period.end : sim.months.first.ym;
    final year = _year.clamp(first.year, period.end.year);
    String age(int y) =>
        protagonist == null ? '' : '\n${ageInYear(protagonist, y)}歳';

    final List<String> labels;
    final List<int?> values;
    final markers = <int, String>{};
    if (_byYear) {
      final years = [for (var y = first.year; y <= period.end.year; y++) y];
      labels = [for (final y in years) '$y${age(y)}'];
      values = [for (final y in years) sim.yearEnd(y)?.total];
      for (final e in events) {
        final i = years.indexOf(e.year);
        if (i >= 0) {
          markers[i] = markers.containsKey(i)
              ? '${markers[i]}・${e.title}'
              : e.title;
        }
      }
    } else {
      labels = [for (var m = 1; m <= 12; m++) '$m月'];
      values = [
        for (var m = 1; m <= 12; m++) sim.at(YearMonth(year, m))?.total,
      ];
      for (final e in events.where((e) => e.year == year)) {
        markers[e.month - 1] = e.title;
      }
    }
    final last = sim.months.isEmpty ? null : sim.months.last;
    final shortage = sim.firstShortage;
    final scheme = Theme.of(context).colorScheme;
    final series = [
      ChartSeries(
        label: '計画線',
        values: values,
        color: scheme.primary,
        dashed: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _byYear ? '資産推移（生涯・年末）' : '資産推移（$year年・月末）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('年単位')),
                ButtonSegment(value: false, label: Text('月単位')),
              ],
              selected: {_byYear},
              onSelectionChanged: (v) => setState(() => _byYear = v.first),
            ),
          ],
        ),
        if (!_byYear)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: year > first.year
                    ? () => setState(() => _year = year - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '$year年${protagonist == null ? '' : '（${protagonist.name} ${ageInYear(protagonist, year)}歳）'}',
              ),
              IconButton(
                onPressed: year < period.end.year
                    ? () => setState(() => _year = year + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ChartLegend(series: series, withEvents: true),
        const SizedBox(height: 8),
        SeriesChart(
          key: const Key('plan-asset-chart'),
          xLabels: labels,
          series: series,
          markers: markers,
          pointWidth: _byYear ? 18 : 24,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _Metric(
              '寿命時の総資産',
              last == null ? '—' : formatYen(last.total),
              key: const Key('lifetime-total'),
            ),
            _Metric(
              '最大の総資産',
              sim.maxTotal == null ? '—' : formatYen(sim.maxTotal!),
            ),
          ],
        ),
        if (shortage != null) ...[
          const SizedBox(height: 12),
          WarningBox(
            key: const Key('shortage'),
            message:
                '資金不足：計画線で ${shortage.year}年${shortage.month}月'
                '${protagonist == null ? '' : '（${protagonist.name} ${ageInYear(protagonist, shortage.year)}歳）'}'
                'に現金系口座の合計がマイナスになります。',
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '計画線＝起点日（${plan.baselineDate.replaceAll('-', '/')}）の残高と評価額＋計画行＋想定利回り。実績は使いません。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

/// ホームのカード用の要約（寿命時の総資産・資金不足）。
({int? lifetimeTotal, YearMonth? shortage}) planSummary(SimResult? sim) => (
  lifetimeTotal: sim == null || sim.months.isEmpty
      ? null
      : sim.months.last.total,
  shortage: sim?.firstShortage,
);
