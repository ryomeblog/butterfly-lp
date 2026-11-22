import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/io/backup_csv.dart';
import 'package:butterfly_lp/data/io/legacy_import.dart';
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

  group('参考アプリからの移行', () {
    final legacy = {
      'lifeplan': [
        {
          'id': 'lp_001',
          'name': '我が家のライフプラン',
          'settings': {'planStartYear': 2024, 'planEndYear': 2080},
          'familyMembers': [
            {
              'id': 'fm1',
              'name': '田中太郎',
              'birthDate': '1985-05-15',
              'lifeExpectancy': 85,
            },
            {
              'id': 'fm2',
              'name': '田中花子',
              'birthDate': '1987-01-01',
              'lifeExpectancy': 90,
            },
          ],
          'accounts': [
            {'id': 'acc1', 'name': 'メイン銀行', 'initialBalance': 1000000},
            {'id': 'acc2', 'name': '証券口座', 'initialBalance': 0},
          ],
          'categories': [
            {'id': 'cat1', 'name': '食費', 'type': 'expense', 'color': '#FF6B6B'},
            {'id': 'cat2', 'name': '給与', 'type': 'income', 'color': '#4E79A7'},
          ],
          'assetInfo': [
            {
              'id': 'ai1',
              'name': '日経225連動投信',
              'symbol': '1321',
              'priceHistory': [
                {'year': 2024, 'price': 28500},
                {'year': 2025, 'price': 30000},
              ],
              'dividendHistory': [
                {'year': 2024, 'dividendPerShare': 180},
                {'year': 2025, 'dividendPerShare': 200},
              ],
            },
          ],
          'holdingAssets': [
            {
              'id': 'ha1',
              'assetId': 'ai1',
              'quantity': 10,
              'purchaseYear': 2024,
              'sellYear': 2025,
              'accountId': 'acc2',
            },
          ],
          'templates': [
            {
              'id': 't1',
              'name': '家賃',
              'type': 'expense',
              'amount': 80000,
              'categoryId': 'cat1',
              'accountId': 'acc1',
            },
            {'id': 't2', 'name': '積立', 'type': 'investment', 'amount': 30000},
          ],
          'yearlyData': [
            {
              'year': 2024,
              'transactions': [
                {
                  'id': 'x1',
                  'title': 'スーパー',
                  'type': 'expense',
                  'year': 2024,
                  'month': 3,
                  'amount': 5000,
                  'categoryId': 'cat1',
                  'fromAccountId': 'acc1',
                },
                {
                  'id': 'x2',
                  'title': '給与',
                  'type': 'income',
                  'year': 2024,
                  'month': 3,
                  'amount': 300000,
                  'categoryId': 'cat2',
                  'toAccountId': 'acc1',
                },
                {
                  'id': 'x3',
                  'title': '積立',
                  'type': 'investment',
                  'year': 2024,
                  'month': 3,
                  'amount': 30000,
                },
              ],
              'events': [
                {
                  'id': 'e1',
                  'title': '投資開始',
                  'description': '積立投資を開始',
                  'year': 2024,
                  'transactionIds': ['x3'],
                },
              ],
            },
          ],
        },
      ],
    };

    test('新しいプラン1つに、実績・資産・価値・配当・テンプレート・家族・イベントを取り込む', () async {
      final plans = LegacyImporter.plansOf(legacy);
      expect(plans.single['name'], '我が家のライフプラン');
      final r = await LegacyImporter(db, stamp).importPlan(plans.single);
      expect(
        (r.events, r.assets, r.templates, r.skippedInvestment),
        (1, 1, 1, 1),
      );

      final plan = (await PlanRepository(db, stamp).getPlan(r.planId!))!;
      expect(plan.startYear, 2024);
      final members = await (db.select(
        db.familyMembers,
      )..where((m) => m.planId.equals(plan.id))).get();
      expect(members.map((m) => m.name), unorderedEquals(['田中太郎', '田中花子']));
      expect(
        members.firstWhere((m) => m.id == plan.protagonistMemberId).name,
        '田中太郎',
      );

      final txns = await (db.select(
        db.txns,
      )..where((t) => t.planId.equals(plan.id))).get();
      final food = txns.firstWhere((t) => t.memo == 'スーパー');
      expect(
        (food.date, food.amount, food.kind),
        ('2024-03-01', 5000, 'expense'),
      );
      // 保有資産：購入年1月1日の購入（10口×28,500）、売却年1月1日の売却（10口×30,000）
      final buy = txns.firstWhere((t) => t.assetAction == 'buy');
      expect(
        (buy.date, buy.amount, buy.quantityX1e4),
        ('2024-01-01', 285000, 100000),
      );
      final sell = txns.firstWhere((t) => t.assetAction == 'sell');
      expect((sell.date, sell.amount), ('2025-01-01', 300000));
      // 配当は保有していた2024年だけ（2025年は売却済み）
      final div = txns.where((t) => t.assetAction == 'income').toList();
      expect(div.map((t) => (t.date, t.amount)), [('2024-12-31', 1800)]);
      // 年次価格は各年1月の月単位の価値
      final values = await db.select(db.assetValues).get();
      expect(
        values.map((v) => (v.unit, v.valueDate, v.valueX100)),
        unorderedEquals([
          ('month', '2024-01', 2850000),
          ('month', '2025-01', 3000000),
        ]),
      );
      // 既存の同じ名前のカテゴリ（初期の「食費」）を使い、口座は作る
      final foodCat = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(food.categoryId!))).getSingle();
      expect(foodCat.name, '食費');
      expect(
        (await db.select(db.accounts).get()).map((a) => a.name),
        containsAll(['メイン銀行', '証券口座']),
      );
    });

    test('参考アプリのデータでないファイル', () {
      expect(() => LegacyImporter.plansOf({'x': 1}), throwsFormatException);
    });
  });
}
