import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'statement.dart';

/// Excel（.xlsx）の1シート。セルは文字列（数値・日付のシリアル値も文字列のまま）。
class XlsxSheet {
  const XlsxSheet(this.name, this.rows);
  final String name;
  final List<List<String?>> rows;

  int get columnCount => rows.fold(0, (m, r) => r.length > m ? r.length : m);
}

/// .xlsx を読む（設計書 3.11）。数式の結果・共有文字列・インライン文字列に対応する。
List<XlsxSheet> readXlsx(List<int> bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const StatementFormatException('Excel（.xlsx）のファイルではありません');
  }
  String? text(String path) {
    final f = archive.findFile(path);
    return f == null ? null : utf8.decode(f.content, allowMalformed: true);
  }

  final workbook = text('xl/workbook.xml');
  if (workbook == null) {
    throw const StatementFormatException('Excel（.xlsx）のファイルではありません');
  }
  final shared = <String>[];
  final sst = text('xl/sharedStrings.xml');
  if (sst != null) {
    for (final si in XmlDocument.parse(sst).findAllElements('si')) {
      shared.add(si.findAllElements('t').map((t) => t.innerText).join());
    }
  }
  // シート名 → ファイル（rels で対応づける）
  final rels = <String, String>{};
  final relText = text('xl/_rels/workbook.xml.rels');
  if (relText != null) {
    for (final r in XmlDocument.parse(
      relText,
    ).findAllElements('Relationship')) {
      final target = r.getAttribute('Target') ?? '';
      rels[r.getAttribute('Id') ?? ''] = target.startsWith('/')
          ? target.substring(1)
          : 'xl/$target';
    }
  }
  final sheets = <XlsxSheet>[];
  var index = 0;
  for (final s in XmlDocument.parse(workbook).findAllElements('sheet')) {
    index++;
    final rid = s.attributes
        .where((a) => a.name.local == 'id')
        .map((a) => a.value)
        .firstOrNull;
    final path = rels[rid] ?? 'xl/worksheets/sheet$index.xml';
    final xml = text(path);
    if (xml == null) continue;
    sheets.add(
      XlsxSheet(s.getAttribute('name') ?? 'Sheet$index', _rows(xml, shared)),
    );
  }
  return sheets;
}

List<List<String?>> _rows(String xml, List<String> shared) {
  final rows = <List<String?>>[];
  for (final row in XmlDocument.parse(xml).findAllElements('row')) {
    final rIndex = int.tryParse(row.getAttribute('r') ?? '') ?? rows.length + 1;
    while (rows.length < rIndex - 1) {
      rows.add(<String?>[]);
    }
    final cells = <String?>[];
    for (final c in row.findElements('c')) {
      final ref = c.getAttribute('r');
      final col = ref == null ? cells.length : columnIndex(ref);
      while (cells.length < col) {
        cells.add(null);
      }
      final type = c.getAttribute('t');
      String? v;
      if (type == 'inlineStr') {
        v = c.findAllElements('t').map((t) => t.innerText).join();
      } else {
        final raw = c.getElement('v')?.innerText;
        if (raw != null && type == 's') {
          final i = int.tryParse(raw);
          v = i != null && i < shared.length ? shared[i] : null;
        } else {
          v = raw;
        }
      }
      cells.add(v);
    }
    rows.add(cells);
  }
  return rows;
}

/// 「B12」→ 1（列は0始まり）。
int columnIndex(String ref) {
  var n = 0;
  for (final c in ref.codeUnits) {
    if (c < 0x41 || c > 0x5A) break;
    n = n * 26 + (c - 0x40);
  }
  return n - 1;
}

/// 0 → 「A」。
String columnName(int index) {
  var n = index + 1;
  final b = StringBuffer();
  while (n > 0) {
    final r = (n - 1) % 26;
    b.write(String.fromCharCode(0x41 + r));
    n = (n - 1) ~/ 26;
  }
  return b.toString().split('').reversed.join();
}
