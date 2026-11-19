#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="4.7.2"
BUILD_TMP="$(mktemp -d)"
trap 'rm -rf "$BUILD_TMP"' EXIT

GODOT_DIR="$BUILD_TMP/godot"
TEMPLATE_DIR="$BUILD_TMP/templates"
mkdir -p "$GODOT_DIR" "$TEMPLATE_DIR" build

curl --fail --location --silent --show-error \
  "https://godot-releases.nbg1.your-objectstorage.com/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
  --output "$BUILD_TMP/godot.zip"
curl --fail --location --silent --show-error \
  "https://godot-releases.nbg1.your-objectstorage.com/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" \
  --output "$BUILD_TMP/templates.tpz"

python3 - "$BUILD_TMP/godot.zip" "$GODOT_DIR" "$BUILD_TMP/templates.tpz" "$TEMPLATE_DIR" <<'PY'
import sys
import zipfile
for archive, destination in ((sys.argv[1], sys.argv[2]), (sys.argv[3], sys.argv[4])):
    with zipfile.ZipFile(archive) as bundle:
        bundle.extractall(destination)
PY

GODOT_BIN="$GODOT_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
chmod +x "$GODOT_BIN"

export XDG_DATA_HOME="$BUILD_TMP/user-data"
TEMPLATE_INSTALL="$XDG_DATA_HOME/godot/export_templates/${GODOT_VERSION}.stable"
mkdir -p "$TEMPLATE_INSTALL"
cp -R "$TEMPLATE_DIR/templates/." "$TEMPLATE_INSTALL/"

"$GODOT_BIN" --headless --editor --path . --import
"$GODOT_BIN" --headless --path . --export-release "Web" build/index.html
