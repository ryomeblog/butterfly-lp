import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
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
              for (final label in [
                '計画（年別）',
                '家族',
                'イベント',
                '登録グループ',
                '率',
                '年別の予実',
              ])
                Chip(label: Text(label)),
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
            '資産推移グラフ・寿命時と最大の総資産・資金不足の警告・ライフイベントは M7 で、'
            '各入口の画面は M4〜M8 で実装します。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
