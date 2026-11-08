#!/usr/bin/env bash
# Imports the project, then runs the unit tests. Fails on any failed test or script error.
# Usage: tools/test.sh [filter]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/get_godot.sh")" || exit 1
cd "$ROOT"
# one import at a time across worktrees: parallel full-project scans thrash the disk
LOCK="${TMPDIR:-/tmp}/wildlore_import.lock"
until mkdir "$LOCK" 2>/dev/null; do
	[ -n "$(find "$LOCK" -maxdepth 0 -mmin +15 2>/dev/null)" ] && rmdir "$LOCK" 2>/dev/null
	sleep 2
done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
"$GODOT" --headless --path . --import >/dev/null 2>&1
rmdir "$LOCK" 2>/dev/null

LOG="$(mktemp)"
"$GODOT" --headless --path . -s res://tests/run_tests.gd -- "${1:-}" 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
  echo "test.sh: script errors in the log, failing" >&2
  STATUS=1
fi
rm -f "$LOG"
"$GODOT" --headless --path . -s res://tools/validate.gd || STATUS=1
exit "$STATUS"
