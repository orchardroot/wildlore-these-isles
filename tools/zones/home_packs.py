"""Regional packs and occupation hints for the homes (w53 rooms).

    python3 tools/zones/home_packs.py data/zones [--dry]

Dresses every home that furnish.py already furnished, deterministically on the same `furnish:<zid>` seed. It only
changes `props`: sofas become settles, beds become box beds (same tile, same turn), generic sofas, plants and
stands may make way for a regional piece, and a few wall hangings and floor pieces are added. It never touches
an NPC, a warp, a sign, the spawn, an `examine` tile or anything under one, and it keeps furnish.py's reachability
checks. It is not idempotent: `git checkout data/zones` before running it again.
"""
import json, random, re, sys, glob, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from furnish import Room

NOT_HOMES = ("lighthouse", "palmhouse", "customhouse", "boathouse", "bakehouse", "warehouse", "woolhouse",
             "tollhouse", "guesthouse", "jewshouse", "testbed", "homepark", "painted_house", "lasthouse")
GENERIC = ("sofa", "plant_stand", "potted_plant")  # what may make way (never a picture, shelf, table, bed or fireplace)
HANGERS = ("window", "wall_map", "mirror", "dartboard", "wall_picture", "clock", "menu_board")

HARBOUR = {"aberystwyth", "holyhead", "penzance", "plymouth", "oban", "stornoway", "kirkwall", "lerwick", "thurso",
           "douglas", "cork", "dingle", "galway", "dover", "cairnryan", "adamstown", "portree", "belfast", "sligo"}
ISLES = {"stornoway", "harris", "portree", "skye"}
SLATE = {"llanberis"}

# what a resident talks about: first match above the threshold wins (the second hint is the next one)
TOPICS = [
    ("fish", r"\b(fisher\w*|trawl\w*|herring|lobsters?|crabs?|creels?|mackerel|skipper)\b", 1),
    ("sky", r"\b(stars?|telescope|astronom\w*|planets?|comet|observatory)\b", 1),
    ("teach", r"\b(teach\w*|pupils?|marking|lecturer|classroom)\b", 1),
    ("student", r"\b(students?|universit\w*|essays?|degrees?|exams?|lectures?)\b", 1),
    ("music", r"\b(fiddle|harp|singing|choir|accordion|piano|bagpipes?)\b", 1),
    ("loom", r"\b(weav\w*|knit\w*|tweed|spinning|sewing|stitch\w*)\b", 1),
    ("slate", r"\bslate\b", 1),
    ("art", r"\b(paint\w*|artists?|sketch\w*)\b", 1),
    ("sport", r"\b(football|rugby|darts|cricket|hurling|gaa|snooker)\b", 1),
    ("cat", r"\b(cats?|kittens?)\b", 1),
    ("dog", r"\b(dogs?|collie|sheepdog|puppy)\b", 1),
    ("farm", r"\b(farm\w*|sheep|cows?|cattle|lambs?|crofts?|crofters?)\b", 1),
    ("book", r"\b(novels?|poets?|poems?|writers?|authors?|librar\w*)\b", 1),
    ("cook", r"\b(bak\w*|recipes?|cakes?|stew)\b", 2),
    ("garden", r"\b(gardens?|allotment|roses)\b", 1),
]


def topics(zid):
    f = os.path.join("data", "dialogue", zid + ".json")
    if not os.path.exists(f):
        return []
    text = " ".join(re.findall(r'"text": "([^"]*)"', open(f).read())).lower()
    scored = []
    for name, rx, need in TOPICS:
        n = len(re.findall(rx, text))
        if n >= need:
            scored.append((n / need, name))
    return [n for _, n in sorted(scored, reverse=True)]


class Dresser:
    def __init__(s, d, examine):
        s.d = d
        s.r = Room(d["rows"], d["props"], d["npcs"], d["warps"], d["spawn"], d.get("signs", []))
        s.rng = random.Random("furnish:" + d["id"])
        s.keep = {(int(e["x"]), int(e["y"])) for e in examine}
        s.hung = {(int(p["x"]), int(p["y"])) for p in d["props"] if p["type"] in HANGERS}
        s.added = []

    def prop_at(s, x, y):
        for p in s.d["props"]:
            if int(p["x"]) == x and int(p["y"]) == y and not p.get("walk") and p["type"] != "building":
                return p
        return None

    def put(s, p):
        s.d["props"].append(p)
        s.added.append(p["type"])

    def block(s, t, x, y, **kw):
        """A blocking piece on a free tile (or one a generic piece vacates), reachability kept."""
        if (x, y) in s.keep:
            return False
        old = s.prop_at(x, y)
        if old is not None:
            if old["type"] not in GENERIC:
                return False
            s.d["props"].remove(old)
            s.r.occ.pop((x, y), None)
        if s.r.add_block(t, x, y, **kw):
            p = s.r.new.pop()
            s.put(p)
            return True
        if old is not None:  # put it back
            s.d["props"].append(old)
            s.r.occ[(x, y)] = old["type"]
        return False

    def hang(s, t, x, y=1, rot=0):
        r = s.r
        if (x, y) in s.keep or (x, y) in s.hung or not r.floor(x, y) or (x, y) in r.exits or (x, y) in r.signs:
            return False
        if (x, y) in r.occ and not (y == 1 and r.occ[(x, y)] in ("table", "bench", "bed", "sofa")):
            return False
        p = {"type": t, "x": x, "y": y, "walk": True}
        if rot:
            p["rot"] = rot
        s.hung.add((x, y))
        s.put(p)
        return True

    def hang_north(s, t):
        xs = list(range(1, s.r.w - 1))
        s.rng.shuffle(xs)
        return any(s.hang(t, x) for x in xs)

    def hang_side(s, t):
        spots = [(1, y, 90) for y in range(2, s.r.h - 3)] + [(s.r.w - 2, y, 270) for y in range(2, s.r.h - 3)]
        s.rng.shuffle(spots)
        for x, y, rot in spots:
            if s.r.occ.get((x, y)) is None and s.hang(t, x, y, rot):
                return True
        return False

    def wall_block(s, t, **kw):
        xs = list(range(1, s.r.w - 1))
        s.rng.shuffle(xs)
        return any(s.block(t, x, 1, **kw) for x in xs)

    def corner(s, t, **kw):
        r = s.r
        spots = [(1, r.h - 4), (r.w - 2, r.h - 4), (1, 2), (r.w - 2, 2), (1, r.h - 3), (r.w - 2, r.h - 3)]
        s.rng.shuffle(spots)
        return any(s.block(t, x, y, **kw) for x, y in spots)

    def floor_flat(s, t, **kw):
        """A walk-over piece (bowls, a mat) on a free tile away from the door lane."""
        r = s.r
        tiles = [(x, y) for y in range(2, r.h - 2) for x in range(1, r.w - 1) if r.free(x, y) and (x, y) not in s.keep]
        s.rng.shuffle(tiles)
        for x, y in tiles:
            if (x, y) in r.occ:
                continue
            p = {"type": t, "x": x, "y": y, "walk": True}
            s.put(p)
            return True
        return False

    def convert(s, frm, to, **kw):
        """Change the type of existing pieces in place (same tile and turn), so nothing under an examine spot moves."""
        n = 0
        for p in s.d["props"]:
            if p["type"] == frm and not p.get("walk"):
                p["type"] = to
                p.update(kw)
                if to == "settle":
                    p["variant"] = s.rng.randrange(2)
                n += 1
                s.r.occ[(int(p["x"]), int(p["y"]))] = to
        return n

    def has(s, t):
        return any(p["type"] == t for p in s.d["props"])


def dress(d, town, region, examine):
    z = Dresser(d, examine)
    rng = z.rng
    done = []
    tp = topics(d["id"])
    sofas = [p for p in d["props"] if p["type"] == "sofa"]

    # regional pack
    if region in ("north_wales", "mid_wales", "south_wales"):
        if not z.has("kitchen_dresser") and z.wall_block("kitchen_dresser"):
            done.append("dresser")
        if town in SLATE and z.corner("slate_heap", variant=rng.randrange(2)):
            done.append("slate")
    elif region in ("ireland", "ireland_east", "ireland_west") or town in ISLES:
        if z.wall_block("range_cooker"):
            done.append("range")
    elif town == "kirkwall":
        if z.convert("bed", "box_bed", variant=rng.randrange(2)):
            done.append("boxbed")
    elif region in ("cumbria", "yorkshire"):
        got = z.convert("sofa", "settle")
        if got:
            done.append("settle")
        if z.corner("kettle_table"):
            done.append("kettle")
    if town in HARBOUR:
        if z.hang_north("wall_map"):
            done.append("map")
        if rng.random() < 0.5 and z.corner("telescope"):
            done.append("scope")

    # occupation hints
    for t in tp[:2]:
        if t == "fish" and (z.corner("lobster_pots", variant=rng.randrange(2)) or z.hang_north("wall_map")):
            done.append("fish")
        elif t == "sky" and (z.has("telescope") or z.corner("telescope")):
            done.append("sky")
        elif t == "teach" and (z.wall_block("bookshelf") or z.hang_north("wall_map")):
            done.append("teach")
        elif t == "student":
            n = sum(z.hang_north("wall_picture") for _ in range(3))
            if n:
                done.append("posters")
        elif t == "music" and (z.has("harp") or z.corner("harp") or z.corner("piano")):
            done.append("music")
        elif t == "loom" and z.corner("loom"):
            done.append("loom")
        elif t == "slate" and not z.has("slate_heap") and z.corner("slate_heap", variant=rng.randrange(2)):
            done.append("slate")
        elif t == "art" and z.hang_north("wall_picture") and z.hang_side("wall_picture"):
            done.append("art")
        elif t == "sport" and z.hang_north("dartboard"):
            done.append("darts")
        elif t in ("cat", "dog") and z.floor_flat("cat_bowl"):
            done.append("bowl")
        elif t == "farm" and (z.floor_flat("cat_bowl") or z.corner("kettle_table")):
            done.append("farm")
        elif t == "book" and z.wall_block("bookshelf"):
            done.append("books")
        elif t == "cook" and (z.has("kettle_table") or z.corner("kettle_table")):
            done.append("kettle")
        elif t == "garden" and z.hang_north("window"):
            done.append("garden")

    # everyone gets one small thing of their own so no two rooms read alike
    extras = ["window", "cat_bowl", "kettle", "map", "window"]
    rng.shuffle(extras)
    if not z.has("window") or "window" not in z.added:
        for e in extras:
            ok = {"window": lambda: z.hang_north("window"), "cat_bowl": lambda: z.floor_flat("cat_bowl"),
                  "kettle": lambda: z.has("kettle_table") or z.corner("kettle_table"),
                  "map": lambda: z.hang_north("wall_map")}[e]()
            if ok:
                done.append(e)
                break
    # a second sofa and a spare plant are the sameness: lose one of each now and then
    if len(sofas) > 1 and rng.random() < 0.5:
        extra = [p for p in d["props"] if p["type"] == "sofa" and (int(p["x"]), int(p["y"])) not in z.keep]
        if extra:
            d["props"].remove(extra[-1])
    return done


def dump(d, style):
    ind, ascii_, nl = style
    t = json.dumps(d, indent=ind, ensure_ascii=ascii_)
    return t + ("\n" if nl else "")


def style_of(text, d):
    for nl in (False, True):
        for ind in (1, None):
            for a in (True, False):
                if dump(d, (ind, a, nl)) == text:
                    return (ind, a, nl)
    return None


def home_ids(zone_dir):
    out = []
    for path in sorted(glob.glob(os.path.join(zone_dir, "*.json"))):
        d = json.load(open(path))
        if d.get("kind") != "interior" or not re.search(r"home|house|cottage", d["id"]):
            continue
        if any(k in d["id"] for k in NOT_HOMES):
            continue
        if not any(p["type"] in ("bed", "sofa") for p in d["props"]):
            continue
        out.append(path)
    return out


def main(zone_dir, dry):
    n = 0
    skipped = []
    kinds = {}
    for path in home_ids(zone_dir):
        text = open(path).read()
        d = json.loads(text)
        st = style_of(text, d)
        if st is None:
            skipped.append(path)
            continue
        town = d["warps"][0]["to"]
        t = json.load(open(os.path.join(zone_dir, town + ".json")))
        done = dress(d, town, t.get("region", ""), d.get("examine", []))
        for k in done:
            kinds[k] = kinds.get(k, 0) + 1
        if not dry:
            open(path, "w").write(dump(d, st))
        n += 1
    print("dressed", n, "homes;", kinds)
    if skipped:
        print("skipped (format does not round-trip):", skipped)


if __name__ == "__main__":
    main(sys.argv[1], "--dry" in sys.argv)
