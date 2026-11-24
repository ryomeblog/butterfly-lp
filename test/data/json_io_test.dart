import 'dart:convert';

import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/io/json_export.dart';
import 'package:butterfly_lp/data/io/json_import.dart';
import 'package:butterfly_lp/data/repositories/asset_repository.dart';
import 'package:butterfly_lp/data/repositories/event_repository.dart';
import 'package:butterfly_lp/data/repositories/master_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_line_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/template_repository.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// 書き出して文字列にし、読み直す（ファイルを通したのと同じ）。
Map<String, dynamic> roundTrip(Map<String, Object?> json) =>
    jsonDecode(JsonExporter.encode(json)) as Map<String, dynamic>;

const planInput = NewPlanInput(
  name: 'プランA',
  startYear: 2026,
  protagonistName: '本人',
  protagonistBirthDate: '1990-01-01',
  protagonistLifeExpectancy: 90,
  createCashAccount: true,
);

void main() {
  late AppDatabase a;
  late AppDatabase b;
  const sa = Stamp('dev-a');
  const sb = Stamp('dev-b');
  late String planA;
  late String cash;
  late String food;
  late String groupId;
  late String assetId;

  /// A：実績2件・手入力の予定・グループの登録・イベント・資産（価値・購入）を持つプラン。
  setUp(() async {
    a = memoryDb();
    b = memoryDb();
    planA = await PlanRepository(a, sa).createPlan(planInput);
    cash = (await a.select(a.accounts).getSingle()).id;
    food = await MasterRepository(a, sa).createCategory(
      const CategoryInput(
        name: '外食',
        kind: CategoryKind.expense,
        color: '#F28E2B',
      ),
    );
    final txns = TxnRepository(a, sa);
    await txns.createTxn(
      TxnInput(
        planId: planA,
        date: '2026-11-02',
        kind: TxnKind.expense,
        amount: 1200,
        accountId: cash,
        categoryId: food,
        memo: 'ランチ',
      ),
    );
    final member = (await PlanRepository(a, sa).getPlan(planA))!
        .protagonistMemberId;
    final ev = await EventRepository(a, sa).saveEvent(
      input: EventInput(
        planId: planA,
        memberId: member,
        title: '旅行',
        year: 2027,
        month: 8,
      ),
      lines: [
        EventLineDraft(
          id: 'el1',
          kind: TxnKind.expense,
          amount: 300000,
          accountId: cash,
          categoryId: food,
        ),
      ],
    );
    await txns.createTxn(
      TxnInput(
        planId: planA,
        date: '2026-11-03',
        kind: TxnKind.expense,
        amount: 5000,
        accountId: cash,
        categoryId: food,
        eventId: ev,
      ),
    );
    await PlanLineRepository(a, sa).createManual(
      PlanLineInput(
        planId: planA,
        ym: YearMonth(2026, 12),
        kind: TxnKind.expense,
        amount: 40000,
        accountId: cash,
        categoryId: food,
      ),
    );
    final tmpl = await TemplateRepository(a, sa).createTemplate(
      TemplateInput(
        name: '給与',
        kind: TxnKind.income,
        amount: 300000,
        categoryId: food,
        accountId: cash,
      ),
    );
    groupId = await TemplateRepository(a, sa).saveGroup(
      name: '給与明細',
      items: [GroupItemDraft(id: 'gi1', templateId: tmpl)],
    );
    await PlanLineRepository(a, sa).registerGroup(
      planId: planA,
      groupId: groupId,
      start: YearMonth(2027, 1),
      end: YearMonth(2027, 3),
    );
    final assets = AssetRepository(a, sa);
    final stocks = (await (a.select(
      a.categories,
    )..where((c) => c.name.equals('株式・投資信託'))).getSingle()).id;
    assetId = await assets.createAsset(
      AssetInput(
        planId: planA,
        name: '銘柄A',
        categoryId: stocks,
        valuation: Valuation.quantity,
        accountId: cash,
      ),
    );
    await assets.setValue(assetId, 'month', '2026-11', 123456);
    await assets.recordFlow(
      AssetFlowInput(
        planId: planA,
        assetId: assetId,
        action: AssetAction.buy,
        amount: 12345,
        quantityX1e4: 100000,
        accountId: cash,
        categoryId: food,
        date: '2026-11-05',
        costs: const [CostLine(categoryId: 'fee-cat', amount: 100)],
      ),
    );
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  test('種類の判別', () {
    expect(
      JsonImporter.detect({'format': 'lifeplan-data', 'masters': {}}),
      ImportKind.full,
    );
    expect(
      JsonImporter.detect({
        'format': 'lifeplan-data',
        'plans': [
          {'plan': {}, 'settings': {}},
        ],
      }),
      ImportKind.plan,
    );
    expect(
      JsonImporter.detect({'format': 'lifeplan-data', 'actuals': []}),
      ImportKind.rows,
    );
    expect(
      () => JsonImporter.detect({'format': 'x'}),
      throwsA(isA<ImportFormatError>()),
    );
  });

  test('ファイルの種類（各画面の取り込みで受け付けるか）', () {
    Map<String, dynamic> f(Map<String, dynamic> body) => {
      'format': 'lifeplan-data',
      ...body,
    };
    expect(FileUnit.of(f({'masters': {}})), FileUnit.full);
    expect(
      FileUnit.of(
        f({
          'plans': [
            {'plan': {}, 'settings': {}},
          ],
          'assets': [{}],
        }),
      ),
      FileUnit.plan,
    );
    expect(
      FileUnit.of(
        f({
          'assets': [{}],
          'actuals': [{}],
        }),
      ),
      FileUnit.assets,
    );
    expect(
      FileUnit.of(
        f({
          'groups': [{}],
          'templates': [{}],
        }),
      ),
      FileUnit.groups,
    );
    expect(
      FileUnit.of(
        f({
          'templates': [{}],
        }),
      ),
      FileUnit.templates,
    );
    expect(
      FileUnit.of(
        f({
          'actuals': [{}],
          'templates': [],
        }),
      ),
      FileUnit.rows,
    );
  });

  test('予定・実績：別の端末へ取り込むと、参照先を同じUUIDで作る。下見では何も変えない。もう一度取り込むと上書き', () async {
    final json = roundTrip(
      await JsonExporter(a).exportRows(
        planId: planA,
        txns: await (a.select(
          a.txns,
        )..where((t) => t.planId.equals(planA))).get(),
        // 2026年11〜12月の予定（家計簿のリストで選んだ想定）
        lines:
            await (a.select(a.planLines)..where(
                  (l) =>
                      l.planId.equals(planA) &
                      l.year.equals(2026) &
                      l.month.isBiggerOrEqualValue(11),
                ))
                .get(),
      ),
    );
    final targetB = await PlanRepository(b, sb).createPlan(planInput);
    final importer = JsonImporter(b, sb);

    final preview = await importer.preview(json, targetPlanId: targetB);
    expect((preview.actualsNew, preview.linesNew), (4, 1));
    expect(
      preview.newRefs,
      containsAll(['カテゴリ「外食」', '口座「現金」', 'イベント「旅行」', '資産「銘柄A」']),
    );
    expect((preview.periodFrom, preview.periodTo), ('2026-11', '2026-12'));
    expect(await b.select(b.txns).get(), isEmpty); // 下見は巻き戻す

    final r = await importer.apply(json, targetPlanId: targetB);
    expect(r.actualsNew, 4);
    final t = await (b.select(
      b.txns,
    )..where((t) => t.memo.equals('ランチ'))).getSingle();
    expect((t.planId, t.categoryId, t.accountId), (targetB, food, cash));
    final fee = await (b.select(
      b.txns,
    )..where((t) => t.assetAction.equals('cost'))).getSingle();
    final buy = await (b.select(
      b.txns,
    )..where((t) => t.assetAction.equals('buy'))).getSingle();
    expect(fee.parentTxnId, buy.id);
    expect(buy.quantityX1e4, 100000);
    final line = await b.select(b.planLines).getSingle();
    expect((line.source, line.amount), ('manual', 40000));

    final again = await importer.preview(json, targetPlanId: targetB);
    expect(
      (again.actualsNew, again.actualsOverwrite, again.linesOverwrite),
      (0, 4, 1),
    );
    expect(again.newRefs, isEmpty);
  });

  test('取り込めない行は飛ばし、行番号と理由を出す', () async {
    final targetB = await PlanRepository(b, sb).createPlan(planInput);
    final json = {
      'format': 'lifeplan-data',
      'actuals': [
        {
          'date': '2026-11-01',
          'kind': 'expense',
          'amount': 'abc',
          'category': {'name': '食費'},
          'account': {'name': '現金'},
        },
        {
          'date': '2026-11-01',
          'kind': 'expense',
          'amount': 100,
          'category': {'name': '食費'},
          'account': {'name': '現金'},
        },
      ],
      'plans': [
        {
          'plan': {'id': targetB},
          'lines': [
            {
              'year': 2027,
              'month': 13,
              'kind': 'expense',
              'amount': 1,
              'category': {'name': '食費'},
              'account': {'name': '現金'},
            },
          ],
        },
      ],
    };
    final r = await JsonImporter(b, sb).apply(json, targetPlanId: targetB);
    expect(
      r.invalid.map((i) => i.toString()),
      unorderedEquals(['金額が数値でない（実績 1行目）', '月が1〜12でない（予定 1行目）']),
    );
    expect(r.actualsNew, 1);
    // id のない参照は同じ種類・同じ名前のものを使う
    final t = await b.select(b.txns).getSingle();
    final cat = await (b.select(
      b.categories,
    )..where((c) => c.id.equals(t.categoryId!))).getSingle();
    expect(cat.name, '食費');
    expect(await (b.select(b.accounts)).get(), hasLength(1));
  });

  test('ライフプラン単位：常に新しいプランとして追加し、配下のUUIDは振り直し、紐づきは保つ', () async {
    final json = roundTrip(await JsonExporter(a).exportPlan(planA));
    final r = await JsonImporter(a, sa).apply(json);
    expect(r.kind, ImportKind.plan);
    final newPlan = (await PlanRepository(a, sa).getPlan(r.createdPlanId!))!;
    expect(newPlan.id, isNot(planA));
    expect(newPlan.name, 'プランA(2)');
    final members = await (a.select(
      a.familyMembers,
    )..where((m) => m.planId.equals(newPlan.id))).get();
    expect(newPlan.protagonistMemberId, members.single.id);
    final txns = await (a.select(
      a.txns,
    )..where((t) => t.planId.equals(newPlan.id))).get();
    expect(txns, hasLength(4));
    final newEvent = await (a.select(
      a.planEvents,
    )..where((e) => e.planId.equals(newPlan.id))).getSingle();
    expect(txns.where((t) => t.eventId != null).single.eventId, newEvent.id);
    final lines = await (a.select(
      a.planLines,
    )..where((l) => l.planId.equals(newPlan.id))).get();
    final reg = await (a.select(
      a.planGroups,
    )..where((r) => r.planId.equals(newPlan.id))).getSingle();
    expect(
      lines
          .where((l) => l.source == 'group')
          .every((l) => l.sourceId == reg.id),
      isTrue,
    );
    expect(
      lines.where((l) => l.source == 'event').single.sourceId,
      newEvent.id,
    );
    expect(reg.groupId, groupId); // グループは同じUUID（上書き）
    final newAsset = await (a.select(
      a.assets,
    )..where((x) => x.planId.equals(newPlan.id))).getSingle();
    expect(newAsset.id, isNot(assetId));
    expect(
      (await (a.select(
        a.assetValues,
      )..where((v) => v.assetId.equals(newAsset.id))).getSingle()).valueX100,
      123456,
    );
    // 元のプランは変わらない
    expect(
      await (a.select(a.txns)..where((t) => t.planId.equals(planA))).get(),
      hasLength(4),
    );
  });

  test('全データ：空の端末へはそのままのUUIDで入り、もう一度入れると上書き（マージ）', () async {
    final json = roundTrip(await JsonExporter(a).exportAll());
    final r = await JsonImporter(b, sb).apply(json);
    expect(r.kind, ImportKind.full);
    expect(r.plansNew, 1);
    expect((await PlanRepository(b, sb).getPlan(planA))!.name, 'プランA');
    expect(
      await (b.select(b.txns)..where((t) => t.planId.equals(planA))).get(),
      hasLength(4),
    );
    expect(
      (await (b.select(
        b.categories,
      )..where((c) => c.id.equals(food))).getSingle()).color,
      '#F28E2B',
    );
    final again = await JsonImporter(b, sb).preview(json);
    expect(
      (again.plansOverwrite, again.actualsOverwrite, again.actualsNew),
      (1, 4, 0),
    );
  });

  test('グループ・テンプレート：同じUUIDは「別に追加」で新しいUUIDと(2)、「取り込まない」なら変えない', () async {
    final json = roundTrip(await JsonExporter(a).exportGroups([groupId]));
    final add = await JsonImporter(
      a,
      sa,
    ).apply(json, policy: SameIdPolicy.addNew);
    expect((add.groupsSame, add.templatesSame), (1, 1));
    final groups = await (a.select(
      a.templateGroups,
    )..where((g) => g.deletedAt.isNull())).get();
    expect(groups.map((g) => g.name), containsAll(['給与明細', '給与明細(2)']));
    final copy = groups.firstWhere((g) => g.name == '給与明細(2)');
    final item = await (a.select(
      a.templateGroupItems,
    )..where((i) => i.groupId.equals(copy.id))).getSingle();
    final t = await (a.select(
      a.templates,
    )..where((t) => t.id.equals(item.templateId))).getSingle();
    expect(t.name, '給与(2)');

    await (a.update(a.templates)..where((t) => t.name.equals('給与'))).write(
      const TemplatesCompanion(amount: Value(1)),
    );
    await JsonImporter(a, sa).apply(json, policy: SameIdPolicy.skip);
    expect(
      (await (a.select(
        a.templates,
      )..where((t) => t.name.equals('給与'))).getSingle()).amount,
      1,
    );
    await JsonImporter(a, sa).apply(json, policy: SameIdPolicy.overwrite);
    expect(
      (await (a.select(
        a.templates,
      )..where((t) => t.name.equals('給与'))).getSingle()).amount,
      300000,
    );
  });

  test('パレットにない色はグレーにする', () async {
    final targetB = await PlanRepository(b, sb).createPlan(planInput);
    await JsonImporter(b, sb).apply({
      'format': 'lifeplan-data',
      'actuals': [
        {
          'id': 'x1',
          'date': '2026-11-01',
          'kind': 'expense',
          'amount': 100,
          'category': {
            'id': 'c-new',
            'name': 'サブスク',
            'kind': 'expense',
            'color': '#1D4ED8',
          },
          'account': {'name': '現金'},
        },
      ],
    }, targetPlanId: targetB);
    final c = await (b.select(
      b.categories,
    )..where((c) => c.id.equals('c-new'))).getSingle();
    expect(c.color, '#BAB0AC');
  });
}
