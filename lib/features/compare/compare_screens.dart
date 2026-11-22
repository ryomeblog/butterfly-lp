import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/simulation.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/calc/compare.dart';
import '../../domain/calc/event_matching.dart';
import '../../domain/models/enums.dart';
import '../events/event_common.dart';
import '../ledger/ledger_state.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/charts.dart';
import '../shared/plan_period.dart';
import '../shared/widgets.dart';
import '../shared/ym_picker.dart';
import 'compare_widgets.dart';

int _valueOf(MatchItem x, CompareKind k) => switch (k) {
  CompareKind.expense => x.kind == TxnKind.expense ? x.amount : 0,
  CompareKind.income => x.kind == TxnKind.income ? x.amount : 0,
  CompareKind.net =>
    x.kind == TxnKind.income
        ? x.amount
        : (x.kind == TxnKind.expense ? -x.amount : 0),
};

/// 予定・実績の表示切替（片方を隠している間は差を出さない。設計書 3.8）。
class _ShowToggle extends StatelessWidget {
  const _ShowToggle({
    required this.plan,
    required this.actual,
    required this.onChanged,
  });

  final bool plan;
  final bool actual;
  final void Function(bool plan, bool actual) onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Text('表示'),
      FilterChip(
        label: const Text('予定'),
        selected: plan,
        onSelected: (v) => v || actual ? onChanged(v, actual) : null,
      ),
      FilterChip(
        label: const Text('実績'),
        selected: actual,
        onSelected: (v) => v || plan ? onChanged(plan, v) : null,
      ),
    ],
  );
}

/// カテゴリ別のカード一覧（年別・年間の予実で共通）。
class _CategoryCards extends StatelessWidget {
  const _CategoryCards({
    required this.plans,
    required this.actuals,
    required this.kind,
    required this.sort,
    required this.lookup,
    required this.showPlan,
    required this.showActual,
    required this.onSort,
  });

  final List<MatchItem> plans;
  final List<MatchItem> actuals;
  final CompareKind kind;
  final CompareSort sort;
  final Lookup lookup;
  final bool showPlan;
  final bool showActual;
  final ValueChanged<CompareSort> onSort;

  @override
  Widget build(BuildContext context) {
    if (kind == CompareKind.net) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('「収支」では棒グラフと合計だけを出します。'),
      );
    }
    final cards = categoryCompare(
      plans,
      actuals,
      kind == CompareKind.income ? TxnKind.income : TxnKind.expense,
      sort: sort,
    );
    final max = cards.fold(
      0,
      (a, c) => [a, c.planned, c.actual].reduce((x, y) => x > y ? x : y),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<CompareSort>(
          value: sort,
          isExpanded: true,
          items: [
            for (final x in CompareSort.values)
              DropdownMenuItem(value: x, child: Text(x.label)),
          ],
          onChanged: (v) => onSort(v!),
        ),
        for (final c in cards)
          CategoryCompareCard(
            item: c,
            lookup: lookup,
            maxAmount: max,
            showPlan: showPlan,
            showActual: showActual,
          ),
      ],
    );
  }
}

/// 年別の予実（一覧・生涯）（ワイヤーフレーム YearsCompare）。設計書 3.8。
class YearsCompareScreen extends ConsumerStatefulWidget {
  const YearsCompareScreen({super.key});

  @override
  ConsumerState<YearsCompareScreen> createState() => _YearsCompareScreenState();
}

class _YearsCompareScreenState extends ConsumerState<YearsCompareScreen> {
  CompareKind _kind = CompareKind.expense;
  CompareSort _sort = CompareSort.overrun;
  bool _plan = true;
  bool _actual = true;
  int? _from;
  int? _to;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    if (plan == null) return Scaffold(appBar: AppBar());
    final members =
        ref.watch(membersProvider(plan.id)).value ?? const <FamilyMemberRow>[];
    final period = planPeriod(plan, members);
    final lines = ref
        .watch(planLinesProvider((planId: plan.id, from: null, to: null)))
        .value;
    final txns = ref
        .watch(txnsProvider((planId: plan.id, from: null, to: null)))
        .value;
    if (period == null || lines == null || txns == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      ref.watch(accountsProvider).value ?? const [],
    );
    final protagonist = protagonistOf(plan, members);
    final years = [
      for (var y = period.start.year; y <= period.end.year; y++) y,
    ];
    final from = _from ?? years.first;
    final to = _to ?? years.last;
    final pi = [for (final l in lines) (l.year, matchItemOfLine(l))];
    final ai = [
      for (final t in txns)
        (int.parse(t.date.substring(0, 4)), matchItemOfTxn(t)),
    ];
    int yearSum(List<(int, MatchItem)> xs, int y) =>
        xs.where((x) => x.$1 == y).fold(0, (a, x) => a + _valueOf(x.$2, _kind));
    final rangeP = [
      for (final x in pi)
        if (x.$1 >= from && x.$1 <= to) x.$2,
    ];
    final rangeA = [
      for (final x in ai)
        if (x.$1 >= from && x.$1 <= to) x.$2,
    ];
    final p = rangeP.fold(0, (a, x) => a + _valueOf(x, _kind));
    final a = rangeA.fold(0, (s, x) => s + _valueOf(x, _kind));
    final both = _plan && _actual;

    return Scaffold(
      appBar: AppBar(title: const Text('年別の予実')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '予定＝表示中の「${plan.name}」の計画。年を押すと、その年の詳細（年間の予実）を開きます。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<CompareKind>(
            segments: [
              for (final k in CompareKind.values)
                ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {_kind},
            onSelectionChanged: (v) => setState(() => _kind = v.first),
          ),
          _ShowToggle(
            plan: _plan,
            actual: _actual,
            onChanged: (p, a) => setState(() {
              _plan = p;
              _actual = a;
            }),
          ),
          Text('年ごとの${_kind.label}'),
          PlanActualBars(
            key: const Key('years-bars'),
            labels: [for (final y in years) '$y'],
            planned: [for (final y in years) yearSum(pi, y)],
            actual: [for (final y in years) yearSum(ai, y)],
            showPlan: _plan,
            showActual: _actual,
            onTap: (i) => context.push('/compare/year/${years[i]}'),
          ),
          Text(
            '横にスクロールして生涯（${years.first}〜${years.last}年'
            '${protagonist == null ? '' : '・${protagonist.name} ${ageInYear(protagonist, years.first)}〜${ageInYear(protagonist, years.last)}歳'}）を表示します。'
            '実績がない年は、実績を¥0（収入・支出とも）として表示します。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final y
                  in years.where((y) => y >= clock.now().year - 1).take(6))
                ActionChip(
                  label: Text('$y年'),
                  onPressed: () => context.push('/compare/year/$y'),
                ),
            ],
          ),
          const SectionTitle('カテゴリ別に集計する年'),
          Row(
            children: [
              Expanded(
                child: _yearDrop(
                  from,
                  years.first,
                  to,
                  (v) => setState(() => _from = v),
                ),
              ),
              const Text('　〜　'),
              Expanded(
                child: _yearDrop(
                  to,
                  from,
                  years.last,
                  (v) => setState(() => _to = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_kind.label}の合計（$from〜$to年。実績がない年は実績¥0）\n'
            '${_plan ? '予定 ${formatYen(p)}　' : ''}${_actual ? '実績 ${formatYen(a)}　' : ''}${both ? '差 ${formatYenSigned(a - p)}' : ''}',
            key: const Key('years-total'),
          ),
          _CategoryCards(
            plans: rangeP,
            actuals: rangeA,
            kind: _kind,
            sort: _sort,
            lookup: lookup,
            showPlan: _plan,
            showActual: _actual,
            onSort: (v) => setState(() => _sort = v),
          ),
        ],
      ),
    );
  }

  Widget _yearDrop(int value, int min, int max, ValueChanged<int> onChanged) =>
      DropdownButton<int>(
        value: value.clamp(min, max),
        isExpanded: true,
        items: [
          for (var y = min; y <= max; y++)
            DropdownMenuItem(value: y, child: Text('$y年')),
        ],
        onChanged: (v) => onChanged(v!),
      );
}

/// 年間の予実（年の詳細）（ワイヤーフレーム YearlyCompare）。月を選ぶと家計簿（比較・月）へ。
class YearlyCompareScreen extends ConsumerStatefulWidget {
  const YearlyCompareScreen({super.key, required this.year});

  final int year;

  @override
  ConsumerState<YearlyCompareScreen> createState() =>
      _YearlyCompareScreenState();
}

class _YearlyCompareScreenState extends ConsumerState<YearlyCompareScreen> {
  CompareKind _kind = CompareKind.expense;
  CompareSort _sort = CompareSort.overrun;
  bool _plan = true;
  bool _actual = true;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    if (plan == null) return Scaffold(appBar: AppBar());
    final y = widget.year;
    final lines =
        ref
            .watch(
              planLinesProvider((
                planId: plan.id,
                from: YearMonth(y, 1),
                to: YearMonth(y, 12),
              )),
            )
            .value ??
        const <PlanLineRow>[];
    final txns =
        ref
            .watch(
              txnsProvider((planId: plan.id, from: '$y-01-01', to: '$y-12-31')),
            )
            .value ??
        const <TxnRow>[];
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      ref.watch(accountsProvider).value ?? const [],
    );
    final pi = [for (final l in lines) (l.month, matchItemOfLine(l))];
    final ai = [
      for (final t in txns)
        (int.parse(t.date.substring(5, 7)), matchItemOfTxn(t)),
    ];
    int monthSum(List<(int, MatchItem)> xs, int m) =>
        xs.where((x) => x.$1 == m).fold(0, (a, x) => a + _valueOf(x.$2, _kind));
    final totals = compareTotals(pi.map((x) => x.$2), ai.map((x) => x.$2));

    return Scaffold(
      appBar: AppBar(title: Text('$y年の予実')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CompareTable(totals: totals),
          const SizedBox(height: 8),
          SegmentedButton<CompareKind>(
            segments: [
              for (final k in CompareKind.values)
                ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {_kind},
            onSelectionChanged: (v) => setState(() => _kind = v.first),
          ),
          _ShowToggle(
            plan: _plan,
            actual: _actual,
            onChanged: (p, a) => setState(() {
              _plan = p;
              _actual = a;
            }),
          ),
          Text('月ごとの${_kind.label}（月を選ぶと、その月の比較へ）'),
          PlanActualBars(
            labels: [for (var m = 1; m <= 12; m++) '$m月'],
            planned: [for (var m = 1; m <= 12; m++) monthSum(pi, m)],
            actual: [for (var m = 1; m <= 12; m++) monthSum(ai, m)],
            showPlan: _plan,
            showActual: _actual,
            onTap: (i) {
              final c = ref.read(ledgerProvider.notifier);
              c.set(
                ref
                    .read(ledgerProvider)
                    .copyWith(
                      mode: LedgerMode.compare,
                      unit: LedgerUnit.month,
                      ym: YearMonth(y, i + 1),
                    ),
              );
              context.go('/ledger');
            },
          ),
          const SectionTitle('カテゴリ別'),
          _CategoryCards(
            plans: [for (final x in pi) x.$2],
            actuals: [for (final x in ai) x.$2],
            kind: _kind,
            sort: _sort,
            lookup: lookup,
            showPlan: _plan,
            showActual: _actual,
            onSort: (v) => setState(() => _sort = v),
          ),
        ],
      ),
    );
  }
}

/// 資産の予実（生涯）（ワイヤーフレーム AssetCompare）。設計書 3.8・6.8。
class AssetCompareScreen extends ConsumerStatefulWidget {
  const AssetCompareScreen({super.key});

  @override
  ConsumerState<AssetCompareScreen> createState() => _AssetCompareScreenState();
}

class _AssetCompareScreenState extends ConsumerState<AssetCompareScreen> {
  late YearMonth _target = YearMonth.ofDate(clock.now());

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    if (plan == null) return Scaffold(appBar: AppBar());
    final members =
        ref.watch(membersProvider(plan.id)).value ?? const <FamilyMemberRow>[];
    final period = planPeriod(plan, members);
    final sim = ref.watch(simulationProvider(plan.id));
    final actualLine = ref.watch(actualLineProvider(plan.id));
    final lines = ref
        .watch(planLinesProvider((planId: plan.id, from: null, to: null)))
        .value;
    final txns = ref
        .watch(txnsProvider((planId: plan.id, from: null, to: null)))
        .value;
    final events =
        ref.watch(eventsProvider(plan.id)).value ?? const <PlanEventRow>[];
    if (period == null ||
        sim == null ||
        actualLine == null ||
        lines == null ||
        txns == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final protagonist = protagonistOf(plan, members);
    final firstSim = sim.months.isEmpty ? period.end : sim.months.first.ym;
    final years = [for (var y = firstSim.year; y <= period.end.year; y++) y];
    final planYearEnd = [for (final y in years) sim.yearEnd(y)?.total];
    final actualYearEnd = [
      for (final y in years) actualLine.totalAt('$y-12-31'),
    ];
    final markers = <int, String>{};
    for (final e in events) {
      final i = years.indexOf(e.year);
      if (i >= 0) markers[i] = e.title;
    }

    // 差の内訳：起点月の翌月から対象月まで
    final start = YearMonth.ofDateString(plan.baselineDate).addMonths(1);
    final target = _target < start
        ? start
        : (_target > period.end ? period.end : _target);
    final inRangeP = [
      for (final l in lines)
        if (YearMonth(l.year, l.month) >= start &&
            YearMonth(l.year, l.month) <= target)
          matchItemOfLine(l),
    ];
    final inRangeA = [
      for (final t in txns)
        if (YearMonth.ofDateString(t.date) >= start &&
            YearMonth.ofDateString(t.date) <= target)
          matchItemOfTxn(t),
    ];
    final ct = compareTotals(inRangeP, inRangeA);
    final planAt = sim.at(target)?.total;
    final actualAt = actualLine.totalAt(target.lastDayString);
    final breakdown = planAt == null
        ? null
        : AssetDiffBreakdown(
            totalDiff: actualAt - planAt,
            income: ct.income,
            expense: ct.expense,
          );
    final scheme = Theme.of(context).colorScheme;
    final series = [
      ChartSeries(label: '実績線', values: actualYearEnd, color: scheme.onSurface),
      ChartSeries(
        label: '計画線',
        values: planYearEnd,
        color: scheme.primary,
        dashed: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('資産の予実')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '予定＝表示中の「${plan.name}」の計画。生涯（${years.first}〜${years.last}年）の年末の総資産を表示します。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          ChartLegend(series: series, withEvents: true),
          SeriesChart(
            xLabels: [
              for (final y in years)
                '$y${protagonist == null ? '' : '\n${ageInYear(protagonist, y)}歳'}',
            ],
            series: series,
            markers: markers,
            pointWidth: 22,
          ),
          const SectionTitle('差の内訳'),
          YmPicker(
            key: const ValueKey('asset-compare-target'),
            label: '起点の翌月から、この月の末まで',
            value: target,
            min: start,
            max: period.end,
            onChanged: (v) => setState(() => _target = v),
          ),
          if (breakdown == null)
            const Text('この月の計画線がありません')
          else
            Table(
              columnWidths: const {0: IntrinsicColumnWidth()},
              children: [
                const TableRow(
                  children: [
                    Text(''),
                    Text('計画', textAlign: TextAlign.end),
                    Text('実績', textAlign: TextAlign.end),
                    Text('差', textAlign: TextAlign.end),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('収入　'),
                    Text(
                      formatYen(ct.income.planned),
                      textAlign: TextAlign.end,
                    ),
                    Text(formatYen(ct.income.actual), textAlign: TextAlign.end),
                    Text(
                      formatYenSigned(ct.income.diff),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('支出　'),
                    Text(
                      formatYen(ct.expense.planned),
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      formatYen(ct.expense.actual),
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      formatYenSigned(ct.expense.diff),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('運用　'),
                    const Text(''),
                    const Text(''),
                    Text(
                      formatYenSigned(breakdown.investmentDiff),
                      textAlign: TextAlign.end,
                      key: const Key('diff-investment'),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('総資産の差　'),
                    Text(formatYen(planAt!), textAlign: TextAlign.end),
                    Text(formatYen(actualAt), textAlign: TextAlign.end),
                    Text(
                      formatYenSigned(breakdown.totalDiff),
                      textAlign: TextAlign.end,
                      key: const Key('diff-total'),
                    ),
                  ],
                ),
              ],
            ),
          Text(
            '運用の差＝総資産の差から、収入・支出の差を引いた残り（利回り・価格の変動など）。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SectionTitle('年末の総資産（生涯）'),
          Table(
            columnWidths: const {0: IntrinsicColumnWidth()},
            children: [
              const TableRow(
                children: [
                  Text('年'),
                  Text('計画線', textAlign: TextAlign.end),
                  Text('実績線', textAlign: TextAlign.end),
                  Text('差', textAlign: TextAlign.end),
                ],
              ),
              for (var i = 0; i < years.length; i++)
                TableRow(
                  children: [
                    Text(
                      '${years[i]}${protagonist == null ? '' : '（${ageInYear(protagonist, years[i])}歳）'}　',
                    ),
                    Text(
                      planYearEnd[i] == null
                          ? '—'
                          : formatYen(planYearEnd[i]!).substring(1),
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      formatYen(actualYearEnd[i]).replaceFirst('¥', ''),
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      planYearEnd[i] == null
                          ? '—'
                          : formatYenSigned(actualYearEnd[i] - planYearEnd[i]!),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
