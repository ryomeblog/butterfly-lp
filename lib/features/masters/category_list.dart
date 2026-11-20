import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';

/// カテゴリの一覧（支出・収入・資産を切り替え、長押しで並べ替え）。
/// ホームのカテゴリタブと、設定の「カテゴリ・口座」で使う。
class CategoryList extends ConsumerStatefulWidget {
  const CategoryList({super.key, required this.onOpen, required this.onAdd});

  final void Function(String categoryId) onOpen;
  final void Function(CategoryKind kind) onAdd;

  @override
  ConsumerState<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<CategoryList> {
  CategoryKind _kind = CategoryKind.expense;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(categoriesProvider).value ?? const [];
    final list = all.where((c) => c.kind == _kind.code).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<CategoryKind>(
            segments: [
              for (final k in CategoryKind.values)
                ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _kind == CategoryKind.asset
                ? '資産一覧のまとまりに使います。長押しで並べ替えできます。'
                : 'カテゴリは全プラン共通です。長押しで並べ替えできます。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            onReorderItem: (from, to) {
              final ids = [for (final c in list) c.id];
              final moved = ids.removeAt(from);
              ids.insert(to, moved);
              ref.read(masterRepositoryProvider).reorderCategories(ids);
            },
            itemBuilder: (context, i) {
              final c = list[i];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(c.id),
                index: i,
                child: ListTile(
                  leading: ColorDot(c.color),
                  title: Text(c.name),
                  subtitle: c.kind == CategoryKind.asset.code
                      ? Text(
                          '既定：${c.defaultValuation == null ? '—' : Valuation.of(c.defaultValuation!).label}'
                          '${c.saleTaxDefault == 1 ? '・売却時に税の初期値' : ''}',
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onOpen(c.id),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('category-add'),
              onPressed: () => widget.onAdd(_kind),
              icon: const Icon(Icons.add),
              label: Text('${_kind.label}のカテゴリを追加'),
            ),
          ),
        ),
      ],
    );
  }
}
