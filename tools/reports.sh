#!/usr/bin/env bash
# Lists the problems reported in game with the report key (F9), newest first: when, zone, scene or menu, and the note.
# Each report is a folder of shot.png, info.json and save.json (see core/problem_report.gd).
# Usage: tools/reports.sh [count]      (default 20; 0 lists them all)
set -uo pipefail
COUNT="${1:-20}"
# Godot names the user data folder after config/name ("Wildlore"), and project.godot sets no custom one.
case "$(uname -s)" in
  Darwin) DATA="$HOME/Library/Application Support/Godot/app_userdata/Wildlore" ;;
  *)      DATA="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Wildlore" ;;
esac
DIR="$DATA/reports"
echo "Reports: $DIR"
if [ ! -d "$DIR" ]; then
  echo "(none yet: press F9 in the game)"
  exit 0
fi
python3 - "$DIR" "$COUNT" <<'EOF'
import json, os, sys
root, count = sys.argv[1], int(sys.argv[2])
names = sorted((n for n in os.listdir(root) if os.path.isdir(os.path.join(root, n))), reverse=True)
if count > 0:
    names = names[:count]
if not names:
    print("(none yet: press F9 in the game)")
for n in names:
    try:
        with open(os.path.join(root, n, "info.json")) as f:
            i = json.load(f)
    except (OSError, ValueError):
        print(f"{n}  (no readable info.json)")
        continue
    where = i.get("zone") or "-"
    tile = i.get("tile")
    if isinstance(tile, list) and len(tile) == 2:
        where += f" @{tile[0]},{tile[1]}"
    menus = i.get("menus") or []
    scene = os.path.splitext(os.path.basename(i.get("scene") or ""))[0] or "-"
    shown = "menu " + " > ".join(menus) if menus else scene
    if i.get("battle"):
        foes = ", ".join(c.get("species", "?") for c in i["battle"].get("foe", []) if c.get("out"))
        shown = f"battle vs {foes}" + (f" ({shown})" if menus else "")
    note = i.get("note") or ""
    print(f"{n}  {where:<24} {shown:<28} {note}")
    print(f"    {os.path.join(root, n)}")
EOF
