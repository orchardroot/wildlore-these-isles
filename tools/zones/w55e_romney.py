# Road 9 (wave 55): the Cinque Ports coast. Brighton (east side) along the Sussex coast by Hastings, Rye and Camber
# Sands to Romney Marsh, Dungeness and Dover (west side). Dover and Kent open only when the Moot is won (the London
# gates), so the road carries a bank and a wall of Wardens until moot_won.
from w55_lib import *

ZID = "romney_marsh"
W, H = 72, 50
FLOOR = 94   # Brighton and Dover both 94
GATE = "moot_won"


def build():
    z = route_zone(ZID, "Romney Marsh", W, H, "south_east", "route_moors", "coast", FLOOR,
                   {"clear": 26, "sunshine": 18, "drizzle": 18, "fog": 14, "gale": 14, "downpour": 10})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#7fa053"},
        "m": {"tile": "grass", "colour": "#8cb15b"},
        "q": {"tile": "tall_grass", "colour": "#83a455", "prop": "short"},
        "p": {"tile": "sand", "colour": "#a39d90"},
        "s": {"tile": "sand", "colour": "#d7c99a"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "c": {"tile": "path", "colour": "#cdc7b2"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(0, 29, 3, 3), (69, 19, 3, 3)])
    z.scatter(0, 0, W, H, "P", 8, 1, only="T")
    # --- the sea along the south: sand, shallows, then open water
    for y in range(40, H - 3):
        for x in range(3, W - 3):
            d = y - 40
            z.set(x, y, "s" if d < 2 else ("w" if d == 2 else "$"))
    # --- Dungeness shingle in the south-east
    ell(z, 56, 36, 11, 4, "p", only="gmq")
    for y in range(3, 40):
        for x in range(3, W - 3):
            if z.g[y][x] == "g" and (x * 5 + y * 3) % 7:
                z.set(x, y, "m")
    for (cx, cy, rx, ry) in [(14, 12, 6, 3), (36, 10, 8, 3), (62, 10, 6, 3), (28, 32, 6, 3)]:
        blob(z, cx, cy, rx, ry, "q", only="gm", seed=cx * cy, jitter=0.5)
    # --- Camber Sands dunes
    ell(z, 28, 38, 10, 2.5, "s", only="gmq")
    # --- the Royal Military Canal: a straight ditch across the east side, bridged by the road
    for y in range(3, 40):
        z.set(44, y, "w"); z.set(45, y, "~"); z.set(46, y, "w")
    # --- the road
    ROUTE = [(1, 30), (16, 30), (16, 34), (34, 34), (34, 24), (48, 24), (48, 20), (70, 20)]
    road(z, ROUTE, "c", 3)
    road(z, [(44, 20), (48, 20)], "c", 3)
    # --- Hastings: net huts, the castle ruin on its hill, Old Town cottages
    for i, x in enumerate((5, 8, 11)):
        z.building(x, 36, 2, 3, "weatherboard", "", show_label=False)
    z.building(5, 12, 7, 4, "castle", "Hastings Castle (ruin)")
    z.building(16, 14, 4, 3, "tudor", "Old Town", show_label=False)
    z.building(14, 22, 5, 3, "white_render", "Fishermen's Net Shops", show_label=True)
    # --- Rye: Ypres Tower, Mermaid Street
    z.building(28, 12, 3, 4, "round_tower", "Ypres Tower")
    z.building(24, 18, 4, 3, "tudor", "Mermaid Inn", show_label=True)
    z.building(32, 18, 4, 3, "tudor", "", show_label=False)
    # --- Dungeness: lighthouse, power station, Prospect Cottage, the halt
    z.prop("lighthouse", 58, 33)
    z.building(62, 32, 6, 4, "flat_house", "Power Station", show_label=True)
    z.building(52, 36, 4, 3, "weatherboard", "Prospect Cottage", show_label=True)
    z.building(48, 33, 4, 2, "tin_cottage", "RH&DR Halt", show_label=True)
    z.building(50, 14, 4, 4, "round_tower", "Martello Tower")
    # --- Battle: the Abbey inland, to the north-west
    z.building(8, 3, 10, 5, "cathedral", "Battle Abbey")
    for (x, y) in [(24, 28), (38, 14), (26, 8), (38, 30), (60, 6), (64, 14)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- the gate: a bank across the zone at x = 56, a wall of Wardens in its one gap, Dover behind
    gate_wall(z, "x", 56, 19, 21)
    gate_npcs(z, "rm_gate", 56, 19, 3, "y", GATE, "Warden", "warden_grunt",
              ["The coast road to Dover is closed. Dungeness lorries. Don't ask.",
               "There's a Moot at Stonehenge for those with all ten Stones. Win that and the road to Kent will open, I'm told. In the meantime I can offer you a very nice view of the sea.",
               ], "left")
    # --- signs and plaques
    sign(z, 3, 26, "WEST: Brighton and the South Downs. EAST: Hastings, Rye, Dungeness and, eventually, Dover. The sea is on your right the whole way, which is a comfort, or a threat.")
    plaque(z, 20, 28, "w55e_hastings", "1066 Country",
           "The Battle of Hastings was fought on 14 October 1066, about six miles inland at the place now called Battle. King Harold was killed, and William of Normandy was crowned in London at Christmas. William had Battle Abbey built on the spot, with the high altar said to mark where Harold fell. The town of Hastings gave the battle its name, but the battle was not in Hastings.")
    plaque(z, 30, 22, "w55e_cinque_ports", "The Cinque Ports",
           "Hastings, New Romney, Hythe, Dover and Sandwich, 'the Five Ports', grouped together in the Middle Ages to supply ships and men to the Crown in return for privileges, including their own courts and freedom from some taxes. Rye and Winchelsea joined them as Ancient Towns. For centuries the Barons of the Cinque Ports carried the canopy over the monarch at the coronation.")
    sign(z, 22, 22, "RYE. Mermaid Street, cobbled and steep. The Mermaid Inn was rebuilt in 1420, and in the 1700s the Hawkhurst Gang drank there, reputedly with pistols on the table. The Owlers moved wool out and brandy in.")
    plaque(z, 42, 26, "w55e_military_canal", "The Royal Military Canal",
           "Begun in 1804, when Napoleon's army was camped at Boulogne, as a barrier across the low ground of Romney Marsh if the French landed. It runs about 28 miles from Seabrook near Hythe to Cliff End near Hastings, with a road on the inland side so that troops and guns could be moved along it. Napoleon never came, and the canal was used for barges and tolls instead. It is a pleasant place to walk, a very long wet ditch with a footpath on both banks.")
    sign(z, 52, 22, "MARTELLO TOWER. One of about a hundred round brick towers built along the south and east coasts from 1805 to look out for Napoleon. They have walls up to thirteen feet thick at the seaward side. Some are now holiday lets.")
    plaque(z, 54, 31, "w55e_dungeness", "Dungeness",
           "A great headland of shingle, one of the largest of its kind in Europe, still growing slowly into the sea. The film-maker Derek Jarman bought a black fisherman's hut here, Prospect Cottage, in 1986 and made a garden of driftwood, flints and tough plants in the shingle. The little steam trains of the Romney, Hythe and Dymchurch Railway, which opened in 1927, run to the foot of the lighthouse.")
    sign(z, 66, 22, "EAST: Hythe, Folkestone and Dover. WEST: Dungeness and Rye. Cars may not park on the shingle, and the shingle may not park on cars.")
    # --- people
    chat(z, "rm_fisher", "fisherman_north", 8, 34, "Net Shop Fisherman",
         ["Those tall black huts are net shops. Tarred wood, built tall because there's no room on the beach. They kept the nets dry for 400 years. Hastings is the biggest beach-launched fishing fleet in the country.",
          "No harbour here, you see. We launch off the shingle. It is not the easy way, but it is ours."], "right", "still")
    chat(z, "rm_smuggler", "villager_4", 26, 26, "Marsh Historian",
         ["The Owlers: they smuggled wool out and brandy in, and the marsh gave them the best cover in England. Churchyards, creeks, and a whole village looking the other way.",
          "Russell Thorndike made a hero out of a smuggling parson, Doctor Syn. It's the sort of story the marsh invites."], "down", "still")
    chat(z, "rm_railman", "rail_guard", 49, 31, "Railway Volunteer",
         ["Fifteen-inch gauge, thirteen and a half miles, and every one of them manufactured at one third of the usual scale. Captain Howey wanted the best miniature railway in the world. He got it.",
          "The little trains carry real passengers and there's a proper timetable. Mind your head on the station roof."], "right", "still")
    chat(z, "rm_gardener", "jam_maker", 50, 38, "Shingle Gardener",
         ["Everyone says it can't be done. A garden on a pebble beach. Sea kale, sea holly, viper's bugloss, rock rose. They like a bad day.",
          "The gardens at Prospect Cottage are laid out with stones and driftwood like a poem. People come from all over to stand at the fence and say nothing."], "left", "still")
    # --- trainers
    tr(z, "rm_fisherman", "Beach Fisher Lionel", "Fisherman", "fisherman_north", [("pinchkin", 94), ("chipgull", 95), ("pupplash", 94)], 12, 33, "right",
       ["Launching off the shingle with a tractor, a boat and a good deal of swearing. You're welcome to help, as long as you don't ask what the swearing is for."],
       "That's me washed ashore.", "A Hastings fisherman used to be able to tell you the week by the fish. Now it's the fish telling us.", 4100, FLOOR)
    tr(z, "rm_smuggler_t", "Owler Dougal", "Smuggler", "sailor", [("barnling", 94), ("hushwing", 95), ("leveret", 94)], 24, 30, "right",
       ["Nothing to declare. Nothing at all. This barrel is for a friend, and you didn't see it, because owls don't have friends."],
       "A fair cop. The marsh gives, the marsh takes.", "They used to say an owl hooted when the excise men were out. Owlers were clever. They'd have done well in a bank.", 4000, FLOOR)
    tr(z, "rm_birder", "Reserve Warden Haf", "Birdwatcher", "birdwatcher", [("ternlet", 94), ("bittling", 95), ("stalklet", 94)], 60, 24, "down",
       ["Dungeness RSPB: shingle, scrub, gravel pits and a good number of rare birds that don't know they're rare. I'm very fond of all of them."],
       "I'll note this as 'vigorous behaviour'.", "Little terns nest on the open shingle and rely on camouflage and luck. We rely on tape and signs.", 4100, FLOOR)
    tr(z, "rm_railman_t", "Driver Barry", "Engine Driver", "rail_guard", [("steamlet", 94), ("railspark", 95), ("sailet", 94)], 46, 30, "left",
       ["Steam engine, miniature. Scale one to three, nearly a century old and still doing the job. I've driven her longer than I've known my wife."],
       "Whistle blown. I'll shunt off.", "The tiny trains are more reliable than the proper ones, and more cheerful, but I would say that.", 4000, FLOOR)
    tr(z, "rm_martello", "Coastguard Carol", "Coastguard", "sailor", [("petrelash", 94), ("gannetling", 95), ("dolphlet", 94)], 52, 12, "down",
       ["I watch the Channel. Busiest shipping lane in the world, five hundred ships a day. I love every one of them from here, a safe distance."],
       "A grey day. I'll have another cup of tea.", "Martello towers were never attacked. Some people think it's because the French saw them and gave up. Others think the French never knew.", 4100, FLOOR)
    # --- wildlife
    wild(z, [("flintling", 94, 96, 10, {}), ("chalkling", 94, 96, 8, {}), ("leveret", 94, 96, 10, {"time": ["dawn", "dusk"]}),
             ("kitelet", 94, 96, 8, {"time": ["day"]}), ("rooklet", 94, 96, 8, {}), ("starlet", 94, 96, 10, {}),
             ("barnling", 94, 96, 8, {"time": ["night"]}), ("ternlet", 94, 96, 8, {"time": ["day"], "season": ["spring", "summer"]}),
             ("peregrin", 94, 96, 6, {"time": ["day"]}), ("bittling", 94, 96, 5, {"time": ["dawn", "dusk"]}), ("chipgull", 94, 96, 10, {}),
             ("petrelash", 94, 96, 6, {"weather": ["gale", "fog"]})])
    wild(z, [("chipgull", 94, 96, 20, {}), ("pupplash", 94, 96, 16, {}), ("pinchkin", 94, 96, 20, {}), ("gannetling", 94, 96, 14, {}), ("dolphlet", 94, 96, 10, {}), ("stalklet", 94, 96, 12, {}), ("croakle", 94, 96, 12, {})], "water")
    seal_tile("brighton", 71, 48, "$")   # a stray shallow tile on the sea edge would walk off into the trees
    offW = link("brighton", "east", ZID, 30)
    offE = link("dover", "west", ZID, 20)
    z.d["edges"] = {"west": {"to": "brighton", "offset": offW}, "east": {"to": "dover", "offset": offE}}
    z.d["spawn"] = [3, 30]
    scenery(z, 1100, bushes=20, rocks=10, trees=8, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(1, 30), (70, 20)]):
        print("PROBLEM:", p)
    add_place(ZID, 890, 1140)
    add_data("poi", [
        poi(ZID, "romney_stone", (30, 6), "stone", stat="hp",
            lore=["It leans into the wind and smells faintly of brandy. A very old marker, to a very old business.",
                  "The real thing is the Romney Marsh smuggling trade of the 1700s: the Owlers moved wool out and brandy and tea in, and nearly the whole marsh looked the other way."]),
        poi(ZID, "romney_cache", (10, 40), "cache", item="sea_glass",
            line="Under the shingle bank, in the lee of a boat: a biscuit tin, a pocketful of sea glass, and a note in a child's hand: 'Treasure. Do not tell Dad.'"),
        poi(ZID, "romney_den", (40, 8), "den", species="longman")])
    add_data("field_spots", [
        fspot(ZID, "romney_glint", 38, 38, "line", "glint",
              "Something glints in the shallows by the net shops. {lead} dips in and comes up with an old tobacco tin, a lead token from a ferry that no longer runs, and a quite surprising amount of change.",
              {"money": 480})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
