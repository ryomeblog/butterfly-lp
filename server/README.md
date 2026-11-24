# バタフライLP サーバー

Web 版の配信と、QRでの共有の受け渡し（暗号文を24時間預かる）だけを行う小さなサーバーです（設計書 3.12）。
家計簿のデータはブラウザ・アプリの中にあり、サーバーには暗号化した共有しか届きません（鍵は URL の `#` 以降にあり、サーバーに送られません）。

## 動かし方

### Docker

リポジトリのルートで：

```sh
docker build -f server/Dockerfile -t butterfly-lp .
docker run -d --name butterfly-lp -p 8080:8080 -v lp-share:/data --restart unless-stopped butterfly-lp
```

ブラウザで `http://サーバーのアドレス:8080/` を開くと Web 版が使えます。

### Docker を使わない

```sh
flutter build web --release          # リポジトリのルートで
cd server && dart pub get
WEB_DIR=../build/web DATA_DIR=./data PORT=8080 dart run bin/server.dart
```

## 設定（環境変数）

| 変数 | 既定 | 内容 |
| --- | --- | --- |
| PORT | 8080 | 待ち受けるポート |
| WEB_DIR | ../build/web | Web 版のフォルダ（なければ配信しない） |
| DATA_DIR | ./data | 共有の暗号文を置くフォルダ |
| MAX_MB | 20 | 共有1件の上限（MB） |

## インターネットに公開するとき

- HTTPS にしてください（リバースプロキシで TLS を終端する）。カメラや一部のブラウザ機能は HTTPS でないと使えないことがあります
- 共有は URL を知っている人なら誰でも受け取れます（24時間で消えます）。預かる件数は1,000件までです
- スマホ版・デスクトップ版は、設定の「共有サーバー」にこのサーバーの URL を入れます

## API

- `POST /api/share`：本文（暗号文）を預かり `201 {"id": "...", "expires_in": 86400}` を返す
- `GET /api/share/{id}`：預かった本文を返す。期限を過ぎたものは `404`
