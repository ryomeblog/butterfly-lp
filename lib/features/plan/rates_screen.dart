import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';

/// 率の設定（ワイヤーフレーム Rates）：口座・資産の想定利回り、カテゴリ別の上昇率（インフレ率・昇給率）。
///
/// 入力欄からフォーカスが外れたときに保存する。空にすると設定を消す
/// （カテゴリはプランの既定値、口座・資産は0%として扱う）。
class RatesScreen extends ConsumerWidget {
  const RatesScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = (ref.watch(plansProvider).value ?? const <PlanRow>[])
        .where((p) => p.id == planId)
        .firstOrNull;
    final rates = ref.watch(ratesProvider(planId));
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final assets =
        ref.watch(assetsProvider(planId)).value ?? const <AssetRow>[];
    if (plan == null || !rates.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final byKey = {
      for (final r in rates.value!)
        '${r.targetType}:${r.targetId}': r.annualRate,
    };
    final repo = ref.read(rateFamilyRepositoryProvider);

    Widget rateRow(
      String label,
      String sub,
      String type,
      String id,
      String hint,
    ) => _RateField(
      key: Key('rate-$type-$label'),
      label: label,
      sub: sub,
      value: byKey['$type:$id'],
      hint: hint,
      onSubmit: (v) => repo.setRate(planId, type, id, v),
    );

    return Scaffold(
      appBar: AppBar(title: Text('率の設定（${plan.name}）')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('想定利回り（年%）'),
          Text(
            '計画線で、口座の残高・資産の評価額を毎月この率で増やします（残高がマイナスの口座は増やしません）。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final a in accounts)
            rateRow(
              a.name,
              '口座・${AccountKind.of(a.kind).label}',
              TargetType.account,
              a.id,
              '0',
            ),
          for (final a in assets)
            rateRow(
              a.name,
              '資産・${Valuation.of(a.valuation).label}（見込みの価値がない月に使う）',
              TargetType.asset,
              a.id,
              '0',
            ),
          const SectionTitle('上昇率（年%）'),
          _RateField(
            key: const Key('rate-default'),
            label: '既定値',
            sub: 'カテゴリ別の設定が無いときに使う',
            value: plan.defaultInflationRate,
            hint: '0',
            allowEmpty: false,
            onSubmit: (v) => repo.setDefaultInflationRate(planId, v ?? 0),
          ),
          for (final kind in [CategoryKind.income, CategoryKind.expense]) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                kind == CategoryKind.income ? '収入（昇給率など）' : '支出（インフレ率）',
              ),
            ),
            for (final c in categories.where((c) => c.kind == kind.code))
              rateRow(
                c.name,
                '未設定なら既定値（${plan.defaultInflationRate}%）',
                TargetType.category,
                c.id,
                '${plan.defaultInflationRate}',
              ),
          ],
          const SizedBox(height: 16),
          Text(
            '上昇率は、グループを計画に登録するときだけ使います。作成済みの計画行は変わりません（登録済みグループの「作り直し」で反映します）。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RateField extends StatefulWidget {
  const _RateField({
    super.key,
    required this.label,
    required this.sub,
    required this.value,
    required this.hint,
    required this.onSubmit,
    this.allowEmpty = true,
  });

  final String label;
  final String sub;
  final double? value;
  final String hint;
  final bool allowEmpty;
  final Future<void> Function(double? v) onSubmit;

  @override
  State<_RateField> createState() => _RateFieldState();
}

class _RateFieldState extends State<_RateField> {
  late final _c = TextEditingController(text: widget.value?.toString() ?? '');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _submit();
    });
  }

  @override
  void didUpdateWidget(covariant _RateField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && old.value != widget.value) {
      _c.text = widget.value?.toString() ?? '';
    }
  }

  void _submit() {
    final v = double.tryParse(_c.text);
    if (v == null && !widget.allowEmpty) return;
    if (v == widget.value) return;
    widget.onSubmit(v);
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.label),
      subtitle: Text(widget.sub),
      trailing: SizedBox(
        width: 96,
        child: TextField(
          controller: _c,
          focusNode: _focus,
          textAlign: TextAlign.end,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixText: '%',
            isDense: true,
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
          ],
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
