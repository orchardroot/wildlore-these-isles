#!/usr/bin/env python3
"""Places the flotsam (data/flotsam.json): crates, lobster pots, bottles and island caches on or beside water that only
a coracle reaches (Brook-wade on rivers and lakes, Tide-ride on the near sea). Deterministic: every choice is a
hash of the zone and tile, so re-running gives the same file. Usage: python3 tools/flotsam/gen_flotsam.py
The rules it mirrors live in tools/flotsam/ridemap.py; core/flotsam.gd re-checks every find with the real ones."""
import json, hashlib, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from ridemap import load_zones, DIRS

def h(*a):
    return int(hashlib.md5("|".join(map(str, a)).encode()).hexdigest()[:8], 16)

# --- what is on offer: modest, existing items only (no money, nothing that pays out twice) ---
CRATE_ITEMS = ["pasty", "flask_of_tea", "tablet", "parkin", "cup_of_tea", "wicker_snare", "buxton_water", "bara_brith", "soda_bread", "pork_pie"]
SEA_POTS = ["mackerel", "herring", "whiting", "pollack", "plaice", "haddock", "cod", "ballan_wrasse"]
FRESH_POTS = ["roach", "perch", "rudd", "chub", "tench", "brown_trout", "european_eel"]
CACHE_ITEMS = ["heather_honey", "honeycomb", "hazelnuts", "truffle", "ammonite", "hawthorn_berry", "rowan_berry", "bakewell_tart", "lavender_sachet", "wicker_snare"]
BOTTLE_ITEMS = ["sea_glass", "sea_glass", "crab_bait"]  # a bottle at sea
BOTTLE_RIVER_ITEMS = ["slate_chip"]  # in a river: a pebble of grit the sender enclosed

CRATE_TEXT = [
    "A wooden crate, adrift and unclaimed. The lid is nailed down, and the stencil says it came from a port nobody can place.",
    "A crate marked THIS WAY UP. It has not been this way up for some time. You fish it out with the paddle.",
    "A tea chest bobs past like it has somewhere to be. You hook it, and it comes quietly.",
    "A sealed tin box, tarred at the seams, floating low. Somebody's emergency rations, and somebody's loss.",
    "A fish box with a crew's initials burned into the lid. Somebody is going to be cross about this, but not today.",
    "A crate roped to a plastic float and let go by the look of it. You decide it counts as a gift from the water.",
]
POT_SEA_TEXT = [
    "A lobster pot, adrift, its rope chewed through. Whatever was in it has been in there a while, and you are now the legal owner.",
    "A creel bobbing on its own float, with no one's name on it. Inside, a fish with the look of someone who has given up arguing.",
    "A lobster pot snagged on a ring of weed. No lobster. One surprised fish, which is something.",
]
POT_FRESH_TEXT = [
    "An eel trap, forgotten and half sunk, its owner long gone. One fish in it, sulking.",
    "A wicker fish trap hanging from a branch in the water. It has caught something and is a little embarrassed about it.",
    "A keepnet left out in the water by an angler who clearly went home for his tea. One fish still in it. You do the decent thing, mostly.",
]
CACHE_TEXT = [
    "A cairn on the far bank, a flat stone, a tin underneath. Somebody else paddled out here once and hoped to come back for it.",
    "A hollow under a thorn bush, out of reach of anyone on foot. Inside, wrapped in oilcloth: provisions, and a note that just says 'Told you.'",
    "Dry sand above the tide line and a tin wedged in the rocks. Not a pirate's, but somebody's, and they are not here.",
    "Whoever hid this had a boat and a plan. You have a boat, and now the plan has been found.",
    "A crate lashed under an overhang, tied with fisherman's knots you do not know. It opens at the second try.",
]

# --- messages in bottles: one per place, short and true. Only zones named here get a bottle. ---
BOTTLES = {
    "bath": "To whoever finds this: the Romans called this place Aquae Sulis and built a spa. We have a weir and a great many tourists. Please send soap.",
    "oxford": "Dear Finder. The Thames is called the Isis here, and people argue about why. Punting is harder than it looks. Yours, damp.",
    "cambridge": "The Mathematical Bridge at Queens' is said to have been built by Newton, with no fixings. It went up in 1749, long after Newton died. Still a good story. A punter.",
    "newcastle": "Seven bridges over the Tyne between Newcastle and Gateshead, and I still managed to end up on the wrong side of it.",
    "hull": "The Humber Bridge was the longest single-span suspension bridge in the world when it opened in 1981. It isn't any more. I am still proud of it. Hull.",
    "dundee": "Captain Scott's Discovery was built here in 1901. She is moored at the quay and has never once tried to leave. Lovely lass.",
    "glasgow": "The Clyde built ships for half the world. Mind the Squinty Bridge: it is not drunk, it is angled.",
    "belfast": "Built in Belfast: the Titanic, and a great many other ships that stayed afloat. We would like to be known for the second bit.",
    "dublin": "The Ha'penny Bridge charged a halfpenny toll until 1919. Inflation has been unkind to everything except the view.",
    "galway": "The Spanish Arch is part of the old city wall, put up in 1584, and named for the Spanish trade. It is very good at standing there.",
    "cork": "The middle of Cork is an island, because the Lee splits round it. Ask a Corkonian and you will get a longer answer than you wanted.",
    "limerick": "King John's Castle was built in the early 1200s and has had a lot of visitors since. A few of them brought cannon.",
    "london": "The summer of 1858 was so hot the Thames smelled terrible and they called it the Great Stink. Parliament hung curtains soaked in lime. Sincerely, a bottle.",
    "keswick": "St Herbert wanted peace and quiet on an island in Derwentwater, and a visit once a year from his friend Cuthbert. I'd say he got the better deal.",
    "llangollen": "Pontcysyllte Aqueduct carries the canal 126 feet above the Dee, and one side of it is nothing but air. I went at walking pace. So did the boat.",
    "ironbridge_gorge": "The Iron Bridge opened in 1781, the first big bridge made of cast iron. It has not given up, which is better than I can say for my knees.",
    "anglesey": "Telford's bridge has carried people over the Menai Strait since 1826. The Strait has a strong opinion about it, twice a day.",
    "penzance": "You can walk to St Michael's Mount at low tide. You can swim back at high tide. Check the table. I did not.",
    "forth_bridges": "The Forth Bridge, 1890. The Road Bridge, 1964. The Queensferry Crossing, 2017. Painting the first one used to mean a job that never ends. They finished in 2011. The saying is retired.",
    "severn_crossing": "The Severn Bore is a wave that runs up the river on the big tides. Surfers love it. The river was not asked.",
    "dingle": "Fungie the dolphin lived in Dingle harbour for nearly forty years and charged nobody a penny. The boats charged you.",
    "poole": "Brownsea Island held the first Scout camp in 1907. They still have red squirrels. The squirrels are not in the Scouts.",
    "fort_william": "Neptune's Staircase is eight locks on the Caledonian Canal and takes about an hour and a half to climb. Be patient. The mountain will wait.",
    "great_glen": "The Caledonian Canal joins four lochs with 22 miles of digging, because the rest was lake. Telford was thrifty.",
    "harris": "Harris and Lewis are the same island. Please don't say so out loud.",
    "lerwick": "At Up Helly Aa they build a Viking galley every January, to burn it. I think of this when I think about my own plans.",
    "kirkwall": "St Magnus Cathedral has stood since 1137, built of red and yellow sandstone, like a stripy scarf.",
    "manchester": "The Ship Canal opened in 1894 and made Manchester a port, 36 miles from the sea. Manchester was thrilled. Liverpool was less so.",
    "bristol": "Brunel's SS Great Britain sailed from here to Australia. She has come home, and sits in dry dock under a glass plate that looks like water.",
    "exeter": "Exeter's canal dates from the 1560s, one of the oldest in England. Nobody has told the swans.",
    "brighton": "The West Pier burned twice in 2003 and has been a skeleton ever since. The starlings have moved in.",
    "gower": "Worm's Head is not a worm. It is an island with a causeway that vanishes at high tide. Do not be the person on the rocks.",
    "pembroke_coast": "Skomer's puffins all look as though they have just remembered something important.",
    "cambrian_coast": "Under Cardigan Bay lies Cantre'r Gwaelod, the drowned lowland hundred. The bells still ring under the waves, they say. I listened. Wet.",
    "loch_ness": "Seen nothing. Not for want of looking. Possibly it is looking for me.",
    "stornoway": "Harris Tweed has to be handwoven by islanders in their own homes. I am not woven. I am glass.",
    "aberystwyth": "The cliff railway on Constitution Hill is said to be the longest in Britain. It is very slow and I love it.",
    "chester": "Chester's Roodee racecourse says it is among the oldest in the world. The horses have yet to confirm.",
}

TARGET = {"bottle": 22, "crate": 18, "pot": 14, "cache": 12}
MIN_ZONES = 44

def region_ok(z):
    r = str(z.d.get("region", ""))
    return not (r.startswith("overseas") or r.startswith("abroad") or r == "dev")

def near_water_dist(z, wet, base):
    """Distance (steps) of each wet water tile from the nearest tile that is not water."""
    dist = {}
    q = []
    for p in wet:
        if z.tile(*p) in ("water", "sea"):
            if any(z.tile(p[0] + dx, p[1] + dy) not in ("water", "sea") for dx, dy in DIRS):
                dist[p] = 1
                q.append(p)
    i = 0
    while i < len(q):
        p = q[i]; i += 1
        for dx, dy in DIRS:
            n = (p[0] + dx, p[1] + dy)
            if n not in dist and z.tile(*n) in ("water", "sea") and n in wet:
                dist[n] = dist[p] + 1
                q.append(n)
    return dist

def occupied(z, f_spots, poi):
    taken = set(z.blocked) | z.walls
    for k in ("warps", "npcs", "signs", "examine", "props"):
        for p in z.d.get(k, []):
            if "x" in p:
                taken.add((int(p["x"]), int(p["y"])))
    taken.add((int(z.d["spawn"][0]), int(z.d["spawn"][1])))
    taken |= f_spots.get(z.id, set()) | poi.get(z.id, set())
    return taken

def load_taken():
    f_spots, poi = {}, {}
    import glob
    for f in glob.glob("data/field_spots/*.json"):
        for s in json.load(open(f)):
            f_spots.setdefault(s["zone"], set()).add((int(s["x"]), int(s["y"])))
    for f in glob.glob("data/poi/*.json"):
        for p in json.load(open(f)).get("pois", []):
            nx, ny = int(p["near"][0]), int(p["near"][1])  # core/poi.gd lands it on the nearest walkable tile
            for dx in range(-3, 4):
                for dy in range(-3, 4):
                    poi.setdefault(p["zone"], set()).add((nx + dx, ny + dy))
    return f_spots, poi

def candidates(zones, arrivals, f_spots, poi):
    out = {}
    for zid, z in sorted(zones.items()):
        if not z.ride_zone or not region_ok(z) or not any(c in r for r in z.rows for c in ("~", "$")):
            continue
        sp = (int(z.d["spawn"][0]), int(z.d["spawn"][1]))
        if not z.walk(sp[0], sp[1], sp[0], sp[1], False):
            continue
        ents = {sp} | arrivals.get(zid, set())
        for s in z.edges:
            for x in range(z.w):
                for y in range(z.h):
                    if (s == "north" and y == 0) or (s == "south" and y == z.h - 1) or (s == "west" and x == 0) or (s == "east" and x == z.w - 1):
                        if z.walk(x, y, x, y, False):
                            ents.add((x, y))
        base = set()
        for e in ents:
            if z.walk(e[0], e[1], e[0], e[1], False):
                base |= z.reach(e, False)
        wet = z.reach(sp, True)
        taken = occupied(z, f_spots, poi)
        dist = near_water_dist(z, wet, base)
        floats, caches = [], []
        for p in sorted(wet):
            if p in taken:
                continue
            t = z.tile(*p)
            nb = [(p[0] + dx, p[1] + dy) for dx, dy in DIRS]
            if t in ("water", "sea"):
                near_base = any((p[0] + dx, p[1] + dy) in base for dx in (-1, 0, 1) for dy in (-1, 0, 1))
                if not near_base and sum(1 for n in nb if n in wet) >= 3 and 2 <= dist.get(p, 0) <= 6 \
                        and p[0] > 1 and p[1] > 1 and p[0] < z.w - 2 and p[1] < z.h - 2:
                    floats.append(p)
            elif p not in base and t in ("grass", "sand", "flowers") and any(n in wet and z.tile(*n) in ("water", "sea") for n in nb) \
                    and sum(1 for n in nb if z.tile(*n) in ("water", "sea") and n in wet) >= 1 \
                    and p[0] > 1 and p[1] > 1 and p[0] < z.w - 2 and p[1] < z.h - 2:
                caches.append(p)
        if floats or caches:
            out[zid] = {"floats": floats, "caches": caches}
    return out

def pick(lst, zid, salt, used):
    ranked = sorted(lst, key=lambda p: h(zid, salt, p[0], p[1]))
    for p in ranked:
        if all(abs(p[0] - u[0]) + abs(p[1] - u[1]) > 6 for u in used):
            return p
    return None

def main():
    zones = load_zones()
    arrivals = {}
    for z in zones.values():
        for w in z.d.get("warps", []):
            arrivals.setdefault(w["to"], set()).add((int(w["tx"]), int(w["ty"])))
    f_spots, poi = load_taken()
    cand = candidates(zones, arrivals, f_spots, poi)
    finds = []
    count = {k: 0 for k in TARGET}
    used = {}
    n_of = {}

    def add(zid, kind, p, text, item, qty=1):
        n_of[zid] = n_of.get(zid, 0) + 1
        k = n_of[zid]
        finds.append({"id": "fl_%s_%d" % (zid, k), "zone": zid, "x": p[0], "y": p[1], "kind": kind, "text": [text],
                      "reward": {"item": item, "qty": qty}, "flag": "flotsam_%s_%d" % (zid, k)})
        used.setdefault(zid, []).append(p)
        count[kind] += 1

    order = sorted(cand, key=lambda z: h("order", z))
    # bottles first: only where a message was written and a float spot exists
    for zid in order:
        if count["bottle"] >= TARGET["bottle"]:
            break
        if zid in BOTTLES and cand[zid]["floats"]:
            p = pick(cand[zid]["floats"], zid, "bottle", used.get(zid, []))
            if p:
                items = BOTTLE_ITEMS if zones[zid].tile(*p) == "sea" else BOTTLE_RIVER_ITEMS
                add(zid, "bottle", p, BOTTLES[zid], items[h(zid, "bi") % len(items)])
    # caches on islets and far banks
    for zid in order:
        if count["cache"] >= TARGET["cache"]:
            break
        if cand[zid]["caches"] and region_ok(zones[zid]):
            p = pick(cand[zid]["caches"], zid, "cache", used.get(zid, []))
            if p:
                add(zid, "cache", p, CACHE_TEXT[h(zid, "ct") % len(CACHE_TEXT)], CACHE_ITEMS[h(zid, "ci") % len(CACHE_ITEMS)])
    # crates and pots, spread over as many zones as it takes (fewest finds first)
    rounds = 0
    while (count["crate"] < TARGET["crate"] or count["pot"] < TARGET["pot"] or len(n_of) < MIN_ZONES) and rounds < 4:
        rounds += 1
        for zid in sorted(order, key=lambda z: (n_of.get(z, 0), h("r", rounds, z))):
            if count["crate"] >= TARGET["crate"] and count["pot"] >= TARGET["pot"] and len(n_of) >= MIN_ZONES:
                break
            if n_of.get(zid, 0) >= 2 or not cand[zid]["floats"]:
                continue
            want_pot = count["pot"] < TARGET["pot"] and (h(zid, "wp", rounds) % 5 < 2 or count["crate"] >= TARGET["crate"])
            if not want_pot and count["crate"] >= TARGET["crate"]:
                if len(n_of) >= MIN_ZONES:
                    continue
                want_pot = count["pot"] < TARGET["pot"]
            p = pick(cand[zid]["floats"], zid, "cp%d" % rounds, used.get(zid, []))
            if not p:
                continue
            sea = zones[zid].tile(*p) == "sea"
            if want_pot and count["pot"] < TARGET["pot"]:
                items = SEA_POTS if sea else FRESH_POTS
                texts = POT_SEA_TEXT if sea else POT_FRESH_TEXT
                add(zid, "pot", p, texts[h(zid, "pt", p[0]) % len(texts)], items[h(zid, "pi", p[1]) % len(items)], 1 + h(zid, "pq") % 2)
            elif count["crate"] < TARGET["crate"] or len(n_of) < MIN_ZONES:
                add(zid, "crate", p, CRATE_TEXT[h(zid, "xt", p[0]) % len(CRATE_TEXT)], CRATE_ITEMS[h(zid, "xi", p[1]) % len(CRATE_ITEMS)])
    finds.sort(key=lambda f: (f["zone"], f["id"]))
    with open("data/flotsam.json", "w") as fh:
        json.dump(finds, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    print("flotsam: %d finds in %d zones %s" % (len(finds), len(n_of), count))

if __name__ == "__main__":
    main()
