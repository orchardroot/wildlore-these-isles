class_name CheeseRoll
extends RefCounted
## Cheese rolling (Cooper's Hill, Brockworth, Gloucestershire; the Spring Bank Holiday): a Double Gloucester is set
## rolling and everyone throws themselves down a hill that is far steeper than it looks from the top. First to the
## bottom wins the cheese. Here: steer left and right down a hill of tussocks and rabbit holes, hold Run to dig your
## heels in, and chase the cheese. A trip costs a tumble, never the race. Pure rules with a seeded Rng (no autoload
## names); ui/cheese_screen.gd draws it and the story command {"do": "cheese"} (story/party_run.gd) pays it out.
## Distances are in "yards" down the slope; speeds in yards a second.

const LENGTH := 230.0
const MAX_V := 23.0            # a runner's top speed, yards a second
const BRACE_V := 11.0          # top speed while digging your heels in
const ACCEL := 5.5
const STEER_V := 2.0           # sideways, in lanes a second (the hill is 2 lanes wide, -1 to 1)
const SEE := 70.0              # how far ahead the runner can see the slope
const HEATS := 3
const POINTS := [100, 75, 55, 40]   # by place
const CATCH_BONUS := 25
const TUMBLE_COST := 10
const CHEESE_HEAD := 16.0
const FLAG_PREFIX := "cheese_"      # cheese_won = true once a heat has been won
const FLAG_DAY := "cheese_day"
const DAILY_PURSE := 3
const RIVAL_NAMES := ["Gareth", "Big Dave", "Priya", "Marcus"]

var rng: Rng
var easy := false
var obstacles: Array = []      # {y, x, kind: "tussock" | "burrow" | "puddle", r}
var stalls: Array = []         # yards where the cheese hits a bump and loses a moment
var camber_phase := 0.0
var t := 0.0
var y := 0.0
var x := 0.0
var vx := 0.0
var v := 3.0
var tumble := 0.0              # seconds left tumbling
var tumbles := 0
var trip_kind := ""            # what you last hit
var brace := false
var caught := false
var scraped := 0.0             # seconds spent grinding along the crowd barrier
var cheese := {"y": CHEESE_HEAD, "x": 0.0, "v": 4.0, "stall": 0.0, "spin": 0.0}
var rivals: Array = []         # {name, y, x, v, top, stall, lane, finish}
var done := false
var finish_t := 0.0
var place := 0
var events: Array = []         # one-shot things for the screen to react to: "trip:<kind>", "catch", "scrape", "stall", "rival_trip:<name>"

func _init(seed_value := 1, easier := false) -> void:
	rng = Rng.new(seed_value)
	easy = easier
	camber_phase = rng.roll() * TAU
	var gap := 17.0 if easy else 13.0
	var yy := 30.0
	var lane := 0.0
	while yy < LENGTH - 14.0:
		lane = clampf(lane + rng.roll_range(-0.9, 0.9), -0.8, 0.8)
		obstacles.append(_obstacle(yy, lane))
		if rng.roll() < (0.25 if easy else 0.4):
			var other := lane + (0.95 if lane < 0.0 else -0.95) + rng.roll_range(-0.1, 0.1)
			obstacles.append(_obstacle(yy + rng.roll_range(-1.5, 1.5), other))
		yy += gap + rng.roll_range(-2.5, 2.5)
	for k in 3:
		stalls.append(rng.roll_range(60.0 + 50.0 * k, 90.0 + 50.0 * k))
	for i in 3:
		rivals.append({"name": RIVAL_NAMES[(seed_value + i) % RIVAL_NAMES.size()], "y": 0.0, "x": [-0.6, 0.05, 0.6][i], "v": 3.0, "top": MAX_V * (0.80 if easy else 0.88) + rng.roll() * MAX_V * 0.1, "stall": 0.0, "lane": [-0.6, 0.05, 0.6][i], "finish": -1.0, "trips": [rng.roll_range(40.0, 110.0), rng.roll_range(120.0, 200.0)]})

func _obstacle(at: float, lane: float) -> Dictionary:
	var k := rng.roll()
	var kind := "tussock" if k < 0.5 else ("burrow" if k < 0.8 else "puddle")
	var r := 0.17 if kind == "puddle" else (0.12 if easy else 0.15)
	return {"y": at, "x": clampf(lane, -0.85, 0.85), "kind": kind, "r": r}

## The sideways push of the camber at a point on the hill (lanes a second).
func camber(at: float) -> float:
	return 0.28 * sin(at * 0.05 + camber_phase) * (0.5 if easy else 1.0)

## Advances the race by dt seconds with steer in -1..1 and brace (hold Run).
func step(dt: float, steer: float, brace_on: bool) -> void:
	if done:
		return
	t += dt
	brace = brace_on
	var top := BRACE_V if brace else MAX_V
	if tumble > 0.0:
		tumble -= dt
		v = move_toward(v, 4.0, 14.0 * dt)
		vx = move_toward(vx, 0.0, 3.0 * dt)
	else:
		v = move_toward(v, top, (ACCEL if v < top else 9.0) * dt)
		var authority := STEER_V * (1.35 if brace else 1.0) * (1.0 - 0.3 * clampf(v / MAX_V, 0.0, 1.0))
		vx = move_toward(vx, steer * authority + camber(y), 9.0 * dt)
	y += v * dt
	x += vx * dt
	if absf(x) > 0.97:
		x = clampf(x, -0.97, 0.97)
		vx = 0.0
		v = maxf(v - 8.0 * dt, 3.0)
		if scraped == 0.0:
			events.append("scrape")
		scraped += dt
	else:
		scraped = 0.0
	if tumble <= 0.0:
		for o in obstacles:
			if absf(float(o.y) - y) < 1.4 and absf(float(o.x) - x) < float(o.r) + 0.07:
				_hit(o)
				break
	_cheese(dt)
	_rivals(dt)
	if y >= LENGTH:
		_finish()

func _hit(o: Dictionary) -> void:
	trip_kind = str(o.kind)
	if trip_kind == "puddle":
		v = maxf(v * 0.6, 5.0)
		events.append("trip:puddle")
		return
	tumble = 0.7 if easy else 1.2
	tumbles += 1
	v *= 0.4
	o.y = -50.0    # a tussock only trips you once
	events.append("trip:" + trip_kind)

func _cheese(dt: float) -> void:
	var c := cheese
	c.spin = float(c.spin) + dt * float(c.v) * 0.35
	if float(c.stall) > 0.0:
		c.stall = float(c.stall) - dt
		c.v = move_toward(float(c.v), 4.0, 30.0 * dt)
	else:
		c.v = move_toward(float(c.v), MAX_V * 1.04, 6.5 * dt)
		for i in stalls.size():
			if float(c.y) >= float(stalls[i]) and float(c.y) - float(c.v) * dt < float(stalls[i]):
				c.stall = 0.9 if easy else 0.7
				stalls[i] = -1.0
				events.append("stall")
	c.y = float(c.y) + float(c.v) * dt
	c.x = 0.55 * sin(float(c.y) * 0.055 + camber_phase * 2.0)
	if not caught and absf(float(c.y) - y) < (3.2 if easy else 2.4) and absf(float(c.x) - x) < (0.32 if easy else 0.24):
		caught = true
		events.append("catch")

func _rivals(dt: float) -> void:
	for r in rivals:
		if float(r.finish) >= 0.0:
			continue
		if float(r.stall) > 0.0:
			r.stall = float(r.stall) - dt
			r.v = move_toward(float(r.v), 3.0, 14.0 * dt)
		else:
			r.v = move_toward(float(r.v), float(r.top), ACCEL * dt)
			for k in r.trips.size():
				if float(r.y) >= float(r.trips[k]) and float(r.trips[k]) > 0.0:
					r.trips[k] = -1.0
					r.stall = 1.0 if easy else 0.8
					events.append("rival_trip:" + str(r.name))
		r.y = float(r.y) + float(r.v) * dt
		r.x = float(r.lane) + 0.12 * sin(float(r.y) * 0.1 + float(r.lane) * 7.0)
		if float(r.y) >= LENGTH:
			r.finish = t

func _finish() -> void:
	done = true
	finish_t = t
	place = 1
	for r in rivals:
		if float(r.finish) >= 0.0 and float(r.finish) < t:
			place += 1
	events.append("finish")

## Points for this run: place, the cheese, and the trips.
func score() -> int:
	return points_for(place, caught, tumbles)

static func points_for(p: int, got_cheese: bool, trips: int) -> int:
	var base: int = POINTS[clampi(p - 1, 0, POINTS.size() - 1)]
	return maxi(0, base + (CATCH_BONUS if got_cheese else 0) - TUMBLE_COST * trips)

## A line about how that went, wry about the injuries.
func verdict() -> String:
	var parts: Array = []
	match place:
		1: parts.append("First to the bottom. The cheese is yours, and so, briefly, is the hill.")
		2: parts.append("Second. Close enough to smell the Double Gloucester.")
		3: parts.append("Third, and still in one piece, which at Cooper's Hill is an achievement.")
		_: parts.append("Last down, but you finished, which beats the stretcher.")
	if tumbles == 0:
		parts.append("Not one tumble. Suspiciously tidy.")
	elif tumbles >= 3:
		parts.append("%d tumbles. The St John Ambulance crew have your name and a plaster." % tumbles)
	if caught:
		parts.append("You laid hands on the cheese, which almost nobody does.")
	return " ".join(parts)

static func easier_text() -> String:
	return "Easier cheese rolling: a gentler slope, fewer holes, shorter tumbles and a more forgiving catch."

# ---- rewards

static func won(data: GameStateData) -> bool:
	return data.flag(FLAG_PREFIX + "won") == true

## Records a finished evening (best heat score and whether a heat was won). Returns {first, money, record}.
static func finish_evening(data: GameStateData, best_score: int, won_heat: bool) -> Dictionary:
	var record := best_score > TrainerStats.get_count(data, "cheese_best")
	if record:
		data.stats["cheese_best"] = best_score
	if not won_heat:
		return {"first": false, "money": 0, "record": record}
	TrainerStats.add(data, "cheese_wins")
	if not won(data):
		data.set_flag(FLAG_PREFIX + "won", true)
		return {"first": true, "money": 10, "record": record}
	if DailyKey.done_today(data, FLAG_DAY):
		return {"first": false, "money": 0, "record": record}
	data.set_flag(FLAG_DAY, DailyKey.stamp(data))
	return {"first": false, "money": DAILY_PURSE, "record": record}
