# Wave 55 roads-celtic, route 7: the Golden Vale and the Rock of Cashel. Kilkenny (south edge) to Limerick (west edge):
# the road through Thurles and Cashel across the Tipperary plain. Kilkenny and Limerick open together, so no gate.
from w55_lib import *

ID = "golden_vale"


def build(OUT):
    W, H = 64, 46
    FL = 55
    z = route(ID, "The Golden Vale and Cashel", W, H, "ireland", "route_ireland", "grass", FL,
              {"drizzle": 32, "clear": 24, "fog": 8, "sunshine": 16, "downpour": 12, "gale": 8},
              {"south": ("kilkenny", 30), "west": ("limerick", 11)})
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["g"] = {"tile": "grass", "colour": "#7fa04a"}
    z.legend["f"] = {"tile": "flowers", "colour": "#e6e0a0"}
    z.rect(3, 3, 58, 40, "g")
    z.scatter(0, 0, W, H, "P", 14, 5, only="T")
    # the road from Kilkenny north through the vale, then west to Limerick
    poly(z, [(30, 45), (30, 11), (0, 11)], "=", 3)
    # the Rock of Cashel: a limestone hill with a ruined cathedral, a round tower and Cormac's Chapel
    z.rect(35, 3, 22, 11, "R")
    z.rect(38, 8, 16, 5, "g")
    z.building(39, 4, 10, 4, "cathedral", "Rock of Cashel")
    z.building(50, 5, 2, 5, "round_tower", "Round Tower")
    z.rect(38, 10, 16, 1, ":")
    z.rect(30, 9, 9, 3, "#")
    z.rect(36, 8, 3, 4, "#")
    z.prop("bench", 42, 10); z.prop("lamp_post", 38, 9); z.prop("lamp_post", 53, 9)
    # Cashel town below it, and the monument in Thurles square, off the road to the west
    z.building(36, 24, 8, 4, "irish_shopfront", "Cashel Blue Cheese Shop")
    z.building(45, 24, 6, 4, "irish_shopfront", show_label=False)
    z.building(52, 24, 5, 4, "ulster_terrace", show_label=False)
    z.rect(34, 29, 24, 1, ":"); z.rect(31, 28, 3, 1, "#")
    z.rect(20, 28, 11, 3, ":")
    z.prop("statue", 24, 30)
    z.prop("lamp_post", 34, 29); z.prop("lamp_post", 56, 29); z.prop("bench", 44, 30)
    # hedges and fields: the Golden Vale is a patchwork
    for (x, y, w, h) in [(4, 14, 24, 1), (4, 24, 14, 1), (4, 36, 24, 1), (36, 34, 22, 1)]:
        z.rect(x, y, w, h, "H")
    z.rect(10, 14, 2, 1, "."); z.rect(20, 14, 2, 1, "."); z.rect(8, 24, 2, 1, "."); z.rect(14, 36, 2, 1, "."); z.rect(44, 34, 2, 1, ".")
    for (x, y, w, h) in [(4, 15, 24, 9), (4, 25, 14, 11), (4, 37, 24, 6), (36, 35, 22, 8), (34, 14, 16, 8), (4, 4, 24, 6)]:
        z.rect(x, y, w, h, ",")
    for (x, y, w, h) in [(4, 15, 24, 9), (36, 35, 22, 8)]:
        scatter_props(z, "sheep", x, y, w, h, 3, x + y, avoid=(",",))
    scatter_props(z, "oak", 3, 3, 58, 40, 22, 51, avoid=("g",))
    scatter_props(z, "bush", 3, 3, 58, 40, 14, 52, avoid=("g",))
    scatter_props(z, "rock", 3, 3, 58, 40, 6, 53, avoid=("g",))
    z.d["spawn"] = [30, 30]
    finish_borders(z, "=")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bw^":
            z.d["props"].remove(p_)

    sign(z, 27, 43, "SOUTH: Kilkenny and the Nore. The road north is a good one. The Tipperary sheep like it too.")
    sign(z, 5, 9, "WEST: Limerick and the Shannon. The vale gives out at the river, and Limerick gets going.")
    sign(z, 33, 7, "CAISEAL. The name means a stone fort. The rock above the town was the seat of the kings of Munster long before it was a church, and the hill has never lost its air of knowing who is in charge.")
    sign(z, 28, 33, "THE GOLDEN VALE. A broad belt of rich pasture across Tipperary and Limerick, and the reason the cheese, the butter and the cattle of the region are what they are. It rains here on purpose.")
    plaque(z, 45, 11, "golden_vale_cashel", "The Rock of Cashel",
           "Cashel was the seat of the kings of Munster before it became a church site. Brian Boru was crowned king of Munster here in the 970s. The buildings on the rock include Cormac's Chapel, a Romanesque chapel consecrated in 1134, a round tower and a ruined cathedral. Legend says that St Patrick came here and baptised King Aengus, driving the point of his crozier through the king's foot. The king, thinking it part of the ritual, said nothing.")
    plaque(z, 25, 30, "golden_vale_gaa", "The Birth of the GAA",
           "On 1 November 1884 a small group of men met in Hayes's Hotel in Thurles and founded the Gaelic Athletic Association, to bring hurling, Gaelic football and other Irish games back under Irish organisation. Hurling, the old game of ash sticks and a small leather ball, is among the fastest field games in the world, and was played in Ireland long before anyone wrote the rules down.")
    plaque(z, 57, 26, "golden_vale_cheese", "Cashel Blue",
           "Cashel Blue is a blue cheese first made on a farm near Cashel in the 1980s by Louis and Jane Grubb. It was one of the first Irish farmhouse blue cheeses, and it showed that the grass of the Golden Vale makes milk that can be turned into something more serious than butter, if you give it a long enough wait.")

    chat(z, "gv_guide", "tour_guide", 43, 11, "Rock Guide",
         ["The tower is nearly thirty metres, and they say it is older than the rest of the buildings. It is the tallest thing for miles, and the best seat in the vale.",
          "Cormac's Chapel is the finest of the lot. Come out of the rain and let your eyes get used to the stone."], "down", "still")
    chat(z, "gv_cheese", "jam_maker", 40, 29, "Cheesemaker",
         ["Taste that. It's blue, but it's gentle. It's made from the milk of cows who've never had a bad thought.",
          "My own grandmother would've said the Grubbs were soft in the head. And she'd've eaten the cheese. Every time."], "up", "still")
    chat(z, "gv_gaa_fan", "hurler", 24, 32, "Hurling Fan",
         ["Thurles is the heartland of the game. Every second child here has a hurley before they have a front tooth.",
          "The sliotar is the ball. The hurley, we call a camán, is the stick. And you hold it like it owes you money."], "left", "still")
    trainer2(z, "gv_hurler", "Hurler Seán", "Hurler", "hurler", [("rooklet", 54), ("strutcoo", 55), ("leveret", 55)],
             28, 18, "right", ["Ye wouldn't have a sliotar on you? No? Then we'll have to settle this the old way."],
             "Well hit. A fine clean strike. I'll tell the lads.", "A good touch is worth ten hard ones. My coach says that, and he's never had a bad day.", FL)
    trainer2(z, "gv_dairy", "Dairy Farmer Bríd", "Farmer", "farmer", [("moolet", 54), ("barnling", 55), ("gealhare", 55)],
             12, 20, "down", ["I've a hundred and forty cows and a husband who thinks he's in charge. One of those is accurate."],
             "God, you've a right arm on you. Come in for a cup of tea.", "Milk at five. Milk at five again. A life in the Golden Vale is very regular.", FL)
    trainer2(z, "gv_pilgrim", "Pilgrim Declan", "Pilgrim", "pilgrim", [("cluricaun", 55), ("hushwing", 54), ("redbreast", 55)],
             48, 32, "left", ["I walked up to the Rock the old way, in my boots, thinking about God. I've got as far as my boots."],
             "A humble loss. Very good for the soul.", "The road's the thing. The Rock is just where it happens to stop.", FL)

    wild2(z, [("leveret", 54, 56, 14, {}), ("moolet", 54, 56, 18, {}), ("rooklet", 54, 56, 14, {"time": ["dawn", "day", "dusk"]}),
              ("rookery", 55, 56, 8, {"time": ["day"]}), ("strutcoo", 54, 56, 12, {}), ("barnling", 54, 56, 10, {"time": ["dusk", "night"]}),
              ("gealhare", 54, 56, 10, {}), ("hushwing", 55, 56, 8, {"time": ["night"]}), ("redbreast", 54, 56, 8, {}),
              ("cluricaun", 55, 56, 6, {"time": ["dusk", "night"]})])
    wild2(z, [("stalklet", 54, 56, 24, {}), ("bradan", 55, 56, 20, {}), ("rillotter", 54, 56, 20, {}), ("pierlord", 55, 56, 14, {})], "water")
    open_gap("kilkenny", "north", 30, ID)
    open_gap("limerick", "east", 11, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 10, 28, "dextera", "golden_vale")
    poi_stone(ID, 54, 40, "golden_vale", "ward", ["It is a long grey stone in a field, with a ring of cow-parsley round its foot.", "The real thing is the standing stones of Tipperary and Limerick, which turn up in fields as if nobody had told the farmers."])
    poi_cache(ID, 55, 18, "golden_vale", "barmbrack", "A biscuit tin in the ditch with a slice of barmbrack in greaseproof paper. Whoever left it knew the road.")
    field_spot(ID, 12, 25, "mend", "wall_gap", "A wall with a tooth missing. {lead} rebuilds it with no mortar and a great deal of dignity, and finds %s in the hollow." % item_name("boxty"), "boxty", "golden_vale")
    add_map_places({ID: (232, 920)})
