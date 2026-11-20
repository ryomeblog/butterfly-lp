import 'package:flutter/material.dart';

import '../../data/repositories/master_repository.dart';

/// 使用中のカテゴリ・口座を削除するときの選択（設計書 3.7）。
sealed class MasterDeleteChoice {
  const MasterDeleteChoice();
}

class DeleteWithHistory extends MasterDeleteChoice {
  const DeleteWithHistory();
}

class ReassignAndDelete extends MasterDeleteChoice {
  const ReassignAndDelete(this.toId);
  final String toId;
}

/// 付け替え先の候補。
class ReassignTarget {
  const ReassignTarget(this.id, this.name);
  final String id;
  final String name;
}

/// 削除の確認。使われていなければ単純な確認、使われていれば「履歴ごと削除」か「付け替えて削除」を選ぶ。
Future<MasterDeleteChoice?> showMasterDeleteDialog(
  BuildContext context, {
  required String title,
  required MasterUsage usage,
  required List<ReassignTarget> targets,
  required String withHistoryLabel,
  required String withHistoryDescription,
}) {
  return showDialog<MasterDeleteChoice>(
    context: context,
    builder: (context) => _MasterDeleteDialog(
      title: title,
      usage: usage,
      targets: targets,
      withHistoryLabel: withHistoryLabel,
      withHistoryDescription: withHistoryDescription,
    ),
  );
}

class _MasterDeleteDialog extends StatefulWidget {
  const _MasterDeleteDialog({
    required this.title,
    required this.usage,
    required this.targets,
    required this.withHistoryLabel,
    required this.withHistoryDescription,
  });

  final String title;
  final MasterUsage usage;
  final List<ReassignTarget> targets;
  final String withHistoryLabel;
  final String withHistoryDescription;

  @override
  State<_MasterDeleteDialog> createState() => _MasterDeleteDialogState();
}

class _MasterDeleteDialogState extends State<_MasterDeleteDialog> {
  String? _to;

  @override
  Widget build(BuildContext context) {
    final u = widget.usage;
    if (!u.isUsed) {
      return AlertDialog(
        title: Text(widget.title),
        content: const Text('使われていないので、そのまま削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('delete-confirm'),
            onPressed: () => Navigator.pop(context, const DeleteWithHistory()),
            child: const Text('削除'),
          ),
        ],
      );
    }
    final parts = [
      if (u.txns > 0) '実績 ${u.txns}件',
      if (u.planLines > 0) '計画行 ${u.planLines}件',
      if (u.templates > 0) 'テンプレート ${u.templates}件',
      if (u.assets > 0) '資産 ${u.assets}件',
    ];
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('このデータは ${parts.join('・')} で使われています。'),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('delete-with-history'),
              onPressed: () =>
                  Navigator.pop(context, const DeleteWithHistory()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(widget.withHistoryLabel),
            ),
            const SizedBox(height: 4),
            Text(
              widget.withHistoryDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _to,
              decoration: const InputDecoration(labelText: '付け替え先'),
              items: [
                for (final t in widget.targets)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setState(() => _to = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('delete-reassign'),
              onPressed: _to == null
                  ? null
                  : () => Navigator.pop(context, ReassignAndDelete(_to!)),
              child: const Text('付け替えて削除'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
