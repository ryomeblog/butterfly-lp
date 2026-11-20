import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/database.dart';

/// 端末設定（同期しない。設計書 4.6）。
class DeviceRepository {
  DeviceRepository(this.db);

  final AppDatabase db;

  /// 端末設定の行を返す。初回起動なら端末IDを作って保存する。
  Future<DeviceSettingRow> ensure() async {
    final existing = await db.select(db.deviceSettings).getSingleOrNull();
    if (existing != null) return existing;
    final row = DeviceSettingsCompanion.insert(deviceId: newId());
    await db.into(db.deviceSettings).insert(row);
    return db.select(db.deviceSettings).getSingle();
  }

  Stream<DeviceSettingRow> watch() =>
      db.select(db.deviceSettings).watchSingle();

  Future<void> setSelectedPlan(String? planId) => db
      .update(db.deviceSettings)
      .write(DeviceSettingsCompanion(selectedPlanId: Value(planId)));
}
