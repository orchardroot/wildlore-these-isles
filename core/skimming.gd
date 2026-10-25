class_name Skimming
extends RefCounted
## Stone skimming: pick a stone, set the angle it meets the water at and how hard you throw, and count the skips.
## A flat, thin stone with a good spin (the Easdale slate) stays steady; a round heavy one digs in. The best angle is
## about 20 degrees (a steep stone sinks, a very flat one skids and loses its speed), each skip costs a little speed
## and tips the stone steeper, and the hops shorten until it sinks. Pure logic with a seeded Rng (no autoload names);
## ui/skimming_screen.gd draws it and the story command {"do": "skim"} (story/pub_sport_run.gd) pays it out. Venues,
## stones and locals live in data/skimming.json.

const PATH := "res://data/skimming.json"
const BEST_ANGLE := 20.0           # degrees: the angle the research (and every Easdale champion) settles on
const SWEET := 25.0                # the model's centre, a little over BEST_ANGLE because the stone tips steeper each skip
const ANGLE_MIN := 5
const ANGLE_MAX := 45
const SINKS_ABOVE := 38.0          # a stone this steep goes straight in
const MIN_SPEED := 2.5             # m/s: slower than this and the stone just settles
const THROWS := 3
const MAX_SKIPS := 40
const FLAG_PREFIX := "skim_"       # skim_<venue> = true once the local has been beaten
const FLAG_DAY := "skim_day_"      # once-a-day purse per venue (a DailyKey stamp)
const DAILY_PURSE := 3             # sterling: a bag of chips on the way home, once a real day per shore

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"stones": [], "venues": {}}
	return _cfg

static func stones() -> Array:
	return cfg().stones

static func stone(id: String) -> Dictionary:
	for s in stones():
		if str(s.id) == id:
			return s
	return stones()[0] if not stones().is_empty() else {"id": "", "name": "A stone", "grip": 0.7, "drag": 0.02}

static func venues() -> Array:
	return cfg().venues.keys()

static func venue(id: String) -> Dictionary:
	return cfg().venues.get(id, {})

## Power (0 to 1) as a throwing speed in m/s.
static func speed_for(power: float) -> float:
	return 5.0 + 11.0 * clampf(power, 0.0, 1.0)

## One throw: {skips, hops (metres between landings, shortening), distance, sank (why it ended: "steep", "wobble",
## "slow") }. `wobble_scale` below 1 steadies the stone (Easier skimming).
static func skim(st: Dictionary, angle: float, power: float, rng: Rng, wobble_scale := 1.0) -> Dictionary:
	var v := speed_for(power)
	var a := angle
	var skips := 0
	var hops: Array = []
	var total := 0.0
	var why := "slow"
	for i in MAX_SKIPS:
		if a > SINKS_ABOVE:
			why = "steep"
			break
		var off := absf(a - SWEET)
		v *= 1.0 - (0.07 + 0.010 * off + float(st.get("drag", 0.0)))
		if v < MIN_SPEED:
			why = "slow"
			break
		var trip := ((1.0 - float(st.get("grip", 0.7))) * 0.22 + 0.006 * off + 0.015) * wobble_scale
		if rng.roll() < trip:
			why = "wobble"
			break
		skips += 1
		var hop := v * v * sin(deg_to_rad(maxf(a, 4.0)) * 2.0) / 9.81 * 0.8
		hops.append(hop)
		total += hop
		a += 0.8
	if skips >= MAX_SKIPS:
		why = "slow"
	return {"skips": skips, "hops": hops, "distance": total, "sank": why}

## A line the screen can show after a throw, saying why it ended and what to do next.
static func advice(res: Dictionary, angle: float) -> String:
	if int(res.skips) >= 8:
		return "That is a proper skim."
	match str(res.sank):
		"steep":
			return "Too steep: it dug straight in. Lay the stone flatter."
		"wobble":
			if angle < 12.0:
				return "Too flat: it skidded and tripped. Tip it up towards 20 degrees."
			return "It wobbled and tripped. A flatter, thinner stone is steadier."
		_:
			return "It ran out of puff. A harder throw keeps it skipping longer." if angle >= 12.0 else "Too flat, so it lost its speed fast. Aim nearer 20 degrees."

## A local's best of THROWS throws, aiming for the angle and power they favour, with a bit of the hand's wobble.
static func local_best(rival: Dictionary, rng: Rng) -> int:
	var st := stone(str(rival.get("stone", "slate_thin")))
	var best := 0
	for i in THROWS:
		var ang := float(rival.get("angle", 20.0)) + (rng.roll() - 0.5) * 2.0 * float(rival.get("angle_spread", 3.0))
		var pw := clampf(float(rival.get("power", 0.8)) + (rng.roll() - 0.5) * 0.2, 0.2, 1.0)
		best = maxi(best, int(skim(st, ang, pw, rng).skips))
	return best

## Easier skimming: the stone is steadier and the screen shows the sweet spot.
static func wobble_scale(easy: bool) -> float:
	return 0.5 if easy else 1.0

# ---- rewards

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

static func best(data: GameStateData) -> int:
	return TrainerStats.get_count(data, "skims_best")

## Records a finished round: your best skip count and whether you beat the local. Returns {first, money (sterling),
## line, record (true if this is your best ever)}.
static func finish(data: GameStateData, venue_id: String, my_best: int, won: bool) -> Dictionary:
	var record := my_best > best(data)
	if record:
		data.stats["skims_best"] = my_best
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
