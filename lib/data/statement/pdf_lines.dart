import 'statement.dart';

/// 1文字と、その位置（PDF の座標。y は上向き）。
class PositionedChar {
  const PositionedChar(this.char, this.left, this.right, this.bottom, this.top);
  final String char;
  final double left;
  final double right;
  final double bottom;
  final double top;
  double get height => top - bottom;
  double get centerY => (top + bottom) / 2;
}

/// 文字の位置から、見た目どおりの行を作る（同じ高さの文字を左から並べ、離れていれば空白を入れる）。
List<String> buildLines(List<PositionedChar> chars) {
  final visible = chars.where((c) => c.char.trim().isNotEmpty).toList();
  if (visible.isEmpty) return const [];
  // 上から順に、行の中心の高さで束ねる
  visible.sort((a, b) => b.centerY.compareTo(a.centerY));
  final rows = <List<PositionedChar>>[];
  for (final c in visible) {
    final last = rows.isEmpty ? null : rows.last;
    if (last != null) {
      final ref = last.first;
      final tol = (ref.height > 0 ? ref.height : 8) * 0.5;
      if ((ref.centerY - c.centerY).abs() <= tol) {
        last.add(c);
        continue;
      }
    }
    rows.add([c]);
  }
  return [
    for (final r in rows) _join(r..sort((a, b) => a.left.compareTo(b.left))),
  ];
}

String _join(List<PositionedChar> row) {
  final b = StringBuffer();
  PositionedChar? prev;
  for (final c in row) {
    if (prev != null) {
      final h = prev.height > 0 ? prev.height : 8;
      if (c.left - prev.right > h * 0.6) b.write(' ');
    }
    b.write(c.char);
    prev = c;
  }
  return b.toString();
}

final _amountToken = RegExp(
  r'^[-−‐△▲]?[¥\\￥]?[-−]?(\d{1,3}(,\d{3})+|\d+)円?$|^\(\d{1,3}(,\d{3})*\)$',
);

/// 「日付 内容 金額」の並びの行を読む（設計書 3.11）。
///
/// 日付は行の先頭。金額は、内容のあとで最初に現れる金額の形の語（「1回払い」などは金額にしない）。
/// 年のない日付（「10/03」）は [defaultYear] の年にする。
StatementResult parseStatementLines(
  List<String> lines, {
  required int defaultYear,
}) {
  final out = <StatementLine>[];
  var skipped = 0;
  for (final raw in lines) {
    final line = toHalfWidth(raw).trim();
    final d = parseLeadingDate(line, defaultYear: defaultYear);
    if (d == null) continue;
    final rest = line.substring(d.$2).trim().split(RegExp(r'\s+'));
    final content = <String>[];
    int? amount;
    for (final t in rest) {
      if (t.isEmpty) continue;
      if (content.isNotEmpty && _amountToken.hasMatch(t)) {
        amount = parseAmount(t);
        break;
      }
      content.add(t);
    }
    if (amount == null || amount == 0 || content.isEmpty) {
      skipped++;
      continue;
    }
    out.add(
      StatementLine(date: d.$1, content: content.join(' '), amount: amount),
    );
  }
  return StatementResult(out, skipped: skipped);
}
