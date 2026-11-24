import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/asset_repository.dart';
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

/// テンプレート2つ・グループ1つ・資産2つ・今月の手入力の予定2件。
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
  final cash = (await db.select(db.accounts).getSingle()).id;
  Future<String> cat(String n) async => (await (db.select(
    db.categories,
  )..where((c) => c.name.equals(n))).getSingle()).id;
  final templates = TemplateRepository(db, stamp);
  final t1 = await templates.createTemplate(
    TemplateInput(
      name: '家賃',
      kind: TxnKind.expense,
      amount: 80000,
      categoryId: await cat('住居費'),
      accountId: cash,
    ),
  );
  await templates.createTemplate(
    TemplateInput(
      name: '電気代',
      kind: TxnKind.expense,
      amount: 8000,
      categoryId: await cat('水道光熱費'),
      accountId: cash,
    ),
  );
  await templates.saveGroup(
    name: '固定費',
    items: [GroupItemDraft(id: 'i1', templateId: t1)],
  );
  final assets = AssetRepository(db, stamp);
  for (final n in ['銘柄A', '銘柄B']) {
    await assets.createAsset(
      AssetInput(
        planId: planId,
        name: n,
        categoryId: await cat('株式・投資信託'),
        valuation: Valuation.value,
      ),
    );
  }
  final lines = PlanLineRepository(db, stamp);
  for (final a in [50000, 60000]) {
    await lines.createManual(
      PlanLineInput(
        planId: planId,
        ym: YearMonth.ofDate(clock.now()),
        kind: TxnKind.expense,
        amount: a,
        accountId: cash,
        categoryId: await cat('食費'),
      ),
    );
  }
}

void main() {
  testWidgets('ホームのテンプレート・グループ：長押しで選んでJSONの書き出し、取り込みの入口', (tester) async {
    final db = await startApp(tester, prepare: _prepare);

    await tester.tap(find.text('テンプレート').first);
    await settle(tester);
    expect(find.text('テンプレートのJSONを取り込む'), findsOneWidget);
    await tester.longPress(find.byKey(const Key('template-tile-家賃')));
    await settle(tester);
    expect(find.text('1件を選択中'), findsOneWidget);
    // 選択中はタップで選ぶ（編集は開かない）
    await tester.tap(find.byKey(const Key('template-tile-電気代')));
    await settle(tester);
    expect(find.text('2件を選択中'), findsOneWidget);
    expect(find.byKey(const Key('select-export')), findsOneWidget);
    await tester.tap(find.byKey(const Key('select-clear')));
    await settle(tester);
    expect(find.byKey(const Key('select-count')), findsNothing);

    await tester.tap(find.text('グループ').first);
    await settle(tester);
    expect(find.text('グループのJSONを取り込む'), findsOneWidget);
    await tester.longPress(find.byKey(const Key('group-tile-固定費')));
    await settle(tester);
    expect(find.text('1件を選択中'), findsOneWidget);
    expect(find.byKey(const Key('select-export')), findsOneWidget);

    await tester.tap(find.text('ライフプラン').first);
    await settle(tester);
    expect(find.text('ライフプランのJSONを取り込む'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('テンプレート・グループの編集画面から1件を書き出せる', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('テンプレート').first);
    await settle(tester);
    await tester.tap(find.byKey(const Key('template-tile-家賃')));
    await settle(tester);
    expect(find.byKey(const Key('template-export')), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('資産：長押しで選んでJSONの書き出し', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('資産').last);
    await settle(tester);
    expect(find.text('資産のJSONを取り込む'), findsOneWidget);
    await tester.longPress(find.byKey(const Key('asset-銘柄A')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('select-all')));
    await settle(tester);
    expect(find.text('2件を選択中'), findsOneWidget);
    expect(find.byKey(const Key('select-export')), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('家計簿（予定・リスト）：長押しで選ぶと入力ボタンを隠し、JSONで書き出せる', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('家計簿'));
    await settle(tester);
    await tester.tap(find.text('予定'));
    await settle(tester);
    await tester.tap(find.text('リスト'));
    await settle(tester);
    expect(find.text('予定・実績のJSONを取り込む'), findsOneWidget);
    final line = (await tester.runAsync(() => db.select(db.planLines).get()))!
        .first;
    await tester.longPress(find.byKey(Key('line-tile-${line.id}')));
    await settle(tester);
    expect(find.byKey(const Key('txn-add')), findsNothing);
    expect(find.text('1件を選択中'), findsOneWidget);
    expect(find.byKey(const Key('select-export')), findsOneWidget);
    // 実績に切り替えると選択をやめる
    await tester.tap(find.text('実績'));
    await settle(tester);
    expect(find.byKey(const Key('select-count')), findsNothing);
    expect(find.byKey(const Key('txn-add')), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
