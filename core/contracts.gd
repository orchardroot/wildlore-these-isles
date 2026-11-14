class_name Contracts
extends RefCounted
## Contracts (data/contracts/<id>.json): work with a story in it. A named person pins a problem to a town's notice
## board (something is taking the hens, the lambs, the sleep of a village) and the player can take it, look into it,
## work out what it is, face it where it lives, and then decide what to do about it. The decision changes something
## for good. Four beats, then the choice:
##   take      the fee is agreed (and can be haggled once the town knows you), the Journal opens a card
##   look into two to four clues: look-spots in the zones (some only at the right hour or in the right weather)
##             and witnesses who do not agree. Each clue points at some of the hypotheses and rules out others
##   prepare   the Journal's working theory: what it is, its types, what to bring. Only what the clues justify
##   face it   the named creature, in its lair, above the local par. Naming it right makes the fight easier, naming
##             it wrong makes it harder, never impossible
##   decide    two or three real options (plus the catch, if you catch it): none of them simply right
## State is all flags in the ct_ namespace, so an old save has no contracts under way and nothing is changed:
##   ct_<id>_state     1 taken, 2 decided (go and say so), 3 closed (reported, paid). Absent is "not taken"
##   ct_<id>_fee       the fee agreed, in sterling
##   ct_<id>_clue_<c>  a clue found
##   ct_<id>_guess     the hypothesis you named at the lair
##   ct_<id>_beaten    the creature was beaten and the decision is waiting
##   ct_<id>_end       the ending id; ct_<id>_is_<end> is the same as a flag a resident's show_if can read
##   ct_rep_<group>    your repute with a group of people (farmers, wardens ...), see REPUTE_STEP
## Pure logic (no autoload names): the validator loads this.

const DIR := "res://data/contracts"
const TYPES_PATH := "res://data/types.json"
const PREFIX := "ct_"
const TAKEN := 1
const DECIDED := 2
const CLOSED := 3
## Levels added to the creature when you named the wrong thing, and when you could not say.
const WRONG_LEVELS := 4
const UNSURE_LEVELS := 2
## Haggling is for towns that know you: a bonus on the fee by standing tier (Regular and up).
const HAGGLE := {2: 0.15, 3: 0.25, 4: 0.35}
## Each point of repute with the poster's group moves the fee this much, within the cap either way.
const REPUTE_STEP := 0.05
const REPUTE_CAP := 4
const GROUPS := {"farmers": "the farming folk", "wardens": "the wardens and naturalists", "fishers": "the fishing folk",
	"walkers": "the walkers and rescue teams", "townsfolk": "the townsfolk", "crofters": "the crofters",
	"miners": "the old mining families", "keepers": "the Keepers"}
const PHASES := ["dawn", "day", "dusk", "night"]
const WEATHERS := ["rain", "fog", "gale", "frost", "sunshine", "clear"]

static var _cache: Array = []
static var _types: Dictionary = {}

static func all() -> Array:
	if _cache.is_empty():
		for p in JsonUtil.list_json(DIR):
			var c = JsonUtil.read(p)
			if c is Dictionary and str(c.get("id", "")) != "":
				_cache.append(c)
	return _cache

## Swap in a contract list (tests); reset() goes back to the files.
static func use(list: Array) -> void:
	_cache = list

static func reset() -> void:
	_cache = []

static func get_contract(id: String) -> Dictionary:
	for c in all():
		if str(c.id) == id:
			return c
	return {}

static func flag(id: String, what: String) -> String:
	return "%s%s_%s" % [PREFIX, id, what]

static func _int(v: Variant) -> int:
	return int(v) if (v is int or v is float) else 0

static func _on(data: GameStateData, key: String) -> bool:
	var v: Variant = data.flag(key)
	return v == true or ((v is int or v is float) and v != 0)

# --- where a contract stands --------------------------------------------------------

static func state(data: GameStateData, id: String) -> int:
	return _int(data.flag(flag(id, "state")))

static func taken(data: GameStateData, id: String) -> bool:
	return state(data, id) >= TAKEN

static func closed(data: GameStateData, id: String) -> bool:
	return state(data, id) >= CLOSED

## The ending chosen ("" until you decide).
static func ending_id(data: GameStateData, id: String) -> String:
	var v: Variant = data.flag(flag(id, "end"))
	return str(v) if v is String else ""

static func ending(data: GameStateData, c: Dictionary) -> Dictionary:
	return choice_of(c, ending_id(data, str(c.id)))

static func choice_of(c: Dictionary, choice_id: String) -> Dictionary:
	for ch in c.get("choices", []):
		if str(ch.id) == choice_id:
			return ch
	return {}

## The options you can pick after beating it (the catch is never on the menu: you do it with a charm).
static func menu_choices(c: Dictionary) -> Array:
	return c.get("choices", []).filter(func(ch): return str(ch.get("via", "")) != "catch")

static func catch_choice(c: Dictionary) -> Dictionary:
	for ch in c.get("choices", []):
		if str(ch.get("via", "")) == "catch":
			return ch
	return {}

## Does the player meet what the notice asks: badges, and an earlier contract ended a given way.
static func available(data: GameStateData, c: Dictionary) -> bool:
	if data.badges.size() < int(c.get("badges", 0)):
		return false
	for n in c.get("needs", []):
		if ending_id(data, str(n.get("contract", ""))) != str(n.get("ending", "")):
			return false
	return true

## The contracts on `town`'s board that nobody has taken yet.
static func offered(data: GameStateData, town: String) -> Array:
	return all().filter(func(c): return str(c.town) == town and state(data, str(c.id)) == 0 and available(data, c))

## Contracts taken and not yet closed, oldest first as the files list them.
static func open_ones(data: GameStateData) -> Array:
	return all().filter(func(c): return state(data, str(c.id)) in [TAKEN, DECIDED])

## Contracts to show in the Journal: anything taken.
static func listed(data: GameStateData) -> Array:
	return all().filter(func(c): return taken(data, str(c.id)))

static func visible(data: GameStateData) -> bool:
	return not listed(data).is_empty()

# --- the fee ------------------------------------------------------------------------

static func base_fee(c: Dictionary) -> int:
	return Jobs.money_for({"pay": int(c.get("pay", 1))}, int(c.get("badges", 0)))

static func repute(data: GameStateData, group: String) -> int:
	return _int(data.flag("ct_rep_" + group))

static func repute_adjust(data: GameStateData, group: String, n: int) -> void:
	data.set_flag("ct_rep_" + group, repute(data, group) + n)

## What the town would pay today: the base fee, nudged by how the poster's kind of people think of you.
static func offer_fee(data: GameStateData, c: Dictionary) -> int:
	var r := clampi(repute(data, str(c.get("group", ""))), -REPUTE_CAP, REPUTE_CAP)
	return int(round(base_fee(c) * (1.0 + REPUTE_STEP * r) / 10.0)) * 10

## The haggle on offer: a share on top of the fee, 0 until the town (the poster's nation) counts you a Regular.
static func haggle_share(data: GameStateData, c: Dictionary) -> float:
	return float(HAGGLE.get(Standing.tier(data, str(c.get("nation", ""))), 0.0))

static func haggled_fee(data: GameStateData, c: Dictionary) -> int:
	return int(round(offer_fee(data, c) * (1.0 + haggle_share(data, c)) / 10.0)) * 10

## Takes the contract. {ok, fee}. A second take, or one you do not qualify for, does nothing.
static func take(data: GameStateData, id: String, haggle: bool) -> Dictionary:
	var c := get_contract(id)
	if c.is_empty() or state(data, id) != 0 or not available(data, c):
		return {"ok": false, "fee": 0}
	var fee := haggled_fee(data, c) if haggle and haggle_share(data, c) > 0.0 else offer_fee(data, c)
	data.set_flag(flag(id, "state"), TAKEN)
	data.set_flag(flag(id, "fee"), fee)
	return {"ok": true, "fee": fee}

static func fee(data: GameStateData, id: String) -> int:
	return _int(data.flag(flag(id, "fee")))

# --- looking into it ----------------------------------------------------------------

static func clue_found(data: GameStateData, id: String, clue_id: String) -> bool:
	return _on(data, flag(id, "clue_" + clue_id))

static func clue_of(c: Dictionary, clue_id: String) -> Dictionary:
	for k in c.get("clues", []):
		if str(k.id) == clue_id:
			return k
	return {}

## A clue's words as one paragraph (a witness says a few lines).
static func clue_text(k: Dictionary) -> String:
	var t: Variant = k.get("text", "")
	return " ".join((t as Array).map(func(l): return str(l))) if t is Array else str(t)

static func found(data: GameStateData, c: Dictionary) -> Array:
	return c.get("clues", []).filter(func(k): return clue_found(data, str(c.id), str(k.id)))

## Is the hour and the weather right for this clue ({} wants nothing special)?
static func clue_ready(clue: Dictionary, phase: String, weather: String) -> bool:
	var w: Dictionary = clue.get("when", {})
	var phases: Array = w.get("phase", [])
	if not phases.is_empty() and phase not in phases:
		return false
	var wants: Array = w.get("weather", [])
	if wants.is_empty():
		return true
	for kind in wants:
		if weather in Jobs.WEATHER.get(str(kind), [str(kind)]):
			return true
	return false

## Notes a clue. True when it is new, which needs the contract taken and not yet decided.
static func note_clue(data: GameStateData, id: String, clue_id: String) -> bool:
	if state(data, id) != TAKEN or clue_found(data, id, clue_id) or clue_of(get_contract(id), clue_id).is_empty():
		return false
	data.set_flag(flag(id, "clue_" + clue_id), true)
	return true

## A look-spot (a zone's examine entry with "clue": "<contract>.<clue>") read now: {lines, new}. The lines are what
## the clue tells you; empty when it is not yours to find yet (not taken, wrong hour, wrong weather).
static func look(data: GameStateData, spec: String, phase: String, weather: String) -> Dictionary:
	var parts := spec.split(".")
	if parts.size() != 2:
		return {"lines": [], "new": false}
	var id := parts[0]
	var c := get_contract(id)
	var k := clue_of(c, parts[1])
	if k.is_empty() or state(data, id) != TAKEN:
		return {"lines": [], "new": false}
	if clue_found(data, id, str(k.id)):
		return {"lines": [clue_text(k)], "new": false}
	if not clue_ready(k, phase, weather):
		return {"lines": [str(k.get("hint_wait", "Nothing here yet. Perhaps it is the wrong time to be looking."))], "new": false}
	return {"lines": [clue_text(k)], "new": note_clue(data, id, str(k.id))}

# --- working it out -----------------------------------------------------------------

static func hypothesis(c: Dictionary, hid: String) -> Dictionary:
	for h in c.get("hypotheses", []):
		if str(h.id) == hid:
			return h
	return {}

## What the clues say so far: {score: {hyp: n}, out: [hyp], lead: [hyp ids still standing with the best score],
## sure: true when one is clearly ahead}. A clue can point at a hypothesis (+1) and rule others out.
static func theory(data: GameStateData, c: Dictionary) -> Dictionary:
	var score := {}
	var out := {}
	for h in c.get("hypotheses", []):
		score[str(h.id)] = 0
	for k in found(data, c):
		for hid in k.get("points", []):
			score[str(hid)] = int(score.get(str(hid), 0)) + 1
		for hid in k.get("rules_out", []):
			out[str(hid)] = true
	var best := -1
	for hid in score:
		if not out.has(hid) and int(score[hid]) > best:
			best = int(score[hid])
	var lead := []
	for hid in score:
		if not out.has(hid) and int(score[hid]) == best and best > 0:
			lead.append(hid)
	return {"score": score, "out": out.keys(), "lead": lead, "sure": lead.size() == 1 and best >= 2}

## Attacking types that are super effective against a creature of these types (and not resisted by the other).
static func weak_to(types: Array) -> Array:
	if _types.is_empty():
		var d = JsonUtil.read(TYPES_PATH)
		_types = d if d is Dictionary else {}
	var chart: Dictionary = _types.get("chart", {})
	var out := []
	for atk in _types.get("types", []):
		var row: Dictionary = chart.get(atk, {})
		var se := false
		var blocked := false
		for t in types:
			if str(t) in row.get("se", []):
				se = true
			if str(t) in row.get("nve", []) or str(t) in row.get("none", []):
				blocked = true
		if se and not blocked:
			out.append(str(atk))
	return out

static func guess(data: GameStateData, id: String) -> String:
	var v: Variant = data.flag(flag(id, "guess"))
	return str(v) if v is String else ""

## The level of the creature you meet, naming `guess_id` ("" = could not say). Authored at a floor par and lifted
## with the story, as the wider Isles are.
static func fight_level(data: GameStateData, c: Dictionary, guess_id: String) -> int:
	var lair: Dictionary = c.get("lair", {})
	var base := ParLevel.lift(int(lair.get("level", 10)), data.flags, int(lair.get("floor_par", 0)))
	if guess_id == "":
		return base + UNSURE_LEVELS
	return base if guess_id == str(c.get("truth", "")) else base + WRONG_LEVELS

static func beaten(data: GameStateData, id: String) -> bool:
	return _on(data, flag(id, "beaten"))

# --- deciding and reporting ---------------------------------------------------------

## Makes the decision. {ok, choice}. What it changes for good happens now (flags, repute, anything given);
## the fee and the nations' standing wait for the poster.
static func decide(data: GameStateData, id: String, choice_id: String) -> Dictionary:
	var c := get_contract(id)
	var ch := choice_of(c, choice_id)
	if c.is_empty() or ch.is_empty() or state(data, id) != TAKEN:
		return {"ok": false, "choice": {}}
	data.set_flag(flag(id, "state"), DECIDED)
	data.set_flag(flag(id, "end"), choice_id)
	data.set_flag(flag(id, "is_" + choice_id), true)
	for k in ch.get("flags", {}):
		data.set_flag(str(k), ch.flags[k])
	for g in ch.get("repute", {}):
		repute_adjust(data, str(g), int(ch.repute[g]))
	for item in ch.get("gives", {}):
		Bag.new(data.bag).add(str(item), int(ch.gives[item]))
	return {"ok": true, "choice": ch}

## Standing with a nation, which a contract may lower as well as raise (never below nothing).
static func move_standing(data: GameStateData, nation: String, n: int) -> String:
	if not Standing.is_nation(nation) or n == 0:
		return ""
	if n > 0:
		return Standing.add(data, nation, n)
	data.set_flag(Standing.FLAG_PREFIX + nation, maxi(0, Standing.points(data, nation) + n))
	return ""

## Goes to the poster with what you did. Pays the fee (less, if the choice says so) in the local money, once, and
## moves the nations' standing. {ok, amount, cur, lines (standing toasts), choice}.
static func report(data: GameStateData, id: String, zone_id: String) -> Dictionary:
	var c := get_contract(id)
	if c.is_empty() or state(data, id) != DECIDED:
		return {"ok": false}
	var ch := ending(data, c)
	data.set_flag(flag(id, "state"), CLOSED)
	var amount := int(round(fee(data, id) * float(ch.get("fee", 1.0)) / 10.0)) * 10
	var paid := {"amount": 0, "cur": Wallet.GBP}
	if amount > 0:
		paid = Wallet.earn_here(data, amount, zone_id)
	var lines := []
	for nation in ch.get("standing", {}):
		var line := move_standing(data, str(nation), int(ch.standing[nation]))
		if line != "":
			lines.append(line)
	return {"ok": true, "amount": int(paid.amount), "cur": str(paid.cur), "lines": lines, "choice": ch}

# --- money for the sim --------------------------------------------------------------

## The fees of every contract whose notice is up at this many badges, each haggled by a Regular and paid at the
## best-paying ending: an upper bound for the economy sim, which pays them as the badges come in.
static func fees_through(badges: int) -> float:
	var t := 0.0
	for c in all():
		if int(c.get("badges", 0)) > badges:
			continue
		var best := 0.0
		for ch in c.get("choices", []):
			best = maxf(best, float(ch.get("fee", 1.0)))
		t += float(base_fee(c)) * (1.0 + float(HAGGLE[2])) * best
	return t

static func fees_total() -> float:
	return fees_through(10)

# --- validation ---------------------------------------------------------------------

const FIELDS := ["id", "title", "town", "nation", "group", "notice", "trouble", "real"]

## Problems in the files, for the validator: [String]. `zones` is id -> raw zone dictionary, `dialogue` is
## file -> {script -> commands}, `species` / `items` answer has(id).
static func validate(zones: Dictionary, dialogue: Dictionary, dex: Dex, items: ItemDB) -> Array:
	var errors := []
	var ids := {}
	var types: Array = []
	var td = JsonUtil.read(TYPES_PATH)
	if td is Dictionary:
		types = td.get("types", [])
	for c in all():
		var id := str(c.id)
		var tag := "contract %s: " % id
		if ids.has(id):
			errors.append(tag + "duplicate id")
		ids[id] = true
		for k in FIELDS:
			if str(c.get(k, "")) == "":
				errors.append(tag + "no " + k)
		if not GROUPS.has(str(c.get("group", ""))):
			errors.append(tag + "unknown group")
		if not Standing.is_nation(str(c.get("nation", ""))):
			errors.append(tag + "unknown nation")
		elif zones.has(str(c.town)) and Standing.nation_for_zone(str(c.town)) != str(c.nation):
			errors.append(tag + "town is not in " + str(c.nation))
		if not zones.has(str(c.town)):
			errors.append(tag + "unknown town")
		elif not (zones[str(c.town)].props as Array).any(func(p): return str(p.get("type", "")) == "noticeboard"):
			errors.append(tag + "town has no notice board")
		if int(c.get("pay", 0)) < 1 or int(c.get("pay", 0)) > 5:
			errors.append(tag + "pay must be 1 to 5")
		if int(c.get("badges", -1)) < 0 or int(c.get("badges", 0)) > 10:
			errors.append(tag + "badges 0 to 10")
		errors.append_array(_validate_clues(c, tag, zones, dialogue, types))
		errors.append_array(_validate_lair(c, tag, zones, dialogue, dex))
		errors.append_array(_validate_choices(c, tag, zones, items))
		for n in c.get("needs", []):
			if get_contract(str(n.get("contract", ""))).is_empty() or choice_of(get_contract(str(n.contract)), str(n.get("ending", ""))).is_empty():
				errors.append(tag + "needs an ending that does not exist")
		errors.append_array(_validate_poster(c, tag, zones, dialogue))
		for s in _strings(c):
			if "—" in s or "–" in s:   # no em or en dashes in anything a player reads
				errors.append(tag + "dash in text: " + s.left(40))
	return errors

static func _strings(v: Variant) -> Array:
	var out := []
	if v is String:
		out.append(v)
	elif v is Array:
		for x in v:
			out.append_array(_strings(x))
	elif v is Dictionary:
		for k in v:
			out.append_array(_strings(v[k]))
	return out

static func _scripts_use(dialogue: Dictionary, zone_id: String, test: Callable) -> bool:
	var file: Dictionary = dialogue.get(zone_id, {})
	for sid in file:
		if file[sid] is Array and _any_command(file[sid], test):
			return true
	return false

static func _any_command(cmds: Array, test: Callable) -> bool:
	for c in cmds:
		if not (c is Dictionary):
			continue
		if bool(test.call(c)):
			return true
		for k in ["then", "else"]:
			if c.get(k) is Array and _any_command(c[k], test):
				return true
	return false

static func _has_npc(zones: Dictionary, dialogue: Dictionary, zone_id: String, test: Callable) -> bool:
	var z: ZoneData = zones.get(zone_id)
	var file: Dictionary = dialogue.get(zone_id, {})
	if z == null:
		return false
	for n in z.npcs:
		var s: Variant = file.get(str(n.get("script", "")), [])
		if s is Array and _any_command(s, test):
			return true
	return false

static func _validate_clues(c: Dictionary, tag: String, zones: Dictionary, dialogue: Dictionary, types: Array) -> Array:
	var errors := []
	var id := str(c.get("id", ""))
	var hyps: Array = c.get("hypotheses", [])
	var hids := {}
	for h in hyps:
		hids[str(h.get("id", ""))] = true
		if str(h.get("name", "")) == "" or (h.get("types", []) as Array).is_empty():
			errors.append(tag + "hypothesis %s needs a name and types" % h.get("id", "?"))
		for t in h.get("types", []):
			if str(t) not in types:
				errors.append(tag + "hypothesis %s has unknown type %s" % [h.get("id", "?"), t])
	if hyps.size() < 3 or hyps.size() > 4:
		errors.append(tag + "three or four hypotheses")
	if not hids.has(str(c.get("truth", ""))):
		errors.append(tag + "truth is not a hypothesis")
	var clues: Array = c.get("clues", [])
	if clues.size() < 3 or clues.size() > 4:
		errors.append(tag + "three or four clues")
	var cids := {}
	var looks := 0
	var asks := 0
	for k in clues:
		var kid := str(k.get("id", ""))
		if cids.has(kid) or kid == "":
			errors.append(tag + "clue ids must be unique")
		cids[kid] = true
		for f in ["text", "hint", "zone"]:
			if str(k.get(f, "")) == "":
				errors.append(tag + "clue %s has no %s" % [kid, f])
		for hid in k.get("points", []) + k.get("rules_out", []):
			if not hids.has(str(hid)):
				errors.append(tag + "clue %s names unknown hypothesis %s" % [kid, hid])
		if str(c.get("truth", "")) in k.get("rules_out", []):
			errors.append(tag + "clue %s rules out the truth" % kid)
		var z: ZoneData = zones.get(str(k.get("zone", "")))
		if z == null:
			errors.append(tag + "clue %s in unknown zone" % kid)
			continue
		match str(k.get("kind", "")):
			"look":
				looks += 1
				var spec := "%s.%s" % [id, kid]
				if not (z.examine as Array).any(func(e): return str(e.get("clue", "")) == spec):
					errors.append(tag + "clue %s has no look-spot in %s" % [kid, k.zone])
				var w: Dictionary = k.get("when", {})
				for ph in w.get("phase", []):
					if str(ph) not in PHASES:
						errors.append(tag + "clue %s has unknown phase %s" % [kid, ph])
				for we in w.get("weather", []):
					if str(we) not in WEATHERS:
						errors.append(tag + "clue %s has unknown weather %s" % [kid, we])
			"ask":
				asks += 1
				if str(k.get("who", "")) == "" or (k.get("idle", []) as Array).is_empty():
					errors.append(tag + "clue %s needs who and idle lines" % kid)
				var want := kid
				if not _has_npc(zones, dialogue, str(k.zone), func(cmd): return str(cmd.get("do", "")) == "contract" and str(cmd.get("as", "")) == "clue" and str(cmd.get("id", "")) == id and str(cmd.get("clue", "")) == want):
					errors.append(tag + "clue %s has no witness in %s" % [kid, k.zone])
			_:
				errors.append(tag + "clue %s: kind must be look or ask" % kid)
	if looks < 1 or asks < 1:
		errors.append(tag + "needs at least one look and one witness")
	return errors

static func _validate_lair(c: Dictionary, tag: String, zones: Dictionary, dialogue: Dictionary, dex: Dex) -> Array:
	var errors := []
	var id := str(c.get("id", ""))
	var lair: Dictionary = c.get("lair", {})
	if not dex.has(str(lair.get("species", ""))):
		errors.append(tag + "lair species does not exist")
	elif str(c.get("truth", "")) != "":
		var truth := hypothesis(c, str(c.truth))
		var types: Array = dex.get_species(str(lair.species)).get("types", [])
		if not truth.is_empty() and truth.get("types", []) != types:
			errors.append(tag + "the true hypothesis must have the creature's own types %s" % [types])
	if str(lair.get("name", "")) == "" or int(lair.get("level", 0)) < 1 or int(lair.get("floor_par", 0)) < 1:
		errors.append(tag + "lair needs a name, a level and a floor_par")
	if not zones.has(str(lair.get("zone", ""))):
		errors.append(tag + "lair in an unknown zone")
		return errors
	if (lair.get("intro", []) as Array).is_empty():
		errors.append(tag + "lair needs intro lines")
	if not _has_npc(zones, dialogue, str(lair.zone), func(cmd): return str(cmd.get("do", "")) == "contract" and str(cmd.get("as", "")) == "lair" and str(cmd.get("id", "")) == id):
		errors.append(tag + "no lair NPC in " + str(lair.zone))
	return errors

static func _validate_choices(c: Dictionary, tag: String, zones: Dictionary, items: ItemDB) -> Array:
	var errors := []
	var menu := menu_choices(c)
	if menu.size() < 2 or menu.size() > 3:
		errors.append(tag + "two or three choices on the menu")
	if catch_choice(c).is_empty():
		errors.append(tag + "needs a catch ending (via: catch)")
	var seen := {}
	for ch in c.get("choices", []):
		var cid := str(ch.get("id", ""))
		if cid == "" or seen.has(cid):
			errors.append(tag + "choice ids must be unique")
		seen[cid] = true
		for f in ["label", "say", "poster", "journal"]:
			if ch.get(f) == null or (ch[f] is String and ch[f] == "") or (ch[f] is Array and (ch[f] as Array).is_empty()):
				errors.append(tag + "choice %s has no %s" % [cid, f])
		var fee_share := float(ch.get("fee", 1.0))
		if fee_share < 0.0 or fee_share > 1.0:
			errors.append(tag + "choice %s: fee is a share from 0 to 1" % cid)
		var change := (ch.get("flags", {}) as Dictionary).size() + (ch.get("repute", {}) as Dictionary).size() + (ch.get("standing", {}) as Dictionary).size()
		if change < 2:
			errors.append(tag + "choice %s must change something that stays (flags, repute, standing)" % cid)
		for n in ch.get("standing", {}):
			if not Standing.is_nation(str(n)):
				errors.append(tag + "choice %s: unknown nation %s" % [cid, n])
		for g in ch.get("repute", {}):
			if not GROUPS.has(str(g)):
				errors.append(tag + "choice %s: unknown group %s" % [cid, g])
		for it in ch.get("gives", {}):
			if not items.has(str(it)):
				errors.append(tag + "choice %s gives unknown item %s" % [cid, it])
		for f in ch.get("flags", {}):
			if not str(f).begins_with("ct_"):
				errors.append(tag + "choice %s: flag %s must start ct_" % [cid, f])
	return errors

static func _validate_poster(c: Dictionary, tag: String, zones: Dictionary, dialogue: Dictionary) -> Array:
	var errors := []
	var id := str(c.get("id", ""))
	var p: Dictionary = c.get("poster", {})
	for f in ["name", "role", "idle", "taken", "decided"]:
		if p.get(f) == null or (p[f] is String and p[f] == "") or (p[f] is Array and (p[f] as Array).is_empty()):
			errors.append(tag + "poster has no " + f)
	if str(c.get("town", "")) != "" and not _has_npc(zones, dialogue, str(c.town), func(cmd): return str(cmd.get("do", "")) == "contract" and str(cmd.get("as", "")) == "poster" and str(cmd.get("id", "")) == id):
		errors.append(tag + "no poster NPC in " + str(c.get("town", "")))
	return errors
