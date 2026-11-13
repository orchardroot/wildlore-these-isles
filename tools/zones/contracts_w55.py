#!/usr/bin/env python3
"""Wave 55 contracts: puts each contract's people and look-spots into the zones and their dialogue.

    python3 tools/zones/contracts_w55.py            # every data/contracts/*.json not yet placed
    python3 tools/zones/contracts_w55.py hares      # one contract (by id)

The contract file is the source of truth: its "places" block says where each person stands and what each look-spot
is. This script finds free tiles near the anchors (reachable, not blocking anything, not by a door or the edge),
inserts the NPCs and "examine" spots into data/zones/<zone>.json and the scripts into data/dialogue/<zone>.json,
by text, so the files keep their existing formatting. It refuses to place a contract twice: to redo one,
`git checkout` the zone and dialogue files it touched first.

"places": {
  "poster":    {"zone", "near": [x, y], "sprite", "script_extra"?: [...]}           the person who posted the notice
  "witnesses": [{"clue", "near", "sprite", "name"}]                                  one per "ask" clue (zone from the clue)
  "looks":     [{"clue", "near", "on": "tree|rock|wall|fence|hedge|any", "text": [...]}]   one per "look" clue
  "lair":      {"near", "sprite"?}                                                    zone from "lair"; creature art by default
  "folk":      [{"id", "zone", "near", "sprite", "name", "show_if"?, "hide_if"?, "says": [[flag, [lines]], ...], "else": [lines]}]
}
"""
import glob
import json
import os
import re
import sys
from collections import deque

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
WALKABLE = {"grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "door", "floor_wood", "floor_tile", "platform", "level_crossing"}
LEGEND = {".": "grass", ",": "tall_grass", "#": "path", "=": "road", ":": "cobbles", "s": "sand", "f": "flowers", "~": "water",
          "w": "shallow", "T": "tree_oak", "P": "tree_pine", "H": "hedge", "W": "drystone_wall", "F": "fence", "R": "rock",
          "^": "cliff", "B": "building", "D": "door", "x": "void", "|": "floor_wood", "+": "floor_tile", "C": "counter",
          "L": "ledge_south", "%": "bramble", "o": "deep_water", "/": "scree", "_": "platform", "!": "rail", "$": "sea",
          "*": "bog", "&": "level_crossing"}
SOLID_KINDS = {"tree": {"tree_oak", "tree_pine"}, "rock": {"rock"}, "wall": {"drystone_wall"}, "fence": {"fence"},
               "hedge": {"hedge", "bramble"}}
SOLID_KINDS["any"] = set().union(*SOLID_KINDS.values())
LIKED = {"grass", "tall_grass", "flowers", "sand"}
SOLID_PROPS = {"tree": {"oak", "birch", "pine", "bush", "palm"}, "rock": {"rock", "standing_stone", "slate_heap"}, "wall": set(),
               "fence": set(), "hedge": {"bush"}, "any": {"oak", "birch", "pine", "bush", "rock", "standing_stone", "slate_heap", "bench", "lobster_pots", "barrel", "buoy"}}


class Zone:
    def __init__(self, zid):
        self.id = zid
        self.path = os.path.join(ROOT, "data", "zones", zid + ".json")
        self.text = open(self.path, encoding="utf-8").read()
        self.d = json.loads(self.text)
        self.rows = self.d["rows"]
        self.h = len(self.rows)
        self.w = len(self.rows[0])
        extra = self.d.get("legend_extra", {})
        self.tiles = dict(LEGEND)
        for ch, v in extra.items():
            self.tiles[ch] = v["tile"]
        self.taken = set()  # tiles we have put something on
        for p in self.d.get("props", []):
            self.taken.add((int(p["x"]), int(p["y"])))
        for n in self.d.get("npcs", []):
            self.taken.add((int(n["x"]), int(n["y"])))
        for s in self.d.get("signs", []):
            self.taken.add((int(s["x"]), int(s["y"])))
        for e in self.d.get("examine", []):
            self.taken.add((int(e["x"]), int(e["y"])))
        self.doors = {(int(w["x"]), int(w["y"])) for w in self.d.get("warps", [])}
        self.new_npcs = []
        self.new_examine = []

    def tile(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.tiles.get(self.rows[y][x], "void")
        return "void"

    def walk(self, x, y):
        return self.tile(x, y) in WALKABLE

    def free(self, x, y):
        return self.walk(x, y) and (x, y) not in self.taken and (x, y) not in self.doors

    def spawn(self):
        sp = self.d["spawn"]
        return (int(sp[0]), int(sp[1]))

    def reach(self, blocked):
        start = self.spawn()
        seen = {start}
        q = deque([start])
        while q:
            x, y = q.popleft()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                p = (x + dx, y + dy)
                if p in seen or not self.walk(*p) or p in blocked:
                    continue
                seen.add(p)
                q.append(p)
        return seen

    def solid_blockers(self):
        return {(int(p["x"]), int(p["y"])) for p in self.d.get("props", [])} | {(int(n["x"]), int(n["y"])) for n in self.d.get("npcs", []) if n.get("move", "still") == "still"} | {(int(n["x"]), int(n["y"])) for n in self.new_npcs}

    def near_border(self, x, y, m=3):
        return x < m or y < m or x >= self.w - m or y >= self.h - m

    def find_stand(self, near):
        """A free tile near the anchor an NPC can stand on without walling anything off."""
        base = self.reach(self.solid_blockers())
        best = None
        for r in range(0, 14):
            cands = []
            for y in range(near[1] - r, near[1] + r + 1):
                for x in range(near[0] - r, near[0] + r + 1):
                    if max(abs(x - near[0]), abs(y - near[1])) != r:
                        continue
                    if not self.free(x, y) or (x, y) not in base or self.near_border(x, y):
                        continue
                    if any(max(abs(x - dx), abs(y - dy)) <= 1 for dx, dy in self.doors):
                        continue
                    if any(max(abs(x - px), abs(y - py)) <= 1 for px, py in self.taken):
                        continue
                    sx, sy = self.spawn()
                    if max(abs(x - sx), abs(y - sy)) <= 2:
                        continue
                    nb = sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if self.walk(x + dx, y + dy))
                    if nb < 3:
                        continue
                    after = self.reach(self.solid_blockers() | {(x, y)})
                    if len(after) < len(base) - 1:
                        continue  # it would cut something off
                    score = (0 if self.tile(x, y) in LIKED else 1, nb * -1)
                    cands.append((score, x, y))
            if cands:
                cands.sort()
                best = cands[0]
                break
        if best is None:
            raise SystemExit("no free tile near %s in %s" % (near, self.id))
        return best[1], best[2]

    def prop_at(self, x, y):
        for p in self.d.get("props", []):
            if int(p["x"]) == x and int(p["y"]) == y:
                return p["type"]
        return None

    def find_spot(self, near, kind):
        """A solid tile of `kind` (terrain or prop) near the anchor with somewhere to stand in front of it."""
        base = self.reach(self.solid_blockers() - {(int(p["x"]), int(p["y"])) for p in self.d.get("props", []) if p["type"] in SOLID_PROPS[kind]})
        want = SOLID_KINDS[kind]
        for r in range(0, 20):
            cands = []
            for y in range(near[1] - r, near[1] + r + 1):
                for x in range(near[0] - r, near[0] + r + 1):
                    if max(abs(x - near[0]), abs(y - near[1])) != r:
                        continue
                    pt = self.prop_at(x, y)
                    ok = (pt in SOLID_PROPS[kind]) if pt else (self.tile(x, y) in want)
                    used = (x, y) in self.taken and not (pt and pt in SOLID_PROPS[kind] and not any(int(e["x"]) == x and int(e["y"]) == y for e in self.d.get("examine", []) + self.new_examine))
                    if not ok or used or (x, y) in self.doors:
                        continue
                    stands = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (x + dx, y + dy) in base and (x + dx, y + dy) not in self.taken]
                    if not stands or self.near_border(x, y, 2):
                        continue
                    cands.append((abs(x - near[0]) + abs(y - near[1]), x, y))
            if cands:
                cands.sort()
                return cands[0][1], cands[0][2]
        raise SystemExit("no %s near %s in %s" % (kind, near, self.id))

    def anchor(self, near):
        """[x, y], or the tile of the first prop of that type ("noticeboard")."""
        if isinstance(near, str):
            for p in self.d.get("props", []):
                if p["type"] == near:
                    return (int(p["x"]), int(p["y"]))
            raise SystemExit("no %s in %s" % (near, self.id))
        return (near[0], near[1])

    def add_npc(self, npc):
        self.new_npcs.append(npc)
        self.taken.add((npc["x"], npc["y"]))

    def add_examine(self, ex):
        self.new_examine.append(ex)
        self.taken.add((ex["x"], ex["y"]))

    def save(self):
        t = self.text
        if self.new_npcs:
            t = insert_items(t, "npcs", self.new_npcs, after=None)
        if self.new_examine:
            t = insert_items(t, "examine", self.new_examine, after="npcs")
        open(self.path, "w", encoding="utf-8").write(t)


def block(obj, pad):
    s = json.dumps(obj, indent=1, ensure_ascii=False)
    return "\n".join((" " * pad) + ln for ln in s.split("\n"))


def insert_items(text, key, items, after):
    """Add objects to a top-level array of a zone file, by text, in the file's own style."""
    lines = text.split("\n")
    head = re.compile(r'^ "%s": \[(.*)$' % re.escape(key))
    for i, ln in enumerate(lines):
        m = head.match(ln)
        if not m:
            continue
        body = [block(it, 2) for it in items]
        if m.group(1).strip() in ("],", "]"):  # an empty array on one line
            tail = "," if m.group(1).strip().endswith(",") else ""
            lines[i] = ' "%s": [' % key
            new = [",\n".join(body), " ]" + tail]
            lines[i + 1:i + 1] = ("\n".join(new)).split("\n")
            return "\n".join(lines)
        j = i + 1
        while j < len(lines) and not re.match(r"^ \],?$", lines[j]):
            j += 1
        lines[j - 1] = lines[j - 1] + ","
        lines[j:j] = (",\n".join(body)).split("\n")
        return "\n".join(lines)
    if key != "examine":
        raise SystemExit("no %s array" % key)
    # a zone with no examine list yet: a new block after the npcs array
    for i, ln in enumerate(lines):
        if ln.startswith(' "%s": [' % after):
            j = i
            while not re.match(r"^ \],?$", lines[j]) and not (j == i and ln.rstrip().endswith("],")):
                j += 1
            body = ",\n".join(block(it, 2) for it in items)
            lines[j + 1:j + 1] = [' "examine": [', *body.split("\n"), " ],"]
            return "\n".join(lines)
    raise SystemExit("no place for examine")


def add_dialogue(zone_id, scripts):
    path = os.path.join(ROOT, "data", "dialogue", zone_id + ".json")
    new = json.dumps(scripts, indent=1, ensure_ascii=False)
    inner = new[2:-2]  # drop the outer braces' first/last newline
    if not os.path.exists(path):
        open(path, "w", encoding="utf-8").write("{\n" + inner + "\n}\n")
        return
    t = open(path, encoding="utf-8").read()
    k = t.rstrip().rfind("}")
    head = t[:k].rstrip()
    tail = t[k:]
    sep = "" if head.endswith("{") else ","
    open(path, "w", encoding="utf-8").write(head + sep + "\n" + inner + "\n" + tail)


def say(who, text):
    return {"do": "say", "who": who, "text": text}


def nest(pairs, default, who):
    """[[flag, [lines]], ...] and default lines -> nested if/else commands."""
    if not pairs:
        return [say(who, ln) for ln in default]
    flag, lines = pairs[0]
    return [{"do": "if", "flag": flag, "then": [say(who, ln) for ln in lines], "else": nest(pairs[1:], default, who)}]


def place(c, zones):
    cid = c["id"]
    pl = c["places"]
    scripts = {}

    def zone(zid):
        if zid not in zones:
            zones[zid] = Zone(zid)
            if '"id": "ct_%s_' % cid in zones[zid].text:
                raise SystemExit("%s is already placed in %s" % (cid, zid))
        return zones[zid]

    def npc(zid, nid, sprite, near, script, name, extra=None):
        z = zone(zid)
        x, y = z.find_stand(z.anchor(near))
        d = {"id": nid, "sprite": sprite, "x": x, "y": y, "facing": "down", "move": "still", "script": script, "name": name}
        d.update(extra or {})
        z.add_npc(d)
        scripts.setdefault(zid, {})
        return d

    p = pl["poster"]
    key = "ct_%s_poster" % cid
    npc(c["town"], key, p["sprite"], p["near"], key, c["poster"]["name"])
    scripts[c["town"]][key] = [{"do": "contract", "as": "poster", "id": cid}]
    for w in pl.get("witnesses", []):
        k = next(k for k in c["clues"] if k["id"] == w["clue"])
        key = "ct_%s_%s" % (cid, w["clue"])
        npc(k["zone"], key, w["sprite"], w["near"], key, k["who"])
        scripts[k["zone"]][key] = [{"do": "contract", "as": "clue", "id": cid, "clue": w["clue"]}]
    for lk in pl.get("looks", []):
        k = next(k for k in c["clues"] if k["id"] == lk["clue"])
        z = zone(k["zone"])
        x, y = z.find_spot(z.anchor(lk["near"]), lk.get("on", "any"))
        z.add_examine({"x": x, "y": y, "text": lk["text"], "clue": "%s.%s" % (cid, lk["clue"])})
    lair = c["lair"]
    key = "ct_%s_lair" % cid
    ln = pl.get("lair", {})
    sprite = ln.get("sprite", "creature:" + lair["species"])
    npc(lair["zone"], key, sprite, ln["near"], key, lair["name"], {"show_if": "ct_%s_state" % cid, "hide_if": "ct_%s_end" % cid})
    scripts.setdefault(lair["zone"], {})[key] = [{"do": "contract", "as": "lair", "id": cid}]
    for f in pl.get("folk", []):
        fid = "ct_%s_%s" % (cid, f["id"])
        extra = {}
        for k in ("show_if", "hide_if"):
            if k in f:
                extra[k] = f[k]
        if "move" in f:
            extra["move"] = f["move"]
        npc(f["zone"], fid, f["sprite"], f["near"], fid, f["name"], extra)
        scripts[f["zone"]][fid] = nest([(a, b) for a, b in f.get("says", [])], f["else"], f["name"])
    for zid, z in zones.items():
        z.save()
    for zid, s in scripts.items():
        if s:
            add_dialogue(zid, s)
    for zid, z in zones.items():
        for n in z.new_npcs:
            print("  npc %-34s %s (%d,%d)" % (n["id"], zid, n["x"], n["y"]))
        for e in z.new_examine:
            print("  look %-33s %s (%d,%d)" % (e["clue"], zid, e["x"], e["y"]))


def main():
    want = sys.argv[1:]
    for path in sorted(glob.glob(os.path.join(ROOT, "data", "contracts", "*.json"))):
        c = json.load(open(path, encoding="utf-8"))
        if want and c["id"] not in want:
            continue
        if not want and '"id": "ct_%s_poster"' % c["id"] in open(os.path.join(ROOT, "data", "zones", c["town"] + ".json"), encoding="utf-8").read():
            continue
        print(c["id"])
        place(c, {})


if __name__ == "__main__":
    main()
