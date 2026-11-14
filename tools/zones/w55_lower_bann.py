# Wave 55 roads-celtic, route 10: the Lower Bann. Bushmills (south edge, so the route's north edge) to Lough Neagh (north
# edge, so the route's south edge): the Bann Way along the river from Toome to the Dark Hedges and Coleraine. Lough
# Neagh opens at ch7_judged but Bushmills only once the Antrim coast does, so the road is shut at the Lough Neagh end
# until badge_iron, the flag on the Belfast gate.
from w55_lib import *

ID = "lower_bann"
GATE_FLAG = "badge_iron"


def build(OUT):
    W, H = 64, 50
    FL = 65
    z = route(ID, "The Lower Bann", W, H, "ireland", "route_ireland", "valley", FL,
              {"drizzle": 32, "clear": 20, "fog": 12, "sunshine": 14, "downpour": 14, "gale": 8},
              {"north": ("bushmills", 22), "south": ("lough_neagh", 10)})
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["g"] = {"tile": "grass", "colour": "#7fa04a"}
    z.rect(3, 3, 58, 44, "g")
    z.scatter(0, 0, W, H, "P", 14, 5, only="T")
    # the Bann, north to south, wide and slow
    river(z, 34, 3, 47, 4, amp=2.0, period=30.0, phase=0.4, bank="r")
    # the Bann Way: down the west bank from Bushmills, with a bridge to the east bank and the Dark Hedges
    poly(z, [(22, 0), (22, 40), (10, 40), (10, 49)], "#", 3)
    poly(z, [(22, 20), (50, 20)], "#", 3)
    bridge(z, 30, 20, 10, 3, deck="=", rail="W")
    # the Dark Hedges: an avenue of old beeches that meet over the road
    poly(z, [(50, 20), (50, 4)], "#", 3)
    for y in range(4, 34):
        if 18 <= y <= 22:
            continue
        z.rect(47, y, 1, 1, "T"); z.rect(53, y, 1, 1, "T")
    z.rect(50, 20, 3, 14, "#")
    # Toome and its eel fishery at the south end, and a lock-keeper's house on the middle bank
    z.building(13, 34, 5, 3, "harbour_white", "Eel Fishery")
    z.building(27, 28, 4, 3, "slate_cottage", show_label=False)
    z.prop("lamp_post", 20, 36); z.prop("bench", 20, 30); z.prop("bollard", 30, 38)
    # fields, bog and tall grass
    for (x, y, w, h) in [(4, 4, 14, 10), (4, 22, 14, 10), (24, 4, 8, 12), (40, 26, 10, 10), (40, 6, 6, 10), (24, 42, 8, 4), (54, 22, 5, 12)]:
        z.rect(x, y, w, h, ",")
        scatter_props(z, "bush", x, y, w, h, 3, x * 3 + y, avoid=(",",))
    z.rect(42, 40, 16, 6, "*")
    scatter_props(z, "oak", 3, 3, 58, 44, 16, 81, avoid=("g",))
    scatter_props(z, "sheep", 4, 4, 14, 10, 3, 82, avoid=(",",))
    scatter_props(z, "rock", 3, 3, 58, 44, 6, 83, avoid=("g",))
    z.d["spawn"] = [22, 8]
    finish_borders(z, "#")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bwr*":
            z.d["props"].remove(p_)

    sign(z, 19, 3, "NORTH: Bushmills, the Causeway and the north coast. The river goes that way too, if it can be said to be in a hurry.")
    sign(z, 7, 44, "SOUTH: Lough Neagh and Toome. The biggest lake in these islands is in the way, and you'll have to go round it.")
    sign(z, 46, 4, "THE DARK HEDGES. An avenue of beech trees planted in the 1770s, to impress visitors coming up to the big house. Two hundred and some years on, they still do, and the photographers know it.")
    sign(z, 14, 38, "THE LOWER BANN. The river leaves Lough Neagh at Toome and makes its way to the sea at Coleraine, about thirty-six miles of slow brown water. The Bann Way follows the bank, mostly.")
    plaque(z, 45, 24, "lower_bann_dark_hedges", "The Dark Hedges",
           "The Dark Hedges are an avenue of beech trees on the Bregagh Road near Armoy, planted in the 1700s by the Stuart family as an approach to their house. Around ninety trees remain, their branches knitted overhead so that in some lights the road becomes a tunnel. They have been in films and television programmes, and some of the trees have been lost to storms over the years.")
    plaque(z, 38, 13, "lower_bann_mount_sandel", "Mount Sandel",
           "A short way up the Bann above Coleraine is Mount Sandel, where hunters and fishers made camp around 7000 BC. It is among the oldest known sites of human settlement in Ireland. They lived in huts of bent saplings and ate salmon, eels, hazelnuts and pig, which, when you think about it, is a perfectly good menu.")
    plaque(z, 16, 37, "lower_bann_neagh", "Lough Neagh and the Giant",
           "Lough Neagh is the largest lake in the British Isles, about 150 square miles of it. The legend says that the giant Finn McCool, in a quarrel with a Scottish rival, tore up a lump of ground and threw it across the sea. It missed, and fell into the Irish Sea, and became the Isle of Man. The hole it left filled with water, and the lake has been very proud of the arrangement ever since.")

    chat(z, "lb_eelman", "angler", 16, 38, "Eel Fisherman",
         ["The eels come out of the sea as glass-clear things the size of your finger, and they spend their whole lives in the lough. Then they go back to the Sargasso to breed. Fifteen years in Neagh, and off for the big finale.",
          "We fish for them here at Toome. It's a co-op. Nobody's got rich, but nobody's gone hungry either."], "right", "still")
    chat(z, "lb_hedges", "tour_guide", 49, 26, "Hedge Guide",
         ["Ye'll want the photograph at dawn, before the buses. Stand in the middle of the road, so ye will. Ye'll not be knocked down. They're all taking the same photo.",
          "Some of the old trees have come down in the storms. The ones that are left are the survivors. A bit like the rest of us."], "left", "still")
    chat(z, "lb_walker", "hillwalker", 24, 33, "Bann Way Walker",
         ["I'm walking it end to end. Slow river, flat path, and a flask. The Bann doesn't do drama. It does a very fine line in being there.",
          "Eleven miles a day, and a pint at the end of each. That's the rule."], "right", "still")
    trainer2(z, "lb_eelfisher", "Eel Fisher Brendan", "Eel Fisher", "angler", [("neagheen", 65), ("pollanet", 66), ("rillotter", 66)],
             30, 34, "right", ["Ye've the look of a person who's never held an eel. Here, mind this one. No? Fight so."],
             "Slippery. And clever. Fair play.", "An eel will get out of anything. The ones I've kept have all been very good escapists.", FL)
    trainer2(z, "lb_farmer", "Farmer Seamus", "Farmer", "farmer", [("leveret", 65), ("flaxling", 66), ("crexling", 66)],
             42, 30, "left", ["Ye can see the Bann from the top field. It's the finest river in Ulster, and I'll say so to anyone who'll stand still."],
             "Ye've a fair hand. Mind my sheep on the way out.", "A man doesn't own a river. He just gets to look at it every morning.", FL)
    trainer2(z, "lb_photographer", "Photographer Orla", "Photographer", "tour_guide", [("hootlet", 65), ("stagmor", 66), ("hushwing", 66)],
             52, 12, "down", ["Don't walk in the shot. Don't walk near the shot. Actually, don't walk."],
             "Right. Well. You were in the shot. I'll call it art.", "It's all about the light. And patience. And bribing the sun with a flask of tea.", FL)

    wild2(z, [("flaxling", 65, 67, 14, {}), ("stalklet", 65, 67, 10, {}), ("midgie", 65, 67, 12, {"time": ["dusk", "dawn"]}),
              ("volet", 65, 67, 10, {}), ("croakle", 65, 67, 10, {"weather": ["drizzle", "downpour"]}), ("leveret", 65, 67, 12, {}),
              ("crexling", 65, 67, 8, {}), ("hootlet", 66, 67, 8, {"time": ["night"]}), ("redbreast", 65, 67, 8, {}),
              ("pipkin", 65, 67, 8, {}), ("stagmor", 66, 67, 6, {"time": ["dawn", "dusk"]})])
    wild2(z, [("neagheen", 65, 67, 24, {}), ("pollanet", 65, 67, 18, {}), ("rillotter", 65, 67, 16, {}), ("bradan", 66, 67, 16, {}),
              ("parrlet", 65, 67, 14, {}), ("heronarch", 66, 67, 10, {})], "water")
    gate(z, "south", 10, GATE_FLAG, "Warden", ["Road's closed. Works on the Bann. Very serious works. We've a cone.",
                                                    "The Keeper at the shipyard in Belfast has the say on this road, and he hasn't said it yet. Ask Ruairí. Past the cranes, the big shed."])
    open_gap("bushmills", "south", 22, ID)
    open_gap("lough_neagh", "north", 10, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 8, 8, "bittling", "lower_bann")
    poi_stone(ID, 56, 30, "lower_bann", "def", ["It has a groove worn into it, as if a long line of something had been pulled across it for centuries.", "The real thing is a Mesolithic find from the Bann valley: flint tools of the first hunters in Ireland, long before the first farms."])
    poi_cache(ID, 16, 26, "lower_bann", "fermanagh_black_bacon", "A greasy brown-paper packet under a stone. Inside, a rasher of something very good. You feel guilty, and then you don't.")
    field_spot(ID, 8, 27, "mend", "wall_gap", "A wall with a tooth missing. {lead} rebuilds it with no mortar and a great deal of dignity, and finds %s in the hollow." % item_name("armagh_bramley"), "armagh_bramley", "lower_bann")
    add_map_places({ID: (360, 620)})
