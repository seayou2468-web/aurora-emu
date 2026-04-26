#!/usr/bin/env python3
"""Extract a minimal vendored Crypto++ subset for aurora3ds.

Usage:
  python3 scripts/extract_min_cryptopp.py /path/to/cryptopp-src /path/to/repo
"""
from __future__ import annotations
import pathlib
import re
import shutil
import sys

DIRECT_HEADERS = {
    "aes.h",
    "base64.h",
    "ccm.h",
    "cmac.h",
    "cryptlib.h",
    "eccrypto.h",
    "filters.h",
    "hex.h",
    "hmac.h",
    "integer.h",
    "md5.h",
    "modes.h",
    "nbtheory.h",
    "oids.h",
    "osrng.h",
    "rsa.h",
    "sha.h",
}

INCLUDE_RE = re.compile(r'#include\s+"([^"]+)"')


def closure(src: pathlib.Path, seeds: set[str]) -> set[str]:
    out: set[str] = set()
    stack = list(seeds)
    while stack:
        name = stack.pop()
        if name in out:
            continue
        p = src / name
        if not p.exists():
            continue
        out.add(name)
        text = p.read_text(errors="ignore")
        for m in INCLUDE_RE.finditer(text):
            inc = m.group(1)
            if (src / inc).exists() and inc not in out:
                stack.append(inc)
    return out


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1

    cryptopp_src = pathlib.Path(sys.argv[1]).resolve()
    repo_root = pathlib.Path(sys.argv[2]).resolve()
    dest = repo_root / "src/core/aurora3ds/cryptopp"

    if not (cryptopp_src / "config.h").exists():
        raise SystemExit(f"Not a Crypto++ source dir: {cryptopp_src}")

    headers = closure(cryptopp_src, DIRECT_HEADERS)

    # Add matching .cpp files and recurse through their local includes.
    seeds = set(headers)
    for h in list(headers):
        cpp = pathlib.Path(h).with_suffix(".cpp").name
        if (cryptopp_src / cpp).exists():
            seeds.add(cpp)

    files = closure(cryptopp_src, seeds)
    files = {
        f
        for f in files
        if pathlib.Path(f).suffix in {".h", ".hpp", ".cpp", ".inc", ".S", ".asm"}
    }

    dest.mkdir(parents=True, exist_ok=True)
    for p in dest.glob("*"):
        if p.is_file():
            p.unlink()

    for name in sorted(files):
        shutil.copy2(cryptopp_src / name, dest / name)

    shutil.copy2(cryptopp_src / "License.txt", dest / "License.txt")

    print(f"Copied {len(files)} Crypto++ files into {dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
