class_name WellyWang
extends RefCounted
## Welly wanging (Upperthong near Holmfirth, West Yorkshire): hold to spin the boot round your head, let go in the
## gap, mind the wind. Pure maths and rewards (no autoload names); ui/welly_wang_screen.gd draws it and the story
## command {"do": "wang"} (story/contest_run.gd) pays it out. Distinct from the village-fete power-and-angle welly
## (core/fete.gd): this one is about timing the release in the swing.

const PATH := "res://data/welly_wang.json"
const THROWS := 3
const IDEAL := 42.0            # degrees above horizontal the boot should leave at
const WINDOW := 12.0           # half-width of the gap in the swing the UI marks
const DIZZY_ABOVE := 0.86      # spin past this and your aim goes
const SPIN_RATE := 0.45        # fraction of full spin gained per second held
const FLAG_PREFIX := "wang_"
const FLAG_DAY := "wang_day_"
const DAILY_PURSE := 3
const STAT := "welly_best"
const GAME_ID := "welly_wang"
const GRAVITY := 9.81

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"venues": {}}
	return _cfg

static func venue(id: String) -> Dictionary:
	return cfg().venues.get(id, {})

## A new wind in m/s along the pitch: positive is a tail wind. Calm to a stiff breeze, Pennine-ish.
static func wind(rng: Rng) -> float:
	return snappedf((rng.roll() - 0.45) * 12.0, 0.5)

static func wind_label(w: float) -> String:
	if absf(w) < 0.75:
		return "Still air"
	return "%s %.1f m/s" % ["Tail wind" if w > 0.0 else "Head wind", absf(w)]

## Launch speed for a spin (0 to 1).
static func speed_for(spin: float) -> float:
	return 7.0 + 14.0 * clampf(spin, 0.0, 1.0)

## Where the boot is in the swing, in degrees, `t` seconds after the spin starts at `spin` (turns faster as it builds).
static func swing_angle(t: float, spin: float) -> float:
	return fposmod(t * (110.0 + 130.0 * spin), 360.0)

## How the swing angle (0 = out in front at ground level, 90 = straight up) becomes a release elevation: only the
## upswing in front of you (0 to 90) throws forwards; the rest goes behind you or into the ground.
static func elevation(swing: float) -> float:
	return swing if swing <= 90.0 else -1.0

## One throw: {metres, foul (released behind or low), dizzy, quality (0..1 how close to the gap)}. `jitter` is the
## dizzy wobble in degrees, supplied by the caller's rng so this stays deterministic for tests.
static func wang(spin: float, swing: float, wind_ms: float, jitter := 0.0) -> Dictionary:
	var el := elevation(swing)
	var dizzy := spin > DIZZY_ABOVE
	if el < 0.0:
		return {"metres": 0.0, "foul": true, "dizzy": dizzy, "quality": 0.0}
	var v := speed_for(spin)
	if dizzy:
		# past the dizzy line the aim wobbles and the legs go: the extra spin is more than lost, so holding on for
		# a full spin and letting go giddy never beats a clean release just under the line
		el = clampf(el + jitter, 1.0, 89.0)
		v = speed_for(DIZZY_ABOVE) * 0.9
	var rad := deg_to_rad(el)
	var flight := 2.0 * v * sin(rad) / GRAVITY
	var m := v * cos(rad) * flight * 0.78 + wind_ms * flight * 0.45
	m = maxf(0.0, snappedf(m, 0.1))
	var q := clampf(1.0 - absf(el - IDEAL) / 45.0, 0.0, 1.0)
	return {"metres": m, "foul": false, "dizzy": dizzy, "quality": q}

static func advice(res: Dictionary, spin: float) -> String:
	if bool(res.foul):
		return "Let go too late: it went out the back, towards the tea tent."
	if bool(res.dizzy):
		return "Too dizzy to aim. Spin fast, not frantic."
	if float(res.quality) > 0.85:
		return "Clean release, right in the gap."
	if spin < 0.5:
		return "Not enough spin. Hold longer before you let go."
	return "A touch early or late. Let go as the boot passes the marked gap."

## A local's best of THROWS: they favour a spin and angle, a bit of wobble, a random wind.
static func local_best(rival: Dictionary, rng: Rng) -> float:
	var best := 0.0
	for i in THROWS:
		var sp := clampf(float(rival.get("speed", 0.8)) + (rng.roll() - 0.5) * 0.16, 0.2, DIZZY_ABOVE)
		var ang := float(rival.get("angle", 42.0)) + (rng.roll() - 0.5) * 2.0 * float(rival.get("angle_spread", 5.0))
		best = maxf(best, float(wang(sp, clampf(ang, 1.0, 89.0), wind(rng))["metres"]))
	return best

# ---- rewards

static func beaten(data: GameStateData, venue_id: String) -> bool:
	return data.flag(FLAG_PREFIX + venue_id) == true

static func best(data: GameStateData) -> int:
	return TrainerStats.get_count(data, STAT)

static func finish(data: GameStateData, venue_id: String, my_best: float, won: bool) -> Dictionary:
	var record := int(my_best) > best(data)
	if record:
		data.stats[STAT] = int(my_best)
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

## Easier minigames: the release is pulled 40% of the way towards the ideal elevation, and the gap shown is wider.
static func assist(swing: float, easy: bool) -> float:
	if not easy or swing > 90.0:
		return swing
	return IDEAL + (swing - IDEAL) * 0.6
