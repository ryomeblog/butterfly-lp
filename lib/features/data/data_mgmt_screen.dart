import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/io/backup_csv.dart';
import '../../data/io/legacy_import.dart';
import '../shared/widgets.dart';
import '../shared/ym_picker.dart';
import 'file_io.dart';

enum _Unit {
  period('予定・実績（プランと期間を指定）'),
  plan('ライフプラン'),
  group('グループ'),
  template('テンプレート'),
  asset('資産'),
  assetList('資産リスト（表示中のプランの資産）'),
  all('アプリの全データ');

  const _Unit(this.label);
  final String label;
}

/// データ管理（ワイヤーフレーム DataMgmt）。設計書 3.7・3.9。
class DataMgmtScreen extends ConsumerStatefulWidget {
  const DataMgmtScreen({super.key});

  @override
  ConsumerState<DataMgmtScreen> createState() => _DataMgmtScreenState();
}

class _DataMgmtScreenState extends ConsumerState<DataMgmtScreen> {
  _Unit _unit = _Unit.period;
  String? _planId;
  String? _itemId; // グループ・テンプレート・資産（null は「すべて」）
  bool _actuals = true;
  bool _plans = true;
  late YearMonth _from = YearMonth(clock.now().year, 1);
  late YearMonth _to = YearMonth(clock.now().year, 12);
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

  Future<void> _exportJson() => _run(() async {
    final plan = ref.read(selectedPlanProvider).value;
    final planId = _planId ?? plan?.id;
    switch (_unit) {
      case _Unit.period:
        await exportJson(
          context,
          ref,
          'actuals-plans',
          (e) => e.exportPeriod(
            planId: planId!,
            from: _from,
            to: _to,
            actuals: _actuals,
            plans: _plans,
          ),
        );
      case _Unit.plan:
        await exportJson(context, ref, 'plan', (e) => e.exportPlan(planId!));
      case _Unit.group:
        final ids = _itemId != null
            ? [_itemId!]
            : <String>[
                for (final g
                    in ref.read(groupSummariesProvider).value ?? const [])
                  g.group.id,
              ];
        await exportJson(context, ref, 'groups', (e) => e.exportGroups(ids));
      case _Unit.template:
        final ids = _itemId != null
            ? [_itemId!]
            : [
                for (final t
                    in ref.read(templatesProvider).value ??
                        const <TemplateRow>[])
                  t.id,
              ];
        await exportJson(
          context,
          ref,
          'templates',
          (e) => e.exportTemplates(ids),
        );
      case _Unit.asset:
        if (_itemId == null) throw '資産を選んでください';
        await exportJson(
          context,
          ref,
          'asset',
          (e) => e.exportAssets(plan!.id, [_itemId!]),
        );
      case _Unit.assetList:
        final ids = [
          for (final a
              in ref.read(assetsProvider(plan!.id)).value ?? const <AssetRow>[])
            a.id,
        ];
        await exportJson(
          context,
          ref,
          'assets',
          (e) => e.exportAssets(plan.id, ids),
        );
      case _Unit.all:
        await exportJson(context, ref, 'all', (e) => e.exportAll());
    }
  });

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

  Future<void> _legacy() => _run(() async {
    final f = await pickFile();
    if (f == null || !mounted) return;
    final plans = LegacyImporter.plansOf(jsonDecode(utf8.decode(f.bytes)));
    if (plans.isEmpty) throw 'プランがありません';
    var p = plans.first;
    if (plans.length > 1) {
      final chosen = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (c) => SimpleDialog(
          title: const Text('取り込むプランを選ぶ'),
          children: [
            for (final x in plans)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(c, x),
                child: Text('${x['name'] ?? '名称なし'}'),
              ),
          ],
        ),
      );
      if (chosen == null) return;
      p = chosen;
    }
    final r = await LegacyImporter(
      ref.read(databaseProvider),
      ref.read(stampProvider),
    ).importPlan(p);
    await ref.read(deviceRepositoryProvider).setSelectedPlan(r.planId);
    if (mounted) {
      _snack(
        '新しいプランに取り込みました：実績 ${r.txns}件・資産 ${r.assets}件・イベント ${r.events}件・テンプレート ${r.templates}件'
        '${r.skippedInvestment > 0 ? '（投資の取引 ${r.skippedInvestment}件は保有資産の購入として取り込み済み）' : ''}',
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider).value ?? const <PlanRow>[];
    final selected = ref.watch(selectedPlanProvider).value;
    final planId = _planId ?? selected?.id;
    final groups = ref.watch(groupSummariesProvider).value ?? const [];
    final templates =
        ref.watch(templatesProvider).value ?? const <TemplateRow>[];
    final assets = selected == null
        ? const <AssetRow>[]
        : (ref.watch(assetsProvider(selected.id)).value ?? const <AssetRow>[]);
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
            const SectionTitle('JSONで書き出し・取り込み'),
            Text(
              '単位を選んで書き出します。取り込みはファイルの中身を自動で判別します。どの行もUUIDを持ち、参照先（カテゴリ・口座・資産・イベントなど）の名前も一緒に書き出します。',
              style: small,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<_Unit>(
              key: const Key('json-unit'),
              initialValue: _unit,
              decoration: const InputDecoration(labelText: '書き出す単位'),
              items: [
                for (final u in _Unit.values)
                  DropdownMenuItem(value: u, child: Text(u.label)),
              ],
              onChanged: (v) => setState(() {
                _unit = v!;
                _itemId = null;
              }),
            ),
            const SizedBox(height: 12),
            ...switch (_unit) {
              _Unit.period => [
                planDrop(),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('実績'),
                      selected: _actuals,
                      onSelected: (v) =>
                          setState(() => _actuals = v || !_plans),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('予定'),
                      selected: _plans,
                      onSelected: (v) =>
                          setState(() => _plans = v || !_actuals),
                    ),
                  ],
                ),
                YmPicker(
                  label: '開始年月',
                  value: _from,
                  min: YearMonth(1900, 1),
                  max: YearMonth(2200, 12),
                  onChanged: (v) => setState(() => _from = v),
                ),
                const SizedBox(height: 8),
                YmPicker(
                  label: '終了年月',
                  value: _to,
                  min: _from,
                  max: YearMonth(2200, 12),
                  onChanged: (v) => setState(() => _to = v),
                ),
              ],
              _Unit.plan => [
                planDrop(),
                Text(
                  '家族・イベント・率・グループの登録・予定（計画行）・家計簿（実績）・資産と、登録しているグループ・テンプレートを含みます。',
                  style: small,
                ),
              ],
              _Unit.group => [
                DropdownButtonFormField<String?>(
                  initialValue: _itemId,
                  decoration: const InputDecoration(labelText: 'グループ'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('すべてのグループ'),
                    ),
                    for (final g in groups)
                      DropdownMenuItem(
                        value: g.group.id,
                        child: Text(g.group.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => _itemId = v),
                ),
                Text('項目・頻度・金額の決め方と、項目が使うテンプレートを含みます。', style: small),
              ],
              _Unit.template => [
                DropdownButtonFormField<String?>(
                  initialValue: _itemId,
                  decoration: const InputDecoration(labelText: 'テンプレート'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('すべてのテンプレート'),
                    ),
                    for (final t in templates)
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (v) => setState(() => _itemId = v),
                ),
              ],
              _Unit.asset => [
                DropdownButtonFormField<String>(
                  initialValue: _itemId,
                  decoration: const InputDecoration(labelText: '資産（表示中のプラン）'),
                  items: [
                    for (final a in assets)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _itemId = v),
                ),
                Text(
                  '資産の情報と日・月単位の価値、その資産を参照する実績・予定、それらが参照するイベントを含みます。',
                  style: small,
                ),
              ],
              _Unit.assetList => [
                Text('表示中のプランのすべての資産と、それぞれの価値・実績・予定・イベントを含みます。', style: small),
              ],
              _Unit.all => [
                Text(
                  'カテゴリ・口座・テンプレート・グループ・全プラン（各プランの家計簿と資産を含む）を含みます。'
                  '取り込みは「追加・上書き（マージ）」です。端末を丸ごと戻すときは「ファイルから復元」を使います。',
                  style: small,
                ),
              ],
            },
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: const Key('json-export'),
                  onPressed: _exportJson,
                  child: const Text('JSONを書き出す'),
                ),
                OutlinedButton(
                  onPressed: () => pickAndImportJson(context),
                  child: const Text('JSONを取り込む'),
                ),
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
            const SectionTitle('参考アプリ（shin-lifeplan-app）から移行'),
            Text(
              '取引は年月の1日付の実績、保有資産は購入・売却の実績、年次価格は各年1月の価値、配当は各年12月31日の収益、'
              '家族・イベントは新しいプランとして取り込みます。テンプレートはテンプレートとして取り込みます（グループは作りません）。',
              style: small,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _legacy,
                child: const Text('JSONファイルを選ぶ'),
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
