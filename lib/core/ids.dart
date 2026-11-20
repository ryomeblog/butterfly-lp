import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 通常の行の id（UUID v4）。
String newId() => _uuid.v4();

/// 資産の価値の決定的ID（設計書 4.4）。日単位は `asset_id:YYYY-MM-DD`、月単位は `asset_id:YYYY-MM`。
String assetValueId(String assetId, String valueDate) => '$assetId:$valueDate';

/// 率・計画線の起点の決定的ID（設計書 4.5）。`plan_id:target_type:target_id`
String planTargetId(String planId, String targetType, String targetId) =>
    '$planId:$targetType:$targetId';

/// 世帯設定の行は1行だけなので固定ID。
const householdId = 'household';

/// 初期データ（初期カテゴリ）の決定的ID。
///
/// 複数の端末がそれぞれ初期データを作っても、同期で重複しないように名前から作る（UUID v5）。
String seedId(String key) =>
    _uuid.v5(Namespace.url.value, 'butterfly-lp:seed:$key');
