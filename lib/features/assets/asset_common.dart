import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/asset_repository.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/models/enums.dart';

/// 表示プランの資産ごとの状態を、指定日（含む）時点で計算する。
Map<String, AssetState> assetStatesAt(
  WidgetRef ref,
  String planId,
  List<AssetRow> assets,
  String date,
) {
  final txns =
      ref.watch(planAssetTxnsProvider(planId)).value ?? const <TxnRow>[];
  final values =
      ref.watch(planAssetValuesProvider(planId)).value ??
      const <AssetValueRow>[];
  return {
    for (final a in assets)
      a.id: assetStateAt(
        valuation: Valuation.of(a.valuation),
        moves: [
          for (final t in txns)
            if (t.assetId == a.id) AssetRepository.moveOf(t),
        ],
        values: [
          for (final v in values)
            if (v.assetId == a.id) AssetRepository.pointOf(v),
        ],
        date: date,
      ),
  };
}

/// 価値（×100）を円の文字列用に（小数第2位まで）。
String formatX100(int x100) {
  final yen = x100 ~/ 100;
  final sen = (x100 % 100).abs();
  final s = yen.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return sen == 0 ? '¥$s' : '¥$s.${sen.toString().padLeft(2, '0')}';
}

/// 数量（×10,000）を小数第4位までの文字列に。
String formatQuantity(int x1e4) {
  final whole = x1e4 ~/ 10000;
  final frac = (x1e4 % 10000).toString().padLeft(4, '0');
  return '$whole.$frac';
}

/// 「12.3456」→ 123456（×10,000。小数第5位以下は切り捨て）。不正なら null。
int? parseQuantity(String s) {
  final t = s.trim();
  if (!RegExp(r'^\d+(\.\d*)?$').hasMatch(t)) return null;
  final parts = t.split('.');
  final frac = (parts.length > 1 ? parts[1] : '')
      .padRight(4, '0')
      .substring(0, 4);
  return int.parse(parts[0]) * 10000 + int.parse(frac);
}

/// 「1234.5」→ 123450（×100。小数第3位以下は切り捨て）。不正なら null。
int? parseX100(String s) {
  final t = s.trim();
  if (!RegExp(r'^\d+(\.\d*)?$').hasMatch(t)) return null;
  final parts = t.split('.');
  final frac = (parts.length > 1 ? parts[1] : '')
      .padRight(2, '0')
      .substring(0, 2);
  return int.parse(parts[0]) * 100 + int.parse(frac);
}
