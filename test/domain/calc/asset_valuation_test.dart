import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/domain/calc/asset_valuation.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('valueAt（価値の求め方）', () {
    const pts = [
      ValuePoint(unit: 'month', date: '2026-01', valueX100: 10000),
      ValuePoint(unit: 'day', date: '2026-01-20', valueX100: 12000),
      ValuePoint(unit: 'month', date: '2026-03', valueX100: 9000),
      ValuePoint(unit: 'day', date: '2026-03-01', valueX100: 9500),
    ];
    test('指定のない日は直前の価値が続く', () {
      expect(valueAt(pts, '2026-01-19'), 10000);
      expect(valueAt(pts, '2026-01-20'), 12000);
      expect(valueAt(pts, '2026-02-28'), 12000);
    });
    test('月単位はその月の1日から有効。同じ日に有効なら日単位を使う', () {
      expect(valueAt(pts, '2026-03-01'), 9500);
    });
    test('価値がない期間は null', () {
      expect(valueAt(pts, '2025-12-31'), isNull);
    });
  });

  group('数量×単価の資産', () {
    // 10口を単価1,000円で、さらに10口を単価2,000円で買い、5口を売る
    final moves = [
      const AssetMove(
        id: 'b1',
        date: '2026-01-10',
        action: AssetAction.buy,
        amount: 10000,
        quantityX1e4: 100000,
      ),
      const AssetMove(
        id: 'b2',
        date: '2026-02-10',
        action: AssetAction.buy,
        amount: 20000,
        quantityX1e4: 100000,
      ),
      const AssetMove(
        id: 'fee',
        date: '2026-02-10',
        action: AssetAction.cost,
        amount: 300,
        parentId: 'b2',
      ),
      const AssetMove(
        id: 's1',
        date: '2026-03-10',
        action: AssetAction.sell,
        amount: 12500,
        quantityX1e4: 50000,
      ),
      const AssetMove(
        id: 'tax',
        date: '2026-03-10',
        action: AssetAction.cost,
        amount: 1000,
        parentId: 's1',
      ),
      const AssetMove(
        id: 'div',
        date: '2026-03-31',
        action: AssetAction.income,
        amount: 800,
      ),
    ];
    const values = [
      ValuePoint(unit: 'month', date: '2026-03', valueX100: 260000),
    ];

    test('保有数・移動平均の取得価額（購入の費用は含めない）', () {
      final s = assetStateAt(
        valuation: Valuation.quantity,
        moves: moves,
        values: values,
        date: '2026-02-28',
      );
      expect(s.quantityX1e4, 200000);
      expect(s.acquisitionCost, 30000);
      // 価値が1つもない期間は取得価額で評価
      expect(s.valuation, 30000);
    });

    test('売却：売却分の取得価額＝取得価額×売却数量÷売却前保有数、実現損益は費用（税も）を引く', () {
      final s = assetStateAt(
        valuation: Valuation.quantity,
        moves: moves,
        values: values,
        date: '2026-03-31',
      );
      expect(s.quantityX1e4, 150000);
      expect(s.sales.single.costOfSold, 7500);
      expect(s.sales.single.realizedGain, 12500 - 7500 - 1000);
      expect(s.acquisitionCost, 22500);
      // 15口×2,600円
      expect(s.valuation, 39000);
      expect(s.unrealizedGain, 39000 - 22500);
      // 通算＝評価額＋売却＋収益−購入−費用
      expect(s.totalGain, 39000 + 12500 + 800 - 30000 - 1300);
    });

    test('全部売ると保有数・取得価額・評価額は0', () {
      final s = assetStateAt(
        valuation: Valuation.quantity,
        moves: [
          moves.first,
          const AssetMove(
            id: 's',
            date: '2026-02-01',
            action: AssetAction.sell,
            amount: 11000,
            quantityX1e4: 100000,
          ),
        ],
        values: values,
        date: '2026-12-31',
      );
      expect((s.quantityX1e4, s.acquisitionCost, s.valuation), (0, 0, 0));
      expect(s.sales.single.realizedGain, 1000);
    });
  });

  group('評価額の資産', () {
    final moves = [
      const AssetMove(
        id: 'b',
        date: '2024-04-20',
        action: AssetAction.buy,
        amount: 35000000,
      ),
      const AssetMove(
        id: 'c',
        date: '2026-05-01',
        action: AssetAction.cost,
        amount: 120000,
      ),
    ];
    const values = [
      ValuePoint(unit: 'day', date: '2024-04-20', valueX100: 3500000000),
      ValuePoint(unit: 'month', date: '2026-01', valueX100: 3300000000),
    ];
    test('保有中は価値、取得価額は購入額', () {
      final s = assetStateAt(
        valuation: Valuation.value,
        moves: moves,
        values: values,
        date: '2026-11-30',
      );
      expect(s.holding, isTrue);
      expect(s.valuation, 33000000);
      expect(s.acquisitionCost, 35000000);
      expect(s.unrealizedGain, -2000000);
      expect(s.totalGain, 33000000 - 35000000 - 120000);
    });
    test('売却の後は0、全部の売却で取得価額も0', () {
      final s = assetStateAt(
        valuation: Valuation.value,
        moves: [
          ...moves,
          const AssetMove(
            id: 's',
            date: '2055-03-01',
            action: AssetAction.sell,
            amount: 20000000,
          ),
        ],
        values: values,
        date: '2055-03-31',
      );
      expect(s.holding, isFalse);
      expect(s.valuation, 0);
      expect(s.acquisitionCost, 0);
      expect(s.sales.single.realizedGain, 20000000 - 35000000);
    });
    test('購入前は0', () {
      final s = assetStateAt(
        valuation: Valuation.value,
        moves: moves,
        values: values,
        date: '2024-01-01',
      );
      expect(s.valuation, 0);
    });
  });

  group('購入の入力と税の初期値', () {
    test('金額指定：数量＝金額÷単価（小数第4位で切り捨て）', () {
      // 10,000円 ÷ 単価3,000円 = 3.33333… → 3.3333
      expect(quantityForAmount(10000, 300000), 33333);
    });
    test('数量指定：金額＝数量×単価（円未満切り捨て）', () {
      // 3.3333口 × 3,000.50円 = 10001.66… → 10001
      expect(amountForQuantity(33333, 300050), 10001);
    });
    test('税額の初期値＝max(利益,0)×20.315%（切り捨て）', () {
      expect(taxInitial(100000), 20315);
      expect(taxInitial(12345), 2507);
      expect(taxInitial(-5000), 0);
    });
  });

  test('月末ごとの評価額', () {
    final s = monthEndValuations(
      valuation: Valuation.value,
      moves: const [
        AssetMove(
          id: 'b',
          date: '2026-02-15',
          action: AssetAction.buy,
          amount: 1000,
        ),
      ],
      values: const [],
      from: YearMonth(2026, 1),
      to: YearMonth(2026, 3),
    );
    expect(s.map((e) => e.$2), [0, 1000, 1000]);
  });

  group('見込み単価（計画用）', () {
    test('起点日より後に指定した価値があればそれを使う', () {
      expect(
        projectedPriceX100(
          values: const [
            ValuePoint(unit: 'month', date: '2030-01', valueX100: 500000),
          ],
          ym: YearMonth(2030, 6),
          baselineDate: '2026-11-20',
          baselinePriceX100: 100000,
          annualRatePercent: 5,
        ),
        500000,
      );
    });
    test('なければ起点の単価を想定利回りで月ごとに増やす（12か月で年率どおり）', () {
      expect(
        projectedPriceX100(
          values: const [
            ValuePoint(unit: 'month', date: '2026-01', valueX100: 1),
          ],
          ym: YearMonth(2027, 11),
          baselineDate: '2026-11-20',
          baselinePriceX100: 100000,
          annualRatePercent: 5,
        ),
        105000,
      );
    });
  });
}
