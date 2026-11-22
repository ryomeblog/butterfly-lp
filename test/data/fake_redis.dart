import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:butterfly_lp/data/sync/resp_client.dart';

/// テスト用の最小の Redis 互換サーバー（AUTH・SCAN・GET・SET EX・TTL だけ）。
class FakeRedis {
  FakeRedis._(this._server, this.password);

  static Future<FakeRedis> start({String? password}) async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final r = FakeRedis._(s, password);
    s.listen(r._handle);
    return r;
  }

  final ServerSocket _server;
  final String? password;
  final data = <String, Uint8List>{};
  final ttl = <String, int>{};

  int get port => _server.port;

  void _handle(Socket socket) {
    final parser = RespParser();
    var authed = password == null;
    socket.listen((bytes) {
      parser.add(bytes);
      while (true) {
        final r = parser.next();
        if (r == null) break;
        final args = [for (final a in r.value! as List) a as Uint8List];
        final cmd = utf8.decode(args[0]).toUpperCase();
        String s(int i) => utf8.decode(args[i]);
        if (cmd == 'AUTH') {
          authed = s(1) == password;
          socket.add(ascii.encode(authed ? '+OK\r\n' : '-WRONGPASS\r\n'));
          continue;
        }
        if (!authed) {
          socket.add(ascii.encode('-NOAUTH Authentication required.\r\n'));
          continue;
        }
        switch (cmd) {
          case 'SET':
            data[s(1)] = args[2];
            ttl[s(1)] = int.parse(s(4));
            socket.add(ascii.encode('+OK\r\n'));
          case 'GET':
            final v = data[s(1)];
            socket.add(v == null ? ascii.encode('\$-1\r\n') : _bulk(v));
          case 'TTL':
            socket.add(ascii.encode(':${ttl[s(1)] ?? -2}\r\n'));
          case 'SCAN':
            final pattern = s(3);
            final re = RegExp(
              '^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$',
            );
            final keys = data.keys.where(re.hasMatch).toList();
            final b = BytesBuilder()
              ..add(ascii.encode('*2\r\n'))
              ..add(_bulk(utf8.encode('0')))
              ..add(ascii.encode('*${keys.length}\r\n'));
            for (final k in keys) {
              b.add(_bulk(utf8.encode(k)));
            }
            socket.add(b.takeBytes());
          default:
            socket.add(ascii.encode('-ERR unknown command\r\n'));
        }
      }
    });
  }

  List<int> _bulk(List<int> v) => [
    ...ascii.encode('\$${v.length}\r\n'),
    ...v,
    13,
    10,
  ];

  Future<void> close() => _server.close();
}
