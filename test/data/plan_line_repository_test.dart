import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/master_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_line_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/rate_family_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/template_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late PlanLineRepository lines;
  late RateFamilyRepository rates;
  late TemplateRepository templates;
  late String planId;
  late String groupId;
  late String salaryCat;
  const stamp = Stamp(testDeviceId);

  setUp(() async {
    db = memoryDb();
    lines = PlanLineRepository(db, stamp);
    rates = RateFamilyRepository(db, stamp);
    templates = TemplateRepository(db, stamp);
    planId = await PlanRepository(db, stamp).createPlan(
      const NewPlanInput(
        name: 'A',
        startYear: 2026,
        protagonistName: '本人',
        protagonistBirthDate: '1990-01-01',
        protagonistLifeExpectancy: 90,
      ),
    );
    final bank = await MasterRepository(db, stamp).createAccount(
      const AccountInput(
        name: '銀行',
        kind: AccountKind.bank,
        initialBalance: 0,
        initialDate: '2026-01-01',
      ),
    );
    salaryCat = (await (db.select(
      db.categories,
    )..where((c) => c.name.equals('給与所得'))).getSingle()).id;
    final taxCat = (await (db.select(
      db.categories,
    )..where((c) => c.name.equals('税金'))).getSingle()).id;
    final s = await templates.createTemplate(
      TemplateInput(
        name: '給与',
        kind: TxnKind.income,
        amount: 300000,
        categoryId: salaryCat,
        accountId: bank,
      ),
    );
    final t = await templates.createTemplate(
      TemplateInput(
        name: '所得税',
        kind: TxnKind.expense,
        categoryId: taxCat,
        accountId: bank,
      ),
    );
    groupId = await templates.saveGroup(
      name: 'A社',
      items: [
        GroupItemDraft(id: 'i-s', templateId: s),
        GroupItemDraft(
          id: 'i-t',
          templateId: t,
          amountMode: AmountMode.percent,
          baseItemId: 'i-s',
          percent: 5,
        ),
      ],
    );
  });
  tearDown(() => db.close());

  Future<List<PlanLineRow>> live() => lines.watchLines(planId).first;

  test('登録：項目ごと・月ごとに計画行を作り、由来と項目IDを持つ', () async {
    final reg = await lines.registerGroup(
      planId: planId,
      groupId: groupId,
      start: YearMonth(2026, 4),
      end: YearMonth(2027, 3),
    );
    final all = await live();
    expect(all, hasLength(24));
    final first = all.firstWhere((l) => l.groupItemId == 'i-t');
    expect(first.source, 'group');
    expect(first.sourceId, reg);
    expect(first.amount, 15000);
    expect(first.memo, '所得税');
    final summaries = await lines.watchRegistrations(planId).first;
    expect(summaries.single.lineCount, 24);
    expect(summaries.single.groupName, 'A社');
  });

  test('カテゴリの上昇率（昇給率）で増やす', () async {
    await rates.setRate(planId, TargetType.category, salaryCat, 2);
    await lines.registerGroup(
      planId: planId,
      groupId: groupId,
      start: YearMonth(2026, 12),
      end: YearMonth(2027, 1),
    );
    final jan = (await live()).firstWhere(
      (l) => l.year == 2027 && l.groupItemId == 'i-s',
    );
    expect(jan.amount, 306000);
  });

  test('作り直し：指定年月以降を今のグループの内容で作り直す（手で直した行も置き換える）', () async {
    final reg = await lines.registerGroup(
      planId: planId,
      groupId: groupId,
      start: YearMonth(2026, 1),
      end: YearMonth(2026, 12),
    );
    // 7月の給与を手で直しておく
    final jul = (await live()).firstWhere(
      (l) => l.month == 7 && l.groupItemId == 'i-s',
    );
    await (db.update(db.planLines)..where((l) => l.id.equals(jul.id))).write(
      const PlanLinesCompanion(amount: Value(1)),
    );
    // テンプレートの金額を変えて、7月以降を作り直す
    final salaryTemplate = (await db.select(db.templates).get()).firstWhere(
      (t) => t.name == '給与',
    );
    await (db.update(db.templates)
          ..where((t) => t.id.equals(salaryTemplate.id)))
        .write(const TemplatesCompanion(amount: Value(400000)));
    await lines.rebuildFrom(reg, YearMonth(2026, 7));

    final all = await live();
    final salaries = {
      for (final l in all.where((l) => l.groupItemId == 'i-s'))
        l.month: l.amount,
    };
    expect(salaries[6], 300000);
    expect(salaries[7], 400000);
    expect(salaries[12], 400000);
    expect(all, hasLength(24));
  });

  test('年範囲の削除は登録を残す、取り消しは計画行ごと削除する', () async {
    final reg = await lines.registerGroup(
      planId: planId,
      groupId: groupId,
      start: YearMonth(2026, 1),
      end: YearMonth(2028, 12),
    );
    await lines.deleteYearRange(reg, 2027, 2027);
    expect((await live()).where((l) => l.year == 2027), isEmpty);
    expect((await live()), hasLength(48));
    expect(await lines.watchRegistrations(planId).first, hasLength(1));

    await lines.cancelRegistration(reg);
    expect(await live(), isEmpty);
    expect(await lines.watchRegistrations(planId).first, isEmpty);
  });

  test('グループを削除しても登録と計画行は残り、「元のグループは削除済み」になる', () async {
    await lines.registerGroup(
      planId: planId,
      groupId: groupId,
      start: YearMonth(2026, 1),
      end: YearMonth(2026, 3),
    );
    await templates.deleteGroup(groupId);
    final s = (await lines.watchRegistrations(planId).first).single;
    expect(s.groupDeleted, isTrue);
    expect(s.lineCount, 6);
  });

  test('手入力の予定の作成・編集（由来は保つ）', () async {
    final bank = (await db.select(db.accounts).get()).first.id;
    final id = await lines.createManual(
      PlanLineInput(
        planId: planId,
        ym: YearMonth(2026, 11),
        kind: TxnKind.expense,
        amount: 50000,
        accountId: bank,
        categoryId: 'food',
      ),
    );
    final l = (await lines.getLine(id))!;
    expect((l.source, l.year, l.month), ('manual', 2026, 11));

    await lines.registerGroup(
      planId: planId,
      groupId: groupId,
      start: YearMonth(2026, 1),
      end: YearMonth(2026, 1),
    );
    final g = (await live()).firstWhere((x) => x.source == 'group');
    await lines.updateLine(
      g.id,
      PlanLineInput(
        planId: planId,
        ym: YearMonth(2026, 1),
        kind: TxnKind.income,
        amount: 1,
        accountId: bank,
        categoryId: salaryCat,
      ),
    );
    final edited = (await lines.getLine(g.id))!;
    expect(edited.amount, 1);
    expect(edited.source, 'group');
    expect(edited.groupItemId, g.groupItemId);
  });

  group('率', () {
    test('設定・変更・消去（決定的ID）', () async {
      await rates.setRate(planId, TargetType.account, 'bank', 0.5);
      await rates.setRate(planId, TargetType.account, 'bank', 1.0);
      var all = await rates.watchRates(planId).first;
      expect(all.single.id, '$planId:account:bank');
      expect(all.single.annualRate, 1.0);
      await rates.setRate(planId, TargetType.account, 'bank', null);
      all = await rates.watchRates(planId).first;
      expect(all, isEmpty);
      // 消したあとにもう一度設定できる
      await rates.setRate(planId, TargetType.account, 'bank', 2.0);
      expect((await rates.watchRates(planId).first).single.annualRate, 2.0);
    });
  });

  group('家族', () {
    test('主人公は削除できない', () async {
      final plan = (await PlanRepository(db, stamp).getPlan(planId))!;
      expect(
        () => rates.deleteMember(plan.protagonistMemberId),
        throwsStateError,
      );
    });

    test('削除でその人のイベントと予定が消え、実績は紐づきだけ外れる', () async {
      final child = await rates.addMember(
        planId,
        const MemberInput(
          name: '第1子',
          relation: Relation.child,
          birthDate: '2028-04-01',
          lifeExpectancy: 90,
        ),
      );
      await db
          .into(db.planEvents)
          .insert(
            PlanEventsCompanion.insert(
              id: 'ev',
              createdAt: 'x',
              updatedAt: 'x',
              updatedBy: 'x',
              planId: planId,
              memberId: child,
              title: '入学',
              year: 2034,
              month: 4,
              status: 'planned',
            ),
          );
      await db
          .into(db.planLines)
          .insert(
            PlanLinesCompanion.insert(
              id: 'l1',
              createdAt: 'x',
              updatedAt: 'x',
              updatedBy: 'x',
              planId: planId,
              year: 2034,
              month: 4,
              kind: 'expense',
              amount: 100,
              accountId: 'bank',
              source: 'event',
              sourceId: const Value('ev'),
              eventId: const Value('ev'),
            ),
          );
      await db
          .into(db.txns)
          .insert(
            TxnsCompanion.insert(
              id: 't1',
              createdAt: 'x',
              updatedAt: 'x',
              updatedBy: 'x',
              planId: planId,
              date: '2034-04-02',
              kind: 'expense',
              amount: 100,
              accountId: 'bank',
              eventId: const Value('ev'),
            ),
          );

      final impact = await rates.memberDeletionImpact(child);
      expect(impact.eventTitles, ['入学']);
      expect(impact.planLineCount, 1);
      expect(impact.txnCount, 1);

      await rates.deleteMember(child);
      expect(
        (await (db.select(
          db.planEvents,
        )..where((e) => e.id.equals('ev'))).getSingle()).deletedAt,
        isNotNull,
      );
      expect((await lines.getLine('l1'))!.deletedAt, isNotNull);
      final t = await (db.select(
        db.txns,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(t.deletedAt, isNull);
      expect(t.eventId, isNull);
    });
  });
}
