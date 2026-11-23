import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/group_entry_repository.dart';
import '../../domain/calc/group_entry.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/group_item.dart';
import '../shared/widgets.dart';
import 'extra_item_sheet.dart';

/// グループから実績入力（ワイヤーフレーム GroupEntry）。設計書 3.2・6.6。
///
/// 金額欄には予定の金額（予定がない月はグループの金額）が入っている。予定どおりならそのまま保存し、
/// 明細と違う項目だけ直す。金額を空にした項目は実績にしない。
/// グループにない臨時の項目（その月だけの控除・補助など）は「項目を追加」で今回の入力だけに足せる。
class GroupEntryScreen extends ConsumerStatefulWidget {
  const GroupEntryScreen({super.key, this.groupId, this.ym});

  final String? groupId;
  final String? ym;

  @override
  ConsumerState<GroupEntryScreen> createState() => _GroupEntryScreenState();
}

class _GroupEntryScreenState extends ConsumerState<GroupEntryScreen> {
  String? _groupId;
  late DateTime _date;
  List<GroupItemDraft> _items = const [];
  final Map<String, TextEditingController> _amounts = {};
  Map<String, int?> _prefill = const {};
  Map<String, int> _planned = const {};
  bool _update = false;
  bool _loading = false;

  /// その回だけ足した臨時の項目（グループ・テンプレートには反映しない）
  final List<ExtraItem> _extras = [];

  @override
  void initState() {
    super.initState();
    _groupId = widget.groupId;
    final now = clock.now();
    if (widget.ym != null) {
      final ym = YearMonth.parse(widget.ym!);
      _date = ym == YearMonth.ofDate(now) ? now : ym.firstDay;
    } else {
      _date = now;
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    for (final e in _extras) {
      e.amount.dispose();
    }
    super.dispose();
  }

  YearMonth get _ym => YearMonth.ofDate(_date);

  Future<void> _load() async {
    final g = _groupId;
    final plan = ref.read(selectedPlanProvider).value;
    if (g == null || plan == null) return;
    setState(() => _loading = true);
    final items = await ref.read(templateRepositoryProvider).getGroupItems(g);
    final templates = {
      for (final t in await ref.readOnce(templatesProvider.future)) t.id: t,
    };
    final planAssets = {
      for (final a in await ref.readOnce(assetsProvider(plan.id).future)) a.id,
    };
    final lines = await ref.readOnce(
      planLinesProvider((planId: plan.id, from: _ym, to: _ym)).future,
    );
    final ids = {for (final i in items) i.id};
    final planned = <String, int>{};
    for (final l in lines) {
      if (l.groupItemId != null && ids.contains(l.groupItemId)) {
        planned[l.groupItemId!] = (planned[l.groupItemId!] ?? 0) + l.amount;
      }
    }
    // 別のプランの資産を参照するテンプレートの項目は使えない
    final usableTemplates = {
      for (final t in templates.values)
        if (t.assetId == null || planAssets.contains(t.assetId)) t.id: t.amount,
    };
    final prefill = entryPrefill(
      items: items,
      templateAmounts: usableTemplates,
      plannedByItem: planned,
      ym: _ym,
    );
    for (final c in _amounts.values) {
      c.dispose();
    }
    _amounts
      ..clear()
      ..addAll({
        for (final e in prefill.entries)
          e.key: TextEditingController(text: e.value?.toString() ?? '')
            ..addListener(() => setState(() {})),
      });
    if (!mounted) return;
    setState(() {
      _items = items;
      _prefill = prefill;
      _planned = planned;
      _loading = false;
    });
  }

  Future<void> _save(Map<String, TemplateRow> templates) async {
    final plan = ref.read(selectedPlanProvider).value;
    if (plan == null || _groupId == null) return;
    final entered = <String, int>{
      for (final e in _amounts.entries)
        if ((int.tryParse(e.value.text) ?? 0) > 0)
          e.key: int.parse(e.value.text),
    };
    final extras = [
      for (final e in _extras)
        if ((int.tryParse(e.amount.text) ?? 0) > 0) e,
    ];
    if (entered.isEmpty && extras.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('金額を入れた項目がありません')));
      return;
    }
    final repo = ref.read(groupEntryRepositoryProvider);
    await repo.saveEntry(
      planId: plan.id,
      groupId: _groupId!,
      date: dateString(_date),
      lines: [
        for (final i in _items)
          if (entered.containsKey(i.id))
            GroupEntryLine.fromTemplate(
              itemId: i.id,
              template: templates[i.templateId]!,
              amount: entered[i.id]!,
            ),
        for (final e in extras)
          GroupEntryLine(
            itemId: null,
            kind: e.kind,
            amount: int.parse(e.amount.text),
            accountId: e.accountId,
            categoryId: e.categoryId,
            toAccountId: e.toAccountId,
            assetId: e.assetId,
            assetAction: e.assetAction,
            memo: e.fromTemplate ? e.memo : e.name,
          ),
      ],
    );
    // 臨時の項目はグループの更新に使わない
    if (_update) await repo.applyUpdate(updateFromEntry(_items, entered));
    if (mounted) Navigator.of(context).pop();
  }

  /// グループの項目の口座（振替以外の最初のもの）。直接入力の口座の初期値にする。
  String? _defaultAccount(Map<String, TemplateRow> templates) {
    for (final i in _items) {
      final t = templates[i.templateId];
      if (t != null && t.kind != TxnKind.transfer.code && t.accountId != null) {
        return t.accountId;
      }
    }
    return ref.read(accountsProvider).value?.firstOrNull?.id;
  }

  /// 「項目を追加」：テンプレートから選ぶか、直接入力する（設計書 6.6）。
  Future<void> _addExtra(Map<String, TemplateRow> templates) async {
    // シートを閉じたあと金額欄にフォーカスが戻ってキーボードが開かないようにする
    FocusScope.of(context).unfocus();
    final how = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('今回の入力だけに項目を足します'),
              subtitle: Text('グループ・テンプレートは変わりません'),
            ),
            ListTile(
              key: const Key('extra-from-template'),
              leading: const Icon(Icons.description_outlined),
              title: const Text('テンプレートから選ぶ'),
              onTap: () => Navigator.pop(context, 'template'),
            ),
            ListTile(
              key: const Key('extra-direct'),
              leading: const Icon(Icons.edit_outlined),
              title: const Text('直接入力'),
              onTap: () => Navigator.pop(context, 'direct'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || how == null) return;
    if (how == 'direct') {
      final d = await showExtraItemSheet(
        context,
        defaultAccountId: _defaultAccount(templates),
      );
      if (d == null) return;
      _addItem(
        ExtraItem(
          kind: d.kind,
          name: d.name,
          accountId: d.accountId,
          categoryId: d.categoryId,
          toAccountId: d.toAccountId,
        ),
      );
      return;
    }
    // 資産を参照するテンプレートは、その資産のプランでだけ使える。カテゴリ・口座が空のものは使えない（3.2・3.7）
    final plan = ref.read(selectedPlanProvider).value;
    final planAssets = plan == null
        ? const <String>{}
        : {
            for (final a in await ref.readOnce(assetsProvider(plan.id).future))
              a.id,
          };
    final usable = templates.values.where((t) {
      if (t.assetId != null && !planAssets.contains(t.assetId)) return false;
      if (t.accountId == null) return false;
      return t.kind == TxnKind.transfer.code
          ? t.toAccountId != null
          : t.categoryId != null;
    }).toList();
    if (!mounted) return;
    final picked = await showModalBottomSheet<TemplateRow>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: usable.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('使えるテンプレートがありません。ホームの「テンプレート」で作れます。'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final t in usable)
                    ListTile(
                      key: Key('extra-template-${t.name}'),
                      leading: KindBadge(TxnKind.of(t.kind).label),
                      title: Text(t.name),
                      trailing: Text(
                        t.amount == null ? '—' : formatYen(t.amount!),
                      ),
                      onTap: () => Navigator.pop(context, t),
                    ),
                ],
              ),
      ),
    );
    if (picked == null) return;
    _addItem(ExtraItem.fromTemplate(picked));
  }

  void _addItem(ExtraItem e) {
    e.amount.addListener(() => setState(() {}));
    setState(() => _extras.add(e));
  }

  Future<void> _editExtra(ExtraItem e) async {
    FocusScope.of(context).unfocus();
    final d = await showExtraItemSheet(
      context,
      initial: (
        kind: e.kind,
        name: e.name,
        categoryId: e.categoryId,
        accountId: e.accountId,
        toAccountId: e.toAccountId,
      ),
    );
    if (d == null) return;
    setState(() {
      e
        ..kind = d.kind
        ..name = d.name
        ..categoryId = d.categoryId
        ..accountId = d.accountId
        ..toAccountId = d.toAccountId;
    });
  }

  void _removeExtra(ExtraItem e) {
    FocusScope.of(context).unfocus();
    setState(() => _extras.remove(e));
    e.amount.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupSummariesProvider).value ?? const [];
    final templates = {
      for (final t
          in ref.watch(templatesProvider).value ?? const <TemplateRow>[])
        t.id: t,
    };
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const <AccountRow>[])
        a.id: a,
    };
    final missing = [
      for (final i in _items)
        if (!_prefill.containsKey(i.id)) i,
    ];
    var income = 0;
    var expense = 0;
    var transfer = 0;
    void add(TxnKind kind, String text) {
      final v = int.tryParse(text) ?? 0;
      switch (kind) {
        case TxnKind.income:
          income += v;
        case TxnKind.expense:
          expense += v;
        case TxnKind.transfer:
          transfer += v;
      }
    }

    for (final i in _items) {
      final t = templates[i.templateId];
      if (t == null) continue;
      add(TxnKind.of(t.kind), _amounts[i.id]?.text ?? '');
    }
    for (final e in _extras) {
      add(e.kind, e.amount.text);
    }
    final count = [
      ..._amounts.values,
      for (final e in _extras) e.amount,
    ].where((c) => (int.tryParse(c.text) ?? 0) > 0).length;
    final categories = {
      for (final c
          in ref.watch(categoriesProvider).value ?? const <CategoryRow>[])
        c.id: c,
    };
    String nameOf(String? itemId) {
      final i = _items.where((x) => x.id == itemId).firstOrNull;
      return templates[i?.templateId]?.name ?? '?';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('グループから実績入力')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            key: const Key('entry-group'),
            initialValue: groups.any((g) => g.group.id == _groupId)
                ? _groupId
                : null,
            decoration: const InputDecoration(labelText: 'グループ'),
            items: [
              for (final g in groups)
                DropdownMenuItem(value: g.group.id, child: Text(g.group.name)),
            ],
            onChanged: (v) {
              _groupId = v;
              _load();
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
              );
              if (d == null) return;
              final monthChanged = YearMonth.ofDate(d) != _ym;
              setState(() => _date = d);
              if (monthChanged) _load();
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: '日付（全項目共通）'),
              child: Text('${_date.year}/${_date.month}/${_date.day}'),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            WarningBox(
              message:
                  'このグループには使えない項目が${missing.length}件あり、入力欄に出していません'
                  '（削除されたテンプレート、または別のプランの資産を参照するテンプレート）。',
              actions: [
                OutlinedButton(
                  onPressed: () async {
                    await context.push('/home/group/$_groupId');
                    _load();
                  },
                  child: const Text('グループを修正する'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (_groupId != null)
            Text(
              '金額には予定の金額（予定がない月はグループの金額）が入っています。予定どおりならそのまま保存し、'
              '明細と違う項目だけ直します。金額を空にした項目は実績にしません。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          for (final i in _items)
            if (_prefill.containsKey(i.id))
              Builder(
                builder: (context) {
                  final t = templates[i.templateId]!;
                  final kind = TxnKind.of(t.kind);
                  final hint = _planned.containsKey(i.id)
                      ? '予定 ${formatYen(_planned[i.id]!)}（${_ym.month}月の予定）'
                      : _planned.isNotEmpty
                      ? '${_ym.month}月は予定なし'
                      : i.amountMode == AmountMode.percent
                      ? '${nameOf(i.baseItemId)}の ${i.percent}%'
                      : (_prefill[i.id] == null
                            ? '${_ym.month}月は発生しない（${describeFrequency(i)}）'
                            : 'グループの金額');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: KindBadge(kind.label),
                    title: Text(t.name),
                    subtitle: Text(
                      kind == TxnKind.transfer
                          ? '$hint・${accounts[t.accountId]?.name ?? '?'} → ${accounts[t.toAccountId]?.name ?? '?'}'
                          : hint,
                    ),
                    trailing: SizedBox(
                      width: 120,
                      child: TextField(
                        key: Key('entry-${t.name}'),
                        controller: _amounts[i.id],
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
                  );
                },
              ),
          if (_groupId != null && !_loading) ...[
            const SizedBox(height: 8),
            if (_extras.isNotEmpty) const SectionTitle('臨時の項目（今回のみ）'),
            for (final e in _extras)
              ListTile(
                key: e.key,
                contentPadding: EdgeInsets.zero,
                leading: KindBadge(e.kind.label),
                title: Text(e.name),
                subtitle: Text(
                  [
                    e.kind == TxnKind.transfer
                        ? '${accounts[e.accountId]?.name ?? '?'} → ${accounts[e.toAccountId]?.name ?? '?'}'
                        : (categories[e.categoryId]?.name ?? '?'),
                    if (e.fromTemplate) 'テンプレート' else 'タップで変更',
                  ].join('・'),
                ),
                onTap: e.fromTemplate ? null : () => _editExtra(e),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        key: Key('extra-amount-${e.name}'),
                        controller: e.amount,
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
                    IconButton(
                      key: Key('extra-remove-${e.name}'),
                      tooltip: '外す',
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeExtra(e),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('entry-add-extra'),
                onPressed: () => _addExtra(templates),
                icon: const Icon(Icons.add),
                label: const Text('項目を追加（今回のみ）'),
              ),
            ),
          ],
          if (_items.isNotEmpty || _extras.isNotEmpty) ...[
            const Divider(),
            Text(
              '収入 ${formatYenSigned(income)}　支出 ${formatYenSigned(-expense)}　振替 ${formatYen(transfer)}',
            ),
            Text(
              '差引（収入−支出−振替） ${formatYenSigned(income - expense - transfer)}',
              key: const Key('entry-net'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '明細の「差引支給額」と合っているか確認できます。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            CheckboxListTile(
              key: const Key('entry-update'),
              contentPadding: EdgeInsets.zero,
              value: _update,
              onChanged: (v) => setState(() => _update = v!),
              title: const Text('入力した実績でグループの金額・割合を更新する'),
              subtitle: _extras.isEmpty ? null : const Text('臨時の項目はグループに入れません'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SaveCancelBar(
        saveKey: const Key('entry-save'),
        saveLabel: '$count件の実績を保存',
        onSave: count == 0 ? null : () => _save(templates),
      ),
    );
  }
}
