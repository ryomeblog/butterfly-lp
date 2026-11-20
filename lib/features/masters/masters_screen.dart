import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../domain/models/enums.dart';
import 'category_list.dart';

/// カテゴリ・口座（ワイヤーフレーム Masters）。タブで切り替え、右上の＋で表示中のタブの追加画面を開く。
class MastersScreen extends StatefulWidget {
  const MastersScreen({super.key});

  @override
  State<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends State<MastersScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カテゴリ・口座'),
        actions: [
          IconButton(
            tooltip: '追加',
            icon: const Icon(Icons.add),
            onPressed: () => _tabs.index == 0
                ? context.push('/settings/masters/category/new')
                : context.push('/settings/masters/account/new'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'カテゴリ'),
            Tab(text: '口座'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          CategoryList(
            onOpen: (id) => context.push('/settings/masters/category/$id'),
            onAdd: (kind) => context.push(
              '/settings/masters/category/new?kind=${kind.code}',
            ),
          ),
          const _AccountList(),
        ],
      ),
    );
  }
}

class _AccountList extends ConsumerWidget {
  const _AccountList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(accountsProvider).value ?? const [];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'カテゴリと口座は全プラン共通です（口座の残高はプランごとの実績で計算）。'
            '使用中の口座は「履歴ごと削除」か「別の口座へ付け替えて削除」を選びます。長押しで並べ替えできます。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: list.length,
            onReorderItem: (from, to) {
              final ids = [for (final a in list) a.id];
              final moved = ids.removeAt(from);
              ids.insert(to, moved);
              ref.read(masterRepositoryProvider).reorderAccounts(ids);
            },
            itemBuilder: (context, i) {
              final a = list[i];
              final d = parseDate(a.initialDate);
              return ReorderableDelayedDragStartListener(
                key: ValueKey(a.id),
                index: i,
                child: ListTile(
                  title: Text(a.name),
                  subtitle: Text(
                    '${AccountKind.of(a.kind).label}・初期残高 ${formatYen(a.initialBalance)}'
                    '（${d.year}/${d.month}/${d.day}）',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/settings/masters/account/${a.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
