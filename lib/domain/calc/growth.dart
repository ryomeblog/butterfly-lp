import 'dart:math' as math;

import 'rounding.dart';

/// 上昇率で増やした金額（設計書 6.3 手順2）。
///
/// 金額×(1＋率)^(対象年−開始年)、円未満切り上げ。[annualRatePercent] は年率%（例 1.5）。
/// 対象年が開始年以前なら増やさない。
int grownAmount(int baseAmount, double annualRatePercent, int years) {
  if (years <= 0 || annualRatePercent == 0) return baseAmount;
  final factor = math.pow(1 + annualRatePercent / 100, years).toDouble();
  return ceilYen(baseAmount * factor);
}
