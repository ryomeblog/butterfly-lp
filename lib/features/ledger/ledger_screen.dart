import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/repositories/txn_repository.dart';
import '../../domain/calc/ledger.dart';
import '../../domain/models/enums.dart';
import '../shared/plan_switch_sheet.dart';
import '../shared/widgets.dart';
import '../compare/ledger_compare_view.dart';
import 'ledger_filter_sheet.dart';
import 'ledger_plan_views.dart';
import 'ledger_state.dart';
import 'ledger_widgets.dart';
import '../data/file_io.dart';
import '../../data/db/database.dart';

/// 家計簿（ワイヤーフレーム Ledger / LedgerMonth / LedgerList / LedgerCalendar）。
///
/// 上部で「実績／予定／比較」、その下で「内訳／リスト／カレンダー」と「年／月」を切り替える（設計書 3.1）。
/// 比較は ledger_compare_views.dart。
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(ledgerProvider);
    final c = ref.read(ledgerProvider.notifier);
    final plan = ref.watch(selectedPlanProvider).value;
    return Scaffold(
      appBar: AppBar(title: const PlanSwitchTitle(title: '家計簿')),
      floatingActionButton: FloatingActionButton(
        key: const Key('txn-add'),
        tooltip: '入力',
        onPressed: () {
          final today = todayString();
          final inPeriod =
              today.compareTo(s.from) >= 0 && today.compareTo(s.to) <= 0;
          final date = inPeriod ? today : s.ym.firstDayString;
          // 予定の表示から開くと「予定」が選ばれた状態（設計書 3.1）
          context.push(
            s.mode == LedgerMode.plan
                ? '/entry/plan-line/new?ym=${YearMonth.ofDateString(date)}'
                : '/entry/txn/new?date=$date',
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<LedgerMode>(
              segments: const [
                ButtonSegment(value: LedgerMode.actual, label: Text('実績')),
                ButtonSegment(value: LedgerMode.plan, label: Text('予定')),
                ButtonSegment(value: LedgerMode.compare, label: Text('比較')),
              ],
              selected: {s.mode},
              onSelectionChanged: (v) => c.set(
                s.copyWith(
                  mode: v.first,
                  filter: () => null,
                  view:
                      v.first == LedgerMode.plan &&
                          s.view == LedgerView.calendar
                      ? LedgerView.breakdown
                      : null,
                ),
              ),
            ),
          ),
          if (plan == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (s.mode == LedgerMode.compare)
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SegmentedButton<LedgerUnit>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: LedgerUnit.year,
                            label: Text('年'),
                          ),
                          ButtonSegment(
                            value: LedgerUnit.month,
                            label: Text('月'),
                          ),
                        ],
                        selected: {s.unit},
                        onSelectionChanged: (v) =>
                            c.set(s.copyWith(unit: v.first)),
                      ),
                    ),
                  ),
                  PeriodNav(
                    label: s.unit == LedgerUnit.year
                        ? '${s.ym.year}年'
                        : '${s.ym.year}年${s.ym.month}月',
                    onPrev: () => c.set(
                      s.copyWith(
                        ym: s.ym.addMonths(
                          s.unit == LedgerUnit.year ? -12 : -1,
                        ),
                      ),
                    ),
                    onNext: () => c.set(
                      s.copyWith(
                        ym: s.ym.addMonths(s.unit == LedgerUnit.year ? 12 : 1),
                      ),
                    ),
                  ),
                  Expanded(child: LedgerCompareView(planId: plan.id)),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<LedgerView>(
                      showSelectedIcon: false,
                      segments: [
                        const ButtonSegment(
                          value: LedgerView.breakdown,
                          label: Text('内訳'),
                        ),
                        const ButtonSegment(
                          value: LedgerView.list,
                          label: Text('リスト'),
                        ),
                        // 予定は月単位なのでカレンダーはない
                        if (s.mode == LedgerMode.actual)
                          const ButtonSegment(
                            value: LedgerView.calendar,
                            label: Text('カレンダー'),
                          ),
                      ],
                      selected: {s.view},
                      onSelectionChanged: (v) =>
                          c.set(s.copyWith(view: v.first, filter: () => null)),
                    ),
                  ),
                  if (s.view == LedgerView.breakdown) ...[
                    const SizedBox(width: 8),
                    SegmentedButton<LedgerUnit>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: LedgerUnit.year, label: Text('年')),
                        ButtonSegment(
                          value: LedgerUnit.month,
                          label: Text('月'),
                        ),
                      ],
                      selected: {s.unit},
                      onSelectionChanged: (v) =>
                          c.set(s.copyWith(unit: v.first)),
                    ),
                  ],
                ],
              ),
            ),
            if (s.filter == null)
              PeriodNav(
                label:
                    s.view == LedgerView.breakdown && s.unit == LedgerUnit.year
                    ? '${s.ym.year}年'
                    : '${s.ym.year}年${s.ym.month}月',
                onPrev: () => c.shift(-1),
                onNext: () => c.shift(1),
              ),
            Expanded(
              child: s.mode == LedgerMode.plan
                  ? switch (s.view) {
                      LedgerView.list => PlanList(planId: plan.id),
                      _ => PlanBreakdown(planId: plan.id),
                    }
                  : switch (s.view) {
                      LedgerView.breakdown => _Breakdown(planId: plan.id),
                      LedgerView.list => _ListView(planId: plan.id),
                      LedgerView.calendar => _CalendarView(planId: plan.id),
                    },
            ),
          ],
        ],
      ),
    );
  }
}

/// 予定から実績入力・グループから入力への入口（設計書 3.8）。
class _EntryButtons extends ConsumerWidget {
  const _EntryButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(ledgerProvider);
    final month = s.unit == LedgerUnit.month || s.view != LedgerView.breakdown
        ? '&month=${s.ym.month}'
        : '';
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton(
          key: const Key('to-planned-entry'),
          onPressed: () =>
              context.push('/entry/planned?year=${s.ym.year}$month'),
          child: const Text('予定から実績を入力'),
        ),
        OutlinedButton(
          onPressed: () => context.push('/entry/group?ym=${s.ym}'),
          child: const Text('グループから入力'),
        ),
      ],
    );
  }
}

Lookup _lookup(WidgetRef ref) => Lookup(
  ref.watch(categoriesProvider).value ?? const [],
  ref.watch(accountsProvider).value ?? const [],
);

// ---- 内訳 ----

class _Breakdown extends ConsumerWidget {
  const _Breakdown({required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(ledgerProvider);
    final c = ref.read(ledgerProvider.notifier);
    final rows = ref.watch(
      txnsProvider((planId: planId, from: s.from, to: s.to)),
    );
    final lookup = _lookup(ref);
    final txns = [for (final r in rows.value ?? const []) ledgerTxnOf(r)];
    final isYear = s.unit == LedgerUnit.year;
    final periodLabel = isYear ? '${s.ym.year}年' : '${s.ym.month}月';
    final byCat = totalsByCategory(txns, s.pieKind);
    final kindTotal = byCat.fold(0, (a, x) => a + x.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        TotalsRow(title: '$periodLabelの実績', totals: totalsOf(txns)),
        const SizedBox(height: 8),
        const _EntryButtons(),
        const SizedBox(height: 16),
        SegmentedButton<TxnKind>(
          segments: const [
            ButtonSegment(value: TxnKind.expense, label: Text('支出')),
            ButtonSegment(value: TxnKind.income, label: Text('収入')),
          ],
          selected: {s.pieKind},
          onSelectionChanged: (v) => c.set(s.copyWith(pieKind: v.first)),
        ),
        const SizedBox(height: 8),
        Text(
          '$periodLabelの実績${s.pieKind.label}　${formatYen(kindTotal)}',
          textAlign: TextAlign.center,
        ),
        CategoryPie(totals: byCat, lookup: lookup),
        SectionTitle('カテゴリ別の実績（$periodLabel・${s.pieKind.label}）'),
        if (isYear)
          Row(
            children: [
              const Text('開いたときの表示'),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<YearOpenMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: YearOpenMode.monthly,
                      label: Text('月ごとにまとめる'),
                    ),
                    ButtonSegment(
                      value: YearOpenMode.each,
                      label: Text('明細を1件ずつ'),
                    ),
                  ],
                  selected: {s.yearOpenMode},
                  onSelectionChanged: (v) =>
                      c.set(s.copyWith(yearOpenMode: v.first)),
                ),
              ),
            ],
          ),
        for (final cat in byCat)
          ExpansionTile(
            key: PageStorageKey(
              'cat-${cat.categoryId}-${s.unit}-${s.yearOpenMode}',
            ),
            tilePadding: EdgeInsets.zero,
            leading: ColorDot(lookup.categoryColor(cat.categoryId)),
            title: Text(lookup.categoryName(cat.categoryId)),
            trailing: Text(
              '${formatYen(cat.amount)}  ${(cat.ratio * 100).round()}%',
            ),
            children: _categoryDetail(context, ref, s, cat, txns, lookup),
          ),
      ],
    );
  }

  List<Widget> _categoryDetail(
    BuildContext context,
    WidgetRef ref,
    LedgerState s,
    CategoryTotal cat,
    List<LedgerTxn> txns,
    Lookup lookup,
  ) {
    final c = ref.read(ledgerProvider.notifier);
    final mine = [
      for (final t in txns)
        if (t.kind == s.pieKind && t.categoryId == cat.categoryId) t,
    ];
    final name = lookup.categoryName(cat.categoryId);
    if (s.unit == LedgerUnit.month) {
      return [
        for (final t in newestFirst(mine)) TxnTile(txn: t, lookup: lookup),
      ];
    }
    if (s.yearOpenMode == YearOpenMode.monthly) {
      return [
        Text(
          '月ごとの$nameの実績（月を選ぶと、その月の表示へ）',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (final m in monthlyTotals(mine))
          ListTile(
            dense: true,
            title: Text('${m.month}月'),
            subtitle: Text(m.count == 0 ? '実績なし' : '${m.count}件'),
            trailing: Text(m.count == 0 ? '—' : formatYen(m.amount)),
            onTap: () => c.openMonth(m.month),
          ),
      ];
    }
    final sorted = newestFirst(mine);
    return [
      Text(
        '${s.ym.year}年の$nameの実績（新しい順）',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      for (final t in sorted.take(6)) TxnTile(txn: t, lookup: lookup),
      TextButton(
        onPressed: () =>
            c.openListFor(categoryId: cat.categoryId, from: s.from, to: s.to),
        child: Text('${s.ym.year}年の$nameをすべて表示（${sorted.length}件）'),
      ),
    ];
  }
}

// ---- リスト ----

class _ListView extends ConsumerWidget {
  const _ListView({required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(ledgerProvider);
    final c = ref.read(ledgerProvider.notifier);
    final f = s.listFilter;
    final rows = ref.watch(
      txnsProvider((planId: planId, from: f.from, to: f.to)),
    );
    final lookup = _lookup(ref);
    final all = [for (final r in rows.value ?? const []) ledgerTxnOf(r)];
    final txns = newestFirst(all.where(f.matches));
    final totals = totalsOf(txns);

    final byDate = <String, List<LedgerTxn>>{};
    for (final t in txns) {
      (byDate[t.date] ??= []).add(t);
    }
    final from = parseDate(f.from);
    final to = parseDate(f.to);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              key: const Key('list-filter'),
              avatar: const Icon(Icons.filter_list, size: 18),
              label: Text(
                '期間：${from.year}/${from.month}/${from.day}〜${to.month}/${to.day}'
                '${f.isNarrowed ? '・絞り込み中' : ''}',
              ),
              onPressed: () async {
                final next = await showLedgerFilterSheet(context, f);
                if (next != null) c.set(s.copyWith(filter: () => next));
              },
            ),
            if (s.filter != null)
              TextButton(
                onPressed: () => c.set(s.copyWith(filter: () => null)),
                child: const Text('絞り込みを解除'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TotalsRow(title: '絞り込み結果の実績', totals: totals),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () {
                final ids = {for (final t in txns) t.id};
                exportJson(
                  context,
                  ref,
                  'list',
                  (e) => e.exportRows(
                    planId: planId,
                    txns: [
                      for (final r in rows.value ?? const <TxnRow>[])
                        if (ids.contains(r.id)) r,
                    ],
                  ),
                );
              },
              child: const Text('絞り込み結果をJSONで書き出す'),
            ),
            TextButton(
              onPressed: () => pickAndImportJson(context),
              child: const Text('収支を取り込む'),
            ),
          ],
        ),
        Text('絞り込み結果 ${txns.length}件'),
        for (final e in byDate.entries) ...[
          _DayHeader(date: e.key, totals: totalsOf(e.value)),
          for (final t in e.value)
            TxnTile(txn: t, lookup: lookup, showDate: false),
        ],
        if (txns.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('該当する実績はありません')),
          ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.totals});

  final String date;
  final LedgerTotals totals;

  @override
  Widget build(BuildContext context) {
    final d = parseDate(date);
    const w = ['月', '火', '水', '木', '金', '土', '日'];
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text('${d.month}月${d.day}日（${w[d.weekday - 1]}）')),
          Text(formatYenSigned(totals.net)),
        ],
      ),
    );
  }
}

// ---- カレンダー ----

class _CalendarView extends ConsumerStatefulWidget {
  const _CalendarView({required this.planId});

  final String planId;

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  int? _day;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(ledgerProvider);
    final ym = s.ym;
    final rows = ref.watch(
      txnsProvider((
        planId: widget.planId,
        from: ym.firstDayString,
        to: ym.lastDayString,
      )),
    );
    final lookup = _lookup(ref);
    final txns = [for (final r in rows.value ?? const []) ledgerTxnOf(r)];
    final daily = dailyTotals(txns);
    // 日曜はじまり
    final lead = ym.firstDay.weekday % 7;
    final cells = lead + ym.daysInMonth;
    final scheme = Theme.of(context).colorScheme;
    final selected = _day;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        TotalsRow(title: '${ym.month}月の実績', totals: totalsOf(txns)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final w in ['日', '月', '火', '水', '木', '金', '土'])
              Expanded(child: Center(child: Text(w))),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          children: [
            for (var i = 0; i < (cells + 6) ~/ 7 * 7; i++)
              if (i < lead || i >= cells)
                const SizedBox.shrink()
              else
                Builder(
                  builder: (context) {
                    final day = i - lead + 1;
                    final t = daily[day];
                    return InkWell(
                      key: Key('cal-$day'),
                      onTap: () => setState(() => _day = day),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: day == selected
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: day == selected ? 2 : 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$day', style: const TextStyle(fontSize: 12)),
                            if (t != null)
                              FittedBox(
                                child: Text(
                                  formatYenSigned(t.net).replaceAll('¥', ''),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: t.net >= 0
                                        ? scheme.primary
                                        : scheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
        if (selected != null) ...[
          SectionTitle('${ym.month}月$selected日'),
          for (final t in newestFirst(txns.where((x) => x.day == selected)))
            TxnTile(txn: t, lookup: lookup, showDate: false),
          if (!txns.any((x) => x.day == selected)) const Text('この日の実績はありません'),
        ],
        const SizedBox(height: 8),
        const _EntryButtons(),
      ],
    );
  }
}
