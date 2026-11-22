// 同期の通しのテスト。ふだんはテスト用の Redis 互換サーバー（fake_redis.dart）で動く。
// 実際の Redis で確かめるときは、環境変数 REDIS_TEST_PORT（と REDIS_TEST_PASSWORD）を渡す。
//
//   docker run -d --rm --name lp-redis -p 6390:6379 redis:7 redis-server --requirepass testpass
//   REDIS_TEST_PORT=6390 REDIS_TEST_PASSWORD=testpass flutter test test/data/sync_redis_test.dart
import 'dart:io';

import 'package:butterfly_lp/core/ids.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/device_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/sync/resp_client.dart';
import 'package:butterfly_lp/data/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'fake_redis.dart';

void main() {
  final realPort = int.tryParse(Platform.environment['REDIS_TEST_PORT'] ?? '');
  FakeRedis? fake;
  late int port;
  late String? password;

  setUpAll(() async {
    if (realPort != null) {
      port = realPort;
      password = Platform.environment['REDIS_TEST_PASSWORD'];
    } else {
      fake = await FakeRedis.start(password: 'testpass');
      port = fake!.port;
      password = 'testpass';
    }
  });
  tearDownAll(() async => fake?.close());

  test('2台の端末が自宅Redisを通して同期する', () async {
    // 合言葉は毎回変える（前回のキャッシュと混ざらないように）
    final passphrase = 'テスト-${newId()}';
    Future<(AppDatabase, SyncService)> device() async {
      final db = memoryDb();
      final d = await DeviceRepository(db).ensure();
      final s = SyncService(db, MemorySecretStore(), d.deviceId);
      await s.setConnection(host: '127.0.0.1', port: port, password: password);
      await s.setPassphrase(passphrase);
      return (db, s);
    }

    final (a, sa) = await device();
    final (b, sb) = await device();
    final planId = await PlanRepository(a, Stamp(sa.deviceId)).createPlan(
      const NewPlanInput(
        name: '家族のプラン',
        startYear: 2026,
        protagonistName: '本人',
        protagonistBirthDate: '1990-01-01',
        protagonistLifeExpectancy: 90,
      ),
    );

    // A が書き込む（まだ他端末はいない）
    final r1 = await sa.sync();
    expect(r1.devices, 0);
    // B が A の分を取り込む
    final r2 = await sb.sync();
    expect(r2.devices, 1);
    expect(r2.adopted, greaterThan(0));
    expect(
      (await PlanRepository(b, Stamp(sb.deviceId)).getPlan(planId))!.name,
      '家族のプラン',
    );
    expect(
      (await b.select(b.deviceSettings).getSingle()).lastSyncAt,
      isNotNull,
    );

    // 合言葉の違う端末は復号できず、無視する
    final (c, sc) = await device();
    await sc.setPassphrase('${passphrase}x');
    final r3 = await sc.sync();
    expect(r3.devices, 0);

    // 有効期限は1日
    final client = await RespClient.connect('127.0.0.1', port);
    if (password != null) await client.auth(password!);
    final keys = await client.scanAll('lp:*:snap:${sa.deviceId}');
    expect(keys, hasLength(1));
    final ttl = await client.command(['TTL', keys.single]) as int;
    expect(ttl, inInclusiveRange(86000, 86400));
    await client.close();

    for (final db in [a, b, c]) {
      await db.close();
    }
  });

  test('パスワードが違うと接続で失敗する', () async {
    final db = memoryDb();
    final d = await DeviceRepository(db).ensure();
    final s = SyncService(db, MemorySecretStore(), d.deviceId);
    await s.setConnection(host: '127.0.0.1', port: port, password: 'wrong');
    await s.setPassphrase('x');
    await expectLater(s.sync(), throwsA(isA<RedisError>()));
    await db.close();
  });
}
