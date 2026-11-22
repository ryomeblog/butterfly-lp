import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/asset_repository.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';
import '../shared/ym_picker.dart';
import 'asset_common.dart';

/// 資産の画面の種類。
enum AssetFlowKind { buy, sell, flow }

/// 購入・売却・収益・費用（ワイヤーフレーム Buy / Sell / AssetFlow）。設計書 3.3・6.2。
///
/// 実績（日付）と予定（年月）のどちらも入れられる。費用（税金・手数料など）は何行でも一緒に入れ、元の動きを指す。
class AssetFlowScreen extends ConsumerStatefulWidget {
  const AssetFlowScreen({
    super.key,
    required this.kind,
    this.assetId,
    this.startAsPlan = false,
  });

  final AssetFlowKind kind;
  final String? assetId;
  final bool startAsPlan;

  @override
  ConsumerState<AssetFlowScreen> createState() => _AssetFlowScreenState();
}

class _CostDraft {
  _CostDraft({this.label = '費用', int? amount})
    : amount = TextEditingController(text: amount?.toString() ?? '');
  final String label;
  String? categoryId;
  final TextEditingController amount;
  final memo = TextEditingController();
}

class _AssetFlowScreenState extends ConsumerState<AssetFlowScreen> {
  final _form = GlobalKey<FormState>();
  late bool _isPlan = widget.startAsPlan;
  late String? _assetId = widget.assetId;
  DateTime _date = clock.now();
  YearMonth _ym = YearMonth.ofDate(clock.now());
  String? _accountId;
  String? _categoryId;

  /// 購入：金額で指定（true）か数量で指定（false）
  bool _byAmount = true;

  /// 収益・費用：収益（true）か費用（false）
  bool _isIncome = true;
  final _amount = TextEditingController();
  final _quantity = TextEditingController();
  final _valueAtBuy = TextEditingController();
  final _memo = TextEditingController();
  final List<_CostDraft> _costs = [];

  /// 税の行（初期値を出したとき）
  _CostDraft? _taxRow;

  @override
  void initState() {
    super.initState();
    for (final c in [_amount, _quantity]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_amount, _quantity, _valueAtBuy, _memo]) {
      c.dispose();
    }
    for (final c in _costs) {
      c.amount.dispose();
      c.memo.dispose();
    }
    super.dispose();
  }

  String get _title => switch (widget.kind) {
    AssetFlowKind.buy => '購入',
    AssetFlowKind.sell => '売却',
    AssetFlowKind.flow => '資産の収益・費用',
  };

  String get _dateStr => _isPlan ? _ym.lastDayString : dateString(_date);

  AssetAction get _action => switch (widget.kind) {
    AssetFlowKind.buy => AssetAction.buy,
    AssetFlowKind.sell => AssetAction.sell,
    AssetFlowKind.flow => _isIncome ? AssetAction.income : AssetAction.cost,
  };

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    if (plan == null) return Scaffold(appBar: AppBar());
    final assets =
        ref.watch(assetsProvider(plan.id)).value ?? const <AssetRow>[];
    final asset = assets.where((a) => a.id == _assetId).firstOrNull;
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final mainKind = switch (_action) {
      AssetAction.buy || AssetAction.cost => CategoryKind.expense,
      AssetAction.sell || AssetAction.income => CategoryKind.income,
    };
    final mainCats = [
      for (final c in categories)
        if (c.kind == mainKind.code) c,
    ];
    final expenseCats = [
      for (final c in categories)
        if (c.kind == CategoryKind.expense.code) c,
    ];
    final assetCat = categories
        .where((c) => c.id == asset?.categoryId)
        .firstOrNull;

    final values = asset == null
        ? const <AssetValueRow>[]
        : (ref.watch(assetValuesProvider(asset.id)).value ??
              const <AssetValueRow>[]);
    final txns = asset == null
        ? const <TxnRow>[]
        : (ref.watch(assetTxnsProvider(asset.id)).value ?? const <TxnRow>[]);
    final isQty =
        asset != null && Valuation.of(asset.valuation) == Valuation.quantity;
    final price = asset == null
        ? null
        : valueAt(values.map(AssetRepository.pointOf), _dateStr);
    final state = asset == null
        ? null
        : assetStateAt(
            valuation: Valuation.of(asset.valuation),
            moves: txns.map(AssetRepository.moveOf),
            values: values.map(AssetRepository.pointOf),
            date: _dateStr,
          );

    // 購入：もう一方を単価から計算
    int? amount = int.tryParse(_amount.text);
    int? qty = parseQuantity(_quantity.text);
    String? calcNote;
    if (widget.kind == AssetFlowKind.buy && isQty && price != null) {
      if (_byAmount && amount != null) {
        qty = quantityForAmount(amount, price);
      } else if (!_byAmount && qty != null) {
        amount = amountForQuantity(qty, price);
      }
      calcNote =
          '${_isPlan ? '${_ym.year}年${_ym.month}月' : '${_date.month}月${_date.day}日'}時点の単価 ${formatX100(price)} で計算';
    }
    // 売却：売却分の取得価額と実現損益
    int? costOfSold;
    if (widget.kind == AssetFlowKind.sell && state != null) {
      if (isQty) {
        final q = qty ?? 0;
        costOfSold = state.quantityX1e4 <= 0
            ? 0
            : state.acquisitionCost *
                  q.clamp(0, state.quantityX1e4) ~/
                  state.quantityX1e4;
      } else {
        costOfSold = state.acquisitionCost;
      }
    }
    final costSum = _costs.fold(
      0,
      (a, c) => a + (int.tryParse(c.amount.text) ?? 0),
    );
    final realized = (amount != null && costOfSold != null)
        ? amount - costOfSold - costSum
        : null;

    // 税の初期値（カテゴリで「売却時に税の初期値を出す」とした資産）
    final wantsTax =
        assetCat?.saleTaxDefault == 1 &&
        (widget.kind == AssetFlowKind.sell ||
            (widget.kind == AssetFlowKind.flow && _isIncome));
    final taxBase = widget.kind == AssetFlowKind.sell
        ? (amount != null && costOfSold != null ? amount - costOfSold : null)
        : amount;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('実績')),
                ButtonSegment(value: true, label: Text('予定')),
              ],
              selected: {_isPlan},
              onSelectionChanged: (s) => setState(() => _isPlan = s.first),
            ),
            if (widget.kind == AssetFlowKind.flow) ...[
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                key: const Key('flow-kind'),
                segments: const [
                  ButtonSegment(value: true, label: Text('収益（収入）')),
                  ButtonSegment(value: false, label: Text('費用（支出）')),
                ],
                selected: {_isIncome},
                onSelectionChanged: (s) => setState(() {
                  _isIncome = s.first;
                  _categoryId = null;
                }),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('flow-asset'),
              initialValue: asset?.id,
              decoration: const InputDecoration(labelText: '資産'),
              items: [
                for (final a in assets)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      '${a.name}（${Valuation.of(a.valuation).label}）',
                    ),
                  ),
              ],
              validator: (v) => v == null ? '選んでください' : null,
              onChanged: (v) => setState(() {
                _assetId = v;
                final a = assets.firstWhere((x) => x.id == v);
                _accountId ??= a.accountId;
              }),
            ),
            const SizedBox(height: 16),
            if (_isPlan)
              YmPicker(
                key: const ValueKey('flow-ym'),
                label: '年月（予定は月単位）',
                value: _ym,
                min: YearMonth(1900, 1),
                max: YearMonth(2200, 12),
                onChanged: (v) => setState(() => _ym = v),
              )
            else
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200),
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '日付'),
                  child: Text('${_date.year}/${_date.month}/${_date.day}'),
                ),
              ),
            const SizedBox(height: 16),
            ..._amountFields(isQty, state, price, amount, qty, calcNote),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('flow-account'),
              initialValue: accounts.any((a) => a.id == _accountId)
                  ? _accountId
                  : null,
              decoration: InputDecoration(
                labelText: mainKind == CategoryKind.income ? '入金口座' : '出金口座',
              ),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              validator: (v) => v == null ? '選んでください' : null,
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('flow-category'),
              initialValue: mainCats.any((c) => c.id == _categoryId)
                  ? _categoryId
                  : null,
              decoration: const InputDecoration(labelText: 'カテゴリ'),
              items: [
                for (final c in mainCats)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        ColorDot(c.color),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
              ],
              validator: (v) => v == null ? '選んでください' : null,
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memo,
              decoration: const InputDecoration(labelText: 'メモ'),
            ),
            if (widget.kind == AssetFlowKind.sell && costOfSold != null) ...[
              const SizedBox(height: 16),
              Text('売却分の取得価額（移動平均）　${formatYen(costOfSold)}'),
              Text('費用　${formatYen(costSum)}'),
              Text(
                '実現損益　${realized == null ? '—' : formatYenSigned(realized)}',
                key: const Key('flow-realized'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            if (widget.kind != AssetFlowKind.flow || _isIncome) ...[
              SectionTitle(
                widget.kind == AssetFlowKind.sell ? '税金・費用（支出）' : '費用（支出）',
                trailing: TextButton(
                  key: const Key('cost-add'),
                  onPressed: () => setState(() => _costs.add(_CostDraft())),
                  child: const Text('＋ 費用を追加'),
                ),
              ),
              if (wantsTax && _taxRow == null)
                OutlinedButton(
                  key: const Key('tax-add'),
                  onPressed: taxBase == null
                      ? null
                      : () => setState(() {
                          _taxRow = _CostDraft(
                            label: '税金',
                            amount: taxInitial(taxBase),
                          );
                          _costs.insert(0, _taxRow!);
                        }),
                  child: Text(
                    widget.kind == AssetFlowKind.sell
                        ? '税額の初期値を入れる（利益×20.315%）'
                        : '税額の初期値を入れる（受取額×20.315%）',
                  ),
                ),
              for (final c in _costs) _costRow(c, expenseCats),
              Text(
                '費用は家計簿の支出に入り、この${_title.replaceAll('資産の', '')}を指します。'
                '税額は修正でき、0円（NISAなど）にもできます。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SaveCancelBar(
        saveKey: const Key('flow-save'),
        onSave: () => _save(plan.id, asset, amount, qty),
      ),
    );
  }

  List<Widget> _amountFields(
    bool isQty,
    AssetState? state,
    int? price,
    int? amount,
    int? qty,
    String? calcNote,
  ) {
    final amountField = YenField(
      key: const Key('flow-amount'),
      controller: _amount,
      label: switch (widget.kind) {
        AssetFlowKind.buy => '購入額（円）',
        AssetFlowKind.sell => '売却額（円・費用を引く前）',
        AssetFlowKind.flow => '金額（円）',
      },
    );
    final qtyField = TextFormField(
      key: const Key('flow-quantity'),
      controller: _quantity,
      decoration: InputDecoration(
        labelText: widget.kind == AssetFlowKind.sell
            ? '売却数量（保有 ${formatQuantity(state?.quantityX1e4 ?? 0)}）'
            : '数量',
        helperText: '小数第4位まで',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
      ],
      validator: (v) {
        final q = parseQuantity(v ?? '');
        if (q == null || q <= 0) return '数量を入れてください';
        if (widget.kind == AssetFlowKind.sell &&
            !_isPlan &&
            q > (state?.quantityX1e4 ?? 0)) {
          return '保有数より多く売れません';
        }
        return null;
      },
    );
    if (widget.kind == AssetFlowKind.buy && isQty) {
      if (price == null) {
        return [
          const Text('この日時点の単価が未指定のため、金額と数量の両方を入れてください（価値は資産詳細で追加できます）。'),
          const SizedBox(height: 8),
          amountField,
          const SizedBox(height: 16),
          qtyField,
        ];
      }
      return [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('金額で指定')),
            ButtonSegment(value: false, label: Text('数量で指定')),
          ],
          selected: {_byAmount},
          onSelectionChanged: (s) => setState(() => _byAmount = s.first),
        ),
        const SizedBox(height: 12),
        if (_byAmount) amountField else qtyField,
        const SizedBox(height: 8),
        Text(
          _byAmount
              ? '自動計算　数量 ${qty == null ? '—' : formatQuantity(qty)}'
              : '自動計算　金額 ${amount == null ? '—' : formatYen(amount)}',
          key: const Key('flow-calc'),
        ),
        if (calcNote != null)
          Text(calcNote, style: Theme.of(context).textTheme.bodySmall),
      ];
    }
    if (widget.kind == AssetFlowKind.buy && !isQty) {
      return [
        amountField,
        if (!_isPlan) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _valueAtBuy,
            decoration: const InputDecoration(
              labelText: '購入日の評価額（空なら購入額）',
              prefixText: '¥ ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ];
    }
    if (widget.kind == AssetFlowKind.sell && isQty) {
      return [qtyField, const SizedBox(height: 16), amountField];
    }
    if (widget.kind == AssetFlowKind.sell) {
      return [
        const Text('評価額の資産は数量の欄がなく、全部の売却になります。'),
        const SizedBox(height: 8),
        amountField,
      ];
    }
    return [amountField];
  }

  Widget _costRow(_CostDraft c, List<CategoryRow> cats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: c.categoryId,
              decoration: InputDecoration(labelText: '${c.label}のカテゴリ'),
              isExpanded: true,
              items: [
                for (final x in cats)
                  DropdownMenuItem(value: x.id, child: Text(x.name)),
              ],
              validator: (v) => v == null ? '選んでください' : null,
              onChanged: (v) => setState(() => c.categoryId = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: c.amount,
              decoration: const InputDecoration(
                labelText: '金額',
                prefixText: '¥',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              validator: (v) => int.tryParse(v ?? '') == null ? '入力' : null,
            ),
          ),
          IconButton(
            tooltip: '外す',
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _costs.remove(c);
              if (identical(c, _taxRow)) _taxRow = null;
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
    String planId,
    AssetRow? asset,
    int? amount,
    int? qty,
  ) async {
    if (!_form.currentState!.validate() || asset == null) return;
    final isQty = Valuation.of(asset.valuation) == Valuation.quantity;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('金額を入れてください')));
      return;
    }
    final needsQty =
        isQty && (_action == AssetAction.buy || _action == AssetAction.sell);
    if (needsQty && (qty == null || qty <= 0)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('数量を入れてください')));
      return;
    }
    final valueAtBuy = int.tryParse(_valueAtBuy.text) ?? amount;
    await ref
        .read(assetRepositoryProvider)
        .recordFlow(
          AssetFlowInput(
            planId: planId,
            assetId: asset.id,
            action: _action,
            amount: amount,
            accountId: _accountId!,
            categoryId: _categoryId!,
            date: _isPlan ? null : dateString(_date),
            ym: _isPlan ? _ym : null,
            quantityX1e4: needsQty ? qty : null,
            memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
            costs: [
              for (final c in _costs)
                if ((int.tryParse(c.amount.text) ?? 0) > 0)
                  CostLine(
                    categoryId: c.categoryId!,
                    amount: int.parse(c.amount.text),
                    memo: c.label == '税金' ? '税金' : null,
                  ),
            ],
            valueAtBuyX100: _action == AssetAction.buy && !isQty && !_isPlan
                ? valueAtBuy * 100
                : null,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }
}
