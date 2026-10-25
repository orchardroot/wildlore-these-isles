class_name Bowls
extends RefCounted
## Crown green bowls: a square green with a hump (the crown) in the middle, a jack that the player of the end rolls
## wherever they like, and two biased woods a side. A biased wood is lopsided, so it curves in as it slows; the crown
## shoves it gently downhill, away from the middle. Three ends against a local, most shots wins (a tie plays extra
## ends). Pure logic with a seeded Rng so tests are exact (no autoload names); ui/bowls_screen.gd draws it and the
## story command {"do": "bowls"} (story/pub_sport_run.gd) pays it out. Venues and locals live in data/bowls.json.
##
## Green units are metres. x is right, y is down the screen; the crown is at (0, 0) and the mat at MAT. A heading
## of 0 points up the green and grows clockwise; a bias of +1 curves a wood to the right, -1 to the left.

const PATH := "res://data/bowls.json"
const HALF := 17.0                  # the green is 34 m square (crown greens run roughly 31 to 37 m)
const MAT := Vector2(0.0, 14.0)
const CROWN_R := 8.0
const CROWN_PUSH := 0.07            # m/s^2 at the very top of the hump, fading to nothing at CROWN_R
const DECEL := 1.2                  # m/s^2: the green is "quick", a wood runs out in about six seconds
const BIAS := 0.13                  # turn rate scale: rad/s times the wood's speed in m/s
const STEP := 0.05
const WOODS := 2                    # each side in singles
const ENDS := 3
const MAX_EXTRA := 3
const JACK_MIN := 12.0
const JACK_MAX := 28.0
const FLAG_PREFIX := "bowls_"       # bowls_<venue> = true once the local has been beaten
const FLAG_DAY := "bowls_day_"      # once-a-day purse per venue (a DailyKey stamp)
const FLAG_ENDS := "bowls_ends_won"
const DAILY_PURSE := 4              # sterling; the winner's pint and a packet of pork scratchings, once a day per green

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

# ---- the wood

static func dir_of(heading: float) -> Vector2:
	return Vector2(sin(heading), -cos(heading))

## The path of a wood: {path: PackedVector2Array (one point every STEP seconds), end: Vector2}. `weight` is the
## distance in metres a wood would run on a flat, unbiased green; the crown and the bias then bend it.
static func roll_wood(start: Vector2, heading: float, weight: float, bias: int) -> Dictionary:
	var v0 := sqrt(2.0 * DECEL * maxf(weight, 0.5))
	var vel := dir_of(heading) * v0
	var pos := start
	var path := PackedVector2Array([pos])
	for i in 400:
		var sp := vel.length()
		if sp < 0.12:
			break
		vel = vel.rotated(float(bias) * BIAS / maxf(sp, 0.7) * STEP)
		vel -= vel / sp * minf(DECEL * STEP, sp)
		var r := pos.length()
		if r < CROWN_R and r > 0.001:
			vel += pos / r * CROWN_PUSH * (1.0 - r / CROWN_R) * STEP
		pos += vel * STEP
		path.append(pos)
	return {"path": path, "end": pos}

## The jack runs true to the spot you pick (a simplification), clamped to a legal length and to the green.
static func jack_spot(aim: Vector2) -> Vector2:
	var off := aim - MAT
	var len := clampf(off.length(), JACK_MIN, JACK_MAX)
	var p := MAT + (off.normalized() if off.length() > 0.001 else Vector2.UP) * len
	return Vector2(clampf(p.x, -HALF + 1.0, HALF - 1.0), clampf(p.y, -HALF + 1.0, HALF))

## {heading, weight} that bring a wood of `bias` from `start` to rest on `target`, found by correction (a few
## trial rolls). This is what a club bowler's hands know and what Easier bowls draws for you.
static func aim_at(start: Vector2, target: Vector2, bias: int) -> Dictionary:
	var off := target - start
	var dist := maxf(off.length(), 1.0)
	var bearing := atan2(off.x, -off.y)
	var h := bearing
	var w := dist
	var d := dir_of(bearing)
	var right := Vector2(-d.y, d.x)   # clockwise of the line of play
	for i in 12:
		var end: Vector2 = roll_wood(start, h, w, bias).end
		var err := target - end
		if err.length() < 0.03:
			break
		h += err.dot(right) / dist
		w = maxf(1.0, w + err.dot(d) * 0.9)
	return {"heading": h, "weight": w}

# ---- the hand: how steady you are

static func gauss(rng: Rng) -> float:
	return sqrt(-2.0 * log(maxf(rng.roll(), 0.0001))) * cos(rng.roll() * TAU)

## Your delivery: {side (radians of heading), weight (a fraction of the weight)}. Easier bowls steadies both.
static func steadiness(easy: bool) -> Dictionary:
	return {"side": 0.007 if easy else 0.014, "weight": 0.02 if easy else 0.04}

## Where a wood really goes once the hand has had its say: {path, end}.
static func deliver(start: Vector2, heading: float, weight: float, bias: int, steady: Dictionary, rng: Rng) -> Dictionary:
	var h := heading + gauss(rng) * float(steady.side)
	var w := weight * (1.0 + gauss(rng) * float(steady.weight))
	return roll_wood(start, h, w, bias)

## True when a wood has run off the green (a dead wood, which never scores).
static func dead(p: Vector2) -> bool:
	return absf(p.x) > HALF or absf(p.y) > HALF

# ---- an end

## {winner: "me" | "them" | "none", shots}. The side with the wood nearest the jack scores a shot for each of its
## live woods nearer than the other side's nearest; a dead wood or an exact tie scores nothing.
static func score_end(jack: Vector2, mine: Array, theirs: Array) -> Dictionary:
	var a := _dists(jack, mine)
	var b := _dists(jack, theirs)
	var best_a: float = a[0] if not a.is_empty() else INF
	var best_b: float = b[0] if not b.is_empty() else INF
	if best_a == best_b:
		return {"winner": "none", "shots": 0}
	var win_a := best_a < best_b
	var lead: Array = a if win_a else b
	var cut := best_b if win_a else best_a
	var n := 0
	for d in lead:
		if d < cut:
			n += 1
	return {"winner": "me" if win_a else "them", "shots": n}

static func _dists(jack: Vector2, woods: Array) -> Array:
	var out: Array = []
	for w in woods:
		if not dead(w):
			out.append(jack.distance_to(w))
	out.sort()
	return out

## Where the match stands after `ends` ends: "play" (another end), "me", "them" or "draw" (still level after the
## extra ends).
static func match_state(mine: int, theirs: int, ends: int) -> String:
	if ends < ENDS:
		return "play"
	if mine != theirs:
		return "me" if mine > theirs else "them"
	return "play" if ends < ENDS + MAX_EXTRA else "draw"

## Who rolls the jack at end number `end` (0 first): you do, then it alternates.
static func jack_setter(end: int) -> String:
	return "me" if end % 2 == 0 else "them"

# ---- locals

## A local's jack: a sensible length, a little off the middle line.
static func local_jack(rng: Rng) -> Vector2:
	return jack_spot(Vector2(rng.roll_range(-5.0, 5.0), rng.roll_range(-8.0, 0.0)))

## A local's wood: aims at the jack with the hand they have. Takes the hand (bias) that suits the jack: bowlers
## play the side that curves towards the middle of the green.
static func local_wood(jack: Vector2, rival: Dictionary, rng: Rng) -> Dictionary:
	var bias := 1 if jack.x < 0.0 else -1
	var aim := aim_at(MAT, jack, bias)
	var steady := {"side": float(rival.get("side", 0.012)), "weight": float(rival.get("weight", 0.035))}
	var res := deliver(MAT, float(aim.heading), float(aim.weight), bias, steady, rng)
	res["bias"] = bias
	return res

## Plays a whole end between you (a hand of `me` steadiness, aiming true) and a local, both simulated: used by the
## fairness tests. Returns score_end's result.
static func sim_end(me: Dictionary, rival: Dictionary, me_first: bool, rng: Rng) -> Dictionary:
	var jack := local_jack(rng)
	var mine: Array = []
	var theirs: Array = []
	var steady := {"side": float(me.side), "weight": float(me.weight)}
	for i in WOODS * 2:
		var mine_turn := (i % 2 == 0) == me_first
		if mine_turn:
			var aim := aim_at(MAT, jack, 1)
			mine.append(deliver(MAT, float(aim.heading), float(aim.weight), 1, steady, rng).end)
		else:
			theirs.append(local_wood(jack, rival, rng).end)
	return score_end(jack, mine, theirs)

## Who bowls next, given the woods already down: the side with the wood further from the jack (or nothing down)
## goes next, as in the real game. Returns "me" or "them"; `first` breaks the opening tie.
static func next_to_play(jack: Vector2, mine: Array, theirs: Array, first: String) -> String:
	if mine.size() >= WOODS and theirs.size() >= WOODS:
		return ""
	if mine.size() >= WOODS:
		return "them"
	if theirs.size() >= WOODS:
		return "me"
	if mine.is_empty() and theirs.is_empty():
		return first
	if mine.is_empty():
		return "me"
	if theirs.is_empty():
		return "them"
	var a := _dists(jack, mine)
	var b := _dists(jack, theirs)
	var da: float = a[0] if not a.is_empty() else INF
	var db: float = b[0] if not b.is_empty() else INF
	return "me" if da > db else "them"

# ---- rewards

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

static func ends_won(data: GameStateData) -> int:
	return TrainerStats.get_count(data, "bowls_ends_won")

## Records a finished match: `ends_me` ends won of the match. Returns {first, money (sterling), line}. A first win is
## the venue's prize; later wins pay the green's daily purse, once a real day per green.
static func finish(data: GameStateData, venue_id: String, ends_me: int, won: bool) -> Dictionary:
	if ends_me > 0:
		TrainerStats.add(data, "bowls_ends_won", ends_me)
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
