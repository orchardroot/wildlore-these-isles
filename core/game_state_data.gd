class_name GameStateData
extends RefCounted
## Everything a save file holds. Pure data plus small helpers, so it can be tested without autoloads.

const PARTY_MAX := 6

var player_name := "Sam"
var rival_name := "Kit"
var party: Array = []
var ark: Array = []
var bag: Dictionary = {}
var money := 500          # sterling (see Wallet)
var euros := 0            # the Republic of Ireland's money (see Wallet)
var purses := {}          # the overseas territories' own money: {currency code: whole units}, only non-zero ones
var markets: Dictionary = Markets.fresh()  # shares, Doggerel and the days the markets noticed things (see Markets)
var flags: Dictionary = {}
var trumps: Dictionary = {}  # Trumps cards {cards: {species: n}, wins, losses, streak}; see Trumps (wave 47)
var zone_id := "macclesfield"
var pos := Vector2i(0, 0)
var facing := "down"
var seen: Dictionary = {}
var caught: Dictionary = {}
var badges: Array = []
var play_seconds := 0.0
var clock_minutes := 480
var tz_zone := "uk"  # runtime only (not saved): the Timezones zone you stand in; interiors keep the street's
var day_count := 0  # in-game midnights passed; drives once-a-day things
var last_sanctuary: Dictionary = {"zone": "macclesfield", "pos": [-1, -1]}  # (-1, -1) = the zone's spawn
var rng_seed := 0
var weather := ""          # the outdoor weather right now ("" = roll it at the next outdoor zone)
var weather_region := ""   # the region it was rolled for
var weather_until := 0     # world minute (see world_minutes) it lasts until
var stats: Dictionary = TrainerStats.fresh()  # lifetime tallies for the Stats page (see TrainerStats)
var look: Dictionary = {}  # the player's look (see Looks); {} on saves from before 4.6, which keep their player_sprite flag
## While a County Show or the Open Moot is on, `party` holds exhibition copies (TournamentRun) and this holds the
## real team; a save written then (never saved itself) writes the real team, so it can never keep the copies.
var real_party: Array = []

const WEATHER_MIN := 120   # in-game minutes a spell of weather lasts (a game minute is a real second)
const WEATHER_MAX := 240

## Where a fresh journey whites out to: the tile just outside Macclesfield's Sanctuary door.
static func default_sanctuary() -> Dictionary:
	var z := ZoneData.load_id("macclesfield")
	for w in z.warps:
		if str(w.get("to", "")) == "macc_sanctuary":
			return {"zone": "macclesfield", "pos": [int(w.x), int(w.y) + 1]}
	return {"zone": "macclesfield", "pos": [-1, -1]}

func add_creature(c: Creature) -> String:
	mark_seen(c.species.id)
	mark_caught(c.species.id)
	Sexes.record_seen(self, c)
	if party.size() < PARTY_MAX:
		party.append(c)
		return "party"
	ark.append(c)
	return "ark"

## Party -> Ark. Returns "" on success or why not.
func deposit(i: int) -> String:
	if i < 0 or i >= party.size():
		return "Nobody there."
	if party.size() <= 1:
		return "You can't travel without a single companion."
	var able := party.filter(func(c): return not c.is_fainted())
	if not party[i].is_fainted() and able.size() <= 1:
		return "That's your last creature fit to battle. Keep them with you."
	ark.append(party[i])
	party.remove_at(i)
	return ""

## Ark -> party. Returns "" on success or why not.
func withdraw(j: int) -> String:
	if j < 0 or j >= ark.size():
		return "Nobody there."
	if party.size() >= PARTY_MAX:
		return "Your team is full. Deposit someone first."
	party.append(ark[j])
	ark.remove_at(j)
	return ""

## Caught with a full team: `c` takes team slot `slot` and whoever was there goes to the Ark. With room on the team
## it just joins. Returns "party" like add_creature.
func add_creature_swapping(c: Creature, slot: int) -> String:
	if party.size() < PARTY_MAX or slot < 0 or slot >= party.size():
		return add_creature(c)
	mark_seen(c.species.id)
	mark_caught(c.species.id)
	Sexes.record_seen(self, c)
	ark.append(party[slot])
	party[slot] = c
	return "party"

## Direct swap: team slot `pi` trades places with Ark entry `aj`. Returns "" on success or why not.
func swap_with_ark(pi: int, aj: int) -> String:
	if pi < 0 or pi >= party.size() or aj < 0 or aj >= ark.size():
		return "Nobody there."
	if not party[pi].is_fainted() and ark[aj].is_fainted():
		var able := party.filter(func(c): return not c.is_fainted())
		if able.size() <= 1:
			return "That's your last creature fit to battle. Keep them with you."
	var t: Creature = party[pi]
	party[pi] = ark[aj]
	ark[aj] = t
	return ""

## Lets a creature go for good (the Ark screen asks first). Returns "" on success or why not.
func release(from_party: bool, i: int) -> String:
	var rule := ArkLogic.release_rule(self, from_party, i)
	if not rule.ok:
		return rule.why
	var c: Creature = party[i] if from_party else ark[i]
	if c.held != "":  # its charm stays with you
		bag[c.held] = int(bag.get(c.held, 0)) + 1
	if from_party:
		party.remove_at(i)
	else:
		ark.remove_at(i)
	return ""

func mark_seen(id: String) -> void:
	seen[id] = true

func mark_caught(id: String) -> void:
	seen[id] = true
	caught[id] = true

func heal_party() -> void:
	for c in party:
		c.hp = c.max_hp()
		c.status = ""
		c.status_turns = 0
		for m in c.moves:
			m.pp = m.max_pp

func first_able() -> Creature:
	for c in party:
		if not c.is_fainted():
			return c
	return null

func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value

func flag(key: String) -> Variant:
	return flags.get(key)

## Minutes since the journey's first midnight: the clock plus whole days.
func world_minutes() -> int:
	return day_count * GameClock.DAY + clock_minutes

func weather_expired() -> bool:
	return weather == "" or world_minutes() >= weather_until

## The weather for a zone. The outdoor weather is kept zone to zone until it runs out or the region changes,
## then re-rolled from `table`. Interiors inherit it (never re-roll). A zone whose table never has the
## region's weather (a cave, a sheltered glen) shows its own pick without changing the region's.
func weather_for(region: String, table: Dictionary, interior: bool, rng: Rng) -> String:
	if interior:
		return weather if weather != "" else "clear"
	if weather_expired() or region != weather_region:
		weather = Weather.pick(table, rng)
		weather_region = region
		weather_until = world_minutes() + rng.roll_int(WEATHER_MIN, WEATHER_MAX)
	if table.is_empty():
		return "clear"
	if float(table.get(weather, 0)) <= 0.0:
		return Weather.pick(table, rng)
	return weather

func to_dict() -> Dictionary:
	return {
		"player_name": player_name, "rival_name": rival_name,
		"party": (real_party if not real_party.is_empty() else party).map(func(c): return c.to_dict()),
		"ark": ark.map(func(c): return c.to_dict()),
		"bag": bag.duplicate(), "money": money, "flags": flags.duplicate(true),
		"zone_id": zone_id, "pos": [pos.x, pos.y], "facing": facing,
		"seen": seen.duplicate(), "caught": caught.duplicate(), "badges": badges.duplicate(),
		"play_seconds": play_seconds, "clock_minutes": clock_minutes, "day_count": day_count,
		"last_sanctuary": last_sanctuary.duplicate(true), "rng_seed": rng_seed,
		"weather": weather, "weather_region": weather_region, "weather_until": weather_until,
		"stats": stats.duplicate(), "euros": euros, "purses": purses.duplicate(), "markets": markets.duplicate(true),
		"look": look.duplicate(true), "trumps": trumps.duplicate(true),
	}

static func from_dict(d: Dictionary, dex: Dex) -> GameStateData:
	var s := GameStateData.new()
	s.player_name = d.get("player_name", "Sam")
	s.rival_name = d.get("rival_name", "Kit")
	for cd in d.get("party", []):
		s.party.append(Creature.from_dict(cd, dex))
	for cd in d.get("ark", []):
		s.ark.append(Creature.from_dict(cd, dex))
	var bag_in: Dictionary = d.get("bag", {})
	for k in bag_in:
		s.bag[k] = int(bag_in[k])
	s.money = int(d.get("money", 0))
	s.flags = d.get("flags", {}).duplicate(true)
	for k in s.flags:
		if typeof(s.flags[k]) == TYPE_FLOAT and s.flags[k] == floorf(s.flags[k]):
			s.flags[k] = int(s.flags[k])
	s.zone_id = d.get("zone_id", "macclesfield")
	var p: Array = d.get("pos", [0, 0])
	s.pos = Vector2i(int(p[0]), int(p[1]))
	s.facing = d.get("facing", "down")
	s.seen = d.get("seen", {}).duplicate()
	s.caught = d.get("caught", {}).duplicate()
	s.badges = d.get("badges", []).duplicate()
	s.play_seconds = float(d.get("play_seconds", 0.0))
	s.clock_minutes = int(d.get("clock_minutes", 480))
	s.day_count = int(d.get("day_count", 0))
	var ls: Dictionary = d.get("last_sanctuary", {})
	var lp: Array = ls.get("pos", [-1, -1])
	s.last_sanctuary = {"zone": str(ls.get("zone", "macclesfield")), "pos": [int(lp[0]), int(lp[1])]}
	s.rng_seed = int(d.get("rng_seed", 0))
	s.weather = str(d.get("weather", ""))
	s.weather_region = str(d.get("weather_region", ""))
	s.weather_until = int(d.get("weather_until", 0))
	s.stats = TrainerStats.sanitise(d.get("stats"))
	s.euros = maxi(0, int(d.get("euros", 0)))
	s.purses = Wallet.sanitise_purses(d.get("purses"))
	s.markets = Markets.sanitise(d.get("markets"))
	s.look = Looks.sanitise(d.get("look"))
	s.trumps = d.get("trumps", {}).duplicate(true) if d.get("trumps") is Dictionary else {}
	if not d.has("euros"):
		Wallet.welcome_old_save(s)  # a save from before euros, made in Ireland: a friendly one-off conversion
	return s
