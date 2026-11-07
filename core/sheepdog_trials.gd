class_name SheepdogTrials
extends RefCounted
## Sheepdog trials: you steer your lead creature round a small flock, through the gate or gates, into the pen, against a
## clock. Top-down and simple: each sheep drifts away from the dog (further if it is dashing, much less if it is lying
## down), clings loosely to the others and grazes a little. The field is FIELD units across; the pen is on the left,
## a fence with a gap (a gate) sits across the field for each gate in the venue. Pure logic with a seeded Rng (no
## autoload names); ui/sheepdog_screen.gd draws it and the story command {"do": "sheepdog"} (story/trials_run.gd)
## pays it out. Venues and locals live in data/sheepdog_trials.json.

const PATH := "res://data/sheepdog_trials.json"
const FIELD := Vector2(96.0, 40.0)
const PEN := Rect2(3.0, 11.0, 15.0, 18.0)       # the pen's outer fence; its open side faces the field (right)
const WALL := 0.8                               # fence thickness
const FLIGHT := 13.0                            # how close the dog can get before a sheep moves off
const WALK := 20.0                              # dog speeds, units per second
const DASH := 31.0
const FLEE := 15.0
const MAX_SPEED := 7.5
const FLAG_PREFIX := "sheepdog_"                # sheepdog_<venue> = true once the local has been beaten
const FLAG_DAY := "sheepdog_day_"
const DAILY_PURSE := 3
const PIECE_ID := "sheepdog_trials"

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"venues": {}}
	return _cfg

static func venues() -> Array:
	return cfg().venues.keys()

static func venue(id: String) -> Dictionary:
	return cfg().venues.get(id, {})

## The fences as thin rectangles: one per gate side, and three sides of the pen.
static func walls(v: Dictionary, easy := false) -> Array:
	var out: Array = []
	for g in v.get("gates", []):
		var w := float(g.w) + (3.0 if easy else 0.0)
		var top := float(g.y) - w * 0.5
		var bot := float(g.y) + w * 0.5
		out.append(Rect2(float(g.x) - WALL * 0.5, 0.0, WALL, top))
		out.append(Rect2(float(g.x) - WALL * 0.5, bot, WALL, FIELD.y - bot))
	out.append(Rect2(PEN.position.x, PEN.position.y - WALL * 0.5, PEN.size.x, WALL))
	out.append(Rect2(PEN.position.x, PEN.end.y - WALL * 0.5, PEN.size.x, WALL))
	out.append(Rect2(PEN.position.x - WALL * 0.5, PEN.position.y, WALL, PEN.size.y))
	return out

## A fresh run. `easy` widens the gates, gives longer, and makes the sheep less jumpy.
static func start(v: Dictionary, easy: bool, rng: Rng) -> Dictionary:
	var sheep: Array = []
	var n := int(v.get("sheep", 7))
	var gates: Array = v.get("gates", [])
	var gx := float(gates[0].x) if not gates.is_empty() else 40.0
	var x0 := minf(gx + 14.0, FIELD.x - 22.0)   # the flock starts beyond the first gate, in the open
	for i in n:
		sheep.append({"p": Vector2(x0 + rng.roll() * 14.0, 8.0 + rng.roll() * 24.0), "v": Vector2.ZERO, "penned": false, "through": 0, "scare": 0.0})
	var limit := float(v.get("limit", 150))
	return {"sheep": sheep, "dog": Vector2(FIELD.x - 4.0, 20.0), "lying": false, "running": false, "t": 0.0,
		"limit": limit * (1.35 if easy else 1.0), "penned": 0, "through": 0, "easy": easy, "rng": rng,
		"walls": walls(v, easy), "gates": gates, "done": false, "events": []}

static func blocked(walls_: Array, p: Vector2, r := 0.5) -> bool:
	if p.x < r or p.y < r or p.x > FIELD.x - r or p.y > FIELD.y - r:
		return true
	for w in walls_:
		if (w as Rect2).grow(r).has_point(p):
			return true
	return false

static func _move(walls_: Array, p: Vector2, d: Vector2, r: float) -> Vector2:
	var to := p + d
	if not blocked(walls_, to, r):
		return to
	if not blocked(walls_, Vector2(to.x, p.y), r):
		return Vector2(to.x, p.y)
	if not blocked(walls_, Vector2(p.x, to.y), r):
		return Vector2(p.x, to.y)
	return p

## Advance by dt seconds with the dog steered by `move` (a vector, length up to 1), dashing or not.
## Returns the events of this step: "gate", "pen", "scatter".
static func step(st: Dictionary, dt: float, move: Vector2, dash: bool, lie: bool) -> Array:
	var events: Array = []
	if bool(st.done):
		return events
	var left := dt
	while left > 0.0:
		var h := minf(left, 0.04)
		_sub(st, h, move, dash, lie, events)
		left -= h
	return events

static func _sub(st: Dictionary, dt: float, move: Vector2, dash: bool, lie: bool, events: Array) -> void:
	var rng: Rng = st.rng
	var easy: bool = st.easy
	st.t = float(st.t) + dt
	st.lying = lie
	st.running = dash and not lie and move != Vector2.ZERO
	var speed := 0.0 if lie else (DASH if st.running else WALK)
	if move != Vector2.ZERO:
		st.dog = _move(st.walls, st.dog, move.limit_length(1.0) * speed * dt, 0.7)
	var flight := FLIGHT * (0.45 if lie else (1.4 if st.running else 1.0)) * (0.82 if easy else 1.0)
	var live: Array = []
	var centre := Vector2.ZERO
	for s in st.sheep:
		if not s.penned:
			live.append(s)
			centre += s.p
	if not live.is_empty():
		centre /= float(live.size())
	for s in live:
		var acc := Vector2.ZERO
		var away: Vector2 = s.p - st.dog
		var dist := away.length()
		if dist < flight and dist > 0.001:
			acc += away / dist * (1.0 - dist / flight) * FLEE * (1.0 + 0.8 * float(s.scare))
			s.scare = minf(1.0, float(s.scare) + dt * 1.2 * (1.0 - dist / flight) * (2.0 if st.running else 1.0))
		else:
			s.scare = maxf(0.0, float(s.scare) - dt * 0.5)
		var toward: Vector2 = centre - s.p
		if toward.length() > 5.0:
			acc += toward.normalized() * 1.6
		for o in live:
			if o != s:
				var dd: Vector2 = s.p - o.p
				var l := dd.length()
				if l < 2.4 and l > 0.001:
					acc += dd / l * (2.4 - l) * 4.0
		acc += Vector2(rng.roll() - 0.5, rng.roll() - 0.5) * 3.0   # grazing
		# a sheep that is being walked on sees the open gap and tends to take it (a nudge, so the game stays fair)
		if float(s.scare) > 0.05:
			var lure := Vector2.ZERO
			var gj := 0
			for g in st.gates:
				var gxx := float(g.x)
				if int(s.through) <= gj and s.p.x > gxx and s.p.x - gxx < 18.0:
					lure = Vector2(gxx - 2.0, float(g.y))
				gj += 1
			if lure == Vector2.ZERO and int(s.through) >= st.gates.size() and s.p.x > PEN.end.x and s.p.x < PEN.end.x + 20.0:
				lure = Vector2(PEN.end.x - 3.0, PEN.get_center().y)
			if lure != Vector2.ZERO:
				acc += (lure - s.p).normalized() * (4.0 if st.easy else 2.6)
		for w in st.walls:   # ...and from the fences, so nobody sticks to one
			var wr: Rect2 = w
			var nearest := Vector2(clampf(s.p.x, wr.position.x, wr.end.x), clampf(s.p.y, wr.position.y, wr.end.y))
			var off: Vector2 = s.p - nearest
			var od := off.length()
			if od < 3.0 and od > 0.001:
				acc += off / od * (3.0 - od) * 3.0
		acc.y += (FIELD.y * 0.5 - s.p.y) * 0.3   # the middle of the field looks safer than the edges
		# they shy from the edge of the field, so nobody gets pinned to the wall
		acc += Vector2(clampf(5.0 - s.p.x, 0.0, 5.0) - clampf(s.p.x - (FIELD.x - 5.0), 0.0, 5.0), clampf(4.0 - s.p.y, 0.0, 4.0) - clampf(s.p.y - (FIELD.y - 4.0), 0.0, 4.0)) * 2.5
		s.v = (s.v + acc * dt) * exp(-2.4 * dt)
		s.v = (s.v as Vector2).limit_length(MAX_SPEED)
		var before: Vector2 = s.p
		s.p = _move(st.walls, s.p, s.v * dt, 0.6)
		if (s.p - before).length() < (s.v * dt).length() * 0.5:
			s.v *= 0.4
		# the gates: a sheep that crosses a fence line (through the gap, since the fences block elsewhere) is through
		var gi := 0
		for g in st.gates:
			var gx := float(g.x)
			if (before.x > gx) != (s.p.x > gx) and s.p.x < before.x and int(s.through) <= gi:
				s.through = gi + 1
				st.through = int(st.through) + 1
				events.append("gate")
			gi += 1
		if float(s.scare) > 0.9 and rng.roll() < dt * 0.6:
			events.append("scatter")
		if PEN.grow(-1.4).has_point(s.p):
			s.penned = true
			s.v = Vector2.ZERO
			st.penned = int(st.penned) + 1
			events.append("pen")
	if int(st.penned) >= st.sheep.size() or float(st.t) >= float(st.limit):
		st.done = true

## Points for the clock: whole sheep first, then the seconds left as a fraction of one.
static func score(st: Dictionary) -> float:
	var left := maxf(0.0, float(st.limit) - float(st.t)) / float(st.limit)
	return float(st.penned) + (left * 0.99 if int(st.penned) >= st.sheep.size() else 0.0)

static func local_score(rival: Dictionary, rng: Rng) -> float:
	var n := float(rival.get("penned", 5.0)) + (rng.roll() - 0.5) * 2.0 * float(rival.get("spread", 1.0))
	return float(clampi(roundi(n), 0, 7)) + rng.roll() * 0.5

static func advice(st: Dictionary) -> String:
	var left: int = st.sheep.size() - int(st.penned)
	if left == 0:
		return "The lot, penned, with %d seconds to spare. Lovely." % int(float(st.limit) - float(st.t))
	if int(st.through) == 0:
		return "Nobody went through the gate. Get behind the flock and walk them at it, slow."
	if int(st.penned) == 0:
		return "Through the gate, but nobody made the pen. Walk them left, steady, and lie down if they bolt."
	return "%d still out. Dashing sends them off in all directions; walk, then lie down to settle them." % left

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

## Records a finished run. Returns {first, money (sterling), line}.
static func finish(data: GameStateData, venue_id: String, penned: int, won: bool) -> Dictionary:
	TrainerStats.add(data, "sheep_penned", penned)
	if not won:
		return {"first": false, "money": 0, "line": ""}
	var v := venue(venue_id)
	if not beaten(data, venue_id):
		data.set_flag(FLAG_PREFIX + venue_id, true)
		return {"first": true, "money": int(v.get("prize", 0)), "line": str(v.get("rival", {}).get("beaten", ""))}
	if DailyKey.done_today(data, FLAG_DAY + venue_id):
		return {"first": false, "money": 0, "line": ""}
	data.set_flag(FLAG_DAY + venue_id, DailyKey.stamp(data))
	return {"first": false, "money": DAILY_PURSE, "line": ""}
