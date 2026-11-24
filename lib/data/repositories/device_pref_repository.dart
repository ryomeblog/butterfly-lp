import '../db/database.dart';

/// この端末だけの設定（device_pref。同期しない）。
class DevicePrefRepository {
  DevicePrefRepository(this.db);

  final AppDatabase db;

  /// 共有サーバーの URL（デスクトップ版・スマホ版。設計書 3.12）
  static const shareServer = 'share.server';

  Future<String?> get(String key) async => (await (db.select(
    db.devicePrefs,
  )..where((p) => p.key.equals(key))).getSingleOrNull())?.value;

  Future<void> set(String key, String value) => db
      .into(db.devicePrefs)
      .insertOnConflictUpdate(
        DevicePrefsCompanion.insert(key: key, value: value),
      );

  Stream<String?> watch(String key) => (db.select(
    db.devicePrefs,
  )..where((p) => p.key.equals(key))).watchSingleOrNull().map((r) => r?.value);
}
