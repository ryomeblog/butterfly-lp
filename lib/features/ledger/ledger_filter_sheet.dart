import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
import '../../domain/calc/ledger.dart';
import '../../domain/models/enums.dart';
import '../shared/widgets.dart';

/// 家計簿リストの絞り込み（カテゴリ・口座・種類・期間・金額範囲。設計書 3.1）。
Future<LedgerFilter?> showLedgerFilterSheet(
  BuildContext context,
  LedgerFilter current,
) {
  return showModalBottomSheet<LedgerFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _FilterSheet(current: current),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.current});

  final LedgerFilter current;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late LedgerFilter _f = widget.current;
  late final _min = TextEditingController(
    text: widget.current.minAmount?.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: widget.current.maxAmount?.toString() ?? '',
  );

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: parseDate(isFrom ? _f.from : _f.to),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (d == null) return;
    setState(() {
      _f = isFrom
          ? _f.copyWith(from: dateString(d))
          : _f.copyWith(to: dateString(d));
    });
  }

  Set<T> _toggle<T>(Set<T> set, T v, bool on) =>
      on ? {...set, v} : ({...set}..remove(v));

  @override
  Widget build(BuildContext context) {
    final cats = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.kind != CategoryKind.asset.code)
        .toList();
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final from = parseDate(_f.from);
    final to = parseDate(_f.to);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('絞り込み', style: Theme.of(context).textTheme.titleMedium),
              const SectionTitle('期間'),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => _pick(true),
                    child: Text('${from.year}/${from.month}/${from.day}'),
                  ),
                  const Text('　〜　'),
                  OutlinedButton(
                    onPressed: () => _pick(false),
                    child: Text('${to.year}/${to.month}/${to.day}'),
                  ),
                ],
              ),
              const SectionTitle('種類'),
              Wrap(
                spacing: 8,
                children: [
                  for (final k in TxnKind.values)
                    FilterChip(
                      label: Text(k.label),
                      selected: _f.kinds.contains(k),
                      onSelected: (on) => setState(
                        () => _f = _f.copyWith(kinds: _toggle(_f.kinds, k, on)),
                      ),
                    ),
                ],
              ),
              const SectionTitle('カテゴリ'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in cats)
                    FilterChip(
                      avatar: ColorDot(c.color),
                      label: Text(c.name),
                      selected: _f.categoryIds.contains(c.id),
                      onSelected: (on) => setState(
                        () => _f = _f.copyWith(
                          categoryIds: _toggle(_f.categoryIds, c.id, on),
                        ),
                      ),
                    ),
                ],
              ),
              const SectionTitle('口座'),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in accounts)
                    FilterChip(
                      label: Text(a.name),
                      selected: _f.accountIds.contains(a.id),
                      onSelected: (on) => setState(
                        () => _f = _f.copyWith(
                          accountIds: _toggle(_f.accountIds, a.id, on),
                        ),
                      ),
                    ),
                ],
              ),
              const SectionTitle('金額'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _min,
                      decoration: const InputDecoration(
                        labelText: '下限',
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const Text('　〜　'),
                  Expanded(
                    child: TextField(
                      controller: _max,
                      decoration: const InputDecoration(
                        labelText: '上限',
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _f = LedgerFilter(from: _f.from, to: _f.to);
                      _min.clear();
                      _max.clear();
                    }),
                    child: const Text('条件をクリア'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('filter-apply'),
                    onPressed: () => Navigator.pop(
                      context,
                      _f.copyWith(
                        minAmount: () => int.tryParse(_min.text),
                        maxAmount: () => int.tryParse(_max.text),
                      ),
                    ),
                    child: const Text('絞り込む'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
