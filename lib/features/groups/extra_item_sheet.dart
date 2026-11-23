import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';

/// グループからの実績入力で、その回だけ足す臨時の項目（設計書 6.6）。
///
/// グループ・テンプレートには反映しない。テンプレートから選んだときは [templateId] を持つ
/// （中身はテンプレートのものを写す）。直接入力では [name] を実績のメモにする。
class ExtraItem {
  ExtraItem({
    required this.kind,
    required this.name,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.memo,
    this.templateId,
    int? amount,
  }) : amount = TextEditingController(text: amount?.toString() ?? '');

  factory ExtraItem.fromTemplate(TemplateRow t) => ExtraItem(
    kind: TxnKind.of(t.kind),
    name: t.name,
    accountId: t.accountId!,
    categoryId: t.categoryId,
    toAccountId: t.toAccountId,
    assetId: t.assetId,
    assetAction: t.assetAction == null ? null : AssetAction.of(t.assetAction!),
    memo: t.memo,
    templateId: t.id,
    amount: t.amount,
  );

  final Key key = UniqueKey();
  TxnKind kind;
  String name;
  String accountId;
  String? categoryId;
  String? toAccountId;
  String? assetId;
  AssetAction? assetAction;
  String? memo;
  final String? templateId;
  final TextEditingController amount;

  bool get fromTemplate => templateId != null;
}

/// 直接入力の内容（種類・名前・カテゴリ・口座）。
typedef ExtraDraft = ({
  TxnKind kind,
  String name,
  String? categoryId,
  String accountId,
  String? toAccountId,
});

/// 臨時の項目を直接入力するシート。[initial] があれば編集。
Future<ExtraDraft?> showExtraItemSheet(
  BuildContext context, {
  ExtraDraft? initial,
  String? defaultAccountId,
}) => showModalBottomSheet<ExtraDraft>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: _ExtraItemForm(initial: initial, defaultAccountId: defaultAccountId),
  ),
);

class _ExtraItemForm extends ConsumerStatefulWidget {
  const _ExtraItemForm({this.initial, this.defaultAccountId});

  final ExtraDraft? initial;
  final String? defaultAccountId;

  @override
  ConsumerState<_ExtraItemForm> createState() => _ExtraItemFormState();
}

class _ExtraItemFormState extends ConsumerState<_ExtraItemForm> {
  final _form = GlobalKey<FormState>();
  late TxnKind _kind;
  late final TextEditingController _name;
  String? _categoryId;
  String? _accountId;
  String? _toAccountId;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _kind = i?.kind ?? TxnKind.expense;
    _name = TextEditingController(text: i?.name ?? '');
    _categoryId = i?.categoryId;
    _accountId = i?.accountId ?? widget.defaultAccountId;
    _toAccountId = i?.toAccountId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop((
      kind: _kind,
      name: _name.text.trim(),
      categoryId: _kind == TxnKind.transfer ? null : _categoryId,
      accountId: _accountId!,
      toAccountId: _kind == TxnKind.transfer ? _toAccountId : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final cats = categories.where((c) => c.kind == _kind.code).toList();
    if (_accountId != null && !accounts.any((a) => a.id == _accountId)) {
      _accountId = null;
    }
    DropdownButtonFormField<String> accountField(
      Key key,
      String label,
      String? value,
      ValueChanged<String?> onChanged,
    ) => DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final a in accounts)
          DropdownMenuItem(value: a.id, child: Text(a.name)),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? '選んでください' : null,
    );

    return SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('臨時の項目', style: Theme.of(context).textTheme.titleMedium),
            Text(
              '今回の入力だけに足します。グループ・テンプレートは変わりません。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<TxnKind>(
              segments: [
                for (final k in TxnKind.values)
                  ButtonSegment(value: k, label: Text(k.label)),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => setState(() {
                _kind = v.first;
                if (!categories.any(
                  (c) => c.id == _categoryId && c.kind == _kind.code,
                )) {
                  _categoryId = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('extra-name'),
              controller: _name,
              decoration: const InputDecoration(
                labelText: '名前（実績のメモになります）',
                hintText: '例：年末調整の追加徴収、電気料金の補助',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '入力してください' : null,
            ),
            if (_kind != TxnKind.transfer) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('extra-category-${_kind.code}'),
                initialValue: cats.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(labelText: 'カテゴリ'),
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
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? '選んでください' : null,
              ),
            ],
            const SizedBox(height: 12),
            accountField(
              const Key('extra-account'),
              _kind == TxnKind.transfer ? '出金口座' : '口座',
              _accountId,
              (v) => setState(() => _accountId = v),
            ),
            if (_kind == TxnKind.transfer) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('extra-to-account'),
                initialValue: accounts.any((a) => a.id == _toAccountId)
                    ? _toAccountId
                    : null,
                decoration: const InputDecoration(labelText: '入金口座'),
                items: [
                  for (final a in accounts)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _toAccountId = v),
                validator: (v) => v == null
                    ? '選んでください'
                    : v == _accountId
                    ? '出金口座と別の口座を選んでください'
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('extra-ok'),
              onPressed: _submit,
              child: Text(widget.initial == null ? '追加' : '変更'),
            ),
          ],
        ),
      ),
    );
  }
}
