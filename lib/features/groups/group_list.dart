import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

/// ホーム（グループ）タブ（ワイヤーフレーム HomeGroups）。
class GroupListTab extends ConsumerWidget {
  const GroupListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupSummariesProvider).value ?? const [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '収入・支出の項目の集まり（給与明細もグループ）。実績の一括入力と、ライフプランへの登録に使います。'
          'ライフプランとは別に管理します。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('「グループから実績を入力」は M8 で実装します。')),
          ),
          icon: const Icon(Icons.playlist_add),
          label: const Text('グループから実績を入力'),
        ),
        const SizedBox(height: 8),
        for (final s in groups)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.group.name),
            subtitle: Text(
              [
                '項目${s.itemCount}件',
                if (s.registeredPlanCount > 0)
                  '${s.registeredPlanCount}プランで登録中',
                if (s.missingCount > 0) '欠けた項目${s.missingCount}件',
              ].join('・'),
            ),
            leading: s.missingCount > 0
                ? Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.tertiary,
                  )
                : const Icon(Icons.folder_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/home/group/${s.group.id}'),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('group-create'),
          onPressed: () => context.push('/home/group/new'),
          icon: const Icon(Icons.add),
          label: const Text('グループを作成'),
        ),
      ],
    );
  }
}
