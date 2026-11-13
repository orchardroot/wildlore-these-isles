# Road 10 (wave 55): Offa's Dyke Path. The Shropshire Hills (south side) by Clun, Knighton, Hay-on-Wye and the Black
# Mountains into the Brecon Beacons (north side). A border crossing: England to Wales. The Shropshire Hills open at
# the Urban Stone and the Welsh south only after the dragon on Yr Wyddfa (the Cambrian gate), so the road carries
# the same gate: Wardens, until ch3_ddraig_woke.
from w55_lib import *

ZID = "offas_dyke"
W, H = 64, 64
FLOOR = 21   # the Shropshire Hills 21: the end that can be walked into first
GATE = "ch3_ddraig_woke"


def build():
    z = route_zone(ZID, "Offa's Dyke", W, H, "mid_wales", "route_moor", "moor", FLOOR,
                   {"drizzle": 32, "clear": 20, "fog": 16, "downpour": 12, "gale": 8, "sunshine": 12})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#7b8c4c"},
        "m": {"tile": "grass", "colour": "#879a52"},
        "q": {"tile": "tall_grass", "colour": "#7a8947", "prop": "short"},
        "h": {"tile": "tall_grass", "colour": "#6e5a5c", "prop": "heather"},
        "b": {"tile": "tall_grass", "colour": "#8a6a44", "prop": "short"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "G": {"tile": "rock", "colour": "#6f6852"},
        "c": {"tile": "path", "colour": "#b9a98a"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(31, 0, 3, 3), (31, 61, 3, 3)])
    z.scatter(0, 0, W, H, "P", 30, 8, only="T")
    # --- Clun forest in the north, the Black Mountains rising in the south-east
    hills(z, [(14, 8, 3, 12), (52, 52, 6, 16), (14, 54, 3, 10)])
    for y in range(3, 16):
        for x in range(3, W - 3):
            if z.g[y][x] == "g" and (x * 7 + y) % 5 == 0:
                z.set(x, y, "P")
    for (cx, cy, rx, ry) in [(52, 52, 9, 5), (14, 8, 6, 3), (44, 10, 6, 3)]:
        blob(z, cx, cy, rx, ry, "h", only="gm", seed=cx + cy, jitter=0.5)
    for (cx, cy, rx, ry) in [(30, 30, 8, 3), (46, 30, 6, 3), (18, 44, 7, 3)]:
        blob(z, cx, cy, rx, ry, "q", only="g", seed=cx * cy, jitter=0.5)
    for y in range(16, 60):
        for x in range(3, W - 3):
            if z.g[y][x] == "g" and (x * 3 + y * 5) % 4:
                z.set(x, y, "m")
    # --- the River Wye across the middle, and the border bridge at Hay
    for x in range(3, W - 3):
        y = 38 + int(round(1.5 * math.sin(x / 6.0)))
        z.set(x, y - 1, "w"); z.set(x, y, "~"); z.set(x, y + 1, "w")
    # --- the road
    ROUTE = [(32, 1), (32, 12), (18, 12), (18, 24), (44, 24), (44, 32), (32, 32), (32, 62)]
    road(z, ROUTE, "c", 3)
    # --- the Dyke: a hedge-and-bank line running north to south along x = 24, gaps where the road crosses
    for y in range(3, 59):
        if not (11 <= y <= 13 or 23 <= y <= 25) and z.g[y][24] not in "w~c":
            z.set(24, y, "H"); z.hg[y][24] = max(z.hg[y][24], 1)
    # --- Knighton: the Offa's Dyke Centre, houses on the bank
    z.building(36, 8, 4, 3, "white_render", "Offa's Dyke Centre", show_label=True)
    sign(z, 34, 12, "KNIGHTON. In Welsh, Tref-y-clawdd: the town on the dyke. The Offa's Dyke Path has its midpoint here, and the Centre will give you a certificate for it.")
    z.building(42, 9, 4, 3, "slate_cottage", "", show_label=False)
    z.building(8, 16, 4, 3, "stone", "Clun Castle (ruin)", show_label=True)
    # --- Hay-on-Wye: the bookshop row on the Welsh bank
    z.building(36, 41, 5, 3, "red_brick", "Booksellers", show_label=True)
    z.building(42, 41, 5, 3, "stone", "Hay Castle", show_label=True)
    z.building(36, 46, 5, 3, "tudor", "Booksellers", show_label=False)
    z.building(42, 46, 5, 3, "white_render", "", show_label=False)
    z.prop("bench", 40, 40); z.prop("lamp_post", 41, 45)
    # --- Llanthony Priory in its valley
    z.building(8, 46, 9, 5, "chapel", "Llanthony Priory (ruin)")
    for (x, y) in [(10, 20), (22, 30), (50, 18), (56, 40), (14, 40), (48, 56)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- the gate: a bank across the zone at y = 50, Wardens in the gap; the Beacons lie behind it
    gate_wall(z, "y", 50, 31, 33)
    gate_npcs(z, "od_gate", 31, 50, 3, "x", GATE, "Warden", "warden_grunt",
              ["The road south is closed. Heritage Assessment. We're waiting for Director Pryce to come back with the results.",
               "He went up Yr Wyddfa, up in Eryri, some while back. If you're passing, tell him we're still here. We're always here."], "down")
    # --- signs and plaques
    sign(z, 28, 3, "NORTH: the Shropshire Hills, Church Stretton and Shrewsbury. SOUTH: Wales, by way of Offa's Dyke. The Dyke is older than any border on a map. It is one of the few borders with a footpath.")
    plaque(z, 36, 14, "w55e_offas_dyke", "Offa's Dyke",
           "A great earthwork bank and ditch built along the Welsh border in the 8th century, probably on the orders of Offa, king of Mercia from 757 to 796. The ditch lies on the Welsh side, the bank on the English, and in places it still stands higher than a man. The Offa's Dyke Path, a National Trail opened in 1971, follows it for 177 miles from Prestatyn on the north Wales coast to Sedbury Cliffs near Chepstow.")
    plaque(z, 14, 28, "w55e_clun", "Clun and Housman",
           "Clun, on the Shropshire side of the Dyke, is the village in A. E. Housman's poem: 'Clunton and Clunbury, Clungunford and Clun, are the quietest places under the sun.' Housman published A Shropshire Lad in 1896. He grew up near Bromsgrove and never lived in Shropshire at all, but he could see its hills from home, and wrote about them from London.")
    sign(z, 26, 34, "CROESO I GYMRU. WELCOME TO WALES. The Wye is the border here, and the bridge is the only frontier post. No passport needed. A sandwich is advised.")
    plaque(z, 38, 39, "w55e_hay", "Hay-on-Wye",
           "A small Welsh border town that has more second-hand bookshops than almost anywhere. Richard Booth opened the first in 1961 and on 1 April 1977 declared Hay an independent kingdom, with himself as king. The joke stuck: Hay has a Festival every spring, begun in 1988, and a good twenty bookshops in a town of fewer than two thousand people.")
    sign(z, 30, 44, "THE BLACK MOUNTAINS. The big whaleback ridge of Hay Bluff, 677 metres, with ponies on top and weather nobody asked for. The Dyke Path runs along it or very near it. Ponies have right of way.")
    plaque(z, 14, 52, "w55e_llanthony", "Llanthony Priory",
           "The ruins of an Augustinian priory in the lonely Vale of Ewyas, in the Black Mountains. Monks founded it around 1100 after a Norman knight, William de Lacy, found a quiet chapel there while hunting. It was closed in 1538 by Henry VIII's commissioners, and part of it became a house and a hotel. The priory church's west towers still stand.")
    sign(z, 28, 50, "ROAD CLOSED. HERITAGE ASSESSMENT. ANYBODY WITH QUESTIONS SHOULD APPLY TO THE DIRECTOR IN WRITING. THE DIRECTOR IS NOT AVAILABLE.")
    # --- people
    chat(z, "od_walker", "hiker", 30, 22, "Dyke Walker",
         ["All hundred and seventy-seven miles. Prestatyn to Chepstow, or the other way, if you like walking uphill the whole time.",
          "You cross the border more than twenty times on the Path. The border doesn't seem to mind."], "right", "still")
    chat(z, "od_bookseller", "poet", 38, 43, "Hay Bookseller",
         ["Booth started it. Said the town could be a kingdom of books and appointed his horse Prime Minister. He was right about the books.",
          "We've got everything. Cookery, ghost stories, fifty copies of last year's best-seller, a very thin volume on how to be modest."], "down", "still")
    chat(z, "od_kitewatcher", "birdwatcher", 52, 20, "Kite Watcher",
         ["Red kites. By the 1900s there were only a few left in Britain, all in mid Wales. They came back from a handful of nests. Now there are thousands.",
          "Stand still and look up. Forked tail, reddish, rocking from side to side. That's a red kite."], "left", "still")
    chat(z, "od_pony", "villager_2", 52, 48, "Pony Trekker",
         ["Welsh mountain ponies, hardy as boots. They roam the Black Mountains, and they remember every sandwich you've ever had.",
          "Don't feed them. I say that every day. Then I feed them."], "down", "still")
    # --- trainers
    tr(z, "od_walker_t", "Walker Haf", "Hillwalker", "hillwalker", [("squibbet", 21), ("foalmoor", 22), ("tapknock", 21)], 26, 21, "right",
       ["Two sides to the Dyke: England on one, Wales on the other. I'm on the English side. For now. My mum's from Brecon."],
       "Chwarae teg. That was fair play.", "Offa had the Dyke built to show who owned what. It's still working, but only just.", 450, FLOOR)
    tr(z, "od_farmer", "Hill Farmer Emlyn", "Farmer", "farmer", [("leveret", 21), ("kitelet", 22), ("slatelet", 21)], 40, 17, "left",
       ["Sheep on one side of the Dyke, sheep on the other. They don't know which country they're in. It's a lot less stressful that way."],
       "I'll go and count my sheep. Slowly.", "My grandad got a letter from the council in 1974 telling him which county he lived in. He said he'd always known.", 430, FLOOR)
    tr(z, "od_bookshop", "Bookseller Arthur", "Bookseller", "poet", [("brammel", 21), ("zigzlet", 22), ("sphagnet", 21)], 34, 45, "up",
       ["Looking for something in particular? I probably have it. If not, I have something else you didn't know you wanted."],
       "That's a first edition of a defeat.", "I read three books a week and sell two. The maths doesn't add up, but nor does anything in Hay.", 440, FLOOR)
    tr(z, "od_kites", "Kite Keeper Ceri", "Ranger", "villager_2", [("kitelet", 22), ("ptarmlet", 21), ("gwyllgi", 22)], 56, 28, "left",
       ["The kites were nearly lost. Now there's a feeding station, a hide and a flask. We take it in turns to wave at them."],
       "A fair fall. Kites are tolerant.", "It takes a kite seven years to learn all the tricks. I'm on my eighth and still learning.", 460, FLOOR)
    tr(z, "od_priory", "Guide Brother Idris", "Guide", "druid", [("tapknock", 22), ("marilwyd", 21), ("sphagnet", 21)], 10, 44, "right",
       ["Llanthony. A priory for the quiet, in a valley that wouldn't be found on a map until 1800. We still prefer to be left alone."],
       "Peace be with you. And a better game next time.", "Walter Savage Landor owned the old priory buildings in 1807 and tried to improve the estate. He was bankrupted. Peace be with him.", 440, FLOOR)
    # --- wildlife
    wild(z, [("squibbet", 21, 23, 10, {"weather": ["drizzle", "downpour"]}), ("foalmoor", 21, 23, 10, {}), ("tapknock", 21, 23, 8, {}),
             ("slatelet", 21, 23, 8, {}), ("kitelet", 21, 23, 12, {"time": ["day"]}), ("ptarmlet", 21, 23, 6, {"weather": ["fog", "gale"]}),
             ("leveret", 21, 23, 10, {"time": ["dawn", "dusk"]}), ("brammel", 21, 23, 8, {}), ("gwyllgi", 21, 23, 6, {"time": ["dusk", "night"]}),
             ("sphagnet", 21, 23, 8, {"weather": ["drizzle", "downpour", "fog"]}), ("zigzlet", 21, 23, 8, {"time": ["day"], "weather": ["sunshine", "clear"]}),
             ("hootlet", 21, 23, 8, {"time": ["dusk", "night"]}), ("puffkin", 21, 23, 6, {"season": ["autumn"]})])
    wild(z, [("dipling", 21, 23, 26, {}), ("volet", 21, 23, 22, {}), ("pollanet", 21, 22, 16, {}), ("elverlet", 21, 23, 16, {}), ("stalklet", 21, 23, 14, {})], "water")
    offN = link("shropshire_hills", "south", ZID, 32)
    offS = link("beacons", "north", ZID, 32)
    z.d["edges"] = {"north": {"to": "shropshire_hills", "offset": offN}, "south": {"to": "beacons", "offset": offS}}
    z.d["spawn"] = [32, 4]
    scenery(z, 1200, bushes=22, rocks=16, trees=8, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(32, 0), (32, 63)]):
        print("PROBLEM:", p)
    add_place(ZID, 606, 975)
    add_data("poi", [
        poi(ZID, "offas_stone", (28, 18), "stone", stat="def",
            lore=["You put a hand on the bank. It is cold, and exactly as wide as one very determined king.",
                  "The real thing is Offa's Dyke itself: a bank and ditch, still higher than a man in places, built in the 8th century along the border and walked today by a National Trail."]),
        poi(ZID, "offas_cache", (46, 6), "cache", item="hag_stone",
            line="In the dry-stone wall, a slate with a hole through it, on a string. A Welsh lucky stone, from a time when luck was the cheapest thing on a farm."),
        poi(ZID, "offas_den", (6, 34), "den", species="tormane")])
    add_data("field_spots", [
        fspot(ZID, "offas_wall", 36, 20, "mend", "wall_gap",
              "A gap in the drystone wall on the border, a few stones short of being a good afternoon's work. {lead} lifts them back into place one by one. Whoever owns the wall, England or Wales, tips a cap from the next field.",
              {"item": "flask_of_tea", "qty": 1})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
