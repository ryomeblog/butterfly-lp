import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/time.dart';
import '../db/database.dart';

/// 同期のスナップショット（全データ。墓石を含む）。設計書 5.2。
class Snapshot {
  const Snapshot({
    required this.schemaVersion,
    required this.deviceId,
    required this.exportedAt,
    required this.tables,
  });

  final int schemaVersion;
  final String deviceId;
  final String exportedAt;

  /// テーブル名→行（列名→値）
  final Map<String, List<Map<String, Object?>>> tables;

  static const format = 'lifeplan-sync';

  List<int> toBytes() => utf8.encode(
    jsonEncode({
      'format': format,
      'schema_version': schemaVersion,
      'device_id': deviceId,
      'exported_at': exportedAt,
      'tables': tables,
    }),
  );

  static Snapshot fromBytes(List<int> bytes) {
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (j['format'] != format) throw const FormatException('同期データではありません');
    return Snapshot(
      schemaVersion: j['schema_version'] as int,
      deviceId: j['device_id'] as String,
      exportedAt: j['exported_at'] as String,
      tables: {
        for (final e in (j['tables'] as Map<String, dynamic>).entries)
          e.key: [
            for (final r in e.value as List)
              (r as Map<String, dynamic>).cast<String, Object?>(),
          ],
      },
    );
  }
}

/// 自端末の全データ（墓石を含む）をスナップショットにする（設計書 5.3-5）。
Future<Snapshot> buildSnapshot(AppDatabase db, String deviceId) async {
  final tables = <String, List<Map<String, Object?>>>{};
  for (final t in syncedTableNames) {
    final rows = await db.customSelect('SELECT * FROM $t').get();
    tables[t] = [for (final r in rows) Map<String, Object?>.from(r.data)];
  }
  return Snapshot(
    schemaVersion: currentSchemaVersion,
    deviceId: deviceId,
    exportedAt: nowTimestamp(),
    tables: tables,
  );
}

/// 行の新しさの比較（設計書 5.3-4）：updated_at が新しい方。同時刻なら updated_by の大きい方。
bool isNewer(
  Map<String, Object?> incoming,
  String? localUpdatedAt,
  String? localUpdatedBy,
) {
  if (localUpdatedAt == null) return true;
  final c = (incoming['updated_at'] as String).compareTo(localUpdatedAt);
  if (c != 0) return c > 0;
  return (incoming['updated_by'] as String).compareTo(localUpdatedBy ?? '') > 0;
}

/// スナップショットを自端末へマージする。採用した行の数を返す。
///
/// テーブルごと・id ごとに比べ、新しい方を採用する（墓石も同じ規則）。自端末にない列は無視する。
Future<int> mergeSnapshot(AppDatabase db, Snapshot snap) {
  return db.transaction(() async {
    var adopted = 0;
    for (final table in syncedTableNames) {
      final rows = snap.tables[table];
      if (rows == null || rows.isEmpty) continue;
      final info = db.allTables.firstWhere((t) => t.actualTableName == table);
      final columns = {for (final c in info.$columns) c.name};
      final local = {
        for (final r
            in await db
                .customSelect('SELECT id, updated_at, updated_by FROM $table')
                .get())
          r.read<String>('id'): (
            r.read<String>('updated_at'),
            r.read<String>('updated_by'),
          ),
      };
      for (final row in rows) {
        final id = row['id'];
        if (id is! String) continue;
        final l = local[id];
        if (!isNewer(row, l?.$1, l?.$2)) continue;
        final cols = [
          for (final k in row.keys)
            if (columns.contains(k)) k,
        ];
        await db.customInsert(
          'INSERT OR REPLACE INTO $table (${cols.join(', ')}) '
          'VALUES (${List.filled(cols.length, '?').join(', ')})',
          variables: [for (final c in cols) _variable(row[c])],
          updates: {info},
        );
        adopted++;
      }
    }
    return adopted;
  });
}

Variable<Object> _variable(Object? v) => switch (v) {
  null => const Variable(null),
  final int i => Variable.withInt(i),
  final double d => Variable.withReal(d),
  final String s => Variable.withString(s),
  final bool b => Variable.withBool(b),
  _ => Variable.withString(v.toString()),
};

/// 参照切れの件数（設計書 5.4）：生きている行が、削除済み・存在しないカテゴリ・口座を指している数。
Future<int> countBrokenReferences(AppDatabase db) async {
  const checks = [
    ('txn', 'category_id', 'category'),
    ('txn', 'account_id', 'account'),
    ('txn', 'to_account_id', 'account'),
    ('plan_line', 'category_id', 'category'),
    ('plan_line', 'account_id', 'account'),
    ('plan_line', 'to_account_id', 'account'),
    ('template', 'category_id', 'category'),
    ('template', 'account_id', 'account'),
    ('asset', 'category_id', 'category'),
  ];
  var n = 0;
  for (final (table, column, target) in checks) {
    final r = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM $table x WHERE x.deleted_at IS NULL AND x.$column IS NOT NULL '
          'AND NOT EXISTS (SELECT 1 FROM $target t WHERE t.id = x.$column AND t.deleted_at IS NULL)',
        )
        .getSingle();
    n += r.read<int>('c');
  }
  return n;
}
