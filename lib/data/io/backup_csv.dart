import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';
import '../db/database.dart';
import '../sync/snapshot.dart';

/// バックアップと復元（設計書 3.7）。
///
/// バックアップは同期のスナップショットと同じ中身（全テーブル・墓石・更新日時を含む）を暗号化せずに書き出す。
/// 復元は端末のデータを全部消してファイルの内容で上書きする（端末設定は残す）。
class Backup {
  Backup(this.db);

  final AppDatabase db;

  Future<List<int>> export(String deviceId) async =>
      (await buildSnapshot(db, deviceId)).toBytes();

  /// 復元。データ形式が新しいファイルは復元しない。
  Future<void> restore(List<int> bytes) async {
    final Snapshot snap;
    try {
      snap = Snapshot.fromBytes(bytes);
    } catch (_) {
      throw const FormatException('バックアップのファイルではありません');
    }
    if (snap.schemaVersion > currentSchemaVersion) {
      throw const FormatException('新しい版のアプリで作ったバックアップです。アプリを更新してください');
    }
    await db.transaction(() async {
      for (final t in syncedTableNames) {
        await db.customUpdate(
          'DELETE FROM $t',
          updates: {db.allTables.firstWhere((x) => x.actualTableName == t)},
          updateKind: UpdateKind.delete,
        );
      }
      await mergeSnapshot(db, snap);
    });
  }
}

/// 実績の CSV（設計書 3.7）：UTF-8（BOM付き）、列は日付・種類・金額・カテゴリ・口座・入金先口座・資産・資産の動き・数量・メモ（名称で出力）。
Future<String> exportActualsCsv(
  AppDatabase db, {
  required String planId,
  required String from,
  required String to,
}) async {
  final txns =
      await (db.select(db.txns)
            ..where(
              (t) =>
                  t.planId.equals(planId) &
                  t.deletedAt.isNull() &
                  t.date.isBetweenValues(from, to),
            )
            ..orderBy([
              (t) => OrderingTerm(expression: t.date),
              (t) => OrderingTerm(expression: t.createdAt),
            ]))
          .get();
  final cats = {
    for (final c in await db.select(db.categories).get()) c.id: c.name,
  };
  final accounts = {
    for (final a in await db.select(db.accounts).get()) a.id: a.name,
  };
  final assets = {
    for (final a in await db.select(db.assets).get()) a.id: a.name,
  };
  String q(Object? v) {
    final s = v?.toString() ?? '';
    return s.contains(RegExp('[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final b =
      StringBuffer('\uFEFF') // BOM
        ..write(
          [
            '日付',
            '種類',
            '金額',
            'カテゴリ',
            '口座',
            '入金先口座',
            '資産',
            '資産の動き',
            '数量',
            'メモ',
          ].join(','),
        )
        ..write('\r\n');
  for (final t in txns) {
    final qty = t.quantityX1e4;
    b
      ..write(
        [
          t.date,
          TxnKind.of(t.kind).label,
          t.amount,
          cats[t.categoryId] ?? '',
          accounts[t.accountId] ?? '',
          accounts[t.toAccountId] ?? '',
          assets[t.assetId] ?? '',
          t.assetAction == null ? '' : AssetAction.of(t.assetAction!).label,
          qty == null ? '' : (qty / 10000).toString(),
          t.memo ?? '',
        ].map(q).join(','),
      )
      ..write('\r\n');
  }
  return b.toString();
}

List<int> csvBytes(String csv) => utf8.encode(csv);
