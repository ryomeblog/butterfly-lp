import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/providers.dart';
import '../../core/platform.dart';
import '../../data/sync/resp_client.dart';
import '../../data/sync/sync_service.dart';
import '../shared/qr_scan_page.dart';
import '../shared/widgets.dart';

/// 秘密の値の置き場所（main で端末のセキュアストレージに上書きする。テストはメモリ）。
final secretStoreProvider = Provider<SecretStore>((ref) => MemorySecretStore());

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.watch(databaseProvider),
    ref.watch(secretStoreProvider),
    ref.watch(deviceIdProvider),
  ),
);

/// 前回の同期の結果（この起動の間だけ持つ）。
class LastSyncResult extends Notifier<SyncResult?> {
  @override
  SyncResult? build() => null;

  void set(SyncResult r) => state = r;
}

final lastSyncResultProvider = NotifierProvider<LastSyncResult, SyncResult?>(
  LastSyncResult.new,
);

/// 「2026-11-11T12:30:00.000Z」→ 端末の時刻で「2026/11/11 21:30」
String formatSyncTime(String? ts) {
  if (ts == null) return '—';
  final t = DateTime.parse(ts).toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}/${t.month}/${t.day} ${two(t.hour)}:${two(t.minute)}';
}

/// 同期（ワイヤーフレーム Sync）。設計書 5。
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '6379');
  final _password = TextEditingController();
  final _passphrase = TextEditingController();
  bool _hasPassphrase = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ref.read(deviceRepositoryProvider).ensure();
    final svc = ref.read(syncServiceProvider);
    _host.text = s.redisHost ?? '';
    if (s.redisPort != null) _port.text = '${s.redisPort}';
    _password.text = await svc.redisPassword() ?? '';
    final p = await svc.passphrase();
    if (mounted) setState(() => _hasPassphrase = p != null);
  }

  @override
  void dispose() {
    for (final c in [_host, _port, _password, _passphrase]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _saveConnection() async {
    final port = int.tryParse(_port.text);
    if (_host.text.trim().isEmpty || port == null) {
      _snack('アドレスとポートを入れてください');
      return;
    }
    await ref
        .read(syncServiceProvider)
        .setConnection(
          host: _host.text.trim(),
          port: port,
          password: _password.text,
        );
    _snack('接続先を保存しました');
  }

  Future<void> _registerPassphrase(String value) async {
    final v = value.trim();
    if (v.length < 8) {
      _snack('合言葉は8文字以上にしてください');
      return;
    }
    setState(() => _busy = true);
    await ref.read(syncServiceProvider).setPassphrase(v);
    _passphrase.clear();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _hasPassphrase = true;
    });
    _snack('合言葉を登録しました');
  }

  Future<void> _sync() async {
    await _saveConnection();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(syncServiceProvider).sync();
      ref.read(lastSyncResultProvider.notifier).set(r);
    } on SyncNotConfigured catch (e) {
      _error = e.message;
    } on RedisError catch (e) {
      _error = 'Redis のエラー：${e.message}（パスワードを確かめてください）';
    } catch (e) {
      _error = '自宅のRedisにつながりません。自宅Wi-Fiに接続しているか、アドレスとポートを確かめてください（$e）';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _showQr() async {
    final p = await ref.read(syncServiceProvider).passphrase();
    if (p == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('合言葉のQRコード'),
        content: SizedBox(
          width: 240,
          height: 240,
          child: QrImageView(data: p, backgroundColor: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScanPage(title: '合言葉のQRコードを読み取る'),
      ),
    );
    if (code != null) await _registerPassphrase(code);
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(deviceSettingProvider).value;
    final r = ref.watch(lastSyncResultProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('同期')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            key: const Key('sync-now'),
            onPressed: _busy ? null : _sync,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: const Text('今すぐ同期'),
          ),
          const SizedBox(height: 8),
          Text(
            '自宅Wi-Fi内でだけ同期できます。他の端末のデータを取り込み、更新日時が新しい方を採用してから、'
            'この端末の全データを書き込みます（キャッシュは1日で消えます）。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            WarningBox(key: const Key('sync-error'), message: _error!),
          ],
          const SectionTitle('前回の結果'),
          Text('日時　${formatSyncTime(r?.at ?? setting?.lastSyncAt)}'),
          if (r != null) ...[
            Text('取り込んだ端末　${r.devices}台', key: const Key('sync-devices')),
            Text('取り込んだ件数　${r.adopted}件'),
            Text('参照切れ　${r.broken}件'),
            if (r.broken > 0)
              Text(
                '参照切れの行は「削除済み○○」と表示します。編集するときに付け替えてください。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (r.undecryptable > 0)
              Text('合言葉が違うため読めなかったデータ　${r.undecryptable}件'),
            if (r.newerSchema > 0)
              WarningBox(
                message:
                    '新しい版のアプリで書かれたデータが${r.newerSchema}台分あり、取り込みませんでした。アプリを更新してください。',
              ),
          ],
          const SectionTitle('接続先（自宅Redis）'),
          TextField(
            key: const Key('sync-host'),
            controller: _host,
            decoration: const InputDecoration(
              labelText: 'アドレス',
              hintText: '192.168.0.10',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('sync-port'),
            controller: _port,
            decoration: const InputDecoration(labelText: 'ポート'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('sync-password'),
            controller: _password,
            decoration: const InputDecoration(labelText: 'パスワード'),
            obscureText: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saveConnection,
              child: const Text('接続先を保存'),
            ),
          ),
          const SectionTitle('合言葉（家族で共通）'),
          Text(
            _hasPassphrase ? '登録済み' : '未登録',
            key: const Key('sync-passphrase-state'),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('sync-passphrase'),
            controller: _passphrase,
            decoration: InputDecoration(
              labelText: _hasPassphrase ? '新しい合言葉' : '合言葉（8文字以上）',
            ),
            obscureText: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('sync-passphrase-save'),
              onPressed: _busy
                  ? null
                  : () => _registerPassphrase(_passphrase.text),
              child: const Text('合言葉を登録'),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _hasPassphrase ? _showQr : null,
                icon: const Icon(Icons.qr_code),
                label: const Text('QRコードを表示'),
              ),
              if (AppPlatform.canScanQr)
                OutlinedButton.icon(
                  onPressed: _scanQr,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('QRコードを読み取る'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '合言葉を変えるときは、家族の全端末で新しい合言葉を登録し直します。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 32),
          Text(
            'この端末のID：${ref.watch(deviceIdProvider)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
