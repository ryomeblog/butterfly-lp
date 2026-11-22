import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/simulation.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/models/enums.dart';
import '../events/event_common.dart';
import '../shared/charts.dart';
import '../shared/plan_period.dart';

/// ホームのプランのカードの中身（設計書 7：生涯の収支グラフ（年ごとの収入と支出の2本線＋イベント）、
/// 寿命時の総資産（計画線）・資金不足）。
class PlanCardSummary extends ConsumerWidget {
  const PlanCardSummary({super.key, required this.plan});

  final PlanRow plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members =
        ref.watch(membersProvider(plan.id)).value ?? const <FamilyMemberRow>[];
    final period = planPeriod(plan, members);
    final lines = ref
        .watch(planLinesProvider((planId: plan.id, from: null, to: null)))
        .value;
    final events =
        ref.watch(eventsProvider(plan.id)).value ?? const <PlanEventRow>[];
    final sim = ref.watch(simulationProvider(plan.id));
    if (period == null || lines == null) return const SizedBox(height: 120);
    final years = [
      for (var y = period.start.year; y <= period.end.year; y++) y,
    ];
    final income = {for (final y in years) y: 0};
    final expense = {for (final y in years) y: 0};
    for (final l in lines) {
      if (!income.containsKey(l.year)) continue;
      if (l.kind == TxnKind.income.code) {
        income[l.year] = income[l.year]! + l.amount;
      } else if (l.kind == TxnKind.expense.code) {
        expense[l.year] = expense[l.year]! + l.amount;
      }
    }
    final protagonist = protagonistOf(plan, members);
    final markers = <int, String>{};
    for (final e in events) {
      final i = years.indexOf(e.year);
      if (i < 0) continue;
      markers[i] = markers.containsKey(i)
          ? '${markers[i]}・${e.title}'
          : e.title;
    }
    final scheme = Theme.of(context).colorScheme;
    final series = [
      ChartSeries(
        label: '収入（年）',
        values: [for (final y in years) income[y]],
        color: scheme.onSurface,
      ),
      ChartSeries(
        label: '支出（年）',
        values: [for (final y in years) expense[y]],
        color: scheme.primary,
        dashed: true,
      ),
    ];
    final shortage = sim?.firstShortage;
    final lifetime = sim == null || sim.months.isEmpty
        ? null
        : sim.months.last.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChartLegend(series: series, withEvents: true),
        SeriesChart(
          xLabels: [
            for (final y in years)
              '$y${protagonist == null ? '' : '\n${ageInYear(protagonist, y)}歳'}',
          ],
          series: series,
          markers: markers,
          height: 150,
          pointWidth: 0, // カードの中では横スクロールせず、全体を1画面に収める
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Cell(
                '寿命時の総資産',
                lifetime == null ? '—' : formatYen(lifetime),
              ),
            ),
            Expanded(
              child: _Cell(
                '資金不足',
                sim == null
                    ? '—'
                    : (shortage == null
                          ? 'なし'
                          : '${shortage.year}年${shortage.month}月〜'),
                key: Key('card-shortage-${plan.id}'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleSmall),
    ],
  );
}

/// 各プランの「⋮」メニュー：名前を変更／複製（今日を起点に計算し直す）／JSONで書き出す／削除（配下のデータごと）。
class PlanMenuButton extends ConsumerWidget {
  const PlanMenuButton({super.key, required this.plan});

  final PlanRow plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.read(planAdminRepositoryProvider);
    return PopupMenuButton<String>(
      key: Key('plan-menu-${plan.name}'),
      onSelected: (v) async {
        switch (v) {
          case 'rename':
            final name = await _askName(context, '名前を変更', plan.name);
            if (name != null) await admin.rename(plan.id, name);
          case 'copy':
            final name = await _askName(
              context,
              '複製（今日を起点に計算し直す）',
              '${plan.name}（複製）',
            );
            if (name != null) await admin.duplicate(plan.id, name);
          case 'json':
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSONの書き出しは M10 で実装します。')),
              );
            }
          case 'delete':
            final plans = ref.read(plansProvider).value ?? const [];
            if (plans.length <= 1) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('最後のプランは削除できません。先に別のプランを作ってください。'),
                  ),
                );
              }
              return;
            }
            if (!context.mounted) return;
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text('「${plan.name}」を削除しますか'),
                content: const Text(
                  '家族・計画・イベント・家計簿（実績）・資産など、このプランのデータをすべて削除します。',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    key: const Key('plan-delete-confirm'),
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('削除'),
                  ),
                ],
              ),
            );
            if (ok == true) await admin.delete(plan.id);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'rename', child: Text('名前を変更')),
        PopupMenuItem(value: 'copy', child: Text('複製（今日を起点に計算し直す）')),
        PopupMenuItem(value: 'json', child: Text('JSONで書き出す')),
        PopupMenuItem(value: 'delete', child: Text('削除（配下のデータごと）')),
      ],
    );
  }

  Future<String?> _askName(BuildContext context, String title, String initial) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          key: const Key('plan-name-input'),
          controller: c,
          decoration: const InputDecoration(labelText: 'プラン名'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('plan-name-ok'),
            onPressed: () {
              final v = c.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
