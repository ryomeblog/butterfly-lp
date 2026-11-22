import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/group_item.dart';
import '../db/database.dart';
import 'stamp.dart';

class TemplateInput {
  const TemplateInput({
    required this.name,
    required this.kind,
    this.amount,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    this.memo,
    this.growthMode = GrowthMode.category,
    this.growthRate,
    this.assetId,
    this.assetAction,
    this.quantityX1e4,
  });

  final String name;
  final TxnKind kind;
  final int? amount;
  final String? categoryId;
  final String? accountId;
  final String? toAccountId;
  final String? memo;
  final GrowthMode growthMode;
  final double? growthRate;

  /// 参照する資産（その資産のプランでだけ使える。設計書 3.2）
  final String? assetId;
  final AssetAction? assetAction;

  /// 数量指定の購入・売却のときの数量×10,000（金額は空）
  final int? quantityX1e4;
}

/// グループ一覧に出す情報。
class GroupSummary {
  const GroupSummary({
    required this.group,
    required this.itemCount,
    required this.missingCount,
    required this.registeredPlanCount,
  });

  final TemplateGroupRow group;
  final int itemCount;

  /// 削除されたテンプレートの項目の数（欠けた項目。設計書 3.2）
  final int missingCount;
  final int registeredPlanCount;
}

/// テンプレート・グループ（全プラン共通。設計書 3.2・4.4）。
class TemplateRepository {
  TemplateRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  // ---- テンプレート ----

  Stream<List<TemplateRow>> watchTemplates() =>
      (db.select(db.templates)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .watch();

  Future<TemplateRow?> getTemplate(String id) => (db.select(
    db.templates,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> createTemplate(TemplateInput input) async {
    final now = stamp.now();
    final id = newId();
    await db
        .into(db.templates)
        .insert(
          TemplatesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: input.name,
            kind: input.kind.code,
            amount: Value(input.amount),
            categoryId: Value(
              input.kind == TxnKind.transfer ? null : input.categoryId,
            ),
            accountId: Value(input.accountId),
            toAccountId: Value(
              input.kind == TxnKind.transfer ? input.toAccountId : null,
            ),
            memo: Value(input.memo),
            growthMode: input.growthMode.code,
            growthRate: Value(
              input.growthMode == GrowthMode.template ? input.growthRate : null,
            ),
            assetId: Value(input.assetId),
            assetAction: Value(
              input.assetId == null ? null : input.assetAction?.code,
            ),
            quantityX1e4: Value(
              input.assetId == null ? null : input.quantityX1e4,
            ),
          ),
        );
    return id;
  }

  /// 更新。
  Future<void> updateTemplate(String id, TemplateInput input) async {
    await (db.update(db.templates)..where((t) => t.id.equals(id))).write(
      TemplatesCompanion(
        name: Value(input.name),
        kind: Value(input.kind.code),
        amount: Value(input.amount),
        categoryId: Value(
          input.kind == TxnKind.transfer ? null : input.categoryId,
        ),
        accountId: Value(input.accountId),
        toAccountId: Value(
          input.kind == TxnKind.transfer ? input.toAccountId : null,
        ),
        memo: Value(input.memo),
        growthMode: Value(input.growthMode.code),
        growthRate: Value(
          input.growthMode == GrowthMode.template ? input.growthRate : null,
        ),
        assetId: Value(input.assetId),
        assetAction: Value(
          input.assetId == null ? null : input.assetAction?.code,
        ),
        quantityX1e4: Value(input.assetId == null ? null : input.quantityX1e4),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  /// 削除。グループの項目は残り、その項目は「欠けた項目」になる（設計書 3.2）。
  Future<void> deleteTemplate(String id) =>
      softDeleteRows(db, stamp, 'template', [id]);

  /// テンプレートを使っているグループ（削除の警告・使っているグループへのリンク）。
  Stream<List<TemplateGroupRow>> watchGroupsUsingTemplate(String templateId) {
    final q =
        db.select(db.templateGroups).join([
            innerJoin(
              db.templateGroupItems,
              db.templateGroupItems.groupId.equalsExp(db.templateGroups.id),
            ),
          ])
          ..where(
            db.templateGroups.deletedAt.isNull() &
                db.templateGroupItems.deletedAt.isNull() &
                db.templateGroupItems.templateId.equals(templateId),
          )
          ..orderBy([OrderingTerm(expression: db.templateGroups.sortOrder)]);
    return q.watch().map((rows) {
      final seen = <String>{};
      return [
        for (final r in rows)
          if (seen.add(r.readTable(db.templateGroups).id))
            r.readTable(db.templateGroups),
      ];
    });
  }

  /// テンプレートごとの所属グループ数（一覧に出す）。
  Stream<Map<String, int>> watchTemplateGroupCounts() {
    final q = db.customSelect(
      'SELECT i.template_id AS t, COUNT(DISTINCT i.group_id) AS c '
      'FROM template_group_item i JOIN template_group g ON g.id = i.group_id '
      'WHERE i.deleted_at IS NULL AND g.deleted_at IS NULL '
      'GROUP BY i.template_id',
      readsFrom: {db.templateGroupItems, db.templateGroups},
    );
    return q.watch().map(
      (rows) => {for (final r in rows) r.read<String>('t'): r.read<int>('c')},
    );
  }

  // ---- グループ ----

  Stream<List<GroupSummary>> watchGroupSummaries() {
    final q = db.customSelect(
      'SELECT g.*, '
      ' (SELECT COUNT(*) FROM template_group_item i '
      '   WHERE i.group_id = g.id AND i.deleted_at IS NULL) AS item_count, '
      ' (SELECT COUNT(*) FROM template_group_item i '
      '   LEFT JOIN template t ON t.id = i.template_id AND t.deleted_at IS NULL '
      '   WHERE i.group_id = g.id AND i.deleted_at IS NULL AND t.id IS NULL) AS missing_count, '
      ' (SELECT COUNT(DISTINCT pg.plan_id) FROM plan_group pg '
      '   JOIN plan p ON p.id = pg.plan_id AND p.deleted_at IS NULL '
      '   WHERE pg.group_id = g.id AND pg.deleted_at IS NULL) AS plan_count '
      'FROM template_group g WHERE g.deleted_at IS NULL '
      'ORDER BY g.sort_order, g.created_at',
      readsFrom: {
        db.templateGroups,
        db.templateGroupItems,
        db.templates,
        db.planGroups,
        db.plans,
      },
    );
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          GroupSummary(
            group: db.templateGroups.map(r.data),
            itemCount: r.read<int>('item_count'),
            missingCount: r.read<int>('missing_count'),
            registeredPlanCount: r.read<int>('plan_count'),
          ),
      ],
    );
  }

  Future<TemplateGroupRow?> getGroup(String id) => (db.select(
    db.templateGroups,
  )..where((g) => g.id.equals(id))).getSingleOrNull();

  Future<List<GroupItemDraft>> getGroupItems(String groupId) async {
    final rows =
        await (db.select(db.templateGroupItems)
              ..where((i) => i.groupId.equals(groupId) & i.deletedAt.isNull())
              ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
            .get();
    return [for (final r in rows) itemDraftOf(r)];
  }

  static GroupItemDraft itemDraftOf(TemplateGroupItemRow r) => GroupItemDraft(
    id: r.id,
    templateId: r.templateId,
    amountMode: AmountMode.of(r.amountMode),
    baseItemId: r.baseItemId,
    percent: r.percent,
    frequency: r.frequency == null
        ? Frequency.monthly
        : Frequency.of(r.frequency!),
    intervalN: r.intervalN,
    month: r.month,
    weekday: r.weekday,
    months: parseMonths(r.months),
  );

  /// グループを保存する。[groupId] が null なら新規。項目は追加・更新・削除をまとめて反映する。
  /// 変わっていない行は書き換えない（更新日時を進めず、同期の衝突を減らす）。
  Future<String> saveGroup({
    String? groupId,
    required String name,
    required List<GroupItemDraft> items,
  }) {
    return db.transaction(() async {
      final now = stamp.now();
      final id = groupId ?? newId();
      if (groupId == null) {
        final m = db.templateGroups.sortOrder.max();
        final q = db.selectOnly(db.templateGroups)
          ..addColumns([m])
          ..where(db.templateGroups.deletedAt.isNull());
        final order = ((await q.getSingle()).read(m) ?? -1) + 1;
        await db
            .into(db.templateGroups)
            .insert(
              TemplateGroupsCompanion.insert(
                id: id,
                createdAt: now,
                updatedAt: now,
                updatedBy: stamp.deviceId,
                name: name,
                sortOrder: order,
              ),
            );
      } else {
        final current = await getGroup(id);
        if (current != null && current.name != name) {
          await (db.update(
            db.templateGroups,
          )..where((g) => g.id.equals(id))).write(
            TemplateGroupsCompanion(
              name: Value(name),
              updatedAt: Value(now),
              updatedBy: Value(stamp.deviceId),
            ),
          );
        }
      }

      final existing = {
        for (final r in await (db.select(
          db.templateGroupItems,
        )..where((i) => i.groupId.equals(id) & i.deletedAt.isNull())).get())
          r.id: r,
      };
      for (final (order, item) in items.indexed) {
        final fixed = item.amountMode == AmountMode.fixed;
        final values = TemplateGroupItemsCompanion(
          groupId: Value(id),
          templateId: Value(item.templateId),
          amountMode: Value(item.amountMode.code),
          baseItemId: Value(fixed ? null : item.baseItemId),
          percent: Value(fixed ? null : item.percent),
          frequency: Value(fixed ? item.frequency.code : null),
          intervalN: Value(
            fixed &&
                    (item.frequency == Frequency.everyNMonths ||
                        item.frequency == Frequency.everyNYears)
                ? item.intervalN
                : null,
          ),
          month: Value(
            fixed && item.frequency == Frequency.yearly ? item.month : null,
          ),
          weekday: Value(
            fixed && item.frequency == Frequency.weekly ? item.weekday : null,
          ),
          months: Value(
            fixed && item.frequency == Frequency.specificMonths
                ? formatMonths(item.months)
                : null,
          ),
          sortOrder: Value(order),
        );
        final old = existing.remove(item.id);
        if (old == null) {
          await db
              .into(db.templateGroupItems)
              .insert(
                values.copyWith(
                  id: Value(item.id),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
              );
        } else if (_changed(old, values)) {
          await (db.update(
            db.templateGroupItems,
          )..where((i) => i.id.equals(item.id))).write(
            values.copyWith(
              updatedAt: Value(now),
              updatedBy: Value(stamp.deviceId),
            ),
          );
        }
      }
      await softDeleteRows(db, stamp, 'template_group_item', existing.keys);
      return id;
    });
  }

  bool _changed(TemplateGroupItemRow old, TemplateGroupItemsCompanion v) =>
      old.templateId != v.templateId.value ||
      old.amountMode != v.amountMode.value ||
      old.baseItemId != v.baseItemId.value ||
      old.percent != v.percent.value ||
      old.frequency != v.frequency.value ||
      old.intervalN != v.intervalN.value ||
      old.month != v.month.value ||
      old.weekday != v.weekday.value ||
      old.months != v.months.value ||
      old.sortOrder != v.sortOrder.value;

  /// グループの削除。項目も削除する。作成済みの予定・実績・プランへの登録は残る（設計書 3.2）。
  Future<void> deleteGroup(String id) {
    return db.transaction(() async {
      final items = await (db.select(
        db.templateGroupItems,
      )..where((i) => i.groupId.equals(id) & i.deletedAt.isNull())).get();
      await softDeleteRows(db, stamp, 'template_group_item', [
        for (final i in items) i.id,
      ]);
      await softDeleteRows(db, stamp, 'template_group', [id]);
    });
  }
}
