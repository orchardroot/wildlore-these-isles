# Wave 55 roads-celtic, route 1: Beddgelert and the Aberglaslyn Pass. Yr Wyddfa (west edge) to the Cambrian Coast (east
# edge), the old Welsh Highland trackbed and the A498 through the gorge. Gated at the Yr Wyddfa end with the flag that
# opens the Cambrian Coast: ch3_ddraig_woke.
from w55_lib import *

ID = "aberglaslyn"
GATE_FLAG = "ch3_ddraig_woke"


def build(OUT):
    W, H = 64, 44
    FL = 31
    z = route(ID, "Beddgelert and Aberglaslyn", W, H, "north_wales", "route_mountain", "mountain", FL,
              {"fog": 22, "drizzle": 26, "clear": 18, "sunshine": 12, "downpour": 14, "gale": 8},
              {"west": ("cambrian_coast", 12), "east": ("yr_wyddfa", 31)})
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["m"] = {"tile": "grass", "colour": "#7f8a55"}
    z.scatter(0, 0, W, H, "P", 40, 3, only="T")
    # the gorge: rock walls either side of the river, the road and the old railway squeezed between them
    z.rect(14, 3, 14, 38, "R")
    z.rect(16, 3, 10, 38, "m")
    # the Glaslyn runs north to south through the gorge and opens out into a pool south of the village
    river(z, 22, 3, 38, 4, amp=2.0, period=22.0, bank="r")
    blob(z, 22, 38, 6, 3, "~", seed=2); blob(z, 22, 38, 8, 4, "r", only="m", seed=3)
    # village side: meadows and the village green at the foot of the hills
    z.rect(28, 3, 33, 38, ".")
    # the walkers' path from the west gap runs down the west bank to Pont Aberglaslyn
    trail(z, [(3, 11), (12, 11), (12, 17)], "#", 3, seed=1)
    z.rect(12, 11, 3, 8, "#")
    z.rect(12, 17, 8, 2, "#")
    z.rect(16, 19, 3, 20, "#")
    # Pont Aberglaslyn: a stone bridge over the water
    bridge(z, 17, 16, 12, 3)
    # the village road from the bridge to the east gap
    trail(z, [(26, 17), (40, 17), (40, 30), (61, 30)], "=", 3, seed=5)
    z.rect(40, 17, 3, 14, "=")
    z.rect(26, 16, 15, 3, "=")
    z.rect(40, 30, 22, 3, "=")
    # the village
    z.building(44, 6, 8, 5, "stone", "Royal Goat Hotel")
    z.building(53, 6, 6, 4, "slate_cottage", show_label=False)
    z.building(44, 12, 6, 4, "white_render", "Welsh Highland Station")
    z.building(53, 12, 5, 4, "slate_cottage", show_label=False)
    z.rect(43, 11, 17, 1, ":"); z.rect(43, 16, 1, 1, ":")
    z.rect(47, 16, 1, 1, ":"); z.rect(44, 16, 8, 1, ":")
    z.prop("lamp_post", 43, 11); z.prop("lamp_post", 52, 11); z.prop("bench", 46, 17); z.prop("post_box", 53, 11)
    # Gelert's Grave: a meadow by the river
    z.rect(30, 22, 8, 7, "f")
    z.prop("standing_stone", 33, 25, variant=1)
    z.prop("bench", 31, 27); z.prop("bench", 36, 27)
    z.rect(34, 17, 1, 5, "#"); z.rect(29, 21, 9, 1, "#")
    # tall grass for the wild things, by the path and in the oak woods
    for (x, y, w, h) in [(4, 14, 7, 5), (4, 22, 8, 6), (4, 32, 8, 6), (29, 31, 10, 7), (45, 22, 12, 6), (46, 35, 12, 4), (30, 5, 12, 8), (14, 20, 1, 1)]:
        z.rect(x, y, w, h, ",")
    for (x, y, w, h) in [(4, 14, 7, 5), (4, 22, 8, 6), (29, 31, 10, 7), (45, 22, 12, 6)]:
        scatter_props(z, "bush", x, y, w, h, 3, x * 7 + y, avoid=(",",))
    z.rect(4, 19, 8, 2, ".")
    # a drystone wall with a gap in it, for the field spot
    z.rect(45, 28, 12, 1, "W"); z.rect(50, 28, 1, 1, ".")
    scatter_props(z, "oak", 28, 3, 33, 38, 22, 7, avoid=(".",))
    scatter_props(z, "birch", 3, 3, 12, 38, 12, 8, avoid=(".",))
    scatter_props(z, "rock", 3, 3, 58, 38, 16, 9, avoid=(".", "m"))
    scatter_props(z, "sheep", 45, 22, 12, 6, 4, 10, avoid=(".",))
    z.d["spawn"] = [20, 17]
    finish_borders(z)
    # clear anything the scatter put on the paths and gaps
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~" :
            z.d["props"].remove(p_)

    # signs and plaques
    sign(z, 6, 9, "WEST: the Cambrian Coast, Porthmadog and Harlech. Gorllewin. The road goes through a gorge first, and the gorge is the better bit.")
    sign(z, 59, 33, "EAST: Yr Wyddfa and the Nantgwynant valley. Dwyrain. The mountain is bigger than it looks on the map, and it looks big on the map.")
    sign(z, 26, 14, "PONT ABERGLASLYN. A stone bridge over the Glaslyn where the river drops through a narrow gorge. The road and the old railway squeezed in beside the water, and neither of them has been able to widen it since.")
    sign(z, 46, 18, "BEDDGELERT. Bedd is a grave. Of whom, you can read at the meadow. (Hint: of one dog, and the story that came with him.)")
    plaque(z, 32, 24, "aberglaslyn_gelert", "Gelert's Grave",
           "The tale says Prince Llywelyn came home to find his hound Gelert bloody and the baby's cradle overturned, killed the dog in a rage, and then found the child alive beside a dead wolf. Versions of the story turn up across Europe. The grave in the meadow was set up at the end of the 1700s, and the village has done well out of it ever since.")
    plaque(z, 35, 24, "aberglaslyn_ospreys", "The Glaslyn Ospreys",
           "In 2004 a pair of ospreys nested near Pont Croesor, the first in Wales for about four hundred years. They have raised chicks on the Glaslyn almost every summer since, and volunteers with telescopes will show you the nest if you ask nicely.")
    plaque(z, 42, 14, "aberglaslyn_whr", "The Welsh Highland Railway",
           "A narrow gauge railway ran through the Aberglaslyn Pass until it closed in the 1930s, and for decades the trackbed was a footpath and a ruin. Volunteers rebuilt it. Steam trains now run again from Caernarfon to Porthmadog through the gorge, and the path beside the river is still one of the best short walks in Wales.")
    sign(z, 48, 29, "A WALL WITH A TOOTH MISSING. The farmer says it was the wind. The wind says it was the sheep.")

    # people
    chat(z, "ag_guide", "tour_guide", 31, 23, "Meadow Guide",
         ["That is Gelert's Grave. Don't tell the dog this, but the story is a lot older than the stone.",
          "An innkeeper is supposed to have set the stone up to bring in visitors. Two hundred years on, it still works. Good marketing never goes out of style."], "right", "still")
    chat(z, "ag_volunteer", "rail_guard", 45, 17, "Railway Volunteer",
         ["I give up my Saturdays to this railway. It is the best bad decision I ever made.",
          "The line goes through the gorge and over the bridge, and the engine does the bit nobody can do on foot: it goes up without complaining."], "down", "still")
    chat(z, "ag_cafe", "villager_3", 51, 17, "Cafe Owner",
         ["Bore da. Tea? Everyone says it is the water. I think it is the fact that I don't let anybody leave until they have had a cup.",
          "The bara brith is my nain's recipe. I'm not allowed to say how much butter."], "down", "wander")
    chat(z, "ag_gorge_walker", "hiker", 18, 32, "Gorge Walker",
         ["Keep to the path by the river. The rock is slippery when it is dry and unbelievable when it is wet.",
          "The Aberglaslyn is the bit of Eryri people drive through and then say they will come back to. They do."], "right", "still")
    trainer2(z, "ag_osprey", "Osprey Watcher Bethan", "Birdwatcher", "birdwatcher", [("kitelet", 31), ("cragchough", 31), ("hootlet", 32)],
             38, 33, "up", ["Shh. There is a bird on the nest and it has not noticed me. Do not make it notice me."],
             "Right. You have scared everything for a mile. Congratulations.", "Ospreys are the bird that brings a fish home like a weekly shop.", FL)
    trainer2(z, "ag_hillfarmer", "Hill Farmer Dafydd", "Farmer", "farmer", [("kidgruff", 31), ("slatelet", 31), ("tapknock", 32)],
             47, 25, "left", ["I have had sheep on this hill since before you were born. Please do not take any of them."],
             "Fair play. That was a good one. I will not tell the dog.", "A day on the hill is a day. A day in the pass is a postcard.", FL)
    trainer2(z, "ag_copper", "Copper Guide Meurig", "Guide", "tour_guide", [("tapknock", 32), ("wispet", 31), ("brockling", 32)],
             12, 24, "right", ["I show people around the old copper mine up the road. It is the only time anyone is pleased to be underground in Wales and then pleased to be out of it."],
             "Well. I was under the impression I would win. Hmm.", "Copper, then slate, then a lot of tourists. Wales has been mined three ways.", FL)

    wild2(z, [("kidgruff", 30, 32, 22, {}), ("cragchough", 30, 32, 18, {}), ("tapknock", 31, 33, 14, {"time": ["dusk", "night"]}),
              ("wispet", 31, 33, 12, {"weather": ["fog", "drizzle"]}), ("kitelet", 30, 32, 14, {"time": ["day", "dawn"]}),
              ("hootlet", 31, 33, 10, {"time": ["dusk", "night"]}), ("slatelet", 30, 32, 14, {}),
              ("tylwyth", 31, 33, 8, {"time": ["dawn", "dusk"]}), ("gwyllgi", 32, 33, 5, {"time": ["night"]})])
    wild2(z, [("dipling", 30, 32, 30, {}), ("ratty", 30, 32, 30, {}), ("afanc", 31, 33, 12, {"weather": ["drizzle", "downpour"]}),
              ("elverlet", 30, 32, 16, {})], "water")
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 8, 34, "afanc", "aberglaslyn")
    poi_stone(ID, 33, 33, "aberglaslyn", "ward", ["It rings faintly when you tap it, like a bell with a cold.", "The real thing is a glacial erratic: Snowdonia has thousands, dropped by the ice."])
    field_spot(ID, 50, 29, "mend", "wall_gap", "A wall with a tooth missing. {lead} rebuilds it with no mortar and a great deal of dignity, and finds %s in the hollow." % item_name("bara_brith"), "bara_brith", "aberglaslyn")

    # the two ends: open a gap through each border and add the edge
    open_gap("yr_wyddfa", "west", 31, ID)
    open_gap("cambrian_coast", "east", 12, ID)
    gate(z, "east", 31, GATE_FLAG, "Warden", ["The road to the Cambrian Coast is closed. Heritage Assessment. Director Pryce has not come back with the results.",
                                                "He has been up the mountain for a good while now. I am sure it is all going very well."])
    z.save(OUT + "/" + ID + ".json")
    add_map_places({ID: (520, 880)})
