import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/plan_line_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/template_repository.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_helpers.dart';

late String _planId;
late String _cash;
late String _groupId;
late String _food;

/// 今月：給与明細グループ（給与300,000・所得税＝給与の5%）を登録、食費の予定 50,000、食費の実績 62,000。
Future<void> _prepare(AppDatabase db, String deviceId) async {
  final stamp = Stamp(deviceId);
  _planId = await PlanRepository(db, stamp).createPlan(
    const NewPlanInput(
      name: 'プランA',
      startYear: 2026,
      protagonistName: '本人',
      protagonistBirthDate: '1990-01-01',
      protagonistLifeExpectancy: 90,
      createCashAccount: true,
    ),
  );
  _cash = (await db.select(db.accounts).getSingle()).id;
  Future<String> cat(String n) async => (await (db.select(
    db.categories,
  )..where((c) => c.name.equals(n))).getSingle()).id;
  _food = await cat('食費');
  final templates = TemplateRepository(db, stamp);
  final s = await templates.createTemplate(
    TemplateInput(
      name: '給与（額面）',
      kind: TxnKind.income,
      amount: 300000,
      categoryId: await cat('給与所得'),
      accountId: _cash,
    ),
  );
  final t = await templates.createTemplate(
    TemplateInput(
      name: '所得税',
      kind: TxnKind.expense,
      categoryId: await cat('税金'),
      accountId: _cash,
    ),
  );
  _groupId = await templates.saveGroup(
    name: 'A社の給与明細',
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
  final now = YearMonth.ofDate(clock.now());
  final lines = PlanLineRepository(db, stamp);
  await lines.registerGroup(
    planId: _planId,
    groupId: _groupId,
    start: now,
    end: now,
  );
  await lines.createManual(
    PlanLineInput(
      planId: _planId,
      ym: now,
      kind: TxnKind.expense,
      amount: 50000,
      accountId: _cash,
      categoryId: _food,
    ),
  );
  await TxnRepository(db, stamp).createTxn(
    TxnInput(
      planId: _planId,
      date: todayString(),
      kind: TxnKind.expense,
      amount: 62000,
      accountId: _cash,
      categoryId: _food,
    ),
  );
}

Future<void> _toCompareMonth(WidgetTester tester) async {
  await tester.tap(find.text('家計簿'));
  await settle(tester);
  await tester.tap(find.text('比較'));
  await settle(tester);
  await tester.tap(find.text('月'));
  await settle(tester);
}

void main() {
  testWidgets('家計簿（比較・月）：予定・実績・差、未入力の件数、カテゴリの超過', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await _toCompareMonth(tester);

    // 支出：予定 50,000＋15,000、実績 62,000
    expect(find.text('¥65,000'), findsWidgets);
    expect(find.text('¥62,000'), findsWidgets);
    expect(find.textContaining('実績が未入力：2件（¥315,000 分）'), findsOneWidget);
    expect(find.text('+¥12,000 超過'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('グループから実績入力：予定額が入っていて、直して保存すると入力済みになり、グループも更新できる', (
    tester,
  ) async {
    final db = await startApp(tester, prepare: _prepare);
    await _toCompareMonth(tester);
    await tester.tap(find.text('予定から入力'));
    await settle(tester);
    expect(find.text('グループ「A社の給与明細」'), findsOneWidget);
    await tester.tap(find.byKey(const Key('group-entry-A社の給与明細')));
    await settle(tester);

    // 予定額が入っている
    expect(find.text('300000'), findsOneWidget);
    expect(find.text('15000'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('entry-所得税')), '16500');
    await settle(tester);
    expect(find.text('差引（収入−支出−振替） +¥283,500'), findsOneWidget);
    await tester.tap(find.byKey(const Key('entry-update')));
    await tester.tap(find.byKey(const Key('entry-save')));
    await settle(tester);

    final txns = await tester.runAsync(
      () =>
          (db.select(db.txns)..where((t) => t.groupId.equals(_groupId))).get(),
    );
    expect(txns, hasLength(2));
    expect(txns!.map((t) => t.entryId).toSet(), hasLength(1));
    expect(txns.map((t) => t.groupItemId).toSet(), {'i-s', 'i-t'});
    final item = await tester.runAsync(
      () => (db.select(
        db.templateGroupItems,
      )..where((i) => i.id.equals('i-t'))).getSingle(),
    );
    expect(item!.percent, 5.5);

    // 予定から入力の画面で、グループの予定は入力済み（未入力の一覧から消える）
    expect(find.text('グループ「A社の給与明細」'), findsNothing);
    expect(find.textContaining('実績が未入力：0件'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('手入力の予定は「入力」で予定の内容が入った実績入力が開く', (tester) async {
    final db = await startApp(
      tester,
      prepare: (db, d) async {
        await _prepare(db, d);
        // 食費の実績を消して、手入力の予定を未入力にする
        await db.delete(db.txns).go();
      },
    );
    await tester.tap(find.text('家計簿'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('to-planned-entry')));
    await settle(tester);
    final line = await tester.runAsync(
      () => (db.select(
        db.planLines,
      )..where((l) => l.source.equals('manual'))).getSingle(),
    );
    await tester.tap(find.byKey(Key('enter-${line!.id}')));
    await settle(tester);
    expect(find.text('実績を入力'), findsOneWidget);
    expect(find.text('50000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('txn-save')));
    await settle(tester);

    final t = await tester.runAsync(() => db.select(db.txns).getSingle());
    expect((t!.amount, t.categoryId, t.groupItemId), (50000, _food, null));
    expect(find.byKey(Key('enter-${line.id}')), findsNothing);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('プラン詳細から年別の予実、年を選んで年間の予実を開ける', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('プランA').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('plan-chip-年別の予実')));
    await settle(tester);
    expect(find.byKey(const Key('years-bars')), findsOneWidget);
    expect(
      find.textContaining('予定 ¥65,000　実績 ¥62,000　差 −¥3,000'),
      findsOneWidget,
    );

    await tester.tap(find.text('${clock.now().year}年').first);
    await settle(tester);
    expect(find.text('${clock.now().year}年の予実'), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('家計簿の比較から資産の予実を開ける', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('家計簿'));
    await settle(tester);
    await tester.tap(find.text('比較'));
    await settle(tester);
    await tester.tap(find.text('資産の予実を見る'));
    await settle(tester);
    expect(find.text('資産の予実'), findsOneWidget);
    expect(find.byKey(const Key('diff-total')), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
