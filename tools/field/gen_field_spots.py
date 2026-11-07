#!/usr/bin/env python3
"""Places the field spots (data/field_spots/<region>.json) on free, reachable tiles beside the path, near the
terrain each verb needs (a wall for mend, water for paddle...). Deterministic. Usage: python3 tools/field/gen_field_spots.py"""
import json, glob, hashlib, collections, re, os

def h(*a):
    return int(hashlib.md5("|".join(map(str, a)).encode()).hexdigest()[:8], 16)

LEGEND = {".": "grass", ",": "tall_grass", "#": "path", "=": "road", ":": "cobbles", "s": "sand", "f": "flowers", "~": "water",
          "w": "shallow", "T": "tree_oak", "P": "tree_pine", "H": "hedge", "W": "drystone_wall", "F": "fence", "R": "rock",
          "^": "cliff", "B": "building", "D": "door", "x": "void", "|": "floor_wood", "+": "floor_tile", "C": "counter",
          "L": "ledge_south", "%": "bramble", "o": "deep_water", "/": "scree", "_": "platform", "!": "rail", "$": "sea",
          "*": "bog", "&": "level_crossing"}
WALK = {"grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "door", "floor_wood", "floor_tile", "platform", "level_crossing"}
GOOD = {"grass", "tall_grass", "flowers", "sand"}
PATHY = {"path", "road", "cobbles"}
WATER = {"water", "deep_water"}

zones = {}
for f in glob.glob("data/zones/*.json"):
    d = json.load(open(f)); zones[d["id"]] = d
mp = json.load(open("data/world_map.json"))
onmap = set(mp["towns"]) | set(mp["places"])
pois = []
for f in glob.glob("data/poi/*.json"):
    pois += json.load(open(f))["pois"]

def tile(z, x, y):
    if y < 0 or x < 0 or y >= len(z["rows"]) or x >= len(z["rows"][y]): return ""
    c = z["rows"][y][x]
    le = z.get("legend_extra", {})
    if c in le:
        if le[c].get("prop") not in (None, "none", ""):
            return "prop:" + str(le[c].get("tile", ""))
        return le[c].get("tile", "")
    return LEGEND.get(c, "")

def reach(z, extra_block=()):
    w, hh = len(z["rows"][0]), len(z["rows"])
    sx, sy = int(z["spawn"][0]), int(z["spawn"][1])
    seen = {(sx, sy)}; q = [(sx, sy)]
    while q:
        x, y = q.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < hh and (nx, ny) not in seen and (nx, ny) not in extra_block and tile(z, nx, ny) in WALK:
                if z.get("heights") and abs(int(z["heights"][ny][nx]) - int(z["heights"][y][x])) > 1: continue
                seen.add((nx, ny)); q.append((nx, ny))
    return seen

def map_at(zid):
    if zid in onmap: return zid
    seen = {zid}; fr = [zid]
    for _ in range(4):
        nx = []
        for a in fr:
            for e in zones[a].get("edges", {}).values():
                t = e["to"]
                if t in seen or t not in zones: continue
                if t in onmap: return t
                seen.add(t); nx.append(t)
            for wp in zones[a].get("warps", []):
                t = wp["to"]
                if t in seen or t not in zones: continue
                if t in onmap: return t
        fr = nx
    return ""

# --- venues: outdoor zones whose interiors (or themselves) run a minigame ---
GAME_CMDS = ["darts", "bowls", "curling", "skim", "crab_comp", "wall", "games", "wrestling", "conkers", "ring", "fete", "quiz", "crossword", "arcade", "trumps", "sing"]
GAME_VERB = {"skim": "skim", "crab_comp": "line", "wall": "mend", "games": "topple", "conkers": "charm", "bowls": "loft", "curling": "paddle"}
venues = collections.defaultdict(set)  # outdoor zone -> verb hints
parent = {}
for zid, z in zones.items():
    for wp in z.get("warps", []):
        if wp["to"] in zones and zones[wp["to"]]["kind"] == "interior" and z["kind"] != "interior":
            parent.setdefault(wp["to"], zid)
for zid, z in zones.items():
    path = "data/dialogue/%s.json" % zid
    txt = open(path).read() if os.path.exists(path) else ""
    zt = json.dumps(z.get("npcs", []))
    for c in GAME_CMDS:
        if '"do": "%s"' % c in txt or '"do": "%s"' % c in zt:
            out = zid if z["kind"] != "interior" else parent.get(zid)
            if out and zones[out]["region"] and not zones[out]["region"].startswith("overseas") and zones[out]["region"] != "dev":
                venues[out].add(GAME_VERB.get(c, ""))

# --- text ---
TEXT = {
 "mend": ["A gap in the wall, where the stones have gone for a walk. {lead} fits them back one by one, like a very slow jigsaw. Tucked in the wall behind: {what}.",
          "The drystone has slumped. {lead} lifts the big stones in first and wedges the small ones after, which is exactly how it is done. Behind the stones: {what}.",
          "A wall with a tooth missing. {lead} rebuilds it with no mortar and a great deal of dignity, and finds {what} in the hollow."],
 "skim": ["A flat stone and a still stretch of water. {lead} sends it dancing across, once, twice, five times, and something on the far side wobbles loose: {what}.",
          "{lead} skims a stone over the pool and a bottle on a post tips over. Hanging from it: {what}.",
          "Ripples run out from {lead}'s throw like a good rumour, and the stone raps a reed stem. Something drops out of it: {what}."],
 "topple": ["A dead trunk, leaning on nothing much. {lead} puts its shoulder to it and over it goes with a crack. Underneath: {what}.",
            "The old trunk is hollow and ready to go. {lead} heaves, it topples, and out of the hollow rolls {what}.",
            "A dead tree, waiting for an excuse. {lead} supplies one. In the roots, undisturbed for years: {what}."],
 "line": ["Something glints in the water. {lead} wades in, makes a few calm passes and fishes it out: {what}.",
          "A glint under the surface, just out of reach. {lead} hooks it with patience and a bit of reed. It is {what}.",
          "{lead} peers into the water, then pulls out, with great ceremony, {what}."],
 "round_up": ["Sheep at the gate, and no sheep will go first. {lead} comes round the back, low and quiet, and the flock files through. The farmer's thanks: {what}.",
              "A knot of sheep, all facing the wrong way. {lead} works them in a neat curve until the gate is clear. Left on the post for you: {what}.",
              "{lead} circles the flock like it has done this all its life. The gate is clear in a minute. Someone has hung {what} on the post."],
 "charm": ["A molehill, freshly heaped. {lead} drums a gentle rhythm on the ground and the worms come up to see what the fuss is. Among the soil: {what}.",
           "{lead} taps out a steady beat beside the hill and the earth begins to wriggle. Turned up with the worms: {what}.",
           "Soft ground, a patient creature, and a lot of worms. {lead} brings up the lot, and under them: {what}."],
 "snorkel": ["A peat pool, black as tea. {lead} dives in, flippers going, and comes up spluttering and delighted with {what}.",
             "The bog water is dark and cold. {lead} ploughs through it with its face down and surfaces holding {what}.",
             "Bubbles rise in the peat. {lead} follows them down and brings up, to its evident pride, {what}."],
 "paddle": ["A coracle, left on the bank, light as a basket. {lead} gets in and paddles across without spinning more than twice. On the far side: {what}.",
            "The little round boat wobbles, then settles. {lead} crosses the water with short, careful strokes and lands among the reeds. There is {what}.",
            "A coracle, tied up and patient. {lead} takes the paddle and you take a seat. The water is easy and the other side has {what}."],
 "roll": ["A cheese wheel stuck in a hollow, as they do. {lead} gives it a shove and down the slope it goes, and the hollow gives up {what}.",
          "{lead} tips the wheel over the lip and it bounds off downhill with great purpose. Where it was sitting: {what}.",
          "The wheel has been here since last spring's chase. {lead} sets it rolling, and underneath is {what}."],
 "loft": ["A bale and a bend, and a bowl that wants lofting. {lead} swings and sends it up over the hedge in one long arc. It lands by {what}.",
          "{lead} takes a run up and lofts the bowl clean over the verge. Where it comes down: {what}.",
          "The bowl sails over the bend like it knew the road. {lead} trots after it, and finds {what} in the grass."],
}
ITEMS = {
 "mend": ["hag_stone", "rowan_sprig", "horseshoe", "slate_chip", "sheep_wool", "four_leaf_clover"],
 "skim": ["sea_glass", "ammonite", "lucky_chip", "oak_acorn", "burn_water_flask", "drakes_drum"],
 "topple": ["conker", "hazelnuts", "oak_acorn", "truffle", "field_mushrooms", "honeycomb"],
 "line": ["sea_glass", "ammonite", "european_eel", "perch", "roach", "seaweed"],
 "round_up": ["cream_tea", "kendal_mint_cake", "double_gloucester", "sheep_wool", "flask_of_tea", "pasty"],
 "charm": ["crab_bait", "peat", "truffle", "field_mushrooms", "four_leaf_clover", "wild_garlic"],
 "snorkel": ["peat", "bog_myrtle_sprig", "ammonite", "whin_blossom", "burn_water_flask", "hag_stone"],
 "paddle": ["norfolk_reed", "willow_sprig", "sea_glass", "selkie_pearl", "peregrine_feather", "ammonite"],
 "roll": ["double_gloucester", "coopers_wheel", "banbury_cake", "cream_tea", "fest_cheese_round", "bristol_cider"],
 "loft": ["horseshoe", "lucky_chip", "hag_stone", "cream_tea", "sloes", "blackberries"],
}
CURIOS = []
j = json.load(open("data/items/w47_a.json"))
for i in (j if isinstance(j, list) else j.get("items", [])):
    if i.get("kind") == "curio": CURIOS.append(i["id"])
MONEY_WHAT = ["a few coins", "a roll of notes", "a purse, a bit damp", "some loose change and a gratitude card"]

# which verbs each terrain allows
def nb4(z, x, y, want):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < len(z["rows"][0]) and 0 <= ny < len(z["rows"]) and tile(z, nx, ny) in want: return True
    return False

def can(z, v, x, y):
    t = tile(z, x, y)
    if v == "mend": return t in GOOD and nb4(z, x, y, {"drystone_wall"})
    if v == "round_up": return t in GOOD and nb4(z, x, y, {"fence", "hedge"})
    if v == "charm": return t in {"grass", "tall_grass"}
    if v == "topple": return t in GOOD and nb4(z, x, y, {"tree_oak", "tree_pine"})
    if v in ("skim", "line"): return t in GOOD and nb4(z, x, y, WATER | {"shallow", "sea"})
    if v == "paddle": return t in GOOD and nb4(z, x, y, WATER | {"shallow"})
    if v == "snorkel": return t in GOOD and nb4(z, x, y, {"bog", "shallow", "water"})
    if v == "roll":
        if t not in {"grass", "tall_grass"} or not z.get("heights"): return t in {"grass"} and h(z["id"], x, y, "r") % 3 == 0
        hs = z["heights"]; return any(0 <= y + dy < len(hs) and 0 <= x + dx < len(hs[0]) and hs[y + dy][x + dx] != hs[y][x] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    if v == "loft": return t in {"grass", "tall_grass"} and nb4(z, x, y, PATHY)
    return False
VERBS = ["mend", "skim", "topple", "line", "round_up", "charm", "snorkel", "paddle", "roll", "loft"]

def reward(v, zid, i, level):
    k = h(zid, v, i, "rw") % 10
    if k < 5:
        return {"item": ITEMS[v][h(zid, v, i, "it") % len(ITEMS[v])], "qty": 1}, None
    if k < 8:
        m = 120 + 30 * level
        return {"money": m}, None
    return {"curio": CURIOS[h(zid, v, i, "cu") % len(CURIOS)]}, None

def levels(z):
    L = [int(e["max"]) for k in z.get("encounters", {}).values() for e in k if "max" in e]
    return max(L) if L else 8

def what_of(rw, itemnames):
    if "item" in rw: return itemnames.get(rw["item"], rw["item"].replace("_", " "))
    if "curio" in rw: return itemnames.get(rw["curio"], rw["curio"].replace("_", " "))
    return "money"

itemnames = {}
for f in glob.glob("data/items/*.json"):
    try:
        jj = json.load(open(f))
    except Exception: continue
    for i in (jj if isinstance(jj, list) else jj.get("items", []) if isinstance(jj, dict) else []):
        if isinstance(i, dict) and "id" in i: itemnames[i["id"]] = i.get("name", i["id"])

PROP = {"mend": "wall_gap", "skim": "skim_target", "topple": "dead_trunk", "line": "glint", "round_up": "sheep_gate", "charm": "molehill",
        "snorkel": "bog_pool", "paddle": "coracle", "roll": "cheese", "loft": "bale"}

out = collections.defaultdict(list)
used = collections.Counter()
for zid, z in sorted(zones.items()):
    if zid.startswith("lease_") or z["kind"] == "interior" or not z.get("rows") or not z["region"] or z["region"].startswith("overseas") or z["region"] == "dev": continue
    isroute = z["kind"] == "route"
    if not isroute and zid not in venues: continue
    w, hh = len(z["rows"][0]), len(z["rows"])
    n = 1 if w * hh < 2000 else (2 if w * hh < 5000 else 3)
    if not isroute: n = 1 if w * hh < 3500 else 2
    blockers = {(int(p.get("x", -9)), int(p.get("y", -9))) for k in ("props", "warps", "signs", "npcs", "examine") for p in z.get(k, []) if isinstance(p, dict)}
    blockers.add((int(z["spawn"][0]), int(z["spawn"][1])))
    for p in pois:
        if p["zone"] == zid: blockers.add((p["near"][0], p["near"][1]))
    r = reach(z)
    pathy = {(x, y) for y in range(hh) for x in range(w) if tile(z, x, y) in PATHY}
    def near_path(x, y):
        return any((x + dx, y + dy) in pathy for dx in range(-2, 3) for dy in range(-2, 3))
    cands = collections.defaultdict(list)
    for (x, y) in r:
        if x < 3 or y < 3 or x >= w - 3 or y >= hh - 3: continue
        if any(abs(x - bx) <= 1 and abs(y - by) <= 1 for bx, by in blockers): continue
        if not all((x + dx, y + dy) in r or tile(z, x + dx, y + dy) not in WALK for dx in (-1, 0, 1) for dy in (-1, 0, 1)): continue
        if sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (x + dx, y + dy) in r) < 3: continue
        if pathy and not near_path(x, y): continue
        for v in VERBS:
            if can(z, v, x, y): cands[v].append((x, y))
    chosen = []
    pref = [v for v in venues.get(zid, ()) if v]
    order = sorted(VERBS, key=lambda v: (v not in pref, used[v] + (h(zid, v) % 3), h(zid, "o", v)))
    lvl = levels(z)
    at = map_at(zid)
    for v in order:
        if len(chosen) >= n: break
        cl = sorted(cands[v], key=lambda p: h(zid, v, p))
        for p in cl:
            if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= 10 for q, _ in chosen):
                chosen.append((p, v)); used[v] += 1; break
    for i, (p, v) in enumerate(chosen):
        rw, _ = reward(v, zid, i, lvl)
        txt = TEXT[v][h(zid, v, "t") % 3].replace("{what}", what_of(rw, itemnames) if "money" not in rw else MONEY_WHAT[h(zid, v) % 4])
        e = {"id": "fs_%s_%s" % (zid, v), "zone": zid, "x": p[0], "y": p[1], "field": v, "prop": PROP[v], "text": txt,
             "reward": rw, "flag": "field_%s_%s" % (zid, v)}
        if at: e["at"] = at
        out[z["region"]].append(e)

# --- pairs: a coracle or a felled trunk takes you across a gap of water inside one zone ---
def find_pairs(z, verb, lo, hi):
    zid = z["id"]; w, hh = len(z["rows"][0]), len(z["rows"])
    r = reach(z)
    blockers = {(int(p.get("x", -9)), int(p.get("y", -9))) for k in ("props", "warps", "signs", "npcs", "examine") for p in z.get(k, []) if isinstance(p, dict)}
    blockers.add((int(z["spawn"][0]), int(z["spawn"][1])))
    for p in pois:
        if p["zone"] == zid: blockers.add((p["near"][0], p["near"][1]))
    taken = {(e["x"], e["y"]) for L in out.values() for e in L if e["zone"] == zid}
    bl = blockers | taken
    res = []
    for (x, y) in sorted(r, key=lambda p: h(zid, verb, p))[:6000]:
        if x < 4 or y < 4 or x >= w - 5 or y >= hh - 5: continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a = (x, y)
            if tile(z, *a) not in GOOD: continue
            pre = (x - dx, y - dy)
            if pre not in r or tile(z, *pre) not in WALK: continue
            for L in range(lo, hi + 1):
                if not all(tile(z, x + dx * k, y + dy * k) in WATER for k in range(1, L + 1)): continue
                b = (x + dx * (L + 1), y + dy * (L + 1))
                land = (b[0] + dx, b[1] + dy)
                if not (0 <= land[0] < w and 0 <= land[1] < hh): continue
                if tile(z, *b) not in GOOD or tile(z, *land) not in WALK: continue
                bad = {a, pre, b, land}
                if any((q[0] + ox, q[1] + oy) in bl for q in bad for ox in (-1, 0, 1) for oy in (-1, 0, 1)): continue
                if b in r:  # a shortcut round the water is fine, but it must save a real walk
                    continue
                res.append((a, pre, b, land, (dx, dy)))
                break
            if res and res[-1][0] == a: break
    return res

pair_n = collections.Counter()
for zid, z in sorted(zones.items()):
    if zid.startswith("lease_") or z["kind"] != "route" or not z.get("rows") or z["region"].startswith("overseas") or z["region"] == "dev": continue
    for verb, lo, hi in (("paddle", 2, 8), ("topple", 1, 3)):
        got = find_pairs(z, verb, lo, hi)
        if not got: continue
        a, pre, b, land, d = got[h(zid, verb) % len(got)]
        lvl = levels(z); at = map_at(zid)
        v = verb
        base = "fs_%s_%s_x" % (zid, v)
        if v == "paddle":
            t1 = "{lead} paddles you across in the little round boat, spinning once for good manners. The far bank is quiet, reedy and yours."
            t2 = "{lead} paddles you back. The boat drifts in a gentle circle the whole way, and nobody mentions it."
        else:
            t1 = "{lead} shoves the dead trunk over the gap, where it lands with a satisfying thump. You walk across, arms out like a tightrope act."
            t2 = "You cross back over the trunk, arms out. {lead} goes under the stream bank, which is its own business."
        e1 = {"id": base + "1", "zone": zid, "x": a[0], "y": a[1], "field": v, "prop": PROP[v], "text": t1, "reward": {"hop": [land[0], land[1]]}, "flag": "field_%s_%s_a" % (zid, v)}
        e2 = {"id": base + "2", "zone": zid, "x": b[0], "y": b[1], "field": v, "prop": PROP[v], "text": t2, "reward": {"hop": [pre[0], pre[1]]}, "flag": "field_%s_%s_b" % (zid, v)}
        if at: e1["at"] = at; e2["at"] = at
        out[z["region"]] += [e1, e2]
        pair_n[v] += 1

total = 0
os.makedirs("data/field_spots", exist_ok=True)
for f in glob.glob("data/field_spots/*.json"): os.remove(f)
for region, L in sorted(out.items()):
    json.dump(L, open("data/field_spots/%s.json" % region, "w"), indent=1, ensure_ascii=False)
    total += len(L)
print(total, "spots in", len(out), "regions; pairs", dict(pair_n))
