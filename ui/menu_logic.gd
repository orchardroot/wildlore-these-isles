class_name MenuLogic
extends RefCounted
## Pure helpers behind the menus, so they can be tested without a scene tree.

const MAX_STACK := Bag.MAX_STACK

static func wrap_index(i: int, delta: int, n: int) -> int:
	if n <= 0:
		return 0
	return posmod(i + delta, n)

static func can_afford(money: int, price: int, qty: int) -> bool:
	return qty > 0 and money >= price * qty

## How many more of an item can be bought: limited by money and by the stack cap.
static func max_buy(money: int, price: int, owned := 0) -> int:
	var room := maxi(0, MAX_STACK - owned)
	if price <= 0:
		return room
	return mini(room, money / price)

static func sell_price(price: int) -> int:
	return maxi(0, price) / 2

## A copy of `arr` with the entries at a and b swapped. Out-of-range indices change nothing.
static func reorder(arr: Array, a: int, b: int) -> Array:
	var out := arr.duplicate()
	if a < 0 or b < 0 or a >= out.size() or b >= out.size():
		return out
	var t = out[a]
	out[a] = out[b]
	out[b] = t
	return out

## species id -> [zone names], in the order the zones were given.
static func habitat_index(zones: Array) -> Dictionary:
	var idx := {}
	for z in zones:
		var seen := {}
		for table in z.get("encounters", {}).values():
			for e in table:
				var sp := str(e.get("species", ""))
				if sp != "" and not seen.has(sp):
					seen[sp] = true
					if not idx.has(sp):
						idx[sp] = []
					idx[sp].append(str(z.get("name", z.get("id", "?"))))
	return idx

## species id -> ["Zone (conditions)"]: like habitat_index, but each place says when the species turns up there,
## e.g. "Bowland Moor (dusk/night, fog)". Any entry with no conditions means "any time", so no brackets.
static func habitat_labels(zones: Array) -> Dictionary:
	var idx := {}
	for z in zones:
		var conds := {}  # species -> condition labels ("" = any time), in first-seen order
		for table in z.get("encounters", {}).values():
			for e in table:
				var sp := str(e.get("species", ""))
				if sp == "":
					continue
				if not conds.has(sp):
					conds[sp] = []
				var c := _condition(e)
				if c not in conds[sp]:
					conds[sp].append(c)
		var zname := str(z.get("name", z.get("id", "?")))
		for sp in conds:
			if not idx.has(sp):
				idx[sp] = []
			var any_time: bool = "" in conds[sp]
			idx[sp].append(zname if any_time else "%s (%s)" % [zname, " or ".join(conds[sp])])
	return idx

const TIME_ORDER := ["dawn", "day", "dusk", "night"]

## "dusk/night, fog" for one encounter entry; "" when it has no time or weather limits.
static func _condition(e: Dictionary) -> String:
	var parts := []
	var times: Array = e.get("time", [])
	var weathers: Array = e.get("weather", [])
	if not times.is_empty():
		parts.append("/".join(TIME_ORDER.filter(func(t): return t in times)))
	if not weathers.is_empty():
		parts.append("/".join(Rules.WEATHERS.filter(func(w): return w in weathers)))
	return ", ".join(parts)

static func habitats(index: Dictionary, species_id: String) -> Array:
	return index.get(species_id, []).duplicate()

static func hp_band(hp: int, max_hp: int) -> String:
	if max_hp <= 0 or hp <= 0:
		return "red"
	var f := float(hp) / float(max_hp)
	if f > 0.25 + 0.0001:
		return "green"
	if f > 0.125:
		return "amber"
	return "red"

## "H:MM" from seconds.
static func play_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	return "%d:%02d" % [mins / 60, mins % 60]

## Fieldbook paging: jump `delta` entries, stopping at either end; from an end, wrap round to the other.
static func page_index(i: int, delta: int, n: int) -> int:
	if n <= 0:
		return 0
	var last := n - 1
	if delta > 0 and i >= last:
		return 0
	if delta < 0 and i <= 0:
		return last
	return clampi(i + delta, 0, last)

const FILTERS := ["all", "caught", "seen", "rumours"]  # the last is the Fieldbook's Rumours tab

static func next_filter(f: String, book := false, cases := false, words := false) -> String:
	var all := FILTERS + (["casebook"] if cases else []) + (["studbook"] if book else []) + (["words"] if words else [])  # the Stud Book tab follows Rumours once there is something in it
	return all[(all.find(f) + 1) % all.size()]

## The Fieldbook's ids for a filter: "all", "caught", or "seen" (which includes caught).
static func fieldbook_filter(ids: Array, seen: Dictionary, caught: Dictionary, f: String) -> Array:
	match f:
		"caught":
			return ids.filter(func(id): return caught.has(id))
		"seen":
			return ids.filter(func(id): return seen.has(id) or caught.has(id))
	return ids.duplicate()

const NAMES_SEP := " · "

## The Fieldbook's one-line local names for a creature's real-life basis: "cy llwynog · ga sionnach · gd sionnach",
## always in cy, ga, gd order from whichever keys `names` has (see docs/design/fieldbook_teaching.md). "" when it
## has none, so a creature based on a place or a machine shows no empty slot.
static func fieldbook_names_line(names: Dictionary) -> String:
	var parts := []
	for code in Langs.CREATURE_NAME_CODES:
		var word := str(names.get(code, "")).strip_edges()
		if word != "":
			parts.append("%s %s" % [code, word])
	return NAMES_SEP.join(parts)

const TIME_WORDS := {"dawn": "at dawn", "day": "by day", "dusk": "at dusk", "night": "at night"}
const WEATHER_WORDS := {"clear": "under clear skies", "sunshine": "in sunshine", "drizzle": "in drizzle", "downpour": "in a downpour",
	"fog": "in fog", "gale": "in a gale", "frost": "in a frost"}

## "Evolves into Sootwing at Lv 20, at night" from a species' `evolves`. An empty target_name (not seen yet)
## leaves the name out; item_name is the evolution item's display name.
static func evolution_text(evo, target_name: String, item_name := "", zone_names = null) -> String:
	if not (evo is Dictionary) or not evo.has("to"):
		return ""
	var s := "Evolves" + (" into " + target_name if target_name != "" else "")
	if evo.has("item"):
		var nm := item_name if item_name != "" else str(evo.item).capitalize()
		s += " with %s %s" % ["an" if nm.left(1).to_lower() in ["a", "e", "i", "o", "u"] else "a", nm]
	if evo.has("level"):
		s += " at Lv %d" % int(evo.level)
	var extra := []
	if evo.has("time"):
		extra.append(TIME_WORDS.get(str(evo.time), "at " + str(evo.time)))
	if evo.has("weather"):
		extra.append(WEATHER_WORDS.get(str(evo.weather), "in " + str(evo.weather)))
	if evo.has("season"):
		extra.append("in " + str(evo.season))
	if evo.has("zone"):
		var zs: Array = evo.zone if evo.zone is Array else [evo.zone]
		var names := []
		for z in zs:
			names.append(zone_names.get(str(z), str(z).capitalize().replace("_", " ")) if zone_names != null else str(z).capitalize().replace("_", " "))
		extra.append("in " + " or ".join(names))
	if evo.has("flag"):
		extra.append(str(evo.get("flag_text", "once you have earned it")))
	if evo.has("friendship"):
		extra.append("once it trusts you")
	if not extra.is_empty():
		s += (", " if evo.has("level") or evo.has("item") else " ") + " and ".join(extra)
	if evo.has("bond"):
		s += ", or sooner if it really trusts you"
	return s

const WEATHER_NAMES := {"clear": "clear skies"}

## The pause card's "Now" line: "Dusk, drizzle". Indoors there's no weather; "" weather shows the time only.
static func now_text(minutes: int, weather: String, indoors := false, clock := "") -> String:
	var t := GameClock.phase(minutes).capitalize()
	if clock != "":
		t = clock + ", " + t.to_lower()
	if indoors:
		return t + ", indoors"
	if weather == "":
		return t
	return "%s, %s" % [t, WEATHER_NAMES.get(weather, weather)]

## The pause menu offers the Ark once you've chatted to a Sanctuary nurse (every nurse sets _nurse_choice),
## or once anyone is in the Ark already.
static func ark_unlocked(d: GameStateData) -> bool:
	return d.flag("_nurse_choice") != null or not d.ark.is_empty()

## The pause menu's entries: the Ark once a Sanctuary nurse has shown you it, the Journal (quests and the
## Gazetteer), the Almanac (every page in one place), and always Close.
static func pause_entries(ark: bool) -> Array:
	return ["Team", "Fieldbook", "Bag", "Wardrobe"] + (["Ark"] if ark else []) + ["Journal", "Almanac", "Map", "Save", "Settings", "Close"]

## The height for each of `n` rows sharing `avail` px with `sep` between them, kept between `lo` and `hi`.
static func row_height(avail: float, n: int, sep: int, lo: int, hi: int) -> int:
	if n <= 0:
		return hi
	return clampi(int((avail - sep * (n - 1)) / n), lo, hi)

## The Bag's party picker stays open after a use while there's still some of the item left.
static func stay_in_picker(ok: bool, remaining: int) -> bool:
	return remaining > 0 or not ok

const OBJECTIVES_PATH := "res://data/objectives.json"
static var _objectives: Dictionary = {}

static func objectives() -> Dictionary:
	if _objectives.is_empty():
		var o = JsonUtil.read(OBJECTIVES_PATH)
		_objectives = o if o is Dictionary else {"story": [], "postgame": [], "rematches": []}
	return _objectives

static func _done(d: GameStateData, key: String) -> bool:
	var v: Variant = d.flag(key)
	match typeof(v):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return v != 0
		TYPE_STRING:
			return v != ""
	return true

## "Where next?": {text, town, map?, postgame?}. Story: the step after the furthest one done, so an
## optional beat the player walked past never nags. After game_complete: a Fieldbook reward waiting, else the
## first post-game hint not done (the last, catch-all one gives way to the next Fieldbook milestone).
## `total` is the number of species (for {total}); `o` defaults to data/objectives.json. With nothing left but the
## catch-all, a Keeper waiting with a side story of their own (SideStories; `sides` defaults to the real ones), else a
## rewilding site, else a quest under way near the last town (Quests; `quests` defaults to the real ones), else the
## next Fieldbook milestone.
static func next_objective(d: GameStateData, total := 0, o := {}, sides: Array = [], quests: Array = []) -> Dictionary:
	if o.is_empty():
		o = objectives()
	var story: Array = o.get("story", [])
	if not _done(d, "game_complete"):
		var next := 0
		for i in story.size():
			if _done(d, str(story[i].get("flag_done", ""))):
				next = i + 1
		if next < story.size():
			return story[next]
		return story.back() if not story.is_empty() else {}
	if FieldbookGoals.pending(d) > 0:  # a Fieldbook reward waiting at the Field Station comes first
		return {"text": FieldbookGoals.hint(d), "town": "macclesfield", "postgame": true}
	for e in o.get("postgame", []):
		var need: Array = e.get("all", [])
		if e.has("flag_done"):
			need = need + [e.flag_done]
		if not need.is_empty() and need.all(func(f): return _done(d, str(f))):
			continue
		var out: Dictionary = e.duplicate()
		var legends: Array = e.get("all", [])
		out["text"] = str(e.get("text", "")).replace("{caught}", str(FieldbookGoals.caught_count(d))).replace("{total}", str(total)) \
			.replace("{legends}", str(legends.filter(func(f): return _done(d, str(f))).size()))
		var side := SideStories.next_hint(d, sides) if need.is_empty() else {}
		if not side.is_empty():  # nothing else left: someone in town would like a word
			out = side
		elif need.is_empty() and not Rewild.hint_entry(d).is_empty():  # or a rewilding site wants a hand
			out = Rewild.hint_entry(d)
		elif need.is_empty() and not quest_entry(d, quests).is_empty():  # or a quest under way near where you are
			out = quest_entry(d, quests)
		elif need.is_empty() and FieldbookGoals.hint(d) != "":  # or the next Fieldbook milestone
			out = {"text": FieldbookGoals.hint(d), "town": "macclesfield"}
		out["postgame"] = true
		return out
	return {}

## The pause card's "Around here" line before the ending ("" when there's nothing, and after it, where "Still to do"
## covers the same ground): a job ready to hand in, else today's County Show if it's in `town`, else a rewilding
## site that wants a hand, else a side story waiting in `town`. `show` is today's show (Tournament.today), `sides`
## defaults to the real side stories.
static func around_here(d: GameStateData, town: String, show := {}, sides: Array = []) -> String:
	if _done(d, "game_complete"):
		return ""
	for a in Jobs.active(d):
		if str(a[2].get("step", {}).get("type", "")) not in Jobs.AUTO and Jobs.is_ready(d, a[0], null):
			return "Job ready to hand in at any noticeboard in %s: %s." % [Standing.name_of(str(a[2].get("nation", ""))), str(a[2].get("title", ""))]
	if town != "" and str(show.get("town", "")) == town and Tournament.open_to(d):
		var nm := str(show.get("name", "the County Show"))
		return "%s is on here today. Enter at the ring." % (nm.left(1).to_upper() + nm.substr(1))
	var site := Rewild.hint_entry(d)
	if not site.is_empty():
		return str(site.text)
	for s in (sides if not sides.is_empty() else SideStories.sides()):
		if town != "" and str(s.get("zone", "")) == town and SideStories.waiting(d, s):
			return str(s.get("hint", ""))
	return ""

## A quest under way near the last town you were in, as a "Where next?" entry {text, town}, or {}.
static func quest_entry(d: GameStateData, quests: Array = []) -> Dictionary:
	var town := str(d.flag("last_town")) if d.flag("last_town") != null else ""
	var idx := ZoneIndex.get_index()
	var q := Quests.nearby(d, town, idx, quests)
	if q.is_empty():
		return {}
	return {"text": Quests.hint_line(d, town, idx, quests), "town": Quests.map_zone(str(Quests.current_step(d, q).get("zone", "")), idx)}

## The pause card's quest line before the ending: one quest under way near `town` ("" for none). Short: its
## title and the next step.
static func quest_nearby(d: GameStateData, town: String, quests: Array = []) -> String:
	if _done(d, "game_complete"):
		return ""
	return Quests.hint_line(d, town, ZoneIndex.get_index(), quests)

## Names of the people whose once-a-day rematch hasn't been fought today (post-game only).
static func rematches_ready(d: GameStateData, o := {}) -> Array:
	if o.is_empty():
		o = objectives()
	if not _done(d, "game_complete"):
		return []
	var out := []
	for r in o.get("rematches", []):
		if not DailyKey.done_today(d, str(r.get("key", ""))):
			out.append(str(r.get("name", "")))
	return out
