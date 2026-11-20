import 'package:butterfly_lp/core/money.dart';
import 'package:butterfly_lp/core/time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updated_at はUTCのミリ秒付きISO8601（マイクロ秒は出さない）', () {
    final t = DateTime.utc(2026, 1, 2, 3, 4, 5, 6, 789);
    expect(timestampOf(t), '2026-01-02T03:04:05.006Z');
  });

  test('ローカル時刻はUTCに直す', () {
    final local = DateTime(2026, 1, 2, 9);
    expect(timestampOf(local), timestampOf(local.toUtc()));
  });

  group('YearMonth', () {
    test('加算と年またぎ', () {
      expect(YearMonth(2026, 11).addMonths(3).toString(), '2027-02');
      expect(YearMonth(2026, 1).addMonths(-1).toString(), '2025-12');
    });
    test('月の日数（うるう年）', () {
      expect(YearMonth(2028, 2).daysInMonth, 29);
      expect(YearMonth(2026, 2).lastDayString, '2026-02-28');
    });
    test('比較', () {
      expect(YearMonth.parse('2026-04') < YearMonth.parse('2026-05'), isTrue);
      expect(YearMonth(2026, 4).monthsUntil(YearMonth(2027, 3)), 11);
    });
  });

  test('満年齢', () {
    expect(ageAt('1990-04-10', DateTime(2026, 4, 9)), 35);
    expect(ageAt('1990-04-10', DateTime(2026, 4, 10)), 36);
  });

  group('金額の表示', () {
    test('桁区切りとマイナス', () {
      expect(formatYen(1234567), '¥1,234,567');
      expect(formatYen(-500), '−¥500');
      expect(formatYenSigned(500), '+¥500');
      expect(formatYenSigned(0), '¥0');
    });
    test('パレットにない色はグレー', () {
      expect(normalizePaletteColor('#4e79a7'), '#4E79A7');
      expect(normalizePaletteColor('#1D4ED8'), '#BAB0AC');
    });
  });
}
