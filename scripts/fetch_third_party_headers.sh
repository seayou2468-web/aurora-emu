#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

BOOST_VERSION="1.87.0"
BOOST_UNDERSCORE="${BOOST_VERSION//./_}"
BOOST_TAR="boost_${BOOST_UNDERSCORE}.tar.bz2"
BOOST_URL="https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_TAR}"
BOOST_INCLUDE_DIR="${ROOT_DIR}/Dependicies/Sources/boost/include/boost"

if [[ -f "${BOOST_INCLUDE_DIR}/serialization/access.hpp" && -f "${BOOST_INCLUDE_DIR}/align/align.hpp" ]]; then
  echo "Boost headers already present: ${BOOST_INCLUDE_DIR}"
else
  echo "Fetching Boost headers ${BOOST_VERSION}..."
  curl -L "${BOOST_URL}" -o "${TMP_DIR}/${BOOST_TAR}"
  tar -xjf "${TMP_DIR}/${BOOST_TAR}" -C "${TMP_DIR}"

  mkdir -p "${ROOT_DIR}/Dependicies/Sources/boost/include"
  rm -rf "${ROOT_DIR}/Dependicies/Sources/boost/include/boost"
  cp -R "${TMP_DIR}/boost_${BOOST_UNDERSCORE}/boost" "${ROOT_DIR}/Dependicies/Sources/boost/include/"
  echo "Installed Boost headers to ${ROOT_DIR}/Dependicies/Sources/boost/include/boost"
fi

VULKAN_HEADERS_VERSION="1.3.296.0"
VULKAN_HEADERS_TAR="vulkan-headers-${VULKAN_HEADERS_VERSION}.tar.gz"
VULKAN_HEADERS_URL="https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/vulkan-sdk-${VULKAN_HEADERS_VERSION}.tar.gz"
VULKAN_INCLUDE_DIR="${ROOT_DIR}/Dependicies/Sources/vulkan/include/vulkan"

if [[ -f "${VULKAN_INCLUDE_DIR}/vulkan.hpp" ]]; then
  echo "Vulkan headers already present: ${VULKAN_INCLUDE_DIR}"
else
  echo "Fetching Vulkan headers ${VULKAN_HEADERS_VERSION}..."
  curl -L "${VULKAN_HEADERS_URL}" -o "${TMP_DIR}/${VULKAN_HEADERS_TAR}"
  tar -xzf "${TMP_DIR}/${VULKAN_HEADERS_TAR}" -C "${TMP_DIR}"
  VULKAN_EXTRACT_DIR="$(find "${TMP_DIR}" -maxdepth 1 -type d -name 'Vulkan-Headers-*' | head -n 1)"
  if [[ -z "${VULKAN_EXTRACT_DIR}" ]]; then
    echo "Failed to locate extracted Vulkan-Headers directory." >&2
    exit 1
  fi

  mkdir -p "${ROOT_DIR}/Dependicies/Sources/vulkan/include"
  rm -rf "${VULKAN_INCLUDE_DIR}"
  cp -R "${VULKAN_EXTRACT_DIR}/include/vulkan" \
    "${ROOT_DIR}/Dependicies/Sources/vulkan/include/"
  echo "Installed Vulkan headers to ${VULKAN_INCLUDE_DIR}"
fi
