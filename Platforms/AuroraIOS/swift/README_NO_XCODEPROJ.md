# xcodeproj なしビルド（SwiftPM）

`Package.swift` を追加したため、`xcodeproj` なしでも Swift Package として依存解決・ビルド設定管理が可能です。

## 使い方

```bash
swift package resolve
swift build
```

> 実機向けの最終リンクは UIKit / ObjC ブリッジ依存があるため、CI では `xcodebuild -scheme AuroraIOSApp` 併用を推奨。
