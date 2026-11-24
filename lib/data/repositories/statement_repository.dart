import 'package:drift/drift.dart';

import '../../core/time.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'device_pref_repository.dart';
import 'plan_line_repository.dart';
import 'stamp.dart';
import 'txn_repository.dart';

/// 確認画面で決めた1行（設計書 3.11）。
class StatementEntry {
  const StatementEntry({
    required this.date,
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.content,
    this.memo,
  });

  /// YYYY-MM-DD（予定にするときは年月だけを使う）
  final String date;

  /// 支出か収入
  final TxnKind kind;
  final int amount;
  final String categoryId;

  /// 明細の内容（読み取ったまま）。カテゴリの規則に覚える
  final String content;
  final String? memo;
}

/// 明細の取り込み：カテゴリの規則（この端末だけ）と、実績・予定の登録（設計書 3.11）。
class StatementRepository {
  StatementRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  /// 内容 → カテゴリID（内容が完全に同じ規則だけ）。
  Future<Map<String, String>> rulesFor(
    TxnKind kind,
    Iterable<String> contents,
  ) async {
    final list = contents.toSet().toList();
    final out = <String, String>{};
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(
        i,
        i + 500 > list.length ? list.length : i + 500,
      );
      final rows = await (db.select(
        db.categoryRules,
      )..where((r) => r.kind.equals(kind.code) & r.content.isIn(chunk))).get();
      for (final r in rows) {
        out[r.content] = r.categoryId;
      }
    }
    return out;
  }

  Future<String?> pref(String key) => DevicePrefRepository(db).get(key);

  Future<void> setPref(String key, String value) =>
      DevicePrefRepository(db).set(key, value);

  /// まとめて実績（[asPlan] なら予定）にし、内容→カテゴリを覚える。作った件数を返す。
  Future<int> register({
    required String planId,
    required String accountId,
    required bool asPlan,
    required List<StatementEntry> entries,
  }) {
    final txns = TxnRepository(db, stamp);
    final lines = PlanLineRepository(db, stamp);
    return db.transaction(() async {
      final now = stamp.now();
      for (final e in entries) {
        assert(e.kind != TxnKind.transfer && e.amount > 0);
        if (asPlan) {
          await lines.createManual(
            PlanLineInput(
              planId: planId,
              ym: YearMonth.parse(e.date.substring(0, 7)),
              kind: e.kind,
              amount: e.amount,
              accountId: accountId,
              categoryId: e.categoryId,
              memo: e.memo,
            ),
          );
        } else {
          await txns.createTxn(
            TxnInput(
              planId: planId,
              date: e.date,
              kind: e.kind,
              amount: e.amount,
              accountId: accountId,
              categoryId: e.categoryId,
              memo: e.memo,
            ),
          );
        }
        if (e.content.isNotEmpty) {
          await db
              .into(db.categoryRules)
              .insertOnConflictUpdate(
                CategoryRulesCompanion.insert(
                  kind: e.kind.code,
                  content: e.content,
                  categoryId: e.categoryId,
                  updatedAt: now,
                ),
              );
        }
      }
      return entries.length;
    });
  }
}
