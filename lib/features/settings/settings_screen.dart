import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

/// 設定（ワイヤーフレーム Settings）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceId = ref.watch(deviceIdProvider);
    void notYet(String what, String m) =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('「$what」は $m で実装します。')));
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
          ListTile(
            title: const Text('同期'),
            subtitle: const Text('最終同期 —'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => notYet('同期', 'M9'),
          ),
          ListTile(
            title: const Text('データ管理'),
            subtitle: const Text('書き出し・復元・CSV・移行'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => notYet('データ管理', 'M10'),
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
