class_name RouteChampions
extends RefCounted
## The Walkers' League (wave 57): each of the thirty roads from waves 55 and 56 has one champion, the strongest trainer
## on it (data/route_champions.json). The first fight is the trainer's own, as ever. Once that is won the champion
## can be challenged again, once a real week (Monday to Sunday, WeeklyChallenge.week_number), at the player's par
## (ParLevel): a team of four, two stayers from the champion's own side, one creature the season brings and one the
## weather of the day brings. Beating champions earns a title at ten, twenty and thirty, each with a keepsake for
## the home shelf (HomeExtras). Prize money is small and only ever paid for a rematch won (see PRIZE_PER_LEVEL).
## State is all flags with safe defaults, so an old save just reads as "beaten before the League kept dates":
##   trainer_<id>   the first win (already how every trainer is remembered)
##   rc_first_<id>  the real date of that win, when it was won after the League began
##   rc_week_<id>   the week number of the last rematch won
##   rc_wins_<id>   rematches won
##   rc_titles      how many titles have been announced
## Pure logic, no autoloads: the story side is story/champion_run.gd, the page is ui/league_tab.gd.

const DATA_PATH := "res://data/route_champions.json"
const FIRST_PREFIX := "rc_first_"
const WEEK_PREFIX := "rc_week_"
const WINS_PREFIX := "rc_wins_"
const TITLES_FLAG := "rc_titles"
const LEAGUE_SIZE := 30   # the roads of waves 55 and 56
const SEASONS := ["spring", "summer", "autumn", "winter"]
const WEATHER_KINDS := ["wet", "rough", "fair"]
## Sterling a rematch pays per level of par, once a week for each champion: about 300 at the very top. A Keeper's
## rematch pays 16,500 a day; nothing here comes close.
const PRIZE_PER_LEVEL := 3
## Level added to the party slots, over the floor of the road (which ParLevel then lifts to the player's par).
const LEVEL_STEPS := [0, 0, 0, 1]
const KEEPSAKE_SHAPES := ["stick", "jug", "helmet", "pencil", "bead", "ball", "badge", "coaster", "figure", "ring", "cloth", "tin", "lamp"]

static var _config: Dictionary = {}
static var _by_id: Dictionary = {}

static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JsonUtil.read(DATA_PATH)
		_config = raw if raw is Dictionary else {}
		for k in ["champions", "titles"]:
			if not (_config.get(k) is Array):
				_config[k] = []
		_by_id = {}
		for c in _config.champions:
			_by_id[str(c.id)] = c
	return _config

static func all() -> Array:
	return config().champions

static func ids() -> Array:
	return all().map(func(c): return str(c.id))

static func total() -> int:
	return all().size()

## The champion whose trainer id (data/trainers) is `id`, or {}.
static func get_champion(id: String) -> Dictionary:
	config()
	return _by_id.get(id, {})

static func is_champion(id: String) -> bool:
	return not get_champion(id).is_empty()

static func titles() -> Array:
	return config().titles

# ---------------------------------------------------------------- who you have beaten

static func beaten(d: GameStateData, id: String) -> bool:
	return d.flag("trainer_" + id) == true

static func beaten_count(d: GameStateData) -> int:
	var n := 0
	for id in ids():
		if beaten(d, str(id)):
			n += 1
	return n

## The real date of the first win, or "" (an old save, or the League's date-keeping began after it).
static func first_date(d: GameStateData, id: String) -> String:
	var v: Variant = d.flag(FIRST_PREFIX + id)
	return str(v) if v is String else ""

## Notes the first win of a champion: remembers the date the first time only. Returns true if `id` is a champion.
static func note_first_win(d: GameStateData, id: String) -> bool:
	if not is_champion(id):
		return false
	if first_date(d, id) == "":
		d.set_flag(FIRST_PREFIX + id, Calendar.today_key())
	return true

static func wins(d: GameStateData, id: String) -> int:
	var v: Variant = d.flag(WINS_PREFIX + id)
	return int(v) if v is int or v is float else 0

# ---------------------------------------------------------------- the weekly rematch

static func week_now() -> int:
	return WeeklyChallenge.week_number(Calendar.today_key())

## The week number of the last rematch won, or -1.
static func last_week(d: GameStateData, id: String) -> int:
	var v: Variant = d.flag(WEEK_PREFIX + id)
	return int(v) if v is int or v is float else -1

## True when a rematch can be fought: the champion has been beaten once and no rematch was won this week.
static func rematch_open(d: GameStateData, id: String) -> bool:
	return beaten(d, id) and last_week(d, id) != week_now()

## Records a rematch won: the week is used, the tally goes up.
static func record_rematch(d: GameStateData, id: String) -> void:
	d.set_flag(WEEK_PREFIX + id, week_now())
	d.set_flag(WINS_PREFIX + id, wins(d, id) + 1)

# ---------------------------------------------------------------- the team of the day

## "wet", "rough" or "fair": what the weather of the day means to the champion's team.
static func weather_kind(weather: String) -> String:
	match weather:
		"drizzle", "downpour":
			return "wet"
		"gale", "fog", "frost", "snow":
			return "rough"
	return "fair"

## The species for the four slots on this season and weather: two stayers, the season's and the weather's.
static func team_species(champ: Dictionary, season: String, weather: String) -> Array:
	var out: Array = champ.get("stay", []).duplicate()
	out.append(str(champ.get("season", {}).get(season, champ.get("season", {}).get("spring", ""))))
	out.append(str(champ.get("weather", {}).get(weather_kind(weather), champ.get("weather", {}).get("fair", ""))))
	return out

## The sterling a rematch pays at this par.
static func prize(par: int) -> int:
	return maxi(1, par) * PRIZE_PER_LEVEL

## A trainer definition for the rematch (the shape of data/trainers, built to be fought): the first-fight trainer's
## name, class and sprite, `scaled_floor` of the road so TrainerParty lifts every level to the player's par and evolves
## each creature to suit. `trainer` is the champion's data/trainers entry; `flags` is the save's flags.
static func rematch_def(champ: Dictionary, trainer: Dictionary, season: String, weather: String, flags: Dictionary) -> Dictionary:
	var floor_par := int(trainer.get("scaled_floor", ParLevel.START))
	var party := []
	var species := team_species(champ, season, weather)
	for i in species.size():
		party.append({"species": str(species[i]), "level": floor_par + int(LEVEL_STEPS[mini(i, LEVEL_STEPS.size() - 1)])})
	return {"id": str(trainer.get("id", champ.id)) + "_rematch", "name": str(trainer.get("name", "")), "class": str(trainer.get("class", "")),
		"sprite": str(trainer.get("sprite", "")), "party": party, "ai": "trainer", "money": prize(ParLevel.par(flags)),
		"intro": [], "win": "", "after": "", "scaled_floor": floor_par}

## "Gwen has brought X for the spring and Y for the rain." Names come from `dex`.
static func team_note(champ: Dictionary, season: String, weather: String, dex: Dex) -> String:
	var sp := team_species(champ, season, weather)
	var s: String = dex.get_species(str(sp[2])).name if dex.has(str(sp[2])) else str(sp[2])
	var w: String = dex.get_species(str(sp[3])).name if dex.has(str(sp[3])) else str(sp[3])
	var sky: String = {"wet": "the wet", "rough": "the rough weather", "fair": "the fine weather"}[weather_kind(weather)]
	return "The %s sends out %s, and %s for %s." % [season, s, w, sky]

# ---------------------------------------------------------------- titles and keepsakes

## The titles earned at `count` beaten: [{at, name, ...}] in order.
static func titles_earned(count: int) -> Array:
	return titles().filter(func(t): return count >= int(t.at))

## The title held now (the last one earned), or {}.
static func current_title(d: GameStateData) -> Dictionary:
	var got := titles_earned(beaten_count(d))
	return got[-1] if not got.is_empty() else {}

## The next title to aim for, or {}.
static func next_title(d: GameStateData) -> Dictionary:
	var n := beaten_count(d)
	for t in titles():
		if n < int(t.at):
			return t
	return {}

static func titles_announced(d: GameStateData) -> int:
	var v: Variant = d.flag(TITLES_FLAG)
	return int(v) if v is int or v is float else 0

## Titles earned but not yet announced (a title is announced in the field the next time a champion is met), and
## marks them announced. Old saves with plenty beaten are told of all they have on their next meeting.
static func take_new_titles(d: GameStateData) -> Array:
	var got := titles_earned(beaten_count(d))
	var seen := titles_announced(d)
	if got.size() <= seen:
		return []
	d.set_flag(TITLES_FLAG, got.size())
	return got.slice(seen)

## The id of title `t`'s keepsake on the home shelf (see HomeExtras).
static func keepsake_id(t: Dictionary) -> String:
	return "wl_%d" % int(t.at)

## The shelf entries the titles bring, for HomeExtras to list.
static func keepsakes() -> Array:
	var out := []
	for t in titles():
		var k: Dictionary = t.get("keepsake", {})
		out.append({"id": keepsake_id(t), "town": "", "league": int(t.at), "name": str(k.get("name", "")), "shape": str(k.get("shape", "badge")),
			"col": Color(str(k.get("col", "888888"))), "col2": Color(str(k.get("col2", "cccccc"))), "line": str(k.get("line", ""))})
	return out

# ---------------------------------------------------------------- the league page and the economy

## [{id, zone, route, name, beaten, date, wins, open, reason}] for the page, in road order.
static func rows(d: GameStateData) -> Array:
	var out := []
	for c in all():
		var id := str(c.id)
		var t := StoryData.trainer(id)
		out.append({"id": id, "zone": str(c.zone), "route": str(c.route), "name": str(t.get("name", id)), "beaten": beaten(d, id), "date": first_date(d, id),
			"wins": wins(d, id), "open": rematch_open(d, id), "reason": str(c.get("reason", "")), "title": str(c.get("title", ""))})
	return out

## The Almanac's one line: "3 of 30 champions met, Waymarker".
static func blurb(d: GameStateData) -> String:
	var t := current_title(d)
	return "%d of %d champions met%s" % [beaten_count(d), total(), (", " + str(t.name)) if not t.is_empty() else ""]

## The sterling a week the economy sim books for a player at `par`: every champion whose road is open at that par,
## beaten and rematched, every week, at the prize for that par.
static func weekly_pay(par: int) -> int:
	var n := 0
	for c in all():
		if int(c.get("floor", 0)) <= par:
			n += 1
	return n * prize(par)

## Problems with the data, for the validator: [String].
static func problems(zones: Dictionary, dex: Dex) -> Array:
	var errs := []
	var seen := {}
	var zone_taken := {}
	for c in all():
		var id := str(c.get("id", ""))
		var tag := "route champion '%s': " % id
		if id == "" or seen.has(id):
			errs.append(tag + "missing or duplicate id")
		seen[id] = true
		var zid := str(c.get("zone", ""))
		if zone_taken.has(zid):
			errs.append(tag + "a second champion for the road '%s'" % zid)
		zone_taken[zid] = true
		var z: ZoneData = zones.get(zid)
		if z == null:
			errs.append(tag + "zone '%s' is not a zone" % zid)
		else:
			var npc: Variant = null
			for n in z.npcs:
				if str(n.get("trainer", "")) == id:
					npc = n
			if npc == null:
				errs.append(tag + "no npc on '%s' fights as that trainer" % zid)
			elif str(npc.get("champion", "")) != id:
				errs.append(tag + "the npc needs \"champion\": \"%s\"" % id)
			elif not StoryData.scripts_for(zid).has("champ_" + id):
				errs.append(tag + "no script champ_%s in the zone's dialogue" % id)
		if not StoryData.trainer_exists(id):
			errs.append(tag + "no such trainer")
		for k in ["route", "title", "reason"]:
			if str(c.get(k, "")).strip_edges() == "":
				errs.append(tag + "no " + k)
		var stay: Array = c.get("stay", [])
		if stay.size() != 2:
			errs.append(tag + "needs two stayers")
		var every: Array = stay.duplicate()
		for s in SEASONS:
			every.append(str(c.get("season", {}).get(s, "")))
		for w in WEATHER_KINDS:
			every.append(str(c.get("weather", {}).get(w, "")))
		for sp in every:
			if str(sp) == "" or not dex.has(str(sp)):
				errs.append(tag + "'%s' is not a species" % sp)
		if "—" in JSON.stringify(c):
			errs.append(tag + "has an em-dash")
	var last := 0
	for t in titles():
		var tag := "league title at %s: " % t.get("at", "?")
		if int(t.get("at", 0)) <= last or int(t.get("at", 0)) > LEAGUE_SIZE:
			errs.append(tag + "titles must rise and stay within the thirty")
		last = int(t.get("at", 0))
		var k: Variant = t.get("keepsake")
		if str(t.get("name", "")) == "" or not (k is Dictionary) or str(k.get("name", "")) == "" or str(k.get("line", "")) == "":
			errs.append(tag + "needs a name and a keepsake with a name and a line")
		elif str(k.get("shape", "")) not in KEEPSAKE_SHAPES or not str(k.get("col", "")).is_valid_html_color() or not str(k.get("col2", "")).is_valid_html_color():
			errs.append(tag + "keepsake has a shape or colour the shelf cannot draw")
		if "—" in JSON.stringify(t):
			errs.append(tag + "has an em-dash")
	return errs
