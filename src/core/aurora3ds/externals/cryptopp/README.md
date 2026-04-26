# vendored Crypto++ (minimal subset)

このディレクトリには、`aurora3ds` が実際に参照している Crypto++ 機能に必要な最小限のソースだけを内蔵しています。

- 取得元: `https://github.com/weidai11/cryptopp`
- ベースタグ: `CRYPTOPP_8_9_0`
- 実体: `cryptopp/` 配下（`#include <cryptopp/...>` 互換）
- 再生成スクリプト: `scripts/vendor_cryptopp_minimal.py`

## 再生成方法

```bash
TMPDIR=$(mktemp -d)
git clone --depth 1 --branch CRYPTOPP_8_9_0 https://github.com/weidai11/cryptopp.git "$TMPDIR/cryptopp"
./scripts/vendor_cryptopp_minimal.py --crypto-root "$TMPDIR/cryptopp"
rm -rf "$TMPDIR"
```

## 依存解決ポリシー

スクリプトは以下を自動収集します。

1. `src/core/aurora3ds` の `#include <cryptopp/...>` エントリヘッダ
2. それらが内部で `#include` している Crypto++ ファイル
3. 必要なヘッダに対応する `.cpp` 実装（存在する場合）

これにより、不要なアルゴリズム/実装を避けつつ、依存で不足しない構成を維持します。
