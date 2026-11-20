import 'package:drift/drift.dart';

import '../../core/time.dart';
import '../db/database.dart';

/// 同期対象の行に付ける共通列（created_at / updated_at / updated_by / deleted_at）を作る。
///
/// すべての書き込みはこのクラスを通し、更新日時と端末IDの付け忘れを防ぐ（設計書 4.1）。
class Stamp {
  const Stamp(this.deviceId);

  final String deviceId;

  String now() => nowTimestamp();
}

/// 墓石を入れる（論理削除）。[ids] が空なら何もしない。
Future<void> softDeleteRows(
  AppDatabase db,
  Stamp stamp,
  String table,
  Iterable<String> ids,
) async {
  final list = ids.toList();
  if (list.isEmpty) return;
  final now = stamp.now();
  final info = db.allTables.firstWhere((t) => t.actualTableName == table);
  // SQLite の変数の上限を超えないよう分けて実行する。
  for (var i = 0; i < list.length; i += 500) {
    final chunk = list.sublist(
      i,
      i + 500 > list.length ? list.length : i + 500,
    );
    final marks = List.filled(chunk.length, '?').join(',');
    await db.customUpdate(
      'UPDATE $table SET deleted_at = ?, updated_at = ?, updated_by = ? '
      'WHERE id IN ($marks) AND deleted_at IS NULL',
      variables: [
        Variable.withString(now),
        Variable.withString(now),
        Variable.withString(stamp.deviceId),
        for (final id in chunk) Variable.withString(id),
      ],
      updates: {info},
      updateKind: UpdateKind.update,
    );
  }
}
