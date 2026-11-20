import 'package:butterfly_lp/data/db/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// テスト用のメモリ上の DB。
AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

const testDeviceId = 'device-test';
