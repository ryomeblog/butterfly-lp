import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/plan_line_repository.dart';
import '../../data/repositories/txn_repository.dart';
import '../../domain/models/enums.dart';
import '../assets/asset_common.dart';
import '../events/event_picker.dart';
import '../shared/widgets.dart';
import '../shared/ym_picker.dart';

/// 予定・実績の入力・編集（ワイヤーフレーム TxnEdit）。
///
/// 「実績／予定」を切り替えて入力する（予定の表示から開くと予定が選ばれた状態）。
/// 予定は表示プランの手入力の計画行（source=manual）として保存する（設計書 3.1）。
class TxnEditScreen extends ConsumerStatefulWidget {
  const TxnEditScreen({
    super.key,
    this.txnId,
    this.planLineId,
    this.initialDate,
    this.initialYm,
    this.startAsPlan = false,
    this.fromLineId,
  });

  final String? txnId;
  final String? planLineId;
  final String? initialDate;
  final String? initialYm;
  final bool startAsPlan;

  /// 予定から実績入力：この計画行の種類・金額・カテゴリ・口座などを入れた実績入力として開く（設計書 3.8）
  final String? fromLineId;

  @override
  ConsumerState<TxnEditScreen> createState() => _TxnEditScreenState();
}

class _TxnEditScreenState extends ConsumerState<TxnEditScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _memo = TextEditingController();
  late bool _isPlan = widget.planLineId != null || widget.startAsPlan;
  TxnKind _kind = TxnKind.expense;
  late DateTime _date = widget.initialDate == null
      ? clock.now()
      : parseDate(widget.initialDate!);
  late YearMonth _ym = widget.initialYm != null
      ? YearMonth.parse(widget.initialYm!)
      : YearMonth.ofDate(_date);
  String? _categoryId;
  String? _accountId;
  String? _toAccountId;

  /// 資産の紐づけ（設計書 3.1）
  String? _assetId;
  AssetAction? _assetAction;
  final _quantity = TextEditingController();
  String? _eventId;

  /// 予定から単発で入力するとき、元がグループ由来なら入れる（設計書 6.8）
  String? _groupId;
  String? _groupItemId;
  TxnRow? _originalTxn;
  PlanLineRow? _originalLine;
  bool _loaded = false;

  bool get _isNew => widget.txnId == null && widget.planLineId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.txnId != null) {
      final t = await ref.read(txnRepositoryProvider).getTxn(widget.txnId!);
      if (t != null) {
        _originalTxn = t;
        _kind = TxnKind.of(t.kind);
        _date = parseDate(t.date);
        _amount.text = '${t.amount}';
        _memo.text = t.memo ?? '';
        _categoryId = t.categoryId;
        _accountId = t.accountId;
        _toAccountId = t.toAccountId;
        _assetId = t.assetId;
        _assetAction = t.assetAction == null
            ? null
            : AssetAction.of(t.assetAction!);
        _quantity.text = t.quantityX1e4 == null
            ? ''
            : formatQuantity(t.quantityX1e4!);
        _eventId = t.eventId;
      }
    } else if (widget.planLineId != null) {
      final l = await ref
          .read(planLineRepositoryProvider)
          .getLine(widget.planLineId!);
      if (l != null) {
        _originalLine = l;
        _kind = TxnKind.of(l.kind);
        _ym = YearMonth(l.year, l.month);
        _amount.text = '${l.amount}';
        _memo.text = l.memo ?? '';
        _categoryId = l.categoryId;
        _accountId = l.accountId;
        _toAccountId = l.toAccountId;
        _assetId = l.assetId;
        _assetAction = l.assetAction == null
            ? null
            : AssetAction.of(l.assetAction!);
        _quantity.text = l.quantityX1e4 == null
            ? ''
            : formatQuantity(l.quantityX1e4!);
        _eventId = l.eventId;
      }
    } else if (widget.fromLineId != null) {
      final l = await ref
          .read(planLineRepositoryProvider)
          .getLine(widget.fromLineId!);
      if (l != null) {
        _isPlan = false;
        _kind = TxnKind.of(l.kind);
        _amount.text = '${l.amount}';
        _memo.text = l.memo ?? '';
        _categoryId = l.categoryId;
        _accountId = l.accountId;
        _toAccountId = l.toAccountId;
        _assetId = l.assetId;
        _assetAction = l.assetAction == null
            ? null
            : AssetAction.of(l.assetAction!);
        _quantity.text = l.quantityX1e4 == null
            ? ''
            : formatQuantity(l.quantityX1e4!);
        _eventId = l.eventId;
        _groupItemId = l.groupItemId;
        if (l.source == PlanLineSource.group.code && l.sourceId != null) {
          final regs = await ref.read(registrationsProvider(l.planId).future);
          _groupId = regs
              .where((r) => r.registration.id == l.sourceId)
              .firstOrNull
              ?.registration
              .groupId;
        }
        // 今月の予定なら今日、それ以外はその月の1日
        final ym = YearMonth(l.year, l.month);
        _date = ym == YearMonth.ofDate(clock.now()) ? clock.now() : ym.firstDay;
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
    _quantity.dispose();
    super.dispose();
  }

  /// 単体テンプレートを選ぶと中身が入る（設計書 3.1）。日付はそのまま。
  Future<void> _fromTemplate() async {
    // 資産を参照するテンプレートは、その資産のプランでだけ使える（設計書 3.2）
    final plan = ref.read(selectedPlanProvider).value;
    final planAssets = plan == null
        ? const <String>{}
        : {
            for (final a in await ref.read(assetsProvider(plan.id).future))
              a.id,
          };
    final templates = (await ref.read(templatesProvider.future))
        .where((t) => t.assetId == null || planAssets.contains(t.assetId))
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
      _assetId = picked.assetId;
      _assetAction = picked.assetAction == null
          ? null
          : AssetAction.of(picked.assetAction!);
      _quantity.text = picked.quantityX1e4 == null
          ? ''
          : formatQuantity(picked.quantityX1e4!);
    });
  }

  /// 種類に合った資産の動き（支出は購入／費用、収入は売却／収益。合わなければ費用・収益）。
  AssetAction get _effectiveAction {
    final actions = _kind == TxnKind.expense
        ? const [AssetAction.buy, AssetAction.cost]
        : const [AssetAction.sell, AssetAction.income];
    return actions.contains(_assetAction) ? _assetAction! : actions.last;
  }

  /// 振替には資産を紐づけない。
  String? get _linkedAsset => _kind == TxnKind.transfer ? null : _assetId;

  int? get _linkedQuantity =>
      _linkedAsset == null ||
          !(_effectiveAction == AssetAction.buy ||
              _effectiveAction == AssetAction.sell)
      ? null
      : parseQuantity(_quantity.text);

  String? get _memoValue =>
      _memo.text.trim().isEmpty ? null : _memo.text.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final plan = ref.read(selectedPlanProvider).value;
    if (plan == null) return;
    if (_isPlan) {
      final input = PlanLineInput(
        planId: _originalLine?.planId ?? plan.id,
        ym: _ym,
        kind: _kind,
        amount: int.parse(_amount.text),
        accountId: _accountId!,
        categoryId: _categoryId,
        toAccountId: _toAccountId,
        memo: _memoValue,
        assetId: _linkedAsset,
        assetAction: _linkedAsset == null ? null : _effectiveAction,
        quantityX1e4: _linkedQuantity,
        eventId: _eventId,
      );
      final repo = ref.read(planLineRepositoryProvider);
      if (_originalLine == null) {
        await repo.createManual(input);
      } else {
        await repo.updateLine(_originalLine!.id, input);
      }
    } else {
      final input = TxnInput(
        planId: _originalTxn?.planId ?? plan.id,
        date: dateString(_date),
        kind: _kind,
        amount: int.parse(_amount.text),
        accountId: _accountId!,
        categoryId: _categoryId,
        toAccountId: _toAccountId,
        memo: _memoValue,
        assetId: _linkedAsset,
        assetAction: _linkedAsset == null ? null : _effectiveAction,
        quantityX1e4: _linkedQuantity,
        eventId: _eventId,
        groupId: _groupId,
        groupItemId: _groupItemId,
      );
      final repo = ref.read(txnRepositoryProvider);
      if (_originalTxn == null) {
        await repo.createTxn(input);
      } else {
        await repo.updateTxn(_originalTxn!.id, input);
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(_isPlan ? 'この予定を削除しますか？' : 'この実績を削除しますか？'),
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
    if (_originalLine != null) {
      await ref.read(planLineRepositoryProvider).deleteLine(_originalLine!.id);
    } else {
      await ref.read(txnRepositoryProvider).deleteTxn(_originalTxn!.id);
    }
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
    final hasAsset = _assetId != null;
    final assets = plan == null
        ? const <AssetRow>[]
        : (ref.watch(assetsProvider(plan.id)).value ?? const <AssetRow>[]);
    final source = _originalLine == null
        ? null
        : PlanLineSource.of(_originalLine!.source);
    final title = _isNew
        ? (_isPlan ? '予定を入力' : '実績を入力')
        : (_isPlan ? '予定を編集' : '実績を編集');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                      key: const Key('txn-mode'),
                      segments: const [
                        ButtonSegment(value: false, label: Text('実績')),
                        ButtonSegment(value: true, label: Text('予定')),
                      ],
                      selected: {_isPlan},
                      onSelectionChanged: (s) =>
                          setState(() => _isPlan = s.first),
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
                        if (!_isPlan)
                          OutlinedButton.icon(
                            onPressed: () => context.pushReplacement(
                              '/entry/group?ym=${YearMonth.ofDate(_date)}',
                            ),
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('グループで一括入力'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (plan != null)
                    Text(
                      _isPlan
                          ? '予定は、表示中のプラン「${plan.name}」の計画行（手入力）として保存します。'
                                'プランを変えるときはホームで切り替えます。'
                          : '表示中のプラン「${plan.name}」の家計簿に記録します。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (source != null && source != PlanLineSource.manual)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${source.label}由来の予定です。編集しても由来は保ちます'
                        '（作り直しをすると置き換わります）。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
                  if (_isPlan)
                    YmPicker(
                      key: const ValueKey('txn-ym'),
                      label: '年月（予定は月単位）',
                      value: _ym,
                      min: YearMonth(1900, 1),
                      max: YearMonth(2200, 12),
                      onChanged: (v) => setState(() => _ym = v),
                    )
                  else
                    InkWell(
                      key: const Key('txn-date'),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '日付（未来日付も可）',
                        ),
                        child: Text(
                          '${_date.year}/${_date.month}/${_date.day}',
                        ),
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
                  if (_kind != TxnKind.transfer) ..._assetFields(assets),
                  const SizedBox(height: 16),
                  EventPicker(
                    value: _eventId,
                    onChanged: (v) => setState(() => _eventId = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('txn-memo'),
                    controller: _memo,
                    decoration: const InputDecoration(labelText: 'メモ'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isPlan
                        ? 'イベントを指定した予定は、そのイベントの予定として予実を比べます。'
                        : '給与明細のように複数の収入・支出をまとめて入れるときは「グループで一括入力」を使います。',
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

  /// 資産（任意）と資産の動き（支出は購入／費用、収入は売却／収益）、購入・売却の数量（設計書 3.1）。
  List<Widget> _assetFields(List<AssetRow> assets) {
    final asset = assets.where((a) => a.id == _assetId).firstOrNull;
    final actions = _kind == TxnKind.expense
        ? const [AssetAction.buy, AssetAction.cost]
        : const [AssetAction.sell, AssetAction.income];
    final action = actions.contains(_assetAction)
        ? _assetAction!
        : actions.last;
    final needsQty =
        asset != null &&
        Valuation.of(asset.valuation) == Valuation.quantity &&
        (action == AssetAction.buy || action == AssetAction.sell);
    return [
      const SizedBox(height: 16),
      DropdownButtonFormField<String?>(
        key: const Key('txn-asset'),
        initialValue: asset?.id,
        decoration: const InputDecoration(labelText: '資産（任意）'),
        items: [
          const DropdownMenuItem(value: null, child: Text('なし')),
          for (final a in assets)
            DropdownMenuItem(value: a.id, child: Text(a.name)),
        ],
        onChanged: (v) => setState(() {
          _assetId = v;
          _assetAction = v == null ? null : action;
        }),
      ),
      if (asset != null) ...[
        const SizedBox(height: 12),
        SegmentedButton<AssetAction>(
          key: const Key('txn-asset-action'),
          segments: [
            for (final a in actions)
              ButtonSegment(value: a, label: Text(a.label)),
          ],
          selected: {action},
          onSelectionChanged: (v) => setState(() => _assetAction = v.first),
        ),
        if (needsQty) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('txn-quantity'),
            controller: _quantity,
            decoration: const InputDecoration(
              labelText: '数量',
              helperText: '小数第4位まで',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final q = parseQuantity(v ?? '');
              return (q == null || q <= 0) ? '数量を入れてください' : null;
            },
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '手数料・税金を一緒に入れる、単価から数量を計算するときは、資産タブの購入・売却の画面を使います。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ];
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
