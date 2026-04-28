#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOST_INCLUDE_DIR="${ROOT_DIR}/Dependicies/Sources/boost/include/boost"
BOOST_VERSION="1.87.0"
BOOST_UNDERSCORE="${BOOST_VERSION//./_}"
BOOST_TAR="boost_${BOOST_UNDERSCORE}.tar.bz2"
BOOST_URL="https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_TAR}"
ZSTD_VERSION="1.5.7"
ZSTD_TAR="zstd-${ZSTD_VERSION}.tar.gz"
ZSTD_URL="https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/${ZSTD_TAR}"
ZSTD_INCLUDE_DIR="${ROOT_DIR}/Dependicies/Sources/zstd/include"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if [[ -f "${BOOST_INCLUDE_DIR}/serialization/access.hpp" ]]; then
  echo "Boost headers already present: ${BOOST_INCLUDE_DIR}"
else
  echo "Fetching Boost headers ${BOOST_VERSION}..."
  curl -L "${BOOST_URL}" -o "${TMP_DIR}/${BOOST_TAR}"
  tar -xjf "${TMP_DIR}/${BOOST_TAR}" -C "${TMP_DIR}"

  mkdir -p "${ROOT_DIR}/Dependicies/Sources/boost/include"
  cp -R "${TMP_DIR}/boost_${BOOST_UNDERSCORE}/boost" "${ROOT_DIR}/Dependicies/Sources/boost/include/"

  echo "Installed Boost headers to ${ROOT_DIR}/Dependicies/Sources/boost/include/boost"
fi

if [[ -f "${ZSTD_INCLUDE_DIR}/zstd.h" ]]; then
  echo "Zstd headers already present: ${ZSTD_INCLUDE_DIR}"
else
  echo "Fetching Zstd headers ${ZSTD_VERSION}..."
  curl -L "${ZSTD_URL}" -o "${TMP_DIR}/${ZSTD_TAR}"
  tar -xzf "${TMP_DIR}/${ZSTD_TAR}" -C "${TMP_DIR}"

  mkdir -p "${ZSTD_INCLUDE_DIR}"
  cp "${TMP_DIR}/zstd-${ZSTD_VERSION}/lib/zstd.h" "${ZSTD_INCLUDE_DIR}/"
  cp "${TMP_DIR}/zstd-${ZSTD_VERSION}/lib/zdict.h" "${ZSTD_INCLUDE_DIR}/"
  cp "${TMP_DIR}/zstd-${ZSTD_VERSION}/lib/zstd_errors.h" "${ZSTD_INCLUDE_DIR}/"

  echo "Installed Zstd headers to ${ZSTD_INCLUDE_DIR}"
fi
