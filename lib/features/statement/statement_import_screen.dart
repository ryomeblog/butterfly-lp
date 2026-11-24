import 'package:clock/clock.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/statement_repository.dart';
import '../../data/statement/amazon.dart';
import '../../data/statement/pdf_lines.dart';
import '../../data/statement/pdf_reader.dart';
import '../../data/statement/statement.dart';
import '../../data/statement/table_mapping.dart';
import '../../data/statement/xlsx.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';

/// 明細の取り込みの入口（家計簿のリスト。デスクトップ版・Web版だけ。設計書 3.11）。
class StatementImportButton extends StatelessWidget {
  const StatementImportButton({super.key, this.asPlan = false});

  final bool asPlan;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton.icon(
      key: const Key('statement-import'),
      onPressed: () =>
          context.push('/entry/statement${asPlan ? '?plan=1' : ''}'),
      icon: const Icon(Icons.receipt_long),
      label: const Text('明細を取り込む（Amazon・Excel・PDF）'),
    ),
  );
}

/// 読む明細の種類。
enum StatementSource {
  amazon('Amazonの注文履歴', 'CSV か、それを含む ZIP', ['csv', 'zip']),
  excel('Excel', '.xlsx。日付・内容・金額の列を指定します', ['xlsx']),
  pdf('PDF', '文字が入ったPDF。「日付 内容 金額」の並びの行を読みます', ['pdf']);

  const StatementSource(this.label, this.hint, this.extensions);
  final String label;
  final String hint;
  final List<String> extensions;
}

class _Row {
  _Row(StatementLine l)
    : content = l.content,
      date = l.date,
      kind = l.amount < 0 ? TxnKind.income : TxnKind.expense,
      amount = TextEditingController(text: '${l.amount.abs()}'),
      memo = TextEditingController(text: l.content);

  final String content;
  String date;
  TxnKind kind;
  String? categoryId;
  bool include = true;
  final TextEditingController amount;
  final TextEditingController memo;

  int? get amountValue => int.tryParse(amount.text);

  void dispose() {
    amount.dispose();
    memo.dispose();
  }
}

const _prefMapping = 'statement.xlsx.mapping';
const _prefAccount = 'statement.account';

/// 明細を読んで、確認してから実績・予定に登録する（設計書 3.11）。
class StatementImportScreen extends ConsumerStatefulWidget {
  const StatementImportScreen({super.key, this.asPlan = false, this.initial});

  final bool asPlan;

  /// テスト用：ファイルを選ばずに、読み取った結果から始める
  @visibleForTesting
  final StatementResult? initial;

  @override
  ConsumerState<StatementImportScreen> createState() =>
      _StatementImportScreenState();
}

class _StatementImportScreenState extends ConsumerState<StatementImportScreen> {
  StatementSource? _source;
  String? _fileName;
  String? _error;
  bool _loading = false;
  bool _saving = false;

  // Excel
  List<XlsxSheet>? _sheets;
  TableMapping? _mapping;

  // PDF
  List<String>? _pdfLines;

  /// 年が書かれていない日付に使う年（PDF・Excel）
  int _year = clock.now().year;

  List<_Row>? _rows;
  int _skipped = 0;

  late bool _asPlan = widget.asPlan;
  String? _accountId;

  StatementRepository get _repo => ref.read(statementRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _repo.pref(_prefAccount).then((v) {
      if (mounted && v != null) setState(() => _accountId ??= v);
    });
    final initial = widget.initial;
    if (initial != null) {
      _source = StatementSource.amazon;
      _fileName = 'test';
      _setLines(initial).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final r in _rows ?? const <_Row>[]) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(StatementSource source) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: source.extensions,
    );
    final f = files.firstOrNull;
    if (f == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await f.readAsBytes();
      _source = source;
      _fileName = f.name;
      _sheets = null;
      _pdfLines = null;
      switch (source) {
        case StatementSource.amazon:
          await _setLines(parseAmazonOrderHistory(bytes));
        case StatementSource.excel:
          final sheets = readXlsx(bytes);
          if (sheets.isEmpty) {
            throw const StatementFormatException('シートがありません');
          }
          final saved = TableMapping.decode(await _repo.pref(_prefMapping));
          _sheets = sheets;
          _mapping = saved != null && sheets.any((s) => s.name == saved.sheet)
              ? saved
              : TableMapping.guess(sheets.first);
          await _reparse();
        case StatementSource.pdf:
          _pdfLines = await readPdfLines(bytes);
          await _reparse();
      }
    } on StatementFormatException catch (e) {
      _error = e.message;
      _setRows(null);
    } catch (e) {
      _error = '読み取れませんでした（$e）';
      _setRows(null);
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Excel の列の指定や年を変えたときに読み直す。
  Future<void> _reparse() async {
    final sheets = _sheets;
    final mapping = _mapping;
    if (sheets != null && mapping != null) {
      final sheet = sheets.firstWhere(
        (s) => s.name == mapping.sheet,
        orElse: () => sheets.first,
      );
      await _setLines(mapping.apply(sheet, defaultYear: _year));
    } else if (_pdfLines != null) {
      await _setLines(parseStatementLines(_pdfLines!, defaultYear: _year));
    }
    if (mounted) setState(() {});
  }

  void _setRows(List<_Row>? rows) {
    for (final r in _rows ?? const <_Row>[]) {
      r.dispose();
    }
    _rows = rows;
  }

  Future<void> _setLines(StatementResult r) async {
    final rows = [for (final l in r.lines) _Row(l)];
    _skipped = r.skipped;
    await _applyRules(rows);
    _setRows(rows);
  }

  /// 覚えた規則でカテゴリを入れる（内容が完全に同じときだけ）。
  Future<void> _applyRules(List<_Row> rows) async {
    final cats = {
      for (final c in await ref.readOnce(categoriesProvider.future)) c.id: c,
    };
    for (final kind in [TxnKind.expense, TxnKind.income]) {
      final target = rows.where((r) => r.kind == kind).toList();
      if (target.isEmpty) continue;
      final rules = await _repo.rulesFor(kind, target.map((r) => r.content));
      for (final r in target) {
        final id = rules[r.content];
        r.categoryId = id != null && cats[id]?.kind == kind.code ? id : null;
      }
    }
  }

  Future<void> _changeKind(_Row r, TxnKind kind) async {
    setState(() {
      r.kind = kind;
      r.categoryId = null;
    });
    await _applyRules([r]);
    if (mounted) setState(() {});
  }

  List<_Row> get _included =>
      (_rows ?? const <_Row>[]).where((r) => r.include).toList();

  /// 取り込めない理由（なければ null）。
  String? _problem(String? accountId) {
    final rows = _included;
    if (rows.isEmpty) return '取り込む行を選んでください';
    if (accountId == null) return '口座を選んでください';
    final noCat = rows.where((r) => r.categoryId == null).length;
    if (noCat > 0) return 'カテゴリが空の行が$noCat件あります';
    final badAmount = rows.where((r) => (r.amountValue ?? 0) <= 0).length;
    if (badAmount > 0) return '金額が0か空の行が$badAmount件あります';
    return null;
  }

  Future<void> _save(String planId, String accountId) async {
    if (_saving) return;
    setState(() => _saving = true);
    final rows = _included;
    final n = await _repo.register(
      planId: planId,
      accountId: accountId,
      asPlan: _asPlan,
      entries: [
        for (final r in rows)
          StatementEntry(
            date: r.date,
            kind: r.kind,
            amount: r.amountValue!,
            categoryId: r.categoryId!,
            content: r.content,
            memo: r.memo.text.trim().isEmpty ? null : r.memo.text.trim(),
          ),
      ],
    );
    await _repo.setPref(_prefAccount, accountId);
    if (_mapping != null) await _repo.setPref(_prefMapping, _mapping!.encode());
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop(true);
    messenger.showSnackBar(
      SnackBar(content: Text('${_asPlan ? '予定' : '実績'}を$n件登録しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(selectedPlanProvider).value;
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final accountId = accounts.any((a) => a.id == _accountId)
        ? _accountId
        : accounts.firstOrNull?.id;
    final rows = _rows;
    final problem = _problem(accountId);
    return Scaffold(
      appBar: AppBar(title: const Text('明細を取り込む')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'レシートやクレジットカードの明細から、支出・収入をまとめて登録します。'
            'マイナスの行（返金・値引きなど）は収入にします。同じ明細を2回取り込むと2件になります。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in StatementSource.values)
                Tooltip(
                  message: s.hint,
                  child: OutlinedButton.icon(
                    key: Key('statement-pick-${s.name}'),
                    onPressed: _loading ? null : () => _pick(s),
                    icon: Icon(
                      s == StatementSource.pdf
                          ? Icons.picture_as_pdf_outlined
                          : s == StatementSource.excel
                          ? Icons.table_chart_outlined
                          : Icons.shopping_cart_outlined,
                    ),
                    label: Text('${s.label}を選ぶ'),
                  ),
                ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            WarningBox(message: _error!),
          ],
          if (_fileName != null && _error == null && !_loading) ...[
            const SizedBox(height: 12),
            Text('${_source!.label}：$_fileName'),
            if (_source != StatementSource.amazon) _yearField(),
            if (_sheets != null && _mapping != null) _mappingPanel(),
          ],
          if (rows != null && !_loading) ...[
            const SectionTitle('登録のしかた'),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('実績')),
                    ButtonSegment(value: true, label: Text('予定')),
                  ],
                  selected: {_asPlan},
                  onSelectionChanged: (v) => setState(() => _asPlan = v.first),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    key: const Key('statement-account'),
                    initialValue: accountId,
                    decoration: const InputDecoration(labelText: '口座'),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _accountId = v),
                  ),
                ),
                Text('登録先のプラン：${plan?.name ?? ''}'),
              ],
            ),
            if (_asPlan)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '予定は、各行の日付の年月の予定（手入力）になります。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            SectionTitle(
              '読み取った明細（${rows.length}件'
              '${_skipped > 0 ? '・読めなかった行$_skipped件' : ''}）',
            ),
            if (rows.isEmpty)
              const Text('明細の行が見つかりませんでした。')
            else ...[
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      for (final r in rows) {
                        r.include = true;
                      }
                    }),
                    child: const Text('すべて選ぶ'),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      for (final r in rows) {
                        r.include = false;
                      }
                    }),
                    child: const Text('すべて外す'),
                  ),
                  Text(
                    '取り込む ${_included.length}件・'
                    '支出 ${formatYen(_sum(TxnKind.expense))}・'
                    '収入 ${formatYen(_sum(TxnKind.income))}',
                  ),
                ],
              ),
              for (final (i, r) in rows.indexed)
                _RowCard(
                  key: ValueKey(r),
                  index: i,
                  row: r,
                  asPlan: _asPlan,
                  categories: [
                    for (final c in categories)
                      if (c.kind == r.kind.code) c,
                  ],
                  onChanged: () => setState(() {}),
                  onKind: (k) => _changeKind(r, k),
                ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: rows == null || rows.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (problem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      problem,
                      key: const Key('statement-problem'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                SaveCancelBar(
                  saveKey: const Key('statement-save'),
                  saveLabel: '${_asPlan ? '予定' : '実績'}を${_included.length}件登録',
                  onSave: problem != null || plan == null || _saving
                      ? null
                      : () => _save(plan.id, accountId!),
                ),
              ],
            ),
    );
  }

  int _sum(TxnKind kind) => _included
      .where((r) => r.kind == kind)
      .fold(0, (s, r) => s + (r.amountValue ?? 0));

  Widget _yearField() {
    final now = clock.now().year;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Text('年が書かれていない日付の年：'),
          DropdownButton<int>(
            value: _year,
            items: [
              for (var y = now - 3; y <= now + 1; y++)
                DropdownMenuItem(value: y, child: Text('$y年')),
            ],
            onChanged: (v) {
              if (v == null) return;
              _year = v;
              _reparse();
            },
          ),
        ],
      ),
    );
  }

  Widget _mappingPanel() {
    final sheets = _sheets!;
    final m = _mapping!;
    final sheet = sheets.firstWhere(
      (s) => s.name == m.sheet,
      orElse: () => sheets.first,
    );
    final cols = sheet.columnCount < 1 ? 1 : sheet.columnCount;
    String sample(int c) {
      for (final r in sheet.rows.skip(m.skipRows).take(5)) {
        final v = c < r.length ? r[c] : null;
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    String header(int c) {
      if (m.skipRows == 0) return '';
      final r = sheet.rows[m.skipRows - 1];
      final v = c < r.length ? r[c] : null;
      return v?.trim() ?? '';
    }

    String label(int c) {
      final h = header(c);
      final s = sample(c);
      final text = [
        if (h.isNotEmpty) h,
        if (s.isNotEmpty) '例：${s.length > 16 ? '${s.substring(0, 16)}…' : s}',
      ].join('　');
      return '${columnName(c)}列${text.isEmpty ? '' : '（$text）'}';
    }

    void set(TableMapping next) {
      _mapping = next;
      _reparse();
    }

    Widget colField(String title, int value, TableMapping Function(int) f) =>
        SizedBox(
          width: 280,
          child: DropdownButtonFormField<int>(
            initialValue: value < cols ? value : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: title),
            items: [
              for (var c = 0; c < cols; c++)
                DropdownMenuItem(
                  value: c,
                  child: Text(label(c), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => v == null ? null : set(f(v)),
          ),
        );

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            if (sheets.length > 1)
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: sheet.name,
                  decoration: const InputDecoration(labelText: 'シート'),
                  items: [
                    for (final s in sheets)
                      DropdownMenuItem(value: s.name, child: Text(s.name)),
                  ],
                  onChanged: (v) {
                    final s = sheets.firstWhere((x) => x.name == v);
                    set(TableMapping.guess(s));
                  },
                ),
              ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int>(
                key: ValueKey('skip-${m.sheet}'),
                initialValue: m.skipRows,
                decoration: const InputDecoration(labelText: '先頭から読み飛ばす行'),
                items: [
                  for (var n = 0; n <= 30; n++)
                    DropdownMenuItem(value: n, child: Text('$n行')),
                ],
                onChanged: (v) =>
                    v == null ? null : set(m.copyWith(skipRows: v)),
              ),
            ),
            colField('日付の列', m.dateCol, (v) => m.copyWith(dateCol: v)),
            colField('内容の列', m.contentCol, (v) => m.copyWith(contentCol: v)),
            colField('金額の列', m.amountCol, (v) => m.copyWith(amountCol: v)),
          ],
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    super.key,
    required this.index,
    required this.row,
    required this.asPlan,
    required this.categories,
    required this.onChanged,
    required this.onKind,
  });

  final int index;
  final _Row row;
  final bool asPlan;
  final List<CategoryRow> categories;
  final VoidCallback onChanged;
  final ValueChanged<TxnKind> onKind;

  @override
  Widget build(BuildContext context) {
    final r = row;
    final d = DateTime.parse(r.date);
    final dateText = asPlan
        ? '${d.year}年${d.month}月'
        : '${d.year}/${d.month}/${d.day}';
    final missing = r.include && r.categoryId == null;
    return Card(
      key: Key('statement-row-$index'),
      margin: const EdgeInsets.only(top: 8),
      child: Opacity(
        opacity: r.include ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: Key('statement-include-$index'),
                value: r.include,
                onChanged: (v) {
                  r.include = v ?? false;
                  onChanged();
                },
              ),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: d,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2200),
                        );
                        if (picked == null) return;
                        r.date =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        onChanged();
                      },
                      child: Text(dateText),
                    ),
                    SegmentedButton<TxnKind>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: TxnKind.expense,
                          label: Text('支出'),
                        ),
                        ButtonSegment(value: TxnKind.income, label: Text('収入')),
                      ],
                      selected: {r.kind},
                      onSelectionChanged: (v) => onKind(v.first),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        key: Key('statement-amount-$index'),
                        controller: r.amount,
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          labelText: '金額',
                          prefixText: '¥ ',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        key: Key('statement-category-$index-${r.kind.code}'),
                        initialValue: r.categoryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'カテゴリ',
                          isDense: true,
                          errorText: missing ? '選んでください' : null,
                        ),
                        items: [
                          for (final c in categories)
                            DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  ColorDot(c.color),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          r.categoryId = v;
                          onChanged();
                        },
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 240,
                        maxWidth: 480,
                      ),
                      child: TextField(
                        controller: r.memo,
                        decoration: const InputDecoration(
                          labelText: 'メモ',
                          isDense: true,
                        ),
                      ),
                    ),
                    if (r.memo.text != r.content)
                      Text(
                        '明細の内容：${r.content}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
