class_name Wants
extends RefCounted
## Residents with wants (wave 47 C). data/trades/<region>.json: {"trades": [{id, zone, npc, wants: {item, n},
## gives: {item, n} | {money}, ask, thanks, repeat}]}. data/trades/traders.json: {"traders": [{zone, npc, shop, line}]},
## the front-room shops (data/shops/home_<zone>.json) a resident opens after their chat. Everything arrives through
## ScriptHooks: `hook` appends to the resident's script, so no dialogue file is edited. State is flags only:
##   tr_<id>_done   a one-off trade has been made
##   tr_<id>_day    a repeatable trade's DailyKey stamp (once a day)
##   tr_<id>_ask    the day the ask was last voiced (so it doesn't nag)
## Pure logic, no autoload names: the validator loads it.

const DIR := "res://data/trades"
const TRADERS_FILE := "traders"
const PICK := "_tr_pick"  # the scratch flag a choice writes
const WHO := "Resident"

static var _loaded := false
static var _by_npc := {}    # "zone|npc" -> [trade]
static var _by_id := {}
static var _traders := {}   # "zone|npc" -> trader
static var _db: ItemDB = null

static func _items() -> ItemDB:
	if _db == null:
		_db = ItemDB.load_default()
	return _db

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	_by_npc = {}
	_by_id = {}
	_traders = {}
	for path in JsonUtil.list_json(DIR):
		var d: Variant = JsonUtil.read(path)
		if not (d is Dictionary):
			continue
		for t in d.get("trades", []):
			if t is Dictionary:
				var key := "%s|%s" % [t.get("zone", ""), t.get("npc", "")]
				if not _by_npc.has(key):
					_by_npc[key] = []
				_by_npc[key].append(t)
				_by_id[str(t.get("id", ""))] = t
		for tr in d.get("traders", []):
			if tr is Dictionary:
				_traders["%s|%s" % [tr.get("zone", ""), tr.get("npc", "")]] = tr

static func reset() -> void:
	_loaded = false
	_db = null

static func all() -> Array:
	_load()
	return _by_id.values()

static func traders() -> Array:
	_load()
	return _traders.values()

static func get_trade(id: String) -> Dictionary:
	_load()
	return _by_id.get(id, {})

static func for_npc(zone_id: String, npc_id: String) -> Array:
	_load()
	return _by_npc.get("%s|%s" % [zone_id, npc_id], [])

static func trader_for(zone_id: String, npc_id: String) -> Dictionary:
	_load()
	return _traders.get("%s|%s" % [zone_id, npc_id], {})

static func is_open(data: GameStateData, t: Dictionary) -> bool:
	var id := str(t.get("id", ""))
	if bool(t.get("repeat", false)):
		return not DailyKey.done_today(data, "tr_%s_day" % id)
	return data.flag("tr_%s_done" % id) != true

## The player carries what the resident wants.
static func can_pay(data: GameStateData, t: Dictionary) -> bool:
	var w: Dictionary = t.get("wants", {})
	return Bag.new(data.bag).count(str(w.get("item", ""))) >= int(w.get("n", 1))

## The bag has room for what they give (money always fits).
static func has_room(data: GameStateData, t: Dictionary) -> bool:
	var g: Dictionary = t.get("gives", {})
	if not g.has("item"):
		return true
	var w: Dictionary = t.get("wants", {})
	var held := Bag.new(data.bag).count(str(g.item))
	if str(g.item) == str(w.get("item", "")):
		held -= int(w.get("n", 1))
	return held + int(g.get("n", 1)) <= Bag.MAX_STACK

## Makes the swap. Returns the line to show ("" when it can't be done and nothing changed).
static func pay(data: GameStateData, t: Dictionary) -> String:
	if not can_pay(data, t) or not has_room(data, t):
		return ""
	var bag := Bag.new(data.bag)
	var w: Dictionary = t.wants
	bag.remove(str(w.item), int(w.get("n", 1)))
	var got := ""
	var g: Dictionary = t.get("gives", {})
	if g.has("item"):
		bag.add(str(g.item), int(g.get("n", 1)))
		got = _items().get_item(str(g.item)).get("name", str(g.item))
	else:
		data.money += int(g.get("money", 0))
		got = "£%d" % int(g.get("money", 0))
	var id := str(t.get("id", ""))
	if bool(t.get("repeat", false)):
		data.set_flag("tr_%s_day" % id, DailyKey.stamp(data))
	else:
		data.set_flag("tr_%s_done" % id, true)
	return "You hand over %s. Received %s." % [_want_text(t), got]

static func _want_text(t: Dictionary) -> String:
	var w: Dictionary = t.get("wants", {})
	var nm: String = _items().get_item(str(w.get("item", ""))).get("name", str(w.get("item", "")))
	var n := int(w.get("n", 1))
	return nm if n <= 1 else "%d x %s" % [n, nm]

static func _say(text: String) -> Dictionary:
	return {"do": "say", "who": WHO, "text": text}

## ScriptHooks entry: the resident's trade, then their front-room shop. Cheap: a dictionary lookup.
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	var key := "%s|%s" % [zone_id, npc_id]
	if not _loaded:
		_load()
	if not _by_npc.has(key) and not _traders.has(key):
		return commands
	var out := commands.duplicate()
	for t in _by_npc.get(key, []):
		if not is_open(data, t):
			continue
		var id := str(t.get("id", ""))
		if can_pay(data, t) and has_room(data, t):
			var what := _want_text(t)
			out.append(_say(str(t.get("ask", ""))))
			out.append({"do": "choice", "text": "Give them %s?" % what, "options": ["Give them %s" % what, "Not now"], "set": PICK})
			out.append({"do": "if", "flag": PICK, "eq": 0, "then": [_say(str(t.get("thanks", "Thank you."))), {"do": "trade", "op": "swap", "id": id}]})
		else:
			out.append({"do": "daily", "key": "tr_%s_ask" % id, "then": [_say(str(t.get("ask", "")))]})
	var tr: Dictionary = _traders.get(key, {})
	if not tr.is_empty():
		out.append(_say(str(tr.get("line", "I sell a few bits."))))
		out.append({"do": "choice", "text": "Have a look?", "options": ["Have a look", "Maybe later"], "set": PICK})
		out.append({"do": "if", "flag": PICK, "eq": 0, "then": [{"do": "shop", "id": str(tr.get("shop", ""))}]})
	return out

## The "trade" story command: {"op": "swap", "id": trade} or {"op": "errand", "id": quest}. Returns the line to show.
static func apply(data: GameStateData, c: Dictionary) -> String:
	if str(c.get("op", "")) == "errand":
		return Errands.reward(data, str(c.get("id", "")))
	var line := pay(data, get_trade(str(c.get("id", ""))))
	return line if line != "" else "You haven't quite got what they asked for."

## Validator: every trade and trader points at a real zone, npc, item and shop; text present, no em-dashes.
static func check(zones: Dictionary, items: ItemDB) -> Array:
	_load()
	var errors := []
	var seen := {}
	for t in _by_id.values():
		var id := str(t.get("id", "?"))
		var tag := "trade %s" % id
		if seen.has(id):
			errors.append(tag + ": duplicate id")
		seen[id] = true
		errors.append_array(_check_at(tag, str(t.get("zone", "")), str(t.get("npc", "")), zones))
		var w: Dictionary = t.get("wants", {})
		if not items.has(str(w.get("item", ""))) or int(w.get("n", 0)) < 1:
			errors.append(tag + ": wants '%s' x%s is not an item" % [w.get("item", ""), w.get("n", "")])
		var g: Dictionary = t.get("gives", {})
		if g.has("item"):
			if not items.has(str(g.item)):
				errors.append(tag + ": gives unknown item '%s'" % g.item)
		elif int(g.get("money", 0)) <= 0:
			errors.append(tag + ": gives nothing")
		for k in ["ask", "thanks"]:
			if str(t.get(k, "")) == "":
				errors.append(tag + ": no " + k)
			elif str(t[k]).contains("—"):
				errors.append(tag + ": " + k + " has an em-dash")
	for tr in _traders.values():
		var tag := "trader %s/%s" % [tr.get("zone", ""), tr.get("npc", "")]
		errors.append_array(_check_at(tag, str(tr.get("zone", "")), str(tr.get("npc", "")), zones))
		if not items.shops.has(str(tr.get("shop", ""))):
			errors.append(tag + ": no shop '%s'" % tr.get("shop", ""))
		if str(tr.get("line", "")).contains("—"):
			errors.append(tag + ": line has an em-dash")
	return errors

static func _check_at(tag: String, zone_id: String, npc_id: String, zones: Dictionary) -> Array:
	if not zones.has(zone_id):
		return [tag + ": unknown zone '%s'" % zone_id]
	for n in zones[zone_id].npcs:
		if str(n.get("id", "")) == npc_id:
			return []
	return [tag + ": no npc '%s' in %s" % [npc_id, zone_id]]
