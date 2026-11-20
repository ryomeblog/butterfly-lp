import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/txn_repository.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';

/// 予定・実績の入力・編集（ワイヤーフレーム TxnEdit）。
///
/// M3 では実績だけを扱う。予定（計画行の手入力）は M4、資産の紐づけは M5、イベントは M6 で加える。
class TxnEditScreen extends ConsumerStatefulWidget {
  const TxnEditScreen({super.key, this.txnId, this.initialDate});

  final String? txnId;
  final String? initialDate;

  @override
  ConsumerState<TxnEditScreen> createState() => _TxnEditScreenState();
}

class _TxnEditScreenState extends ConsumerState<TxnEditScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _memo = TextEditingController();
  TxnKind _kind = TxnKind.expense;
  late DateTime _date = widget.initialDate == null
      ? clock.now()
      : parseDate(widget.initialDate!);
  String? _categoryId;
  String? _accountId;
  String? _toAccountId;
  TxnRow? _original;
  bool _loaded = false;

  bool get _isNew => widget.txnId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.txnId;
    if (id != null) {
      final t = await ref.read(txnRepositoryProvider).getTxn(id);
      if (t != null) {
        _original = t;
        _kind = TxnKind.of(t.kind);
        _date = parseDate(t.date);
        _amount.text = '${t.amount}';
        _memo.text = t.memo ?? '';
        _categoryId = t.categoryId;
        _accountId = t.accountId;
        _toAccountId = t.toAccountId;
      }
    } else {
      final accounts = await ref.read(accountsProvider.future);
      if (accounts.isNotEmpty) _accountId = accounts.first.id;
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  /// 単体テンプレートを選ぶと中身が入る（設計書 3.1）。日付はそのまま。
  Future<void> _fromTemplate() async {
    final templates = (await ref.read(templatesProvider.future))
        .where((t) => t.assetId == null)
        .toList();
    if (!mounted) return;
    final picked = await showModalBottomSheet<TemplateRow>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: templates.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('テンプレートがありません。ホームの「テンプレート」で作れます。'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final t in templates)
                    ListTile(
                      leading: KindBadge(TxnKind.of(t.kind).label),
                      title: Text(t.name),
                      trailing: Text(
                        t.amount == null ? '—' : formatYen(t.amount!),
                      ),
                      onTap: () => Navigator.pop(context, t),
                    ),
                ],
              ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _kind = TxnKind.of(picked.kind);
      if (picked.amount != null) _amount.text = '${picked.amount}';
      _categoryId = picked.categoryId;
      _accountId = picked.accountId ?? _accountId;
      _toAccountId = picked.toAccountId;
      _memo.text = picked.memo ?? '';
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final plan = ref.read(selectedPlanProvider).value;
    if (plan == null) return;
    final input = TxnInput(
      planId: _original?.planId ?? plan.id,
      date: dateString(_date),
      kind: _kind,
      amount: int.parse(_amount.text),
      accountId: _accountId!,
      categoryId: _categoryId,
      toAccountId: _toAccountId,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
    );
    final repo = ref.read(txnRepositoryProvider);
    if (_isNew) {
      await repo.createTxn(input);
    } else {
      await repo.updateTxn(widget.txnId!, input);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: const Text('この実績を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('txn-delete-confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(txnRepositoryProvider).deleteTxn(widget.txnId!);
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final cats = categories.where((c) => c.kind == _kind.code).toList();
    final catMissing =
        _kind != TxnKind.transfer &&
        _categoryId != null &&
        !cats.any((c) => c.id == _categoryId);
    final hasAsset = _original?.assetId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '実績を入力' : '実績を編集'),
        actions: [
          IconButton(
            tooltip: 'この収支をJSONで書き出す',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _snack('JSONの書き出しは M10 で実装します。'),
          ),
          if (!_isNew)
            IconButton(
              key: const Key('txn-delete'),
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
                  if (_isNew) ...[
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('実績')),
                        ButtonSegment(value: false, label: Text('予定')),
                      ],
                      selected: const {true},
                      onSelectionChanged: (_) => _snack('予定の入力は M4 で実装します。'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _fromTemplate,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('テンプレートから入力'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _snack('グループで一括入力は M8 で実装します。'),
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('グループで一括入力'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (plan != null)
                    Text(
                      '表示中のプラン「${plan.name}」の家計簿に記録します。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  SegmentedButton<TxnKind>(
                    segments: const [
                      ButtonSegment(value: TxnKind.expense, label: Text('支出')),
                      ButtonSegment(value: TxnKind.income, label: Text('収入')),
                      ButtonSegment(value: TxnKind.transfer, label: Text('振替')),
                    ],
                    selected: {_kind},
                    onSelectionChanged: hasAsset
                        ? null
                        : (s) => setState(() {
                            _kind = s.first;
                            if (!categories.any(
                              (c) =>
                                  c.id == _categoryId && c.kind == _kind.code,
                            )) {
                              _categoryId = null;
                            }
                          }),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    key: const Key('txn-date'),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '日付（未来日付も可）',
                      ),
                      child: Text('${_date.year}/${_date.month}/${_date.day}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  YenField(key: const Key('txn-amount'), controller: _amount),
                  const SizedBox(height: 16),
                  if (_kind != TxnKind.transfer)
                    DropdownButtonFormField<String>(
                      key: const Key('txn-category'),
                      initialValue: catMissing ? null : _categoryId,
                      decoration: InputDecoration(
                        labelText: 'カテゴリ',
                        errorText: catMissing ? '削除済みのカテゴリです。付け替えてください' : null,
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
                  _accountField(
                    key: const Key('txn-account'),
                    label: _kind == TxnKind.income ? '口座（入金先）' : '口座（出金元）',
                    value: _accountId,
                    accounts: accounts,
                    onChanged: (v) => setState(() => _accountId = v),
                  ),
                  if (_kind == TxnKind.transfer) ...[
                    const SizedBox(height: 16),
                    _accountField(
                      key: const Key('txn-to-account'),
                      label: '入金先口座',
                      value: _toAccountId,
                      accounts: accounts,
                      onChanged: (v) => setState(() => _toAccountId = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('txn-memo'),
                    controller: _memo,
                    decoration: const InputDecoration(labelText: 'メモ'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '給与明細のように複数の収入・支出をまとめて入れるときは「グループで一括入力」を使います。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SaveCancelBar(
        onSave: _loaded ? _save : null,
        saveKey: const Key('txn-save'),
      ),
    );
  }

  Widget _accountField({
    required Key key,
    required String label,
    required String? value,
    required List<AccountRow> accounts,
    required ValueChanged<String?> onChanged,
  }) {
    final missing = value != null && !accounts.any((a) => a.id == value);
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: missing ? null : value,
      decoration: InputDecoration(
        labelText: label,
        errorText: missing ? '削除済みの口座です。付け替えてください' : null,
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
