import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../domain/models/enums.dart';
import '../../data/io/json_import.dart' show FileUnit;
import '../data/file_io.dart';
import '../shared/widgets.dart';
import 'template_edit_screen.dart';

/// ホーム（テンプレート）タブ（ワイヤーフレーム HomeTemplates）。
///
/// 長押しで選んで JSON に書き出せる。テンプレートの JSON の取り込みもここから（設計書 3.9）。
class TemplateListTab extends ConsumerStatefulWidget {
  const TemplateListTab({super.key});

  @override
  ConsumerState<TemplateListTab> createState() => _TemplateListTabState();
}

class _TemplateListTabState extends ConsumerState<TemplateListTab> {
  final Set<String> _selected = {};

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesProvider).value ?? const [];
    final counts = ref.watch(templateGroupCountsProvider).value ?? const {};
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const []) c.id: c,
    };
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const []) a.id: a,
    };
    // 削除されたテンプレートは選択から外す
    _selected.retainWhere((id) => templates.any((t) => t.id == id));
    final selecting = _selected.isNotEmpty;
    final list = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '取引1回分の中身。単体では実績入力の雛形になり、グループの項目としても使います。ライフプランとは別に管理します。'
          '長押しで選んでJSONで書き出せます。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final t in templates)
          Builder(
            builder: (context) {
              final kind = TxnKind.of(t.kind);
              final account = accounts[t.accountId]?.name ?? '口座なし';
              final where = kind == TxnKind.transfer
                  ? '$account → ${accounts[t.toAccountId]?.name ?? '口座なし'}'
                  : '${cats[t.categoryId]?.name ?? 'カテゴリなし'}・$account';
              final growth = kind == TxnKind.transfer
                  ? ''
                  : switch (GrowthMode.of(t.growthMode)) {
                      GrowthMode.category => '・上昇 カテゴリの率',
                      GrowthMode.template => '・上昇 年${t.growthRate ?? 0}%',
                      GrowthMode.none => '・上昇なし',
                    };
              final n = counts[t.id] ?? 0;
              return ListTile(
                key: Key('template-tile-${t.name}'),
                contentPadding: EdgeInsets.zero,
                selected: _selected.contains(t.id),
                leading: selecting
                    ? SelectMark(selected: _selected.contains(t.id))
                    : null,
                onLongPress: () => _toggle(t.id),
                title: Row(
                  children: [
                    Flexible(child: Text(t.name)),
                    const SizedBox(width: 8),
                    KindBadge(kind.label),
                  ],
                ),
                subtitle: Text('$where${n > 0 ? '・所属 $nグループ' : ''}$growth'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.amount == null ? '—' : formatYen(t.amount!)),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v != 'delete') return;
                        final groups = await ref.readOnce(
                          groupsUsingTemplateProvider(t.id).future,
                        );
                        if (!context.mounted) return;
                        final ok = await showTemplateDeleteDialog(
                          context,
                          templateName: t.name,
                          groups: groups,
                        );
                        if (ok == true) {
                          await ref
                              .read(templateRepositoryProvider)
                              .deleteTemplate(t.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('削除')),
                      ],
                    ),
                  ],
                ),
                onTap: selecting
                    ? () => _toggle(t.id)
                    : () => context.push('/home/template/${t.id}'),
              );
            },
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('template-create'),
          onPressed: () => context.push('/home/template/new'),
          icon: const Icon(Icons.add),
          label: const Text('テンプレートを作成'),
        ),
        const SizedBox(height: 8),
        const ImportJsonButton(expect: FileUnit.templates),
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
            () => _selected.addAll([for (final t in templates) t.id]),
          ),
          actions: [
            FilledButton(
              key: const Key('select-export'),
              onPressed: () => exportJson(
                context,
                ref,
                'templates',
                (e) => e.exportTemplates([
                  for (final t in templates)
                    if (_selected.contains(t.id)) t.id,
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
