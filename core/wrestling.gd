class_name Wrestling
extends RefCounted
## Cumberland and Westmorland wrestling at Grasmere Sports: a read-and-react game. You start in the hold, chest to
## chest, and the other wrestler telegraphs a throw (a hipe, a buttock or a cross-buttock); you answer with the right
## counter in time. Each answer that works takes him off balance, each miss takes you off balance; a fall goes to
## whoever throws the other, and a bout is the best of three falls. Pure logic (no autoload names); the screen is
## ui/wrestling_screen.gd and the story command {"do": "wrestling"} pays it out.
##
## The three throws are real; the counters are the game's own (it is a game, not a coaching manual).

const PATH := "res://data/wrestling.json"
const MOVES := ["hipe", "buttock", "cross_buttock"]
const NAMES := {"hipe": "hipe", "buttock": "buttock", "cross_buttock": "cross-buttock"}
const COUNTERS := {"hipe": "sink", "buttock": "step", "cross_buttock": "hook"}
const COUNTER_NAMES := {"sink": "Sink your weight", "step": "Step round", "hook": "Hook the leg"}
const TELLS := {
	"hipe": "He drops his hips under yours and heaves you upwards.",
	"buttock": "He turns his back in and sets his hip across yours.",
	"cross_buttock": "He swings his far arm across and hooks his hip in from the other side.",
}
const LESSONS := {
	"hipe": "A hipe: he lifts. Sink your weight and he cannot get you off the ground.",
	"buttock": "A buttock: he turns his back in. Step round and his hip is in the wrong place.",
	"cross_buttock": "A cross-buttock: he swings across. Hook the leg and the throw has nothing to turn on.",
}
const BALANCE := 2
const FEINT_GAP := 0.8            # seconds between a decoy and the real tell
const FLAG_PREFIX := "wrestling_" # wrestling_<venue> = rivals beaten (an int)
const FLAG_DAY := "wrestling_day_"
const DAILY_PURSE := 8            # sterling; a mug of tea and a slice of something at the tent

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"venues": {}}
	return _cfg

static func venue(id: String) -> Dictionary:
	return cfg().venues.get(id, {})

static func counter_of(move: String) -> String:
	return str(COUNTERS.get(move, ""))

static func tell(move: String) -> String:
	return str(TELLS.get(move, ""))

## The seconds you get to answer a real tell: the rival's own pace, longer on easier play.
static func window(base: float, easy: bool) -> float:
	return base * (1.6 if easy else 1.0)

## The tells he shows, in order: [{at, move}]. A feint shows a different throw first and the real one after
## FEINT_GAP; answering before the real tell is answering the decoy.
static func cues(move: String, feint: bool, rng: Rng) -> Array:
	if not feint:
		return [{"at": 0.0, "move": move}]
	var others: Array = MOVES.filter(func(m): return m != move)
	return [{"at": 0.0, "move": rng.pick(others)}, {"at": FEINT_GAP, "move": move}]

## Judges an answer given `elapsed` seconds into the exchange: "counter", "wrong", "late" or "early". The window
## runs from the real tell. An empty `pick` is no answer at all (late).
static func judge(shown: Array, pick: String, elapsed: float, win_s: float) -> String:
	if pick == "":
		return "late"
	var real: Dictionary = shown.back()
	var at := float(real.at)
	if elapsed < at:
		return "early"
	if elapsed > at + win_s:
		return "late"
	return "counter" if pick == counter_of(str(real.move)) else "wrong"

## His next throw: random, but never the same three in a row.
static func next_move(rng: Rng, history: Array) -> String:
	var pool: Array = MOVES.duplicate()
	var n := history.size()
	if n >= 2 and history[n - 1] == history[n - 2]:
		pool.erase(history[n - 1])
	return rng.pick(pool)

# ---- falls and bouts

static func new_fall(easy: bool) -> Dictionary:
	return {"me": BALANCE + (1 if easy else 0), "opp": BALANCE, "winner": ""}

## One exchange's result ("counter" or anything else) applied to a fall.
static func apply(fall: Dictionary, result: String) -> Dictionary:
	var f := fall.duplicate()
	if result == "counter":
		f.opp = int(f.opp) - 1
	else:
		f.me = int(f.me) - 1
	if int(f.opp) <= 0:
		f.winner = "me"
	elif int(f.me) <= 0:
		f.winner = "opp"
	return f

static func new_bout() -> Dictionary:
	return {"me": 0, "opp": 0, "winner": ""}

static func record_fall(bout: Dictionary, who: String) -> Dictionary:
	var b := bout.duplicate()
	b[who] = int(b[who]) + 1
	if int(b.me) >= 2:
		b.winner = "me"
	elif int(b.opp) >= 2:
		b.winner = "opp"
	return b

## A simulated bout where you answer correctly with probability `p` (a feinting rival costs a little of it): who won.
static func sim_bout(p: float, rival: Dictionary, easy: bool, rng: Rng) -> String:
	var p_eff := p * (1.0 - float(rival.get("feint", 0)) / 100.0 * 0.3)
	var bout := new_bout()
	for guard in 40:
		var fall := new_fall(easy)
		for x in 40:
			fall = apply(fall, "counter" if rng.roll() < p_eff else "wrong")
			if fall.winner != "":
				break
		bout = record_fall(bout, fall.winner if fall.winner != "" else "opp")
		if bout.winner != "":
			return bout.winner
	return "opp"

# ---- the ladder

static func rungs_beaten(data: GameStateData, venue_id: String) -> int:
	return int(data.flags.get(FLAG_PREFIX + venue_id, 0))

static func next_rung(data: GameStateData, venue_id: String) -> Dictionary:
	var rivals: Array = venue(venue_id).get("rivals", [])
	var i := rungs_beaten(data, venue_id)
	return rivals[i] if i < rivals.size() else {}

static func champion(data: GameStateData, venue_id: String) -> bool:
	return next_rung(data, venue_id).is_empty() and not venue(venue_id).is_empty()

## Records a won bout against rival `rung_index`: {first, money (sterling), line}. A rematch pays the purse once a day.
static func win(data: GameStateData, venue_id: String, rung_index: int) -> Dictionary:
	var rivals: Array = venue(venue_id).get("rivals", [])
	TrainerStats.add(data, "wrestling_won")
	if rung_index == rungs_beaten(data, venue_id) and rung_index < rivals.size():
		data.set_flag(FLAG_PREFIX + venue_id, rung_index + 1)
		return {"first": true, "money": int(rivals[rung_index].get("prize", 0)), "line": str(rivals[rung_index].get("beaten", ""))}
	if DailyKey.done_today(data, FLAG_DAY + venue_id):
		return {"first": false, "money": 0, "line": ""}
	data.set_flag(FLAG_DAY + venue_id, DailyKey.stamp(data))
	return {"first": false, "money": DAILY_PURSE, "line": ""}

static func venue_total(venue_id: String) -> int:
	var t := 0
	for r in venue(venue_id).get("rivals", []):
		t += int(r.get("prize", 0))
	return t
