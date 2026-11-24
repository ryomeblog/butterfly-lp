import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/io/backup_csv.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const planInput = NewPlanInput(
  name: 'プランA',
  startYear: 2026,
  protagonistName: '本人',
  protagonistBirthDate: '1990-01-01',
  protagonistLifeExpectancy: 90,
  createCashAccount: true,
);

void main() {
  late AppDatabase db;
  const stamp = Stamp('dev');
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('バックアップと復元：復元は端末のデータを全部消して、ファイルの内容（墓石・更新日時も）で上書きする', () async {
    final planId = await PlanRepository(db, stamp).createPlan(planInput);
    final cash = (await db.select(db.accounts).getSingle()).id;
    final txns = TxnRepository(db, stamp);
    final keep = await txns.createTxn(
      TxnInput(
        planId: planId,
        date: '2026-11-01',
        kind: TxnKind.expense,
        amount: 100,
        accountId: cash,
        categoryId: 'c',
      ),
    );
    final gone = await txns.createTxn(
      TxnInput(
        planId: planId,
        date: '2026-11-02',
        kind: TxnKind.expense,
        amount: 200,
        accountId: cash,
        categoryId: 'c',
      ),
    );
    await txns.deleteTxn(gone);
    final bytes = await Backup(db).export('dev');

    // バックアップの後に入れたデータは、復元で消える
    await PlanRepository(db, stamp).createPlan(planInput);
    await txns.createTxn(
      TxnInput(
        planId: planId,
        date: '2026-12-01',
        kind: TxnKind.income,
        amount: 9,
        accountId: cash,
        categoryId: 'c',
      ),
    );
    await Backup(db).restore(bytes);

    expect(await db.select(db.plans).get(), hasLength(1));
    final all = await db.select(db.txns).get();
    expect(all.map((t) => t.id), unorderedEquals([keep, gone]));
    expect(all.firstWhere((t) => t.id == gone).deletedAt, isNotNull);
    expect(await db.select(db.categories).get(), hasLength(23));
  });

  test('バックアップでないファイルは復元しない', () async {
    await expectLater(
      Backup(db).restore('{"a":1}'.codeUnits),
      throwsFormatException,
    );
  });

  test('実績のCSV：BOM付き、名称で出力、カンマを含む値は囲む', () async {
    final planId = await PlanRepository(db, stamp).createPlan(planInput);
    final cash = (await db.select(db.accounts).getSingle()).id;
    final food = (await (db.select(
      db.categories,
    )..where((c) => c.name.equals('食費'))).getSingle()).id;
    await TxnRepository(db, stamp).createTxn(
      TxnInput(
        planId: planId,
        date: '2026-11-01',
        kind: TxnKind.expense,
        amount: 1200,
        accountId: cash,
        categoryId: food,
        memo: 'パン, 牛乳',
      ),
    );
    final csv = await exportActualsCsv(
      db,
      planId: planId,
      from: '2026-01-01',
      to: '2026-12-31',
    );
    expect(
      csv.startsWith('﻿日付,種類,金額,カテゴリ,口座,入金先口座,資産,資産の動き,数量,メモ\r\n'),
      isTrue,
    );
    expect(csv, contains('2026-11-01,支出,1200,食費,現金,,,,,"パン, 牛乳"\r\n'));
  });
}
