import 'package:butterfly_lp/domain/calc/event_matching.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

MatchItem m(
  String id,
  TxnKind kind,
  int amount, {
  String? cat,
  String acc = 'bank',
  String? to,
  String? asset,
  AssetAction? action,
}) => MatchItem(
  id: id,
  kind: kind,
  amount: amount,
  accountId: acc,
  categoryId: cat,
  toAccountId: to,
  assetId: asset,
  assetAction: action,
);

void main() {
  final lines = [
    m('down', TxnKind.expense, 5000000, cat: 'house'),
    m(
      'buy',
      TxnKind.expense,
      30000000,
      cat: 'other',
      asset: 'home',
      action: AssetAction.buy,
    ),
    m('fee', TxnKind.expense, 500000, cat: 'other'),
    m('move', TxnKind.transfer, 100000, to: 'sec'),
  ];

  test('同じ種類・同じカテゴリの実績の合計（入力していない項目は0）', () {
    final r = eventLineActuals(lines, [
      m('t1', TxnKind.expense, 4800000, cat: 'house'),
      m('t2', TxnKind.expense, 300000, cat: 'other'),
      m('t3', TxnKind.expense, 250000, cat: 'other'),
    ]);
    expect(r['down'], 4800000);
    expect(r['fee'], 550000);
    expect(r['buy'], 0); // 資産の動きは同じ資産・同じ動きの実績だけ
    expect(r['move'], 0);
  });

  test('資産の動きは同じ資産・同じ動き、振替は同じ口座で対応づける', () {
    final r = eventLineActuals(lines, [
      m(
        't1',
        TxnKind.expense,
        29000000,
        cat: 'other',
        asset: 'home',
        action: AssetAction.buy,
      ),
      m('t2', TxnKind.transfer, 100000, to: 'sec'),
      m('t3', TxnKind.transfer, 999, to: 'cash'),
    ]);
    expect(r['buy'], 29000000);
    expect(r['fee'], 0);
    expect(r['move'], 100000);
  });

  test('予定・実績の合計（振替は含めない）', () {
    final t = kindTotals([
      ...lines,
      m('i', TxnKind.income, 200000, cat: 'gift'),
    ]);
    expect(t.expense, 35500000);
    expect(t.income, 200000);
    expect(t.net, 200000 - 35500000);
  });
}
