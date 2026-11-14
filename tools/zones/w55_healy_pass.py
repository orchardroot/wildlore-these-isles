# Wave 55 roads-celtic, route 6: the Beara Peninsula and the Healy Pass. Cork (south edge) to the Ring of Kerry (west
# edge): the R574 over the Caha Mountains between Adrigole in Cork and Lauragh in Kerry, with the Beara Way beside it.
# Cork and the Ring of Kerry open together, so there is no gate. Irish English throughout.
from w55_lib import *

ID = "healy_pass"


def build(OUT):
    W, H = 64, 52
    FL = 54
    z = route(ID, "Beara and the Healy Pass", W, H, "ireland", "route_ireland", "mountain", FL,
              {"drizzle": 34, "clear": 14, "fog": 16, "sunshine": 8, "downpour": 18, "gale": 10},
              {"north": ("cork", 31), "east": ("ring_of_kerry", 24)}, base="m")
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["m"] = {"tile": "grass", "colour": "#7f8a55"}
    z.legend["h"] = {"tile": "tall_grass", "colour": "#7a5c6a", "prop": "heather"}
    z.scatter(0, 0, W, H, "P", 30, 5, only="T")
    # Hungry Hill and the Caha Mountains: rock and heather
    z.rect(4, 3, 20, 7, "h")
    z.rect(6, 4, 8, 4, "R")
    z.scatter(4, 3, 20, 7, "R", 14, 31, only="h")
    z.rect(38, 28, 22, 8, "h")
    # a lough in the high ground
    blob(z, 50, 9, 6, 3, "~", seed=11)
    blob(z, 50, 9, 8, 4, "r", only="m", seed=12)
    # the Atlantic: sand, a shallow fringe and open sea along the south
    z.rect(0, 44, W, 8, "$")
    z.rect(3, 42, W - 6, 2, "w")
    z.rect(3, 40, W - 6, 2, "s")
    # the Healy Pass: hairpin after hairpin, up out of Cork and over to Kerry
    poly(z, [(31, 0), (31, 9), (12, 9), (12, 17), (48, 17), (48, 24), (63, 24)], "=", 3)
    # the Beara Way drops off the road to the old copper country and the cable car on the coast
    poly(z, [(12, 17), (12, 36)], "#", 2)
    poly(z, [(12, 28), (30, 28)], "#", 2)
    # buildings: the Allihies engine house, the cable car station, a farm
    z.building(20, 20, 5, 4, "stone", "Allihies Engine House")
    z.building(14, 33, 6, 3, "white_render", "Dursey Cable Car")
    z.building(36, 21, 6, 4, "croft_house", show_label=False)
    z.prop("lamp_post", 11, 36); z.prop("bench", 15, 31)
    # tall grass for the wild things
    for (x, y, w, h) in [(4, 18, 6, 12), (16, 21, 3, 8), (26, 20, 8, 7), (34, 29, 4, 6), (40, 4, 8, 5), (54, 17, 6, 12), (16, 3, 12, 5), (22, 29, 12, 6)]:
        z.rect(x, y, w, h, ",")
        scatter_props(z, "bush", x, y, w, h, 3, x * 3 + y, avoid=(",",))
    z.rect(32, 21, 3, 3, "m")
    # a drystone wall with a gap in it
    z.rect(36, 27, 14, 1, "W"); z.rect(42, 27, 1, 1, ".")
    scatter_props(z, "rock", 3, 3, 58, 36, 22, 41, avoid=("m", "h"))
    scatter_props(z, "sheep", 20, 10, 24, 6, 6, 42, avoid=("m",))
    z.d["spawn"] = [31, 6]
    finish_borders(z, "=")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bw^":
            z.d["props"].remove(p_)

    sign(z, 28, 3, "NORTH: Cork and the road to Bantry. The road to the peninsula starts as a decent road and gets more honest as it goes.")
    sign(z, 59, 21, "EAST: Kenmare and the Ring of Kerry. The Healy Pass goes over the top and comes down in Kerry, with its dignity mostly intact.")
    sign(z, 14, 8, "THE HEALY PASS. A road that goes up a mountain the long way round, in hairpins. Gears, brakes and prayers are all recommended. It was built to give men work, and it gives everyone else a view.")
    sign(z, 14, 38, "THE BEARA WAY. A walking route of about 200 kilometres round the peninsula, in Cork and in Kerry. You can do it in a fortnight. You can also do it in sections, with a pint at the end of each.")
    plaque(z, 22, 19, "healy_pass_allihies", "The Allihies Copper Mines",
           "Copper was mined at Allihies from 1812 until the 1880s. The mines belonged to the Puxley family of Dunboy Castle, and many of the miners were brought over from Cornwall, which is why the engine houses on the hill look like the ones in Cornwall. The Cornish went home or went to America when the copper ran out, and the Irish went to America and Cornwall and everywhere else. A place that looks this empty was once very busy.")
    plaque(z, 14, 35, "healy_pass_dursey", "The Dursey Cable Car",
           "A cable car carries a handful of people at a time across Dursey Sound to Dursey Island, a trip of a few minutes over a strait with a strong current. It is the only cable car in Ireland that crosses the sea. It has carried sheep and cattle as well as walkers, in the days when the island's farms were still working.")
    plaque(z, 33, 8, "healy_pass_bantry", "The French at Bantry Bay",
           "In December 1796 a French fleet sailed into Bantry Bay carrying an army of about fourteen thousand men, with Wolfe Tone among them, to help the United Irishmen. Storms scattered the ships and prevented a landing. Nobody who has stood in Bantry Bay in December will wonder why. The fleet turned for home, and a great deal of Irish history turned on the weather.")

    chat(z, "hp_driver", "farmer", 29, 12, "Man at the Lay-by",
         ["The Healy Pass has more hairpins than a hairdresser's. I come up here every Sunday to watch the cars, and the cars to watch the sheep.",
          "God, it's soft out. That's what we say in this country when it's raining so gently you could mistake it for a mood."], "right", "still")
    chat(z, "hp_miner_guide", "tour_guide", 24, 25, "Heritage Guide",
         ["Those engine houses are Cornish. Cornish miners came over with the steam engines. A fair few stayed and married, and now half of Allihies is a Trevithick.",
          "Daphne du Maurier wrote a novel about it called Hungry Hill, about a family with a mine and a great many feuds. It is not a quiet book."], "up", "still")
    chat(z, "hp_cable", "villager_4", 17, 36, "Cable Car Attendant",
         ["A handful at a time, and no more. The wind has a say, and when the wind says no, we wait. Sure what's the hurry? It's an island.",
          "Dursey is a grand place for a walk. Nobody lives there now. The cows, the sheep and the birds do the housekeeping."], "down", "still")
    trainer2(z, "hp_farmer", "Farmer Mick", "Farmer", "farmer", [("loaghtan", 53), ("billgruff", 54), ("brockmoor", 54)],
             40, 26, "down", ["Is that my wall you're standing next to? It is. I will let you off. If you win."],
             "Fair play to ye. A good battle is worth a gap in the wall.", "I mind this hill for the sheep. The sheep mind it for themselves.", FL)
    trainer2(z, "hp_walker", "Beara Way Walker Nuala", "Walker", "hiker", [("pooka", 53), ("gealhare", 54), ("snowhare", 54)],
             8, 24, "right", ["I'm walking the Beara Way, the whole circuit. I'm on day nine. My feet and I are no longer speaking."],
             "Grand. That was a rest. A good one. Thank you.", "Keep the sea on your left and a sandwich in your pocket. That's the whole route.", FL)
    trainer2(z, "hp_cornish", "Heritage Volunteer Jago", "Volunteer", "explorer", [("tormane", 53), ("sikawhistle", 54), ("hushwing", 54)],
             27, 23, "left", ["I'm from Cornwall, originally. My great-great-grandad dug here. I came to see his name on a list and stayed for the tea."],
             "That's the thing about a good fight. It reminds you of your ancestors, and then you apologise to them.", "Copper and tin, same men, same engines. Different weather.", FL)

    wild2(z, [("pooka", 53, 55, 16, {"time": ["dusk", "night"]}), ("gealhare", 53, 55, 16, {}),
              ("snowhare", 54, 55, 12, {"weather": ["frost", "fog"]}), ("loaghtan", 53, 55, 18, {}),
              ("billgruff", 54, 55, 12, {}), ("brockmoor", 53, 55, 12, {"time": ["dawn", "dusk"]}),
              ("tormane", 53, 55, 10, {}), ("sikawhistle", 53, 55, 10, {}), ("hushwing", 54, 55, 8, {"time": ["night"]}),
              ("natterjack", 53, 55, 8, {"weather": ["drizzle", "downpour"]}), ("kerryspot", 54, 55, 8, {})])
    wild2(z, [("kerryspot", 53, 55, 22, {}), ("bradan", 53, 55, 22, {}), ("rillotter", 54, 55, 18, {}), ("heronarch", 54, 55, 14, {}),
              ("parrlet", 53, 55, 14, {})], "water")
    open_gap("cork", "south", 31, ID)
    open_gap("ring_of_kerry", "west", 24, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 8, 20, "corncrake", "healy_pass")
    poi_stone(ID, 58, 32, "healy_pass", "ward", ["It is a standing stone, green with lichen, leaning like it has been told a long story.", "The real thing is the standing stones of Beara and west Cork: the peninsula has dozens, many of them older than the roads."])
    poi_cache(ID, 6, 14, "healy_pass", "bunratty_mead", "A hip flask jammed behind a boulder. The label says 'for emergencies'. You have decided this counts.")
    field_spot(ID, 43, 28, "mend", "wall_gap", "A wall with a tooth missing. {lead} rebuilds it with no mortar and a great deal of dignity, and finds %s in the hollow." % item_name("barmbrack"), "barmbrack", "healy_pass")
    add_map_places({ID: (128, 1040)})
