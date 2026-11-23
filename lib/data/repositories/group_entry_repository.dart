import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/time.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/calc/group_entry.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'stamp.dart';

/// 一括入力の1項目。
///
/// グループの項目は [itemId] を持つ。その回だけ足した臨時の項目（設計書 6.6）は [itemId] が null で、
/// グループ・テンプレートには反映しない。
class GroupEntryLine {
  const GroupEntryLine({
    required this.itemId,
    required this.kind,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.memo,
  });

  /// テンプレートの中身で作る。
  factory GroupEntryLine.fromTemplate({
    required String? itemId,
    required TemplateRow template,
    required int amount,
  }) => GroupEntryLine(
    itemId: itemId,
    kind: TxnKind.of(template.kind),
    amount: amount,
    accountId: template.accountId!,
    categoryId: template.categoryId,
    toAccountId: template.toAccountId,
    assetId: template.assetId,
    assetAction: template.assetAction == null
        ? null
        : AssetAction.of(template.assetAction!),
    memo: template.memo,
  );

  final String? itemId;
  final TxnKind kind;
  final int amount;
  final String accountId;
  final String? categoryId;
  final String? toAccountId;
  final String? assetId;
  final AssetAction? assetAction;
  final String? memo;
}

/// グループからの実績入力（設計書 6.6）。
class GroupEntryRepository {
  GroupEntryRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  /// 入力した項目ごとに実績を作る。全行に同じ entry_id と group_id を入れ、グループの項目には
  /// group_item_id も入れる（臨時の項目は空）。口座・カテゴリは各行のもの（[accountOverride] があれば振替以外の口座をそれにする）。
  Future<String> saveEntry({
    required String planId,
    required String groupId,
    required String date,
    required List<GroupEntryLine> lines,
    String? accountOverride,
  }) {
    return db.transaction(() async {
      final now = stamp.now();
      final entryId = newId();
      for (final l in lines) {
        final kind = l.kind;
        final action = l.assetAction;
        int? quantity;
        if (l.assetId != null &&
            (action == AssetAction.buy || action == AssetAction.sell)) {
          quantity = await _quantityAt(l.assetId!, date, l.amount);
        }
        await db
            .into(db.txns)
            .insert(
              TxnsCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                updatedBy: stamp.deviceId,
                planId: planId,
                date: date,
                kind: kind.code,
                amount: l.amount,
                categoryId: Value(
                  kind == TxnKind.transfer ? null : l.categoryId,
                ),
                accountId:
                    (kind == TxnKind.transfer ? null : accountOverride) ??
                    l.accountId,
                toAccountId: Value(
                  kind == TxnKind.transfer ? l.toAccountId : null,
                ),
                assetId: Value(l.assetId),
                assetAction: Value(action?.code),
                quantityX1e4: Value(quantity),
                memo: Value(l.memo),
                groupId: Value(groupId),
                groupItemId: Value(l.itemId),
                entryId: Value(entryId),
              ),
            );
      }
      return entryId;
    });
  }

  /// 数量×単価の資産なら、その日の単価で数量を計算する。単価がなければ null。
  Future<int?> _quantityAt(String assetId, String date, int amount) async {
    final asset = await (db.select(
      db.assets,
    )..where((a) => a.id.equals(assetId))).getSingleOrNull();
    if (asset == null || asset.valuation != Valuation.quantity.code) {
      return null;
    }
    final values = await (db.select(
      db.assetValues,
    )..where((v) => v.assetId.equals(assetId) & v.deletedAt.isNull())).get();
    final price = valueAt([
      for (final v in values)
        ValuePoint(unit: v.unit, date: v.valueDate, valueX100: v.valueX100),
    ], date);
    return price == null ? null : quantityForAmount(amount, price);
  }

  /// 「入力した実績でグループを更新」（設計書 6.6）。
  Future<void> applyUpdate(GroupUpdate update) {
    return db.transaction(() async {
      final now = stamp.now();
      for (final e in update.templateAmounts.entries) {
        await (db.update(db.templates)..where((t) => t.id.equals(e.key))).write(
          TemplatesCompanion(
            amount: Value(e.value),
            updatedAt: Value(now),
            updatedBy: Value(stamp.deviceId),
          ),
        );
      }
      for (final e in update.percents.entries) {
        await (db.update(
          db.templateGroupItems,
        )..where((i) => i.id.equals(e.key))).write(
          TemplateGroupItemsCompanion(
            percent: Value(e.value),
            updatedAt: Value(now),
            updatedBy: Value(stamp.deviceId),
          ),
        );
      }
    });
  }

  /// 割合の提案のため、直近12か月の一括入力の実績を項目ごとに合計する（[planId] のプランの実績）。
  /// 戻り値：項目ID→（合計, 件数）
  Future<Map<String, (int, int)>> recentItemTotals(
    String planId,
    String groupId,
  ) async {
    final since = dateString(
      DateTime(clock.now().year - 1, clock.now().month, clock.now().day + 1),
    );
    final rows =
        await (db.select(db.txns)..where(
              (t) =>
                  t.planId.equals(planId) &
                  t.groupId.equals(groupId) &
                  t.deletedAt.isNull() &
                  t.groupItemId.isNotNull() &
                  t.date.isBiggerOrEqualValue(since) &
                  t.date.isSmallerOrEqualValue(todayString()),
            ))
            .get();
    final result = <String, (int, int)>{};
    for (final t in rows) {
      final v = result[t.groupItemId!] ?? (0, 0);
      result[t.groupItemId!] = (v.$1 + t.amount, v.$2 + 1);
    }
    return result;
  }
}
