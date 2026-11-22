import '../models/enums.dart';

/// 予定と実績の突き合わせに使う項目（plan_line・txn 共通）。
class MatchItem {
  const MatchItem({
    required this.id,
    required this.kind,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
  });

  final String id;
  final TxnKind kind;
  final int amount;
  final String accountId;
  final String? categoryId;
  final String? toAccountId;
  final String? assetId;
  final AssetAction? assetAction;

  /// 突き合わせのキー（設計書 6.8）：同じ種類・同じカテゴリ。振替は同じ口座、資産の動きは同じ資産・同じ動き。
  String get matchKey {
    if (assetId != null && assetAction != null) {
      return '${kind.code}|asset|$assetId|${assetAction!.code}';
    }
    if (kind == TxnKind.transfer) {
      return '${kind.code}|transfer|$accountId|$toAccountId';
    }
    return '${kind.code}|category|$categoryId';
  }
}

/// イベントを指す予定の、それぞれの実績額（設計書 6.8）。
///
/// 同じ event_id の実績のうち、キーが同じものの合計を実績額とする（月は問わない）。
/// 実績額が0でなければ「入力済み」。同じキーの予定が複数あれば、どれも同じ実績額になる。
Map<String, int> eventLineActuals(
  Iterable<MatchItem> eventLines,
  Iterable<MatchItem> eventTxns,
) {
  final sums = <String, int>{};
  for (final t in eventTxns) {
    sums[t.matchKey] = (sums[t.matchKey] ?? 0) + t.amount;
  }
  return {for (final l in eventLines) l.id: sums[l.matchKey] ?? 0};
}

/// 予定・実績の合計（支出・収入。振替は収支に含めない）。
class KindTotals {
  const KindTotals({this.income = 0, this.expense = 0});

  final int income;
  final int expense;

  int get net => income - expense;
}

KindTotals kindTotals(Iterable<MatchItem> items) {
  var income = 0;
  var expense = 0;
  for (final i in items) {
    if (i.kind == TxnKind.income) income += i.amount;
    if (i.kind == TxnKind.expense) expense += i.amount;
  }
  return KindTotals(income: income, expense: expense);
}
