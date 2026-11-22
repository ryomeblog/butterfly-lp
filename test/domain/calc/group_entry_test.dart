import 'package:butterfly_lp/core/time.dart';
import 'package:butterfly_lp/domain/calc/group_entry.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:flutter_test/flutter_test.dart';

const items = [
  GroupItemDraft(id: 's', templateId: 'ts'),
  GroupItemDraft(
    id: 'tax',
    templateId: 'tt',
    amountMode: AmountMode.percent,
    baseItemId: 's',
    percent: 5.5,
  ),
  GroupItemDraft(
    id: 'b',
    templateId: 'tb',
    frequency: Frequency.specificMonths,
    months: [6, 12],
  ),
  GroupItemDraft(
    id: 'bt',
    templateId: 'tt2',
    amountMode: AmountMode.percent,
    baseItemId: 'b',
    percent: 15,
  ),
  GroupItemDraft(id: 'gone', templateId: 'deleted'),
];
const amounts = {'ts': 300001, 'tt': null, 'tb': 500000, 'tt2': null};

void main() {
  group('entryPrefill（6.6）', () {
    test('予定がなければ固定額はテンプレートの金額、割合は基準×%（切り上げ）。発生しない月の項目は空', () {
      final r = entryPrefill(
        items: items,
        templateAmounts: amounts,
        plannedByItem: const {},
        ym: YearMonth(2026, 11),
      );
      expect(r, {'s': 300001, 'b': null, 'tax': 16501, 'bt': null});
      final june = entryPrefill(
        items: items,
        templateAmounts: amounts,
        plannedByItem: const {},
        ym: YearMonth(2026, 6),
      );
      expect((june['b'], june['bt']), (500000, 75000));
    });

    test('予定があれば予定額。予定がない項目は空。削除されたテンプレートの項目は出さない', () {
      final r = entryPrefill(
        items: items,
        templateAmounts: amounts,
        plannedByItem: const {'s': 306000, 'tax': 16830},
        ym: YearMonth(2027, 11),
      );
      expect(r, {'s': 306000, 'tax': 16830, 'b': null, 'bt': null});
      expect(r.containsKey('gone'), isFalse);
    });
  });

  test('割合の提案：小数第2位で四捨五入、実績がなければ出さない', () {
    expect(suggestPercent(16543, 300000), 5.51);
    expect(suggestPercent(0, 300000), isNull);
    expect(suggestPercent(100, 0), isNull);
  });

  test('入力した実績でグループを更新：固定額はテンプレートの金額、割合は今回の比率', () {
    final u = updateFromEntry(items, const {
      's': 320000,
      'tax': 17600,
      'bt': 999,
    });
    expect(u.templateAmounts, {'ts': 320000});
    expect(u.percents, {'tax': 5.5});
  });
}
