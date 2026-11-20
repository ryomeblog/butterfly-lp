import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';
import 'template_edit_screen.dart';

/// ホーム（テンプレート）タブ（ワイヤーフレーム HomeTemplates）。
class TemplateListTab extends ConsumerWidget {
  const TemplateListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).value ?? const [];
    final counts = ref.watch(templateGroupCountsProvider).value ?? const {};
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const []) c.id: c,
    };
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const []) a.id: a,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '取引1回分の中身。単体では実績入力の雛形になり、グループの項目としても使います。ライフプランとは別に管理します。',
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
                contentPadding: EdgeInsets.zero,
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
                        final groups = await ref.read(
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
                onTap: () => context.push('/home/template/${t.id}'),
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
      ],
    );
  }
}
