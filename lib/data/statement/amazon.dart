import 'dart:convert';

import 'package:archive/archive.dart';

import 'csv.dart';
import 'statement.dart';

/// Amazon の注文履歴（「データのリクエスト」の Retail.OrderHistory の CSV。設計書 3.11）。
///
/// 注文1件を1行にし、同じ注文番号の商品の金額（Total Owed）を合計する。内容は商品名を「、」でつなぐ。
/// 注文日は UTC なので日本時間の日付にする。キャンセルした注文は読まない。
/// [bytes] は CSV か、それを含む ZIP。
StatementResult parseAmazonOrderHistory(List<int> bytes) {
  final csvs = _csvTexts(bytes);
  if (csvs.isEmpty) {
    throw const StatementFormatException(
      '注文履歴の CSV（Retail.OrderHistory）が見つかりません',
    );
  }
  final orders = <String, _Order>{};
  var skipped = 0;
  for (final text in csvs) {
    final rows = parseCsv(text);
    if (rows.isEmpty) continue;
    final header = rows.first.map((h) => h.trim()).toList();
    int col(List<String> names) {
      for (final n in names) {
        final i = header.indexOf(n);
        if (i >= 0) return i;
      }
      return -1;
    }

    final cId = col(['Order ID']);
    final cDate = col(['Order Date']);
    final cTotal = col(['Total Owed', 'Total Amount']);
    final cName = col(['Product Name']);
    final cStatus = col(['Order Status']);
    if (cId < 0 || cDate < 0 || cTotal < 0) {
      throw const StatementFormatException(
        'Amazon の注文履歴の CSV ではありません（Order ID・Order Date・Total Owed の列がありません）',
      );
    }
    for (final r in rows.skip(1)) {
      String at(int i) => i >= 0 && i < r.length ? r[i].trim() : '';
      final status = at(cStatus).toLowerCase();
      if (status.startsWith('cancel')) continue;
      final id = at(cId);
      final date = _jstDate(at(cDate));
      final amount = parseAmount(at(cTotal));
      if (id.isEmpty || date == null || amount == null) {
        skipped++;
        continue;
      }
      final o = orders.putIfAbsent(id, () => _Order(date));
      o.amount += amount;
      final name = at(cName);
      if (name.isNotEmpty && !o.names.contains(name)) o.names.add(name);
    }
  }
  final lines = [
    for (final o in orders.values)
      if (o.amount != 0)
        StatementLine(
          date: o.date,
          content: o.names.isEmpty ? 'Amazon' : o.names.join('、'),
          amount: o.amount,
        ),
  ]..sort((a, b) => a.date.compareTo(b.date));
  return StatementResult(lines, skipped: skipped);
}

class _Order {
  _Order(this.date);
  final String date;
  int amount = 0;
  final names = <String>[];
}

List<String> _csvTexts(List<int> bytes) {
  // ZIP（PK\x03\x04）なら、中の Retail.OrderHistory*.csv を全部読む
  if (bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
    final archive = ZipDecoder().decodeBytes(bytes);
    return [
      for (final f in archive.files)
        if (f.isFile &&
            f.name.toLowerCase().endsWith('.csv') &&
            f.name.contains('OrderHistory'))
          utf8.decode(f.content, allowMalformed: true),
    ];
  }
  return [utf8.decode(bytes, allowMalformed: true)];
}

String? _jstDate(String s) {
  if (s.isEmpty) return null;
  final dt = DateTime.tryParse(s);
  if (dt == null) return null;
  // 時差が書かれていなければ UTC とみなす
  final utc = (s.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s))
      ? dt.toUtc()
      : DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
  final j = utc.add(const Duration(hours: 9));
  return ymd(j.year, j.month, j.day);
}
