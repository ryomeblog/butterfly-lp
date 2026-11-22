import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/plan_line_repository.dart';
import '../../domain/calc/compare.dart';
import '../../domain/models/enums.dart';
import '../events/event_common.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/widgets.dart';
import 'compare_common.dart';

enum _KindFilter { all, expense, income, transfer, asset }

/// 予定から実績入力（ワイヤーフレーム PlannedEntry）。設計書 3.8。
///
/// 実績が未入力の予定を一覧する。グループ由来はグループごと（まとめて入力）、イベント由来はイベントごと
/// （イベントの実績を入力）、手入力の予定はその後に1件ずつ。
class PlannedEntryScreen extends ConsumerStatefulWidget {
  const PlannedEntryScreen({super.key, this.year, this.month});

  final int? year;
  final int? month;

  @override
  ConsumerState<PlannedEntryScreen> createState() => _PlannedEntryScreenState();
}

class _PlannedEntryScreenState extends ConsumerState<PlannedEntryScreen> {
  late int _year = widget.year ?? clock.now().year;
  late int? _month = widget.month;
  bool _onlyOpen = true;
  _KindFilter _kind = _KindFilter.all;

  bool _matchesKind(PlanLineRow l) => switch (_kind) {
    _KindFilter.all => true,
    _KindFilter.expense => l.kind == TxnKind.expense.code && l.assetId == null,
    _KindFilter.income => l.kind == TxnKind.income.code && l.assetId == null,
    _KindFilter.transfer => l.kind == TxnKind.transfer.code,
    _KindFilter.asset => l.assetId != null,
  };

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    if (plan == null) return Scaffold(appBar: AppBar());
    final from = YearMonth(_year, _month ?? 1);
    final to = YearMonth(_year, _month ?? 12);
    final lines =
        ref
            .watch(planLinesProvider((planId: plan.id, from: from, to: to)))
            .value ??
        const <PlanLineRow>[];
    final txns =
        ref
            .watch(txnsProvider((planId: plan.id, from: null, to: null)))
            .value ??
        const <TxnRow>[];
    final regs = <String, RegistrationSummary>{
      for (final r
          in ref.watch(registrationsProvider(plan.id)).value ?? const [])
        r.registration.id: r,
    };
    final events = {
      for (final e
          in ref.watch(eventsProvider(plan.id)).value ?? const <PlanEventRow>[])
        e.id: e,
    };
    final members = {
      for (final m
          in ref.watch(membersProvider(plan.id)).value ??
              const <FamilyMemberRow>[])
        m.id: m,
    };
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      ref.watch(accountsProvider).value ?? const [],
    );
    final actuals = planActuals(lines.map(planItemOf), txns.map(actualItemOf));
    final shown = [
      for (final l in lines)
        if (_matchesKind(l) && (!_onlyOpen || (actuals[l.id] ?? 0) == 0)) l,
    ];
    final open = [
      for (final l in lines)
        if (_matchesKind(l) && (actuals[l.id] ?? 0) == 0) l,
    ];
    final thisMonth = YearMonth.ofDate(clock.now());
    final past = [
      for (final l in open)
        if (YearMonth(l.year, l.month) <= thisMonth) l,
    ];
    final future = [
      for (final l in open)
        if (YearMonth(l.year, l.month) > thisMonth) l,
    ];
    int sum(List<PlanLineRow> ls) => ls.fold(0, (a, l) => a + l.amount);

    final byMonth = <int, List<PlanLineRow>>{};
    for (final l in shown) {
      (byMonth[l.month] ??= []).add(l);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('予定から実績入力')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '予定＝表示中の「${plan.name}」の計画。支出・収入・振替・資産の購入／売却を、実績が未入力のものから入力します。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  if (_month == null) {
                    _year--;
                  } else {
                    final p = YearMonth(_year, _month!).addMonths(-1);
                    _year = p.year;
                    _month = p.month;
                  }
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(_month == null ? '$_year年' : '$_year年$_month月'),
              IconButton(
                onPressed: () => setState(() {
                  if (_month == null) {
                    _year++;
                  } else {
                    final n = YearMonth(_year, _month!).addMonths(1);
                    _year = n.year;
                    _month = n.month;
                  }
                }),
                icon: const Icon(Icons.chevron_right),
              ),
              const Spacer(),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('年')),
                  ButtonSegment(value: false, label: Text('月')),
                ],
                selected: {_month == null},
                onSelectionChanged: (v) => setState(
                  () => _month = v.first
                      ? null
                      : (_year == thisMonth.year ? thisMonth.month : 1),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('未入力')),
                  ButtonSegment(value: false, label: Text('すべて')),
                ],
                selected: {_onlyOpen},
                onSelectionChanged: (v) => setState(() => _onlyOpen = v.first),
              ),
              DropdownButton<_KindFilter>(
                value: _kind,
                items: const [
                  DropdownMenuItem(value: _KindFilter.all, child: Text('全種類')),
                  DropdownMenuItem(
                    value: _KindFilter.expense,
                    child: Text('支出'),
                  ),
                  DropdownMenuItem(
                    value: _KindFilter.income,
                    child: Text('収入'),
                  ),
                  DropdownMenuItem(
                    value: _KindFilter.transfer,
                    child: Text('振替'),
                  ),
                  DropdownMenuItem(value: _KindFilter.asset, child: Text('資産')),
                ],
                onChanged: (v) => setState(() => _kind = v!),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${_month == null ? '$_year年' : '$_month月'}の予定のうち実績が未入力：${open.length}件（${formatYen(sum(open))} 分）\n'
                '今日までの月 ${past.length}件（${formatYen(sum(past))} 分）／これからの月 ${future.length}件（${formatYen(sum(future))} 分）',
                key: const Key('planned-summary'),
              ),
            ),
          ),
          Text(
            'グループの予定はグループ単位、イベントの予定はイベント単位でまとめて表示します。'
            '「入力」で開く画面には、予定の金額・カテゴリ・口座が入っています（予定どおりならそのまま保存）。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('予定はありません')),
            ),
          for (final m in byMonth.keys) ...[
            SectionTitle(
              '$_year年$m月'
              '${YearMonth(_year, m) > thisMonth ? '（これからの月）' : ''}',
            ),
            ..._monthBlocks(
              context,
              byMonth[m]!,
              actuals,
              regs,
              events,
              members,
              lookup,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _monthBlocks(
    BuildContext context,
    List<PlanLineRow> lines,
    Map<String, int> actuals,
    Map<String, RegistrationSummary> regs,
    Map<String, PlanEventRow> events,
    Map<String, FamilyMemberRow> members,
    Lookup lookup,
  ) {
    final groups = <String, List<PlanLineRow>>{};
    final evs = <String, List<PlanLineRow>>{};
    final manual = <PlanLineRow>[];
    for (final l in lines) {
      if (l.eventId != null) {
        (evs[l.eventId!] ??= []).add(l);
      } else if (l.source == PlanLineSource.group.code && l.sourceId != null) {
        (groups[l.sourceId!] ??= []).add(l);
      } else {
        manual.add(l);
      }
    }
    final ym = YearMonth(lines.first.year, lines.first.month);
    Widget row(PlanLineRow l, {bool single = true}) {
      final done = actuals[l.id] ?? 0;
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(
          '${l.memo ?? lookup.categoryName(l.categoryId)}　${done == 0 ? '未入力' : '入力済み'}',
        ),
        subtitle: Text(
          '${EventLineType.of(TxnKind.of(l.kind), l.assetAction == null ? null : AssetAction.of(l.assetAction!)).label}'
          '・${lookup.categoryName(l.categoryId)}・${lookup.accountName(l.accountId)}'
          '\n予定 ${signedAmount(TxnKind.of(l.kind), l.amount)}'
          '${done == 0 ? '' : '　実績 ${signedAmount(TxnKind.of(l.kind), done)}'}',
        ),
        trailing: single && done == 0
            ? TextButton(
                key: Key('enter-${l.id}'),
                onPressed: () =>
                    context.push('/entry/txn/new?fromLine=${l.id}'),
                child: const Text('入力'),
              )
            : null,
      );
    }

    return [
      for (final e in groups.entries)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'グループ「${regs[e.key]?.groupName ?? '（削除済みのグループ）'}」',
                      ),
                    ),
                    if (regs[e.key]?.groupName != null)
                      TextButton(
                        key: Key('group-entry-${regs[e.key]!.groupName}'),
                        onPressed: () => context.push(
                          '/entry/group?group=${regs[e.key]!.registration.groupId}&ym=$ym',
                        ),
                        child: const Text('まとめて入力'),
                      ),
                  ],
                ),
                for (final l in e.value) row(l),
              ],
            ),
          ),
        ),
      for (final e in evs.entries)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        events[e.key] == null
                            ? 'イベント'
                            : 'イベント「${events[e.key]!.title}」\n'
                                  '${eventWhen(events[e.key]!, members[events[e.key]!.memberId])}・'
                                  '${EventStatus.of(events[e.key]!.status).label}',
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/events/actual/${e.key}'),
                      child: const Text('イベントの実績を入力'),
                    ),
                  ],
                ),
                // イベントの予定は1件ずつには入力せず、まとめて入力する（設計書 3.8）
                for (final l in e.value) row(l, single: false),
              ],
            ),
          ),
        ),
      if (manual.isNotEmpty) ...[
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('手入力の予定')),
        for (final l in manual) row(l),
      ],
    ];
  }
}
