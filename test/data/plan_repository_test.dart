import 'package:butterfly_lp/app/providers.dart';
import 'package:butterfly_lp/core/ids.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/db/seed.dart';
import 'package:butterfly_lp/data/repositories/device_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late PlanRepository repo;
  final fixed = Clock.fixed(DateTime.utc(2026, 11, 20, 1, 2, 3, 456));

  setUp(() {
    db = memoryDb();
    repo = PlanRepository(db, const Stamp(testDeviceId));
  });
  tearDown(() => db.close());

  const input = NewPlanInput(
    name: 'プランA',
    startYear: 2026,
    protagonistName: '本人',
    protagonistBirthDate: '1990-01-01',
    protagonistLifeExpectancy: 90,
    createCashAccount: true,
  );

  group('初期データ', () {
    test('世帯設定と初期カテゴリ（支出10・収入10・資産3）を入れる', () async {
      final h = await db.select(db.household).getSingle();
      expect(h.schemaVersion, currentSchemaVersion);

      final cats = await db.select(db.categories).get();
      int count(CategoryKind k) => cats.where((c) => c.kind == k.code).length;
      expect(count(CategoryKind.expense), 10);
      expect(count(CategoryKind.income), 10);
      expect(count(CategoryKind.asset), 3);
      expect(cats.map((c) => c.name), containsAll(['食費', '給与所得', '不動産']));
    });

    test('初期カテゴリのIDは名前から決まり、どの端末でも同じになる', () async {
      final food = await (db.select(
        db.categories,
      )..where((c) => c.name.equals('食費'))).getSingle();
      expect(food.id, seedId('category:expense:食費'));
      expect(food.updatedAt, seedTimestamp);
    });

    test('資産のカテゴリは既定の評価のしかたと税の初期値を持つ', () async {
      final stock = await (db.select(
        db.categories,
      )..where((c) => c.name.equals('株式・投資信託'))).getSingle();
      expect(stock.defaultValuation, Valuation.quantity.code);
      expect(stock.saleTaxDefault, 1);
      final car = await (db.select(
        db.categories,
      )..where((c) => c.name.equals('車・持ち物'))).getSingle();
      expect(car.defaultValuation, Valuation.value.code);
      expect(car.saleTaxDefault, 0);
    });

    test('色は10色のパレットを順に割り当てる', () async {
      final cats =
          await (db.select(db.categories)
                ..where((c) => c.kind.equals('expense'))
                ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
              .get();
      expect(cats.first.color, '#4E79A7');
      expect(cats.last.color, '#BAB0AC');
    });
  });

  group('端末設定', () {
    test('初回に端末IDを作り、2回目は同じ行を返す', () async {
      final r = DeviceRepository(db);
      final a = await r.ensure();
      final b = await r.ensure();
      expect(a.deviceId, isNotEmpty);
      expect(b.deviceId, a.deviceId);
    });
  });

  group('プランの作成', () {
    test('プラン・主人公・口座「現金」・口座の起点を作る', () async {
      final planId = await withClock(fixed, () => repo.createPlan(input));

      final plan = await repo.getPlan(planId);
      expect(plan!.name, 'プランA');
      expect(plan.startYear, 2026);
      expect(plan.baselineDate, '2026-11-20');

      final members = await repo.getMembers(planId);
      expect(members, hasLength(1));
      expect(members.single.id, plan.protagonistMemberId);
      expect(members.single.relation, Relation.self.code);

      final accounts = await db.select(db.accounts).get();
      expect(accounts.single.name, '現金');
      expect(accounts.single.initialBalance, 0);
      expect(accounts.single.initialDate, '2026-11-20');

      final baselines = await db.select(db.planBaselines).get();
      expect(baselines.single.id, '$planId:account:${accounts.single.id}');
      expect(baselines.single.balance, 0);
    });

    test('共通列：UTCミリ秒の更新日時と端末IDを付ける', () async {
      final planId = await withClock(fixed, () => repo.createPlan(input));
      final plan = await repo.getPlan(planId);
      expect(plan!.createdAt, '2026-11-20T01:02:03.456Z');
      expect(plan.updatedAt, '2026-11-20T01:02:03.456Z');
      expect(plan.updatedBy, testDeviceId);
      expect(plan.deletedAt, isNull);
    });

    test('2つ目のプランは口座を作らず、表示順が後ろになる', () async {
      final a = await repo.createPlan(input);
      final b = await repo.createPlan(
        const NewPlanInput(
          name: 'プランB',
          startYear: 2027,
          protagonistName: '本人',
          protagonistBirthDate: '1990-01-01',
          protagonistLifeExpectancy: 85,
        ),
      );
      expect(await db.select(db.accounts).get(), hasLength(1));
      final plans = await repo.watchPlans().first;
      expect(plans.map((p) => p.id), [a, b]);
    });

    test('起点はその時点の実績から計算する', () async {
      final planId = await withClock(fixed, () => repo.createPlan(input));
      final cash = await db.select(db.accounts).getSingle();
      await db
          .into(db.txns)
          .insert(
            TxnsCompanion.insert(
              id: newId(),
              createdAt: 'x',
              updatedAt: 'x',
              updatedBy: 'x',
              planId: planId,
              date: '2026-11-20',
              kind: TxnKind.income.code,
              amount: 5000,
              accountId: cash.id,
            ),
          );
      await repo.writeAccountBaselines(planId, '2026-11-20');
      final b = await db.select(db.planBaselines).getSingle();
      expect(b.balance, 5000);
    });
  });

  group('墓石', () {
    test('論理削除した行は一覧から消え、行自体は残る', () async {
      final planId = await repo.createPlan(input);
      await softDeleteRows(db, const Stamp('other'), 'plan', [planId]);
      expect(await repo.watchPlans().first, isEmpty);
      final raw = await db.select(db.plans).getSingle();
      expect(raw.deletedAt, isNotNull);
      expect(raw.updatedBy, 'other');
    });
  });

  group('表示プラン', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue(testDeviceId),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    Future<PlanRow?> selected(ProviderContainer c) async {
      await c.read(plansProvider.future);
      await c.read(deviceSettingProvider.future);
      return c.read(selectedPlanProvider).value;
    }

    test('未選択なら先頭のプラン、選ぶとそのプラン', () async {
      await DeviceRepository(db).ensure();
      final a = await repo.createPlan(input);
      final b = await repo.createPlan(input);
      final c = container();
      c.listen(selectedPlanProvider, (_, _) {});
      expect((await selected(c))!.id, a);

      await DeviceRepository(db).setSelectedPlan(b);
      await Future<void>.delayed(Duration.zero);
      expect((await selected(c))!.id, b);
    });

    test('選んだプランが削除されたら先頭のプラン', () async {
      await DeviceRepository(db).ensure();
      final a = await repo.createPlan(input);
      final b = await repo.createPlan(input);
      await DeviceRepository(db).setSelectedPlan(b);
      await softDeleteRows(db, const Stamp(testDeviceId), 'plan', [b]);
      final c = container();
      c.listen(selectedPlanProvider, (_, _) {});
      expect((await selected(c))!.id, a);
    });
  });
}
