import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/template_repository.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';

/// 家計簿のリストで選んだ実績から、テンプレートを作る／新しいグループを作る（設計書 3.2）。
///
/// 実績1件ごとに新しいテンプレートを作る（既存のテンプレートは使わない）。名前の初期値は実績のメモ、
/// なければカテゴリ名（振替は「口座→口座」）。グループのときは、それらを項目（毎月・固定額）にした
/// 新しいグループを作る。
class RegisterFromTxnsScreen extends ConsumerStatefulWidget {
  const RegisterFromTxnsScreen({
    super.key,
    required this.txnIds,
    required this.asGroup,
  });

  final List<String> txnIds;
  final bool asGroup;

  @override
  ConsumerState<RegisterFromTxnsScreen> createState() =>
      _RegisterFromTxnsScreenState();
}

class _RegisterFromTxnsScreenState
    extends ConsumerState<RegisterFromTxnsScreen> {
  final _form = GlobalKey<FormState>();
  final _groupName = TextEditingController();
  List<TxnRow>? _txns;
  final List<TextEditingController> _names = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _groupName.dispose();
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(txnRepositoryProvider);
    final cats = {
      for (final c in await ref.readOnce(categoriesProvider.future)) c.id: c,
    };
    final accounts = {
      for (final a in await ref.readOnce(accountsProvider.future)) a.id: a,
    };
    final txns =
        [for (final id in widget.txnIds) ?await repo.getTxn(id)]
            .where((t) => t.deletedAt == null)
            .toList()
          // 日付の古い順、同じ日は作った順（グループの項目の並びになる）
          ..sort(
            (a, b) => a.date != b.date
                ? a.date.compareTo(b.date)
                : a.createdAt.compareTo(b.createdAt),
          );
    String defaultName(TxnRow t) {
      final memo = t.memo?.trim();
      if (memo != null && memo.isNotEmpty) return memo;
      if (t.kind == TxnKind.transfer.code) {
        return '${accounts[t.accountId]?.name ?? '?'}→${accounts[t.toAccountId]?.name ?? '?'}';
      }
      return cats[t.categoryId]?.name ?? '';
    }

    if (!mounted) return;
    setState(() {
      _txns = txns;
      _names.addAll([
        for (final t in txns) TextEditingController(text: defaultName(t)),
      ]);
    });
  }

  Future<void> _save() async {
    final txns = _txns;
    if (txns == null || txns.isEmpty || _saving) return;
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref
        .read(templateRepositoryProvider)
        .createFromTxns(
          inputs: [
            for (final (i, t) in txns.indexed)
              TemplateRepository.inputFromTxn(t, name: _names[i].text.trim()),
          ],
          groupName: widget.asGroup ? _groupName.text.trim() : null,
        );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final groupId = result.groupId;
    context.pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          groupId == null
              ? 'テンプレートを${result.templateIds.length}件作りました'
              : 'グループ「${_groupName.text.trim()}」を作りました（項目${result.templateIds.length}件）',
        ),
        // テンプレートはホームの「テンプレート」タブに並ぶ。グループは編集画面で頻度などを直せる
        action: groupId == null
            ? null
            : SnackBarAction(
                label: '開く',
                onPressed: () => router.push('/home/group/$groupId'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = {
      for (final c
          in ref.watch(categoriesProvider).value ?? const <CategoryRow>[])
        c.id: c,
    };
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const <AccountRow>[])
        a.id: a,
    };
    final txns = _txns;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asGroup ? '実績からグループを作る' : '実績からテンプレートを作る'),
      ),
      body: txns == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.asGroup
                        ? '選んだ実績1件ごとにテンプレートを新しく作り、それらを項目にしたグループを作ります。'
                              '項目は「毎月・固定額」で作ります。頻度や割合はあとでグループ編集で直せます。'
                        : '選んだ実績1件ごとにテンプレートを新しく作ります。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '金額・カテゴリ・口座・資産・メモは実績から写します（イベントは写しません）。'
                    '金額の上昇は「カテゴリの率」になります。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (widget.asGroup) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('reg-group-name'),
                      controller: _groupName,
                      decoration: const InputDecoration(
                        labelText: 'グループ名',
                        hintText: '例：A社の給与明細',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '入力してください' : null,
                    ),
                  ],
                  SectionTitle('作るテンプレート（${txns.length}件）'),
                  for (final (i, t) in txns.indexed)
                    Builder(
                      builder: (context) {
                        final kind = TxnKind.of(t.kind);
                        final where = kind == TxnKind.transfer
                            ? '${accounts[t.accountId]?.name ?? '?'} → ${accounts[t.toAccountId]?.name ?? '?'}'
                            : '${categories[t.categoryId]?.name ?? 'カテゴリなし'}・${accounts[t.accountId]?.name ?? '?'}';
                        final noCategory =
                            kind != TxnKind.transfer &&
                            !categories.containsKey(t.categoryId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  KindBadge(kind.label),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${t.date.replaceAll('-', '/')}　$where',
                                    ),
                                  ),
                                  Text(formatYen(t.amount)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                key: Key('reg-name-$i'),
                                controller: _names[i],
                                decoration: const InputDecoration(
                                  labelText: 'テンプレート名',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? '入力してください'
                                    : null,
                              ),
                              if (noCategory)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'カテゴリが空です。作ったあと、テンプレートの編集で選び直してください。',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SaveCancelBar(
        saveKey: const Key('reg-save'),
        saveLabel: widget.asGroup
            ? 'グループを作る'
            : 'テンプレートを${txns?.length ?? 0}件作る',
        onSave: txns == null || txns.isEmpty || _saving ? null : _save,
      ),
    );
  }
}
