import 'package:clock/clock.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/repositories/txn_repository.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/models/enums.dart';
import '../ledger/ledger_widgets.dart';
import '../shared/widgets.dart';
import 'asset_common.dart';
import 'asset_edit_screen.dart';

/// 資産詳細（ワイヤーフレーム AssetDetail）。
///
/// 評価額の推移（実績線。計画線は M7）、保有数・取得価額・評価額・含み損益・通算の損益、価値の一覧と追加・削除、
/// 購入・売却・収益・費用の実績と予定、資産の削除。
class AssetDetailScreen extends ConsumerWidget {
  const AssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(selectedPlanProvider).value;
    final assets = plan == null
        ? const <AssetRow>[]
        : (ref.watch(assetsProvider(plan.id)).value ?? const <AssetRow>[]);
    final asset = assets.where((a) => a.id == assetId).firstOrNull;
    if (asset == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('この資産は見つかりません')),
      );
    }
    final valuation = Valuation.of(asset.valuation);
    final values =
        ref.watch(assetValuesProvider(assetId)).value ??
        const <AssetValueRow>[];
    final txns =
        ref.watch(assetTxnsProvider(assetId)).value ?? const <TxnRow>[];
    final lines =
        ref.watch(assetPlanLinesProvider(assetId)).value ??
        const <PlanLineRow>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final lookup = Lookup(
      categories,
      ref.watch(accountsProvider).value ?? const [],
    );
    final moves = [for (final t in txns) AssetRepository.moveOf(t)];
    final points = [for (final v in values) AssetRepository.pointOf(v)];
    final now = YearMonth.ofDate(clock.now());
    final state = assetStateAt(
      valuation: valuation,
      moves: moves,
      values: points,
      date: now.lastDayString,
    );
    final starts = [
      for (final m in moves) YearMonth.ofDateString(m.date),
      for (final p in points) YearMonth.ofDateString(p.effectiveFrom),
    ]..sort();
    final from = starts.isEmpty ? now : starts.first;
    final series = monthEndValuations(
      valuation: valuation,
      moves: moves,
      values: points,
      from: from < now.addMonths(-119) ? now.addMonths(-119) : from,
      to: now,
    );
    final cat = categories.where((c) => c.id == asset.categoryId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name),
        actions: [
          IconButton(
            tooltip: 'この資産をJSONで書き出す',
            icon: const Icon(Icons.ios_share),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('JSONの書き出しは M10 で実装します。')),
            ),
          ),
          IconButton(
            tooltip: '編集',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/assets/asset-edit/$assetId'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${cat?.name ?? '削除済みカテゴリ'}・${valuation.label}で評価　${plan!.name}の資産',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SectionTitle('評価額の推移（実績線）'),
          if (series.length >= 2)
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 64,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          final step = (series.length / 4).ceil().clamp(
                            1,
                            1000,
                          );
                          if (i < 0 || i >= series.length || i % step != 0) {
                            return const SizedBox.shrink();
                          }
                          final ym = series[i].$1;
                          return Text(
                            '${ym.year}/${ym.month}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (final (i, e) in series.indexed)
                          FlSpot(i.toDouble(), e.$2.toDouble()),
                      ],
                      color: Theme.of(context).colorScheme.primary,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text('グラフは2か月分以上の記録から表示します。'),
          Text(
            '計画線（見込みの価値・想定利回り）は M7 で重ねます。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _Metric(
                '評価額（${now.month}月末）',
                formatYen(state.valuation),
                key: const Key('m-valuation'),
              ),
              _Metric('取得価額', formatYen(state.acquisitionCost)),
              _Metric('含み損益', formatYenSigned(state.unrealizedGain)),
              _Metric(
                '保有数',
                valuation == Valuation.quantity
                    ? formatQuantity(state.quantityX1e4)
                    : '評価額の資産のためなし',
              ),
              _Metric(
                '通算の損益',
                formatYenSigned(state.totalGain),
                key: const Key('m-total'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '通算の損益＝評価額＋売却額＋収益−購入額−費用（税・ローン返済・維持費など）',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, path) in const [
                ('購入', 'buy'),
                ('売却', 'sell'),
                ('収益・費用', 'flow'),
              ])
                FilledButton.tonal(
                  onPressed: () =>
                      context.push('/entry/asset/$path?asset=$assetId'),
                  child: Text(label),
                ),
            ],
          ),
          SectionTitle(
            '価値（${valuation == Valuation.quantity ? '単価' : '評価額'}）',
            trailing: TextButton(
              onPressed: () async {
                final v = await showValueDialog(context, valuation: valuation);
                if (v != null) {
                  await ref
                      .read(assetRepositoryProvider)
                      .setValue(assetId, v.$1, v.$2, v.$3);
                }
              },
              child: const Text('追加'),
            ),
          ),
          Text(
            '日単位か月単位で指定。指定のない期間は直前の値が続きます。未来の日付は計画線の見込みに使います。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final v in values)
            ValueTile(
              value: v,
              onDelete: () =>
                  ref.read(assetRepositoryProvider).deleteValue(v.id),
            ),
          const SectionTitle('実績'),
          if (txns.isEmpty) const Text('実績はまだありません'),
          for (final t in txns)
            TxnTile(
              txn: ledgerTxnOf(t),
              lookup: lookup,
              prefix: AssetAction.of(t.assetAction!).label,
            ),
          const SectionTitle('予定'),
          if (lines.isEmpty) const Text('予定はありません'),
          for (final l in lines)
            PlanLineTile(
              line: l,
              lookup: lookup,
              showMonth: true,
              showYear: true,
            ),
          const SectionTitle('関連するイベント'),
          Text(
            'イベントは M6 で実装します。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('asset-delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _delete(context, ref, asset),
            child: const Text('この資産を削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AssetRow asset,
  ) async {
    final repo = ref.read(assetRepositoryProvider);
    final impact = await repo.deletionImpact(asset.id);
    if (!context.mounted) return;
    final result = await showDialog<(bool, bool)>(
      context: context,
      builder: (context) =>
          _AssetDeleteDialog(name: asset.name, impact: impact),
    );
    if (result == null) return;
    await repo.deleteAsset(
      asset.id,
      deleteTxns: result.$1,
      deletePlanLines: result.$2,
    );
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

/// 資産の削除：削除するものをチェックボックスで選ぶ（既定はすべて削除。設計書 3.7）。
class _AssetDeleteDialog extends StatefulWidget {
  const _AssetDeleteDialog({required this.name, required this.impact});

  final String name;
  final AssetDeletionImpact impact;

  @override
  State<_AssetDeleteDialog> createState() => _AssetDeleteDialogState();
}

class _AssetDeleteDialogState extends State<_AssetDeleteDialog> {
  bool _txns = true;
  bool _lines = true;

  @override
  Widget build(BuildContext context) {
    final i = widget.impact;
    return AlertDialog(
      title: Text('「${widget.name}」を削除'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('価値 ${i.values}件は一緒に削除します。'),
          CheckboxListTile(
            key: const Key('del-txns'),
            contentPadding: EdgeInsets.zero,
            value: _txns,
            onChanged: (v) => setState(() => _txns = v!),
            title: Text('この資産の実績 ${i.txns}件も削除する'),
          ),
          CheckboxListTile(
            key: const Key('del-lines'),
            contentPadding: EdgeInsets.zero,
            value: _lines,
            onChanged: (v) => setState(() => _lines = v!),
            title: Text('この資産の予定 ${i.planLines}件も削除する'),
          ),
          const Text('チェックを外したものは残し、資産との紐づきだけを外します（ただの収入・支出になります）。'),
          if (i.templates > 0)
            Text('この資産を使うテンプレート ${i.templates}件は残り、資産の欄が空になります。'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('asset-delete-confirm'),
          onPressed: () => Navigator.pop(context, (_txns, _lines)),
          child: const Text('削除'),
        ),
      ],
    );
  }
}
