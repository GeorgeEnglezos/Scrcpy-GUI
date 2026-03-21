#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cd "$PROJECT_DIR"
if [ "$#" -eq 0 ]; then
  set -- run -d linux
fi

if command -v flatpak-spawn >/dev/null 2>&1; then
  exec flatpak-spawn --host sh -c 'cd "$1" && shift && exec flutter "$@"' sh "$PROJECT_DIR" "$@"
fi

exec flutter "$@"
