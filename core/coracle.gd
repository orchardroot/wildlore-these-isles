class_name Coracle
extends RefCounted
## Coracle racing: a round, woven boat with no keel, so it goes wherever you are careless. Left and Right paddle on
## that side: each stroke drives you forward and turns the boat away from the stroke, so alternate sides to go
## straight and keep paddling one side and you spin like a dropped plate. Confirm braces the paddle and stops the
## spin. Steer through the pairs of buoys down the river; a missed gate costs seconds. Pure logic (no autoloads);
## ui/coracle_screen.gd draws it and {"do": "coracle"} (story/bog_run.gd) pays it out. Venues live in data/coracle.json.
## World units are metres; x runs down the course, y across it.

const PATH := "res://data/coracle.json"
const STROKE_COOLDOWN := 0.30     # seconds between strokes
const STROKE_PUSH := 1.5          # m/s added along the heading
const STROKE_TURN := 1.05         # rad/s of spin added (away from the stroked side)
const DRAG_ALONG := 0.85          # per second
const DRAG_SIDE := 0.55           # a round boat slides sideways
const SPIN_DRAG := 0.9
const CURRENT := 0.35             # the river's own push, m/s down the course
const FLOW_LOW := 0.5             # the river's level changes from run to run: a seeded fraction of CURRENT, low to high
const FLOW_HIGH := 1.2
const MIDSTREAM := 0.9            # the current is stronger in mid-channel than under the banks (1 = the full effect)
const EDDY := 0.3                 # and gusts and slackens along the course
const MISS_PENALTY := 3.0         # seconds per missed gate
const FLAG_PREFIX := "coracle_"
const FLAG_DAY := "coracle_day_"
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

## The river's centre line y at x (a gentle double bend).
static func centre(course: Dictionary, x: float) -> float:
	return float(course.get("mid", 28.0)) + float(course.get("bend", 9.0)) * sin(x / float(course.get("wave", 24.0)))

## The gates down the course: [{x, y, gap}], from the venue's `gates` count and spacing. `easy` widens the gaps.
static func gates(course: Dictionary, easy := false) -> Array:
	var out := []
	var n := int(course.get("gates", 8))
	var first := float(course.get("first", 16.0))
	var step := float(course.get("step", 12.0))
	var gap := float(course.get("gap", 10.0)) * (1.4 if easy else 1.0)
	for i in n:
		var x := first + step * float(i)
		out.append({"x": x, "y": centre(course, x), "gap": gap})
	return out

static func finish_x(course: Dictionary) -> float:
	return float(course.get("first", 16.0)) + float(course.get("step", 12.0)) * float(int(course.get("gates", 8))) + 6.0

## `seed_value` 0 is the plain river (the old, even current); any other seed gives that day's river: its level, where
## the eddies are, and a stronger stream down the middle for a boat that holds a good line.
static func fresh(course: Dictionary, seed_value := 0) -> Dictionary:
	var flow := 1.0
	var mid := 0.0
	var eddy := 0.0
	var phase := 0.0
	if seed_value != 0:
		var r := Rng.new(seed_value)
		flow = lerpf(FLOW_LOW, FLOW_HIGH, r.roll())
		mid = MIDSTREAM
		eddy = EDDY
		phase = r.roll() * TAU
	return {"p": Vector2(4.0, centre(course, 4.0)), "v": Vector2.ZERO, "h": 0.0, "spin": 0.0, "cool": 0.0, "t": 0.0,
		"gate": 0, "misses": 0, "hits": 0, "strokes": 0, "done": false, "last": "", "flow": flow, "mid": mid, "eddy": eddy, "phase": phase}

## The river's push at p, m/s down the course.
static func current_at(s: Dictionary, course: Dictionary, p: Vector2) -> float:
	var half := float(course.get("width", 22.0)) * 0.5
	var d := clampf((p.y - centre(course, p.x)) / half, -1.0, 1.0)
	var line := 1.0 + float(s.get("mid", 0.0)) * (0.35 - 0.9 * d * d)
	var gust := 1.0 + float(s.get("eddy", 0.0)) * sin(p.x / 14.0 + float(s.get("phase", 0.0)))
	return CURRENT * float(s.get("flow", 1.0)) * line * gust

## A stroke on `side` ("l" or "r"). Returns false if the paddle is still coming round.
static func paddle(s: Dictionary, side: String) -> bool:
	if bool(s.done) or float(s.cool) > 0.0:
		return false
	s.cool = STROKE_COOLDOWN
	s.strokes = int(s.strokes) + 1
	s.last = side
	var fwd := Vector2.from_angle(float(s.h))
	s.v = Vector2(s.v) + fwd * STROKE_PUSH
	# a left stroke turns the boat to the right (clockwise, +h as y points down the page), and the other way round
	s.spin = float(s.spin) + (STROKE_TURN if side == "l" else -STROKE_TURN)
	return true

## Braces the paddle against the water: kills most of the spin.
static func brace(s: Dictionary) -> void:
	s.spin = float(s.spin) * 0.25
	s.v = Vector2(s.v) * 0.9

## Advances by dt. Returns events: "gate" (cleared), "miss", "bump" (hit a bank), "finish".
static func step(s: Dictionary, course: Dictionary, gate_list: Array, dt: float, easy := false) -> Array:
	var ev := []
	if bool(s.done):
		return ev
	s.t = float(s.t) + dt
	s.cool = maxf(0.0, float(s.cool) - dt)
	var sp_drag := SPIN_DRAG * (1.8 if easy else 1.0)
	s.spin = float(s.spin) * maxf(0.0, 1.0 - sp_drag * dt)
	s.h = float(s.h) + float(s.spin) * dt
	# drag split along and across the boat
	var fwd := Vector2.from_angle(float(s.h))
	var side := Vector2(-fwd.y, fwd.x)
	var v: Vector2 = s.v
	var along := v.dot(fwd) * maxf(0.0, 1.0 - DRAG_ALONG * dt)
	var across := v.dot(side) * maxf(0.0, 1.0 - DRAG_SIDE * dt)
	s.v = fwd * along + side * across
	var p: Vector2 = s.p + (Vector2(s.v) + Vector2(current_at(s, course, s.p), 0.0)) * dt
	# banks
	var half := float(course.get("width", 22.0)) * 0.5
	var cy := centre(course, p.x)
	if absf(p.y - cy) > half:
		p.y = cy + signf(p.y - cy) * half
		var vv: Vector2 = s.v
		vv.y *= -0.3
		vv *= 0.6
		s.v = vv
		s.spin = float(s.spin) * 0.5
		ev.append("bump")
	if p.x < 0.0:
		p.x = 0.0
		s.v = Vector2(maxf(0.0, s.v.x), s.v.y)
	s.p = p
	var gi := int(s.gate)
	if gi < gate_list.size() and p.x >= float(gate_list[gi].x):
		var g: Dictionary = gate_list[gi]
		if absf(p.y - float(g.y)) <= float(g.gap) * 0.5:
			s.hits = int(s.hits) + 1
			ev.append("gate")
		else:
			s.misses = int(s.misses) + 1
			ev.append("miss")
		s.gate = gi + 1
	if p.x >= finish_x(course):
		s.done = true
		ev.append("finish")
	return ev

## Elapsed plus penalties: the time that counts.
static func score(s: Dictionary) -> float:
	return float(s.t) + MISS_PENALTY * float(s.misses)

static func local_time(rival: Dictionary, rng: Rng) -> float:
	return float(rival.get("time", 40.0)) + (rng.roll() - 0.5) * 2.0 * float(rival.get("spread", 3.0))

## A simple helmsman for tests and balancing: alternates strokes, and every so often corrects towards the next gate
## by stroking the "wrong" side. `skill` 0..1 is how often it picks the right correction (1 = always).
static func auto_paddle(course: Dictionary, skill: float, rng: Rng, spam_one_side := false) -> Dictionary:
	var s := fresh(course)
	var gl := gates(course)
	var side := "l"
	var guard := 0
	while not bool(s.done) and guard < 6000:
		guard += 1
		if float(s.cool) <= 0.0:
			if spam_one_side:
				paddle(s, "l")
			else:
				var gi := mini(int(s.gate), gl.size() - 1)
				var target := float(gl[gi].y) if int(s.gate) < gl.size() else centre(course, float(s.p.x))
				var heading_err := wrapf(float(s.h), -PI, PI)
				var want := clampf((target - float(s.p.y)) * 0.08, -0.5, 0.5)
				# y grows with +h, so to head to larger y we need h > 0 (more left strokes)
				if rng.roll() > skill:
					side = "r" if side == "l" else "l"
				elif heading_err < want - 0.05:
					side = "l"
				elif heading_err > want + 0.05:
					side = "r"
				else:
					side = "r" if side == "l" else "l"
				paddle(s, side)
		step(s, course, gl, 0.05)
	return s

## ---- rewards

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

static func best(data: GameStateData) -> int:
	return TrainerStats.get_count(data, "coracle_best_tenths")

static func finish(data: GameStateData, venue_id: String, my_time: float, won: bool) -> Dictionary:
	var tenths := int(round(my_time * 10.0))
	var old := best(data)
	var record := old == 0 or tenths < old
	if record:
		data.stats["coracle_best_tenths"] = tenths
	TrainerStats.add(data, "coracle_races")
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
