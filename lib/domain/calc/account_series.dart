import '../../core/time.dart';
import 'balance.dart';

/// 口座の月末残高の推移（口座詳細のグラフ）。設計書 6.1 を月末ごとに当てはめる。
///
/// [txns] は日付順でなくてよい。[from]〜[to] の各月末の残高を返す。
List<(YearMonth, int)> monthEndBalances(
  BalanceAccount account,
  Iterable<BalanceTxn> txns,
  YearMonth from,
  YearMonth to,
) {
  final sorted = [
    for (final t in txns)
      if (t.date.compareTo(account.initialDate) >= 0) t,
  ]..sort((a, b) => a.date.compareTo(b.date));
  final result = <(YearMonth, int)>[];
  var i = 0;
  var balance = account.initialBalance;
  for (var ym = from; ym <= to; ym = ym.addMonths(1)) {
    final end = ym.lastDayString;
    while (i < sorted.length && sorted[i].date.compareTo(end) <= 0) {
      balance += balanceDelta(sorted[i], account.id);
      i++;
    }
    result.add((ym, end.compareTo(account.initialDate) < 0 ? 0 : balance));
  }
  return result;
}
