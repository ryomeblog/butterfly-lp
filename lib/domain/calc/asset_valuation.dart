import 'dart:math' as math;

import '../../core/time.dart';
import '../models/enums.dart';
import 'rounding.dart';

/// 資産の価値1件（asset_value）。日単位はその日から、月単位はその月の1日から有効（設計書 6.2）。
class ValuePoint {
  const ValuePoint({
    required this.unit,
    required this.date,
    required this.valueX100,
  });

  /// day / month
  final String unit;

  /// day は YYYY-MM-DD、month は YYYY-MM
  final String date;

  /// quantity の資産は1単位あたりの単価×100、value の資産は評価額（円）×100
  final int valueX100;

  bool get isDay => unit == 'day';

  /// 有効になる日（YYYY-MM-DD）
  String get effectiveFrom => isDay ? date : '$date-01';
}

/// [date] 時点の価値（×100）。その日以前に有効になったもののうち最新。なければ null。
///
/// 同じ日に有効になる月単位と日単位があれば、日単位を使う（より細かい指定を優先）。
int? valueAt(Iterable<ValuePoint> points, String date) {
  ValuePoint? best;
  for (final p in points) {
    if (p.effectiveFrom.compareTo(date) > 0) continue;
    if (best == null) {
      best = p;
      continue;
    }
    final c = p.effectiveFrom.compareTo(best.effectiveFrom);
    if (c > 0 || (c == 0 && p.isDay && !best.isDay)) best = p;
  }
  return best?.valueX100;
}

/// 資産の動き（txn の asset_action がある行）。
class AssetMove {
  const AssetMove({
    required this.id,
    required this.date,
    required this.action,
    required this.amount,
    this.quantityX1e4,
    this.parentId,
  });

  final String id;
  final String date;
  final AssetAction action;
  final int amount;
  final int? quantityX1e4;

  /// cost が元の buy / sell / income を指す
  final String? parentId;
}

/// 売却1件の結果。
class SaleResult {
  const SaleResult({
    required this.moveId,
    required this.costOfSold,
    required this.realizedGain,
  });

  final String moveId;

  /// 売却分の取得価額（移動平均）
  final int costOfSold;

  /// 実現損益＝売却額−売却分の取得価額−その売却を指す費用すべて
  final int realizedGain;
}

/// ある時点の資産の状態（設計書 6.2）。
class AssetState {
  const AssetState({
    required this.quantityX1e4,
    required this.holding,
    required this.acquisitionCost,
    required this.valuation,
    required this.sales,
    required this.totalBuy,
    required this.totalSell,
    required this.totalIncome,
    required this.totalCost,
  });

  /// 保有数×10,000（数量×単価の資産）
  final int quantityX1e4;

  /// 保有中か（評価額の資産：最初の購入から売却まで）
  final bool holding;

  /// 取得価額（移動平均。購入にかかった費用は含めない）
  final int acquisitionCost;

  /// 評価額
  final int valuation;

  final List<SaleResult> sales;
  final int totalBuy;
  final int totalSell;
  final int totalIncome;
  final int totalCost;

  /// 含み損益＝評価額−取得価額
  int get unrealizedGain => valuation - acquisitionCost;

  /// 通算の損益＝評価額＋売却額＋収益−購入額−費用（設計書 6.2）
  int get totalGain =>
      valuation + totalSell + totalIncome - totalBuy - totalCost;
}

/// 数量×単価：評価額（円未満切り捨て）。
int valuationOf(int quantityX1e4, int priceX100) =>
    floorYen(quantityX1e4 * priceX100 / 1000000);

/// 購入の入力：金額指定なら数量＝金額÷単価（小数第4位で切り捨て。×10,000の整数）。
int quantityForAmount(int amount, int priceX100) =>
    priceX100 <= 0 ? 0 : (amount * 1000000) ~/ priceX100;

/// 購入の入力：数量指定なら金額＝数量×単価（円未満切り捨て）。
int amountForQuantity(int quantityX1e4, int priceX100) =>
    valuationOf(quantityX1e4, priceX100);

/// 税額の初期値：max(利益, 0)×20.315%（円未満切り捨て）。配当は受取額を渡す。
int taxInitial(int gain) => floorYen(math.max(gain, 0) * 0.20315);

/// [date]（含む）時点の資産の状態を、実績の動きと価値から計算する（設計書 6.2）。
AssetState assetStateAt({
  required Valuation valuation,
  required Iterable<AssetMove> moves,
  required Iterable<ValuePoint> values,
  required String date,
}) {
  final sorted =
      [
        for (final m in moves)
          if (m.date.compareTo(date) <= 0) m,
      ]..sort((a, b) {
        final c = a.date.compareTo(b.date);
        if (c != 0) return c;
        // 同じ日は購入を先に（同日に買って売る場合）
        return _order(a.action).compareTo(_order(b.action));
      });
  final costsByParent = <String, int>{};
  for (final m in sorted) {
    if (m.action == AssetAction.cost && m.parentId != null) {
      costsByParent[m.parentId!] = (costsByParent[m.parentId!] ?? 0) + m.amount;
    }
  }

  var qty = 0;
  var cost = 0;
  var holding = false;
  var totalBuy = 0;
  var totalSell = 0;
  var totalIncome = 0;
  var totalCost = 0;
  final sales = <SaleResult>[];

  for (final m in sorted) {
    switch (m.action) {
      case AssetAction.buy:
        totalBuy += m.amount;
        cost += m.amount;
        qty += m.quantityX1e4 ?? 0;
        holding = true;
      case AssetAction.sell:
        totalSell += m.amount;
        int sold;
        if (valuation == Valuation.quantity) {
          final q = m.quantityX1e4 ?? 0;
          sold = qty <= 0 ? 0 : (cost * math.min(q, qty)) ~/ qty;
          qty -= q;
          cost -= sold;
          if (qty <= 0) {
            qty = math.max(qty, 0);
            cost = 0;
          }
        } else {
          sold = cost;
          cost = 0;
          holding = false;
        }
        sales.add(
          SaleResult(
            moveId: m.id,
            costOfSold: sold,
            realizedGain: m.amount - sold - (costsByParent[m.id] ?? 0),
          ),
        );
      case AssetAction.income:
        totalIncome += m.amount;
      case AssetAction.cost:
        totalCost += m.amount;
    }
  }

  final v = valueAt(values, date);
  int valuationYen;
  if (valuation == Valuation.quantity) {
    // 価値が1つもない期間は取得価額で評価する
    valuationYen = qty <= 0 ? 0 : (v == null ? cost : valuationOf(qty, v));
  } else {
    valuationYen = !holding ? 0 : (v == null ? cost : floorYen(v / 100));
  }
  return AssetState(
    quantityX1e4: valuation == Valuation.quantity ? qty : 0,
    holding: valuation == Valuation.quantity ? qty > 0 : holding,
    acquisitionCost: cost,
    valuation: valuationYen,
    sales: sales,
    totalBuy: totalBuy,
    totalSell: totalSell,
    totalIncome: totalIncome,
    totalCost: totalCost,
  );
}

int _order(AssetAction a) => switch (a) {
  AssetAction.buy => 0,
  AssetAction.income => 1,
  AssetAction.sell => 2,
  AssetAction.cost => 3,
};

/// 月末ごとの評価額（資産詳細の実績線）。
List<(YearMonth, int)> monthEndValuations({
  required Valuation valuation,
  required List<AssetMove> moves,
  required List<ValuePoint> values,
  required YearMonth from,
  required YearMonth to,
}) => [
  for (var ym = from; ym <= to; ym = ym.addMonths(1))
    (
      ym,
      assetStateAt(
        valuation: valuation,
        moves: moves,
        values: values,
        date: ym.lastDayString,
      ).valuation,
    ),
];

/// 計画で使う「その月の見込み単価」（設計書 6.3 補足）。
///
/// その月末に有効な価値が [baselineDate] より後に指定されていればそれ、なければ起点の単価
/// [baselinePriceX100] を想定利回り [annualRatePercent] で月ごとに増やした単価（起点月の翌月から）。
int projectedPriceX100({
  required List<ValuePoint> values,
  required YearMonth ym,
  required String baselineDate,
  required int baselinePriceX100,
  required double annualRatePercent,
}) {
  final end = ym.lastDayString;
  ValuePoint? latestAfterBaseline;
  for (final p in values) {
    if (p.effectiveFrom.compareTo(baselineDate) <= 0) continue;
    if (p.effectiveFrom.compareTo(end) > 0) continue;
    if (latestAfterBaseline == null ||
        p.effectiveFrom.compareTo(latestAfterBaseline.effectiveFrom) > 0) {
      latestAfterBaseline = p;
    }
  }
  if (latestAfterBaseline != null) return latestAfterBaseline.valueX100;
  final months = YearMonth.ofDateString(baselineDate).monthsUntil(ym);
  if (months <= 0 || annualRatePercent == 0) return baselinePriceX100;
  final monthly = math.pow(1 + annualRatePercent / 100, 1 / 12) - 1;
  return (baselinePriceX100 * math.pow(1 + monthly, months)).round();
}
