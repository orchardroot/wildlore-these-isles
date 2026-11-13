# Wave 55 roads-celtic, route 8: the Clare road, Limerick to the Burren by way of Bunratty and Ennis (the old N18). The
# Burren (north edge) to Limerick (south edge). Both open with the road to Galway, so there is no gate. Irish English.
from w55_lib import *

ID = "clare_road"


def build(OUT):
    W, H = 64, 46
    FL = 57
    z = route(ID, "Bunratty and Ennis", W, H, "ireland_west", "route_ireland", "grass", FL,
              {"drizzle": 30, "clear": 22, "fog": 10, "sunshine": 16, "downpour": 12, "gale": 10},
              {"north": ("burren", 36), "south": ("limerick", 45)})
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["g"] = {"tile": "grass", "colour": "#7fa04a"}
    z.rect(3, 3, 58, 40, "g")
    z.scatter(0, 0, W, H, "P", 14, 5, only="T")
    # the Fergus runs through Ennis; the road goes round it and a footbridge crosses
    river(z, 22, 3, 43, 3, amp=1.5, period=26.0, phase=0.3, bank="r")
    # the road: down from the Burren, east round Ennis, and on south to Limerick by way of Bunratty
    poly(z, [(36, 0), (36, 12), (45, 12), (45, 45)], "=", 3)
    # Ennis, west of the road: a main street over the river, the friary and a column to a famous man
    poly(z, [(36, 28), (14, 28)], ":", 3)
    bridge(z, 19, 28, 8, 3, deck=":", rail="W")
    z.building(8, 22, 7, 4, "chapel", "Ennis Friary")
    z.building(28, 22, 6, 4, "irish_shopfront", show_label=False)
    z.building(10, 31, 6, 4, "irish_shopfront", show_label=False)
    z.building(28, 31, 6, 4, "ulster_terrace", show_label=False)
    z.rect(8, 26, 28, 1, ":"); z.rect(30, 26, 1, 3, ":")
    z.prop("statue", 31, 29); z.prop("lamp_post", 14, 27); z.prop("lamp_post", 35, 27); z.prop("bench", 24, 27)
    # Bunratty Castle and the folk park, east of the road
    z.building(50, 14, 7, 5, "castle", "Bunratty Castle")
    z.building(50, 22, 5, 3, "thatch_cottage", "Folk Park Cottage")
    z.building(56, 22, 4, 3, "thatch_cottage", show_label=False)
    z.rect(47, 20, 13, 1, "#"); z.rect(47, 13, 1, 8, "#")
    z.rect(49, 19, 1, 1, "#")
    # Quin Abbey, a ruined friary inside an old castle, to the south west
    z.building(10, 38, 6, 3, "chapel", "Quin Abbey")
    z.rect(16, 39, 29, 1, "#"); z.rect(10, 41, 1, 1, ".")
    # fields and hedges
    for (x, y, w, h) in [(4, 4, 18, 14), (24, 14, 10, 6), (49, 28, 11, 12), (4, 14, 14, 6), (18, 34, 10, 4), (49, 4, 8, 7)]:
        z.rect(x, y, w, h, ",")
        scatter_props(z, "bush", x, y, w, h, 3, x * 3 + y, avoid=(",",))
    z.rect(4, 20, 14, 1, "H"); z.rect(10, 20, 2, 1, ".")
    scatter_props(z, "oak", 3, 3, 58, 40, 18, 61, avoid=("g",))
    scatter_props(z, "sheep", 49, 28, 11, 12, 3, 62, avoid=(",",))
    scatter_props(z, "rock", 3, 3, 58, 40, 8, 63, avoid=("g",))
    z.d["spawn"] = [36, 8]
    finish_borders(z, "=")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bwr":
            z.d["props"].remove(p_)

    sign(z, 33, 3, "NORTH: the Burren, Kilfenora and the cliffs. The grey country: stone to the horizon, and a flower growing in every crack.")
    sign(z, 48, 43, "SOUTH: Limerick and the Shannon. Shannon Airport is the other way, out the road. The Atlantic is thirty minutes beyond and a little cross.")
    sign(z, 26, 26, "ENNIS. The name comes from the Irish 'Inis', which can mean an island or a river meadow, and the Fergus has made both here. It has opinions about that.")
    sign(z, 52, 12, "BUNRATTY. A castle of the 1400s on the Shannon side of the road, with a folk park of thatched cottages beside it. Beware the medieval banquet. It has mead.")
    plaque(z, 56, 15, "clare_bunratty", "Bunratty Castle",
           "Bunratty is a tall tower house, built around 1425 by the MacNamara family and held later by the O'Briens, Earls of Thomond. It was left to decay and was bought in 1954 by Lord Gort, who restored it with furniture and tapestries from the same centuries. The folk park beside it re-creates a village of thatched cottages, and a banquet of mead and meat is served in the great hall in the evenings.")
    plaque(z, 32, 29, "clare_oconnell", "O'Connell's Election, 1828",
           "In 1828 Daniel O'Connell, a Catholic, stood for the House of Commons in a by-election in County Clare. By law he could not take his seat if he won, and he won handsomely, in a vote held in Ennis. Parliament was frightened of what might happen next, and in 1829 it passed Catholic Emancipation. Clare is known as the Banner County, and it has never let anyone forget it.")
    plaque(z, 14, 40, "clare_quin", "Quin Abbey",
           "Quin Abbey is a Franciscan friary built in the 1430s inside the walls of a Norman castle, so that its cloister sits between the old towers. It is a very handsome ruin and a good place to eat a sandwich in the rain. The friars kept a strict rule and a patient eye on the weather.")
    plaque(z, 47, 40, "clare_shannon", "The First Duty Free",
           "Shannon Airport, a few miles from this road, became in 1947 the first duty-free airport in the world. It was built for transatlantic flights, which had to refuel here, and the fuel stops became an excuse to sell passengers cigarettes and tweed. The idea was copied by airports all over the world, and nobody was ever asked for royalties.")

    chat(z, "cr_steward", "tour_guide", 53, 20, "Castle Steward",
         ["Welcome to Bunratty. Sit anywhere. Tonight's menu is mead and meat. Sláinte!",
          "The castle was falling down in the 1950s, and Lord Gort bought it and put the walls back on. He'd the money, he'd the notion, and he'd the taste, which is rare in all three."], "left", "still")
    chat(z, "cr_ennis_local", "villager_2", 24, 30, "Ennis Local",
         ["O'Connell's statue is up on the column. Fair play to him. A Catholic, a Clareman, and a lawyer. The English never saw it coming.",
          "Ennis is the music town. Every second pub has a session going, and the third has a better one."], "right", "still")
    chat(z, "cr_fiddler", "fiddler", 40, 20, "Fiddler",
         ["Kilfenora has a céilí band that's been going since 1909. Eight or ten of them, and you could hear them in the next parish.",
          "A reel is a reel and a jig is a jig. But a Clare reel has a lift in it you won't get elsewhere. I'm not biased. I'm from Clare."], "down", "still")
    trainer2(z, "cr_hurler", "Banner Hurler Cian", "Hurler", "hurler", [("rooklet", 56), ("strutcoo", 57), ("gealhare", 57)],
             40, 34, "up", ["I've a hurley in the boot and a point to prove. You'll do. Hold on while I find the ball."],
             "That was a point. A good one. The Banner County's proud of you.", "Clare hurlers are the only ones who can lose a final with grace. We practise.", FL)
    trainer2(z, "cr_musician", "Musician Aoife", "Musician", "fiddler", [("redbreast", 56), ("starlet", 57), ("versling", 57)],
             30, 20, "right", ["I'm on my way to a session in Doolin. Play the tune. Tip the fiddler. In that order."],
             "Lovely. That'll go in the next set.", "A session isn't a gig. It's a conversation with a drink in it.", FL)
    trainer2(z, "cr_farmer", "Farmer Padraig", "Farmer", "farmer", [("gentlet", 56), ("cluricaun", 57), ("corncrake", 57)],
             58, 32, "left", ["Ye can't pass through here without a word with me. It's the law. I made it just now."],
             "Well. That's me told. Mind the cow on your way out.", "The corncrake's gone from most places. I've two in the top field and I don't tell a soul.", FL)

    wild2(z, [("gentlet", 56, 58, 14, {}), ("gealhare", 56, 58, 14, {}), ("corncrake", 56, 58, 12, {"time": ["dusk", "night", "dawn"]}),
              ("horselet", 56, 58, 10, {}), ("crexling", 56, 58, 8, {}), ("versling", 57, 58, 10, {}), ("rooklet", 56, 58, 14, {"time": ["dawn", "day", "dusk"]}),
              ("strutcoo", 56, 58, 10, {}), ("redbreast", 56, 58, 8, {}), ("starlet", 56, 58, 8, {}),
              ("cluricaun", 57, 58, 6, {"time": ["dusk", "night"]})])
    wild2(z, [("heronarch", 56, 58, 16, {}), ("rillotter", 56, 58, 18, {}), ("bradan", 57, 58, 18, {}), ("spatelord", 57, 58, 12, {}),
              ("estuarch", 57, 58, 8, {})], "water")
    open_gap("burren", "south", 36, ID)
    open_gap("limerick", "north", 45, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 6, 8, "horseshoe", "clare_road")
    poi_stone(ID, 58, 6, "clare_road", "def", ["It is a flat grey slab, and when you press your hand against it the cold goes up your arm like an apology.", "The real thing is the Burren limestone: a pavement of bare rock that once lay under a tropical sea."])
    poi_cache(ID, 56, 40, "clare_road", "bunratty_mead", "A flask in a hollow of the wall. The cork says 'Bunratty' and the smell says 'dangerous'. You decide to carry it carefully.")
    field_spot(ID, 12, 17, "charm", "molehill", "Soft ground, a patient creature, and a lot of worms. {lead} brings up the lot, and under them: %s." % item_name("four_leaf_clover"), "four_leaf_clover", "clare_road")
    add_map_places({ID: (166, 890)})
