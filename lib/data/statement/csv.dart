/// CSV（RFC 4180）を行と列に分ける。先頭の BOM は外す。
List<List<String>> parseCsv(String text) {
  var s = text;
  if (s.startsWith('﻿')) s = s.substring(1);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var i = 0;
  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
    row = <String>[];
  }

  while (i < s.length) {
    final c = s[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      endField();
    } else if (c == '\r') {
      if (i + 1 < s.length && s[i + 1] == '\n') i++;
      endRow();
    } else if (c == '\n') {
      endRow();
    } else {
      field.write(c);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}
