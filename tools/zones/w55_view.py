# Print a zone as ASCII with props, NPCs and signs overlaid: python3 tools/zones/w55_view.py <zone> [root]
import json, os, sys
zid = sys.argv[1]
root = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("W55_ROOT") or os.getcwd()
d = json.load(open(os.path.join(root, "data", "zones", zid + ".json"), encoding="utf-8"))
rows = [list(r) for r in d["rows"]]
for p in d.get("props", []):
    if p["type"] != "building":
        rows[p["y"]][p["x"]] = {"oak": "o", "sheep": "s", "bush": "b", "rock": "r", "standing_stone": "I", "slate_heap": "h"}.get(p["type"], "+")
for s in d.get("signs", []):
    rows[s["y"]][s["x"]] = "P" if "plaque" in s else "?"
for n in d.get("npcs", []):
    rows[n["y"]][n["x"]] = "!" if "trainer" in n else "@"
for y, r in enumerate(rows):
    print("%2d %s" % (y, "".join(r)))
print(d["edges"], d["spawn"])
