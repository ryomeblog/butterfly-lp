import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/repositories/master_repository.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';
import 'master_delete_dialog.dart';

/// カテゴリの追加・編集（ワイヤーフレーム CategoryEdit）。ホームのカテゴリタブと設定の両方から開く。
class CategoryEditScreen extends ConsumerStatefulWidget {
  const CategoryEditScreen({super.key, this.categoryId, this.initialKind});

  final String? categoryId;
  final CategoryKind? initialKind;

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  CategoryKind _kind = CategoryKind.expense;
  String _color = categoryPalette.first;
  Valuation _valuation = Valuation.value;
  bool _saleTax = false;
  bool _loaded = false;
  bool _used = false;

  bool get _isNew => widget.categoryId == null;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind ?? CategoryKind.expense;
    _load();
  }

  Future<void> _load() async {
    final id = widget.categoryId;
    if (id == null) {
      // 新規は、同じ種類のカテゴリの数で次の色を選ぶ。
      final cats = await ref.readOnce(categoriesProvider.future);
      final n = cats.where((c) => c.kind == _kind.code).length;
      setState(() {
        _color = categoryPalette[n % categoryPalette.length];
        _loaded = true;
      });
      return;
    }
    final repo = ref.read(masterRepositoryProvider);
    final c = await repo.getCategory(id);
    final usage = await repo.categoryUsage(id);
    if (c == null) return;
    setState(() {
      _name.text = c.name;
      _kind = CategoryKind.of(c.kind);
      _color = c.color;
      _valuation = c.defaultValuation == null
          ? Valuation.value
          : Valuation.of(c.defaultValuation!);
      _saleTax = c.saleTaxDefault == 1;
      _used = usage.isUsed;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final input = CategoryInput(
      name: _name.text.trim(),
      kind: _kind,
      color: _color,
      defaultValuation: _valuation,
      saleTaxDefault: _saleTax,
    );
    final repo = ref.read(masterRepositoryProvider);
    if (_isNew) {
      await repo.createCategory(input);
    } else {
      await repo.updateCategory(widget.categoryId!, input);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final id = widget.categoryId!;
    final repo = ref.read(masterRepositoryProvider);
    final usage = await repo.categoryUsage(id);
    final cats = await ref.readOnce(categoriesProvider.future);
    if (!mounted) return;
    final isAsset = _kind == CategoryKind.asset;
    final choice = await showMasterDeleteDialog(
      context,
      title: '「${_name.text}」を削除',
      usage: usage,
      targets: [
        for (final c in cats)
          if (c.kind == _kind.code && c.id != id) ReassignTarget(c.id, c.name),
      ],
      withHistoryLabel: isAsset ? '資産ごと削除' : '関連する履歴ごと削除',
      withHistoryDescription: isAsset
          ? 'このカテゴリの資産を全プランから削除します（価値と、その資産の実績・予定も削除）。'
                'その資産を使うテンプレートは残り、資産の欄が空になります。'
          : 'このカテゴリの実績・計画行を削除します。テンプレートは残り、カテゴリの欄が空になります。',
    );
    if (choice == null) return;
    switch (choice) {
      case DeleteWithHistory():
        await repo.deleteCategoryWithHistory(id);
      case ReassignAndDelete(:final toId):
        await repo.reassignCategoryAndDelete(id, toId);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'カテゴリを追加' : 'カテゴリを編集'),
        actions: [
          if (!_isNew)
            IconButton(
              key: const Key('category-delete'),
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('category-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'カテゴリ名'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '入力してください' : null,
                  ),
                  const SectionTitle('種類'),
                  SegmentedButton<CategoryKind>(
                    segments: [
                      for (final k in CategoryKind.values)
                        ButtonSegment(value: k, label: Text(k.label)),
                    ],
                    selected: {_kind},
                    // 使われているカテゴリの種類は変えない（実績の種類と食い違うため）
                    onSelectionChanged: _used
                        ? null
                        : (s) => setState(() => _kind = s.first),
                  ),
                  if (_used)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '使われているカテゴリは種類を変えられません。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SectionTitle('色（10色から選ぶ。円グラフ・内訳・資産一覧に使います）'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final c in categoryPalette)
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 3,
                                color: _color == c
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                              ),
                            ),
                            child: ColorDot(c, size: 32),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '同じ色を複数のカテゴリで使えます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_kind == CategoryKind.asset) ...[
                    const SectionTitle('この種類の資産の既定の評価のしかた'),
                    SegmentedButton<Valuation>(
                      segments: [
                        for (final v in Valuation.values)
                          ButtonSegment(value: v, label: Text(v.label)),
                      ],
                      selected: {_valuation},
                      onSelectionChanged: (s) =>
                          setState(() => _valuation = s.first),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('売却時に税額の初期値（実現損益×20.315%）を出す'),
                      value: _saleTax,
                      onChanged: (v) => setState(() => _saleTax = v),
                    ),
                    Text(
                      '資産の追加画面では、ここで決めた評価のしかたが初期値になります（資産ごとに変更できます）。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'カテゴリは全プラン共通・1階層です。使用中のカテゴリの削除は「履歴ごと削除」か「付け替えて削除」を選びます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SaveCancelBar(
        onSave: _loaded ? _save : null,
        saveKey: const Key('category-save'),
      ),
    );
  }
}
