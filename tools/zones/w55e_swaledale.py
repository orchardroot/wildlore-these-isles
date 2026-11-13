# Road 2 (wave 55): Swaledale, a stretch of Wainwright's Coast to Coast Walk. The Lake District (east side) over Nine
# Standards Rigg and down Swaledale to the North York Moors (west side). Both ends open at the same story step.
from w55_lib import *

ZID = "swaledale"
W, H = 80, 48
FLOOR = 84   # Lake District 86-88, North York Moors 81-83


def build():
    z = route_zone(ZID, "Swaledale", W, H, "yorkshire", "route_moors", "valley", FLOOR,
                   {"clear": 28, "drizzle": 24, "sunshine": 16, "fog": 12, "gale": 8, "downpour": 12})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#7d8a4c"},
        "m": {"tile": "grass", "colour": "#86974f"},
        "h": {"tile": "tall_grass", "colour": "#6e5a5c", "prop": "heather"},
        "q": {"tile": "tall_grass", "colour": "#8a9a52", "prop": "short"},
        "f": {"tile": "flowers", "colour": "#a8b856"},
        "G": {"tile": "rock", "colour": "#7d7a6a", "prop": "gritstone"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "W": {"tile": "drystone_wall", "colour": "#76734a"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(0, 29, 3, 3), (77, 18, 3, 3)])
    z.scatter(0, 0, W, H, "P", 30, 5, only="T")
    # --- ground: Nine Standards Rigg high in the north-west, the dale floor low and green, the east side lifting again
    hills(z, [(22, 7, 6, 20), (66, 8, 3, 14), (12, 40, 2, 12)])
    # heather and short turf on the tops, hay meadows (flowers) down the dale
    for i, (cx, cy, rx, ry) in enumerate([(22, 7, 14, 5), (36, 5, 8, 3), (66, 7, 9, 4), (70, 40, 6, 3), (8, 40, 6, 3)]):
        blob(z, cx, cy, rx, ry, "h", only="g", seed=30 + i, jitter=0.5)
    for i, (cx, cy, rx, ry) in enumerate([(30, 14, 12, 3), (56, 13, 9, 3), (20, 16, 7, 2)]):
        blob(z, cx, cy, rx, ry, "q", only="gh", seed=50 + i, jitter=0.5)
    for y in range(22, 44):
        for x in range(26, 76):
            if z.g[y][x] == "g":
                z.set(x, y, "m")
    for i, (cx, cy, rx, ry) in enumerate([(34, 30, 5, 3), (46, 32, 6, 3), (60, 31, 5, 3), (40, 40, 6, 2), (66, 38, 4, 2)]):
        blob(z, cx, cy, rx, ry, "f", only="m", seed=70 + i, jitter=0.4)
    # --- the River Swale along the dale floor, with a ford where the road crosses
    for x in range(26, W - 3):
        y = 36 + int(round(2.2 * math.sin(x / 6.0)))
        z.set(x, y - 1, "w"); z.set(x, y, "~"); z.set(x, y + 1, "w")
    # --- Kisdon Force: a beck coming off the north side and across the road
    for y in range(8, 29):
        z.set(34, y, "w"); z.set(35, y, "w")
        if y in (13, 14, 15):
            z.set(34, y, "~"); z.set(35, y, "~")
    # --- the road (the Coast to Coast): in from the Lake District, down the dale, out to the North York Moors
    ROUTE = [(1, 30), (24, 30), (24, 26), (52, 26), (52, 19), (78, 19)]
    road(z, ROUTE, "#", 3)
    road(z, [(14, 30), (14, 12), (22, 12)], "#", 1)         # the path up to Nine Standards
    road(z, [(24, 26), (24, 20), (30, 20)], "#", 1)         # a lane to the barns
    # --- Nine Standards: a row of cairns on the skyline
    for i, x in enumerate(range(17, 35, 2)):
        z.prop("rock", x, 9 + (i % 2), variant=i % 3)
    z.prop("standing_stone", 25, 11, variant=1)
    # --- Swaledale walls and stone field barns
    for (bx, by) in [(28, 22), (38, 23), (53, 29), (58, 29), (64, 24)]:
        z.building(bx, by, 3, 2, "field_barn", "", show_label=False)
    for (x0, y0, x1, y1) in [(27, 30, 50, 30), (27, 31, 27, 34), (50, 31, 50, 34)]:
        hedge_line(z, x0, y0, x1, y1, ch="W", gaps={(36, 30), (37, 30), (38, 30)})
    hedge_line(z, 54, 22, 74, 22, ch="W", gaps={(60, 22), (61, 22)})
    hedge_line(z, 54, 34, 74, 34, ch="W", gaps={(66, 34), (67, 34)})
    # --- Keld: a hamlet of stone houses
    z.building(40, 10, 5, 3, "slate_cottage", "Keld Lodge", show_label=True)
    z.building(46, 11, 4, 3, "stone", "Chapel", show_label=False)
    # --- the lead mines: a smelt mill ruin and spoil heaps
    z.building(56, 8, 5, 3, "stone", "Smelt Mill (ruin)")
    for (x, y) in [(55, 12), (58, 12), (61, 11), (63, 9)]:
        z.prop("slate_heap", x, y, variant=1)
    # --- Richmond, at the far end of the dale
    z.building(62, 40, 10, 5, "castle", "Richmond Castle")
    z.prop("flagpole", 61, 40)
    # --- signs and plaques
    sign(z, 3, 26, "WEST: Kirkby Stephen and the Lakes, with Wainwright's blessing. EAST: Keld, Reeth and Richmond. Remember to pace yourself, it is a hundred and ninety-two miles.")
    plaque(z, 16, 26, "w55e_coast_to_coast", "The Coast to Coast Walk",
           "Alfred Wainwright devised this walk and published it in 1973: 192 miles from St Bees on the Irish Sea to Robin Hood's Bay on the North Sea, across three National Parks, the Lakes, the Dales and the North York Moors. It is not an official National Trail, but walkers by tradition dip their boots at one end and toss a pebble in at the other.")
    plaque(z, 22, 14, "w55e_nine_standards", "Nine Standards Rigg",
           "A line of big stone cairns on the skyline above Kirkby Stephen, 662 metres up. Nobody knows who built them or why. Theories include boundary markers and a trick to make passing armies think more men were watching. Walkers go round them by different routes in the wet, which is part of why the path is so wide.")
    sign(z, 31, 28, "KELD. A hamlet at the head of Swaledale, where the Pennine Way and the Coast to Coast cross. Kisdon Force is just up the beck. Pack a flask.")
    plaque(z, 54, 14, "w55e_swaledale_lead", "Lead Mining in Swaledale",
           "For centuries Swaledale and Arkengarthdale were among the great lead mining dales of England. Hundreds of men and their families lived off the ore, dressing it, smelting it and carting it to Richmond. When prices collapsed in the 1870s many families left for the coalfields, or America, and the barns and the long walls of the hay meadows are what they left.")
    sign(z, 50, 24, "HAY MEADOWS. Cut late, in July, so that the flowers seed first. Please keep to the path or Farmer Atkinson will have a word.")
    plaque(z, 66, 36, "w55e_richmond_castle", "Richmond Castle",
           "Begun about 1071 by Alan Rufus, a Breton lord who had fought at Hastings, as one of the first Norman castles in the north. The great keep, over thirty metres tall, was added about a century later. It stands high above the River Swale and is one of the best preserved early castles in England.")
    sign(z, 74, 16, "EAST: the North York Moors, the Cleveland Way and Robin Hood's Bay, with a pebble to throw in. WEST: Swaledale and Wainwright's sandwiches.")
    # --- people
    chat(z, "sw_walker", "hiker", 18, 27, "Coast to Coast Walker",
         ["I dipped my boots at St Bees on Monday. I am carrying a pebble in my pocket. It has become my best friend, and my lowest back pain.",
          "Wainwright said, make up your own route if you like. Many do. Nobody gets a medal, but the B&B owners are very kind."], "right", "still")
    chat(z, "sw_shepherd", "farmer", 38, 25, "Hay Farmer",
         ["These meadows are cut late, after the flowers have gone to seed. Some of them have not been ploughed or sprayed in centuries.",
          "Dozens of different flowers in a field, easy. My granddad could name every one. I can name about nine. The rest I call 'that blue one'."], "down", "still")
    chat(z, "sw_miner", "villager_4", 59, 13, "Dale Historian",
         ["Gunnerside Gill was one of the richest lead mines in the dale. They built the hushes: dammed a beck, let the water go all at once, and the whole hillside washed away to show the ore.",
          "Brutal, but clever. They called it hushing."], "down", "still")
    chat(z, "sw_ranger", "villager_2", 46, 15, "Dales Ranger",
         ["Mind the becks after rain. They come up fast, and they take hats."], "left", "still")
    # --- trainers
    tr(z, "sw_c2c", "Walker Imogen", "Hillwalker", "hillwalker", [("kitelet", 84), ("brockling", 84), ("slatelet", 85)], 28, 27, "right",
       ["Wainwright did it in eleven days. I've allowed fourteen and a long lunch. Fancy a fight at a sensible pace?"],
       "Fair play. Blisters and defeat in one afternoon.", "I only carry the pebble. It's the principle.", 3600, FLOOR)
    tr(z, "sw_shepherd_t", "Shepherd Dale", "Shepherd", "farmer", [("herdlet", 84), ("kidgruff", 85), ("stoatlet", 84)], 48, 28, "up",
       ["Swaledales, these. Black faces, white noses, horns like a Roman helmet. They'll survive anything the weather throws at them. Unlike me."],
       "Ah, well. The ewes weren't looking.", "A Swaledale ewe will happily lamb in a blizzard and look cross about it afterwards.", 3500, FLOOR)
    tr(z, "sw_canoeist", "Angler Raif", "Angler", "angler", [("volet", 84), ("cranelet", 85), ("dipling", 84)], 44, 38, "up",
       ["The Swale rises like a lift after heavy rain. I fish it carefully. And with a lifejacket. And a flask."],
       "I'll tell the grayling it wasn't personal.", "Dippers all along here. The only songbird that walks underwater, and does it better than I do.", 3500, FLOOR)
    tr(z, "sw_birder", "Birdwatcher Moira", "Birdwatcher", "birdwatcher", [("ospret", 84), ("starlet", 85), ("zigzlet", 84)], 68, 26, "left",
       ["Curlews, lapwings, redshank, all nesting in the hay meadows. We stay out till June to let them. Now, shh."],
       "That'll have put the curlews off. I've never been so embarrassed.", "A curlew's call is the sound of the moor. I'd miss it more than my own phone.", 3600, FLOOR)
    tr(z, "sw_historian", "Castle Warden Hugh", "Warden", "warden_grunt", [("tapknock", 85), ("scorchbun", 84), ("brockling", 85)], 68, 21, "down",
       ["The castle has stood for about nine hundred years. I intend to keep it standing."],
       "The walls held. I'm less sure about me.", "They say King Arthur sleeps under Richmond Castle with his knights. A drummer boy found the tunnel once, and never came back.", 3700, FLOOR)
    # --- wildlife
    wild(z, [("herdlet", 84, 86, 14, {}), ("kidgruff", 84, 86, 10, {}), ("slatelet", 84, 86, 10, {}), ("zigzlet", 84, 86, 10, {"time": ["day"], "weather": ["sunshine", "clear"]}),
             ("ospret", 84, 86, 6, {"time": ["day"]}), ("starlet", 84, 86, 8, {}), ("midgie", 84, 86, 8, {"time": ["dusk", "dawn"]}),
             ("stoatlet", 84, 86, 8, {}), ("kitelet", 84, 86, 8, {"time": ["day"]}), ("brockling", 84, 86, 8, {"time": ["dusk", "night"]}),
             ("leveret", 84, 86, 8, {"time": ["dawn", "dusk"]}), ("hootlet", 84, 86, 8, {"time": ["dusk", "night"]}),
             ("sphagnet", 84, 86, 6, {"weather": ["drizzle", "downpour", "fog"]})])
    wild(z, [("dipling", 84, 86, 28, {}), ("volet", 84, 86, 22, {}), ("stalklet", 84, 86, 18, {}), ("parrlet", 84, 86, 16, {}), ("ratty", 84, 86, 16, {})], "water")
    # --- gaps: Lake District's east side, the North York Moors' west side
    offW = link("lake_district", "east", ZID, 30)
    offE = link("north_york_moors", "west", ZID, 19)
    z.d["edges"] = {"west": {"to": "lake_district", "offset": offW}, "east": {"to": "north_york_moors", "offset": offE}}
    z.d["spawn"] = [3, 30]
    scenery(z, 400, bushes=26, rocks=18, trees=10, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(1, 30), (78, 19)]):
        print("PROBLEM:", p)
    add_place(ZID, 712, 700)
    add_data("poi", [
        poi(ZID, "swaledale_stone", (24, 10), "stone", stat="def",
            lore=["The cairn is warm on one side. Probably the sun. You decide not to check.",
                  "The real thing is Nine Standards Rigg above Kirkby Stephen, where nobody knows who built the big cairns, or why."]),
        poi(ZID, "swaledale_mintcake", (31, 6), "cache", item="kendal_mint_cake",
            line="Under a flat stone on the ridge: a tin, a dry sandwich, and a bar of mint cake in a wrapper from before you were born."),
        poi(ZID, "swaledale_camp", (68, 30), "camp", names=[["Lead Hunter Pat", "Poacher"], ["Lead Hunter Ed", "Poacher"]],
            party=["brockling", "stoatlet", "kitelet"], line="Looking for old lead on the spoil heaps. It's not illegal. It's very nearly rude.", money=2500, item="flask_of_tea")])
    add_data("field_spots", [
        fspot(ZID, "swaledale_wall", 36, 30, "mend", "wall_gap",
              "A gap in a Swaledale wall, one stone short of a good afternoon. {lead} nudges the capstone back in, snug as a key in a lock, and the farmer, watching from the barn door, tips his cap.",
              {"item": "flask_of_tea", "qty": 1})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
