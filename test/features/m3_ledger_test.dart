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
late String _food;
late String _salary;

/// プラン・口座「現金」と、今月の実績（給与・食費2件）を用意する。
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
  _food = await cat('食費');
  _salary = await cat('給与所得');
  // 初期残高の基準日は今日なので、実績も今月の今日以降の日付にはしない（今日にそろえる）
  final today = todayString();
  final repo = TxnRepository(db, stamp);
  await repo.createTxn(
    TxnInput(
      planId: planId,
      date: today,
      kind: TxnKind.income,
      amount: 300000,
      accountId: _cash,
      categoryId: _salary,
    ),
  );
  for (final a in [3000, 2000]) {
    await repo.createTxn(
      TxnInput(
        planId: planId,
        date: today,
        kind: TxnKind.expense,
        amount: a,
        accountId: _cash,
        categoryId: _food,
        memo: 'スーパー$a',
      ),
    );
  }
}

void main() {
  testWidgets('内訳：収入・支出・収支とカテゴリ別の内訳を出す', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('家計簿'));
    await settle(tester);

    expect(find.text('¥300,000'), findsWidgets);
    expect(find.text('¥5,000'), findsWidgets);
    expect(find.text('+¥295,000'), findsOneWidget);
    expect(find.text('食費'), findsWidgets);

    // 月表示でカテゴリを開くと、その月の明細が出る
    await tester.tap(find.text('月'));
    await settle(tester);
    await tester.tap(find.text('食費').last);
    await settle(tester);
    expect(find.textContaining('スーパー3000'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('実績を入力すると内訳とリストに出て、編集・削除できる', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('家計簿'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('txn-add')));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('txn-amount')),
        matching: find.byType(EditableText),
      ),
      '1500',
    );
    await tester.tap(find.byKey(const Key('txn-category')));
    await settle(tester);
    await tester.tap(find.text('交際費').last);
    await settle(tester);
    await tester.enterText(find.byKey(const Key('txn-memo')), 'ランチ');
    await tester.tap(find.byKey(const Key('txn-save')));
    await settle(tester);

    expect(find.text('¥6,500'), findsWidgets); // 支出 5,000＋1,500

    // リスト
    await tester.tap(find.text('リスト'));
    await settle(tester);
    expect(find.textContaining('絞り込み結果 4件'), findsOneWidget);
    expect(find.textContaining('ランチ'), findsOneWidget);

    // 押して編集 → 削除
    await tester.tap(find.textContaining('ランチ'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('txn-delete')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('txn-delete-confirm')));
    await settle(tester);
    expect(find.textContaining('絞り込み結果 3件'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('リストを種類で絞り込む・カレンダーで日を選ぶ', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('家計簿'));
    await settle(tester);
    await tester.tap(find.text('リスト'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('list-filter')));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilterChip, '収入'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('filter-apply')));
    await settle(tester);
    expect(find.textContaining('絞り込み結果 1件'), findsOneWidget);

    await tester.tap(find.text('カレンダー'));
    await settle(tester);
    final day = parseDate(todayString()).day;
    await tester.tap(find.byKey(Key('cal-$day')));
    await settle(tester);
    expect(find.textContaining('スーパー2000'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('口座詳細：今月末の残高と口座の実績', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    await tester.tap(find.text('資産'));
    await settle(tester);
    expect(find.text('¥295,000'), findsOneWidget);
    await tester.tap(find.text('現金'));
    await settle(tester);
    expect(find.text('¥295,000'), findsOneWidget);
    expect(find.textContaining('スーパー3000'), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
