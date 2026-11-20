# バタフライLP

家計簿兼ライフプランアプリ（Flutter / Android）。仕様は [docs/design.md](docs/design.md) を参照。

## 開発

```sh
flutter pub get
dart run build_runner build   # drift のコード生成（テーブルを変えたとき）
flutter analyze
flutter test
flutter run                   # Android エミュレータ・実機で起動
```
