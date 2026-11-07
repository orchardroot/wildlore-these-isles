class_name Poohsticks
extends RefCounted
## Poohsticks: drop a stick into the river on the upstream side of a bridge and see whose comes out the other side
## first. You choose the lane (and a stick) by reading the current: the middle runs fastest, the banks are slow, the
## odd lane has an eddy or a snag of reeds, and the river is a bit different every race. Five races against the local,
## most wins takes the match, with a small stake on the side if you like. Pure logic with a seeded Rng (no autoload
## names); ui/poohsticks_screen.gd draws it and the story command {"do": "poohsticks"} (story/road_bowl_run.gd) pays
## it out. Venues, sticks and locals live in data/poohsticks.json.

const PATH := "res://data/poohsticks.json"
const LANES := 7
const SPAN := 6.0                  # metres of bridge deck the stick has to get under
const RACES := 5
const FLAG_PREFIX := "pooh_"
const FLAG_DAY := "pooh_day_"
const DAILY_PURSE := 2

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"venues": {}, "sticks": []}
	return _cfg

static func venues() -> Array:
	return cfg().venues.keys()

static func venue(id: String) -> Dictionary:
	return cfg().venues.get(id, {})

static func sticks() -> Array:
	return cfg().sticks

static func stick(i: int) -> Dictionary:
	return sticks()[clampi(i, 0, sticks().size() - 1)]

## A river for one race: {speed: Array[float] per lane (m/s, what you can read from the ripples), snag: lane index
## or -1, eddy: lane index or -1}. `bias` leans the fast water toward one bank (-1 to 1).
static func river(v: Dictionary, rng: Rng) -> Dictionary:
	var flow := float(v.get("flow", 0.5)) * rng.roll_range(0.8, 1.25)
	var mid := float(LANES - 1) * 0.5 + float(v.get("bias", 0.0)) * rng.roll_range(0.4, 1.6)
	var speed: Array = []
	for i in LANES:
		var x := (float(i) - mid) / (float(LANES) * 0.5)
		speed.append(flow * (1.3 - 1.0 * x * x) * rng.roll_range(0.9, 1.1))
	var eddy := -1
	if rng.roll() < 0.5:
		eddy = 0 if rng.roll() < 0.5 else LANES - 1
		speed[eddy] = float(speed[eddy]) * 0.25
	var snag := -1
	if rng.roll() < 0.65:
		snag = rng.roll_int(1, LANES - 2)
	return {"speed": speed, "snag": snag, "eddy": eddy}

## How long a stick takes to get through, in seconds: {time, snagged, stall (seconds held up), speed (m/s)}. A little luck rides on every drop.
static func run(r: Dictionary, lane: int, st: Dictionary, rng: Rng) -> Dictionary:
	var l := clampi(lane, 0, LANES - 1)
	var v := maxf(0.05, float(r.speed[l]) * float(st.get("speed", 1.0)) * rng.roll_range(0.93, 1.07))
	var t := SPAN / v
	var caught := false
	var stall := 0.0
	if int(r.snag) == l and rng.roll() < 0.5 * float(st.get("snag", 1.0)):
		caught = true
		stall = rng.roll_range(2.5, 5.0)
		t += stall
	return {"time": t, "snagged": caught, "stall": stall, "speed": v}

## The local's lane: the fastest water as they see it (a better eye sees more clearly), avoiding the reeds.
static func local_lane(r: Dictionary, skill: float, rng: Rng) -> int:
	var best := 0
	var bv := -1.0
	for i in LANES:
		var seen := float(r.speed[i]) * (1.0 + (rng.roll() - 0.5) * (1.0 - skill))
		if i == int(r.snag):
			seen *= 0.6 if rng.roll() < skill else 1.0
		if seen > bv:
			bv = seen
			best = i
	return best

## The lane you'd pick if you read the water perfectly (for tests and the easy-mode marker).
static func best_lane(r: Dictionary) -> int:
	var best := 0
	var bv := -1.0
	for i in LANES:
		var s := float(r.speed[i]) * (0.6 if i == int(r.snag) else 1.0)
		if s > bv:
			bv = s
			best = i
	return best

# ---- rewards

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

## A finished match: wins = races you took (of RACES), won = most wins. Returns {first, money, line}.
static func finish(data: GameStateData, venue_id: String, won: bool) -> Dictionary:
	if not won:
		return {"first": false, "money": 0, "line": ""}
	TrainerStats.add(data, "poohsticks_won")
	var v := venue(venue_id)
	if not beaten(data, venue_id):
		data.set_flag(FLAG_PREFIX + venue_id, true)
		return {"first": true, "money": int(v.get("prize", 0)), "line": str(v.get("rival", {}).get("beaten", ""))}
	if DailyKey.done_today(data, FLAG_DAY + venue_id):
		return {"first": false, "money": 0, "line": ""}
	data.set_flag(FLAG_DAY + venue_id, DailyKey.stamp(data))
	return {"first": false, "money": DAILY_PURSE, "line": ""}
