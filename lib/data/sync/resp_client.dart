import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'resp_socket_stub.dart' if (dart.library.io) 'resp_socket_io.dart';

/// Redis がエラーを返した。
class RedisError implements Exception {
  RedisError(this.message);
  final String message;
  @override
  String toString() => 'RedisError: $message';
}

/// RESP の応答を、届いたバイト列から順に読み出す（設計書 5・11）。
///
/// 値はバイト列のまま扱う（暗号化したスナップショットを壊さないため）。
class RespParser {
  final _buf = BytesBuilder(copy: false);
  Uint8List _data = Uint8List(0);
  int _pos = 0;

  void add(List<int> bytes) {
    final rest = _data.sublist(_pos);
    _buf
      ..add(rest)
      ..add(bytes);
    _data = _buf.takeBytes();
    _pos = 0;
  }

  /// 1つの応答を読む。まだ揃っていなければ null（読んだ位置は戻す）。
  /// 戻り値：String（+）、RedisError（-）、int（:）、Uint8List?（$）、List（*）。
  ({Object? value})? next() {
    final start = _pos;
    try {
      return (value: _read());
    } on _Incomplete {
      _pos = start;
      return null;
    }
  }

  Object? _read() {
    final type = _byte();
    final line = _line();
    switch (type) {
      case 0x2B: // +
        return line;
      case 0x2D: // -
        return RedisError(line);
      case 0x3A: // :
        return int.parse(line);
      case 0x24: // $
        final n = int.parse(line);
        if (n < 0) return null;
        if (_data.length - _pos < n + 2) throw const _Incomplete();
        final v = Uint8List.sublistView(_data, _pos, _pos + n);
        _pos += n + 2;
        return Uint8List.fromList(v);
      case 0x2A: // *
        final n = int.parse(line);
        if (n < 0) return null;
        return [for (var i = 0; i < n; i++) _read()];
      default:
        throw FormatException('RESP の種類が不明です: $type');
    }
  }

  int _byte() {
    if (_pos >= _data.length) throw const _Incomplete();
    return _data[_pos++];
  }

  String _line() {
    for (var i = _pos; i + 1 < _data.length; i++) {
      if (_data[i] == 0x0D && _data[i + 1] == 0x0A) {
        final s = latin1.decode(Uint8List.sublistView(_data, _pos, i));
        _pos = i + 2;
        return s;
      }
    }
    throw const _Incomplete();
  }
}

class _Incomplete implements Exception {
  const _Incomplete();
}

/// コマンドを RESP の配列（バルク文字列）にする。引数は String か `List<int>`。
Uint8List encodeCommand(List<Object> args) {
  final b = BytesBuilder();
  b.add(ascii.encode('*${args.length}\r\n'));
  for (final a in args) {
    final bytes = a is String ? utf8.encode(a) : (a as List<int>);
    b.add(ascii.encode('\$${bytes.length}\r\n'));
    b.add(bytes);
    b.add(const [0x0D, 0x0A]);
  }
  return b.takeBytes();
}

/// 同期に使う4つのコマンド（AUTH・SCAN・GET・SET EX）だけを持つ最小の Redis クライアント。
class RespClient {
  RespClient._(this._socket) {
    _sub = _socket.listen(
      (data) {
        _parser.add(data);
        _drain();
      },
      onError: (Object e) => _failAll(e),
      onDone: () => _failAll(const RespConnectionClosed()),
    );
  }

  static Future<RespClient> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return RespClient._(await openRespSocket(host, port, timeout));
  }

  final RespSocket _socket;
  late final StreamSubscription<Uint8List> _sub;
  final _parser = RespParser();
  final _waiting = <Completer<Object?>>[];

  void _drain() {
    while (_waiting.isNotEmpty) {
      final r = _parser.next();
      if (r == null) return;
      final c = _waiting.removeAt(0);
      final v = r.value;
      if (v is RedisError) {
        c.completeError(v);
      } else {
        c.complete(v);
      }
    }
  }

  void _failAll(Object e) {
    for (final c in _waiting) {
      if (!c.isCompleted) c.completeError(e);
    }
    _waiting.clear();
  }

  Future<Object?> command(
    List<Object> args, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    final c = Completer<Object?>();
    _waiting.add(c);
    _socket.add(encodeCommand(args));
    return c.future.timeout(timeout);
  }

  Future<void> auth(String password) => command(['AUTH', password]);

  /// パターンに合うキーをすべて列挙する（SCAN を繰り返す）。
  Future<List<String>> scanAll(String pattern) async {
    final keys = <String>[];
    var cursor = '0';
    do {
      final r = await command([
        'SCAN',
        cursor,
        'MATCH',
        pattern,
        'COUNT',
        '100',
      ]) as List;
      cursor = utf8.decode(r[0] as Uint8List);
      for (final k in r[1] as List) {
        keys.add(utf8.decode(k as Uint8List));
      }
    } while (cursor != '0');
    return keys;
  }

  Future<Uint8List?> get(String key) async =>
      await command(['GET', key]) as Uint8List?;

  Future<void> setEx(String key, List<int> value, int seconds) =>
      command(['SET', key, value, 'EX', '$seconds']);

  Future<void> close() async {
    await _sub.cancel();
    await _socket.close();
    _socket.destroy();
  }
}
