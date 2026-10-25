class_name Curling
extends RefCounted
## Curling, a four-stone end against a club skip. Pure logic (no autoload names): ui/curling_screen.gd draws it and
## the story command {"do": "curling"} pays it out.
##
## The sheet, in metres, with the tee line and the button at (0, 0): x across the sheet, y along it, positive towards
## the back line. The hack is 38.4 m before the tee; the far hog line is 6.4 m before it. The house is 12 feet
## (1.83 m) across from the button to its edge; a stone counts if any of it touches the house, so its radius is
## added. A stone that stops short of the far hog line is taken off, and so is one that slides past the back line.
##
## You choose a weight from 1 to 10 (6 stops on the tee with no sweeping), a broom position and a handle (which way
## it turns). The stone curls about a metre towards the handle side, a little less when it is thrown harder or
## swept; sweeping carries it further.

const PATH := "res://data/curling.json"
const HACK_TO_TEE := 38.4
const HOG := -6.4
const HOUSE := 1.83
const BUTTON := 0.15
const STONE_R := 0.145
const BACK := 1.83
const HALF_SHEET := 2.375
const CURL := 1.0                   # sideways drift of a draw weight stone with no sweeping
const SWEEP_CAP := 10               # taps that count
const SWEEP_GAIN := 0.55            # metres carried per sweep tap
const SWEEP_GAIN_EASY := 0.75
const STONES_EACH := 4
const FLAG_PREFIX := "curling_"     # curling_<rink> = skips beaten (an int)
const FLAG_DAY := "curling_day_"    # the rink's once-a-day kitty
const DAILY_PURSE := 8              # sterling; a hot chocolate and a bag of crisps

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"rinks": {}}
	return _cfg

static func rink(id: String) -> Dictionary:
	return cfg().rinks.get(id, {})

# ---- throwing

## How far a stone travels from the hack at weight 1 to 10: weight 6 is the tee.
static func weight_distance(weight: int) -> float:
	return 30.0 + 1.4 * float(clampi(weight, 1, 10))

## What the weight number means in the curler's words, for the screen.
static func weight_name(weight: int) -> String:
	match weight:
		1, 2: return "Too light"
		3: return "Guard"
		4: return "Short draw"
		5: return "Draw to the front of the house"
		6: return "Draw to the button"
		7: return "Heavy draw"
		_: return "Take-out"

## Metres carried by `taps` sweeps (capped).
static func carry(taps: int, easy: bool) -> float:
	return float(clampi(taps, 0, SWEEP_CAP)) * (SWEEP_GAIN_EASY if easy else SWEEP_GAIN)

static func _curl(d_total: float, taps: int) -> float:
	var frac := float(clampi(taps, 0, SWEEP_CAP)) / float(SWEEP_CAP)
	return CURL * clampf(HACK_TO_TEE / maxf(d_total, 1.0), 0.7, 1.25) * (1.0 - 0.35 * frac)

## Where the stone is when it has travelled `s` of its whole slide (0 to 1).
static func lateral(broom: float, handle: int, curl: float, s: float) -> float:
	return broom + float(handle) * curl * s * s

static func _copy(stones: Array) -> Array:
	var out: Array = []
	for s in stones:
		out.append({"team": int(s.team), "x": float(s.x), "y": float(s.y)})
	return out

static func _out_of_play(x: float, y: float) -> bool:
	return y > BACK + STONE_R or absf(x) > HALF_SHEET

static func in_house(s: Dictionary) -> bool:
	return Vector2(float(s.x), float(s.y)).length() <= HOUSE + STONE_R

## Delivers one stone for `team`. `dist` is the slide before ice and sweeping (weight_distance), `ice` the sheet's
## speed this end (positive runs long). Returns {stones, event, x, y}: the stones left on the sheet and what
## happened: "house", "guard", "hit" (a stone knocked out), "glance" (a stone moved), "hog" (short, removed), "back"
## (through the house, removed) or "wide" (off the side, removed). x and y are where the stone ended.
static func deliver(stones: Array, team: int, dist: float, broom: float, handle: int, taps: int, ice: float, easy: bool) -> Dictionary:
	var out := _copy(stones)
	var d_total := dist + ice + carry(taps, easy)
	var curl := _curl(d_total, taps)
	var end_y := d_total - HACK_TO_TEE
	var end_x := lateral(broom, handle, curl, 1.0)
	if end_y < HOG:
		return {"stones": out, "event": "hog", "x": end_x, "y": end_y}
	var order: Array = out.duplicate()
	order.sort_custom(func(a, b): return a.y < b.y)
	for s in order:
		if float(s.y) > end_y + 2.0 * STONE_R:
			break
		var travelled := minf(float(s.y) + HACK_TO_TEE, d_total)
		var px := lateral(broom, handle, curl, travelled / d_total)
		var off := absf(px - float(s.x))
		if off >= 2.0 * STONE_R:
			continue
		var sy := float(s.y) - 2.0 * STONE_R
		var event := "hit"
		if off < 0.15:
			out.erase(s)
		else:
			event = "glance"
			var nx := float(s.x) + (1.0 if float(s.x) >= px else -1.0) * 0.6
			var ny := float(s.y) + 0.9
			if _out_of_play(nx, ny):
				out.erase(s)
			else:
				s.x = nx
				s.y = ny
		if sy < HOG:
			return {"stones": out, "event": "hog", "x": px, "y": sy}
		out.append({"team": team, "x": px, "y": sy})
		return {"stones": out, "event": event, "x": px, "y": sy}
	if end_y > BACK + STONE_R:
		return {"stones": out, "event": "back", "x": end_x, "y": end_y}
	if absf(end_x) > HALF_SHEET:
		return {"stones": out, "event": "wide", "x": end_x, "y": end_y}
	var mine := {"team": team, "x": end_x, "y": end_y}
	out.append(mine)
	return {"stones": out, "event": "house" if in_house(mine) else "guard", "x": end_x, "y": end_y}

## The delivery that puts a stone at `target` with no sweeping: {dist, broom}. A take-out (`strike`) goes in
## harder, 3 m beyond, so it is still moving when it arrives.
static func plan(target: Vector2, handle: int, ice: float, strike: bool) -> Dictionary:
	var travel := target.y + HACK_TO_TEE
	var d_total := travel + (3.0 if strike else 0.0)
	var curl := _curl(d_total, 0)
	var s := travel / d_total
	return {"dist": d_total - ice, "broom": target.x - float(handle) * curl * s * s}

# ---- scoring

## {team, points}: the side with the stone nearest the button scores one for each of its stones in the house that
## are nearer than the other side's best. -1 and 0 for a blank end (nothing in the house, or a dead tie).
static func score_end(stones: Array) -> Dictionary:
	var best := [INF, INF]
	var mine: Array = [[], []]
	for s in stones:
		if not in_house(s):
			continue
		var d := Vector2(float(s.x), float(s.y)).length()
		var t := int(s.team)
		best[t] = minf(best[t], d)
		mine[t].append(d)
	if best[0] == best[1]:
		return {"team": -1, "points": 0}
	var win := 0 if best[0] < best[1] else 1
	var pts := 0
	for d in mine[win]:
		if d < best[1 - win]:
			pts += 1
	return {"team": win, "points": pts}

## The shot stone's owner and distance right now: {team, d}, or team -1 with an empty house.
static func shot(stones: Array) -> Dictionary:
	var t := -1
	var best := INF
	for s in stones:
		if in_house(s):
			var d := Vector2(float(s.x), float(s.y)).length()
			if d < best:
				best = d
				t = int(s.team)
	return {"team": t, "d": best}

# ---- the skip

static func _gauss(rng: Rng, sigma: float) -> float:
	return sqrt(-2.0 * log(maxf(rng.roll(), 0.0001))) * cos(rng.roll() * TAU) * sigma

## What a sensible skip throws next: a take-out if you hold shot (and they fancy it), else a draw to the button.
## {kind, dist, broom, handle, target}; `skip` has sigma_w and sigma_l (metres of error) and hit (percent).
static func skip_stone(stones: Array, team: int, skip: Dictionary, ice: float, rng: Rng) -> Dictionary:
	var sh := shot(stones)
	var handle := 1 if rng.chance(50.0) else -1
	var kind := "draw"
	var target := Vector2.ZERO
	if sh.team >= 0 and sh.team != team and rng.chance(float(skip.get("hit", 50))):
		kind = "takeout"
		for s in stones:
			if int(s.team) == int(sh.team) and in_house(s) and is_equal_approx(Vector2(float(s.x), float(s.y)).length(), float(sh.d)):
				target = Vector2(float(s.x), float(s.y))
				break
	var p := plan(target, handle, ice, kind == "takeout")
	return {"kind": kind, "dist": float(p.dist) + _gauss(rng, float(skip.get("sigma_w", 0.5))),
		"broom": float(p.broom) + _gauss(rng, float(skip.get("sigma_l", 0.25))), "handle": handle, "target": target}

## The sheet's speed for an end: -0.8 (keen) to +0.8 (heavy) metres, in 0.4 steps.
static func ice_speed(rng: Rng) -> float:
	return float(rng.roll_int(-2, 2)) * 0.4

static func ice_name(ice: float) -> String:
	if ice < -0.1:
		return "Keen ice: stones will run a touch long, so throw a little lighter."
	if ice > 0.1:
		return "Heavy ice: stones stop early, so throw a little harder."
	return "True ice: the stones run as you'd expect."

## A whole end between a simulated player (team 0, the last stone) and a skip, for tuning and the money check.
static func sim_end(me_w: float, me_l: float, skip: Dictionary, rng: Rng) -> Dictionary:
	var stones: Array = []
	var ice := ice_speed(rng)
	var me := {"sigma_w": me_w, "sigma_l": me_l, "hit": 70}
	for i in STONES_EACH:
		for team in [1, 0]:
			var a := skip_stone(stones, team, skip if team == 1 else me, ice, rng)
			stones = deliver(stones, team, a.dist, a.broom, a.handle, 0, ice, false).stones
	return score_end(stones)

# ---- the ladder

static func rungs_beaten(data: GameStateData, rink_id: String) -> int:
	return int(data.flags.get(FLAG_PREFIX + rink_id, 0))

static func next_rung(data: GameStateData, rink_id: String) -> Dictionary:
	var skips: Array = rink(rink_id).get("skips", [])
	var i := rungs_beaten(data, rink_id)
	return skips[i] if i < skips.size() else {}

static func champion(data: GameStateData, rink_id: String) -> bool:
	return next_rung(data, rink_id).is_empty() and not rink(rink_id).is_empty()

## Records a won end against `rung_index` and returns what to hand over: {first, money (sterling), line}. A rematch
## (or a win as champion) is worth the rink's purse, once a real day per rink.
static func win(data: GameStateData, rink_id: String, rung_index: int) -> Dictionary:
	var skips: Array = rink(rink_id).get("skips", [])
	TrainerStats.add(data, "curling_won")
	if rung_index == rungs_beaten(data, rink_id) and rung_index < skips.size():
		data.set_flag(FLAG_PREFIX + rink_id, rung_index + 1)
		return {"first": true, "money": int(skips[rung_index].get("prize", 0)), "line": str(skips[rung_index].get("beaten", ""))}
	if DailyKey.done_today(data, FLAG_DAY + rink_id):
		return {"first": false, "money": 0, "line": ""}
	data.set_flag(FLAG_DAY + rink_id, DailyKey.stamp(data))
	return {"first": false, "money": DAILY_PURSE, "line": ""}

static func rink_total(rink_id: String) -> int:
	var t := 0
	for s in rink(rink_id).get("skips", []):
		t += int(s.get("prize", 0))
	return t
