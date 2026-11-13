# Road 6 (wave 55): the Black Country road. Ironbridge Gorge (east side) over the Staffordshire coalfield by Dudley and the
# canals to Birmingham (west side). Ironbridge opens at the Urban Stone and Birmingham only at the Spirit Stone, so the
# road carries the same gate the road to Sheffield has: Wardens, until badge_spirit.
from w55_lib import *

ZID = "black_country"
W, H = 64, 52
FLOOR = 21   # Ironbridge Gorge 21: the end where it can be walked into first (the zone scales with the story)
GATE = "badge_spirit"


def build():
    z = route_zone(ZID, "The Black Country", W, H, "midlands", "route_forest", "town", FLOOR,
                   {"drizzle": 34, "clear": 20, "fog": 12, "downpour": 12, "sunshine": 10, "gale": 6, "snow": 6})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#6f7a45"},
        "m": {"tile": "grass", "colour": "#7a8450"},
        "q": {"tile": "tall_grass", "colour": "#6c7743", "prop": "short"},
        "c": {"tile": "cobbles", "colour": "#7b7468"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "R": {"tile": "rock", "colour": "#5a554c"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(0, 23, 3, 3), (61, 23, 3, 3)])
    z.scatter(0, 0, W, H, "P", 10, 4, only="T")
    # --- Dudley hill in the south-east, spoil heaps and old pit mounds
    hills(z, [(42, 40, 4, 12), (12, 12, 2, 8), (30, 44, 2, 8)])
    for (cx, cy, rx, ry) in [(10, 10, 5, 3), (24, 44, 6, 3), (52, 8, 5, 3), (36, 8, 4, 2)]:
        blob(z, cx, cy, rx, ry, "q", only="g", seed=cx * cy, jitter=0.5)
    for (cx, cy) in [(8, 38), (36, 36), (54, 14), (20, 14)]:
        blob(z, cx, cy, 2.5, 1.6, "R", only="gq", seed=cx, jitter=0.4)
    # --- the canal: runs east to west just south of the road, with a towpath
    for x in range(3, W - 3):
        z.set(x, 31, "w"); z.set(x, 32, "~"); z.set(x, 33, "w")
    # a lock and a bridge or two over it are painted by the road
    # --- the road: in from Ironbridge, past the works, to the gate and on to Birmingham
    ROUTE = [(1, 24), (14, 24), (14, 28), (30, 28), (30, 24), (62, 24)]
    road(z, ROUTE, "c", 3)
    road(z, [(23, 28), (23, 35)], "c", 3)      # a bridge over the canal to the terraces
    road(z, [(41, 24), (41, 35)], "c", 3)      # and another, to Dudley Castle
    # --- works and terraces: red brick, mill brick, a chain shop, the anchor forge
    z.building(5, 17, 8, 4, "mill_brick", "Anchor Forge", show_label=True)
    z.building(17, 16, 6, 4, "red_brick", "Chain Shop", show_label=True)
    z.building(30, 16, 5, 4, "grit_terrace", "", show_label=False)
    z.building(36, 16, 5, 4, "grit_terrace", "", show_label=False)
    z.building(55, 16, 6, 5, "red_brick", "Glassworks", show_label=True)
    z.building(5, 36, 9, 4, "terrace", "", show_label=False)
    z.building(18, 37, 6, 4, "backtoback", "", show_label=False)
    z.building(30, 38, 4, 3, "weavers_cottage", "", show_label=False)
    # --- Dudley Castle on its hill
    z.building(36, 38, 12, 6, "castle", "Dudley Castle")
    z.prop("flagpole", 49, 38)
    z.prop("canal_boat", 20, 32, variant=0); z.prop("canal_boat", 38, 32, variant=1); z.prop("canal_boat", 8, 32, variant=0)
    z.prop("statue", 20, 28)   # the anchor, standing where it was made
    # --- the gate: a hedged bank across the whole zone at x = 52, and a wall of Wardens in the one gap, for the road to Birmingham
    for y in range(3, H - 3):
        if y not in (23, 24, 25):
            z.set(52, y, "H")
    gate_npcs(z, "bc_gate", 52, 23, 3, "y", GATE, "Warden", "warden_grunt",
              ["The road to Birmingham is closed. Bridge inspection. We are inspecting it very thoroughly.",
               "Spirit Stone, they say. Hester in York has it. Something about a crypt. Come back when you've seen a bit more of the country."], "left")
    # --- signs and plaques
    sign(z, 3, 20, "WEST: Ironbridge Gorge and the Severn. EAST: Dudley, Netherton and Birmingham, assuming the road is open. It may not be.")
    plaque(z, 8, 22, "w55e_black_country", "The Black Country",
           "The name arrived in the 19th century, when coal seams, ironworks, foundries and furnaces filled the country west of Birmingham with smoke. The American visitor Elihu Burritt called it 'black by day and red by night'. The seam under Dudley was ten metres thick in places, among the thickest in England. It is a country of small workshops, canals and a famous accent.")
    plaque(z, 21, 28, "w55e_titanic_anchor", "The Anchor of the Titanic",
           "The centre anchor of the Titanic, about fifteen and a half tonnes, was forged at Netherton by Noah Hingley and Sons in 1910 or 1911 and carried to Dudley station behind a team of horses. Netherton made anchors and chain for great ships for generations, and the Black Country's ironmasters led the world in both.")
    plaque(z, 24, 22, "w55e_chainmakers", "The Women Chainmakers",
           "In 1910 the women chainmakers of Cradley Heath went on strike for a minimum wage under the new Trade Boards Act. They worked at hearths in their back sheds, swinging heavy hammers for very little. The trade union leader Mary Macarthur backed them, and after ten weeks the employers gave in. It was one of the first wins for low-paid women workers in Britain.")
    sign(z, 14, 28, "THE CANAL. Birmingham boasts more miles of canal than Venice, and the Black Country has plenty of them too. The Birmingham Canal Navigations were among Britain's busiest waterways in their day.")
    plaque(z, 40, 36, "w55e_dudley_castle", "Dudley Castle",
           "A castle on the hill above Dudley, begun about 1070 as a motte and bailey and rebuilt in stone from the 12th century. A Royalist garrison held it for the king in the Civil War until it surrendered in 1646, and it was made unusable the following year. Today it stands beside Dudley Zoo.")
    sign(z, 49, 21, "THE ROAD EAST. Birmingham, the city of a thousand trades, and the Bull Ring. Don't ask the Wardens, they only know the one word.")
    sign(z, 50, 27, "BRIDGE INSPECTION IN PROGRESS. Please do not walk on the bridge, over the bridge, or in the vicinity of the bridge. Thank you.")
    sign(z, 5, 28, "LOCAL SPEAKING. A 'bostin' tea is a very good one. Say 'ow bin ya?' and you'll be told. Do not ask about the football.")
    # --- people
    chat(z, "bc_boater", "canal_boater", 10, 30, "Narrowboat Skipper",
         ["She's called the Mildred. I'm called Dave. I've been up and down these canals for thirty years and I still can't get the lock gate to stop squeaking.",
          "The Dudley Tunnel is nearly two miles long and the old boatmen walked the boats through on their backs, legging it along the roof. Imagine your hamstrings."], "down", "still")
    chat(z, "bc_museum", "tour_guide", 19, 24, "Museum Guide",
         ["Over at the Living Museum in Dudley they've moved real Black Country buildings brick by brick. A chip shop, a chapel, a pub. The chip shop does a very good faggot and peas.",
          "Our dialect has a thousand years behind it. Black Country speech has kept some old English forms the rest of England dropped. Some say 'thee' and 'thou' still."], "right", "still")
    chat(z, "bc_pigeon", "villager_4", 33, 28, "Pigeon Fancier",
         ["Racing pigeons. A good bird will fly five hundred miles home in a day. They know the way back to the loft better than I do to the pub.",
          "Half the lofts in the Black Country are on allotments. The other half are in someone's back garden, behind a fence and a dog."], "down", "still")
    chat(z, "bc_ironmaster", "steelworker", 44, 26, "Ironworker",
         ["Iron's in our blood. Coal under the ground, ironstone, limestone, all within a few miles of each other. That's why the Black Country happened here, and not in Cornwall.",
          "My grandad made chain at Cradley Heath. My gran made it too. She was better at it."], "right", "still")
    # --- trainers
    tr(z, "bc_chainmaker", "Chainmaker Doreen", "Chainmaker", "steelworker", [("pigling", 21), ("bobbin", 22), ("brockling", 21)], 15, 27, "up",
       ["Heavy hammer, hot iron, a very small shed. We made chain for ships, for farms, for the Navy. Mind your fingers."],
       "Hot work. I need a cuppa and a sit.", "My gran made chain at home with a hammer and a baby on her hip. It was how it was.", 400, FLOOR)
    tr(z, "bc_boater_t", "Boatman Terry", "Canal Boater", "canal_boater", [("ductling", 21), ("stalklet", 22), ("elverlet", 21)], 29, 30, "up",
       ["Horse-drawn, that was. Shire horses on the towpath, a boatman at the tiller. Now it's a diesel and a lot of cups of tea."],
       "I'll get my coat. And the boat.", "The towpaths are the only quiet places in the Black Country. That's why we walk them.", 400, FLOOR)
    tr(z, "bc_foundry", "Foundryman Ken", "Foundryman", "steelworker", [("pigling", 22), ("sootwing", 22), ("rooklet", 21)], 47, 26, "left",
       ["Moulds, molten iron and a hard hat. It's a proper job. I used to see the glow of the furnaces from my bedroom window."],
       "Cooled off. Fair play.", "At night the whole sky used to turn orange. My mum said it was the Devil's kitchen.", 420, FLOOR)
    tr(z, "bc_pigeon_t", "Fancier Stan", "Pigeon Fancier", "villager_5", [("cooplet", 21), ("starlet", 21), ("murmurant", 22)], 24, 38, "up",
       ["I'll bet you a pint my bird gets home before yours does. Mine's quicker. And she's got a better accent."],
       "She'll be home before me. But you'll need a pint.", "Pigeon racing in the Black Country goes back well over a century. Some birds have flown from France.", 400, FLOOR)
    tr(z, "bc_dudley_t", "Zookeeper Gwen", "Zookeeper", "student", [("binfox", 22), ("grizzlet", 21), ("raidtail", 22)], 42, 35, "up",
       ["Dudley Zoo is in the castle grounds. We have the lot: penguins, okapis, a very loud peacock. It's the only zoo I know with a castle."],
       "That's bad for morale. Not for the peacock, though.", "Some of the zoo buildings were designed by the same architect who did London Zoo's penguin pool. They look like very modern concrete bunkers, in the best way.", 420, FLOOR)
    # --- wildlife
    wild(z, [("pigling", 21, 23, 12, {}), ("binfox", 21, 23, 12, {"time": ["dusk", "night", "dawn"]}), ("cooplet", 21, 23, 14, {"time": ["day"]}),
             ("starlet", 21, 23, 12, {}), ("grizzlet", 21, 23, 10, {"time": ["day"]}), ("rooklet", 21, 23, 10, {}),
             ("sootwing", 21, 23, 6, {"time": ["night"]}), ("bobbin", 21, 22, 8, {}), ("squibbet", 21, 23, 8, {"weather": ["drizzle", "downpour"]}),
             ("brockling", 21, 23, 8, {"time": ["dusk", "night"]}), ("zigzlet", 21, 23, 8, {"time": ["day"], "weather": ["sunshine", "clear"]}),
             ("hootlet", 21, 23, 8, {"time": ["dusk", "night"]})])
    wild(z, [("ductling", 21, 23, 24, {}), ("elverlet", 21, 23, 20, {}), ("stalklet", 21, 23, 18, {}), ("dipling", 21, 23, 18, {}), ("pollanet", 21, 22, 14, {}), ("rillotter", 21, 23, 10, {})], "water")
    offW = link("ironbridge_gorge", "east", ZID, 24)
    offE = link("birmingham", "west", ZID, 24)
    z.d["edges"] = {"west": {"to": "ironbridge_gorge", "offset": offW}, "east": {"to": "birmingham", "offset": offE}}
    z.d["spawn"] = [3, 24]
    scenery(z, 800, bushes=20, rocks=10, trees=10, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(1, 24), (62, 24)]):
        print("PROBLEM:", p)
    add_place(ZID, 680, 930)
    add_data("poi", [
        poi(ZID, "blackcountry_stone", (30, 12), "stone", stat="atk",
            lore=["It is warm, which is unreasonable in this weather. A cinder, perhaps, from the great ironworks that fed the Black Country for a century.",
                  "The real thing is the Black Country's pig iron and chain: Netherton anchors, Cradley Heath chain, and the forges that glowed red every night."]),
        poi(ZID, "blackcountry_cache", (40, 48), "cache", item="miners_lamp",
            line="At the back of a ruined pit-head shed: a Davy lamp, still half full of paraffin, and a chalk note that reads 'DON'T'."),
        poi(ZID, "blackcountry_camp", (10, 46), "camp", names=[["Scrap Merchant Colin", "Scavenger"], ["Scrap Merchant Maureen", "Scavenger"]],
            party=["pigling", "bobbin", "binfox"], line="Reclaimed lead from the church roof. It's called recycling when you're me.", money=700, item="iron_snare")])
    add_data("field_spots", [
        fspot(ZID, "blackcountry_line", 26, 34, "line", "glint",
              "Something glints in the canal: a lost shilling, a lump of tin, the kind of thing that sits in the silt for a hundred years. {lead} dips in, and up comes a handful of old pennies and a surprise.",
              {"money": 320})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
