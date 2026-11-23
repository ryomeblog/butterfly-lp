import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/ids.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/models/enums.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/widgets.dart';
import '../shared/ym_picker.dart';
import 'event_common.dart';

enum _When { date, ym, age }

/// イベントの追加・編集（ワイヤーフレーム EventEdit）。
///
/// 名前・対象の家族・予定の時期（「日付／年月／年齢」で切り替え。年齢は年月に置き換えて保存）・メモ、
/// 予定の収支（支出・収入・振替・資産の購入／売却など）の行（設計書 3.10）。
class EventEditScreen extends ConsumerStatefulWidget {
  const EventEditScreen({super.key, this.eventId});

  final String? eventId;

  @override
  ConsumerState<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends ConsumerState<EventEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _memo = TextEditingController();
  String? _memberId;
  _When _when = _When.ym;
  DateTime _date = clock.now();
  YearMonth _ym = YearMonth.ofDate(clock.now());
  int _age = 40;
  int _ageMonth = 4;
  List<EventLineDraft> _lines = [];
  bool _loaded = false;

  bool get _isNew => widget.eventId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.eventId;
    if (id != null) {
      final repo = ref.read(eventRepositoryProvider);
      final e = await repo.getEvent(id);
      if (e != null) {
        _title.text = e.title;
        _memo.text = e.memo ?? '';
        _memberId = e.memberId;
        if (e.day != null) {
          _when = _When.date;
          _date = DateTime(e.year, e.month, e.day!);
        }
        _ym = YearMonth(e.year, e.month);
        final lines = await ref.readOnce(eventLinesProvider(e.planId).future);
        _lines = [
          for (final l in lines)
            if (l.source == PlanLineSource.event.code && l.sourceId == e.id)
              EventLineDraft.of(l),
        ];
      }
    } else {
      final plan = ref.read(selectedPlanProvider).value;
      if (plan != null) _memberId = plan.protagonistMemberId;
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _memo.dispose();
    super.dispose();
  }

  /// 保存する年月と日。
  (int, int, int?) _resolved(FamilyMemberRow? member) => switch (_when) {
    _When.date => (_date.year, _date.month, _date.day),
    _When.ym => (_ym.year, _ym.month, null),
    _When.age => (
      member == null ? _ym.year : parseDate(member.birthDate).year + _age,
      _ageMonth,
      null,
    ),
  };

  Future<void> _save(List<FamilyMemberRow> members) async {
    if (!_form.currentState!.validate()) return;
    final plan = ref.read(selectedPlanProvider).value;
    if (plan == null) return;
    final member = members.where((m) => m.id == _memberId).firstOrNull;
    final (y, m, d) = _resolved(member);
    await ref
        .read(eventRepositoryProvider)
        .saveEvent(
          eventId: widget.eventId,
          input: EventInput(
            planId: plan.id,
            memberId: _memberId!,
            title: _title.text.trim(),
            year: y,
            month: m,
            day: d,
            memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
          ),
          lines: _lines,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _editLine(EventLineDraft? line) async {
    final result = await showModalBottomSheet<EventLineDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EventLineSheet(line: line),
    );
    if (result == null) return;
    setState(() {
      final i = _lines.indexWhere((l) => l.id == result.id);
      if (i >= 0) {
        _lines[i] = result;
      } else {
        _lines = [..._lines, result];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    final members = plan == null
        ? const <FamilyMemberRow>[]
        : (ref.watch(membersProvider(plan.id)).value ??
              const <FamilyMemberRow>[]);
    final member = members.where((m) => m.id == _memberId).firstOrNull;
    final assets = {
      for (final a
          in plan == null
              ? const <AssetRow>[]
              : (ref.watch(assetsProvider(plan.id)).value ??
                    const <AssetRow>[]))
        a.id: a,
    };
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      ref.watch(accountsProvider).value ?? const [],
    );
    final (ry, rm, rd) = _resolved(member);

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'イベントを追加' : 'イベントを編集')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('event-title'),
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'イベント名'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '入力してください' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: members.any((m) => m.id == _memberId)
                        ? _memberId
                        : null,
                    decoration: const InputDecoration(labelText: '対象の家族'),
                    items: [
                      for (final m in members)
                        DropdownMenuItem(value: m.id, child: Text(m.name)),
                    ],
                    validator: (v) => v == null ? '選んでください' : null,
                    onChanged: (v) => setState(() => _memberId = v),
                  ),
                  const SectionTitle('予定の時期'),
                  SegmentedButton<_When>(
                    key: const Key('event-when'),
                    segments: const [
                      ButtonSegment(value: _When.date, label: Text('日付')),
                      ButtonSegment(value: _When.ym, label: Text('年月')),
                      ButtonSegment(value: _When.age, label: Text('年齢')),
                    ],
                    selected: {_when},
                    onSelectionChanged: (v) => setState(() {
                      if (v.first == _When.age && member != null) {
                        _age = ageInYear(member, ry);
                        _ageMonth = rm;
                      }
                      _when = v.first;
                    }),
                  ),
                  const SizedBox(height: 12),
                  switch (_when) {
                    _When.date => OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2200),
                        );
                        if (d != null) setState(() => _date = d);
                      },
                      child: Text('${_date.year}年${_date.month}月${_date.day}日'),
                    ),
                    _When.ym => YmPicker(
                      key: const ValueKey('event-ym'),
                      label: '年月',
                      value: _ym,
                      min: YearMonth(1900, 1),
                      max: YearMonth(2200, 12),
                      onChanged: (v) => setState(() => _ym = v),
                    ),
                    _When.age => Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: const Key('event-age'),
                            initialValue: _age.clamp(0, 120),
                            decoration: InputDecoration(
                              labelText: '${member?.name ?? ''}の年齢',
                            ),
                            items: [
                              for (var a = 0; a <= 120; a++)
                                DropdownMenuItem(value: a, child: Text('$a歳')),
                            ],
                            onChanged: (v) => setState(() => _age = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _ageMonth,
                            decoration: const InputDecoration(labelText: '月'),
                            items: [
                              for (var m = 1; m <= 12; m++)
                                DropdownMenuItem(value: m, child: Text('$m月')),
                            ],
                            onChanged: (v) => setState(() => _ageMonth = v!),
                          ),
                        ),
                      ],
                    ),
                  },
                  const SizedBox(height: 8),
                  Text(
                    '保存する時期：$ry年$rm月${rd == null ? '' : '$rd日'}'
                    '${member == null ? '' : '（${member.name} ${ageInYear(member, ry)}歳）'}'
                    '${_when == _When.ym ? '。実績を入力するときの実施日は、その月の1日が初期値です。' : ''}'
                    '${_when == _When.age ? '。年齢は年月に置き換えて保存します。' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _memo,
                    decoration: const InputDecoration(labelText: 'メモ'),
                  ),
                  SectionTitle(
                    '予定の収支（計画行）',
                    trailing: TextButton(
                      key: const Key('event-line-add'),
                      onPressed: () => _editLine(null),
                      child: const Text('＋ 行を追加'),
                    ),
                  ),
                  Text(
                    '支出・収入・振替・資産の購入／売却を入れられます。行を押すと編集します。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  for (final l in _lines)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.memo ?? EventLineType.of(l.kind, l.assetAction).label,
                      ),
                      subtitle: Text(
                        eventItemLabel(
                          kind: l.kind,
                          action: l.assetAction,
                          categoryId: l.categoryId,
                          accountId: l.accountId,
                          toAccountId: l.toAccountId,
                          assetName: assets[l.assetId]?.name,
                          lookup: lookup,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(signedAmount(l.kind, l.amount)),
                          IconButton(
                            tooltip: '行を外す',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(
                              () => _lines = [
                                for (final x in _lines)
                                  if (x.id != l.id) x,
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _editLine(l),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SaveCancelBar(
        saveKey: const Key('event-save'),
        onSave: _loaded ? () => _save(members) : null,
      ),
    );
  }
}

/// 予定の収支1行の入力（イベントの編集と、実績入力の「予定になかった収支」で使う）。
class EventLineSheet extends ConsumerStatefulWidget {
  const EventLineSheet({super.key, this.line});

  final EventLineDraft? line;

  @override
  ConsumerState<EventLineSheet> createState() => _EventLineSheetState();
}

class _EventLineSheetState extends ConsumerState<EventLineSheet> {
  final _form = GlobalKey<FormState>();
  late EventLineType _type = widget.line == null
      ? EventLineType.expense
      : EventLineType.of(widget.line!.kind, widget.line!.assetAction);
  late final _amount = TextEditingController(
    text: widget.line?.amount.toString() ?? '',
  );
  late final _memo = TextEditingController(text: widget.line?.memo ?? '');
  late String? _categoryId = widget.line?.categoryId;
  late String? _accountId = widget.line?.accountId;
  late String? _toAccountId = widget.line?.toAccountId;
  late String? _assetId = widget.line?.assetId;

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    final assets = plan == null
        ? const <AssetRow>[]
        : (ref.watch(assetsProvider(plan.id)).value ?? const <AssetRow>[]);
    final categories =
        ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final cats = [
      for (final c in categories)
        if (c.kind == _type.kind.code) c,
    ];
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<EventLineType>(
                  key: const Key('line-type'),
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: '種類'),
                  items: [
                    for (final t in EventLineType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (v) => setState(() {
                    _type = v!;
                    if (!cats.any(
                      (c) => c.id == _categoryId && c.kind == _type.kind.code,
                    )) {
                      _categoryId = null;
                    }
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _memo,
                  decoration: const InputDecoration(labelText: '項目名（例：頭金・諸費用）'),
                ),
                const SizedBox(height: 12),
                YenField(key: const Key('line-amount'), controller: _amount),
                if (_type.action != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('line-asset'),
                    initialValue: assets.any((a) => a.id == _assetId)
                        ? _assetId
                        : null,
                    decoration: const InputDecoration(labelText: '資産'),
                    items: [
                      for (final a in assets)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    validator: (v) =>
                        v == null ? '選んでください（先に資産タブで資産を登録します）' : null,
                    onChanged: (v) => setState(() => _assetId = v),
                  ),
                ],
                if (_type.kind != TxnKind.transfer) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('line-category'),
                    initialValue: cats.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null,
                    decoration: const InputDecoration(labelText: 'カテゴリ'),
                    items: [
                      for (final c in cats)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    validator: (v) => v == null ? '選んでください' : null,
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('line-account'),
                  initialValue: accounts.any((a) => a.id == _accountId)
                      ? _accountId
                      : null,
                  decoration: InputDecoration(
                    labelText: _type.kind == TxnKind.income
                        ? '入金口座'
                        : '口座（出金元）',
                  ),
                  items: [
                    for (final a in accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  validator: (v) => v == null ? '選んでください' : null,
                  onChanged: (v) => setState(() => _accountId = v),
                ),
                if (_type.kind == TxnKind.transfer) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: accounts.any((a) => a.id == _toAccountId)
                        ? _toAccountId
                        : null,
                    decoration: const InputDecoration(labelText: '入金先口座'),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    validator: (v) => v == null ? '選んでください' : null,
                    onChanged: (v) => setState(() => _toAccountId = v),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('line-ok'),
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    Navigator.pop(
                      context,
                      EventLineDraft(
                        id: widget.line?.id ?? newId(),
                        kind: _type.kind,
                        amount: int.parse(_amount.text),
                        accountId: _accountId!,
                        categoryId: _type.kind == TxnKind.transfer
                            ? null
                            : _categoryId,
                        toAccountId: _type.kind == TxnKind.transfer
                            ? _toAccountId
                            : null,
                        assetId: _type.action == null ? null : _assetId,
                        assetAction: _type.action,
                        memo: _memo.text.trim().isEmpty
                            ? null
                            : _memo.text.trim(),
                      ),
                    );
                  },
                  child: const Text('この行にする'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
