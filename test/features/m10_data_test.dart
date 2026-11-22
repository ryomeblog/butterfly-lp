import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../widget_helpers.dart';

late String _planId;

Future<void> _plan(AppDatabase db, String deviceId) async {
  _planId = await PlanRepository(db, Stamp(deviceId)).createPlan(
    const NewPlanInput(
      name: 'プランA',
      startYear: 2026,
      protagonistName: '本人',
      protagonistBirthDate: '1990-01-01',
      protagonistLifeExpectancy: 90,
      createCashAccount: true,
    ),
  );
}

Map<String, dynamic> _file() => {
  'format': 'lifeplan-data',
  'version': 1,
  'actuals': [
    {
      'id': 'a1',
      'plan': {'id': _planId, 'name': 'プランA'},
      'date': '2026-11-25',
      'kind': 'income',
      'amount': 300000,
      'category': {
        'id': 'c-new',
        'name': 'ボーナス',
        'kind': 'income',
        'color': '#1D4ED8',
      },
      'account': {'name': '現金'},
    },
    {
      'id': 'a2',
      'date': '2026-11-26',
      'kind': 'expense',
      'amount': 'abc',
      'category': {'name': '食費'},
      'account': {'name': '現金'},
    },
  ],
};

void main() {
  testWidgets('JSONの取り込み：件数・新しく作るもの・取り込めない行を確かめてから取り込む', (tester) async {
    final db = await startApp(tester, prepare: _plan);
    GoRouter.of(tester.element(find.text('ホーム').first))
        .push('/entry/json-import', extra: (name: 'test.json', json: _file()));
    await settle(tester, rounds: 12);

    expect(find.textContaining('実績：新しく追加 1件・上書き（同じUUID） 0件'), findsOneWidget);
    expect(find.text('・カテゴリ「ボーナス」'), findsOneWidget);
    expect(find.textContaining('金額が数値でない（実績 2行目）'), findsOneWidget);
    expect(find.textContaining('プランA・ファイル内と同じプラン'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.txns).get()), isEmpty);

    await tester.tap(find.byKey(const Key('import-apply')));
    await settle(tester, rounds: 12);
    final t = await tester.runAsync(() => db.select(db.txns).getSingle());
    expect((t!.id, t.planId, t.amount), ('a1', _planId, 300000));

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('このアプリのJSONでなければ取り込まない', (tester) async {
    final db = await startApp(tester, prepare: _plan);
    GoRouter.of(tester.element(find.text('ホーム').first)).push(
      '/entry/json-import',
      extra: (name: 'x.json', json: <String, dynamic>{'foo': 1}),
    );
    await settle(tester, rounds: 12);
    expect(find.byKey(const Key('import-error')), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('設定からデータ管理を開き、書き出す単位を切り替えられる', (tester) async {
    final db = await startApp(tester, prepare: _plan);
    await tester.tap(find.text('設定'));
    await settle(tester);
    await tester.tap(find.text('データ管理'));
    await settle(tester);
    expect(find.text('バックアップを書き出す'), findsOneWidget);
    await tester.tap(find.byKey(const Key('json-unit')));
    await settle(tester);
    await tester.tap(find.text('ライフプラン').last);
    await settle(tester);
    expect(find.textContaining('家族・イベント・率・グループの登録'), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
