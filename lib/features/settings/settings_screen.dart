import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/platform.dart';
import 'sync_screen.dart';

/// 設定（ワイヤーフレーム Settings）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceId = ref.watch(deviceIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _Header('家計簿'),
          ListTile(
            title: const Text('カテゴリ・口座'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/masters'),
          ),
          const _Header('データ'),
          // Web 版はブラウザから Redis につなげないので同期を持たない（設計書 3.12）
          if (AppPlatform.canSync)
            ListTile(
              title: const Text('同期'),
              subtitle: Text(
                '最終同期 ${formatSyncTime(ref.watch(deviceSettingProvider).value?.lastSyncAt)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/sync'),
            ),
          ListTile(
            title: const Text('データ管理'),
            subtitle: const Text('バックアップ・全データのJSON・CSV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/data'),
          ),
          const Divider(),
          ListTile(
            title: const Text('この端末のID'),
            subtitle: SelectableText(deviceId),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
