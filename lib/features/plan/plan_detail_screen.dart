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
import 'plan_asset_chart.dart';

/// プラン詳細（ワイヤーフレーム PlanDetail）。
///
/// 資産推移グラフは計画線だけで、年単位（生涯の年末ごと）と月単位（選んだ年の1月〜12月）を切り替える。
/// 寿命時・最大の総資産、資金不足の警告、ライフイベント（設計書 3.6・7）。
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
              for (final (label, path) in const [
                ('計画（年別）', 'year'),
                ('家族', 'family'),
                ('イベント', '@events'),
                ('登録グループ', 'groups'),
                ('率', 'rates'),
                ('年別の予実', '@years'),
              ])
                ActionChip(
                  key: Key('plan-chip-$label'),
                  label: Text(label),
                  onPressed: () => switch (path) {
                    '@events' => context.go('/events'),
                    '@years' => context.push('/compare/years'),
                    _ => context.push('/home/plan/$planId/$path'),
                  },
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
          const SizedBox(height: 16),
          PlanAssetChart(planId: planId),
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
