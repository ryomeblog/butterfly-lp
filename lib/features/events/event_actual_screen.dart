import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/calc/event_matching.dart';
import '../../domain/models/enums.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/widgets.dart';
import 'event_common.dart';
import 'event_edit_screen.dart';

/// イベントの実績入力（ワイヤーフレーム EventActual）。設計書 3.10。
///
/// 実施日（全項目共通）を決め、金額欄には予定の金額を初めから入れておく。金額を空にした項目は実績にしない。
/// すでに実績が入っている項目は空にしておく（一部だけ入力済みのイベントは残りの項目だけ）。
class EventActualScreen extends ConsumerStatefulWidget {
  const EventActualScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventActualScreen> createState() => _EventActualScreenState();
}

class _Row {
  _Row({required this.line, required this.label, String initial = ''})
    : amount = TextEditingController(text: initial);

  final EventLineDraft line;
  final String label;
  final TextEditingController amount;

  /// 予定の行なら予定額、予定になかった行なら null
  int? planned;
  int entered = 0;
}

class _EventActualScreenState extends ConsumerState<EventActualScreen> {
  PlanEventRow? _event;
  DateTime? _date;

  /// null は「予定どおり」
  String? _account;
  bool _markDone = true;
  final List<_Row> _rows = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(eventRepositoryProvider);
    final e = await repo.getEvent(widget.eventId);
    if (e == null) return;
    final lines = [
      for (final l in await ref.read(eventLinesProvider(e.planId).future))
        if (l.eventId == e.id) l,
    ];
    final txns = [
      for (final t in await ref.read(eventTxnsProvider(e.planId).future))
        if (t.eventId == e.id) t,
    ];
    final entered = eventLineActuals(
      lines.map(matchItemOfLine),
      txns.map(matchItemOfTxn),
    );
    for (final l in lines) {
      final done = entered[l.id] ?? 0;
      final row =
          _Row(
              line: EventLineDraft.of(l),
              label:
                  l.memo ??
                  EventLineType.of(
                    TxnKind.of(l.kind),
                    l.assetAction == null
                        ? null
                        : AssetAction.of(l.assetAction!),
                  ).label,
              initial: done == 0 ? '${l.amount}' : '',
            )
            ..planned = l.amount
            ..entered = done;
      _rows.add(row);
    }
    setState(() {
      _event = e;
      _date = parseDate(EventRepository.plannedDate(e));
      _loaded = true;
    });
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _addUnplanned() async {
    final line = await showModalBottomSheet<EventLineDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const EventLineSheet(),
    );
    if (line == null) return;
    setState(
      () => _rows.add(
        _Row(
          line: line,
          label:
              line.memo ?? EventLineType.of(line.kind, line.assetAction).label,
          initial: '${line.amount}',
        ),
      ),
    );
  }

  Future<void> _save() async {
    final e = _event!;
    final items = [
      for (final r in _rows)
        if ((int.tryParse(r.amount.text) ?? 0) > 0)
          EventActualItem(
            kind: r.line.kind,
            amount: int.parse(r.amount.text),
            // 振替の出金元・入金先は予定どおり。それ以外は「口座」でまとめて変えられる
            accountId: r.line.kind == TxnKind.transfer
                ? r.line.accountId
                : (_account ?? r.line.accountId),
            categoryId: r.line.categoryId,
            toAccountId: r.line.toAccountId,
            assetId: r.line.assetId,
            assetAction: r.line.assetAction,
            memo: r.line.memo,
          ),
    ];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('金額を入れた項目がありません')));
      return;
    }
    await ref
        .read(eventRepositoryProvider)
        .recordActual(
          event: e,
          doneDate: dateString(_date!),
          items: items,
          markDone: _markDone,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final e = _event;
    if (!_loaded || e == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final assets = {
      for (final a
          in ref.watch(assetsProvider(e.planId)).value ?? const <AssetRow>[])
        a.id: a,
    };
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      accounts,
    );
    final d = _date!;
    return Scaffold(
      appBar: AppBar(title: const Text('イベントの実績を入力')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${e.title}（予定 ${e.day == null ? '${e.year}年${e.month}月' : '${e.year}年${e.month}月${e.day}日'}）の予定の収支を実績にします。'
            '金額には予定の金額が入っています。予定どおりならそのまま保存し、違う項目だけ直します。'
            '金額を空にした項目は実績にしません。記録した項目は、どれもこのイベントの実績になります。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          InkWell(
            key: const Key('actual-date'),
            onTap: () async {
              final p = await showDatePicker(
                context: context,
                initialDate: d,
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
              );
              if (p != null) setState(() => _date = p);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: '実施日（全項目共通）'),
              child: Text('${d.year}/${d.month}/${d.day}'),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _account,
            decoration: const InputDecoration(labelText: '口座'),
            items: [
              const DropdownMenuItem(value: null, child: Text('予定どおり')),
              for (final a in accounts)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _account = v),
          ),
          const SizedBox(height: 8),
          for (final r in _rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label),
                          Text(
                            eventItemLabel(
                              kind: r.line.kind,
                              action: r.line.assetAction,
                              categoryId: r.line.categoryId,
                              accountId: r.line.accountId,
                              toAccountId: r.line.toAccountId,
                              assetName: assets[r.line.assetId]?.name,
                              lookup: lookup,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            r.planned == null
                                ? '予定になかった収支'
                                : '予定 ${formatYen(r.planned!)}'
                                      '${r.entered > 0 ? '・入力済み ${formatYen(r.entered)}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        key: Key('actual-${r.label}'),
                        controller: r.amount,
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          prefixText: '¥ ',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            onPressed: _addUnplanned,
            icon: const Icon(Icons.add),
            label: const Text('予定になかった収支を追加'),
          ),
          Text(
            '資産の購入は資産の動きとして記録し、評価額の資産は購入日の評価額にもなります。'
            '数量×単価の資産は、金額から実施日の単価で数量を計算します。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          CheckboxListTile(
            key: const Key('actual-mark-done'),
            contentPadding: EdgeInsets.zero,
            value: _markDone,
            onChanged: (v) => setState(() => _markDone = v!),
            title: const Text('保存したらイベントを「実施済み」にする'),
          ),
        ],
      ),
      bottomNavigationBar: SaveCancelBar(
        saveLabel: '実績を保存',
        saveKey: const Key('actual-save'),
        onSave: _save,
      ),
    );
  }
}
