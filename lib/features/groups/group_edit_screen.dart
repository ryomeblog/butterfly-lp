import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/calc/group_entry.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/group_item.dart';
import '../shared/widgets.dart';

/// グループ編集（ワイヤーフレーム GroupEdit）。
///
/// 項目の追加、項目ごとの頻度、金額（固定額か別の項目の○%）。グループは期間を持たない。
/// 削除されたテンプレートの項目は警告し、その場で外すか別のテンプレートを選び直せる（設計書 3.2）。
class GroupEditScreen extends ConsumerStatefulWidget {
  const GroupEditScreen({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends ConsumerState<GroupEditScreen> {
  final _name = TextEditingController();
  List<GroupItemDraft> _items = [];
  String? _expanded;
  bool _loaded = false;
  bool _dirty = false;

  /// 割合の提案（項目ID→直近12か月の一括入力の（合計, 件数））。設計書 6.6
  Map<String, (int, int)> _recent = const {};

  /// 「提案を使う」で割合の入力欄を作り直すための版
  final Map<String, int> _percentVersion = {};

  bool get _isNew => widget.groupId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.groupId;
    if (id != null) {
      final repo = ref.read(templateRepositoryProvider);
      final g = await repo.getGroup(id);
      _name.text = g?.name ?? '';
      _items = await repo.getGroupItems(id);
      final plan = ref.read(selectedPlanProvider).value;
      if (plan != null) {
        _recent = await ref
            .read(groupEntryRepositoryProvider)
            .recentItemTotals(plan.id, id);
      }
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _update(void Function() f) => setState(() {
    f();
    _dirty = true;
  });

  void _replaceItem(GroupItemDraft item) => _update(
    () => _items = [for (final i in _items) i.id == item.id ? item : i],
  );

  Future<String?> _pickTemplate() {
    final templates = ref.read(templatesProvider).value ?? const [];
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: templates.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('テンプレートがありません。先にホームの「テンプレート」で作ってください。'),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in templates)
                      ListTile(
                        leading: KindBadge(TxnKind.of(t.kind).label),
                        title: Text(t.name),
                        trailing: Text(
                          t.amount == null ? '—' : formatYen(t.amount!),
                        ),
                        onTap: () => Navigator.pop(context, t.id),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _addItem() async {
    final templateId = await _pickTemplate();
    if (templateId == null) return;
    final item = GroupItemDraft(id: newId(), templateId: templateId);
    _update(() {
      _items = [..._items, item];
      _expanded = item.id;
    });
  }

  Future<void> _save(Set<String> missing) async {
    if (_name.text.trim().isEmpty) {
      _snack('グループ名を入れてください');
      return;
    }
    for (final item in _items) {
      if (missing.contains(item.templateId)) continue; // 欠けた項目は警告だけ
      final err = validateGroupItem(item, _items, missingTemplateIds: missing);
      if (err != null) {
        setState(() => _expanded = item.id);
        _snack(err);
        return;
      }
    }
    await ref
        .read(templateRepositoryProvider)
        .saveGroup(
          groupId: widget.groupId,
          name: _name.text.trim(),
          items: _items,
        );
    _dirty = false;
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('「${_name.text}」を削除しますか'),
        content: const Text(
          'このグループで作った予定（計画行）と実績は残ります。プランへの登録も残り、'
          '登録済みグループの画面で「元のグループは削除済み」と表示します（作り直しはできなくなります）。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(templateRepositoryProvider).deleteGroup(widget.groupId!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final templates = {
      for (final t
          in ref.watch(templatesProvider).value ?? const <TemplateRow>[])
        t.id: t,
    };
    final cats = {
      for (final c
          in ref.watch(categoriesProvider).value ?? const <CategoryRow>[])
        c.id: c,
    };
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const <AccountRow>[])
        a.id: a,
    };
    final missing = {
      for (final i in _items)
        if (!templates.containsKey(i.templateId)) i.templateId,
    };
    final missingItems = [
      for (final i in _items)
        if (missing.contains(i.templateId)) i,
    ];

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            content: const Text('変更を保存せずに戻りますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('編集を続ける'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('保存せずに戻る'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          setState(() => _dirty = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'グループを作成' : 'グループを編集'),
          actions: [
            if (!_isNew)
              IconButton(
                tooltip: '削除',
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
              ),
          ],
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    key: const Key('group-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'グループ名'),
                    onChanged: (_) => _dirty = true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'グループは収入・支出の項目の集まりです。給与明細も「給与＋税・社会保険料」のグループとして作ります。'
                    '期間は持たず、ライフプランに登録するときに決めます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SectionTitle('項目', trailing: Text('${_items.length}件')),
                  if (missingItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          for (final m in missingItems)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: WarningBox(
                                message:
                                    '削除されたテンプレートの項目があります'
                                    '（${_percentLabel(m, templates) ?? '固定額の項目'}）。'
                                    'この項目は登録・実績入力では使われません。'
                                    '項目を外すか、テンプレートを選び直してください。',
                                actions: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      final t = await _pickTemplate();
                                      if (t != null) {
                                        _replaceItem(m.copyWith(templateId: t));
                                      }
                                    },
                                    child: const Text('別のテンプレートを選ぶ'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _update(
                                      () => _items = [
                                        for (final i in _items)
                                          if (i.id != m.id) i,
                                      ],
                                    ),
                                    child: const Text('この項目を外す'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  for (final (index, item) in _items.indexed)
                    _ItemCard(
                      key: ValueKey(item.id),
                      item: item,
                      all: _items,
                      templates: templates,
                      cats: cats,
                      accounts: accounts,
                      missing: missing,
                      recent: _recent,
                      percentVersion: _percentVersion[item.id] ?? 0,
                      onUseSuggestion: (p) {
                        _replaceItem(item.copyWith(percent: () => p));
                        setState(
                          () => _percentVersion[item.id] =
                              (_percentVersion[item.id] ?? 0) + 1,
                        );
                      },
                      expanded: _expanded == item.id,
                      onToggle: () => setState(
                        () => _expanded = _expanded == item.id ? null : item.id,
                      ),
                      onChanged: _replaceItem,
                      onRemove: () => _update(() {
                        _items = [
                          for (final i in _items)
                            if (i.id != item.id) i,
                        ];
                      }),
                      onMove: (delta) {
                        final to = index + delta;
                        if (to < 0 || to >= _items.length) return;
                        _update(() {
                          final list = [..._items];
                          list.insert(to, list.removeAt(index));
                          _items = list;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('group-add-item'),
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('項目（テンプレート）を追加'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isNew
                        ? () => _snack('先にグループを保存してください')
                        : () => context.push(
                            '/entry/group?group=${widget.groupId}',
                          ),
                    child: const Text('このグループで実績を入力'),
                  ),
                ],
              ),
        bottomNavigationBar: SaveCancelBar(
          onSave: _loaded ? () => _save(missing) : null,
          saveKey: const Key('group-save'),
        ),
      ),
    );
  }

  /// 割合の項目なら「ボーナスの15%」のような説明。
  String? _percentLabel(
    GroupItemDraft item,
    Map<String, TemplateRow> templates,
  ) {
    if (item.amountMode != AmountMode.percent) return null;
    final base = _items.where((i) => i.id == item.baseItemId).firstOrNull;
    final name = base == null ? '?' : (templates[base.templateId]?.name ?? '?');
    return '$nameの${item.percent ?? '?'}%';
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.all,
    required this.templates,
    required this.cats,
    required this.accounts,
    required this.missing,
    required this.recent,
    required this.percentVersion,
    required this.onUseSuggestion,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
    required this.onRemove,
    required this.onMove,
  });

  final GroupItemDraft item;
  final List<GroupItemDraft> all;
  final Map<String, TemplateRow> templates;
  final Map<String, CategoryRow> cats;
  final Map<String, AccountRow> accounts;
  final Set<String> missing;
  final Map<String, (int, int)> recent;
  final int percentVersion;
  final ValueChanged<double> onUseSuggestion;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<GroupItemDraft> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;

  String _nameOf(GroupItemDraft i) =>
      templates[i.templateId]?.name ?? '（削除されたテンプレート）';

  @override
  Widget build(BuildContext context) {
    final t = templates[item.templateId];
    final isMissing = missing.contains(item.templateId);
    final kind = t == null ? null : TxnKind.of(t.kind);
    final base = all.where((i) => i.id == item.baseItemId).firstOrNull;
    final amountText = item.amountMode == AmountMode.percent
        ? '${base == null ? '?' : _nameOf(base)}の ${item.percent ?? '?'}%'
        : (t?.amount == null ? '—' : formatYen(t!.amount!));
    final freqText = item.amountMode == AmountMode.percent
        ? '${base == null ? '?' : _nameOf(base)}と同じ月'
        : '${describeFrequency(item)}・固定額';
    final where = t == null
        ? ''
        : kind == TxnKind.transfer
        ? '・${accounts[t.accountId]?.name ?? '?'} → ${accounts[t.toAccountId]?.name ?? '?'}'
        : '・${cats[t.categoryId]?.name ?? '?'}／${accounts[t.accountId]?.name ?? '?'}';
    final err = isMissing
        ? null
        : validateGroupItem(item, all, missingTemplateIds: missing);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: expanded
              ? scheme.primary
              : (isMissing ? scheme.tertiary : scheme.outlineVariant),
          width: expanded ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (kind != null) ...[
                        KindBadge(kind.label),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: Text(_nameOf(item))),
                      Text(amountText),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$freqText$where',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (err != null)
                    Text(
                      err,
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (expanded && !isMissing) ..._editor(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _editor(BuildContext context) {
    final fixedOthers = [
      for (final i in all)
        if (i.id != item.id &&
            i.amountMode == AmountMode.fixed &&
            !missing.contains(i.templateId))
          i,
    ];
    return [
      const SizedBox(height: 12),
      const Text('金額の決め方'),
      const SizedBox(height: 4),
      SegmentedButton<AmountMode>(
        segments: [
          for (final m in AmountMode.values)
            ButtonSegment(value: m, label: Text(m.label)),
        ],
        selected: {item.amountMode},
        onSelectionChanged: (s) =>
            onChanged(item.copyWith(amountMode: s.first)),
      ),
      const SizedBox(height: 12),
      if (item.amountMode == AmountMode.percent) ...[
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: fixedOthers.any((i) => i.id == item.baseItemId)
                    ? item.baseItemId
                    : null,
                decoration: const InputDecoration(labelText: '基準にする項目'),
                items: [
                  for (final i in fixedOthers)
                    DropdownMenuItem(value: i.id, child: Text(_nameOf(i))),
                ],
                onChanged: (v) => onChanged(item.copyWith(baseItemId: () => v)),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: TextFormField(
                key: Key('percent-${item.id}-$percentVersion'),
                initialValue: item.percent?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: '割合',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (v) =>
                    onChanged(item.copyWith(percent: () => double.tryParse(v))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '基準の項目が発生する月に、その金額×%（円未満切り上げ）で発生します。昇給で基準が増えれば一緒に増えます。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Builder(
          builder: (context) {
            final mine = recent[item.id];
            final base = recent[item.baseItemId];
            final p = mine == null || base == null
                ? null
                : suggestPercent(mine.$1, base.$1);
            if (p == null) {
              return Text(
                '実績からの提案：直近12か月の一括入力がないため、まだ出せません。',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return Row(
              children: [
                Expanded(
                  child: Text(
                    '実績からの提案：$p%（直近12か月の一括入力 ${mine!.$2}回分）',
                    key: Key('suggest-${item.id}'),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => onUseSuggestion(p),
                  child: const Text('提案を使う'),
                ),
              ],
            );
          },
        ),
      ] else
        ..._frequencyEditor(context),
      const SizedBox(height: 8),
      Row(
        children: [
          IconButton(
            tooltip: '上へ',
            onPressed: () => onMove(-1),
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            tooltip: '下へ',
            onPressed: () => onMove(1),
            icon: const Icon(Icons.arrow_downward),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('この項目を外す'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _frequencyEditor(BuildContext context) {
    return [
      DropdownButtonFormField<Frequency>(
        initialValue: item.frequency,
        decoration: const InputDecoration(labelText: '頻度'),
        items: [
          for (final f in Frequency.values)
            DropdownMenuItem(value: f, child: Text(f.label)),
        ],
        onChanged: (f) => onChanged(item.copyWith(frequency: f)),
      ),
      const SizedBox(height: 12),
      switch (item.frequency) {
        Frequency.monthly => const SizedBox.shrink(),
        Frequency.yearly => DropdownButtonFormField<int>(
          initialValue: item.month,
          decoration: const InputDecoration(labelText: '月'),
          items: [
            for (var m = 1; m <= 12; m++)
              DropdownMenuItem(value: m, child: Text('$m月')),
          ],
          onChanged: (m) => onChanged(item.copyWith(month: () => m)),
        ),
        Frequency.everyNMonths || Frequency.everyNYears => TextFormField(
          key: Key('interval-${item.id}'),
          initialValue: item.intervalN?.toString() ?? '',
          decoration: InputDecoration(
            labelText: 'N',
            suffixText: item.frequency == Frequency.everyNMonths
                ? 'か月ごと'
                : '年ごと',
            helperText: '登録の開始年月を起点に数えます',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) =>
              onChanged(item.copyWith(intervalN: () => int.tryParse(v))),
        ),
        Frequency.weekly => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              children: [
                for (var w = 1; w <= 7; w++)
                  ChoiceChip(
                    label: Text(weekdayLabels[w - 1]),
                    selected: item.weekday == w,
                    onSelected: (_) =>
                        onChanged(item.copyWith(weekday: () => w)),
                  ),
              ],
            ),
            Text(
              'その月に該当する曜日の回数分を、1か月分にまとめて予定にします。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Frequency.specificMonths => Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var m = 1; m <= 12; m++)
              FilterChip(
                label: Text('$m月'),
                selected: item.months.contains(m),
                onSelected: (on) => onChanged(
                  item.copyWith(
                    months: on
                        ? ([...item.months, m]..sort())
                        : [
                            for (final x in item.months)
                              if (x != m) x,
                          ],
                  ),
                ),
              ),
          ],
        ),
      },
    ];
  }
}
