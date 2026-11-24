import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/time.dart';
import '../db/database.dart';
import '../repositories/stamp.dart';
import '../sync/snapshot.dart';

/// QRでの共有の中身：ライフプラン1つ（設計書 3.12）。
///
/// 3.9 のライフプラン単位と同じ範囲（プランと配下の行、登録しているグループとその項目・テンプレート）を、
/// 同期のスナップショットと同じ「テーブル名→行」の形で持つ。カテゴリ・口座は全部入れる（少ないため）。
class PlanShare {
  const PlanShare({
    required this.schemaVersion,
    required this.planId,
    required this.planName,
    required this.exportedAt,
    required this.tables,
  });

  static const format = 'lifeplan-share';

  final int schemaVersion;
  final String planId;
  final String planName;
  final String exportedAt;
  final Map<String, List<Map<String, Object?>>> tables;

  int count(String table) => tables[table]?.length ?? 0;

  List<int> toBytes() => utf8.encode(
    jsonEncode({
      'format': format,
      'schema_version': schemaVersion,
      'plan_id': planId,
      'plan_name': planName,
      'exported_at': exportedAt,
      'tables': tables,
    }),
  );

  static PlanShare fromBytes(List<int> bytes) {
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('共有のデータを読めませんでした');
    }
    if (j['format'] != format) {
      throw const FormatException('ライフプランの共有のデータではありません');
    }
    return PlanShare(
      schemaVersion: j['schema_version'] as int,
      planId: j['plan_id'] as String,
      planName: j['plan_name'] as String,
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

/// プランの配下の表（plan_id を持つ）。asset_value は資産を通して配下になる。
const planScopedTables = [
  'family_member',
  'plan_line',
  'plan_event',
  'plan_rate',
  'plan_baseline',
  'plan_group',
  'txn',
  'asset',
];

/// 全プラン共通の表（UUID で追加・上書きし、削除はしない）。
const sharedMasterTables = [
  'category',
  'account',
  'template',
  'template_group',
  'template_group_item',
];

Future<List<Map<String, Object?>>> _select(
  AppDatabase db,
  String sql, [
  List<Variable<Object>> vars = const [],
]) async => [
  for (final r in await db.customSelect(sql, variables: vars).get())
    Map<String, Object?>.from(r.data),
];

String _marks(int n) => List.filled(n, '?').join(', ');

/// プラン1つを共有の中身にする（墓石は入れない）。
Future<PlanShare> buildPlanShare(AppDatabase db, String planId) async {
  final pid = Variable.withString(planId);
  final plan = await _select(
    db,
    'SELECT * FROM plan WHERE id = ? AND deleted_at IS NULL',
    [pid],
  );
  if (plan.isEmpty) throw StateError('プランがありません');
  final tables = <String, List<Map<String, Object?>>>{'plan': plan};
  for (final t in planScopedTables) {
    tables[t] = await _select(
      db,
      'SELECT * FROM $t WHERE plan_id = ? AND deleted_at IS NULL',
      [pid],
    );
  }
  final assetIds = [for (final a in tables['asset']!) a['id']! as String];
  tables['asset_value'] = assetIds.isEmpty
      ? []
      : await _select(
          db,
          'SELECT * FROM asset_value WHERE deleted_at IS NULL '
          'AND asset_id IN (${_marks(assetIds.length)})',
          [for (final id in assetIds) Variable.withString(id)],
        );
  tables['category'] = await _select(
    db,
    'SELECT * FROM category WHERE deleted_at IS NULL',
  );
  tables['account'] = await _select(
    db,
    'SELECT * FROM account WHERE deleted_at IS NULL',
  );
  final groupIds = {
    for (final r in tables['plan_group']!) r['group_id']! as String,
  }.toList();
  if (groupIds.isEmpty) {
    tables['template_group'] = [];
    tables['template_group_item'] = [];
    tables['template'] = [];
  } else {
    final gv = [for (final id in groupIds) Variable.withString(id)];
    tables['template_group'] = await _select(
      db,
      'SELECT * FROM template_group WHERE deleted_at IS NULL '
      'AND id IN (${_marks(groupIds.length)})',
      gv,
    );
    tables['template_group_item'] = await _select(
      db,
      'SELECT * FROM template_group_item WHERE deleted_at IS NULL '
      'AND group_id IN (${_marks(groupIds.length)})',
      gv,
    );
    final templateIds = {
      for (final r in tables['template_group_item']!)
        r['template_id']! as String,
    }.toList();
    tables['template'] = templateIds.isEmpty
        ? []
        : await _select(
            db,
            'SELECT * FROM template WHERE deleted_at IS NULL '
            'AND id IN (${_marks(templateIds.length)})',
            [for (final id in templateIds) Variable.withString(id)],
          );
  }
  return PlanShare(
    schemaVersion: currentSchemaVersion,
    planId: planId,
    planName: plan.single['name']! as String,
    exportedAt: nowTimestamp(),
    tables: tables,
  );
}

/// 共有を受け取った結果。
class PlanShareResult {
  const PlanShareResult({required this.overwritten, required this.removed});

  /// 同じ ID のプランを上書きした（false なら新しく作った）
  final bool overwritten;

  /// ファイルになかったので削除（墓石）した配下の行の数
  final int removed;
}

/// 受け取ったプランを取り込む（設計書 3.12）。
///
/// - 同じ ID のプランがあれば上書きし、なければその ID のまま作る
/// - プランと配下の行はファイルの中身に置き換える。ファイルにない配下の行は削除（墓石）する。
///   書き込む行は、この端末で今更新したものとして updated_at・updated_by を付け直す（同期で家族の端末へ伝わる）
/// - カテゴリ・口座・テンプレート・グループは UUID で追加・上書きし、削除はしない。
///   どちらが新しいかは同期と同じ規則（updated_at）で決める（古い共有で新しい変更を戻さないため）
Future<PlanShareResult> applyPlanShare(
  AppDatabase db,
  Stamp stamp,
  PlanShare share,
) {
  if (share.schemaVersion > currentSchemaVersion) {
    throw const FormatException('新しい版のアプリで作った共有です。アプリを更新してください');
  }
  return db.transaction(() async {
    final pid = Variable.withString(share.planId);
    final existing = await _select(
      db,
      'SELECT id FROM plan WHERE id = ? AND deleted_at IS NULL',
      [pid],
    );

    // 共通の表は同期と同じ後勝ちでマージする
    await mergeSnapshot(
      db,
      Snapshot(
        schemaVersion: share.schemaVersion,
        deviceId: '',
        exportedAt: share.exportedAt,
        tables: {
          for (final t in sharedMasterTables) t: share.tables[t] ?? const [],
        },
      ),
    );

    final now = stamp.now();
    Future<void> put(String table, List<Map<String, Object?>> rows) async {
      if (rows.isEmpty) return;
      final info = db.allTables.firstWhere((t) => t.actualTableName == table);
      final columns = {for (final c in info.$columns) c.name};
      for (final src in rows) {
        final row = {
          ...src,
          'updated_at': now,
          'updated_by': stamp.deviceId,
          'deleted_at': null,
        };
        final cols = [
          for (final k in row.keys)
            if (columns.contains(k)) k,
        ];
        await db.customInsert(
          'INSERT OR REPLACE INTO $table (${cols.join(', ')}) '
          'VALUES (${_marks(cols.length)})',
          variables: [for (final c in cols) _variable(row[c])],
          updates: {info},
        );
      }
    }

    var removed = 0;
    Future<void> replace(
      String table,
      List<Map<String, Object?>> rows,
      List<String> localIds,
    ) async {
      final keep = {for (final r in rows) r['id']};
      final gone = [
        for (final id in localIds)
          if (!keep.contains(id)) id,
      ];
      removed += gone.length;
      await softDeleteRows(db, stamp, table, gone);
      await put(table, rows);
    }

    final planRows = (share.tables['plan'] ?? const [])
        .where((r) => r['id'] == share.planId)
        .toList();
    if (planRows.isEmpty) throw const FormatException('プランの行がありません');
    await put('plan', planRows);

    final localAssetIds = <String>[];
    for (final t in planScopedTables) {
      final local = [
        for (final r in await _select(
          db,
          'SELECT id FROM $t WHERE plan_id = ? AND deleted_at IS NULL',
          [pid],
        ))
          r['id']! as String,
      ];
      if (t == 'asset') localAssetIds.addAll(local);
      await replace(t, [
        for (final r in share.tables[t] ?? const <Map<String, Object?>>[])
          {...r, 'plan_id': share.planId},
      ], local);
    }

    // 資産の価値：この端末とファイルの、プランの資産のもの
    final assetIds = {
      ...localAssetIds,
      for (final a in share.tables['asset'] ?? const []) a['id']! as String,
    }.toList();
    final localValues = assetIds.isEmpty
        ? <String>[]
        : [
            for (final r in await _select(
              db,
              'SELECT id FROM asset_value WHERE deleted_at IS NULL '
              'AND asset_id IN (${_marks(assetIds.length)})',
              [for (final id in assetIds) Variable.withString(id)],
            ))
              r['id']! as String,
          ];
    await replace(
      'asset_value',
      share.tables['asset_value'] ?? const [],
      localValues,
    );
    return PlanShareResult(overwritten: existing.isNotEmpty, removed: removed);
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
