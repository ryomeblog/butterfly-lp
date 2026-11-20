import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/domain/calc/account_series.dart';
import 'package:butterfly_lp/domain/calc/balance.dart';
import 'package:butterfly_lp/domain/calc/ledger.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

LedgerTxn t(
  String id,
  String date,
  TxnKind kind,
  int amount, {
  String? cat,
  String account = 'bank',
  String? to,
}) => LedgerTxn(
  id: id,
  date: date,
  kind: kind,
  amount: amount,
  categoryId: cat,
  accountId: account,
  toAccountId: to,
);

void main() {
  final txns = [
    t('1', '2026-01-25', TxnKind.income, 300000, cat: 'salary'),
    t('2', '2026-01-10', TxnKind.expense, 80000, cat: 'rent'),
    t('3', '2026-01-12', TxnKind.expense, 5000, cat: 'food'),
    t('4', '2026-02-12', TxnKind.expense, 15000, cat: 'food'),
    t('5', '2026-02-12', TxnKind.transfer, 30000, to: 'sec'),
    t('6', '2026-02-28', TxnKind.expense, 80000, cat: 'rent', account: 'cash'),
  ];

  test('収入・支出・収支（振替は含めない）', () {
    final s = totalsOf(txns);
    expect(s.income, 300000);
    expect(s.expense, 180000);
    expect(s.net, 120000);
  });

  test('カテゴリ別：金額の大きい順・構成比・件数', () {
    final list = totalsByCategory(txns, TxnKind.expense);
    expect(list.map((c) => c.categoryId), ['rent', 'food']);
    expect(list.first.amount, 160000);
    expect(list.first.count, 2);
    expect(list.first.ratio, closeTo(160000 / 180000, 1e-9));
    expect(list.last.ratio, closeTo(20000 / 180000, 1e-9));
  });

  test('月ごと：実績のない月も0で出す', () {
    final food = txns.where((x) => x.categoryId == 'food');
    final m = monthlyTotals(food);
    expect(m, hasLength(12));
    expect((m[0].amount, m[0].count), (5000, 1));
    expect((m[1].amount, m[1].count), (15000, 1));
    expect((m[11].amount, m[11].count), (0, 0));
  });

  test('日ごとの収支（カレンダー）', () {
    final d = dailyTotals(txns.where((x) => x.ym == '2026-02'));
    expect(d[12]!.expense, 15000);
    expect(d[12]!.income, 0);
    expect(d[28]!.net, -80000);
    expect(d.containsKey(1), isFalse);
  });

  test('新しい順', () {
    expect(newestFirst(txns).map((x) => x.id).take(3), ['6', '5', '4']);
  });

  group('絞り込み', () {
    final feb = LedgerFilter.month(YearMonth(2026, 2));
    test('期間', () {
      expect(txns.where(feb.matches).map((x) => x.id), ['4', '5', '6']);
    });
    test('カテゴリ・種類・金額範囲', () {
      final f = feb.copyWith(kinds: {TxnKind.expense}, minAmount: () => 20000);
      expect(txns.where(f.matches).map((x) => x.id), ['6']);
      final g = feb.copyWith(categoryIds: {'food'});
      expect(txns.where(g.matches).map((x) => x.id), ['4']);
    });
    test('口座は振替の入金先でも一致する', () {
      final f = feb.copyWith(accountIds: {'sec'});
      expect(txns.where(f.matches).map((x) => x.id), ['5']);
    });
  });

  test('口座の月末残高の推移', () {
    const bank = BalanceAccount(
      id: 'bank',
      initialBalance: 10000,
      initialDate: '2026-01-05',
    );
    final b = [
      for (final x in txns)
        BalanceTxn(
          date: x.date,
          kind: x.kind,
          amount: x.amount,
          accountId: x.accountId,
          toAccountId: x.toAccountId,
        ),
    ];
    final s = monthEndBalances(
      bank,
      b,
      YearMonth(2025, 12),
      YearMonth(2026, 3),
    );
    expect(s.map((e) => e.$2), [
      0, // 基準日より前
      10000 + 300000 - 80000 - 5000,
      225000 - 15000 - 30000,
      180000,
    ]);
    // 1件ずつ計算した結果と一致する
    expect(s[2].$2, accountBalanceAt(bank, b, '2026-02-28'));
  });
}
