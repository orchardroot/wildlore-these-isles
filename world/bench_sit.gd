class_name BenchSit
extends Node
## Sit down (wave 54). Face a bench and press confirm: you settle onto it, the camera eases in, and the clock runs
## fast so dusk comes on, the lamps light and the windows glow. Any key stands you up again. The fast clock is
## capped: DAY_CAP game minutes a day, never across midnight, so a bench is for watching the evening, not for
## skipping days. The playtest bot never sits. While you sit the world is busy (nobody wanders, the pause menu waits).

const SEAT := 0.17            # how far above the ground you sit
const SETTLE_SECS := 0.4
const ZOOM := 0.8             # camera distance while seated
const BOOST := 15.0           # game minutes per second while the clock is fast
const SIT_CAP := 240          # game minutes one sitting can speed through
const DAY_CAP := 360          # game minutes a day can be sped through, all sittings together
const MIDNIGHT_GUARD := 1425  # no fast clock past 23:45, so the day never turns over faster than it should
const DEAF_SECS := 0.35       # ignore keys this long, so the press that sat you down doesn't stand you straight up
const MAX_SECS := 300.0       # and a long sit ends by itself

static var sitting := false
static var _day := -1         # the day_count _used belongs to
static var _used := 0         # game minutes sped through that day

var _ow: Node
var _bench: Vector2i
var _stand_at := Vector3.ZERO
var _t := 0.0
var _start_minute := 0
var _gained_before := 0
var _hint: CanvasLayer
var _tween: Tween
var _standing := false

# --- rules (pure, tested) ------------------------------------------------------------

## The bench prop standing on `p`, or {}.
static func bench_at(props: Array, p: Vector2i) -> Dictionary:
	for pr in props:
		if str(pr.get("type", "")) == "bench" and int(pr.get("x", -1)) == p.x and int(pr.get("y", -1)) == p.y:
			return pr
	return {}

## Game minutes still allowed on the fast clock: this sitting's share of the day's allowance, `gained` so far.
static func boost_left(used_today: int, gained_this_sit: int) -> int:
	return maxi(0, mini(SIT_CAP - gained_this_sit, DAY_CAP - used_today - gained_this_sit))

## Should the clock still run fast? Not past the allowance, not near midnight.
static func fast_clock(used_today: int, gained_this_sit: int, minute_of_day: int) -> bool:
	return boost_left(used_today, gained_this_sit) > 0 and minute_of_day < MIDNIGHT_GUARD

## Minutes passed between two clock readings in the same day (0 if it wrapped).
static func minutes_between(from_min: int, to_min: int) -> int:
	return maxi(0, to_min - from_min)

## A key, button or click that stands you up.
static func is_stand_event(e: InputEvent) -> bool:
	if e is InputEventKey:
		return e.pressed and not e.echo
	if e is InputEventMouseButton or e is InputEventJoypadButton:
		return e.pressed
	return false

# --- in the world ------------------------------------------------------------------------

## Facing a bench and pressing confirm. True when it was one (and you sat).
static func interact(ow: Node, p: Vector2i) -> bool:
	if sitting or ow.zone == null or bench_at(ow.zone.props, p).is_empty():
		return false
	if Engine.has_meta("autopilot") or ow.player.on_bike or ow.player.wading or ow.player.moving:
		return false
	var s := BenchSit.new()
	s.name = "BenchSit"
	ow.add_child(s)
	s._sit(ow, p)
	return true

func _sit(ow: Node, p: Vector2i) -> void:
	_ow = ow
	_bench = p
	sitting = true
	Router.busy = true
	var pl: Player = ow.player
	_stand_at = pl.position
	if Game.data.day_count != _day:
		_day = Game.data.day_count
		_used = 0
	_start_minute = Game.data.clock_minutes
	pl.sprite.walking = false
	pl.face("down")
	var seat := Vector3(p.x + 0.5, ow.ground_y(p) + SEAT, p.y + 0.5)
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(pl, "position", seat, SETTLE_SECS).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(pl.sprite, "scale:y", 0.88, SETTLE_SECS)
	if ow.rig:
		_tween.tween_property(ow.rig, "_zoom", ZOOM, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_make_hint()
	Game.time_boost = BOOST

func _make_hint() -> void:
	_hint = CanvasLayer.new()
	_hint.layer = 55
	var l := Label.new()
	l.text = "Sitting a while. Press any key to get up."
	l.add_theme_font_size_override("font_size", Access.scaled(22, Settings.text_size))
	l.add_theme_color_override("font_color", Color(0.949, 0.91, 0.812))
	l.add_theme_color_override("font_outline_color", Color(0.114, 0.133, 0.188))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_top = -64
	l.offset_bottom = -24
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_child(l)
	add_child(_hint)

func _process(delta: float) -> void:
	_t += delta
	if _standing:
		return
	var gained := minutes_between(_start_minute, Game.data.clock_minutes)
	if Game.time_boost > 1.0 and not fast_clock(_used, gained, Game.data.clock_minutes):
		Game.time_boost = 1.0  # the evening has played out as far as it may
	if _t > MAX_SECS or not is_instance_valid(_ow) or _ow.zone == null:
		stand()

func _input(e: InputEvent) -> void:
	if _t > DEAF_SECS and not _standing and is_stand_event(e):
		get_viewport().set_input_as_handled()
		stand()

## Back onto your feet, on the tile you sat down from.
func stand() -> void:
	if _standing:
		return
	_standing = true
	Game.time_boost = 1.0
	_used += minutes_between(_start_minute, Game.data.clock_minutes)
	if _hint:
		_hint.queue_free()
	if _tween:
		_tween.kill()
	if not is_instance_valid(_ow):
		_finish()
		return
	var pl: Player = _ow.player
	var tw := create_tween().set_parallel(true)
	tw.tween_property(pl, "position", _stand_at, SETTLE_SECS).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pl.sprite, "scale:y", 1.0, SETTLE_SECS)
	if _ow.rig:
		tw.tween_property(_ow.rig, "_zoom", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_finish()

func _finish() -> void:
	sitting = false
	Router.busy = false
	queue_free()

func _exit_tree() -> void:
	if sitting:  # torn down mid-sit (a whiteout, a scene change): leave nothing stuck
		sitting = false
		Game.time_boost = 1.0
