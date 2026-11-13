# Wave 55 roads-celtic: shared helpers for the new routes in Wales, Ireland and Northern Ireland.
#
# A route joins two existing zones. For each end `open_gap()` cuts a three-wide path through the border of the existing
# zone (only the tiles that change, written back as text so the rest of the file is untouched) and adds the edge, and
# the new zone has the matching gap and the matching edge. Gated routes put three Wardens across the gap nearest the
# end that opens earlier, hidden once the same flag the existing gate uses is set (see data/dialogue/llanberis.json,
# gate_cambrian), so the new road never opens a place earlier than the story does.
#
# Run from the repo root:  python3 tools/zones/w55_celtic.py            (every route)
#                          python3 tools/zones/w55_celtic.py beddgelert  (one)
import json, os, re, sys, random, glob
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from wcommon import *   # Z, say, chat, script, trainer, wild, scatter_props, clear_prop, DLG, TRN, path
ROOT = os.path.dirname(os.path.dirname(HERE))
ZD = os.path.join(ROOT, "data", "zones")

WALK = set(".,#=:sfwD|+_&")
OPP = {"north": "south", "south": "north", "east": "west", "west": "east"}
VEC = {"north": (0, -1), "south": (0, 1), "east": (1, 0), "west": (-1, 0)}


# ------------------------------------------------------------------ species and items
def _species_ids():
    out = set()
    for f in glob.glob(os.path.join(ROOT, "data", "creatures", "*.json")):
        d = json.load(open(f))
        if isinstance(d, dict):
            if "base" in d and "id" in d:
                out.add(d["id"])
            for s in d.get("species", []):
                if "id" in s:
                    out.add(s["id"])
    return out

SPECIES = _species_ids()

def need_species(*ids):
    bad = [i for i in ids if i not in SPECIES]
    assert not bad, "unknown species: %s" % bad


def _items():
    out = {}
    def walk(x):
        if isinstance(x, dict):
            if "id" in x and "name" in x and isinstance(x["id"], str):
                out[x["id"]] = x["name"]
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    for f in glob.glob(os.path.join(ROOT, "data", "items", "*.json")):
        walk(json.load(open(f)))
    return out

ITEMS = _items()

def item_name(i):
    assert i in ITEMS, "unknown item " + i
    return ITEMS[i]


# ------------------------------------------------------------------ the existing zones
def zpath(zid):
    return os.path.join(ZD, zid + ".json")

def zload(zid):
    return json.load(open(zpath(zid)))

def tile_char_walkable(d, c):
    le = d.get("legend_extra", {})
    if c in le:
        return le[c].get("tile", "") in ("grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "door", "floor_wood", "floor_tile", "platform", "level_crossing")
    return c in WALK

def reach(d, start=None, extra=()):
    rows = d["rows"]
    w, h = len(rows[0]), len(rows)
    hts = d.get("heights")
    sx, sy = start or d["spawn"]
    sx, sy = int(sx), int(sy)
    seen = {(sx, sy)}
    q = [(sx, sy)]
    blocked = set(extra)
    while q:
        x, y = q.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and (nx, ny) not in blocked and tile_char_walkable(d, rows[ny][nx]):
                if hts and abs(int(hts[ny][nx]) - int(hts[y][x])) > 1:
                    continue
                seen.add((nx, ny))
                q.append((nx, ny))
    return seen

def border_tiles(d, side):
    rows = d["rows"]
    w, h = len(rows[0]), len(rows)
    if side == "north":
        return [(x, 0) for x in range(w)]
    if side == "south":
        return [(x, h - 1) for x in range(w)]
    if side == "west":
        return [(0, y) for y in range(h)]
    return [(w - 1, y) for y in range(h)]

def _text_block(lines, key, n):
    """index of the first of the n lines of the list under `"key": [`."""
    for i, l in enumerate(lines):
        if l.strip().startswith('"%s": [' % key) and l.strip() == '"%s": [' % key:
            return i + 1
    raise SystemExit("no multi-line %s block" % key)

def _replace_lines(lines, key, new):
    i0 = _text_block(lines, key, len(new))
    for k, row in enumerate(new):
        l = lines[i0 + k]
        m = re.match(r'^(\s*)"[^"]*"(,?)\s*$', l)
        assert m, "unexpected %s line %r" % (key, l)
        lines[i0 + k] = '%s"%s"%s' % (m.group(1), row, m.group(2))

def open_gap(zid, side, at, to, width=3):
    """Cut a `width`-wide path through the `side` border of existing zone `zid` at position `at` (x for north and south,
    y for east and west) inward to the first reachable land, and add the edge to `to` (offset 0). Idempotent."""
    p = zpath(zid)
    text = open(p).read()
    d = json.loads(text)
    if side in d["edges"]:
        assert d["edges"][side]["to"] == to, "%s already has a %s edge to %s" % (zid, side, d["edges"][side]["to"])
        return
    rows = [list(r) for r in d["rows"]]
    hts = [list(r) for r in d["heights"]] if d.get("heights") else None
    w, h = len(rows[0]), len(rows)
    R = reach(d)
    vx, vy = VEC[side]
    ix, iy = -vx, -vy    # inward
    lo = at - width // 2
    band = list(range(lo, lo + width))
    cut = []
    land_h = None
    depth = 0
    while depth < 40:
        tiles = []
        for b in band:
            if side in ("north", "south"):
                x = b
                y = 0 if side == "north" else h - 1
                y += iy * depth
            else:
                y = b
                x = 0 if side == "west" else w - 1
                x += ix * depth
            tiles.append((x, y))
        hit = [t for t in tiles if t in R]
        if hit:
            land_h = int(hts[hit[0][1]][hit[0][0]]) if hts else None
            # tidy the last row too, so the path joins the land with no tree stuck in it
            for t in tiles:
                if t not in R:
                    cut.append(t)
            break
        cut.extend(tiles)
        depth += 1
    else:
        raise SystemExit("%s: no land within 40 tiles of the %s border at %d" % (zid, side, at))
    # nothing standing on the cut
    taken = {(int(n["x"]), int(n["y"])) for n in d["npcs"]} | {(int(s["x"]), int(s["y"])) for s in d["signs"]} | {(int(w_["x"]), int(w_["y"])) for w_ in d["warps"]}
    for pr in d["props"]:
        if pr.get("type") == "building":
            for yy in range(int(pr["y"]), int(pr["y"]) + int(pr["h"])):
                for xx in range(int(pr["x"]), int(pr["x"]) + int(pr["w"])):
                    taken.add((xx, yy))
        else:
            taken.add((int(pr["x"]), int(pr["y"])))
    clash = [t for t in cut if t in taken]
    assert not clash, "%s: the new gap runs over %s" % (zid, clash)
    for (x, y) in cut:
        rows[y][x] = "#"
        if hts is not None and land_h is not None:
            hts[y][x] = str(land_h)
    # an edge turns every walkable tile on that border into an exit, so close any other one (a strip of sand along the map
    # edge, say) with a tree: only the new gap leads on
    gap_border = {t for t in cut if t in set(border_tiles(d, side))}
    for t in border_tiles(d, side):
        x, y = t
        if t not in gap_border and t not in taken and tile_char_walkable(d, rows[y][x]):
            rows[y][x] = "T"
    new_rows = ["".join(r) for r in rows]
    lines = text.split("\n")
    _replace_lines(lines, "rows", new_rows)
    if hts is not None:
        _replace_lines(lines, "heights", ["".join(r) for r in hts])
    text = "\n".join(lines)
    text = _add_edge(text, side, to)
    open(p, "w").write(text)
    d2 = json.loads(text)
    assert d2["edges"][side]["to"] == to
    return cut

def _add_edge(text, side, to):
    i = text.index('"edges": {')
    j = text.index("{", i)
    depth = 0
    k = j
    while True:
        if text[k] == "{":
            depth += 1
        elif text[k] == "}":
            depth -= 1
            if depth == 0:
                break
        k += 1
    block = text[j:k + 1]
    edges = json.loads(block)
    edges[side] = {"to": to, "offset": 0}
    if "\n" in block:
        s = json.dumps(edges, indent=1, ensure_ascii=False)
        s = s.replace("\n", "\n ")
    else:
        s = json.dumps(edges, ensure_ascii=False)
    return text[:j] + s + text[k + 1:]


# ------------------------------------------------------------------ new routes
def route(zid, name, w, h, region, music, stage, floor, weather, edges, base=".", border="T", thick=3):
    """A new route zone. `edges` = {side: (to, at)}: a three-wide gap at position `at` on that side."""
    z = Z(zid, name, w, h, fill=base, kind="route", region=region, music=music, weather=weather)
    z.d["stage"] = stage
    if floor:
        z.d["scaled_floor"] = floor
    z.rect(0, 0, w, h, base)
    gaps = []
    for side, (to, at) in edges.items():
        z.d["edges"][side] = {"to": to, "offset": 0}
        lo = at - 1
        if side == "north":
            gaps.append((lo, 0, 3, thick))
        elif side == "south":
            gaps.append((lo, h - thick, 3, thick))
        elif side == "west":
            gaps.append((0, lo, thick, 3))
        else:
            gaps.append((w - thick, lo, thick, 3))
    z.border(border, thick)
    z.gaps = gaps
    z.edge_def = edges
    return z

def trainer2(z, tid, name, cls, sprite, party, x, y, facing, intro, win, after, floor, move="still"):
    """A trainer whose party lifts with the story like the zone does (scaled_floor). Money is by the top level."""
    need_species(*[p[0] for p in party])
    top = max(l for _, l in party)
    money = int(round(top * top / 1.55 / 10.0)) * 10
    trainer(z, tid, name, cls, sprite, party, x, y, facing, intro, win, after, money, move)
    if floor:
        TRN[tid]["scaled_floor"] = floor

def wild2(z, rows, name="grass"):
    need_species(*[r[0] for r in rows])
    assert len(rows) >= 6 or name != "grass", "six or more grass encounters"
    wild(z, rows, name)

def finish_borders(z, ch="#"):
    """Put the path through each gap (run once the scenery is down, so trees never close a gap)."""
    for (x, y, gw, gh) in z.gaps:
        z.rect(x, y, gw, gh, ch)

def gate(z, side, at, flag, who, lines, name="gate"):
    """Three Wardens across the gap on `side`, one tile in from the edge tile, hidden once `flag` is set."""
    sid = "gate_" + z.d["id"]
    w, h = z.w, z.h
    if side == "north":
        pos = [(at + k, 1) for k in (-1, 0, 1)]
    elif side == "south":
        pos = [(at + k, h - 2) for k in (-1, 0, 1)]
    elif side == "west":
        pos = [(1, at + k) for k in (-1, 0, 1)]
    else:
        pos = [(w - 2, at + k) for k in (-1, 0, 1)]
    for k, (x, y) in enumerate(pos):
        z.d["npcs"].append({"id": "%s_%s" % (sid, "abc"[k]), "sprite": "warden_grunt", "x": x, "y": y, "facing": {"north": "up", "south": "down", "west": "left", "east": "right"}[side],
                            "move": "still", "name": "Warden", "script": sid, "hide_if": flag})
    DLG.setdefault(z.d["id"], {})[sid] = say("Warden", *lines)
    for (x, y) in pos:
        z.set(x, y, "#")

def plaque(z, x, y, pid, title, text):
    z.d["signs"].append({"x": x, "y": y, "plaque": pid, "title": title, "text": text})

def sign(z, x, y, text, local=None):
    s = {"x": x, "y": y, "text": text}
    if local:
        s["local"] = local
    z.d["signs"].append(s)

def blob(z, cx, cy, rx, ry, ch, only=None, seed=0, wobble=0.25):
    r = random.Random(seed)
    for y in range(max(0, cy - ry - 1), min(z.h, cy + ry + 2)):
        for x in range(max(0, cx - rx - 1), min(z.w, cx + rx + 2)):
            dd = ((x - cx) / max(rx, 0.5)) ** 2 + ((y - cy) / max(ry, 0.5)) ** 2
            if dd <= 1.0 + (r.random() - 0.5) * wobble:
                if only is None or z.g[y][x] in only:
                    z.g[y][x] = ch

def river(z, x0, y0, y1, width=3, amp=2.0, period=18.0, phase=0.0, bank="r", water="~"):
    """A river running north to south from (x0, y0) to y1, meandering, with a reedy shallow bank each side."""
    import math
    for y in range(y0, y1):
        cx = int(round(x0 + amp * math.sin(phase + (y - y0) * 2 * math.pi / period)))
        for x in range(cx - width // 2, cx - width // 2 + width):
            if 0 <= x < z.w:
                z.g[y][x] = water
        for x in (cx - width // 2 - 1, cx - width // 2 + width):
            if 0 <= x < z.w and z.g[y][x] != water and bank:
                z.g[y][x] = bank

def river_h(z, y0, x0, x1, width=3, amp=2.0, period=18.0, phase=0.0, bank="r", water="~"):
    """The same running west to east."""
    import math
    for x in range(x0, x1):
        cy = int(round(y0 + amp * math.sin(phase + (x - x0) * 2 * math.pi / period)))
        for y in range(cy - width // 2, cy - width // 2 + width):
            if 0 <= y < z.h:
                z.g[y][x] = water
        for y in (cy - width // 2 - 1, cy - width // 2 + width):
            if 0 <= y < z.h and z.g[y][x] != water and bank:
                z.g[y][x] = bank

def bridge(z, x, y, w, h, deck="=", rail="W"):
    """A bridge deck of size w by h (spanning along its long side) with a parapet on the two long sides."""
    z.rect(x, y, w, h, deck)
    if w >= h:
        z.rect(x, y - 1, w, 1, rail); z.rect(x, y + h, w, 1, rail)
        z.rect(x, y, w, h, deck)
    else:
        z.rect(x - 1, y, 1, h, rail); z.rect(x + w, y, 1, h, rail)
        z.rect(x, y, w, h, deck)

def poly(z, pts, ch="=", w=3):
    """A road of width w through axis-aligned corner points: every segment shares an x or a y with the next point."""
    h = w // 2
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        assert x1 == x2 or y1 == y2, "poly needs axis-aligned points: %s %s" % ((x1, y1), (x2, y2))
        z.rect(min(x1, x2) - h, min(y1, y2) - h, abs(x2 - x1) + w, abs(y2 - y1) + w, ch)

def trail(z, pts, ch="#", w=2, jitter=0, seed=0):
    """A path through waypoints (axis-aligned dog-legs between them), `w` wide."""
    r = random.Random(seed)
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        mx = x2 if r.random() < 0.5 else x1
        for (a, b), (c, d_) in (((x1, y1), (mx, y1 if mx == x2 else y2)), ((mx, y1 if mx == x2 else y2), (x2, y2))):
            z.rect(min(a, c), min(b, d_), abs(c - a) + w, abs(d_ - b) + w, ch)

def reach_new(z):
    d = {"rows": ["".join(r) for r in z.g], "spawn": z.d["spawn"], "legend_extra": z.legend}
    if any(any(v for v in r) for r in z.hg):
        d["heights"] = ["".join(str(v) for v in r) for r in z.hg]
    return reach(d)

def check_route(z):
    """The validator's basics, early: spawn, gaps, NPCs, signs, buildings."""
    d = {"rows": ["".join(r) for r in z.g], "spawn": z.d["spawn"], "legend_extra": z.legend}
    if any(any(v for v in r) for r in z.hg):
        d["heights"] = ["".join(str(v) for v in r) for r in z.hg]
    zid = z.d["id"]
    assert tile_char_walkable(d, z.g[z.d["spawn"][1]][z.d["spawn"][0]]), zid + ": spawn not walkable"
    R = reach(d)
    for side, (to, at) in z.edge_def.items():
        for b in range(at - 1, at + 2):
            t = {"north": (b, 0), "south": (b, z.h - 1), "west": (0, b), "east": (z.w - 1, b)}[side]
            assert t in R, "%s: the %s gap tile %s is not reachable from the spawn" % (zid, side, t)
    for side, (to, at) in z.edge_def.items():
        for (x, y) in border_tiles(d, side):
            gap = (at - 1 <= (x if side in ("north", "south") else y) <= at + 1)
            assert gap or not tile_char_walkable(d, z.g[y][x]), "%s: a walkable tile on the %s edge outside the gap at %s,%s" % (zid, side, x, y)
    for side in OPP:
        if side in z.edge_def:
            continue
        for (x, y) in border_tiles(d, side):
            assert z.g[y][x] not in "#=:", "%s: a road runs off the %s edge" % (zid, side)
    occ = {}
    for n in z.d["npcs"]:
        t = (int(n["x"]), int(n["y"]))
        assert tile_char_walkable(d, z.g[t[1]][t[0]]), "%s: npc %s on an unwalkable tile %s" % (zid, n["id"], t)
        assert t not in occ, "%s: npcs %s and %s share a tile" % (zid, n["id"], occ[t])
        occ[t] = n["id"]
        assert any((t[0] + dx, t[1] + dy) in R for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))), "%s: npc %s cannot be talked to" % (zid, n["id"])
    for s in z.d["signs"]:
        t = (int(s["x"]), int(s["y"]))
        assert 0 <= t[0] < z.w and 0 <= t[1] < z.h, "%s: sign out of bounds" % zid
        assert t not in occ, "%s: sign on npc tile %s" % (zid, t)
        occ[t] = "sign"
    # nothing standing in the path of the gaps and no trainer corks the way through
    corks = {(int(n["x"]), int(n["y"])) for n in z.d["npcs"] if "trainer" in n}
    R2 = reach(d, extra=corks)
    for side, (to, at) in z.edge_def.items():
        t = {"north": (at, 0), "south": (at, z.h - 1), "west": (0, at), "east": (z.w - 1, at)}[side]
        assert t in R2, "%s: trainers cork the %s gap" % (zid, side)
    # every walkable prop or sign tile, etc. fine; walkable tiles under props are the caller's business
    for p in z.d["props"]:
        if p["type"] == "building":
            for yy in range(p["y"], p["y"] + p["h"]):
                for xx in range(p["x"], p["x"] + p["w"]):
                    assert z.g[yy][xx] in "BD", "%s: building %s covers %s,%s which is not B or D" % (zid, p.get("label"), xx, yy)
    return R


# ------------------------------------------------------------------ output
def save_route(z, OUT):
    finish = getattr(z, "_finished", False)
    z.save(os.path.join(OUT, z.d["id"] + ".json"))

POIS = []
SPOTS = []

def poi_den(zid, x, y, species, at, mentioned_by=None):
    p = {"id": "poi_%s_den" % zid, "zone": zid, "near": [x, y], "kind": "den", "at": at, "species": species}
    if mentioned_by:
        p["mentioned_by"] = mentioned_by
    POIS.append(p)

def poi_stone(zid, x, y, at, stat, lore):
    POIS.append({"id": "poi_%s_stone" % zid, "zone": zid, "near": [x, y], "kind": "stone", "at": at, "stat": stat, "lore": lore})

def poi_cache(zid, x, y, at, item, line):
    POIS.append({"id": "poi_%s_cache" % zid, "zone": zid, "near": [x, y], "kind": "cache", "at": at, "item": item, "line": line})

def poi_camp(zid, x, y, at, names, party, line, money, item):
    POIS.append({"id": "poi_%s_camp" % zid, "zone": zid, "near": [x, y], "kind": "camp", "at": at, "names": names, "party": party, "line": line, "money": money, "item": item})

def field_spot(zid, x, y, field, prop, text, item, at, suffix=""):
    item_name(item)
    SPOTS.append({"id": "fs_%s_%s%s" % (zid, field, suffix), "zone": zid, "x": x, "y": y, "field": field, "prop": prop, "text": text,
                  "reward": {"item": item, "qty": 1}, "flag": "field_%s_%s%s" % (zid, field, suffix), "at": at})

def merge_json_list(path, key, items, idkey="id"):
    """Write items into a JSON file that holds {key: [...]} (or a bare list when key is None), replacing ids already there."""
    cur = []
    if os.path.exists(path):
        j = json.load(open(path))
        cur = j[key] if key else j
    ids = {i[idkey] for i in items}
    cur = [c for c in cur if c.get(idkey) not in ids] + items
    out = {key: cur} if key else cur
    json.dump(out, open(path, "w"), indent=1, ensure_ascii=False)

def add_map_places(places):
    """places = {zone id: (x, y)}: append to the 'places' line of data/world_map.json without touching the rest."""
    p = os.path.join(ROOT, "data", "world_map.json")
    s = open(p).read()
    i = s.index('"places": {')
    j = s.index("}}", i) + 1
    block = json.loads(s[s.index("{", i):j + 1])
    for k, (x, y) in places.items():
        block[k] = {"x": x, "y": y}
    s = s[:s.index("{", i)] + json.dumps(block) + s[j + 1:]
    open(p, "w").write(s)

_TAKEN = {}

def _snap(zid, x, y, what):
    """The nearest free, reachable tile of plain ground to (x, y): not a path, not under a prop, sign, door or person, and
    not another point of interest's. Moves a point of interest or field spot that the random scenery happened to land on."""
    d = zload(zid)
    occ = {(int(n["x"]), int(n["y"])) for n in d["npcs"]} | {(int(s_["x"]), int(s_["y"])) for s_ in d["signs"]} | {(int(w["x"]), int(w["y"])) for w in d["warps"]}
    for pr in d["props"]:
        if pr["type"] != "building" and not pr.get("walk"):
            occ.add((int(pr["x"]), int(pr["y"])))
    occ |= _TAKEN.setdefault(zid, set())
    R = reach(d)
    le = d.get("legend_extra", {})
    def plain(px, py):
        c = d["rows"][py][px]
        t = le[c].get("tile", "") if c in le else {".": "grass", ",": "tall_grass", "f": "flowers", "s": "sand"}.get(c, "")
        return t in ("grass", "tall_grass", "flowers", "sand")
    h, w = len(d["rows"]), len(d["rows"][0])
    for r in range(0, 9):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if max(abs(dx), abs(dy)) != r:
                    continue
                px, py = x + dx, y + dy
                if 0 <= px < w and 0 <= py < h and (px, py) in R and (px, py) not in occ and plain(px, py):
                    _TAKEN[zid].add((px, py))
                    if r:
                        print("  note: %s moved from (%d,%d) to (%d,%d)" % (what, x, y, px, py))
                    return px, py
    raise AssertionError("%s: nowhere free near (%d,%d) in %s" % (what, x, y, zid))

def finalize(OUT):
    _TAKEN.clear()
    for p_ in POIS:
        p_["near"] = list(_snap(p_["zone"], p_["near"][0], p_["near"][1], p_["id"]))
    for s_ in SPOTS:
        s_["x"], s_["y"] = _snap(s_["zone"], s_["x"], s_["y"], s_["id"])
    write_all(OUT)
    if POIS:
        merge_json_list(os.path.join(ROOT, "data", "poi", "w55_celtic.json"), "pois", POIS)
    if SPOTS:
        merge_json_list(os.path.join(ROOT, "data", "field_spots", "w55_celtic.json"), None, SPOTS)
