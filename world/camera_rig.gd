class_name CameraRig
extends Node3D
## HD-2D camera: narrow-FOV perspective looking down at about 35 degrees, following the player smoothly
## with a little lead, clamped so the void outside the zone stays off screen.
## Feel: a very slight drift once you have stood still a few seconds, a settle (and a glide, where the zone
## leaves room) as you cross into the next zone, and a lean toward a trainer who has just spotted you.

const PITCH := 35.0
const IDLE_AFTER := 4.0       # seconds standing still before the drift starts
const IDLE_RAMP := 2.5        # seconds for the drift to fade in
const EDGE_GLIDE := 1.6       # tiles behind you the camera starts from, crossing a zone edge
const EDGE_ZOOM := 1.04       # and a little further out, settling back in (inside the clamp's 5% slack)
const NUDGE_ZOOM := 0.9       # spotted: tighten in this much
const NUDGE_REACH := 0.35     # and lean this share of the way toward the trainer
const NUDGE_MAX := 1.6
var distance := 21.0
var fov := 30.0
var target: Node3D
var bounds := Rect2(0, 0, 10, 10)
var camera: Camera3D
var _lead := Vector3.ZERO
var _idle_t := 0.0
var _clock := 0.0
var _nudge := Vector3.ZERO
var _zoom := 1.0
var _applied_zoom := 1.0
var photo := Vector3(0, 0, 1)   # photo mode: yaw and pitch change in degrees, and a zoom factor (see PhotoMode)
var _applied_photo := Vector3(0, 0, 1)
var _tween: Tween

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = fov
	camera.near = 0.3
	camera.far = 120.0
	add_child(camera)
	camera.current = true
	_apply_offset()

func configure(zone_w: int, zone_h: int, interior: bool) -> void:
	bounds = Rect2(0, 0, zone_w, zone_h)
	distance = 12.0 if interior else 21.0
	fov = 32.0 if interior else 30.0
	if camera:
		camera.fov = fov
		_apply_offset()
	snap()

func _apply_offset() -> void:
	var p := deg_to_rad(PITCH + photo.y)
	var yaw := deg_to_rad(photo.x)
	var dist := distance * _zoom * photo.z
	camera.position = Vector3(sin(yaw) * cos(p) * dist, sin(p) * dist, cos(yaw) * cos(p) * dist)
	camera.rotation = Vector3(-p, yaw, 0)
	_applied_zoom = _zoom
	_applied_photo = photo

func snap() -> void:
	_idle_t = 0.0
	_nudge = Vector3.ZERO
	if _tween and _tween.is_valid():
		_tween.kill()
	_zoom = 1.0
	if camera:
		_apply_offset()
	if target:
		global_position = _clamped(target.global_position)

## A very slight wander once the player has stood still IDLE_AFTER seconds (`idle_t`), easing in. `t` is a clock.
static func idle_drift(idle_t: float, t: float) -> Vector3:
	if idle_t <= IDLE_AFTER:
		return Vector3.ZERO
	var k := clampf((idle_t - IDLE_AFTER) / IDLE_RAMP, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	return Vector3(sin(t * 0.37) * 0.16 + sin(t * 0.13 + 0.7) * 0.07, 0.0, sin(t * 0.29 + 1.3) * 0.11) * k

## Where the camera starts (from where it would sit) on walking into a new zone facing `facing`: a little behind.
static func edge_offset(facing: String) -> Vector3:
	var d := GridMotion.dir_vec(facing)
	return -Vector3(d.x, 0, d.y) * EDGE_GLIDE

## Spotted at `from` by someone at `to`: lean part of the way toward them, never far.
static func nudge_offset(from: Vector3, to: Vector3) -> Vector3:
	var o := Vector3(to.x - from.x, 0, to.z - from.z) * NUDGE_REACH
	return o.limit_length(NUDGE_MAX)

## Just crossed a zone edge (the zone is built and the camera snapped): glide in from behind and settle.
func arrive(facing: String) -> void:
	if target == null:
		return
	global_position = _clamped(target.global_position + edge_offset(facing))
	_zoom = EDGE_ZOOM
	_apply_offset()
	_tween = create_tween()
	_tween.tween_property(self, "_zoom", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## A trainer at `at` has spotted the player: lean in and tighten for `hold` seconds, then ease back.
func nudge(at: Vector3, hold := 0.7) -> void:
	if target == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "_nudge", nudge_offset(target.global_position, at), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_zoom", NUDGE_ZOOM, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_interval(hold)
	_tween.chain().tween_property(self, "_nudge", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_property(self, "_zoom", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	if target == null:
		return
	_clock += delta
	if _zoom != _applied_zoom or photo != _applied_photo:
		_apply_offset()
	var want := target.global_position
	var walking: bool = target is Player and target.moving
	if walking:
		_lead = _lead.lerp(Vector3(GridMotion.dir_vec(target.facing).x, 0, GridMotion.dir_vec(target.facing).y) * 0.8, delta * 3.0)
	else:
		_lead = _lead.lerp(Vector3.ZERO, delta * 2.0)
	if walking or Router.busy:
		_idle_t = 0.0
	else:
		_idle_t += delta
	global_position = global_position.lerp(_clamped(want + _lead + _nudge + idle_drift(_idle_t, _clock)), 1.0 - exp(-delta * 6.0))

func _clamped(p: Vector3) -> Vector3:
	return clamp_to(bounds, p, distance, fov)

## Where the rig sits following a player at `p` in a zone `bounds` (tiles), and where its eye is: the signs ask
## this to read their fronts as you will see them.
static func clamp_to(bounds: Rect2, p: Vector3, distance := 21.0, fov := 30.0) -> Vector3:
	var half_w := distance * tan(deg_to_rad(fov) * 0.5) * (16.0 / 9.0) * 0.95
	var x := p.x
	if bounds.size.x > half_w * 2.0:
		x = clampf(p.x, bounds.position.x + half_w, bounds.end.x - half_w)
	else:
		x = bounds.get_center().x
	var near_margin := distance * 0.22
	var far_margin := distance * 0.32
	var z := p.z
	if bounds.size.y > near_margin + far_margin:
		z = clampf(p.z, bounds.position.y + far_margin, bounds.end.y - near_margin)
	else:
		z = bounds.get_center().y
	return Vector3(x, p.y, z)

static func eye_for(bounds: Rect2, p: Vector3, distance := 21.0) -> Vector3:
	var a := deg_to_rad(PITCH)
	return clamp_to(bounds, p, distance) + Vector3(0, sin(a) * distance, cos(a) * distance)
