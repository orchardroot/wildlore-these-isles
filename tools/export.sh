#!/usr/bin/env bash
# Exports Mac, Windows and Linux (x86_64) builds into build/. Downloads export templates (about 1 GB) on first run.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/get_godot.sh")"
TAG="$("$ROOT/tools/get_godot.sh" --version)"   # e.g. 4.7.2-stable
TPL_NAME="${TAG/-/.}"                            # e.g. 4.7.2.stable
case "$(uname -s)" in
  Darwin) TPL="$HOME/Library/Application Support/Godot/export_templates/$TPL_NAME" ;;
  *)      TPL="$HOME/.local/share/godot/export_templates/$TPL_NAME" ;;
esac
if [ ! -f "$TPL/version.txt" ]; then
  mkdir -p "$TPL"
  TMP="$(mktemp -d)"
  # GitHub first; Godot's own download site if GitHub's release files are having a bad day
  curl -fsSL --retry 3 --retry-delay 10 -o "$TMP/t.tpz" "https://github.com/godotengine/godot/releases/download/$TAG/Godot_v${TAG}_export_templates.tpz" \
    || curl -fsSL --retry 3 --retry-delay 10 -o "$TMP/t.tpz" "https://downloads.godotengine.org/?version=${TAG%-*}&flavor=${TAG#*-}&slug=export_templates.tpz&platform=templates"
  unzip -q "$TMP/t.tpz" -d "$TMP"
  mv "$TMP"/templates/* "$TPL"/
  rm -rf "$TMP"
fi

cd "$ROOT"
rm -rf build
mkdir -p build/mac build/windows build/linux
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --export-release "macOS" build/mac/Wildlore.zip
"$GODOT" --headless --path . --export-release "Windows" build/windows/Wildlore.exe
"$GODOT" --headless --path . --export-release "Linux" build/linux/Wildlore.x86_64
chmod +x build/linux/Wildlore.x86_64

# The JSON data must be inside the packs, or the game boots empty.
PCK="$(mktemp)"
unzip -p build/mac/Wildlore.zip '*.pck' > "$PCK"
grep -aq '"chart": {' "$PCK" || { echo "export.sh: data missing from mac pck" >&2; exit 1; }
rm -f "$PCK"
grep -aq '"chart": {' build/windows/Wildlore.exe || { echo "export.sh: data missing from windows exe" >&2; exit 1; }

grep -aq '"chart": {' build/linux/Wildlore.x86_64 || { echo "export.sh: data missing from linux build" >&2; exit 1; }

cp build/mac/Wildlore.zip build/Wildlore-mac.zip
(cd build/windows && zip -q -r ../Wildlore-windows.zip .)
(cd build/linux && zip -q -r ../Wildlore-linux.zip .)
ls -la build/*.zip
