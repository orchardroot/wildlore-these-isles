# Wave 55 roads-celtic, route 3: Bala and Llyn Tegid. Llangollen (north edge) to Aberystwyth (west edge): the A5 and the
# A494 by way of Corwen and Bala, then on past the lake towards the coast. Aberystwyth opens with the Cambrian Coast,
# after ch3_ddraig_woke, so the road is shut at the Llangollen end until that flag is set.
from w55_lib import *

ID = "llyn_tegid"
GATE_FLAG = "ch3_ddraig_woke"


def build(OUT):
    W, H = 64, 46
    FL = 31
    z = route(ID, "Bala and Llyn Tegid", W, H, "north_wales", "route_lakes", "valley", FL,
              {"drizzle": 30, "clear": 20, "fog": 14, "sunshine": 14, "downpour": 14, "gale": 8},
              {"north": ("llangollen", 32), "west": ("aberystwyth", 20)})
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["m"] = {"tile": "grass", "colour": "#7f8a55"}
    z.legend["h"] = {"tile": "tall_grass", "colour": "#7a6478", "prop": "heather"}
    z.scatter(0, 0, W, H, "P", 50, 5, only="T")
    # the Berwyn slopes, north west of the road, in heather
    z.rect(4, 4, 18, 6, "h")
    # Llyn Tegid, the biggest natural lake in Wales
    blob(z, 36, 25, 14, 6, "~", seed=8)
    blob(z, 36, 25, 16, 8, "r", only=".", seed=9)
    # roads: from Llangollen down to the junction at Bala, then west along the north shore towards Aberystwyth
    z.rect(31, 0, 3, 13, "=")
    z.rect(19, 11, 36, 3, "=")
    z.rect(3, 11, 17, 3, "=")
    z.rect(3, 11, 3, 11, "=")
    z.rect(0, 19, 6, 3, "#")
    # Bala: a main street's worth of buildings north of the road
    z.building(36, 4, 8, 4, "stone", "Bala Grammar Hall")
    z.building(45, 4, 6, 4, "slate_cottage", show_label=False)
    z.building(52, 5, 5, 3, "white_render", show_label=False)
    z.rect(35, 8, 22, 1, ":"); z.rect(35, 9, 1, 2, ":")
    z.prop("lamp_post", 35, 9); z.prop("lamp_post", 56, 9); z.prop("bench", 44, 9); z.prop("post_box", 49, 9)
    z.prop("statue", 28, 9)
    # the lake railway halt on the south shore, off the path, reached by a track round the east end
    z.building(38, 36, 8, 3, "white_render", "Bala Lake Railway")
    z.rect(52, 14, 3, 21, "#"); z.rect(38, 34, 17, 1, "#")
    z.rect(40, 35, 1, 1, "#")
    # tall grass and woods
    for (x, y, w, h) in [(24, 4, 8, 5), (46, 15, 6, 8), (6, 24, 10, 8), (10, 36, 16, 6), (56, 20, 4, 12), (22, 18, 6, 6)]:
        z.rect(x, y, w, h, ",")
        scatter_props(z, "bush", x, y, w, h, 3, x * 3 + y, avoid=(",",))
    scatter_props(z, "oak", 3, 3, 58, 40, 20, 14, avoid=(".",))
    scatter_props(z, "birch", 3, 3, 58, 40, 10, 15, avoid=(".",))
    scatter_props(z, "rock", 3, 3, 58, 40, 12, 16, avoid=(".", "h"))
    scatter_props(z, "sheep", 4, 4, 18, 6, 4, 17, avoid=("h",))
    z.d["spawn"] = [32, 8]
    finish_borders(z, "=")
    z.rect(0, 19, 3, 3, "#")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bw":
            z.d["props"].remove(p_)

    sign(z, 29, 2, "NORTH: Corwen, Llangollen and the Dee. Gogledd. Owain Glyndŵr was proclaimed Prince of Wales near here in 1400, and the Welsh have not entirely stopped cheering.")
    sign(z, 5, 18, "WEST: Dolgellau, Machynlleth and the Cambrian Coast. Gorllewin. The road climbs, falls, and does it again, as if it were showing off.")
    sign(z, 40, 12, "LLYN TEGID. Four miles long, a mile wide, and the largest natural lake in Wales. The River Dee runs through it from end to end, which is the sort of thing a lake does when it is determined to be useful.")
    sign(z, 14, 16, "Y BALA. The name means the outlet, the place where a lake empties. The lake does not mind. It has been emptying here since the ice left.")
    plaque(z, 27, 9, "llyn_tegid_glyndwr", "Glyndŵr's Proclamation",
           "On 16 September 1400 Owain Glyndŵr was proclaimed Prince of Wales at his manor at Glyndyfrdwy, on the Dee between Llangollen and Corwen. The revolt that followed lasted over a decade. Glyndŵr was never captured and no one knows for certain where he died, which has kept the legend in good health.")
    plaque(z, 47, 9, "llyn_tegid_bible", "Mary Jones and the Bible",
           "In 1800 a Welsh girl of fifteen, Mary Jones, is said to have walked some twenty-five miles from her home to Bala to buy a Bible from the minister Thomas Charles. He had run out of copies. The story goes that he found her one anyway, and that her journey helped to inspire the founding of the British and Foreign Bible Society in 1804.")
    plaque(z, 54, 22, "llyn_tegid_gwyniad", "The Gwyniad",
           "The gwyniad is a whitefish that lives in Llyn Tegid and nowhere else in Wales, a relic of the cold water left behind when the glaciers melted. It is silver, shy and rare, and fishermen who catch one are asked politely to put it back.")

    chat(z, "tg_boatman", "sailor", 22, 26, "Boat Hirer",
         ["The lake can go from glass to white horses in the time it takes to eat a Welsh cake. Wear the life jacket. It does not make you look silly. It makes you look alive.",
          "Welsh legend puts Ceridwen in a house on this lake. She is the one who kept the cauldron that made the poet Taliesin. I would not leave my sandwiches unattended near her."], "right", "still")
    chat(z, "tg_learner", "student", 42, 10, "Welsh Learner",
         ["Dw i'n dysgu Cymraeg. I am learning Welsh. It is going well, if by well you mean I can order a tea and apologise for not being able to order anything else.",
          "Everyone in Bala is lovely about it. They wait. They smile. They answer in English, and then in Welsh, and then in a slower Welsh, which I appreciate."], "down", "still")
    chat(z, "tg_railwayman", "rail_guard", 34, 35, "Railway Volunteer",
         ["Our little steam railway runs along the shore of the lake. Four miles of it, at the speed of a good conversation.",
          "The track was once a main line. Now it is a narrow gauge and a very lovely thing to sit on with a flask."], "right", "still")
    trainer2(z, "tg_angler", "Angler Elis", "Angler", "angler", [("elverlet", 30), ("ductling", 31), ("afanc", 32)],
             24, 33, "right", ["Quiet, please. There is a gwyniad out there and it has not yet decided to be impressed by me."],
             "Hm. That is the fish I was hoping for, and it did not come.", "The gwyniad only lives here. If you ever see one, say hello and put it back.", FL)
    trainer2(z, "tg_walker", "Walker Mari", "Walker", "hiker", [("kidgruff", 30), ("wispet", 31), ("brockling", 31)],
             20, 22, "up", ["I am walking to Bala the way Mary Jones did. It is about twenty-five miles. She did it in a day, in 1800, with a bit of bread and a plan."],
             "Right. That is a lesson in endurance. I am glad it was yours.", "Twenty-five miles on foot for one book. It makes a late train look like a minor inconvenience.", FL)
    trainer2(z, "tg_choir", "Choir Singer Bryn", "Choir Singer", "choir_singer", [("tylwyth", 31), ("gwyllgi", 31), ("martling", 32)],
             46, 18, "left", ["I am in the male voice choir. We are rehearsing a hymn in four parts and I am the part that always comes in late."],
             "Well sung. I would give you a round of applause, but I have my hands full of your victory.", "Cwm Rhondda in a lakeside barn. That is how the Welsh like to spend Saturday night.", FL)

    wild2(z, [("tylwyth", 30, 32, 16, {"time": ["dawn", "dusk"]}), ("gwyllgi", 31, 33, 14, {"time": ["night", "dusk"]}),
              ("martling", 30, 32, 12, {"time": ["dusk", "night"]}), ("brockling", 30, 32, 16, {"time": ["dawn", "day", "dusk"]}),
              ("wispet", 31, 33, 10, {"weather": ["fog", "drizzle"]}), ("kidgruff", 30, 32, 18, {}),
              ("cragchough", 30, 32, 14, {}), ("kitelet", 30, 32, 12, {"time": ["day", "dawn"]}),
              ("hootlet", 31, 33, 8, {"time": ["night"]})])
    wild2(z, [("afanc", 31, 33, 18, {}), ("elverlet", 30, 32, 24, {}), ("ductling", 30, 32, 22, {}), ("dipling", 30, 32, 20, {}),
              ("moonbell", 31, 33, 10, {"time": ["dusk", "night"]})], "water")
    gate(z, "north", 32, GATE_FLAG, "Warden", ["The road to Bala and the coast is closed. Heritage Assessment. Director Pryce has not come back with the results.",
                                                  "He has been up the mountain for a good while now. I am sure it is all going very well."])
    open_gap("llangollen", "south", 32, ID)
    open_gap("aberystwyth", "east", 20, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 9, 28, "afanc", "llyn_tegid")
    poi_stone(ID, 56, 38, "llyn_tegid", "ward", ["It is cold, round and quietly smug, like a stone that has been polished by a glacier and knows it.", "The real thing is a Welsh erratic: a boulder the ice carried and left behind in the valley."])
    poi_cache(ID, 20, 40, "llyn_tegid", "cawl", "A bottle-green flask wedged in a wall. Someone's lunch, kept warm for later. Sorry about that.")
    field_spot(ID, 19, 26, "line", "glint", "A glint under the water at the lake's edge. {lead} hooks it with patience and a bit of reed. It is %s." % item_name("brown_trout"), "brown_trout", "llyn_tegid")
    add_map_places({ID: (570, 915)})
