import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/plan/plan_create_screen.dart';
import '../features/plan/plan_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shared/placeholder.dart';
import '../features/shared/plan_tab_placeholder.dart';
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
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('同期')),
              body: const NotYetImplemented(feature: '同期', milestone: 'M9'),
            ),
          ),
        ],
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
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ledger',
                builder: (context, state) =>
                    const PlanTabPlaceholder(title: '家計簿', milestone: 'M3'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assets',
                builder: (context, state) =>
                    const PlanTabPlaceholder(title: '資産', milestone: 'M5'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) =>
                    const PlanTabPlaceholder(title: 'イベント', milestone: 'M6'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
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
