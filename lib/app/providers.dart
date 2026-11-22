import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time.dart';
import '../data/db/database.dart';
import '../data/repositories/asset_repository.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/master_repository.dart';
import '../data/repositories/plan_line_repository.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/rate_family_repository.dart';
import '../data/repositories/stamp.dart';
import '../data/repositories/template_repository.dart';
import '../data/repositories/txn_repository.dart';

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

final masterRepositoryProvider = Provider<MasterRepository>(
  (ref) =>
      MasterRepository(ref.watch(databaseProvider), ref.watch(stampProvider)),
);

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) =>
      TemplateRepository(ref.watch(databaseProvider), ref.watch(stampProvider)),
);

final categoriesProvider = StreamProvider<List<CategoryRow>>(
  (ref) => ref.watch(masterRepositoryProvider).watchCategories(),
);

final accountsProvider = StreamProvider<List<AccountRow>>(
  (ref) => ref.watch(masterRepositoryProvider).watchAccounts(),
);

final templatesProvider = StreamProvider<List<TemplateRow>>(
  (ref) => ref.watch(templateRepositoryProvider).watchTemplates(),
);

final templateGroupCountsProvider = StreamProvider<Map<String, int>>(
  (ref) => ref.watch(templateRepositoryProvider).watchTemplateGroupCounts(),
);

final groupSummariesProvider = StreamProvider<List<GroupSummary>>(
  (ref) => ref.watch(templateRepositoryProvider).watchGroupSummaries(),
);

final groupsUsingTemplateProvider =
    StreamProvider.family<List<TemplateGroupRow>, String>(
      (ref, templateId) => ref
          .watch(templateRepositoryProvider)
          .watchGroupsUsingTemplate(templateId),
    );

final txnRepositoryProvider = Provider<TxnRepository>(
  (ref) => TxnRepository(ref.watch(databaseProvider), ref.watch(stampProvider)),
);

/// 期間を指定したプランの実績。
typedef TxnQuery = ({String planId, String? from, String? to});

final txnsProvider = StreamProvider.family<List<TxnRow>, TxnQuery>(
  (ref, q) => ref
      .watch(txnRepositoryProvider)
      .watchTxns(q.planId, from: q.from, to: q.to),
);

final planLineRepositoryProvider = Provider<PlanLineRepository>(
  (ref) =>
      PlanLineRepository(ref.watch(databaseProvider), ref.watch(stampProvider)),
);

final rateFamilyRepositoryProvider = Provider<RateFamilyRepository>(
  (ref) => RateFamilyRepository(
    ref.watch(databaseProvider),
    ref.watch(stampProvider),
  ),
);

/// 年月の範囲を指定したプランの計画行。
typedef LineQuery = ({String planId, YearMonth? from, YearMonth? to});

final planLinesProvider = StreamProvider.family<List<PlanLineRow>, LineQuery>(
  (ref, q) => ref
      .watch(planLineRepositoryProvider)
      .watchLines(q.planId, from: q.from, to: q.to),
);

final registrationsProvider =
    StreamProvider.family<List<RegistrationSummary>, String>(
      (ref, planId) =>
          ref.watch(planLineRepositoryProvider).watchRegistrations(planId),
    );

final ratesProvider = StreamProvider.family<List<PlanRateRow>, String>(
  (ref, planId) => ref.watch(rateFamilyRepositoryProvider).watchRates(planId),
);

final assetRepositoryProvider = Provider<AssetRepository>(
  (ref) =>
      AssetRepository(ref.watch(databaseProvider), ref.watch(stampProvider)),
);

final assetsProvider = StreamProvider.family<List<AssetRow>, String>(
  (ref, planId) => ref.watch(assetRepositoryProvider).watchAssets(planId),
);

final assetValuesProvider = StreamProvider.family<List<AssetValueRow>, String>(
  (ref, assetId) => ref.watch(assetRepositoryProvider).watchValues(assetId),
);

final planAssetValuesProvider =
    StreamProvider.family<List<AssetValueRow>, String>(
      (ref, planId) =>
          ref.watch(assetRepositoryProvider).watchPlanValues(planId),
    );

final assetTxnsProvider = StreamProvider.family<List<TxnRow>, String>(
  (ref, assetId) => ref.watch(assetRepositoryProvider).watchAssetTxns(assetId),
);

final planAssetTxnsProvider = StreamProvider.family<List<TxnRow>, String>(
  (ref, planId) =>
      ref.watch(assetRepositoryProvider).watchPlanAssetTxns(planId),
);

final assetPlanLinesProvider = StreamProvider.family<List<PlanLineRow>, String>(
  (ref, assetId) =>
      ref.watch(assetRepositoryProvider).watchAssetPlanLines(assetId),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) =>
      EventRepository(ref.watch(databaseProvider), ref.watch(stampProvider)),
);

final eventsProvider = StreamProvider.family<List<PlanEventRow>, String>(
  (ref, planId) => ref.watch(eventRepositoryProvider).watchEvents(planId),
);

final eventLinesProvider = StreamProvider.family<List<PlanLineRow>, String>(
  (ref, planId) => ref.watch(eventRepositoryProvider).watchEventLines(planId),
);

final eventTxnsProvider = StreamProvider.family<List<TxnRow>, String>(
  (ref, planId) => ref.watch(eventRepositoryProvider).watchEventTxns(planId),
);
