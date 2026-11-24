/// 明細の取り込み（設計書 3.11）で読み取った1行。
///
/// [amount] は明細のままの符号付き。マイナスは返金・値引きなどで、登録するときは収入にする。
class StatementLine {
  const StatementLine({
    required this.date,
    required this.content,
    required this.amount,
  });

  /// YYYY-MM-DD
  final String date;

  /// 内容（店名・商品名）。カテゴリの規則の照合に使う
  final String content;
  final int amount;

  @override
  String toString() => 'StatementLine($date, $content, $amount)';
}

/// 読み取りの結果。[skipped] は読めなかった行（確認画面に件数を出す）。
class StatementResult {
  const StatementResult(this.lines, {this.skipped = 0});
  final List<StatementLine> lines;
  final int skipped;
}

/// 明細を読めなかった（形式が違うなど）。
class StatementFormatException implements Exception {
  const StatementFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 年月日から YYYY-MM-DD を作る。ありえない日付なら null。
String? ymd(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > 31 || y < 1900 || y > 2200) return null;
  final dt = DateTime.utc(y, m, d);
  if (dt.month != m || dt.day != d) return null;
  return '$y-${_two(m)}-${_two(d)}';
}

/// 全角の数字・記号を半角にする。
String toHalfWidth(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xFF01 && r <= 0xFF5E) {
      b.writeCharCode(r - 0xFEE0);
    } else if (r == 0x3000) {
      b.write(' ');
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

final _dateFull = RegExp(
  r'^(\d{4})\s*[/.\-年]\s*(\d{1,2})\s*[/.\-月]\s*(\d{1,2})\s*日?',
);
final _dateShortYear = RegExp(r'^(\d{2})[/.](\d{1,2})[/.](\d{1,2})(?!\d)');
final _dateNoYear = RegExp(r'^(\d{1,2})\s*[/月]\s*(\d{1,2})\s*日?(?![\d/])');

/// 文字列の先頭の日付を読む。年がない日付は [defaultYear] にする。
/// 読めれば (YYYY-MM-DD, 日付の文字数)。
(String, int)? parseLeadingDate(String text, {required int defaultYear}) {
  final s = toHalfWidth(text);
  var m = _dateFull.firstMatch(s);
  if (m != null) {
    final d = ymd(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    return d == null ? null : (d, m.end);
  }
  m = _dateShortYear.firstMatch(s);
  if (m != null) {
    final d = ymd(2000 + int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    return d == null ? null : (d, m.end);
  }
  m = _dateNoYear.firstMatch(s);
  if (m != null) {
    final d = ymd(defaultYear, int.parse(m[1]!), int.parse(m[2]!));
    return d == null ? null : (d, m.end);
  }
  return null;
}

/// Excel の日付のシリアル値（1900年方式）を YYYY-MM-DD にする。
String? excelSerialToDate(num serial) {
  if (serial < 1 || serial > 200000) return null;
  final d = DateTime.utc(1899, 12, 30).add(Duration(days: serial.floor()));
  return ymd(d.year, d.month, d.day);
}

/// セルの日付を読む（シリアル値・文字列のどちらも）。
String? parseDateCell(String? cell, {required int defaultYear}) {
  if (cell == null) return null;
  final t = cell.trim();
  if (t.isEmpty) return null;
  final n = num.tryParse(t);
  if (n != null && !t.contains('/') && !t.contains('-')) {
    return excelSerialToDate(n);
  }
  final r = parseLeadingDate(t, defaultYear: defaultYear);
  return r?.$1;
}

final _amount = RegExp(
  r'^([-−‐ー△▲])?\s*[¥\\￥]?\s*([-−])?\s*(\d{1,3}(?:,\d{3})+|\d+)(?:\.(\d+))?\s*円?$',
);
final _paren = RegExp(r'^\((.+)\)$');

/// 金額を読む（「1,234」「¥1,234」「1234円」「-1,234」「△1,234」「(1,234)」）。読めなければ null。
int? parseAmount(String? text) {
  if (text == null) return null;
  var s = toHalfWidth(text).trim().replaceAll(' ', '');
  if (s.isEmpty) return null;
  var negative = false;
  final p = _paren.firstMatch(s);
  if (p != null) {
    negative = true;
    s = p[1]!;
  }
  final m = _amount.firstMatch(s);
  if (m == null) return null;
  if (m[1] != null || m[2] != null) negative = !negative;
  var v = int.parse(m[3]!.replaceAll(',', ''));
  final frac = m[4];
  if (frac != null && frac.isNotEmpty && frac[0].compareTo('5') >= 0) v += 1;
  return negative ? -v : v;
}
