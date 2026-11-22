import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/txn_repository.dart';
import '../../domain/calc/event_matching.dart';
import '../../domain/models/enums.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/plan_switch_sheet.dart';
import '../shared/widgets.dart';
import 'event_common.dart';

/// イベント（一覧）（ワイヤーフレーム Events）：表示プランのイベントを年ごとに一覧（すべて／予定／実施済み）。
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  EventStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const PlanSwitchTitle(title: 'イベント')),
      );
    }
    final events =
        ref.watch(eventsProvider(plan.id)).value ?? const <PlanEventRow>[];
    final lines =
        ref.watch(eventLinesProvider(plan.id)).value ?? const <PlanLineRow>[];
    final txns =
        ref.watch(eventTxnsProvider(plan.id)).value ?? const <TxnRow>[];
    final members = {
      for (final m
          in ref.watch(membersProvider(plan.id)).value ??
              const <FamilyMemberRow>[])
        m.id: m,
    };
    final shown = [
      for (final e in events)
        if (_filter == null || e.status == _filter!.code) e,
    ];
    KindTotals planOf(String id) => kindTotals([
      for (final l in lines)
        if (l.eventId == id) matchItemOfLine(l),
    ]);
    KindTotals actualOf(String id) => kindTotals([
      for (final t in txns)
        if (t.eventId == id) matchItemOfTxn(t),
    ]);
    final planTotal = shown.fold(0, (a, e) => a + planOf(e.id).net);
    final doneDiff = [
      for (final e in shown)
        if (e.status == EventStatus.done.code)
          actualOf(e.id).net - planOf(e.id).net,
    ].fold(0, (a, b) => a + b);
    final years = <int, List<PlanEventRow>>{};
    for (final e in shown) {
      (years[e.year] ??= []).add(e);
    }

    return Scaffold(
      appBar: AppBar(title: const PlanSwitchTitle(title: 'イベント')),
      floatingActionButton: FloatingActionButton(
        key: const Key('event-add'),
        tooltip: 'イベントを追加',
        onPressed: () => context.push('/events/edit/new'),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SegmentedButton<EventStatus?>(
            segments: const [
              ButtonSegment(value: null, label: Text('すべて')),
              ButtonSegment(value: EventStatus.planned, label: Text('予定')),
              ButtonSegment(value: EventStatus.done, label: Text('実施済み')),
            ],
            selected: {_filter},
            onSelectionChanged: (v) => setState(() => _filter = v.first),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('予定の収支の合計\n${formatYenSigned(planTotal)}'),
                  ),
                  Expanded(
                    child: Text('実施済みの予実の差\n${formatYenSigned(doneDiff)}'),
                  ),
                ],
              ),
            ),
          ),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('イベントはありません')),
            ),
          for (final y in years.keys) ...[
            SectionTitle('$y年'),
            for (final e in years[y]!)
              Card(
                key: Key('event-${e.title}'),
                child: ListTile(
                  title: Row(
                    children: [
                      Flexible(child: Text(e.title)),
                      const SizedBox(width: 8),
                      EventStatusChip(e.status),
                    ],
                  ),
                  subtitle: Text(
                    '${eventWhen(e, members[e.memberId])}・予定の収支 ${lines.where((l) => l.eventId == e.id).length}件',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('予定 ${formatYenSigned(planOf(e.id).net)}'),
                      Text(
                        txns.any((t) => t.eventId == e.id)
                            ? '実績 ${formatYenSigned(actualOf(e.id).net)}'
                            : '実績なし',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () => context.push('/events/detail/${e.id}'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// イベント詳細（ワイヤーフレーム EventDetail）：予定と実績の合計・差、明細（全て／実績／予定）、関連する資産。
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

enum _Show { all, actual, plan }

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  _Show _show = _Show.all;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    final events = plan == null
        ? const <PlanEventRow>[]
        : (ref.watch(eventsProvider(plan.id)).value ?? const <PlanEventRow>[]);
    final e = events.where((x) => x.id == widget.eventId).firstOrNull;
    if (plan == null || e == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('このイベントは見つかりません')),
      );
    }
    final lines = [
      for (final l
          in ref.watch(eventLinesProvider(plan.id)).value ??
              const <PlanLineRow>[])
        if (l.eventId == e.id) l,
    ];
    final txns = [
      for (final t
          in ref.watch(eventTxnsProvider(plan.id)).value ?? const <TxnRow>[])
        if (t.eventId == e.id) t,
    ];
    final members = {
      for (final m
          in ref.watch(membersProvider(plan.id)).value ??
              const <FamilyMemberRow>[])
        m.id: m,
    };
    final assets = {
      for (final a
          in ref.watch(assetsProvider(plan.id)).value ?? const <AssetRow>[])
        a.id: a,
    };
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      ref.watch(accountsProvider).value ?? const [],
    );
    final p = kindTotals(lines.map(matchItemOfLine));
    final a = kindTotals(txns.map(matchItemOfTxn));
    final hasActual = txns.isNotEmpty;
    final related = {
      for (final x in [
        ...lines.map((l) => l.assetId),
        ...txns.map((t) => t.assetId),
      ])
        if (x != null && assets.containsKey(x)) x,
    };

    String cell(int v) => hasActual ? formatYen(v) : '—';
    String diff(int actual, int planned) =>
        hasActual ? formatYenSigned(actual - planned) : '—';

    return Scaffold(
      appBar: AppBar(
        title: Text(e.title),
        actions: [
          IconButton(
            tooltip: '編集',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/events/edit/${e.id}'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text(eventWhen(e, members[e.memberId]))),
              EventStatusChip(e.status),
            ],
          ),
          Text(
            '${plan.name}${e.memo == null ? '' : '・メモ：${e.memo}'}'
            '${e.doneDate == null ? '' : '・実施日 ${e.doneDate!.replaceAll('-', '/')}'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('event-actual'),
            onPressed: () => context.push('/events/actual/${e.id}'),
            child: const Text('実績を入力（イベントを実施）'),
          ),
          if (e.status == EventStatus.done.code)
            TextButton(
              onPressed: () => ref
                  .read(eventRepositoryProvider)
                  .setStatus(e.id, EventStatus.planned),
              child: const Text('予定に戻す'),
            ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {0: IntrinsicColumnWidth()},
            children: [
              const TableRow(
                children: [Text(''), Text('予定'), Text('実績'), Text('差')],
              ),
              TableRow(
                children: [
                  const Text('支出　'),
                  Text(formatYen(p.expense)),
                  Text(cell(a.expense)),
                  Text(diff(a.expense, p.expense)),
                ],
              ),
              TableRow(
                children: [
                  const Text('収入　'),
                  Text(formatYen(p.income)),
                  Text(cell(a.income)),
                  Text(diff(a.income, p.income)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<_Show>(
            segments: const [
              ButtonSegment(value: _Show.all, label: Text('全て')),
              ButtonSegment(value: _Show.actual, label: Text('実績')),
              ButtonSegment(value: _Show.plan, label: Text('予定')),
            ],
            selected: {_show},
            onSelectionChanged: (v) => setState(() => _show = v.first),
          ),
          if (_show != _Show.actual) ...[
            SectionTitle(
              '予定の収支',
              trailing: TextButton(
                onPressed: () => context.push('/events/edit/${e.id}'),
                child: const Text('＋ 予定を追加'),
              ),
            ),
            if (lines.isEmpty) const Text('予定の収支はありません'),
            for (final l in lines)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Text('予定'),
                title: Text(
                  l.memo ??
                      EventLineType.of(
                        TxnKind.of(l.kind),
                        l.assetAction == null
                            ? null
                            : AssetAction.of(l.assetAction!),
                      ).label,
                ),
                subtitle: Text(
                  eventItemLabel(
                    kind: TxnKind.of(l.kind),
                    action: l.assetAction == null
                        ? null
                        : AssetAction.of(l.assetAction!),
                    categoryId: l.categoryId,
                    accountId: l.accountId,
                    toAccountId: l.toAccountId,
                    assetName: assets[l.assetId]?.name,
                    lookup: lookup,
                  ),
                ),
                trailing: Text(signedAmount(TxnKind.of(l.kind), l.amount)),
                onTap: () => context.push('/entry/plan-line/${l.id}'),
              ),
          ],
          if (_show != _Show.plan) ...[
            const SectionTitle('実績'),
            if (txns.isEmpty)
              const Text('まだ実績はありません。「実績を入力」で、予定の収支をまとめて実績にできます。'),
            for (final t in txns)
              TxnTile(txn: ledgerTxnOf(t), lookup: lookup, prefix: '実績'),
          ],
          if (related.isNotEmpty) ...[
            const SectionTitle('関連する資産'),
            for (final id in related)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(assets[id]!.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/assets/detail/$id'),
              ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('event-delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('「${e.title}」を削除しますか'),
                  content: const Text(
                    '予定の収支も一緒に消えます。入力済みの実績は残り、イベントとの関連だけが外れます。',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      key: const Key('event-delete-confirm'),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              await ref.read(eventRepositoryProvider).deleteEvent(e.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('イベントを削除'),
          ),
        ],
      ),
    );
  }
}
