import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/statement_repository.dart';
import 'package:butterfly_lp/data/statement/amazon.dart';
import 'package:butterfly_lp/data/statement/csv.dart';
import 'package:butterfly_lp/data/statement/pdf_lines.dart';
import 'package:butterfly_lp/data/statement/statement.dart';
import 'package:butterfly_lp/data/statement/table_mapping.dart';
import 'package:butterfly_lp/data/statement/xlsx.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// テスト用の最小の .xlsx（共有文字列・数値・インライン文字列）。
List<int> _xlsx(List<List<Object?>> rows, {String sheetName = '明細'}) {
  final shared = <String>[];
  final sheet = StringBuffer(
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
  );
  for (final (ri, row) in rows.indexed) {
    sheet.write('<row r="${ri + 1}">');
    for (final (ci, v) in row.indexed) {
      final ref = '${columnName(ci)}${ri + 1}';
      if (v == null) continue;
      if (v is num) {
        sheet.write('<c r="$ref"><v>$v</v></c>');
      } else if (ci == 1) {
        sheet.write('<c r="$ref" t="inlineStr"><is><t>$v</t></is></c>');
      } else {
        shared.add('$v');
        sheet.write('<c r="$ref" t="s"><v>${shared.length - 1}</v></c>');
      }
    }
    sheet.write('</row>');
  }
  sheet.write('</sheetData></worksheet>');
  final a = Archive();
  void add(String name, String text) {
    final b = utf8.encode(text);
    a.add(ArchiveFile(name, b.length, b));
  }

  add(
    'xl/workbook.xml',
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="$sheetName" sheetId="1" r:id="rId1"/></sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
  );
  add(
    'xl/sharedStrings.xml',
    '<sst>${shared.map((s) => '<si><t>$s</t></si>').join()}</sst>',
  );
  add('xl/worksheets/sheet1.xml', sheet.toString());
  return ZipEncoder().encode(a);
}

void main() {
  group('部品', () {
    test('CSV：引用符・改行・BOM', () {
      expect(parseCsv('﻿a,"b,c","d""e"\r\n1,"2\n3",4\n'), [
        ['a', 'b,c', 'd"e'],
        ['1', '2\n3', '4'],
      ]);
    });

    test('金額：区切り・円・マイナスの書き方・小数は四捨五入', () {
      expect(parseAmount('1,234'), 1234);
      expect(parseAmount('¥1,234'), 1234);
      expect(parseAmount('１，２３４円'), 1234);
      expect(parseAmount('-500'), -500);
      expect(parseAmount('△500'), -500);
      expect(parseAmount('(1,000)'), -1000);
      expect(parseAmount('1280.5'), 1281);
      expect(parseAmount('1回払い'), isNull);
      expect(parseAmount(''), isNull);
    });

    test('日付：いろいろな書き方と、年がないときの年', () {
      expect(
        parseLeadingDate('2026/10/3 店', defaultYear: 2000)?.$1,
        '2026-10-03',
      );
      expect(
        parseLeadingDate('2026年10月3日 店', defaultYear: 2000)?.$1,
        '2026-10-03',
      );
      expect(
        parseLeadingDate('26/10/03 店', defaultYear: 2000)?.$1,
        '2026-10-03',
      );
      expect(parseLeadingDate('10/03 店', defaultYear: 2025)?.$1, '2025-10-03');
      expect(parseLeadingDate('2026/02/30', defaultYear: 2000), isNull);
      expect(excelSerialToDate(46298), '2026-10-03');
    });
  });

  group('Amazon の注文履歴', () {
    const header =
        '"Website","Order ID","Order Date","Currency","Unit Price","Total Owed","Product Name","Order Status"';
    const csv =
        '$header\n'
        '"Amazon.co.jp","250-1","2026-10-02T16:30:00Z","JPY","980","980","本A","Closed"\n'
        '"Amazon.co.jp","250-1","2026-10-02T16:30:00Z","JPY","300","300","ペンB","Closed"\n'
        '"Amazon.co.jp","250-2","2026-10-05T01:00:00Z","JPY","1,500","1,500","洗剤","Closed"\n'
        '"Amazon.co.jp","250-3","2026-10-06T01:00:00Z","JPY","2000","2000","取消品","Cancelled"\n'
        '"Amazon.co.jp","250-4","bad","JPY","1","1","壊れた行","Closed"\n';

    test('注文1件を1行にし、金額を合計・日本時間の日付にする。キャンセルは読まない', () {
      final r = parseAmazonOrderHistory(utf8.encode(csv));
      expect(r.lines.map((l) => (l.date, l.content, l.amount)), [
        ('2026-10-03', '本A、ペンB', 1280),
        ('2026-10-05', '洗剤', 1500),
      ]);
      expect(r.skipped, 1);
    });

    test('ZIP の中の CSV も読む', () {
      final a = Archive();
      final b = utf8.encode(csv);
      a.add(
        ArchiveFile(
          'Retail.OrderHistory.1/Retail.OrderHistory.1.csv',
          b.length,
          b,
        ),
      );
      final r = parseAmazonOrderHistory(ZipEncoder().encode(a));
      expect(r.lines, hasLength(2));
    });

    test('違う CSV は分かる言葉で断る', () {
      expect(
        () => parseAmazonOrderHistory(utf8.encode('a,b\n1,2\n')),
        throwsA(isA<StatementFormatException>()),
      );
    });
  });

  group('Excel', () {
    final bytes = _xlsx([
      ['ご利用明細'],
      ['ご利用日', 'ご利用店名', 'ご利用金額', '支払区分'],
      [46298, 'スーパーA', 3200, '1回'],
      ['2026/10/05', 'カフェB', '¥480', '1回'],
      [46300, '返品', -1200, '1回'],
      [null, '合計', 2480],
    ]);

    test('シートを読み、見出しから列を推測し、行を読む（日付はシリアル値も文字列も）', () {
      final sheets = readXlsx(bytes);
      expect(sheets.single.name, '明細');
      final m = TableMapping.guess(sheets.single);
      expect((m.skipRows, m.dateCol, m.contentCol, m.amountCol), (2, 0, 1, 2));
      final r = m.apply(sheets.single, defaultYear: 2026);
      expect(r.lines.map((l) => (l.date, l.content, l.amount)), [
        ('2026-10-03', 'スーパーA', 3200),
        ('2026-10-05', 'カフェB', 480),
        ('2026-10-05', '返品', -1200),
      ]);
      expect(r.skipped, 1); // 合計の行
      expect(TableMapping.decode(m.encode())!.amountCol, 2);
    });

    test('Excel でないファイルは断る', () {
      expect(
        () => readXlsx(utf8.encode('not zip')),
        throwsA(isA<StatementFormatException>()),
      );
    });
  });

  group('PDF の行', () {
    test('同じ高さの文字を1行にし、離れていれば空白を入れる', () {
      PositionedChar ch(String c, double x, double y) =>
          PositionedChar(c, x, x + 10, y, y + 10);
      final lines = buildLines([
        ch('B', 0, 80),
        ch('1', 0, 100),
        ch('A', 10, 100.5),
        ch('9', 60, 100),
        ch('C', 10, 80),
      ]);
      expect(lines, ['1A 9', 'BC']);
    });

    test('「日付 内容 金額」の行だけを読み、支払回数などは金額にしない', () {
      final r = parseStatementLines([
        'ご利用明細書',
        '2026/10/03 セブンイレブン 1回払い 540 540',
        '10/05 東京電力 8,120',
        '2026/10/07 返品 -1,000',
        '2026/10/08 金額なし',
      ], defaultYear: 2026);
      expect(r.lines.map((l) => (l.date, l.content, l.amount)), [
        ('2026-10-03', 'セブンイレブン 1回払い', 540),
        ('2026-10-05', '東京電力', 8120),
        ('2026-10-07', '返品', -1000),
      ]);
      expect(r.skipped, 1);
    });
  });

  group('登録と規則', () {
    late AppDatabase db;
    late StatementRepository repo;
    setUp(() {
      db = memoryDb();
      repo = StatementRepository(db, const Stamp(testDeviceId));
    });
    tearDown(() => db.close());

    test('実績にし、内容→カテゴリを覚える（種類ごと・完全一致だけ）', () async {
      final n = await repo.register(
        planId: 'P',
        accountId: 'card',
        asPlan: false,
        entries: const [
          StatementEntry(
            date: '2026-10-03',
            kind: TxnKind.expense,
            amount: 540,
            categoryId: 'food',
            content: 'セブンイレブン',
            memo: 'おにぎり',
          ),
          StatementEntry(
            date: '2026-10-07',
            kind: TxnKind.income,
            amount: 1000,
            categoryId: 'other-in',
            content: '返品',
          ),
        ],
      );
      expect(n, 2);
      final txns = await db.select(db.txns).get();
      expect(
        txns
            .map((t) => (t.date, t.kind, t.amount, t.accountId, t.memo))
            .toSet(),
        {
          ('2026-10-03', 'expense', 540, 'card', 'おにぎり'),
          ('2026-10-07', 'income', 1000, 'card', null),
        },
      );
      expect(await repo.rulesFor(TxnKind.expense, ['セブンイレブン', 'セブン', '返品']), {
        'セブンイレブン': 'food',
      });
      expect(await repo.rulesFor(TxnKind.income, ['返品']), {'返品': 'other-in'});
    });

    test('予定にするときは日付の年月の手入力の予定。規則は後から上書きする', () async {
      Future<void> reg(String cat) => repo.register(
        planId: 'P',
        accountId: 'card',
        asPlan: true,
        entries: [
          StatementEntry(
            date: '2026-11-20',
            kind: TxnKind.expense,
            amount: 8000,
            categoryId: cat,
            content: '東京電力',
          ),
        ],
      );
      await reg('util');
      await reg('util2');
      final lines = await db.select(db.planLines).get();
      expect(lines.map((l) => (l.year, l.month, l.source, l.amount)), [
        (2026, 11, 'manual', 8000),
        (2026, 11, 'manual', 8000),
      ]);
      expect(await db.select(db.txns).get(), isEmpty);
      expect(await repo.rulesFor(TxnKind.expense, ['東京電力']), {'東京電力': 'util2'});
    });

    test('端末の設定を覚える', () async {
      expect(await repo.pref('k'), isNull);
      await repo.setPref('k', 'a');
      await repo.setPref('k', 'b');
      expect(await repo.pref('k'), 'b');
    });
  });
}
