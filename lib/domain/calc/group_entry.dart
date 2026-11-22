import '../../core/time.dart';
import '../models/enums.dart';
import '../models/group_item.dart';
import 'rounding.dart';

/// 小数第2位で四捨五入。
double round2(double v) => (v * 100).round() / 100;

/// その月に、頻度から見て項目が発生しうるか（予定がないときの初期値に使う）。
/// 開始年月が分からない Nか月ごと・N年ごとは発生するものとみなす。
bool mayOccur(GroupItemDraft item, YearMonth ym) => switch (item.frequency) {
  Frequency.yearly => item.month == ym.month,
  Frequency.specificMonths => item.months.contains(ym.month),
  _ => true,
};

/// グループからの実績入力の金額欄の初期値（設計書 6.6）。null は空欄。
///
/// - その月にこのグループの予定（[plannedByItem]：項目ID→その月の予定額）があれば、予定額。予定がない項目は空欄
/// - 予定がなければ、固定額はテンプレートの金額、割合の項目は基準項目の金額×%（円未満切り上げ）。
///   その月に発生しない頻度の項目（6月・12月だけのボーナスなど）は空欄
/// - 削除されたテンプレートの項目（[templateAmounts] にない）は出さない
Map<String, int?> entryPrefill({
  required List<GroupItemDraft> items,
  required Map<String, int?> templateAmounts,
  required Map<String, int> plannedByItem,
  required YearMonth ym,
}) {
  final usable = [
    for (final i in items)
      if (templateAmounts.containsKey(i.templateId)) i,
  ];
  if (plannedByItem.isNotEmpty) {
    return {for (final i in usable) i.id: plannedByItem[i.id]};
  }
  final result = <String, int?>{};
  for (final i in usable) {
    if (i.amountMode == AmountMode.fixed) {
      result[i.id] = mayOccur(i, ym) ? templateAmounts[i.templateId] : null;
    }
  }
  for (final i in usable) {
    if (i.amountMode != AmountMode.percent) continue;
    final base = result[i.baseItemId];
    result[i.id] = base == null ? null : ceilYen(base * (i.percent ?? 0) / 100);
  }
  return result;
}

/// 割合の提案（設計書 6.6）：項目の実績合計÷基準項目の実績合計×100（小数第2位で四捨五入）。実績がなければ null。
double? suggestPercent(int itemTotal, int baseTotal) {
  if (baseTotal <= 0 || itemTotal <= 0) return null;
  return round2(itemTotal / baseTotal * 100);
}

/// 「入力した実績でグループを更新」で書き換える内容。
class GroupUpdate {
  const GroupUpdate({required this.templateAmounts, required this.percents});

  /// テンプレートID→新しい金額（固定額の項目）
  final Map<String, int> templateAmounts;

  /// 項目ID→新しい割合（割合の項目。基準項目にも入力があったときだけ）
  final Map<String, double> percents;
}

GroupUpdate updateFromEntry(
  List<GroupItemDraft> items,
  Map<String, int> entered,
) {
  final amounts = <String, int>{};
  final percents = <String, double>{};
  for (final i in items) {
    final v = entered[i.id];
    if (v == null) continue;
    if (i.amountMode == AmountMode.fixed) {
      amounts[i.templateId] = v;
    } else {
      final base = entered[i.baseItemId];
      final p = base == null ? null : suggestPercent(v, base);
      if (p != null) percents[i.id] = p;
    }
  }
  return GroupUpdate(templateAmounts: amounts, percents: percents);
}
