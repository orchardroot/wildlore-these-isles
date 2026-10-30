class_name Chapbooks
extends RefCounted
## Chapbooks: cheap ballad sheets, sold by chapmen, that teach a creature a move (the game's TMs). A book is kept
## for good, so one teaches as many creatures as can learn it. Pure logic: the Bag does the learn/forget prompt.

const KIND := "chapbook"
const TOWNS := ["macclesfield", "buxton", "manchester", "chester", "shrewsbury", "cardiff", "bristol", "york",
	"newcastle", "edinburgh", "inverness", "belfast", "dublin", "galway"]
const ROTATE := 3  # books a chapman has out of stock in any one week

const CAN := "can"
const KNOWS := "knows"
const CANT := "cant"

## The move an item teaches, or "".
static func move_of(item: Dictionary) -> String:
	return str(item.get("move", "")) if str(item.get("kind", "")) == KIND else ""

## A creature can be taught a move whose type is one of its types, a kin move, or one its species lists under
## "chapbooks". Already known: no.
static func can_learn(c: Creature, move_id: String, move_db: MoveDB) -> bool:
	return status(c, move_id, move_db) == CAN

## CAN, KNOWS or CANT, for the Bag's picker.
static func status(c: Creature, move_id: String, move_db: MoveDB) -> String:
	if c == null or not move_db.has(move_id):
		return CANT
	if c.has_move(move_id):
		return KNOWS
	var t := str(move_db.get_move(move_id).get("type", ""))
	if t == "kin" or t in c.types() or move_id in c.species.get("chapbooks", []):
		return CAN
	return CANT

static func label(st: String) -> String:
	return {CAN: "Can learn", KNOWS: "Knows it"}.get(st, "Can't")

## The week number (whole weeks since 1970) of a "YYYY-MM-DD" key, so a pick is the same all week.
static func week_of(day_key: String) -> int:
	var p := day_key.split("-")
	if p.size() != 3:
		return 0
	var secs := Time.get_unix_time_from_datetime_dict({"year": int(p[0]), "month": int(p[1]), "day": int(p[2]), "hour": 0, "minute": 0, "second": 0})
	return int(secs / 604800.0)

## What the chapman has on the shelf this week: his whole shop file less ROTATE books (never the staples, the first
## four on the list), chosen from town and week alone.
static func stock(town: String, week: int, full: Array) -> Array:
	var movable := full.slice(4) if full.size() > 4 + ROTATE else []
	var out := full.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [town, week])
	for _i in mini(ROTATE, movable.size()):
		var pick: Variant = movable[rng.randi_range(0, movable.size() - 1)]
		movable.erase(pick)
		out.erase(pick)
	return out

## A shop dictionary as the shop screen should show it this week (other shops come back unchanged).
static func shop_for_week(shop: Dictionary, week: int) -> Dictionary:
	var id := str(shop.get("id", ""))
	if not id.begins_with("chapman_"):
		return shop
	var s := shop.duplicate()
	s["stock"] = stock(id.substr(8), week, shop.get("stock", []))
	return s

## Dev/validator: everything wrong with the chapbook items and the chapmen's placements.
static func problems(db: ItemDB, moves: MoveDB) -> Array:
	var e := []
	var n := 0
	for id in db.ids():
		var it := db.get_item(id)
		if str(it.get("kind", "")) != KIND:
			continue
		n += 1
		if not moves.has(str(it.get("move", ""))):
			e.append("chapbook %s: move '%s' does not exist" % [id, it.get("move", "")])
		if str(it.get("name", "")) != "Chapbook: " + str(moves.get_move(str(it.get("move", ""))).get("name", "?")):
			e.append("chapbook %s: name should be 'Chapbook: <Move Name>'" % id)
		if int(it.get("price", 0)) < 400 or int(it.get("price", 0)) > 3000:
			e.append("chapbook %s: price outside 400..3000" % id)
	if n == 0:  # a hand-made item set (tests) has no chapmen to check
		return e
	for t in TOWNS:
		var shop: Dictionary = db.shops.get("chapman_" + t, {})
		if shop.is_empty():
			e.append("chapman %s: no shop file" % t)
			continue
		var sz: int = shop.get("stock", []).size()
		if sz < 10 or sz > 14:
			e.append("chapman %s: stocks %d books, wants 10 to 14" % [t, sz])
		for b in shop.get("stock", []):
			if str(db.get_item(str(b)).get("kind", "")) != KIND:
				e.append("chapman %s: '%s' is not a chapbook" % [t, b])
		e.append_array(_placement(t))
	return e

static func _placement(t: String) -> Array:
	var z := ZoneData.load_id(t)
	if z == null:
		return ["chapman %s: zone missing" % t]
	var npc := {}
	for n in z.npcs:
		if str(n.get("id", "")) == "chapman_" + t:
			npc = n
	if npc.is_empty():
		return ["chapman %s: npc not in the zone" % t]
	var p := Vector2i(int(npc.x), int(npc.y))
	if not z.walkable(p):
		return ["chapman %s: stands on an unwalkable tile" % t]
	if not z.reachable(z.spawn).has(p):
		return ["chapman %s: cannot be reached from the spawn" % t]
	var beside := false
	for pr in z.props:
		if str(pr.get("type", "")) == "market_stall" and absi(int(pr.x) - p.x) + absi(int(pr.y) - p.y) == 1:
			beside = true
	if not beside:
		return ["chapman %s: not beside a market_stall" % t]
	var f := FileAccess.open("res://data/dialogue/%s.json" % t, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
	if not (d is Dictionary) or not d.has("chapman_" + t):
		return ["chapman %s: no script" % t]
	var has_shop := false
	for c in d["chapman_" + t]:
		if str(c.get("do", "")) == "shop" and str(c.get("id", "")) == "chapman_" + t:
			has_shop = true
	return [] if has_shop else ["chapman %s: script has no shop command" % t]
