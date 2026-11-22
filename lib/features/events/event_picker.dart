import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';

/// 関連するイベント（任意）の選択。表示プランのイベントから選ぶ（設計書 3.3・3.10）。
class EventPicker extends ConsumerWidget {
  const EventPicker({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(selectedPlanProvider).value;
    final events = plan == null
        ? const <PlanEventRow>[]
        : (ref.watch(eventsProvider(plan.id)).value ?? const <PlanEventRow>[]);
    return DropdownButtonFormField<String?>(
      key: const Key('event-picker'),
      initialValue: events.any((e) => e.id == value) ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'イベント（任意）'),
      items: [
        const DropdownMenuItem(value: null, child: Text('なし')),
        for (final e in events)
          DropdownMenuItem(
            value: e.id,
            child: Text('${e.title}（${e.year}年${e.month}月）'),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
