import 'package:flutter/material.dart';

/// Material 3 標準・青系（#1D4ED8 付近）・端末設定に合わせたダークモード（設計書 11）。
const _seed = Color(0xFF1D4ED8);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  );
}

/// 金額の色（収入＝青系、支出＝赤系）。
extension MoneyColors on ColorScheme {
  Color get incomeColor => primary;
  Color get expenseColor => error;
}
