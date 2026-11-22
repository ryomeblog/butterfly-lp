import 'dart:convert';

import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/master_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/data/sync/resp_client.dart';
import 'package:butterfly_lp/data/sync/snapshot.dart';
import 'package:butterfly_lp/data/sync/sync_crypto.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('RESP', () {
    test('コマンドはバルク文字列の配列（値はバイト列のまま）', () {
      final b = encodeCommand([
        'SET',
        'k',
        [0, 255, 13, 10],
        'EX',
        '86400',
      ]);
      expect(
        latin1.decode(b),
        '*5\r\n\$3\r\nSET\r\n\$1\r\nk\r\n\$4\r\n\x00\xff\r\n\r\n\$2\r\nEX\r\n\$5\r\n86400\r\n',
      );
    });

    test('応答の読み出し：分割して届いても読める', () {
      final p = RespParser();
      p.add(latin1.encode('+OK\r\n\$4\r\nab'));
      expect(p.next()!.value, 'OK');
      expect(p.next(), isNull); // バルク文字列の途中
      p.add(
        latin1.encode(
          '\r\n\r\n*2\r\n\$1\r\n0\r\n*1\r\n\$3\r\nkey\r\n\$-1\r\n-ERR bad\r\n:7\r\n',
        ),
      );
      expect(p.next()!.value, Uint8List.fromList([97, 98, 13, 10]));
      final arr = p.next()!.value as List;
      expect(utf8.decode(arr[0] as Uint8List), '0');
      expect(utf8.decode((arr[1] as List).single as Uint8List), 'key');
      expect(p.next()!.value, isNull);
      expect(p.next()!.value, isA<RedisError>());
      expect(p.next()!.value, 7);
    });
  });

  group('暗号化（5.1）', () {
    test('グループIDは合言葉のSHA-256の16進で、同じ合言葉なら同じ', () async {
      final a = await SyncCrypto.groupIdOf('ひみつ');
      expect(a, hasLength(64));
      expect(await SyncCrypto.groupIdOf('ひみつ'), a);
      expect(await SyncCrypto.groupIdOf('ひみつ2'), isNot(a));
    });

    test('暗号化して復号すると元に戻り、別の鍵では復号できない', () async {
      final key = await SyncCrypto.deriveKey('ひみつ', iterations: 1000);
      final other = await SyncCrypto.deriveKey('ちがう', iterations: 1000);
      expect(key, hasLength(32));
      final plain = utf8.encode('{"a":"家計簿"}' * 100);
      final enc = await SyncCrypto.encrypt(plain, key);
      expect(enc.length, lessThan(plain.length)); // gzip で小さくなる
      expect(await SyncCrypto.decrypt(enc, key), plain);
      expect(() => SyncCrypto.decrypt(enc, other), throwsA(anything));
    });

    test('鍵の導出は20万回（本番の回数で動く）', () async {
      final key = await SyncCrypto.deriveKey('ひみつ');
      expect(key, hasLength(32));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('マージ（5.3）', () {
    late AppDatabase a;
    late AppDatabase b;
    setUp(() {
      a = memoryDb();
      b = memoryDb();
    });
    tearDown(() async {
      await a.close();
      await b.close();
    });

    const input = NewPlanInput(
      name: 'A',
      startYear: 2026,
      protagonistName: '本人',
      protagonistBirthDate: '1990-01-01',
      protagonistLifeExpectancy: 90,
      createCashAccount: true,
    );

    Future<T> at<T>(String ts, Future<T> Function() f) =>
        withClock(Clock.fixed(DateTime.parse(ts)), f);

    test('相手の行を取り込み、新しい方を採用する（同時刻は端末IDの大きい方）', () async {
      final planId = await at(
        '2026-11-01T00:00:00Z',
        () => PlanRepository(a, const Stamp('dev-a')).createPlan(input),
      );
      final snapA = await buildSnapshot(a, 'dev-a');
      final n = await mergeSnapshot(b, Snapshot.fromBytes(snapA.toBytes()));
      expect(n, greaterThan(0));
      expect(
        (await (b.select(
          b.plans,
        )..where((p) => p.id.equals(planId))).getSingle()).name,
        'A',
      );

      // B で名前を変える（新しい）→ A へマージすると B の名前になる
      await at('2026-11-02T00:00:00Z', () async {
        await (b.update(b.plans)..where((p) => p.id.equals(planId))).write(
          const PlansCompanion(
            name: Value('Bで変更'),
            updatedAt: Value('2026-11-02T00:00:00.000Z'),
            updatedBy: Value('dev-b'),
          ),
        );
      });
      await mergeSnapshot(a, await buildSnapshot(b, 'dev-b'));
      expect(
        (await (a.select(
          a.plans,
        )..where((p) => p.id.equals(planId))).getSingle()).name,
        'Bで変更',
      );

      // 古い変更は採用しない
      await (b.update(b.plans)..where((p) => p.id.equals(planId))).write(
        const PlansCompanion(
          name: Value('古い'),
          updatedAt: Value('2026-10-01T00:00:00.000Z'),
          updatedBy: Value('dev-z'),
        ),
      );
      expect(await mergeSnapshot(a, await buildSnapshot(b, 'dev-b')), 0);
      expect(
        (await (a.select(
          a.plans,
        )..where((p) => p.id.equals(planId))).getSingle()).name,
        'Bで変更',
      );

      // 同時刻は updated_by の大きい方
      Future<void> setName(AppDatabase db, String name, String by) =>
          (db.update(db.plans)..where((p) => p.id.equals(planId))).write(
            PlansCompanion(
              name: Value(name),
              updatedAt: const Value('2026-11-05T00:00:00.000Z'),
              updatedBy: Value(by),
            ),
          );
      await setName(a, 'aの名前', 'dev-a');
      await setName(b, 'bの名前', 'dev-b');
      await mergeSnapshot(a, await buildSnapshot(b, 'dev-b'));
      await mergeSnapshot(b, await buildSnapshot(a, 'dev-a'));
      for (final db in [a, b]) {
        expect(
          (await (db.select(
            db.plans,
          )..where((p) => p.id.equals(planId))).getSingle()).name,
          'bの名前',
        );
      }
    });

    test('墓石も伝わり、初期カテゴリは重複しない', () async {
      final planId = await PlanRepository(
        a,
        const Stamp('dev-a'),
      ).createPlan(input);
      final cash = (await a.select(a.accounts).getSingle()).id;
      final txn = await TxnRepository(a, const Stamp('dev-a')).createTxn(
        TxnInput(
          planId: planId,
          date: '2026-11-01',
          kind: TxnKind.expense,
          amount: 100,
          accountId: cash,
          categoryId: 'x',
        ),
      );
      await mergeSnapshot(b, await buildSnapshot(a, 'dev-a'));
      expect(await b.select(b.categories).get(), hasLength(23));

      await withClock(
        Clock.fixed(DateTime.utc(2030)),
        () => TxnRepository(a, const Stamp('dev-a')).deleteTxn(txn),
      );
      await mergeSnapshot(b, await buildSnapshot(a, 'dev-a'));
      final t = await (b.select(
        b.txns,
      )..where((t) => t.id.equals(txn))).getSingle();
      expect(t.deletedAt, isNotNull);
    });

    test('参照切れの件数：他端末で削除されたカテゴリを使った行', () async {
      final planId = await PlanRepository(
        a,
        const Stamp('dev-a'),
      ).createPlan(input);
      final cash = (await a.select(a.accounts).getSingle()).id;
      final cat = await MasterRepository(a, const Stamp('dev-a'))
          .createCategory(
            const CategoryInput(
              name: '新',
              kind: CategoryKind.expense,
              color: '#4E79A7',
            ),
          );
      await mergeSnapshot(b, await buildSnapshot(a, 'dev-a'));
      // B でそのカテゴリを使い、A では削除
      await TxnRepository(b, const Stamp('dev-b')).createTxn(
        TxnInput(
          planId: planId,
          date: '2026-11-01',
          kind: TxnKind.expense,
          amount: 1,
          accountId: cash,
          categoryId: cat,
        ),
      );
      await withClock(
        Clock.fixed(DateTime.utc(2030)),
        () => MasterRepository(
          a,
          const Stamp('dev-a'),
        ).deleteCategoryWithHistory(cat),
      );
      await mergeSnapshot(b, await buildSnapshot(a, 'dev-a'));
      expect(await countBrokenReferences(b), 1);
    });
  });
}
