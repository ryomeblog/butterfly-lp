import 'package:drift/drift.dart';

/// 同期対象テーブルの共通列（設計書 4.1）。
///
/// - `id`：UUID v4。自然キーがある行（資産の価値・率・計画線の起点）は決定的ID
/// - `updated_at`：UTC のミリ秒付き ISO8601
/// - `updated_by`：更新した端末ID
/// - `deleted_at`：墓石。物理削除はしない
mixin SyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at')();
  TextColumn get updatedBy => text().named('updated_by')();
  TextColumn get deletedAt => text().named('deleted_at').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ---- 共通 ----

@DataClassName('HouseholdRow')
class Household extends Table with SyncColumns {
  @override
  String get tableName => 'household';
  IntColumn get schemaVersion => integer().named('schema_version')();
}

@DataClassName('AccountRow')
class Accounts extends Table with SyncColumns {
  @override
  String get tableName => 'account';
  TextColumn get name => text()();

  /// cash / bank / securities / other
  TextColumn get kind => text()();
  IntColumn get initialBalance => integer().named('initial_balance')();
  TextColumn get initialDate => text().named('initial_date')();
  IntColumn get sortOrder => integer().named('sort_order')();
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  @override
  String get tableName => 'category';
  TextColumn get name => text()();

  /// income / expense / asset
  TextColumn get kind => text()();
  TextColumn get color => text()();

  /// asset のみ。quantity / value
  TextColumn get defaultValuation =>
      text().named('default_valuation').nullable()();

  /// asset のみ。1 なら売却時に税額の初期値を出す
  IntColumn get saleTaxDefault =>
      integer().named('sale_tax_default').nullable()();
  IntColumn get sortOrder => integer().named('sort_order')();
}

// ---- 実績・資産・テンプレート ----

@DataClassName('TxnRow')
class Txns extends Table with SyncColumns {
  @override
  String get tableName => 'txn';
  TextColumn get planId => text().named('plan_id')();
  TextColumn get date => text()();

  /// income / expense / transfer
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().named('category_id').nullable()();
  TextColumn get accountId => text().named('account_id')();
  TextColumn get toAccountId => text().named('to_account_id').nullable()();
  TextColumn get assetId => text().named('asset_id').nullable()();

  /// buy / sell / income / cost
  TextColumn get assetAction => text().named('asset_action').nullable()();
  IntColumn get quantityX1e4 => integer().named('quantity_x1e4').nullable()();
  TextColumn get eventId => text().named('event_id').nullable()();
  TextColumn get parentTxnId => text().named('parent_txn_id').nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get groupId => text().named('group_id').nullable()();
  TextColumn get groupItemId => text().named('group_item_id').nullable()();
  TextColumn get entryId => text().named('entry_id').nullable()();
}

@DataClassName('AssetRow')
class Assets extends Table with SyncColumns {
  @override
  String get tableName => 'asset';
  TextColumn get planId => text().named('plan_id')();
  TextColumn get name => text()();
  TextColumn get categoryId => text().named('category_id')();

  /// quantity / value
  TextColumn get valuation => text()();
  TextColumn get code => text().nullable()();
  TextColumn get accountId => text().named('account_id').nullable()();
  IntColumn get sortOrder => integer().named('sort_order')();
}

/// id＝`asset_id:YYYY-MM-DD`（日単位）または `asset_id:YYYY-MM`（月単位）
@DataClassName('AssetValueRow')
class AssetValues extends Table with SyncColumns {
  @override
  String get tableName => 'asset_value';
  TextColumn get assetId => text().named('asset_id')();

  /// day / month
  TextColumn get unit => text()();
  TextColumn get valueDate => text().named('value_date')();
  IntColumn get valueX100 => integer().named('value_x100')();
}

@DataClassName('TemplateRow')
class Templates extends Table with SyncColumns {
  @override
  String get tableName => 'template';
  TextColumn get name => text()();
  TextColumn get kind => text()();
  IntColumn get amount => integer().nullable()();
  IntColumn get quantityX1e4 => integer().named('quantity_x1e4').nullable()();
  TextColumn get categoryId => text().named('category_id').nullable()();

  /// 口座を「履歴ごと削除」したときだけ空になる（設計書 3.7）
  TextColumn get accountId => text().named('account_id').nullable()();
  TextColumn get toAccountId => text().named('to_account_id').nullable()();
  TextColumn get assetId => text().named('asset_id').nullable()();
  TextColumn get assetAction => text().named('asset_action').nullable()();
  TextColumn get memo => text().nullable()();

  /// category / template / none
  TextColumn get growthMode => text().named('growth_mode')();
  RealColumn get growthRate => real().named('growth_rate').nullable()();
}

@DataClassName('TemplateGroupRow')
class TemplateGroups extends Table with SyncColumns {
  @override
  String get tableName => 'template_group';
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().named('sort_order')();
}

@DataClassName('TemplateGroupItemRow')
class TemplateGroupItems extends Table with SyncColumns {
  @override
  String get tableName => 'template_group_item';
  TextColumn get groupId => text().named('group_id')();
  TextColumn get templateId => text().named('template_id')();

  /// fixed / percent
  TextColumn get amountMode => text().named('amount_mode')();
  TextColumn get baseItemId => text().named('base_item_id').nullable()();
  RealColumn get percent => real().nullable()();

  /// monthly / yearly / every_n_months / every_n_years / weekly / specific_months
  TextColumn get frequency => text().nullable()();
  IntColumn get intervalN => integer().named('interval_n').nullable()();
  IntColumn get month => integer().nullable()();
  IntColumn get weekday => integer().nullable()();
  TextColumn get months => text().nullable()();
  IntColumn get sortOrder => integer().named('sort_order')();
}

// ---- 計画 ----

@DataClassName('PlanRow')
class Plans extends Table with SyncColumns {
  @override
  String get tableName => 'plan';
  TextColumn get name => text()();
  TextColumn get protagonistMemberId => text().named('protagonist_member_id')();
  IntColumn get startYear => integer().named('start_year')();
  TextColumn get baselineDate => text().named('baseline_date')();
  RealColumn get defaultInflationRate =>
      real().named('default_inflation_rate')();
  TextColumn get copiedFromPlanId =>
      text().named('copied_from_plan_id').nullable()();
  IntColumn get sortOrder => integer().named('sort_order')();
}

@DataClassName('FamilyMemberRow')
class FamilyMembers extends Table with SyncColumns {
  @override
  String get tableName => 'family_member';
  TextColumn get planId => text().named('plan_id')();
  TextColumn get name => text()();

  /// self / spouse / child / parent / other
  TextColumn get relation => text()();
  TextColumn get birthDate => text().named('birth_date')();
  IntColumn get lifeExpectancy => integer().named('life_expectancy')();
  IntColumn get sortOrder => integer().named('sort_order')();
}

@DataClassName('PlanLineRow')
class PlanLines extends Table with SyncColumns {
  @override
  String get tableName => 'plan_line';
  TextColumn get planId => text().named('plan_id')();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().named('category_id').nullable()();
  TextColumn get accountId => text().named('account_id')();
  TextColumn get toAccountId => text().named('to_account_id').nullable()();
  TextColumn get assetId => text().named('asset_id').nullable()();
  TextColumn get assetAction => text().named('asset_action').nullable()();
  IntColumn get quantityX1e4 => integer().named('quantity_x1e4').nullable()();
  TextColumn get eventId => text().named('event_id').nullable()();
  TextColumn get memo => text().nullable()();

  /// manual / group / event
  TextColumn get source => text()();
  TextColumn get sourceId => text().named('source_id').nullable()();
  TextColumn get memberId => text().named('member_id').nullable()();
  TextColumn get groupItemId => text().named('group_item_id').nullable()();
}

@DataClassName('PlanEventRow')
class PlanEvents extends Table with SyncColumns {
  @override
  String get tableName => 'plan_event';
  TextColumn get planId => text().named('plan_id')();
  TextColumn get memberId => text().named('member_id')();
  TextColumn get title => text()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get day => integer().nullable()();

  /// planned / done
  TextColumn get status => text()();
  TextColumn get doneDate => text().named('done_date').nullable()();
  TextColumn get memo => text().nullable()();
}

/// id＝`plan_id:target_type:target_id`
@DataClassName('PlanRateRow')
class PlanRates extends Table with SyncColumns {
  @override
  String get tableName => 'plan_rate';
  TextColumn get planId => text().named('plan_id')();

  /// account / asset / category
  TextColumn get targetType => text().named('target_type')();
  TextColumn get targetId => text().named('target_id')();
  RealColumn get annualRate => real().named('annual_rate')();
}

/// id＝`plan_id:target_type:target_id`
@DataClassName('PlanBaselineRow')
class PlanBaselines extends Table with SyncColumns {
  @override
  String get tableName => 'plan_baseline';
  TextColumn get planId => text().named('plan_id')();
  TextColumn get targetType => text().named('target_type')();
  TextColumn get targetId => text().named('target_id')();
  IntColumn get balance => integer().nullable()();
  IntColumn get quantityX1e4 => integer().named('quantity_x1e4').nullable()();
  IntColumn get priceX100 => integer().named('price_x100').nullable()();
}

@DataClassName('PlanGroupRow')
class PlanGroups extends Table with SyncColumns {
  @override
  String get tableName => 'plan_group';
  TextColumn get planId => text().named('plan_id')();
  TextColumn get groupId => text().named('group_id')();
  TextColumn get startYm => text().named('start_ym')();
  TextColumn get endYm => text().named('end_ym')();
  TextColumn get memo => text().nullable()();
}

// ---- 端末（同期しない） ----

@DataClassName('DeviceSettingRow')
class DeviceSettings extends Table {
  @override
  String get tableName => 'device_setting';
  TextColumn get deviceId => text().named('device_id')();
  TextColumn get selectedPlanId =>
      text().named('selected_plan_id').nullable()();
  TextColumn get redisHost => text().named('redis_host').nullable()();
  IntColumn get redisPort => integer().named('redis_port').nullable()();
  TextColumn get lastSyncAt => text().named('last_sync_at').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}
