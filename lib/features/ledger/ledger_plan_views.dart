import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/io/json_import.dart' show FileUnit;
import '../../domain/calc/ledger.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';
import 'ledger_filter_sheet.dart';
import 'ledger_state.dart';
import 'ledger_widgets.dart';
import '../data/file_io.dart';

Lookup _lookup(WidgetRef ref) => Lookup(
  ref.watch(categoriesProvider).value ?? const [],
  ref.watch(accountsProvider).value ?? const [],
);

/// 家計簿（予定・年／月）（ワイヤーフレーム LedgerPlan / LedgerPlanMonth）。
///
/// 表示プランの計画行だけで、実績と同じ構成（上部の合計・円グラフ・カテゴリ別のアコーディオン）を出す（設計書 3.1）。
class PlanBreakdown extends ConsumerWidget {
  const PlanBreakdown({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(ledgerProvider);
    final c = ref.read(ledgerProvider.notifier);
    final isYear = s.unit == LedgerUnit.year;
    final from = isYear ? YearMonth(s.ym.year, 1) : s.ym;
    final to = isYear ? YearMonth(s.ym.year, 12) : s.ym;
    final rows =
        ref
            .watch(planLinesProvider((planId: planId, from: from, to: to)))
            .value ??
        const <PlanLineRow>[];
    final byId = {for (final r in rows) r.id: r};
    final items = [for (final r in rows) ledgerTxnOfLine(r)];
    final lookup = _lookup(ref);
    final periodLabel = isYear ? '${s.ym.year}年' : '${s.ym.month}月';
    final byCat = totalsByCategory(items, s.pieKind);
    final kindTotal = byCat.fold(0, (a, x) => a + x.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        TotalsRow(title: '$periodLabelの予定', totals: totalsOf(items)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => context.push('/home/plan/$planId/groups'),
              child: const Text('登録済みグループ'),
            ),
            OutlinedButton(
              onPressed: () => context.push('/home/plan/$planId/register'),
              child: const Text('グループを登録'),
            ),
          ],
        ),
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
          '$periodLabelの予定${s.pieKind.label}　${formatYen(kindTotal)}',
          textAlign: TextAlign.center,
        ),
        CategoryPie(totals: byCat, lookup: lookup, emptyText: 'この期間の予定はありません'),
        SectionTitle('カテゴリ別の予定（$periodLabel・${s.pieKind.label}）'),
        for (final cat in byCat)
          ExpansionTile(
            key: PageStorageKey('plan-cat-${cat.categoryId}-${s.unit}'),
            tilePadding: EdgeInsets.zero,
            leading: ColorDot(lookup.categoryColor(cat.categoryId)),
            title: Text(lookup.categoryName(cat.categoryId)),
            trailing: Text(
              '${formatYen(cat.amount)}  ${(cat.ratio * 100).round()}%',
            ),
            children: () {
              final mine = [
                for (final t in items)
                  if (t.kind == s.pieKind && t.categoryId == cat.categoryId) t,
              ];
              if (isYear) {
                return [
                  Text(
                    '月ごとの${lookup.categoryName(cat.categoryId)}の予定（月を選ぶと、その月の表示へ）',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  for (final m in monthlyTotals(mine))
                    ListTile(
                      dense: true,
                      title: Text('${m.month}月'),
                      subtitle: Text(m.count == 0 ? '予定なし' : '${m.count}件'),
                      trailing: Text(m.count == 0 ? '—' : formatYen(m.amount)),
                      onTap: () => c.openMonth(m.month),
                    ),
                ];
              }
              return [
                for (final t in mine)
                  PlanLineTile(line: byId[t.id]!, lookup: lookup),
              ];
            }(),
          ),
      ],
    );
  }
}

/// 家計簿（予定・リスト）（ワイヤーフレーム LedgerPlanList）：その月の予定を由来ごとにまとめる。
class PlanList extends ConsumerStatefulWidget {
  const PlanList({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanList> createState() => _PlanListState();
}

class _PlanListState extends ConsumerState<PlanList> {
  Set<PlanLineSource> _sources = const {};

  /// 選択は実績のリストと同じプロバイダで持つ（選択中は入力ボタンを隠す）
  late final TxnSelection _sel = ref.read(txnSelectionProvider.notifier);

  @override
  void initState() {
    super.initState();
    _sel; // dispose で使うため先に取っておく
  }

  @override
  void dispose() {
    final sel = _sel;
    Future.microtask(sel.clear);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(ledgerProvider);
    ref.listen(ledgerProvider.select((s) => (s.ym, s.filter)), (_, _) {
      _sel.clear();
    });
    final selected = ref.watch(txnSelectionProvider);
    final selecting = selected.isNotEmpty;
    final c = ref.read(ledgerProvider.notifier);
    final f = s.listFilter;
    final from = YearMonth.ofDateString(f.from);
    final to = YearMonth.ofDateString(f.to);
    final rows =
        ref
            .watch(
              planLinesProvider((planId: widget.planId, from: from, to: to)),
            )
            .value ??
        const <PlanLineRow>[];
    final regs = {
      for (final r
          in ref.watch(registrationsProvider(widget.planId)).value ?? const [])
        r.registration.id: r.groupName ?? '（削除済みのグループ）',
    };
    final lookup = _lookup(ref);
    final shown = [
      for (final r in rows)
        if (f.matches(ledgerTxnOfLine(r)) &&
            (_sources.isEmpty ||
                _sources.contains(PlanLineSource.of(r.source))))
          r,
    ];
    final groups = <String, List<PlanLineRow>>{};
    for (final r in shown) {
      final key = r.source == PlanLineSource.group.code
          ? 'グループ「${regs[r.sourceId] ?? '?'}」'
          : '手入力・イベント';
      (groups[key] ??= []).add(r);
    }
    final keys = groups.keys.toList()
      ..sort(
        (a, b) => a == '手入力・イベント' ? 1 : (b == '手入力・イベント' ? -1 : a.compareTo(b)),
      );

    final list = ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, selecting ? 16 : 96),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ActionChip(
              avatar: const Icon(Icons.filter_list, size: 18),
              label: Text('カテゴリ・口座・金額${f.isNarrowed ? '・絞り込み中' : ''}'),
              onPressed: () async {
                final next = await showLedgerFilterSheet(context, f);
                if (next != null) c.set(s.copyWith(filter: () => next));
              },
            ),
            for (final src in PlanLineSource.values)
              FilterChip(
                label: Text(src.label),
                selected: _sources.contains(src),
                onSelected: (on) => setState(
                  () => _sources = on
                      ? {..._sources, src}
                      : ({..._sources}..remove(src)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TotalsRow(
          title:
              '${from == to ? '${from.month}月' : '絞り込み期間'}の予定（${ref.watch(selectedPlanProvider).value?.name ?? ''}の計画）',
          totals: totalsOf(shown.map(ledgerTxnOfLine)),
        ),
        const ImportJsonButton(expect: FileUnit.rows),
        Text(
          '予定 ${shown.length}件（予定は月単位なので、日付ではなく月でまとめます）'
          '${selecting ? '' : '。長押しで選んでJSONで書き出せます'}',
        ),
        for (final k in keys) ...[
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(top: 8),
            child: Text(k),
          ),
          for (final r in groups[k]!)
            PlanLineTile(
              line: r,
              lookup: lookup,
              showMonth: from != to,
              selected: selecting ? selected.contains(r.id) : null,
              onTap: selecting ? () => _sel.toggle(r.id) : null,
              onLongPress: () => _sel.toggle(r.id),
            ),
        ],
      ],
    );
    if (!selecting) return list;
    return Column(
      children: [
        Expanded(child: list),
        SelectionBar(
          count: selected.length,
          onClear: _sel.clear,
          onSelectAll: () => _sel.addAll([for (final r in shown) r.id]),
          actions: [
            FilledButton(
              key: const Key('select-export'),
              onPressed: () => exportJson(
                context,
                ref,
                'plans',
                (e) => e.exportRows(
                  planId: widget.planId,
                  lines: [
                    for (final r in rows)
                      if (selected.contains(r.id)) r,
                  ],
                ),
              ),
              child: const Text('JSONで書き出す'),
            ),
          ],
        ),
      ],
    );
  }
}
