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

SOURCE_ROOT = pathlib.Path("src/core/aurora3ds")
VENDORED_DIR = pathlib.Path("src/core/aurora3ds/cryptopp")

INCLUDE_RE = re.compile(r'#include\s+"([^"]+)"')
PROJECT_CRYPTOPP_INCLUDE_RE = re.compile(r'#include\s+[<"]cryptopp/([^>"]+)[>"]')


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


def discover_direct_headers(repo_root: pathlib.Path) -> set[str]:
    source_root = repo_root / SOURCE_ROOT
    headers: set[str] = set()
    for path in source_root.rglob("*"):
        if path.suffix not in {".c", ".cc", ".cpp", ".h", ".hpp"}:
            continue
        text = path.read_text(errors="ignore")
        headers.update(PROJECT_CRYPTOPP_INCLUDE_RE.findall(text))

    if not headers:
        raise RuntimeError(f"No Crypto++ includes found under {source_root}")

    return headers


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1

    cryptopp_src = pathlib.Path(sys.argv[1]).resolve()
    repo_root = pathlib.Path(sys.argv[2]).resolve()
    dest = repo_root / VENDORED_DIR

    if cryptopp_src == dest:
        raise SystemExit("cryptopp source and vendored destination must be different directories")

    if not (cryptopp_src / "config.h").exists():
        raise SystemExit(f"Not a Crypto++ source dir: {cryptopp_src}")

    direct_headers = discover_direct_headers(repo_root)
    headers = closure(cryptopp_src, direct_headers)

    # Add matching .cpp files and recurse through their local includes.
    seeds = set(headers)
    for h in list(direct_headers):
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
        if p.is_file() and p.name != "README.md":
            p.unlink()

    for name in sorted(files):
        shutil.copy2(cryptopp_src / name, dest / name)

    shutil.copy2(cryptopp_src / "License.txt", dest / "License.txt")

    print(f"Found {len(direct_headers)} directly used Crypto++ headers")
    print(f"Copied {len(files)} Crypto++ files into {dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
