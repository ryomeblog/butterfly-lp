import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/event_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_helpers.dart';

late String _planId;
late String _cash;
late String _memberId;

Future<String> _cat(AppDatabase db, String name) async => (await (db.select(
  db.categories,
)..where((c) => c.name.equals(name))).getSingle()).id;

Future<void> _plan(AppDatabase db, String deviceId) async {
  final repo = PlanRepository(db, Stamp(deviceId));
  _planId = await repo.createPlan(
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
  _memberId = (await repo.getPlan(_planId))!.protagonistMemberId;
}

/// 2030年3月の「住宅購入」（頭金 5,000,000・諸費用 300,000）。
Future<void> _withEvent(AppDatabase db, String deviceId) async {
  await _plan(db, deviceId);
  await EventRepository(db, Stamp(deviceId)).saveEvent(
    input: EventInput(
      planId: _planId,
      memberId: _memberId,
      title: '住宅購入',
      year: 2030,
      month: 3,
    ),
    lines: [
      EventLineDraft(
        id: 'l1',
        kind: TxnKind.expense,
        amount: 5000000,
        accountId: _cash,
        categoryId: await _cat(db, '住居費'),
        memo: '頭金',
      ),
      EventLineDraft(
        id: 'l2',
        kind: TxnKind.expense,
        amount: 300000,
        accountId: _cash,
        categoryId: await _cat(db, 'その他'),
        memo: '諸費用',
      ),
    ],
  );
}

Future<void> _pick(WidgetTester tester, Key field, String item) async {
  await tester.ensureVisible(find.byKey(field));
  await tester.tap(find.byKey(field));
  await settle(tester);
  await tester.tap(find.text(item).last);
  await settle(tester);
}

void main() {
  testWidgets('年齢で時期を決めてイベントを作り、予定の収支を入れる', (tester) async {
    final db = await startApp(tester, prepare: _plan);
    await tester.tap(find.text('イベント'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('event-add')));
    await settle(tester);

    await tester.enterText(find.byKey(const Key('event-title')), '退職');
    await tester.tap(find.text('年齢'));
    await settle(tester);
    await _pick(tester, const Key('event-age'), '38歳');
    expect(find.textContaining('保存する時期：2028年'), findsOneWidget);

    await tester.tap(find.byKey(const Key('event-line-add')));
    await settle(tester);
    await _pick(tester, const Key('line-type'), '収入');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('line-amount')),
        matching: find.byType(EditableText),
      ),
      '20000000',
    );
    await _pick(tester, const Key('line-category'), '退職所得');
    await _pick(tester, const Key('line-account'), '現金');
    await tester.tap(find.byKey(const Key('line-ok')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('event-save')));
    await settle(tester);

    expect(find.byKey(const Key('event-退職')), findsOneWidget);
    expect(find.textContaining('本人 38歳'), findsOneWidget);
    expect(find.text('予定 +¥20,000,000'), findsOneWidget);
    final line = await tester.runAsync(
      () => db.select(db.planLines).getSingle(),
    );
    expect((line!.source, line.year, line.amount), ('event', 2028, 20000000));

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('実績を入力：予定の金額が入っていて、直した項目だけ変わり、実施済みになる', (tester) async {
    final db = await startApp(tester, prepare: _withEvent);
    await tester.tap(find.text('イベント'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('event-住宅購入')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('event-actual')));
    await settle(tester);

    // 頭金は予定どおり、諸費用は空にする（実績にしない）
    expect(find.text('5000000'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('actual-諸費用')), '');
    await tester.tap(find.byKey(const Key('actual-save')));
    await settle(tester);

    final txns = await tester.runAsync(() => db.select(db.txns).get());
    expect(txns!.single.amount, 5000000);
    expect(txns.single.date, '2030-03-01');
    expect(find.text('実施済み'), findsWidgets);
    expect(find.text('¥5,000,000'), findsWidgets);

    // もう一度開くと、入力済みの頭金は空、諸費用だけ予定額が入っている
    await tester.tap(find.byKey(const Key('event-actual')));
    await settle(tester);
    expect(find.text('5000000'), findsNothing);
    expect(find.text('300000'), findsOneWidget);
    expect(find.textContaining('入力済み ¥5,000,000'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('イベントを削除すると予定は消え、実績は残る', (tester) async {
    final db = await startApp(
      tester,
      prepare: (db, d) async {
        await _withEvent(db, d);
        final repo = EventRepository(db, Stamp(d));
        final e = (await db.select(db.planEvents).getSingle());
        await repo.recordActual(
          event: e,
          doneDate: '2030-03-10',
          items: [
            EventActualItem(
              kind: TxnKind.expense,
              amount: 4000000,
              accountId: _cash,
              categoryId: await _cat(db, '住居費'),
            ),
          ],
          markDone: true,
        );
      },
    );
    await tester.tap(find.text('イベント'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('event-住宅購入')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('event-delete')));
    await tester.tap(find.byKey(const Key('event-delete')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('event-delete-confirm')));
    await settle(tester);

    expect(find.text('イベントはありません'), findsOneWidget);
    final t = await tester.runAsync(() => db.select(db.txns).getSingle());
    expect((t!.deletedAt, t.eventId), (null, null));

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('家計簿の予定の入力でイベントを指定できる', (tester) async {
    final db = await startApp(tester, prepare: _withEvent);
    await tester.tap(find.text('家計簿'));
    await settle(tester);
    await tester.tap(find.text('予定'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('txn-add')));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('txn-amount')),
        matching: find.byType(EditableText),
      ),
      '100000',
    );
    await _pick(tester, const Key('txn-category'), '耐久消耗品');
    await _pick(tester, const Key('event-picker'), '住宅購入（2030年3月）');
    await tester.tap(find.byKey(const Key('txn-save')));
    await settle(tester);

    final manual = await tester.runAsync(
      () => (db.select(
        db.planLines,
      )..where((l) => l.source.equals('manual'))).getSingle(),
    );
    final e = await tester.runAsync(() => db.select(db.planEvents).getSingle());
    expect(manual!.eventId, e!.id);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
