import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../domain/models/enums.dart';
import '../ledger/ledger_widgets.dart';

/// その年の年齢（イベントの表示・年齢での指定に使う。年齢での指定は「生年＋年齢」の年に置き換える）。
int ageInYear(FamilyMemberRow m, int year) =>
    year - parseDate(m.birthDate).year;

/// 「2030年3月20日・本人 40歳」
String eventWhen(PlanEventRow e, FamilyMemberRow? m) {
  final date = e.day == null
      ? '${e.year}年${e.month}月'
      : '${e.year}年${e.month}月${e.day}日';
  return m == null ? date : '$date・${m.name} ${ageInYear(m, e.year)}歳';
}

/// 予定の収支の種類（イベントの行の入力で選ぶ）。
enum EventLineType {
  expense('支出', TxnKind.expense, null),
  income('収入', TxnKind.income, null),
  transfer('振替', TxnKind.transfer, null),
  buy('資産の購入', TxnKind.expense, AssetAction.buy),
  sell('資産の売却', TxnKind.income, AssetAction.sell),
  assetIncome('資産の収益', TxnKind.income, AssetAction.income),
  assetCost('資産の費用', TxnKind.expense, AssetAction.cost);

  const EventLineType(this.label, this.kind, this.action);
  final String label;
  final TxnKind kind;
  final AssetAction? action;

  static EventLineType of(TxnKind kind, AssetAction? action) =>
      values.firstWhere(
        (t) => t.kind == kind && t.action == action,
        orElse: () => expense,
      );
}

/// 予定・実績の金額を符号つきで（収入＋、支出−、振替は符号なし）。
String signedAmount(TxnKind kind, int amount) => switch (kind) {
  TxnKind.income => formatYenSigned(amount),
  TxnKind.expense => formatYenSigned(-amount),
  TxnKind.transfer => formatYen(amount),
};

/// イベントの予定・実績の1行の見出し（種類・カテゴリ／資産・口座）。
String eventItemLabel({
  required TxnKind kind,
  required AssetAction? action,
  required String? categoryId,
  required String accountId,
  required String? toAccountId,
  required String? assetName,
  required Lookup lookup,
}) {
  final type = EventLineType.of(kind, action).label;
  if (kind == TxnKind.transfer) {
    return '$type　${lookup.accountName(accountId)} → ${lookup.accountName(toAccountId)}';
  }
  final what = assetName != null
      ? '資産「$assetName」'
      : lookup.categoryName(categoryId);
  return '$type　$what・${lookup.accountName(accountId)}';
}

/// 状態の小さな印。
class EventStatusChip extends StatelessWidget {
  const EventStatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final done = status == EventStatus.done.code;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: done ? scheme.secondaryContainer : null,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        EventStatus.of(status).label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
