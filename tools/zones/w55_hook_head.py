# Wave 55 roads-celtic, route 9: Hook Head and the Waterford coast. The Wicklow Mountains (south edge of Wicklow, so the
# route's north edge) to the Comeraghs (their east edge, so the route's west edge): down the Wexford coast road to the
# lighthouse, then west towards Waterford and the Greenway. Both ends open at badge_kin, so there is no gate.
from w55_lib import *

ID = "hook_head"


def build(OUT):
    W, H = 64, 50
    FL = 51
    z = route(ID, "Hook Head and the Waterford Coast", W, H, "ireland", "route_ireland", "coast", FL,
              {"drizzle": 28, "clear": 20, "fog": 10, "sunshine": 16, "downpour": 12, "gale": 14},
              {"north": ("wicklow", 31), "west": ("comeraghs", 44)})
    z.legend["r"] = {"tile": "shallow", "prop": "reeds"}
    z.legend["g"] = {"tile": "grass", "colour": "#7fa04a"}
    z.rect(3, 3, 58, 44, "g")
    z.scatter(0, 0, W, H, "P", 14, 5, only="T")
    # the sea to the east, and the Hook peninsula pushing out into it
    z.rect(44, 3, 17, 28, "$")
    z.rect(43, 3, 1, 28, "w")
    z.rect(42, 3, 1, 28, "s")
    z.rect(44, 31, 17, 16, "g")
    z.rect(52, 38, 9, 9, "$")
    z.rect(51, 38, 1, 9, "w"); z.rect(52, 37, 9, 1, "w")
    # the road down the coast and across to the Comeraghs, with a lane to the lighthouse
    poly(z, [(31, 0), (31, 44), (0, 44)], "=", 3)
    poly(z, [(31, 34), (50, 34), (50, 41)], "#", 2)
    # Kilmore Quay's harbour wall is the one thing standing between the village and the Saltees
    z.building(34, 14, 6, 3, "harbour_white", show_label=False)
    z.building(34, 20, 5, 3, "harbour_white", show_label=False)
    z.building(12, 37, 6, 3, "white_render", "Greenway Cafe")
    z.prop("lighthouse", 52, 41)
    z.prop("bollard", 40, 17); z.prop("bollard", 40, 23); z.prop("bench", 36, 18); z.prop("lamp_post", 33, 22)
    z.rect(33, 17, 1, 1, "="); z.rect(32, 17, 1, 1, "=")
    # fields, the greenway's cutting, and tall grass
    for (x, y, w, h) in [(4, 4, 14, 12), (18, 18, 10, 12), (4, 22, 10, 10), (44, 32, 14, 3), (4, 42, 22, 2), (34, 26, 8, 6)]:
        z.rect(x, y, w, h, ",")
        scatter_props(z, "bush", x, y, w, h, 3, x * 3 + y, avoid=(",",))
    z.rect(4, 36, 24, 1, "H"); z.rect(14, 36, 2, 1, ".")
    scatter_props(z, "oak", 3, 3, 58, 44, 14, 71, avoid=("g",))
    scatter_props(z, "rock", 3, 3, 58, 44, 8, 72, avoid=("g",))
    scatter_props(z, "sheep", 4, 4, 14, 12, 3, 73, avoid=(",",))
    z.d["spawn"] = [31, 8]
    finish_borders(z, "=")
    for p_ in list(z.d["props"]):
        if p_["type"] != "building" and z.g[p_["y"]][p_["x"]] in "#=:W~Bwr$":
            z.d["props"].remove(p_)

    sign(z, 28, 3, "NORTH: the Wicklow Mountains and Dublin. The road south from the capital goes by Wexford and ends, if you let it, at a lighthouse.")
    sign(z, 5, 42, "WEST: Waterford and the Comeragh Mountains. The old railway line is a greenway now, forty-six kilometres of flat, which is a mercy after the mountains.")
    sign(z, 52, 33, "HOOK HEAD. Last bit of land before the Celtic Sea. There is a lighthouse at the end and a café at the foot of it, and the café is very glad of you.")
    sign(z, 37, 25, "KILMORE QUAY. A village of thatched cottages and a small harbour. Boats leave here for the Saltee Islands, which are full of birds and one-time princes.")
    plaque(z, 49, 36, "hook_lighthouse", "Hook Lighthouse",
           "The tower on Hook Head is among the oldest working lighthouses in the world. It was built in the 1200s, probably by the Marshal family who held the lands hereabouts, and monks lived in it to keep the fire lit. It has been warning ships off the Wexford and Waterford shore for roughly eight hundred years, and the monks' beacon has become a laser, but the job is the same.")
    plaque(z, 35, 24, "hook_crook", "By Hook or by Crook",
           "Local tradition says the phrase 'by hook or by crook' began here. Hook Head is on the Wexford side of Waterford Harbour and Crooke is on the Waterford side, and the story is that Cromwell's army swore to take the city by one or the other. Linguists point out that the phrase is older than Cromwell, but the lighthouse keepers have heard that and have decided to carry on regardless.")
    plaque(z, 14, 43, "hook_waterford", "Waterford and the Vikings",
           "Waterford was founded by the Vikings in 914, which makes it the oldest city in Ireland. Reginald's Tower, which still stands by the quay, is named after the Viking leader said to have built the first tower there. The city's glassworks produced fine crystal from 1783, and its crusty bread rolls, called blaas, are a local passion, to be eaten fresh and with strong opinions.")

    chat(z, "hh_keeper", "ghillie", 49, 33, "Lighthouse Guide",
         ["Eight hundred years, that tower. I'm only in it forty. But the stairs know me.",
          "When the monks kept it, they burned a fire on the top. It's brighter now. It's also easier on the arms."], "right", "still")
    chat(z, "hh_greenway", "student", 15, 41, "Greenway Cyclist",
         ["I'm doing the Waterford Greenway. Forty-six kilometres, flat the whole way, and a tunnel with the lights on. I've never been happier.",
          "It used to be a railway, and there was no bike in the whole thing. Now there are only bikes. It's a better arrangement."], "left", "still")
    chat(z, "hh_fisher", "fisher", 40, 20, "Fisherman",
         ["The Saltees are out there, a few miles. A Wexford man bought one in 1943 and crowned himself prince. Nobody argued. It was cheaper than an argument.",
          "Gannets, puffins, seals. The islands are the best birdwatching in the south-east. And the prince's throne is still out there, a chair on a rock."], "right", "still")
    trainer2(z, "hh_lighthouse", "Lighthouse Keeper Eamon", "Keeper", "sailor", [("polartern", 50), ("chipgull", 51), ("pierlord", 51)],
             50, 36, "down", ["Ye can't go up in a gale. And ye can't go in a gale and have an argument either. So I'll have it now."],
             "Well hit. The beam is in your favour.", "The light's got eight hundred years on me. I'm just the one who dusts it.", FL)
    trainer2(z, "hh_cyclist", "Cyclist Roisin", "Cyclist", "jogger", [("leveret", 50), ("stoatlet", 51), ("fawnlet", 51)],
             20, 44, "up", ["I've forty kilometres in my legs and a flapjack in my pocket. Stand aside or race me."],
             "That's me beaten. I'll walk the last bit. And eat the flapjack.", "The tunnel on the Greenway's lit up by lights that come on as you pass. It's very Disney.", FL)
    trainer2(z, "hh_birder", "Birdwatcher Maeve", "Birdwatcher", "birdwatcher", [("hushwing", 51), ("sikawhistle", 50), ("tormane", 51)],
             12, 12, "right", ["There's a rare thing in the field. I've been watching it for an hour. It might be a stick."],
             "Hm. That was a rarer thing than I thought.", "Patience is the whole of birdwatching. And a very good flask.", FL)

    wild2(z, [("pooka", 50, 52, 12, {"time": ["dusk", "night"]}), ("gealhare", 50, 52, 14, {}), ("leveret", 50, 52, 14, {}),
              ("tormane", 50, 52, 10, {}), ("sikawhistle", 50, 52, 10, {}), ("hushwing", 51, 52, 8, {"time": ["night"]}),
              ("polartern", 50, 52, 10, {"weather": ["gale", "frost", "fog"]}), ("chipgull", 50, 52, 14, {"time": ["day"]}),
              ("fawnlet", 50, 52, 8, {}), ("stoatlet", 50, 52, 8, {})])
    wild2(z, [("parrlet", 50, 52, 18, {}), ("bradan", 51, 52, 18, {}), ("stalklet", 50, 52, 22, {}), ("pierlord", 50, 52, 16, {}),
              ("rillotter", 50, 52, 14, {}), ("dipling", 50, 52, 10, {})], "water")
    open_gap("wicklow", "south", 31, ID)
    open_gap("comeraghs", "east", 44, ID)
    check_route(z)
    z.save(OUT + "/" + ID + ".json")
    poi_den(ID, 20, 24, "stagmor", "hook_head")
    poi_stone(ID, 58, 32, "hook_head", "ward", ["The salt wind has sanded it smooth, like a pebble the size of a calf.", "The real thing is a Wexford boundary stone, one of many cut to mark the old parish limits."])
    poi_cache(ID, 6, 28, "hook_head", "barmbrack", "A biscuit tin in the hedge with a slice of barmbrack and a note: 'for whoever needs it'. You needed it.")
    field_spot(ID, 15, 35, "mend", "wall_gap", "A wall with a tooth missing. {lead} rebuilds it with no mortar and a great deal of dignity, and finds %s in the hollow." % item_name("colcannon"), "colcannon", "hook_head")
    add_map_places({ID: (300, 960)})
