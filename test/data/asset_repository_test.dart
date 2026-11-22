import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/asset_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_line_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/template_repository.dart';
import 'package:butterfly_lp/domain/calc/asset_valuation.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('資産を参照するグループの登録・起点', registrationTests);
  late AppDatabase db;
  late AssetRepository repo;
  const stamp = Stamp(testDeviceId);

  setUp(() {
    db = memoryDb();
    repo = AssetRepository(db, stamp);
  });
  tearDown(() => db.close());

  Future<String> asset(Valuation v) => repo.createAsset(
    AssetInput(
      planId: 'p',
      name: '銘柄A',
      categoryId: 'k',
      valuation: v,
      accountId: 'sec',
    ),
  );

  test('価値：同じ日（月）は上書き、削除してもう一度入れられる', () async {
    final a = await asset(Valuation.quantity);
    await repo.setValue(a, 'month', '2026-01', 100000);
    await repo.setValue(a, 'month', '2026-01', 120000);
    await repo.setValue(a, 'day', '2026-01-15', 110000);
    var vs = await repo.watchValues(a).first;
    expect(vs, hasLength(2));
    expect(vs.firstWhere((v) => v.unit == 'month').valueX100, 120000);
    expect(vs.firstWhere((v) => v.unit == 'month').id, '$a:2026-01');

    await repo.deleteValue('$a:2026-01');
    expect(await repo.watchValues(a).first, hasLength(1));
    await repo.setValue(a, 'month', '2026-01', 130000);
    vs = await repo.watchValues(a).first;
    expect(vs, hasLength(2));
  });

  test('売却：費用は元の売却を指し、実現損益は費用を引く', () async {
    final a = await asset(Valuation.quantity);
    await repo.recordFlow(
      AssetFlowInput(
        planId: 'p',
        assetId: a,
        action: AssetAction.buy,
        amount: 10000,
        quantityX1e4: 100000,
        accountId: 'sec',
        categoryId: 'buy',
        date: '2026-01-10',
        costs: const [CostLine(categoryId: 'fee', amount: 100)],
      ),
    );
    final sell = await repo.recordFlow(
      AssetFlowInput(
        planId: 'p',
        assetId: a,
        action: AssetAction.sell,
        amount: 8000,
        quantityX1e4: 50000,
        accountId: 'sec',
        categoryId: 'sell',
        date: '2026-03-10',
        costs: const [CostLine(categoryId: 'tax', amount: 609)],
      ),
    );
    final txns = await repo.watchAssetTxns(a).first;
    expect(txns, hasLength(4));
    final tax = txns.firstWhere((t) => t.categoryId == 'tax');
    expect(
      (tax.kind, tax.assetAction, tax.parentTxnId),
      ('expense', 'cost', sell),
    );
    final s = assetStateAt(
      valuation: Valuation.quantity,
      moves: [for (final t in txns) AssetRepository.moveOf(t)],
      values: const [],
      date: '2026-12-31',
    );
    expect(s.sales.single.realizedGain, 8000 - 5000 - 609);
    expect(s.acquisitionCost, 5000);
  });

  test('評価額の資産の購入は、購入日の評価額として価値にも記録する', () async {
    final a = await asset(Valuation.value);
    await repo.recordFlow(
      AssetFlowInput(
        planId: 'p',
        assetId: a,
        action: AssetAction.buy,
        amount: 35000000,
        accountId: 'bank',
        categoryId: 'buy',
        date: '2024-04-20',
        valueAtBuyX100: 3500000000,
      ),
    );
    final v = (await repo.watchValues(a).first).single;
    expect(
      (v.unit, v.valueDate, v.valueX100),
      ('day', '2024-04-20', 3500000000),
    );
  });

  test('予定として保存すると手入力の計画行になる（費用も別の行）', () async {
    final a = await asset(Valuation.quantity);
    await repo.recordFlow(
      AssetFlowInput(
        planId: 'p',
        assetId: a,
        action: AssetAction.buy,
        amount: 30000,
        accountId: 'sec',
        categoryId: 'buy',
        ym: YearMonth(2027, 1),
        costs: const [CostLine(categoryId: 'fee', amount: 100)],
      ),
    );
    final lines = await repo.watchAssetPlanLines(a).first;
    expect(lines, hasLength(2));
    expect(lines.every((l) => l.source == 'manual' && l.assetId == a), isTrue);
    expect(await repo.watchAssetTxns(a).first, isEmpty);
  });

  test('削除：価値は削除、実績は残して紐づきを外す・予定は削除、テンプレートは資産を空欄', () async {
    final a = await asset(Valuation.quantity);
    await repo.setValue(a, 'month', '2026-01', 100000);
    await repo.recordFlow(
      AssetFlowInput(
        planId: 'p',
        assetId: a,
        action: AssetAction.buy,
        amount: 10000,
        quantityX1e4: 100000,
        accountId: 'sec',
        categoryId: 'buy',
        date: '2026-01-10',
      ),
    );
    await repo.recordFlow(
      AssetFlowInput(
        planId: 'p',
        assetId: a,
        action: AssetAction.buy,
        amount: 10000,
        accountId: 'sec',
        categoryId: 'buy',
        ym: YearMonth(2027, 1),
      ),
    );
    final tmpl = await TemplateRepository(db, stamp).createTemplate(
      const TemplateInput(name: '積立', kind: TxnKind.expense, accountId: 'sec'),
    );
    await (db.update(db.templates)..where((t) => t.id.equals(tmpl))).write(
      TemplatesCompanion(assetId: Value(a), assetAction: const Value('buy')),
    );

    final impact = await repo.deletionImpact(a);
    expect(
      [impact.txns, impact.planLines, impact.values, impact.templates],
      [1, 1, 1, 1],
    );
    await repo.deleteAsset(a, deleteTxns: false, deletePlanLines: true);

    final t = await db.select(db.txns).getSingle();
    expect(t.deletedAt, isNull);
    expect((t.assetId, t.assetAction, t.quantityX1e4), (null, null, null));
    expect((await db.select(db.planLines).getSingle()).deletedAt, isNotNull);
    expect((await db.select(db.assetValues).getSingle()).deletedAt, isNotNull);
    expect((await db.select(db.templates).getSingle()).assetId, isNull);
    expect(await repo.watchAssets('p').first, isEmpty);
  });
}

void registrationTests() {
  late AppDatabase db;
  const stamp = Stamp(testDeviceId);

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('数量指定の購入テンプレートを登録すると、見込み単価×数量の計画行と数量ができる', () async {
    final planId = await PlanRepository(db, stamp).createPlan(
      const NewPlanInput(
        name: 'A',
        startYear: 2026,
        protagonistName: '本人',
        protagonistBirthDate: '1990-01-01',
        protagonistLifeExpectancy: 90,
      ),
    );
    final assets = AssetRepository(db, stamp);
    final a = await assets.createAsset(
      AssetInput(
        planId: planId,
        name: '銘柄A',
        categoryId: 'k',
        valuation: Valuation.quantity,
      ),
    );
    // 起点日（今日）より後の 2030年1月に単価2,000円の見込みを指定
    await assets.setValue(a, 'month', '2030-01', 200000);
    final templates = TemplateRepository(db, stamp);
    final t = await templates.createTemplate(
      TemplateInput(
        name: '銘柄A 10口',
        kind: TxnKind.expense,
        categoryId: 'c',
        accountId: 'sec',
        assetId: a,
        assetAction: AssetAction.buy,
        quantityX1e4: 100000,
      ),
    );
    final g = await templates.saveGroup(
      name: '積立',
      items: [GroupItemDraft(id: 'i', templateId: t)],
    );
    await PlanLineRepository(db, stamp).registerGroup(
      planId: planId,
      groupId: g,
      start: YearMonth(2030, 1),
      end: YearMonth(2030, 2),
    );
    final lines = await db.select(db.planLines).get();
    expect(lines.map((l) => (l.amount, l.quantityX1e4, l.assetAction)), [
      (20000, 100000, 'buy'),
      (20000, 100000, 'buy'),
    ]);
  });

  test('別のプランの資産を参照するグループは、その項目を登録しない', () async {
    final pr = PlanRepository(db, stamp);
    const input = NewPlanInput(
      name: 'A',
      startYear: 2026,
      protagonistName: '本人',
      protagonistBirthDate: '1990-01-01',
      protagonistLifeExpectancy: 90,
    );
    final p1 = await pr.createPlan(input);
    final p2 = await pr.createPlan(input);
    final a = await AssetRepository(db, stamp).createAsset(
      AssetInput(
        planId: p1,
        name: '自宅',
        categoryId: 'k',
        valuation: Valuation.value,
      ),
    );
    final templates = TemplateRepository(db, stamp);
    final t = await templates.createTemplate(
      TemplateInput(
        name: '固定資産税',
        kind: TxnKind.expense,
        amount: 100000,
        categoryId: 'c',
        accountId: 'bank',
        assetId: a,
        assetAction: AssetAction.cost,
      ),
    );
    final g = await templates.saveGroup(
      name: '自宅',
      items: [
        GroupItemDraft(
          id: 'i',
          templateId: t,
          frequency: Frequency.yearly,
          month: 5,
        ),
      ],
    );
    final r = await PlanLineRepository(db, stamp).preview(
      planId: p2,
      groupId: g,
      start: YearMonth(2027, 1),
      end: YearMonth(2027, 12),
    );
    expect(r.lines, isEmpty);
    expect(r.skipped, hasLength(1));
  });

  test('プランの作成で資産の起点（保有数・単価／評価額）を保存する', () async {
    final pr = PlanRepository(db, stamp);
    final assets = AssetRepository(db, stamp);
    // 先に資産と実績を入れておき、起点だけ計算し直す
    final a = await assets.createAsset(
      const AssetInput(
        planId: 'p',
        name: '銘柄A',
        categoryId: 'k',
        valuation: Valuation.quantity,
      ),
    );
    await assets.recordFlow(
      AssetFlowInput(
        planId: 'p',
        assetId: a,
        action: AssetAction.buy,
        amount: 30000,
        quantityX1e4: 200000,
        accountId: 'sec',
        categoryId: 'c',
        date: '2026-01-10',
      ),
    );
    await pr.writeAssetBaselines('p', '2026-06-30');
    final b = await db.select(db.planBaselines).getSingle();
    expect((b.quantityX1e4, b.priceX100, b.balance), (200000, 150000, null));
  });
}
