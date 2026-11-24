import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/statement/statement.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../widget_helpers.dart';

late String _food;

/// プラン1つと、「スーパーA → 食費」の規則。
Future<void> _prepare(AppDatabase db, String deviceId) async {
  await PlanRepository(db, Stamp(deviceId)).createPlan(
    const NewPlanInput(
      name: 'プランA',
      startYear: 2026,
      protagonistName: '本人',
      protagonistBirthDate: '1990-01-01',
      protagonistLifeExpectancy: 90,
      createCashAccount: true,
    ),
  );
  _food = (await (db.select(
    db.categories,
  )..where((c) => c.name.equals('食費'))).getSingle()).id;
  await db
      .into(db.categoryRules)
      .insert(
        CategoryRulesCompanion.insert(
          kind: 'expense',
          content: 'スーパーA',
          categoryId: _food,
          updatedAt: 'x',
        ),
      );
}

Future<void> _openList(WidgetTester tester) async {
  await tester.tap(find.text('家計簿'));
  await settle(tester);
  await tester.tap(find.text('リスト'));
  await settle(tester);
}

void main() {
  testWidgets('スマホ版（Android）では家計簿のリストに明細の取り込みを出さない', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await _openList(tester);
    expect(find.text('予定・実績のJSONを取り込む'), findsOneWidget);
    expect(find.byKey(const Key('statement-import')), findsNothing);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('デスクトップ版では入口があり、規則でカテゴリが入り、空の行を外すと登録できる', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final db = await startApp(tester, prepare: _prepare);
      await _openList(tester);
      expect(find.byKey(const Key('statement-import')), findsOneWidget);
      await tester.tap(find.byKey(const Key('statement-import')));
      await settle(tester);
      expect(find.byKey(const Key('statement-pick-amazon')), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      // 読み取った結果から始める（ファイル選択はテストできないため）
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push(
        '/entry/statement',
        extra: const StatementResult([
          StatementLine(date: '2026-10-03', content: 'スーパーA', amount: 3200),
          StatementLine(date: '2026-10-04', content: '初めての店', amount: 800),
          StatementLine(date: '2026-10-05', content: '返品', amount: -1200),
        ], skipped: 2),
      );
      await settle(tester);
      expect(find.text('読み取った明細（3件・読めなかった行2件）'), findsOneWidget);
      // マイナスの行は収入になり、規則のない2行はカテゴリが空
      expect(find.text('カテゴリが空の行が2件あります'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('statement-save')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('statement-include-1')));
      await tester.tap(find.byKey(const Key('statement-include-2')));
      await settle(tester);
      expect(find.byKey(const Key('statement-problem')), findsNothing);
      expect(find.text('実績を1件登録'), findsOneWidget);
      await tester.tap(find.byKey(const Key('statement-save')));
      await settle(tester);

      final txns = (await tester.runAsync(() => db.select(db.txns).get()))!;
      expect(
        txns.map((t) => (t.date, t.kind, t.amount, t.categoryId, t.memo)),
        [('2026-10-03', 'expense', 3200, _food, 'スーパーA')],
      );
      expect(find.text('実績を1件登録しました'), findsOneWidget);
      await stopApp(tester, db);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
