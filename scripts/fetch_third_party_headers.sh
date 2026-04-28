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
VMA_VERSION="3.3.0"
VMA_TAR="VulkanMemoryAllocator-${VMA_VERSION}.tar.gz"
VMA_URL="https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/archive/refs/tags/v${VMA_VERSION}.tar.gz"
VMA_INCLUDE_DIR="${ROOT_DIR}/Dependicies/Sources/vma/include/vma"
VMA_HEADER="${VMA_INCLUDE_DIR}/vk_mem_alloc.h"

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

if [[ -f "${VMA_HEADER}" ]]; then
  echo "VMA header already present: ${VMA_HEADER}"
else
  echo "Fetching VMA headers ${VMA_VERSION}..."
  curl -L "${VMA_URL}" -o "${TMP_DIR}/${VMA_TAR}"
  tar -xzf "${TMP_DIR}/${VMA_TAR}" -C "${TMP_DIR}"

  mkdir -p "${VMA_INCLUDE_DIR}"
  cp "${TMP_DIR}/VulkanMemoryAllocator-${VMA_VERSION}/include/vk_mem_alloc.h" "${VMA_HEADER}"
  echo "Installed VMA header to ${VMA_HEADER}"
fi
