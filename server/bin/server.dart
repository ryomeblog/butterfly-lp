import 'dart:io';

import 'package:butterfly_lp_server/share_server.dart';

/// 起動：`dart run bin/server.dart`（環境変数で設定する）
///
/// - PORT：待ち受けるポート（既定 8080）
/// - WEB_DIR：Web 版のフォルダ（既定 ../build/web。なければ配信しない）
/// - DATA_DIR：共有を置くフォルダ（既定 ./data）
/// - MAX_MB：1件の上限（MB。既定 20）
Future<void> main() async {
  final env = Platform.environment;
  final web = env['WEB_DIR'] ?? '../build/web';
  final config = ServerConfig(
    dataDir: env['DATA_DIR'] ?? 'data',
    webDir: Directory(web).existsSync() ? web : null,
    maxBytes: (int.tryParse(env['MAX_MB'] ?? '') ?? 20) * 1024 * 1024,
  );
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  final s = await ShareServer(config).start(port: port);
  stdout.writeln(
    'バタフライLP サーバー: http://${s.address.host}:${s.port}/ '
    '(Web: ${config.webDir ?? 'なし'}, 共有: ${config.dataDir})',
  );
  ProcessSignal.sigint.watch().listen((_) => exit(0));
}
