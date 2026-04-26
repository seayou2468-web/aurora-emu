# Vendored minimal Crypto++ subset (aurora3ds)

This directory contains a minimized subset of Crypto++ source files used by `src/core/aurora3ds`.

## Source

- Upstream: https://github.com/weidai11/cryptopp
- Version used for extraction: `CRYPTOPP_8_9_0`

## Why this exists

aurora3ds uses many Crypto++ features (AES modes, CCM, RSA, EC2N ECC, hashing, HMAC, CMAC,
filters, and RNG). This subset vendors only the files needed by the currently included Crypto++
headers and their transitive local dependencies.

## Regeneration

Use:

```bash
python3 scripts/extract_min_cryptopp.py /path/to/cryptopp-source /path/to/repo
```

The script computes transitive local `#include "..."` closure from the directly referenced
Crypto++ headers and copies matching `.cpp` pairs when present.

## License

Crypto++ license text is provided in `License.txt`.
