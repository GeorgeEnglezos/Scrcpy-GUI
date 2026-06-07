#!/bin/bash
# Packages the Linux release bundle into a single-file Flatpak at
# artifacts/flatpak/Scrcpy_GUI-x86_64.flatpak
#
# This is the "self-distributed" flatpak: it relies on flatpak-spawn --host to
# run scrcpy/adb on the host, so the user still needs scrcpy + adb installed.
# It will NOT be accepted on Flathub because of the broad host permission.
#
# Requires: flatpak, flatpak-builder, and the flathub remote.
# Must be run from the ScrcpyGui/ directory, after `flutter build linux --release`.
set -euo pipefail

APP_ID="io.github.GeorgeEnglezos.ScrcpyGUI"
APP_NAME="scrcpy_gui_prod"
DISPLAY_NAME="Scrcpy GUI"
BUILD_PATH="build/linux/x64/release/bundle"
OUT_DIR="artifacts/flatpak"
STAGE="flatpak/_stage"

if [ ! -d "$BUILD_PATH" ]; then
  echo "Error: release bundle not found at $BUILD_PATH" >&2
  echo "Run 'flutter build linux --release' first." >&2
  exit 1
fi

# --- Stage the prebuilt bundle + desktop file next to a copy of the manifest --
# flatpak-builder's `dir` source resolves paths relative to the manifest, so
# everything the manifest references must sit in the same directory.
rm -rf "$STAGE"
mkdir -p "$STAGE/bundle"
cp -r "${BUILD_PATH}/." "$STAGE/bundle/"
cp "flatpak/${APP_ID}.yml" "$STAGE/${APP_ID}.yml"

cat > "$STAGE/${APP_ID}.desktop" << DESKTOP_EOF
[Desktop Entry]
Name=${DISPLAY_NAME}
Comment=A GUI for Scrcpy - Android screen mirroring
Exec=${APP_NAME}
Icon=${APP_ID}
Terminal=false
Type=Application
Categories=Utility;
DESKTOP_EOF

# --- Build, then export a single-file .flatpak bundle -------------------------
mkdir -p "$OUT_DIR"

flatpak-builder --force-clean --user --install-deps-from=flathub \
  --repo=.flatpak-repo .flatpak-build "$STAGE/${APP_ID}.yml"

flatpak build-bundle .flatpak-repo \
  "${OUT_DIR}/Scrcpy_GUI-x86_64.flatpak" "$APP_ID"

echo "Flatpak bundle created:"
ls -lh "${OUT_DIR}/Scrcpy_GUI-x86_64.flatpak"
