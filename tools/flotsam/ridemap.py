"""Shared by gen_flotsam.py: a Python mirror of ZoneData's ride rules (data_api/zone_data.gd), so the generator
can find water only a coracle reaches. The validator (core/flotsam.gd) re-checks every placed find with the real rules."""
import json, glob

LEGEND = {".": "grass", ",": "tall_grass", "#": "path", "=": "road", ":": "cobbles", "s": "sand", "f": "flowers", "~": "water",
          "w": "shallow", "T": "tree_oak", "P": "tree_pine", "H": "hedge", "W": "drystone_wall", "F": "fence", "R": "rock",
          "^": "cliff", "B": "building", "D": "door", "x": "void", "|": "floor_wood", "+": "floor_tile", "C": "counter",
          "L": "ledge_south", "%": "bramble", "o": "deep_water", "/": "scree", "_": "platform", "!": "rail", "$": "sea",
          "*": "bog", "&": "level_crossing"}
WALK = {"grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "door", "floor_wood", "floor_tile", "platform", "level_crossing"}
SEA_REACH = 3
DIRS = ((0, 1), (0, -1), (1, 0), (-1, 0))
# the same story gates RideCheck walls off (data_api/ride_check.gd)
GATE_FLAGS = {"champion", "moot_won", "kit1_fought", "starter", "ashcombe1_done"}

def is_gate(n):
    if n.get("move", "still") != "still" or "hide_if" not in n or "show_if" in n:
        return False
    f = str(n["hide_if"])
    return f in GATE_FLAGS or f.startswith("badge_") or f.startswith("trainer_") or (len(f) > 2 and f.startswith("ch") and f[2].isdigit())

class Zone:
    def __init__(self, d):
        self.d = d
        self.id = d["id"]
        self.rows = d["rows"]
        self.h = len(self.rows)
        self.w = max(len(r) for r in self.rows)
        self.kind = d.get("kind", "route")
        self.edges = d.get("edges", {})
        self.no_ride = d.get("no_ride", [])
        self.ride_zone = self.kind != "interior" and not d.get("deep")
        self.le = d.get("legend_extra", {})
        self.heights = d.get("heights")
        self.ground = int(d.get("ground_height", 0))
        self.blocked = set()
        for p in d.get("props", []):
            if p.get("type") != "building" and not p.get("walk", False):
                self.blocked.add((int(p.get("x", 0)), int(p.get("y", 0))))
        for s in d.get("signs", []):
            self.blocked.add((int(s.get("x", 0)), int(s.get("y", 0))))
        self.walls = {(int(n["x"]), int(n["y"])) for n in d.get("npcs", []) if is_gate(n)}
        self._sea = {}

    def tile(self, x, y):
        if not (0 <= x < self.w and 0 <= y < self.h):
            return ""
        row = self.rows[y]
        c = row[x] if x < len(row) else "x"
        if c in self.le:
            return self.le[c].get("tile", "")
        return LEGEND.get(c, "")

    def height(self, x, y):
        if self.heights and 0 <= y < len(self.heights) and x < len(self.heights[y]) and self.heights[y][x].isdigit():
            return int(self.heights[y][x])
        return self.ground

    def edge_border(self, x, y):
        e = self.edges
        return (x == 0 and "west" in e) or (x == self.w - 1 and "east" in e) or (y == 0 and "north" in e) or (y == self.h - 1 and "south" in e)

    def in_no_ride(self, x, y):
        return any(r[0] <= x < r[0] + r[2] and r[1] <= y < r[1] + r[3] for r in self.no_ride)

    def sea_near(self, x, y):
        k = (x, y)
        if k not in self._sea:
            near = False
            for dy in range(-SEA_REACH, SEA_REACH + 1):
                for dx in range(-SEA_REACH, SEA_REACH + 1):
                    if self.tile(x + dx, y + dy) not in ("sea", "void", ""):
                        near = True
            self._sea[k] = near
        return self._sea[k]

    def can_ride(self, x, y):
        t = self.tile(x, y)
        if t not in ("water", "sea") or not self.ride_zone or self.in_no_ride(x, y) or self.edge_border(x, y):
            return False
        return t == "water" or self.sea_near(x, y)

    def walk(self, x, y, px, py, ride):
        """Can you step onto (x, y) from (px, py)? ride: coracle allowed."""
        t = self.tile(x, y)
        if t == "":
            return False
        if (x, y) in self.blocked or (x, y) in self.walls:
            return False
        ok = t in WALK or t == "deep_water" or t in ("scree", "bog")  # every land ability held
        if t == "bramble":
            ok = True
        if not ok and ride and t in ("water", "sea"):
            ok = self.can_ride(x, y)
        if not ok:
            return False
        return abs(self.height(px, py) - self.height(x, y)) <= 1

    def reach(self, start, ride):
        seen = {start}
        q = [start]
        while q:
            x, y = q.pop()
            for dx, dy in DIRS:
                n = (x + dx, y + dy)
                if n in seen:
                    continue
                t = self.tile(*n)
                if t == "ledge_south":
                    if (dx, dy) == (0, 1):
                        land = (n[0], n[1] + 1)
                        if land not in seen and self.walk(land[0], land[1], n[0], n[1], ride):
                            seen.add(land)
                            q.append(land)
                    continue
                if self.walk(n[0], n[1], x, y, ride):
                    seen.add(n)
                    q.append(n)
        return seen

def load_zones():
    out = {}
    for f in sorted(glob.glob("data/zones/*.json")):
        d = json.load(open(f))
        out[d["id"]] = Zone(d)
    return out
