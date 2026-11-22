import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/domain/calc/asset_valuation.dart';
import 'package:butterfly_lp/domain/calc/simulation.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

SimLine line(
  int y,
  int m,
  TxnKind kind,
  int amount, {
  String acc = 'bank',
  String? to,
  String? asset,
  AssetAction? action,
  int? qty,
}) => SimLine(
  ym: YearMonth(y, m),
  kind: kind,
  amount: amount,
  accountId: acc,
  toAccountId: to,
  assetId: asset,
  assetAction: action,
  quantityX1e4: qty,
);

void main() {
  test('起点月の翌月から、計画行を適用して総資産を出す（起点月までの行は使わない）', () {
    final r = simulatePlan(
      baselineDate: '2026-11-20',
      end: YearMonth(2027, 2),
      accounts: const [SimAccount(id: 'bank', balance: 100000, cashLike: true)],
      assets: const [],
      lines: [
        line(2026, 11, TxnKind.income, 999999), // 起点月：使わない
        line(2026, 12, TxnKind.income, 300000),
        line(2026, 12, TxnKind.expense, 200000),
        line(2027, 1, TxnKind.expense, 50000),
      ],
    );
    expect(r.months.first.ym, YearMonth(2026, 12));
    expect(r.months.map((m) => m.total), [200000, 150000, 150000]);
  });

  test('想定利回り：月ごとに (1+年率)^(1/12)−1、増える額は切り上げ。マイナスの口座は増やさない', () {
    final r = simulatePlan(
      baselineDate: '2026-12-31',
      end: YearMonth(2027, 12),
      accounts: const [
        SimAccount(
          id: 'sec',
          balance: 1000000,
          cashLike: false,
          annualRate: 12,
        ),
        SimAccount(id: 'card', balance: -5000, cashLike: true, annualRate: 12),
      ],
      assets: const [],
      lines: const [],
    );
    final sec = r.months.last.accountsTotal + 5000;
    // 12か月でほぼ年率どおり（毎月の切り上げで数円多くなる）
    expect(sec, inInclusiveRange(1120000, 1120012));
    expect(r.months.last.cashLikeTotal, -5000);
  });

  test('資金不足：現金系口座の合計がマイナスになる最初の年月', () {
    final r = simulatePlan(
      baselineDate: '2026-12-01',
      end: YearMonth(2027, 6),
      accounts: const [
        SimAccount(id: 'bank', balance: 100000, cashLike: true),
        SimAccount(id: 'sec', balance: 9000000, cashLike: false),
      ],
      assets: const [],
      lines: [
        for (var m = 1; m <= 6; m++) line(2027, m, TxnKind.expense, 30000),
      ],
    );
    expect(r.firstShortage, YearMonth(2027, 4));
  });

  test('数量×単価の資産：購入で保有数が増え、単価は見込みの価値か想定利回りで変わる', () {
    final r = simulatePlan(
      baselineDate: '2026-12-31',
      end: YearMonth(2027, 3),
      accounts: const [
        SimAccount(id: 'bank', balance: 1000000, cashLike: true),
      ],
      assets: const [
        SimAsset(
          id: 'fund',
          valuation: Valuation.quantity,
          quantityX1e4: 100000,
          priceX100: 100000,
          values: [
            ValuePoint(unit: 'month', date: '2027-03', valueX100: 200000),
          ],
        ),
      ],
      lines: [
        line(
          2027,
          1,
          TxnKind.expense,
          30000,
          asset: 'fund',
          action: AssetAction.buy,
          qty: 300000,
        ),
      ],
    );
    // 1月：口座 970,000 ＋ 40口×1,000円
    expect(r.months[0].total, 970000 + 40000);
    // 3月：見込みの単価 2,000円
    expect(r.months[2].assetsTotal, 80000);
  });

  test('評価額の資産：購入で現金が評価額に置き換わり、想定利回りで増減、売却で0', () {
    final r = simulatePlan(
      baselineDate: '2026-12-31',
      end: YearMonth(2028, 1),
      accounts: const [
        SimAccount(id: 'bank', balance: 40000000, cashLike: true),
      ],
      assets: const [
        SimAsset(id: 'home', valuation: Valuation.value, annualRate: -2),
      ],
      lines: [
        line(
          2027,
          1,
          TxnKind.expense,
          35000000,
          asset: 'home',
          action: AssetAction.buy,
        ),
        line(
          2028,
          1,
          TxnKind.income,
          30000000,
          asset: 'home',
          action: AssetAction.sell,
        ),
      ],
    );
    final jan = r.at(YearMonth(2027, 1))!;
    expect(jan.accountsTotal, 5000000);
    expect(jan.assetsTotal, inInclusiveRange(34940000, 34950000));
    final dec = r.yearEnd(2027)!;
    expect(dec.assetsTotal, inInclusiveRange(34300000, 34400000));
    final sold = r.at(YearMonth(2028, 1))!;
    expect((sold.assetsTotal, sold.accountsTotal), (0, 35000000));
  });

  test('最大の総資産・年末', () {
    final r = simulatePlan(
      baselineDate: '2026-12-31',
      end: YearMonth(2028, 6),
      accounts: const [SimAccount(id: 'bank', balance: 0, cashLike: true)],
      assets: const [],
      lines: [
        line(2027, 6, TxnKind.income, 500),
        line(2028, 3, TxnKind.expense, 200),
      ],
    );
    expect(r.maxTotal, 500);
    expect(r.yearEnd(2027)!.total, 500);
    expect(r.yearEnd(2028)!.ym, YearMonth(2028, 6));
  });
}
