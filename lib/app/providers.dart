import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/stamp.dart';

/// アプリ起動時（main）に開いた DB で上書きする。
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider は main で上書きする'),
);

/// アプリ起動時に確定した端末ID で上書きする。
final deviceIdProvider = Provider<String>(
  (ref) => throw UnimplementedError('deviceIdProvider は main で上書きする'),
);

final stampProvider = Provider<Stamp>(
  (ref) => Stamp(ref.watch(deviceIdProvider)),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepository(ref.watch(databaseProvider)),
);

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) =>
      PlanRepository(ref.watch(databaseProvider), ref.watch(stampProvider)),
);

final deviceSettingProvider = StreamProvider<DeviceSettingRow>(
  (ref) => ref.watch(deviceRepositoryProvider).watch(),
);

final plansProvider = StreamProvider<List<PlanRow>>(
  (ref) => ref.watch(planRepositoryProvider).watchPlans(),
);

/// 表示プラン（設計書 2. 用語）。
///
/// 端末に記憶した selected_plan_id のプランを返す。未選択か削除済みなら先頭のプラン。
/// プランが1つもなければ null。
final selectedPlanProvider = Provider<AsyncValue<PlanRow?>>((ref) {
  final plans = ref.watch(plansProvider);
  final setting = ref.watch(deviceSettingProvider);
  if (plans.isLoading || setting.isLoading) return const AsyncLoading();
  if (plans.hasError) return AsyncError(plans.error!, plans.stackTrace!);
  final list = plans.value ?? const <PlanRow>[];
  if (list.isEmpty) return const AsyncData(null);
  final id = setting.value?.selectedPlanId;
  final found = list.where((p) => p.id == id).firstOrNull;
  return AsyncData(found ?? list.first);
});

final membersProvider = StreamProvider.family<List<FamilyMemberRow>, String>(
  (ref, planId) => ref.watch(planRepositoryProvider).watchMembers(planId),
);
