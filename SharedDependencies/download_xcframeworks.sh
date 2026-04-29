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
  url="${BASE_URL}/${version}/${zip_name}"

  echo "Downloading ${zip_name} (${version})"
  curl -L --fail --retry 3 --output "$zip_path" "$url"

  unzip -oq "$zip_path" -d "$DEST_DIR"
  rm -f "$zip_path"
done

echo "Done: xcframework artifacts downloaded and extracted into ${DEST_DIR}."
