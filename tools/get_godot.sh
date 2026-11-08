#!/usr/bin/env bash
# Downloads the pinned Godot into .godot-bin/ (once) and prints the binary path.
# With --version, prints the pinned version tag instead.
set -euo pipefail
VERSION="4.7.2-stable"
if [ "${1:-}" = "--version" ]; then echo "$VERSION"; exit 0; fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$ROOT/.godot-bin"
BASE="https://github.com/godotengine/godot/releases/download/$VERSION"
case "$(uname -s)" in
  Darwin) ZIP="Godot_v${VERSION}_macos.universal.zip"; EXE="$BIN_DIR/Godot.app/Contents/MacOS/Godot" ;;
  Linux)  ZIP="Godot_v${VERSION}_linux.x86_64.zip";    EXE="$BIN_DIR/Godot_v${VERSION}_linux.x86_64" ;;
  *) echo "get_godot.sh: unsupported OS $(uname -s)" >&2; exit 1 ;;
esac
if [ ! -x "$EXE" ]; then
  mkdir -p "$BIN_DIR"
  # GitHub first; Godot's own download site if GitHub's release files are having a bad day
  V="${VERSION%-*}"; F="${VERSION#*-}"; SLUG="${ZIP#Godot_v${VERSION}_}"
  curl -fsSL --retry 3 --retry-delay 10 -o "$BIN_DIR/$ZIP" "$BASE/$ZIP" \
    || curl -fsSL --retry 3 --retry-delay 10 -o "$BIN_DIR/$ZIP" "https://downloads.godotengine.org/?version=$V&flavor=$F&slug=$SLUG&platform=${SLUG%.zip}"
  unzip -q -o "$BIN_DIR/$ZIP" -d "$BIN_DIR"
  rm "$BIN_DIR/$ZIP"
  chmod +x "$EXE"
fi
echo "$EXE"
