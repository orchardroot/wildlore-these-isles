# Wave 55 roads-scotland, part 2: the Highland roads (West Highland Way, Devil's Staircase, Pass of Brander, Rob Roy Way).
import os
from w55_sc_kit import *

OUT = os.path.join(ROOT, "data", "zones")
WX_HIGH_ = {"fog": 30, "drizzle": 28, "downpour": 12, "clear": 14, "gale": 8, "frost": 4, "sunshine": 4}
HEATHER = {"tile": "tall_grass", "colour": "#6e5a5c", "prop": "heather"}


def pond(z, x, y, w, h):
    z.rect(x, y, w, h, "w")
    z.rect(x + 1, y + 1, w - 2, h - 2, "~")


# ----------------------------------------------------------------------------------------------------------------
# 2. The West Highland Way over Rannoch Moor: Loch Lomond north to Glencoe
def west_highland_way():
    zid = "west_highland_way"
    at = zid
    z = scaffold(zid, "The West Highland Way", 60, 48, "route_highlands", WX_HIGH_, "mountain", 70, seed=31)
    z.legend["h"] = HEATHER
    z.rect(3, 3, 54, 42, ".")
    z.scatter(3, 3, 54, 42, "R", 60, 32, only=".")
    z.scatter(3, 3, 54, 42, "P", 30, 33, only=".")
    link(z, "west", 20, "glencoe", "east", 52)
    link(z, "south", 40, "loch_lomond", "north", 8)
    path(z, [(3, 19), (39, 19), (39, 45)], "#", 3)
    # lochans of the moor
    pond(z, 12, 5, 12, 8); pond(z, 25, 27, 10, 8); pond(z, 6, 28, 8, 6); pond(z, 46, 8, 8, 6)
    grass_patches(z, [(6, 14, 12, 4), (20, 22, 12, 4), (4, 36, 14, 7), (28, 10, 8, 6), (44, 22, 10, 8), (44, 34, 10, 8), (24, 38, 12, 6)])
    for (x, y, w, h) in [(6, 14, 12, 4), (44, 22, 10, 8), (44, 34, 10, 8)]:
        z.rect(x, y, w, h, "h")
    # Bridge of Orchy: a hotel, a station cottage, a bridge
    z.building(46, 14, 8, 4, "white_render", "Bridge of Orchy Hotel")
    z.rect(46, 18, 8, 1, ":"); z.rect(42, 18, 4, 1, "#")
    z.building(46, 30, 5, 3, "slate_cottage")
    z.prop("bench", 45, 19); z.prop("lamp_post", 54, 19)
    plaque(z, 36, 18, "w55_sc_whw", "The West Highland Way",
           "THE WEST HIGHLAND WAY. Ninety-six miles from Milngavie, on the edge of Glasgow, to Fort William, and the first official long-distance path in Scotland, opened in 1980. It follows drove roads, military roads and old railway ground, so mostly somebody else has already done the hard thinking about where to put your feet.")
    plaque(z, 38, 32, "w55_sc_rannoch", "Rannoch Moor",
           "RANNOCH MOOR. The railway crossed this moor in 1894. The ground was too soft for an ordinary embankment, so the engineers floated the track on mattresses of brushwood, earth and ash, and the trains have been running over a bog ever since. Nobody has been brave enough to ask it to stop.")
    z.sign(40, 18, "THE BLACK MOUNT. Heather, rock and a great deal of sky. Red deer come down here in winter. In summer the midges do the same, in greater numbers, and with less dignity.")
    z.sign(22, 20, "DROVERS' ROAD. Cattle were walked south along this line to the markets for centuries. The drovers' dogs found their own way home, which is more than can be said for most walkers.")
    scatter_props(z, "rock", 3, 3, 54, 42, 16, 34, avoid=("."))
    scatter_props(z, "bush", 3, 3, 54, 42, 12, 35, avoid=("."))
    z.d["spawn"] = [5, 20]
    chat(z, "whw_walker", "hiker", 14, 22, "Way Walker", ["Milngavie to Fort William, ninety-six miles. Everyone tells you the Rannoch Moor day is the long one. Everyone is right and nobody tells you what to do about it.",
         "Mòran taing for the biscuit, by the way. That is how you say 'many thanks'. I learned it three days ago."], "right", "still")
    chat(z, "whw_hotelier", "villager_2", 50, 19, "Hotelier", ["We get a lot of boots at the door and a lot of mud on the carpet. I wouldn't change it.",
         "Last week a man asked me if the moor was always this empty. I said it is never empty. It is just very quiet about who is in it."], "down", "still")
    chat(z, "whw_stalker", "ghillie", 30, 25, "Deer Watcher", ["Red deer on the hill. Look for the ones that do not move. They have seen you and do not care.",
         "They come down in winter, when the snow stays on the tops. In summer they go back up to get away from the midges, which tells you how bad the midges are."], "left", "still")
    chat(z, "whw_signalman", "steelworker", 44, 24, "Railway Walker", ["I walk the line by the railway when I can. The track floats on the moor. I like to think of it as a very long boat.",
         "The line over the moor was built floating on brushwood. The bit I like is that nobody told the brushwood it was a foundation."], "down", "still")
    creature_npc(z, "whw_stag", "stagmor", 26, 14, "A stag stands on the skyline, doing a very good impression of a statue of a stag.")
    creature_npc(z, "whw_hare", "snowhare", 18, 36, "A mountain hare sits up, considers you, and decides the nearest rock is the safest place in Scotland.")
    trn(z, "whw_walker_t", "Hillwalker Struan", "Hillwalker", "hillwalker", [("kidgruff", 70), ("midgie", 70), ("martling", 70)],
        18, 21, "down", ["Munros are a state of mind. I am in a state. Fancy a battle?"],
        "Well walked. I will go and have a sit on the moor.", "I have done the Way three times, and every time it is longer than the last. The moor insists on it.", 2300)
    trn(z, "whw_drover", "Drover Callum", "Drover", "farmer", [("herdlet", 70), ("kidgruff", 70), ("stagmor", 71), ("wildkit", 70)],
        32, 20, "up", ["My grandfather walked cattle over this moor. I walk Keepers into the ground."],
        "A fair drive. I will tip my cap and my dog.", "A good drover knows three things: the road, the weather and when to stop talking. I am working on the third.", 2340)
    trn(z, "whw_guide", "Guide Eilidh", "Guide", "tour_guide", [("ptarmlet", 70), ("eaglet", 71), ("snowhare", 70)],
        40, 28, "left", ["Welcome to Rannoch Moor. I am contractually obliged to say it is one of the last great wild places in these islands. Also, it is true."],
        "That was a good one. I will put it on the leaflet.", "If the cloud comes down on the moor, stop. The moor was here first and it will wait for you.", 2360)
    trn(z, "whw_photographer", "Photographer Kirsty", "Photographer", "explorer", [("midgie", 71), ("snowhare", 70), ("fawnlet", 70), ("hootlet", 70)],
        10, 8, "down", ["Hold still. I am waiting for the light. I have been waiting since Tuesday. Battle while I wait?"],
        "Lovely. I got the shot. You are in it, sorry.", "The light on the moor lasts about four minutes. I spend the other eleven hours in a layby.", 2320)
    wild(z, [("wildkit", 70, 71, 10, {}), ("eaglet", 70, 71, 8, {"time": ["day", "dawn"]}), ("midgie", 70, 71, 12, {"weather": ["drizzle", "fog", "clear"]}),
             ("stagmor", 70, 71, 8, {"time": ["dawn", "dusk"]}), ("fawnlet", 70, 71, 8, {}), ("snowhare", 70, 71, 10, {"weather": ["frost", "fog"]}),
             ("kidgruff", 70, 71, 8, {}), ("hootlet", 70, 71, 8, {"time": ["night"]}), ("sphagnet", 70, 71, 6, {"weather": ["drizzle", "downpour"]}),
             ("ptarmlet", 70, 71, 8, {"time": ["day", "dawn", "dusk"]})])
    wild(z, [("dipling", 70, 71, 20, {}), ("rillotter", 70, 71, 16, {}), ("bradan", 70, 71, 16, {}), ("heronarch", 70, 71, 10, {}),
             ("stalklet", 70, 71, 12, {}), ("spatelord", 70, 71, 6, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 41)
    poi(z, "cache", at, a, item="flask_of_tea", line="A flask-sized tin under a flat stone, tied with garden twine. Someone's emergency tea. You are an emergency.")
    poi(z, "stone", at, b, stat="hp", lore=["Sheep have rubbed one side smooth. Even the sheep come here.", "The real thing is the Ring of Brodgar, on Orkney: a huge ring of upright slabs on a spit between two lochs."])
    poi(z, "den", at, c, species="caperling")
    field(z, "glint", "line", "glint", 24, 29, "Something glints in a lochan. {lead} wades in, makes a few calm passes and fishes it out: a walker's purse, a bit damp.", {"money": 32 * 71}, at)
    place(at, 480, 420)


# ----------------------------------------------------------------------------------------------------------------
# 3. The Devil's Staircase and Kinlochleven: Glencoe west to Fort William
def devils_staircase():
    zid = "devils_staircase"
    at = zid
    z = scaffold(zid, "The Devil's Staircase", 56, 52, "route_highlands", WX_HIGH_, "mountain", 70, seed=41)
    z.rect(3, 3, 50, 46, ".")
    z.scatter(3, 3, 50, 46, "R", 140, 42, only=".")
    z.scatter(3, 3, 50, 46, "P", 50, 43, only=".")
    link(z, "west", 40, "fort_william", "east", 8)
    link(z, "east", 10, "glencoe", "west", 2)
    # the zigzag
    path(z, [(3, 39), (20, 39), (20, 33), (32, 33), (32, 27), (20, 27), (20, 21), (32, 21), (32, 15), (20, 15), (20, 9), (52, 9)], "#", 3)
    z.rect(36, 18, 14, 9, "w"); z.rect(37, 19, 12, 7, "~")  # the Blackwater Reservoir
    z.prop("bench", 35, 12)
    # Kinlochleven below
    z.building(6, 43, 9, 4, "stone", "Ice Factor")
    z.building(18, 44, 5, 3, "white_render"); z.building(26, 44, 5, 3, "slate_cottage"); z.building(34, 43, 6, 4, "cream_render", "Village Hall")
    z.rect(6, 47, 36, 1, ":"); z.rect(10, 41, 3, 2, ":")
    z.prop("lamp_post", 17, 42); z.prop("lamp_post", 33, 42); z.prop("post_box", 31, 47)
    plaque(z, 15, 38, "w55_sc_staircase", "The Devil's Staircase",
           "THE DEVIL'S STAIRCASE. At about 550 metres the highest point on the West Highland Way, a zigzag up out of Kinlochleven towards Glencoe. The name is said to come from the soldiers who built the military road over it in the 1750s. They had a view of the Devil's own handiwork and no pension for it.")
    plaque(z, 30, 42, "w55_sc_kinlochleven", "Kinlochleven",
           "KINLOCHLEVEN. The village grew up round an aluminium smelter that opened in 1909 and ran on hydro-electric power from the Blackwater Reservoir above it. The smelter closed in the 1990s. The pipes still come down the hill, and the old works now hold an indoor ice-climbing centre.")
    z.sign(24, 20, "THE MAMORES. A long ridge of high hills to the south, a dozen Munros one after another. Hillwalkers do the whole ridge in a day and then tell everyone about it in the pub for a year.")
    scatter_props(z, "rock", 3, 3, 50, 46, 18, 44, avoid=("."))
    z.d["spawn"] = [5, 40]
    grass_patches(z, [(4, 28, 10, 8), (36, 28, 14, 10), (22, 3, 10, 5), (40, 3, 10, 5), (4, 10, 12, 8), (24, 36, 6, 3)])
    chat(z, "dev_walker", "hiker", 24, 36, "Weary Walker", ["The staircase is the highest point, and it is not even the hardest bit. The hardest bit is the sign that says how far to go.",
         "I am going to Fort William. I have said that for three days. It still sounds like a joke."], "left", "still")
    chat(z, "dev_climber", "fell_runner", 8, 38, "Ice Climber", ["There is an indoor ice wall in the old works. It is the one place in Scotland where you can be cold on purpose and pay for it.",
         "Slàinte mhath, that is 'good health'. We say it with a mug of tea here."], "right", "still")
    chat(z, "dev_hydro", "steelworker", 40, 12, "Dam Keeper", ["The smelter needed a lot of power, so they built a dam up here and sent the water down in pipes. You can still see where it ran.",
         "The works are gone, but the loch is still full. The hills have a long memory for water."], "down", "still")
    chat(z, "dev_cafe", "villager_6", 24, 46, "Cafe Owner", ["Everyone comes in off the Way looking like they have been through a hedge. A bacon roll fixes about half of them.",
         "The Staircase is not as bad as it sounds. It is worse. But it is over quickly, and the cake is good."], "up", "still")
    trn(z, "dev_rescue", "Rescue Volunteer Mairi", "Rescue Volunteer", "fell_runner", [("eaglet", 71), ("snowhare", 71), ("kidgruff", 71)],
        26, 31, "up", ["Mountain rescue. We turn out at three in the morning for people who have not read the forecast. Have you read the forecast?"],
        "Well fought. Do read the forecast.", "We have helped a lot of people down this hill. They always say they were fine. They always say it while being carried.", 2380)
    trn(z, "dev_ghillie", "Ghillie Alasdair", "Ghillie", "ghillie", [("stagmor", 71), ("fawnlet", 71), ("wildkit", 72), ("martling", 71)],
        28, 25, "left", ["The hill belongs to the deer and the weather. I am here to point out which is which."],
        "Aye, that was well played. You can have the hill.", "The Devil's Staircase is the one place on the Way where the Devil gets a vote.", 2400)
    trn(z, "dev_aluminium", "Foreman Dougie", "Foreman", "steelworker", [("ptarmlet", 71), ("midgie", 71), ("hootlet", 71)],
        44, 10, "left", ["I worked in the old smelter, thirty years of heat and noise. Now I run the dam tours. It is cooler, and the noise is mostly me."],
        "That was a fair fight. I have had worse in the canteen.", "They made aluminium here by the ton. It went to aeroplanes. Nothing here has gone to an aeroplane since, which suits the hens.", 2420)
    wild(z, [("eaglet", 71, 72, 10, {"time": ["day", "dawn"]}), ("snowhare", 71, 72, 10, {"weather": ["frost", "fog"]}), ("kidgruff", 71, 72, 10, {}),
             ("wildkit", 71, 72, 10, {}), ("midgie", 71, 72, 10, {"weather": ["drizzle", "fog", "clear"]}), ("stagmor", 71, 72, 8, {"time": ["dawn", "dusk"]}),
             ("ptarmlet", 71, 72, 8, {"time": ["day", "dawn", "dusk"]}), ("hootlet", 71, 72, 8, {"time": ["night"]}), ("fawnlet", 71, 72, 8, {}),
             ("martling", 71, 72, 6, {})])
    wild(z, [("dipling", 71, 72, 20, {}), ("rillotter", 71, 72, 16, {}), ("bradan", 71, 72, 16, {}), ("heronarch", 71, 72, 10, {}),
             ("spatelord", 71, 72, 8, {}), ("stalklet", 71, 72, 10, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 51)
    poi(z, "cache", at, a, item="hag_stone", line="A hollow behind a rock, and a lunchbox in the hollow. Whoever left it knew what they were doing, and was not coming back for it.")
    poi(z, "camp", at, b, names=[["Lamper Ged", "Lamper"], ["Poacher Rab", "Poacher"]], party=["wildkit", "kidgruff", "snowhare"],
        line="You didn't see us. We didn't see you. Except now we have.", money=300 + 40 * 72, item="silver_snare")
    poi(z, "stone", at, c, stat="spd", lore=["It is cold, and it hums very faintly, the way a fridge does.", "The real thing is Machrie Moor, on the Isle of Arran: a moor full of rings, one with a tall granite slab."])
    field(z, "topple", "topple", "dead_trunk", 36, 31, "{lead} leans into the leaning trunk and it comes down with a thump, right across the burn, which makes a bridge. On the far side, a few coins in a tin.", {"money": 32 * 72}, at)
    place(at, 465, 368)


# ----------------------------------------------------------------------------------------------------------------
# 4. The Pass of Brander: Loch Lomond to Oban by Rest and Be Thankful, Loch Awe and the foot of Ben Cruachan
def pass_of_brander():
    zid = "pass_of_brander"
    at = zid
    z = scaffold(zid, "The Pass of Brander", 60, 52, "route_highlands", WX_HIGH_, "forest", 69, seed=51)
    z.rect(3, 3, 54, 46, ".")
    z.scatter(3, 3, 54, 46, "P", 120, 52, only=".")
    z.scatter(3, 3, 54, 46, "T", 40, 53, only=".")
    link(z, "north", 30, "loch_lomond", "south", 30)
    link(z, "south", 30, "oban", "north", 16)
    path(z, [(29, 3), (29, 18), (11, 18), (11, 34), (29, 34), (29, 48)], "#", 3)
    # Ben Cruachan in the north-west: a cliff face of its own
    z.rect(4, 4, 14, 9, "^"); z.rect(4, 13, 14, 2, "R"); z.rect(18, 4, 3, 8, "R")
    # Loch Awe, east, with Kilchurn Castle on its point
    z.rect(38, 9, 17, 28, "w"); z.rect(39, 10, 15, 26, "~"); z.rect(36, 28, 3, 3, "s")
    z.building(33, 22, 5, 4, "stone", "Kilchurn Castle"); z.rect(31, 24, 2, 2, "#")
    z.prop("boat", 44, 30, variant=0)
    # Rest and Be Thankful, a stone seat at the top of the first climb
    z.prop("bench", 27, 12); z.prop("standing_stone", 26, 14)
    plaque(z, 33, 16, "w55_sc_rest", "Rest and Be Thankful",
           "REST AND BE THANKFUL. At the top of the pass out of Glen Croe is a stone seat with those words cut on it, put up by the soldiers who built the military road here under Major William Caulfeild. The modern road still slides off the hill in heavy rain, so the name has never been more useful.")
    plaque(z, 33, 40, "w55_sc_brander", "The Pass of Brander",
           "THE PASS OF BRANDER. In 1308 Robert the Bruce, fighting the MacDougalls of Lorn, held the narrow pass between Ben Cruachan and Loch Awe and had his archers on the slopes above it. Rocks and arrows from above did the rest, as they have in Scotland on more than one occasion.")
    z.sign(24, 36, "CRUACHAN. The 'hollow mountain': a power station was blasted out of the inside of Ben Cruachan and opened in 1965. At night, water is pumped up to a loch high above, and in the day it runs back down through the turbines. The mountain is a giant battery with sheep on it.")
    z.sign(36, 29, "KILCHURN CASTLE. A tower house on a point of Loch Awe, begun about 1450 by Sir Colin Campbell of Glenorchy. It was left to fall into ruin in the eighteenth century, and has been the most photographed thing on the loch ever since.")
    grass_patches(z, [(14, 22, 14, 8), (34, 40, 18, 6), (14, 38, 12, 8), (40, 4, 14, 4), (6, 22, 3, 14)])
    scatter_props(z, "rock", 3, 3, 54, 46, 14, 54, avoid=("."))
    scatter_props(z, "bush", 3, 3, 54, 46, 16, 55, avoid=("."))
    z.d["spawn"] = [30, 5]
    chat(z, "brn_walker", "hiker", 26, 16, "Pass Walker", ["Rest and be thankful, it says on the stone. I rested. I am thankful. I would like to be thankful somewhere warmer.",
         "The old military road goes up the hill in loops. Soldiers built it, and I think they built it that way on purpose to make us suffer less than they did."], "right", "still")
    chat(z, "brn_ranger", "villager_2", 36, 33, "Loch Awe Ranger", ["Ospreys nest round the loch in summer. If one drops a fish at your feet, it is a compliment. Do not argue.",
         "The loch is about twenty-five miles long, the longest freshwater loch in Scotland, if you do not count the ones with monsters."], "left", "still")
    chat(z, "brn_hydro", "steelworker", 24, 30, "Power Station Guide", ["There is a power station inside that mountain. Sixty years in there and it has never once been rained on.",
         "Beannachd leibh, that is 'blessings with you', which is what we say when you leave and the lights are still on."], "right", "still")
    chat(z, "brn_historian", "tour_guide", 31, 41, "Battle Guide", ["Some people say Bruce won the Pass of Brander without ever needing to fight the main force. I say he won it with a good map and a better ambush.",
         "Nobody built a visitor centre, and I think that is the best compliment a battlefield can get."], "left", "still")
    trn(z, "brn_stalker", "Stalker Hamish", "Stalker", "ghillie", [("stagmor", 69), ("fawnlet", 69), ("lekling", 70), ("brockling", 69)],
        15, 20, "right", ["Quiet. There is a stag on the hill. He has heard worse than you, but not often."],
        "Well hunted, if that is the word. The stag has gone.", "You do not stalk a deer. You let the hill do it for you.", 2260)
    trn(z, "brn_angler", "Angler Morag", "Angler", "angler", [("rillotter", 69), ("heronarch", 70), ("ospret", 70)],
        37, 12, "left", ["It is a very long loch. I have been fishing one end of it since breakfast."],
        "That is me beaten. I will be at the other end of the loch.", "A good angler is nine parts patience and one part knowing who is looking at their sandwich.", 2270)
    trn(z, "brn_forester", "Forester Ian", "Forester", "farmer", [("pinewraith", 70), ("martling", 70), ("caperling", 69), ("hootlet", 69)],
        20, 36, "up", ["These are working woods, so mind the lorries. And mind me. Mostly me."],
        "Well, that has felled me. I will plant another of you.", "A tree takes forty years to grow and ten minutes to cut. The maths has always been on the saw's side.", 2280)
    trn(z, "brn_piper", "Piper Isla", "Piper", "piper", [("stagmor", 70), ("midgie", 70), ("ospret", 70)],
        11, 44, "right", ["I play the pipes on the old road. The tune is for the deer. They have not complained."],
        "A good battle. A better tune. I will play it for you at the bridge.", "A pipe tune is a story you cannot talk back to. That is its whole appeal.", 2250)
    wild(z, [("fawnlet", 69, 70, 10, {"time": ["dawn", "dusk", "day"]}), ("stagmor", 69, 70, 8, {"time": ["dawn", "dusk"]}), ("lekling", 69, 70, 8, {}),
             ("pinewraith", 69, 70, 10, {"time": ["dusk", "night"]}), ("brockling", 69, 70, 8, {"time": ["night", "dusk"]}), ("martling", 69, 70, 10, {}),
             ("hootlet", 69, 70, 8, {"time": ["night"]}), ("midgie", 69, 70, 8, {"weather": ["drizzle", "fog", "clear"]}), ("wildkit", 69, 70, 6, {}),
             ("ospret", 69, 70, 8, {"time": ["day"]}), ("caperling", 69, 70, 8, {})])
    wild(z, [("rillotter", 69, 70, 20, {}), ("dipling", 69, 70, 16, {}), ("ospret", 69, 70, 10, {}), ("heronarch", 69, 70, 10, {}),
             ("bradan", 69, 70, 16, {}), ("stalklet", 69, 70, 10, {}), ("minkshade", 69, 70, 8, {"time": ["dusk", "night"]})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 61)
    poi(z, "stone", at, a, stat="atk", lore=["You put a hand on it. It is older than your whole family tree, put together.", "The real thing is the Clava Cairns, near Inverness: ring cairns inside circles of standing stones, among old beech trees."])
    poi(z, "cache", at, b, item="rowan_sprig", line="A hollow in the old tree, and something wrapped in oilcloth.")
    poi(z, "den", at, c, species="snowhare")
    field(z, "mend", "mend", "wall_gap", 12, 30, "{lead} nudges the loose stones of the drystone wall back into line, one at a time. The farmer leaves a flask of tea on the post.", {"item": "flask_of_tea", "qty": 1}, at)
    place(at, 455, 440)


# ----------------------------------------------------------------------------------------------------------------
# 5. The Rob Roy Way: the Trossachs, Balquhidder and Strathearn, from the Central Belt to Dundee
def rob_roy_way():
    zid = "rob_roy_way"
    at = zid
    z = scaffold(zid, "The Rob Roy Way", 64, 52, "route_forest", WX_HIGH_, "forest", 69, seed=61)
    z.rect(3, 3, 58, 46, ".")
    z.scatter(3, 3, 58, 46, "P", 70, 62, only=".")
    z.scatter(3, 3, 58, 46, "T", 70, 63, only=".")
    link(z, "south", 20, "central_belt", "north", 36)
    link(z, "east", 12, "dundee", "west", 10)
    path(z, [(19, 47), (19, 28), (36, 28), (36, 11), (60, 11)], "#", 3)
    # Loch Katrine in the north-west with the steamship at her pier
    z.rect(5, 4, 20, 13, "w"); z.rect(6, 5, 18, 11, "~"); z.rect(10, 17, 8, 1, "s")
    z.prop("boat", 14, 9, variant=1); z.prop("bench", 24, 18)
    # Balquhidder kirk and the clan graves, mid-south
    z.building(40, 34, 6, 4, "stone", "Balquhidder Kirk"); z.rect(40, 38, 6, 1, ":")
    z.prop("standing_stone", 48, 35); z.prop("standing_stone", 50, 37)
    # Doune Castle on the way to Strathearn
    z.building(46, 16, 8, 5, "stone", "Doune Castle"); z.rect(46, 21, 8, 1, ":"); z.rect(36, 21, 10, 1, "#")
    z.prop("flagpole", 44, 20)
    plaque(z, 17, 20, "w55_sc_katrine", "Loch Katrine",
           "LOCH KATRINE. Since 1859 this loch has supplied Glasgow with its drinking water, piped some twenty-six miles to the city, and it was opened by Queen Victoria. A steamship, the Sir Walter Scott, has carried visitors on the loch since 1900, and is still sailing. Glasgow has never forgotten who to thank.")
    plaque(z, 43, 38, "w55_sc_rob_roy", "Rob Roy at Balquhidder",
           "ROB ROY MACGREGOR. Born in 1671, a cattle dealer turned outlaw and folk hero who spent his last years at Balquhidder. He is buried in the kirkyard here, and the grave is the thing visitors come to see. Walter Scott gave him a novel in 1817 and the legend never looked back.")
    z.sign(41, 22, "DOUNE CASTLE. A fourteenth-century courtyard castle built for Robert Stewart, Duke of Albany. It has played a castle in a great many films, and a very silly one about a grail. It has never once complained about the extras.")
    z.sign(22, 29, "THE ROB ROY WAY. About eighty miles from Drymen, on the edge of the Trossachs, to Pitlochry, through glens, lochs and places that have had a bad deal from the weather and a good one from Walter Scott.")
    grass_patches(z, [(6, 22, 10, 8), (24, 32, 10, 8), (42, 24, 14, 6), (8, 36, 10, 8), (26, 4, 8, 10), (50, 40, 8, 6)])
    scatter_props(z, "rock", 3, 3, 58, 46, 12, 64, avoid=("."))
    scatter_props(z, "bush", 3, 3, 58, 46, 18, 65, avoid=("."))
    z.d["spawn"] = [20, 46]
    chat(z, "rrw_boatman", "sailor", 12, 18, "Loch Boatman", ["The steamship has been sailing since 1900. I keep telling it to retire and it keeps coming in on time.",
         "Glasgow drinks this loch. Every time a Glaswegian pours a glass of water, a Trossachs sheep gets a bit more famous."], "down", "still")
    chat(z, "rrw_minister", "pilgrim", 44, 39, "Kirk Visitor", ["Rob Roy is buried here with his wife and two of his sons. The stone is plain. He would have approved: he did not like a fuss, unless it was the other side's.",
         "There is a very good tearoom down the road. I would put it on the list ahead of the grave, to be honest."], "up", "still")
    chat(z, "rrw_film", "festival_goer", 40, 22, "Film Buff", ["They shot a silly film about a grail here. A very silly film. The coconuts were not the castle's idea.",
         "It is a fine castle. It has been in more films than I have, and it has not once asked for a better trailer."], "left", "still")
    chat(z, "rrw_walker", "hiker", 22, 31, "Way Walker", ["Drymen to Pitlochry on foot. I am doing it in my own time, which is a polite way of saying I stop for tea.",
         "Fàilte to the Trossachs. That is 'welcome'. Walter Scott gave the place a reputation. It has been living off it since."], "right", "still")
    creature_npc(z, "rrw_osprey", "ospret", 30, 6, "An osprey hangs over the water, then drops like a dropped umbrella and comes up with lunch. It looks at you as if you had not seen anything.")
    trn(z, "rrw_clansman", "Clansman Ruairidh", "Clansman", "piper", [("raidtail", 69), ("thistlet", 70), ("grizzlet", 69)],
        28, 30, "left", ["I am a MacGregor. I do not say that lightly. I say it with a very large cattle-raiding grin."],
        "A fair fight. The cattle can stay.", "The MacGregor name was banned, on and off, for generations. We kept it on the inside.", 2260)
    trn(z, "rrw_angler", "Angler Fiona", "Angler", "angler", [("rillotter", 69), ("heronarch", 69), ("stalklet", 70)],
        26, 12, "right", ["Fishing on the loch is a quiet business. Do you mind?"],
        "A fair net. I will go and fish elsewhere. Possibly in Fife.", "A good loch is always quiet. A very good loch is quiet and has a decent cafe.", 2230)
    trn(z, "rrw_stalker", "Stalker Duncan", "Stalker", "ghillie", [("fawnlet", 69), ("brockling", 70), ("hootlet", 69), ("sootwing", 70)],
        46, 30, "down", ["Wildlife survey. If I hold still long enough, a squirrel will show up. It has been three hours."],
        "That is me caught. The squirrel is laughing.", "Red squirrels are about the only thing in Scotland smaller than a midge that anyone is happy to see.", 2280)
    trn(z, "rrw_historian", "Historian Margaret", "Historian", "poet", [("swiftlet", 69), ("starlet", 69), ("bobbin", 70), ("flittermouse", 70)],
        54, 12, "left", ["I give talks on Rob Roy. Everyone asks if he was a villain or a hero. I say he was a cattle dealer with a very good press agent."],
        "Well done. I shall add you to the footnotes.", "Sir Walter Scott did more for the Trossachs than anyone with a bulldozer ever could. People came for the verse and stayed for the scones.", 2290)
    wild(z, [("thistlet", 69, 70, 10, {}), ("raidtail", 69, 70, 10, {}), ("grizzlet", 69, 70, 10, {}), ("starlet", 69, 70, 10, {"time": ["day", "dawn"]}),
             ("swiftlet", 69, 70, 8, {"time": ["day"]}), ("sootwing", 69, 70, 8, {"time": ["day", "dusk"]}), ("bobbin", 69, 70, 8, {}),
             ("flittermouse", 69, 70, 8, {"time": ["night"]}), ("hootlet", 69, 70, 8, {"time": ["night"]}), ("brockling", 69, 70, 8, {"time": ["night", "dusk"]}),
             ("strutcoo", 69, 70, 6, {})])
    wild(z, [("stalklet", 69, 70, 18, {}), ("rillotter", 69, 70, 16, {}), ("dipling", 69, 70, 16, {}), ("heronarch", 69, 70, 12, {}),
             ("minkshade", 69, 70, 8, {"time": ["dusk", "night"]}), ("pierlord", 69, 70, 8, {})], "water")
    verify(z)
    z.save(OUT + "/" + zid + ".json")
    a, b, c = spots(z, 3, 71)
    poi(z, "cache", at, a, item="burns_tam", line="Behind the rock there is a gap, and in the gap there is a lunchbox. Inside, a bonnet, folded very neatly.")
    poi(z, "stone", at, b, stat="lore", lore=["Lichen has been at it for a few thousand years and has barely got started.", "The real thing is Callanish, on the Isle of Lewis: a cross of standing stones about 5,000 years old."])
    poi(z, "camp", at, c, names=[["Poacher Dilys", "Poacher"], ["Trapper Moira", "Trapper"]], party=["raidtail", "thistlet", "brockling"],
        line="This is a private camp. Private as in 'mind your own'.", money=300 + 40 * 70, item="cream_tea")
    field(z, "line", "line", "glint", 15, 17, "Something glints in the shallows. {lead} wades in, makes a few calm passes and fishes it out: a tin of toffee, a bit damp.", {"money": 32 * 70}, at)
    place(at, 585, 445)


ROUTES = {"west_highland_way": west_highland_way, "devils_staircase": devils_staircase, "pass_of_brander": pass_of_brander,
          "rob_roy_way": rob_roy_way}
