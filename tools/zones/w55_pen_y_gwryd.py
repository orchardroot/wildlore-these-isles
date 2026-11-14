# Wave 55 roads-celtic, route 2: Pen-y-Gwryd and Capel Curig. Nant Ffrancon and Ogwen (north edge) to Yr Wyddfa (west
# edge): the A5 into Capel Curig, the A4086 past the Llynnau Mymbyr and Pen-y-Gwryd, and the start of the Miners' Track.
# Ogwen and Yr Wyddfa both open on the road to Llanberis, so there is no gate.
from w55_lib import *

ID = "pen_y_gwryd"


def build(OUT):
    W, H = 60, 44
    FL = 28
    z = route(ID, "Pen-y-Gwryd and Capel Curig", W, H, "north_wales", "route_mountain", "mountain", FL,
              {"fog": 24, "drizzle": 24, "clear": 16, "sunshine": 8, "downpour": 12, "gale": 10, "frost": 6},
              {"north": ("ogwen", 34), "west": ("yr_wyddfa", 27)}, base="m", border="R")
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["m"] = {"tile": "grass", "colour": "#848a52"}
    z.legend["h"] = {"tile": "tall_grass", "colour": "#7a6478", "prop": "heather"}
    # heather on the slopes, bare rock higher up
    for (x, y, w, h) in [(4, 4, 18, 6), (38, 14, 18, 8), (4, 30, 14, 10), (44, 28, 12, 12)]:
        z.rect(x, y, w, h, "h")
    z.rect(20, 28, 36, 13, "R")
    z.scatter(20, 28, 36, 13, "m", 60, 11, only="R")
    # Llynnau Mymbyr: two long lakes under the Snowdon Horseshoe
    blob(z, 22, 17, 10, 3, "~", seed=4)
    blob(z, 22, 17, 12, 4, "r", only="mh", seed=5)
    # Llyn Llydaw, up the Miners' Track
    blob(z, 38, 36, 7, 3, "~", seed=6)
    blob(z, 38, 36, 9, 4, "r", only="mhR", seed=7)
    # roads: the A5 comes in from the north, the A4086 runs west along the lakes to Pen-y-Gwryd and on to Pen-y-Pass
    z.rect(33, 0, 3, 14, "=")
    z.rect(8, 11, 28, 3, "=")
    z.rect(8, 11, 3, 18, "=")
    z.rect(0, 26, 11, 3, "=")
    # the Miners' Track: a stony path to the lake with a causeway across it
    z.rect(11, 29, 3, 1, "#"); z.rect(13, 29, 18, 1, "#")
    z.rect(30, 29, 1, 7, "#"); z.rect(30, 35, 16, 1, "#")
    z.rect(31, 36, 14, 1, "w")
    z.rect(31, 35, 14, 1, "=")
    # Capel Curig: a handful of buildings round the junction
    z.building(37, 4, 7, 4, "white_render", "Plas y Brenin")
    z.building(46, 4, 6, 4, "slate_cottage", show_label=False)
    z.building(37, 15, 6, 4, "slate_cottage", show_label=False)
    z.rect(36, 8, 18, 1, ":"); z.rect(36, 14, 1, 1, ":")
    z.prop("lamp_post", 36, 9); z.prop("bench", 45, 9); z.prop("post_box", 44, 9)
    # Pen-y-Gwryd Hotel and its yard
    z.building(14, 22, 7, 4, "stone", "Pen-y-Gwryd Hotel")
    z.rect(11, 26, 12, 1, ":")
    z.prop("bench", 22, 26); z.prop("lamp_post", 12, 26)
    # Cwm Dyli power station
    z.building(46, 22, 6, 3, "stone", "Cwm Dyli Power Station")
    z.rect(40, 25, 14, 1, "#"); z.rect(40, 25, 1, 5, "#")
    # tall grass for the wild things
    for (x, y, w, h) in [(14, 4, 14, 5), (44, 12, 10, 6), (24, 22, 12, 5), (4, 14, 4, 9), (4, 31, 8, 8), (45, 38, 10, 3)]:
        z.rect(x, y, w, h, ",")
        scatter_props(z, "bush", x, y, w, h, 3, x * 3 + y, avoid=(",",))
    z.rect(36, 24, 9, 1, "m")
    scatter_props(z, "rock", 3, 3, 54, 38, 22, 12, avoid=("m", "h"))
    scatter_props(z, "sheep", 4, 4, 18, 6, 4, 13, avoid=("h",))
    z.d["spawn"] = [34, 9]
    finish_borders(z, "=")
    # the gap into Ogwen is road, the way into Yr Wyddfa is path
    for (x, y, gw, gh) in z.gaps:
        if x < 3 and gh == 3:
            z.rect(x, y, gw, gh, "#")
    z.rect(0, 26, 3, 3, "#")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bw":
            z.d["props"].remove(p_)

    sign(z, 31, 3, "NORTH: Nant Ffrancon and Ogwen. Gogledd. The A5 carries on to Bethesda and the sea, and it is the route Telford built to get the mail to Holyhead.")
    sign(z, 6, 24, "WEST: Pen-y-Pass and Yr Wyddfa. Gorllewin. The Miners' Track and the Pyg Track both start a mile up the road. Nobody agrees on why the second one is called Pyg.")
    sign(z, 9, 30, "CRIB GOCH. 'Red ridge'. A knife edge of rock on the Snowdon Horseshoe that has made a great many brave people say a short word. Not a place for a first date.")
    sign(z, 34, 33, "THE MINERS' TRACK. Copper miners walked this way to the mine under the mountain. It is now one of the easier ways up Yr Wyddfa, which is not the same thing as easy.")
    plaque(z, 17, 27, "pen_y_gwryd_everest", "Everest, 1953",
           "In 1953 the British team that was about to attempt Everest trained in these hills and stayed at the Pen-y-Gwryd Hotel. Their signatures are still on the ceiling of the smoke room, with the names of climbers who came after them. On 29 May Edmund Hillary and Tenzing Norgay reached the summit.")
    plaque(z, 38, 34, "pen_y_gwryd_causeway", "The Llydaw Causeway",
           "The causeway across Llyn Llydaw was built in 1853 for the Britannia copper mine, whose workings lie beneath the high lake Glaslyn. Ore came down in sledges and went on by cart and by water. Walkers took over the miners' track long ago, and the causeway has been getting more use since the mine closed than it ever did while the mine worked.")
    plaque(z, 44, 24, "pen_y_gwryd_dyli", "Cwm Dyli",
           "The power station at Cwm Dyli opened in 1906. Water piped from Llyn Llydaw falls the long way down the hillside to the turbines, and the station is one of the oldest hydroelectric stations in Britain that still works. It makes electricity without anybody remarking on it, which is the best kind.")

    chat(z, "pyg_landlord", "villager_2", 18, 27, "Hotel Landlord",
         ["The ceiling in the smoke room is covered in signatures. Climbers have been signing it since before the war, and the Everest team of 1953 signed it too.",
          "Come in for tea, if the weather turns. In this valley the weather turns about every nine minutes."], "up", "still")
    chat(z, "pyg_instructor", "hiker", 40, 9, "Mountain Instructor",
         ["I teach people to read a map in a cloud. You are meant to be calm. They are meant to be calm too. That is the difficult bit.",
          "Plas y Brenin is the national mountain centre. Half the people you see on the hills in Britain learned something here."], "down", "still")
    chat(z, "pyg_photographer", "tour_guide", 20, 14, "Photographer",
         ["Everyone stands here for the photograph. The lakes, the ridge, the reflection. It is a good photograph.",
          "The Horseshoe in the morning is a postcard. By lunchtime it is a cloud. I take my pictures early and eat my sandwiches late."], "down", "wander")
    trainer2(z, "pyg_instructor_t", "Instructor Rhian", "Instructor", "hillwalker", [("kidgruff", 27), ("slatelet", 28), ("cragchough", 28)],
             35, 20, "up", ["Right. Compass out. Which way is north? It is a trick question, the cloud has taken it."],
             "Fair enough. You went the right way and you did not even look at the map.", "Always pack for the weather you did not forecast.", FL)
    trainer2(z, "pyg_climber", "Climber Gareth", "Climber", "hiker", [("prismite", 28), ("tapknock", 28), ("wispet", 29)],
             29, 31, "right", ["I am on my way up Crib Goch. Do not talk about it. I am concentrating on not talking about it."],
             "Well. That was less frightening than the ridge. Barely.", "Three points of contact at all times. Four, if you can find a fourth.", FL)
    trainer2(z, "pyg_runner", "Fell Runner Sioned", "Fell Runner", "fell_runner", [("brockling", 27), ("martling", 28), ("hootlet", 28)],
             49, 16, "left", ["I am running the Horseshoe in under four hours. It is a very personal goal. Please do not speak while I lose it."],
             "That cost me a minute. I shall blame you at the finish.", "Run on a clear day, if you can find one. Wear the bright jacket if you cannot.", FL)

    wild2(z, [("kidgruff", 27, 29, 22, {}), ("slatelet", 27, 29, 18, {}), ("brockling", 27, 29, 14, {"time": ["dawn", "day", "dusk"]}),
              ("martling", 28, 29, 12, {"time": ["dusk", "night"]}), ("tylwyth", 27, 29, 10, {"time": ["dawn", "dusk"]}),
              ("cragchough", 27, 29, 14, {}), ("wispet", 28, 29, 10, {"weather": ["fog", "drizzle"]}),
              ("hootlet", 27, 29, 8, {"time": ["night"]}), ("tapknock", 28, 29, 8, {})])
    wild2(z, [("afanc", 28, 29, 22, {}), ("dipling", 27, 29, 36, {}), ("ratty", 27, 29, 30, {}), ("elverlet", 28, 29, 14, {})], "water")
    open_gap("ogwen", "south", 34, ID)
    open_gap("yr_wyddfa", "east", 27, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_stone(ID, 8, 36, "pen_y_gwryd", "def", ["It is sharp and cold and has been left exactly where the glacier dropped it.", "The real thing is the glacial erratics of Eryri, boulders the ice carried and dropped across Snowdonia."])
    poi_cache(ID, 52, 40, "pen_y_gwryd", "bog_myrtle_sprig", "A flask in a crack in the rock. Someone's emergency tea. They will not be needing it now that you have found it.")
    field_spot(ID, 7, 22, "charm", "molehill", "Soft ground, a patient creature, and a lot of worms. {lead} brings up the lot, and under them: %s." % item_name("four_leaf_clover"), "four_leaf_clover", "pen_y_gwryd")
    add_map_places({ID: (548, 866)})
