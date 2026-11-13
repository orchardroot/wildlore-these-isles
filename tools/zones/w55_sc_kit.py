# Wave 55 roads-scotland: building blocks for a new road zone (see w55_sc_roads.py).
import random
from w55_sc_lib import *

POIS = []
FIELD = []


def scaffold(zid, name, W, H, music, weather, stage, floor, border="T", trees=60, seed=1):
    z = Z(zid, name, W, H, kind="route", region=SCOT, music=music, weather=weather)
    z.d["stage"] = stage
    z.d["scaled_floor"] = floor
    z.border(border, 3)
    z.scatter(0, 0, W, H, "P", trees, seed, only="T")
    return z


def link(z, side, at, other, oside, oat, width=3):
    """Join new zone z's `side` (position `at`) to existing zone `other`'s `oside` (position `oat`)."""
    assert OPP[side] == oside, "sides must face: %s/%s" % (side, oside)
    x, y, w, h = gap_rect(side, at, z.w, z.h, width, 3)
    z.rect(x, y, w, h, "#")
    z.d["edges"][side] = {"to": other, "offset": oat - at}
    carve(other, oside, oat, z.d["id"], at - oat, width)
    seal(other, oside, oat, width)


def trn(z, tid, name, cls, sprite, party, x, y, facing, intro, win, after, money):
    trainer(z, tid, name, cls, sprite, party, x, y, facing, intro, win, after, money)
    TRN[tid]["scaled_floor"] = z.d["scaled_floor"]


def reach_tiles(z):
    sx, sy = z.d["spawn"]
    seen = {(sx, sy)}
    q = [(sx, sy)]
    walk = WALK_CH | set(z.legend)
    while q:
        x, y = q.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < z.w and 0 <= ny < z.h and (nx, ny) not in seen and z.g[ny][nx] in walk:
                if abs(z.hg[ny][nx] - z.hg[y][x]) > 1:
                    continue
                seen.add((nx, ny))
                q.append((nx, ny))
    return seen


def spots(z, n, seed, area=None, apart=12, on=".,f"):
    """n open, reachable tiles (all eight neighbours reachable, clear of props), well apart."""
    r = reach_tiles(z)
    blockers = {(p.get("x", -9), p.get("y", -9)) for p in z.d["props"]}
    blockers |= {(s["x"], s["y"]) for s in z.d["signs"]} | {(n_["x"], n_["y"]) for n_ in z.d["npcs"]}
    blockers |= {(w_["x"], w_["y"]) for w_ in z.d["warps"]}
    blockers.add(tuple(z.d["spawn"]))
    cands = []
    for (x, y) in r:
        if x < 4 or y < 4 or x >= z.w - 4 or y >= z.h - 4:
            continue
        if area and not (area[0] <= x < area[0] + area[2] and area[1] <= y < area[1] + area[3]):
            continue
        if z.g[y][x] not in on:
            continue
        if any(abs(x - bx) <= 1 and abs(y - by) <= 1 for bx, by in blockers):
            continue
        if not all((x + dx, y + dy) in r for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
            continue
        cands.append((x, y))
    cands.sort()
    random.Random(seed).shuffle(cands)
    out = []
    for p in cands:
        if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= apart for q in out):
            out.append(p)
        if len(out) == n:
            break
    assert len(out) == n, "%s: only %d open spots" % (z.d["id"], len(out))
    return out


def poi(z, kind, at, near, **kw):
    e = {"id": "poi_%s_%s" % (z.d["id"], kind), "zone": z.d["id"], "near": [near[0], near[1]], "kind": kind, "at": at}
    e.update(kw)
    POIS.append(e)


def field(z, name, verb, prop, x, y, text, reward, at):
    zid = z.d["id"]
    FIELD.append({"id": "fs_%s_%s" % (zid, name), "zone": zid, "x": x, "y": y, "field": verb, "prop": prop, "text": text,
                  "reward": reward, "flag": "field_%s_%s" % (zid, name), "at": at})


def _merge(path, new, key, wrap=None):
    """the file's entries for zones this run did not build, then this run's."""
    mine = {e["zone"] for e in new}
    old = []
    if os.path.exists(path):
        d = json.load(open(path))
        old = d[wrap] if wrap else d
    out = [e for e in old if e["zone"] not in mine] + new
    json.dump({wrap: out} if wrap else out, open(path, "w"), indent=1)


def write_extras():
    _merge(os.path.join(ROOT, "data", "poi", "w55_scotland.json"), POIS, "zone", "pois")
    _merge(os.path.join(ROOT, "data", "field_spots", "w55_scotland.json"), FIELD, "zone")


def verify(z):
    """Complain (and stop) if anything stands on ground it should not, or cannot be reached from the spawn."""
    r = reach_tiles(z)
    bad = []
    seen = {}
    for kind, items in (("npc", z.d["npcs"]), ("sign", z.d["signs"])):
        for it in items:
            p = (int(it["x"]), int(it["y"]))
            if kind == "npc" and p not in r:
                bad.append("%s %s at %s is not reachable ground" % (kind, it.get("id", it.get("text", "")[:20]), p))
            if kind == "sign" and not any((p[0] + dx, p[1] + dy) in r for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                bad.append("sign at %s cannot be read from reachable ground" % (p,))
            if p in seen:
                bad.append("%s at %s shares a tile with %s" % (kind, p, seen[p]))
            seen[p] = it.get("id", "sign")
    for side, e in z.d["edges"].items():
        x, y = {"north": (z.d["spawn"][0], 0), "south": (z.d["spawn"][0], z.h - 1)}.get(side, (None, None))
        cells = [(a, b) for (a, b) in r if (side == "west" and a == 0) or (side == "east" and a == z.w - 1)
                 or (side == "north" and b == 0) or (side == "south" and b == z.h - 1)]
        if not cells:
            bad.append("edge %s is not reachable from the spawn" % side)
    if bad:
        raise SystemExit("%s: %s" % (z.d["id"], "; ".join(bad)))


def plaque(z, x, y, pid, title, text):
    z.d["signs"].append({"x": x, "y": y, "text": text, "plaque": pid, "title": title})


def grass_patches(z, rects):
    for (x, y, w, h) in rects:
        z.rect(x, y, w, h, ",")
