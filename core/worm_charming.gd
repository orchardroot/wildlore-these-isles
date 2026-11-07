class_name WormCharming
extends RefCounted
## Worm charming (the World Worm Charming Championships at Willaston, Cheshire): a three-by-three plot of earth, a fork
## and a beat. Tap on the beat to thrum the patch under the fork and its neighbours; steady taps build the rhythm and
## coax worms up, a patch gives up its worms and needs a rest, and a sloppy rhythm brings the birds. Shoo a bird before
## it lands or it takes every worm that is up. Pure logic with a seeded Rng (no autoload names); ui/worm_screen.gd draws
## it and the story command {"do": "worms"} (story/trials_run.gd) pays it out. Data: data/worm_charming.json.

const PATH := "res://data/worm_charming.json"
const GRID := 3
const LIFE := 1.5            # seconds a worm stays up before it is counted and put back
const WARN := 1.3            # seconds of warning before a bird lands
const FLAG_PREFIX := "worms_"
const FLAG_DAY := "worms_day_"
const DAILY_PURSE := 3
const PIECE_ID := "worms"

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"venues": {}}
	return _cfg

static func venue(id: String) -> Dictionary:
	return cfg().venues.get(id, {})

static func period() -> float:
	return 60.0 / float(cfg().get("bpm", 96))

static func duration() -> float:
	return float(cfg().get("seconds", 60))

## The timing window (seconds either side of the beat) for a good tap and a perfect one.
static func windows(easy: bool) -> Vector2:
	return Vector2(0.2, 0.09) if easy else Vector2(0.13, 0.06)

static func start(rng: Rng, easy := false) -> Dictionary:
	var cells: Array = []
	for i in GRID * GRID:
		cells.append(0.55 + rng.roll() * 0.4)
	return {"cells": cells, "worms": [], "bucket": 0, "stolen": 0, "meter": 0.0, "cursor": GRID * GRID / 2, "t": 0.0,
		"bird": {}, "bird_in": 7.0 + rng.roll() * 3.0, "rng": rng, "easy": easy, "done": false, "taps": 0, "misses": 0,
		"last_tap": -9.0, "shoos": 0}

## Offset in seconds from the nearest beat (beats fall at multiples of the period, after a count-in the screen handles).
static func offset(t: float) -> float:
	var p := period()
	var m := fmod(t, p)
	return m if m <= p * 0.5 else m - p

## Judges a tap at clock time t: "perfect", "good" or "miss".
static func judge(t: float, easy: bool) -> String:
	var w := windows(easy)
	var o := absf(offset(t))
	return "perfect" if o <= w.y else ("good" if o <= w.x else "miss")

## A tap on the cell under the fork. Returns the verdict. Worms rise from that cell and its neighbours.
static func tap(st: Dictionary, t: float) -> String:
	var rng: Rng = st.rng
	var verdict := judge(t, st.easy)
	st.taps = int(st.taps) + 1
	st.last_tap = t
	if verdict == "miss":
		st.misses = int(st.misses) + 1
		st.meter = float(st.meter) * 0.5
		st.bird_in = maxf(1.5, float(st.bird_in) - 1.6)   # a messy beat draws the birds
		return verdict
	var q := 1.0 if verdict == "perfect" else 0.65
	st.meter = minf(1.0, float(st.meter) + (0.14 if verdict == "perfect" else 0.09))
	var c: int = st.cursor
	var cx := c % GRID
	var cy := c / GRID
	for i in GRID * GRID:
		var dx := absi(i % GRID - cx)
		var dy := absi(i / GRID - cy)
		if dx + dy > 1:
			continue
		var w := 1.0 if dx + dy == 0 else 0.4
		var dens: float = st.cells[i]
		var expect := q * w * dens * (0.35 + 1.15 * float(st.meter)) * 0.22
		var n := int(expect)
		if rng.roll() < expect - float(n):
			n += 1
		if n > 0:
			for k in n:
				st.worms.append({"cell": i, "age": 0.0, "off": Vector2(rng.roll() - 0.5, rng.roll() - 0.5)})
			st.cells[i] = maxf(0.0, dens - 0.14 * w * float(n))
	return verdict

static func move_cursor(st: Dictionary, dx: int, dy: int) -> void:
	var x := clampi(int(st.cursor) % GRID + dx, 0, GRID - 1)
	var y := clampi(int(st.cursor) / GRID + dy, 0, GRID - 1)
	st.cursor = y * GRID + x

## Shoo: sends off a bird that is coming or just landed. True if there was one.
static func shoo(st: Dictionary) -> bool:
	st.shoos = int(st.shoos) + 1
	if (st.bird as Dictionary).is_empty():
		return false
	st.bird = {}
	st.bird_in = 6.0 + (st.rng as Rng).roll() * 3.0
	return true

## Advance by dt. Returns events: "bagged" (a worm counted), "bird" (a bird has been spotted), "stolen", "done".
static func step(st: Dictionary, dt: float) -> Array:
	var ev: Array = []
	if bool(st.done):
		return ev
	var rng: Rng = st.rng
	st.t = float(st.t) + dt
	for i in st.cells.size():
		st.cells[i] = minf(1.0, float(st.cells[i]) + dt * 0.05)
	if float(st.t) - float(st.last_tap) > period() * 1.6:
		st.meter = maxf(0.0, float(st.meter) - dt * 0.25)
	# worms: counted when they have been up long enough
	var keep: Array = []
	for w in st.worms:
		w.age = float(w.age) + dt
		if float(w.age) >= LIFE:
			st.bucket = int(st.bucket) + 1
			ev.append("bagged")
		else:
			keep.append(w)
	st.worms = keep
	# the bird
	var b: Dictionary = st.bird
	if b.is_empty():
		st.bird_in = float(st.bird_in) - dt
		if float(st.bird_in) <= 0.0:
			var target := int(st.cursor)
			if not st.worms.is_empty() and rng.roll() < 0.7:
				target = int(st.worms[rng.roll_int(0, st.worms.size() - 1)].cell)
			st.bird = {"cell": target, "eta": WARN}
			ev.append("bird")
	else:
		b.eta = float(b.eta) - dt
		if float(b.eta) <= 0.0:
			var took := 0
			var rest: Array = []
			for w in st.worms:
				var dx := absi(int(w.cell) % GRID - int(b.cell) % GRID)
				var dy := absi(int(w.cell) / GRID - int(b.cell) / GRID)
				if dx + dy <= 1:
					took += 1
				else:
					rest.append(w)
			st.worms = rest
			st.stolen = int(st.stolen) + took
			if took > 0:
				ev.append("stolen")
			st.bird = {}
			st.bird_in = 5.0 + rng.roll() * 3.0 + float(st.meter) * 3.0
	if float(st.t) >= duration():
		st.done = true
		ev.append("done")
	return ev

static func local_score(rival: Dictionary, rng: Rng) -> int:
	return maxi(0, roundi(float(rival.get("worms", 25)) + (rng.roll() - 0.5) * 2.0 * float(rival.get("spread", 5))))

static func advice(st: Dictionary) -> String:
	if int(st.misses) > int(st.taps) / 3:
		return "Too many taps off the beat: a messy rhythm scares worms down and calls the birds."
	if int(st.stolen) > 4:
		return "The birds had %d. Press Shoo as soon as you see the shadow." % int(st.stolen)
	if int(st.taps) < 40:
		return "Quiet hands. Tap every beat and the ground does the rest."
	return "A tidy rhythm. Move the fork to fresh earth when a patch goes pale."

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

static func finish(data: GameStateData, venue_id: String, worms: int, won: bool) -> Dictionary:
	var record := worms > TrainerStats.get_count(data, "worms_best")
	if record:
		data.stats["worms_best"] = worms
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
