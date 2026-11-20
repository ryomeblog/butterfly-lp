import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const salary = GroupItemDraft(id: 's', templateId: 'ts');
  const bonus = GroupItemDraft(
    id: 'b',
    templateId: 'tb',
    frequency: Frequency.specificMonths,
    months: [6, 12],
  );

  GroupItemDraft pct(String base, {double? p = 5}) => GroupItemDraft(
    id: 'p',
    templateId: 'tp',
    amountMode: AmountMode.percent,
    baseItemId: base,
    percent: p,
  );

  group('validateGroupItem（設計書 3.2）', () {
    test('固定額・毎月はそのままでよい', () {
      expect(validateGroupItem(salary, [salary]), isNull);
    });
    test('割合の項目は固定額の項目を基準にできる', () {
      final p = pct('s');
      expect(validateGroupItem(p, [salary, p]), isNull);
    });
    test('割合の連鎖はできない', () {
      final p1 = pct('s');
      final p2 = GroupItemDraft(
        id: 'p2',
        templateId: 'x',
        amountMode: AmountMode.percent,
        baseItemId: 'p',
        percent: 1,
      );
      expect(validateGroupItem(p2, [salary, p1, p2]), contains('固定額'));
    });
    test('基準がない・自分自身・割合がない', () {
      expect(validateGroupItem(pct('zz'), [salary]), isNotNull);
      final self = pct('p');
      expect(validateGroupItem(self, [self]), isNotNull);
      final noP = pct('s', p: null);
      expect(validateGroupItem(noP, [salary, noP]), contains('割合'));
    });
    test('削除されたテンプレートの項目は基準にできない', () {
      final p = pct('s');
      expect(
        validateGroupItem(p, [salary, p], missingTemplateIds: {'ts'}),
        contains('削除'),
      );
    });
    test('頻度ごとに必要な値', () {
      expect(
        validateGroupItem(
          const GroupItemDraft(
            id: 'y',
            templateId: 't',
            frequency: Frequency.yearly,
          ),
          const [],
        ),
        isNotNull,
      );
      expect(
        validateGroupItem(
          const GroupItemDraft(
            id: 'n',
            templateId: 't',
            frequency: Frequency.everyNMonths,
            intervalN: 0,
          ),
          const [],
        ),
        isNotNull,
      );
      expect(
        validateGroupItem(
          const GroupItemDraft(
            id: 'w',
            templateId: 't',
            frequency: Frequency.weekly,
            weekday: 1,
          ),
          const [],
        ),
        isNull,
      );
      expect(
        validateGroupItem(
          const GroupItemDraft(
            id: 'm',
            templateId: 't',
            frequency: Frequency.specificMonths,
          ),
          const [],
        ),
        isNotNull,
      );
    });
  });

  test('頻度の説明', () {
    expect(describeFrequency(bonus), '特定の月のみ（6月・12月）');
    expect(
      describeFrequency(
        const GroupItemDraft(
          id: 'w',
          templateId: 't',
          frequency: Frequency.weekly,
          weekday: 1,
        ),
      ),
      '毎週月曜',
    );
  });

  test('対象月の文字列', () {
    expect(parseMonths('12,6'), [6, 12]);
    expect(formatMonths([12, 6]), '6,12');
    expect(parseMonths(null), isEmpty);
  });
}
