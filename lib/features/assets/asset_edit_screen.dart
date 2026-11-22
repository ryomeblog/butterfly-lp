import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/asset_repository.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';
import 'asset_common.dart';

/// 資産の追加・編集（ワイヤーフレーム AssetEdit）。
///
/// 資産名、カテゴリ（資産のカテゴリ。その場で作成も可）、評価のしかた、コード、保管口座、価値（日・月単位で何件でも）。
/// グループやテンプレートは自動では作らない（設計書 3.3）。
class AssetEditScreen extends ConsumerStatefulWidget {
  const AssetEditScreen({super.key, this.assetId});

  final String? assetId;

  @override
  ConsumerState<AssetEditScreen> createState() => _AssetEditScreenState();
}

class _ValueDraft {
  _ValueDraft(this.unit, this.date, this.valueX100);
  final String unit;
  final String date;
  final int valueX100;
}

class _AssetEditScreenState extends ConsumerState<AssetEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  String? _categoryId;
  Valuation? _valuation;
  String? _accountId;
  bool _loaded = false;

  /// 新規のときだけ使う（保存時にまとめて入れる）
  final List<_ValueDraft> _drafts = [];

  bool get _isNew => widget.assetId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.assetId;
    if (id != null) {
      final a = await ref.read(assetRepositoryProvider).getAsset(id);
      if (a != null) {
        _name.text = a.name;
        _code.text = a.code ?? '';
        _categoryId = a.categoryId;
        _valuation = Valuation.of(a.valuation);
        _accountId = a.accountId;
      }
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final plan = ref.read(selectedPlanProvider).value;
    if (plan == null) return;
    final repo = ref.read(assetRepositoryProvider);
    final existing = _isNew ? null : await repo.getAsset(widget.assetId!);
    final input = AssetInput(
      planId: existing?.planId ?? plan.id,
      name: _name.text.trim(),
      categoryId: _categoryId!,
      valuation: _valuation ?? Valuation.value,
      code: _code.text.trim().isEmpty ? null : _code.text.trim(),
      accountId: _accountId,
    );
    if (_isNew) {
      final id = await repo.createAsset(input);
      for (final d in _drafts) {
        await repo.setValue(id, d.unit, d.date, d.valueX100);
      }
    } else {
      await repo.updateAsset(widget.assetId!, input);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addValue() async {
    final v = await showValueDialog(
      context,
      valuation: _valuation ?? Valuation.value,
    );
    if (v == null) return;
    if (_isNew) {
      setState(() {
        _drafts.removeWhere((d) => d.date == v.$2);
        _drafts.add(_ValueDraft(v.$1, v.$2, v.$3));
      });
    } else {
      await ref
          .read(assetRepositoryProvider)
          .setValue(widget.assetId!, v.$1, v.$2, v.$3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    final cats = [
      for (final c
          in ref.watch(categoriesProvider).value ?? const <CategoryRow>[])
        if (c.kind == CategoryKind.asset.code) c,
    ];
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final values = _isNew
        ? const <AssetValueRow>[]
        : (ref.watch(assetValuesProvider(widget.assetId!)).value ??
              const <AssetValueRow>[]);
    final valuation = _valuation ?? Valuation.value;
    final valueName = valuation == Valuation.quantity ? '単価' : '評価額';

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? '資産を追加' : '資産を編集')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isNew && plan != null)
                    Text(
                      '表示中のプラン「${plan.name}」の資産として追加します。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('asset-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: '資産名'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '入力してください' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('asset-category'),
                    initialValue: cats.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'カテゴリ（全プラン共通）',
                    ),
                    items: [
                      for (final c in cats)
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
                    onChanged: (v) => setState(() {
                      _categoryId = v;
                      // 新規は、カテゴリの既定の評価のしかたを初期値にする
                      final c = cats.firstWhere((c) => c.id == v);
                      if (_isNew && c.defaultValuation != null) {
                        _valuation = Valuation.of(c.defaultValuation!);
                      }
                    }),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          context.push('/assets/category/new?kind=asset'),
                      child: const Text('＋ 資産のカテゴリを作る'),
                    ),
                  ),
                  const SectionTitle('評価のしかた'),
                  SegmentedButton<Valuation>(
                    segments: [
                      for (final v in Valuation.values)
                        ButtonSegment(value: v, label: Text(v.label)),
                    ],
                    selected: {valuation},
                    // 価値の意味（単価か評価額か）が変わるので、価値を記録した後は変えない
                    onSelectionChanged:
                        (!_isNew && values.isNotEmpty) || _drafts.isNotEmpty
                        ? null
                        : (s) => setState(() => _valuation = s.first),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valuation == Valuation.quantity
                        ? '株式・投資信託など。保有数は購入・売却の数量から求め、評価額＝保有数×単価。'
                        : '不動産・車・持ち物など。資産全体の評価額を直接指定します。売却は全部の売却です。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _code,
                    decoration: const InputDecoration(labelText: 'コード（任意・表示用）'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: accounts.any((a) => a.id == _accountId)
                        ? _accountId
                        : null,
                    decoration: const InputDecoration(labelText: '保管口座（任意）'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('なし')),
                      for (final a in accounts)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _accountId = v),
                  ),
                  SectionTitle(
                    '価値（$valueName）',
                    trailing: TextButton(
                      key: const Key('value-add'),
                      onPressed: _addValue,
                      child: const Text('追加'),
                    ),
                  ),
                  Text(
                    '日単位か月単位で何件でも指定できます。指定のない期間は直前の値が続きます。値下がりも手入力で指定します。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  for (final d in _drafts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${d.unit == 'day' ? '日' : '月'}　${d.date}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatX100(d.valueX100)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _drafts.remove(d)),
                          ),
                        ],
                      ),
                    ),
                  for (final v in values)
                    ValueTile(
                      value: v,
                      onDelete: () =>
                          ref.read(assetRepositoryProvider).deleteValue(v.id),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    '購入した記録は、保存後に「購入」で入力します（支出として家計簿に入ります）。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SaveCancelBar(
        onSave: _loaded ? _save : null,
        saveLabel: '資産を保存',
        saveKey: const Key('asset-save'),
      ),
    );
  }
}

/// 価値1件の行。
class ValueTile extends StatelessWidget {
  const ValueTile({super.key, required this.value, required this.onDelete});

  final AssetValueRow value;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final future =
        value.valueDate.compareTo(
          value.unit == 'day' ? todayString() : todayString().substring(0, 7),
        ) >
        0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        '${value.unit == 'day' ? '日' : '月'}　${value.valueDate}${future ? '（見込み）' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatX100(value.valueX100)),
          IconButton(
            tooltip: '削除',
            icon: const Icon(Icons.close),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// 価値の追加。（単位, 日付文字列, 値×100）を返す。
Future<(String, String, int)?> showValueDialog(
  BuildContext context, {
  required Valuation valuation,
}) {
  return showDialog<(String, String, int)>(
    context: context,
    builder: (context) => _ValueDialog(valuation: valuation),
  );
}

class _ValueDialog extends StatefulWidget {
  const _ValueDialog({required this.valuation});

  final Valuation valuation;

  @override
  State<_ValueDialog> createState() => _ValueDialogState();
}

class _ValueDialogState extends State<_ValueDialog> {
  String _unit = 'month';
  DateTime _date = clock.now();
  final _value = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _unit == 'day'
        ? '${_date.year}/${_date.month}/${_date.day}'
        : '${_date.year}年${_date.month}月';
    return AlertDialog(
      title: const Text('価値を追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'day', label: Text('日')),
              ButtonSegment(value: 'month', label: Text('月')),
            ],
            selected: {_unit},
            onSelectionChanged: (s) => setState(() => _unit = s.first),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
              );
              if (d != null) setState(() => _date = d);
            },
            child: Text(dateText),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('value-input'),
            controller: _value,
            decoration: InputDecoration(
              labelText: widget.valuation == Valuation.quantity
                  ? '1単位あたりの単価（円）'
                  : '評価額（円）',
              helperText: '小数第2位まで',
              prefixText: '¥ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('value-ok'),
          onPressed: () {
            final v = parseX100(_value.text);
            if (v == null) return;
            final date = _unit == 'day'
                ? dateString(_date)
                : YearMonth.ofDate(_date).toString();
            Navigator.pop(context, (_unit, date, v));
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}
