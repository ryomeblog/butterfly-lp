import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
import '../../data/repositories/master_repository.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';
import 'master_delete_dialog.dart';

/// 口座の追加・編集（ワイヤーフレーム AccountEdit）。
class AccountEditScreen extends ConsumerStatefulWidget {
  const AccountEditScreen({super.key, this.accountId});

  final String? accountId;

  @override
  ConsumerState<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends ConsumerState<AccountEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _balance = TextEditingController(text: '0');
  AccountKind _kind = AccountKind.bank;
  late DateTime _initialDate = clock.now();
  bool _loaded = false;

  bool get _isNew => widget.accountId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.accountId;
    if (id != null) {
      final a = await ref.read(masterRepositoryProvider).getAccount(id);
      if (a != null) {
        _name.text = a.name;
        _balance.text = '${a.initialBalance}';
        _kind = AccountKind.of(a.kind);
        _initialDate = parseDate(a.initialDate);
      }
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final input = AccountInput(
      name: _name.text.trim(),
      kind: _kind,
      initialBalance: int.parse(_balance.text),
      initialDate: dateString(_initialDate),
    );
    final repo = ref.read(masterRepositoryProvider);
    if (_isNew) {
      await repo.createAccount(input);
    } else {
      await repo.updateAccount(widget.accountId!, input);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final id = widget.accountId!;
    final repo = ref.read(masterRepositoryProvider);
    final usage = await repo.accountUsage(id);
    final accounts = await ref.read(accountsProvider.future);
    if (!mounted) return;
    final choice = await showMasterDeleteDialog(
      context,
      title: '「${_name.text}」を削除',
      usage: usage,
      targets: [
        for (final a in accounts)
          if (a.id != id) ReassignTarget(a.id, a.name),
      ],
      withHistoryLabel: '関連する履歴ごと削除',
      withHistoryDescription:
          'この口座の実績・計画行（振替の入金先を含む）を削除します。'
          'テンプレートは残り口座の欄が空に、資産の保管口座も空になります。',
    );
    if (choice == null) return;
    switch (choice) {
      case DeleteWithHistory():
        await repo.deleteAccountWithHistory(id);
      case ReassignAndDelete(:final toId):
        await repo.reassignAccountAndDelete(id, toId);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (d != null) setState(() => _initialDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? '口座を追加' : '口座を編集')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('account-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: '口座名'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '入力してください' : null,
                  ),
                  const SectionTitle('種類'),
                  SegmentedButton<AccountKind>(
                    segments: [
                      for (final k in AccountKind.values)
                        ButtonSegment(value: k, label: Text(k.label)),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                  const SizedBox(height: 16),
                  YenField(
                    controller: _balance,
                    label: '初期残高（円）',
                    allowNegative: true,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '初期残高の基準日'),
                      child: Text(
                        '${_initialDate.year}/${_initialDate.month}/${_initialDate.day}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '残高＝初期残高＋基準日以降の実績。基準日より前の実績は残高に含めません。'
                    '口座は全プラン共通で、残高はプランごとの実績で計算します。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '想定利回りはプランごとに「率の設定」で決めます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!_isNew) ...[
                    const SizedBox(height: 24),
                    OutlinedButton(
                      key: const Key('account-delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _delete,
                      child: const Text('この口座を削除'),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: SaveCancelBar(
        onSave: _loaded ? _save : null,
        saveLabel: '口座を保存',
        saveKey: const Key('account-save'),
      ),
    );
  }
}
