import 'package:butterfly_lp/domain/calc/growth.dart';
import 'package:butterfly_lp/domain/calc/rounding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('端数', () {
    test('切り上げ：浮動小数の誤差で1円多くならない', () {
      expect(300000 * 1.015, isNot(304500)); // 304500.00000000006
      expect(ceilYen(300000 * 1.015), 304500);
    });
    test('切り上げ：端数があれば上げる', () {
      expect(ceilYen(100.01), 101);
      expect(ceilYen(100.5), 101);
    });
    test('切り捨て', () {
      expect(floorYen(100.99), 100);
      expect(floorYen(99.9999999999), 100);
    });
  });

  group('grownAmount（6.3 手順2）', () {
    test('開始年は増やさない', () {
      expect(grownAmount(300000, 1.5, 0), 300000);
    });
    test('1年後・5年後・10年後（複利・切り上げ）', () {
      expect(grownAmount(300000, 1.5, 1), 304500);
      // 300000×1.015^5 = 323185.2...
      expect(grownAmount(300000, 1.5, 5), 323186);
      // 300000×1.015^10 = 348162.1...
      expect(grownAmount(300000, 1.5, 10), 348163);
    });
    test('率0は増やさない', () {
      expect(grownAmount(12345, 0, 10), 12345);
    });
    test('マイナスの率（下落）', () {
      // 100000×0.99^2 = 98010
      expect(grownAmount(100000, -1, 2), 98010);
    });
  });
}
