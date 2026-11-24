import 'dart:convert';

import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/asset_repository.dart';
import 'package:butterfly_lp/data/repositories/master_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/data/share/plan_share.dart';
import 'package:butterfly_lp/data/share/share_link.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers.dart';

void main() {
  late AppDatabase a; // 渡す側
  late AppDatabase b; // 受け取る側
  const sa = Stamp('device-a');
  const sb = Stamp('device-b');
  late String planId;
  late String cash;
  late String food;

  Future<String> txn(String date, int amount, {String? plan}) =>
      TxnRepository(a, sa).createTxn(
        TxnInput(
          planId: plan ?? planId,
          date: date,
          kind: TxnKind.expense,
          amount: amount,
          accountId: cash,
          categoryId: food,
        ),
      );

  Future<List<TxnRow>> liveTxns(AppDatabase db) =>
      (db.select(db.txns)..where((t) => t.deletedAt.isNull())).get();

  setUp(() async {
    a = memoryDb();
    b = memoryDb();
    planId = await PlanRepository(a, sa).createPlan(
      const NewPlanInput(
        name: '我が家',
        startYear: 2026,
        protagonistName: '本人',
        protagonistBirthDate: '1990-01-01',
        protagonistLifeExpectancy: 90,
        createCashAccount: true,
      ),
    );
    cash = (await a.select(a.accounts).getSingle()).id;
    food = (await (a.select(
      a.categories,
    )..where((c) => c.name.equals('食費'))).getSingle()).id;
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  test('共有の中身：プランと配下・カテゴリ・口座。ほかのプランと墓石は入れない', () async {
    final other = await PlanRepository(a, sa).createPlan(
      const NewPlanInput(
        name: '別',
        startYear: 2026,
        protagonistName: '別人',
        protagonistBirthDate: '1990-01-01',
        protagonistLifeExpectancy: 90,
      ),
    );
    await txn('2026-10-01', 100);
    final gone = await txn('2026-10-02', 200);
    await TxnRepository(a, sa).deleteTxn(gone);
    await txn('2026-10-03', 300, plan: other);
    final assetCat = (await (a.select(
      a.categories,
    )..where((c) => c.kind.equals('asset'))).get()).first.id;
    final asset = await AssetRepository(a, sa).createAsset(
      AssetInput(
        planId: planId,
        name: '自宅',
        categoryId: assetCat,
        valuation: Valuation.value,
      ),
    );
    await AssetRepository(a, sa).setValue(asset, 'month', '2026-10', 100);

    final s = await buildPlanShare(a, planId);
    expect(s.planName, '我が家');
    expect(s.count('plan'), 1);
    expect(s.count('family_member'), 1);
    expect(s.tables['txn']!.map((r) => r['amount']), [100]);
    expect(s.count('asset'), 1);
    expect(s.count('asset_value'), 1);
    expect(s.count('category'), greaterThan(5));
    expect(s.count('account'), 1);
    final back = PlanShare.fromBytes(s.toBytes());
    expect(back.planId, planId);
    expect(back.tables['txn']!.single['id'], s.tables['txn']!.single['id']);
  });

  test('受け取る：なければ同じIDで作り、あれば上書きして共有にない行を消す', () async {
    final t1 = await txn('2026-10-01', 100);
    final t2 = await txn('2026-10-02', 200);
    final r1 = await applyPlanShare(b, sb, await buildPlanShare(a, planId));
    expect(r1.overwritten, isFalse);
    expect((await b.select(b.plans).getSingle()).id, planId);
    expect((await liveTxns(b)).map((t) => t.id).toSet(), {t1, t2});
    // 受け取った端末で更新したものとして印を付け直す（同期で家族に伝わる）
    expect((await liveTxns(b)).first.updatedBy, 'device-b');

    // 渡す側で1件消して1件足し、金額も直してから共有し直す
    await TxnRepository(a, sa).deleteTxn(t1);
    final t3 = await txn('2026-10-05', 500);
    await (a.update(a.txns)..where((t) => t.id.equals(t2))).write(
      const TxnsCompanion(amount: Value(250)),
    );
    // 受け取る側だけにある実績も、このプランのものなら消える
    final onlyB = await TxnRepository(b, sb).createTxn(
      TxnInput(
        planId: planId,
        date: '2026-10-09',
        kind: TxnKind.expense,
        amount: 9,
        accountId: cash,
        categoryId: food,
      ),
    );
    final r2 = await applyPlanShare(b, sb, await buildPlanShare(a, planId));
    expect(r2.overwritten, isTrue);
    expect(r2.removed, 2);
    final live = await liveTxns(b);
    expect(live.map((t) => (t.id, t.amount)).toSet(), {(t2, 250), (t3, 500)});
    final tomb = await (b.select(
      b.txns,
    )..where((t) => t.id.isIn([t1, onlyB]))).get();
    expect(tomb.every((t) => t.deletedAt != null), isTrue);
  });

  test('カテゴリなど共通のものは後勝ち（古い共有で新しい変更を戻さない）・削除しない', () async {
    await txn('2026-10-01', 100);
    final share = await buildPlanShare(a, planId);
    await applyPlanShare(b, sb, share);
    // 受け取る側で後から名前を変え、カテゴリを1つ足す
    final cat = await (b.select(
      b.categories,
    )..where((c) => c.id.equals(food))).getSingle();
    await MasterRepository(b, sb).updateCategory(
      food,
      CategoryInput(
        name: '食費（家族）',
        kind: CategoryKind.expense,
        color: cat.color,
      ),
    );
    final extra = await MasterRepository(b, sb).createCategory(
      const CategoryInput(
        name: '受け取り側だけ',
        kind: CategoryKind.expense,
        color: '#000000',
      ),
    );
    await applyPlanShare(b, sb, share);
    final cats = {for (final c in await b.select(b.categories).get()) c.id: c};
    expect(cats[food]!.name, '食費（家族）');
    expect(cats[extra]!.deletedAt, isNull);
  });

  group('リンクとサーバー', () {
    test('URL を作って読み戻す（鍵は # 以降）', () {
      final link = ShareLink(
        server: Uri.parse('https://lp.example.com/app'),
        id: 'AbCdEfGhIjKlMnOpQrStUv',
        key: List.generate(32, (i) => i),
      );
      final url = link.url.toString();
      expect(
        url,
        startsWith(
          'https://lp.example.com/app#/share/AbCdEfGhIjKlMnOpQrStUv?k=',
        ),
      );
      final back = ShareLink.parse(url)!;
      expect(back.server.toString(), 'https://lp.example.com/app/');
      expect(back.key, link.key);
      expect(
        back.apiUrl.toString(),
        'https://lp.example.com/app/api/share/AbCdEfGhIjKlMnOpQrStUv',
      );
      expect(ShareLink.parse('https://example.com/#/home'), isNull);
      expect(ShareLink.parse('not a url'), isNull);
    });

    test('置いて受け取ると元に戻る。サーバーには暗号文しか届かない', () async {
      final store = <String, List<int>>{};
      final mock = MockClient((req) async {
        if (req.method == 'POST') {
          store['AAAAAAAAAAAAAAAAAAAAAA'] = req.bodyBytes;
          return http.Response(
            jsonEncode({'id': 'AAAAAAAAAAAAAAAAAAAAAA'}),
            201,
          );
        }
        final body = store[req.url.pathSegments.last];
        return body == null
            ? http.Response('', 404)
            : http.Response.bytes(body, 200);
      });
      final client = ShareClient(client: mock);
      final plain = utf8.encode('{"秘密": "家計簿"}');
      final link = await client.upload(Uri.parse('http://home:8080'), plain);
      expect(link.server.toString(), 'http://home:8080/');
      expect(
        utf8.decode(store.values.single, allowMalformed: true),
        isNot(contains('家計簿')),
      );
      expect(await client.download(link), plain);
      // 鍵が違えば復号できない
      final wrong = ShareLink(
        server: link.server,
        id: link.id,
        key: List.filled(32, 7),
      );
      await expectLater(client.download(wrong), throwsA(isA<ShareException>()));
      store.clear();
      await expectLater(client.download(link), throwsA(isA<ShareException>()));
    });
  });
}
