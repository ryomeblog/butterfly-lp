import '../models/enums.dart';

/// 口座残高の計算に必要な実績の項目。
class BalanceTxn {
  const BalanceTxn({
    required this.date,
    required this.kind,
    required this.amount,
    required this.accountId,
    this.toAccountId,
  });

  final String date;
  final TxnKind kind;
  final int amount;
  final String accountId;
  final String? toAccountId;
}

class BalanceAccount {
  const BalanceAccount({
    required this.id,
    required this.initialBalance,
    required this.initialDate,
  });

  final String id;
  final int initialBalance;
  final String initialDate;
}

/// 1件の実績が、ある口座の残高をいくら増減させるか（設計書 6.1 の表）。
int balanceDelta(BalanceTxn t, String accountId) {
  var d = 0;
  if (t.accountId == accountId) {
    d += switch (t.kind) {
      TxnKind.income => t.amount,
      TxnKind.expense => -t.amount,
      TxnKind.transfer => -t.amount,
    };
  }
  if (t.kind == TxnKind.transfer && t.toAccountId == accountId) {
    d += t.amount;
  }
  return d;
}

/// [date]（`YYYY-MM-DD`、その日を含む）時点の口座残高。
///
/// 初期残高＋`initial_date` 以降の実績（設計書 6.1）。[date] が `initial_date` より前なら 0。
/// [txns] はそのプランの実績だけを渡す（残高はプランごとに異なる）。
int accountBalanceAt(
  BalanceAccount account,
  Iterable<BalanceTxn> txns,
  String date,
) {
  if (date.compareTo(account.initialDate) < 0) return 0;
  var balance = account.initialBalance;
  for (final t in txns) {
    if (t.date.compareTo(account.initialDate) < 0) continue;
    if (t.date.compareTo(date) > 0) continue;
    balance += balanceDelta(t, account.id);
  }
  return balance;
}
