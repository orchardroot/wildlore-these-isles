class_name Wants
extends RefCounted
## Residents with wants (wave 47 C). data/trades/<region>.json: {"trades": [{id, zone, npc, wants: {item, n},
## gives: {item, n} | {money}, ask, thanks, repeat}]}. data/trades/traders.json: {"traders": [{zone, npc, shop, line}]},
## the front-room shops (data/shops/home_<zone>.json) a resident opens after their chat. Everything arrives through
## ScriptHooks: `hook` appends to the resident's script, so no dialogue file is edited. State is flags only:
##   tr_<id>_done   a one-off trade has been made
##   tr_<id>_day    a repeatable trade's DailyKey stamp (once a day)
##   tr_<id>_ask    the day the ask was last voiced (so it doesn't nag)
## A want has a kind: an item (the default: `{item, n}`), a sighting `{kind: "seen", species}` (the Fieldbook has it as
## seen or caught) or a photograph `{kind: "photo", zone}` (the flag photo_<zone>, set by photo mode's take). Only an
## item changes hands; the other two are shown, so a repeatable one is a daily errand like any other.
## Pure logic, no autoload names: the validator loads it.

const DIR := "res://data/trades"
const TRADERS_FILE := "traders"
const PICK := "_tr_pick"  # the scratch flag a choice writes
const WHO := "Resident"
const PHOTO_PREFIX := "photo_"   # flag: the player has taken a photograph in this zone
const KINDS := ["item", "seen", "photo"]

static var _loaded := false
static var _by_npc := {}    # "zone|npc" -> [trade]
static var _by_id := {}
static var _traders := {}   # "zone|npc" -> trader
static var _db: ItemDB = null
static var _dex: Dex = null

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
	_dex = null

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

static func kind_of(t: Dictionary) -> String:
	return str(t.get("wants", {}).get("kind", "item"))

## Photo mode's take: a photograph was saved in this zone (see ui/photo_mode.gd).
static func note_photo(data: GameStateData, zone_id: String) -> void:
	data.set_flag(PHOTO_PREFIX + zone_id, true)

## Money from asks that cost the player nothing but a visit (a sighting or a photograph), each paid once: a lump for the
## economy sim. Item asks are not counted: what they take is worth at least what they pay.
static func visit_asks_total() -> int:
	var n := 0
	for t in all():
		if kind_of(t) != "item" and not bool(t.get("repeat", false)):
			n += int(t.get("gives", {}).get("money", 0))
	return n

## The player carries (or has seen, or has photographed) what the resident wants.
static func can_pay(data: GameStateData, t: Dictionary) -> bool:
	var w: Dictionary = t.get("wants", {})
	match kind_of(t):
		"seen":
			return data.seen.get(str(w.get("species", "")), false) == true or data.caught.get(str(w.get("species", "")), false) == true
		"photo":
			return ZoneData.flag_on(data.flag(PHOTO_PREFIX + str(w.get("zone", ""))))
	return Bag.new(data.bag).count(str(w.get("item", ""))) >= int(w.get("n", 1))

## The bag has room for what they give (money always fits).
static func has_room(data: GameStateData, t: Dictionary) -> bool:
	var g: Dictionary = t.get("gives", {})
	if not g.has("item"):
		return true
	var w: Dictionary = t.get("wants", {})
	if kind_of(t) != "item":
		return Bag.new(data.bag).count(str(g.item)) + int(g.get("n", 1)) <= Bag.MAX_STACK
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
	if kind_of(t) == "item":
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
	return "%s Received %s." % [_hand_text(t), got]

static func _hand_text(t: Dictionary) -> String:
	match kind_of(t):
		"seen":
			return "You open the Fieldbook at the %s page." % _species_name(str(t.wants.get("species", "")))
		"photo":
			return "You show them the photograph."
	return "You hand over %s." % _want_text(t)

static func _species_name(id: String) -> String:
	if _dex == null:
		_dex = Dex.load_default()
	return str(_dex.get_species(id).get("name", id.capitalize())) if _dex.has(id) else id.capitalize()

## The choice shown for an offer: {text, give}. Items are handed over; a sighting or photograph is shown.
static func _offer(t: Dictionary) -> Dictionary:
	match kind_of(t):
		"seen":
			var nm := _species_name(str(t.wants.get("species", "")))
			return {"text": "Show them your %s page?" % nm, "give": "Show them the %s page" % nm}
		"photo":
			return {"text": "Show them your photograph?", "give": "Show them the photograph"}
	var what := _want_text(t)
	return {"text": "Give them %s?" % what, "give": "Give them %s" % what}

static func _want_text(t: Dictionary) -> String:
	var w: Dictionary = t.get("wants", {})
	var nm: String = _items().get_item(str(w.get("item", ""))).get("name", str(w.get("item", "")))
	var n := int(w.get("n", 1))
	return nm if n <= 1 else "%d x %s" % [n, nm]

static func _say(text: String) -> Dictionary:
	return {"do": "say", "who": WHO, "text": text}

## The resident's offers split by kind: {"trade": [first swap they could make now], "asks": [unmet asks, daily],
## "shop": [front-room line and choice]}. ScriptHooks picks at most one prompt from these and the other hooks.
static func parts(zone_id: String, npc_id: String, data: GameStateData) -> Dictionary:
	var key := "%s|%s" % [zone_id, npc_id]
	if not _loaded:
		_load()
	var res: Dictionary = {"trade": [], "asks": [], "shop": []}
	if not _by_npc.has(key) and not _traders.has(key):
		return res
	for t in _by_npc.get(key, []):
		if not is_open(data, t):
			continue
		var id := str(t.get("id", ""))
		if can_pay(data, t) and has_room(data, t):
			if res.trade.is_empty():
				var offer := _offer(t)
				res.trade.append(_say(str(t.get("ask", ""))))
				res.trade.append({"do": "choice", "text": offer.text, "options": [offer.give, "Not now"], "set": PICK})
				res.trade.append({"do": "if", "flag": PICK, "eq": 0, "then": [_say(str(t.get("thanks", "Thank you."))), {"do": "trade", "op": "swap", "id": id}]})
		else:
			res.asks.append({"do": "daily", "key": "tr_%s_ask" % id, "then": [_say(str(t.get("ask", "")))]})
	var tr: Dictionary = _traders.get(key, {})
	if not tr.is_empty():
		res.shop.append(_say(str(tr.get("line", "I sell a few bits."))))
		res.shop.append({"do": "choice", "text": "Have a look?", "options": ["Have a look", "Maybe later"], "set": PICK})
		res.shop.append({"do": "if", "flag": PICK, "eq": 0, "then": [{"do": "shop", "id": str(tr.get("shop", ""))}]})
	return res

## ScriptHooks entry (all parts, uncapped; ScriptHooks.wrap itself uses `parts` to offer only one prompt per talk).
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	var key := "%s|%s" % [zone_id, npc_id]
	if not _loaded:
		_load()
	if not _by_npc.has(key) and not _traders.has(key):
		return commands
	var p: Dictionary = parts(zone_id, npc_id, data)
	return commands + p.asks + p.trade + p.shop

## The "trade" story command: {"op": "swap", "id": trade} or {"op": "errand", "id": quest}. Returns the line to show.
static func apply(data: GameStateData, c: Dictionary) -> String:
	if str(c.get("op", "")) == "errand":
		return Errands.reward(data, str(c.get("id", "")))
	var line := pay(data, get_trade(str(c.get("id", ""))))
	return line if line != "" else "You haven't quite got what they asked for."

## Validator: every trade and trader points at a real zone, npc, item and shop; text present, no em-dashes.
static func check(zones: Dictionary, items: ItemDB, dex: Dex = null) -> Array:
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
		var kind := kind_of(t)
		if kind not in KINDS:
			errors.append(tag + ": unknown wants kind '%s'" % kind)
		elif kind == "seen":
			if dex != null and not dex.has(str(w.get("species", ""))):
				errors.append(tag + ": wants to see '%s', which is not a species" % w.get("species", ""))
		elif kind == "photo":
			if not zones.has(str(w.get("zone", ""))):
				errors.append(tag + ": wants a photograph in unknown zone '%s'" % w.get("zone", ""))
		elif not items.has(str(w.get("item", ""))) or int(w.get("n", 0)) < 1:
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
