# Wave 55 roads-scotland, part 3: the coast and island roads (Angus coast, Trotternish, Uig, Scalloway, the Machars).
import os
from w55_sc_kit import *

OUT = os.path.join(ROOT, "data", "zones")
WX_COAST = {"drizzle": 30, "clear": 22, "downpour": 10, "fog": 14, "gale": 12, "sunshine": 12}


def pond(z, x, y, w, h):
    z.rect(x, y, w, h, "w")
    z.rect(x + 1, y + 1, w - 2, h - 2, "~")


def sea_strip(z, x, y, w, h):
    """open sea with a shallow fringe on its landward (west and north) edges, a beach strip west of it."""
    z.rect(x, y, w, h, "$")
    z.rect(x - 1, y, 1, h, "w")
    z.rect(x - 4, y, 3, h, "s")


# ----------------------------------------------------------------------------------------------------------------
# 6. The Angus coast: Dundee north-east by Arbroath, Montrose and Stonehaven to Aberdeen
def angus_coast():
    zid = "angus_coast"
    at = zid
    z = scaffold(zid, "The Angus Coast", 64, 48, "route_coast", WX_COAST, "coast", 69, seed=71)
    z.rect(3, 3, 58, 42, ".")
    z.scatter(3, 3, 40, 42, "T", 30, 72, only=".")
    link(z, "west", 20, "dundee", "east", 22)
    link(z, "south", 30, "aberdeen", "north", 14)
    sea_strip(z, 47, 3, 14, 42)
    path(z, [(3, 19), (29, 19), (29, 45)], "#", 3)
    # Arbroath
    z.building(8, 6, 10, 5, "stone", "Arbroath Abbey"); z.rect(8, 11, 10, 1, ":"); z.rect(12, 12, 3, 7, "#")
    z.building(21, 6, 6, 4, "white_render", "Smokie Shed"); z.rect(21, 10, 6, 1, ":")
    # Bell Rock, a long way off
    z.rect(54, 9, 3, 3, "s"); z.prop("lighthouse", 55, 10)
    # Dunnottar, on its rock to the south
    z.building(33, 36, 8, 5, "stone", "Dunnottar Castle"); z.rect(32, 41, 9, 1, ":")
    z.prop("flagpole", 41, 37)
    z.prop("bench", 28, 38); z.prop("lamp_post", 33, 42)
    plaque(z, 14, 12, "w55_sc_arbroath", "The Declaration of Arbroath",
           "THE DECLARATION OF ARBROATH. In 1320 the barons and nobles of Scotland sent a letter from Arbroath to the Pope, saying that as long as a hundred of them lived they would never submit to English rule: 'for it is not for glory, nor riches, nor honours that we are fighting, but for freedom'. The abbey itself had been founded in 1178 by William the Lion. It has kept the roof off ever since, on a technicality.")
    plaque(z, 45, 12, "w55_sc_bell_rock", "The Bell Rock",
           "THE BELL ROCK LIGHTHOUSE. Built on a reef eleven miles out to sea, off Arbroath, between 1807 and 1810 to the design of Robert Stevenson, and the oldest sea-washed lighthouse still standing in the world. The masons worked on the reef at low tide with the sea coming in round their ankles, and then went home for tea.")
    plaque(z, 36, 42, "w55_sc_dunnottar", "Dunnottar Castle",
           "DUNNOTTAR CASTLE. A ruined fortress on a headland south of Stonehaven. In 1651, with Cromwell's army closing in, the Honours of Scotland, the crown, sceptre and sword of state, were smuggled out past the besiegers and hidden in the church at Kinneff. They came back to Edinburgh after the Restoration and are in the Castle now.")
    z.sign(23, 11, "ARBROATH SMOKIES. Haddock, salted and smoked in pairs over a hardwood fire in a half barrel, a method from the fishing village of Auchmithie. The name is protected, so a smokie from anywhere else is not allowed to call itself one.")
    z.sign(40, 28, "FOWLSHEUGH. Red sandstone cliffs south of Stonehaven that hold one of the great seabird colonies of the east coast: guillemots, razorbills and kittiwakes on every ledge, and the odd puffin, looking as if it has come to the wrong party.")
    grass_patches(z, [(36, 4, 8, 12), (36, 22, 8, 8), (4, 24, 14, 10), (34, 30, 8, 4), (18, 36, 10, 6), (4, 38, 8, 5)])
    scatter_props(z, "rock", 3, 3, 40, 42, 12, 74, avoid=("."))
    scatter_props(z, "bush", 3, 3, 40, 42, 12, 75, avoid=("."))
    z.d["spawn"] = [5, 20]
    # Aberdeen opens when the Frost Stone is won at Inverness (the Inverness gates hide on badge_frost): so does this road
    gate_blockers(z, "south", 30, "badge_frost", "gate_angus", lines=[
        "Road closed at Stonehaven. Resurfacing, apparently, though I have not seen a single steamroller.",
        "It reopens once the Keeper at the Inverness ice rink has had a word with you. Don't ask me how I know. I only hold the cones."])
    chat(z, "ang_smokie", "fisherman_north", 24, 12, "Smokie Maker", ["Two haddock tied by the tails, hung over a barrel fire. That is it. That is the secret. The other secret is not to tell the tourists it is that simple.",
         "Mòran taing for asking. Most people just ask where the chip shop is."], "down", "still")
    chat(z, "ang_birder", "birdwatcher", 40, 22, "Birdwatcher", ["Fowlsheugh is a good wall of birds. Kittiwakes, guillemots, razorbills. If anyone says the puffin is hiding, they are lying. It is just thinking.",
         "A kittiwake is named for its own call. Whoever came up with the name had an easy day."], "left", "still")
    chat(z, "ang_honours", "tour_guide", 33, 43, "Castle Guide", ["The Honours of Scotland were hidden from Cromwell here, carried out under the besiegers' noses, and buried in a kirk. The story is better than any film they have made of it.",
         "A woman in the kirkyard hid them, they say, in plain sight, with a basket of flax. That is the sort of bravery you do not put in a poster."], "up", "still")
    chat(z, "ang_lifeboat", "villager_5", 26, 16, "Lifeboat Volunteer", ["I am on the crew. Two hours' warning, usually. The pager goes at the worst moment. It is always the worst moment.",
         "The sea off Angus has taken ships for a very long time. We have been taking them back out, a little more often, ever since."], "right", "still")
    trn(z, "ang_fisher", "Fisherman Dod", "Fisherman", "fisherman_north", [("cooplet", 69), ("chipgull", 70), ("gannetling", 70)],
        36, 20, "left", ["I am up at four every day. I thought I would let you know, in case you thought I was awake out of choice."],
        "A fair fight. I will take the boat out and think about it.", "I have been fishing this coast for forty years. The fish still do not tell me where they are.", 2260)
    trn(z, "ang_keeper", "Keeper Andrina", "Lighthouse Keeper", "ravenmaster", [("polartern", 70), ("ternlet", 69), ("haarling", 70)],
        22, 24, "up", ["I look after a light. A real one, a long way off. You will not see it from here, but I like to imagine it is watching."],
        "A very good battle. The light is still on. I checked.", "The Bell Rock was lit for the first time in 1811. A hundred and eighty years of keepers have stared at that horizon. Some of them stayed awake.", 2290)
    trn(z, "ang_walker", "Coastal Walker Fraser", "Walker", "hiker", [("starlet", 69), ("binfox", 69), ("clownbill", 70)],
        10, 24, "right", ["Cliff path, sea air, bacon roll. That is a good day, and you are not in it."],
        "A good battle. The bacon roll is on me.", "The best bit of this coast is the bit you do not walk, because the cliff is not there any more.", 2250)
    trn(z, "ang_birder_t", "Warden Isobel", "Warden", "warden_grunt", [("clownbill", 70), ("polartern", 70), ("puffling", 70), ("haarling", 69)],
        38, 33, "up", ["Please keep off the ledge. The ledge is for the kittiwakes. The kittiwakes have a better lawyer than you."],
        "Fair play. I will report you to the puffins.", "A seabird colony is a city with no police. We are the nearest thing, and nobody takes us seriously.", 2300)
    wild(z, [("cooplet", 69, 70, 10, {}), ("chipgull", 69, 70, 12, {"time": ["dawn", "day"]}), ("ternlet", 69, 70, 8, {"time": ["dawn", "day"]}),
             ("polartern", 69, 70, 8, {}), ("clownbill", 69, 70, 8, {"time": ["day", "dawn"]}), ("haarling", 69, 70, 8, {"weather": ["fog", "drizzle"]}),
             ("starlet", 69, 70, 8, {"time": ["day"]}), ("binfox", 69, 70, 8, {"time": ["night", "dusk"]}), ("flittermouse", 69, 70, 6, {"time": ["night"]}),
             ("puffling", 69, 70, 6, {"time": ["day"]})])
    wild(z, [("dolphlet", 69, 70, 16, {}), ("pupplash", 69, 70, 12, {}), ("gannetling", 69, 70, 16, {"weather": ["gale", "drizzle"]}),
             ("puffling", 69, 70, 12, {}), ("selklet", 69, 70, 12, {}), ("greyhaul", 69, 70, 14, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 81, area=(3, 3, 42, 42))
    poi(z, "cache", at, a, item="sou_wester_yellow", line="A biscuit tin, wedged behind the rock. The lid took three goes.")
    poi(z, "den", at, b, species="puffling")
    poi(z, "stone", at, c, stat="ward", lore=["The wind drops when you stand beside it. You do not mention this to anyone.", "The real thing is the Ring of Brodgar, on Orkney: a huge ring of upright slabs on a spit between two lochs."])
    field(z, "line", "line", "glint", 46, 26, "Something glints in the surf. {lead} wades in, makes a few calm passes and fishes it out: a purse, a bit salty.", {"money": 32 * 70}, at)
    place(at, 665, 360)


# ----------------------------------------------------------------------------------------------------------------
# 7. Trotternish: Skye's northern peninsula, Portree round by the Storr, the Quiraing and Kilmuir
def trotternish():
    zid = "trotternish"
    at = zid
    z = scaffold(zid, "Trotternish", 60, 48, "route_highlands", WX_HIGH, "mountain", 74, seed=81)
    z.rect(3, 3, 54, 42, ".")
    z.scatter(3, 3, 54, 42, "R", 120, 82, only=".")
    link(z, "north", 30, "skye", "south", 60)
    link(z, "east", 24, "portree", "west", 36)
    path(z, [(29, 3), (29, 23), (57, 23)], "#", 3)
    z.rect(40, 3, 17, 12, "$"); z.rect(39, 3, 1, 12, "w"); z.rect(40, 15, 17, 1, "w")
    # the Quiraing, a landslip of cliff and pinnacle
    z.rect(5, 5, 16, 9, "^"); z.rect(5, 14, 16, 2, "R")
    z.prop("standing_stone", 8, 17); z.prop("standing_stone", 11, 18); z.prop("standing_stone", 14, 17)
    # the Old Man of Storr
    z.prop("standing_stone", 24, 8); z.prop("rock", 25, 9); z.prop("rock", 23, 9)
    # Kilmuir: the old kirkyard and the museum of island life
    z.building(8, 30, 6, 4, "stone", "Kilmuir Kirkyard")
    z.building(22, 34, 8, 4, "slate_cottage", "Museum of Island Life")
    for (x, y) in [(10, 36), (12, 37), (14, 36), (16, 38)]:
        z.prop("headstone", x, y)
    z.prop("standing_stone", 12, 39)
    z.rect(10, 34, 3, 2, ":"); z.rect(24, 38, 4, 1, ":")
    # Staffin shore: the dinosaur slab
    z.prop("limestone_pavement", 44, 30); z.prop("limestone_pavement", 45, 31)
    z.rect(42, 26, 14, 10, "s")
    # Mealt Falls over Kilt Rock
    z.prop("cascade", 50, 17)
    plaque(z, 12, 34, "w55_sc_flora", "Flora MacDonald",
           "FLORA MACDONALD. In June 1746, after Culloden, the young Flora MacDonald helped Prince Charles Edward Stuart escape from the Outer Hebrides to Skye, with the Prince dressed as her maid, Betty Burke. She was arrested and held in the Tower of London, then freed in 1747, and she is buried in the kirkyard at Kilmuir under a large Celtic cross.")
    plaque(z, 26, 10, "w55_sc_storr", "The Storr",
           "THE OLD MAN OF STORR. A pinnacle of rock some fifty metres tall, standing in the ruin of a vast landslip. The whole of the Trotternish ridge has been sliding slowly towards the sea for thousands of years, which makes it one of the longest landslips in Britain, and the Old Man is the bit that has stayed upright.")
    plaque(z, 46, 30, "w55_sc_staffin", "Skye's Dinosaurs",
           "STAFFIN. The rocks of Trotternish are Middle Jurassic, about 170 million years old, and the shore at Staffin Bay holds dinosaur footprints in the slabs. Skye is one of the most important places in Britain for dinosaur remains of that age. The prints are best at low tide, and best of all when you have been told where to look.")
    z.sign(20, 20, "THE QUIRAING. A hillside that has slipped, leaving a wall of cliff, a flat green table and a scatter of pinnacles. The road over the top is single track and the view is a very good reason to pull in.")
    z.sign(48, 18, "KILT ROCK. Basalt columns in a cliff above the sea, looking like the pleats of a kilt, with the Mealt Falls pouring off the top. The wind sometimes blows the waterfall back up the hill.")
    scatter_props(z, "bush", 3, 3, 54, 42, 12, 83, avoid=("."))
    grass_patches(z, [(6, 18, 12, 6), (34, 26, 8, 6), (6, 26, 10, 3), (36, 36, 16, 6), (34, 6, 5, 10), (22, 12, 5, 6)])
    z.d["spawn"] = [30, 5]
    chat(z, "trt_walker", "hiker", 31, 12, "Ridge Walker", ["The Trotternish ridge is one long walk with a view on the one side and a view on the other. In between is a path that is not always there.",
         "Everyone takes a photograph of the Old Man. The Old Man does not mind. He has been photographed more than the Queen."], "right", "still")
    chat(z, "trt_museum", "villager_4", 26, 39, "Museum Guide", ["The blackhouse here has a peat fire and a bed in the corner for the cow. I would not want to live in one. I would not want it demolished either.",
         "Fàilte. That is 'welcome'. The kettle is always on, because the peat is always lit."], "up", "still")
    chat(z, "trt_cross", "pilgrim", 14, 33, "Visitor", ["Flora MacDonald is buried here. A woman who did something very brave and then was very modest about it. I find that restful.",
         "She is said to have said she would have done the same for any man in distress. I notice she did not say it twice."], "right", "still")
    chat(z, "trt_fossil", "student", 44, 33, "Fossil Hunter", ["Those are not scratch marks. Those are footprints. A dinosaur walked across this mud about a hundred and seventy million years ago and nobody told it to stop.",
         "The tide comes in fast. If you are looking for the best prints, bring a torch and a good excuse."], "down", "still")
    creature_npc(z, "trt_eagle", "goldeneyrie", 22, 16, "A golden eagle hangs on the wind above the Quiraing, taking in the whole of Skye as though it had a mortgage on it.")
    trn(z, "trt_crofter", "Crofter Seonaid", "Crofter", "farmer", [("heilan", 74), ("cragchough", 74), ("hushwing", 75)],
        32, 20, "down", ["A croft is a small farm and a large argument. Fancy joining the argument?"],
        "A good battle. The sheep will have something to say.", "My great-grandmother worked this croft. She said the land owns you. It has never once let me forget it.", 2400)
    trn(z, "trt_guide", "Guide Calum", "Guide", "tour_guide", [("goldeneyrie", 75), ("highlynx", 74), ("ptarmigan", 75), ("forkwing", 74)],
        30, 30, "left", ["The Storr is the most photographed rock in Skye, and I give the talk four times a day. Tell me you are not in a hurry."],
        "Well fought. I will give the talk again, but shorter.", "The real secret of Trotternish is the weather. It will be a different place in five minutes, and you will like it more.", 2460)
    trn(z, "trt_birdwatcher", "Birdwatcher Rhona", "Birdwatcher", "birdwatcher", [("polartern", 74), ("clownbill", 75), ("plungebeak", 75)],
        46, 24, "up", ["Sea eagles are back on Skye. Have you seen one? Do not tell me you have seen one. I have been out here since six."],
        "A good battle. I did not see an eagle, but I saw you.", "A white-tailed eagle has a wingspan of about two and a half metres. It is the barn door of the sky.", 2430)
    trn(z, "trt_piper", "Piper Donald", "Piper", "piper", [("heilan", 75), ("midgeswarm", 74), ("cragchough", 74), ("hushwing", 74)],
        12, 24, "right", ["I play on the hill so the sound carries. It carries all the way to Portree, which is the complaint."],
        "A grand fight. I will write a tune about it. It will be sad.", "A pipe tune over a landslip is the sound of the island remembering itself.", 2420)
    wild(z, [("highlynx", 74, 75, 8, {"time": ["dusk", "night"]}), ("goldeneyrie", 74, 75, 8, {"time": ["day"]}), ("ptarmigan", 74, 75, 10, {"weather": ["frost", "fog"]}),
             ("heilan", 74, 75, 12, {}), ("clownbill", 74, 75, 8, {"time": ["day", "dawn"]}), ("plungebeak", 74, 75, 8, {}),
             ("midgeswarm", 74, 75, 10, {"weather": ["drizzle", "fog", "clear"]}), ("cragchough", 74, 75, 10, {}), ("forkwing", 74, 75, 8, {}),
             ("polartern", 74, 75, 6, {}), ("hushwing", 74, 75, 8, {"time": ["night"]})])
    wild(z, [("skaldling", 74, 75, 14, {}), ("orcalet", 74, 75, 10, {}), ("bayrunner", 74, 75, 12, {}), ("selkie", 74, 75, 8, {"time": ["dusk", "night"]}),
             ("greyhaul", 74, 75, 12, {}), ("rillotter", 74, 75, 12, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 91)
    poi(z, "stone", at, a, stat="def", lore=["It is cold, and it hums very faintly, the way a fridge does.", "The real thing is Callanish, on the Isle of Lewis: a cross of standing stones about 5,000 years old."])
    poi(z, "cache", at, b, item="kendal_mint_cake", line="A flask-sized tin under a flat stone, tied with garden twine. There is mint cake in it. Not a bad find.")
    poi(z, "camp", at, c, names=[["Poacher Rab", "Poacher"], ["Poacher Seamus", "Poacher"]], party=["heilan", "cragchough", "forkwing"],
        line="The lamping's good here. Was good here.", money=300 + 40 * 75, item="iron_snare")
    field(z, "round_up", "round_up", "sheep_gate", 36, 24, "Sheep at the gate, and no sheep will go first. {lead} comes round the back, low and quiet, and the flock files through. The crofter's thanks: a pasty.", {"item": "pasty", "qty": 1}, at)
    place(at, 372, 262)


# ----------------------------------------------------------------------------------------------------------------
# 8. The Uig road: Stornoway west across Lewis by the Callanish road to the Uig sands, and round to Harris
def uig_road():
    zid = "uig_road"
    at = zid
    z = scaffold(zid, "The Uig Road", 64, 48, "route_coast", WX_COAST, "coast", 74, seed=91)
    z.rect(3, 3, 58, 42, ".")
    z.scatter(3, 3, 58, 42, "R", 60, 92, only=".")
    link(z, "east", 16, "stornoway", "west", 40)
    link(z, "west", 34, "harris", "east", 64)
    path(z, [(3, 33), (20, 33), (20, 15), (60, 15)], "#", 3)
    # Uig sands and the sea to the south-east
    z.rect(30, 32, 31, 13, "$"); z.rect(30, 31, 31, 1, "w"); z.rect(30, 26, 31, 5, "s")
    # Dun Carloway and Gearrannan
    z.building(44, 6, 7, 6, "stone", "Dun Carloway"); z.rect(44, 12, 7, 1, "#")
    z.building(8, 6, 6, 3, "white_render", "Blackhouse"); z.building(16, 6, 6, 3, "white_render", "Blackhouse"); z.building(8, 11, 6, 3, "white_render", "Blackhouse")
    z.rect(8, 9, 14, 1, ":"); z.rect(12, 14, 3, 1, "#")
    z.prop("standing_stone", 38, 20); z.prop("standing_stone", 40, 21); z.prop("standing_stone", 42, 20)
    z.prop("boat", 40, 37, variant=1); z.prop("bollard", 33, 30)
    plaque(z, 36, 24, "w55_sc_chessmen", "The Lewis Chessmen",
           "THE LEWIS CHESSMEN. In 1831 a hoard of ninety-three carved chess pieces, made of walrus ivory and whale's tooth in the twelfth century, was found in the sands at Uig. Most are now in the British Museum and the rest in the National Museum of Scotland in Edinburgh. Some of the kings look frightened, which has always seemed fair.")
    plaque(z, 47, 13, "w55_sc_carloway", "Dun Carloway",
           "DUN CARLOWAY. A broch, a drystone tower built for defence about two thousand years ago and one of the best preserved in Scotland, standing on a rocky hill overlooking Loch Carloway. The walls are hollow, with stairs between the inner and outer skin, so the whole wall was lived in.")
    z.sign(15, 10, "GEARRANNAN. A village of blackhouses, the old thatched crofting houses of Lewis, on the shore at the end of a steep road. They were lived in until the 1970s and have since been restored. The thatch is held down with stones against the Atlantic, which has opinions.")
    z.sign(34, 29, "UIG SANDS. A great tidal bay with a beach so wide and flat that the tide goes out and nearly forgets to come back. The Lewis Chessmen were found at Ardroil, at the south end. They had been waiting a long time to be found.")
    scatter_props(z, "bush", 3, 3, 58, 42, 10, 93, avoid=("."))
    grass_patches(z, [(24, 4, 12, 8), (4, 18, 12, 8), (24, 36, 4, 6), (50, 18, 8, 8), (4, 36, 12, 6), (26, 18, 8, 6)])
    z.d["spawn"] = [5, 34]
    chat(z, "uig_weaver", "villager_6", 12, 15, "Tweed Weaver", ["Everything here was done by hand. The cloth, the thatch, the dry stone. Do not look at me like that, I use a machine for some of it.",
         "Mòran taing for asking. Most visitors take a photograph of the loom and ask if it is for sale."], "down", "still")
    chat(z, "uig_guide", "tour_guide", 46, 14, "Broch Guide", ["The wall of the broch is hollow, with stairs inside. If you were an Iron Age family, you lived in the wall, and the cattle lived in the middle.",
         "A thousand years later they were still using it. I always say that is the highest praise a building can get."], "down", "still")
    chat(z, "uig_chess", "poet", 38, 24, "Chess Player", ["The Lewis Chessmen are the most famous chess pieces in the world. Some of the queens have their hand on their cheek, as if the game has gone on too long.",
         "The pieces were found in a sand dune. A man dug them up in 1831 and took them to Stornoway in a sack. They have not been in the same place since."], "right", "still")
    chat(z, "uig_crofter", "farmer", 28, 20, "Crofter", ["I could say something clever about the Atlantic. Instead I will tell you the wind has been working on my gate since March.",
         "Slàinte mhath. That is a good-health toast. I say it with tea, since the tea is stronger."], "left", "still")
    creature_npc(z, "uig_seal", "selklet", 40, 29, "A selkie pup, or something very like one, lolls at the edge of the tide. It gives you a very long look, then a short one, then a yawn.")
    trn(z, "uig_islander", "Islander Murdo", "Islander", "fisherman_north", [("heilan", 74), ("crexling", 74), ("skaldling", 75)],
        24, 26, "up", ["I have lived on Lewis all my life. I know where the road goes. I do not always know where it has been."],
        "A good battle. I will have tea on the strength of it.", "People ask if it is lonely. I say no. There is a lot of company in a place with that many sheep.", 2400)
    trn(z, "uig_birdwatcher", "Corncrake Watcher Peigi", "Birdwatcher", "birdwatcher", [("crexling", 74), ("buntling", 75), ("eaglet", 75)],
        6, 24, "right", ["Listen. That rasping noise in the grass is a corncrake. There are very few left, and here is a place they still turn up."],
        "That was a fine battle. I will stay and listen to the grass.", "Corncrakes are heard far more than seen. They are the introverts of the bird world.", 2420)
    trn(z, "uig_beachcomber", "Beachcomber Iain", "Beachcomber", "fisher", [("selklet", 74), ("dolphlet", 75), ("greyhaul", 75), ("chipgull", 74)],
        46, 24, "left", ["I walk the sands every tide. I have found a great many things. None of them are chess pieces. It still counts as a hobby."],
        "That was a fine fight. I will find something to consolation-prize you with.", "The sea gives things up, and eventually takes them back. It is the most honest dealer on the coast.", 2430)
    trn(z, "uig_warden", "Ranger Fionnghal", "Ranger", "warden_grunt", [("cragchough", 75), ("heilan", 74), ("midgeswarm", 74)],
        52, 16, "down", ["This stretch of coast is protected. By me. Please do not take the sand home. A woman tried last week. She was very sorry."],
        "Fair battle. I will take it as a warning.", "A machair is a low meadow of shell sand, flowers and grass, and it is one of the rarest habitats in Europe. We are quite fond of it.", 2400)
    wild(z, [("heilan", 74, 75, 12, {}), ("crexling", 74, 75, 10, {"time": ["dusk", "night", "dawn"]}), ("cragchough", 74, 75, 10, {}), ("buntling", 74, 75, 8, {}),
             ("hushwing", 74, 75, 8, {"time": ["night"]}), ("flittermouse", 74, 75, 6, {"time": ["night"]}), ("midgeswarm", 74, 75, 10, {"weather": ["drizzle", "fog", "clear"]}),
             ("herdlet", 74, 75, 8, {}), ("eaglet", 74, 75, 6, {"time": ["day"]}), ("skaldling", 74, 75, 6, {})])
    wild(z, [("selklet", 74, 75, 16, {}), ("greyhaul", 74, 75, 14, {}), ("dolphlet", 74, 75, 12, {}), ("chipgull", 74, 75, 12, {}),
             ("plungebeak", 74, 75, 10, {}), ("skaldling", 74, 75, 10, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 101, area=(3, 3, 56, 24))
    poi(z, "cache", at, a, item="headscarf_tartan", line="Someone's hiding place, and not as hidden as they hoped.")
    poi(z, "stone", at, b, stat="lore", lore=["It leans, slightly, like it has heard all this before.", "The real thing is Callanish, on the Isle of Lewis: a cross of standing stones about 5,000 years old."])
    poi(z, "den", at, c, species="selklet")
    field(z, "charm", "charm", "molehill", 50, 22, "A fresh molehill, and a hopeful hum. {lead} wriggles on the spot and up come the worms, in their dozens, to a crofter's applause: a few coins in the grass.", {"money": 32 * 75}, at)
    place(at, 330, 190)


# ----------------------------------------------------------------------------------------------------------------
# 9. The Scalloway road: Lerwick west over the hill to the old capital of Shetland, and on to the Mainland
def scalloway_road():
    zid = "scalloway_road"
    at = zid
    z = scaffold(zid, "The Scalloway Road", 56, 44, "route_coast", WX_COAST, "coast", 80, seed=111)
    z.rect(3, 3, 50, 38, ".")
    z.scatter(3, 3, 50, 38, "R", 50, 112, only=".")
    link(z, "east", 20, "lerwick", "west", 20)
    link(z, "west", 29, "shetland_mainland", "east", 28)
    path(z, [(3, 28), (20, 28), (20, 19), (52, 19)], "#", 3)
    # the harbour at Scalloway, below the castle
    z.rect(3, 36, 50, 5, "$"); z.rect(3, 35, 50, 1, "w"); z.rect(14, 32, 12, 3, ":")
    z.prop("boat", 8, 38, variant=0); z.prop("boat", 20, 39, variant=1); z.prop("boat", 36, 38, variant=0); z.prop("bollard", 15, 34); z.prop("bollard", 24, 34)
    z.building(28, 25, 8, 5, "stone", "Scalloway Castle"); z.rect(28, 30, 8, 1, ":")
    z.prop("flagpole", 37, 28)
    # Tingwall: the loch and the Law Ting Holm
    z.rect(36, 4, 15, 10, "w"); z.rect(37, 5, 13, 8, "~"); z.rect(42, 8, 3, 3, "s"); z.prop("standing_stone", 43, 9)
    plaque(z, 33, 24, "w55_sc_scalloway_castle", "Scalloway Castle",
           "SCALLOWAY CASTLE. Built in 1600 by Patrick Stewart, Earl of Orkney and Lord of Shetland, who was not much loved for how he raised the money, and who was executed in 1615. The castle stands above the harbour at what was, until 1708, the capital of Shetland. It has a roof of grey sky and walls of very stubborn stone.")
    plaque(z, 17, 31, "w55_sc_shetland_bus", "The Shetland Bus",
           "THE SHETLAND BUS. In the war years, Norwegian crews ran small fishing boats from Shetland across the North Sea in the winter dark, landing agents and arms for the Norwegian resistance and bringing refugees back. A good part of that traffic ran from Scalloway, and the quay here is where the story is told.")
    plaque(z, 40, 15, "w55_sc_tingwall", "Tingwall",
           "TINGWALL. The word means 'the field of the assembly', Norse for a place where people met to make laws. The islet in the loch here, the Law Ting Holm, was where Shetland's law-makers met for centuries, and it is joined to the shore by a causeway. Parliament, Shetland style: a loch, a gale and everyone talking at once.")
    z.sign(22, 20, "THE LERWICK ROAD. The A970 runs over the hill and down to Scalloway, the old capital. It is a short road in miles and a long one in weather, since the weather on one side is never the weather on the other.")
    scatter_props(z, "bush", 3, 3, 50, 38, 8, 113, avoid=("."))
    grass_patches(z, [(24, 4, 8, 12), (4, 20, 12, 6), (40, 22, 12, 9), (4, 10, 12, 6), (36, 30, 12, 3), (24, 22, 4, 4)])
    z.d["spawn"] = [5, 29]
    chat(z, "sca_fisher", "fisherman_north", 24, 33, "Quay Fisherman", ["Scalloway has the fish market, and the fish market has the fishermen, and the fishermen have all the opinions. I will not tell you which ones are right.",
         "Mòran taing, they say in the west. Here we say 'tank you'. It is the same, only more windy."], "down", "still")
    chat(z, "sca_bus", "villager_3", 17, 33, "Memorial Volunteer", ["The Shetland Bus is a proper story. Small boats, long nights, men who could have stayed at home. My grandfather said nothing about it. I am told that was the point.",
         "Ask at the museum if you want the proper telling. I only know the bit I have been allowed to."], "down", "still")
    chat(z, "sca_castle", "tour_guide", 31, 31, "Castle Guide", ["Patrick Stewart built this castle with forced labour and a lot of timber. He did not get to enjoy it for long. History is not always kind to men with a good eye for a view.",
         "It was the capital of Shetland until 1708. After that, Lerwick took over, and Scalloway has been getting its own back ever since, mostly at the fish market."], "left", "still")
    chat(z, "sca_pony", "farmer", 46, 24, "Pony Keeper", ["Shetland ponies are small, hardy and thoroughly aware of both. Do not try to tell one what to do. Offer an apple and ask nicely.",
         "They were bred to carry peat and children. They are very good at the first and have strong views on the second."], "left", "still")
    creature_npc(z, "sca_foal", "foalmoor", 44, 22, "A small, very round pony trots up, takes in your pockets, and walks off with its dignity intact.")
    trn(z, "sca_boatman", "Boatman Magnie", "Boatman", "sailor", [("haarling", 80), ("gannetling", 80), ("polartern", 81)],
        18, 24, "up", ["I take the boat out when the weather says I should not. That is called knowing the weather."],
        "A good fight. The weather was on your side.", "A boat is always a bit smaller than the sea. The skill is knowing how much.", 2560)
    trn(z, "sca_knitter", "Knitter Ina", "Knitter", "villager_5", [("foalmoor", 80), ("herdlet", 80), ("crexling", 81), ("hushwing", 80)],
        38, 20, "left", ["Fair Isle, Shetland lace, you name it. I have been knitting since before you were born. You will lose. It is going to be very soft."],
        "Well fought. The wool is on the house.", "There is a pattern in a Shetland jumper for everything. Even the weather has a stitch.", 2600)
    trn(z, "sca_birder", "Birdwatcher Gideon", "Birdwatcher", "birdwatcher", [("puffling", 80), ("cragchough", 80), ("snowbunting", 81)],
        46, 14, "down", ["Whooper swans in winter. If you have never heard a whooper swan, you will not believe it. It sounds like a trumpet that has had a long day."],
        "A good battle. The swans looked away.", "Shetland is the best place in Britain to find birds that are lost. I have a lot in common with them.", 2580)
    trn(z, "sca_lawman", "Lawman Tormod", "Lawman", "poet", [("midgeswarm", 80), ("hushwing", 81), ("herdlet", 80)],
        34, 32, "left", ["I am here for the Law Ting. Someone has to be. Nobody has legislated on that holm for a few centuries, but I like to be ready."],
        "A fair judgement. I will report the finding to the loch.", "The Norse loved a good assembly. They would argue for days and then go home and not change anything. It is a tradition we have kept up.", 2590)
    wild(z, [("foalmoor", 80, 81, 12, {}), ("herdlet", 80, 81, 10, {}), ("puffling", 80, 81, 8, {"time": ["day"]}), ("cragchough", 80, 81, 10, {}),
             ("polartern", 80, 81, 8, {}), ("snowbunting", 80, 81, 8, {"weather": ["frost", "fog"]}), ("midgeswarm", 80, 81, 10, {"weather": ["drizzle", "fog", "clear"]}),
             ("hushwing", 80, 81, 8, {"time": ["night"]}), ("haarling", 80, 81, 8, {"weather": ["fog", "drizzle"]}), ("crexling", 80, 81, 6, {"time": ["dusk", "night"]})])
    wild(z, [("rillotter", 80, 81, 16, {}), ("selklet", 80, 81, 14, {}), ("greyhaul", 80, 81, 12, {}), ("dolphlet", 80, 81, 10, {}),
             ("gannetling", 80, 81, 14, {}), ("plungebeak", 80, 81, 10, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 121)
    poi(z, "cache", at, a, item="bobble_hat_red", line="A hollow in a drystone dyke, and something wrapped in oilcloth. The knitting is excellent.")
    poi(z, "stone", at, b, stat="hp", lore=["Lichen has been at it for a few thousand years and has barely got started.", "The real thing is the Ring of Brodgar, on Orkney: a huge ring of upright slabs on a spit between two lochs."])
    poi(z, "den", at, c, species="foalmoor")
    field(z, "line", "line", "glint", 30, 34, "Something glints in the harbour water. {lead} wades in, makes a few calm passes and fishes it out: a purse, a bit damp.", {"money": 32 * 81}, at)
    place(at, 688, 40)


# ----------------------------------------------------------------------------------------------------------------
# 10. The Machars: Galloway west to Wigtown, Whithorn and the shore of Wigtown Bay, and on to Cairnryan
def the_machars():
    zid = "the_machars"
    at = zid
    z = scaffold(zid, "The Machars", 60, 44, "route_forest", WX_WEST, "coast", 67, seed=121)
    z.rect(3, 3, 54, 38, ".")
    z.scatter(3, 3, 54, 30, "T", 60, 122, only=".")
    z.scatter(3, 3, 54, 30, "P", 40, 123, only=".")
    link(z, "west", 10, "cairnryan", "east", 10)
    link(z, "east", 34, "galloway", "west", 34)
    path(z, [(3, 9), (20, 9), (20, 33), (57, 33)], "#", 3)
    # the Solway shore to the south
    z.rect(3, 38, 54, 3, "$"); z.rect(3, 37, 54, 1, "w"); z.rect(3, 35, 54, 2, "s")
    # Wigtown: the book town
    z.rect(6, 14, 12, 8, ":")
    z.building(5, 12, 6, 3, "cream_render", "Bookshop"); z.building(12, 12, 6, 3, "white_render", "Bookshop"); z.building(5, 22, 6, 3, "slate_cottage", "Bookshop")
    z.building(12, 22, 6, 3, "stone", "Bookshop")
    z.rect(11, 15, 1, 6, ":"); z.rect(18, 15, 2, 2, "#")
    z.prop("bench", 9, 17); z.prop("lamp_post", 13, 17); z.prop("lamp_post", 8, 20)
    # Whithorn: the priory ruin and the cradle of Christianity
    z.building(36, 12, 10, 5, "stone", "Whithorn Priory"); z.rect(36, 17, 10, 1, ":"); z.rect(30, 17, 6, 1, "#")
    z.prop("standing_stone", 48, 14); z.prop("headstone", 34, 20); z.prop("headstone", 38, 21)
    plaque(z, 15, 18, "w55_sc_wigtown", "Wigtown, Scotland's National Book Town",
           "WIGTOWN. In 1998 this small town in Galloway was chosen as Scotland's National Book Town, to give a new life to a place that had lost much of its business. It now has a good dozen bookshops, and a book festival every autumn, in a town of under a thousand people. The books have never once asked for a bigger shop.")
    plaque(z, 40, 18, "w55_sc_ninian", "Whithorn and St Ninian",
           "WHITHORN. Tradition says St Ninian came here about the year 397 and built a stone church, Candida Casa, the White House, which makes Whithorn the cradle of Christianity in Scotland. Pilgrims came to his shrine for centuries after, including, it is said, kings. The priory here is a ruin and the story is still standing.")
    z.sign(24, 32, "THE MACHARS. A broad green peninsula between Wigtown Bay and Luce Bay, the south end of Galloway. It is farmland, bog and long shore, and it has one road in and out and a great many bookshops.")
    z.sign(30, 36, "RED KITES. Reintroduced to Galloway from 2001 after being gone from Scotland for over a century. Watch the sky above the farmland for a forked tail that twists to steer. If you see one, say hello.")
    scatter_props(z, "bush", 3, 3, 54, 34, 12, 124, avoid=("."))
    grass_patches(z, [(24, 14, 10, 10), (40, 22, 14, 8), (4, 26, 12, 6), (24, 24, 8, 6), (46, 4, 10, 6), (24, 4, 12, 3)])
    z.d["spawn"] = [5, 10]
    chat(z, "mac_bookseller", "villager_2", 8, 18, "Bookseller", ["Scotland's National Book Town, and I run the smallest shop in it. A customer buys a book here and I know the title and their dog's name.",
         "Fàilte, and mind the step. The step is the best-read in the building."], "right", "still")
    chat(z, "mac_prior", "pilgrim", 41, 19, "Pilgrim", ["St Ninian came to Whithorn about 397, they say, and built a white stone church. Pilgrims have been walking here ever since. I took the bus for the last bit, to be honest.",
         "Beannachd leibh, that is 'blessings with you', which is what the monks would say as you left. They did not say it if you left with the silverware."], "left", "still")
    chat(z, "mac_kite", "birdwatcher", 30, 25, "Kite Watcher", ["A red kite has a forked tail and a very elegant way of showing off. Back in the nineteenth century they were all but gone. Now you can count them on a good day.",
         "I have watched them since they were let go. I like to think they remember me. They do not."], "right", "still")
    chat(z, "mac_farmer", "farmer", 45, 28, "Machars Farmer", ["The Machars is a place where nothing happens, slowly, in a very green way. I would not live anywhere else, because nowhere else would put up with me.",
         "If a bookshop and a priory and a kite all turn up in one afternoon, that is a good day on the Machars."], "left", "still")
    creature_npc(z, "mac_kite_c", "hootlet", 28, 12, "A hootlet, sleepy and wide-eyed, sits on a book shelf in a window and looks very much like it is reading.")
    trn(z, "mac_reader", "Reader Morven", "Reader", "student", [("natterjack", 67), ("whiffhorn", 67), ("zigzlet", 68)],
        14, 26, "up", ["I have read twelve books this week. I am ahead on points. Shall we?"],
        "A good battle. I will put it in a footnote.", "The trick is to buy more books than you can read, and then be very calm about it.", 2240)
    trn(z, "mac_farmer_t", "Farmer Jock", "Farmer", "farmer", [("thornsow", 68), ("brockling", 67), ("fawnlet", 68), ("stagmor", 68)],
        34, 34, "left", ["This is my road. And my field. And my gate. And you."],
        "That was a fair fight. You may keep the gate.", "A farmer on the Machars has three jobs: sheep, weather and not saying what they think of the council.", 2300)
    trn(z, "mac_pilgrim", "Pilgrim Ailsa", "Pilgrim", "pilgrim", [("martling", 67), ("hootlet", 67), ("pinewraith", 68)],
        44, 20, "left", ["I am walking St Ninian's Way. I have been at it for six days. I need something to push against."],
        "A good battle. Pilgrims are not meant to win.", "A pilgrimage is a long walk with a good excuse. I have both.", 2260)
    trn(z, "mac_angler", "Angler Rory", "Angler", "angler", [("chipgull", 67), ("plungebeak", 68), ("baskling", 67)],
        24, 35, "up", ["Solway tides come in faster than a horse can run. Please do not stand there."],
        "A fair net. I will keep to the shore.", "The Solway has some of the biggest tides in Britain. It is not a place for the unprepared. Or the optimists.", 2250)
    wild(z, [("fawnlet", 67, 69, 10, {"time": ["dawn", "dusk", "day"]}), ("stagmor", 68, 69, 6, {"time": ["dawn", "dusk"]}), ("natterjack", 67, 69, 10, {"weather": ["drizzle", "downpour"]}),
             ("whiffhorn", 67, 69, 8, {}), ("zigzlet", 67, 69, 8, {}), ("thornsow", 67, 69, 8, {}), ("brockling", 67, 69, 8, {"time": ["night", "dusk"]}),
             ("martling", 67, 69, 8, {}), ("hootlet", 67, 69, 8, {"time": ["night"]}), ("flittermouse", 67, 69, 6, {"time": ["night"]}), ("chipgull", 67, 68, 8, {"time": ["dawn", "day"]})])
    wild(z, [("greyhaul", 67, 68, 14, {}), ("plungebeak", 67, 68, 12, {}), ("dolphlet", 67, 68, 10, {}), ("selklet", 67, 68, 10, {}),
             ("chipgull", 67, 68, 12, {}), ("baskling", 67, 68, 8, {}), ("rillotter", 67, 69, 12, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 131, area=(3, 3, 54, 30))
    poi(z, "cache", at, a, item="horseshoe", line="A hollow tree has been used as a post box by someone with no postman.")
    poi(z, "den", at, b, species="natterjack")
    poi(z, "stone", at, c, stat="spd", lore=["Someone has left a single conker on top. Sensible.", "The real thing is Machrie Moor, on the Isle of Arran: a moor full of rings, one with a tall granite slab."])
    field(z, "loft", "loft", "bale", 28, 34, "{lead} takes a run up and lofts the bowl clean over the verge. Where it comes down: a farmer's tip.", {"money": 32 * 69}, at)
    place(at, 480, 625)


ROUTES = {"angus_coast": angus_coast, "trotternish": trotternish, "uig_road": uig_road, "scalloway_road": scalloway_road,
          "the_machars": the_machars}
