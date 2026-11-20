import 'package:butterfly_lp/core/ids.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/master_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/template_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late MasterRepository masters;
  late TemplateRepository templates;
  const stamp = Stamp(testDeviceId);

  setUp(() {
    db = memoryDb();
    masters = MasterRepository(db, stamp);
    templates = TemplateRepository(db, stamp);
  });
  tearDown(() => db.close());

  Future<String> account(String name) => masters.createAccount(
    AccountInput(
      name: name,
      kind: AccountKind.bank,
      initialBalance: 0,
      initialDate: '2026-01-01',
    ),
  );

  Future<String> category(
    String name, [
    CategoryKind k = CategoryKind.expense,
  ]) => masters.createCategory(
    CategoryInput(name: name, kind: k, color: '#4E79A7'),
  );

  Future<String> txn({
    required String accountId,
    String? to,
    String? categoryId,
    String? assetId,
  }) async {
    final id = newId();
    await db
        .into(db.txns)
        .insert(
          TxnsCompanion.insert(
            id: id,
            createdAt: 'x',
            updatedAt: 'x',
            updatedBy: 'x',
            planId: 'p1',
            date: '2026-05-01',
            kind: to != null ? 'transfer' : 'expense',
            amount: 100,
            categoryId: Value(categoryId),
            accountId: accountId,
            toAccountId: Value(to),
            assetId: Value(assetId),
          ),
        );
    return id;
  }

  Future<String> line({required String accountId, String? categoryId}) async {
    final id = newId();
    await db
        .into(db.planLines)
        .insert(
          PlanLinesCompanion.insert(
            id: id,
            createdAt: 'x',
            updatedAt: 'x',
            updatedBy: 'x',
            planId: 'p1',
            year: 2027,
            month: 1,
            kind: 'expense',
            amount: 100,
            categoryId: Value(categoryId),
            accountId: accountId,
            source: 'manual',
          ),
        );
    return id;
  }

  Future<TxnRow> getTxn(String id) =>
      (db.select(db.txns)..where((t) => t.id.equals(id))).getSingle();

  group('カテゴリの削除', () {
    test('使用件数を数える', () async {
      final bank = await account('銀行');
      final food = await category('外食');
      await txn(accountId: bank, categoryId: food);
      await line(accountId: bank, categoryId: food);
      await templates.createTemplate(
        TemplateInput(
          name: 't',
          kind: TxnKind.expense,
          categoryId: food,
          accountId: bank,
        ),
      );
      final u = await masters.categoryUsage(food);
      expect([u.txns, u.planLines, u.templates, u.assets], [1, 1, 1, 0]);
      expect(u.isUsed, isTrue);
    });

    test('関連履歴ごと削除：実績・計画行は墓石、テンプレートは残してカテゴリを空欄', () async {
      final bank = await account('銀行');
      final food = await category('外食');
      final t = await txn(accountId: bank, categoryId: food);
      await line(accountId: bank, categoryId: food);
      final tmpl = await templates.createTemplate(
        TemplateInput(
          name: 't',
          kind: TxnKind.expense,
          categoryId: food,
          accountId: bank,
        ),
      );

      await masters.deleteCategoryWithHistory(food);

      expect((await getTxn(t)).deletedAt, isNotNull);
      expect((await db.select(db.planLines).get()).single.deletedAt, isNotNull);
      final tr = await templates.getTemplate(tmpl);
      expect(tr!.deletedAt, isNull);
      expect(tr.categoryId, isNull);
      expect((await masters.getCategory(food))!.deletedAt, isNotNull);
    });

    test('付け替えて削除：実績・計画行・テンプレートを付け替える', () async {
      final bank = await account('銀行');
      final a = await category('外食');
      final b = await category('食費2');
      final t = await txn(accountId: bank, categoryId: a);
      final tmpl = await templates.createTemplate(
        TemplateInput(
          name: 't',
          kind: TxnKind.expense,
          categoryId: a,
          accountId: bank,
        ),
      );

      await masters.reassignCategoryAndDelete(a, b);

      final tx = await getTxn(t);
      expect(tx.categoryId, b);
      expect(tx.deletedAt, isNull);
      expect(tx.updatedBy, testDeviceId);
      expect((await templates.getTemplate(tmpl))!.categoryId, b);
    });

    test('資産のカテゴリを資産ごと削除：資産・価値・その資産の実績を削除し、テンプレートは資産を空欄', () async {
      final bank = await account('銀行');
      final stocks = await category('株', CategoryKind.asset);
      final assetId = newId();
      await db
          .into(db.assets)
          .insert(
            AssetsCompanion.insert(
              id: assetId,
              createdAt: 'x',
              updatedAt: 'x',
              updatedBy: 'x',
              planId: 'p1',
              name: '銘柄A',
              categoryId: stocks,
              valuation: 'quantity',
              sortOrder: 0,
            ),
          );
      await db
          .into(db.assetValues)
          .insert(
            AssetValuesCompanion.insert(
              id: assetValueId(assetId, '2026-01'),
              createdAt: 'x',
              updatedAt: 'x',
              updatedBy: 'x',
              assetId: assetId,
              unit: 'month',
              valueDate: '2026-01',
              valueX100: 100,
            ),
          );
      final t = await txn(accountId: bank, assetId: assetId);
      final tmpl = await templates.createTemplate(
        TemplateInput(name: 't', kind: TxnKind.expense, accountId: bank),
      );
      await (db.update(db.templates)..where((x) => x.id.equals(tmpl))).write(
        TemplatesCompanion(
          assetId: Value(assetId),
          assetAction: const Value('buy'),
        ),
      );

      expect((await masters.categoryUsage(stocks)).assets, 1);
      await masters.deleteCategoryWithHistory(stocks);

      expect((await db.select(db.assets).getSingle()).deletedAt, isNotNull);
      expect(
        (await db.select(db.assetValues).getSingle()).deletedAt,
        isNotNull,
      );
      expect((await getTxn(t)).deletedAt, isNotNull);
      final tr = (await templates.getTemplate(tmpl))!;
      expect(tr.deletedAt, isNull);
      expect(tr.assetId, isNull);
      expect(tr.assetAction, isNull);
    });
  });

  group('口座の削除', () {
    test('関連履歴ごと削除：振替の入金先として使われた実績も消え、テンプレートは口座を空欄', () async {
      final bank = await account('銀行');
      final sec = await account('証券');
      final t = await txn(accountId: bank, to: sec);
      final tmpl = await templates.createTemplate(
        TemplateInput(
          name: '積立',
          kind: TxnKind.transfer,
          accountId: bank,
          toAccountId: sec,
        ),
      );
      expect((await masters.accountUsage(sec)).txns, 1);

      await masters.deleteAccountWithHistory(sec);

      expect((await getTxn(t)).deletedAt, isNotNull);
      final tr = (await templates.getTemplate(tmpl))!;
      expect(tr.accountId, bank);
      expect(tr.toAccountId, isNull);
    });

    test('付け替えて削除：主口座・入金先・資産の保管口座を付け替える', () async {
      final a = await account('A');
      final b = await account('B');
      final c = await account('C');
      final t1 = await txn(accountId: a);
      final t2 = await txn(accountId: c, to: a);

      await masters.reassignAccountAndDelete(a, b);

      expect((await getTxn(t1)).accountId, b);
      expect((await getTxn(t2)).toAccountId, b);
      expect((await masters.getAccount(a))!.deletedAt, isNotNull);
    });
  });

  test('並べ替えは表示順を振り直す', () async {
    final a = await account('A');
    final b = await account('B');
    await masters.reorderAccounts([b, a]);
    final list = await masters.watchAccounts().first;
    expect(list.map((x) => x.name), ['B', 'A']);
  });

  group('テンプレート', () {
    test('振替のテンプレートはカテゴリを持たない・年率は「このテンプレートの率」のときだけ保存', () async {
      final bank = await account('銀行');
      final sec = await account('証券');
      final id = await templates.createTemplate(
        TemplateInput(
          name: '積立',
          kind: TxnKind.transfer,
          amount: 30000,
          categoryId: 'ignored',
          accountId: bank,
          toAccountId: sec,
          growthMode: GrowthMode.category,
          growthRate: 2.0,
        ),
      );
      final t = (await templates.getTemplate(id))!;
      expect(t.categoryId, isNull);
      expect(t.toAccountId, sec);
      expect(t.growthRate, isNull);
    });

    test('削除してもグループの項目は残り、欠けた項目として数える', () async {
      final bank = await account('銀行');
      final salary = await templates.createTemplate(
        TemplateInput(
          name: '給与',
          kind: TxnKind.income,
          amount: 300000,
          accountId: bank,
        ),
      );
      final tax = await templates.createTemplate(
        TemplateInput(name: '所得税', kind: TxnKind.expense, accountId: bank),
      );
      final g = await templates.saveGroup(
        name: 'A社の給与明細',
        items: [
          GroupItemDraft(id: 'i1', templateId: salary),
          GroupItemDraft(
            id: 'i2',
            templateId: tax,
            amountMode: AmountMode.percent,
            baseItemId: 'i1',
            percent: 5,
          ),
        ],
      );
      expect(
        (await templates.watchGroupsUsingTemplate(salary).first).single.id,
        g,
      );

      await templates.deleteTemplate(tax);

      final s = (await templates.watchGroupSummaries().first).single;
      expect(s.itemCount, 2);
      expect(s.missingCount, 1);
    });
  });

  group('グループの保存', () {
    test('項目の追加・変更・削除を反映し、変わっていない行は書き換えない', () async {
      final bank = await account('銀行');
      final t1 = await templates.createTemplate(
        TemplateInput(name: '家賃', kind: TxnKind.expense, accountId: bank),
      );
      final t2 = await templates.createTemplate(
        TemplateInput(name: '更新料', kind: TxnKind.expense, accountId: bank),
      );
      final g = await templates.saveGroup(
        name: '住居費',
        items: [
          GroupItemDraft(id: 'a', templateId: t1),
          GroupItemDraft(
            id: 'b',
            templateId: t2,
            frequency: Frequency.everyNYears,
            intervalN: 2,
          ),
        ],
      );
      // 未変更の行の更新日時が変わらないことを確かめるため、印を付ける
      await (db.update(db.templateGroupItems)..where((i) => i.id.equals('a')))
          .write(const TemplateGroupItemsCompanion(updatedAt: Value('mark')));

      await templates.saveGroup(
        groupId: g,
        name: '住居費',
        items: [
          GroupItemDraft(id: 'a', templateId: t1),
          GroupItemDraft(
            id: 'c',
            templateId: t2,
            frequency: Frequency.specificMonths,
            months: const [12, 6],
          ),
        ],
      );

      final rows = await db.select(db.templateGroupItems).get();
      final byId = {for (final r in rows) r.id: r};
      expect(byId['a']!.updatedAt, 'mark');
      expect(byId['b']!.deletedAt, isNotNull);
      expect(byId['c']!.months, '6,12');
      expect(byId['c']!.intervalN, isNull);
      final items = await templates.getGroupItems(g);
      expect(items.map((i) => i.id), ['a', 'c']);
    });

    test('割合の項目は頻度を持たない', () async {
      final bank = await account('銀行');
      final t = await templates.createTemplate(
        TemplateInput(name: 'x', kind: TxnKind.expense, accountId: bank),
      );
      final g = await templates.saveGroup(
        name: 'g',
        items: [
          GroupItemDraft(id: 'a', templateId: t),
          GroupItemDraft(
            id: 'b',
            templateId: t,
            amountMode: AmountMode.percent,
            baseItemId: 'a',
            percent: 15,
            frequency: Frequency.yearly,
            month: 6,
          ),
        ],
      );
      final b = (await db.select(db.templateGroupItems).get()).firstWhere(
        (r) => r.id == 'b',
      );
      expect(b.frequency, isNull);
      expect(b.month, isNull);
      expect(b.percent, 15);
      expect(b.groupId, g);
    });

    test('グループの削除で項目も削除する', () async {
      final bank = await account('銀行');
      final t = await templates.createTemplate(
        TemplateInput(name: 'x', kind: TxnKind.expense, accountId: bank),
      );
      final g = await templates.saveGroup(
        name: 'g',
        items: [GroupItemDraft(id: 'a', templateId: t)],
      );
      await templates.deleteGroup(g);
      expect(await templates.watchGroupSummaries().first, isEmpty);
      expect(
        (await db.select(db.templateGroupItems).getSingle()).deletedAt,
        isNotNull,
      );
    });
  });
}
