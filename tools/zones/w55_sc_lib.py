# Wave 55 roads-scotland: helpers for the new Scottish roads (see w55_sc_roads.py).
# Existing zones are patched as TEXT so their formatting is untouched: only the few border rows of the new gap
# (and their heights, if the zone has any), plus one entry in "edges", change.
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sc_common import *

ROOT = os.environ.get("W55_ROOT") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WALK_CH = set(".,#=:sfwD|+_&")
OPP = {"north": "south", "south": "north", "east": "west", "west": "east"}


def zpath(zid):
    return os.path.join(ROOT, "data", "zones", zid + ".json")


def _walk_chars(d):
    out = set(WALK_CH)
    for ch, v in d.get("legend_extra", {}).items():
        if v.get("tile") in ("grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow") and v.get("prop") in (None, "none", "", "heather", "gorse", "reeds"):
            out.add(ch)
    return out


def _region(d, walk):
    rows = d["rows"]; h = len(rows); w = len(rows[0])
    sx, sy = int(d["spawn"][0]), int(d["spawn"][1])
    seen = {(sx, sy)}; q = [(sx, sy)]
    hs = d.get("heights")
    while q:
        x, y = q.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and rows[ny][nx] in walk:
                if hs and abs(int(hs[ny][nx]) - int(hs[y][x])) > 1:
                    continue
                seen.add((nx, ny)); q.append((nx, ny))
    return seen


def _find_block(lines, key, indent=" "):
    """index of the line opening ` "key": [` or `{`, and of its closing line."""
    for i, ln in enumerate(lines):
        if ln.startswith(indent + '"%s": ' % key) and (ln.rstrip().endswith("[") or ln.rstrip().endswith("{")):
            for j in range(i + 1, len(lines)):
                if lines[j].startswith(indent + "]") or lines[j].startswith(indent + "}"):
                    return i, j
    raise SystemExit("no block %s" % key)


def carve(zid, side, at, to, offset, width=3, force_depth=None):
    """Open a gap of `width` tiles centred on `at` on `side` of existing zone `zid`, cutting a path inward until it
    meets land the spawn can reach, and add the edge side -> `to` with `offset`. Returns the gap's first tile index."""
    p = zpath(zid)
    text = open(p, encoding="utf-8").read()
    d = json.loads(text)
    if side in d["edges"]:
        if d["edges"][side].get("to") == to:
            return at - width // 2  # already cut by an earlier run
        raise SystemExit("%s already has a %s edge to %s" % (zid, side, d["edges"][side].get("to")))
    walk = _walk_chars(d)
    reg = _region(d, walk)
    rows = [list(r) for r in d["rows"]]
    hs = [list(r) for r in d["heights"]] if d.get("heights") else None
    h = len(rows); w = len(rows[0])
    lo = at - width // 2
    cells = []
    depth = 0
    found = None
    for dpt in range(0, 26):
        col = []
        for k in range(width):
            a = lo + k
            if side == "north": col.append((a, dpt))
            elif side == "south": col.append((a, h - 1 - dpt))
            elif side == "west": col.append((dpt, a))
            else: col.append((w - 1 - dpt, a))
        ok = [c in reg for c in col]
        cells.append(col)
        if all(ok):
            found = dpt
            break
        if any(ok) and dpt > 0:
            found = dpt
            break
    if found is None:
        raise SystemExit("%s %s at %d: no land within 25 tiles" % (zid, side, at))
    # heights to use: that of the first reached tile in the contact column
    contact = [c for c in cells[-1] if c in reg]
    hc = int(hs[contact[0][1]][contact[0][0]]) if hs and contact else 0
    changed = set()
    for col in cells[:-1]:
        for (x, y) in col:
            rows[y][x] = "#"
            if hs: hs[y][x] = str(hc)
            changed.add(y)
    # the contact column: only fill tiles that are not already walkable
    for (x, y) in cells[-1]:
        if rows[y][x] not in walk:
            rows[y][x] = "#"
            if hs: hs[y][x] = str(hc)
            changed.add(y)
    lines = text.split("\n")
    ri, _ = _find_block(lines, "rows")
    for y in changed:
        lines[ri + 1 + y] = '  "%s"%s' % ("".join(rows[y]), "," if y < h - 1 else "")
    if hs:
        hi, _ = _find_block(lines, "heights")
        for y in changed:
            lines[hi + 1 + y] = '  "%s"%s' % ("".join(hs[y]), "," if y < h - 1 else "")
    ei, ej = _find_block(lines, "edges")
    # the new side goes in first, not last, so it does not sit beside an entry another session appends
    new = ['  "%s": {' % side, '   "to": "%s",' % to, '   "offset": %d' % offset, "  },"]
    lines[ei + 1:ei + 1] = new
    open(p, "w", encoding="utf-8").write("\n".join(lines))
    json.loads("\n".join(lines))  # still valid
    return lo


def seal(zid, side, at, width=3):
    """Once `side` of an existing zone has an edge, every walkable tile on that border leads somewhere. A zone that
    had no edge there may have a stray walkable tile on it (a bit of beach, a pier end): turn each one outside the
    new gap into whatever the nearest blocked border tile is, so the only way off that side is the gap. Idempotent."""
    p = zpath(zid)
    text = open(p, encoding="utf-8").read()
    d = json.loads(text)
    walk = _walk_chars(d)
    rows = [list(r) for r in d["rows"]]
    h = len(rows); w = len(rows[0])
    lo = at - width // 2
    if side in ("north", "south"):
        y = 0 if side == "north" else h - 1
        cells = [(x, y) for x in range(w)]
        pos = lambda c: c[0]
    else:
        x = 0 if side == "west" else w - 1
        cells = [(x, y) for y in range(h)]
        pos = lambda c: c[1]
    changed = set()
    for c in cells:
        if rows[c[1]][c[0]] in walk and not (lo <= pos(c) < lo + width):
            best = None
            for o in cells:
                if rows[o[1]][o[0]] not in walk and (best is None or abs(pos(o) - pos(c)) < abs(pos(best) - pos(c))):
                    best = o
            rows[c[1]][c[0]] = rows[best[1]][best[0]] if best else "T"
            changed.add(c[1])
    if not changed:
        return
    lines = text.split("\n")
    ri, _ = _find_block(lines, "rows")
    for y in changed:
        lines[ri + 1 + y] = '  "%s"%s' % ("".join(rows[y]), "," if y < h - 1 else "")
    open(p, "w", encoding="utf-8").write("\n".join(lines))
    json.loads("\n".join(lines))


def place(pid, x, y):
    """add `pid` to the world map's places (a text patch of the one-line object)."""
    p = os.path.join(ROOT, "data", "world_map.json")
    t = open(p, encoding="utf-8").read()
    if '"%s": {"x"' % pid in t.split('"places"')[1].split("}}")[0] + "}":
        return
    m = re.search(r'("places": \{.*?\})(,\n)', t)
    assert m, "places line"
    line = m.group(1)
    newline = line[:-1] + ', "%s": {"x": %d, "y": %d}}' % (pid, x, y)
    t = t.replace(line, newline, 1)
    open(p, "w", encoding="utf-8").write(t)


def edge(z, side, to, offset):
    z.d["edges"][side] = {"to": to, "offset": offset}


def gap_rect(side, at, w, h, width=3, depth=2):
    """(x, y, w, h) of an opening of `width` tiles centred on `at`, `depth` deep, on `side` of a w x h zone."""
    lo = at - width // 2
    if side == "north": return (lo, 0, width, depth)
    if side == "south": return (lo, h - depth, width, depth)
    if side == "west": return (0, lo, depth, width)
    return (w - depth, lo, depth, width)


def gate_blockers(zid_obj, side, at, flag, script_id, who="Warden", sprite="warden_grunt", lines=()):
    """a three-tile blocker across a road: NPCs hidden once `flag` is set, all running the same script."""
    lo = at - 1
    w, h = zid_obj.w, zid_obj.h
    for k in range(3):
        if side in ("north", "south"):
            x, y = lo + k, (2 if side == "north" else h - 3)
        else:
            x, y = (2 if side == "west" else w - 3), lo + k
        zid_obj.npc(id="%s_%s" % (script_id, "abc"[k]), sprite=sprite, x=x, y=y, facing="down", move="still",
                    name=who, script=script_id, hide_if=flag)
    script(zid_obj.d["id"], script_id, say(who, *lines))
