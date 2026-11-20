import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';

/// プランの主人公（なければ null）。
FamilyMemberRow? protagonistOf(PlanRow plan, List<FamilyMemberRow> members) =>
    members.where((m) => m.id == plan.protagonistMemberId).firstOrNull;

/// プランの終了年＝主人公の生年＋寿命（設計書 4.5）。
int? planEndYear(PlanRow plan, List<FamilyMemberRow> members) {
  final p = protagonistOf(plan, members);
  if (p == null) return null;
  return parseDate(p.birthDate).year + p.lifeExpectancy;
}

/// 「主人公：本人　期間：2026〜2080年」
class PlanPeriodText extends ConsumerWidget {
  const PlanPeriodText({super.key, required this.plan, this.style});

  final PlanRow plan;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider(plan.id)).value ?? const [];
    final p = protagonistOf(plan, members);
    final end = planEndYear(plan, members);
    return Text(
      '主人公：${p?.name ?? '—'}　期間：${plan.startYear}〜${end ?? '—'}年',
      style: style,
    );
  }
}
