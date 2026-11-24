import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/time.dart';
import '../db/database.dart';
import 'resp_client.dart';
import 'snapshot.dart';
import 'sync_crypto.dart';

/// 秘密の値の置き場所。端末ではセキュアストレージ（Keychain / Keystore）、テストではメモリ（設計書 4.6）。
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  // macOS は署名のチームなしでも使えるよう、従来のキーチェーンに保存する
  static const _s = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  @override
  Future<String?> read(String key) => _s.read(key: key);

  @override
  Future<void> write(String key, String? value) =>
      value == null ? _s.delete(key: key) : _s.write(key: key, value: value);
}

class MemorySecretStore implements SecretStore {
  final _m = <String, String>{};

  @override
  Future<String?> read(String key) async => _m[key];

  @override
  Future<void> write(String key, String? value) async =>
      value == null ? _m.remove(key) : _m[key] = value;
}

/// 同期1回の結果（設計書 5.3-6）。
class SyncResult {
  const SyncResult({
    required this.at,
    required this.devices,
    required this.adopted,
    required this.broken,
    this.undecryptable = 0,
    this.newerSchema = 0,
  });

  final String at;

  /// 取り込んだ他端末の数
  final int devices;

  /// 採用した行の数
  final int adopted;

  /// 参照切れの件数
  final int broken;

  /// 復号できなかった（合言葉が違う）スナップショットの数
  final int undecryptable;

  /// データ形式が新しく取り込めなかった（アプリの更新が必要な）端末の数
  final int newerSchema;
}

/// 同期の設定がそろっていない。
class SyncNotConfigured implements Exception {
  const SyncNotConfigured(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 自宅Redisを受け渡し場所にした同期（設計書 5）。
class SyncService {
  SyncService(this.db, this.secrets, this.deviceId);

  final AppDatabase db;
  final SecretStore secrets;
  final String deviceId;

  static const ttlSeconds = 86400;
  static const _passphrase = 'sync_passphrase';
  static const _key = 'sync_key';
  static const _groupId = 'sync_group_id';
  static const _redisPassword = 'redis_password';

  Future<String?> passphrase() => secrets.read(_passphrase);
  Future<String?> redisPassword() => secrets.read(_redisPassword);

  /// 合言葉を登録する。鍵とグループIDはここで1回だけ作って保存する（設計書 11）。
  Future<void> setPassphrase(String passphrase) async {
    final groupId = await SyncCrypto.groupIdOf(passphrase);
    final key = await SyncCrypto.deriveKey(passphrase);
    await secrets.write(_passphrase, passphrase);
    await secrets.write(_groupId, groupId);
    await secrets.write(_key, base64.encode(key));
  }

  /// 接続先（アドレス・ポートは端末設定、パスワードはセキュアストレージ）。
  Future<void> setConnection({
    required String host,
    required int port,
    String? password,
  }) async {
    await db
        .update(db.deviceSettings)
        .write(
          DeviceSettingsCompanion(
            redisHost: Value(host),
            redisPort: Value(port),
          ),
        );
    await secrets.write(
      _redisPassword,
      (password == null || password.isEmpty) ? null : password,
    );
  }

  /// 同期ボタンの処理（設計書 5.3）。
  Future<SyncResult> sync() async {
    final setting = await db.select(db.deviceSettings).getSingle();
    final host = setting.redisHost;
    final port = setting.redisPort;
    final groupId = await secrets.read(_groupId);
    final keyText = await secrets.read(_key);
    if (host == null || host.isEmpty || port == null) {
      throw const SyncNotConfigured('接続先（自宅Redis）のアドレスとポートを入れてください');
    }
    if (groupId == null || keyText == null) {
      throw const SyncNotConfigured('合言葉を登録してください');
    }
    final key = base64.decode(keyText);
    final password = await secrets.read(_redisPassword);
    final ownKey = 'lp:$groupId:snap:$deviceId';

    final client = await RespClient.connect(host, port);
    try {
      if (password != null) await client.auth(password);
      // 1. 自端末以外のスナップショットを取得
      final keys = await client.scanAll('lp:$groupId:snap:*');
      var devices = 0;
      var adopted = 0;
      var undecryptable = 0;
      var newer = 0;
      for (final k in keys) {
        if (k == ownKey) continue;
        final data = await client.get(k);
        if (data == null) continue; // 期限切れ
        // 2. 復号・展開。失敗したもの（合言葉違い）は無視する
        Snapshot snap;
        try {
          snap = Snapshot.fromBytes(await SyncCrypto.decrypt(data, key));
        } catch (_) {
          undecryptable++;
          continue;
        }
        // 3. 自端末より新しいデータ形式は取り込まない
        if (snap.schemaVersion > currentSchemaVersion) {
          newer++;
          continue;
        }
        // 4. 行ごとに新しい方を採用
        adopted += await mergeSnapshot(db, snap);
        devices++;
      }
      // 5. 自端末の全データ（墓石を含む）を有効期限1日で書き込む
      final own = await buildSnapshot(db, deviceId);
      await client.setEx(
        ownKey,
        await SyncCrypto.encrypt(own.toBytes(), key),
        ttlSeconds,
      );

      // 6. 最終同期日時を更新し、件数を返す
      final at = nowTimestamp();
      await db
          .update(db.deviceSettings)
          .write(DeviceSettingsCompanion(lastSyncAt: Value(at)));
      return SyncResult(
        at: at,
        devices: devices,
        adopted: adopted,
        broken: await countBrokenReferences(db),
        undecryptable: undecryptable,
        newerSchema: newer,
      );
    } finally {
      await client.close();
    }
  }
}
