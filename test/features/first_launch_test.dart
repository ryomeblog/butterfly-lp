import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_helpers.dart';

void main() {
  testWidgets('初回起動：最初のプランを作るとホームにカードが出る', (tester) async {
    final db = await startApp(tester);

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

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
