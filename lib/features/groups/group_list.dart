import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/io/json_import.dart' show FileUnit;
import '../data/file_io.dart';
import '../shared/widgets.dart';

/// ホーム（グループ）タブ（ワイヤーフレーム HomeGroups）。
///
/// 長押しで選んで JSON に書き出せる。グループの JSON の取り込みもここから（設計書 3.9）。
class GroupListTab extends ConsumerStatefulWidget {
  const GroupListTab({super.key});

  @override
  ConsumerState<GroupListTab> createState() => _GroupListTabState();
}

class _GroupListTabState extends ConsumerState<GroupListTab> {
  final Set<String> _selected = {};

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupSummariesProvider).value ?? const [];
    _selected.retainWhere((id) => groups.any((g) => g.group.id == id));
    final selecting = _selected.isNotEmpty;
    final list = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '収入・支出の項目の集まり（給与明細もグループ）。実績の一括入力と、ライフプランへの登録に使います。'
          'ライフプランとは別に管理します。長押しで選んでJSONで書き出せます。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.push('/entry/group'),
          icon: const Icon(Icons.playlist_add),
          label: const Text('グループから実績を入力'),
        ),
        const SizedBox(height: 8),
        for (final s in groups)
          ListTile(
            key: Key('group-tile-${s.group.name}'),
            contentPadding: EdgeInsets.zero,
            selected: _selected.contains(s.group.id),
            onLongPress: () => _toggle(s.group.id),
            title: Text(s.group.name),
            subtitle: Text(
              [
                '項目${s.itemCount}件',
                if (s.registeredPlanCount > 0)
                  '${s.registeredPlanCount}プランで登録中',
                if (s.missingCount > 0) '欠けた項目${s.missingCount}件',
              ].join('・'),
            ),
            leading: selecting
                ? SelectMark(selected: _selected.contains(s.group.id))
                : s.missingCount > 0
                ? Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.tertiary,
                  )
                : const Icon(Icons.folder_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: selecting
                ? () => _toggle(s.group.id)
                : () => context.push('/home/group/${s.group.id}'),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('group-create'),
          onPressed: () => context.push('/home/group/new'),
          icon: const Icon(Icons.add),
          label: const Text('グループを作成'),
        ),
        const SizedBox(height: 8),
        const ImportJsonButton(expect: FileUnit.groups),
      ],
    );
    if (!selecting) return list;
    return Column(
      children: [
        Expanded(child: list),
        SelectionBar(
          count: _selected.length,
          onClear: () => setState(_selected.clear),
          onSelectAll: () => setState(
            () => _selected.addAll([for (final g in groups) g.group.id]),
          ),
          actions: [
            FilledButton(
              key: const Key('select-export'),
              onPressed: () => exportJson(
                context,
                ref,
                'groups',
                (e) => e.exportGroups([
                  for (final g in groups)
                    if (_selected.contains(g.group.id)) g.group.id,
                ]),
              ),
              child: const Text('JSONで書き出す'),
            ),
          ],
        ),
      ],
    );
  }
}
