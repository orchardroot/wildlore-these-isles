"""Wave 55 integration: put a story gate across a new route in place (a hedge bank with Wardens in its gap), without
re-running the route's generator (the fact pass edited the zone text by hand).
Usage: python3 tools/zones/w55_gate.py <zone> <x|y> <pos> <gap_lo> <gap_hi> <flag> <npc_base> <facing> "<line 1>" "<line 2>" """
import json, sys

def dump(p, d, raw):
    for ea in (False, True):
        for tail in ("\n", ""):
            if json.dumps(json.loads(raw), indent=1, ensure_ascii=ea) + tail == raw:
                open(p, "w").write(json.dumps(d, indent=1, ensure_ascii=ea) + tail)
                return
    raise SystemExit("unknown JSON format: " + p)

zid, axis, pos, lo, hi, flag, base, facing = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), sys.argv[6], sys.argv[7], sys.argv[8]
lines = sys.argv[9:]
p = "data/zones/%s.json" % zid
raw = open(p).read(); d = json.loads(raw)
rows = [list(r) for r in d["rows"]]
h, w = len(rows), len(rows[0])
if axis == "y":
    for x in range(3, w - 3):
        if not lo <= x <= hi:
            rows[pos][x] = "H"
else:
    for y in range(3, h - 3):
        if not lo <= y <= hi:
            rows[y][pos] = "H"
d["rows"] = ["".join(r) for r in rows]
on = (lambda q: q.get("y") == pos) if axis == "y" else (lambda q: q.get("x") == pos)
d["props"] = [q for q in d["props"] if q.get("type") == "building" or not on(q)]
d["npcs"] = [n for n in d["npcs"] if not n["id"].startswith(base + "_")]
for i in range(hi - lo + 1):
    x, y = (lo + i, pos) if axis == "y" else (pos, lo + i)
    d["npcs"].append({"id": "%s_%d" % (base, i), "sprite": "warden_grunt", "x": x, "y": y, "facing": facing, "move": "still",
                      "script": base, "name": "Warden", "hide_if": flag})
dump(p, d, raw)
p = "data/dialogue/%s.json" % zid
raw = open(p).read(); d = json.loads(raw)
d[base] = [{"do": "say", "who": "Warden", "text": t} for t in lines]
dump(p, d, raw)
print("gated", zid, axis, pos, flag)
