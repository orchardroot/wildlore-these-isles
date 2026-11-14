# Wave 55 roads-celtic, route 4: the Glamorgan Heritage Coast. Swansea (west edge) to Cardiff (north edge): out along the
# Wales Coast Path past Merthyr Mawr, Ogmore and Nash Point, and back through the Vale by Llantwit Major and the road to
# the capital. Swansea and Cardiff both open by way of the Brecon Beacons, so there is no gate.
from w55_lib import *

ID = "glamorgan_coast"


def build(OUT):
    W, H = 64, 48
    FL = 35
    z = route(ID, "Glamorgan Heritage Coast", W, H, "south_wales", "route_coast", "coast", FL,
              {"clear": 22, "sunshine": 18, "drizzle": 20, "gale": 16, "fog": 10, "downpour": 14},
              {"west": ("swansea", 21), "north": ("cardiff", 8)})
    z.legend["g"] = {"tile": "grass", "colour": "#8a9a52"}
    z.scatter(0, 0, W, H, "P", 24, 5, only="T")
    # sea along the south, with a sand and shingle strip and cliffs above it
    z.rect(0, 40, W, 8, "$")
    z.rect(3, 38, W - 6, 2, "w")
    z.rect(3, 36, W - 6, 2, "s")
    z.rect(3, 34, 58, 2, "^")
    # Merthyr Mawr's dunes in the south west
    z.rect(3, 26, 22, 8, "s")
    z.rect(5, 28, 16, 4, ",")
    # the River Ogmore, with stepping stones where the path crosses
    river(z, 16, 13, 34, 3, amp=1.5, period=24.0, phase=0.8, bank="w")
    # the coast path out and the road back: an L
    z.rect(0, 20, 54, 3, "#")
    z.rect(51, 10, 3, 13, "#")
    z.rect(7, 10, 47, 3, "=")
    z.rect(7, 0, 3, 11, "=")
    for yy in (20, 21, 22):   # the stepping stones: the river is shallow here
        for xx in range(10, 24):
            if z.g[yy][xx] == "~":
                z.g[yy][xx] = "w"
    # Ogmore Castle by the river, and Llantwit Major's church in the Vale
    z.building(21, 15, 6, 3, "castle", "Ogmore Castle")
    z.building(14, 3, 6, 4, "chapel", "St Illtud's Church")
    z.building(22, 4, 5, 3, "slate_cottage", show_label=False)
    z.building(30, 4, 6, 3, "slate_cottage", show_label=False)
    z.rect(13, 7, 25, 1, ":"); z.rect(12, 8, 1, 2, ":")
    z.prop("lamp_post", 13, 8); z.prop("bench", 20, 8); z.prop("post_box", 29, 8)
    # St Donat's Castle on the coast, and the two Nash Point lighthouses on the cliff top
    z.building(40, 26, 8, 5, "castle", "St Donat's Castle")
    z.rect(43, 22, 1, 4, "#")
    z.prop("lighthouse", 34, 32); z.prop("lighthouse", 38, 33)
    z.rect(34, 22, 1, 9, "#")
    # tall grass for the wild things, and the usual hedges
    for (x, y, w, h) in [(4, 14, 14, 5), (30, 24, 8, 7), (44, 14, 7, 6), (46, 33, 12, 1), (4, 4, 6, 4), (14, 12, 8, 2), (56, 24, 5, 10)]:
        z.rect(x, y, w, h, ",")
        scatter_props(z, "bush", x, y, w, h, 2, x * 3 + y, avoid=(",",))
    scatter_props(z, "oak", 3, 3, 58, 30, 12, 21, avoid=(".",))
    scatter_props(z, "rock", 3, 3, 58, 36, 12, 22, avoid=(".", "s"))
    scatter_props(z, "sheep", 40, 12, 10, 8, 3, 23, avoid=(".",))
    z.d["spawn"] = [8, 8]
    finish_borders(z, "=")
    z.rect(0, 20, 3, 3, "#")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bw^":
            z.d["props"].remove(p_)

    sign(z, 5, 18, "WEST: Swansea and Gower. Gorllewin. The Wales Coast Path runs the whole way round the country, and the way round the country is long.")
    sign(z, 11, 5, "NORTH: Cardiff and the Bay. Gogledd. The road runs through the Vale of Glamorgan, which is as gentle as Wales gets.")
    sign(z, 22, 19, "OGMORE STEPPING STONES. A line of big stones across the river, put there by somebody who trusted your balance. Not recommended at high tide, or on the way home from the pub.")
    sign(z, 36, 30, "NASH POINT. A cliff-top lighthouse, a rocky shore, and a tide that goes out a very long way and comes back with an opinion.")
    plaque(z, 23, 18, "glamorgan_heritage_coast", "The Heritage Coast",
           "The Glamorgan Heritage Coast runs for fourteen miles from Porthcawl to Aberthaw, and was named a Heritage Coast in 1972. The cliffs are layers of blue-grey limestone and shale called the Blue Lias, laid down about two hundred million years ago, and the rocks are full of fossils. Hunters of ammonites should look down, and also up, for the cliffs fall.")
    plaque(z, 35, 31, "glamorgan_nash_point", "Nash Point Lighthouses",
           "There are two lighthouses at Nash Point, both built in 1832 to warn ships off the Nash Sands, a long sandbank offshore that has wrecked a great many of them. Between them they made a pair of lights that sailors could not mistake for any other on the coast. One of them has since been switched off, and the other does the work alone.")
    plaque(z, 17, 8, "glamorgan_illtud", "St Illtud of Llantwit Major",
           "At Llanilltud Fawr, now Llantwit Major, tradition places a school and monastery founded by St Illtud around the year 500. It is said to have taught saints and kings, and is counted among the oldest centres of learning in Britain. The church that stands there now has a fine collection of early carved Celtic crosses, which have survived a great deal more than most exam results.")
    plaque(z, 41, 31, "glamorgan_stdonat", "St Donat's Castle",
           "St Donat's is a medieval castle on the Vale of Glamorgan coast. In 1925 it was bought by the American newspaper owner William Randolph Hearst, who filled it with furniture and fittings from older buildings across Britain. Since 1962 it has been home to Atlantic College, a school that gathers students from across the world.")

    chat(z, "gc_guide", "tour_guide", 28, 19, "Path Warden",
         ["The Wales Coast Path was opened in 2012. It goes the whole way round the country, all eight hundred and some miles of it.",
          "You can walk it in sections. People do it in a summer. People also do it in a lifetime, in bits, with a flask."], "right", "still")
    chat(z, "gc_student", "gown_student", 38, 8, "Atlantic College Student",
         ["Our college is in the castle. It is the most beautiful place to be homesick in.",
          "We all learn to do the coastguard and rescue work, if you can believe it. A castle and a lifeboat. Odd, but it works."], "down", "still")
    chat(z, "gc_fossil", "explorer", 26, 24, "Fossil Hunter",
         ["Stand back from the cliff and look at the rocks on the beach. Half of them have a spiral in them. That is a fossil, or a very decorative accident.",
          "I once found an ammonite the size of a dinner plate. I was so pleased I forgot my own sandwich."], "down", "still")
    trainer2(z, "gc_surfer", "Surfer Dylan", "Surfer", "surfer", [("pupplash", 34), ("selklet", 35), ("gannetling", 35)],
             50, 28, "down", ["The Atlantic swell comes straight up the Channel and ends up here. It is beautiful and it will hold you under."],
             "Wiped out. In the best way.", "The waves at Southerndown are small. The ones at Porthcawl are smaller. Wales has a lot of coast and none of it is flat.", FL)
    trainer2(z, "gc_keeper", "Lighthouse Keeper Aled", "Keeper", "sailor", [("polartern", 35), ("chipgull", 34), ("petrelash", 36)],
             33, 25, "right", ["I used to keep a light. Now it is automatic, and I keep a view. It is less work and more thinking."],
             "All right. I lost my footing and my pride. Both will return by evening.", "A good light flashes the same pattern for a hundred years. I admire that, in a way.", FL)
    trainer2(z, "gc_walker", "Walker Heulwen", "Walker", "hiker", [("kitelet", 34), ("swiftlet", 35), ("starlet", 35)],
             10, 15, "right", ["I am walking the coast path in stages. This stage is Ogmore to Nash. It is mostly grass, with occasional drama."],
             "That was dramatic. I will include it in my diary.", "Wear proper boots. The coast path does not care about your trainers.", FL)

    wild2(z, [("chipgull", 34, 36, 20, {"time": ["day"]}), ("gannetling", 34, 36, 12, {"weather": ["clear", "sunshine"]}),
              ("starlet", 34, 36, 14, {}), ("swiftlet", 35, 36, 10, {"time": ["day", "dawn"]}),
              ("hootlet", 34, 36, 10, {"time": ["night"]}), ("flittermouse", 35, 36, 10, {"time": ["dusk", "night"]}),
              ("ternlet", 34, 36, 12, {"time": ["day", "dawn"]}), ("kitelet", 34, 36, 10, {}),
              ("pipkin", 34, 36, 10, {}), ("binfox", 35, 36, 8, {"time": ["dusk", "night"]})])
    wild2(z, [("pupplash", 34, 36, 24, {}), ("pinchkin", 34, 36, 20, {}), ("gannetling", 34, 36, 16, {}),
              ("stalklet", 34, 36, 16, {}), ("selklet", 35, 36, 12, {"time": ["dusk", "night", "dawn"]})], "water")
    open_gap("swansea", "east", 21, ID)
    open_gap("cardiff", "south", 8, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 10, 29, "pupplash", "glamorgan_coast")
    poi_stone(ID, 48, 12, "glamorgan_coast", "def", ["It is a boulder of grey limestone with a spiral on it, tucked into the grass by the road.", "The real thing is an ammonite fossil: the Blue Lias of the Glamorgan coast is full of them."])
    poi_cache(ID, 58, 30, "glamorgan_coast", "ammonite", "A jam jar under a stone. Inside, a spiral of grey rock, wrapped in a tea towel. Someone's pride and joy.")
    field_spot(ID, 7, 24, "mend", "wall_gap", "A wall with a tooth missing. {lead} rebuilds it with no mortar and a great deal of dignity, and finds %s in the hollow." % item_name("glamorgan_sausage"), "glamorgan_sausage", "glamorgan_coast")
    add_map_places({ID: (572, 1068)})
