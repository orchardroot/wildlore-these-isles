class_name Snorkel
extends RefCounted
## Bog snorkelling: two lengths of a 60-yard peat trench, flippers only (no arms, no strokes), so all you have is
## the kick. Alternate left and right on the beat: a steady rhythm builds speed, a ragged one stirs up silt that
## clogs the snorkel and burns your breath. Confirm blows the snorkel clear (it costs a beat). Out of breath and you
## swallow some bog and lose a few seconds. Pure logic (no autoloads); ui/snorkel_screen.gd draws it and the story
## command {"do": "snorkel"} (story/bog_run.gd) pays it out. Venues and locals live in data/snorkel.json.

const PATH := "res://data/snorkel.json"
const LENGTH := 60.0              # yards per length (the real trench at Waen Rhydd is 60 yards)
const LENGTHS := 2
const BEAT := 0.62                # seconds between beats
const WINDOW := 0.13              # seconds either side of a beat that is a "good" kick
const WINDOW_EASY := 0.22
const OK_WINDOW := 0.27           # a "fair" kick; anything later is ragged
const GAIN := {"good": 1.5, "ok": 1.05, "ragged": 0.45}
const STREAK_CAP := 6
const SET_LOW := 0.96             # the trench is different every swim: how far a kick carries, low to high
const SET_HIGH := 1.04
const SPRING := 0.07              # cold springs and peat slacks along the trench speed or slow a stretch of it
const FLAG_PREFIX := "snorkel_"   # snorkel_<venue> = true once the local has been beaten
const FLAG_DAY := "snorkel_day_"
const DAILY_PURSE := 3

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"venues": {}}
	return _cfg

static func venue(id: String) -> Dictionary:
	return cfg().venues.get(id, {})

static func venues() -> Array:
	return cfg().venues.keys()

## A fresh swim. x counts yards over both lengths (0 to LENGTH * LENGTHS). `seed_value` 0 is the plain trench; any
## other seed sets that swim's set (how far a kick carries) and where the springs and slacks are.
static func fresh(seed_value := 0) -> Dictionary:
	var carry := 1.0
	var spring := 0.0
	var phase := 0.0
	if seed_value != 0:
		var r := Rng.new(seed_value)
		carry = lerpf(SET_LOW, SET_HIGH, r.roll())
		spring = SPRING
		phase = r.roll() * TAU
	return {"carry": carry, "spring": spring, "phase": phase, "x": 0.0, "t": 0.0, "breath": 1.0, "silt": 0.0, "last": "", "streak": 0, "pause": 0.0, "done": false,
		"swallowed": 0, "kicks": 0, "good": 0, "length": 0, "turn": false}

static func window(easy: bool) -> float:
	return WINDOW_EASY if easy else WINDOW

## How a kick landed: "good", "ok" or "ragged", from how many seconds it was off the beat.
static func grade(err: float, easy: bool) -> String:
	var e := absf(err)
	if e <= window(easy):
		return "good"
	return "ok" if e <= OK_WINDOW * (1.25 if easy else 1.0) else "ragged"

## One kick of the flippers on `side` ("l" or "r"), `err` seconds off the beat. Returns the grade ("" if you cannot
## kick right now: mid-turn, mid-blow or done). Kicking the same flipper twice is always ragged.
static func kick(s: Dictionary, side: String, err: float, easy := false) -> String:
	if bool(s.done) or float(s.pause) > 0.0:
		return ""
	var g := grade(err, easy)
	if side == str(s.last):
		g = "ragged"
	s.last = side
	s.kicks = int(s.kicks) + 1
	if g == "good":
		s.streak = mini(int(s.streak) + 1, STREAK_CAP)
		s.good = int(s.good) + 1
	elif g == "ok":
		s.streak = maxi(0, int(s.streak) - 1)
	else:
		s.streak = 0
		s.silt = minf(1.0, float(s.silt) + 0.14)
	var clog := 1.0 - 0.6 * float(s.silt)   # a clogged snorkel means you swim half-blind and short of air
	s.x = float(s.x) + float(GAIN[g]) * (1.0 + 0.05 * float(s.streak)) * clog * carry_at(s)
	s.breath = maxf(0.0, float(s.breath) - (0.012 if g == "good" else 0.03))
	return g

## How far a kick carries just here: the swim's set, and a springs-and-slacks wobble along the trench.
static func carry_at(s: Dictionary) -> float:
	return float(s.get("carry", 1.0)) * (1.0 + float(s.get("spring", 0.0)) * sin(float(s.x) / 9.0 + float(s.get("phase", 0.0))))

## Blow the snorkel clear: it costs about a beat.
static func blow(s: Dictionary) -> bool:
	if bool(s.done) or float(s.pause) > 0.0:
		return false
	s.silt = 0.0
	s.breath = minf(1.0, float(s.breath) + 0.18)
	s.pause = BEAT * 0.8
	return true

## Advances the clock. Returns events for the screen's sounds: "turn", "swallow", "finish".
static func tick(s: Dictionary, dt: float) -> Array:
	var ev := []
	if bool(s.done):
		return ev
	s.t = float(s.t) + dt
	s.pause = maxf(0.0, float(s.pause) - dt)
	s.breath = maxf(0.0, float(s.breath) - dt * (0.016 + 0.05 * float(s.silt)))
	if float(s.breath) <= 0.0:
		s.breath = 0.45
		s.silt = 0.0
		s.pause = 2.2
		s.swallowed = int(s.swallowed) + 1
		ev.append("swallow")
	var full := LENGTH * float(LENGTHS)
	var at_wall := LENGTH * float(int(s.length) + 1)
	if float(s.x) >= full:
		s.x = full
		s.done = true
		ev.append("finish")
	elif float(s.x) >= at_wall:
		s.length = int(s.length) + 1
		s.x = at_wall
		s.pause = maxf(float(s.pause), 1.0)   # the turn
		s.last = ""
		ev.append("turn")
	return ev

## Yards along the trench the swimmer is at on the current length, 0 to LENGTH (the second length runs back).
static func lane_x(s: Dictionary) -> float:
	var in_len := float(s.x) - LENGTH * float(s.length)
	return in_len if int(s.length) % 2 == 0 else LENGTH - in_len

## A local's time for the two lengths: their usual, give or take their spread.
static func local_time(rival: Dictionary, rng: Rng) -> float:
	return float(rival.get("time", 70.0)) + (rng.roll() - 0.5) * 2.0 * float(rival.get("spread", 4.0))

## A tidy m:ss.s for the clock.
static func fmt(t: float) -> String:
	var m := int(t) / 60
	return "%d:%04.1f" % [m, t - float(m) * 60.0]

## Plays a swim with a rhythm of steadiness `steady` (0 to 1: the share of kicks that land on the beat) and returns
## the final state. For tests and for balancing the locals.
static func auto_swim(steady: float, rng: Rng, easy := false, seed_value := 0) -> Dictionary:
	var s := fresh(seed_value)
	var side := "l"
	var guard := 0
	while not bool(s.done) and guard < 4000:
		guard += 1
		var err := 0.0 if rng.roll() < steady else 0.32
		if float(s.pause) > 0.0:
			tick(s, BEAT)
			continue
		if float(s.silt) > 0.5 or float(s.breath) < 0.3:
			blow(s)
		else:
			kick(s, side, err, easy)
			side = "r" if side == "l" else "l"
		tick(s, BEAT)
	return s

## ---- rewards (same shape as Skimming.finish)

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

static func best(data: GameStateData) -> int:
	return TrainerStats.get_count(data, "snorkel_best_tenths")

## Records a finished swim: your time and whether you beat the local. Returns {first, money, line, record}.
static func finish(data: GameStateData, venue_id: String, my_time: float, won: bool) -> Dictionary:
	var tenths := int(round(my_time * 10.0))
	var old := best(data)
	var record := old == 0 or tenths < old
	if record:
		data.stats["snorkel_best_tenths"] = tenths
	TrainerStats.add(data, "snorkel_swims")
	if not won:
		return {"first": false, "money": 0, "line": "", "record": record}
	var v := venue(venue_id)
	if not beaten(data, venue_id):
		data.set_flag(FLAG_PREFIX + venue_id, true)
		return {"first": true, "money": int(v.get("prize", 0)), "line": str(v.get("rival", {}).get("beaten", "")), "record": record}
	if DailyKey.done_today(data, FLAG_DAY + venue_id):
		return {"first": false, "money": 0, "line": "", "record": record}
	data.set_flag(FLAG_DAY + venue_id, DailyKey.stamp(data))
	return {"first": false, "money": DAILY_PURSE, "line": "", "record": record}
