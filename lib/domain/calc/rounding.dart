/// 端数処理（設計書 6.3・6.5：上昇率・利回り・割合の項目は円未満切り上げ）。
///
/// 浮動小数の誤差（例 300000×1.015＝304500.00000000006）で1円多く切り上がらないよう、
/// ごく小さな誤差は切り捨ててから切り上げる。
int ceilYen(double v) {
  final r = v.roundToDouble();
  if ((v - r).abs() < 1e-6) return r.toInt();
  return v.ceil();
}

/// 円未満切り捨て（購入金額＝数量×単価、税額の初期値など）。
int floorYen(double v) {
  final r = v.roundToDouble();
  if ((v - r).abs() < 1e-6) return r.toInt();
  return v.floor();
}
