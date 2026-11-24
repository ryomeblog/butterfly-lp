import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipDecoder, GZipEncoder;
import 'package:cryptography/cryptography.dart';

/// 合言葉から作るもの（設計書 5.1）。
///
/// - グループID：`SHA-256("lifeplan-group:" + 合言葉)` の16進
/// - 暗号鍵：PBKDF2-HMAC-SHA256（合言葉、ソルト＝`"lifeplan-enc:" + グループID`、20万回）の256bit
class SyncCrypto {
  static const iterations = 200000;

  /// 暗号化したバイト列の先頭の版（形式を変えたときに見分ける）
  static const formatVersion = 1;

  static Future<String> groupIdOf(String passphrase) async {
    final h = await Sha256().hash(utf8.encode('lifeplan-group:$passphrase'));
    return h.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 鍵の導出。端末では cryptography_flutter のネイティブ実装が使われる。
  static Future<List<int>> deriveKey(
    String passphrase, {
    int iterations = iterations,
  }) async {
    final groupId = await groupIdOf(passphrase);
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: utf8.encode('lifeplan-enc:$groupId'),
    );
    return key.extractBytes();
  }

  /// gzip で圧縮してから AES-256-GCM で暗号化する。形式：[版 1バイト][nonce 12][暗号文][MAC 16]
  static Future<Uint8List> encrypt(List<int> plain, List<int> key) async {
    final aes = AesGcm.with256bits();
    final box = await aes.encrypt(
      const GZipEncoder().encodeBytes(plain),
      secretKey: SecretKey(key),
      nonce: aes.newNonce(),
    );
    return Uint8List.fromList([
      formatVersion,
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  /// 復号して展開する。合言葉が違う・壊れているときは例外（設計書 5.3-2：無視する）。
  static Future<List<int>> decrypt(List<int> data, List<int> key) async {
    if (data.length < 1 + 12 + 16 || data[0] != formatVersion) {
      throw const FormatException('同期データの形式が違います');
    }
    final nonce = data.sublist(1, 13);
    final mac = data.sublist(data.length - 16);
    final cipher = data.sublist(13, data.length - 16);
    final plain = await AesGcm.with256bits().decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(key),
    );
    return const GZipDecoder().decodeBytes(plain);
  }
}
