# AuroraIOS platform layout

- `objc/`: 既存のObjective-C/Objective-C++実装（旧 `AuroraIOS` の内容）。
- `swift/`: 新規のSwift実装。
  - `Bridge/`: Swift <-> Core ブリッジ層。
  - `App/`: Swift版アプリのエントリーポイント。
  - `UI/`: Swift版UI（グラスモーフィックUI、ROMインポート/検索/フィルタ/起動/削除を実装。`.3ds/.3dsx` は Aurora3DS ブリッジへ接続）。
- `../API/`: iOS/Linux共通で使うコアAPI参照ヘッダ。

`objc/Bridge/AURCoreSessionFactory` がコア種類に応じて接続方式を選択し、
`objc/Bridge/AURModuleCoreAdapter`（module接続型）または
`objc/Bridge/AURBridgeCoreAdapter`（bridge接続型）を言語版に依存せず利用します。
