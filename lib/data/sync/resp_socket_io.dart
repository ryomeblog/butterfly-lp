import 'dart:io';

/// Redis への TCP 接続（Android・デスクトップ）。
typedef RespSocket = Socket;

/// 接続が切れた。
class RespConnectionClosed extends SocketException {
  const RespConnectionClosed() : super('Redis との接続が切れました');
}

Future<RespSocket> openRespSocket(String host, int port, Duration timeout) =>
    Socket.connect(host, port, timeout: timeout);
