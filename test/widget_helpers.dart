import 'package:butterfly_lp/app/app.dart';
import 'package:butterfly_lp/app/providers.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/device_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DB のストリーム（実時間）と画面のアニメーションを交互に進める。
/// 読み込み中のスピナーで pumpAndSettle が終わらなくなるのを避ける。
Future<void> settle(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// メモリ上の DB でアプリを起動する。[prepare] で事前のデータを入れられる。
Future<AppDatabase> startApp(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db, String deviceId)? prepare,
}) async {
  final db = memoryDb();
  final device = (await tester.runAsync(() => DeviceRepository(db).ensure()))!;
  if (prepare != null) {
    await tester.runAsync(() => prepare(db, device.deviceId));
  }
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        deviceIdProvider.overrideWithValue(device.deviceId),
      ],
      child: const ButterflyApp(),
    ),
  );
  await settle(tester);
  return db;
}

/// 画面を外し、drift がストリームを閉じるためのタイマーを進めてから DB を閉じる。
Future<void> stopApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(() => db.close());
  await tester.binding.setSurfaceSize(null);
}
