class_name HomeExtras
extends RefCounted
## 3.1 home and garden, the logic (the look is world/home_extras_meshes.gd, the hooks world/home_extras_scene.gd).
##  - souvenirs: one for each of a score of towns, earned by reading any Gazetteer plaque there. Set them on the
##    shelf and the cabinet in Mum's house (slot n is the flag home_souv_<n> = souvenir id).
##  - plaque boards: how many heritage plaques you've read in each nation, as framed boards on the wall.
##  - the garden's bird table, bug hotel and pond: each has one visitor a day, picked by the season. Befriend it for
##    a small gift (and, once it knows you, something special) or try to catch it. Flags: home_visit_<feature> = the
##    day it last came, home_pal_<species> = how many times you've befriended it.
## Everything is a flag with a safe default, so old saves load as an empty shelf and a quiet garden. Pure logic.

const SLOT_PREFIX := "home_souv_"
const VISIT_PREFIX := "home_visit_"
const PAL_PREFIX := "home_pal_"
const PROJECT_PREFIX := "kp_"
const SLOTS := 12
const FRIEND_REWARD_AT := 5

## [id, town (a Gazetteer town), name, shape, colour, second colour, the line when you look at it].
const _S := [
	["blackpool_rock", "blackpool", "Stick of Blackpool Rock", "stick", "e8467c", "fff4f0", "Pink all the way through, with BLACKPOOL down the middle. Mum has banned biting it."],
	["toby_jug", "stoke", "Toby Jug from Stoke", "jug", "7a4a2a", "e8d8a8", "A jolly gentleman in a tricorn hat, in glazed Staffordshire pottery. His smile follows you round the room."],
	["viking_helmet", "york", "Viking Helmet from York", "helmet", "9a9a9a", "efe6c8", "Horns and all. The horns are historically wrong, but nobody tells the cat."],
	["keswick_pencil", "keswick", "Giant Keswick Pencil", "pencil", "e0b020", "3a3a3a", "A pencil the length of your arm, from the home of the pencil. Far too grand to sharpen."],
	["whitby_jet", "whitby", "Whitby Jet", "bead", "15151a", "50505c", "Polished black jet from the Whitby cliffs. It is fossilised tree, which feels like cheating."],
	["pilgrim_badge", "canterbury", "Canterbury Pilgrim Badge", "badge", "9a9aa8", "c8c8d8", "A pewter pilgrim's badge. Chaucer's lot collected these. Mum collects the compliments."],
	["liver_bird", "liverpool", "Liver Bird", "figure", "3a6a52", "d8c878", "A little Liver Bird on a base. It has, as always, one eye on the Mersey and one on the sandwiches."],
	["welsh_dragon", "cardiff", "Welsh Dragon", "figure", "c8302a", "f2f2f2", "A red dragon with an attitude problem and a very good cause. Y Ddraig Goch, Mum says."],
	["slate_coaster", "llanberis", "Slate Coaster", "coaster", "4a5560", "6a7580", "A coaster of Llanberis slate, cut so square it would pass an inspection. It holds a mug, and a grudge."],
	["miners_lamp", "blaenavon", "Miner's Lamp", "lamp", "c9a541", "f8e8a0", "A little lamp from Blaenavon, where they dug the coal that shaped the valleys. It does not light, but it glows with pride."],
	["shortbread_tin", "edinburgh", "Edinburgh Shortbread Tin", "tin", "2f5fa0", "e8e0b0", "A tartan tin from Edinburgh. There has not been shortbread in it since 2019, but you can still smell it."],
	["nessie_plush", "loch_ness", "Nessie Plush", "figure", "5c8a5c", "f2e8c0", "A soft Nessie from the shores of Loch Ness. Evidence, said the shop. Mum bought two."],
	["highland_cow", "portree", "Highland Coo", "figure", "b8602a", "e8d098", "A shaggy ginger coo from Skye, fringe over the eyes. It sees nothing. It judges everything."],
	["golf_ball", "st_andrews", "St Andrews Golf Ball", "ball", "f4f4f0", "d0d0d0", "A golf ball from the home of golf. Never been hit. Never will be."],
	["tweed_swatch", "harris", "Harris Tweed Swatch", "cloth", "7a6a4a", "b09a6a", "A square of Harris Tweed, woven on the island. Smells faintly of rain and good decisions."],
	["claddagh_ring", "galway", "Claddagh Ring", "ring", "d8b040", "c83040", "Two hands, a heart and a crown: love, loyalty and friendship. Worn with the heart turned in, it says yours is taken."],
	["kells_bookmark", "dublin", "Book of Kells Bookmark", "badge", "3f7a4a", "e0b830", "A bookmark with a page of interlace from the Book of Kells. Mum uses it for the crossword."],
	["hurley", "kilkenny", "Miniature Hurley", "stick", "b89860", "d8c088", "A tiny hurley, ash wood, signed by someone who looked busy. Kilkenny will tell you about it at length."],
	["limerick_lace", "limerick", "Limerick Lace", "cloth", "f4f0e6", "e0d8c0", "A doily of real Limerick lace. Finer than anything else in the house, and Mum knows it."],
	["basalt_column", "causeway", "Basalt Column Magnet", "coaster", "3a3a40", "5a5a62", "A hexagonal fridge magnet of the Giant's Causeway. Fionn mac Cumhaill would approve."],
	["belfast_crane", "belfast", "Model Crane", "lamp", "d8a020", "2a2a30", "A little yellow shipyard crane, the sort that has stood over Belfast longer than most of its people."],
	["manx_cat", "douglas", "Manx Cat", "figure", "b8a070", "f0e0b0", "A china Manx cat, rumpy as the real thing. Meadow looked at it, then at you, then walked off."],
]

const FEATURES := {
	"bird_table": {"name": "bird table", "gift": "hawthorn_berry", "reward": "oak_acorn",
		"visitors": {"spring": "swiftlet", "summer": "kitelet", "autumn": "rooklet", "winter": "buntling"}},
	"bug_hotel": {"name": "bug hotel", "gift": "honeycomb", "reward": "rowan_sprig",
		"visitors": {"spring": "midgie", "summer": "flyling", "autumn": "stagbeet", "winter": "glowmite"}},
	"pond": {"name": "pond", "gift": "field_mushrooms", "reward": "four_leaf_clover",
		"visitors": {"spring": "croakle", "summer": "natterjack", "autumn": "dipling", "winter": "bittling"}},
}

static var SOUVENIRS: Array = _build()

static func _build() -> Array:
	var out := []
	for s in _S:
		out.append({"id": s[0], "town": s[1], "name": s[2], "shape": s[3], "col": Color(str(s[4])), "col2": Color(str(s[5])), "line": s[6]})
	for p in TownProjects.all():  # w56: a finished town project leaves a keepsake for the shelf too
		var k: Variant = p.get("effects", {}).get("keepsake", null)
		if k is Dictionary:
			out.append({"id": PROJECT_PREFIX + str(p.id), "town": "", "project": str(p.id), "name": str(k.name), "shape": str(k.shape),
				"col": Color(str(k.col)), "col2": Color(str(k.col2)), "line": str(k.line)})
	out.append_array(RouteChampions.keepsakes())  # w57: each Walkers' League title leaves a keepsake too
	return out

static func souvenir(id: String) -> Dictionary:
	for s in SOUVENIRS:
		if s.id == id:
			return s
	return {}

# --- souvenirs ---------------------------------------------------------------------------------

## Souvenir ids earned: any plaque read in the town, or the town project finished (w56).
static func unlocked(d: GameStateData, plaques: Array = []) -> Array:
	var list: Array = plaques if not plaques.is_empty() else Gazetteer.all()
	var towns := {}
	for p in list:
		if Gazetteer.is_read(d, str(p.id)):
			towns[str(p.town)] = true
	return SOUVENIRS.filter(func(s): return towns.has(s.town) or (s.has("project") and TownProjects.is_done(d, str(s.project))) or (s.has("league") and RouteChampions.beaten_count(d) >= int(s.league))).map(func(s): return s.id)

static func slot(d: GameStateData, n: int) -> String:
	var v: Variant = d.flag(SLOT_PREFIX + str(n))
	return str(v) if v is String else ""

## Sets souvenir `id` in slot n (taking it off wherever it was). False if you haven't earned it.
static func place(d: GameStateData, n: int, id: String, plaques: Array = []) -> bool:
	if n < 1 or n > SLOTS or id not in unlocked(d, plaques):
		return false
	for i in range(1, SLOTS + 1):
		if slot(d, i) == id:
			clear(d, i)
	d.set_flag(SLOT_PREFIX + str(n), id)
	return true

static func clear(d: GameStateData, n: int) -> void:
	d.flags.erase(SLOT_PREFIX + str(n))

# --- the plaque boards -------------------------------------------------------------------------

## [{nation, name, read, total}] in Standing order.
static func boards(d: GameStateData, plaques: Array = []) -> Array:
	var list: Array = plaques if not plaques.is_empty() else Gazetteer.all()
	var out := []
	for nation in Standing.NATIONS:
		var total := 0
		var read := 0
		for p in list:
			if str(p.nation) == nation:
				total += 1
				if Gazetteer.is_read(d, str(p.id)):
					read += 1
		out.append({"nation": nation, "name": Standing.NAMES[nation], "read": read, "total": total})
	return out

static func board_lines(d: GameStateData, plaques: Array = []) -> Array:
	var b := boards(d, plaques)
	var read := 0
	for x in b:
		read += int(x.read)
	if read == 0:
		return ["Six empty frames, waiting for the Gazetteer. Mum had them done at the framer's before you'd read a single plaque. Optimist."]
	var lines := ["Mum has framed your Gazetteer, nation by nation. %d plaques read so far." % read]
	for x in b:
		if int(x.total) == 0:
			continue
		var tail := " Every one. Mum has put a star on it." if int(x.read) >= int(x.total) else ""
		lines.append("%s: %d of %d.%s" % [x.name, x.read, x.total, tail])
	return lines

# --- the garden's visitors ---------------------------------------------------------------------

static func visitor(feature: String, season: String) -> String:
	return str(FEATURES[feature].visitors.get(season, FEATURES[feature].visitors.spring))

static func visitor_here(d: GameStateData, feature: String) -> bool:
	var v: Variant = d.flag(VISIT_PREFIX + feature)
	return not (v is int or v is float) or int(v) != d.day_count

static func mark_visited(d: GameStateData, feature: String) -> void:
	d.set_flag(VISIT_PREFIX + feature, d.day_count)

static func friends(d: GameStateData, species: String) -> int:
	var v: Variant = d.flag(PAL_PREFIX + species)
	return int(v) if v is int or v is float else 0

## Befriends today's visitor: a small gift into the bag, and at FRIEND_REWARD_AT visits something special (once).
## Returns {species, gift, reward, friends}; gift is "" when the bag is too full to take it.
static func befriend(d: GameStateData, feature: String, season: String) -> Dictionary:
	var f: Dictionary = FEATURES[feature]
	var sp := visitor(feature, season)
	mark_visited(d, feature)
	var n := friends(d, sp) + 1
	d.set_flag(PAL_PREFIX + sp, n)
	var bag := Bag.new(d.bag)
	var gift: String = str(f.gift) if bag.add(str(f.gift), 1) > 0 else ""
	var reward := ""
	if n == FRIEND_REWARD_AT and bag.add(str(f.reward), 1) > 0:
		reward = str(f.reward)
	return {"species": sp, "gift": gift, "reward": reward, "friends": n}

## The level of a creature you try to catch in the garden: a bit behind your best, so it's a pleasant tussle.
static func visit_level(top_party_level: int) -> int:
	return clampi(top_party_level - 6, 3, 25)

## --home=full|ready|mixed: read a plaque in most souvenir towns and put the first dozen on show, plus a few boards' worth.
static func dev_setup(d: GameStateData) -> void:
	var done := {}
	for p in Gazetteer.all():
		var t := str(p.town)
		if not done.has(t) or int(done[t]) < 3:
			var is_souv := false
			for s in SOUVENIRS:
				is_souv = is_souv or s.town == t
			if is_souv or str(p.nation) in ["england", "wales"]:
				d.set_flag(Gazetteer.flag_key(str(p.id)))
				done[t] = int(done.get(t, 0)) + 1
	var n := 1
	for id in unlocked(d):
		if n <= SLOTS:
			place(d, n, str(id))
			n += 1
