import 'dart:convert';
import 'dart:io';

import 'package:butterfly_lp_server/share_server.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late ShareServer server;
  late Uri base;
  late HttpClient client;
  var now = DateTime(2026, 11, 24, 12);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lp_server');
    final web = Directory('${dir.path}/web')..createSync();
    File('${web.path}/index.html').writeAsStringSync('<html>app</html>');
    File('${web.path}/main.dart.js').writeAsStringSync('js');
    File('${dir.path}/secret.txt').writeAsStringSync('secret');
    now = DateTime(2026, 11, 24, 12);
    server = ShareServer(
      ServerConfig(
        dataDir: '${dir.path}/data',
        webDir: web.path,
        maxBytes: 1000,
        maxItems: 3,
      ),
      now: () => now,
    );
    final s = await server.start(
      address: InternetAddress.loopbackIPv4,
      port: 0,
    );
    base = Uri.parse('http://127.0.0.1:${s.port}/');
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.stop();
    await dir.delete(recursive: true);
  });

  Future<(int, List<int>, HttpHeaders)> req(
    String method,
    String path, [
    List<int>? body,
  ]) async {
    final r = await client.openUrl(method, base.resolve(path));
    if (body != null) r.add(body);
    final res = await r.close();
    final bytes = await res.fold<List<int>>([], (a, b) => a..addAll(b));
    return (res.statusCode, bytes, res.headers);
  }

  test('置いて受け取れる。24時間を過ぎると消える', () async {
    final (code, body, _) = await req('POST', 'api/share', [1, 2, 3]);
    expect(code, 201);
    final id = (jsonDecode(utf8.decode(body)) as Map)['id'] as String;
    expect(id, hasLength(22));
    final got = await req('GET', 'api/share/$id');
    expect(got.$1, 200);
    expect(got.$2, [1, 2, 3]);
    expect(got.$3.value('access-control-allow-origin'), '*');
    // 2回目も受け取れる（何台でも）
    expect((await req('GET', 'api/share/$id')).$1, 200);

    now = now.add(const Duration(hours: 24, minutes: 1));
    expect((await req('GET', 'api/share/$id')).$1, 404);
    expect(File('${dir.path}/data/$id.bin').existsSync(), isFalse);
  });

  test('知らない ID・形の違う ID・大きすぎる本文・件数の上限', () async {
    expect((await req('GET', 'api/share/AAAAAAAAAAAAAAAAAAAAAA')).$1, 404);
    expect((await req('GET', 'api/share/..%2Fsecret')).$1, 404);
    expect((await req('POST', 'api/share', List.filled(1001, 0))).$1, 413);
    expect((await req('POST', 'api/share', [])).$1, 400);
    for (var i = 0; i < 3; i++) {
      expect((await req('POST', 'api/share', [i])).$1, 201);
    }
    expect((await req('POST', 'api/share', [9])).$1, 503);
  });

  test('Web 版を配信し、知らないパスは index.html。フォルダの外は読ませない', () async {
    final index = await req('GET', '');
    expect(utf8.decode(index.$2), '<html>app</html>');
    expect(index.$3.value('content-type'), startsWith('text/html'));
    final js = await req('GET', 'main.dart.js');
    expect(utf8.decode(js.$2), 'js');
    expect(js.$3.value('content-type'), startsWith('text/javascript'));
    expect(js.$3.value('cache-control'), 'no-cache');
    // 変わっていなければ 304
    final r = await client.getUrl(base.resolve('main.dart.js'));
    r.headers.ifModifiedSince = HttpDate.parse(js.$3.value('last-modified')!);
    final notModified = await r.close();
    await notModified.drain<void>();
    expect(notModified.statusCode, 304);
    expect(utf8.decode((await req('GET', 'share/xyz')).$2), '<html>app</html>');
    final out = await req('GET', '..%2Fsecret.txt');
    expect(out.$1, anyOf(403, 404));
    expect(utf8.decode(out.$2), isNot(contains('secret')));
    expect((await req('PUT', 'index.html')).$1, 405);
  });
}
