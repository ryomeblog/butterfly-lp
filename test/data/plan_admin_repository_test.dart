import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/asset_repository.dart';
import 'package:butterfly_lp/data/repositories/event_repository.dart';
import 'package:butterfly_lp/data/repositories/master_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_admin_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_line_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/rate_family_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/template_repository.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late PlanAdminRepository admin;
  late String src;
  late String bank;
  late String assetId;
  late String eventId;
  const stamp = Stamp(testDeviceId);

  const planInput = NewPlanInput(
    name: 'プランA',
    startYear: 2026,
    protagonistName: '本人',
    protagonistBirthDate: '1990-01-01',
    protagonistLifeExpectancy: 90,
  );

  /// 家族・イベント・資産（と資産のテンプレート・グループ）・登録・計画行・実績（費用つき）・率を持つプラン。
  setUp(() async {
    db = memoryDb();
    admin = PlanAdminRepository(db, stamp);
    src = await PlanRepository(db, stamp).createPlan(planInput);
    bank = await MasterRepository(db, stamp).createAccount(
      const AccountInput(
        name: '銀行',
        kind: AccountKind.bank,
        initialBalance: 100000,
        initialDate: '2020-01-01',
      ),
    );
    final member = (await PlanRepository(db, stamp).getPlan(src))!
        .protagonistMemberId;
    final assets = AssetRepository(db, stamp);
    assetId = await assets.createAsset(
      AssetInput(
        planId: src,
        name: '自宅',
        categoryId: 'k',
        valuation: Valuation.value,
      ),
    );
    await assets.setValue(assetId, 'month', '2026-01', 100000000);
    eventId = await EventRepository(db, stamp).saveEvent(
      input: EventInput(
        planId: src,
        memberId: member,
        title: '住宅購入',
        year: 2030,
        month: 3,
      ),
      lines: [
        EventLineDraft(
          id: 'el',
          kind: TxnKind.expense,
          amount: 100,
          accountId: bank,
          categoryId: 'c',
        ),
      ],
    );
    final buy = await assets.recordFlow(
      AssetFlowInput(
        planId: src,
        assetId: assetId,
        action: AssetAction.buy,
        amount: 1000000,
        accountId: bank,
        categoryId: 'c',
        date: '2026-01-10',
        eventId: eventId,
        costs: const [CostLine(categoryId: 'fee', amount: 5000)],
      ),
    );
    expect(buy, isNotEmpty);
    final templates = TemplateRepository(db, stamp);
    final tax = await templates.createTemplate(
      TemplateInput(
        name: '固定資産税',
        kind: TxnKind.expense,
        amount: 50000,
        categoryId: 'c',
        accountId: bank,
        assetId: assetId,
        assetAction: AssetAction.cost,
      ),
    );
    final g = await templates.saveGroup(
      name: '自宅',
      items: [
        GroupItemDraft(
          id: 'gi',
          templateId: tax,
          frequency: Frequency.yearly,
          month: 5,
        ),
      ],
    );
    await PlanLineRepository(db, stamp).registerGroup(
      planId: src,
      groupId: g,
      start: YearMonth(2027, 1),
      end: YearMonth(2028, 12),
    );
    await RateFamilyRepository(
      db,
      stamp,
    ).setRate(src, TargetType.asset, assetId, -1.5);
    await TxnRepository(db, stamp).createTxn(
      TxnInput(
        planId: src,
        date: '2026-02-01',
        kind: TxnKind.income,
        amount: 300000,
        accountId: bank,
        categoryId: 'salary',
      ),
    );
  });
  tearDown(() => db.close());

  Future<List<T>> live<T>(Future<List<T>> Function() q) => q();

  test('複製：配下を新しいUUIDで写し、参照を付け替える。元のプランは変わらない', () async {
    final copy = await admin.duplicate(src, 'プランA（複製）');
    final plan = (await PlanRepository(db, stamp).getPlan(copy))!;
    expect(plan.copiedFromPlanId, src);
    expect(plan.baselineDate, todayString());

    final members = await (db.select(
      db.familyMembers,
    )..where((m) => m.planId.equals(copy))).get();
    expect(plan.protagonistMemberId, members.single.id);

    final newAsset = (await (db.select(
      db.assets,
    )..where((a) => a.planId.equals(copy))).getSingle()).id;
    expect(newAsset, isNot(assetId));
    expect(
      (await (db.select(
        db.assetValues,
      )..where((v) => v.assetId.equals(newAsset))).getSingle()).id,
      '$newAsset:2026-01',
    );

    final newEvent = (await (db.select(
      db.planEvents,
    )..where((e) => e.planId.equals(copy))).getSingle()).id;
    final txns = await (db.select(
      db.txns,
    )..where((t) => t.planId.equals(copy))).get();
    expect(txns, hasLength(3));
    final buy = txns.firstWhere((t) => t.assetAction == 'buy');
    final fee = txns.firstWhere((t) => t.assetAction == 'cost');
    expect((buy.assetId, buy.eventId), (newAsset, newEvent));
    expect(fee.parentTxnId, buy.id);

    // 資産のテンプレートとグループは複製先の資産用に写し、登録・計画行もそれを指す
    final newGroup = (await (db.select(
      db.templateGroups,
    )..where((g) => g.name.equals('自宅（プランA（複製））'))).getSingle()).id;
    final reg = await (db.select(
      db.planGroups,
    )..where((r) => r.planId.equals(copy))).getSingle();
    expect(reg.groupId, newGroup);
    final lines = await (db.select(
      db.planLines,
    )..where((l) => l.planId.equals(copy))).get();
    final groupLines = lines.where((l) => l.source == 'group').toList();
    expect(groupLines, hasLength(2));
    expect(
      groupLines.every(
        (l) =>
            l.sourceId == reg.id &&
            l.assetId == newAsset &&
            l.groupItemId != 'gi',
      ),
      isTrue,
    );
    final eventLine = lines.firstWhere((l) => l.source == 'event');
    expect((eventLine.sourceId, eventLine.eventId), (newEvent, newEvent));

    final rate = await (db.select(
      db.planRates,
    )..where((r) => r.planId.equals(copy))).getSingle();
    expect((rate.id, rate.targetId), ('$copy:asset:$newAsset', newAsset));

    // 起点は今日の実績から計算し直す
    final base = await (db.select(
      db.planBaselines,
    )..where((b) => b.planId.equals(copy))).get();
    expect(
      base.firstWhere((b) => b.targetType == 'account').balance,
      100000 - 1000000 - 5000 + 300000,
    );
    expect(base.firstWhere((b) => b.targetType == 'asset').balance, 1000000);

    // 元のプランは変わらない
    expect(
      await (db.select(db.txns)..where((t) => t.planId.equals(src))).get(),
      hasLength(3),
    );
  });

  test('実績と資産を引き継いで作る：家族・イベント・計画行は引き継がず、実績のイベントとの関連は外す', () async {
    final p = await admin.createInheriting(
      const NewPlanInput(
        name: 'プランB',
        startYear: 2027,
        protagonistName: '本人',
        protagonistBirthDate: '1990-01-01',
        protagonistLifeExpectancy: 85,
      ),
      src,
    );
    final txns = await (db.select(
      db.txns,
    )..where((t) => t.planId.equals(p))).get();
    expect(txns, hasLength(3));
    expect(txns.every((t) => t.eventId == null), isTrue);
    expect(
      await (db.select(db.planLines)..where((l) => l.planId.equals(p))).get(),
      isEmpty,
    );
    expect(
      await (db.select(db.planEvents)..where((e) => e.planId.equals(p))).get(),
      isEmpty,
    );
    expect(
      await (db.select(db.assets)..where((a) => a.planId.equals(p))).get(),
      hasLength(1),
    );
    final base =
        await (db.select(db.planBaselines)..where(
              (b) => b.planId.equals(p) & b.targetType.equals('account'),
            ))
            .getSingle();
    expect(base.balance, 100000 - 1000000 - 5000 + 300000);
  });

  test('削除：配下のデータも墓石になり、資産のテンプレートは資産の欄が空になる', () async {
    await admin.delete(src);
    Future<int> liveCount(String table) async =>
        (await db
                .customSelect(
                  "SELECT COUNT(*) AS c FROM $table WHERE deleted_at IS NULL AND plan_id = '$src'",
                )
                .getSingle())
            .read<int>('c');
    for (final t in [
      'txn',
      'asset',
      'plan_line',
      'plan_event',
      'family_member',
      'plan_rate',
      'plan_baseline',
      'plan_group',
    ]) {
      expect(await liveCount(t), 0, reason: t);
    }
    expect((await PlanRepository(db, stamp).getPlan(src)), isNull);
    final t = await (db.select(
      db.templates,
    )..where((t) => t.name.equals('固定資産税'))).getSingle();
    expect((t.deletedAt, t.assetId), (null, null));
    expect(
      await live(
        () => (db.select(
          db.assetValues,
        )..where((v) => v.deletedAt.isNull())).get(),
      ),
      isEmpty,
    );
  });

  test('名前変更', () async {
    await admin.rename(src, '新しい名前');
    expect((await PlanRepository(db, stamp).getPlan(src))!.name, '新しい名前');
  });
}
