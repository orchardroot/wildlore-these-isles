class_name Jobs
extends RefCounted
## Odd jobs off the parish noticeboards (data/jobs.json). Every town's board offers two or three jobs a day, drawn
## from that town's own and its nation's, gated by badges so early towns never ask for a level-60 anything. You can
## carry three at once. Catch and beat jobs finish themselves (with a toast); the rest are handed in at any
## noticeboard in the job's nation. Rewards: money scaled to progress, standing (see Standing), sometimes
## materials, a recipe or, rarely, a charm.
##
## State is all flags (the `job_*` namespace, nothing when missing so old saves are fine):
##   job_1..job_3   one per slot: {id, n (progress), need, lvl (show jobs), town, nation}
##   job_day        DailyKey stamp of the board day; a new real day (or the marathon fallback) moves job_epoch on
##   job_epoch      which board day it is (seeds each board's pick)
##   job_done       ids finished this board day, comma separated (they leave the board until tomorrow)
##   job_treat_<nation>  the Local landlord's parcel, once per real day
## Pure logic (no autoload names): the validator loads this.

const PATH := "res://data/jobs.json"
const SLOTS := 3
const SLOT_PREFIX := "job_"
const DAY_FLAG := "job_day"
const EPOCH_FLAG := "job_epoch"
const DONE_FLAG := "job_done"
const TREAT_PREFIX := "job_treat_"
const STEP_TYPES := ["catch", "show", "bring", "beat", "visit", "forage"]
## These finish themselves the moment they're done; the rest go back to a noticeboard.
const AUTO := ["catch", "beat"]
const STANDING_FOR_PAY := {1: 2, 2: 3, 3: 5}
const WEATHER := {"rain": ["drizzle", "downpour"], "fog": ["fog"], "gale": ["gale"], "frost": ["frost"],
	"sunshine": ["sunshine"], "clear": ["clear", "sunshine"]}
const PHASE_WORDS := {"night": "after dark", "dawn": "at dawn", "dusk": "at dusk", "day": "in daylight"}
const WEATHER_WORDS := {"rain": "in the rain", "fog": "in the fog", "gale": "in a gale", "frost": "on a frosty day",
	"sunshine": "in the sunshine", "clear": "on a clear day"}
## Badges you'll usually have on first walking into each nation (tests check every town has work by then).
const ARRIVAL_BADGES := {"england": 0, "wales": 3, "mann": 5, "ireland": 6, "northern_ireland": 7, "scotland": 8, "channel_islands": 4}

static var _cache: Array = []
static var _by_id: Dictionary = {}

static func all() -> Array:
	if _cache.is_empty():
		var d = JsonUtil.read(PATH)
		use(d.get("jobs", []) if d is Dictionary else [])
	return _cache

## Swap in a job list (tests); reset() goes back to the file.
static func use(list: Array) -> void:
	_cache = list
	_by_id = {}
	for j in list:
		_by_id[str(j.get("id", ""))] = j

static func reset() -> void:
	_cache = []
	_by_id = {}

static func get_job(id: String) -> Dictionary:
	all()
	return _by_id.get(id, {})

# --- the board ------------------------------------------------------------------

## The board day: moves on with the real date (DailyKey, so the marathon fallback frees it after four hours of play
## and an in-game midnight). Clears the "done today" list when it does.
static func epoch(data: GameStateData) -> int:
	if not DailyKey.is_today(data, data.flag(DAY_FLAG)):
		data.set_flag(EPOCH_FLAG, _int(data.flag(EPOCH_FLAG)) + 1)
		data.set_flag(DAY_FLAG, DailyKey.stamp(data))
		data.set_flag(DONE_FLAG, "")
	return _int(data.flag(EPOCH_FLAG))

static func eligible(job: Dictionary, nation: String, town: String, badges: int) -> bool:
	var jt := str(job.get("town", ""))
	return str(job.get("nation", "")) == nation and (jt == "" or jt == town) and badges >= int(job.get("badges", 0))

## Today's two or three jobs on `town`'s board (the same all day; taken and finished ones stay listed, and the
## screen shows them as such). The town's own jobs come first, then the nation's.
static func offers(data: GameStateData, town: String) -> Array:
	var e := epoch(data)
	var nation := Standing.nation_for_zone(town)
	var badges := data.badges.size()
	var local := []
	var wide := []
	for j in all():
		if eligible(j, nation, town, badges):
			(local if str(j.get("town", "")) == town else wide).append(j)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%d" % [town, e, data.rng_seed])
	_shuffle(local, rng)
	if badges == 0: local.sort_custom(func(a, b): return a.get("first", false) and not b.get("first", false))  # before Maud, the first job leads
	_shuffle(wide, rng)
	var want := 2 + rng.randi() % 2
	var out := local.slice(0, mini(2, want))
	for j in wide:
		if out.size() >= want:
			break
		out.append(j)
	for j in local.slice(out.size()):
		if out.size() >= want:
			break
		out.append(j)
	return out

static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var k := rng.randi() % (i + 1)
		var t = a[i]
		a[i] = a[k]
		a[k] = t

static func done_today(data: GameStateData, id: String) -> bool:
	epoch(data)
	return id in str(data.flag(DONE_FLAG) if data.flag(DONE_FLAG) != null else "").split(",")

# --- slots ------------------------------------------------------------------------

static func slot(data: GameStateData, i: int) -> Dictionary:
	var v = data.flag(SLOT_PREFIX + str(i))
	return v if v is Dictionary and str(v.get("id", "")) != "" and not get_job(str(v.id)).is_empty() else {}

## Filled slots as [slot number, slot dict, job].
static func active(data: GameStateData) -> Array:
	var out := []
	for i in range(1, SLOTS + 1):
		var s := slot(data, i)
		if not s.is_empty():
			out.append([i, s, get_job(str(s.id))])
	return out

static func has_active(data: GameStateData, id: String) -> bool:
	return active(data).any(func(a): return str(a[1].id) == id)

## Takes a job. "" when it worked, else why not.
static func accept(data: GameStateData, id: String, town: String) -> String:
	var j := get_job(id)
	if j.is_empty():
		return "That notice has blown away."
	if has_active(data, id):
		return "You're already on that one."
	if done_today(data, id):
		return "Done and dusted today. Check back tomorrow."
	for i in range(1, SLOTS + 1):
		if slot(data, i).is_empty():
			var st: Dictionary = j.get("step", {})
			var s := {"id": id, "n": 0, "need": need_of(j), "town": town, "nation": str(j.nation)}
			if str(st.get("type", "")) == "show":
				s["lvl"] = show_level(data.badges.size())
			data.set_flag(SLOT_PREFIX + str(i), s)
			return ""
	return "Your hands are full: three jobs at once is plenty."

static func abandon(data: GameStateData, i: int) -> void:
	data.set_flag(SLOT_PREFIX + str(i), {})

static func need_of(j: Dictionary) -> int:
	var st: Dictionary = j.get("step", {})
	return 1 if str(st.get("type", "")) in ["show", "visit"] else maxi(1, int(st.get("n", 1)))

## What a show job asks for at this many badges: roughly where the wild creatures are, never absurd.
static func show_level(badges: int) -> int:
	return clampi(5 + badges * 7, 5, 70)

## Money scales with progress: a big job late on is worth a charm's price.
static func money_for(j: Dictionary, badges: int) -> int:
	return int(round(int(j.get("pay", 1)) * (100 + 90 * badges) / 10.0)) * 10

# --- progress ---------------------------------------------------------------------

static func _bump(data: GameStateData, i: int, s: Dictionary) -> bool:
	var was := int(s.get("n", 0)) >= int(s.get("need", 1))
	s["n"] = mini(int(s.get("n", 0)) + 1, int(s.get("need", 1)))
	data.set_flag(SLOT_PREFIX + str(i), s)
	return not was and int(s.n) >= int(s.get("need", 1))

## A creature was caught: catch jobs for that species, or any of the type, move on. Returns slots now done.
static func note_catch(data: GameStateData, species_id: String, dex: Dex) -> Array:
	var sp: Dictionary = dex.get_species(species_id) if dex.has(species_id) else {}
	var out := []
	for a in active(data):
		var st: Dictionary = a[2].get("step", {})
		if str(st.get("type", "")) != "catch":
			continue
		var hit: bool = str(st.get("species", "")) == species_id if st.has("species") else str(st.get("ctype", "")) in sp.get("types", [])
		if hit and _bump(data, a[0], a[1]):
			out.append(a[0])
	return out

static func _note_zone(data: GameStateData, kind: String, zone_id: String) -> Array:
	var out := []
	for a in active(data):
		var st: Dictionary = a[2].get("step", {})
		if str(st.get("type", "")) == kind and str(st.get("zone", "")) == zone_id and _bump(data, a[0], a[1]):
			out.append(a[0])
	return out

## A wild battle won in `zone_id`.
static func note_win(data: GameStateData, zone_id: String) -> Array:
	return _note_zone(data, "beat", zone_id)

## Something foraged in `zone_id`.
static func note_forage(data: GameStateData, zone_id: String) -> Array:
	return _note_zone(data, "forage", zone_id)

## Standing in `zone_id` at this time of day (dawn/day/dusk/night) in this weather.
static func note_visit(data: GameStateData, zone_id: String, phase: String, weather: String) -> Array:
	var out := []
	for a in active(data):
		var st: Dictionary = a[2].get("step", {})
		if str(st.get("type", "")) != "visit" or str(st.get("zone", "")) != zone_id:
			continue
		var times: Array = st.get("time", [])
		if not times.is_empty() and phase not in times:
			continue
		var w := str(st.get("weather", ""))
		if w != "" and weather not in WEATHER.get(w, [w]):
			continue
		if _bump(data, a[0], a[1]):
			out.append(a[0])
	return out

## True when slot i's job can be handed in (bring: the goods are in the bag; show: someone fit is in the team).
static func is_ready(data: GameStateData, i: int, dex: Dex) -> bool:
	var s := slot(data, i)
	if s.is_empty():
		return false
	var st: Dictionary = get_job(str(s.id)).get("step", {})
	match str(st.get("type", "")):
		"bring":
			return Bag.new(data.bag).count(str(st.get("item", ""))) >= int(st.get("n", 1))
		"show":
			return show_fit(data, str(st.get("ctype", "")), int(s.get("lvl", 1)), str(st.get("species", ""))) != null
	return int(s.get("n", 0)) >= int(s.get("need", 1))

## The first team member who'd do for a show job, or null.
static func show_fit(data: GameStateData, ctype: String, lvl: int, species := "") -> Creature:
	for c in data.party:
		var ok: bool = str(c.species.id) == species if species != "" else ctype in c.species.get("types", [])
		if ok and c.level >= lvl:
			return c
	return null

## Slots whose job finishes by itself and is done now (catch and beat).
static func auto_ready(data: GameStateData, dex: Dex) -> Array:
	var out := []
	for a in active(data):
		if str(a[2].get("step", {}).get("type", "")) in AUTO and is_ready(data, a[0], dex):
			out.append(a[0])
	return out

# --- finishing --------------------------------------------------------------------

## Pays slot i out and clears it. {id, title, poster, money, got: {item: n}, recipe (name or ""), standing, tier_line}.
static func complete(data: GameStateData, i: int, items: ItemDB) -> Dictionary:
	var s := slot(data, i)
	if s.is_empty():
		return {}
	var j := get_job(str(s.id))
	var st: Dictionary = j.get("step", {})
	var bag := Bag.new(data.bag)
	if str(st.get("type", "")) == "bring":
		bag.remove(str(st.item), int(st.get("n", 1)))
	var rw: Dictionary = j.get("reward", {})
	var cur := Wallet.currency_of_nation(str(j.get("nation", "")))  # an Irish job pays in euros
	var money := Wallet.localise(money_for(j, data.badges.size()), cur)
	Wallet.earn(data, money, cur)
	var got := {}
	var gifts: Dictionary = rw.get("items", {}).duplicate()
	if str(rw.get("charm", "")) != "":
		gifts[str(rw.charm)] = 1
	for id in gifts:
		var n := bag.add(str(id), int(gifts[id]))
		if n > 0:
			got[str(id)] = n
	var recipe := ""
	var rid := str(rw.get("recipe", ""))
	if rid != "" and Crafting.has(rid) and Crafting.learn(data, rid):
		var r := Crafting.get_recipe(rid)
		recipe = str(items.get_item(str(r.out)).get("name", str(r.out).capitalize())) if items != null else rid
	var pts := int(rw.get("standing", STANDING_FOR_PAY.get(int(j.get("pay", 1)), 2)))
	var line := Standing.add(data, str(j.nation), pts)
	abandon(data, i)
	epoch(data)
	var done := str(data.flag(DONE_FLAG) if data.flag(DONE_FLAG) != null else "")
	data.set_flag(DONE_FLAG, (done + "," if done != "" else "") + str(j.id))
	return {"id": str(j.id), "title": str(j.get("title", "")), "poster": str(j.get("poster", "")), "money": money, "cur": cur,
		"got": got, "recipe": recipe, "standing": pts, "nation": str(j.nation), "tier_line": line}

## At a noticeboard in `nation`: hands in every ready job of that nation.
static func hand_in(data: GameStateData, nation: String, items: ItemDB, dex: Dex) -> Array:
	var out := []
	for a in active(data):
		if str(a[2].get("nation", "")) == nation and is_ready(data, a[0], dex):
			out.append(complete(data, a[0], items))
	return out

## The Local landlord's parcel: the nation's food, once per real day. "" when not due (or not Local yet).
static func landlord_parcel(data: GameStateData, nation: String) -> String:
	if not Standing.is_nation(nation) or Standing.tier(data, nation) < Standing.LOCAL:
		return ""
	if DailyKey.done_today(data, TREAT_PREFIX + nation):
		return ""
	data.set_flag(TREAT_PREFIX + nation, DailyKey.stamp(data))
	var food := str(Standing.LANDLORD_FOOD[nation])
	Bag.new(data.bag).add(food, 1)
	return food

# --- words ------------------------------------------------------------------------

static func _type_name(t: String) -> String:
	return t.capitalize() + "-type"

static func _zone_name(id: String) -> String:
	var z: Dictionary = ZoneIndex.get_index().zones.get(id, {})
	return str(z.get("name", id.capitalize()))

## "Bring 3 Blackberries", "Catch a Croakle", "Win 2 wild battles in Macclesfield Forest".
static func step_text(j: Dictionary, s: Dictionary, items: ItemDB, dex: Dex) -> String:
	var st: Dictionary = j.get("step", {})
	var n := int(st.get("n", 1))
	match str(st.get("type", "")):
		"catch":
			if st.has("species"):
				var nm := str(dex.get_species(str(st.species)).get("name", str(st.species).capitalize()))
				return "Catch a%s %s" % ["n" if nm.left(1) in ["A", "E", "I", "O", "U"] else "", nm] if n <= 1 else "Catch %d %s" % [n, nm]
			return "Catch a%s %s creature" % ["n" if str(st.ctype).left(1) in ["a", "e", "i", "o", "u"] else "", _type_name(str(st.ctype))] if n <= 1 \
				else "Catch %d %s creatures" % [n, _type_name(str(st.ctype))]
		"show":
			var what := str(dex.get_species(str(st.species)).get("name", "")) if st.has("species") else _type_name(str(st.get("ctype", "")))
			return "Show a%s %s at level %d or above" % ["n" if what.left(1) in ["A", "E", "I", "O", "U"] else "", what, int(s.get("lvl", show_level(int(j.get("badges", 0)))))]
		"bring":
			var it := items.get_item(str(st.get("item", "")))
			var nm := str(it.get("name", str(st.get("item", ""))))
			return "Bring %s" % (str(it.get("one", "a " + nm)) if n <= 1 else "%d %s" % [n, nm])
		"beat":
			return "Win %d wild battle%s in %s" % [n, "" if n == 1 else "s", _zone_name(str(st.get("zone", "")))]
		"visit":
			var when := []
			for t in st.get("time", []):
				when.append(PHASE_WORDS.get(str(t), str(t)))
			var bits := " or ".join(when)
			if str(st.get("weather", "")) != "":
				bits = (bits + " " if bits != "" else "") + str(WEATHER_WORDS.get(str(st.weather), str(st.weather)))
			return ("Go to %s %s" % [_zone_name(str(st.get("zone", ""))), bits]).strip_edges()
		"forage":
			return "Forage %d time%s in %s" % [n, "" if n == 1 else "s", _zone_name(str(st.get("zone", "")))]
	return ""

## "1 / 3", "Ready to hand in", "Done" for slot i.
static func progress_text(data: GameStateData, i: int, dex: Dex) -> String:
	var s := slot(data, i)
	if s.is_empty():
		return ""
	var j := get_job(str(s.id))
	var kind := str(j.get("step", {}).get("type", ""))
	if is_ready(data, i, dex):
		return "Ready: hand in at any noticeboard in %s" % Standing.mid_name(str(j.nation))
	if kind == "bring":
		var st: Dictionary = j.get("step", {})
		return "Have %d of %d" % [mini(Bag.new(data.bag).count(str(st.get("item", ""))), int(st.get("n", 1))), int(st.get("n", 1))]
	if kind == "show":
		return "Not yet"
	return "%d / %d" % [int(s.get("n", 0)), int(s.get("need", 1))]

## At a board in `nation`: why each held job didn't hand in, so the board can say so. "Tea for the planning meeting:
## still needs a Flask of Tea." or "Bog census: done, hand it in at a board in England." Jobs that finish themselves
## and aren't done yet say nothing (their progress is on the list).
static func held_back(data: GameStateData, nation: String, items: ItemDB, dex: Dex) -> Array:
	var out := []
	for a in active(data):
		var j: Dictionary = a[2]
		var title := str(j.get("title", ""))
		if is_ready(data, a[0], dex):
			if str(j.get("nation", "")) != nation:
				out.append("%s: done, hand it in at a board in %s." % [title, Standing.mid_name(str(j.nation))])
			continue
		var st: Dictionary = j.get("step", {})
		match str(st.get("type", "")):
			"bring":
				var n := int(st.get("n", 1))
				var it := items.get_item(str(st.get("item", "")))
				var nm := str(it.get("name", str(st.get("item", ""))))
				out.append("%s: still needs %s." % [title, str(it.get("one", "a " + nm)) if n <= 1 else "%d %s" % [n, nm]])
			"show":
				out.append("%s: %s." % [title, step_text(j, slot(data, a[0]), items, dex).to_lower()])
	return out

## One line for the pause menu's "Where next?" card: "Jobs in hand: 2 of 3, 1 ready to hand in", or "".
static func summary(data: GameStateData, dex: Dex) -> String:
	var held := active(data)
	if held.is_empty():
		return ""
	var ready := held.filter(func(a): return is_ready(data, a[0], dex)).size()
	return "Jobs in hand: %d of %d%s" % [held.size(), SLOTS, (", %d ready to hand in" % ready) if ready > 0 else ""]

## Short lines for the Stats page's "Where next?" card: "Bats at the castle: 0 / 1".
static func pause_lines(data: GameStateData, dex: Dex) -> Array:
	var out := []
	for a in active(data):
		var p := "ready" if is_ready(data, a[0], dex) else progress_text(data, a[0], dex)
		out.append("%s: %s" % [str(a[2].get("title", "")), p])
	return out

# --- checking the data ------------------------------------------------------------

static func validate(items: ItemDB, dex: Dex, zones: Dictionary) -> Array:
	var e := []
	var seen := {}
	var types := TypeChart.load_default().types
	for j in all():
		var id := str(j.get("id", ""))
		var tag := "job '%s': " % id
		if id == "" or seen.has(id):
			e.append(tag + "id is missing or duplicated")
		seen[id] = true
		var nation := str(j.get("nation", ""))
		if not Standing.is_nation(nation):
			e.append(tag + "unknown nation '%s'" % nation)
		var town := str(j.get("town", ""))
		if town != "" and (not zones.has(town) or Standing.nation_for_zone(town) != nation):
			e.append(tag + "town '%s' is unknown or not in %s" % [town, nation])
		for k in ["title", "text", "poster"]:
			var t := str(j.get(k, ""))
			if t == "":
				e.append(tag + "no " + k)
			if "—" in t:
				e.append(tag + "em-dash in " + k)
		if int(j.get("pay", 0)) < 1 or int(j.get("pay", 0)) > 3:
			e.append(tag + "pay must be 1, 2 or 3")
		if int(j.get("badges", 0)) < 0 or int(j.get("badges", 0)) > 10:
			e.append(tag + "badges must be 0..10")
		var st: Dictionary = j.get("step", {})
		var kind := str(st.get("type", ""))
		if kind not in STEP_TYPES:
			e.append(tag + "unknown step '%s'" % kind)
		if st.has("species") and not dex.has(str(st.species)):
			e.append(tag + "unknown species '%s'" % st.species)
		if st.has("ctype") and not types.is_empty() and str(st.ctype) not in types:
			e.append(tag + "unknown type '%s'" % st.ctype)
		if kind in ["catch", "show"] and not st.has("species") and not st.has("ctype"):
			e.append(tag + "%s needs a species or a ctype" % kind)
		if kind == "bring" and not items.has(str(st.get("item", ""))):
			e.append(tag + "bring unknown item '%s'" % st.get("item", ""))
		if kind in ["beat", "visit", "forage"] and not zones.has(str(st.get("zone", ""))):
			e.append(tag + "unknown zone '%s'" % st.get("zone", ""))
		for t in st.get("time", []):
			if str(t) not in PHASE_WORDS:
				e.append(tag + "unknown time '%s'" % t)
		if str(st.get("weather", "")) != "" and not WEATHER.has(str(st.weather)):
			e.append(tag + "unknown weather '%s'" % st.weather)
		var rw: Dictionary = j.get("reward", {})
		for it in rw.get("items", {}):
			if not items.has(str(it)):
				e.append(tag + "reward item '%s' does not exist" % it)
		if str(rw.get("charm", "")) != "" and str(items.get_item(str(rw.charm)).get("kind", "")) != "charm":
			e.append(tag + "reward charm '%s' is not a charm" % rw.charm)
		if str(rw.get("recipe", "")) != "" and not Crafting.has(str(rw.recipe)):
			e.append(tag + "reward recipe '%s' does not exist" % rw.recipe)
	return e

static func _int(v: Variant) -> int:
	return int(v) if (v is int or v is float) else 0
