# Road 1 (wave 55): Pendle Hill. Haworth (Brontë moor country) west over the Pennine edge to Blackpool, by Pendle Hill,
# the Ribble Valley and the Fylde. Same story step at both ends (the first step after the Field Station), so no gate.
from w55_lib import *

ZID = "pendle_hill"
W, H = 72, 46
FLOOR = 16   # Haworth 14, Blackpool 18


def build():
    z = route_zone(ZID, "Pendle Hill", W, H, "yorkshire", "route_moor", "moor", FLOOR,
                   {"drizzle": 32, "clear": 22, "fog": 16, "downpour": 10, "gale": 8, "sunshine": 12})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#7f7b49"},
        "m": {"tile": "grass", "colour": "#77804a"},
        "h": {"tile": "tall_grass", "colour": "#655060", "prop": "heather"},
        "k": {"tile": "tall_grass", "colour": "#7c7a47", "prop": "short"},
        "G": {"tile": "rock", "colour": "#6f6852", "prop": "gritstone"},
        "r": {"tile": "shallow", "prop": "reeds"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(69, 32, 3, 3), (0, 13, 3, 3)])
    z.scatter(0, 0, W, H, "P", 40, 11, only="T")
    # --- ground: heights climb to the Pendle massif in the north-middle
    hills(z, [(34, 9, 6, 22), (58, 22, 2, 14), (12, 16, 1, 10)])
    # heather on the high ground, short turf on the shoulders, green fields in the Ribble valley to the west
    for i, (cx, cy, rx, ry) in enumerate([(36, 8, 14, 5), (30, 15, 9, 3), (48, 14, 6, 4), (60, 12, 7, 4), (56, 38, 8, 4), (66, 24, 4, 3), (46, 38, 5, 3)]):
        blob(z, cx, cy, rx, ry, "h", only="g", seed=20 + i, jitter=0.5)
    for i, (cx, cy, rx, ry) in enumerate([(40, 18, 8, 2), (62, 30, 5, 2), (24, 8, 5, 3), (50, 24, 4, 2)]):
        blob(z, cx, cy, rx, ry, "k", only="gh", seed=40 + i, jitter=0.5)
    for x0 in range(3, 22):
        for y0 in range(3, 43):
            if z.g[y0][x0] == "g":
                z.set(x0, y0, "m")
    # --- the road: in from Haworth, over the moor, round the foot of the hill, down to the Ribble
    ROUTE = [(71, 33), (58, 33), (58, 27), (44, 27), (44, 22), (30, 22), (30, 14), (1, 14)]
    road(z, ROUTE, "#", 3)
    # Pendle summit trail (a narrow path up the Big End)
    road(z, [(31, 14), (36, 14), (36, 10)], "#", 1)
    # --- a beck across the moor with stepping fords
    for y in range(3, H - 3):
        x = 40 + int(round(1.2 * math.sin(y / 3.0)))
        for dx in (0, 1):
            if z.g[y][x + dx] not in "#":
                z.set(x + dx, y, "w")
    for y in range(3, H - 3):
        if z.g[y][40 + int(round(1.2 * math.sin(y / 3.0)))] != "#":
            pass
    # --- Haworth Moor: Top Withens ruin, gritstone, sheep
    z.building(52, 36, 5, 3, "stone", "Top Withens (ruin)")
    blob(z, 54, 40, 3, 1.5, "G", only="gh", seed=3, jitter=0.5)
    for (x, y) in [(50, 30), (53, 31), (62, 29), (64, 36), (47, 34)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- the Pendle massif
    z.prop("standing_stone", 36, 9, variant=0)
    z.prop("bench", 34, 11)
    for (cx, cy) in [(26, 6), (44, 5), (30, 10), (42, 12)]:
        blob(z, cx, cy, 2, 1.2, "G", only="gh", seed=cx, jitter=0.4)
    # --- Barley and the Ribble side: a hamlet, hedged fields, the canal
    z.building(22, 24, 5, 3, "lancs_limestone", "Barley Cottages", show_label=False)
    z.building(28, 25, 4, 3, "slate_cottage", "The Pendle Inn", door=None)
    z.building(6, 31, 9, 5, "mill_brick", "Weavers' Mill")
    z.rect(3, 38, 20, 1, "~"); z.rect(3, 37, 20, 1, "w"); z.rect(3, 39, 20, 1, "w")
    z.rect(8, 37, 3, 3, "#")   # a bridge over the canal
    z.prop("canal_boat", 14, 38, variant=0); z.prop("canal_boat", 19, 38, variant=1)
    hedge_line(z, 4, 19, 19, 19, gaps={(12, 19), (13, 19), (14, 19)})
    hedge_line(z, 4, 28, 20, 28)
    hedge_line(z, 19, 20, 19, 27)
    # --- signs and plaques
    sign(z, 68, 30, "EAST: Haworth, the Parsonage and a great many Brontë tea towels. WEST: Pendle Hill, Clitheroe and the Fylde coast. Mind the sheep, they have right of way.")
    plaque(z, 56, 31, "w55e_top_withens", "Top Withens",
           "A ruined farmhouse on the moor above Haworth, long said to be the model for Wuthering Heights, though the real house was a good deal smaller than the one in the book. The Brontë children walked these moors all the time. Emily Brontë's novel came out in 1847, and she died the next year at the parsonage in the village.")
    sign(z, 46, 24, "THE PENDLE WAY. Forty-five miles in a loop round Pendle Hill, waymarked with a witch on a broomstick. Nobody has asked her to move.")
    plaque(z, 32, 19, "w55e_pendle_witches", "The Pendle Witches",
           "In 1612 twelve people from the villages round Pendle Hill were accused of witchcraft. One died in Lancaster Castle before her trial, one was tried and hanged at York, and ten were hanged at Lancaster on 20 August 1612. It is one of the best documented witch trials in English history, mainly because the court clerk wrote it all down.")
    plaque(z, 38, 11, "w55e_george_fox", "George Fox on Pendle Hill",
           "In 1652 the preacher George Fox climbed Pendle Hill and had a vision of a great people to be gathered. That summer he went on to Firbank Fell and Sedbergh and drew crowds. Quakers count it as the beginning of their movement.")
    sign(z, 24, 12, "PENDLE HILL, the Big End. 557 metres of gritstone and heather, standing on its own above the Ribble Valley. On a clear day you can see Blackpool Tower. On most days you can see your own hand.")
    plaque(z, 12, 36, "w55e_leeds_liverpool", "The Leeds and Liverpool Canal",
           "Opened in 1816 after more than forty years of building, at 127 miles the longest canal in Britain built as a single waterway. It carried coal east and wool and cotton west, and it still crosses the Pennines. Through Burnley it rides a mile-long embankment above the mill roofs.")
    sign(z, 4, 16, "WEST: Clitheroe, Preston and the Fylde coast. Blackpool is thirty miles on, give or take a stag party.")
    sign(z, 18, 30, "WEAVERS' MILL. Cotton, until the 1960s. Nowadays a craft centre, a cafe and a very large flock of pigeons.")
    sign(z, 38, 15, "SUMMIT PATH. The Big End, then back down the same way. Please don't hurry the witches.")
    # --- people
    chat(z, "pn_walker", "hiker", 50, 28, "Brontë Walker",
         ["I walked from Haworth this morning to see Top Withens. It is a ruin and I loved every damp minute.",
          "The Brontës walked these moors for miles. Their father kept them out in all weathers, which explains the novels."], "down", "still")
    chat(z, "pn_guide", "tour_guide", 31, 20, "Witch Trail Guide",
         ["Welcome to Pendle! There is a witch trail every year on the anniversary and a pub that sells a lot of broomsticks.",
          "The real story is sadder than the fun. People who were poor, old and a bit too noisy got accused. I try to tell it straight."], "right", "still")
    chat(z, "pn_ranger", "villager_2", 38, 17, "Fell Ranger",
         ["The Quakers still come up here. They sit on the summit in silence. Very peaceful, apart from the wind, which is not a Quaker."], "left", "still")
    chat(z, "pn_miller", "villager_5", 10, 36, "Mill Volunteer",
         ["My great-gran was a weaver here. Four looms at once, the noise so loud they all learned to lip-read. Half this valley can read lips to this day."], "down", "still")
    # --- trainers
    tr(z, "pn_fellrunner", "Fell Runner Gwen", "Fell Runner", "fell_runner", [("scuttlet", 16), ("snowhare", 17), ("pipkin", 17)], 60, 31, "left",
       ["Pendle Fell Race: Barley to the summit and back, as fast as you like. I've done it in under an hour!"],
       "Off the pace. I'll walk the downhill.", "The record's mad. They fly down the loose bits. I fall down them.", 520, FLOOR)
    tr(z, "pn_witch_guide", "Walker Morag", "Hillwalker", "hillwalker", [("wispet", 17), ("hootlet", 16), ("sphagnet", 17)], 43, 29, "up",
       ["Pendle at dusk, in a fog? Wonderful. Terrifying. I carry a flask, and a very small kitchen knife for apples."],
       "I thought you'd cast a spell. It was only footwork.", "If you hear a cackle on the hill, it is probably the grouse. Probably.", 480, FLOOR)
    tr(z, "pn_farmer", "Farmer Dennis", "Farmer", "farmer", [("leveret", 16), ("zigzlet", 17), ("croakle", 16)], 14, 20, "down",
       ["Lambs are late, the beck's up and the dog's lost her marbles. And you want a fight. Right."],
       "Right. That's the day properly gone.", "Ribble Valley lamb is the best lamb in England. I will fight anyone who says otherwise. Except you. You've already won.", 500, FLOOR)
    tr(z, "pn_weaver", "Mill Hand Janet", "Weaver", "villager_6", [("starlet", 17), ("barnling", 16), ("rooklet", 17)], 5, 32, "up",
       ["I do the Saturday tours of the mill. Cotton, steam, a hundred looms. You've no idea how loud, love."],
       "Well, that's me deafened and beaten.", "The canal carried the cotton in and the cloth out. Every week.", 470, FLOOR)
    tr(z, "pn_birdwatcher", "Birdwatcher Phil", "Birdwatcher", "birdwatcher", [("kitelet", 17), ("starlet", 16), ("stoatlet", 17)], 22, 13, "right",
       ["Hen harriers breed in Bowland, just up the road. Not that I'd tell you where. Not that I'd be allowed."],
       "A fair fight. I'll note it in the logbook, under 'unusual behaviour'.", "In my day we didn't have binoculars like these. We had a hanky and hope.", 520, FLOOR)
    # --- wildlife
    wild(z, [("sphagnet", 16, 18, 14, {"weather": ["drizzle", "downpour", "fog"]}), ("pipkin", 16, 18, 12, {"time": ["dawn", "day"]}),
             ("scuttlet", 16, 18, 14, {"time": ["dawn", "day", "dusk"]}), ("snowhare", 16, 18, 10, {}),
             ("hootlet", 16, 18, 10, {"time": ["dusk", "night"]}), ("barnling", 16, 18, 8, {"time": ["night"]}),
             ("wispet", 16, 18, 8, {"weather": ["fog"]}), ("leveret", 16, 18, 10, {"time": ["dawn", "dusk"]}),
             ("kitelet", 16, 18, 8, {"time": ["day"]}), ("starlet", 16, 18, 8, {"time": ["day"]}),
             ("zigzlet", 16, 18, 8, {"time": ["day"], "weather": ["sunshine", "clear"]}), ("croakle", 16, 17, 8, {"weather": ["drizzle", "downpour"]})])
    wild(z, [("dipling", 16, 18, 26, {}), ("volet", 16, 18, 22, {}), ("croakle", 16, 18, 20, {}), ("stalklet", 16, 18, 18, {})], "water")
    # --- gaps joined to Haworth (east side of this zone) and Blackpool (west side)
    offE = link("haworth", "west", ZID, 33)
    offW = link("blackpool", "east", ZID, 14)
    z.d["edges"] = {"east": {"to": "haworth", "offset": offE}, "west": {"to": "blackpool", "offset": offW}}
    z.d["spawn"] = [68, 33]
    # --- scenery on free ground
    scatter_props(z, "bush", 3, 3, 66, 40, 36, 90, avoid=("g", "m"))
    scatter_props(z, "rock", 3, 3, 66, 40, 22, 91, avoid=("g", "h", "k"))
    scatter_props(z, "oak", 3, 3, 20, 40, 14, 92, avoid=("m",))
    z.d["region"] = "yorkshire"
    finish_zone(z, ZID)
    probs = check_route(z, [(70, 33), (1, 14)])
    for p in probs:
        print("PROBLEM:", p)
    add_place(ZID, 655, 762)
    add_data("poi", [
        poi(ZID, "pendle_stone", (37, 8), "stone", stat="lore",
            lore=["You put a hand on it. The wind drops. Somewhere below you a very small sheep says something rude.",
                  "The real thing is the trig point on Pendle Hill's summit, the Big End, 557 metres up. George Fox is said to have climbed it in 1652 before the vision that began the Quakers."]),
        poi(ZID, "pendle_hagstone", (21, 31), "cache", item="hag_stone",
            line="A flat stone by the wall, with a hole worn clean through it. Hung over a door, they say, it keeps witches out. It has not kept you out."),
        poi(ZID, "pendle_den", (27, 7), "den", species="hobthrust")])
    add_data("field_spots", [
        fspot(ZID, "pendle_round_up", 17, 22, "round_up", "sheep_gate",
              "Bowland sheep, all facing the wrong way and each convinced it is the one who is right. {lead} circles once, low, and the whole flock goes through the gate like water. The farmer leaves a flask on the post.",
              {"item": "flask_of_tea", "qty": 1})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
