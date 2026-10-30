#!/usr/bin/env python3
"""Places the points of interest (data/poi/<region>.json) on free, reachable, walkable tiles of the outdoor routes.
Deterministic: run it again and the files come out the same. Usage: python3 tools/poi/gen_poi.py"""
import json, glob, os, hashlib, collections

def h(*a):
    return int(hashlib.md5("|".join(map(str, a)).encode()).hexdigest()[:8], 16)

LEG = {".": ("grass", 1), ",": ("tall_grass", 1), "#": ("path", 1), "=": ("road", 1), ":": ("cobbles", 1), "s": ("sand", 1),
       "f": ("flowers", 1), "w": ("shallow", 1), "D": ("door", 1)}
WALK = {"grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "door"}
GOOD = {"grass", "tall_grass", "path", "flowers", "sand"}

zones = {}
for f in glob.glob("data/zones/*.json"):
    d = json.load(open(f)); zones[d["id"]] = d
dex = {}
for f in glob.glob("data/creatures/*.json"):
    d = json.load(open(f))
    for sp_ in ([d] if "base" in d else d.get("species", [])):
        if "id" in sp_ and "base" in sp_: dex[sp_["id"]] = sp_
mp = json.load(open("data/world_map.json"))
onmap = set(mp["towns"]) | set(mp["places"])

def tile(z, x, y):
    c = z["rows"][y][x]
    le = z.get("legend_extra", {})
    if c in le:
        if le[c].get("prop") not in (None, "none"):
            return "prop"
        return le[c].get("tile", "")
    return LEG.get(c, ("", 0))[0]

def reach(z):
    w, hh = len(z["rows"][0]), len(z["rows"])
    sx, sy = z["spawn"][:2]
    seen = {(sx, sy)}; q = [(sx, sy)]
    while q:
        x, y = q.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < hh and (nx, ny) not in seen and tile(z, nx, ny) in WALK:
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

def town_npc(zid):
    """A resident of a neighbouring town (outdoor) who might mention this place."""
    for e in zones[zid].get("edges", {}).values():
        t = zones.get(e["to"])
        if t and t["kind"] == "town":
            ns = [n for n in t.get("npcs", []) if not n.get("trainer") and n.get("script") and not n["sprite"].startswith("creature:")]
            if ns:
                return {"zone": t["id"], "npc": ns[h(zid, "ment") % len(ns)]["id"]}
    return None

STONES = {
 "cheshire": [("the Bridestones", "near Congleton, on the Cheshire and Staffordshire border", "a Neolithic burial chamber that has lost most of its mound")],
 "peak": [("Arbor Low", "in the Derbyshire Peak District", "a henge of fallen limestone slabs, shaped like a dropped clock face"), ("the Nine Ladies", "on Stanton Moor in Derbyshire", "a small Bronze Age circle, said to be dancers caught out by the Sabbath")],
 "cumbria": [("Castlerigg", "near Keswick", "a ring of 38 stones with mountains all the way round, and arguably the best view of any circle"), ("Long Meg and Her Daughters", "near Penrith", "a huge red sandstone stone beside a ring of its daughters")],
 "manchester": [("Arbor Low", "in the Derbyshire Peak District", "a henge of fallen limestone slabs")],
 "merseyside": [("the Bridestones", "near Congleton in Cheshire", "a Neolithic burial chamber")],
 "midlands": [("the Rollright Stones", "on the Oxfordshire and Warwickshire border", "a circle called the King's Men, with the King's Stone across the road")],
 "east_anglia": [("Seahenge", "at Holme-next-the-Sea in Norfolk", "a ring of oak posts found on the beach in 1999, now in a museum in King's Lynn")],
 "south_england": [("Avebury", "in Wiltshire", "the largest stone circle in Britain, with a village built through the middle of it"), ("Stonehenge", "on Salisbury Plain", "the famous one, with lintels")],
 "south_east": [("Kit's Coty House", "near Aylesford in Kent", "a Neolithic burial chamber, three uprights and a capstone")],
 "cornwall": [("the Merry Maidens", "near Lamorna in Cornwall", "19 stones said to be girls turned to granite for dancing on a Sunday"), ("the Hurlers", "on Bodmin Moor", "three circles in a row, and the men who played hurling on a Sunday")],
 "yorkshire": [("the Devil's Arrows", "at Boroughbridge in North Yorkshire", "three tall gritstone stones in a line beside the A1")],
 "north_east": [("Duddo Five Stones", "in Northumberland", "five weathered stones, grooved by the rain")],
 "north_wales": [("Bryn Celli Ddu", "on Anglesey", "a passage tomb that lights up at the summer solstice"), ("the Druids' Circle", "above Penmaenmawr", "a small ring on the hillside above the sea")],
 "mid_wales": [("Pentre Ifan", "in Pembrokeshire, a good day south", "a dolmen with a capstone big enough to shelter a cow")],
 "south_wales": [("Pentre Ifan", "in Pembrokeshire", "a dolmen with a capstone big enough to shelter a cow"), ("Gors Fawr", "in the Preseli Hills", "a ring of 16 small stones, with two big ones outside")],
 "scotland": [("Callanish", "on the Isle of Lewis", "a cross of standing stones, about 5,000 years old"), ("the Ring of Brodgar", "on Orkney", "a huge ring of upright slabs on a spit between two lochs"), ("Machrie Moor", "on the Isle of Arran", "a moor full of rings, one with a tall granite slab"), ("the Clava Cairns", "near Inverness", "ring cairns inside circles of standing stones, among old beeches")],
 "ireland": [("Drombeg", "near Glandore in Co. Cork", "a ring of 17 stones with a recumbent stone pointing at the midwinter sunset"), ("Beaghmore", "in Co. Tyrone", "a field of small circles and rows of stones coming up out of the bog")],
 "ireland_east": [("Newgrange", "in Co. Meath", "a passage tomb older than the Pyramids, lit by the midwinter sunrise"), ("the Lia Fail", "on the Hill of Tara in Co. Meath", "a standing stone where the High Kings were said to be crowned")],
 "ireland_west": [("Carrowmore", "in Co. Sligo", "one of the biggest cemeteries of megalithic tombs in Ireland"), ("Poulnabrone", "in the Burren, Co. Clare", "a dolmen on bare limestone, with a capstone like a table")],
 "channel_islands": [("La Hougue Bie", "in Jersey", "a Neolithic passage grave under a mound with a chapel on top")],
}
FLAV = ["It is cold, and it hums very faintly, the way a fridge does.", "You put a hand on it. It is older than your whole family tree, put together.",
        "Lichen has been at it for a few thousand years and has barely got started.", "Sheep have rubbed one side smooth. Even the sheep come here.",
        "It leans, slightly, like it has heard all this before.", "The wind drops when you stand beside it. You do not mention this to anyone.",
        "Someone has left a single conker on top. Sensible."]
STATS = ["hp", "atk", "def", "lore", "ward", "spd"]
CACHE_ITEMS = [("hag_stone",), ("rowan_sprig",), ("oak_acorn",), ("silver_snare",), ("iron_snare",), ("night_snare",), ("water_snare",),
               ("flat_cap_yorkshire",), ("bobble_hat_red",), ("sunhat_straw",), ("sou_wester_yellow",), ("burns_tam",), ("deerstalker_tweed",),
               ("hard_hat_yellow",), ("headscarf_tartan",), ("kendal_mint_cake",), ("cream_tea",), ("four_leaf_clover",), ("horseshoe",), ("lucky_chip",), ("miners_lamp",)]
CACHE_LINES = ["A biscuit tin, wedged behind the rock. The lid took three goes.", "A hollow in the old tree, and something wrapped in oilcloth.",
               "Someone's hiding place, and not as hidden as they hoped.", "A flask-sized tin under a flat stone, tied with garden twine.",
               "Behind the rock there is a gap, and in the gap there is a lunchbox.", "A hollow tree has been used as a post box by someone with no postman."]
PAPERS = ["Scrawled inside the lid: 'If found, you may keep it. If you are Gareth, put it back.'", "A note says: 'Gone to the chippy. Back never.'",
          "A note, in careful capitals: 'FINDERS KEEPERS. SIGNED, THE MOORSIDE GANG, AGED NINE.'", "There is a scrap of paper too: 'Hid this in 1987. Hope the sheep were kind.'",
          "A pencilled card: 'To whoever is nosy enough, well done.'"]
CAMP_NAMES = [("Poacher Rab", "Poacher"), ("Poacher Dilys", "Poacher"), ("Poacher Seamus", "Poacher"), ("Trapper Moira", "Trapper"), ("Lamper Ged", "Lamper"), ("Poacher Bronwen", "Poacher")]
CAMP_LINES = ["This is a private camp. Private as in 'mind your own'.", "You didn't see us. We didn't see you. Except now we have.", "The lamping's good here. Was good here."]
CAMP_ITEMS = ["silver_snare", "iron_snare", "night_snare", "water_snare", "kendal_mint_cake", "cream_tea", "flask_of_tea", "hag_stone", "rowan_sprig"]

def levels(z):
    L = [int(e["max"]) for k in z.get("encounters", {}).values() for e in k if "max" in e]
    return (min(L), max(L)) if L else (5, 8)

def species_of(z):
    return [e["species"] for k in z.get("encounters", {}).values() for e in k if e["species"] in dex]

by_region = collections.defaultdict(list)
for zid, z in sorted(zones.items()):
    if z["kind"] == "route" and z.get("encounters") and not z["region"].startswith("overseas") and z["region"] != "dev" and z.get("rows"):
        by_region[z["region"]].append(z)

out = collections.defaultdict(list)
for region, zl in sorted(by_region.items()):
    for z in zl:
        w, hh = len(z["rows"][0]), len(z["rows"])
        n = 1 if w * hh < 1400 else (2 if w * hh < 4200 else 3)
        if len(zl) == 1: n = max(n, 2)
        kinds_all = ["den", "camp", "stone", "cache"]
        order = sorted(kinds_all, key=lambda k: h(z["id"], "k", k))
        r = reach(z)
        blockers = {(int(p.get("x", -9)), int(p.get("y", -9))) for p in z.get("props", [])}
        blockers |= {(int(p["x"]), int(p["y"])) for p in z.get("warps", [])}
        blockers |= {(int(p["x"]), int(p["y"])) for p in z.get("signs", [])}
        blockers |= {(int(p["x"]), int(p["y"])) for p in z.get("npcs", [])}
        blockers.add(tuple(z["spawn"][:2]))
        cands = []
        for (x, y) in r:
            if x < 3 or y < 3 or x >= w - 3 or y >= hh - 3: continue
            if tile(z, x, y) not in GOOD: continue
            if any(abs(x - bx) <= 1 and abs(y - by) <= 1 for bx, by in blockers): continue
            # open ground around: 8 neighbours all reachable, so it is approachable from every side
            if not all((x + dx, y + dy) in r for dx in (-1, 0, 1) for dy in (-1, 0, 1)): continue
            cands.append((x, y))
        cands.sort(key=lambda p: h(z["id"], p))
        chosen = []
        for p in cands:
            if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= 12 for q in chosen):
                chosen.append(p)
            if len(chosen) == n: break
        lo, hi = levels(z)
        mine = set(species_of(z))
        pool = []
        for o in zl:
            for s in species_of(o):
                if s not in mine and dex[s]["catch_rate"] >= 25 and s not in pool: pool.append(s)
        if not pool:
            for o in zones.values():
                if o["region"] == region:
                    for s in species_of(o):
                        if s not in mine and dex[s]["catch_rate"] >= 25 and s not in pool: pool.append(s)
        for i, p in enumerate(chosen):
            kind = order[i % 4]
            if kind == "stone" and region not in STONES: kind = "cache"
            if kind == "den" and not pool: kind = "cache"
            if kind == "camp" and not mine: kind = "cache"
            pid = "poi_%s_%s" % (z["id"], kind if sum(1 for q in out[region] if q["zone"] == z["id"] and q["kind"] == kind) == 0 else kind + str(i))
            e = {"id": pid, "zone": z["id"], "near": [p[0], p[1]], "kind": kind}
            at = map_at(z["id"])
            if at: e["at"] = at
            sp = sorted(mine)
            if kind == "den":
                e["species"] = pool[h(pid, "sp") % len(pool)]
            elif kind == "camp":
                nm = h(pid, "n") % len(CAMP_NAMES)
                e["names"] = [CAMP_NAMES[(nm + j) % len(CAMP_NAMES)] for j in range(2 + h(pid, "c") % 2)]
                e["party"] = [sp[(h(pid, "p", j) % len(sp))] for j in range(3)]
                e["line"] = CAMP_LINES[h(pid, "l") % len(CAMP_LINES)]
                e["money"] = 300 + 40 * hi
                e["item"] = CAMP_ITEMS[h(pid, "i") % len(CAMP_ITEMS)]
            elif kind == "stone":
                st = STONES[region][h(pid, "s") % len(STONES[region])]
                e["stat"] = STATS[h(pid, "stat") % 6]
                e["lore"] = [FLAV[h(pid, "f") % len(FLAV)], "The real thing is %s, %s: %s." % (st[0], st[1], st[2])]
            else:
                e["item"] = CACHE_ITEMS[h(pid, "ci") % len(CACHE_ITEMS)][0]
                e["line"] = CACHE_LINES[h(pid, "cl") % len(CACHE_LINES)]
                if h(pid, "pp") % 3 == 0: e["paper"] = PAPERS[h(pid, "pa") % len(PAPERS)]
                if h(pid, "cu") % 4 == 0: e["curio"] = True
            if h(pid, "m") % 3 == 0:
                m = town_npc(z["id"])
                if m: e["mentioned_by"] = m
            out[region].append(e)

total = 0
for region, L in out.items():
    json.dump({"pois": L}, open("data/poi/%s.json" % region, "w"), indent=1, ensure_ascii=False)
    total += len(L)
print(total, "pois in", len(out), "regions", collections.Counter(e["kind"] for L in out.values() for e in L))
