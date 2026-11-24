import 'dart:convert';

import 'package:butterfly_lp/app/providers.dart';
import 'package:butterfly_lp/data/repositories/device_pref_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/data/share/plan_share.dart';
import 'package:butterfly_lp/data/share/share_link.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../widget_helpers.dart';

const _id = 'AAAAAAAAAAAAAAAAAAAAAA';

void main() {
  testWidgets('受け取る：同じプランなら上書きの注意を出し、共有にない実績を消す', (tester) async {
    final store = <String, List<int>>{};
    final client = ShareClient(
      client: MockClient((req) async {
        if (req.method == 'POST') {
          store[_id] = req.bodyBytes;
          return http.Response(jsonEncode({'id': _id}), 201);
        }
        final b = store[req.url.pathSegments.last];
        return b == null ? http.Response('', 404) : http.Response.bytes(b, 200);
      }),
    );
    late ShareLink link;
    late String extraTxn;
    final db = await startApp(
      tester,
      overrides: [shareClientProvider.overrideWithValue(client)],
      prepare: (db, deviceId) async {
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
        final share = await buildPlanShare(db, planId);
        link = await client.upload(
          Uri.parse('http://home:8080/'),
          share.toBytes(),
        );
        // 共有したあとに足した実績（上書きで消える）
        extraTxn = await TxnRepository(db, stamp).createTxn(
          TxnInput(
            planId: planId,
            date: '2026-10-01',
            kind: TxnKind.expense,
            amount: 100,
            accountId: (await db.select(db.accounts).getSingle()).id,
          ),
        );
      },
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push('/share/$_id', extra: link);
    await settle(tester);
    expect(find.text('プランA'), findsWidgets);
    expect(find.textContaining('（同じプラン）を上書きします'), findsOneWidget);
    expect(find.text('上書きする'), findsOneWidget);
    await tester.tap(find.byKey(const Key('share-apply')));
    await settle(tester);
    final t = (await tester.runAsync(
      () =>
          (db.select(db.txns)..where((x) => x.id.equals(extraTxn))).getSingle(),
    ))!;
    expect(t.deletedAt, isNotNull);
    expect(find.text('「プランA」を上書きしました（共有になかった1件を削除）'), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('鍵のない URL・期限切れは分かる言葉で知らせる', (tester) async {
    final client = ShareClient(
      client: MockClient((req) async => http.Response('', 404)),
    );
    final db = await startApp(
      tester,
      overrides: [shareClientProvider.overrideWithValue(client)],
    );
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.push('/share/$_id');
    await settle(tester);
    expect(find.text('共有のURLが正しくありません'), findsOneWidget);
    router.pop();
    await settle(tester);
    router.push(
      '/share/$_id',
      extra: ShareLink(
        server: Uri.parse('http://home/'),
        id: _id,
        key: List.filled(32, 1),
      ),
    );
    await settle(tester);
    expect(find.textContaining('24時間を過ぎて消えた'), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('共有する：カードのメニューから置いてQRを出し、閉じるとホームに戻る', (tester) async {
    final store = <String, List<int>>{};
    final client = ShareClient(
      client: MockClient((req) async {
        store[_id] = req.bodyBytes;
        return http.Response(jsonEncode({'id': _id}), 201);
      }),
    );
    final db = await startApp(
      tester,
      overrides: [shareClientProvider.overrideWithValue(client)],
      prepare: (db, deviceId) async {
        await PlanRepository(db, Stamp(deviceId)).createPlan(
          const NewPlanInput(
            name: 'プランA',
            startYear: 2026,
            protagonistName: '本人',
            protagonistBirthDate: '1990-01-01',
            protagonistLifeExpectancy: 90,
          ),
        );
        await DevicePrefRepository(db)
            .set(DevicePrefRepository.shareServer, 'http://home:8080/');
      },
    );
    await tester.tap(find.byKey(const Key('plan-menu-プランA')));
    await settle(tester);
    await tester.tap(find.text('QRで共有（24時間）'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('share-start')));
    await settle(tester);
    expect(store, hasLength(1));
    expect(find.byKey(const Key('share-qr')), findsOneWidget);
    expect(
      find.text('http://home:8080/#/share/$_id?k=').evaluate().isEmpty,
      isTrue,
    );
    expect(
      find.textContaining('http://home:8080/#/share/$_id?k='),
      findsOneWidget,
    );
    await tester.tap(find.text('閉じる'));
    await settle(tester);
    expect(find.byKey(const Key('plan-menu-プランA')), findsOneWidget);
    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
