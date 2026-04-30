# xcodeproj なしビルド（SwiftPM）

この構成では、SwiftPM用エントリ (`AuroraIOSApp`) を最小依存で分離しています。

- **SwiftPMターゲット**: `App` + `CompatApp` のみ
- 既存の ObjC ブリッジ/UI 実装（`Bridge`, `UI`）は既存アプリ構成側で管理

## 使い方

```bash
swift package resolve
xcodebuild -scheme AuroraIOSApp -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

CIでは上記ビルドの `.app` を `Payload/` に詰め、zipして `.ipa` としてアップロードします。
