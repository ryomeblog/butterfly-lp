import 'dart:math' as math;

import '../../core/time.dart';
import '../models/enums.dart';
import 'asset_valuation.dart';
import 'rounding.dart';

/// 計画線の起点（plan_baseline）。
class SimAccount {
  const SimAccount({
    required this.id,
    required this.balance,
    required this.cashLike,
    this.annualRate = 0,
  });

  final String id;

  /// 起点残高
  final int balance;

  /// 現金系口座（cash / bank / other）。資金不足の判定に使う
  final bool cashLike;
  final double annualRate;
}

class SimAsset {
  const SimAsset({
    required this.id,
    required this.valuation,
    this.quantityX1e4 = 0,
    this.priceX100,
    this.balance = 0,
    this.annualRate = 0,
    this.values = const [],
  });

  final String id;
  final Valuation valuation;

  /// 数量×単価の資産：起点の保有数と単価
  final int quantityX1e4;
  final int? priceX100;

  /// 評価額の資産：起点の評価額
  final int balance;
  final double annualRate;

  /// 指定した価値（起点日より後のものが見込みとして使われる）
  final List<ValuePoint> values;
}

/// 計画行（plan_line）のうち計算に使う項目。
class SimLine {
  const SimLine({
    required this.ym,
    required this.kind,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.quantityX1e4,
  });

  final YearMonth ym;
  final TxnKind kind;
  final int amount;
  final String accountId;
  final String? toAccountId;
  final String? assetId;
  final AssetAction? assetAction;
  final int? quantityX1e4;
}

/// 月末1か月分の計画線。
class SimMonth {
  const SimMonth({
    required this.ym,
    required this.total,
    required this.accountsTotal,
    required this.assetsTotal,
    required this.cashLikeTotal,
    this.assetValues = const {},
  });

  final YearMonth ym;

  /// 総資産＝口座残高の合計＋資産の評価額の合計
  final int total;
  final int accountsTotal;
  final int assetsTotal;
  final int cashLikeTotal;

  /// 資産ごとの評価額（資産詳細の計画線）
  final Map<String, int> assetValues;
}

class SimResult {
  const SimResult(this.months);

  /// 起点月の翌月から終了月まで
  final List<SimMonth> months;

  /// 現金系口座の合計がマイナスになる最初の年月（なければ null）。設計書 6.5
  YearMonth? get firstShortage =>
      months.where((m) => m.cashLikeTotal < 0).firstOrNull?.ym;

  int? get maxTotal =>
      months.isEmpty ? null : months.map((m) => m.total).reduce(math.max);

  SimMonth? at(YearMonth ym) => months.where((m) => m.ym == ym).firstOrNull;

  /// その年の年末（12月。なければその年の最後の月）
  SimMonth? yearEnd(int year) =>
      at(YearMonth(year, 12)) ??
      months.where((m) => m.ym.year == year).lastOrNull;
}

double _monthlyFactor(double annualRatePercent) =>
    math.pow(1 + annualRatePercent / 100, 1 / 12).toDouble() - 1;

/// 計画線（設計書 6.5）。起点 [baselineDate] の月の翌月から [end] まで、月ごとに
/// 1. その月の計画行を適用し、2. 想定利回りで増やし、3. 総資産を求める。
SimResult simulatePlan({
  required String baselineDate,
  required YearMonth end,
  required List<SimAccount> accounts,
  required List<SimAsset> assets,
  required List<SimLine> lines,
}) {
  final start = YearMonth.ofDateString(baselineDate).addMonths(1);
  final balances = {for (final a in accounts) a.id: a.balance};
  final assetById = {for (final a in assets) a.id: a};
  // 数量×単価：保有数と単価（×100、小数のまま積み上げる）。評価額の資産：評価額（円、小数）
  final qty = {for (final a in assets) a.id: a.quantityX1e4};
  final price = <String, double?>{
    for (final a in assets) a.id: a.priceX100?.toDouble(),
  };
  final value = {for (final a in assets) a.id: a.balance.toDouble()};

  final byMonth = <int, List<SimLine>>{};
  for (final l in lines) {
    if (l.ym < start || l.ym > end) continue; // 起点月までの計画行は使わない
    (byMonth[l.ym.index] ??= []).add(l);
  }

  final months = <SimMonth>[];
  for (var ym = start; ym <= end; ym = ym.addMonths(1)) {
    // 1. 計画行を適用する（口座は 6.1 と同じ）
    for (final l in byMonth[ym.index] ?? const <SimLine>[]) {
      void add(String? id, int delta) {
        if (id == null) return;
        balances[id] = (balances[id] ?? 0) + delta;
      }

      switch (l.kind) {
        case TxnKind.income:
          add(l.accountId, l.amount);
        case TxnKind.expense:
          add(l.accountId, -l.amount);
        case TxnKind.transfer:
          add(l.accountId, -l.amount);
          add(l.toAccountId, l.amount);
      }
      final asset = assetById[l.assetId];
      if (asset == null) continue;
      final p = price[asset.id];
      if (l.assetAction == AssetAction.buy) {
        if (asset.valuation == Valuation.quantity) {
          final q =
              l.quantityX1e4 ??
              (p == null || p <= 0
                  ? 0
                  : quantityForAmount(l.amount, p.round()));
          qty[asset.id] = qty[asset.id]! + q;
          // 単価がまだなければ、この購入の単価を使う
          if (p == null && q > 0) price[asset.id] = l.amount * 1000000 / q;
        } else {
          value[asset.id] = value[asset.id]! + l.amount;
        }
      } else if (l.assetAction == AssetAction.sell) {
        if (asset.valuation == Valuation.quantity) {
          final q =
              l.quantityX1e4 ??
              (p == null || p <= 0
                  ? qty[asset.id]!
                  : quantityForAmount(l.amount, p.round()));
          qty[asset.id] = math.max(0, qty[asset.id]! - q);
        } else {
          value[asset.id] = 0; // 評価額の資産は全部の売却
        }
      }
    }

    // 2. 想定利回りで増やす。資産は、その月末に有効な見込みの価値が起点日より後にあればそれを使う
    for (final a in accounts) {
      final b = balances[a.id]!;
      if (b <= 0 || a.annualRate == 0) continue;
      balances[a.id] = b + ceilYen(b * _monthlyFactor(a.annualRate));
    }
    final monthEnd = ym.lastDayString;
    for (final a in assets) {
      final point = _latestAfter(a.values, baselineDate, monthEnd);
      if (a.valuation == Valuation.quantity) {
        if (point != null) {
          price[a.id] = point.toDouble();
        } else if (price[a.id] != null && a.annualRate != 0) {
          price[a.id] = price[a.id]! * (1 + _monthlyFactor(a.annualRate));
        }
      } else {
        if (value[a.id]! <= 0) continue; // 売却後・未購入は0のまま
        if (point != null) {
          value[a.id] = point / 100;
        } else if (a.annualRate != 0) {
          value[a.id] = value[a.id]! * (1 + _monthlyFactor(a.annualRate));
        }
      }
    }

    // 3. 総資産
    var accountsTotal = 0;
    var cashLike = 0;
    for (final a in accounts) {
      accountsTotal += balances[a.id]!;
      if (a.cashLike) cashLike += balances[a.id]!;
    }
    var assetsTotal = 0;
    final assetValues = <String, int>{};
    for (final a in assets) {
      final v = a.valuation == Valuation.quantity
          ? (price[a.id] == null
                ? 0
                : valuationOf(qty[a.id]!, price[a.id]!.round()))
          : value[a.id]!.round();
      assetValues[a.id] = v;
      assetsTotal += v;
    }
    months.add(
      SimMonth(
        ym: ym,
        total: accountsTotal + assetsTotal,
        accountsTotal: accountsTotal,
        assetsTotal: assetsTotal,
        cashLikeTotal: cashLike,
        assetValues: assetValues,
      ),
    );
  }
  return SimResult(months);
}

/// 起点日より後に有効になり、[date] までに有効な価値の最新。
int? _latestAfter(List<ValuePoint> points, String baselineDate, String date) {
  ValuePoint? best;
  for (final p in points) {
    if (p.effectiveFrom.compareTo(baselineDate) <= 0) continue;
    if (p.effectiveFrom.compareTo(date) > 0) continue;
    if (best == null || p.effectiveFrom.compareTo(best.effectiveFrom) > 0) {
      best = p;
    }
  }
  return best?.valueX100;
}
