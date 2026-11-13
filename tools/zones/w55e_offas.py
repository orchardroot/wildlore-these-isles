# Road 10 (wave 55): Offa's Dyke Path, the northern end. Shrewsbury (west side) over the border by Welshpool, Chirk and the
# Pontcysyllte Aqueduct to Llangollen (south side). A border crossing: England to Wales. Shrewsbury and Llangollen both
# open at the Urban Stone (data/objectives.json), so there is no gate.
from w55_lib import *

ZID = "offas_dyke"
W, H = 64, 60
FLOOR = 22   # Shrewsbury 21, Llangollen 25


def build():
    z = route_zone(ZID, "Offa's Dyke", W, H, "north_wales", "route_forest", "valley", FLOOR,
                   {"drizzle": 32, "clear": 20, "fog": 14, "downpour": 12, "gale": 8, "sunshine": 14})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#7b8c4c"},
        "m": {"tile": "grass", "colour": "#879a52"},
        "q": {"tile": "tall_grass", "colour": "#7a8947", "prop": "short"},
        "h": {"tile": "tall_grass", "colour": "#6e5a5c", "prop": "heather"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "c": {"tile": "path", "colour": "#b9a98a"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(61, 45, 3, 3), (31, 0, 3, 3)])
    z.scatter(0, 0, W, H, "P", 28, 8, only="T")
    # --- Castell Dinas Bran's hill in the north-west, the Berwyn foothills, flatter farmland round Welshpool
    hills(z, [(12, 10, 5, 12), (50, 12, 3, 12)])
    for (cx, cy, rx, ry) in [(12, 10, 7, 4), (50, 10, 6, 3), (20, 50, 6, 3)]:
        blob(z, cx, cy, rx, ry, "h", only="g", seed=cx * cy, jitter=0.5)
    for (cx, cy, rx, ry) in [(30, 40, 8, 3), (12, 30, 6, 3), (46, 28, 6, 3)]:
        blob(z, cx, cy, rx, ry, "q", only="g", seed=cx + cy, jitter=0.5)
    for y in range(18, 58):
        for x in range(3, W - 3):
            if z.g[y][x] == "g" and (x * 3 + y * 5) % 4:
                z.set(x, y, "m")
    # --- the valley of the Dee across the north with the aqueduct
    for x in range(3, W - 3):
        y = 13 + int(round(1.2 * math.sin(x / 7.0)))
        z.set(x, y - 1, "w"); z.set(x, y, "~"); z.set(x, y + 1, "w")
    # --- the road
    ROUTE = [(62, 46), (46, 46), (46, 36), (20, 36), (20, 24), (32, 24), (32, 1)]
    road(z, ROUTE, "c", 3)
    # --- the Dyke: a hedge-and-bank line along x = 40, gaps where the road crosses it
    for y in range(3, 58):
        if not (35 <= y <= 37) and z.g[y][40] not in "w~c":
            z.set(40, y, "H"); z.hg[y][40] = max(z.hg[y][40], 1)
    # --- places along the road
    z.building(51, 38, 9, 5, "castle", "Powis Castle")
    z.building(52, 48, 4, 2, "tin_cottage", "Welshpool & Llanfair Halt", show_label=True)
    z.building(6, 28, 10, 5, "castle", "Chirk Castle")
    z.building(8, 4, 6, 4, "castle", "Castell Dinas Bran (ruin)")
    z.building(42, 5, 7, 4, "chapel", "Valle Crucis Abbey (ruin)")
    z.building(22, 8, 4, 3, "tudor", "Plas Newydd", show_label=True)
    z.prop("canal_boat", 24, 13, variant=0); z.prop("canal_boat", 38, 13, variant=0)
    z.prop("standing_stone", 50, 9, variant=1)
    for (x, y) in [(8, 40), (26, 42), (36, 28), (54, 28), (14, 48), (48, 54)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- signs and plaques
    sign(z, 60, 43, "EAST: Shrewsbury and England. WEST: Welshpool, Chirk and Llangollen, and the Dyke. The Dyke is older than any border on a map. It is one of the few borders with a footpath.")
    plaque(z, 43, 33, "w55e_offas_dyke", "Offa's Dyke",
           "A great earthwork bank and ditch built along the Welsh border in the 8th century, probably on the orders of Offa, king of Mercia from 757 to 796. The ditch lies on the Welsh side, the bank on the English, and in places it still stands higher than a man. The Offa's Dyke Path, a National Trail opened in 1971, follows it for 177 miles from Sedbury Cliffs near Chepstow to Prestatyn on the north Wales coast.")
    sign(z, 38, 40, "CROESO I GYMRU. WELCOME TO WALES. Somewhere about here the Dyke and the border part company and then meet again. Nobody has told the sheep.")
    plaque(z, 12, 34, "w55e_chirk", "Chirk Castle",
           "A fortress built for Edward I in the 1290s by Roger Mortimer, to hold the Welsh border after his conquest of Wales. It has been lived in ever since, which makes it unusual among the Marcher castles, most of which fell to ruin. The families who held it made it comfortable, with a long gallery, tapestries and some of the finest wrought iron gates in Britain.")
    sign(z, 26, 26, "CHIRK. A castle, a railway viaduct and a canal aqueduct all within a few hundred yards of the border, each from a different century. Telford built the canal one, and nobody could say it didn't last.")
    plaque(z, 34, 17, "w55e_pontcysyllte", "Pontcysyllte Aqueduct",
           "Thomas Telford's aqueduct carries the Llangollen Canal across the Dee valley on eighteen stone piers, 38 metres above the river. It opened in 1805, 307 metres long, and is still the highest navigable aqueduct in the world. The iron trough has a towpath on one side and nothing at all between the boat and the drop on the other. It became a World Heritage Site in 2009.")
    plaque(z, 46, 11, "w55e_eliseg", "Eliseg's Pillar",
           "A weathered stone column in a field above Valle Crucis Abbey, the remains of a cross raised in the 9th century by Cyngen, king of Powys, in memory of his great-grandfather Elisedd. Its long Latin inscription, which told the family's history, wore away over the centuries and was copied down in 1696 while it could still be read. The Cistercian abbey below was founded in 1201.")
    sign(z, 18, 6, "CASTELL DINAS BRAN. A medieval castle on an Iron Age hillfort above Llangollen, built in the 1260s by the princes of Powys and ruined soon after. Legend says it burned itself rather than fall to Edward I.")
    sign(z, 28, 4, "NORTH: Llangollen, the Dee and the International Eisteddfod every July. SOUTH: Chirk, Welshpool and the Dyke. Mind the narrowboats, they have no brakes and right of way.")
    # --- people
    chat(z, "od_walker", "hiker", 30, 38, "Dyke Walker",
         ["All hundred and seventy-seven miles. Chepstow to Prestatyn, or the other way round, if you like going down hills.",
          "You cross the border more than twenty times on the Path. The border doesn't seem to mind."], "right", "still")
    chat(z, "od_bargee", "canal_boater", 31, 15, "Narrowboat Skipper",
         ["Across Pontcysyllte at four miles an hour. Thirty-eight metres up. I don't look down. My wife does it for me, and describes it.",
          "Telford built it in iron and stone. The mortar was lime and ox blood, they say. Nobody likes to think about the ox blood, but it's still holding up."], "down", "still")
    chat(z, "od_singer", "choir_singer", 24, 22, "Eisteddfod Singer",
         ["The International Eisteddfod began in 1947. Choirs from all over the world came to sing in a tent in a Welsh field, just two years after the war. People thought it a very odd idea. It's been going ever since.",
          "Every July the town fills up with folk dancers and the smell of chip fat. Lovely."], "right", "still")
    chat(z, "od_railman", "rail_guard", 54, 46, "Railway Volunteer",
         ["The Welshpool and Llanfair is a narrow gauge line, two foot six, opened in 1903. It was nearly lost in the sixties, and a lot of enthusiasts saved it with sandwiches and shovels.",
          "It runs through the border country at a walking pace. It's the only way to see the Dyke without getting your boots dirty."], "left", "still")
    # --- trainers
    tr(z, "od_walker_t", "Walker Haf", "Hillwalker", "hillwalker", [("squibbet", 22), ("foalmoor", 23), ("tylwyth", 22)], 36, 38, "right",
       ["Two sides to the Dyke: England on one, Wales on the other. I'm on the English side. For now. My mum's from Wrexham."],
       "Chwarae teg. That was fair play.", "Offa had the Dyke built to show who owned what. It still works, but only just.", 450, FLOOR)
    tr(z, "od_castle", "Castle Warden Gethin", "Warden", "warden_grunt", [("martling", 23), ("brockling", 22), ("slatelet", 22)], 14, 34, "up",
       ["I look after the castle for the National Trust. It looks after me, mostly by being cold."],
       "I'll lock up. Slowly.", "The Mortimers built it, the Myddeltons bought it, and now the Trust has it. And every one of them has had a go at the plumbing.", 440, FLOOR)
    tr(z, "od_boater", "Boatman Idris", "Canal Boater", "canal_boater", [("ductling", 22), ("afanc", 23), ("elverlet", 22)], 28, 16, "right",
       ["It's narrow, the boat. It's narrow, the canal. It's narrow, the aqueduct. Everything round here is narrow except the views."],
       "I'll steer clear next time.", "Beavers have been reintroduced in Wales, so I'm told. I haven't seen one. They've probably got a better view than I have.", 440, FLOOR)
    tr(z, "od_farmer", "Hill Farmer Emlyn", "Farmer", "farmer", [("leveret", 22), ("kitelet", 23), ("flyling", 22)], 48, 24, "left",
       ["Sheep on one side of the Dyke, sheep on the other. They don't know which country they're in. It's a lot less stressful that way."],
       "I'll go and count my sheep. Slowly.", "My grandad got a letter from the council in 1974 telling him which county he lived in. He said he'd always known.", 430, FLOOR)
    tr(z, "od_choir", "Choirmaster Rhian", "Singer", "choir_singer", [("wispet", 23), ("gwyllgi", 23), ("pipkin", 22)], 44, 16, "down",
       ["A male voice choir has more power than a brass band and costs less. Warm up? We've been warmed up since Christmas."],
       "Harmony restored. Mostly.", "Sing in the open air up here and the hills give it back to you a second later. Every Welshman knows that.", 450, FLOOR)
    # --- wildlife
    wild(z, [("squibbet", 22, 24, 10, {"weather": ["drizzle", "downpour"]}), ("foalmoor", 22, 24, 8, {}), ("tylwyth", 22, 24, 10, {"time": ["dusk", "night"]}),
             ("martling", 22, 24, 10, {}), ("brockling", 22, 24, 10, {"time": ["dusk", "night"]}), ("flittermouse", 22, 24, 8, {"time": ["dusk", "night"]}),
             ("kitelet", 22, 24, 12, {"time": ["day"]}), ("leveret", 22, 24, 8, {"time": ["dawn", "dusk"]}), ("pipkin", 22, 24, 8, {"time": ["dawn", "day"]}),
             ("wispet", 22, 24, 8, {"weather": ["fog"]}), ("brammel", 22, 24, 6, {"season": ["summer", "autumn"]}), ("gwyllgi", 22, 24, 5, {"time": ["night"]}),
             ("flyling", 22, 24, 6, {"time": ["dusk"], "weather": ["drizzle", "fog"]})])
    wild(z, [("elverlet", 22, 24, 22, {}), ("afanc", 22, 24, 12, {}), ("minkshade", 22, 24, 14, {"time": ["dusk", "night"]}), ("ratty", 22, 24, 20, {}), ("ductling", 22, 24, 18, {}), ("dipling", 22, 24, 18, {})], "water")
    offE = link("shrewsbury", "west", ZID, 46)
    offN = link("llangollen", "south", ZID, 32)
    z.d["edges"] = {"east": {"to": "shrewsbury", "offset": offE}, "north": {"to": "llangollen", "offset": offN}}
    z.d["spawn"] = [60, 46]
    scenery(z, 1200, bushes=22, rocks=16, trees=8, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(62, 46), (32, 0)]):
        print("PROBLEM:", p)
    add_place(ZID, 590, 915)
    add_data("poi", [
        poi(ZID, "offas_stone", (42, 20), "stone", stat="def",
            lore=["You put a hand on the bank. It is cold, and exactly as wide as one very determined king.",
                  "The real thing is Offa's Dyke itself: a bank and ditch, still higher than a man in places, built in the 8th century along the border and walked today by a National Trail."]),
        poi(ZID, "offas_cache", (46, 54), "cache", item="hag_stone",
            line="In the dry-stone wall, a slate with a hole through it, on a string. A lucky stone, from a time when luck was the cheapest thing on a farm."),
        poi(ZID, "offas_den", (6, 52), "den", species="tormane")])
    add_data("field_spots", [
        fspot(ZID, "offas_wall", 34, 30, "mend", "wall_gap",
              "A gap in the drystone wall on the border, a few stones short of a good afternoon's work. {lead} lifts them back into place one by one. Whoever owns the wall, England or Wales, tips a cap from the next field.",
              {"item": "flask_of_tea", "qty": 1})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
