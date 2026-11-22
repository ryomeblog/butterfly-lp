import '../../core/time.dart';
import '../models/enums.dart';
import '../models/group_item.dart';
import 'growth.dart';
import 'rounding.dart';

/// 登録に使うテンプレートの中身（設計書 4.4 template）。
class RegTemplate {
  const RegTemplate({
    required this.id,
    required this.name,
    required this.kind,
    this.amount,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.quantityX1e4,
    this.growthMode = GrowthMode.category,
    this.growthRate,
  });

  final String id;
  final String name;
  final TxnKind kind;
  final int? amount;
  final String? categoryId;
  final String? accountId;
  final String? toAccountId;
  final String? assetId;
  final AssetAction? assetAction;
  final int? quantityX1e4;
  final GrowthMode growthMode;
  final double? growthRate;

  bool get isBuyOrSell =>
      assetAction == AssetAction.buy || assetAction == AssetAction.sell;
}

/// 作る計画行1件分（plan_line の source=group の行）。
class GeneratedLine {
  const GeneratedLine({
    required this.ym,
    required this.itemId,
    required this.template,
    required this.amount,
  });

  final YearMonth ym;
  final String itemId;
  final RegTemplate template;
  final int amount;
}

/// 登録で使えない項目と、その理由（確認画面に出す。設計書 3.2）。
class SkippedItem {
  const SkippedItem(this.itemId, this.reason, {this.templateName});

  final String itemId;
  final String reason;
  final String? templateName;
}

class RegistrationResult {
  const RegistrationResult(this.lines, this.skipped);

  final List<GeneratedLine> lines;
  final List<SkippedItem> skipped;
}

/// その月に、固定額の項目が何回発生するか（設計書 6.3 手順1）。
///
/// Nか月ごと・N年ごとは登録の開始年月 [start] を起点に数える。毎週はその月の該当曜日の数。
int occurrences(GroupItemDraft item, YearMonth ym, YearMonth start) {
  final elapsed = start.monthsUntil(ym);
  if (elapsed < 0) return 0;
  switch (item.frequency) {
    case Frequency.monthly:
      return 1;
    case Frequency.yearly:
      return ym.month == item.month ? 1 : 0;
    case Frequency.everyNMonths:
      final n = item.intervalN ?? 0;
      return n > 0 && elapsed % n == 0 ? 1 : 0;
    case Frequency.everyNYears:
      final n = item.intervalN ?? 0;
      return n > 0 && elapsed % (12 * n) == 0 ? 1 : 0;
    case Frequency.weekly:
      final w = item.weekday;
      if (w == null) return 0;
      var count = 0;
      for (var d = 1; d <= ym.daysInMonth; d++) {
        if (DateTime(ym.year, ym.month, d).weekday == w) count++;
      }
      return count;
    case Frequency.specificMonths:
      return item.months.contains(ym.month) ? 1 : 0;
  }
}

/// グループの登録で作る計画行（設計書 6.3）。
///
/// - [start]〜[end] の各月について作る。[from] を渡すと、その年月以降だけを作る（作り直し。6.4）
/// - 上昇率の基準は常に登録の開始年（[start] の年）
/// - [categoryRate]：プランのカテゴリの上昇率（未設定なら null）。[defaultRate]：プランの既定値
/// - 金額が0以下になる行は作らない
/// - テンプレートが削除された項目、必要な欄（カテゴリ・口座）が空のテンプレートの項目、
///   それらを基準にした割合の項目は作らず、[RegistrationResult.skipped] に入れる
RegistrationResult generateGroupLines({
  required List<GroupItemDraft> items,
  required Map<String, RegTemplate> templates,
  required YearMonth start,
  required YearMonth end,
  YearMonth? from,
  required double? Function(String? categoryId) categoryRate,
  required double defaultRate,
}) {
  final skipped = <SkippedItem>[];
  final usable = <String, RegTemplate>{};
  for (final item in items) {
    final t = templates[item.templateId];
    if (t == null) {
      skipped.add(SkippedItem(item.id, 'テンプレートが削除されています'));
      continue;
    }
    if (t.accountId == null ||
        (t.kind == TxnKind.transfer && t.toAccountId == null)) {
      skipped.add(SkippedItem(item.id, '口座が空です', templateName: t.name));
      continue;
    }
    if (t.kind != TxnKind.transfer && t.categoryId == null) {
      skipped.add(SkippedItem(item.id, 'カテゴリが空です', templateName: t.name));
      continue;
    }
    usable[item.id] = t;
  }
  final byId = {for (final i in items) i.id: i};
  for (final item in items) {
    if (item.amountMode != AmountMode.percent || !usable.containsKey(item.id)) {
      continue;
    }
    final base = byId[item.baseItemId];
    if (base == null ||
        !usable.containsKey(base.id) ||
        base.amountMode != AmountMode.fixed) {
      usable.remove(item.id);
      skipped.add(
        SkippedItem(
          item.id,
          '基準の項目が使えないため金額を決められません',
          templateName: templates[item.templateId]?.name,
        ),
      );
    }
  }

  double rateOf(RegTemplate t) {
    if (t.kind == TxnKind.transfer || t.isBuyOrSell) return 0;
    return switch (t.growthMode) {
      GrowthMode.none => 0,
      GrowthMode.template => t.growthRate ?? 0,
      GrowthMode.category => categoryRate(t.categoryId) ?? defaultRate,
    };
  }

  final lines = <GeneratedLine>[];
  final first = from != null && from > start ? from : start;
  for (var ym = first; ym <= end; ym = ym.addMonths(1)) {
    final fixedAmounts = <String, int>{};
    for (final item in items) {
      final t = usable[item.id];
      if (t == null || item.amountMode != AmountMode.fixed) continue;
      final n = occurrences(item, ym, start);
      if (n == 0) continue;
      final base = t.amount ?? 0;
      final amount = grownAmount(base, rateOf(t), ym.year - start.year) * n;
      fixedAmounts[item.id] = amount;
      if (amount > 0) {
        lines.add(
          GeneratedLine(ym: ym, itemId: item.id, template: t, amount: amount),
        );
      }
    }
    for (final item in items) {
      final t = usable[item.id];
      if (t == null || item.amountMode != AmountMode.percent) continue;
      final baseAmount = fixedAmounts[item.baseItemId];
      if (baseAmount == null) continue;
      final amount = ceilYen(baseAmount * (item.percent ?? 0) / 100);
      if (amount > 0) {
        lines.add(
          GeneratedLine(ym: ym, itemId: item.id, template: t, amount: amount),
        );
      }
    }
  }
  return RegistrationResult(lines, skipped);
}
