# Road 3 (wave 55): the Humber Bridge and Ermine Street. Hull (south side) across the estuary to Barton-upon-Humber, then
# the Lincolnshire Wolds on the old Roman road to Lincoln (north side). Both towns open at the same story step.
from w55_lib import *

ZID = "humber_bridge"
W, H = 64, 62
FLOOR = 86   # Hull 84, Lincoln 88


def build():
    z = route_zone(ZID, "Humber Bridge", W, H, "midlands", "route_moors", "grass", FLOOR,
                   {"clear": 26, "drizzle": 20, "fog": 14, "gale": 12, "sunshine": 16, "downpour": 12})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#82964f"},
        "m": {"tile": "grass", "colour": "#8fa457"},
        "q": {"tile": "tall_grass", "colour": "#7f9650", "prop": "short"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "c": {"tile": "grass", "colour": "#a99f78"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(30, 0, 3, 3), (30, 59, 3, 3)])
    z.scatter(0, 0, W, H, "P", 8, 7, only="T")
    # --- the estuary across the top, then Barton's mudflat shore
    z.rect(3, 3, W - 6, 15, "~")
    z.rect(3, 3, W - 6, 1, "w"); z.rect(3, 16, W - 6, 2, "w")
    for x in range(3, W - 3):
        if x % 7 < 3:
            z.set(x, 17, "r")
    # --- the bridge deck: from the north gap down the middle to the south shore
    z.rect(30, 0, 3, 19, "=")
    z.rect(27, 10, 3, 5, "=")   # a lay-by for the plaque
    for y in range(3, 18, 4):
        z.prop("lamp_post", 29, y); z.prop("lamp_post", 33, y)
    # --- hills: the Wolds roll up behind the shore
    hills(z, [(14, 38, 4, 18), (50, 44, 4, 16), (32, 52, 2, 10), (52, 26, 2, 8)])
    for y in range(18, H - 3):
        for x in range(3, W - 3):
            if z.g[y][x] == "g":
                z.set(x, y, "m" if (x * 7 + y * 3) % 11 else "g")
    for i, (cx, cy, rx, ry) in enumerate([(12, 36, 7, 4), (49, 42, 8, 4), (22, 50, 6, 2), (56, 52, 4, 3), (10, 24, 4, 2)]):
        blob(z, cx, cy, rx, ry, "q", only="gm", seed=60 + i, jitter=0.5)
    # --- Ermine Street: straight south from the shore to Lincoln, as the Romans liked it
    z.rect(31, 19, 1, 41, "=")
    z.rect(30, 19, 3, 3, "=")
    road(z, [(31, 18), (31, 60)], "=", 3)
    # --- Far Ings: old clay pits turned reed bed, west of the bridge foot
    for (cx, cy, rx, ry) in [(14, 22, 5, 2), (22, 26, 4, 2), (8, 28, 3, 2)]:
        pond(z, cx, cy, rx, ry, shore="r")
    for (x, y) in [(18, 20), (11, 24), (25, 23)]:
        z.set(x, y, "r")
    road(z, [(28, 22), (18, 22)], "c", 1)
    # --- Barton: St Peter's, a tile works chimney, cottages
    z.building(40, 21, 5, 4, "chapel", "St Peter's, Barton")
    z.building(47, 23, 4, 3, "red_brick", "Barton Tile Works", show_label=True)
    z.building(41, 28, 3, 2, "red_brick", "", show_label=False)
    z.building(35, 30, 3, 2, "slate_cottage", "", show_label=False)
    z.prop("lamp_post", 38, 26)
    road(z, [(33, 27), (45, 27)], "c", 1)
    # --- the Wolds: hedged fields, a tower mill, copses
    z.building(8, 44, 3, 3, "windmill_white", "Tower Mill")
    hedge_line(z, 4, 40, 27, 40, gaps={(14, 40), (15, 40)})
    hedge_line(z, 36, 36, 59, 36, gaps={(48, 36), (49, 36)})
    hedge_line(z, 36, 48, 59, 48, gaps={(52, 48), (53, 48)})
    hedge_line(z, 4, 54, 27, 54, gaps={(10, 54), (11, 54)})
    for (cx, cy) in [(18, 33), (52, 30), (26, 46), (44, 55)]:
        blob(z, cx, cy, 3, 2, "T", only="gmq", seed=cx, jitter=0.4)
    for (x, y) in [(8, 34), (12, 48), (20, 44), (54, 40), (46, 52), (24, 56)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- signs and plaques
    sign(z, 29, 1, "NORTH: Hull, the Deep, and the Humber Bridge's far end. The bridge is nearly a mile and a half long and the towers lean very slightly apart, which is the Earth being round.")
    plaque(z, 28, 11, "w55e_humber_bridge", "The Humber Bridge",
           "Opened by the Queen in July 1981 after nine years of building, joining Hessle on the north bank to Barton-upon-Humber on the south. Its main span of 1,410 metres made it the longest single-span suspension bridge in the world, until Japan built a longer one in 1998. The two towers are about 36 millimetres further apart at the top than at the bottom, because the Earth curves.")
    plaque(z, 38, 20, "w55e_barton_church", "St Peter's, Barton-upon-Humber",
           "The tower of this church was built about 970, in the last decades of Anglo-Saxon England, and the baptistery beside it is nearly as old. Archaeologists dug up thousands of burials in the churchyard in the 1970s and 80s, which makes it a very well studied Anglo-Saxon graveyard. The Barton clay beside the Humber later fed a famous brick and tile industry.")
    sign(z, 20, 21, "FAR INGS. Old clay pits that flooded and filled with reeds. The reeds are cut each winter. Bitterns turn up on a good day. So do people with cameras and no particular plans.")
    sign(z, 34, 24, "BARTON-UPON-HUMBER. Mind the lorries from the bridge. They have a lot of road, and a lot on their minds.")
    plaque(z, 34, 34, "w55e_ermine_street", "Ermine Street",
           "A Roman road that ran north from London through Lincoln to the Humber crossing, and on to York. The Romans built it dead straight, cutting corners and pushing through hills. The modern A15 north of Lincoln follows its line for mile after mile, which is why the road here looks like it was drawn with a ruler.")
    sign(z, 20, 38, "THE LINCOLNSHIRE WOLDS. Chalk hills, hedged fields and big skies, officially an Area of Outstanding Natural Beauty. Locals call it a nice drive.")
    sign(z, 38, 52, "SOUTH: Lincoln, where the Cathedral stands on the hill. You'll see it for miles before you get there, which was rather the point.")
    sign(z, 12, 46, "TOWER MILL. Corn, until a bad winter. Now it is a very pretty mill with very little to do. Many of us understand.")
    # --- people
    chat(z, "hb_toll", "villager_1", 28, 21, "Bridge Keeper",
         ["The tolls are what they are. Take it up with the Humber Bridge Board, or the Queen. She opened it.",
          "It moves a little in a gale. It is meant to. Don't look down, and don't look at the cyclists either, they look at nobody."], "right", "still")
    chat(z, "hb_historian", "tour_guide", 36, 33, "Roman Re-enactor",
         ["This is Ermine Street. Legions marched up it to York, in a straight line, with their own pots and pans on a pole.",
          "A legionary carried about forty kilos. And you complain about a rucksack."], "left", "still")
    chat(z, "hb_farmer", "farmer", 40, 44, "Wolds Farmer",
         ["Wolds soil is chalk and flint. Not a lot grows in it, except barley, and Lord, does barley grow. Half of what you drink started in a field like this.",
          "That chap Tennyson grew up near here, at Somersby. Even the poets couldn't stay away from the Wolds."], "down", "still")
    chat(z, "hb_birdman", "birdwatcher", 12, 29, "Reed Cutter",
         ["Reed beds don't look after themselves. I cut them each winter so the bitterns have something to hide in. Roof thatchers love the leftovers."], "down", "still")
    # --- trainers
    tr(z, "hb_cyclist", "Cyclist Pru", "Cyclist", "jogger", [("peregrin", 86), ("starlet", 86), ("rooklet", 87)], 34, 56, "up",
       ["Humber Bridge has a cycle lane. The wind off the estuary has a view on that. I ride it anyway."],
       "Blown off. I'd say it was the wind.", "Across the bridge into a headwind is the best training there is. And the worst. Same thing.", 3700, FLOOR)
    tr(z, "hb_legionary", "Centurion Dai", "Re-enactor", "hiker", [("legionette", 87), ("hootlet", 86), ("spikkin", 86)], 29, 36, "right",
       ["Form up! Shields! Well, a sort of shield. It's mostly a cardboard cut-out of one, but it's a lot of fun."],
       "The Ninth Legion vanished round here, they say. I know how they felt.", "Eboracum, Lindum, Londinium. I've walked them all, over a very long weekend.", 3800, FLOOR)
    tr(z, "hb_birder", "Birdwatcher Elsa", "Birdwatcher", "birdwatcher", [("bittling", 86), ("stalklet", 86), ("dipling", 86)], 21, 24, "right",
       ["Quiet! A bittern booms in spring. It sounds like somebody blowing across a bottle, a mile off. Marvellous. Now hush."],
       "That's every bittern for a mile gone. Oh well. I'll count the pigeons.", "Bitterns nearly died out in Britain in the 1990s. They have come back, and I like to think we deserve some of the credit.", 3600, FLOOR)
    tr(z, "hb_shepherd", "Shepherd Rhona", "Shepherd", "farmer", [("herdlet", 86), ("tattybogle", 86), ("leveret", 87)], 45, 41, "left",
       ["Wolds lambs are the best-looking in the county. I wouldn't know about the other counties. I have never left."],
       "I'll need a cup of tea after that. And possibly a sit-down.", "The wind up here could take your hat to Lincoln before you'd said goodbye.", 3700, FLOOR)
    tr(z, "hb_angler", "Angler Sid", "Angler", "angler", [("pupplash", 86), ("pinchkin", 86), ("chipgull", 86)], 8, 19, "right",
       ["Waiting for a flounder. Been waiting since Tuesday. The Humber's got a lot of mud and not a lot of urgency."],
       "Well. The flounder's not the only one who's been beaten today.", "Grey seals come right up the estuary some winters. I've never seen one. I assume they're avoiding me.", 3600, FLOOR)
    # --- wildlife
    wild(z, [("leveret", 86, 88, 12, {"time": ["dawn", "dusk"]}), ("kitelet", 86, 88, 10, {"time": ["day"]}), ("starlet", 86, 88, 10, {}),
             ("rooklet", 86, 88, 10, {}), ("moldiwarp", 86, 88, 8, {}), ("pipkin", 86, 88, 10, {"time": ["dawn", "day"]}),
             ("spikkin", 86, 88, 8, {}), ("hootlet", 86, 88, 8, {"time": ["dusk", "night"]}), ("barnling", 86, 88, 8, {"time": ["night"]}),
             ("stoatlet", 86, 88, 8, {}), ("tattybogle", 86, 88, 6, {"time": ["dusk", "night"]}), ("peregrin", 86, 88, 6, {"time": ["day"]}),
             ("bittling", 86, 88, 5, {"time": ["dawn", "dusk"]})])
    wild(z, [("pupplash", 86, 88, 18, {}), ("chipgull", 86, 88, 22, {}), ("pinchkin", 86, 88, 18, {}), ("stalklet", 86, 88, 16, {}),
             ("dipling", 86, 88, 12, {}), ("croakle", 86, 88, 10, {}), ("gannetling", 86, 88, 8, {})], "water")
    offN = link("hull", "south", ZID, 31, water_ok=True)
    offS = link("lincoln", "north", ZID, 31)
    z.d["edges"] = {"north": {"to": "hull", "offset": offN}, "south": {"to": "lincoln", "offset": offS}}
    z.d["spawn"] = [31, 24]
    scenery(z, 500, bushes=20, rocks=10, trees=10, ground=("g", "m"), y=19)
    finish_zone(z, ZID)
    for p in check_route(z, [(31, 0), (31, 61)]):
        print("PROBLEM:", p)
    add_place(ZID, 818, 805)
    add_data("poi", [
        poi(ZID, "humber_stone", (50, 54), "stone", stat="spd",
            lore=["It is a milestone, and it points two ways at once. You decide it is just being diplomatic.",
                  "The real thing is the line of Ermine Street itself: the Romans ran the road dead straight from Lincoln to the Humber, and the A15 still follows much of it today."]),
        poi(ZID, "humber_cache", (6, 30), "cache", item="field_mushrooms",
            line="A thermos, a bag of sandwiches, and a note: 'Back at four. Do NOT touch the pickled onions.'"),
        poi(ZID, "humber_camp", (54, 20), "camp", names=[["Fisher Gav", "Poacher"], ["Fisher Lin", "Poacher"]],
            party=["pinchkin", "pupplash", "chipgull"], line="Just a spot of unofficial netting. Nobody's looking. Except you.", money=2600, item="water_snare")])
    add_data("field_spots", [
        fspot(ZID, "humber_roll", 24, 48, "roll", "cheese",
              "A wheel of Lincolnshire Poacher, stuck in a rut. {lead} gives it a shove and down the slope it goes, round and round, and out of the hollow comes an old bus pass and a lot of loose change.",
              {"money": 380})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
