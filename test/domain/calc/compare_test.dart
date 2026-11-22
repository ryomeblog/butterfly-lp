import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/domain/calc/compare.dart';
import 'package:butterfly_lp/domain/calc/event_matching.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

MatchItem mi(
  String id,
  TxnKind k,
  int amount, {
  String? cat,
  String acc = 'bank',
}) =>
    MatchItem(id: id, kind: k, amount: amount, accountId: acc, categoryId: cat);

PlanItem plan(
  String id,
  int m,
  TxnKind k,
  int amount, {
  String? cat,
  String? item,
  String? event,
}) => PlanItem(
  match: mi(id, k, amount, cat: cat),
  ym: YearMonth(2026, m),
  groupItemId: item,
  eventId: event,
);

ActualItem act(
  String id,
  String date,
  TxnKind k,
  int amount, {
  String? cat,
  String? item,
  String? event,
}) => ActualItem(
  match: mi(id, k, amount, cat: cat),
  date: date,
  groupItemId: item,
  eventId: event,
);

void main() {
  group('planActuals（6.8）', () {
    test('グループ由来は同じ月・同じ group_item_id の実績', () {
      final r = planActuals(
        [
          plan('p11', 11, TxnKind.income, 300000, cat: 'salary', item: 'i1'),
          plan('p12', 12, TxnKind.income, 300000, cat: 'salary', item: 'i1'),
        ],
        [
          act(
            'a',
            '2026-11-25',
            TxnKind.income,
            310000,
            cat: 'salary',
            item: 'i1',
          ),
          // 同じカテゴリでもグループ由来でない実績は数えない
          act('b', '2026-12-25', TxnKind.income, 5000, cat: 'salary'),
        ],
      );
      expect(r, {'p11': 310000, 'p12': 0});
    });

    test('手入力は同じ月・同じカテゴリで、グループ由来・イベントの実績は除く', () {
      final r = planActuals(
        [plan('food', 11, TxnKind.expense, 50000, cat: 'food')],
        [
          act('a', '2026-11-02', TxnKind.expense, 1000, cat: 'food'),
          act('b', '2026-11-20', TxnKind.expense, 2000, cat: 'food'),
          act(
            'c',
            '2026-11-21',
            TxnKind.expense,
            9999,
            cat: 'food',
            event: 'e1',
          ),
          act('d', '2026-11-22', TxnKind.expense, 9999, cat: 'food', item: 'x'),
          act('e', '2026-12-01', TxnKind.expense, 9999, cat: 'food'),
        ],
      );
      expect(r['food'], 3000);
    });

    test('イベントを指す予定は月を問わず同じイベントの実績', () {
      final r = planActuals(
        [plan('ev', 3, TxnKind.expense, 100, cat: 'x', event: 'e1')],
        [act('a', '2026-05-01', TxnKind.expense, 80, cat: 'x', event: 'e1')],
      );
      expect(r['ev'], 80);
    });
  });

  test('収入・支出・収支の予定と実績（振替は含めない）', () {
    final t = compareTotals(
      [
        mi('1', TxnKind.income, 300),
        mi('2', TxnKind.expense, 200),
        mi('3', TxnKind.transfer, 999),
      ],
      [mi('a', TxnKind.income, 280), mi('b', TxnKind.expense, 250)],
    );
    expect((t.income.diff, t.expense.diff), (-20, 50));
    expect((t.net.planned, t.net.actual, t.net.diff), (100, 30, -70));
  });

  test('カテゴリ別：ウェイトと超過・余り、既定は超過が大きい順', () {
    final list = categoryCompare(
      [
        mi('1', TxnKind.expense, 50000, cat: 'food'),
        mi('2', TxnKind.expense, 80000, cat: 'rent'),
        mi('3', TxnKind.expense, 20000, cat: 'fun'),
      ],
      [
        mi('a', TxnKind.expense, 62000, cat: 'food'),
        mi('b', TxnKind.expense, 80000, cat: 'rent'),
        mi('c', TxnKind.expense, 5000, cat: 'fun'),
        mi('d', TxnKind.expense, 3000, cat: 'new'),
      ],
      TxnKind.expense,
    );
    expect(list.map((c) => c.categoryId), ['food', 'new', 'rent', 'fun']);
    expect(list.first.diff, 12000);
    expect(list.last.diff, -15000);
    expect(list.first.plannedWeight, closeTo(50000 / 150000, 1e-9));
    expect(list.first.actualWeight, closeTo(62000 / 150000, 1e-9));
    final byPlan = categoryCompare(
      [
        mi('1', TxnKind.expense, 1, cat: 'a'),
        mi('2', TxnKind.expense, 2, cat: 'b'),
      ],
      const [],
      TxnKind.expense,
      sort: CompareSort.planned,
    );
    expect(byPlan.map((c) => c.categoryId), ['b', 'a']);
  });

  test('総資産の差の内訳：運用の差＝総資産の差−収入の差＋支出の差', () {
    const b = AssetDiffBreakdown(
      totalDiff: -100000,
      income: PlanActual(1000000, 980000),
      expense: PlanActual(800000, 850000),
    );
    // -100000 - (-20000) + 50000
    expect(b.investmentDiff, -30000);
  });
}
