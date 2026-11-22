import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/plan_line_repository.dart';
import '../../domain/models/enums.dart';
import '../shared/plan_period.dart';
import '../shared/widgets.dart';
import '../shared/ym_picker.dart';

/// 登録済みグループ（ワイヤーフレーム PlanGroups）。
///
/// このプランに登録したグループの一覧（期間）、年別の収入・支出の合計、
/// 指定年月以降の作り直し・年範囲を指定した計画行の削除・登録の取り消し（設計書 6.4）。
class PlanGroupsScreen extends ConsumerStatefulWidget {
  const PlanGroupsScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanGroupsScreen> createState() => _PlanGroupsScreenState();
}

class _PlanGroupsScreenState extends ConsumerState<PlanGroupsScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final plan = (ref.watch(plansProvider).value ?? const <PlanRow>[])
        .where((p) => p.id == widget.planId)
        .firstOrNull;
    final members = ref.watch(membersProvider(widget.planId)).value ?? const [];
    final regs =
        ref.watch(registrationsProvider(widget.planId)).value ?? const [];
    final lines =
        ref
            .watch(
              planLinesProvider((planId: widget.planId, from: null, to: null)),
            )
            .value ??
        const <PlanLineRow>[];
    final period = plan == null ? null : planPeriod(plan, members);
    if (plan == null || period == null) return Scaffold(appBar: AppBar());

    final selected =
        regs.where((r) => r.registration.id == _selected).firstOrNull ??
        regs.firstOrNull;

    // 収入のグループがない年（登録していない期間は収入なしとして扱う）
    final incomeYears = {
      for (final l in lines)
        if (l.source == PlanLineSource.group.code &&
            l.kind == TxnKind.income.code)
          l.year,
    };
    final noIncome = [
      for (var y = period.start.year; y <= period.end.year; y++)
        if (!incomeYears.contains(y)) y,
    ];

    return Scaffold(
      appBar: AppBar(title: Text('登録済みグループ（${plan.name}）')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/plan/${widget.planId}/register'),
        icon: const Icon(Icons.add),
        label: const Text('グループを登録'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (regs.isEmpty) const Text('まだグループを登録していません。'),
          for (final r in regs)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: r == selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: r == selected ? 2 : 1,
                ),
              ),
              child: ListTile(
                title: Text(r.groupName ?? '（元のグループは削除済み）'),
                subtitle: Text(_period(r.registration)),
                onTap: () => setState(() => _selected = r.registration.id),
              ),
            ),
          if (noIncome.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '登録していない期間は、その収入・支出がないものとして計算します。収入のグループがない年：${_ranges(noIncome)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (selected != null)
            _RegistrationDetail(
              key: ValueKey(selected.registration.id),
              summary: selected,
              lines: [
                for (final l in lines)
                  if (l.source == PlanLineSource.group.code &&
                      l.sourceId == selected.registration.id)
                    l,
              ],
            ),
        ],
      ),
    );
  }

  String _period(PlanGroupRow r) =>
      '${r.startYm.replaceAll('-', '/')}〜${r.endYm.replaceAll('-', '/')}';

  /// [2055, 2056, 2057, 2060] → 「2055〜2057年・2060年」
  String _ranges(List<int> years) {
    final parts = <String>[];
    var i = 0;
    while (i < years.length) {
      var j = i;
      while (j + 1 < years.length && years[j + 1] == years[j] + 1) {
        j++;
      }
      parts.add(i == j ? '${years[i]}年' : '${years[i]}〜${years[j]}年');
      i = j + 1;
    }
    return parts.join('・');
  }
}

class _RegistrationDetail extends ConsumerStatefulWidget {
  const _RegistrationDetail({
    super.key,
    required this.summary,
    required this.lines,
  });

  final RegistrationSummary summary;
  final List<PlanLineRow> lines;

  @override
  ConsumerState<_RegistrationDetail> createState() =>
      _RegistrationDetailState();
}

class _RegistrationDetailState extends ConsumerState<_RegistrationDetail> {
  late final r = widget.summary.registration;
  late YearMonth _rebuildFrom = YearMonth.parse(r.startYm);
  late int _delFrom = YearMonth.parse(r.startYm).year;
  late int _delTo = YearMonth.parse(r.startYm).year;

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              key: const Key('confirm-ok'),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('実行'),
            ),
          ],
        ),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(planLineRepositoryProvider);
    final start = YearMonth.parse(r.startYm);
    final end = YearMonth.parse(r.endYm);
    final byYear = <int, ({int income, int expense, int transfer})>{};
    for (final l in widget.lines) {
      final v = byYear[l.year] ?? (income: 0, expense: 0, transfer: 0);
      byYear[l.year] = switch (TxnKind.of(l.kind)) {
        TxnKind.income => (
          income: v.income + l.amount,
          expense: v.expense,
          transfer: v.transfer,
        ),
        TxnKind.expense => (
          income: v.income,
          expense: v.expense + l.amount,
          transfer: v.transfer,
        ),
        TxnKind.transfer => (
          income: v.income,
          expense: v.expense,
          transfer: v.transfer + l.amount,
        ),
      };
    }
    final years = byYear.keys.toList()..sort();
    final deleted = widget.summary.groupDeleted;

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.summary.groupName ?? '（元のグループは削除済み）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${r.startYm.replaceAll('-', '/')}〜${r.endYm.replaceAll('-', '/')}'
              '・上昇率の基準：${start.year}年・作成した計画行 ${widget.lines.length}件',
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 32,
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('年')),
                  DataColumn(label: Text('収入'), numeric: true),
                  DataColumn(label: Text('支出'), numeric: true),
                  DataColumn(label: Text('振替'), numeric: true),
                  DataColumn(label: Text('差引'), numeric: true),
                ],
                rows: [
                  for (final y in years)
                    DataRow(
                      cells: [
                        DataCell(Text('$y')),
                        DataCell(
                          Text(formatYen(byYear[y]!.income).substring(1)),
                        ),
                        DataCell(
                          Text(formatYen(byYear[y]!.expense).substring(1)),
                        ),
                        DataCell(
                          Text(formatYen(byYear[y]!.transfer).substring(1)),
                        ),
                        DataCell(
                          Text(
                            formatYenSigned(
                              byYear[y]!.income - byYear[y]!.expense,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '作成した計画行は、グループを後で変えても自動では変わりません。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SectionTitle('作り直し'),
            if (deleted)
              const WarningBox(
                message: '元のグループは削除済みのため、作り直しはできません。年範囲の削除と登録の取り消しはできます。',
              )
            else ...[
              YmPicker(
                key: const ValueKey('rebuild-from'),
                label: 'この年月以降を、今のグループの内容で作り直す',
                value: _rebuildFrom,
                min: start,
                max: end,
                onChanged: (v) => setState(() => _rebuildFrom = v),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('rebuild'),
                onPressed: () async {
                  if (!await _confirm(
                    '作り直しますか',
                    '${_rebuildFrom.year}年${_rebuildFrom.month}月以降の計画行を削除し、今のグループの内容で作り直します。'
                        '手で直した行も置き換わります。',
                  )) {
                    return;
                  }
                  await repo.rebuildFrom(r.id, _rebuildFrom);
                },
                child: const Text('作り直す（手で直した行も置き換え）'),
              ),
            ],
            const SectionTitle('削除'),
            Row(
              children: [
                Expanded(
                  child: _yearDropdown('開始年', _delFrom, start.year, end.year, (
                    v,
                  ) {
                    setState(() {
                      _delFrom = v;
                      if (_delTo < v) _delTo = v;
                    });
                  }),
                ),
                const Text('　〜　'),
                Expanded(
                  child: _yearDropdown('終了年', _delTo, _delFrom, end.year, (v) {
                    setState(() => _delTo = v);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('delete-range'),
              onPressed: () async {
                if (!await _confirm(
                  '計画行を削除しますか',
                  '$_delFrom年〜$_delTo年のこの登録の計画行を削除します（登録は残ります）。',
                )) {
                  return;
                }
                await repo.deleteYearRange(r.id, _delFrom, _delTo);
              },
              child: const Text('この範囲の計画行を削除（登録は残す）'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('cancel-registration'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                if (!await _confirm(
                  '登録を取り消しますか',
                  'この登録で作った計画行をすべて削除し、登録も削除します。',
                )) {
                  return;
                }
                await repo.cancelRegistration(r.id);
              },
              child: const Text('登録を取り消す（計画行ごと削除）'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearDropdown(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) => DropdownButtonFormField<int>(
    initialValue: value.clamp(min, max),
    decoration: InputDecoration(labelText: label),
    items: [
      for (var y = min; y <= max; y++)
        DropdownMenuItem(value: y, child: Text('$y年')),
    ],
    onChanged: (v) => onChanged(v!),
  );
}
