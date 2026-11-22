import '../../core/time.dart';
import '../models/enums.dart';
import 'event_matching.dart';

/// 予定（計画行）の突き合わせ用の項目。
class PlanItem {
  const PlanItem({
    required this.match,
    required this.ym,
    this.groupItemId,
    this.eventId,
  });

  final MatchItem match;
  final YearMonth ym;
  final String? groupItemId;
  final String? eventId;

  String get id => match.id;
  int get amount => match.amount;
  TxnKind get kind => match.kind;
}

/// 実績（txn）の突き合わせ用の項目。
class ActualItem {
  const ActualItem({
    required this.match,
    required this.date,
    this.groupItemId,
    this.eventId,
  });

  final MatchItem match;
  final String date;
  final String? groupItemId;
  final String? eventId;

  YearMonth get ym => YearMonth.ofDateString(date);
  int get amount => match.amount;
  TxnKind get kind => match.kind;
}

/// 予定ごとの実績額（設計書 6.8）。実績額が0でなければ「入力済み」。
///
/// - グループ由来（group_item_id がある）：同じ月・同じ group_item_id の実績の合計
/// - イベントを指す（event_id がある）：同じ event_id・同じキーの実績の合計（月は問わない）
/// - それ以外（手入力）：同じ月・同じキーの実績のうち、group_item_id も event_id もないものの合計
Map<String, int> planActuals(
  Iterable<PlanItem> plans,
  Iterable<ActualItem> actuals,
) {
  final byGroup = <String, int>{};
  final byEvent = <String, int>{};
  final byManual = <String, int>{};
  for (final a in actuals) {
    if (a.groupItemId != null) {
      final k = '${a.ym}|${a.groupItemId}';
      byGroup[k] = (byGroup[k] ?? 0) + a.amount;
    }
    if (a.eventId != null) {
      final k = '${a.eventId}|${a.match.matchKey}';
      byEvent[k] = (byEvent[k] ?? 0) + a.amount;
    }
    if (a.groupItemId == null && a.eventId == null) {
      final k = '${a.ym}|${a.match.matchKey}';
      byManual[k] = (byManual[k] ?? 0) + a.amount;
    }
  }
  return {
    for (final p in plans)
      p.id: p.groupItemId != null
          ? byGroup['${p.ym}|${p.groupItemId}'] ?? 0
          : p.eventId != null
          ? byEvent['${p.eventId}|${p.match.matchKey}'] ?? 0
          : byManual['${p.ym}|${p.match.matchKey}'] ?? 0,
  };
}

/// 予定・実績・差（差＝実績−予定）。
class PlanActual {
  const PlanActual(this.planned, this.actual);

  final int planned;
  final int actual;

  int get diff => actual - planned;
}

/// 収入・支出・収支の予定と実績（振替は含めない。資産の購入・売却は支出・収入として含める）。
class CompareTotals {
  const CompareTotals({required this.income, required this.expense});

  final PlanActual income;
  final PlanActual expense;

  PlanActual get net => PlanActual(
    income.planned - expense.planned,
    income.actual - expense.actual,
  );
}

CompareTotals compareTotals(
  Iterable<MatchItem> plans,
  Iterable<MatchItem> actuals,
) {
  final p = kindTotals(plans);
  final a = kindTotals(actuals);
  return CompareTotals(
    income: PlanActual(p.income, a.income),
    expense: PlanActual(p.expense, a.expense),
  );
}

/// カテゴリ1つ＝1カードの予定と実績（設計書 3.8）。
class CategoryCompare {
  const CategoryCompare({
    required this.categoryId,
    required this.planned,
    required this.actual,
    required this.plannedWeight,
    required this.actualWeight,
  });

  final String? categoryId;
  final int planned;
  final int actual;

  /// 予定は予定の合計、実績は実績の合計に対する割合（0〜1）
  final double plannedWeight;
  final double actualWeight;

  /// 正なら超過、負なら余り
  int get diff => actual - planned;
}

enum CompareSort {
  overrun('予定からの超過が大きい順'),
  actual('実績の金額が大きい順'),
  planned('予定の金額が大きい順');

  const CompareSort(this.label);
  final String label;
}

/// [kind]（収入か支出）のカテゴリ別の予定と実績。既定の並びは予定からの超過が大きい順。
List<CategoryCompare> categoryCompare(
  Iterable<MatchItem> plans,
  Iterable<MatchItem> actuals,
  TxnKind kind, {
  CompareSort sort = CompareSort.overrun,
}) {
  final p = <String?, int>{};
  final a = <String?, int>{};
  var pt = 0;
  var at = 0;
  for (final x in plans) {
    if (x.kind != kind) continue;
    p[x.categoryId] = (p[x.categoryId] ?? 0) + x.amount;
    pt += x.amount;
  }
  for (final x in actuals) {
    if (x.kind != kind) continue;
    a[x.categoryId] = (a[x.categoryId] ?? 0) + x.amount;
    at += x.amount;
  }
  final list = [
    for (final c in {...p.keys, ...a.keys})
      CategoryCompare(
        categoryId: c,
        planned: p[c] ?? 0,
        actual: a[c] ?? 0,
        plannedWeight: pt == 0 ? 0 : (p[c] ?? 0) / pt,
        actualWeight: at == 0 ? 0 : (a[c] ?? 0) / at,
      ),
  ];
  list.sort(
    (x, y) => switch (sort) {
      CompareSort.overrun => y.diff.compareTo(x.diff),
      CompareSort.actual => y.actual.compareTo(x.actual),
      CompareSort.planned => y.planned.compareTo(x.planned),
    },
  );
  return list;
}

/// 総資産の差の内訳（設計書 6.8）。収入の差・支出の差は起点月の翌月から対象月まで。
/// 運用の差＝総資産の差−収入の差＋支出の差。
class AssetDiffBreakdown {
  const AssetDiffBreakdown({
    required this.totalDiff,
    required this.income,
    required this.expense,
  });

  final int totalDiff;
  final PlanActual income;
  final PlanActual expense;

  int get investmentDiff => totalDiff - income.diff + expense.diff;
}
