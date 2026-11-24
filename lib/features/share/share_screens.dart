import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/providers.dart';
import '../../core/platform.dart';
import '../../data/db/database.dart';
import '../../data/repositories/device_pref_repository.dart';
import '../../data/share/plan_share.dart';
import '../../data/share/share_link.dart';
import '../shared/qr_scan_page.dart';
import '../shared/widgets.dart';

/// 共有サーバーの URL。Web 版は開いているサーバー、それ以外はこの端末の設定（設計書 3.12）。
Future<Uri?> currentShareServer(WidgetRef ref) async {
  if (AppPlatform.isWeb) return ShareLink.normalizeServer(Uri.base);
  final v = await ref
      .read(devicePrefRepositoryProvider)
      .get(DevicePrefRepository.shareServer);
  if (v == null || v.isEmpty) return null;
  return ShareLink.normalizeServer(Uri.parse(v));
}

/// 共有サーバーの URL を入れてもらい、保存する。キャンセルなら null。
Future<Uri?> askShareServer(BuildContext context, WidgetRef ref) async {
  final current = await ref
      .read(devicePrefRepositoryProvider)
      .get(DevicePrefRepository.shareServer);
  if (!context.mounted) return null;
  final c = TextEditingController(text: current ?? 'http://');
  final value = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('共有サーバー'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Web版を置いているサーバーのURLです（例：http://192.168.1.10:8080/）。'),
          const SizedBox(height: 8),
          TextField(
            key: const Key('share-server-field'),
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('share-server-save'),
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  c.dispose();
  if (value == null) return null;
  final u = Uri.tryParse(value);
  if (u == null ||
      !(u.scheme == 'http' || u.scheme == 'https') ||
      u.host.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('http:// か https:// で始まるURLを入れてください')),
      );
    }
    return null;
  }
  final server = ShareLink.normalizeServer(u);
  await ref
      .read(devicePrefRepositoryProvider)
      .set(DevicePrefRepository.shareServer, server.toString());
  return server;
}

/// ライフプランを暗号化して共有サーバーに置き、受け取り用の QR を出す（プランのカードのメニュー）。
Future<void> sharePlanByQr(
  BuildContext context,
  WidgetRef ref,
  PlanRow plan,
) async {
  var server = await currentShareServer(ref);
  if (server == null) {
    if (!context.mounted) return;
    server = await askShareServer(context, ref);
    if (server == null) return;
  }
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('「${plan.name}」をQRで共有'),
      content: Text(
        'このプランを暗号化して共有サーバー（$server）に24時間置き、受け取り用のQRコードを出します。'
        '受け取った端末では、同じプランがあれば上書きし、なければ新しく作ります。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('share-start'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('共有する'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final db = ref.read(databaseProvider);
  final client = ref.read(shareClientProvider);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  ShareLink? link;
  String? error;
  try {
    final share = await buildPlanShare(db, plan.id);
    link = await client.upload(server, share.toBytes());
  } on ShareException catch (e) {
    error = e.message;
  } catch (e) {
    error = '共有できませんでした（$e）';
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  if (link == null) {
    messenger.showSnackBar(SnackBar(content: Text(error ?? '共有できませんでした')));
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => ShareQrDialog(planName: plan.name, link: link!),
  );
}

/// 受け取り用の QR と URL。
class ShareQrDialog extends StatelessWidget {
  const ShareQrDialog({super.key, required this.planName, required this.link});

  final String planName;
  final ShareLink link;

  @override
  Widget build(BuildContext context) {
    final url = link.url.toString();
    return AlertDialog(
      title: Text('「$planName」を受け取るQRコード'),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  key: const Key('share-qr'),
                  data: url,
                  size: 240,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                url,
                key: const Key('share-url'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '受け取る端末で、ホームの「QR・URLで受け取る」から読み取るか、このURLをブラウザで開きます。'
                '24時間で消えます。URLを知っている人は誰でも受け取れるので、家族以外に渡さないでください。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('URLをコピーしました')));
            }
          },
          child: const Text('URLをコピー'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

/// 「QR・URLで受け取る」（ホームのライフプラン一覧・はじめに）。
class ShareReceiveButton extends StatelessWidget {
  const ShareReceiveButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const Key('share-receive'),
    onPressed: () => _receive(context),
    icon: const Icon(Icons.qr_code_scanner),
    label: const Text('QR・URLで受け取る'),
  );

  Future<void> _receive(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ReceiveDialog(),
    );
    if (text == null || !context.mounted) return;
    final link = ShareLink.parse(text);
    if (link == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('共有のURLではありません')));
      return;
    }
    context.push('/share/${link.id}', extra: link);
  }
}

class _ReceiveDialog extends StatefulWidget {
  const _ReceiveDialog();

  @override
  State<_ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends State<_ReceiveDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ライフプランを受け取る'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (AppPlatform.canScanQr) ...[
          OutlinedButton.icon(
            key: const Key('share-scan'),
            onPressed: () async {
              final v = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => const QrScanPage(title: '共有のQRコードを読み取る'),
                ),
              );
              if (v != null && context.mounted) Navigator.pop(context, v);
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('QRコードを読み取る'),
          ),
          const SizedBox(height: 12),
          const Text('または、共有のURLを貼り付けます。'),
        ] else
          const Text('共有のURLを貼り付けます。'),
        TextField(
          key: const Key('share-url-field'),
          controller: _c,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'URL'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('キャンセル'),
      ),
      FilledButton(
        key: const Key('share-url-ok'),
        onPressed: () => Navigator.pop(context, _c.text),
        child: const Text('受け取る'),
      ),
    ],
  );
}

/// 共有を受け取り、確認してから取り込む（設計書 3.12）。
class ShareReceiveScreen extends ConsumerStatefulWidget {
  const ShareReceiveScreen({super.key, required this.link});

  /// null なら URL が正しくない
  final ShareLink? link;

  @override
  ConsumerState<ShareReceiveScreen> createState() => _ShareReceiveScreenState();
}

class _ShareReceiveScreenState extends ConsumerState<ShareReceiveScreen> {
  PlanShare? _share;
  String? _error;
  PlanRow? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final link = widget.link;
    if (link == null) {
      setState(() => _error = '共有のURLが正しくありません');
      return;
    }
    try {
      final bytes = await ref.read(shareClientProvider).download(link);
      final share = PlanShare.fromBytes(bytes);
      final db = ref.read(databaseProvider);
      final existing =
          await (db.select(
                db.plans,
              )..where((p) => p.id.equals(share.planId) & p.deletedAt.isNull()))
              .getSingleOrNull();
      if (!mounted) return;
      setState(() {
        _share = share;
        _existing = existing;
      });
    } on ShareException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '受け取れませんでした（$e）');
    }
  }

  Future<void> _apply() async {
    final share = _share;
    if (share == null || _saving) return;
    setState(() => _saving = true);
    try {
      final r = await applyPlanShare(
        ref.read(databaseProvider),
        ref.read(stampProvider),
        share,
      );
      await ref.read(deviceRepositoryProvider).setSelectedPlan(share.planId);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.go('/home');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            r.overwritten
                ? '「${share.planName}」を上書きしました'
                      '${r.removed > 0 ? '（共有になかった${r.removed}件を削除）' : ''}'
                : '「${share.planName}」を取り込みました',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e is FormatException ? e.message : '取り込めませんでした（$e）';
        });
      }
    }
  }

  /// URL を直接開いたとき（Web 版）は戻る先がないので、ホームへ行く。
  void _leave() => context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context) {
    final share = _share;
    final existing = _existing;
    return Scaffold(
      appBar: AppBar(title: const Text('ライフプランを受け取る')),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: WarningBox(
                message: _error!,
                actions: [
                  TextButton(onPressed: _leave, child: const Text('戻る')),
                ],
              ),
            )
          : share == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  share.planName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('共有した日時：${_local(share.exportedAt)}'),
                const SizedBox(height: 12),
                Text(
                  [
                    '家族${share.count('family_member')}人',
                    'イベント${share.count('plan_event')}件',
                    '予定${share.count('plan_line')}件',
                    '実績${share.count('txn')}件',
                    '資産${share.count('asset')}件',
                    'グループ${share.count('template_group')}件',
                  ].join('・'),
                ),
                const SizedBox(height: 16),
                if (existing != null)
                  WarningBox(
                    message:
                        'この端末の「${existing.name}」（同じプラン）を上書きします。'
                        'このプランの家族・予定・実績・資産などは共有の内容に置き換わり、'
                        '共有にないものは削除されます。カテゴリ・口座・テンプレート・グループは追加・更新だけで、削除しません。',
                  )
                else
                  const Text(
                    '新しいプランとして取り込みます。カテゴリ・口座・テンプレート・グループは追加・更新だけで、削除しません。',
                  ),
              ],
            ),
      bottomNavigationBar: share == null || _error != null
          ? null
          : SaveCancelBar(
              saveKey: const Key('share-apply'),
              saveLabel: existing != null ? '上書きする' : '取り込む',
              onSave: _saving ? null : _apply,
              onCancel: _leave,
            ),
    );
  }

  static String _local(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}/${t.month}/${t.day} ${two(t.hour)}:${two(t.minute)}';
  }
}
