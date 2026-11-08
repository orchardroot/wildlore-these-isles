class_name Gurning
extends RefCounted
## The gurning contest (Egremont Crab Fair, Cumbria, since 1267): a Simon-style game. The judges flash a gurn, you
## copy them in order with the direction keys, and each round adds one. Two slips and the collar comes off (three with
## Easier minigames, which also slows the show and removes the time limit). Pure logic with a seeded Rng (no autoload
## names); ui/gurning_screen.gd draws it and the story command {"do": "gurn"} (story/contest_run.gd) pays it out.

const PATH := "res://data/gurning.json"
const START_LEN := 3
const MAX_LEN := 14
const SLIPS := 2
const FLAG_PREFIX := "gurn_"
const FLAG_DAY := "gurn_day_"
const DAILY_PURSE := 3
const STAT := "gurn_best"
const GAME_ID := "gurning"

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"faces": [], "venues": {}}
	return _cfg

static func faces() -> Array:
	return cfg().faces

static func venue(id: String) -> Dictionary:
	return cfg().venues.get(id, {})

static func face_for_dir(dir: String) -> int:
	for i in faces().size():
		if str(faces()[i].dir) == dir:
			return i
	return -1

## The next sequence: the old one with one more gurn on the end (Simon-style), never the same face three times running.
static func extend(seq: Array, rng: Rng) -> Array:
	var out := seq.duplicate()
	while true:
		var f := rng.roll_int(0, faces().size() - 1)
		var n := out.size()
		if n >= 2 and int(out[n - 1]) == f and int(out[n - 2]) == f:
			continue
		out.append(f)
		break
	return out

static func start_sequence(rng: Rng) -> Array:
	var s: Array = []
	for i in START_LEN:
		s = extend(s, rng)
	return s

static func slips_allowed(easy: bool) -> int:
	return SLIPS + (1 if easy else 0)

## Seconds the judges show each gurn, and the time you get for each copy (0 = no limit).
static func show_time(round_len: int, easy: bool) -> float:
	var t := maxf(0.42, 0.75 - 0.03 * float(round_len - START_LEN))
	return t * (1.5 if easy else 1.0)

static func answer_time(easy: bool) -> float:
	return 0.0 if easy else 4.0

## One answer: correct when it matches the face at that position.
static func is_correct(seq: Array, i: int, face: int) -> bool:
	return i >= 0 and i < seq.size() and int(seq[i]) == face

## A rival's longest clean run: their reach, a little spread either way.
static func local_best(rival: Dictionary, rng: Rng) -> int:
	var base := int(rival.get("reach", 6))
	var sp := int(rival.get("spread", 1))
	return clampi(base + rng.roll_int(-sp, sp), START_LEN - 1, MAX_LEN)

static func advice(score: int) -> String:
	if score >= 10:
		return "The judges are speechless. That is the highest compliment gurning has."
	if score >= 6:
		return "A proper gurn. Your mother would say you will stick like that."
	if score >= 3:
		return "A decent set of faces. Watch the order, not just the faces."
	return "The collar fits, the memory needs work. Say the order under your breath."

# ---- rewards

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

static func best(data: GameStateData) -> int:
	return TrainerStats.get_count(data, STAT)

static func finish(data: GameStateData, venue_id: String, my_best: int, won: bool) -> Dictionary:
	var record := my_best > best(data)
	if record:
		data.stats[STAT] = my_best
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
