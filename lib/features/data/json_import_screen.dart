import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../data/io/json_import.dart';
import '../shared/widgets.dart';

/// JSONの取り込み（ワイヤーフレーム JsonImport）。設計書 3.9。
///
/// ファイルの中身を自動で判別し、追加・上書きの件数、期間、取り込み先のプラン、同じUUIDの扱い、
/// 新しく作るもの、取り込めない行を確かめてから取り込む。取り込みは追加・上書きだけで、既存のデータは削除しない。
class JsonImportScreen extends ConsumerStatefulWidget {
  const JsonImportScreen({
    super.key,
    required this.fileName,
    required this.json,
  });

  final String fileName;
  final Map<String, dynamic> json;

  @override
  ConsumerState<JsonImportScreen> createState() => _JsonImportScreenState();
}

class _JsonImportScreenState extends ConsumerState<JsonImportScreen> {
  String? _target;
  SameIdPolicy _policy = SameIdPolicy.overwrite;
  ImportReport? _report;
  String? _error;
  bool _busy = false;

  JsonImporter get _importer =>
      JsonImporter(ref.read(databaseProvider), ref.read(stampProvider));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preview());
  }

  Future<void> _preview() async {
    setState(() => _busy = true);
    try {
      final plans = await ref.readOnce(plansProvider.future);
      // 取り込み先の既定値：ファイル内と同じUUIDのプラン、なければ表示プラン
      if (_target == null) {
        final first = await _importer.preview(
          widget.json,
          targetPlanId: ref.read(selectedPlanProvider).value?.id,
        );
        final fileId = first.filePlanId;
        _target = plans.any((p) => p.id == fileId)
            ? fileId
            : ref.read(selectedPlanProvider).value?.id;
      }
      final r = await _importer.preview(
        widget.json,
        targetPlanId: _target,
        policy: _policy,
      );
      setState(() {
        _report = r;
        _error = null;
      });
    } on ImportFormatError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '取り込めません：$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      final r = await _importer.apply(
        widget.json,
        targetPlanId: _target,
        policy: _policy,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '取り込みました（実績 ${r.actualsNew + r.actualsOverwrite}件・予定 ${r.linesNew + r.linesOverwrite}件'
            '${r.createdPlanId != null && r.kind == ImportKind.plan ? '・新しいプラン' : ''}）',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '取り込めませんでした（何も変えていません）：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final plans = ref.watch(plansProvider).value ?? const <PlanRow>[];
    return Scaffold(
      appBar: AppBar(title: const Text('JSONの取り込み')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${widget.fileName} を読み込みました。内容を確認してから取り込みます。'),
          if (_error != null) ...[
            const SizedBox(height: 8),
            WarningBox(key: const Key('import-error'), message: _error!),
          ],
          if (r == null && _error == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (r != null) ...[
            const SectionTitle('取り込み先のプラン'),
            if (r.kind == ImportKind.plan)
              const Text('ライフプラン単位のファイルは、常に新しいプランとして追加します（同じ名前があれば「(2)」を付けます）。')
            else if (r.kind == ImportKind.full)
              const Text(
                'アプリの全データのファイルです。プランは同じUUIDで追加・上書き（マージ）します。端末を丸ごと戻すときは「バックアップの復元」を使います。',
              )
            else
              DropdownButtonFormField<String>(
                key: const Key('import-target'),
                initialValue: plans.any((p) => p.id == _target)
                    ? _target
                    : null,
                decoration: const InputDecoration(
                  labelText: '実績・予定・資産・イベントを入れるプラン',
                ),
                items: [
                  for (final p in plans)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.name}${p.id == r.filePlanId ? '・ファイル内と同じプラン' : ''}',
                      ),
                    ),
                ],
                onChanged: (v) {
                  _target = v;
                  _preview();
                },
              ),
            SectionTitle('件数'),
            Text(
              [
                if (r.plansNew + r.plansOverwrite > 0)
                  'プラン：新しく追加 ${r.plansNew}件・上書き ${r.plansOverwrite}件',
                '実績：新しく追加 ${r.actualsNew}件・上書き（同じUUID） ${r.actualsOverwrite}件',
                '予定：新しく追加 ${r.linesNew}件・上書き ${r.linesOverwrite}件',
                if (r.periodFrom != null)
                  '期間：${r.periodFrom!.replaceAll('-', '/')}〜${r.periodTo!.replaceAll('-', '/')}',
                if (r.assetsNew + r.assetsOverwrite > 0)
                  '資産：新しく追加 ${r.assetsNew}件・上書き ${r.assetsOverwrite}件／価値：追加 ${r.valuesAdd}件・上書き ${r.valuesOverwrite}件',
                if (r.groupsNew + r.groupsSame > 0)
                  'グループ：新規 ${r.groupsNew}件・同じUUID ${r.groupsSame}件',
                if (r.templatesNew + r.templatesSame > 0)
                  'テンプレート：新規 ${r.templatesNew}件・同じUUID ${r.templatesSame}件',
              ].join('\n'),
              key: const Key('import-counts'),
            ),
            if (r.groupsSame + r.templatesSame > 0) ...[
              const SectionTitle('同じUUIDのグループ・テンプレートがアプリにあるとき'),
              RadioGroup<SameIdPolicy>(
                groupValue: _policy,
                onChanged: (v) {
                  _policy = v!;
                  _preview();
                },
                child: Column(
                  children: [
                    for (final p in SameIdPolicy.values)
                      RadioListTile<SameIdPolicy>(
                        contentPadding: EdgeInsets.zero,
                        value: p,
                        title: Text(p.label),
                      ),
                  ],
                ),
              ),
              Text(
                'グループを上書きしても、作成済みの計画行は変わりません。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            SectionTitle('新しく作るもの（${r.newRefs.length}件）'),
            if (r.newRefs.isEmpty) const Text('なし'),
            if (r.newRefs.isNotEmpty) ...[
              Text(
                '参照先のUUIDがアプリに見つからないため、ファイルに書かれた内容で、同じUUIDのまま作ります。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              for (final n in r.newRefs) Text('・$n'),
            ],
            if (r.invalid.isNotEmpty) ...[
              const SizedBox(height: 12),
              WarningBox(
                key: const Key('import-invalid'),
                message:
                    '取り込めない行 ${r.invalid.length}件：${r.invalid.join('、')}。この行は飛ばします。',
              ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: SaveCancelBar(
        saveLabel: '取り込む',
        saveKey: const Key('import-apply'),
        onSave:
            r == null ||
                _busy ||
                _error != null ||
                (r.kind == ImportKind.rows && _target == null)
            ? null
            : _apply,
      ),
    );
  }
}
