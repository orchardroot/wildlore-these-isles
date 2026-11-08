class_name RoadBowling
extends RefCounted
## Irish road bowling (Cork and Armagh): a 28 ounce iron bowl thrown along a country lane, fewest throws to the finish
## wins. The lane bends, the bowl is thrown with a power and a swing (it curves as it goes), a bowl that leaves the
## tarmac is fetched out of the nettles and put back a few yards, and a LOFT carries the bowl through the air over the
## first half of its flight (so it can cut a corner) at the cost of landing dead. Pure logic with a seeded Rng (no
## autoload names); ui/road_bowling_screen.gd draws it and the story command {"do": "road_bowl"}
## (story/road_bowl_run.gd) pays it out. Lanes and locals live in data/road_bowling.json.

const PATH := "res://data/road_bowling.json"
const STEP := 2.0                  # metres between checks along a throw
const CURL := 18.0                 # sideways metres a full swing gives by the time the bowl lands
const MIN_D := 35.0
const MAX_D := 160.0
const LOFT_AIR := 0.55             # fraction of the throw spent in the air when lofted
const ROLL := 0.22                 # fraction of the throw it runs on after landing
const ROLL_LOFT := 0.08
const FETCH_BACK := 8.0            # metres a fetched bowl is put back from where it left the road
const MAX_THROWS := 16
const FLAG_PREFIX := "roadbowl_"   # roadbowl_<venue> = true once the local has been beaten
const FLAG_DAY := "roadbowl_day_"
const DAILY_PURSE := 3

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

## Where the middle of the road sits sideways (metres, positive = right) at distance s along it.
static func centre(v: Dictionary, s: float) -> float:
	var c := 0.0
	for b in v.get("bends", []):
		var t := clampf((s - float(b.at)) / maxf(1.0, float(b.len)), 0.0, 1.0)
		c += float(b.shift) * t * t * (3.0 - 2.0 * t)
	return c

static func half_width(v: Dictionary, easy := false) -> float:
	return float(v.get("half_width", 5.0)) * (1.35 if easy else 1.0)

## Throwing distance for a power (0 to 1).
static func distance_for(power: float) -> float:
	return MIN_D + (MAX_D - MIN_D) * clampf(power, 0.0, 1.0)

## One throw from (s0, y0). Returns {pts: PackedVector2Array of (s, y) from the start, air_until (s where it lands),
## s1, y1 (where it ends up, back on the road if it left it), off (left the road), off_s, finished, d}.
## `wobble` below 1 steadies the throw (Easier road bowling).
static func throw_bowl(v: Dictionary, s0: float, y0: float, power: float, swing: float, loft: bool, rng: Rng, wobble := 1.0, easy := false) -> Dictionary:
	var d := distance_for(power) * (1.0 + (rng.roll() - 0.5) * 0.08 * wobble)
	var sw := clampf(swing + (rng.roll() - 0.5) * 0.14 * wobble, -1.0, 1.0)
	var roll := d * (ROLL_LOFT if loft else ROLL)
	var total := d + roll
	var hw := half_width(v, easy)
	var length := float(v.get("length", 600))
	var pts := PackedVector2Array()
	pts.append(Vector2(s0, y0))
	var off := false
	var off_s := 0.0
	var finished := false
	var t := STEP
	var last := Vector2(s0, y0)
	while t <= total + 0.001:
		var u := t / d
		var y := y0 + CURL * sw * (u * u if u <= 1.0 else 1.0 + 2.0 * (u - 1.0))
		var s := s0 + t
		var p := Vector2(s, y)
		var in_air := loft and t < d * LOFT_AIR
		if s >= length:
			pts.append(Vector2(length, lerpf(last.y, y, (length - last.x) / maxf(0.001, s - last.x))))
			finished = true
			break
		if not in_air and absf(y - centre(v, s)) > hw:
			off = true
			off_s = s
			pts.append(p)
			break
		pts.append(p)
		last = p
		t += STEP
	var end := pts[pts.size() - 1]
	var s1 := end.x
	var y1 := end.y
	if off:
		s1 = maxf(s0, end.x - FETCH_BACK)
		y1 = centre(v, s1)
	return {"pts": pts, "air_until": s0 + (d * LOFT_AIR if loft else d), "s1": s1, "y1": y1, "off": off, "off_s": off_s, "finished": finished, "d": d, "loft": loft}

## What the local throws: tries a few powers and swings on a steady hand, keeps the one that gets furthest without
## leaving the road, then lets the hand wobble a little.
static func local_throw(v: Dictionary, rival: Dictionary, s0: float, y0: float, rng: Rng) -> Dictionary:
	var base := float(rival.get("power", 0.8))
	var best_pw := base
	var best_sw := 0.0
	var best_score := -1.0
	var probe := Rng.new(1)
	for pw in [base, base * 0.7, base * 0.5, base * 0.3, 0.1]:
		for k in 21:
			var sw := -1.0 + float(k) * 0.1
			var r := throw_bowl(v, s0, y0, pw, sw, false, probe, 0.0)
			var sc := float(r.s1) - s0 + (1000.0 if bool(r.finished) else 0.0) - (40.0 if bool(r.off) else 0.0)
			if sc > best_score:
				best_score = sc
				best_pw = pw
				best_sw = sw
	var sloppy := float(rival.get("sloppy", 0.1))
	var pw2 := clampf(best_pw + (rng.roll() - 0.5) * 0.16, 0.25, 1.0)
	var sw2 := clampf(best_sw + (rng.roll() - 0.5) * 2.0 * sloppy, -1.0, 1.0)
	return throw_bowl(v, s0, y0, pw2, sw2, false, rng)

## The local's whole round: how many throws.
static func local_round(v: Dictionary, rng: Rng) -> int:
	var rival: Dictionary = v.get("rival", {})
	var s := 0.0
	var y := 0.0
	for n in MAX_THROWS:
		var r := local_throw(v, rival, s, y, rng)
		if bool(r.finished):
			return n + 1
		s = float(r.s1)
		y = float(r.y1)
	return MAX_THROWS

## A short line saying what happened, and what to try next.
static func advice(res: Dictionary, finished: bool) -> String:
	if finished:
		return "Over the line."
	if bool(res.off):
		return "Into the nettles. Swing into the bend sooner, or loft it over the corner."
	if bool(res.loft):
		return "Lofted and landed dead. Good for a corner, poor for distance."
	if float(res.d) > 135.0:
		return "A big one."
	return "Safe on the tarmac."

# ---- rewards

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

## Records a finished round. Returns {first, money (sterling), line}.
static func finish(data: GameStateData, venue_id: String, won: bool) -> Dictionary:
	if not won:
		return {"first": false, "money": 0, "line": ""}
	TrainerStats.add(data, "roadbowl_won")
	var v := venue(venue_id)
	if not beaten(data, venue_id):
		data.set_flag(FLAG_PREFIX + venue_id, true)
		return {"first": true, "money": int(v.get("prize", 0)), "line": str(v.get("rival", {}).get("beaten", ""))}
	if DailyKey.done_today(data, FLAG_DAY + venue_id):
		return {"first": false, "money": 0, "line": ""}
	data.set_flag(FLAG_DAY + venue_id, DailyKey.stamp(data))
	return {"first": false, "money": DAILY_PURSE, "line": ""}

static func wobble_scale(easy: bool) -> float:
	return 0.5 if easy else 1.0
