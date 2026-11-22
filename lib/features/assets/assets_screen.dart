import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/txn_repository.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/calc/balance.dart';
import '../../domain/models/enums.dart';
import '../shared/plan_switch_sheet.dart';
import '../shared/widgets.dart';
import 'asset_common.dart';

/// 資産一覧（ワイヤーフレーム Assets）。
///
/// 上部で「年」（年末時点）か「年月」（月末時点）を選び（既定は今月）、その時点の表示プランの実績による
/// 口座残高と、資産の評価額・含み損益・合計を出す。計画との比較はしない（設計書 7）。
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  bool _byYear = false;
  late YearMonth _ym = YearMonth.ofDate(clock.now());

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const PlanSwitchTitle(title: '資産')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final date = _byYear ? '${_ym.year}-12-31' : _ym.lastDayString;
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final txns =
        ref
            .watch(txnsProvider((planId: plan.id, from: null, to: null)))
            .value ??
        const <TxnRow>[];
    final balanceTxns = [for (final t in txns) balanceTxnOf(t)];
    final assets =
        ref.watch(assetsProvider(plan.id)).value ?? const <AssetRow>[];
    final states = assetStatesAt(ref, plan.id, assets, date);
    final categories =
        ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final assetCats = [
      for (final c in categories)
        if (c.kind == CategoryKind.asset.code) c,
    ];

    final balances = {
      for (final a in accounts)
        a.id: accountBalanceAt(
          BalanceAccount(
            id: a.id,
            initialBalance: a.initialBalance,
            initialDate: a.initialDate,
          ),
          balanceTxns,
          date,
        ),
    };
    final accountTotal = balances.values.fold(0, (a, b) => a + b);
    final assetTotal = states.values.fold(0, (a, s) => a + s.valuation);
    final d = parseDate(date);

    return Scaffold(
      appBar: AppBar(title: const PlanSwitchTitle(title: '資産')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('年')),
                  ButtonSegment(value: false, label: Text('年月')),
                ],
                selected: {_byYear},
                onSelectionChanged: (v) => setState(() => _byYear = v.first),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    setState(() => _ym = _ym.addMonths(_byYear ? -12 : -1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(_byYear ? '${_ym.year}年末' : '${_ym.year}年${_ym.month}月末'),
              IconButton(
                onPressed: () =>
                    setState(() => _ym = _ym.addMonths(_byYear ? 12 : 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.year}年${d.month}月${d.day}日時点（${plan.name}の実績で計算）'),
                  Text(
                    formatYen(accountTotal + assetTotal),
                    key: const Key('assets-total'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '口座 ${formatYen(accountTotal)}　資産 ${formatYen(assetTotal)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => context.push('/entry/asset/buy'),
                child: const Text('購入'),
              ),
              FilledButton.tonal(
                onPressed: () => context.push('/entry/asset/sell'),
                child: const Text('売却'),
              ),
              FilledButton.tonal(
                onPressed: () => context.push('/entry/asset/flow'),
                child: const Text('収益・費用'),
              ),
            ],
          ),
          SectionTitle(
            '口座',
            trailing: TextButton(
              onPressed: () => context.push('/assets/account-edit/new'),
              child: const Text('＋ 口座を追加'),
            ),
          ),
          for (final a in accounts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(a.name),
              subtitle: Text(AccountKind.of(a.kind).label),
              trailing: Text(formatYen(balances[a.id]!)),
              onTap: () => context.push('/assets/account/${a.id}'),
            ),
          SectionTitle(
            '資産',
            trailing: Wrap(
              children: [
                TextButton(
                  onPressed: () =>
                      context.push('/assets/category/new?kind=asset'),
                  child: const Text('カテゴリを追加'),
                ),
                TextButton(
                  key: const Key('asset-add'),
                  onPressed: () => context.push('/assets/asset-edit/new'),
                  child: const Text('＋ 資産を追加'),
                ),
              ],
            ),
          ),
          if (assets.isEmpty) const Text('資産はまだありません。'),
          for (final c in assetCats)
            if (assets.any((a) => a.categoryId == c.id)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () => context.push('/assets/category/${c.id}'),
                  child: Row(
                    children: [
                      ColorDot(c.color),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
              for (final a in assets.where((a) => a.categoryId == c.id))
                _AssetTile(asset: a, category: c, state: states[a.id]!),
            ],
          for (final a in assets.where(
            (a) => !assetCats.any((c) => c.id == a.categoryId),
          ))
            _AssetTile(asset: a, category: null, state: states[a.id]!),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('資産リストの書き出しは M10 で実装します。')),
                ),
                child: const Text('資産リストを書き出す'),
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('資産の取り込みは M10 で実装します。')),
                ),
                child: const Text('資産を取り込む'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.asset,
    required this.category,
    required this.state,
  });

  final AssetRow asset;
  final CategoryRow? category;
  final AssetState state;

  @override
  Widget build(BuildContext context) {
    final valuation = Valuation.of(asset.valuation);
    final sub = [
      category?.name ?? '削除済みカテゴリ',
      valuation.label,
      if (valuation == Valuation.quantity)
        '保有 ${formatQuantity(state.quantityX1e4)}',
    ].join('・');
    final gain = state.unrealizedGain;
    return ListTile(
      key: Key('asset-${asset.name}'),
      contentPadding: EdgeInsets.zero,
      title: Text(asset.name),
      subtitle: Text(sub),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatYen(state.valuation)),
          Text(
            '含み損益 ${formatYenSigned(gain)}',
            style: TextStyle(
              fontSize: 12,
              color: gain < 0 ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ],
      ),
      onTap: () => context.push('/assets/detail/${asset.id}'),
    );
  }
}
