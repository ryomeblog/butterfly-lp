import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 一時ファイルに書き、そのパスを返す（共有シートに渡すため。Android）。
Future<String> writeTempFile(String fileName, List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
