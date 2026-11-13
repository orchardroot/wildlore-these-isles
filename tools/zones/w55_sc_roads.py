# Wave 55, roads-scotland: new roads that turn the lines of Scotland into loops.
# Run from the repo root:  python3 tools/zones/w55_sc_roads.py [route ...]
# With no names it builds every route. Each route builds one new zone, cuts a gap in the neighbours it joins (text
# patches, see w55_sc_lib.carve), writes its dialogue and trainers, its point of interest and field spot, and its
# place on the world map. Re-running is safe: a gap that is already cut is left alone.
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from w55_sc_kit import *

OUT = os.path.join(ROOT, "data", "zones")
WX_MOOR = {"drizzle": 30, "clear": 22, "downpour": 10, "fog": 14, "gale": 8, "sunshine": 12, "frost": 4}


# ----------------------------------------------------------------------------------------------------------------
# 1. The Southern Upland Way: the Scottish Borders west over the lead hills to Galloway (a loop with Glasgow and Edinburgh)
def southern_upland_way():
    zid = "southern_upland_way"
    z = scaffold(zid, "The Southern Upland Way", 64, 48, "route_moors", WX_MOOR, "valley", 69, seed=21)
    at = "southern_upland_way"
    z.rect(3, 3, 58, 42, ".")
    z.scatter(3, 3, 58, 42, "T", 90, 22, only=".")
    z.scatter(3, 3, 58, 42, "P", 70, 23, only=".")
    # the way: west gap at y 14 (Galloway), a long diagonal over the hills, east gap at y 30 (the Borders)
    path(z, [(3, 13), (20, 13), (20, 29), (60, 29)], "#", 3)
    link(z, "west", 14, "galloway", "east", 13)
    link(z, "east", 30, "scottish_borders", "west", 24)
    # Wanlockhead: Scotland's highest village, a hamlet of lead miners' cottages in the west
    z.rect(6, 17, 14, 9, ".")
    z.building(7, 18, 8, 4, "stone", "Museum of Lead Mining")
    z.building(15, 19, 5, 4, "slate_cottage")
    z.building(7, 24, 5, 3, "white_render")
    z.rect(14, 22, 1, 5, ":"); z.rect(12, 26, 8, 1, ":")
    z.prop("slate_heap", 5, 20); z.prop("slate_heap", 5, 22); z.prop("slate_heap", 19, 25)
    z.prop("bench", 15, 17); z.prop("lamp_post", 13, 17)
    plaque(z, 12, 17, "w55_sc_wanlockhead", "Wanlockhead",
           "WANLOCKHEAD. About 467 metres above the sea, the highest village in Scotland. Lead was dug out of these hills for centuries, and the old workings are kept as the Museum of Lead Mining. The miners paid a subscription to keep a library of their own, and the Miners' Library is still here. Books were the other thing they dug for.")
    z.sign(19, 17, "SOUTHERN UPLAND WAY. 212 miles, Portpatrick to Cockburnspath, opened in 1984 as Scotland's first coast-to-coast long-distance path. The waymarks are a thistle in a hexagon. You are on the bit between the lead hills and the Borders, and it is as good as the rest.")
    # the loch: St Mary's Loch in the middle east, with Tibbie Shiels Inn on the shore
    z.rect(36, 5, 14, 15, "w"); z.rect(37, 6, 12, 13, "~")
    z.rect(34, 20, 18, 2, "s")
    z.building(46, 24, 8, 4, "white_render", "Tibbie Shiels Inn")
    z.rect(46, 28, 8, 1, ":")
    z.prop("bench", 44, 23); z.prop("bench", 52, 22); z.prop("boat", 38, 12, variant=1); z.prop("statue", 33, 22)
    plaque(z, 43, 22, "w55_sc_tibbie", "Tibbie Shiels",
           "TIBBIE SHIELS. A widow called Isabella Richardson, known as Tibbie Shiels, took in lodgers at this cottage on St Mary's Loch from the 1820s and went on doing it for the rest of a long life. Walter Scott and James Hogg are both said to have called, and so did a great many walkers who were glad of the fire. The inn still has her name.")
    z.sign(34, 23, "JAMES HOGG, THE ETTRICK SHEPHERD. Shepherd turned poet, who wrote The Private Memoirs and Confessions of a Justified Sinner in 1824. The statue looks across the loch he grew up beside, with a dog at his feet, because of course.")
    # drystone walls and the sheep gate on the way up from the hamlet
    z.rect(24, 17, 12, 1, "W"); z.rect(24, 24, 12, 1, "W"); z.rect(24, 17, 1, 8, "W")
    z.rect(25, 18, 11, 6, ",")
    # tall grass along the way
    grass_patches(z, [(6, 5, 12, 6), (24, 5, 9, 8), (24, 32, 14, 8), (40, 32, 12, 8), (6, 34, 12, 8), (52, 5, 7, 12), (20, 40, 12, 4)])
    scatter_props(z, "bush", 3, 3, 58, 42, 22, 24, avoid=("."))
    scatter_props(z, "rock", 3, 3, 58, 42, 14, 25, avoid=("."))
    z.d["spawn"] = [5, 14]
    # NPCs
    chat(z, "sw_walker", "hiker", 18, 16, "Way Walker",
         ["Portpatrick to Cockburnspath, two hundred and twelve miles. I am doing it in sections, which is what you call it when you keep going home for a bath.",
          "The best bit is the day nobody warned me about. It is different every time."], "right", "still")
    chat(z, "sw_librarian", "villager_4", 12, 22, "Museum Guide",
         ["The miners here set up their own library, and paid for it themselves. I like to say they dug for lead by day and for ideas by night. It does not always go down well.",
          "Down the mine they worked by candle. Up here we have electricity, but we have not let it go to our heads."], "down", "still")
    chat(z, "sw_landlady", "villager_2", 50, 29, "Innkeeper",
         ["We have had walkers, writers and a surprising number of wet dogs. The fire has seen them all. Tibbie would have approved of the fire.",
          "Mòran taing for stopping. Mind the sheep on your way out. They have opinions."], "down", "still")
    chat(z, "sw_shepherd", "farmer", 30, 22, "Hill Shepherd",
         ["There are more sheep on this hill than people in the whole county, and they all know where the gap in the wall is. It is a gift.",
          "If one of them looks at you, that is not an invitation to conversation. It is an invitation to leave."], "left", "still")
    trn(z, "swy_walker", "Walker Isobel", "Hillwalker", "hillwalker", [("herdlet", 69), ("leveret", 69), ("thistlet", 70)],
        22, 20, "right", ["Waymarks, boots and flapjacks. Have you got all three? No? Then you will be easy to beat."],
        "Well walked. I will rest my feet and your result.", "I met a man who has done it three times. He said it was a different path every time. I did not believe him until the fourth day.", 2240)
    trn(z, "swy_shepherd", "Shepherd Wattie", "Shepherd", "farmer", [("herdlet", 70), ("foalmoor", 69), ("hootlet", 69), ("tattybogle", 70)],
        28, 21, "down", ["Away you go. This is a working hill, and the work has just shown up."],
        "Well, that was a bit of a handful. My dogs are insulted.", "A good dog is worth three men and eats less. I will not say which dog I mean.", 2300)
    trn(z, "swy_angler", "Angler Fergus", "Angler", "angler", [("bradan", 69), ("rillotter", 70), ("heronarch", 70)],
        40, 21, "left", ["Hush now. I have been after a trout since Tuesday, and it is only Thursday."],
        "Caught out. I will go back to the trout. It is not as rude.", "St Mary's Loch is full of fish and empty of anyone who wants to tell you where.", 2260)
    trn(z, "swy_stalker", "Deerstalker Anne", "Stalker", "ghillie", [("fawnlet", 69), ("stagmor", 70), ("martling", 70), ("pinewraith", 69)],
        30, 38, "up", ["Quiet on the hill. Ah. A Keeper. Quiet is off the table, then."],
        "Well stalked. You have a good eye. Do not tell the deer.", "The trick is to be downwind of everything, including your own opinions.", 2320)
    wild(z, [("leveret", 69, 70, 14, {"time": ["dawn", "dusk", "day"]}), ("herdlet", 69, 70, 12, {}), ("thistlet", 69, 70, 10, {}),
             ("stoatlet", 69, 70, 8, {"time": ["dawn", "dusk"]}), ("hootlet", 69, 70, 8, {"time": ["night"]}), ("ospret", 69, 70, 8, {"time": ["day"]}),
             ("tattybogle", 69, 70, 8, {"weather": ["fog", "drizzle"]}), ("fawnlet", 69, 70, 8, {"time": ["dawn", "dusk"]}),
             ("whiffhorn", 69, 70, 6, {}), ("pinewraith", 69, 70, 6, {"time": ["dusk", "night"]})])
    wild(z, [("bradan", 69, 70, 20, {}), ("ratty", 69, 70, 16, {}), ("dipling", 69, 70, 16, {}), ("stalklet", 69, 70, 10, {}),
             ("rillotter", 69, 70, 14, {"time": ["dawn", "dusk"]}), ("heronarch", 69, 70, 8, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 31)
    poi(z, "cache", at, a, item="miners_lamp", line="A flat tin under a slate slab, left by someone who knew these hills well and trusted nobody else to.")
    poi(z, "stone", at, b, stat="def",
        lore=["The wind drops when you stand beside it. You do not mention this to anyone.", "The real thing is Callanish, on the Isle of Lewis: a cross of standing stones about 5,000 years old."])
    poi(z, "camp", at, c, names=[["Poacher Rab", "Poacher"], ["Poacher Bronwen", "Poacher"]], party=["leveret", "fawnlet", "stoatlet"],
        line="This is a private camp. Private as in 'mind your own'.", money=300 + 40 * 70, item="flask_of_tea")
    field(z, "mend", "mend", "wall_gap", 23, 21, "{lead} nudges the loose stones back into the gap in the drystone wall, one at a time, and the sheep, who had been about to leave, change their minds. The shepherd leaves a flask of tea on the post.", {"item": "flask_of_tea", "qty": 1}, at)
    place(at, 570, 556)


import w55_sc_hills, w55_sc_coast
ROUTES = {"southern_upland_way": southern_upland_way}
ROUTES.update(w55_sc_hills.ROUTES)
ROUTES.update(w55_sc_coast.ROUTES)

if __name__ == "__main__":
    names = sys.argv[1:] or list(ROUTES)
    for n in names:
        ROUTES[n]()
    write_all(OUT)
    write_extras()
