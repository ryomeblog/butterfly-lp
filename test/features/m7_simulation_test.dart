import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/plan_line_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_helpers.dart';

late String _planId;

/// 現金 100,000 円で始まり、来月から毎月 30,000 円の支出だけがある（4か月目に資金不足）。
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
  final food = (await (db.select(
    db.categories,
  )..where((c) => c.name.equals('食費'))).getSingle()).id;
  final salary = (await (db.select(
    db.categories,
  )..where((c) => c.name.equals('給与所得'))).getSingle()).id;
  // 起点日（今日）の実績 100,000 円を起点に入れる
  await TxnRepository(db, stamp).createTxn(
    TxnInput(
      planId: _planId,
      date: todayString(),
      kind: TxnKind.income,
      amount: 100000,
      accountId: cash,
      categoryId: salary,
    ),
  );
  await PlanRepository(db, stamp).writeAccountBaselines(_planId, todayString());
  final lines = PlanLineRepository(db, stamp);
  final next = YearMonth.ofDate(clock.now()).addMonths(1);
  for (var i = 0; i < 6; i++) {
    await lines.createManual(
      PlanLineInput(
        planId: _planId,
        ym: next.addMonths(i),
        kind: TxnKind.expense,
        amount: 30000,
        accountId: cash,
        categoryId: food,
      ),
    );
  }
}

void main() {
  testWidgets('プラン詳細：計画線の寿命時の総資産と資金不足、ホームのカードにも出る', (tester) async {
    final db = await startApp(tester, prepare: _prepare);
    final shortage = YearMonth.ofDate(clock.now()).addMonths(4);

    // ホームのカード
    expect(
      tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(Key('card-shortage-$_planId')),
                  matching: find.byType(Text),
                )
                .last,
          )
          .data,
      '${shortage.year}年${shortage.month}月〜',
    );
    expect(find.text('−¥80,000'), findsWidgets);

    await tester.tap(find.text('プランA').last);
    await settle(tester);
    expect(find.byKey(const Key('plan-asset-chart')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('lifetime-total')),
        matching: find.text('−¥80,000'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('資金不足：計画線で ${shortage.year}年${shortage.month}月'),
      findsOneWidget,
    );

    // 月単位に切り替えられる
    await tester.tap(find.text('月単位'));
    await settle(tester);
    expect(
      find.textContaining('資産推移（${clock.now().year}年・月末）'),
      findsOneWidget,
    );

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('メニューから複製と削除、引き継いで作成', (tester) async {
    final db = await startApp(tester, prepare: _prepare);

    await tester.tap(find.byKey(const Key('plan-menu-プランA')));
    await settle(tester);
    await tester.tap(find.text('複製（今日を起点に計算し直す）'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('plan-name-ok')));
    await settle(tester);
    expect(find.text('プランA（複製）'), findsWidgets);
    final copied = await tester.runAsync(
      () => (db.select(
        db.planLines,
      )..where((l) => l.planId.isNotValue(_planId))).get(),
    );
    expect(copied, hasLength(6));

    // 引き継いで作成
    await tester.ensureVisible(find.byKey(const Key('plan-create')));
    await tester.tap(find.byKey(const Key('plan-create')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('plan-name')), 'プランC');
    await tester.tap(find.byKey(const Key('protagonist-birth')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '1990/01/01');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('plan-inherit')));
    await settle(tester);
    await tester.tap(find.text('「プランA」から引き継ぐ').last);
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('plan-create-save')));
    await tester.tap(find.byKey(const Key('plan-create-save')));
    await settle(tester);
    final c = await tester.runAsync(
      () => (db.select(
        db.plans,
      )..where((p) => p.name.equals('プランC'))).getSingle(),
    );
    final txns = await tester.runAsync(
      () => (db.select(db.txns)..where((t) => t.planId.equals(c!.id))).get(),
    );
    expect(txns, hasLength(1));

    // 複製を削除
    await tester.tap(find.byKey(const Key('plan-menu-プランA（複製）')));
    await settle(tester);
    await tester.tap(find.text('削除（配下のデータごと）'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('plan-delete-confirm')));
    await settle(tester);
    expect(find.text('プランA（複製）'), findsNothing);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
