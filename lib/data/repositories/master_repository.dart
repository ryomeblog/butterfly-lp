import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'stamp.dart';

/// カテゴリ・口座がどれだけ使われているか（削除の確認に出す件数）。
class MasterUsage {
  const MasterUsage({
    this.txns = 0,
    this.planLines = 0,
    this.templates = 0,
    this.assets = 0,
  });

  final int txns;
  final int planLines;
  final int templates;

  /// 資産のカテゴリなら、そのカテゴリの資産。口座なら、その口座を保管口座にしている資産。
  final int assets;

  bool get isUsed => txns + planLines + templates + assets > 0;
}

class CategoryInput {
  const CategoryInput({
    required this.name,
    required this.kind,
    required this.color,
    this.defaultValuation,
    this.saleTaxDefault,
  });

  final String name;
  final CategoryKind kind;
  final String color;
  final Valuation? defaultValuation;
  final bool? saleTaxDefault;
}

class AccountInput {
  const AccountInput({
    required this.name,
    required this.kind,
    required this.initialBalance,
    required this.initialDate,
  });

  final String name;
  final AccountKind kind;
  final int initialBalance;
  final String initialDate;
}

/// カテゴリ・口座（全プラン共通のマスタ。設計書 4.3）。
class MasterRepository {
  MasterRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  // ---- カテゴリ ----

  Stream<List<CategoryRow>> watchCategories() =>
      (db.select(db.categories)
            ..where((c) => c.deletedAt.isNull())
            ..orderBy([
              (c) => OrderingTerm(expression: c.sortOrder),
              (c) => OrderingTerm(expression: c.createdAt),
            ]))
          .watch();

  Future<CategoryRow?> getCategory(String id) => (db.select(
    db.categories,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<String> createCategory(CategoryInput input) async {
    final now = stamp.now();
    final id = newId();
    final order = await _nextCategoryOrder(input.kind);
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: input.name,
            kind: input.kind.code,
            color: input.color,
            defaultValuation: Value(
              input.kind == CategoryKind.asset
                  ? input.defaultValuation?.code
                  : null,
            ),
            saleTaxDefault: Value(
              input.kind == CategoryKind.asset
                  ? ((input.saleTaxDefault ?? false) ? 1 : 0)
                  : null,
            ),
            sortOrder: order,
          ),
        );
    return id;
  }

  Future<void> updateCategory(String id, CategoryInput input) async {
    await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(input.name),
        kind: Value(input.kind.code),
        color: Value(input.color),
        defaultValuation: Value(
          input.kind == CategoryKind.asset
              ? input.defaultValuation?.code
              : null,
        ),
        saleTaxDefault: Value(
          input.kind == CategoryKind.asset
              ? ((input.saleTaxDefault ?? false) ? 1 : 0)
              : null,
        ),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  /// 並べ替え（長押し）。[orderedIds] の順に sort_order を振り直す。
  Future<void> reorderCategories(List<String> orderedIds) =>
      _reorder('category', orderedIds);

  Future<MasterUsage> categoryUsage(String id) async {
    return MasterUsage(
      txns: await _count('txn', 'category_id = ?', [id]),
      planLines: await _count('plan_line', 'category_id = ?', [id]),
      templates: await _count('template', 'category_id = ?', [id]),
      assets: await _count('asset', 'category_id = ?', [id]),
    );
  }

  /// 関連履歴ごと削除（設計書 3.7）。
  ///
  /// 実績・計画行・率を削除し、テンプレートは残してカテゴリを空欄にする。
  /// 資産のカテゴリなら、そのカテゴリの資産（全プラン）と、価値・その資産を指す実績・予定も削除し、
  /// その資産を指すテンプレートは資産の欄を空欄にする。
  Future<void> deleteCategoryWithHistory(String id) {
    return db.transaction(() async {
      final now = stamp.now();
      await softDeleteRows(
        db,
        stamp,
        'txn',
        await _ids('txn', 'category_id = ?', [id]),
      );
      await softDeleteRows(
        db,
        stamp,
        'plan_line',
        await _ids('plan_line', 'category_id = ?', [id]),
      );
      await softDeleteRows(
        db,
        stamp,
        'plan_rate',
        await _ids('plan_rate', "target_type = 'category' AND target_id = ?", [
          id,
        ]),
      );
      await _blank('template', 'category_id', id, now);

      final assetIds = await _ids('asset', 'category_id = ?', [id]);
      if (assetIds.isNotEmpty) {
        await _deleteAssetsCompletely(assetIds, now);
      }
      await softDeleteRows(db, stamp, 'category', [id]);
    });
  }

  /// 付け替えて削除（設計書 3.7）。実績・計画行・テンプレート・資産をすべて [toId] へ移す。
  Future<void> reassignCategoryAndDelete(String id, String toId) {
    return db.transaction(() async {
      final now = stamp.now();
      for (final table in ['txn', 'plan_line', 'template', 'asset']) {
        await _replace(table, 'category_id', id, toId, now);
      }
      // 率（インフレ率）はカテゴリごとの設定なので、付け替え先には移さず削除する。
      await softDeleteRows(
        db,
        stamp,
        'plan_rate',
        await _ids('plan_rate', "target_type = 'category' AND target_id = ?", [
          id,
        ]),
      );
      await softDeleteRows(db, stamp, 'category', [id]);
    });
  }

  // ---- 口座 ----

  Stream<List<AccountRow>> watchAccounts() =>
      (db.select(db.accounts)
            ..where((a) => a.deletedAt.isNull())
            ..orderBy([
              (a) => OrderingTerm(expression: a.sortOrder),
              (a) => OrderingTerm(expression: a.createdAt),
            ]))
          .watch();

  Future<AccountRow?> getAccount(String id) =>
      (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<String> createAccount(AccountInput input) async {
    final now = stamp.now();
    final id = newId();
    final m = db.accounts.sortOrder.max();
    final q = db.selectOnly(db.accounts)
      ..addColumns([m])
      ..where(db.accounts.deletedAt.isNull());
    final order = ((await q.getSingle()).read(m) ?? -1) + 1;
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: input.name,
            kind: input.kind.code,
            initialBalance: input.initialBalance,
            initialDate: input.initialDate,
            sortOrder: order,
          ),
        );
    return id;
  }

  Future<void> updateAccount(String id, AccountInput input) async {
    await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(input.name),
        kind: Value(input.kind.code),
        initialBalance: Value(input.initialBalance),
        initialDate: Value(input.initialDate),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  Future<void> reorderAccounts(List<String> orderedIds) =>
      _reorder('account', orderedIds);

  Future<MasterUsage> accountUsage(String id) async {
    const w = 'account_id = ? OR to_account_id = ?';
    return MasterUsage(
      txns: await _count('txn', w, [id, id]),
      planLines: await _count('plan_line', w, [id, id]),
      templates: await _count('template', w, [id, id]),
      assets: await _count('asset', 'account_id = ?', [id]),
    );
  }

  /// 関連履歴ごと削除。実績・計画行・率・起点を削除し、テンプレートと資産の保管口座は空欄にする。
  Future<void> deleteAccountWithHistory(String id) {
    return db.transaction(() async {
      final now = stamp.now();
      const w = 'account_id = ? OR to_account_id = ?';
      await softDeleteRows(db, stamp, 'txn', await _ids('txn', w, [id, id]));
      await softDeleteRows(
        db,
        stamp,
        'plan_line',
        await _ids('plan_line', w, [id, id]),
      );
      for (final t in ['plan_rate', 'plan_baseline']) {
        await softDeleteRows(
          db,
          stamp,
          t,
          await _ids(t, "target_type = 'account' AND target_id = ?", [id]),
        );
      }
      await _blank('template', 'account_id', id, now);
      await _blank('template', 'to_account_id', id, now);
      await _blank('asset', 'account_id', id, now);
      await softDeleteRows(db, stamp, 'account', [id]);
    });
  }

  /// 付け替えて削除。実績・計画行・テンプレート・資産の保管口座を [toId] へ移す。
  Future<void> reassignAccountAndDelete(String id, String toId) {
    return db.transaction(() async {
      final now = stamp.now();
      for (final table in ['txn', 'plan_line', 'template']) {
        await _replace(table, 'account_id', id, toId, now);
        await _replace(table, 'to_account_id', id, toId, now);
      }
      await _replace('asset', 'account_id', id, toId, now);
      for (final t in ['plan_rate', 'plan_baseline']) {
        await softDeleteRows(
          db,
          stamp,
          t,
          await _ids(t, "target_type = 'account' AND target_id = ?", [id]),
        );
      }
      await softDeleteRows(db, stamp, 'account', [id]);
    });
  }

  // ---- 内部 ----

  Future<void> _deleteAssetsCompletely(
    List<String> assetIds,
    String now,
  ) async {
    for (final assetId in assetIds) {
      await softDeleteRows(
        db,
        stamp,
        'asset_value',
        await _ids('asset_value', 'asset_id = ?', [assetId]),
      );
      await softDeleteRows(
        db,
        stamp,
        'txn',
        await _ids('txn', 'asset_id = ?', [assetId]),
      );
      await softDeleteRows(
        db,
        stamp,
        'plan_line',
        await _ids('plan_line', 'asset_id = ?', [assetId]),
      );
      for (final t in ['plan_rate', 'plan_baseline']) {
        await softDeleteRows(
          db,
          stamp,
          t,
          await _ids(t, "target_type = 'asset' AND target_id = ?", [assetId]),
        );
      }
      await _blankAssetOfTemplates(assetId, now);
    }
    await softDeleteRows(db, stamp, 'asset', assetIds);
  }

  Future<void> _blankAssetOfTemplates(String assetId, String now) async {
    await db.customUpdate(
      'UPDATE template SET asset_id = NULL, asset_action = NULL, '
      'quantity_x1e4 = NULL, updated_at = ?, updated_by = ? '
      'WHERE asset_id = ? AND deleted_at IS NULL',
      variables: [
        Variable.withString(now),
        Variable.withString(stamp.deviceId),
        Variable.withString(assetId),
      ],
      updates: {db.templates},
      updateKind: UpdateKind.update,
    );
  }

  Future<List<String>> _ids(
    String table,
    String where,
    List<String> args,
  ) async {
    final rows = await db
        .customSelect(
          'SELECT id FROM $table WHERE deleted_at IS NULL AND ($where)',
          variables: [for (final a in args) Variable.withString(a)],
        )
        .get();
    return [for (final r in rows) r.read<String>('id')];
  }

  Future<int> _count(String table, String where, List<String> args) async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM $table WHERE deleted_at IS NULL AND ($where)',
          variables: [for (final a in args) Variable.withString(a)],
        )
        .getSingle();
    return row.read<int>('c');
  }

  TableInfo<Table, dynamic> _info(String table) =>
      db.allTables.firstWhere((t) => t.actualTableName == table);

  Future<void> _blank(String table, String column, String id, String now) =>
      db.customUpdate(
        'UPDATE $table SET $column = NULL, updated_at = ?, updated_by = ? '
        'WHERE $column = ? AND deleted_at IS NULL',
        variables: [
          Variable.withString(now),
          Variable.withString(stamp.deviceId),
          Variable.withString(id),
        ],
        updates: {_info(table)},
        updateKind: UpdateKind.update,
      );

  Future<void> _replace(
    String table,
    String column,
    String from,
    String to,
    String now,
  ) => db.customUpdate(
    'UPDATE $table SET $column = ?, updated_at = ?, updated_by = ? '
    'WHERE $column = ? AND deleted_at IS NULL',
    variables: [
      Variable.withString(to),
      Variable.withString(now),
      Variable.withString(stamp.deviceId),
      Variable.withString(from),
    ],
    updates: {_info(table)},
    updateKind: UpdateKind.update,
  );

  Future<void> _reorder(String table, List<String> orderedIds) {
    return db.transaction(() async {
      final now = stamp.now();
      for (final (i, id) in orderedIds.indexed) {
        await db.customUpdate(
          'UPDATE $table SET sort_order = ?, updated_at = ?, updated_by = ? '
          'WHERE id = ? AND sort_order <> ?',
          variables: [
            Variable.withInt(i),
            Variable.withString(now),
            Variable.withString(stamp.deviceId),
            Variable.withString(id),
            Variable.withInt(i),
          ],
          updates: {_info(table)},
          updateKind: UpdateKind.update,
        );
      }
    });
  }

  Future<int> _nextCategoryOrder(CategoryKind kind) async {
    final m = db.categories.sortOrder.max();
    final q = db.selectOnly(db.categories)
      ..addColumns([m])
      ..where(
        db.categories.deletedAt.isNull() & db.categories.kind.equals(kind.code),
      );
    return ((await q.getSingle()).read(m) ?? -1) + 1;
  }
}
