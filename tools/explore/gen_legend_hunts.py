#!/usr/bin/env python3
"""Writes data/legend_hunts.json: the folklore rumours that point at each legend stood in the world.

Each hunt: id, species, zone (where the legend stands: the map rings it), and one or two rumours, each told once by a
named resident (zone + npc id) and carrying a `clue` for the Fieldbook. Only tales and facts we are sure of go in here;
a legend whose real story we cannot vouch for is left out (Megalorn, Shivertor, the natterjack).
Run from the repo root: python3 tools/explore/gen_legend_hunts.py
"""
import json

H = []

def hunt(id, species, zone, *rumours):
    H.append({"id": id, "species": species, "zone": zone, "rumours": [
        {"zone": z, "npc": n, "text": t, "clue": c} for (z, n, t, c) in rumours]})

hunt("shuck", "shuck", "whitby",
     ("whitby", "wby_oldsalt",
      "The old fisherman squints up at the East Cliff. \"Big black dog, up by the abbey when the sea fog comes in. Eyes like lamps. We call it the Barghest. Mr Stoker had one come ashore here in his book, so we're spoilt for dogs.\"",
      "The clifftop by Whitby Abbey, when the sea fog rolls in."),
     ("york", "york_night_baker",
      "The night baker says the whole east coast has a great black hound. \"Black Shuck down in Norfolk, the Barghest up here. Same dog, different accent. He's choosy who he walks with, mind.\"",
      "Whitby's East Cliff in the fog. He is choosy about company."))

hunt("lambton", "lambton", "penshaw",
     ("newcastle", "ncl_baker",
      "The baker leans over the counter. \"Penshaw Hill, up by the monument. The Lambton Worm coiled round it, after young Lambton fished on a Sunday and tossed the thing down a well. There's a song. Whisht, lads.\"",
      "Penshaw Hill, round the monument. They say it coils there. Sundays, mostly."))

hunt("tchian", "tchian", "jersey_country",
     ("st_helier", "sth_crapaud",
      "The local grins. \"The Black Dog of Bouley Bay. Cliff path, after dark or in the fog, eyes like lamps. They say if you meet him you won't see the year out. Funny how nobody ever gets bitten.\"",
      "The cliff path above Bouley Bay, after dark or in the fog."))

hunt("cusith", "cusith", "faerie_glen",
     ("portree", "por_harbourhand",
      "The harbour hand lowers his voice. \"Faerie Glen, up the Trotternish road, among the little cone hills. A green dog the size of a calf, tail in a plait. It barks three times. The old advice is to be indoors before the third.\"",
      "Faerie Glen on Skye, among the cone hills. It barks three times."))

hunt("nessie", "nessie", "loch_ness",
     ("inverness", "inverness_astronomer",
      "The astronomer prefers stars, but allows it. \"Loch Ness. A monk wrote down a beast in the River Ness in the Life of St Columba, long before anyone had a camera. Try the island, on a still day.\"",
      "Out on the loch by the island, on a still day."))

hunt("ddraig", "ddraig", "dinas_emrys",
     ("llanberis", "castle_guide",
      "The guide points up the valley. \"Dinas Emrys, over by Beddgelert. Vortigern's tower kept falling down, so they dug and found a pool with two dragons asleep in it, red and white. The red one won. It's on the flag.\"",
      "Dinas Emrys, near Beddgelert: the pool under the hill."))

hunt("enbarr", "enbarr", "causeway",
     ("bushmills", "post_clerk",
      "The post clerk stamps a card. \"The Causeway, down where the surf runs along the rock. Manannán's horse, Enbarr, could cross sea as easily as land, they say. Mind the tide, she doesn't.\"",
      "The Giant's Causeway, where the surf runs along the rocks."))

hunt("balor", "balor", "tory_island",
     ("gweedore", "gw_fisher",
      "The fisherman nods out to sea. \"Tory. The east end's Balor's fort, Dún Balor. One eye, and whatever he looked at withered. Tory still has its own king, you know. Nothing withers on his watch.\"",
      "The east end of Tory Island: Balor's fort, the headland."))

hunt("hereward", "hereward", "the_fens",
     ("cambridge", "cam_guide",
      "The tour guide waves a flag at the horizon. \"Out in the Fens, Hereward the Wake held the island at Ely against William the Conqueror. Never caught, the story goes. Look for the beacon.\"",
      "Out in the Fens, by the beacon: Hereward's island."))

hunt("herne", "herne", "sherwood",
     ("nottingham", "not_footie",
      "The jogger stops jogging. \"Herne the Hunter. Antlers, horn, pale horse. He's properly Windsor's, but Sherwood has a go at claiming him. Listen for the horn near the Major Oak.\"",
      "Sherwood Forest, near the Major Oak. Listen for a horn."))

hunt("greenman", "greenman", "glastonbury_tor",
     ("glastonbury", "crystal_seller",
      "The crystal seller drops her voice. \"The Green Man. A face made of leaves, carved in half the church roofs in England. And there's an old orchard tucked in the Tor, if you're asking. I'm not saying. I'm just saying.\"",
      "The old orchard on Glastonbury Tor, among the apple trees."))

hunt("bran", "bran", "london",
     ("london", "london_lamplighter",
      "The lamplighter peers at the Tower. \"The ravens. Six at least, by custom. And in the old Welsh tale it's Brân the Blessed's head buried on the White Hill, facing France, to keep the isles safe. They say that's here.\"",
      "The Tower of London, on the green with the ravens."))

hunt("morrigan", "morrigan", "newgrange_tomb",
     ("newgrange", "ng_archaeologist",
      "The archaeologist nods at the mound. \"Crows. The Morrígan's, if you like the old stories: the crow goddess, more battle than hospitality. She doesn't give herself, they say. She's met. Not a place I'd linger in the passage at dusk.\"",
      "The inner chamber of Newgrange, among the crows."))

hunt("nuckelavee", "nuckelavee", "pentland_coast",
     ("thurso", "th_mason",
      "The mason sets down his hammer. \"Orkney's oldest horror. A horse and rider grown together, no skin on either, up out of the sea. The tales say it can't abide fresh running water. There's not many burns on that shore, mind.\"",
      "The Pentland shore, after dark. Fresh running water is said to turn it."))

hunt("knucker", "knucker", "south_downs",
     ("brighton", "br_old_salt",
      "The old salt says over the Downs there's a knucker hole, a bottomless pond with a dragon in it. \"A lad did for the Lyminster one with a poisoned pie, or pudding, depending who's telling it. Nobody says what went in the pie.\"",
      "A still pool on the Downs, after dark. A pie is part of the old story."))

hunt("silvershod", "silvershod", "lough_gur",
     ("limerick", "lim_treaty_guide",
      "The guide pauses the Treaty Stone patter. \"Lough Gur, out south of us. Gearóid Iarla, the Earl of Desmond, rides out of the water every seven years on a white horse with silver shoes, till the shoes are worn through. At night, naturally.\"",
      "Lough Gur at night: a pale horse with silver shoes on the water."))

hunt("eildonmare", "eildonmare", "scottish_borders",
     ("edinburgh", "edinburgh_lamplighter",
      "The lamplighter hums. \"Thomas the Rhymer met the Queen of Elfland under the Eildon Tree, down in the Borders, and rode off with her for seven years. The ballad has silver bells in the horse's mane. Fifty and nine.\"",
      "The Eildon Tree in the Borders: a white horse with silver bells."))

hunt("taywraith", "taywraith", "dundee",
     ("dundee", "dun_law_walker",
      "The walker points at the water. \"The old Tay Bridge fell in a gale in December 1879, with a train on it. Folk say you can still see the lamps cross at night, out where the stumps are.\"",
      "The stumps of the old Tay Bridge, at night."))

hunt("hairyhands", "hairyhands", "exe_estuary",
     ("exeter", "exe_gran",
      "The gran pats the bench. \"The B3212 over Dartmoor, near Postbridge. Drivers have said for a century that unseen hands wrenched the wheel off them. After dark, naturally. Take the bus.\"",
      "A lay-by on the B3212 over Dartmoor, after dark."))

hunt("cailleach", "cailleach", "oban",
     ("oban", "obn_porter",
      "The pier porter coils a rope. \"Out past Kerrera is the Corryvreckan, the whirlpool. The Cailleach, the old winter hag, washes her plaid in it. When it comes out white, that's winter. Pier gets cold of an evening, mind.\"",
      "The end of Oban pier, when it is bitterly cold."))

hunt("lincolnimp", "lincolnimp", "lincoln",
     ("lincoln", "lin_spire_guide",
      "The spire guide points up. \"The Lincoln Imp. The story is two imps blew in to wreck the cathedral and an angel turned one to stone for cheek. The other ran off. You'll find the carving in the Angel Choir. Don't feed it.\"",
      "Minster Yard, Lincoln, on the wall: a small stone imp."))

hunt("fingalith", "fingalith", "staffa_hollow",
     ("tobermory", "tob_painter",
      "The artist squints at the sea. \"Staffa. Fingal's Cave, An Uamh Bhinn, the melodious cave, and when the swell's right you'll hear why. Mendelssohn wrote an overture about it. It's a hum, really.\"",
      "Fingal's Cave on Staffa, where the columns hum."))

hunt("twaface", "twaface", "enniskillen",
     ("enniskillen", "en_local_wit",
      "The local winks. \"Boa Island, out in Lough Erne. A stone with two faces, back to back, in Caldragh graveyard. Nobody knows who carved it, or why two. Leave a coin, the way you do.\"",
      "The two-faced stone in Caldragh graveyard, Lough Erne. Leave a coin."))

hunt("ormwyrm", "ormwyrm", "gower",
     ("swansea", "swa_tide_chat",
      "The tide man taps the rail. \"Worm's Head, off Rhossili. Named for a worm, the old word for a dragon or a sea serpent, going by the shape. When the swell's right the blowhole booms, and the locals say it's him.\"",
      "The Worm's Head end of Gower, when the swell hits the blowhole."))

hunt("tylwyth", "tylwyth", "douglas",
     ("douglas", "doug_tynwald",
      "The guide smiles. \"The Fairy Bridge, on the Castletown road. Every Manx driver says hello to the little folk going over. It's only polite. There's a reason the roads here are so well mannered.\"",
      "The Fairy Bridge outside Douglas. Say good morning."))

hunt("cobblet", "cobblet", "blaenavon_bigpit_below",
     ("blaenavon", "bla_old",
      "The old man leans on his stick. \"Big Pit. The coblynau knock in the coal, the miners always said. Little fellows who tap where the good seam runs. You listen for the knocking, and you don't laugh.\"",
      "Ninety metres down in Big Pit: listen for knocking at the coal face."))

hunt("roachroo", "roachroo", "the_roaches",
     ("macclesfield", "hiker_flav",
      "The hiker lowers her flask. \"Wallabies on the Roaches. They got out of a private zoo at Swythamley and did very nicely, thank you. Some say not every one has gone. Dawn or dusk, up in the bracken.\"",
      "The Roaches at dawn or dusk, up in the bracken."))

hunt("diaboulder", "diaboulder", "shropshire_hills",
     ("shrewsbury", "shr_drover",
      "The drover tips his hat to the west. \"The Stiperstones. The Devil's Chair, that heap of quartzite on the ridge. When the mist comes down, they say he's sat in it. I've never gone to check.\"",
      "The Devil's Chair on the Stiperstones, when the mist comes down."))

hunt("dodo", "dodo", "oxford_natural",
     ("oxford", "ox_guide",
      "The guide beams. \"The dodo in the Museum of Natural History. A head and a foot, the only soft tissue of a dodo anywhere. Lewis Carroll took the Liddell girls to see it, they say, and Alice did the rest.\"",
      "Oxford's Museum of Natural History, behind glass."))

with open("data/legend_hunts.json", "w") as f:
    f.write("[\n")
    for i, h in enumerate(H):
        f.write("  " + json.dumps(h, ensure_ascii=False) + (",\n" if i < len(H) - 1 else "\n"))
    f.write("]\n")
print(len(H), "hunts,", sum(len(h["rumours"]) for h in H), "rumours")
