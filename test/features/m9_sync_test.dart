import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/fake_redis.dart';
import '../widget_helpers.dart';

Future<void> _plan(AppDatabase db, String deviceId) async {
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
}

Future<void> _openSync(WidgetTester tester) async {
  await tester.tap(find.text('設定'));
  await settle(tester);
  await tester.tap(find.text('同期'));
  await settle(tester);
}

void main() {
  testWidgets('設定がないと、何が足りないかを出す', (tester) async {
    final db = await startApp(tester, prepare: _plan);
    await _openSync(tester);
    await tester.tap(find.byKey(const Key('sync-now')));
    await settle(tester);
    expect(find.byKey(const Key('sync-error')), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('接続先と合言葉を入れて同期すると、結果と最終同期日時が出る', (tester) async {
    final redis = (await tester.runAsync(
      () => FakeRedis.start(password: 'pw'),
    ))!;
    final db = await startApp(tester, prepare: _plan);
    await _openSync(tester);

    await tester.enterText(find.byKey(const Key('sync-host')), '127.0.0.1');
    await tester.enterText(find.byKey(const Key('sync-port')), '${redis.port}');
    await tester.enterText(find.byKey(const Key('sync-password')), 'pw');
    await tester.enterText(
      find.byKey(const Key('sync-passphrase')),
      'かぞくのあいことば',
    );
    await tester.ensureVisible(find.byKey(const Key('sync-passphrase-save')));
    await tester.tap(find.byKey(const Key('sync-passphrase-save')));
    await settle(tester, rounds: 60);
    expect(find.text('登録済み'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('sync-now')));
    await tester.tap(find.byKey(const Key('sync-now')));
    await settle(tester, rounds: 40);
    expect(find.byKey(const Key('sync-error')), findsNothing);
    expect(find.text('取り込んだ端末　0台'), findsOneWidget);
    expect(redis.data.keys.single, startsWith('lp:'));

    final s = await tester.runAsync(
      () => db.select(db.deviceSettings).getSingle(),
    );
    expect(
      (s!.redisHost, s.redisPort, s.lastSyncAt != null),
      ('127.0.0.1', redis.port, true),
    );

    await stopApp(tester, db);
    await tester.runAsync(redis.close);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
