import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/db/database.dart';
import 'data/repositories/device_repository.dart';
import 'data/sync/sync_service.dart';
import 'features/settings/sync_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  final db = AppDatabase.open();
  final device = await DeviceRepository(db).ensure();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        deviceIdProvider.overrideWithValue(device.deviceId),
        secretStoreProvider.overrideWithValue(const SecureSecretStore()),
      ],
      child: const ButterflyApp(),
    ),
  );
}
