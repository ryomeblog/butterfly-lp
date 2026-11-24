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
import '../../data/io/json_import.dart';

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
///
/// 各画面の「取り込む」は、その画面に合う種類（[expect]）のファイルだけを受け付ける（設計書 3.9）。
/// 違う種類なら、取り込める画面を案内する。
Future<void> pickAndImportJson(
  BuildContext context, {
  required FileUnit expect,
}) async {
  final f = await pickFile();
  if (f == null || !context.mounted) return;
  void snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  Object? json;
  try {
    json = jsonDecode(utf8.decode(f.bytes));
  } catch (_) {
    json = null;
  }
  if (json is! Map<String, dynamic>) {
    snack('JSONファイルとして読めませんでした');
    return;
  }
  final String? mismatch;
  try {
    final unit = FileUnit.of(json);
    mismatch = unit == expect
        ? null
        : 'このファイルは「${unit.label}」のファイルです。${unit.where}から取り込んでください。';
  } on ImportFormatError catch (e) {
    snack(e.message);
    return;
  }
  if (mismatch != null) {
    snack(mismatch);
    return;
  }
  await context.push('/entry/json-import', extra: (name: f.name, json: json));
}

/// 取り込みの入口のボタン（各一覧の画面に置く）。
class ImportJsonButton extends StatelessWidget {
  const ImportJsonButton({super.key, required this.expect});

  final FileUnit expect;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: Key('import-${expect.name}'),
    onPressed: () => pickAndImportJson(context, expect: expect),
    icon: const Icon(Icons.file_download_outlined),
    label: Text('${expect.label}のJSONを取り込む'),
  );
}
