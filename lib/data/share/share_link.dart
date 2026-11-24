import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../sync/sync_crypto.dart';

/// 共有の受け取り用 URL（設計書 3.12）：`{サーバー}/#/share/{ID}?k={鍵}`。
///
/// 鍵は URL の # 以降に入れる（# 以降はサーバーに送られない）。
class ShareLink {
  const ShareLink({required this.server, required this.id, required this.key});

  /// サーバーの URL（末尾は /）
  final Uri server;
  final String id;

  /// AES-256 の鍵（32バイト）
  final List<int> key;

  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{16,64}$');

  Uri get url => server.replace(
    fragment: '/share/$id?k=${base64Url.encode(key).replaceAll('=', '')}',
  );

  Uri get apiUrl => server.resolve('api/share/$id');

  /// 共有の URL を読む。読めなければ null。
  static ShareLink? parse(String text) {
    final u = Uri.tryParse(text.trim());
    if (u == null || !u.hasScheme || u.host.isEmpty) return null;
    final f = Uri.tryParse(u.fragment);
    if (f == null) return null;
    final seg = f.pathSegments;
    if (seg.length != 2 || seg[0] != 'share') return null;
    return fromParts(
      server: u.replace(fragment: ''),
      id: seg[1],
      key: f.queryParameters['k'],
    );
  }

  /// ルートの ID と鍵から作る（Web 版で URL を開いたとき）。
  static ShareLink? fromParts({
    required Uri server,
    required String id,
    required String? key,
  }) {
    if (!_idPattern.hasMatch(id) || key == null) return null;
    final List<int> k;
    try {
      k = base64Url.decode(base64Url.normalize(key));
    } catch (_) {
      return null;
    }
    if (k.length != 32) return null;
    return ShareLink(server: normalizeServer(server), id: id, key: k);
  }

  /// サーバーの URL をそろえる（# と ? を外し、末尾を / にする）。
  static Uri normalizeServer(Uri u) {
    var path = u.path;
    if (!path.endsWith('/')) path = '$path/';
    return Uri(
      scheme: u.scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: path,
    );
  }
}

/// 共有のサーバーとのやり取りに失敗した。
class ShareException implements Exception {
  const ShareException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// サーバーに暗号化して置く・受け取って復号する。
class ShareClient {
  ShareClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static List<int> newKey() {
    final r = Random.secure();
    return [for (var i = 0; i < 32; i++) r.nextInt(256)];
  }

  /// [plain] を暗号化してサーバーに置き、受け取り用のリンクを返す。
  Future<ShareLink> upload(Uri server, List<int> plain) async {
    final base = ShareLink.normalizeServer(server);
    final key = newKey();
    final body = await SyncCrypto.encrypt(plain, key);
    final http.Response res;
    try {
      res = await _client
          .post(
            base.resolve('api/share'),
            headers: {'content-type': 'application/octet-stream'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw ShareException('共有サーバーにつながりません（$e）');
    }
    if (res.statusCode == 413) {
      throw const ShareException('データが大きすぎて置けませんでした');
    }
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw ShareException('共有サーバーに置けませんでした（${res.statusCode}）');
    }
    final id = (jsonDecode(res.body) as Map<String, dynamic>)['id'] as String;
    return ShareLink(server: base, id: id, key: key);
  }

  /// 受け取って復号する。
  Future<List<int>> download(ShareLink link) async {
    final http.Response res;
    try {
      res = await _client.get(link.apiUrl).timeout(const Duration(seconds: 60));
    } catch (e) {
      throw ShareException('共有サーバーにつながりません（$e）');
    }
    if (res.statusCode == 404) {
      throw const ShareException('共有が見つかりません（24時間を過ぎて消えたか、URLが違います）');
    }
    if (res.statusCode != 200) {
      throw ShareException('受け取れませんでした（${res.statusCode}）');
    }
    try {
      return await SyncCrypto.decrypt(res.bodyBytes, link.key);
    } catch (_) {
      throw const ShareException('復号できませんでした（URLの鍵が違います）');
    }
  }
}
