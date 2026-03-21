#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cd "$PROJECT_DIR"

if [ "${1:-}" = "--release" ]; then
  # Mirror the full CI Linux release flow:
  # 1. flutter pub get
  # 2. flutter build linux --release
  # 3. package into artifacts/linux_package/ (same script as CI)
  "$PROJECT_DIR"/flutter_host.sh pub get
  "$PROJECT_DIR"/flutter_host.sh build linux --release
  bash "$PROJECT_DIR/package_linux.sh"
  echo ""
  echo "Artifacts ready at: $PROJECT_DIR/artifacts/linux_package/"
else
  # Debug build + run (development mode)
  "$PROJECT_DIR"/flutter_host.sh build linux --debug

  BUNDLE_DIR=$(find "$PROJECT_DIR/build/linux" -type d -path '*/debug/bundle' | head -n 1)
  if [ -z "$BUNDLE_DIR" ]; then
    echo "Could not find the Linux debug bundle under build/linux" >&2
    exit 1
  fi

  if command -v flatpak-spawn >/dev/null 2>&1; then
    exec flatpak-spawn --host sh -c 'cd "$1" && exec ./scrcpy_gui_prod' sh "$BUNDLE_DIR"
  fi

  exec sh -c 'cd "$1" && exec ./scrcpy_gui_prod' sh "$BUNDLE_DIR"
fi
