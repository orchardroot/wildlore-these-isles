class_name Search
extends RefCounted
## Behind every door (wave 47): face a bookshelf, dresser, display case, bed, sofa, fireplace, piano or clock in
## a room and press confirm to go through it. What a piece of furniture holds is fixed by a hash of the zone, the
## tile and the week, so the same drawer holds the same thing until it restocks, seven in-game days after you
## searched it. Pure logic, no autoloads; SearchScene talks and plays the sounds.

const TYPES := ["bookshelf", "kitchen_dresser", "display_case", "bed", "sofa", "fireplace", "piano", "clock",
	"specimen_shelf", "tomb_chest", "barrel"]
const RESTOCK_DAYS := 7
const CURIO_KIND := "curio"
const FOUND_PREFIX := "curio_found_"
const ITEM_DIR := "res://data/items/"
const MATERIALS := ["blackberries", "sloes", "hazelnuts", "elderflower", "wild_garlic", "field_mushrooms", "seaweed",
	"heather_honey", "nettles", "slate_chip", "peat", "sheep_wool", "hawthorn_berry", "rowan_berry", "sea_glass", "ammonite",
	"truffle", "honeycomb"]
const SNACKS := ["cup_of_tea", "bakewell_tart", "bara_brith", "soda_bread", "pasty", "tablet", "soda_farl", "yorkshire_pudding",
	"parkin", "pork_pie", "welsh_cakes_tin", "deeside_shortbread", "eccles_cake", "kendal_mint_cake"]
const HEALING := ["cup_of_tea", "flask_of_tea", "buxton_water", "smelling_salts", "bara_brith", "irn_tonic", "eccles_cake", "scouse"]
const RARE_SNARES := ["iron_snare", "night_snare", "water_snare", "silver_snare"]
const NOTHING := {
	"bookshelf": ["Dust, mostly. And a book about fishing that nobody has opened.", "Three paperbacks with the covers off. No luck.", "A shelf of Reader's Digests. Nothing falls out."],
	"kitchen_dresser": ["Socks. Only socks. In a kitchen dresser, which is a choice.", "A drawer of takeaway menus and one dead battery.", "String, elastic bands and a key to nothing."],
	"display_case": ["Locked, or at least stiff. The plates look at you.", "Everything in here is for best, and best is a long way off.", "A china dog, glaring. Nothing else of use."],
	"bed": ["You lift the pillow. A pillow-shaped nothing.", "Under the bed: a slipper, one.", "The duvet hides nothing. Honest bedding."],
	"sofa": ["Down the back of the sofa: crumbs and regret.", "A remote control that is not for this telly.", "Cushions, just cushions."],
	"fireplace": ["Ash and a poker. You get soot on your hands.", "A cold grate and a calendar from 2009.", "Nothing but a draught going up the chimney."],
	"piano": ["You lift the lid. Middle C sticks. Nothing else in there.", "Sheet music for a song you do not know.", "A metronome, paused mid-thought."],
	"clock": ["The clock ticks at you, faintly accusing. Nothing behind it.", "Behind the clock: a spider, a spare key to a different house.", "Ten past ten, as it has been since 1994."],
}
const QUIPS := ["Help yourself. Everyone else does.", "Mind the dust. It has been there longer than me.", "If you find the other sock, it's yours.",
	"Go on, have a rummage. I won't tell.", "That drawer's a mystery to me as well.", "Don't mind me. I'm just watching.", "I wouldn't open that one if I were you. I would, mind.",
	"Anything you find in there, I'll swear I never saw it.", "There's a reason it's in there. I just can't remember it.", "Oh, you're having a look, are you? Fair enough.",
	"Not a lot in there, but you're welcome to it.", "You're very thorough. Have you thought about a career in the Customs?"]

static var _tables: Dictionary = {}
static var _last_zone := ""
static var _last_time := -1000

## The flag a searched piece of furniture is recorded under. Its value is day_count + 1 on the day it was searched.
static func flag_key(zone_id: String, x: int, y: int) -> String:
	return "srch_%s_%d_%d" % [zone_id, x, y]

static func week(data: GameStateData) -> int:
	return data.day_count / 7

## The searchable prop at a tile of an interior, or {}.
static func prop_at(zone: ZoneData, p: Vector2i) -> Dictionary:
	if zone.kind != "interior":
		return {}
	for pr in zone.props:
		if int(pr.get("x", -1)) == p.x and int(pr.get("y", -1)) == p.y:
			return pr if str(pr.get("type", "")) in TYPES else {}
	return {}

## Whether this one is still empty from your last search (it restocks RESTOCK_DAYS days after).
static func searched(data: GameStateData, zone_id: String, x: int, y: int) -> bool:
	var v = data.flag(flag_key(zone_id, x, y))
	if not (v is int or v is float) or int(v) <= 0:
		return false
	return data.day_count + 1 - int(v) < RESTOCK_DAYS

## The room's character from its id and kind: home, study, kitchen, sanctuary, shop, pub, church, other.
static func room(zone: ZoneData) -> String:
	var id := String(zone.id)
	for key in ["sanctuary", "shop", "pub", "inn", "church", "cathedral", "abbey", "museum", "library", "castle", "tearoom", "cafe", "chipp"]:
		if id.contains(key):
			return {"inn": "pub", "cathedral": "church", "abbey": "church", "library": "study", "museum": "study", "castle": "study", "cafe": "kitchen", "tearoom": "kitchen", "chipp": "kitchen"}.get(key, key)
	if id.contains("home") or id.contains("_h") or id.contains("house") or id.contains("cottage"):
		return "home"
	return "other"

## What the furniture holds this week: {"item": id, "n": 1, "line"}, {"money": pence, "line"}, {"curio": id, "line"}
## or {"nothing": true, "line"}. Deterministic in (zone, tile, week, rng_seed).
static func stash(zone: ZoneData, prop: Dictionary, data: GameStateData, rng_seed := 0) -> Dictionary:
	var x := int(prop.get("x", 0))
	var y := int(prop.get("y", 0))
	var type := str(prop.get("type", ""))
	var rng := Rng.new(("%s|%d|%d|%d|%d" % [zone.id, x, y, week(data), rng_seed]).hash())
	var r := rng.roll_int(0, 99)
	var kind := room(zone)
	var nothing_to := 33
	var common_to := 66
	var coin_to := 86
	var curio_to := 98
	if kind == "study" or type in ["display_case", "specimen_shelf", "tomb_chest"]:
		nothing_to = 25  # a study or a display case gives more curios
		common_to = 50
		coin_to = 66
		curio_to = 96
	elif kind == "sanctuary":
		nothing_to = 20
		common_to = 76
		coin_to = 84
		curio_to = 95
	if r < nothing_to:
		return {"nothing": true, "line": _nothing_line(type, rng)}
	if r < common_to:
		var id := _common(kind, type, zone, rng)
		return {"item": id, "n": 1, "line": ""}
	if r < coin_to:
		return {"money": rng.roll_int(20, 300), "line": ""}
	if r < curio_to:
		return {"curio": rng.pick(curio_ids()), "line": ""}
	var f := _find(rng)
	if f == "":
		return {"curio": rng.pick(curio_ids()), "line": ""}
	return {"item": f, "n": 1, "line": "", "rare": true}

static func _nothing_line(type: String, rng: Rng) -> String:
	var lines: Array = NOTHING.get(type, ["You have a good look. Nothing."])
	return str(lines[rng.roll_int(0, lines.size() - 1)])

static func _common(kind: String, type: String, zone: ZoneData, rng: Rng) -> String:
	if kind == "sanctuary":
		return str(rng.pick(HEALING))
	if kind == "shop":
		var stock := shop_stock(String(zone.id))
		if not stock.is_empty():
			return str(rng.pick(stock))
	if kind in ["kitchen", "pub"] or type == "kitchen_dresser":
		return str(rng.pick(SNACKS))
	return str(rng.pick(MATERIALS if rng.chance(50) else SNACKS))

## A shop's own cheap stock, for its back room (nothing if it has no shop file).
static func shop_stock(zone_id: String) -> Array:
	var key := "shop_" + zone_id
	if not _tables.has(key):
		var out := []
		var path := "res://data/shops/%s.json" % zone_id
		if FileAccess.file_exists(path):
			var j = JSON.parse_string(FileAccess.get_file_as_string(path))
			if j is Dictionary:
				for id in j.get("stock", []):
					if _price_of(str(id)) <= 1500:
						out.append(str(id))
		_tables[key] = out
	return _tables[key]

static func _price_of(id: String) -> int:
	for p in _all_items():
		if str(p.get("id", "")) == id:
			return int(p.get("price", 0))
	return 0

static func _all_items() -> Array:
	if not _tables.has("all"):
		var out := []
		for f in ["healing", "materials", "snares", "crafted_snares", "charms", "w47_a", "w47_d"]:
			out.append_array(_read_items(f))
		_tables["all"] = out
	return _tables["all"]

static func _read_items(name: String) -> Array:
	var path := ITEM_DIR + name + ".json"
	if not FileAccess.file_exists(path):
		return []
	var j = JSON.parse_string(FileAccess.get_file_as_string(path))
	return j if j is Array else []

## The 60 curios, in file order.
static func curio_ids() -> Array:
	if not _tables.has("curios"):
		var out := []
		for it in _read_items("w47_a"):
			if str(it.get("kind", "")) == CURIO_KIND:
				out.append(str(it.id))
		_tables["curios"] = out
	return _tables["curios"]

## Ids of chapbooks if session D's file exists (read at runtime, no dependency on its code).
static func chapbook_ids() -> Array:
	if not _tables.has("chaps"):
		var out := []
		for it in _read_items("w47_d"):
			if str(it.get("kind", "")) == "chapbook":
				out.append(str(it.id))
		_tables["chaps"] = out
	return _tables["chaps"]

static func charm_ids() -> Array:
	if not _tables.has("charms"):
		var out := []
		for it in _read_items("charms"):
			out.append(str(it.id))
		_tables["charms"] = out
	return _tables["charms"]

static func _find(rng: Rng) -> String:
	var pool := []
	pool.append_array(charm_ids())
	pool.append_array(RARE_SNARES)
	pool.append_array(chapbook_ids())
	return str(rng.pick(pool)) if not pool.is_empty() else ""

## Every item id the loot tables can hand out (for the tests: each must exist in the ItemDB).
static func all_table_ids() -> Array:
	var out := []
	for src in [MATERIALS, SNACKS, HEALING, RARE_SNARES, charm_ids(), chapbook_ids(), curio_ids()]:
		out.append_array(src)
	return out

## A resident's wry word, once per visit to a room (a long gap between searches counts as a new visit).
static func quip(zone: ZoneData, data: GameStateData) -> String:
	var now := data.world_minutes()
	var fresh := _last_zone != String(zone.id) or now - _last_time >= 20
	_last_zone = String(zone.id)
	_last_time = now
	if not fresh or zone.kind != "interior" or zone.npcs.is_empty():
		return ""
	var h := ("%s|%d" % [zone.id, data.day_count]).hash()
	return str(QUIPS[absi(h) % QUIPS.size()])

## Goes through a piece of furniture: marks it searched, hands over the find, tallies it. Returns
## {lines: Array, gave: bool, curio: bool, rare: bool}. `items` is the ItemDB (or null in tests).
static func take(zone: ZoneData, prop: Dictionary, data: GameStateData, items, rng_seed := 0) -> Dictionary:
	var x := int(prop.get("x", 0))
	var y := int(prop.get("y", 0))
	if searched(data, String(zone.id), x, y):
		return {"lines": ["You've already been through this one. Give it a week."], "gave": false, "curio": false, "rare": false, "again": true}
	var s := stash(zone, prop, data, rng_seed)
	data.set_flag(flag_key(String(zone.id), x, y), data.day_count + 1)
	TrainerStats.add(data, "searches")
	var lines: Array = []
	var gave := false
	var curio := false
	if s.has("nothing"):
		lines.append(str(s.line))
	elif s.has("money"):
		var m := int(s.money)
		data.money += m
		lines.append("Tucked away: %s in loose change." % Wallet.fmt(m))
		gave = true
	else:
		var id := str(s.get("item", s.get("curio", "")))
		curio = s.has("curio")
		var n := int(s.get("n", 1))
		data.bag[id] = mini(Bag.MAX_STACK, int(data.bag.get(id, 0)) + n)
		var it: Dictionary = items.get_item(id) if items != null and items.has(id) else {}
		var nm := str(it.get("name", id))
		if curio:
			var first := not ZoneData.flag_on(data.flag(FOUND_PREFIX + id))
			data.set_flag(FOUND_PREFIX + id, true)
			TrainerStats.add(data, "curios_found")
			lines.append("Wrapped in a hanky: %s." % str(it.get("one", nm)))
			if first:
				lines.append("A new one for the Curios page.")
		else:
			lines.append("You found %s." % str(it.get("one", nm)))
		gave = true
	return {"lines": lines, "gave": gave, "curio": curio, "rare": bool(s.get("rare", false)), "again": false}

## Curios found so far, in file order.
static func found(data: GameStateData) -> Array:
	return curio_ids().filter(func(id): return ZoneData.flag_on(data.flag(FOUND_PREFIX + str(id))))

static func found_count(data: GameStateData) -> int:
	return found(data).size()

## The pat on the back for 20, 40 and 60 curios, or "".
static func pat_on_back(n: int) -> String:
	if n >= 60:
		return "The full set. You are, officially, a magpie with taste."
	if n >= 40:
		return "Forty. The mantelpiece is getting nervous."
	if n >= 20:
		return "Twenty. That's a proper shelf's worth. Well done."
	return ""
