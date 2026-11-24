import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/io/backup_csv.dart';
import '../../data/io/json_import.dart' show FileUnit;
import '../shared/widgets.dart';
import 'file_io.dart';

/// データ管理（ワイヤーフレーム DataMgmt）。設計書 3.7・3.9。
///
/// バックアップと復元・全データのJSON・実績のCSV。ほかの単位のJSONの書き出し・取り込みは、それぞれの画面から行う。
class DataMgmtScreen extends ConsumerStatefulWidget {
  const DataMgmtScreen({super.key});

  @override
  ConsumerState<DataMgmtScreen> createState() => _DataMgmtScreenState();
}

class _DataMgmtScreenState extends ConsumerState<DataMgmtScreen> {
  String? _planId;
  late DateTime _csvFrom = DateTime(clock.now().year, 1, 1);
  late DateTime _csvTo = DateTime(clock.now().year, 12, 31);
  bool _busy = false;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String get _stamp => todayString().replaceAll('-', '');

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) _snack('できませんでした：$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _backup() => _run(() async {
    final bytes = await Backup(ref.read(databaseProvider))
        .export(ref.read(deviceIdProvider));
    await shareFile('lifeplan-backup-$_stamp.json', bytes);
  });

  Future<void> _restore() => _run(() async {
    final f = await pickFile();
    if (f == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ファイルから復元しますか'),
        content: Text(
          '「${f.name}」の内容で、この端末のデータをすべて消して上書きします。'
          '復元後に同期すると、他の端末のデータは通常どおりマージされます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('復元する'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Backup(ref.read(databaseProvider)).restore(f.bytes);
    if (mounted) _snack('復元しました');
  });

  Future<void> _exportAll() =>
      _run(() => exportJson(context, ref, 'all', (e) => e.exportAll()));

  Future<void> _exportCsv() => _run(() async {
    final plan = ref.read(selectedPlanProvider).value!;
    final csv = await exportActualsCsv(
      ref.read(databaseProvider),
      planId: _planId ?? plan.id,
      from: dateString(_csvFrom),
      to: dateString(_csvTo),
    );
    await shareFile(
      'lifeplan-actuals-$_stamp.csv',
      csvBytes(csv),
      mime: 'text/csv',
    );
  });

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider).value ?? const <PlanRow>[];
    final selected = ref.watch(selectedPlanProvider).value;
    final planId = _planId ?? selected?.id;
    final small = Theme.of(context).textTheme.bodySmall;

    Widget planDrop() => DropdownButtonFormField<String>(
      initialValue: plans.any((p) => p.id == planId) ? planId : null,
      decoration: const InputDecoration(labelText: 'プラン'),
      items: [
        for (final p in plans)
          DropdownMenuItem(value: p.id, child: Text(p.name)),
      ],
      onChanged: (v) => setState(() => _planId = v),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('データ管理')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle('バックアップと復元'),
            Text('全データを1つのファイルに書き出します（端末の変更・故障に備える用）。', style: small),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const Key('backup'),
                onPressed: _backup,
                child: const Text('バックアップを書き出す'),
              ),
            ),
            Text(
              'この端末のデータをすべて消して、ファイルの内容で上書きします。復元後に同期すると、他の端末のデータは通常どおりマージされます。',
              style: small,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _restore,
                child: const Text('ファイルを選んで復元'),
              ),
            ),
            const SectionTitle('全データのJSON'),
            Text(
              'カテゴリ・口座・テンプレート・グループ・全プラン（各プランの家計簿と資産を含む）を書き出します。'
              '取り込みは「追加・上書き（マージ）」です。端末を丸ごと戻すときは「ファイルを選んで復元」を使います。'
              '予定・実績・プラン・資産・グループ・テンプレートのJSONは、それぞれの画面から書き出し・取り込みます。',
              style: small,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  key: const Key('json-export-all'),
                  onPressed: _exportAll,
                  child: const Text('全データをJSONで書き出す'),
                ),
                const ImportJsonButton(expect: FileUnit.full),
              ],
            ),
            const SectionTitle('実績をCSVで書き出し'),
            planDrop(),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _csvFrom,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2200),
                    );
                    if (d != null) setState(() => _csvFrom = d);
                  },
                  child: Text(dateString(_csvFrom).replaceAll('-', '/')),
                ),
                const Text('〜'),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _csvTo,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2200),
                    );
                    if (d != null) setState(() => _csvTo = d);
                  },
                  child: Text(dateString(_csvTo).replaceAll('-', '/')),
                ),
              ],
            ),
            Text(
              'UTF-8（BOM付き）。列：日付・種類・金額・カテゴリ・口座・入金先口座・資産・資産の動き・数量・メモ',
              style: small,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _exportCsv,
                child: const Text('CSVを書き出す'),
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
