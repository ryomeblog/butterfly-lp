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
import '../../data/repositories/txn_repository.dart';
import '../../domain/calc/compare.dart';
import '../../domain/calc/event_matching.dart';
import '../../domain/models/enums.dart';
import '../ledger/ledger_state.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/widgets.dart';
import 'compare_common.dart';
import 'compare_widgets.dart';

enum _Open { monthly, detail }

enum _Detail { all, actual, plan }

/// 家計簿（比較・年／月）（ワイヤーフレーム LedgerCompare / LedgerCompareMonth）。設計書 3.1・3.8。
///
/// 予定・実績・差の表、（年）月ごとの棒グラフ、総資産の計画・実績・差、未入力の予定、
/// カテゴリ1つ＝1カード。年は1月〜12月の全月を対象にし、実績がない月は実績¥0として数える。
class LedgerCompareView extends ConsumerStatefulWidget {
  const LedgerCompareView({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<LedgerCompareView> createState() => _LedgerCompareViewState();
}

class _LedgerCompareViewState extends ConsumerState<LedgerCompareView> {
  CompareKind _kind = CompareKind.expense;
  CompareSort _sort = CompareSort.overrun;
  _Open _open = _Open.monthly;
  _Detail _detail = _Detail.all;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(ledgerProvider);
    final isYear = s.unit == LedgerUnit.year;
    final from = isYear ? YearMonth(s.ym.year, 1) : s.ym;
    final to = isYear ? YearMonth(s.ym.year, 12) : s.ym;
    final lines =
        ref
            .watch(
              planLinesProvider((planId: widget.planId, from: from, to: to)),
            )
            .value ??
        const <PlanLineRow>[];
    final txns =
        ref
            .watch(
              txnsProvider((
                planId: widget.planId,
                from: from.firstDayString,
                to: to.lastDayString,
              )),
            )
            .value ??
        const <TxnRow>[];
    final allTxns =
        ref
            .watch(txnsProvider((planId: widget.planId, from: null, to: null)))
            .value ??
        const <TxnRow>[];
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      ref.watch(accountsProvider).value ?? const [],
    );
    final planItems = [for (final l in lines) matchItemOfLine(l)];
    final actualItems = [for (final t in txns) matchItemOfTxn(t)];
    final totals = compareTotals(planItems, actualItems);

    // 未入力の予定（今日までの月／これからの月）
    final actuals = planActuals(
      lines.map(planItemOf),
      allTxns.map(actualItemOf),
    );
    final open = [
      for (final l in lines)
        if ((actuals[l.id] ?? 0) == 0) l,
    ];
    final thisMonth = YearMonth.ofDate(clock.now());
    final pastOpen = [
      for (final l in open)
        if (YearMonth(l.year, l.month) <= thisMonth) l,
    ];
    int sum(List<PlanLineRow> x) => x.fold(0, (a, l) => a + l.amount);

    // 総資産（年は年末、月は月末）
    final sim = ref.watch(simulationProvider(widget.planId));
    final actualLine = ref.watch(actualLineProvider(widget.planId));
    final planTotal = sim?.at(to)?.total;
    final actualTotal = actualLine?.totalAt(to.lastDayString);

    final periodLabel = isYear ? '${s.ym.year}年（1月〜12月）' : '${s.ym.month}月';
    final kindTxn = _kind == CompareKind.income
        ? TxnKind.income
        : TxnKind.expense;
    final cards = _kind == CompareKind.net
        ? const <CategoryCompare>[]
        : categoryCompare(planItems, actualItems, kindTxn, sort: _sort);
    final maxAmount = cards.fold(
      0,
      (a, c) => [a, c.planned, c.actual].reduce((x, y) => x > y ? x : y),
    );

    int monthValue(Iterable<MatchItem> items, int m, Iterable<int> monthsOf) {
      var v = 0;
      final list = items.toList();
      final ms = monthsOf.toList();
      for (var i = 0; i < list.length; i++) {
        if (ms[i] != m) continue;
        final x = list[i];
        v += switch (_kind) {
          CompareKind.expense => x.kind == TxnKind.expense ? x.amount : 0,
          CompareKind.income => x.kind == TxnKind.income ? x.amount : 0,
          CompareKind.net =>
            x.kind == TxnKind.income
                ? x.amount
                : (x.kind == TxnKind.expense ? -x.amount : 0),
        };
      }
      return v;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Text(
          '$periodLabelの予定と実績（差＝実績−予定）${isYear ? '。実績がない月は実績¥0として数える' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        CompareTable(key: const Key('compare-table'), totals: totals),
        const SizedBox(height: 12),
        SegmentedButton<CompareKind>(
          segments: [
            for (final k in CompareKind.values)
              ButtonSegment(value: k, label: Text(k.label)),
          ],
          selected: {_kind},
          onSelectionChanged: (v) => setState(() => _kind = v.first),
        ),
        if (isYear) ...[
          const SizedBox(height: 8),
          Text('月ごとの${_kind.label}（予定と実績。月を選ぶと、その月の比較へ）'),
          PlanActualBars(
            labels: [for (var m = 1; m <= 12; m++) '$m月'],
            planned: [
              for (var m = 1; m <= 12; m++)
                monthValue(planItems, m, lines.map((l) => l.month)),
            ],
            actual: [
              for (var m = 1; m <= 12; m++)
                monthValue(
                  actualItems,
                  m,
                  txns.map((t) => int.parse(t.date.substring(5, 7))),
                ),
            ],
            onTap: (i) => ref.read(ledgerProvider.notifier).openMonth(i + 1),
          ),
        ],
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('総資産（${isYear ? '${s.ym.year}年末' : '${s.ym.month}月末'}）'),
                Text(
                  '計画線 ${planTotal == null ? '—' : formatYen(planTotal)}　'
                  '実績線 ${actualTotal == null ? '—' : formatYen(actualTotal)}　'
                  '差 ${planTotal == null || actualTotal == null ? '—' : formatYenSigned(actualTotal - planTotal)}',
                  key: const Key('compare-assets'),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/compare/years'),
                      child: const Text('年別の予実を見る'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/compare/assets'),
                      child: const Text('資産の予実を見る'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isYear ? '${s.ym.year}年' : '${s.ym.month}月'}の予定のうち実績が未入力：${open.length}件（${formatYen(sum(open))} 分）',
                  key: const Key('compare-open'),
                ),
                if (isYear)
                  Text(
                    '今日までの月 ${pastOpen.length}件／これからの月 ${open.length - pastOpen.length}件',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                TextButton(
                  onPressed: () => context.push(
                    '/entry/planned?year=${s.ym.year}${isYear ? '' : '&month=${s.ym.month}'}',
                  ),
                  child: const Text('予定から入力'),
                ),
                Text(
                  '未入力の予定があると、実績が少なく見えます。予定との差が大きいカテゴリは、下のカテゴリ別（並び順：予定からの超過が大きい順）で確認します。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (_kind != CompareKind.net) ...[
          SectionTitle(
            'カテゴリ別の予定と実績（${isYear ? '${s.ym.year}年' : '${s.ym.month}月'}・${_kind.label}）',
          ),
          DropdownButton<CompareSort>(
            value: _sort,
            isExpanded: true,
            items: [
              for (final x in CompareSort.values)
                DropdownMenuItem(value: x, child: Text(x.label)),
            ],
            onChanged: (v) => setState(() => _sort = v!),
          ),
          if (isYear)
            SegmentedButton<_Open>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Open.monthly, label: Text('月ごと')),
                ButtonSegment(value: _Open.detail, label: Text('明細')),
              ],
              selected: {_open},
              onSelectionChanged: (v) => setState(() => _open = v.first),
            ),
          if (!isYear || _open == _Open.detail) ...[
            const SizedBox(height: 4),
            SegmentedButton<_Detail>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Detail.all, label: Text('全て')),
                ButtonSegment(value: _Detail.actual, label: Text('実績')),
                ButtonSegment(value: _Detail.plan, label: Text('予定')),
              ],
              selected: {_detail},
              onSelectionChanged: (v) => setState(() => _detail = v.first),
            ),
          ],
          for (final c in cards)
            CategoryCompareCard(
              item: c,
              lookup: lookup,
              maxAmount: maxAmount,
              children: isYear && _open == _Open.monthly
                  ? _monthly(c, lines, txns, kindTxn)
                  : _details(c, lines, txns, kindTxn, lookup),
            ),
        ] else
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('「収支」では棒グラフと合計だけを出します。'),
          ),
      ],
    );
  }

  List<Widget> _monthly(
    CategoryCompare c,
    List<PlanLineRow> lines,
    List<TxnRow> txns,
    TxnKind kind,
  ) {
    return [
      Text(
        '月ごとの${c.categoryId == null ? '' : ''}予定・実績・差（月を選ぶと、その月の比較へ）',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      for (var m = 1; m <= 12; m++)
        Builder(
          builder: (context) {
            final p = lines
                .where(
                  (l) =>
                      l.month == m &&
                      l.kind == kind.code &&
                      l.categoryId == c.categoryId,
                )
                .fold(0, (a, l) => a + l.amount);
            final mt = txns.where(
              (t) =>
                  int.parse(t.date.substring(5, 7)) == m &&
                  t.kind == kind.code &&
                  t.categoryId == c.categoryId,
            );
            final a = mt.fold(0, (x, t) => x + t.amount);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('$m月'),
              trailing: Text(
                '予定 ${formatYen(p)}　実績 ${mt.isEmpty ? '—' : formatYen(a)}　差 ${mt.isEmpty ? '—' : formatYenSigned(a - p)}',
              ),
              onTap: () => ref.read(ledgerProvider.notifier).openMonth(m),
            );
          },
        ),
    ];
  }

  List<Widget> _details(
    CategoryCompare c,
    List<PlanLineRow> lines,
    List<TxnRow> txns,
    TxnKind kind,
    Lookup lookup,
  ) {
    final ps = [
      for (final l in lines)
        if (l.kind == kind.code && l.categoryId == c.categoryId) l,
    ];
    final as = [
      for (final t in txns)
        if (t.kind == kind.code && t.categoryId == c.categoryId) t,
    ];
    return [
      if (_detail != _Detail.actual) ...[
        Text(
          '予定（${ps.length}件）',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        for (final l in ps)
          PlanLineTile(line: l, lookup: lookup, showMonth: true),
      ],
      if (_detail != _Detail.plan) ...[
        Text(
          '実績（${as.length}件）',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        for (final t in newestFirstRows(as))
          TxnTile(txn: ledgerTxnOf(t), lookup: lookup),
      ],
    ];
  }
}

List<TxnRow> newestFirstRows(List<TxnRow> rows) =>
    [...rows]..sort((a, b) => b.date.compareTo(a.date));
