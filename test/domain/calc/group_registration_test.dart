import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/domain/calc/group_registration.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:flutter_test/flutter_test.dart';

const salary = RegTemplate(
  id: 't-salary',
  name: '給与',
  kind: TxnKind.income,
  amount: 300000,
  categoryId: 'c-salary',
  accountId: 'bank',
);
const tax = RegTemplate(
  id: 't-tax',
  name: '所得税',
  kind: TxnKind.expense,
  amount: 0,
  categoryId: 'c-tax',
  accountId: 'bank',
);
const bonus = RegTemplate(
  id: 't-bonus',
  name: 'ボーナス',
  kind: TxnKind.income,
  amount: 500000,
  categoryId: 'c-salary',
  accountId: 'bank',
);
const stock = RegTemplate(
  id: 't-stock',
  name: '持株会',
  kind: TxnKind.transfer,
  amount: 10000,
  accountId: 'bank',
  toAccountId: 'sec',
);

final templates = {
  for (final t in [salary, tax, bonus, stock]) t.id: t,
};

RegistrationResult gen(
  List<GroupItemDraft> items, {
  String start = '2026-04',
  String end = '2027-03',
  String? from,
  Map<String, double> rates = const {},
  double defaultRate = 0,
  Map<String, RegTemplate>? tmpl,
}) => generateGroupLines(
  items: items,
  templates: tmpl ?? templates,
  start: YearMonth.parse(start),
  end: YearMonth.parse(end),
  from: from == null ? null : YearMonth.parse(from),
  categoryRate: (c) => rates[c],
  defaultRate: defaultRate,
);

void main() {
  group('occurrences（6.3 手順1）', () {
    final start = YearMonth(2026, 4);
    test('毎年（月指定）', () {
      const i = GroupItemDraft(
        id: 'a',
        templateId: 'x',
        frequency: Frequency.yearly,
        month: 6,
      );
      expect(occurrences(i, YearMonth(2026, 6), start), 1);
      expect(occurrences(i, YearMonth(2026, 7), start), 0);
    });
    test('Nか月ごと・N年ごとは開始年月を起点に数える', () {
      const m3 = GroupItemDraft(
        id: 'a',
        templateId: 'x',
        frequency: Frequency.everyNMonths,
        intervalN: 3,
      );
      expect(
        [
          for (var k = 0; k < 7; k++)
            occurrences(m3, start.addMonths(k), start),
        ],
        [1, 0, 0, 1, 0, 0, 1],
      );
      const y2 = GroupItemDraft(
        id: 'b',
        templateId: 'x',
        frequency: Frequency.everyNYears,
        intervalN: 2,
      );
      expect(occurrences(y2, YearMonth(2026, 4), start), 1);
      expect(occurrences(y2, YearMonth(2027, 4), start), 0);
      expect(occurrences(y2, YearMonth(2028, 4), start), 1);
      expect(occurrences(y2, YearMonth(2028, 5), start), 0);
    });
    test('毎週はその月の該当曜日の数', () {
      const mon = GroupItemDraft(
        id: 'a',
        templateId: 'x',
        frequency: Frequency.weekly,
        weekday: 1,
      );
      // 2026年6月の月曜は 1・8・15・22・29 の5回、7月は4回
      expect(occurrences(mon, YearMonth(2026, 6), start), 5);
      expect(occurrences(mon, YearMonth(2026, 7), start), 4);
    });
    test('特定の月のみ', () {
      const i = GroupItemDraft(
        id: 'a',
        templateId: 'x',
        frequency: Frequency.specificMonths,
        months: [6, 12],
      );
      expect(occurrences(i, YearMonth(2026, 12), start), 1);
      expect(occurrences(i, YearMonth(2026, 11), start), 0);
    });
    test('開始年月より前は0', () {
      const i = GroupItemDraft(id: 'a', templateId: 'x');
      expect(occurrences(i, YearMonth(2026, 3), start), 0);
    });
  });

  group('generateGroupLines（6.3）', () {
    test('給与明細：毎月の給与と給与の5%の所得税、6月と12月のボーナスとその15%', () {
      final r = gen([
        const GroupItemDraft(id: 's', templateId: 't-salary'),
        const GroupItemDraft(
          id: 'tx',
          templateId: 't-tax',
          amountMode: AmountMode.percent,
          baseItemId: 's',
          percent: 5,
        ),
        const GroupItemDraft(
          id: 'b',
          templateId: 't-bonus',
          frequency: Frequency.specificMonths,
          months: [6, 12],
        ),
        const GroupItemDraft(
          id: 'bt',
          templateId: 't-tax',
          amountMode: AmountMode.percent,
          baseItemId: 'b',
          percent: 15,
        ),
      ]);
      int count(String id) => r.lines.where((l) => l.itemId == id).length;
      expect(count('s'), 12);
      expect(count('tx'), 12);
      expect(count('b'), 2);
      expect(count('bt'), 2);
      final june = r.lines.where((l) => l.ym == YearMonth(2026, 6));
      expect(
        {for (final l in june) l.itemId: l.amount},
        {'s': 300000, 'b': 500000, 'tx': 15000, 'bt': 75000},
      );
      expect(r.skipped, isEmpty);
    });

    test('上昇率：基準は開始年。カテゴリの率→なければ既定値。割合は増えた基準に連動・切り上げ', () {
      final r = gen(
        [
          const GroupItemDraft(id: 's', templateId: 't-salary'),
          const GroupItemDraft(
            id: 'tx',
            templateId: 't-tax',
            amountMode: AmountMode.percent,
            baseItemId: 's',
            percent: 3.3,
          ),
        ],
        start: '2026-04',
        end: '2028-04',
        rates: {'c-salary': 2.0},
        defaultRate: 9,
      );
      int amount(String id, int y, int m) => r.lines
          .firstWhere((l) => l.itemId == id && l.ym == YearMonth(y, m))
          .amount;
      expect(amount('s', 2026, 12), 300000);
      expect(amount('s', 2027, 1), 306000);
      expect(amount('s', 2028, 4), 312120);
      // 312120×3.3% = 10299.96 → 10300（切り上げ）
      expect(amount('tx', 2028, 4), 10300);
    });

    test('カテゴリの率がなければプランの既定値、テンプレートの率はそれより優先', () {
      final own = {
        ...templates,
        't-salary': const RegTemplate(
          id: 't-salary',
          name: '給与',
          kind: TxnKind.income,
          amount: 100000,
          categoryId: 'c-salary',
          accountId: 'bank',
          growthMode: GrowthMode.template,
          growthRate: 10,
        ),
      };
      final r1 = gen(
        [const GroupItemDraft(id: 's', templateId: 't-salary')],
        start: '2026-01',
        end: '2027-01',
        defaultRate: 1,
        rates: {'c-salary': 5},
        tmpl: own,
      );
      expect(r1.lines.last.amount, 110000);
      final r2 = gen(
        [const GroupItemDraft(id: 'b', templateId: 't-bonus')],
        start: '2026-01',
        end: '2027-01',
        defaultRate: 1,
      );
      expect(r2.lines.last.amount, 505000);
    });

    test('振替は増やさない', () {
      final r = gen(
        [const GroupItemDraft(id: 'k', templateId: 't-stock')],
        start: '2026-01',
        end: '2030-01',
        defaultRate: 3,
      );
      expect(r.lines.last.amount, 10000);
    });

    test('毎週は金額×回数の1行', () {
      final r = gen(
        [
          const GroupItemDraft(
            id: 'w',
            templateId: 't-stock',
            frequency: Frequency.weekly,
            weekday: 1,
          ),
        ],
        start: '2026-06',
        end: '2026-06',
      );
      expect(r.lines.single.amount, 50000);
    });

    test('作り直し：指定年月以降だけを作り、上昇率の基準は登録の開始年のまま', () {
      final r = gen(
        [const GroupItemDraft(id: 's', templateId: 't-salary')],
        start: '2026-04',
        end: '2027-12',
        from: '2027-06',
        rates: {'c-salary': 2.0},
      );
      expect(r.lines.first.ym, YearMonth(2027, 6));
      expect(r.lines.first.amount, 306000);
      expect(r.lines, hasLength(7));
    });

    test('欠けた項目と、それを基準にした割合の項目は作らない', () {
      final r = gen([
        const GroupItemDraft(id: 's', templateId: 't-deleted'),
        const GroupItemDraft(
          id: 'tx',
          templateId: 't-tax',
          amountMode: AmountMode.percent,
          baseItemId: 's',
          percent: 5,
        ),
        const GroupItemDraft(
          id: 'b',
          templateId: 't-bonus',
          frequency: Frequency.yearly,
          month: 6,
        ),
      ]);
      expect(r.lines.map((l) => l.itemId).toSet(), {'b'});
      expect(r.skipped.map((s) => s.itemId), ['s', 'tx']);
    });

    test('口座が空のテンプレートは使えない', () {
      final r = gen(
        [const GroupItemDraft(id: 's', templateId: 't-salary')],
        tmpl: {
          't-salary': const RegTemplate(
            id: 't-salary',
            name: '給与',
            kind: TxnKind.income,
            amount: 1,
            categoryId: 'c',
          ),
        },
      );
      expect(r.lines, isEmpty);
      expect(r.skipped.single.reason, contains('口座'));
    });

    test('金額0の項目は行を作らない', () {
      final r = gen([const GroupItemDraft(id: 'z', templateId: 't-tax')]);
      expect(r.lines, isEmpty);
    });
  });
}
