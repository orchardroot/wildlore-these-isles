# Road 7 (wave 55): the Wessex Ridgeway over Cranborne Chase. Poole (north side) up by Badbury Rings and Knowlton to
# Cranborne Chase and the chalk to Stonehenge (south side). Poole opens at the Fae Stone and Stonehenge at the Spirit
# Stone, so the road carries the Wardens and their bank across it until badge_spirit, as the road to Sheffield does.
from w55_lib import *

ZID = "cranborne_chase"
W, H = 60, 58
FLOOR = 40   # Poole 40: the end that can be walked into first
GATE = "badge_spirit"


def build():
    z = route_zone(ZID, "Cranborne Chase", W, H, "south_england", "route_moors", "grass", FLOOR,
                   {"clear": 28, "sunshine": 16, "drizzle": 22, "fog": 14, "gale": 8, "downpour": 12})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#82964f"},
        "m": {"tile": "grass", "colour": "#8fa457"},
        "q": {"tile": "tall_grass", "colour": "#7f9650", "prop": "short"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "c": {"tile": "path", "colour": "#e0dccb"},
        "R": {"tile": "rock", "colour": "#9a9482"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(29, 0, 3, 3), (29, 55, 3, 3)])
    z.scatter(0, 0, W, H, "P", 14, 6, only="T")
    # --- the chalk ridge, Badbury Rings (a hill fort ringed with three banks) in the south, the downs to the north
    hills(z, [(16, 44, 5, 12), (44, 22, 4, 14), (30, 10, 3, 10)])
    for y in range(3, H - 3):
        for x in range(3, W - 3):
            if z.g[y][x] == "g" and (x * 5 + y * 3) % 7:
                z.set(x, y, "m")
    for (cx, cy, rx, ry) in [(10, 22, 7, 3), (40, 40, 7, 3), (50, 12, 5, 3), (24, 32, 5, 2)]:
        blob(z, cx, cy, rx, ry, "q", only="gm", seed=cx * cy, jitter=0.5)
    # Badbury Rings: concentric banks (rock) with gaps at the four entrances
    for rad, step in [(8, 1), (6, 1), (4, 1)]:
        for ang in range(0, 360, 4):
            x = int(round(16 + rad * math.cos(math.radians(ang)))); y = int(round(44 + 0.8 * rad * math.sin(math.radians(ang))))
            if 3 <= x < W - 3 and 3 <= y < H - 3 and not (abs(x - 16) <= 1 or abs(y - 44) <= 1):
                z.set(x, y, "R")
    # --- Knowlton: a henge ring with a ruined church inside it
    ell(z, 44, 27, 5, 4, "R", only="gmq")
    ell(z, 44, 27, 3.8, 3.0, "m", only="R")
    z.set(44, 31, "m"); z.set(44, 30, "m"); z.set(39, 27, "m")
    z.building(43, 26, 3, 3, "chapel", "Knowlton Church (ruin)", show_label=False)
    # --- the road (the Wessex Ridgeway): up from Poole, across the Chase, to the gate and Stonehenge
    ROUTE = [(30, 56), (30, 48), (30, 36), (14, 36), (14, 28), (30, 28), (30, 18), (50, 18), (50, 8), (30, 8), (30, 1)]
    road(z, ROUTE, "c", 3)
    # --- Larmer Tree Gardens, a keeper's cottage, a flint barn
    z.building(8, 10, 5, 3, "flint_cottage", "Keeper's Cottage")
    z.building(46, 42, 6, 3, "field_barn", "Flint Barn", show_label=False)
    z.building(6, 16, 5, 4, "chapel", "Larmer Tree Temple", show_label=True)
    for (x, y) in [(10, 18), (20, 24), (40, 30), (22, 42), (54, 30), (34, 44)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- the gate: a bank across the zone at y = 14, the Wardens in its gap; Stonehenge lies behind it
    gate_wall(z, "y", 14, 29, 31)
    gate_npcs(z, "cc_gate", 29, 14, 3, "x", GATE, "Warden", "warden_grunt",
              ["The Chase road is closed. It is being inspected. We have been inspecting it since Easter, and very thoroughly.",
               "The Spirit Stone, they say. Down in the crypt at York, with Keeper Hester. Come back when you've seen a bit more of the country."], "down")
    # --- signs and plaques
    sign(z, 28, 54, "SOUTH: Poole, Wimborne and the sea. NORTH: Cranborne Chase, Salisbury and Stonehenge. The Wessex Ridgeway runs this way, all the way from Marlborough to the Dorset coast at Lyme Regis.")
    plaque(z, 24, 50, "w55e_badbury", "Badbury Rings",
           "An Iron Age hill fort with three concentric banks and ditches, with entrances on opposite sides, standing on a chalk ridge near Wimborne. The Romans later built roads that met close by. It is one of several places that have been suggested as the site of King Arthur's victory at Mons Badonicus, though nobody knows.")
    plaque(z, 36, 27, "w55e_knowlton", "Knowlton Circles",
           "A group of Neolithic henges, ring-shaped banks and ditches built about 4,500 years ago. In the 12th century the Normans built a church inside the biggest ring, perhaps to claim a place that was already holy. It was left to decay in the 1700s and stands roofless now, with the sheep for a congregation.")
    sign(z, 26, 36, "THE WESSEX RIDGEWAY. About 136 miles from Marlborough to Lyme Regis, mostly on old chalk ridgeways and green lanes. Walkers say the Dorset end is the best, and they are all from Dorset.")
    plaque(z, 32, 24, "w55e_pitt_rivers", "General Pitt Rivers",
           "Augustus Pitt Rivers inherited the Cranborne Chase estates in 1880 and spent the next two decades digging them, Roman villages, barrows and hill forts. He recorded every find in place and published the lot with plans and drawings, which made him one of the founders of modern archaeology. The Larmer Tree Gardens he made for the pleasure of his tenants are still open.")
    sign(z, 34, 6, "TOLLARD ROYAL. A village in a fold of the chalk, named for a royal hunting lodge. Pitt Rivers once lived at Rushmore, over the hill. Do take the road slowly. It is lined with deer.")
    sign(z, 26, 15, "WARDENS. NO THROUGH ROAD. (Bridge inspection.) With thanks for your patience.")
    # --- people
    chat(z, "cc_archaeologist", "student", 26, 33, "Student Archaeologist",
         ["Every field in this part of Dorset has something under it. We just dig a trench and wait for the farmer to stop shouting.",
          "Pitt Rivers set the standard here. Draw it, number it, record where it was. We still do that. Mostly."], "right", "still")
    chat(z, "cc_keeper", "farmer", 34, 28, "Gamekeeper",
         ["Fallow deer all over the Chase. They've been here since the Normans, give or take. Muntjac too, tiny and shy. You hear them barking at night.",
          "Walk quietly at dusk and you might get a sighting. Or a ticking-off from a roe, which is worse."], "left", "still")
    chat(z, "cc_walker", "hiker", 33, 41, "Ridgeway Walker",
         ["I'm walking the whole Ridgeway. Marlborough to Lyme Regis. Day six. Chalk, flint, chalk, flint. I'm becoming a hill.",
          "The old ridgeways kept to the high ground to stay dry and out of the forest. They were drovers' roads. They knew things."], "right", "still")
    chat(z, "cc_ranger", "villager_2", 22, 30, "Down Warden",
         ["Chalk grassland is one of the richest habitats we have. A square metre can hold forty kinds of plant. The sheep keep it that way.",
          "Nightjars come in May. You can hear them at dusk, a long churring like a very small tractor."], "down", "still")
    # --- trainers
    tr(z, "cc_hillfort", "Digger Rhiannon", "Archaeologist", "student", [("flintling", 40), ("tunneller", 41), ("chalkling", 40)], 34, 52, "left",
       ["Hillforts aren't forts, strictly. More fortified villages. Some people lived here for centuries. Think of it as the first estate agent's dream."],
       "Well, that's a trench I'd rather not have dug.", "Badbury Rings has three banks and no one can say why three. Probably a sign of how worried they were.", 1450, FLOOR)
    tr(z, "cc_deerman", "Deerstalker Hugh", "Gamekeeper", "farmer", [("barkdeer", 40), ("brockling", 41), ("hootlet", 40)], 22, 36, "right",
       ["A fine fallow buck and I'll have you know it. Don't mess with a stag in the rut. Or me. I'm about as flexible."],
       "That's a hit to the pride. And my hat.", "Cranborne Chase was hunted for centuries by kings and lords. Now it's just me and a pair of binoculars.", 1450, FLOOR)
    tr(z, "cc_nightjar", "Birdwatcher Phyllis", "Birdwatcher", "birdwatcher", [("churrjar", 41), ("hushwing", 40), ("kitelet", 40)], 12, 32, "down",
       ["Nightjars! Camouflaged like a bit of dead branch, and a call like a distant motorbike. I wait all day to hear it for five minutes."],
       "Oh dear. I hope I haven't put the nightjar off.", "The old name was goatsucker. They think it drank milk from goats. They were wrong, but it's a better name than 'Caprimulgus'.", 1400, FLOOR)
    tr(z, "cc_rider", "Rambler Giles", "Hillwalker", "hillwalker", [("leveret", 40), ("pipkin", 41), ("stoatlet", 40)], 38, 6, "down",
       ["Drovers took their cattle and sheep along this ridge for hundreds of years. I'm a modern drover. I'm carrying a sandwich."],
       "Well, that's me driven off. I'll go and think about my life.", "A drover could do twenty miles a day. I can do ten and then there's a pub.", 1400, FLOOR)
    tr(z, "cc_shepherd", "Shepherd Netta", "Shepherd", "farmer", [("herdlet", 40), ("zigzlet", 41), ("puffkin", 40)], 46, 38, "up",
       ["Chalk downland sheep. They keep the turf short, and the flowers come. I'm doing my bit for the butterflies. Don't tell the ewes."],
       "Righto. The ewes will be so cross with me.", "The chalkhill blue only lives where the horseshoe vetch grows, and that only grows on grazed turf. It all depends on sheep.", 1450, FLOOR)
    # --- wildlife
    wild(z, [("barkdeer", 40, 42, 10, {"time": ["dusk", "night", "dawn"]}), ("churrjar", 40, 42, 8, {"time": ["dusk", "night"], "season": ["summer"]}),
             ("hushwing", 40, 42, 8, {"time": ["dusk", "night"]}), ("leveret", 40, 42, 10, {"time": ["dawn", "dusk"]}),
             ("chalkling", 40, 42, 10, {}), ("kitelet", 40, 42, 8, {"time": ["day"]}), ("flintling", 40, 42, 8, {}),
             ("pipkin", 40, 42, 10, {"time": ["dawn", "day"]}), ("stoatlet", 40, 42, 8, {}), ("tunneller", 40, 42, 6, {}),
             ("zigzlet", 40, 42, 8, {"time": ["day"], "weather": ["sunshine", "clear"]}), ("brockling", 40, 42, 8, {"time": ["dusk", "night"]}),
             ("flittermouse", 40, 42, 6, {"time": ["dusk", "night"]})])
    wild(z, [("croakle", 40, 42, 20, {}), ("stalklet", 40, 42, 20, {}), ("dipling", 40, 42, 20, {}), ("volet", 40, 42, 16, {})], "water")
    offN = link("stonehenge", "south", ZID, 30)
    offS = link("poole", "north", ZID, 30)
    z.d["edges"] = {"north": {"to": "stonehenge", "offset": offN}, "south": {"to": "poole", "offset": offS}}
    z.d["spawn"] = [30, 52]
    scenery(z, 900, bushes=20, rocks=10, trees=8, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(30, 57), (30, 0)]):
        print("PROBLEM:", p)
    add_place(ZID, 690, 1160)
    add_data("poi", [
        poi(ZID, "cranborne_stone", (14, 34), "stone", stat="ward",
            lore=["The stone is cold and faintly humming. Then you realise that's you.",
                  "The real thing is Knowlton Church: a Norman church in the middle of a Neolithic henge, left to decay in the 1700s and standing roofless since."]),
        poi(ZID, "cranborne_cache", (6, 22), "cache", item="ammonite",
            line="Where the chalk has slumped, something curled and grey is sticking out of the bank. An ammonite, perfectly round, with a very old look about it."),
        poi(ZID, "cranborne_den", (48, 48), "den", species="megalorn")])
    add_data("field_spots", [
        fspot(ZID, "cranborne_loft", 36, 36, "loft", "bale",
              "A bend in the old drove road, a straw bale for a target and a grassy verge. {lead} lobs the bowl and it sails over the bend like it knew the way. In the grass beyond: a handful of loose coins.",
              {"money": 450})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
