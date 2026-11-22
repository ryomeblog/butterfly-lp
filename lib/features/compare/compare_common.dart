import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/calc/compare.dart';

/// 計画行・実績を突き合わせ用の形に（設計書 6.8）。
PlanItem planItemOf(PlanLineRow l) => PlanItem(
  match: matchItemOfLine(l),
  ym: YearMonth(l.year, l.month),
  groupItemId: l.groupItemId,
  eventId: l.eventId,
);

ActualItem actualItemOf(TxnRow t) => ActualItem(
  match: matchItemOfTxn(t),
  date: t.date,
  groupItemId: t.groupItemId,
  eventId: t.eventId,
);
