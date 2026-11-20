import '../../core/time.dart';
import '../models/enums.dart';

/// 家計簿の集計に使う実績の項目。
class LedgerTxn {
  const LedgerTxn({
    required this.id,
    required this.date,
    required this.kind,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.memo,
  });

  final String id;
  final String date;
  final TxnKind kind;
  final int amount;
  final String accountId;
  final String? categoryId;
  final String? toAccountId;
  final String? memo;

  String get ym => date.substring(0, 7);
  int get month => int.parse(date.substring(5, 7));
  int get day => int.parse(date.substring(8, 10));
}

/// 収入・支出・収支（振替は含めない。設計書 3.1・6.8）。
class LedgerTotals {
  const LedgerTotals({this.income = 0, this.expense = 0});

  final int income;
  final int expense;

  int get net => income - expense;

  LedgerTotals add(LedgerTxn t) => switch (t.kind) {
    TxnKind.income => LedgerTotals(income: income + t.amount, expense: expense),
    TxnKind.expense => LedgerTotals(
      income: income,
      expense: expense + t.amount,
    ),
    TxnKind.transfer => this,
  };
}

LedgerTotals totalsOf(Iterable<LedgerTxn> txns) =>
    txns.fold(const LedgerTotals(), (a, t) => a.add(t));

/// カテゴリ1つ分の集計（円グラフ・内訳のアコーディオン）。
class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.amount,
    required this.count,
    required this.ratio,
  });

  /// カテゴリなし（参照切れ）は null
  final String? categoryId;
  final int amount;
  final int count;

  /// その種類の合計に占める割合（0〜1）
  final double ratio;
}

/// [kind]（収入か支出）の実績を、カテゴリ別に金額の大きい順で集計する。
List<CategoryTotal> totalsByCategory(Iterable<LedgerTxn> txns, TxnKind kind) {
  final sums = <String?, int>{};
  final counts = <String?, int>{};
  var total = 0;
  for (final t in txns) {
    if (t.kind != kind) continue;
    sums[t.categoryId] = (sums[t.categoryId] ?? 0) + t.amount;
    counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
    total += t.amount;
  }
  final list = [
    for (final e in sums.entries)
      CategoryTotal(
        categoryId: e.key,
        amount: e.value,
        count: counts[e.key]!,
        ratio: total == 0 ? 0 : e.value / total,
      ),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  return list;
}

/// 1か月分の金額と件数。
class MonthTotal {
  const MonthTotal(this.month, this.amount, this.count);
  final int month;
  final int amount;
  final int count;
}

/// 年表示のアコーディオン「月ごとにまとめる」：1月〜12月の金額と件数（実績のない月も出す）。
List<MonthTotal> monthlyTotals(Iterable<LedgerTxn> txns) {
  final amounts = List.filled(13, 0);
  final counts = List.filled(13, 0);
  for (final t in txns) {
    amounts[t.month] += t.amount;
    counts[t.month]++;
  }
  return [for (var m = 1; m <= 12; m++) MonthTotal(m, amounts[m], counts[m])];
}

/// カレンダー：日ごとの収入・支出。
Map<int, LedgerTotals> dailyTotals(Iterable<LedgerTxn> txns) {
  final map = <int, LedgerTotals>{};
  for (final t in txns) {
    map[t.day] = (map[t.day] ?? const LedgerTotals()).add(t);
  }
  return map;
}

/// 新しい順（日付の降順、同じ日は入力の逆順を保つ）。
List<LedgerTxn> newestFirst(Iterable<LedgerTxn> txns) {
  final list = txns.toList();
  final indexed = [for (final (i, t) in list.indexed) (i, t)];
  indexed.sort((a, b) {
    final c = b.$2.date.compareTo(a.$2.date);
    return c != 0 ? c : b.$1.compareTo(a.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// リストの絞り込み条件（設計書 3.1：カテゴリ・口座・種類・期間・金額範囲）。
class LedgerFilter {
  const LedgerFilter({
    required this.from,
    required this.to,
    this.categoryIds = const {},
    this.accountIds = const {},
    this.kinds = const {},
    this.minAmount,
    this.maxAmount,
  });

  /// 月のはじめから月末まで。
  factory LedgerFilter.month(YearMonth ym) =>
      LedgerFilter(from: ym.firstDayString, to: ym.lastDayString);

  final String from;
  final String to;

  /// 空なら全部
  final Set<String> categoryIds;
  final Set<String> accountIds;
  final Set<TxnKind> kinds;
  final int? minAmount;
  final int? maxAmount;

  bool get isNarrowed =>
      categoryIds.isNotEmpty ||
      accountIds.isNotEmpty ||
      kinds.isNotEmpty ||
      minAmount != null ||
      maxAmount != null;

  bool matches(LedgerTxn t) {
    if (t.date.compareTo(from) < 0 || t.date.compareTo(to) > 0) return false;
    if (categoryIds.isNotEmpty && !categoryIds.contains(t.categoryId)) {
      return false;
    }
    if (accountIds.isNotEmpty &&
        !accountIds.contains(t.accountId) &&
        !accountIds.contains(t.toAccountId)) {
      return false;
    }
    if (kinds.isNotEmpty && !kinds.contains(t.kind)) return false;
    if (minAmount != null && t.amount < minAmount!) return false;
    if (maxAmount != null && t.amount > maxAmount!) return false;
    return true;
  }

  LedgerFilter copyWith({
    String? from,
    String? to,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    Set<TxnKind>? kinds,
    int? Function()? minAmount,
    int? Function()? maxAmount,
  }) => LedgerFilter(
    from: from ?? this.from,
    to: to ?? this.to,
    categoryIds: categoryIds ?? this.categoryIds,
    accountIds: accountIds ?? this.accountIds,
    kinds: kinds ?? this.kinds,
    minAmount: minAmount != null ? minAmount() : this.minAmount,
    maxAmount: maxAmount != null ? maxAmount() : this.maxAmount,
  );
}
