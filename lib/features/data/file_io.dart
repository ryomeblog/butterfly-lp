import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
import '../../data/io/json_export.dart';

/// ファイルを作り、共有シート（ファイルに保存・ドライブ・メールなど）で書き出す。
Future<void> shareFile(
  String fileName,
  List<int> bytes, {
  String mime = 'application/json',
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mime)],
      subject: fileName,
    ),
  );
}

/// ファイルを選んで中身を読む。選ばなければ null。
Future<({String name, List<int> bytes})?> pickFile() async {
  final files = await FilePicker.pickFiles();
  final f = files.firstOrNull;
  if (f == null) return null;
  return (name: f.name, bytes: await f.readAsBytes());
}

String _stamp() => todayString().replaceAll('-', '');

/// JSON を作って書き出す（収支1件・リスト・資産・プランなどの各画面の右上から使う）。
Future<void> exportJson(
  BuildContext context,
  WidgetRef ref,
  String label,
  Future<Map<String, Object?>> Function(JsonExporter e) build,
) async {
  final json = await build(JsonExporter(ref.read(databaseProvider)));
  await shareFile(
    'lifeplan-$label-${_stamp()}.json',
    utf8.encode(JsonExporter.encode(json)),
  );
}

/// JSON のファイルを選び、取り込みの確認画面を開く。
Future<void> pickAndImportJson(BuildContext context) async {
  final f = await pickFile();
  if (f == null || !context.mounted) return;
  Object? json;
  try {
    json = jsonDecode(utf8.decode(f.bytes));
  } catch (_) {
    json = null;
  }
  if (json is! Map<String, dynamic>) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('JSONファイルとして読めませんでした')));
    return;
  }
  await context.push('/entry/json-import', extra: (name: f.name, json: json));
}
