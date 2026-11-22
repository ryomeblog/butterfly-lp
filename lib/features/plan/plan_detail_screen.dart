import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/calc/event_matching.dart';
import '../events/event_common.dart';
import '../shared/widgets.dart';
import '../shared/plan_period.dart';

/// プラン詳細（ワイヤーフレーム PlanDetail）。M1 では基本情報だけを出す。
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = (ref.watch(plansProvider).value ?? const [])
        .where((p) => p.id == planId)
        .firstOrNull;
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('このプランは見つかりません')),
      );
    }
    final members = ref.watch(membersProvider(planId)).value ?? const [];
    final events =
        ref.watch(eventsProvider(planId)).value ?? const <PlanEventRow>[];
    final eventLines =
        ref.watch(eventLinesProvider(planId)).value ?? const <PlanLineRow>[];
    final protagonist = protagonistOf(plan, members);
    final baseline = parseDate(plan.baselineDate);
    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, path, m) in const [
                ('計画（年別）', 'year', null),
                ('家族', 'family', null),
                ('イベント', '@events', null),
                ('登録グループ', 'groups', null),
                ('率', 'rates', null),
                ('年別の予実', null, 'M8'),
              ])
                ActionChip(
                  key: Key('plan-chip-$label'),
                  label: Text(label),
                  onPressed: () => path == '@events'
                      ? context.go('/events')
                      : path != null
                      ? context.push('/home/plan/$planId/$path')
                      : ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('「$label」は $m で実装します。')),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (protagonist != null)
            Text(
              '主人公：${protagonist.name}'
              '（${parseDate(protagonist.birthDate).year}年生・寿命${protagonist.lifeExpectancy}歳）',
            ),
          PlanPeriodText(plan: plan),
          Text('起点日：${baseline.year}/${baseline.month}/${baseline.day}（変更不可）'),
          const SizedBox(height: 24),
          Text(
            '資産推移グラフ・寿命時と最大の総資産・資金不足の警告は M7 で、年別の予実は M8 で実装します。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SectionTitle('ライフイベント'),
          if (events.isEmpty) const Text('イベントはありません'),
          for (final e in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${e.year}年${e.month}月　${e.title}'),
              subtitle: Text(
                [
                  for (final m in members)
                    if (m.id == e.memberId)
                      '${m.name} ${ageInYear(m, e.year)}歳',
                ].join(),
              ),
              trailing: Text(
                formatYenSigned(
                  kindTotals([
                    for (final l in eventLines)
                      if (l.eventId == e.id) matchItemOfLine(l),
                  ]).net,
                ),
              ),
              onTap: () => context.go('/events'),
            ),
        ],
      ),
    );
  }
}
