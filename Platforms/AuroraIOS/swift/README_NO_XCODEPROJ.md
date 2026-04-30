# xcodeproj なしビルド（SwiftPM）

## 重要
- **フル機能エミュ（ObjC/C++コア連携）** は既存のObjCブリッジ構成が必要です。
- SwiftPMターゲット `AuroraIOSApp` は、CIでの unsigned `.app/.ipa` 生成を目的にした**最小起動構成**です。

## 構成
- `SWIFT_PACKAGE` 時: `AuroraCompatRootViewController` を起動（最小UI）
- 非 `SWIFT_PACKAGE` 時: `SwiftLibraryViewController` を起動（エミュライブラリUI）

## 使い方
```bash
swift package resolve
xcodebuild -scheme AuroraIOSApp -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

CIでは生成された `.app` を `Payload/` に入れて zip し、`.ipa` として成果物アップロードします。
