import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/master_repository.dart';
import 'package:butterfly_lp/data/repositories/plan_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/template_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:butterfly_lp/domain/models/group_item.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_helpers.dart';

/// プラン1つ・口座「現金」・テンプレート「給与」「所得税」を用意する。
Future<void> _prepare(AppDatabase db, String deviceId) async {
  final stamp = Stamp(deviceId);
  await PlanRepository(db, stamp).createPlan(
    const NewPlanInput(
      name: 'プランA',
      startYear: 2026,
      protagonistName: '本人',
      protagonistBirthDate: '1990-01-01',
      protagonistLifeExpectancy: 90,
      createCashAccount: true,
    ),
  );
  final cash = (await db.select(db.accounts).getSingle()).id;
  final salaryCat = (await (db.select(
    db.categories,
  )..where((c) => c.name.equals('給与所得'))).getSingle()).id;
  final taxCat = (await (db.select(
    db.categories,
  )..where((c) => c.name.equals('税金'))).getSingle()).id;
  final repo = TemplateRepository(db, stamp);
  await repo.createTemplate(
    TemplateInput(
      name: '給与（額面）',
      kind: TxnKind.income,
      amount: 300000,
      categoryId: salaryCat,
      accountId: cash,
    ),
  );
  await repo.createTemplate(
    TemplateInput(
      name: '所得税',
      kind: TxnKind.expense,
      amount: 10000,
      categoryId: taxCat,
      accountId: cash,
    ),
  );
}

void main() {
  testWidgets('グループを作り、割合の項目を設定して保存する', (tester) async {
    final db = await startApp(tester, prepare: _prepare);

    await tester.tap(find.text('グループ'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('group-create')));
    await settle(tester);

    await tester.enterText(find.byKey(const Key('group-name')), 'A社の給与明細');

    // 項目1：給与（固定額・毎月）
    await tester.tap(find.byKey(const Key('group-add-item')));
    await settle(tester);
    await tester.tap(find.text('給与（額面）').last);
    await settle(tester);

    // 項目2：所得税（給与の5%）
    await tester.ensureVisible(find.byKey(const Key('group-add-item')));
    await tester.tap(find.byKey(const Key('group-add-item')));
    await settle(tester);
    await tester.tap(find.text('所得税').last);
    await settle(tester);
    await tester.tap(find.text('別の項目の○%'));
    await settle(tester);
    await tester.tap(find.text('基準にする項目'));
    await settle(tester);
    await tester.tap(find.text('給与（額面）').last);
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '割合'), '5');
    await settle(tester);

    await tester.tap(find.byKey(const Key('group-save')));
    await settle(tester);

    final items = await tester.runAsync(
      () => db.select(db.templateGroupItems).get(),
    );
    expect(items, hasLength(2));
    final tax = items!.firstWhere((i) => i.amountMode == 'percent');
    expect(tax.percent, 5);
    expect(tax.baseItemId, items.firstWhere((i) => i.amountMode == 'fixed').id);
    expect(find.text('A社の給与明細'), findsOneWidget);
    expect(find.textContaining('項目2件'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('テンプレートを削除すると、グループに欠けた項目の警告が出る', (tester) async {
    final db = await startApp(
      tester,
      prepare: (db, deviceId) async {
        await _prepare(db, deviceId);
        final ts = await db.select(db.templates).get();
        await TemplateRepository(db, Stamp(deviceId)).saveGroup(
          name: 'A社の給与明細',
          items: [
            GroupItemDraft(
              id: 'i1',
              templateId: ts.firstWhere((t) => t.name == '給与（額面）').id,
            ),
            GroupItemDraft(
              id: 'i2',
              templateId: ts.firstWhere((t) => t.name == '所得税').id,
            ),
          ],
        );
      },
    );

    await tester.tap(find.text('テンプレート'));
    await settle(tester);
    await tester.tap(find.text('所得税'));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('template-delete')));
    await tester.tap(find.byKey(const Key('template-delete')));
    await settle(tester);

    // 使っているグループを示し、グループ名から移れる
    expect(find.text('・A社の給与明細'), findsOneWidget);
    await tester.tap(find.byKey(const Key('template-delete-confirm')));
    await settle(tester);

    await tester.tap(find.text('グループ'));
    await settle(tester);
    expect(find.textContaining('欠けた項目1件'), findsOneWidget);
    await tester.tap(find.text('A社の給与明細'));
    await settle(tester);
    expect(find.textContaining('削除されたテンプレートの項目があります'), findsOneWidget);

    // その場で外して保存
    await tester.tap(find.text('この項目を外す').first);
    await settle(tester);
    await tester.tap(find.byKey(const Key('group-save')));
    await settle(tester);
    expect(find.textContaining('項目1件'), findsOneWidget);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('使用中のカテゴリを付け替えて削除する', (tester) async {
    final db = await startApp(tester, prepare: _prepare);

    await tester.tap(find.text('カテゴリ'));
    await settle(tester);
    await tester.tap(find.text('税金'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('category-delete')));
    await settle(tester);
    expect(find.textContaining('テンプレート 1件'), findsOneWidget);

    await tester.tap(find.text('付け替え先'));
    await settle(tester);
    await tester.tap(find.text('その他').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('delete-reassign')));
    await settle(tester);

    final t = await tester.runAsync(
      () => (db.select(
        db.templates,
      )..where((t) => t.name.equals('所得税'))).getSingle(),
    );
    final other = await tester.runAsync(
      () =>
          (db.select(db.categories)
                ..where((c) => c.name.equals('その他') & c.kind.equals('expense')))
              .getSingle(),
    );
    expect(t!.categoryId, other!.id);
    expect(find.text('税金'), findsNothing);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('設定から口座を追加する', (tester) async {
    final db = await startApp(tester, prepare: _prepare);

    await tester.tap(find.text('設定'));
    await settle(tester);
    await tester.tap(find.text('カテゴリ・口座'));
    await settle(tester);
    await tester.tap(find.text('口座'));
    await settle(tester);
    await tester.tap(find.byTooltip('追加'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('account-name')), 'メイン銀行');
    await tester.tap(find.byKey(const Key('account-save')));
    await settle(tester);

    expect(find.text('メイン銀行'), findsOneWidget);
    final usage = await tester.runAsync(() async {
      final a = await (db.select(
        db.accounts,
      )..where((a) => a.name.equals('メイン銀行'))).getSingle();
      return MasterRepository(db, const Stamp('x')).accountUsage(a.id);
    });
    expect(usage!.isUsed, isFalse);

    await stopApp(tester, db);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
