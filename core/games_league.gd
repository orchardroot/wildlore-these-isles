class_name GamesLeague
extends RefCounted
## The Isles Games League card (wave 48 G5): every minigame venue in the Isles, by region, with a stamp for each game
## you have played (a bronze rosette or better in PartyPieces state) and three reward letters from the Isles Games
## Society, at 10 stamps, 20 stamps and all of them. Pure logic, no autoload names; ui/league_card.gd draws it and the
## story command {"do": "league"} (story/contest_run.gd) delivers the letters.

const ALL_MIN := 12                 # "all stamps" only counts once the Isles hold at least this many games
const FLAG_PREFIX := "league_letter_"
const TIERS := [
	{"id": "10", "n": 10, "money": 10, "text": "Dear member. Ten stamps on your card, and not one of them for turning up. The committee has met, argued about biscuits, and enclosed a little something. Yours in sport, the Secretary."},
	{"id": "20", "n": 20, "money": 25, "text": "Dear member. Twenty games. The committee has stopped calling you a visitor and started calling you a regular, which in the Isles is nearly a title. A modest purse is enclosed. Yours in sport, the Secretary."},
	{"id": "all", "n": -1, "money": 60, "text": "Dear member. Every stamp on the card. The Isles Games Society has no higher honour, so it has asked the tea urn to stand in your honour. A purse is enclosed, and the urn sends its regards. Yours in sport, the Secretary."},
]

static var _regions: Dictionary = {}

static func _region_of(zone_id: String) -> String:
	if _regions.has(zone_id):
		return _regions[zone_id]
	var z = JsonUtil.read("res://data/zones/%s.json" % zone_id)
	var r := str(z.get("region", "elsewhere")) if z is Dictionary else "elsewhere"
	_regions[zone_id] = r.replace("_", " ").capitalize()
	return _regions[zone_id]

static func _pieces(data) -> Dictionary:
	if "pieces" in data:
		return data.pieces
	var f = data.flag("pieces_stub")
	return f if f is Dictionary else {}

static func plays(data, game_id: String) -> int:
	return int(_pieces(data).get(game_id, {}).get("plays", 0))

static func rosette(data, game_id: String) -> int:
	return int(_pieces(data).get(game_id, {}).get("rosette", 0))

static func best(data, game_id: String) -> float:
	return float(_pieces(data).get(game_id, {}).get("best", 0.0))

## Every game, as rows: {id, name, region, where, stamped, rosette, best, unit}; sorted by region then name.
static func rows(data) -> Array:
	var out: Array = []
	var ents := PartyPieces.entries()
	for id in ents:
		var e: Dictionary = ents[id]
		out.append({"id": str(id), "name": str(e.get("name", id)), "region": _region_of(str(e.get("zone", ""))), "where": str(e.get("where", "")),
			"stamped": plays(data, str(id)) > 0, "rosette": rosette(data, str(id)), "best": best(data, str(id)), "unit": str(e.get("unit", ""))})
	out.sort_custom(func(a, b): return a.region < b.region or (a.region == b.region and a.name < b.name))
	return out

static func stamps(data) -> int:
	var n := 0
	for r in rows(data):
		if bool(r.stamped):
			n += 1
	return n

static func total() -> int:
	return PartyPieces.entries().size()

## The next letter the card is working towards: {label, need, have} or {} when all are earned.
static func next_goal(data) -> Dictionary:
	var have := stamps(data)
	for t in TIERS:
		if data.flag(FLAG_PREFIX + str(t.id)) == true:
			continue
		var need: int = int(t.n) if int(t.n) > 0 else total()
		return {"label": "all %d" % need if int(t.n) < 0 else "%d stamps" % need, "need": need, "have": have}
	return {}

## Letters now earned and not yet delivered; marks each delivered. Each {id, text, money}.
static func due_letters(data) -> Array:
	var have := stamps(data)
	var out: Array = []
	for t in TIERS:
		if data.flag(FLAG_PREFIX + str(t.id)) == true:
			continue
		var ok := false
		if int(t.n) > 0:
			ok = have >= int(t.n)
		else:
			ok = total() >= ALL_MIN and have >= total()
		if ok:
			data.set_flag(FLAG_PREFIX + str(t.id), true)
			out.append({"id": str(t.id), "text": str(t.text), "money": int(t.money)})
	return out

## Dev only (`--menu=league:dev`): plays a few games to fill the card.
static func dev_fill(data) -> void:
	var n := 0
	for id in PartyPieces.entries():
		var e: Dictionary = PartyPieces.entries()[id]
		PartyPieces.record(data, str(id), float(e.get("master", 1)) if n % 3 == 0 else float(e.get("good", 1)) if n % 3 == 1 else 0.0)
		n += 1
		if n >= 7:
			break
