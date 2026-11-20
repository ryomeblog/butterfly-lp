import 'package:butterfly_lp/app/app.dart';
import 'package:butterfly_lp/app/providers.dart';
import 'package:butterfly_lp/data/repositories/device_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// DB のストリーム（実時間）と画面のアニメーションを交互に進める。
/// 読み込み中のスピナーで pumpAndSettle が終わらなくなるのを避ける。
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('初回起動：最初のプランを作るとホームにカードが出る', (tester) async {
    final db = memoryDb();
    final device = await tester.runAsync(() => DeviceRepository(db).ensure());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue(device!.deviceId),
        ],
        child: const ButterflyApp(),
      ),
    );
    await settle(tester);

    // プランがないので「はじめに」画面
    expect(find.text('はじめに'), findsOneWidget);

    // 生年月日を入力（入力モードの日付ピッカー）
    await tester.tap(find.byKey(const Key('protagonist-birth')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '1990/01/01');
    await tester.tap(find.text('OK'));
    await settle(tester);

    await tester.ensureVisible(find.byKey(const Key('plan-create-save')));
    await tester.tap(find.byKey(const Key('plan-create-save')));
    await settle(tester);

    expect(find.text('ホーム'), findsWidgets);
    expect(find.text('プラン1'), findsWidgets);
    expect(find.text('表示中'), findsOneWidget);
    expect(find.textContaining('期間：'), findsWidgets);

    // 画面を外し、drift がストリームを閉じるためのタイマーを進めてから DB を閉じる。
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  }, timeout: const Timeout(Duration(seconds: 60)));
}
