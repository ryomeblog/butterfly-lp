import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/template_repository.dart';
import '../../domain/calc/growth.dart';
import '../../domain/models/enums.dart';
import '../assets/asset_common.dart';
import '../shared/widgets.dart';

/// テンプレートの追加・編集（ワイヤーフレーム TemplateEdit）。
///
/// 資産の参照（購入・売却・収益・費用の雛形）は資産の実装（M5）で加える。
class TemplateEditScreen extends ConsumerStatefulWidget {
  const TemplateEditScreen({super.key, this.templateId});

  final String? templateId;

  @override
  ConsumerState<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends ConsumerState<TemplateEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _memo = TextEditingController();
  final _rate = TextEditingController(text: '0');
  TxnKind _kind = TxnKind.expense;
  String? _categoryId;
  String? _accountId;
  String? _toAccountId;
  GrowthMode _growth = GrowthMode.category;
  bool _loaded = false;

  /// 資産の参照（任意）
  String? _assetId;
  AssetAction? _assetAction;

  /// 数量×単価の資産の購入・売却：金額で指定（true）か数量で指定（false）
  bool _byAmount = true;
  final _quantity = TextEditingController();

  bool get _isNew => widget.templateId == null;

  @override
  void initState() {
    super.initState();
    _rate.addListener(() => setState(() {}));
    _amount.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    final id = widget.templateId;
    if (id != null) {
      final t = await ref.read(templateRepositoryProvider).getTemplate(id);
      if (t != null) {
        _assetId = t.assetId;
        _assetAction = t.assetAction == null
            ? null
            : AssetAction.of(t.assetAction!);
        _byAmount = t.quantityX1e4 == null;
        _quantity.text = t.quantityX1e4 == null
            ? ''
            : formatQuantity(t.quantityX1e4!);
        _name.text = t.name;
        _amount.text = t.amount?.toString() ?? '';
        _memo.text = t.memo ?? '';
        _kind = TxnKind.of(t.kind);
        _categoryId = t.categoryId;
        _accountId = t.accountId;
        _toAccountId = t.toAccountId;
        _growth = GrowthMode.of(t.growthMode);
        _rate.text = t.growthRate?.toString() ?? '0';
      }
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _memo.dispose();
    _rate.dispose();
    _quantity.dispose();
    super.dispose();
  }

  /// 種類に合った資産の動き（支出は購入／費用、収入は売却／収益）。
  AssetAction get _effectiveAction {
    final actions = _kind == TxnKind.expense
        ? const [AssetAction.buy, AssetAction.cost]
        : const [AssetAction.sell, AssetAction.income];
    return actions.contains(_assetAction) ? _assetAction! : actions.last;
  }

  bool get _isBuySell =>
      _assetId != null &&
      _kind != TxnKind.transfer &&
      (_effectiveAction == AssetAction.buy ||
          _effectiveAction == AssetAction.sell);

  /// 振替と資産の購入・売却は金額を増やさない（設計書 6.3）
  bool get _hasGrowth => _kind != TxnKind.transfer && !_isBuySell;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final linked = _kind == TxnKind.transfer ? null : _assetId;
    final byQty = linked != null && _isBuySell && !_byAmount;
    final input = TemplateInput(
      name: _name.text.trim(),
      kind: _kind,
      amount: byQty || _amount.text.isEmpty ? null : int.parse(_amount.text),
      assetId: linked,
      assetAction: linked == null ? null : _effectiveAction,
      quantityX1e4: byQty ? parseQuantity(_quantity.text) : null,
      categoryId: _categoryId,
      accountId: _accountId,
      toAccountId: _toAccountId,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      growthMode: _growth,
      growthRate: double.tryParse(_rate.text),
    );
    final repo = ref.read(templateRepositoryProvider);
    if (_isNew) {
      await repo.createTemplate(input);
    } else {
      await repo.updateTemplate(widget.templateId!, input);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final groups = await ref.readOnce(
      groupsUsingTemplateProvider(widget.templateId!).future,
    );
    if (!mounted) return;
    final ok = await showTemplateDeleteDialog(
      context,
      templateName: _name.text,
      groups: groups,
    );
    if (ok != true) return;
    await ref
        .read(templateRepositoryProvider)
        .deleteTemplate(widget.templateId!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final cats = categories.where((c) => c.kind == _kind.code).toList();
    final usedBy = _isNew
        ? const <TemplateGroupRow>[]
        : (ref.watch(groupsUsingTemplateProvider(widget.templateId!)).value ??
              const []);
    final catMissing =
        _kind != TxnKind.transfer &&
        _categoryId != null &&
        !cats.any((c) => c.id == _categoryId);

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'テンプレートを作成' : 'テンプレートを編集')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('template-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'テンプレート名'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '入力してください' : null,
                  ),
                  const SectionTitle('種類'),
                  SegmentedButton<TxnKind>(
                    segments: const [
                      ButtonSegment(value: TxnKind.expense, label: Text('支出')),
                      ButtonSegment(value: TxnKind.income, label: Text('収入')),
                      ButtonSegment(value: TxnKind.transfer, label: Text('振替')),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() {
                      _kind = s.first;
                      if (!categories.any(
                        (c) => c.id == _categoryId && c.kind == _kind.code,
                      )) {
                        _categoryId = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (_kind != TxnKind.transfer) ..._assetFields(),
                  if (_isBuySell && _isQuantityAsset && !_byAmount)
                    TextFormField(
                      key: const Key('template-quantity'),
                      controller: _quantity,
                      decoration: const InputDecoration(
                        labelText: '数量',
                        helperText: 'プランに登録すると、その月の見込み単価×数量の金額になります',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final q = parseQuantity(v ?? '');
                        return (q == null || q <= 0) ? '数量を入れてください' : null;
                      },
                    )
                  else
                    YenField(controller: _amount, label: '金額（円）'),
                  const SizedBox(height: 16),
                  if (_kind != TxnKind.transfer)
                    DropdownButtonFormField<String>(
                      key: const Key('template-category'),
                      initialValue: catMissing ? null : _categoryId,
                      decoration: InputDecoration(
                        labelText: 'カテゴリ',
                        errorText: catMissing
                            ? 'カテゴリが削除されています。選び直してください'
                            : null,
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
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  const SizedBox(height: 16),
                  _AccountDropdown(
                    key: const Key('template-account'),
                    label: _kind == TxnKind.income ? '口座（入金先）' : '口座（出金元）',
                    value: _accountId,
                    accounts: accounts,
                    onChanged: (v) => setState(() => _accountId = v),
                  ),
                  if (_kind == TxnKind.transfer) ...[
                    const SizedBox(height: 16),
                    _AccountDropdown(
                      key: const Key('template-to-account'),
                      label: '入金先口座',
                      value: _toAccountId,
                      accounts: accounts,
                      onChanged: (v) => setState(() => _toAccountId = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _memo,
                    decoration: const InputDecoration(labelText: 'メモ（実績に引き継ぐ）'),
                  ),
                  if (_hasGrowth) _growthCard(context),
                  if (!_isNew) ...[
                    const SizedBox(height: 16),
                    _UsedGroupsBox(groups: usedBy),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      key: const Key('template-delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _delete,
                      child: const Text('テンプレートを削除'),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: SaveCancelBar(
        onSave: _loaded ? _save : null,
        saveKey: const Key('template-save'),
      ),
    );
  }

  bool get _isQuantityAsset {
    final plan = ref.read(selectedPlanProvider).value;
    final assets = plan == null
        ? const <AssetRow>[]
        : (ref.read(assetsProvider(plan.id)).value ?? const <AssetRow>[]);
    final a = assets.where((x) => x.id == _assetId).firstOrNull;
    return a != null && Valuation.of(a.valuation) == Valuation.quantity;
  }

  /// 資産（任意）と資産の動き。資産を参照するテンプレートは、その資産のプランでだけ使える（設計書 3.2）。
  List<Widget> _assetFields() {
    final plan = ref.watch(selectedPlanProvider).value;
    final assets = plan == null
        ? const <AssetRow>[]
        : (ref.watch(assetsProvider(plan.id)).value ?? const <AssetRow>[]);
    final inPlan = _assetId == null || assets.any((a) => a.id == _assetId);
    final actions = _kind == TxnKind.expense
        ? const [AssetAction.buy, AssetAction.cost]
        : const [AssetAction.sell, AssetAction.income];
    return [
      if (!inPlan)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('別のプランの資産を参照しています（そのプランでだけ使えます）。表示プランを切り替えると変更できます。'),
        )
      else ...[
        DropdownButtonFormField<String?>(
          key: const Key('template-asset'),
          initialValue: _assetId,
          decoration: const InputDecoration(labelText: '資産（任意・表示中のプランの資産）'),
          items: [
            const DropdownMenuItem(value: null, child: Text('なし')),
            for (final a in assets)
              DropdownMenuItem(value: a.id, child: Text(a.name)),
          ],
          onChanged: (v) => setState(() => _assetId = v),
        ),
        const SizedBox(height: 12),
      ],
      if (_assetId != null) ...[
        SegmentedButton<AssetAction>(
          segments: [
            for (final a in actions)
              ButtonSegment(value: a, label: Text(a.label)),
          ],
          selected: {_effectiveAction},
          onSelectionChanged: inPlan
              ? (v) => setState(() => _assetAction = v.first)
              : null,
        ),
        const SizedBox(height: 12),
        if (_isBuySell && _isQuantityAsset) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('金額で指定')),
              ButtonSegment(value: false, label: Text('数量で指定')),
            ],
            selected: {_byAmount},
            onSelectionChanged: (v) => setState(() => _byAmount = v.first),
          ),
          const SizedBox(height: 12),
        ],
      ],
    ];
  }

  Widget _growthCard(BuildContext context) {
    final base = int.tryParse(_amount.text);
    final rate = double.tryParse(_rate.text) ?? 0;
    return Card(
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '金額の上昇（インフレ率・昇給率）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text('プランに登録して予定を作るとき、年ごとに金額を増やします。'),
            const SizedBox(height: 12),
            SegmentedButton<GrowthMode>(
              segments: [
                for (final g in GrowthMode.values)
                  ButtonSegment(value: g, label: Text(g.label)),
              ],
              selected: {_growth},
              onSelectionChanged: (s) => setState(() => _growth = s.first),
            ),
            const SizedBox(height: 12),
            switch (_growth) {
              GrowthMode.category => const Text(
                'プランの「率の設定」にある、このカテゴリの上昇率（なければプランの既定値）で増やします。',
              ),
              GrowthMode.none => const Text('金額を増やしません。'),
              GrowthMode.template => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160,
                    child: DecimalField(
                      key: const Key('template-rate'),
                      controller: _rate,
                      label: '年率',
                      suffix: '%／年',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {1: IntrinsicColumnWidth()},
                    children: [
                      const TableRow(
                        children: [
                          Text(
                            '登録の開始年から',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '金額',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      for (final (label, years) in const [
                        ('開始年', 0),
                        ('1年後', 1),
                        ('5年後', 5),
                        ('10年後', 10),
                      ])
                        TableRow(
                          children: [
                            Text(label),
                            Text(
                              base == null
                                  ? '—'
                                  : formatYen(grownAmount(base, rate, years)),
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '金額×(1＋年率)^(対象年−開始年)、円未満切り上げ。全プラン共通で、'
                    'プランの「率の設定」のカテゴリの率より優先します。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<AccountRow> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final missing = value != null && !accounts.any((a) => a.id == value);
    return DropdownButtonFormField<String>(
      initialValue: missing ? null : value,
      decoration: InputDecoration(
        labelText: label,
        errorText: missing ? '口座が削除されています。選び直してください' : null,
      ),
      items: [
        for (final a in accounts)
          DropdownMenuItem(value: a.id, child: Text(a.name)),
      ],
      validator: (v) => v == null ? '選んでください' : null,
      onChanged: onChanged,
    );
  }
}

class _UsedGroupsBox extends StatelessWidget {
  const _UsedGroupsBox({required this.groups});

  final List<TemplateGroupRow> groups;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: groups.isEmpty
          ? const Text('このテンプレートを使っているグループはありません。')
          : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('使っているグループ：'),
                for (final g in groups)
                  TextButton(
                    onPressed: () => context.push('/home/group/${g.id}'),
                    child: Text(g.name),
                  ),
                const Text('変更は、グループを登録し直すか「作り直し」をしたときに予定へ反映します。'),
              ],
            ),
    );
  }
}

/// テンプレートの削除の警告（ワイヤーフレーム HomeTemplates）。
/// 使っているグループを示し、グループ名からグループ編集へ移れる（先に項目を差し替えられる）。
Future<bool?> showTemplateDeleteDialog(
  BuildContext context, {
  required String templateName,
  required List<TemplateGroupRow> groups,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('「$templateName」を削除しますか'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (groups.isNotEmpty) ...[
            const Text('このテンプレートはグループで使われています：'),
            for (final g in groups)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                  context.push('/home/group/${g.id}');
                },
                child: Text('・${g.name}'),
              ),
            const Text(
              '削除すると、これらのグループの項目が欠けます。グループを登録・使用するときに、欠けている項目の確認が出ます。'
              'グループ名を押すと、先に項目を差し替えられます。',
            ),
            const SizedBox(height: 8),
          ],
          const Text('作成済みの予定・実績は消えません。'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('template-delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('削除する'),
        ),
      ],
    ),
  );
}
