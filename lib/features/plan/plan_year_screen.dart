import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../domain/calc/ledger.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/plan_period.dart';

/// 計画（年別）（ワイヤーフレーム PlanYear）：年を選び、月ごとの計画行を一覧・編集。グループの登録への入口。
class PlanYearScreen extends ConsumerStatefulWidget {
  const PlanYearScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanYearScreen> createState() => _PlanYearScreenState();
}

class _PlanYearScreenState extends ConsumerState<PlanYearScreen> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final plan = (ref.watch(plansProvider).value ?? const <PlanRow>[])
        .where((p) => p.id == widget.planId)
        .firstOrNull;
    final members = ref.watch(membersProvider(widget.planId)).value ?? const [];
    final period = plan == null ? null : planPeriod(plan, members);
    if (plan == null || period == null) return Scaffold(appBar: AppBar());
    final year = (_year ?? clock.now().year).clamp(
      period.start.year,
      period.end.year,
    );
    final lines =
        ref
            .watch(
              planLinesProvider((
                planId: widget.planId,
                from: YearMonth(year, 1),
                to: YearMonth(year, 12),
              )),
            )
            .value ??
        const <PlanLineRow>[];
    final lookup = Lookup(
      ref.watch(categoriesProvider).value ?? const [],
      ref.watch(accountsProvider).value ?? const [],
    );
    final protagonist = protagonistOf(plan, members);
    final age = protagonist == null
        ? null
        : year - parseDate(protagonist.birthDate).year;
    final totals = totalsOf(lines.map(ledgerTxnOfLine));

    return Scaffold(
      appBar: AppBar(title: const Text('計画（年別）')),
      floatingActionButton: FloatingActionButton(
        tooltip: '予定を追加',
        onPressed: () => context.push(
          '/entry/plan-line/new?ym=${YearMonth(year, clock.now().year == year ? clock.now().month : 1)}',
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: year > period.start.year
                    ? () => setState(() => _year = year - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '$year年${age == null ? '' : '（主人公 $age歳）'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                onPressed: year < period.end.year
                    ? () => setState(() => _year = year + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                key: const Key('to-register'),
                onPressed: () =>
                    context.push('/home/plan/${widget.planId}/register'),
                child: const Text('グループを登録'),
              ),
              OutlinedButton(
                onPressed: () =>
                    context.push('/home/plan/${widget.planId}/groups'),
                child: const Text('登録済みグループ（取り消し・削除）'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '年間　収入 ${formatYenSigned(totals.income)}　支出 ${formatYenSigned(-totals.expense)}',
          ),
          for (var m = 1; m <= 12; m++)
            Builder(
              builder: (context) {
                final ms = [
                  for (final l in lines)
                    if (l.month == m) l,
                ];
                final t = totalsOf(ms.map(ledgerTxnOfLine));
                return ExpansionTile(
                  key: PageStorageKey('py-$year-$m'),
                  tilePadding: EdgeInsets.zero,
                  title: Text('$m月'),
                  subtitle: Text(ms.isEmpty ? '予定なし' : '${ms.length}件'),
                  trailing: Text('収支 ${formatYenSigned(t.net)}'),
                  children: [
                    for (final l in ms) PlanLineTile(line: l, lookup: lookup),
                    TextButton.icon(
                      onPressed: () => context.push(
                        '/entry/plan-line/new?ym=${YearMonth(year, m)}',
                      ),
                      icon: const Icon(Icons.add),
                      label: Text('$m月に予定を追加'),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
