import 'package:drift/drift.dart' show OrderingTerm;
import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_helpers.dart';

late String _cash;
late String _salaryTxn;
late String _taxTxn;
late String _foodTxn;

/// 今日の実績：給与 300,000（メモ「A社」）・税金 15,000（メモなし）・食費 3,000。
Future<void> _prepare(AppDatabase db, String deviceId) async {
  final stamp = Stamp(deviceId);
  final planId = await PlanRepository(db, stamp).createPlan(
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
  Future<String> cat(String name) async => (await (db.select(
    db.categories,
  )..where((c) => c.name.equals(name))).getSingle()).id;
  final repo = TxnRepository(db, stamp);
  Future<String> add(
    TxnKind kind,
    int amount,
    String category, [
    String? memo,
  ]) async => repo.createTxn(
    TxnInput(
      planId: planId,
      date: todayString(),
      kind: kind,
      amount: amount,
      accountId: _cash,
      categoryId: await cat(category),
      memo: memo,
    ),
  );
  _salaryTxn = await add(TxnKind.income, 300000, '給与所得', 'A社');
  _taxTxn = await add(TxnKind.expense, 15000, '税金');
  _foodTxn = await add(TxnKind.expense, 3000, '食費');
}

Future<void> _toList(WidgetTester tester) async {
  await tester.tap(find.text('家計簿'));
  await settle(tester);
  await tester.tap(find.text('リスト'));
  await settle(tester);
}

void main() {
  testWidgets('リストで実績を長押しして選び、新しいグループを作る', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await _toList(tester);

    expect(find.byKey(const Key('txn-add')), findsOneWidget);
    await tester.longPress(find.byKey(Key('txn-tile-$_salaryTxn')));
    await settle(tester);
    // 選択中は入力ボタンを隠し、タップで選ぶ（編集は開かない）
    expect(find.byKey(const Key('txn-add')), findsNothing);
    await tester.tap(find.byKey(Key('txn-tile-$_taxTxn')));
    await settle(tester);
    expect(find.text('2件を選択中'), findsOneWidget);

    await tester.tap(find.byKey(const Key('select-to-group')));
    await settle(tester);
    // 名前の初期値：メモ、なければカテゴリ名
    expect(find.text('A社'), findsOneWidget);
    expect(find.text('税金'), findsWidgets);
    await tester.enterText(find.byKey(const Key('reg-name-1')), '所得税');
    // グループ名は必須
    await tester.tap(find.byKey(const Key('reg-save')));
    await settle(tester);
    expect(find.text('入力してください'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('reg-group-name')), 'A社の給与明細');
    await tester.tap(find.byKey(const Key('reg-save')));
    await settle(tester);

    // 戻ると選択は解除されている
    expect(find.byKey(const Key('txn-add')), findsOneWidget);
    expect(find.textContaining('グループ「A社の給与明細」を作りました'), findsOneWidget);

    final templates = (await tester.runAsync(
      () => db.select(db.templates).get(),
    ))!;
    expect(
      {for (final t in templates) t.name: t.amount},
      {'A社': 300000, '所得税': 15000},
    );
    final salary = templates.singleWhere((t) => t.name == 'A社');
    expect(salary.kind, 'income');
    expect(salary.accountId, _cash);
    expect(salary.memo, 'A社');
    expect(salary.growthMode, 'category');
    final group = (await tester.runAsync(
      () => db.select(db.templateGroups).getSingle(),
    ))!;
    expect(group.name, 'A社の給与明細');
    final items = (await tester.runAsync(
      () => (db.select(
        db.templateGroupItems,
      )..orderBy([(i) => OrderingTerm(expression: i.sortOrder)])).get(),
    ))!;
    // 日付の古い順（同じ日は作った順）、毎月・固定額
    expect(items.map((i) => i.templateId), [
      salary.id,
      templates.singleWhere((t) => t.name == '所得税').id,
    ]);
    expect(items.map((i) => (i.amountMode, i.frequency)).toSet(), {
      ('fixed', 'monthly'),
    });

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('すべて選んでテンプレートだけを作る・選択をやめる', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await _toList(tester);

    await tester.longPress(find.byKey(Key('txn-tile-$_foodTxn')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('select-clear')));
    await settle(tester);
    expect(find.byKey(const Key('select-count')), findsNothing);
    expect(find.byKey(const Key('txn-add')), findsOneWidget);

    await tester.longPress(find.byKey(Key('txn-tile-$_foodTxn')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('select-all')));
    await settle(tester);
    expect(find.text('3件を選択中'), findsOneWidget);
    await tester.tap(find.byKey(const Key('select-to-templates')));
    await settle(tester);
    expect(find.byKey(const Key('reg-group-name')), findsNothing);
    await tester.tap(find.byKey(const Key('reg-save')));
    await settle(tester);

    final templates = (await tester.runAsync(
      () => db.select(db.templates).get(),
    ))!;
    expect(templates.map((t) => t.name).toSet(), {'A社', '税金', '食費'});
    expect(
      await tester.runAsync(() => db.select(db.templateGroups).get()),
      isEmpty,
    );
    // 同じ実績からもう一度作ると、既存を使わず新しく作る
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .hideCurrentSnackBar();
    await settle(tester);
    await tester.longPress(find.byKey(Key('txn-tile-$_foodTxn')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('select-to-templates')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('reg-save')));
    await settle(tester);
    final again = (await tester.runAsync(() => db.select(db.templates).get()))!;
    expect(again.where((t) => t.name == '食費'), hasLength(2));

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
