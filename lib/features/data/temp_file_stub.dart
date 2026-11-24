/// Web 版では使わない（ファイルはダウンロードで保存する）。
Future<String> writeTempFile(String fileName, List<int> bytes) =>
    throw UnsupportedError('Web 版では一時ファイルを作れません');
