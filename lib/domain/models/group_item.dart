import 'enums.dart';

/// グループの項目（編集中の内容。設計書 4.4 template_group_item）。
class GroupItemDraft {
  const GroupItemDraft({
    required this.id,
    required this.templateId,
    this.amountMode = AmountMode.fixed,
    this.baseItemId,
    this.percent,
    this.frequency = Frequency.monthly,
    this.intervalN,
    this.month,
    this.weekday,
    this.months = const [],
  });

  final String id;
  final String templateId;
  final AmountMode amountMode;
  final String? baseItemId;
  final double? percent;

  /// fixed のときだけ使う。
  final Frequency frequency;
  final int? intervalN;
  final int? month;

  /// 1＝月〜7＝日
  final int? weekday;
  final List<int> months;

  GroupItemDraft copyWith({
    String? templateId,
    AmountMode? amountMode,
    String? Function()? baseItemId,
    double? Function()? percent,
    Frequency? frequency,
    int? Function()? intervalN,
    int? Function()? month,
    int? Function()? weekday,
    List<int>? months,
  }) => GroupItemDraft(
    id: id,
    templateId: templateId ?? this.templateId,
    amountMode: amountMode ?? this.amountMode,
    baseItemId: baseItemId != null ? baseItemId() : this.baseItemId,
    percent: percent != null ? percent() : this.percent,
    frequency: frequency ?? this.frequency,
    intervalN: intervalN != null ? intervalN() : this.intervalN,
    month: month != null ? month() : this.month,
    weekday: weekday != null ? weekday() : this.weekday,
    months: months ?? this.months,
  );
}

const weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

/// 頻度の説明（「毎月」「毎年6月」「3か月ごと」「特定の月のみ（6月・12月）」など）。
String describeFrequency(GroupItemDraft item) {
  switch (item.frequency) {
    case Frequency.monthly:
      return '毎月';
    case Frequency.yearly:
      return '毎年${item.month ?? '?'}月';
    case Frequency.everyNMonths:
      return '${item.intervalN ?? '?'}か月ごと';
    case Frequency.everyNYears:
      return '${item.intervalN ?? '?'}年ごと';
    case Frequency.weekly:
      final w = item.weekday;
      return '毎週${w == null ? '?' : weekdayLabels[w - 1]}曜';
    case Frequency.specificMonths:
      return '特定の月のみ（${item.months.map((m) => '$m月').join('・')}）';
  }
}

/// 項目の入力の誤り。なければ null。
///
/// - 固定額の項目は頻度とそのパラメータが必要
/// - 割合の項目は、同じグループの固定額の項目を基準にする（割合の連鎖はしない。設計書 3.2）
/// - [missingTemplateIds]：削除されたテンプレートの項目は基準にできない
String? validateGroupItem(
  GroupItemDraft item,
  List<GroupItemDraft> all, {
  Set<String> missingTemplateIds = const {},
}) {
  if (item.amountMode == AmountMode.percent) {
    final base = all.where((i) => i.id == item.baseItemId).firstOrNull;
    if (base == null) return '基準にする項目を選んでください';
    if (base.id == item.id) return '自分自身は基準にできません';
    if (base.amountMode != AmountMode.fixed) return '基準にできるのは固定額の項目だけです';
    if (missingTemplateIds.contains(base.templateId)) {
      return '基準の項目のテンプレートが削除されています';
    }
    final p = item.percent;
    if (p == null) return '割合を入れてください';
    if (p < 0) return '割合は0以上にしてください';
    return null;
  }
  switch (item.frequency) {
    case Frequency.monthly:
      return null;
    case Frequency.yearly:
      final m = item.month;
      return (m == null || m < 1 || m > 12) ? '月を選んでください' : null;
    case Frequency.everyNMonths:
    case Frequency.everyNYears:
      final n = item.intervalN;
      return (n == null || n < 1) ? 'Nを1以上で入れてください' : null;
    case Frequency.weekly:
      final w = item.weekday;
      return (w == null || w < 1 || w > 7) ? '曜日を選んでください' : null;
    case Frequency.specificMonths:
      return item.months.isEmpty ? '対象の月を1つ以上選んでください' : null;
  }
}

/// `6,12` ⇔ [6, 12]
List<int> parseMonths(String? s) => (s == null || s.trim().isEmpty)
    ? const []
    : (s.split(',').map((e) => int.parse(e.trim())).toList()..sort());

String formatMonths(List<int> months) => ([...months]..sort()).join(',');
