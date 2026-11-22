import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/asset_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_helpers.dart';

late String _planId;
late String _cash;
late String _assetId;

Future<String> _cat(AppDatabase db, String name) async => (await (db.select(
  db.categories,
)..where((c) => c.name.equals(name))).getSingle()).id;

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
  _cash = (await db.select(db.accounts).getSingle()).id;
}

/// 株式の資産を10口（10,000円）買ってあり、今月の単価が1,500円。
Future<void> _withStock(AppDatabase db, String deviceId) async {
  await _plan(db, deviceId);
  final repo = AssetRepository(db, Stamp(deviceId));
  _assetId = await repo.createAsset(
    AssetInput(
      planId: _planId,
      name: '銘柄A',
      categoryId: await _cat(db, '株式・投資信託'),
      valuation: Valuation.quantity,
      accountId: _cash,
    ),
  );
  final today = todayString();
  await repo.recordFlow(
    AssetFlowInput(
      planId: _planId,
      assetId: _assetId,
      action: AssetAction.buy,
      amount: 10000,
      quantityX1e4: 100000,
      accountId: _cash,
      categoryId: await _cat(db, 'その他'),
      date: today,
    ),
  );
  await repo.setValue(_assetId, 'day', today, 150000);
}

Future<void> _pick(WidgetTester tester, Key field, String item) async {
  await tester.ensureVisible(find.byKey(field));
  await tester.tap(find.byKey(field));
  await settle(tester);
  await tester.tap(find.text(item).last);
  await settle(tester);
}

void main() {
  testWidgets('資産を追加し、価値を入れて、金額指定で購入する', (tester) async {
    final db = await startApp(tester, prepare: _plan);
    await tester.tap(find.text('資産'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('asset-add')));
    await settle(tester);

    await tester.enterText(find.byKey(const Key('asset-name')), '全世界株式');
    await _pick(tester, const Key('asset-category'), '株式・投資信託');
    expect(find.textContaining('保有数は購入・売却の数量から求め'), findsOneWidget);

    // 今月の単価 2,000円
    await tester.tap(find.byKey(const Key('value-add')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('value-input')), '2000');
    await tester.tap(find.byKey(const Key('value-ok')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('asset-save')));
    await settle(tester);
    expect(find.byKey(const Key('asset-全世界株式')), findsOneWidget);

    // 資産詳細から購入
    await tester.tap(find.byKey(const Key('asset-全世界株式')));
    await settle(tester);
    await tester.tap(find.text('購入').first);
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('flow-amount')),
        matching: find.byType(EditableText),
      ),
      '30000',
    );
    await settle(tester);
    expect(find.text('自動計算　数量 15.0000'), findsOneWidget);
    await _pick(tester, const Key('flow-account'), '現金');
    await _pick(tester, const Key('flow-category'), 'その他');
    await tester.tap(find.byKey(const Key('flow-save')));
    await settle(tester);

    final t = await tester.runAsync(
      () => (db.select(
        db.txns,
      )..where((t) => t.assetAction.equals('buy'))).getSingle(),
    );
    expect((t!.amount, t.quantityX1e4, t.kind), (30000, 150000, 'expense'));
    // 15口×2,000円
    expect(
      find.descendant(
        of: find.byKey(const Key('m-valuation')),
        matching: find.text('¥30,000'),
      ),
      findsOneWidget,
    );

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('売却：税額の初期値を入れ、実現損益を出す', (tester) async {
    final db = await startApp(tester, prepare: _withStock);
    await tester.tap(find.text('資産'));
    await settle(tester);
    await tester.tap(find.text('売却'));
    await settle(tester);

    await _pick(tester, const Key('flow-asset'), '銘柄A（数量×単価）');
    await tester.enterText(find.byKey(const Key('flow-quantity')), '5');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('flow-amount')),
        matching: find.byType(EditableText),
      ),
      '7500',
    );
    await settle(tester);
    // 売却分の取得価額 5,000 → 利益 2,500 → 税 507
    await tester.tap(find.byKey(const Key('tax-add')));
    await settle(tester);
    expect(find.text('507'), findsOneWidget);
    expect(find.text('実現損益　+¥1,993'), findsOneWidget);

    await _pick(tester, const Key('flow-account'), '現金');
    await _pick(tester, const Key('flow-category'), '譲渡所得');
    // 税の行のカテゴリ
    final taxCat = find.widgetWithText(
      DropdownButtonFormField<String>,
      '税金のカテゴリ',
    );
    await tester.ensureVisible(taxCat);
    await tester.tap(taxCat);
    await settle(tester);
    await tester.tap(find.text('税金').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('flow-save')));
    await settle(tester);

    final txns = await tester.runAsync(() => db.select(db.txns).get());
    final sell = txns!.firstWhere((t) => t.assetAction == 'sell');
    final tax = txns.firstWhere((t) => t.parentTxnId == sell.id);
    expect((sell.amount, sell.quantityX1e4), (7500, 50000));
    expect((tax.amount, tax.assetAction, tax.kind), (507, 'cost', 'expense'));

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('家計簿から資産の実績を編集しても、資産との紐づきは残る', (tester) async {
    final db = await startApp(tester, prepare: _withStock);
    await tester.tap(find.text('家計簿'));
    await settle(tester);
    await tester.tap(find.text('リスト'));
    await settle(tester);
    await tester.tap(find.text('その他').last);
    await settle(tester);
    expect(find.byKey(const Key('txn-asset-action')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('txn-memo')), '初回');
    await tester.tap(find.byKey(const Key('txn-save')));
    await settle(tester);

    final t = await tester.runAsync(() => db.select(db.txns).getSingle());
    expect(
      (t!.memo, t.assetId, t.assetAction, t.quantityX1e4),
      ('初回', _assetId, 'buy', 100000),
    );

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('資産の一覧と詳細：評価額・含み損益・通算の損益、削除はチェックで選ぶ', (tester) async {
    final db = await startApp(tester, prepare: _withStock);
    await tester.tap(find.text('資産'));
    await settle(tester);
    // 10口×1,500円
    expect(find.text('¥15,000'), findsWidgets);
    expect(find.text('含み損益 +¥5,000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('asset-銘柄A')));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('m-total')),
        matching: find.text('+¥5,000'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('asset-delete')));
    await tester.tap(find.byKey(const Key('asset-delete')));
    await settle(tester);
    // 実績は残す（紐づきだけ外す）
    await tester.tap(find.byKey(const Key('del-txns')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('asset-delete-confirm')));
    await settle(tester);

    final t = await tester.runAsync(() => db.select(db.txns).getSingle());
    expect(t!.deletedAt, isNull);
    expect(t.assetId, isNull);
    expect(find.text('資産はまだありません。'), findsOneWidget);
    expect(clock.now(), isNotNull);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
