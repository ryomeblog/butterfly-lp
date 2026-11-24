import 'dart:convert';

import 'statement.dart';
import 'xlsx.dart';

/// Excel の列の指定（設計書 3.11。端末に覚える）。
class TableMapping {
  const TableMapping({
    required this.sheet,
    required this.skipRows,
    required this.dateCol,
    required this.contentCol,
    required this.amountCol,
  });

  final String sheet;

  /// 先頭から読み飛ばす行数（見出しなど）
  final int skipRows;
  final int dateCol;
  final int contentCol;
  final int amountCol;

  TableMapping copyWith({
    String? sheet,
    int? skipRows,
    int? dateCol,
    int? contentCol,
    int? amountCol,
  }) => TableMapping(
    sheet: sheet ?? this.sheet,
    skipRows: skipRows ?? this.skipRows,
    dateCol: dateCol ?? this.dateCol,
    contentCol: contentCol ?? this.contentCol,
    amountCol: amountCol ?? this.amountCol,
  );

  String encode() => jsonEncode({
    'sheet': sheet,
    'skip': skipRows,
    'date': dateCol,
    'content': contentCol,
    'amount': amountCol,
  });

  static TableMapping? decode(String? s) {
    if (s == null) return null;
    try {
      final m = jsonDecode(s) as Map<String, Object?>;
      return TableMapping(
        sheet: m['sheet'] as String,
        skipRows: m['skip'] as int,
        dateCol: m['date'] as int,
        contentCol: m['content'] as int,
        amountCol: m['amount'] as int,
      );
    } catch (_) {
      return null;
    }
  }

  /// 見出しの語から列を推測する。見つからなければ A・B・C。
  static TableMapping guess(XlsxSheet sheet) {
    const dateWords = ['利用日', 'ご利用日', '日付', '取引日', '購入日', '年月日', 'Date'];
    const contentWords = [
      '利用店名',
      'ご利用店名',
      '内容',
      '摘要',
      '店名',
      '品名',
      '商品名',
      '利用先',
      'ご利用先',
    ];
    const amountWords = ['利用金額', 'ご利用金額', '金額', '支払金額', '請求金額', 'Amount'];
    for (var r = 0; r < sheet.rows.length && r < 30; r++) {
      final row = sheet.rows[r];
      int find(List<String> words) {
        for (final w in words) {
          for (var c = 0; c < row.length; c++) {
            if ((row[c] ?? '').replaceAll(RegExp(r'\s'), '').contains(w)) {
              return c;
            }
          }
        }
        return -1;
      }

      final d = find(dateWords);
      final a = find(amountWords);
      if (d >= 0 && a >= 0) {
        final c = find(contentWords);
        return TableMapping(
          sheet: sheet.name,
          skipRows: r + 1,
          dateCol: d,
          contentCol: c >= 0 ? c : (d + 1 == a ? d + 2 : d + 1),
          amountCol: a,
        );
      }
    }
    return TableMapping(
      sheet: sheet.name,
      skipRows: 0,
      dateCol: 0,
      contentCol: 1,
      amountCol: 2,
    );
  }

  /// 指定どおりに行を読む。日付か金額が読めない行は読み飛ばす（見出し・合計行など）。
  StatementResult apply(XlsxSheet sheet, {required int defaultYear}) {
    final lines = <StatementLine>[];
    var skipped = 0;
    for (final row in sheet.rows.skip(skipRows)) {
      String? at(int i) => i >= 0 && i < row.length ? row[i] : null;
      if (row.every((c) => c == null || c.trim().isEmpty)) continue;
      final date = parseDateCell(at(dateCol), defaultYear: defaultYear);
      final amount = parseAmount(at(amountCol));
      if (date == null || amount == null || amount == 0) {
        skipped++;
        continue;
      }
      lines.add(
        StatementLine(
          date: date,
          content: (at(contentCol) ?? '').trim(),
          amount: amount,
        ),
      );
    }
    return StatementResult(lines, skipped: skipped);
  }
}
