import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/calc/balance.dart';
import '../../domain/calc/ledger.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'stamp.dart';

/// 実績の入力内容（家計簿の入力画面。資産・イベントの欄は M5・M6 で加える）。
class TxnInput {
  const TxnInput({
    required this.planId,
    required this.date,
    required this.kind,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.memo,
  });

  final String planId;
  final String date;
  final TxnKind kind;
  final int amount;
  final String accountId;
  final String? categoryId;
  final String? toAccountId;
  final String? memo;
}

LedgerTxn ledgerTxnOf(TxnRow r) => LedgerTxn(
  id: r.id,
  date: r.date,
  kind: TxnKind.of(r.kind),
  amount: r.amount,
  accountId: r.accountId,
  categoryId: r.categoryId,
  toAccountId: r.toAccountId,
  memo: r.memo,
);

BalanceTxn balanceTxnOf(TxnRow r) => BalanceTxn(
  date: r.date,
  kind: TxnKind.of(r.kind),
  amount: r.amount,
  accountId: r.accountId,
  toAccountId: r.toAccountId,
);

/// 実績（プランごと。設計書 4.4 txn）。
class TxnRepository {
  TxnRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  /// プランの実績のうち [from]〜[to]（どちらも `YYYY-MM-DD`、含む）。null なら制限しない。
  Stream<List<TxnRow>> watchTxns(String planId, {String? from, String? to}) {
    final q = db.select(db.txns)
      ..where((t) {
        var e = t.planId.equals(planId) & t.deletedAt.isNull();
        if (from != null) e = e & t.date.isBiggerOrEqualValue(from);
        if (to != null) e = e & t.date.isSmallerOrEqualValue(to);
        return e;
      })
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  Future<TxnRow?> getTxn(String id) =>
      (db.select(db.txns)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> createTxn(TxnInput input) async {
    final now = stamp.now();
    final id = newId();
    await db
        .into(db.txns)
        .insert(
          TxnsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: input.planId,
            date: input.date,
            kind: input.kind.code,
            amount: input.amount,
            categoryId: Value(
              input.kind == TxnKind.transfer ? null : input.categoryId,
            ),
            accountId: input.accountId,
            toAccountId: Value(
              input.kind == TxnKind.transfer ? input.toAccountId : null,
            ),
            memo: Value(input.memo),
          ),
        );
    return id;
  }

  /// 更新。資産・イベント・グループの記録（asset_id・event_id・group_item_id など）は変えない。
  Future<void> updateTxn(String id, TxnInput input) async {
    await (db.update(db.txns)..where((t) => t.id.equals(id))).write(
      TxnsCompanion(
        date: Value(input.date),
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
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  Future<void> deleteTxn(String id) => softDeleteRows(db, stamp, 'txn', [id]);
}
