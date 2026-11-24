import 'package:flutter/foundation.dart';

/// 動いている版（設計書 1.1・3.12）。
///
/// dart:io の Platform は Web で使えないので、[defaultTargetPlatform] と [kIsWeb] で見分ける。
abstract final class AppPlatform {
  static bool get isWeb => kIsWeb;

  /// スマホ版（Android）。
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// デスクトップ版（macOS・Windows）。
  static bool get isDesktop => !kIsWeb && !isMobile;

  /// 自宅 Redis との同期を使えるか（Web 版は使えない）。
  static bool get canSync => !kIsWeb;

  /// カメラで QR を読めるか（mobile_scanner は Windows に対応していない）。
  static bool get canScanQr =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;

  /// 明細（Amazon・Excel・PDF）を読めるか（設計書 3.11。デスクトップ版・Web版だけ）。
  static bool get canReadStatements => !isMobile;
}
