import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../data/io/json_import.dart' show FileUnit;
import '../data/file_io.dart';
import '../groups/group_list.dart';
import '../masters/category_list.dart';
import '../templates/template_list.dart';
import '../shared/plan_period.dart';
import 'plan_card.dart';

/// ホーム。上部のタブで「ライフプラン／グループ／テンプレート／カテゴリ」を切り替える（設計書 7）。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ホーム'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'ライフプラン'),
              Tab(text: 'グループ'),
              Tab(text: 'テンプレート'),
              Tab(text: 'カテゴリ'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlanListTab(),
            GroupListTab(),
            TemplateListTab(),
            _CategoryTab(),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab();

  @override
  Widget build(BuildContext context) => CategoryList(
    onOpen: (id) => context.push('/home/category/$id'),
    onAdd: (kind) => context.push('/home/category/new?kind=${kind.code}'),
  );
}

class _PlanListTab extends ConsumerWidget {
  const _PlanListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final selected = ref.watch(selectedPlanProvider).value;
    return plans.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('読み込めませんでした：$e')),
      data: (list) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (selected != null) _SelectedBanner(plan: selected),
          const SizedBox(height: 8),
          Text(
            'プランを選ぶと詳細を開き、そのプランが「表示中」に切り替わります。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final p in list) ...[
            _PlanCard(plan: p, isSelected: p.id == selected?.id),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            key: const Key('plan-create'),
            onPressed: () => context.push('/home/plan-new'),
            icon: const Icon(Icons.add),
            label: const Text('プランを作成'),
          ),
          const SizedBox(height: 8),
          // プランの書き出しは各カードのメニューから（設計書 3.9）
          const ImportJsonButton(expect: FileUnit.plan),
        ],
      ),
    );
  }
}

class _SelectedBanner extends StatelessWidget {
  const _SelectedBanner({required this.plan});

  final PlanRow plan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.insert_chart_outlined, color: scheme.onPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '表示中のプラン',
                    style: TextStyle(color: scheme.onPrimary, fontSize: 12),
                  ),
                  Text(
                    plan.name,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '家計簿・資産・予実\nはこのプラン',
              textAlign: TextAlign.end,
              style: TextStyle(color: scheme.onPrimary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan, required this.isSelected});

  final PlanRow plan;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: Key('plan-card-${plan.id}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await ref.read(deviceRepositoryProvider).setSelectedPlan(plan.id);
          if (context.mounted) context.push('/home/plan/${plan.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('表示中'),
                      avatar: const Icon(Icons.check, size: 16),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.primaryContainer,
                    ),
                  ],
                  const Spacer(),
                  PlanMenuButton(plan: plan),
                ],
              ),
              const SizedBox(height: 4),
              PlanPeriodText(
                plan: plan,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              PlanCardSummary(plan: plan),
            ],
          ),
        ),
      ),
    );
  }
}
