# Shared helpers for the wave 55 roads (England and the two borders): new route zones that join existing places.
# Run a route script from the repo root, e.g. `python3 tools/zones/w55_england.py pendle`. Each route writes its zone,
# dialogue and trainers, cuts a gap in the zones it joins (cut_gap), adds its places to data/world_map.json and its
# points of interest and field spots to data/poi/w55_england.json and data/field_spots/w55_england.json. Idempotent.
import sys, os, json, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ie_common import *          # Z, DLG, TRN, say, chat, script, path, wild, scatter_props, blob, hills, finish
from wcommon import _stand

ROOT = os.environ.get("W55_ROOT") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "zones")
WALK_CH = set(".,#=:sf_D|+&w")
SOLID_FILL = set("TPHWFRB^~o$x!C")

PLAQUES = {}


def plaque(z, x, y, pid, title, text):
    """a heritage plaque for the Gazetteer; ids are unique across the game (ours start w55e_)."""
    _stand(z, x, y)
    z.d["signs"].append({"x": x, "y": y, "text": text, "plaque": pid, "title": title})


def sign(z, x, y, text):
    _stand(z, x, y)
    z.d["signs"].append({"x": x, "y": y, "text": text})


def tr(z, tid, name, cls, sprite, party, x, y, facing, intro, win, after, money, floor, move="still"):
    """a trainer, scaled with the story from `floor` (the par of the places the road joins)."""
    trainer(z, tid, name, cls, sprite, party, x, y, facing, intro, win, after, money, move)
    TRN[tid]["scaled_floor"] = floor


def gate_npcs(z, base_id, x, y, count, axis, flag, who, sprite, lines, facing, move="still"):
    """A line of `count` standing people across the road, gone once `flag` is set (the story's own gate flag)."""
    for i in range(count):
        gx, gy = (x + i, y) if axis == "x" else (x, y + i)
        _stand(z, gx, gy)
        z.npc(id="%s_%d" % (base_id, i), sprite=sprite, x=gx, y=gy, facing=facing, move=move, script=base_id, name=who,
              hide_if=flag)
    script(z.d["id"], base_id, say(who, *lines))


def gate_wall(z, axis, pos, gap_lo, gap_hi, ch="H", border=3):
    """A hedge bank right across the zone (a column x = pos for axis 'x', a row y = pos for axis 'y'), with one gap of
    tiles gap_lo..gap_hi where the road goes; gate_npcs() then stands in the gap. Nothing can walk round it."""
    if axis == "x":
        for y in range(border, z.h - border):
            if not (gap_lo <= y <= gap_hi):
                z.set(pos, y, ch)
    else:
        for x in range(border, z.w - border):
            if not (gap_lo <= x <= gap_hi):
                z.set(x, pos, ch)
    z.d["props"] = [p for p in z.d["props"] if p["type"] == "building" or not (
        (axis == "x" and p["x"] == pos) or (axis == "y" and p["y"] == pos))]


def route_zone(zid, name, w, h, region, music, stage, floor, weather, fill="."):
    z = Z(zid, name, w, h, kind="route", region=region, music=music, weather=weather)
    z.d["stage"] = stage
    z.d["scaled_floor"] = floor
    z.rect(0, 0, w, h, fill)
    return z


def smooth_heights(z, passes=30):
    """walkable neighbours differ by at most one level."""
    for _ in range(passes):
        ch = False
        for y in range(z.h):
            for x in range(z.w):
                for dx, dy in ((1, 0), (0, 1)):
                    xx, yy = x + dx, y + dy
                    if xx < z.w and yy < z.h and z.g[y][x] not in SOLID_FILL and z.g[yy][xx] not in SOLID_FILL:
                        a, b = z.hg[y][x], z.hg[yy][xx]
                        if a - b > 1:
                            z.hg[y][x] = b + 1; ch = True
                        elif b - a > 1:
                            z.hg[yy][xx] = a + 1; ch = True
        if not ch:
            break


# ------------------------------------------------------------------ checks on a zone we have just laid out
def tiles_ok(z, legend_walk=None):
    """walkable (for our flood) char set for this zone."""
    ws = set(WALK_CH)
    for ch, spec in z.legend.items():
        if spec.get("tile") in ("grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "floor_wood"):
            ws.add(ch)
        else:
            ws.discard(ch)
    return ws


def flood(z, start):
    ws = tiles_ok(z)
    blocked = {(p["x"], p["y"]) for p in z.d["props"] if p["type"] != "building"}
    blocked |= {(s["x"], s["y"]) for s in z.d["signs"]}
    blocked |= {(n["x"], n["y"]) for n in z.d["npcs"] if "hide_if" not in n}   # a gate is only closed for a while
    seen = {start}
    q = [start]
    while q:
        x, y = q.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if (nx, ny) in seen or not (0 <= nx < z.w and 0 <= ny < z.h):
                continue
            if z.g[ny][nx] in ws and (nx, ny) not in blocked:
                seen.add((nx, ny)); q.append((nx, ny))
    return seen


def check_route(z, entries):
    """Both gaps joined to the spawn, every trainer, NPC, sign, plaque reachable (a walkable neighbour is reachable)."""
    reach = flood(z, tuple(z.d["spawn"]))
    probs = []
    for (ex, ey) in entries:
        if (ex, ey) not in reach:
            probs.append("entry %d,%d not reachable from spawn" % (ex, ey))
    ws = tiles_ok(z)
    things = [("npc " + n["id"], n["x"], n["y"]) for n in z.d["npcs"]] + [("sign %d,%d" % (s["x"], s["y"]), s["x"], s["y"]) for s in z.d["signs"]]
    for what, x, y in things:
        if not any((x + dx, y + dy) in reach for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            probs.append("%s at %d,%d cannot be walked up to" % (what, x, y))
    return probs


# ------------------------------------------------------------------ cutting a gap in an existing zone
def _load(zid):
    return json.load(open(os.path.join(OUT, zid + ".json")))


def _save(zid, d):
    json.dump(d, open(os.path.join(OUT, zid + ".json"), "w"), indent=1)


def _walk_chars(d):
    ws = set(WALK_CH) | set("%*/")   # bramble, bog, scree: crossable by a field ability, not solid scenery
    for ch, spec in d.get("legend_extra", {}).items():
        t = spec.get("tile")
        if t in ("grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "floor_wood", "floor_tile"):
            ws.add(ch)
        else:
            ws.discard(ch)
    return ws


def _reachable(d):
    ws = _walk_chars(d)
    rows = d["rows"]
    H, W = len(rows), len(rows[0])
    blocked = {(p["x"], p["y"]) for p in d.get("props", []) if p["type"] != "building" and not p.get("walk")}
    blocked |= {(s["x"], s["y"]) for s in d.get("signs", [])}
    start = tuple(d["spawn"])
    seen = {start}
    q = [start]
    while q:
        x, y = q.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in seen and rows[ny][nx] in ws and (nx, ny) not in blocked:
                seen.add((nx, ny)); q.append((nx, ny))
    return seen


def plan_gap(zid, side, want=None, width=3, max_depth=26, water_ok=False):
    """Find where to cut a `width`-wide gap through the border of `side` of zone zid: the position along the border
    (x for north/south, y for east/west) with the shortest cut from the border to land the spawn can reach.
    Returns (at, depth). `want` is a preferred position; otherwise the middle of the side."""
    d = _load(zid)
    rows = d["rows"]
    H, W = len(rows), len(rows[0])
    ws = _walk_chars(d)
    reach = _reachable(d)
    horiz = side in ("north", "south")
    length = W if horiz else H
    mid = want if want is not None else length // 2
    cands = sorted(range(2, length - 2), key=lambda a: abs(a - mid))
    occupied = {(p["x"], p["y"]) for p in d.get("props", []) if p["type"] != "building"}
    occupied |= {(s["x"], s["y"]) for s in d.get("signs", [])}
    occupied |= {(n["x"], n["y"]) for n in d.get("npcs", [])}
    occupied |= {(w["x"], w["y"]) for w in d.get("warps", [])}
    best = None
    for a in cands:
        cut = []
        ok = False
        for depth in range(max_depth):
            tiles = []
            for k in range(-(width // 2), width // 2 + 1):
                if side == "north":
                    t = (a + k, depth)
                elif side == "south":
                    t = (a + k, H - 1 - depth)
                elif side == "west":
                    t = (depth, a + k)
                else:
                    t = (W - 1 - depth, a + k)
                tiles.append(t)
            mids = tiles[width // 2]
            if mids in reach:
                ok = True
                break
            bad = False
            for t in tiles:
                ch = rows[t[1]][t[0]]
                if ch in ("BD^L" if water_ok else "BoD~$^L") or t in occupied:
                    bad = True
            if bad:
                break
            cut.extend(tiles)
        if ok and cut:
            score = len(cut) // width + abs(a - mid) * 0.25
            if best is None or score < best[0]:
                best = (score, a, cut)
            if abs(a - mid) > 14 and best is not None:
                break
    if best is None:
        raise SystemExit("no gap found in %s %s" % (zid, side))
    return best[1], best[2]


def _patch_block(lines, key, changes):
    """Rewrite single-line string rows of the "key": [ ... ] block at the given row indexes."""
    start = next(i for i, l in enumerate(lines) if l.startswith(' "%s": [' % key))
    for y, new in changes.items():
        old = lines[start + 1 + y]
        assert old.startswith('  "'), old
        tail = old[old.rindex('"') + 1:]
        lines[start + 1 + y] = '  "' + new + '"' + tail


def cut_gap(zid, side, at, cut, other, offset, path_char="#"):
    """Carve `cut` tiles as path and put an edge `side` -> other with `offset` on zone zid, editing the file's own
    text (rows, heights, edges) so that nothing else about its formatting moves. Idempotent."""
    path = os.path.join(OUT, zid + ".json")
    text = open(path, encoding="utf-8").read()
    d = json.loads(text)
    rows = [list(r) for r in d["rows"]]
    legend = d.get("legend_extra", {})
    pc = path_char
    if pc in legend and legend[pc].get("tile") not in ("path", "road", "cobbles"):
        for ch, spec in legend.items():
            if spec.get("tile") == "path":
                pc = ch
                break
    heights = [list(r) for r in d["heights"]] if d.get("heights") else None
    hh = None
    if heights:
        x, y = cut[-2]
        jx, jy = {"north": (x, y + 1), "south": (x, y - 1), "west": (x + 1, y), "east": (x - 1, y)}[side]
        hh = heights[jy][jx]
    row_changes, h_changes = {}, {}
    for (x, y) in cut:
        rows[y][x] = pc
        row_changes[y] = "".join(rows[y])
        if heights:
            heights[y][x] = hh
            h_changes[y] = "".join(heights[y])
    lines = text.split("\n")
    _patch_block(lines, "rows", row_changes)
    if heights:
        _patch_block(lines, "heights", h_changes)
    # edges: add the new entry before the block's closing brace
    i = next(k for k, l in enumerate(lines) if l.startswith(' "edges": {'))
    if lines[i].rstrip().endswith("{},") or lines[i].rstrip().endswith("{}"):
        comma = "," if lines[i].rstrip().endswith(",") else ""
        lines[i:i + 1] = [' "edges": {', '  "%s": {' % side, '   "to": "%s",' % other, '   "offset": %d' % offset, '  }', ' }' + comma]
    else:
        j = i + 1
        while not (lines[j] == " }," or lines[j] == " }"):
            j += 1
        assert lines[j - 1] == "  }", lines[j - 1]
        lines[j - 1] = "  },"
        lines[j:j] = ['  "%s": {' % side, '   "to": "%s",' % other, '   "offset": %d' % offset, '  }']
    open(path, "w", encoding="utf-8").write("\n".join(lines))
    chk = json.loads("\n".join(lines))
    assert chk["edges"][side] == {"to": other, "offset": offset}


# ------------------------------------------------------------------ the world map
def add_place(zid, x, y):
    path = os.path.join(ROOT, "data", "world_map.json")
    t = open(path, encoding="utf-8").read()
    i = t.index('"places": {')
    j = t.index("}}", i)  # end of the last place entry
    if '"%s": {' % zid in t[i:j + 2]:
        return
    t = t[:j + 1] + ', "%s": {"x": %d, "y": %d}' % (zid, x, y) + t[j + 1:]
    open(path, "w", encoding="utf-8").write(t)


# ------------------------------------------------------------------ poi and field spots
def add_data(kind, entries, key=None):
    """kind 'poi' ({"pois": [...]}) or 'field_spots' (a list): replace entries whose id we own, keep the rest."""
    path = os.path.join(ROOT, "data", kind, "w55_england.json")
    cur = None
    if os.path.exists(path):
        cur = json.load(open(path))
    if kind == "poi":
        lst = (cur or {"pois": []})["pois"]
    else:
        lst = cur or []
    ids = {e["id"] for e in entries}
    lst = [e for e in lst if e["id"] not in ids] + entries
    json.dump({"pois": lst} if kind == "poi" else lst, open(path, "w"), indent=1)


def poi(zone, pid, near, kind, **kw):
    """a point of interest (core/poi.gd): kind den | camp | stone | cache. `at` defaults to the zone."""
    e = {"id": "poi_" + pid, "zone": zone, "near": list(near), "kind": kind, "at": zone}
    e.update(kw)
    return e


def fspot(zone, sid, x, y, field, prop, text, reward):
    """a field spot (core/field_spots.gd): a creature that knows the matching party piece can deal with it."""
    return {"id": "fs_" + sid, "zone": zone, "x": x, "y": y, "field": field, "prop": prop, "text": text,
            "reward": reward, "flag": "field_" + sid, "at": zone}


def scenery(z, seed, bushes=30, rocks=16, trees=0, tree="oak", ground=(".", "g", "m"), rock_ground=None, x=3, y=3, w=None, h=None):
    """loose props on free ground (never on a road or path tile)."""
    w = w if w is not None else z.w - 2 * x
    h = h if h is not None else z.h - 2 * y
    if bushes:
        scatter_props(z, "bush", x, y, w, h, bushes, seed, avoid=ground)
    if rocks:
        scatter_props(z, "rock", x, y, w, h, rocks, seed + 1, avoid=rock_ground or ground)
    if trees:
        scatter_props(z, tree, x, y, w, h, trees, seed + 2, avoid=ground)


def flush_all():
    """dialogue per zone, trainers one file each (scaled_floor already set)."""
    write_all(OUT)


OPP = {"north": "south", "south": "north", "east": "west", "west": "east"}


def link(existing, side, rid, rc, water_ok=False, want=None, width=3):
    """Join zone `existing` (on its `side`) to our route rid, whose gap on the opposite side is centred at `rc`.
    Cuts the gap in `existing` (once) and returns the offset for the route's own edge back to it."""
    d = _load(existing)
    e = d["edges"].get(side)
    if e is not None and e["to"] != rid:
        raise SystemExit("%s already has a %s edge to %s" % (existing, side, e["to"]))
    if e is not None:
        at = rc - int(e["offset"])
    else:
        at, cut = plan_gap(existing, side, want, width=width, water_ok=water_ok)
        cut_gap(existing, side, at, cut, rid, rc - at)
    return at - rc


def road(z, pts, ch="#", w=3):
    """a w-wide road through axis-aligned points, centred on the line."""
    o = w // 2
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        z.rect(min(x1, x2) - o, min(y1, y2) - o, abs(x2 - x1) + w, abs(y2 - y1) + w, ch)


def ell(z, cx, cy, rx, ry, ch, only=None):
    for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if 0 <= xx < z.w and 0 <= yy < z.h and ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1:
                if only is None or z.g[yy][xx] in only:
                    z.g[yy][xx] = ch


def pond(z, cx, cy, rx, ry, shore="s", on=".,fTPgmqc"):
    """a pond: deep water, a ring of shallows, a shore of `shore` (reeds, sand)."""
    ell(z, cx, cy, rx + 1.6, ry + 1.4, shore, only=on)
    ell(z, cx, cy, rx + 0.6, ry + 0.5, "w", only=on + shore)
    ell(z, cx, cy, rx - 0.6, ry - 0.6, "~")


def hedge_line(z, x0, y0, x1, y1, ch="H", gaps=()):
    for x in range(min(x0, x1), max(x0, x1) + 1):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            if (x, y) not in gaps and z.g[y][x] not in "#=":
                z.set(x, y, ch)


def finish_zone(z, name):
    finish(z)
    smooth_heights(z)
    z.save(os.path.join(OUT, name + ".json"))
