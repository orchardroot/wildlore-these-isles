# Wave 55 roads-celtic, route 11: the Erne shore road. Donegal Town (east edge, so the route's west edge) to Enniskillen
# (west edge, so the route's east edge): the A46 and the N15 by Belleek and Ballyshannon. Donegal opens only after the
# Antrim coast does, so the road is shut at the Enniskillen end until badge_iron, the flag on the Belfast gate.
from w55_lib import *

ID = "erne_shore"
GATE_FLAG = "badge_iron"


def build(OUT):
    W, H = 64, 46
    FL = 65
    z = route(ID, "The Erne Shore Road", W, H, "ireland", "route_lakes", "valley", FL,
              {"drizzle": 32, "clear": 20, "fog": 12, "sunshine": 12, "downpour": 16, "gale": 8},
              {"west": ("donegal_town", 20), "east": ("enniskillen", 26)})
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["g"] = {"tile": "grass", "colour": "#7fa04a"}
    z.legend["h"] = {"tile": "tall_grass", "colour": "#7a5c6a", "prop": "heather"}
    z.rect(3, 3, 58, 40, "g")
    z.scatter(0, 0, W, H, "P", 14, 5, only="T")
    # Lough Erne to the north, with islands in it, and the river running out of it to the sea in the west
    z.rect(3, 3, 58, 9, "~")
    z.rect(3, 12, 58, 1, "r")
    for (cx, cy, rx, ry, sd) in [(24, 6, 3, 1, 3), (36, 8, 4, 2, 4), (48, 5, 3, 1, 5), (54, 9, 2, 1, 6)]:
        blob(z, cx, cy, rx, ry, "g", seed=sd)
    z.rect(3, 12, 20, 2, "~")
    # Cuilcagh, a heather mountain in the south east, with a boardwalk up it
    z.rect(44, 33, 17, 10, "h")
    z.rect(52, 34, 1, 8, "#")
    # the road: out of Donegal Town, along the shore past Ballyshannon and Belleek to Enniskillen
    poly(z, [(0, 20), (26, 20), (26, 26), (63, 26)], "=", 3)
    # Belleek: the pottery on the river bank
    z.building(8, 15, 8, 4, "white_render", "Belleek Pottery")
    z.building(18, 15, 5, 3, "slate_cottage", show_label=False)
    z.rect(7, 19, 17, 1, ":"); z.rect(10, 19, 1, 1, ":")
    z.prop("lamp_post", 7, 18); z.prop("bench", 20, 18)
    # the hydro station and a chapel on the shore
    z.building(34, 14, 6, 3, "stone", "Hydro Station")
    z.building(46, 15, 5, 3, "chapel", "Shore Chapel")
    z.rect(35, 17, 1, 3, "#"); z.rect(47, 18, 1, 2, "#")
    # fields, hedges and tall grass
    for (x, y, w, h) in [(4, 22, 14, 14), (28, 28, 14, 10), (28, 14, 4, 5), (40, 20, 12, 4), (4, 38, 22, 4), (54, 28, 6, 10)]:
        z.rect(x, y, w, h, ",")
        scatter_props(z, "bush", x, y, w, h, 3, x * 3 + y, avoid=(",",))
    z.rect(4, 36, 22, 1, "H"); z.rect(12, 36, 2, 1, ".")
    scatter_props(z, "oak", 3, 3, 58, 40, 14, 91, avoid=("g",))
    scatter_props(z, "sheep", 4, 22, 14, 14, 3, 92, avoid=(",",))
    scatter_props(z, "rock", 3, 3, 58, 40, 6, 93, avoid=("g", "h"))
    scatter_props(z, "boat", 14, 4, 40, 7, 0, 94, avoid=("~",))
    z.d["spawn"] = [12, 20]
    finish_borders(z, "=")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bwr":
            z.d["props"].remove(p_)

    sign(z, 4, 17, "WEST: Ballyshannon and Donegal Town. The road goes by the river mouth and the old falls, and on to the castle of the O'Donnells.")
    sign(z, 59, 29, "EAST: Enniskillen. The county town sits on an island in the lough, and has done since before the bridges.")
    sign(z, 13, 21, "BELLEEK. A village on the River Erne, split in two by the border on the old maps and joined together by a shared interest in good china.")
    sign(z, 50, 40, "CUILCAGH. A bog on a mountain, with a boardwalk across it known as the Stairway to Heaven. It was built to protect the bog, and the walkers were told it was for the walkers.")
    plaque(z, 12, 20, "erne_belleek", "Belleek Pottery",
           "Belleek Pottery was founded in 1857 beside the River Erne, and is among the oldest working potteries in Ireland. It makes a very thin, glowing china called parian, and is best known for its basket-weave pieces, which look as if they were woven out of white shells. The potters work in the same village their grandparents did, and the kiln smoke is almost nostalgic.")
    plaque(z, 36, 18, "erne_hydro", "The Erne Hydro Scheme",
           "The Erne was dammed for hydroelectric power in the 1940s and 1950s, with stations at Cliff and at Cathaleen's Fall near Ballyshannon. It was one of the first big schemes of the new Irish state. The falls at Assaroe had been famous for centuries and were much reduced by the project, and the stations still work.")
    plaque(z, 48, 38, "erne_cuilcagh", "The Cuilcagh Boardwalk",
           "Cuilcagh Mountain, on the Fermanagh and Cavan border, is covered in a blanket of peat that has been forming for thousands of years. A boardwalk, opened in 2015, carries walkers across the bog to the foot of the summit, so that the bog can go on being a bog under their feet. It is nicknamed the Stairway to Heaven. It is all good, plain timber, and the view at the top is a lot of Ireland at once.")

    chat(z, "es_potter", "shopkeeper", 13, 20, "Potter",
         ["Parian china. It's fired thin, so you can see the light through the cup. If you drop it, you'll hear the whole parish sigh.",
          "The basket-weave's the thing. Every piece is rolled by hand, from strips of clay. It's slow, but it's Belleek."], "up", "still")
    chat(z, "es_hydro_man", "steelworker", 36, 20, "Hydro Engineer",
         ["The falls at Assaroe were a sight. When they built the station, a lot of that was gone. Everyone has views on it. I just keep the turbines turning.",
          "Forty years of electricity from the Erne. A lough that makes your tea. That's a good trade."], "up", "still")
    chat(z, "es_walker", "hillwalker", 50, 36, "Boardwalk Walker",
         ["Three kilometres of boardwalk, and not one inch of bog harmed. They've done it right. Well. They've done it as right as a boardwalk can be.",
          "The summit's a plateau, and the wind up there has a plan. I recommend a good hat."], "left", "still")
    trainer2(z, "es_angler", "Angler Declan", "Angler", "angler", [("elverlet", 65), ("cranelet", 66), ("pollanet", 66)],
             28, 13, "down", ["The pike in Erne are the size of small dogs. I'm not joking. I've a photograph, and the dog's in it for scale."],
             "Bit. That's the first bite I've had all week.", "Roach, bream, pike, and the odd tale. Mostly tales.", FL)
    trainer2(z, "es_farmer", "Farmer Bernie", "Farmer", "farmer", [("moolet", 65), ("leveret", 66), ("dozelet", 66)],
             38, 30, "up", ["I've a hundred acres by the lough. The lough's got most of them. It's a sharing arrangement."],
             "Good luck to ye. And mind my reeds.", "I'd a cow once that swam the Erne for pleasure. Never saw her again. She'd a great life.", FL)
    trainer2(z, "es_boatman", "Boatman Colm", "Boatman", "sailor", [("neagheen", 65), ("stalklet", 66), ("parrlet", 66)],
             28, 18, "right", ["There's a hundred islands out there, give or take, and I know every one of them by its mood."],
             "You've a great pair of hands on you. Come out for a spin.", "The Erne's two lakes, joined by a town. An odd way to organise a county, but it works.", FL)

    wild2(z, [("pipkin", 65, 67, 12, {}), ("rooklet", 65, 67, 12, {"time": ["dawn", "day", "dusk"]}), ("starlet", 65, 67, 12, {}),
              ("leveret", 65, 67, 12, {}), ("stoatlet", 65, 67, 10, {}), ("dozelet", 65, 67, 8, {"time": ["night", "dusk"]}),
              ("hootlet", 66, 67, 8, {"time": ["night"]}), ("flaxling", 65, 67, 8, {}), ("moolet", 65, 67, 10, {}),
              ("chipgull", 65, 67, 10, {"time": ["day"]})])
    wild2(z, [("neagheen", 65, 67, 22, {}), ("pollanet", 65, 67, 16, {}), ("parrlet", 65, 67, 14, {}), ("elverlet", 65, 67, 14, {}),
              ("cranelet", 66, 67, 10, {}), ("stalklet", 65, 67, 14, {}), ("bradan", 66, 67, 10, {})], "water")
    gate(z, "east", 26, GATE_FLAG, "Warden", ["Road's closed. Works on the Erne. Very serious works. We've a cone.",
                                                 "The Keeper at the shipyard in Belfast has the say on this road, and he hasn't said it yet. Ask Ruairí. Past the cranes, the big shed."])
    open_gap("donegal_town", "east", 20, ID)
    open_gap("enniskillen", "west", 26, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 8, 26, "cranelet", "erne_shore")
    poi_stone(ID, 58, 40, "erne_shore", "ward", ["It has a Y-shaped crack down one side and a coat of orange lichen, like a stone that has been signed.", "The real thing is a Fermanagh cross slab: the county's islands and shores are scattered with carved stones of the early monks."])
    poi_cache(ID, 58, 14, "erne_shore", "fermanagh_black_bacon", "A paper bag in the reeds, tied with a bootlace. A rasher of Fermanagh black bacon, wrapped in a cloth. Somebody's dinner and your lucky day.")
    field_spot(ID, 12, 37, "mend", "wall_gap", "A wall with a tooth missing. {lead} rebuilds it with no mortar and a great deal of dignity, and finds %s in the hollow." % item_name("champ"), "champ", "erne_shore")
    add_map_places({ID: (240, 672)})
