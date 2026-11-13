# Road 8 (wave 55): the Varsity Line. Bletchley Park (east side) along the old Oxford to Cambridge railway through the
# Marston Vale, Cardington, Bedford and Sandy to Cambridge (west side). Both ends open at the same story step.
from w55_lib import *

ZID = "varsity_line"
W, H = 72, 46
FLOOR = 90   # Cambridge 94, Bletchley Park (no table of its own)


def build():
    z = route_zone(ZID, "The Varsity Line", W, H, "east_anglia", "route_moor_south", "grass", FLOOR,
                   {"clear": 28, "drizzle": 22, "sunshine": 16, "fog": 12, "gale": 8, "downpour": 14})
    z.legend.update({
        "g": {"tile": "grass", "colour": "#86994f"},
        "m": {"tile": "grass", "colour": "#92a65a"},
        "q": {"tile": "tall_grass", "colour": "#7f9650", "prop": "short"},
        "r": {"tile": "shallow", "prop": "reeds"},
        "c": {"tile": "path", "colour": "#b9a98a"},
    })
    z.rect(0, 0, W, H, "g")
    z.border("T", 3, gaps=[(0, 21, 3, 3), (69, 15, 3, 3)])
    z.scatter(0, 0, W, H, "P", 10, 2, only="T")
    hills(z, [(14, 34, 2, 10), (56, 10, 2, 10)])
    for y in range(3, H - 3):
        for x in range(3, W - 3):
            if z.g[y][x] == "g" and (x * 3 + y * 7) % 5:
                z.set(x, y, "m")
    for (cx, cy, rx, ry) in [(12, 12, 6, 3), (34, 34, 7, 3), (58, 32, 6, 3), (24, 22, 4, 2)]:
        blob(z, cx, cy, rx, ry, "q", only="gm", seed=cx * cy, jitter=0.5)
    # --- the old line: a cinder path on the trackbed with a rail stub, a level crossing, signals
    ROUTE = [(1, 22), (20, 22), (20, 28), (40, 28), (40, 16), (70, 16)]
    road(z, ROUTE, "c", 3)
    z.set(40, 22, "c")
    # --- the River Great Ouse winding across the middle, bridged by the line
    for y in range(3, H - 3):
        x = 30 + int(round(3.0 * math.sin(y / 5.0)))
        z.set(x - 1, y, "w"); z.set(x, y, "~"); z.set(x + 1, y, "w")
    road(z, [(26, 22), (34, 22)], "c", 3)
    road(z, [(26, 28), (34, 28)], "c", 3)
    # --- Cardington: the two great airship sheds, the biggest buildings for miles
    z.building(46, 22, 14, 7, "red_brick", "Cardington Airship Sheds")
    z.building(46, 31, 14, 6, "red_brick", "", show_label=False)
    # --- Bedford: a chapel, a gaol wall, an almshouse row
    z.building(6, 30, 6, 4, "chapel", "Bunyan Meeting")
    z.building(14, 36, 8, 3, "terrace", "", show_label=False)
    z.building(8, 8, 6, 3, "red_brick", "Station (closed)")
    z.prop("bench", 10, 12); z.prop("lamp_post", 15, 12)
    # --- Sandy: lowland heath with birch and pines
    blob(z, 60, 36, 6, 3, "q", only="gm", seed=7, jitter=0.5)
    pond(z, 62, 8, 4, 2, shore="r")
    for (x, y) in [(10, 20), (22, 34), (36, 38), (52, 14), (48, 40), (64, 24)]:
        z.prop("sheep", x, y, variant=(x + y) % 3)
    # --- signs and plaques
    sign(z, 3, 18, "WEST: Bletchley, Milton Keynes and Oxford. EAST: Bedford, Sandy and Cambridge. This was the Varsity Line. The trains would take you between the two universities, in the end with a change at Bletchley and a long wait.")
    plaque(z, 16, 27, "w55e_varsity_line", "The Varsity Line",
           "A railway that once ran 77 miles from Oxford to Cambridge, by way of Bletchley and Bedford, so that dons, undergraduates and the occasional spy could travel between the two universities. Most of it closed in the late 1960s. Parts survive in use, and the missing parts are being rebuilt as East West Rail, which is why you will find a cycle track and a lot of men in hi-vis.")
    sign(z, 32, 18, "THE GREAT OUSE. The fourth-longest river in the UK. It rises in Northamptonshire, wanders through Bedford and Ely, and reaches the Wash at King's Lynn after about 140 miles of not being in a hurry.")
    plaque(z, 44, 30, "w55e_cardington", "The Cardington Sheds",
           "Two enormous airship hangars stand on the Bedfordshire flat. The first was built in 1917 and the second, bigger, in 1927, for the government's R100 and R101 airships. The R101 left Cardington for India in October 1930 and crashed in France on the way. Forty-eight of the fifty-four people aboard died. Britain gave up airships, and the sheds have since been used for storage, research and film sets.")
    plaque(z, 12, 35, "w55e_bunyan", "John Bunyan",
           "Bunyan, a tinker from Elstow, was jailed in Bedford for preaching without a licence in 1660 and spent most of the next twelve years in the county gaol. His great book, The Pilgrim's Progress, grew out of those years and came out in 1678. It has never been out of print. The Bunyan Meeting in Bedford stands where his congregation met.")
    sign(z, 66, 18, "EAST: Sandy, the Lodge, and Cambridge in the distance. The RSPB's headquarters is at The Lodge, Sandy. Expect a lot of binoculars and a very good flapjack.")
    sign(z, 38, 12, "CONCRETE COWS. Milton Keynes, to the west, has had its famous concrete cows since 1978. They have been moved about the town and painted more than once. They have never produced any milk.")
    # --- people
    chat(z, "vl_cyclist", "jogger", 24, 25, "Sustrans Cyclist",
         ["It's a national cycle route now, where the trains used to be. National Route 51. Bletchley to Oxford one way and Cambridge the other.",
          "You can still see where the platforms were. And the signal boxes. And the pie shops that have not noticed."], "down", "still")
    chat(z, "vl_volunteer", "villager_2", 56, 20, "Airship Volunteer",
         ["The R101 was the biggest flying thing in the world. It was nearly as long as the Titanic. It carried fifty-odd people out over France in bad weather, and that was the last we ever knew of her.",
          "We were so proud of her. Then, in a field near Beauvais, we had a funeral."], "left", "still")
    chat(z, "vl_pilgrim", "pilgrim", 10, 34, "Meeting House Guide",
         ["They locked Bunyan up for preaching. He was in Bedford gaol twelve years, off and on. He made shoelaces to support his family and wrote in between.",
          "Pilgrim's Progress. Christian, a heavy pack, a long road. You can see why he'd be a Varsity Line man."], "right", "still")
    chat(z, "vl_codebreaker", "student", 4, 24, "Codebreaker's Granddaughter",
         ["My nan worked at Bletchley Park. She never told us what she did, not till she was eighty. Then she said: 'I broke a very big code'. And went to put the kettle on.",
          "There were about ten thousand people there at the peak, and three out of four were women."], "right", "still")
    # --- trainers
    tr(z, "vl_navvy", "Rail Volunteer Rob", "Railwayman", "rail_guard", [("railspark", 90), ("tickhopper", 91), ("shuttlecog", 90)], 28, 21, "right",
       ["I'm a volunteer on the heritage line. I wave a flag. Occasionally a train waves back. I'm happy."],
       "Signal's at danger. I'll stand down.", "They rebuilt the Marston Vale line and half the stations. It's amazing what you can do if you have enough enthusiasts.", 3700, FLOOR)
    tr(z, "vl_birder", "Birdwatcher Imran", "Birdwatcher", "birdwatcher", [("kitelet", 90), ("starlet", 90), ("hootlet", 91)], 62, 12, "down",
       ["Sandy Heath has a heath, a hill and a very silly number of birds. I've got a list as long as my arm and a worse back."],
       "I've seen worse. But not today.", "The Lodge at Sandy is the RSPB's headquarters. I went on a school trip and never really went home.", 3600, FLOOR)
    tr(z, "vl_scholar", "Don Priscilla", "Scholar", "gown_student", [("tickhopper", 90), ("stagbeet", 91), ("cranelet", 90)], 38, 24, "left",
       ["Between the two universities. A rail journey that should be done in an hour. In practice it took an afternoon. We did our best thinking en route."],
       "Defeat. I'll write it up with footnotes.", "A fellow of St John's once told me you could do your whole degree on the Varsity Line, if you got the timings wrong.", 3800, FLOOR)
    tr(z, "vl_farmer", "Market Gardener Pete", "Farmer", "farmer", [("leveret", 90), ("pipkin", 90), ("barkdeer", 91)], 48, 40, "up",
       ["Bedfordshire clay, brick pits and the best sprouts in England. Everyone laughs. They laugh until they've tried them."],
       "Right. I'll have a lie-down in the sprouts.", "The brick pits north of Bedford fed the London building trade for a hundred years. They're lakes now. Nature moves in fast.", 3600, FLOOR)
    tr(z, "vl_cardington", "Airman Dawn", "Airman", "student", [("stormswift", 91), ("bleeplet", 90), ("starlet", 90)], 50, 21, "down",
       ["They flew airships here, you know. Very big. Very slow. Very flammable, in the early days. I like a plane myself."],
       "You've shot me out of the sky. Clean.", "R100 flew to Canada and back in 1930. A lot better than R101, and a lot less talked about.", 3700, FLOOR)
    # --- wildlife
    wild(z, [("barkdeer", 90, 92, 10, {"time": ["dusk", "night", "dawn"]}), ("stagbeet", 90, 92, 8, {"time": ["dusk", "night"], "season": ["summer"]}),
             ("tickhopper", 90, 92, 10, {}), ("leveret", 90, 92, 10, {"time": ["dawn", "dusk"]}), ("kitelet", 90, 92, 10, {"time": ["day"]}),
             ("starlet", 90, 92, 10, {}), ("swiftlet", 90, 92, 8, {"time": ["day"]}), ("rooklet", 90, 92, 8, {}), ("pipkin", 90, 92, 8, {"time": ["dawn", "day"]}),
             ("hootlet", 90, 92, 8, {"time": ["dusk", "night"]}), ("flittermouse", 90, 92, 6, {"time": ["dusk", "night"]}), ("binfox", 90, 92, 8, {"time": ["dusk", "night", "dawn"]})])
    wild(z, [("volet", 90, 92, 20, {}), ("elverlet", 90, 92, 20, {}), ("stalklet", 90, 92, 20, {}), ("cranelet", 90, 92, 14, {}), ("pollanet", 90, 92, 12, {}), ("minkshade", 90, 92, 10, {})], "water")
    offW = link("bletchley_park", "east", ZID, 22)
    offE = link("cambridge", "west", ZID, 16)
    z.d["edges"] = {"west": {"to": "bletchley_park", "offset": offW}, "east": {"to": "cambridge", "offset": offE}}
    z.d["spawn"] = [3, 22]
    scenery(z, 1000, bushes=22, rocks=8, trees=12, ground=("g", "m"))
    finish_zone(z, ZID)
    for p in check_route(z, [(1, 22), (70, 16)]):
        print("PROBLEM:", p)
    add_place(ZID, 822, 995)
    add_data("poi", [
        poi(ZID, "varsity_stone", (60, 6), "stone", stat="spd",
            lore=["The old milepost still says Oxford on one side and Cambridge on the other. Someone has added a small sticker: 'DELAYED'.",
                  "The real thing is the Varsity Line itself: the railway between Oxford and Cambridge, most of it closed in the late 1960s, now being rebuilt in stages as East West Rail."]),
        poi(ZID, "varsity_cache", (6, 40), "cache", item="four_leaf_clover",
            line="In the old platform edging: a flask, a ticket for the 7.42 to Cambridge, and a clover, pressed in a Ladybird book."),
        poi(ZID, "varsity_camp", (34, 40), "camp", names=[["Scrap Dealer Vic", "Scavenger"], ["Scrap Dealer Jan", "Scavenger"]],
            party=["railspark", "shuttlecog", "binfox"], line="Reclaiming old rail. It's called heritage when somebody else does it.", money=2700, item="iron_snare")])
    add_data("field_spots", [
        fspot(ZID, "varsity_roundup", 22, 38, "round_up", "sheep_gate",
              "Sheep on the old trackbed, all facing the wrong way and all convinced the next train is theirs. {lead} circles, low and quick, and the flock files through the gate like passengers. A signalman's flask is left on the post.",
              {"item": "flask_of_tea", "qty": 1})])
    return z


if __name__ == "__main__":
    build()
    flush_all()
