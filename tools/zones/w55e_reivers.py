# Road 5 (wave 55): the Border Reivers' road. Carlisle (north side) over the Esk and the Debatable Land to Gretna and the
# Liddesdale hills, into the Scottish Borders (south side). A border crossing: England to Scotland. Both ends open at the
# same story step, so no gate.
from w55_lib import *

ZID = "reivers_road"
W, H = 60, 64
FLOOR = 78   # Carlisle 87, Scottish Borders 69


def build():
    z = route_zone(ZID, "The Debatable Land", W, H, "scotland", "route_moors", "valley", FLOOR,
                   {"drizzle": 30, "clear": 22, "fog": 14, "downpour": 12, "gale": 8, "sunshine": 14})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#7b8c4c"},
        "m": {"tile": "grass", "colour": "#879a52"},
        "q": {"tile": "tall_grass", "colour": "#7b8a49", "prop": "short"},
        "h": {"tile": "tall_grass", "colour": "#6e5a5c", "prop": "heather"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "W": {"tile": "drystone_wall", "colour": "#8a8470"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(29, 61, 3, 3), (29, 0, 3, 3)])
    z.scatter(0, 0, W, H, "P", 20, 9, only="T")
    # --- hills rise to the north, the Liddesdale tops
    hills(z, [(14, 12, 5, 16), (46, 8, 4, 14), (30, 4, 3, 12)])
    for (cx, cy, rx, ry) in [(14, 12, 8, 4), (46, 8, 8, 3), (30, 6, 9, 3), (50, 46, 5, 3)]:
        blob(z, cx, cy, rx, ry, "h", only="g", seed=cx + cy, jitter=0.5)
    for (cx, cy, rx, ry) in [(16, 30, 7, 3), (44, 28, 8, 3), (12, 50, 6, 3), (40, 54, 8, 2)]:
        blob(z, cx, cy, rx, ry, "q", only="g", seed=cx * cy, jitter=0.5)
    for y in range(26, 58):
        for x in range(3, W - 3):
            if z.g[y][x] == "g":
                z.set(x, y, "m")
    # --- the River Esk across the south of the zone: the Border, with Longtown and the bridge
    for x in range(3, W - 3):
        y = 52 + int(round(1.5 * math.sin(x / 5.0)))
        z.set(x, y - 1, "w"); z.set(x, y, "~"); z.set(x, y + 1, "w")
    # --- the Sark and the Scotch Dyke: a ditch and bank line marking the old Debatable Land's edge
    for y in range(26, 50):
        z.set(14, y, "w")
    # --- the road: up from Carlisle, over the Esk, through the Debatable Land, on to Gretna and the hills
    ROUTE = [(30, 62), (30, 56), (30, 46), (22, 46), (22, 34), (40, 34), (40, 24), (30, 24), (30, 1)]
    road(z, ROUTE, "#", 3)
    # --- Gretna: the Old Blacksmith's Shop and some wedding-wagon cottages
    z.building(42, 36, 6, 4, "stone", "Old Blacksmith's Shop")
    z.building(49, 37, 4, 3, "slate_cottage", "", show_label=False)
    z.building(36, 40, 4, 3, "white_render", "", show_label=False)
    z.prop("lamp_post", 41, 41); z.prop("bench", 45, 41)
    # --- bastles and a ruined tower, Reiver country
    z.building(8, 40, 4, 3, "field_barn", "Bastle House")
    z.building(10, 16, 5, 4, "stone", "Reiver Tower (ruin)")
    z.building(46, 14, 8, 5, "castle", "Hermitage Castle")
    z.prop("flagpole", 55, 14)
    for (x, y) in [(6, 28), (11, 32), (26, 40), (50, 28), (48, 42), (16, 22)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- the borderline itself: a standing stone and a sign across the road
    z.prop("standing_stone", 25, 21, variant=0); z.prop("standing_stone", 35, 21, variant=1)
    # --- signs and plaques
    sign(z, 28, 59, "SOUTH: Carlisle and England. NORTH: the Debatable Land, Gretna and the Scottish Borders. Cattle prices have not changed. The reivers' views on them have.")
    plaque(z, 33, 55, "w55e_border_reivers", "The Border Reivers",
           "For about three hundred years, from the end of the 13th century until the Union of the Crowns in 1603, families on both sides of the Anglo-Scottish border raided each other for cattle and goods. They included Armstrongs, Elliots, Grahams and Nixons, and many were loyal to their family before either crown. Our word 'blackmail' comes from the protection money farmers paid to be left alone.")
    plaque(z, 25, 44, "w55e_debatable_land", "The Debatable Land",
           "A strip of land between the rivers Esk and Sark that both England and Scotland claimed, and neither governed. It became a refuge for outlaws and reivers. In 1552 a border commission divided it with a ditch and bank, the Scotch Dyke, and the Debatable Land ceased to be debatable, at least on paper.")
    sign(z, 20, 38, "SARK. The river is the boundary here. The Sark was a name for trouble long before the toll bridge. Don't mind the dyke, it's mostly grass now.")
    plaque(z, 44, 34, "w55e_gretna", "Gretna Green",
           "In 1754 Lord Hardwicke's Marriage Act tightened the rules for marrying in England, but Scotland's law stayed looser: young couples could marry there without a parent's consent. Gretna was the first village across the border on the main road north, and runaway couples hurried to the blacksmith's, who was as good as any priest. Thousands were married here, and people still are.")
    sign(z, 36, 28, "BORDER. A sign, a stone, a lay-by and a slightly different type of rain. You are in Scotland, or you will be in about eleven steps.")
    plaque(z, 44, 21, "w55e_hermitage", "Hermitage Castle",
           "A brooding fortress in Liddesdale, rebuilt in the 14th century and held by powerful border families. In October 1566 Mary, Queen of Scots, rode here from Jedburgh to visit her wounded favourite, the Earl of Bothwell, and back again, a round trip of about fifty miles. She fell dangerously ill soon after. The castle has a bad name for ghosts.")
    sign(z, 28, 3, "NORTH: the Scottish Borders. Melrose, the Eildon Hills and a pig with a lot of opinions. SOUTH: Gretna, Longtown and Carlisle.")
    # --- people
    chat(z, "rr_clerk", "tour_guide", 43, 33, "Gretna Guide",
         ["Come in, come in. This is the anvil. Couples would clasp hands over it and a blacksmith would hit it with a hammer. Whack. That was the wedding. Cheaper than a church.",
          "The blacksmiths were called anvil priests. They are in the village records, with all their fees."], "right", "still")
    chat(z, "rr_walker", "hiker", 27, 49, "Border Walker",
         ["Which side of the border am I on? I've gone back and forth five times this morning. The signs have an opinion. My boots don't.",
          "They say a Reiver's wife would serve her man a spur on a dish when the larder was bare. That was her way of saying 'time to go and steal dinner'."], "down", "still")
    chat(z, "rr_historian", "villager_4", 12, 21, "Border Historian",
         ["A reiver was a rider: light horse, a steel cap, a long spear and no scruples. They called a good night's raid 'Hot Trod' when the injured chased them back across the border. Good law on one side, no law on the other.",
          "The Union of the Crowns in 1603 ended it. King James VI and I called the borders 'the Middle Shires' to stop people being so sensitive."], "right", "still")
    chat(z, "rr_stationman", "rail_guard", 33, 28, "Railway Volunteer",
         ["There was a line here once, the Waverley Route: Edinburgh, Galashiels, Hawick, Carlisle. It closed in January 1969, to a great deal of regret.",
          "Part of it came back in 2015. Edinburgh to Tweedbank. Not as far as Hawick, but folk live in hope."], "left", "still")
    # --- trainers
    tr(z, "rr_reiver", "Rider Archie", "Rider", "hillwalker", [("reivling", 78), ("reiver", 79), ("foalmoor", 78)], 31, 41, "left",
       ["My name's Elliot, and I can tell you my forebears were great men. Stole a cow once from a man called Elliot. Then gave it back."],
       "Fair enough. A raid I didn't see coming.", "The reivers had their own code. Cattle, yes. Women and children, no. Mostly.", 3000, FLOOR)
    tr(z, "rr_blacksmith", "Blacksmith Callum", "Blacksmith", "steelworker", [("sailet", 78), ("thistlet", 79), ("tapknock", 78)], 39, 37, "up",
       ["I run the forge at Gretna. Fifty weddings a week in the summer. Mind the hammer and your credentials."],
       "A pity. I'd have done you a wedding rate.", "A Gretna wedding can be done in about ten minutes. Longer if there's a photographer and a piper.", 3000, FLOOR)
    tr(z, "rr_birder", "Birdwatcher Moira", "Birdwatcher", "birdwatcher", [("ospret", 78), ("starlet", 78), ("kitelet", 79)], 28, 36, "right",
       ["Solway marshes, just south. The pink-footed geese come in their tens of thousands each winter. Not today, though. Today it's just me."],
       "Well. I've learned something. Keep an eye on you.", "Solway is the sort of estuary where you can see a mile and still not see where the sea has gone.", 3000, FLOOR)
    tr(z, "rr_shepherd", "Shepherd Gordon", "Shepherd", "farmer", [("herdlet", 78), ("tattybogle", 79), ("eildonmare", 79)], 45, 28, "down",
       ["Blackface sheep, mainly. A Borders shepherd needs three things: a dog, a stick and a very bad memory for the price of lamb."],
       "Right. I'll have to sit down and have a think about this.", "My dog would have beaten you. But you didn't bring a sheep.", 3100, FLOOR)
    tr(z, "rr_rider", "Rider Joanne", "Rider", "hillwalker", [("foalmoor", 78), ("reivling", 78), ("hootlet", 78)], 24, 14, "right",
       ["Common Riding season! We ride the bounds of the town on horseback. Hundreds of us. Half a day of mud and then a very big tea."],
       "Well ridden. I'll write it down in the standing orders.", "The Common Ridings have been going since the 1500s. They never really stopped, whatever the Union said.", 3100, FLOOR)
    # --- wildlife
    wild(z, [("reivling", 78, 80, 12, {"time": ["dusk", "night"]}), ("foalmoor", 78, 80, 10, {}), ("thistlet", 78, 80, 10, {}), ("herdlet", 78, 80, 10, {}),
             ("leveret", 78, 80, 8, {"time": ["dawn", "dusk"]}), ("stoatlet", 78, 80, 8, {}), ("hootlet", 78, 80, 8, {"time": ["dusk", "night"]}),
             ("ospret", 78, 80, 6, {"time": ["day"]}), ("reiver", 78, 80, 5, {"time": ["night"]}), ("tattybogle", 78, 80, 8, {"time": ["dusk", "night"]}),
             ("starlet", 78, 80, 8, {}), ("kitelet", 78, 80, 8, {"time": ["day"]}), ("midgie", 78, 80, 6, {"time": ["dawn", "dusk"], "weather": ["drizzle", "fog"]})])
    wild(z, [("bradan", 78, 80, 20, {}), ("ratty", 78, 80, 20, {}), ("dipling", 78, 80, 24, {}), ("stalklet", 78, 80, 16, {}), ("ospret", 78, 80, 12, {})], "water")
    offS = link("carlisle", "north", ZID, 30, water_ok=True)
    offN = link("scottish_borders", "south", ZID, 30)
    z.d["edges"] = {"south": {"to": "carlisle", "offset": offS}, "north": {"to": "scottish_borders", "offset": offN}}
    z.d["spawn"] = [30, 60]
    scenery(z, 700, bushes=24, rocks=14, trees=10, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(30, 63), (30, 0)]):
        print("PROBLEM:", p)
    add_place(ZID, 612, 575)
    add_data("poi", [
        poi(ZID, "reivers_stone", (23, 22), "stone", stat="atk",
            lore=["It is a boundary stone, and it leans slightly Scottish. Or you are leaning slightly English. Hard to say.",
                  "The real thing is the Scotch Dyke, the ditch and bank dug in 1552 to divide the Debatable Land between England and Scotland after generations of argument."]),
        poi(ZID, "reivers_cache", (8, 46), "cache", item="horseshoe",
            line="In the hollow of an old wall, wrapped in oilskin: a horseshoe, a handful of copper coins and a very short list of other people's cows."),
        poi(ZID, "reivers_den", (50, 50), "den", species="eildonmare")])
    add_data("field_spots", [
        fspot(ZID, "reivers_roundup", 14, 34, "round_up", "sheep_gate",
              "Blackface sheep, all facing the border and none crossing it. {lead} nips round the back, low and quick, and the lot of them stream through the gate into England, or possibly Scotland. The farmer will not say which. He leaves a flask on the post.",
              {"item": "flask_of_tea", "qty": 1})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
