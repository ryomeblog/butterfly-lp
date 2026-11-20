import 'package:intl/intl.dart';

final _yen = NumberFormat('#,##0', 'ja_JP');

/// `¥1,234` / `−¥1,234`（マイナスは全角のマイナス記号）。
String formatYen(int amount) {
  final s = _yen.format(amount.abs());
  return amount < 0 ? '−¥$s' : '¥$s';
}

/// 符号つき：`+¥1,234` / `−¥1,234` / `¥0`
String formatYenSigned(int amount) {
  if (amount == 0) return '¥0';
  return amount > 0 ? '+${formatYen(amount)}' : formatYen(amount);
}

/// カテゴリの色のパレット（設計書 4.3）。
const categoryPalette = <String>[
  '#4E79A7',
  '#F28E2B',
  '#E15759',
  '#76B7B2',
  '#59A14F',
  '#EDC948',
  '#B07AA1',
  '#FF9DA7',
  '#9C755F',
  '#BAB0AC',
];

/// パレットにない色を取り込んだときに使うグレー（設計書 6.9）。
const paletteGray = '#BAB0AC';

String normalizePaletteColor(String color) {
  final upper = color.toUpperCase();
  return categoryPalette.contains(upper) ? upper : paletteGray;
}
