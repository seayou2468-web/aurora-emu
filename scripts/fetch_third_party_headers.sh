#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

# -----------------------
# Boost ヘッダ
# -----------------------
BOOST_VERSION="1.87.0"
BOOST_UNDERSCORE="${BOOST_VERSION//./_}"
BOOST_TAR="boost_${BOOST_UNDERSCORE}.tar.bz2"
BOOST_URL="https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_TAR}"
BOOST_INCLUDE_DIR="${ROOT_DIR}/SharedDependencies/Sources/boost/include/boost"

echo "Fetching Boost headers ${BOOST_VERSION}..."
curl -L "${BOOST_URL}" -o "${TMP_DIR}/${BOOST_TAR}"
tar -xjf "${TMP_DIR}/${BOOST_TAR}" -C "${TMP_DIR}"

mkdir -p "${ROOT_DIR}/SharedDependencies/Sources/boost/include"
rm -rf "${ROOT_DIR}/SharedDependencies/Sources/boost/include/boost"
cp -R "${TMP_DIR}/boost_${BOOST_UNDERSCORE}/boost" "${ROOT_DIR}/SharedDependencies/Sources/boost/include/"
echo "Installed Boost headers to ${ROOT_DIR}/SharedDependencies/Sources/boost/include/boost"
