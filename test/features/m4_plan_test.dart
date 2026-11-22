import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/plan_line_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/template_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_helpers.dart';

late String _planId;
late String _groupId;

/// プラン・口座・給与明細グループ（給与300,000と給与の5%の所得税）を用意する。
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
  final cash = (await db.select(db.accounts).getSingle()).id;
  Future<String> cat(String n) async => (await (db.select(
    db.categories,
  )..where((c) => c.name.equals(n))).getSingle()).id;
  final repo = TemplateRepository(db, stamp);
  final s = await repo.createTemplate(
    TemplateInput(
      name: '給与（額面）',
      kind: TxnKind.income,
      amount: 300000,
      categoryId: await cat('給与所得'),
      accountId: cash,
    ),
  );
  final t = await repo.createTemplate(
    TemplateInput(
      name: '所得税',
      kind: TxnKind.expense,
      categoryId: await cat('税金'),
      accountId: cash,
    ),
  );
  _groupId = await repo.saveGroup(
    name: 'A社の給与明細',
    items: [
      GroupItemDraft(id: 'i1', templateId: s),
      GroupItemDraft(
        id: 'i2',
        templateId: t,
        amountMode: AmountMode.percent,
        baseItemId: 'i1',
        percent: 5,
      ),
    ],
  );
}

Future<void> _openPlanDetail(WidgetTester tester) async {
  await tester.tap(find.text('プランA').last);
  await settle(tester);
}

void main() {
  testWidgets('プラン詳細からグループを登録し、登録済みグループと家計簿（予定）に出る', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await _openPlanDetail(tester);
    await tester.tap(find.byKey(const Key('plan-chip-計画（年別）')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('to-register')));
    await settle(tester);

    await tester.tap(find.byKey(const Key('register-group')));
    await settle(tester);
    await tester.tap(find.textContaining('A社の給与明細').last);
    await settle(tester);
    expect(find.textContaining('作成される計画行'), findsOneWidget);
    expect(find.text('+¥300,000'), findsOneWidget);
    expect(find.text('−¥15,000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('register-save')));
    await settle(tester);

    final lines = await tester.runAsync(() => db.select(db.planLines).get());
    expect(lines, isNotEmpty);
    expect(lines!.every((l) => l.source == 'group'), isTrue);

    // 家計簿（予定・月）に今月の給与が出る
    await tester.tap(find.text('家計簿'));
    await settle(tester);
    await tester.tap(find.text('予定'));
    await settle(tester);
    await tester.tap(find.text('月'));
    await settle(tester);
    expect(find.text('¥300,000'), findsWidgets);
    expect(find.text('¥15,000'), findsWidgets);

    // 予定のリストはグループごとにまとめる
    await tester.tap(find.text('リスト'));
    await settle(tester);
    expect(find.text('グループ「A社の給与明細」'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('家計簿の予定表示から手入力の予定を入れる', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('家計簿'));
    await settle(tester);
    await tester.tap(find.text('予定'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('txn-add')));
    await settle(tester);
    expect(find.text('予定を入力'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('txn-amount')),
        matching: find.byType(EditableText),
      ),
      '40000',
    );
    await tester.tap(find.byKey(const Key('txn-category')));
    await settle(tester);
    await tester.tap(find.text('食費').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('txn-save')));
    await settle(tester);

    final l = await tester.runAsync(() => db.select(db.planLines).getSingle());
    expect(l!.source, 'manual');
    expect(l.amount, 40000);
    final now = clock.now();
    expect((l.year, l.month), (now.year, now.month));
    expect(find.text('¥40,000'), findsWidgets);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('登録済みグループ：登録を取り消すと計画行も消える', (tester) async {
    final db = await startApp(
      tester,
      prepare: (db, d) async {
        await _prepare(db, d);
        await PlanLineRepository(db, Stamp(d)).registerGroup(
          planId: _planId,
          groupId: _groupId,
          start: YearMonth(2026, 1),
          end: YearMonth(2026, 12),
        );
      },
    );
    await _openPlanDetail(tester);
    await tester.tap(find.byKey(const Key('plan-chip-登録グループ')));
    await settle(tester);
    expect(find.text('A社の給与明細'), findsWidgets);
    expect(find.textContaining('作成した計画行 24件'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('cancel-registration')));
    await tester.tap(find.byKey(const Key('cancel-registration')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await settle(tester);

    expect(find.text('まだグループを登録していません。'), findsOneWidget);
    final live = await tester.runAsync(
      () => (db.select(db.planLines)..where((l) => l.deletedAt.isNull())).get(),
    );
    expect(live, isEmpty);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('家族を追加し、消えるものを確かめてすぐ削除する', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await _openPlanDetail(tester);
    await tester.tap(find.byKey(const Key('plan-chip-家族')));
    await settle(tester);

    await tester.tap(find.byKey(const Key('member-add')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('member-name')), '第1子');
    await tester.tap(find.byKey(const Key('member-birth')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '2028/04/01');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('member-save')));
    await settle(tester);
    expect(find.byKey(const Key('member-第1子')), findsOneWidget);

    await tester.tap(find.byKey(const Key('member-第1子')));
    await settle(tester);
    expect(find.text('この人のイベント：なし'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('member-delete')));
    await tester.tap(find.byKey(const Key('member-delete')));
    await settle(tester);
    // モーダルを挟まず削除される
    expect(find.byKey(const Key('member-第1子')), findsNothing);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('率の設定：カテゴリの上昇率を入れて保存する', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await _openPlanDetail(tester);
    await tester.tap(find.byKey(const Key('plan-chip-率')));
    await settle(tester);

    final field = find.descendant(
      of: find.byKey(const Key('rate-category-給与所得')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, '1.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);

    final rates = await tester.runAsync(() => db.select(db.planRates).get());
    expect(rates!.single.annualRate, 1.5);
    expect(rates.single.targetType, 'category');

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
