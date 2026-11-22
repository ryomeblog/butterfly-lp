import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/time.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/calc/event_matching.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'stamp.dart';

class EventInput {
  const EventInput({
    required this.planId,
    required this.memberId,
    required this.title,
    required this.year,
    required this.month,
    this.day,
    this.memo,
  });

  final String planId;
  final String memberId;
  final String title;
  final int year;
  final int month;

  /// 日付まで決めたときだけ。空なら年月だけのイベント
  final int? day;
  final String? memo;
}

/// イベントの予定の収支1行（編集中の内容。source=event の計画行）。
class EventLineDraft {
  EventLineDraft({
    required this.id,
    required this.kind,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.memo,
  });

  final String id;
  TxnKind kind;
  int amount;
  String accountId;
  String? categoryId;
  String? toAccountId;
  String? assetId;
  AssetAction? assetAction;
  String? memo;

  static EventLineDraft of(PlanLineRow l) => EventLineDraft(
    id: l.id,
    kind: TxnKind.of(l.kind),
    amount: l.amount,
    accountId: l.accountId,
    categoryId: l.categoryId,
    toAccountId: l.toAccountId,
    assetId: l.assetId,
    assetAction: l.assetAction == null ? null : AssetAction.of(l.assetAction!),
    memo: l.memo,
  );
}

/// イベントの実績入力の1行（設計書 3.10）。
class EventActualItem {
  const EventActualItem({
    required this.kind,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.memo,
  });

  final TxnKind kind;
  final int amount;
  final String accountId;
  final String? categoryId;
  final String? toAccountId;
  final String? assetId;
  final AssetAction? assetAction;
  final String? memo;
}

MatchItem matchItemOfLine(PlanLineRow l) => MatchItem(
  id: l.id,
  kind: TxnKind.of(l.kind),
  amount: l.amount,
  accountId: l.accountId,
  categoryId: l.categoryId,
  toAccountId: l.toAccountId,
  assetId: l.assetId,
  assetAction: l.assetAction == null ? null : AssetAction.of(l.assetAction!),
);

MatchItem matchItemOfTxn(TxnRow t) => MatchItem(
  id: t.id,
  kind: TxnKind.of(t.kind),
  amount: t.amount,
  accountId: t.accountId,
  categoryId: t.categoryId,
  toAccountId: t.toAccountId,
  assetId: t.assetId,
  assetAction: t.assetAction == null ? null : AssetAction.of(t.assetAction!),
);

/// イベント（プランごと。設計書 3.10・4.5 plan_event）。
class EventRepository {
  EventRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  Stream<List<PlanEventRow>> watchEvents(String planId) =>
      (db.select(db.planEvents)
            ..where((e) => e.planId.equals(planId) & e.deletedAt.isNull())
            ..orderBy([
              (e) => OrderingTerm(expression: e.year),
              (e) => OrderingTerm(expression: e.month),
              (e) => OrderingTerm(expression: e.day),
              (e) => OrderingTerm(expression: e.createdAt),
            ]))
          .watch();

  Future<PlanEventRow?> getEvent(String id) => (db.select(
    db.planEvents,
  )..where((e) => e.id.equals(id))).getSingleOrNull();

  /// プランの、イベントを指す計画行（予定の合計に使う）。
  Stream<List<PlanLineRow>> watchEventLines(String planId) =>
      (db.select(db.planLines)..where(
            (l) =>
                l.planId.equals(planId) &
                l.eventId.isNotNull() &
                l.deletedAt.isNull(),
          ))
          .watch();

  /// プランの、イベントを指す実績（実績の合計に使う）。
  Stream<List<TxnRow>> watchEventTxns(String planId) =>
      (db.select(db.txns)..where(
            (t) =>
                t.planId.equals(planId) &
                t.eventId.isNotNull() &
                t.deletedAt.isNull(),
          ))
          .watch();

  /// イベントと予定の収支を保存する。[eventId] が null なら新規。
  ///
  /// 予定の収支は source=event・source_id＝event_id の計画行として、イベントの年月に置く。
  /// イベントの年月を変えると、イベント由来の行も新しい年月へ移す。
  Future<String> saveEvent({
    String? eventId,
    required EventInput input,
    required List<EventLineDraft> lines,
  }) {
    return db.transaction(() async {
      final now = stamp.now();
      final id = eventId ?? newId();
      if (eventId == null) {
        await db
            .into(db.planEvents)
            .insert(
              PlanEventsCompanion.insert(
                id: id,
                createdAt: now,
                updatedAt: now,
                updatedBy: stamp.deviceId,
                planId: input.planId,
                memberId: input.memberId,
                title: input.title,
                year: input.year,
                month: input.month,
                day: Value(input.day),
                status: EventStatus.planned.code,
                memo: Value(input.memo),
              ),
            );
      } else {
        await (db.update(db.planEvents)..where((e) => e.id.equals(id))).write(
          PlanEventsCompanion(
            memberId: Value(input.memberId),
            title: Value(input.title),
            year: Value(input.year),
            month: Value(input.month),
            day: Value(input.day),
            memo: Value(input.memo),
            updatedAt: Value(now),
            updatedBy: Value(stamp.deviceId),
          ),
        );
      }

      final existing = {
        for (final l
            in await (db.select(db.planLines)..where(
                  (l) =>
                      l.source.equals(PlanLineSource.event.code) &
                      l.sourceId.equals(id) &
                      l.deletedAt.isNull(),
                ))
                .get())
          l.id: l,
      };
      for (final d in lines) {
        final values = PlanLinesCompanion(
          planId: Value(input.planId),
          year: Value(input.year),
          month: Value(input.month),
          kind: Value(d.kind.code),
          amount: Value(d.amount),
          categoryId: Value(d.kind == TxnKind.transfer ? null : d.categoryId),
          accountId: Value(d.accountId),
          toAccountId: Value(d.kind == TxnKind.transfer ? d.toAccountId : null),
          assetId: Value(d.assetId),
          assetAction: Value(d.assetId == null ? null : d.assetAction?.code),
          memo: Value(d.memo),
          source: Value(PlanLineSource.event.code),
          sourceId: Value(id),
          eventId: Value(id),
          memberId: Value(input.memberId),
        );
        final old = existing.remove(d.id);
        if (old == null) {
          await db
              .into(db.planLines)
              .insert(
                values.copyWith(
                  id: Value(d.id),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
              );
        } else {
          await (db.update(
            db.planLines,
          )..where((l) => l.id.equals(d.id))).write(
            values.copyWith(
              updatedAt: Value(now),
              updatedBy: Value(stamp.deviceId),
            ),
          );
        }
      }
      await softDeleteRows(db, stamp, 'plan_line', existing.keys);
      return id;
    });
  }

  /// イベントの状態（予定／実施済み）を変える。予定に戻すと実施日を消す。
  Future<void> setStatus(
    String eventId,
    EventStatus status, {
    String? doneDate,
  }) async {
    await (db.update(db.planEvents)..where((e) => e.id.equals(eventId))).write(
      PlanEventsCompanion(
        status: Value(status.code),
        doneDate: Value(status == EventStatus.done ? doneDate : null),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  /// イベントの実績を入力する（設計書 3.10）。入れた項目はどれも event_id 付きの実績になる。
  ///
  /// 資産の購入・売却は資産の動きとして記録する。数量×単価の資産は実施日の単価で数量を計算し、
  /// 評価額の資産の購入は購入日の評価額として価値にも記録する。[markDone] なら実施済みにして実施日を記録する。
  Future<void> recordActual({
    required PlanEventRow event,
    required String doneDate,
    required List<EventActualItem> items,
    required bool markDone,
  }) {
    return db.transaction(() async {
      final now = stamp.now();
      for (final i in items) {
        int? quantity;
        if (i.assetId != null &&
            (i.assetAction == AssetAction.buy ||
                i.assetAction == AssetAction.sell)) {
          final asset = await (db.select(
            db.assets,
          )..where((a) => a.id.equals(i.assetId!))).getSingleOrNull();
          if (asset != null && asset.valuation == Valuation.quantity.code) {
            final values =
                await (db.select(db.assetValues)..where(
                      (v) => v.assetId.equals(asset.id) & v.deletedAt.isNull(),
                    ))
                    .get();
            final price = valueAt([
              for (final v in values)
                ValuePoint(
                  unit: v.unit,
                  date: v.valueDate,
                  valueX100: v.valueX100,
                ),
            ], doneDate);
            if (price != null) quantity = quantityForAmount(i.amount, price);
          } else if (asset != null && i.assetAction == AssetAction.buy) {
            await db
                .into(db.assetValues)
                .insertOnConflictUpdate(
                  AssetValuesCompanion.insert(
                    id: assetValueId(asset.id, doneDate),
                    createdAt: now,
                    updatedAt: now,
                    updatedBy: stamp.deviceId,
                    assetId: asset.id,
                    unit: 'day',
                    valueDate: doneDate,
                    valueX100: i.amount * 100,
                    deletedAt: const Value(null),
                  ),
                );
          }
        }
        await db
            .into(db.txns)
            .insert(
              TxnsCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                updatedBy: stamp.deviceId,
                planId: event.planId,
                date: doneDate,
                kind: i.kind.code,
                amount: i.amount,
                categoryId: Value(
                  i.kind == TxnKind.transfer ? null : i.categoryId,
                ),
                accountId: i.accountId,
                toAccountId: Value(
                  i.kind == TxnKind.transfer ? i.toAccountId : null,
                ),
                assetId: Value(i.assetId),
                assetAction: Value(
                  i.assetId == null ? null : i.assetAction?.code,
                ),
                quantityX1e4: Value(quantity),
                eventId: Value(event.id),
                memo: Value(i.memo),
              ),
            );
      }
      if (markDone) {
        await setStatus(event.id, EventStatus.done, doneDate: doneDate);
      }
    });
  }

  /// イベントの削除（設計書 3.10）。予定の収支も削除し、入力済みの実績は残してイベントとの関連だけ外す。
  /// イベントを指定した手入力の予定も、関連だけ外して残す。
  Future<void> deleteEvent(String eventId) {
    return db.transaction(() async {
      final now = stamp.now();
      final eventLines =
          await (db.select(db.planLines)..where(
                (l) =>
                    l.source.equals(PlanLineSource.event.code) &
                    l.sourceId.equals(eventId) &
                    l.deletedAt.isNull(),
              ))
              .get();
      await softDeleteRows(db, stamp, 'plan_line', [
        for (final l in eventLines) l.id,
      ]);
      for (final (name, info) in <(String, TableInfo<Table, dynamic>)>[
        ('txn', db.txns),
        ('plan_line', db.planLines),
      ]) {
        await db.customUpdate(
          'UPDATE $name SET event_id = NULL, updated_at = ?, updated_by = ? '
          'WHERE event_id = ? AND deleted_at IS NULL',
          variables: [
            Variable.withString(now),
            Variable.withString(stamp.deviceId),
            Variable.withString(eventId),
          ],
          updates: {info},
          updateKind: UpdateKind.update,
        );
      }
      await softDeleteRows(db, stamp, 'plan_event', [eventId]);
    });
  }

  /// 予定日（日付まで決めたイベントはその日、年月だけならその月の1日）。実施日の初期値（設計書 3.10）。
  static String plannedDate(PlanEventRow e) =>
      dateString(DateTime(e.year, e.month, e.day ?? 1));
}
