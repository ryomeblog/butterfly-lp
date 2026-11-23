import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/enums.dart';
import '../features/assets/account_detail_screen.dart';
import '../features/assets/asset_detail_screen.dart';
import '../features/assets/asset_edit_screen.dart';
import '../features/assets/asset_flow_screen.dart';
import '../features/assets/assets_screen.dart';
import '../features/ledger/ledger_screen.dart';
import '../features/ledger/txn_edit_screen.dart';
import '../features/compare/compare_screens.dart';
import '../features/compare/planned_entry_screen.dart';
import '../features/data/data_mgmt_screen.dart';
import '../features/data/json_import_screen.dart';
import '../features/events/event_actual_screen.dart';
import '../features/events/event_edit_screen.dart';
import '../features/events/events_screen.dart';
import '../features/groups/group_edit_screen.dart';
import '../features/groups/group_entry_screen.dart';
import '../features/home/home_screen.dart';
import '../features/masters/account_edit_screen.dart';
import '../features/masters/category_edit_screen.dart';
import '../features/masters/masters_screen.dart';
import '../features/templates/register_from_txns_screen.dart';
import '../features/templates/template_edit_screen.dart';
import '../features/plan/plan_create_screen.dart';
import '../features/plan/family_screen.dart';
import '../features/plan/group_register_screen.dart';
import '../features/plan/plan_detail_screen.dart';
import '../features/plan/plan_groups_screen.dart';
import '../features/plan/plan_year_screen.dart';
import '../features/plan/rates_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/sync_screen.dart';
import 'providers.dart';

/// 画面の移動。下部5タブ（ホーム／家計簿／資産／イベント／設定）ごとに履歴を持つ（設計書 7・11）。
///
/// プランが1つもないときは、最初のプランを作る画面（/welcome）へ移す（設計書 7.1）。
final routerProvider = Provider<GoRouter>((ref) {
  final hasPlans = ValueNotifier<bool?>(null);
  ref.listen(plansProvider, (_, next) {
    if (next.hasValue) hasPlans.value = next.value!.isNotEmpty;
  }, fireImmediately: true);
  ref.onDispose(hasPlans.dispose);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: hasPlans,
    redirect: (context, state) {
      final has = hasPlans.value;
      if (has == null) return null;
      final onWelcome = state.matchedLocation.startsWith('/welcome');
      if (!has && !onWelcome) return '/welcome';
      if (has && onWelcome) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const PlanCreateScreen(isFirst: true),
        routes: [
          GoRoute(
            path: 'sync',
            builder: (context, state) => const SyncScreen(),
          ),
        ],
      ),
      // 実績の入力・編集。家計簿・資産・口座詳細から開くので、タブの外に置く。
      GoRoute(
        path: '/entry/txn/:id',
        builder: (context, state) => TxnEditScreen(
          txnId: _idOrNull(state.pathParameters['id']),
          initialDate: state.uri.queryParameters['date'],
          fromLineId: state.uri.queryParameters['fromLine'],
        ),
      ),
      // 年別・年間・資産の予実（表示プランについて。家計簿の比較とプラン詳細から開く）
      GoRoute(
        path: '/compare/years',
        builder: (context, state) => const YearsCompareScreen(),
      ),
      GoRoute(
        path: '/compare/year/:year',
        builder: (context, state) =>
            YearlyCompareScreen(year: int.parse(state.pathParameters['year']!)),
      ),
      GoRoute(
        path: '/compare/assets',
        builder: (context, state) => const AssetCompareScreen(),
      ),
      // JSONの取り込みの確認（データ管理・家計簿のリスト・資産一覧から開く）
      GoRoute(
        path: '/entry/json-import',
        builder: (context, state) {
          final x = state.extra! as ({String name, Map<String, dynamic> json});
          return JsonImportScreen(fileName: x.name, json: x.json);
        },
      ),
      // 家計簿のリストで選んだ実績からテンプレート・グループを作る
      GoRoute(
        path: '/entry/register-from-txns',
        builder: (context, state) {
          final x = state.extra! as ({List<String> txnIds, bool asGroup});
          return RegisterFromTxnsScreen(txnIds: x.txnIds, asGroup: x.asGroup);
        },
      ),
      // 予定から実績入力・グループから実績入力（家計簿・ホームから開く）
      GoRoute(
        path: '/entry/planned',
        builder: (context, state) => PlannedEntryScreen(
          year: int.tryParse(state.uri.queryParameters['year'] ?? ''),
          month: int.tryParse(state.uri.queryParameters['month'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/entry/group',
        builder: (context, state) => GroupEntryScreen(
          groupId: state.uri.queryParameters['group'],
          ym: state.uri.queryParameters['ym'],
        ),
      ),
      // 資産の購入・売却・収益と費用。
      GoRoute(
        path: '/entry/asset/:kind',
        builder: (context, state) => AssetFlowScreen(
          kind: AssetFlowKind.values.byName(state.pathParameters['kind']!),
          assetId: state.uri.queryParameters['asset'],
          startAsPlan: state.uri.queryParameters['plan'] == '1',
        ),
      ),
      // 予定の入力・編集。ホーム（計画）からも家計簿からも開くので、タブの外に置く。
      GoRoute(
        path: '/entry/plan-line/:id',
        builder: (context, state) {
          final id = _idOrNull(state.pathParameters['id']);
          return TxnEditScreen(
            planLineId: id,
            initialYm: state.uri.queryParameters['ym'],
            startAsPlan: true,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _TabShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'plan-new',
                    builder: (context, state) =>
                        const PlanCreateScreen(isFirst: false),
                  ),
                  GoRoute(
                    path: 'plan/:id',
                    builder: (context, state) =>
                        PlanDetailScreen(planId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'year',
                        builder: (context, state) =>
                            PlanYearScreen(planId: state.pathParameters['id']!),
                      ),
                      GoRoute(
                        path: 'family',
                        builder: (context, state) =>
                            FamilyScreen(planId: state.pathParameters['id']!),
                      ),
                      GoRoute(
                        path: 'rates',
                        builder: (context, state) =>
                            RatesScreen(planId: state.pathParameters['id']!),
                      ),
                      GoRoute(
                        path: 'groups',
                        builder: (context, state) => PlanGroupsScreen(
                          planId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'register',
                        builder: (context, state) => GroupRegisterScreen(
                          planId: state.pathParameters['id']!,
                          groupId: state.uri.queryParameters['group'],
                        ),
                      ),
                    ],
                  ),
                  ..._categoryRoutes(),
                  GoRoute(
                    path: 'template/:id',
                    builder: (context, state) => TemplateEditScreen(
                      templateId: _idOrNull(state.pathParameters['id']),
                    ),
                  ),
                  GoRoute(
                    path: 'group/:id',
                    builder: (context, state) => GroupEditScreen(
                      groupId: _idOrNull(state.pathParameters['id']),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ledger',
                builder: (context, state) => const LedgerScreen(),
                routes: [
                  GoRoute(
                    path: 'txn/:id',
                    builder: (context, state) => TxnEditScreen(
                      txnId: _idOrNull(state.pathParameters['id']),
                      initialDate: state.uri.queryParameters['date'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assets',
                builder: (context, state) => const AssetsScreen(),
                routes: [
                  GoRoute(
                    path: 'account/:id',
                    builder: (context, state) => AccountDetailScreen(
                      accountId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'account-edit/:id',
                    builder: (context, state) => AccountEditScreen(
                      accountId: _idOrNull(state.pathParameters['id']),
                    ),
                  ),
                  GoRoute(
                    path: 'asset-edit/:id',
                    builder: (context, state) => AssetEditScreen(
                      assetId: _idOrNull(state.pathParameters['id']),
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) =>
                        AssetDetailScreen(assetId: state.pathParameters['id']!),
                  ),
                  ..._categoryRoutes(),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) =>
                        EventDetailScreen(eventId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => EventEditScreen(
                      eventId: _idOrNull(state.pathParameters['id']),
                    ),
                  ),
                  GoRoute(
                    path: 'actual/:id',
                    builder: (context, state) =>
                        EventActualScreen(eventId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'sync',
                    builder: (context, state) => const SyncScreen(),
                  ),
                  GoRoute(
                    path: 'data',
                    builder: (context, state) => const DataMgmtScreen(),
                  ),
                  GoRoute(
                    path: 'masters',
                    builder: (context, state) => const MastersScreen(),
                    routes: [
                      ..._categoryRoutes(),
                      GoRoute(
                        path: 'account/:id',
                        builder: (context, state) => AccountEditScreen(
                          accountId: _idOrNull(state.pathParameters['id']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// `new` は新規作成。
String? _idOrNull(String? id) => id == 'new' ? null : id;

/// カテゴリの追加・編集。ホームのカテゴリタブと設定の両方から開く。
List<GoRoute> _categoryRoutes() => [
  GoRoute(
    path: 'category/:id',
    builder: (context, state) {
      final kind = state.uri.queryParameters['kind'];
      return CategoryEditScreen(
        categoryId: _idOrNull(state.pathParameters['id']),
        initialKind: kind == null ? null : CategoryKind.of(kind),
      );
    },
  ),
];

class _TabShell extends StatelessWidget {
  const _TabShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'ホーム'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: '家計簿',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: '資産',
          ),
          NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'イベント'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
