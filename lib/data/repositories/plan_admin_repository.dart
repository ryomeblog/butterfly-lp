import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/time.dart';
import '../db/database.dart';
import 'plan_repository.dart';
import 'stamp.dart';

/// プランの名前変更・複製・削除と、実績と資産を引き継ぐ作成（設計書 3.4）。
class PlanAdminRepository {
  PlanAdminRepository(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  Future<void> rename(String planId, String name) =>
      (db.update(db.plans)..where((p) => p.id.equals(planId))).write(
        PlansCompanion(
          name: Value(name),
          updatedAt: Value(stamp.now()),
          updatedBy: Value(stamp.deviceId),
        ),
      );

  /// プランを丸ごと複製する。家族・計画行・イベント・率・グループの登録・実績・資産と価値を新しいUUIDで写し、
  /// 複製日（今日）を新しい起点日として計画線の起点を計算し直す（設計書 4.5）。
  Future<String> duplicate(String sourcePlanId, String newName) {
    return db.transaction(() async {
      final src = await (db.select(
        db.plans,
      )..where((p) => p.id.equals(sourcePlanId))).getSingle();
      final now = stamp.now();
      final planId = newId();
      final c = _Copier(db, stamp, now, sourcePlanId, planId, newName);

      final members = await c.copyMembers();
      await db
          .into(db.plans)
          .insert(
            src
                .toCompanion(true)
                .copyWith(
                  id: Value(planId),
                  name: Value(newName),
                  protagonistMemberId: Value(
                    members[src.protagonistMemberId] ?? src.protagonistMemberId,
                  ),
                  baselineDate: Value(todayString()),
                  copiedFromPlanId: Value(sourcePlanId),
                  sortOrder: Value(await _nextOrder()),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                  deletedAt: const Value(null),
                ),
          );
      final events = await c.copyEvents(members);
      await c.copyAssetsAndTemplates();
      final regs = await c.copyRegistrations();
      await c.copyRates();
      await c.copyLines(members: members, events: events, regs: regs);
      await c.copyTxns(events: events);
      await _rebaseline(planId);
      return planId;
    });
  }

  /// 新しいプランを作り、[sourcePlanId] の実績と資産を引き継ぐ（設計書 3.4）。
  /// 家族・計画行・イベントは引き継がない（実績のイベントとの関連は外す）。
  Future<String> createInheriting(NewPlanInput input, String sourcePlanId) {
    return db.transaction(() async {
      final planId = await PlanRepository(db, stamp).createPlan(input);
      final c = _Copier(
        db,
        stamp,
        stamp.now(),
        sourcePlanId,
        planId,
        input.name,
      );
      await c.copyAssetsAndTemplates();
      await c.copyTxns(events: const {});
      await _rebaseline(planId);
      return planId;
    });
  }

  /// プランの削除。配下のデータも一緒に削除する（設計書 3.4）。
  /// そのプランの資産を参照するテンプレートは残し、資産の欄を空にする。
  Future<void> delete(String planId) {
    return db.transaction(() async {
      final now = stamp.now();
      Future<List<String>> ids(
        String table,
        String where, [
        List<String>? args,
      ]) async => [
        for (final r
            in await db
                .customSelect(
                  'SELECT id FROM $table WHERE deleted_at IS NULL AND ($where)',
                  variables: [
                    for (final a in args ?? [planId]) Variable.withString(a),
                  ],
                )
                .get())
          r.read<String>('id'),
      ];
      final assetIds = await ids('asset', 'plan_id = ?');
      for (final a in assetIds) {
        await softDeleteRows(
          db,
          stamp,
          'asset_value',
          await ids('asset_value', 'asset_id = ?', [a]),
        );
        await db.customUpdate(
          'UPDATE template SET asset_id = NULL, asset_action = NULL, quantity_x1e4 = NULL, '
          'updated_at = ?, updated_by = ? WHERE asset_id = ? AND deleted_at IS NULL',
          variables: [
            Variable.withString(now),
            Variable.withString(stamp.deviceId),
            Variable.withString(a),
          ],
          updates: {db.templates},
          updateKind: UpdateKind.update,
        );
      }
      for (final t in [
        'txn',
        'asset',
        'plan_line',
        'plan_event',
        'family_member',
        'plan_rate',
        'plan_baseline',
        'plan_group',
      ]) {
        await softDeleteRows(db, stamp, t, await ids(t, 'plan_id = ?'));
      }
      await softDeleteRows(db, stamp, 'plan', [planId]);
    });
  }

  Future<void> _rebaseline(String planId) async {
    final plan = await (db.select(
      db.plans,
    )..where((p) => p.id.equals(planId))).getSingle();
    final repo = PlanRepository(db, stamp);
    await repo.writeAccountBaselines(planId, plan.baselineDate);
    await repo.writeAssetBaselines(planId, plan.baselineDate);
  }

  Future<int> _nextOrder() async {
    final m = db.plans.sortOrder.max();
    final q = db.selectOnly(db.plans)
      ..addColumns([m])
      ..where(db.plans.deletedAt.isNull());
    return ((await q.getSingle()).read(m) ?? -1) + 1;
  }
}

/// 1つのプランから別のプランへ行を写す。写した行の新旧IDの対応を持ち、参照を付け替える。
class _Copier {
  _Copier(this.db, this.stamp, this.now, this.from, this.to, this.newPlanName);

  final AppDatabase db;
  final Stamp stamp;
  final String now;
  final String from;
  final String to;
  final String newPlanName;

  final assets = <String, String>{};
  final templates = <String, String>{};
  final groups = <String, String>{};
  final items = <String, String>{};

  String? _map(Map<String, String> m, String? id) =>
      id == null ? null : (m[id] ?? id);

  Future<Map<String, String>> copyMembers() async {
    final map = <String, String>{};
    for (final m in await (db.select(
      db.familyMembers,
    )..where((x) => x.planId.equals(from) & x.deletedAt.isNull())).get()) {
      final id = newId();
      map[m.id] = id;
      await db
          .into(db.familyMembers)
          .insert(
            m
                .toCompanion(true)
                .copyWith(
                  id: Value(id),
                  planId: Value(to),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
          );
    }
    return map;
  }

  Future<Map<String, String>> copyEvents(Map<String, String> members) async {
    final map = <String, String>{};
    for (final e in await (db.select(
      db.planEvents,
    )..where((x) => x.planId.equals(from) & x.deletedAt.isNull())).get()) {
      final id = newId();
      map[e.id] = id;
      await db
          .into(db.planEvents)
          .insert(
            e
                .toCompanion(true)
                .copyWith(
                  id: Value(id),
                  planId: Value(to),
                  memberId: Value(members[e.memberId] ?? e.memberId),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
          );
    }
    return map;
  }

  /// 資産と価値、その資産を参照するテンプレートと、それを項目に含むグループを写す（設計書 3.4）。
  Future<void> copyAssetsAndTemplates() async {
    for (final a in await (db.select(
      db.assets,
    )..where((x) => x.planId.equals(from) & x.deletedAt.isNull())).get()) {
      final id = newId();
      assets[a.id] = id;
      await db
          .into(db.assets)
          .insert(
            a
                .toCompanion(true)
                .copyWith(
                  id: Value(id),
                  planId: Value(to),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
          );
      for (final v in await (db.select(
        db.assetValues,
      )..where((x) => x.assetId.equals(a.id) & x.deletedAt.isNull())).get()) {
        await db
            .into(db.assetValues)
            .insert(
              v
                  .toCompanion(true)
                  .copyWith(
                    id: Value(assetValueId(id, v.valueDate)),
                    assetId: Value(id),
                    createdAt: Value(now),
                    updatedAt: Value(now),
                    updatedBy: Value(stamp.deviceId),
                  ),
            );
      }
    }
    if (assets.isEmpty) return;
    final suffix = '（$newPlanName）';
    for (final t
        in await (db.select(
              db.templates,
            )..where((x) => x.assetId.isIn(assets.keys) & x.deletedAt.isNull()))
            .get()) {
      final id = newId();
      templates[t.id] = id;
      await db
          .into(db.templates)
          .insert(
            t
                .toCompanion(true)
                .copyWith(
                  id: Value(id),
                  name: Value('${t.name}$suffix'),
                  assetId: Value(assets[t.assetId]),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
          );
    }
    if (templates.isEmpty) return;
    final groupIds = {
      for (final i
          in await (db.select(db.templateGroupItems)..where(
                (x) => x.templateId.isIn(templates.keys) & x.deletedAt.isNull(),
              ))
              .get())
        i.groupId,
    };
    for (final g in await (db.select(
      db.templateGroups,
    )..where((x) => x.id.isIn(groupIds) & x.deletedAt.isNull())).get()) {
      final id = newId();
      groups[g.id] = id;
      await db
          .into(db.templateGroups)
          .insert(
            g
                .toCompanion(true)
                .copyWith(
                  id: Value(id),
                  name: Value('${g.name}$suffix'),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
          );
      final its = await (db.select(
        db.templateGroupItems,
      )..where((x) => x.groupId.equals(g.id) & x.deletedAt.isNull())).get();
      for (final i in its) {
        items[i.id] = newId();
      }
      for (final i in its) {
        await db
            .into(db.templateGroupItems)
            .insert(
              i
                  .toCompanion(true)
                  .copyWith(
                    id: Value(items[i.id]!),
                    groupId: Value(id),
                    templateId: Value(_map(templates, i.templateId)!),
                    baseItemId: Value(_map(items, i.baseItemId)),
                    createdAt: Value(now),
                    updatedAt: Value(now),
                    updatedBy: Value(stamp.deviceId),
                  ),
            );
      }
    }
  }

  Future<Map<String, String>> copyRegistrations() async {
    final map = <String, String>{};
    for (final r in await (db.select(
      db.planGroups,
    )..where((x) => x.planId.equals(from) & x.deletedAt.isNull())).get()) {
      final id = newId();
      map[r.id] = id;
      await db
          .into(db.planGroups)
          .insert(
            r
                .toCompanion(true)
                .copyWith(
                  id: Value(id),
                  planId: Value(to),
                  groupId: Value(_map(groups, r.groupId)!),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
          );
    }
    return map;
  }

  Future<void> copyRates() async {
    for (final r in await (db.select(
      db.planRates,
    )..where((x) => x.planId.equals(from) & x.deletedAt.isNull())).get()) {
      final target = _map(assets, r.targetId)!;
      await db
          .into(db.planRates)
          .insert(
            r
                .toCompanion(true)
                .copyWith(
                  id: Value(planTargetId(to, r.targetType, target)),
                  planId: Value(to),
                  targetId: Value(target),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  updatedBy: Value(stamp.deviceId),
                ),
          );
    }
  }

  Future<void> copyLines({
    required Map<String, String> members,
    required Map<String, String> events,
    required Map<String, String> regs,
  }) async {
    final rows = await (db.select(
      db.planLines,
    )..where((x) => x.planId.equals(from) & x.deletedAt.isNull())).get();
    await db.batch((b) {
      for (final l in rows) {
        final sourceId = switch (l.source) {
          'group' => _map(regs, l.sourceId),
          'event' => _map(events, l.sourceId),
          _ => l.sourceId,
        };
        b.insert(
          db.planLines,
          l
              .toCompanion(true)
              .copyWith(
                id: Value(newId()),
                planId: Value(to),
                assetId: Value(_map(assets, l.assetId)),
                eventId: Value(_map(events, l.eventId)),
                sourceId: Value(sourceId),
                memberId: Value(_map(members, l.memberId)),
                groupItemId: Value(_map(items, l.groupItemId)),
                createdAt: Value(now),
                updatedAt: Value(now),
                updatedBy: Value(stamp.deviceId),
              ),
        );
      }
    });
  }

  /// 実績を写す。[events] にないイベントとの関連は外す（引き継ぎではイベントを写さない）。
  Future<void> copyTxns({required Map<String, String> events}) async {
    final rows = await (db.select(
      db.txns,
    )..where((x) => x.planId.equals(from) & x.deletedAt.isNull())).get();
    final map = {for (final t in rows) t.id: newId()};
    await db.batch((b) {
      for (final t in rows) {
        b.insert(
          db.txns,
          t
              .toCompanion(true)
              .copyWith(
                id: Value(map[t.id]!),
                planId: Value(to),
                assetId: Value(_map(assets, t.assetId)),
                eventId: Value(t.eventId == null ? null : events[t.eventId]),
                parentTxnId: Value(_map(map, t.parentTxnId)),
                groupId: Value(_map(groups, t.groupId)),
                groupItemId: Value(_map(items, t.groupItemId)),
                createdAt: Value(now),
                updatedAt: Value(now),
                updatedBy: Value(stamp.deviceId),
              ),
        );
      }
    });
  }
}
