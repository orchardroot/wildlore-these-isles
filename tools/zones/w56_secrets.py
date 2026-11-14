#!/usr/bin/env python3
"""Wave 56, secrets: builds the hidden places from the specs in w56_secrets_spec.py.

    python3 tools/zones/w56_secrets.py [id ...]       # all the specs, or only the named ones

For each spec it writes the room (data/zones/secret_*.json), its dialogue and letter, adds a `hidden` warp, the
reveal (an examine spot or a resident who tells you) to the outdoor zone that hides it, and lists it in
data/secrets.json. Outdoor zone files are edited as text so their formatting stays as it was. Re-running is safe:
what is already there is left alone, and the spots picked are kept in w56_secrets_spots.json.
"""
import json, os, re, sys, hashlib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.dirname(__file__))
from w56_secrets_spec import SPECS  # noqa: E402

ZONES = os.path.join(ROOT, "data", "zones")
DLG = os.path.join(ROOT, "data", "dialogue")
SPOTS = os.path.join(os.path.dirname(__file__), "w56_secrets_spots.json")

LEG = {".": "grass", ",": "tall_grass", "#": "path", "=": "road", ":": "cobbles", "s": "sand", "f": "flowers", "~": "water",
       "w": "shallow", "T": "tree_oak", "P": "tree_pine", "H": "hedge", "W": "drystone_wall", "F": "fence", "R": "rock",
       "^": "cliff", "B": "building", "D": "door", "x": "void", "|": "floor_wood", "+": "floor_tile", "C": "counter",
       "L": "ledge_south", "%": "bramble", "o": "deep_water", "/": "scree", "_": "platform", "!": "rail", "$": "sea",
       "*": "bog", "&": "level_crossing"}
WALK = {"grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "door", "floor_wood", "floor_tile",
        "platform", "level_crossing"}
DIRS4 = ((1, 0), (-1, 0), (0, 1), (0, -1))


# ---- JSON text editing (keeps each file's own formatting) -------------------------------------------------------

def top_keys(text):
    """{key: (value_start, value_end)} for the keys at depth 1 of the object in `text`."""
    dec = json.JSONDecoder()
    out = {}
    i = text.index("{") + 1
    n = len(text)
    while i < n:
        c = text[i]
        if c == '"':
            key, j = dec.raw_decode(text, i)
            k = j
            while text[k] in " \t\r\n":
                k += 1
            if text[k] == ":":
                k += 1
                while text[k] in " \t\r\n":
                    k += 1
                _, e = dec.raw_decode(text, k)
                out[key] = (k, e)
                i = e
                continue
            i = j
            continue
        if c == "}":
            break
        i += 1
    return out


def _reindent(js, base):
    lines = js.split("\n")
    return ("\n" + base).join(lines)


def insert_array_item(text, key, item):
    keys = top_keys(text)
    multi = "\n" in text.strip()
    if key not in keys:
        end = text.rindex("}")
        before = text[:end].rstrip()
        if multi:
            body = json.dumps({key: [item]}, indent=1, ensure_ascii=False)
            body = "\n".join(body.split("\n")[1:-1])
            return before + ",\n" + body + "\n" + text[end:]
        return before + ", " + json.dumps({key: [item]}, ensure_ascii=False)[1:-1] + text[end:]
    vs, ve = keys[key]
    arr = text[vs:ve]
    if re.fullmatch(r"\[\s*\]", arr):
        if multi:
            ind = " " * (len(text[:vs].split("\n")[-1]) - len(text[:vs].split("\n")[-1].lstrip()) + 1)
            return text[:vs] + "[\n" + ind + _reindent(json.dumps(item, indent=1, ensure_ascii=False), ind) + "\n" + ind[:-1] + "]" + text[ve:]
        return text[:vs] + "[" + json.dumps(item, ensure_ascii=False) + "]" + text[ve:]
    close = ve - 1
    last = len(text[:close].rstrip())
    if "\n" in arr:
        m = re.search(r"\[\s*\n([ \t]*)", arr)
        ind = m.group(1)
        return text[:last] + ",\n" + ind + _reindent(json.dumps(item, indent=1, ensure_ascii=False), ind) + text[last:]
    return text[:last] + ", " + json.dumps(item, ensure_ascii=False) + text[last:]


def insert_object_key(text, key, value):
    end = text.rindex("}")
    before = text[:end].rstrip()
    body = json.dumps({key: value}, indent=1, ensure_ascii=False)
    body = "\n".join(body.split("\n")[1:-1])
    sep = "" if before.endswith("{") else ","
    return before + sep + "\n" + body + "\n" + text[end:]


# ---- reading zones ----------------------------------------------------------------------------------------------

class Z:
    def __init__(self, zid):
        self.id = zid
        self.path = os.path.join(ZONES, zid + ".json")
        self.text = open(self.path).read()
        self.raw = json.loads(self.text)
        r = self.raw
        self.rows = r["rows"]
        self.h = len(self.rows)
        self.w = len(self.rows[0])
        leg = dict(LEG)
        for k, v in r.get("legend_extra", {}).items():
            if isinstance(v, dict) and "tile" in v:
                leg[k] = v["tile"]
        self.leg = leg
        self.spawn = tuple(r["spawn"])
        self.edges = r.get("edges", {})
        self.occ = set()
        for lst in ("warps", "npcs", "signs", "examine"):
            for e in r.get(lst, []):
                self.occ.add((int(e["x"]), int(e["y"])))
        self.pblock = set()
        for p in r.get("props", []):
            if p.get("type") == "building":
                for yy in range(int(p["y"]), int(p["y"]) + int(p.get("h", 1))):
                    for xx in range(int(p["x"]), int(p["x"]) + int(p.get("w", 1))):
                        self.pblock.add((xx, yy))
            elif not p.get("walk", False) and "x" in p:
                self.pblock.add((int(p["x"]), int(p["y"])))

    def tile(self, x, y):
        return self.leg.get(self.rows[y][x], "grass")

    def ok(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def walk(self, x, y):
        return self.ok(x, y) and self.tile(x, y) in WALK and (x, y) not in self.pblock

    def reach(self, start=None, block=()):
        st = start or self.spawn
        seen = {st}
        q = [st]
        warps = {(int(w["x"]), int(w["y"])) for w in self.raw.get("warps", [])}
        while q:
            x, y = q.pop()
            for dx, dy in DIRS4:
                p = (x + dx, y + dy)
                if p in seen or not self.walk(*p) or p in warps or p in block:
                    continue
                seen.add(p)
                q.append(p)
        return seen

    def border(self, x, y, m=2):
        return x < m or y < m or x >= self.w - m or y >= self.h - m

    def near_occ(self, x, y, d=2):
        return any(abs(x - ox) <= d and abs(y - oy) <= d for ox, oy in self.occ)

    def sea_ok(self, x, y):
        """Sea within 3 tiles of anything that is not sea or void (ZoneData.sea_near_shore)."""
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                if self.ok(x + dx, y + dy) and self.tile(x + dx, y + dy) not in ("sea", "void"):
                    return True
        return False

    def ride_ok(self, x, y):
        t = self.tile(x, y)
        if self.border(x, y, 1):
            return False
        return t == "water" or (t == "sea" and self.sea_ok(x, y))


def h(*parts):
    return int(hashlib.md5("|".join(map(str, parts)).encode()).hexdigest()[:8], 16)


def pick_spots(sp, zone, taken):
    """Warp tile, arrival tile, reveal tile and NPC tile for a spec, deterministic."""
    land = zone.reach()
    cands = []
    if sp.get("coracle"):
        want = ("water", "sea")
        for y in range(zone.h):
            for x in range(zone.w):
                if not zone.ride_ok(x, y) or (x, y) in zone.occ or zone.near_occ(x, y, 1):
                    continue
                for dx, dy in DIRS4:
                    a = (x + dx, y + dy)
                    if a in land and a not in zone.occ and not zone.border(*a, 1):
                        # open water round the warp, and an arrival tile with a free neighbour that is not the warp
                        free = sum(1 for ddx, ddy in DIRS4 if (a[0] + ddx, a[1] + ddy) in land)
                        if free >= 1:
                            cands.append(((x, y), a, free))
                            break
        cands = [c for c in cands if not any(abs(c[0][0] - t[0]) < 6 and abs(c[0][1] - t[1]) < 6 for t in taken)]
        cands.sort(key=lambda c: (-c[2], h(sp["id"], c[0])))
        # prefer something away from the spawn (not on the doorstep)
        far = [c for c in cands if abs(c[0][0] - zone.spawn[0]) + abs(c[0][1] - zone.spawn[1]) >= 10] or cands
        warp, arrive, _ = far[(h(sp["id"]) % min(len(far), 8))]
    else:
        feats = set(sp.get("near", ["rock", "cliff", "water", "tree_oak", "tree_pine", "drystone_wall", "hedge"]))
        for (x, y) in land:
            if zone.border(x, y, 3) or (x, y) in zone.occ or zone.near_occ(x, y, 2):
                continue
            if zone.tile(x, y) not in ("grass", "path", "sand", "flowers", "cobbles", "tall_grass"):
                continue
            score = 0
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if (dx or dy) and zone.ok(x + dx, y + dy) and zone.tile(x + dx, y + dy) in feats:
                        score += 1
            opens = [(x + dx, y + dy) for dx, dy in DIRS4 if (x + dx, y + dy) in land and (x + dx, y + dy) not in zone.occ]
            if score < 2 or len(opens) < 2:
                continue
            if any(abs(x - t[0]) < 6 and abs(y - t[1]) < 6 for t in taken):
                continue
            if abs(x - zone.spawn[0]) + abs(y - zone.spawn[1]) < 8:
                continue
            cands.append(((x, y), opens[0], score))
        cands.sort(key=lambda c: (-c[2], h(sp["id"], c[0])))
        warp, arrive, _ = cands[(h(sp["id"]) % min(len(cands), 6))]
    out = {"warp": list(warp), "arrive": list(arrive)}
    # the reveal spot: a solid tile you can face from a reachable one, close to the warp
    if sp["how"] in ("examine", "bottle", "dawn"):
        solid = set(sp.get("spot", ["rock", "cliff", "water", "tree_oak", "tree_pine", "drystone_wall", "hedge", "building"]))
        best = None
        for y in range(max(0, warp[1] - 7), min(zone.h, warp[1] + 8)):
            for x in range(max(0, warp[0] - 7), min(zone.w, warp[0] + 8)):
                if (x, y) in zone.occ or (x, y) in land or zone.tile(x, y) not in solid:
                    continue
                if zone.border(x, y, 1) or max(abs(x - warp[0]), abs(y - warp[1])) < 2:
                    continue
                if not any((x + dx, y + dy) in land and (x + dx, y + dy) not in zone.occ for dx, dy in DIRS4):
                    continue
                d = abs(x - warp[0]) + abs(y - warp[1])
                key = (d, h(sp["id"], "ex", x, y))
                if best is None or key < best[0]:
                    best = (key, (x, y))
        out["spot"] = list(best[1])
    # the resident: an open reachable tile that does not cut the zone in two, a few tiles from the warp
    best = None
    base = len(land)
    for (x, y) in land:
        if (x, y) in zone.occ or zone.near_occ(x, y, 1) or zone.border(x, y, 3) or zone.tile(x, y) not in ("grass", "path", "sand", "flowers", "cobbles"):
            continue
        if (x, y) in (tuple(out["warp"]), tuple(out["arrive"])) or (out.get("spot") and abs(x - out["spot"][0]) + abs(y - out["spot"][1]) < 3):
            continue
        d = abs(x - warp[0]) + abs(y - warp[1])
        if d < 4 or d > 16:
            continue
        opens = sum(1 for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx or dy) and (x + dx, y + dy) in land)
        if opens < 7:
            continue
        key = (abs(d - 8), h(sp["id"], "npc", x, y))
        if best is None or key < best[0]:
            best = (key, (x, y))
    cand = sorted([(abs(abs(x - warp[0]) + abs(y - warp[1]) - 8), h(sp["id"], "npc", x, y), (x, y)) for (x, y) in land
                   if (x, y) not in zone.occ and not zone.near_occ(x, y, 1) and not zone.border(x, y, 3)
                   and zone.tile(x, y) in ("grass", "path", "sand", "flowers", "cobbles")
                   and 4 <= abs(x - warp[0]) + abs(y - warp[1]) <= 16
                   and sum(1 for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx or dy) and (x + dx, y + dy) in land) >= 7
                   and (x, y) not in (tuple(out["warp"]), tuple(out["arrive"]))
                   and not (out.get("spot") and abs(x - out["spot"][0]) + abs(y - out["spot"][1]) < 3)])
    for _, _, t in cand:
        if len(zone.reach(block={t})) >= base - 1:
            out["npc"] = list(t)
            break
    return out


def pick_dig(sp):
    """A bare, reachable tile for a letter's treasure trail, in the zone the trail names (kept off every spot the zone uses)."""
    z = Z(sp["letter"]["trail"]["zone"])
    land = z.reach()
    cand = []
    for (x, y) in land:
        if z.tile(x, y) in ("grass", "flowers", "sand", "path") and (x, y) not in z.pblock and not z.near_occ(x, y, 1) and not z.border(x, y, 3):
            if abs(x - z.spawn[0]) + abs(y - z.spawn[1]) >= 8:
                cand.append((h(sp["id"], "dig", x, y), (x, y)))
    return list(sorted(cand)[0][1])


# ---- the rooms --------------------------------------------------------------------------------------------------

CAVE = ["xxxxxxxxxxxxx",
        "xxxxcccccxxxx",
        "xxcccccccccxx",
        "xxcccccccccxx",
        "xcccccccccccx",
        "xcccccccccccx",
        "xxcccccccccxx",
        "xxxcccccccxxx",
        "xxxxxcccxxxxx",
        "xxxxxxDxxxxxx"]
ROOM = ["xxxxxxxxxxxxx",
        "xcccccccccccx",
        "xcccccccccccx",
        "xcccccccccccx",
        "xcccccccccccx",
        "xcccccccccccx",
        "xcccccccccccx",
        "xxxxxxDxxxxxx"]
SHAPES = {"cave": (CAVE, (6, 9), (6, 8)), "room": (ROOM, (6, 7), (6, 6))}


def build_room(sp, outer_arrive):
    rows, door, arrive = SHAPES[sp.get("shape", "cave")]
    room = {"id": sp["zone"], "name": sp["room_name"], "region": "", "kind": "interior", "music": "", "weather": {}, "dark": True,
            "legend_extra": {"c": {"tile": "floor_tile", "colour": sp.get("floor", "#6f6a62")}},
            "props": sp.get("props", []), "warps": [{"x": door[0], "y": door[1], "to": sp["at"], "tx": outer_arrive[0], "ty": outer_arrive[1],
                                                      "facing": sp.get("out_facing", "down")}],
            "edges": {}, "encounters": {}, "signs": sp.get("signs", []), "spawn": list(arrive)}
    ex = list(sp.get("examine", []))
    if sp["reward"] == "chapbook" or sp["reward"] == "curio":
        ex.append({"x": sp["find_at"][0], "y": sp["find_at"][1], "text": sp["find_text"], "find": {"item": sp["item"]}})
    if sp["reward"] == "view":
        ex.append({"x": sp["find_at"][0], "y": sp["find_at"][1], "text": sp["find_text"], "flag": sp["zone"] + "_viewed"})
    room["examine"] = ex
    npcs = []
    if sp["reward"] == "creature":
        npcs.append({"id": sp["zone"] + "_pup", "sprite": "creature:" + sp["species"], "x": sp["find_at"][0], "y": sp["find_at"][1], "facing": "down",
                     "move": "still", "script": sp["zone"] + "_find", "name": sp["creature_name"], "hide_if": sp["zone"] + "_got"})
    room["npcs"] = npcs
    room["rows"] = rows
    return room


def dump_room(room):
    # the same layout the other hand-made interiors use: indent 1, the rows last
    rows = room.pop("rows")
    s = json.dumps(room, indent=1, ensure_ascii=False)
    room["rows"] = rows
    s = s[:-2] + ',\n "rows": [\n' + ",\n".join('  "%s"' % r for r in rows) + "\n ]\n}\n"
    return s


def creature_level(zone):
    mins = []
    for tbl in zone.raw.get("encounters", {}).values():
        for e in tbl:
            mins.append(int(e.get("min", 5)))
    return max(5, round(sum(mins) / len(mins))) if mins else 20


def say(who, text):
    assert len(text) <= 150, (len(text), text)
    assert "—" not in text and "–" not in text and '"' not in text, text
    return {"do": "say", "who": who, "text": text}


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").write(text)


def main():
    spots = json.load(open(SPOTS)) if os.path.exists(SPOTS) else {}
    want = set(sys.argv[1:])
    index = []
    letters = []
    world_ok = []
    taken_by_zone = {}
    for sp in SPECS:
        zone = Z(sp["at"])
        taken = taken_by_zone.setdefault(sp["at"], [])
        if sp["id"] not in spots:
            spots[sp["id"]] = pick_spots(sp, zone, taken)
        if sp["reward"] == "letter" and "dig" not in spots[sp["id"]]:
            spots[sp["id"]]["dig"] = pick_dig(sp)
        st = spots[sp["id"]]
        taken.append(tuple(st["warp"]))
        # --- data/secrets.json row
        row = {"id": sp["id"], "zone": sp["zone"], "at": sp["at"], "x": st["warp"][0], "y": st["warp"][1], "reveal": sp["reveal"],
               "how": sp["how"], "name": sp["name"], "nation": sp["nation"], "kind": sp["kind"], "reward": sp["reward"]}
        if sp.get("coracle"):
            row["coracle"] = True
        for k in ("species", "item"):
            if k in sp:
                row[k] = sp[k]
        index.append(row)
        world_ok.append({"rule": "cave", "zone": sp["at"], "key": sp["zone"], "why": "a hidden place: the way in is hidden until something in the world reveals it"})
        if want and sp["id"] not in want:
            continue
        outer_text = zone.text
        # --- the room and its dialogue
        room = build_room(sp, st["arrive"])
        write(os.path.join(ZONES, sp["zone"] + ".json"), dump_room(room))
        dlg = {}
        if sp["reward"] == "creature":
            lvl = creature_level(zone)
            dlg[sp["zone"] + "_find"] = [say("", t) for t in sp["find_lines"]] + [
                {"do": "give_creature", "species": sp["species"], "level": lvl, "scaled_floor": lvl},
                {"do": "set", "flag": sp["zone"] + "_got", "value": True}] + [say("", t) for t in sp["after_lines"]]
        if dlg:
            write(os.path.join(DLG, sp["zone"] + ".json"), json.dumps(dlg, indent=1, ensure_ascii=False) + "\n")
        if sp["reward"] == "letter":
            trail = dict(sp["letter"]["trail"])
            trail["near"] = st["dig"]
            trail = {"zone": trail["zone"], "near": trail["near"], "clue": trail["clue"], "reward": trail["reward"]}
            p = {"id": "ltr_" + sp["zone"], "zone": sp["zone"], "title": sp["letter"]["title"], "lines": sp["letter"]["lines"], "trail": trail}
            letters.append(p)
        # --- the outdoor zone: the hidden warp, the reveal, the resident
        if '"to": "%s"' % sp["zone"] not in outer_text.replace('"to":"', '"to": "'):
            w = {"x": st["warp"][0], "y": st["warp"][1], "to": sp["zone"], "tx": SHAPES[sp.get("shape", "cave")][2][0], "ty": SHAPES[sp.get("shape", "cave")][2][1],
                 "facing": "up", "hidden": {"reveal": sp["reveal"]}}
            if sp.get("coracle"):
                w["coracle"] = True
            outer_text = insert_array_item(outer_text, "warps", w)
        if sp["how"] in ("examine", "bottle", "dawn") and ('"flag": "%s"' % sp["reveal"]) not in outer_text:
            ex = {"x": st["spot"][0], "y": st["spot"][1], "text": sp["spot_text"], "flag": sp["reveal"]}
            if sp["how"] == "dawn":
                ex["phase"] = ["dawn"]
                ex["off"] = sp["spot_off"]
            outer_text = insert_array_item(outer_text, "examine", ex)
        if ('"id": "%s"' % sp["npc"]["id"]) not in outer_text:
            n = {"id": sp["npc"]["id"], "sprite": sp["npc"]["sprite"], "x": st["npc"][0], "y": st["npc"][1], "facing": "down", "move": "still",
                 "script": sp["npc"]["id"], "name": sp["npc"]["name"]}
            outer_text = insert_array_item(outer_text, "npcs", n)
        if outer_text != zone.text:
            write(zone.path, outer_text)
        # the resident's words go in the outdoor zone's dialogue file
        dpath = os.path.join(DLG, sp["at"] + ".json")
        dtext = open(dpath).read() if os.path.exists(dpath) else "{\n}\n"
        if ('"%s"' % sp["npc"]["id"]) not in dtext:
            who = sp["npc"]["name"]
            told = [say(who, t) for t in sp["npc"]["lines"]]
            if sp["how"] == "rumour":
                script = [{"do": "if", "flag": sp["reveal"], "then": [say(who, t) for t in sp["npc"]["again"]],
                           "else": told + [{"do": "set", "flag": sp["reveal"], "value": True}]}]
            else:
                script = [{"do": "if", "flag": sp["reveal"], "then": [say(who, t) for t in sp["npc"]["again"]], "else": told}]
            dtext = insert_object_key(dtext, sp["npc"]["id"], script)
            write(dpath, dtext)
    write(SPOTS, json.dumps(spots, indent=1) + "\n")
    # --- the registries
    write(os.path.join(ROOT, "data", "secrets.json"), json.dumps({"secrets": index}, indent=1, ensure_ascii=False) + "\n")
    lp = os.path.join(ROOT, "data", "letters", "secrets.json")
    if letters or os.path.exists(lp):
        old = json.load(open(lp))["papers"] if os.path.exists(lp) else []
        ids = {p["id"] for p in letters}
        write(lp, json.dumps({"papers": [p for p in old if p["id"] not in ids] + letters}, indent=1, ensure_ascii=False) + "\n")
    wp = os.path.join(ROOT, "data", "world_consistency.json")
    wc = json.load(open(wp))
    have = {(o["rule"], o["zone"], o["key"]) for o in wc["ok"]}
    add = [o for o in world_ok if (o["rule"], o["zone"], o["key"]) not in have]
    if add:
        text = open(wp).read()
        for o in add:
            text = insert_array_item(text, "ok", o)
        write(wp, text)
    print("built", len(index), "secret(s)")


if __name__ == "__main__":
    main()
