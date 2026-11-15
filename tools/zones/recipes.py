#!/usr/bin/env python3
"""Wildlore 1.5 crafting: puts the benches in Mum's kitchen and the Field Station, and the recipe teachers in
interiors around the isles. Safe to re-run (it replaces what it added before).

RETIRED PART: this used to write Mum's recipe-book scene into data/dialogue/macc_home.json. Since 5.7.0 that scene is
hand-edited there (it ends Mum's first morning and sets `mum_recipes`), so this script no longer touches Mum's
dialogue. Re-running the rest has not been checked since the zones last changed (the teachers are placed by
free_tile on today's rooms), so read the git diff before keeping a run.

    python3 tools/zones/recipes.py
"""
import json
import os
from collections import deque

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
ZONES = os.path.join(ROOT, "data", "zones")
DIALOGUE = os.path.join(ROOT, "data", "dialogue")

WALK = set(".,#=:sfwD|+_&")


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save(path, d):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=1, ensure_ascii=False)


def walkable_set(z, extra_block=()):
    rows = z["rows"]
    legend = z.get("legend_extra", {})
    blocked = {(int(p["x"]), int(p["y"])) for p in z.get("props", []) if p.get("type") != "building" and not p.get("walk")}
    blocked |= {(int(s["x"]), int(s["y"])) for s in z.get("signs", [])}
    blocked |= set(extra_block)
    out = set()
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            ok = c in WALK
            if c in legend:
                ok = legend[c].get("tile") in ("grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow",
                                               "door", "floor_wood", "floor_tile", "platform", "level_crossing")
            if ok and (x, y) not in blocked:
                out.add((x, y))
    return out


def reach(walk, start, also=()):
    seen = {start}
    q = deque([start])
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n in walk and n not in seen and n not in also:
                seen.add(n)
                q.append(n)
    return seen


def free_tile(z):
    """A floor tile for a still NPC: nobody there, off the doorstep, and blocking it cuts nothing off."""
    walk = walkable_set(z)
    npcs = {(int(n["x"]), int(n["y"])) for n in z.get("npcs", [])}
    warps = {(int(w["x"]), int(w["y"])) for w in z.get("warps", [])}
    spawn = tuple(z.get("spawn", [0, 0]))
    base = reach(walk, spawn, npcs)
    best = None
    for t in sorted(walk):
        if t in npcs or t in warps or t == spawn:
            continue
        if any(abs(t[0] - w[0]) + abs(t[1] - w[1]) <= 2 for w in warps):
            continue
        if any(abs(t[0] - n[0]) <= 1 and abs(t[1] - n[1]) <= 1 for n in npcs):
            continue
        if any(str(n.get("move", "still")) != "still" and max(abs(t[0] - int(n["x"])), abs(t[1] - int(n["y"]))) <= int(n.get("radius", 2)) + 1 for n in z.get("npcs", [])):
            continue
        if t not in base:
            continue
        after = reach(walk, spawn, npcs | {t})
        if after != base - {t}:
            continue
        # every NPC still has a tile to be talked to from
        ok = True
        for n in list(npcs) + [t]:
            if not any((n[0] + dx, n[1] + dy) in after for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                ok = False
        if not ok:
            continue
        score = -t[1] * 10 + abs(t[0] - spawn[0])  # towards the back of the room
        if best is None or score > best[0]:
            best = (score, t)
    return best[1] if best else None


def teach_script(name, ids, intro, after):
    first = ids[0]
    return [{"do": "if", "flag": "recipe_" + first,
             "then": [{"do": "say", "who": name, "text": after},
                      {"do": "choice", "text": "Borrow the kitchen?", "options": ["Yes, please", "No, ta"], "set": "_borrow_bench"},
                      {"do": "if", "flag": "_borrow_bench", "eq": 0, "then": [{"do": "craft", "bench": "borrowed"}]}],
             "else": [{"do": "say", "who": name, "text": t} for t in intro] + [{"do": "recipe", "id": ids},
                      {"do": "say", "who": name, "text": "Pop in whenever you've got the makings. You can use my kitchen."}]}]


TEACHERS = [
    ("bath_sallylunn", "bath_baker", "Baker", "villager_3", ["cream_tea"], [
        "Mind the flour. Everything in here is flour. I am at least forty per cent flour.",
        "You've got blackberries on your fingers. Forager, are we? Then you want a proper cream tea.",
        "Hedgerow jam, a splash of elderflower, scones like clouds. Jam first, cream second. We are in Bath, not Devon, and I'll not be told."],
     "Jam first. Always jam first. Fancy a go at my oven?"),
    ("penzance_home1", "cornish_fisherman", "Fisherman", "fisher", ["pasty", "creel_snare", "hag_stone"], [
        "Dreckly, my lover, dreckly. Oh, you're not the man about the boiler.",
        "You've the look of someone who picks seaweed off the beach and doesn't know what to do with it.",
        "Here. A proper pasty, a little creel for the Brook lot, and how to dress a hag stone. My nan's ways. Don't tell the Tourist Board."],
     "Crimp's on the side, not the top. Want to borrow the range?"),
    ("llanberis_home1", "welsh_miner", "Old Quarryman", "tin_miner", ["miners_lamp", "bara_brith"], [
        "Forty years I split slate up on that mountain. You can still hear it in my knees.",
        "We had a lamp we made ourselves, see. Slate back, peat to light it, a bit of honeywax for the wick. Stone creatures dig like mad for it.",
        "And bara brith, because you can't split slate on an empty stomach. Tea in the fruit overnight. Not optional."],
     "Croeso, come in. Kettle's on. Use the table if you like."),
    ("inverness_home_a", "highland_ghillie", "Ghillie", "ghillie", ["cranachan", "tablet", "thistle_brooch"], [
        "Ach, a forager. I can tell by the midge bites.",
        "Heather honey's the thing up here. Cranachan, tablet, and a thistle brooch from wool and a hawthorn pin. Wha daur meddle wi' me, and so on.",
        "Write them down. Well, don't write the tablet down. Your dentist might read it."],
     "Back again? There's a pan on the hob if you want it."),
    ("galway_home_claddagh", "irish_granny", "Granny Ní Fhlatharta", "villager_4", ["barmbrack", "brigid_cross", "shamrock_pin"], [
        "Come in, come in, you're letting the heat out. Sit. Have you eaten? You haven't. I can tell.",
        "I'll give you the barmbrack, the way my mother made it. There's a ring in it, so chew careful.",
        "And a Brigid's cross and a shamrock pin. They'll mind your creatures when I can't."],
     "There you are, pet. Will you use the kitchen? Go on, sure it's no bother."),
    ("york_bettys", "york_baker", "Pastry Chef", "villager_2", ["parkin"], [
        "Parkin, love. Oats, treacle, ginger, heather honey. Best a week old.",
        "Nobody in Yorkshire has ever managed to leave one for a week. It's been tried. There were casualties."],
     "Ey up. The ovens are free, if you've got the makings."),
    ("keswick_teashop", "kendal_confectioner", "Confectioner", "villager_1", ["kendal_mint_cake"], [
        "Mint cake. Kendal's finest. Got Hillary up Everest and my cousin up Skiddaw, which was harder.",
        "Sugar, mint, honey and a bit of wild honeycomb if you can find it. It'll pick a fainted creature right up."],
     "Back for more? The copper pan's yours."),
    ("liverpool_h1", "scouse_nan", "Nan", "villager_5", ["scouse"], [
        "Sit down, la, you look starved. Here's how you make a proper scouse.",
        "Mushrooms if you can't get the lamb. Red cabbage on the side. If anyone calls it stew, you show them the door."],
     "Pan's on. It's always on. Want a go?"),
    ("belfast_home_lisburn", "belfast_baker", "Baker", "villager_6", ["soda_farl"], [
        "Ach, come in. You'll have a farl? You will.",
        "Soda bread on a griddle, cut in quarters. A bit of wild garlic through it if you're fancy. And you are fancy, I can see."],
     "Griddle's hot. Help yourself."),
    ("buxton_well", "buxton_bottler", "Bottler", "villager_3", ["elderflower_cordial"], [
        "Spring water from the well, elderflower from the hedge, and a pinch of something I'm not allowed to tell you.",
        "Fine, it's sugar. Mix them up and it clears whatever ails a creature. Better than Buxton Water. Don't tell my boss."],
     "Want to use the bottling table?"),
    ("sherwood_visitor", "sherwood_forester", "Forester", "fox_watcher", ["oak_acorn"], [
        "Every acorn off the Major Oak is spoken for. Except the odd one I polish up for friends.",
        "Hazelnuts round it for luck, and a truffle from under the old roots. It makes whoever holds it stand like an oak."],
     "Need a bench? There's room."),
    ("sheffield_forge", "sheffield_smith", "Smith", "steelworker", ["horseshoe"], [
        "Mind the anvil, love. It's not moving, but your toes are.",
        "A horseshoe for luck, forged on peat with an ammonite set in the crown. Points up, so the luck doesn't drain out.",
        "Hang it over a creature and it'll take a knock it shouldn't survive. Once. Luck's not a bottomless pit."],
     "Forge is hot. Want to use the bench?"),
    ("kirkwall_home_a", "island_storyteller", "Storyteller", "fisherman_north", ["selkie_pearl"], [
        "You'll have heard of the selkies. Seals in the sea, folk on the land. My granny married one. Allegedly.",
        "Leave sea glass wrapped in seaweed on the tideline overnight, and the selkies swap it for a pearl. Brook creatures love one."],
     "Back for another story? Or the table? Both are free."),
]

def add_prop(zid, prop):
    path = os.path.join(ZONES, zid + ".json")
    z = load(path)
    z["props"] = [p for p in z.get("props", []) if p.get("type") != "craft_bench"] + [prop]
    save(path, z)


def main():
    add_prop("macc_home", {"type": "craft_bench", "bench": "kitchen", "x": 6, "y": 2})
    add_prop("macc_fieldstation", {"type": "craft_bench", "bench": "workbench", "x": 2, "y": 5})
    for zid, nid, name, sprite, ids, intro, after in TEACHERS:
        zpath = os.path.join(ZONES, zid + ".json")
        z = load(zpath)
        z["npcs"] = [n for n in z.get("npcs", []) if n.get("id") != nid]
        t = free_tile(z)
        if t is None:
            raise SystemExit("no room for %s in %s" % (nid, zid))
        z["npcs"].append({"id": nid, "sprite": sprite, "x": t[0], "y": t[1], "facing": "down", "move": "still",
                          "script": "teach_" + nid, "name": name})
        save(zpath, z)
        dpath = os.path.join(DIALOGUE, zid + ".json")
        dd = load(dpath) if os.path.exists(dpath) else {}
        dd["teach_" + nid] = teach_script(name, ids, intro, after)
        save(dpath, dd)
        print("%s: %s at %d,%d" % (zid, nid, t[0], t[1]))


if __name__ == "__main__":
    main()
