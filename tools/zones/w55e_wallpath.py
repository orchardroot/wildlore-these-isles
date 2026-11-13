# Road 4 (wave 55): the western end of the Hadrian's Wall Path. Carlisle (east side) by Lanercost and the Irthing gorge
# to Birdoswald and on to the Wall zone (west side). Both ends open at the same story step.
from w55_lib import *

ZID = "hadrians_wall_path"
W, H = 72, 50
FLOOR = 84   # Carlisle 87, Hadrian's Wall 80


def build():
    z = route_zone(ZID, "Hadrian's Wall Path", W, H, "cumbria", "route_moors", "moor", FLOOR,
                   {"drizzle": 30, "clear": 24, "fog": 12, "downpour": 12, "gale": 8, "sunshine": 14})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#7e8c4e"},
        "m": {"tile": "grass", "colour": "#889a52"},
        "q": {"tile": "tall_grass", "colour": "#7c8a4a", "prop": "short"},
        "h": {"tile": "tall_grass", "colour": "#6e5a5c", "prop": "heather"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "W": {"tile": "drystone_wall", "colour": "#8a8470"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(0, 31, 3, 3), (69, 21, 3, 3)])
    z.scatter(0, 0, W, H, "P", 24, 3, only="T")
    # --- heights: the gorge of the Irthing runs north to south, the fort on its eastern lip, high ground by the Wall
    for y in range(H):
        for x in range(W):
            z.hg[y][x] = 2 if x > 40 and y < 24 else 1 if x > 28 else 0
    hills(z, [(60, 8, 4, 16), (10, 40, 1, 8)])
    for x in range(32, 40):
        for y in range(3, H - 3):
            z.hg[y][x] = 0
    for (cx, cy, rx, ry) in [(56, 8, 10, 4), (66, 36, 5, 3), (24, 8, 7, 3)]:
        blob(z, cx, cy, rx, ry, "h", only="g", seed=cx, jitter=0.5)
    for (cx, cy, rx, ry) in [(10, 14, 6, 3), (50, 38, 8, 3), (22, 40, 6, 3)]:
        blob(z, cx, cy, rx, ry, "q", only="g", seed=cy, jitter=0.5)
    # --- the River Irthing in its gorge, cliffs on both lips
    for y in range(3, H - 3):
        x = 35 + int(round(1.0 * math.sin(y / 4.0)))
        z.set(x - 1, y, "w"); z.set(x, y, "~"); z.set(x + 1, y, "w")
        z.set(x - 3, y, "^"); z.set(x + 3, y, "^")
    # --- the road: in from Carlisle, past Lanercost, over the Irthing, up to Birdoswald and the Wall
    ROUTE = [(1, 32), (20, 32), (20, 28), (35, 28), (35, 22), (70, 22)]
    road(z, ROUTE, "#", 3)
    road(z, [(35, 28), (35, 32), (44, 32)], "#", 1)      # a loop by the river
    # --- Lanercost Priory
    z.building(7, 22, 10, 5, "chapel", "Lanercost Priory")
    z.prop("bench", 12, 28)
    # --- Birdoswald fort and the Wall itself running east along the ridge
    z.building(46, 15, 10, 5, "castle", "Birdoswald Fort")
    z.building(58, 16, 4, 3, "castle", "Granary", show_label=False)
    for x in range(42, 69):
        if z.g[13][x] not in "#":
            z.set(x, 13, "W")
    z.set(52, 13, "g"); z.set(53, 13, "g")      # a milecastle gate
    for x in range(42, 69, 5):
        z.prop("rock", x, 11, variant=x % 3)
    z.rect(42, 27, 28, 1, "w")                  # the Vallum ditch, south of the Wall
    z.set(60, 27, "g"); z.set(61, 27, "g")
    # --- a bastle farm and a few sheep
    z.building(52, 36, 4, 3, "field_barn", "Bastle Farm")
    for (x, y) in [(46, 34), (50, 40), (58, 40), (64, 30), (14, 38), (24, 44)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- signs and plaques
    sign(z, 3, 28, "WEST: Carlisle, Tullie House and the cathedral. EAST: Lanercost, Birdoswald and the Wall, with all of Northumberland beyond it. Hadrian does not like to be hurried, he is two thousand years old.")
    plaque(z, 24, 30, "w55e_wall_path", "The Hadrian's Wall Path",
           "A National Trail opened in 2003. It runs 84 miles, 135 kilometres, from Wallsend on the Tyne to Bowness-on-Solway, following the line of the Wall as closely as the farmland and the law allow. Walkers go either way, though the prevailing wind is behind you if you start in the west.")
    plaque(z, 15, 29, "w55e_lanercost", "Lanercost Priory",
           "Founded in 1169 by Augustinian canons, and built largely from stone robbed out of the nearby Roman Wall. Edward I of England stayed here through the winter of 1306 to 1307, already ill, on his way to fight Robert the Bruce. He died the following July, less than twenty miles away at Burgh by Sands, still on the road north.")
    sign(z, 31, 26, "RIVER IRTHING. Crossed by the Romans on a stone bridge here: the abutment is still in the bank. The river takes no notice of either.")
    plaque(z, 49, 24, "w55e_birdoswald", "Birdoswald Roman Fort",
           "The Roman fort of Banna, on a spur above the Irthing gorge. West of the river the Wall was first built of turf rather than stone, and only rebuilt in stone later, which is why you can still see how the two kinds of Wall differ. There is a fine stretch of standing Wall here. After the Romans left, a family with a timber hall lived inside the fort walls for generations.")
    sign(z, 56, 24, "THE VALLUM. A deep flat-bottomed ditch with mounds on both sides, running south of the Wall. Archaeologists still argue about what it was for. The best guess is that it marked the military zone and kept the locals out.")
    sign(z, 54, 21, "MILECASTLE. A small gate fort, one for every Roman mile of the Wall, with two watchtowers between it and the next. Big enough for a few soldiers and a lot of sandwiches.")
    sign(z, 68, 20, "EAST: the Wall proper, Housesteads and the Sycamore Gap, then Newcastle. WEST: Lanercost and Carlisle. Mind the wind, and mind the sheep.")
    # --- people
    chat(z, "hp_walker", "hiker", 26, 27, "Wall Walker",
         ["Hadrian's Wall, ninety-odd miles from sea to sea, and not one of them flat. I'm having a lovely time. It says so on my blister plaster.",
          "People have been walking this line for two thousand years. Some were in sandals. They had a point."], "right", "still")
    chat(z, "hp_volunteer", "villager_2", 48, 21, "Fort Volunteer",
         ["Dig down under the granary and you find the timber halls that came after the Romans. Wood over stone. It's the wrong way round, but it's what happened.",
          "After they left, a family built a timber hall inside the old fort. People never really leave a good place. They just change the furniture."], "down", "still")
    chat(z, "hp_monk", "choir_singer", 12, 30, "Priory Guide",
         ["Edward I wintered here. He had the whole court in. Imagine the bills. Imagine the bacon.",
          "Lanercost has been repaired and added to many times. Half of it is used as a parish church today. The other half is roofless, which suits some of us."], "left", "still")
    chat(z, "hp_farmer", "farmer", 56, 33, "Bastle Farmer",
         ["Bastles are fortified farmhouses: thick walls, a ground floor for the cattle, the family up a ladder. All because the Border Reivers came by night.",
          "Cattle on the ground floor was good for heating and bad for visitors."], "down", "still")
    # --- trainers
    tr(z, "hp_centurion", "Centurion Titus", "Re-enactor", "hiker", [("legionette", 84), ("tapknock", 85), ("fawnlet", 84)], 40, 29, "up",
       ["I'm a legionary. Twenty-five years' service and a discharge bonus. Well, I'm a volunteer. But I do it properly."],
       "Stand down. I need a long sit and a short wine.", "Garrison life was dull, mostly. Cold, damp, and then some very cross barbarians. Same as a bank holiday.", 3500, FLOOR)
    tr(z, "hp_angler", "Angler Lorna", "Angler", "angler", [("bradan", 84), ("dipling", 84), ("ratty", 85)], 36, 34, "up",
       ["The Irthing runs fast and cold, and the salmon run it every autumn. Today the salmon are doing better than me."],
       "Fair play. I'll go back to the other end of the river.", "A salmon will go back to the river it was born in, years later, and leap a weir to do it. I couldn't get back to my own birthplace if there was a bus.", 3400, FLOOR)
    tr(z, "hp_reiver", "Rambler Alec", "Hillwalker", "hillwalker", [("reivling", 85), ("brockling", 84), ("starlet", 84)], 62, 24, "left",
       ["My family name is Armstrong. Reivers, all of them. Stealing cattle was the family trade for about three hundred years."],
       "Stolen fair and square, you'd say. I've no complaints.", "We went straight, mostly. The sheep still look at us oddly.", 3500, FLOOR)
    tr(z, "hp_birder", "Birdwatcher Joan", "Birdwatcher", "birdwatcher", [("kitelet", 84), ("ospret", 85), ("zigzlet", 84)], 22, 36, "right",
       ["Pied flycatchers nest in the oak woods in the gorge. Look, that's one! No, that's a leaf. Look, that's a leaf!"],
       "Oh, I missed a flycatcher for that.", "A pied flycatcher can find its way from West Africa back to the same oak. I find my way back to the car park with a map.", 3400, FLOOR)
    tr(z, "hp_warden", "Wall Warden Fiona", "Warden", "warden_grunt", [("slatelet", 85), ("tapknock", 84), ("thistlet", 85)], 66, 19, "down",
       ["I look after this stretch of Wall for the National Trust. It looks after me, mostly by raining on me."],
       "I'll put the Wall back, and you can put yourself back.", "Every year someone tries to take a stone home. I put it back. The stones have a better memory than the people.", 3500, FLOOR)
    # --- wildlife
    wild(z, [("kitelet", 84, 86, 12, {"time": ["day"]}), ("starlet", 84, 86, 10, {}), ("thistlet", 84, 86, 10, {}), ("fawnlet", 84, 86, 8, {}),
             ("brockling", 84, 86, 8, {"time": ["dusk", "night"]}), ("leveret", 84, 86, 8, {"time": ["dawn", "dusk"]}),
             ("zigzlet", 84, 86, 8, {"time": ["day"], "weather": ["sunshine", "clear"]}), ("flittermouse", 84, 86, 8, {"time": ["dusk", "night"]}),
             ("stoatlet", 84, 86, 8, {}), ("rooklet", 84, 86, 8, {}), ("slatelet", 84, 86, 8, {}), ("reivling", 84, 86, 6, {"time": ["dusk", "night"]}),
             ("midgie", 84, 86, 6, {"time": ["dawn", "dusk"], "weather": ["drizzle", "fog"]})])
    wild(z, [("bradan", 84, 86, 20, {}), ("dipling", 84, 86, 26, {}), ("ratty", 84, 86, 20, {}), ("ospret", 84, 86, 14, {}), ("cranelet", 84, 86, 14, {})], "water")
    offW = link("carlisle", "east", ZID, 32)
    offE = link("hadrians_wall", "west", ZID, 22)
    z.d["edges"] = {"west": {"to": "carlisle", "offset": offW}, "east": {"to": "hadrians_wall", "offset": offE}}
    z.d["spawn"] = [3, 32]
    scenery(z, 600, bushes=26, rocks=14, trees=12, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(1, 32), (70, 22)]):
        print("PROBLEM:", p)
    add_place(ZID, 668, 606)
    add_data("poi", [
        poi(ZID, "wallpath_stone", (44, 9), "stone", stat="def",
            lore=["It is a squared stone, with a groove cut in one face. Somebody's initials, you suspect, and a long way before the Normans.",
                  "The real thing is the Wall itself: begun about AD 122 on the orders of Hadrian, 73 miles from the Tyne to the Solway, and later plundered for farms, bridges and abbeys all along its length."]),
        poi(ZID, "wallpath_cache", (28, 14), "cache", item="miners_lamp",
            line="Tucked in a gap between two stones, a very old-looking lantern. Or a very new one with a good story."),
        poi(ZID, "wallpath_camp", (62, 42), "camp", names=[["Reiver Dougie", "Poacher"], ["Reiver Beth", "Poacher"]],
            party=["reivling", "stoatlet", "brockling"], line="Borrowing a few sheep. Strictly, it's tradition. Not that tradition holds up in court.", money=2500, item="flask_of_tea")])
    add_data("field_spots", [
        fspot(ZID, "wallpath_wall", 52, 12, "mend", "wall_gap",
              "A gap in a drystone dyke, a few stones short. {lead} lifts them back, one by one, and the farmer waves a stick from the next field. Under the last stone: a handful of loose change from the 1950s.",
              {"money": 330})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
