import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// サーバーの設定。
class ServerConfig {
  const ServerConfig({
    required this.dataDir,
    this.webDir,
    this.ttl = const Duration(hours: 24),
    this.maxBytes = 20 * 1024 * 1024,
    this.maxItems = 1000,
  });

  /// 共有の暗号文を置くフォルダ
  final String dataDir;

  /// Web 版（flutter build web の出力）。null なら配信しない
  final String? webDir;

  /// 共有を預かる時間（設計書 3.12：24時間）
  final Duration ttl;

  /// 1件の上限
  final int maxBytes;

  /// 預かる件数の上限（インターネットに公開したときに埋め尽くされないように）
  final int maxItems;
}

/// Web 版の配信と、共有の受け渡しだけを行うサーバー（設計書 3.12）。
///
/// - `POST /api/share`：本文（暗号文）を預かり `{"id": "..."}` を返す
/// - `GET /api/share/{id}`：預かった本文を返す。期限を過ぎたものは 404
/// - それ以外：Web 版のファイル（見つからなければ index.html）
///
/// サーバーには暗号文しか届かない（鍵は URL の # 以降で、ブラウザはサーバーに送らない）。
class ShareServer {
  ShareServer(this.config, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ServerConfig config;
  final DateTime Function() _now;
  final _random = Random.secure();
  HttpServer? _server;
  Timer? _sweeper;

  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{22}$');

  Directory get _data => Directory(config.dataDir);

  Future<HttpServer> start({
    Object address = '0.0.0.0',
    int port = 8080,
  }) async {
    await _data.create(recursive: true);
    await sweep();
    final s = await HttpServer.bind(address, port);
    _server = s;
    _sweeper = Timer.periodic(const Duration(minutes: 10), (_) => sweep());
    s.listen((req) async {
      try {
        await handle(req);
      } catch (e) {
        try {
          req.response.statusCode = HttpStatus.internalServerError;
          await req.response.close();
        } catch (_) {}
      }
    });
    return s;
  }

  Future<void> stop() async {
    _sweeper?.cancel();
    await _server?.close(force: true);
  }

  String _newId() {
    final b = [for (var i = 0; i < 16; i++) _random.nextInt(256)];
    return base64Url.encode(b).replaceAll('=', '');
  }

  File _file(String id) => File('${_data.path}/$id.bin');

  /// 期限を過ぎた共有を消す。
  Future<void> sweep() async {
    if (!await _data.exists()) return;
    final limit = _now().subtract(config.ttl);
    await for (final f in _data.list()) {
      if (f is File && f.path.endsWith('.bin')) {
        if ((await f.lastModified()).isBefore(limit)) {
          await f.delete().catchError((_) => f);
        }
      }
    }
  }

  Future<void> handle(HttpRequest req) async {
    final res = req.response;
    final path = req.uri.path;
    if (path == '/api/share' || path.startsWith('/api/share/')) {
      // 別の場所に置いた Web 版やアプリからも使えるようにする
      res.headers
        ..set('access-control-allow-origin', '*')
        ..set('access-control-allow-methods', 'GET, POST, OPTIONS')
        ..set('access-control-allow-headers', 'content-type')
        ..set('cache-control', 'no-store');
      if (req.method == 'OPTIONS') {
        res.statusCode = HttpStatus.noContent;
        return res.close();
      }
      if (path == '/api/share' && req.method == 'POST') return _put(req);
      if (req.method == 'GET') {
        return _get(req, path.substring('/api/share/'.length));
      }
      res.statusCode = HttpStatus.methodNotAllowed;
      return res.close();
    }
    if (req.method != 'GET' && req.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      return res.close();
    }
    return _static(req);
  }

  Future<void> _put(HttpRequest req) async {
    final res = req.response;
    final declared = req.contentLength;
    if (declared > config.maxBytes) {
      res.statusCode = HttpStatus.requestEntityTooLarge;
      return res.close();
    }
    final body = BytesBuilder(copy: false);
    await for (final chunk in req) {
      body.add(chunk);
      if (body.length > config.maxBytes) {
        res.statusCode = HttpStatus.requestEntityTooLarge;
        return res.close();
      }
    }
    if (body.isEmpty) {
      res.statusCode = HttpStatus.badRequest;
      return res.close();
    }
    await sweep();
    final count = await _data
        .list()
        .where((f) => f.path.endsWith('.bin'))
        .length;
    if (count >= config.maxItems) {
      res.statusCode = HttpStatus.serviceUnavailable;
      return res.close();
    }
    final id = _newId();
    final f = _file(id);
    await f.writeAsBytes(body.takeBytes(), flush: true);
    await f.setLastModified(_now());
    res
      ..statusCode = HttpStatus.created
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'id': id, 'expires_in': config.ttl.inSeconds}));
    return res.close();
  }

  Future<void> _get(HttpRequest req, String id) async {
    final res = req.response;
    final f = _file(id);
    if (!_idPattern.hasMatch(id) || !await f.exists()) {
      res.statusCode = HttpStatus.notFound;
      return res.close();
    }
    if ((await f.lastModified()).isBefore(_now().subtract(config.ttl))) {
      await f.delete().catchError((_) => f);
      res.statusCode = HttpStatus.notFound;
      return res.close();
    }
    res.headers.contentType = ContentType.binary;
    res.add(await f.readAsBytes());
    return res.close();
  }

  static const _types = {
    'html': 'text/html; charset=utf-8',
    'js': 'text/javascript; charset=utf-8',
    'mjs': 'text/javascript; charset=utf-8',
    'json': 'application/json',
    'wasm': 'application/wasm',
    'css': 'text/css; charset=utf-8',
    'png': 'image/png',
    'ico': 'image/x-icon',
    'svg': 'image/svg+xml',
    'otf': 'font/otf',
    'ttf': 'font/ttf',
    'woff2': 'font/woff2',
    'bin': 'application/octet-stream',
    'frag': 'application/octet-stream',
  };

  Future<void> _static(HttpRequest req) async {
    final res = req.response;
    final web = config.webDir;
    if (web == null) {
      res.statusCode = HttpStatus.notFound;
      return res.close();
    }
    final root = Directory(web).absolute.path;
    var rel = Uri.decodeComponent(req.uri.path);
    if (rel.isEmpty || rel.endsWith('/')) rel = '${rel}index.html';
    var file = File('$root$rel');
    final resolved = file.absolute.path;
    // フォルダの外を読ませない
    if (rel.contains('..') || !resolved.startsWith(root)) {
      res.statusCode = HttpStatus.forbidden;
      return res.close();
    }
    if (!await file.exists()) file = File('$root/index.html');
    if (!await file.exists()) {
      res.statusCode = HttpStatus.notFound;
      return res.close();
    }
    final ext = file.path.split('.').last.toLowerCase();
    res.headers.set('content-type', _types[ext] ?? 'application/octet-stream');
    // Flutter の Web 版はファイル名が版で変わらないので、毎回更新を確かめさせる（変わっていなければ 304）
    final modified = (await file.lastModified()).toUtc();
    final since = req.headers.ifModifiedSince;
    res.headers
      ..set('cache-control', 'no-cache')
      ..set('last-modified', HttpDate.format(modified));
    if (since != null && modified.difference(since.toUtc()).inSeconds <= 0) {
      res.statusCode = HttpStatus.notModified;
      return res.close();
    }
    if (req.method == 'HEAD') return res.close();
    await res.addStream(file.openRead());
    return res.close();
  }
}
