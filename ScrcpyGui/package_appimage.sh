#!/bin/bash
# Packages the Linux release bundle into a single-file AppImage at
# artifacts/appimage/Scrcpy_GUI-x86_64.AppImage
#
# GTK3 (and its theme engines + pixbuf loaders) is bundled via the linuxdeploy
# GTK plugin, so the AppImage runs on any glibc Linux distro (Arch, Fedora,
# Ubuntu, ...) with zero runtime dependencies. The user still needs scrcpy and
# adb installed separately, since this app shells out to them.
#
# Must be run from the ScrcpyGui/ directory.
set -euo pipefail

APP_NAME="scrcpy_gui_prod"
DISPLAY_NAME="Scrcpy GUI"
BUILD_PATH="build/linux/x64/release/bundle"
APPDIR="AppDir"
OUT_DIR="artifacts/appimage"
OUTPUT="${OUT_DIR}/Scrcpy_GUI-x86_64.AppImage"

if [ ! -d "$BUILD_PATH" ]; then
  echo "Error: release bundle not found at $BUILD_PATH" >&2
  echo "Run 'flutter build linux --release' first." >&2
  exit 1
fi

# --- Build a clean AppDir -----------------------------------------------------
rm -rf "$APPDIR"
mkdir -p "${APPDIR}/usr/bin"

# Copy the entire Flutter bundle (binary + lib/ + data/) into usr/bin so the
# app finds its assets and libraries via the relative paths Flutter expects.
cp -r "${BUILD_PATH}/." "${APPDIR}/usr/bin/"
chmod +x "${APPDIR}/usr/bin/${APP_NAME}"

# Icon used for the .desktop entry and the AppImage itself.
ICON_SRC="${BUILD_PATH}/data/flutter_assets/icon.png"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/512x512/apps"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "${APPDIR}/usr/share/icons/hicolor/512x512/apps/${APP_NAME}.png"
  cp "$ICON_SRC" "${APPDIR}/${APP_NAME}.png"
else
  echo "Warning: icon not found at $ICON_SRC; AppImage will have no icon." >&2
fi

# Desktop entry consumed by linuxdeploy.
DESKTOP_FILE="${APPDIR}/usr/share/applications/${APP_NAME}.desktop"
mkdir -p "${APPDIR}/usr/share/applications"
cat > "$DESKTOP_FILE" << DESKTOP_EOF
[Desktop Entry]
Name=${DISPLAY_NAME}
Comment=A GUI for Scrcpy - Android screen mirroring
Exec=${APP_NAME}
Icon=${APP_NAME}
Terminal=false
Type=Application
Categories=Utility;
DESKTOP_EOF

# --- Fetch linuxdeploy + GTK plugin (cached if already present) ---------------
LD_TOOL="linuxdeploy-x86_64.AppImage"
GTK_PLUGIN="linuxdeploy-plugin-gtk.sh"

if [ ! -x "$LD_TOOL" ]; then
  echo "Downloading linuxdeploy..."
  curl -fsSL -o "$LD_TOOL" \
    "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
  chmod +x "$LD_TOOL"
fi

if [ ! -f "$GTK_PLUGIN" ]; then
  echo "Downloading linuxdeploy GTK plugin..."
  curl -fsSL -o "$GTK_PLUGIN" \
    "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh"
  chmod +x "$GTK_PLUGIN"
fi

# --- Build the AppImage -------------------------------------------------------
mkdir -p "$OUT_DIR"

# APPIMAGE_EXTRACT_AND_RUN avoids needing FUSE on CI runners.
# The gtk plugin copies libgtk-3, theme engines, gdk-pixbuf loaders, and the
# glib schemas into the AppDir and wires up the matching env vars in AppRun.
export APPIMAGE_EXTRACT_AND_RUN=1
export OUTPUT
PATH="$(pwd):${PATH}" ./"$LD_TOOL" \
  --appdir "$APPDIR" \
  --executable "${APPDIR}/usr/bin/${APP_NAME}" \
  --desktop-file "$DESKTOP_FILE" \
  --icon-file "${APPDIR}/${APP_NAME}.png" \
  --plugin gtk \
  --output appimage

# linuxdeploy writes the AppImage to the repo root; move it to the artifacts dir.
GENERATED=$(ls -t Scrcpy_GUI*-x86_64.AppImage *.AppImage 2>/dev/null \
  | grep -v -E '^(linuxdeploy|appimagetool)' | head -n1)
mv "$GENERATED" "$OUTPUT"

echo "AppImage created:"
ls -lh "$OUTPUT"
