import 'dart:io';

import 'package:butterfly_lp/data/db/database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1→v2：template.account_id を空にできるようになり、既存の行は残る', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = await Directory.systemTemp.createTemp('lp_migration');
    final file = File('${dir.path}/db.sqlite');

    // v1 の状態を作る：template.account_id を NOT NULL に戻し、行を1つ入れて user_version=1 にする
    var db = AppDatabase(NativeDatabase(file));
    await db.customStatement('DROP TABLE template');
    await db.customStatement(
      'CREATE TABLE template (id TEXT NOT NULL PRIMARY KEY, created_at TEXT NOT NULL, '
      'updated_at TEXT NOT NULL, updated_by TEXT NOT NULL, deleted_at TEXT, '
      'name TEXT NOT NULL, kind TEXT NOT NULL, amount INTEGER, quantity_x1e4 INTEGER, '
      'category_id TEXT, account_id TEXT NOT NULL, to_account_id TEXT, asset_id TEXT, '
      'asset_action TEXT, memo TEXT, growth_mode TEXT NOT NULL, growth_rate REAL)',
    );
    await db.customStatement(
      "INSERT INTO template VALUES ('t1','x','x','x',NULL,'家賃','expense',80000,NULL,"
      "NULL,'acc',NULL,NULL,NULL,NULL,'category',NULL)",
    );
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    // 開き直すと v2 へ移行する
    db = AppDatabase(NativeDatabase(file));
    final t = await db.select(db.templates).getSingle();
    expect(t.name, '家賃');
    expect(t.accountId, 'acc');
    await db.customStatement(
      "UPDATE template SET account_id = NULL WHERE id = 't1'",
    );
    expect((await db.select(db.templates).getSingle()).accountId, isNull);
    await db.close();
    await dir.delete(recursive: true);
  });
}
