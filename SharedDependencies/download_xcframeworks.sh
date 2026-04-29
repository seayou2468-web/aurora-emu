#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://github.com/folium-app/SharedDependencies/releases/download"
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

artifacts=(
  "lib_boostcontext:0.0.6"
  "lib_boostiostreams:0.0.6"
  "lib_boostprogramoptions:0.0.6"
  "lib_boostserialization:0.0.6"
  "lib_dynarmic:0.0.7"
  "lib_fmt:0.0.7"
  "lib_mcl:0.0.7"
  "lib_enet:0.0.6"
  "lib_faad2:0.0.6"
  "lib_genericcodegen:0.0.6"
  "lib_glslang:0.0.6"
  "lib_machineindependent:0.0.6"
  "lib_spirv:0.0.6"
  "lib_openal:0.0.6"
  "lib_opus:0.0.6"
  "lib_sdl3:0.0.7"
  "lib_sirit:0.0.6"
  "lib_soundtouch:0.0.6"
  "lib_teakra:0.0.7"
)

for artifact in "${artifacts[@]}"; do
  IFS=":" read -r name version <<< "$artifact"
  zip_name="${name}.xcframework.zip"
  zip_path="${DEST_DIR}/${zip_name}"
  expected_path="${DEST_DIR}/${name}.xcframework"
  url="${BASE_URL}/${version}/${zip_name}"

  echo "Downloading ${zip_name} (${version})"
  curl -L --fail --retry 3 --output "$zip_path" "$url"

  rm -rf "$expected_path"
  unzip -oq "$zip_path" -d "$DEST_DIR"
  rm -f "$zip_path"

  # Release artifacts may unpack with legacy names (e.g. libboostcontext.xcframework, SDL3.xcframework).
  candidate_paths=(
    "$expected_path"
    "${DEST_DIR}/${name/lib_/lib}.xcframework"
  )
  if [[ "$name" == "lib_sdl3" ]]; then
    candidate_paths+=("${DEST_DIR}/SDL3.xcframework")
  fi

  resolved_path=""
  for candidate in "${candidate_paths[@]}"; do
    if [[ -d "$candidate" ]]; then
      resolved_path="$candidate"
      break
    fi
  done

  if [[ -z "$resolved_path" ]]; then
    echo "Failed to locate extracted xcframework for ${name}" >&2
    exit 1
  fi

  if [[ "$resolved_path" != "$expected_path" ]]; then
    rm -rf "$expected_path"
    mv "$resolved_path" "$expected_path"
  fi
done

echo "Done: xcframework artifacts downloaded and extracted into ${DEST_DIR}."
