import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed.dart';
import 'tables.dart';

part 'database.g.dart';

/// データ形式のバージョン（household.schema_version・同期の互換判定に使う。設計書 5.3）。
const currentSchemaVersion = 1;

/// 同期対象の16テーブル名（device_setting は含まない）。
const syncedTableNames = <String>[
  'household',
  'account',
  'category',
  'txn',
  'asset',
  'asset_value',
  'template',
  'template_group',
  'template_group_item',
  'plan',
  'family_member',
  'plan_line',
  'plan_event',
  'plan_rate',
  'plan_baseline',
  'plan_group',
];

@DriftDatabase(
  tables: [
    Household,
    Accounts,
    Categories,
    Txns,
    Assets,
    AssetValues,
    Templates,
    TemplateGroups,
    TemplateGroupItems,
    Plans,
    FamilyMembers,
    PlanLines,
    PlanEvents,
    PlanRates,
    PlanBaselines,
    PlanGroups,
    DeviceSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// アプリ本体用（端末のアプリ領域に `butterfly_lp.sqlite` を作る）。
  ///
  /// Web 版はブラウザ内（OPFS か IndexedDB）に保存する。`web/` の sqlite3.wasm と
  /// drift_worker.js を使う（設計書 3.12）。
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'butterfly_lp',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // よく使う絞り込み（プラン・日付・年月）に索引を張る。
      await customStatement(
        'CREATE INDEX idx_txn_plan_date ON txn (plan_id, date)',
      );
      await customStatement(
        'CREATE INDEX idx_plan_line_plan_ym ON plan_line (plan_id, year, month)',
      );
      await customStatement(
        'CREATE INDEX idx_asset_value_asset ON asset_value (asset_id)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: template.account_id を空にできるようにした（設計書 3.7）
        await m.alterTable(TableMigration(templates));
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = OFF');
      if (details.wasCreated) {
        await seedInitialData(this);
      }
    },
  );
}
