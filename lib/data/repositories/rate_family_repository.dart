import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import 'stamp.dart';

class MemberInput {
  const MemberInput({
    required this.name,
    required this.relation,
    required this.birthDate,
    required this.lifeExpectancy,
  });

  final String name;
  final Relation relation;
  final String birthDate;
  final int lifeExpectancy;
}

/// 家族メンバーを削除すると消えるもの（家族画面に出す）。
class MemberDeletionImpact {
  const MemberDeletionImpact({
    required this.eventTitles,
    required this.planLineCount,
    required this.txnCount,
  });

  /// その人のイベント
  final List<String> eventTitles;

  /// そのイベントの予定（計画行）
  final int planLineCount;

  /// そのイベントを指す実績（紐づきだけが外れる）
  final int txnCount;
}

/// 率（想定利回り・上昇率）と家族（設計書 4.5 plan_rate / family_member）。
class RateFamilyRepository {
  RateFamilyRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  // ---- 率 ----

  Stream<List<PlanRateRow>> watchRates(String planId) => (db.select(
    db.planRates,
  )..where((r) => r.planId.equals(planId) & r.deletedAt.isNull())).watch();

  /// 率を設定する。[rate] が null なら設定を消す（カテゴリは既定値、口座・資産は0%として扱う）。
  Future<void> setRate(
    String planId,
    String targetType,
    String targetId,
    double? rate,
  ) async {
    final id = planTargetId(planId, targetType, targetId);
    final now = stamp.now();
    if (rate == null) {
      await softDeleteRows(db, stamp, 'plan_rate', [id]);
      return;
    }
    final existing = await (db.select(
      db.planRates,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (existing != null &&
        existing.deletedAt == null &&
        existing.annualRate == rate) {
      return;
    }
    await db
        .into(db.planRates)
        .insertOnConflictUpdate(
          PlanRatesCompanion.insert(
            id: id,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            targetType: targetType,
            targetId: targetId,
            annualRate: rate,
            // 消した率をもう一度設定したときは墓石を外す
            deletedAt: const Value(null),
          ),
        );
  }

  Future<void> setDefaultInflationRate(String planId, double rate) async {
    await (db.update(db.plans)..where((p) => p.id.equals(planId))).write(
      PlansCompanion(
        defaultInflationRate: Value(rate),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  // ---- 家族 ----

  Future<String> addMember(String planId, MemberInput input) async {
    final now = stamp.now();
    final id = newId();
    final m = db.familyMembers.sortOrder.max();
    final q = db.selectOnly(db.familyMembers)
      ..addColumns([m])
      ..where(
        db.familyMembers.planId.equals(planId) &
            db.familyMembers.deletedAt.isNull(),
      );
    final order = ((await q.getSingle()).read(m) ?? -1) + 1;
    await db
        .into(db.familyMembers)
        .insert(
          FamilyMembersCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            planId: planId,
            name: input.name,
            relation: input.relation.code,
            birthDate: input.birthDate,
            lifeExpectancy: input.lifeExpectancy,
            sortOrder: order,
          ),
        );
    return id;
  }

  Future<void> updateMember(String id, MemberInput input) async {
    await (db.update(db.familyMembers)..where((m) => m.id.equals(id))).write(
      FamilyMembersCompanion(
        name: Value(input.name),
        relation: Value(input.relation.code),
        birthDate: Value(input.birthDate),
        lifeExpectancy: Value(input.lifeExpectancy),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  Future<void> setProtagonist(String planId, String memberId) async {
    await (db.update(db.plans)..where((p) => p.id.equals(planId))).write(
      PlansCompanion(
        protagonistMemberId: Value(memberId),
        updatedAt: Value(stamp.now()),
        updatedBy: Value(stamp.deviceId),
      ),
    );
  }

  Future<MemberDeletionImpact> memberDeletionImpact(String memberId) async {
    final events = await (db.select(
      db.planEvents,
    )..where((e) => e.memberId.equals(memberId) & e.deletedAt.isNull())).get();
    final ids = [for (final e in events) e.id];
    var lines = 0;
    var txns = 0;
    if (ids.isNotEmpty) {
      lines =
          (await (db.select(db.planLines)
                    ..where((l) => l.eventId.isIn(ids) & l.deletedAt.isNull()))
                  .get())
              .length;
      txns =
          (await (db.select(db.txns)
                    ..where((t) => t.eventId.isIn(ids) & t.deletedAt.isNull()))
                  .get())
              .length;
    }
    return MemberDeletionImpact(
      eventTitles: [for (final e in events) e.title],
      planLineCount: lines,
      txnCount: txns,
    );
  }

  /// 家族メンバーの削除（設計書 3.7）。その人のイベントと、イベントの予定（計画行）を削除し、
  /// イベントを指す実績・手入力の予定は紐づき（event_id）だけを外す。主人公は削除できない。
  Future<void> deleteMember(String memberId) {
    return db.transaction(() async {
      final member = await (db.select(
        db.familyMembers,
      )..where((m) => m.id.equals(memberId))).getSingle();
      final plan = await (db.select(
        db.plans,
      )..where((p) => p.id.equals(member.planId))).getSingle();
      if (plan.protagonistMemberId == memberId) {
        throw StateError('主人公は削除できません');
      }
      final now = stamp.now();
      final events =
          await (db.select(db.planEvents)..where(
                (e) => e.memberId.equals(memberId) & e.deletedAt.isNull(),
              ))
              .get();
      final ids = [for (final e in events) e.id];
      if (ids.isNotEmpty) {
        final eventLines =
            await (db.select(db.planLines)..where(
                  (l) =>
                      l.source.equals(PlanLineSource.event.code) &
                      l.sourceId.isIn(ids) &
                      l.deletedAt.isNull(),
                ))
                .get();
        await softDeleteRows(db, stamp, 'plan_line', [
          for (final l in eventLines) l.id,
        ]);
        for (final table in ['txn', 'plan_line']) {
          final marks = List.filled(ids.length, '?').join(',');
          await db.customUpdate(
            'UPDATE $table SET event_id = NULL, updated_at = ?, updated_by = ? '
            'WHERE event_id IN ($marks) AND deleted_at IS NULL',
            variables: [
              Variable.withString(now),
              Variable.withString(stamp.deviceId),
              for (final id in ids) Variable.withString(id),
            ],
            updates: {table == 'txn' ? db.txns : db.planLines},
            updateKind: UpdateKind.update,
          );
        }
        await softDeleteRows(db, stamp, 'plan_event', ids);
      }
      await softDeleteRows(db, stamp, 'family_member', [memberId]);
    });
  }
}
