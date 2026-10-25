class_name Fete
extends RefCounted
## The village fete (data/fete.json): cheese rolling (Cooper's Hill), bog snorkelling (Llanwrtyd Wells) and welly
## wanging (a Yorkshire fete). Pure, seeded rules; ui/fete_screen.gd plays them and story/fete_run.gd (the `fete`
## command) starts them and pays out. Playable any day for a small prize, bigger on the real date.

const PATH := "res://data/fete.json"
const EVENTS := ["cheese", "bog", "welly"]
const FLAG_DONE := "fete_done_"      # fete_done_<event> = the DailyKey stamp of today's paid win
const FLAG_FIRST := "fete_first_"    # fete_first_<event> = won at least once (plaque shown)

# cheese
const GATES := 8
const CHEESE_BASE := 12.0
const CHEESE_STUMBLE := 1.0
const CHEESE_DIVE := 0.8
# bog
const BOG_LENGTHS := 2
const BOG_BEATS := 10
const BOG_BASE := 70.0
const BOG_MISS := 4.0
const BOG_TARGET := 80.0
# welly
const WELLY_THROWS := 3
const WELLY_TARGET := 30.0

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"events": {}}
	return _cfg

static func event(id: String) -> Dictionary:
	return cfg().events.get(id, {})

# ---- real dates

static func _weekday(y: int, m: int, d: int) -> int:
	var u := int(Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": d, "hour": 12, "minute": 0, "second": 0}))
	return int(Time.get_date_dict_from_unix_time(u).weekday)  # 0 = Sunday

## The last Monday of a month (May and August both have 31 days).
static func last_monday(y: int, m: int) -> int:
	var d := 31
	while _weekday(y, m, d) != 1:
		d -= 1
	return d

## True on the real date of the event: cheese on the last Monday of May, bog snorkelling on the Saturday to Monday of
## the August bank holiday weekend, welly wanging on a Saturday from June to August.
static func real_day(id: String, month: int, day: int, year: int) -> bool:
	match id:
		"cheese":
			return month == 5 and day == last_monday(year, 5)
		"bog":
			var mon := last_monday(year, 8)
			return month == 8 and day >= mon - 2 and day <= mon
		"welly":
			return month >= 6 and month <= 8 and _weekday(year, month, day) == 6
	return false

# ---- cheese rolling

static func cheese_course(rng: Rng) -> Array:
	var out: Array = []
	for i in GATES:
		out.append(-1 if rng.roll() < 0.5 else 1)
	return out

## A lean matched the lurch if it was the right way and near enough to the beat.
static func cheese_judge(lean: int, want: int, offset: float, easy: bool) -> bool:
	return lean == want and absf(offset) <= (0.8 if easy else 0.5)

static func dive_ok(held: float, easy: bool) -> bool:
	return held >= (0.3 if easy else 0.5)

static func cheese_time(stumbles: int, dived: bool) -> float:
	return CHEESE_BASE + CHEESE_STUMBLE * stumbles - (CHEESE_DIVE if dived else 0.0)

static func cheese_rivals(rng: Rng, easy: bool) -> Array:
	var out: Array = []
	for i in 3:
		out.append(snappedf(12.5 + (0.8 if easy else 0.0) + rng.roll() * 3.0, 0.01))
	return out

## 1 for first. Ties go to the runner.
static func place(mine: float, rivals: Array) -> int:
	var p := 1
	for r in rivals:
		if float(r) < mine:
			p += 1
	return p

# ---- bog snorkelling

## One beat per kick ("k") or breath ("b"), both lengths together; never opens or goes on with a breath twice.
static func bog_pattern(rng: Rng) -> Array:
	var out: Array = []
	for l in BOG_LENGTHS:
		var seg: Array = []
		for i in BOG_BEATS:
			seg.append("k")
		for n in 2:
			var i := rng.roll_int(1, BOG_BEATS - 1)
			if seg[i - 1] == "k" and (i + 1 >= BOG_BEATS or seg[i + 1] == "k"):
				seg[i] = "b"
		if not seg.has("b"):
			seg[4] = "b"
		out.append_array(seg)
	return out

static func bog_beat(easy: bool) -> Dictionary:
	return {"interval": 1.0 if easy else 0.8, "window": 0.4 if easy else 0.28}

static func bog_time(misses: int) -> float:
	return BOG_BASE + BOG_MISS * misses

# ---- welly wanging

## A 0..1..0 triangle wave with the given period.
static func sweep(t: float, period: float) -> float:
	var ph := fposmod(t, period) / period
	return ph * 2.0 if ph < 0.5 else 2.0 - ph * 2.0

static func wind(rng: Rng) -> float:
	return snappedf(rng.roll() * 6.0 - 3.0, 0.1)

## Metres: a projectile with a push or a drag from the wind (positive = behind you).
static func welly_distance(power: float, angle_deg: float, wind_ms: float) -> float:
	var v := 6.0 + 16.0 * clampf(power, 0.0, 1.0)
	var d := v * v * sin(deg_to_rad(2.0 * angle_deg)) / 9.81
	return maxf(0.0, d * (1.0 + 0.04 * wind_ms))

# ---- results

static func won_today(data: GameStateData, id: String) -> bool:
	return DailyKey.done_today(data, FLAG_DONE + id)

## Books a win: the counter and the day's prize (the bigger one on the real date). Returns {first, prize (whole pounds)}.
static func win(data: GameStateData, id: String, real: bool) -> Dictionary:
	var e := event(id)
	TrainerStats.add(data, "fete_won")
	var out := {"first": false, "prize": 0}
	if not data.flags.has(FLAG_FIRST + id):
		data.set_flag(FLAG_FIRST + id, 1)
		out.first = true
	if not won_today(data, id):
		out.prize = int(e.get("real_prize" if real else "prize", 0))
		data.set_flag(FLAG_DONE + id, DailyKey.stamp(data))
	return out
