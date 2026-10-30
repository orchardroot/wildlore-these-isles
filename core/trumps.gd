class_name Trumps
extends RefCounted
## Trumps, the card game of these isles (wave 47). One card per species, five stats worked out from the species
## itself (nothing to author), a hand of five against a resident who fancies a game, the winner of each pair
## taking the loser's card. Holders are generated per resident from their region's wild creatures, so every region
## has a set to collect, and a full set earns a prize. Pure logic, seeded Rng, no autoload names;
## ui/trumps_screen.gd plays it and ui/cards_tab.gd shows the album.

const STATS := ["size", "speed", "lore", "grit", "rarity"]
const STAT_NAMES := {"size": "Size", "speed": "Speed", "lore": "Lore", "grit": "Grit", "rarity": "Rarity"}
const HAND := 5
const MAX_ROUNDS := 12
const RANDOM_PICK := 20.0          # percent of AI picks that ignore the maths
const FLAG_STARTER := "trumps_starter"
const FLAG_DAY := "trumps_day_"    # + zone_npc: once a real day per resident (DailyKey stamp)
const FLAG_WON := "trumps_won_"    # + zone_npc: their held card has been won
const FLAG_PRIZE := "trumps_prize_"  # + region: the region set's prize has been claimed
const KEEPER_TOWNS := ["buxton", "liverpool", "llanberis", "cardiff", "glastonbury", "dublin", "galway", "belfast", "inverness", "york"]
const CHAPBOOKS := "res://data/items/w47_d.json"

static var _dex: Dex = null
static var _tab: Dictionary = {}     # stat -> sorted raw values across the original 200
static var _tab_for := 0
static var _legends: Array = []

# ---- the dex behind the numbers

## Use this Dex for the stat spread (the game passes its own; tests may too). Otherwise one is loaded on first use.
static func use_dex(d: Dex) -> void:
	if d == _dex:
		return
	_dex = d
	_tab = {}
	_legends = []

static func dex() -> Dex:
	if _dex == null:
		_dex = Dex.load_default()
	return _dex

static func _raw(sp: Dictionary, stat: String) -> float:
	var b: Dictionary = sp.get("base", {})
	match stat:
		"size":
			return float(b.get("hp", 0))
		"speed":
			return float(b.get("spd", 0))
		"lore":
			return float(b.get("lore", 0))
		"grit":
			return (float(b.get("def", 0)) + float(b.get("ward", 0))) * 0.5
	return 1000.0 if bool(sp.get("legend", false)) else 256.0 - float(sp.get("catch_rate", 128))

static func _table() -> Dictionary:
	if _tab.is_empty():
		var d := dex()
		for stat in STATS:
			var vals := []
			for id in d.core_ids():
				vals.append(_raw(d.get_species(id), stat))
			vals.sort()
			_tab[stat] = vals
		_legends = d.core_ids().filter(func(i): return bool(d.get_species(i).get("legend", false)))
		_legends.sort()
	return _tab

## 1 to 10: where this value sits in the spread of the original 200 (ties share the middle of their run).
static func scaled(stat: String, v: float) -> int:
	var vals: Array = _table()[stat]
	var below := vals.bsearch(v, true)
	var upto := vals.bsearch(v, false)
	var frac := (float(below) + float(upto - below) * 0.5) / maxf(1.0, float(vals.size()))
	return clampi(1 + int(frac * 10.0), 1, 10)

## A card: {species, size, speed, lore, grit, rarity}, each 1 to 10.
static func card(sp: Dictionary) -> Dictionary:
	var out := {"species": str(sp.get("id", ""))}
	for stat in STATS:
		out[stat] = scaled(stat, _raw(sp, stat))
	return out

static func card_of(species_id: String) -> Dictionary:
	return card(dex().get_species(species_id))

static func total(c: Dictionary) -> int:
	var t := 0
	for s in STATS:
		t += int(c.get(s, 0))
	return t

## Mean of one stat across the 200: what the AI measures a card against.
static func average(stat: String) -> float:
	var vals: Array = _table()[stat]
	var sum := 0.0
	for v in vals:
		sum += float(scaled(stat, float(v)))
	return sum / maxf(1.0, float(vals.size()))

static func legends() -> Array:
	_table()
	return _legends

static func core_ids() -> Array:
	return dex().core_ids()

# ---- the collection (data.trumps)

static func cards(data: GameStateData) -> Dictionary:
	return data.trumps.get("cards", {})

static func has_card(data: GameStateData, species_id: String) -> bool:
	return int(cards(data).get(species_id, 0)) > 0

static func owned_count(data: GameStateData) -> int:
	return cards(data).keys().filter(func(k): return int(cards(data)[k]) > 0 and not Dex.in_appendix(str(k))).size()

static func give(data: GameStateData, species_id: String, n := 1) -> void:
	if not data.trumps.has("cards"):
		data.trumps["cards"] = {}
	data.trumps.cards[species_id] = int(data.trumps.cards.get(species_id, 0)) + n

static func record(data: GameStateData, won: bool) -> void:
	if won:
		data.trumps["wins"] = int(data.trumps.get("wins", 0)) + 1
		data.trumps["streak"] = int(data.trumps.get("streak", 0)) + 1
	else:
		data.trumps["losses"] = int(data.trumps.get("losses", 0)) + 1
		data.trumps["streak"] = 0

static func streak(data: GameStateData) -> int:
	return int(data.trumps.get("streak", 0))

## Your best hand: up to five distinct cards, strongest first.
static func best_hand(data: GameStateData) -> Array:
	var ids := cards(data).keys().filter(func(k): return int(cards(data)[k]) > 0 and dex().has(str(k)))
	ids.sort_custom(func(a, b):
		var ta := total(card_of(a))
		var tb := total(card_of(b))
		return ta > tb if ta != tb else str(a) < str(b))
	return ids.slice(0, HAND)

## Mum's five: the lead creature plus four Cheshire commons (the most ordinary, in a steady order).
static func starter(data: GameStateData, idx: Dictionary = {}) -> Array:
	if idx.is_empty():
		idx = ZoneIndex.get_index()
	var out := []
	if not data.party.is_empty():
		out.append(str(data.party[0].species.id))
	var pool := _region_pool("cheshire", idx)
	pool.sort_custom(func(a, b):
		var ra := int(card_of(a).rarity)
		var rb := int(card_of(b).rarity)
		return ra < rb if ra != rb else str(a) < str(b))
	for s in pool:
		if out.size() >= HAND:
			break
		if s not in out:
			out.append(s)
	return out

static func give_starter(data: GameStateData, idx: Dictionary = {}) -> Array:
	var five := starter(data, idx)
	for s in five:
		give(data, str(s))
	data.set_flag(FLAG_STARTER, true)
	return five

# ---- holders (who plays, and with what)

static func _region_pool(region: String, idx: Dictionary) -> Array:
	var out := []
	for s in idx.get("region_species", {}).get(region, []):
		if not Dex.in_appendix(str(s)) and dex().has(str(s)) and s not in out:
			out.append(s)
	out.sort()
	return out

static func _seed(parts: Array) -> int:
	return ("|".join(parts.map(func(p): return str(p)))).hash() & 0x3fffffff

static func _interior_ok(zone_id: String) -> bool:
	var t := zone_id.split("_")
	return zone_id.contains("home") or zone_id.contains("pub") or "inn" in t

## True when this resident plays: a home, pub or inn, and about one in two by a steady hash.
static func plays(zone_id: String, npc_id: String, idx: Dictionary = {}) -> bool:
	if npc_id == "" or not _interior_ok(zone_id):
		return false
	if idx.is_empty():
		idx = ZoneIndex.get_index()
	var z: Dictionary = idx.get("zones", {}).get(zone_id, {})
	if str(z.get("kind", "")) != "interior":
		return false
	return _seed(["plays", zone_id, npc_id]) % 2 == 0

static func region_of(zone_id: String, idx: Dictionary = {}) -> String:
	if idx.is_empty():
		idx = ZoneIndex.get_index()
	return str(idx.get("zones", {}).get(zone_id, {}).get("region", ""))

## The species card this resident holds at slot `idx` (0 is the one you win). Stable for ever.
static func holder(zone_id: String, npc_id: String, slot: int, zidx: Dictionary = {}) -> String:
	if zidx.is_empty():
		zidx = ZoneIndex.get_index()
	var rng := Rng.new(_seed(["holder", zone_id, npc_id, slot]))
	var region := region_of(zone_id, zidx)
	var town := str(zidx.get("room_town", {}).get(zone_id, ""))
	if slot == 0 and town in KEEPER_TOWNS and zone_id.contains("pub") and not legends().is_empty():
		return str(legends()[rng.roll_int(0, legends().size() - 1)])
	var pool := _region_pool(region, zidx)
	if rng.roll_int(1, 6) == 1:  # one in six: a card from next door
		var next: Array = zidx.get("adj", {}).get(region, [])
		if not next.is_empty():
			var np := _region_pool(str(next[rng.roll_int(0, next.size() - 1)]), zidx)
			if not np.is_empty():
				pool = np
	if pool.is_empty():
		pool = core_ids()
	return str(pool[rng.roll_int(0, pool.size() - 1)])

## A resident's hand of `n` distinct cards, the one you can win first.
static func deck(zone_id: String, npc_id: String, n := HAND, zidx: Dictionary = {}) -> Array:
	var out := []
	var slot := 0
	while out.size() < n and slot < n * 8:
		var s := holder(zone_id, npc_id, slot, zidx)
		if s not in out:
			out.append(s)
		slot += 1
	return out

static func day_key(zone_id: String, npc_id: String) -> String:
	return FLAG_DAY + zone_id + "_" + npc_id

static func won_key(zone_id: String, npc_id: String) -> String:
	return FLAG_WON + zone_id + "_" + npc_id

static func blurb(data: GameStateData) -> String:
	return "%d of %d cards, %d won, %d lost" % [owned_count(data), core_ids().size(), int(data.trumps.get("wins", 0)), int(data.trumps.get("losses", 0))]

# ---- one game

## A game of two hands. Each side is an Array of species ids, the front card is the one in play.
static func new_game(mine: Array, theirs: Array, i_lead := true) -> Dictionary:
	var stats := {}
	for s in mine + theirs:
		stats[str(s)] = card_of(str(s))
	return {"mine": mine.duplicate(), "theirs": theirs.duplicate(), "lead": "mine" if i_lead else "theirs",
		"round": 0, "tried": [], "stats": stats, "log": []}

static func value(g: Dictionary, species_id: String, stat: String) -> int:
	return int(g.stats[species_id][stat])

static func over(g: Dictionary) -> bool:
	return g.mine.is_empty() or g.theirs.is_empty() or int(g.round) >= MAX_ROUNDS

## "mine", "theirs" or "draw" (only meaningful once over).
static func winner(g: Dictionary) -> String:
	if g.mine.size() == g.theirs.size():
		return "draw"
	return "mine" if g.mine.size() > g.theirs.size() else "theirs"

## The leader plays `stat` on the two front cards. Returns {result: "win"|"lose"|"tie", stat, mine, theirs, taken}
## from the player's point of view. A tie leaves the cards where they are and the leader must choose again.
static func play(g: Dictionary, stat: String) -> Dictionary:
	var a: String = g.mine[0]
	var b: String = g.theirs[0]
	var va := value(g, a, stat)
	var vb := value(g, b, stat)
	var out := {"stat": stat, "mine": va, "theirs": vb, "result": "tie", "taken": "", "a": a, "b": b}
	if va == vb:
		g.tried.append(stat)
		if g.tried.size() >= STATS.size():  # nothing separates them: back to the bottom of each hand
			g.mine.pop_front()
			g.mine.append(a)
			g.theirs.pop_front()
			g.theirs.append(b)
			g.tried = []
			g.round += 1
			out.result = "stalemate"
		return out
	g.tried = []
	g.round += 1
	if va > vb:
		g.mine.pop_front()
		g.theirs.pop_front()
		g.mine.append(a)
		g.mine.append(b)
		g.lead = "mine"
		out.result = "win"
		out.taken = b
	else:
		g.mine.pop_front()
		g.theirs.pop_front()
		g.theirs.append(b)
		g.theirs.append(a)
		g.lead = "theirs"
		out.result = "lose"
		out.taken = a
	g.log.append(out)
	return out

## What the leader may still pick (stats not already tied this pair).
static func choices(g: Dictionary) -> Array:
	return STATS.filter(func(s): return s not in g.tried)

## The AI's pick for its front card: the stat furthest above the 200's average, but one time in five a random one.
static func ai_pick(g: Dictionary, rng: Rng) -> String:
	var opts := choices(g)
	if rng.chance(RANDOM_PICK):
		return str(opts[rng.roll_int(0, opts.size() - 1)])
	var mine_card: String = g.theirs[0]
	var best: String = opts[0]
	var best_gap := -99.0
	for s in opts:
		var gap := float(value(g, mine_card, s)) - average(s)
		if gap > best_gap:
			best_gap = gap
			best = s
	return best

## Plays a whole game with both sides on the AI; used by tests and the dev deck.
static func autoplay(g: Dictionary, rng: Rng) -> Dictionary:
	var guard := 0
	while not over(g) and guard < 200:
		guard += 1
		var stat: String
		if g.lead == "mine":
			var flip: Dictionary = g.duplicate()
			flip.mine = g.theirs
			flip.theirs = g.mine
			stat = ai_pick(flip, rng)
		else:
			stat = ai_pick(g, rng)
		play(g, stat)
	return g

# ---- prizes

## Pounds for a win: a couple, a little more for a rare card on the table, and a little for a streak. Once a day each.
static func prize_money(rarity: int, streak_now: int) -> int:
	return 2 + rarity / 2 + mini(streak_now, 5)

## What a resident pays out: {card: species or "", money: pounds}. Their held card the first time you win, then money.
static func settle(data: GameStateData, zone_id: String, npc_id: String, won: bool, zidx: Dictionary = {}) -> Dictionary:
	record(data, won)
	var out := {"card": "", "money": 0}
	if not won:
		return out
	var held := holder(zone_id, npc_id, 0, zidx)
	if data.flag(won_key(zone_id, npc_id)) != true:
		data.set_flag(won_key(zone_id, npc_id), true)
		give(data, held)
		out.card = held
	out.money = prize_money(int(card_of(held).rarity), streak(data))
	return out

# ---- the album and region sets

## The original-200 species that live in a region (its set).
static func region_set(region: String, idx: Dictionary = {}) -> Array:
	if idx.is_empty():
		idx = ZoneIndex.get_index()
	return _region_pool(region, idx)

static func region_complete(data: GameStateData, region: String, idx: Dictionary = {}) -> bool:
	var set := region_set(region, idx)
	return not set.is_empty() and set.all(func(s): return has_card(data, str(s)))

## Regions with a set, in the Fieldbook's order, plus a last group for original-200 species no wild route holds.
## [{region, name, species: [ids], have, total, complete, claimed}]
static func album(data: GameStateData, idx: Dictionary = {}) -> Array:
	if idx.is_empty():
		idx = ZoneIndex.get_index()
	var out := []
	var seen := {}
	for p in FieldbookGoals.region_progress(data, idx):
		var set := region_set(str(p.region), idx)
		if set.is_empty():
			continue
		for s in set:
			seen[s] = true
		out.append(_group(data, str(p.region), str(p.name), set))
	var rest := core_ids().filter(func(s): return not seen.has(s))
	if not rest.is_empty():
		var g := _group(data, "elsewhere", "Elsewhere", rest)
		g.claimed = true  # no prize for the strays
		out.append(g)
	return out

static func _group(data: GameStateData, region: String, nm: String, set: Array) -> Dictionary:
	var have := set.filter(func(s): return has_card(data, str(s))).size()
	return {"region": region, "name": nm, "species": set, "have": have, "total": set.size(),
		"complete": have >= set.size(), "claimed": data.flag(FLAG_PRIZE + region) == true}

## A chapbook id from session D's file, if it is there, else "".
static func chapbook_ids() -> Array:
	var out := []
	if not FileAccess.file_exists(CHAPBOOKS):
		return out
	var d = JsonUtil.read(CHAPBOOKS)
	var items: Array = d.get("items", []) if d is Dictionary else (d if d is Array else [])
	for it in items:
		if it is Dictionary and str(it.get("kind", "")) == "chapbook":
			out.append(str(it.get("id", "")))
	out.sort()
	return out

## The prize for a finished region, fixed by the region: a chapbook or a coat for one of its creatures.
## {kind: "chapbook", item} or {kind: "coat", species, variant}
static func prize(region: String, idx: Dictionary = {}) -> Dictionary:
	var h := _seed(["prize", region])
	var books := chapbook_ids()
	if h % 2 == 0 and not books.is_empty():
		return {"kind": "chapbook", "item": str(books[(h / 2) % books.size()])}
	var set := region_set(region, idx)
	if set.is_empty():
		set = core_ids()
	return {"kind": "coat", "species": str(set[(h / 3) % set.size()]), "variant": str(Coats.ALL[(h / 7) % Coats.ALL.size()])}

static func prize_line(p: Dictionary, dex_in: Dex = null) -> String:
	var d := dex_in if dex_in != null else dex()
	if str(p.kind) == "chapbook":
		return "a chapbook"
	var sp := d.get_species(str(p.species))
	return "a %s-coated %s" % [str(p.variant), str(sp.get("name", p.species))]

# ---- the script hook (story/script_hooks.gd)

## Mum hands out the starter five once; a resident who plays offers a game after their chat, once a day.
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	if zone_id == "macc_home" and npc_id == "mum" and data.flag(FLAG_STARTER) != true:
		return commands + [
			{"do": "say", "who": "Mum", "text": "Oh, and before I forget. Your gran's old Trumps cards, found down the back of the settee. A creature on each, five numbers underneath."},
			{"do": "say", "who": "Mum", "text": "Get folk to play you. Winner takes the other one's card. She cheated something rotten, so you've a head start."},
			{"do": "trumps", "give": "starter"}]
	if data.flag(FLAG_STARTER) != true or not plays(zone_id, npc_id):
		return commands
	if DailyKey.done_today(data, day_key(zone_id, npc_id)):
		return commands
	return commands + [
		{"do": "choice", "text": "Fancy a game of Trumps?", "options": ["Go on, then", "Another time"], "set": "trumps_ask"},
		{"do": "if", "flag": "trumps_ask", "eq": 0, "then": [{"do": "trumps", "npc": npc_id}]}]
