import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import 'plan_period.dart';

/// 表示するプランの切り替え（ワイヤーフレーム PlanSwitch）。
///
/// 家計簿・資産・イベントの上部のプラン名を押すと出る。選ぶと端末の表示プランが変わる（同期しない）。
Future<void> showPlanSwitchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _PlanSwitchSheet(),
  );
}

class _PlanSwitchSheet extends ConsumerWidget {
  const _PlanSwitchSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider).value ?? const [];
    final selected = ref.watch(selectedPlanProvider).value;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              '表示するプラン',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('家計簿・資産・イベントは、選んだプランのものを表示します。'),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in plans)
                  ListTile(
                    leading: Icon(
                      p.id == selected?.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(p.name),
                    subtitle: PlanPeriodText(plan: p),
                    onTap: () async {
                      await ref
                          .read(deviceRepositoryProvider)
                          .setSelectedPlan(p.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('ホームでプランの一覧を見る'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 家計簿・資産・イベントの AppBar の見出し。表示中のプラン名を出し、押すと切り替えシートを開く。
class PlanSwitchTitle extends ConsumerWidget {
  const PlanSwitchTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(selectedPlanProvider).value;
    return Row(
      children: [
        Text(title),
        const SizedBox(width: 12),
        if (plan != null)
          Flexible(
            child: ActionChip(
              key: const Key('plan-switch-chip'),
              label: Text('${plan.name} ▾', overflow: TextOverflow.ellipsis),
              onPressed: () => showPlanSwitchSheet(context),
            ),
          ),
      ],
    );
  }
}
