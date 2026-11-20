import 'package:butterfly_lp/domain/calc/balance.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bank = BalanceAccount(
    id: 'bank',
    initialBalance: 100000,
    initialDate: '2026-01-01',
  );

  BalanceTxn t(
    String date,
    TxnKind kind,
    int amount, {
    String account = 'bank',
    String? to,
  }) => BalanceTxn(
    date: date,
    kind: kind,
    amount: amount,
    accountId: account,
    toAccountId: to,
  );

  group('balanceDelta（6.1 の表）', () {
    test('収入は主口座を増やす', () {
      expect(balanceDelta(t('2026-01-02', TxnKind.income, 500), 'bank'), 500);
    });
    test('支出は主口座を減らす', () {
      expect(balanceDelta(t('2026-01-02', TxnKind.expense, 500), 'bank'), -500);
    });
    test('振替は出金元を減らし入金先を増やす', () {
      final x = t('2026-01-02', TxnKind.transfer, 300, to: 'sec');
      expect(balanceDelta(x, 'bank'), -300);
      expect(balanceDelta(x, 'sec'), 300);
    });
    test('関係ない口座は0', () {
      expect(balanceDelta(t('2026-01-02', TxnKind.income, 500), 'cash'), 0);
    });
  });

  group('accountBalanceAt', () {
    final txns = [
      t('2025-12-31', TxnKind.income, 999999), // 基準日より前は含めない
      t('2026-01-01', TxnKind.income, 1000), // 基準日当日は含める
      t('2026-02-10', TxnKind.expense, 300),
      t('2026-03-01', TxnKind.transfer, 200, to: 'sec'),
      t('2027-01-01', TxnKind.expense, 50000), // 未来日付の実績も日付で効く
    ];

    test('初期残高＋基準日以降の実績', () {
      expect(accountBalanceAt(bank, txns, '2026-02-28'), 100000 + 1000 - 300);
    });
    test('指定日の実績を含む', () {
      expect(accountBalanceAt(bank, txns, '2026-03-01'), 100500);
    });
    test('未来日付の実績はその日付で減る', () {
      expect(accountBalanceAt(bank, txns, '2026-12-31'), 100500);
      expect(accountBalanceAt(bank, txns, '2027-01-01'), 50500);
    });
    test('基準日より前の時点は0', () {
      expect(accountBalanceAt(bank, txns, '2025-12-31'), 0);
    });
    test('振替の入金先の残高', () {
      const sec = BalanceAccount(
        id: 'sec',
        initialBalance: 0,
        initialDate: '2026-01-01',
      );
      expect(accountBalanceAt(sec, txns, '2026-03-31'), 200);
    });
  });
}
