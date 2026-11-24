import 'dart:async';
import 'dart:typed_data';

/// Web 版にはない（ブラウザから Redis に直接つなげない。設計書 3.12）。
abstract class RespSocket implements Stream<Uint8List> {
  void add(List<int> data);
  Future<void> close();
  void destroy();
}

/// 接続が切れた。
class RespConnectionClosed implements Exception {
  const RespConnectionClosed();
  @override
  String toString() => 'Redis との接続が切れました';
}

Future<RespSocket> openRespSocket(String host, int port, Duration timeout) =>
    throw UnsupportedError('Web 版では同期を使えません');
