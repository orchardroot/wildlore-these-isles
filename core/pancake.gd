class_name Pancake
extends RefCounted
## The Olney pancake race (Buckinghamshire, Shrove Tuesday, run since 1445 by tradition): in an apron and a
## headscarf, carrying a frying pan, over 415 yards of High Street to the church door. The pancake must be tossed at
## the start and again at the finish. Here: hold Run to sprint (faster, but the pan sways more), lean the pan left
## and right to keep the pancake in it, and press Confirm as you pass each flag to flip it. A drop costs a stop to
## scrape it up; a missed flip costs a penalty. Lowest time wins. Pure rules (no autoload names); ui/pancake_screen.gd
## draws it, and the story command {"do": "pancake"} (story/party_run.gd) pays it out.

const LENGTH := 415.0
const JOG := 7.4                   # yards a second
const SPRINT := 11.2
const STATIONS := 9                # flip flags along the street, then the finish
const SWAY_HZ := 0.55
const FLIP_AIR := 0.5
const OPEN := 0.9                  # seconds before a flag that its flip window opens
const CLOSE := 0.6                 # and seconds after it that it shuts
const MISS_PENALTY := 1.5
const FINISH_MISS_PENALTY := 3.0
const PERFECT_BONUS := 0.2
const FLAG_PREFIX := "pancake_"
const FLAG_DAY := "pancake_day"
const DAILY_PURSE := 3
const GOOD_TIME := 52.0
const MASTER_TIME := 42.0

var rng: Rng
var easy := false
var t := 0.0                       # the clock
var penalty := 0.0                 # seconds added or taken off
var y := 0.0
var v := 0.0
var lean := 0.0                    # the pan's tilt, -1 to 1
var p := 0.0                       # where the pancake sits on the pan, -1 to 1 (rim at +-1)
var pv := 0.0
var phase := 0.0
var drift := 0.0
var air := 0.0                     # seconds the pancake has left in the air
var land_offset := 0.0
var stopped := 0.0                 # seconds left scraping it off the road
var drops := 0
var next_station := 0              # index of the next flag (flag 0 is the starting toss, done before the clock runs)
var flips: Array = []              # per flag: "perfect" | "good" | "scruffy" | "miss"
var flipped_here := false
var started := false
var done := false
var cross_t := -1.0                # the clock reading as the finish line is crossed
var events: Array = []             # "flip:<grade>", "drop", "pickup", "start", "finish", "near_rim"
var _near := false

func _init(seed_value := 1, easier := false) -> void:
	rng = Rng.new(seed_value)
	easy = easier
	phase = rng.roll() * TAU

## y of flag i (0 is the start line, STATIONS is the church door).
static func station_y(i: int) -> float:
	return LENGTH * float(i) / float(STATIONS)

## Seconds either side of a flag for each grade of flip.
func windows() -> Dictionary:
	return {"perfect": 0.26, "good": 0.55, "scruffy": 0.85} if easy else {"perfect": 0.14, "good": 0.32, "scruffy": 0.55}

## 0..1 as a flag nears (1 at the flag itself), or -1 when none is open. The screen shrinks a ring with it.
func prompt() -> float:
	if done or next_station > STATIONS or flipped_here:
		return -1.0
	var d := station_y(next_station) - y
	var sp := maxf(v, JOG)
	if d / sp > OPEN or d / sp < -CLOSE:
		return -1.0
	return clampf(1.0 - d / sp / OPEN, 0.0, 1.5)

## Advances the race by dt seconds. tilt in -1..1 leans the pan, sprint is Run held, flip is Confirm just pressed.
func step(dt: float, tilt: float, sprint: bool, flip: bool) -> void:
	if done:
		return
	if not started:
		# the starting toss comes first: the race begins with the first flip (or the pan is kept waiting)
		if flip:
			started = true
			next_station = 1
			air = FLIP_AIR
			events.append("start")
		return
	t += dt
	if air > 0.0:
		air -= dt
		if air <= 0.0:
			p = land_offset
			pv = 0.0
	if stopped > 0.0:
		stopped -= dt
		v = move_toward(v, 0.0, 30.0 * dt)
		if stopped <= 0.0:
			events.append("pickup")
			p = 0.0
			pv = 0.0
	else:
		v = move_toward(v, SPRINT if sprint else JOG, 9.0 * dt)
	y += v * dt
	# the pan: a sway with every stride, a slow drift, and your lean pushing back
	lean = move_toward(lean, tilt, 14.0 * dt)
	if air <= 0.0 and stopped <= 0.0:
		var frac := clampf((v - JOG * 0.5) / (SPRINT - JOG * 0.5), 0.0, 1.0)
		var amp := (2.5 + 5.5 * frac) * (0.55 if easy else 1.0)
		drift = clampf(drift + (rng.roll() - 0.5) * 3.0 * dt, -1.0, 1.0)
		var push := amp * sin(TAU * SWAY_HZ * t + phase) + drift * 1.6 * frac - 13.0 * lean
		pv = (pv + push * dt) * (1.0 - 0.9 * dt)
		p += pv * dt
		var rim := 1.0
		if absf(p) > 0.72 * rim and not _near:
			_near = true
			events.append("near_rim")
		elif absf(p) < 0.55:
			_near = false
		if absf(p) >= rim:
			drops += 1
			stopped = 0.8 if easy else 1.4
			p = clampf(p, -1.0, 1.0)
			events.append("drop")
	# flags
	if next_station <= STATIONS:
		var d := station_y(next_station) - y
		if flip and not flipped_here and air <= 0.0 and stopped <= 0.0:
			var secs := d / maxf(v, JOG)
			_grade_flip(secs)
		if next_station <= STATIONS and y - station_y(next_station) > CLOSE * maxf(v, JOG):
			if not flipped_here:
				_miss()
			next_station += 1
			flipped_here = false
	if y >= LENGTH and cross_t < 0.0:
		cross_t = t - (y - LENGTH) / maxf(v, 1.0)
	if y >= LENGTH and not done and next_station > STATIONS:
		_finish()
	elif y >= LENGTH + 20.0 and not done:
		_finish()

func _grade_flip(secs: float) -> void:
	var w := windows()
	var off := absf(secs)
	var grade := "miss"
	if off <= float(w.perfect):
		grade = "perfect"
	elif off <= float(w.good):
		grade = "good"
	elif off <= float(w.scruffy):
		grade = "scruffy"
	if grade == "miss":
		return    # nowhere near a flag: an idle press does nothing
	flipped_here = true
	flips.append(grade)
	air = FLIP_AIR
	land_offset = 0.0 if grade == "perfect" else (1.0 if rng.roll() < 0.5 else -1.0) * (0.28 if grade == "good" else 0.5)
	if grade == "perfect":
		penalty -= PERFECT_BONUS
	events.append("flip:" + grade)

func _miss() -> void:
	flips.append("miss")
	penalty += FINISH_MISS_PENALTY if next_station >= STATIONS else MISS_PENALTY
	events.append("flip:miss")

func _finish() -> void:
	done = true
	events.append("finish")

## The time on the clock, with penalties and bonuses.
func total() -> float:
	return maxf(0.0, (cross_t if cross_t >= 0.0 else t) + penalty)

func count(grade: String) -> int:
	var n := 0
	for g in flips:
		if g == grade:
			n += 1
	return n

## The champion's time on the day: a touch over MASTER, a touch under GOOD.
static func champion_time(seed_value: int) -> float:
	var r := Rng.new(seed_value * 7 + 3)
	return snappedf(46.0 + r.roll() * 4.0, 0.1)

func verdict(champ: float) -> String:
	var tt := total()
	var line := ""
	if tt < champ:
		line = "%.1f seconds. Past the champion, with the pan still level and the pancake still pancake-shaped." % tt
	elif tt < champ + 6.0:
		line = "%.1f seconds. A hair behind the champion, and she did not even look round." % tt
	else:
		line = "%.1f seconds. The church has stood since the thirteenth century and it was in no hurry either." % tt
	if drops > 0:
		line += " %d drop%s, scraped off the cobbles with dignity." % [drops, "" if drops == 1 else "s"]
	return line

# ---- rewards

static func won(data: GameStateData) -> bool:
	return data.flag(FLAG_PREFIX + "won") == true

## Records a finished race. Returns {first, money, record (best time)}.
static func finish_race(data: GameStateData, time: float, beat_champion: bool) -> Dictionary:
	var best := float(data.stats.get("pancake_best", 0)) / 10.0
	var record := best <= 0.0 or time < best
	if record:
		data.stats["pancake_best"] = int(round(time * 10.0))
	if not beat_champion:
		return {"first": false, "money": 0, "record": record}
	TrainerStats.add(data, "pancake_wins")
	if not won(data):
		data.set_flag(FLAG_PREFIX + "won", true)
		return {"first": true, "money": 10, "record": record}
	if DailyKey.done_today(data, FLAG_DAY):
		return {"first": false, "money": 0, "record": record}
	data.set_flag(FLAG_DAY, DailyKey.stamp(data))
	return {"first": false, "money": DAILY_PURSE, "record": record}
