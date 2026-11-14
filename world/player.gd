class_name Player
extends Node3D
## The player on the grid. Reads input unless Router is busy; asks the overworld whether a step is allowed.

const WALK_SPEED := 4.0   # tiles per second
const RUN_SPEED := 7.0
const BIKE_SPEED := 9.0
const TURN_GRACE := 0.09  # a quick tap turns on the spot, holding walks
const PADDLE_SPEED := 5.0 # a coracle at a brisk stroke (the run key); easy paddling is WALK_SPEED
const HOP_SECS := 0.35    # a ledge hop, two tiles

signal step_finished(p: Vector2i)
## A step has just begun from `from` to `to` (two tiles for a ledge hop). The follower takes its own step on this,
## and reads step_fraction() each frame to stay in time with it.
signal step_started(from: Vector2i, to: Vector2i)

var grid_pos := Vector2i.ZERO
var facing := "down"
var moving := false
var overworld: Node
var sprite: CharSprite
var _held_dir := ""
var _held_t := 0.0
var _bump_cooldown := 0.0
## The playtest bot sets this to drive the player without real input.
var forced_dir := ""
var on_bike := false
var _run_latched := false   # run mode "toggle": running stays on until the run key is pressed again
var wading := false
var _bike: Node3D
var _coracle: CoracleBoat
var _was_running := false   # for the dust puff on breaking into a run
var _dust: CPUParticles3D
# the step under way: advanced in _process (not a tween) so a held direction runs straight on into the next step
# with the frame's spare time, instead of standing still for a frame between steps
var _step_to := Vector2i.ZERO
var _step_start := Vector3.ZERO
var _step_dest := Vector3.ZERO
var _step_secs := 1.0
var _step_t := 0.0
var _step_hop := false

func setup(ow: Node, sprite_id: String) -> void:
	overworld = ow
	sprite = CharSprite.new()
	add_child(sprite)
	sprite.setup(sprite_id)
	_bike = _make_bike()
	add_child(_bike)
	_coracle = CoracleBoat.new()
	add_child(_coracle)
	_coracle.setup(sprite)
	_refresh_ride()

## A little bicycle under the sprite: two wheels and a frame, turned with the rider (see face).
func _make_bike() -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("2f6b8a")
	for x in [-0.28, 0.28]:
		var w := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.13
		t.outer_radius = 0.17
		w.mesh = t
		w.rotation_degrees = Vector3(90, 0, 0)
		w.position = Vector3(x, 0.17, 0.05)
		w.material_override = mat
		root.add_child(w)
	var frame := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.56, 0.05, 0.05)
	frame.mesh = b
	frame.position = Vector3(0, 0.3, 0.05)
	frame.material_override = mat
	root.add_child(frame)
	return root

func set_bike(v: bool) -> void:
	on_bike = v
	_refresh_ride()

func set_wading(v: bool) -> void:
	wading = v
	_refresh_ride()

func _refresh_ride() -> void:
	if _bike:
		_bike.visible = on_bike
	if _coracle:
		_coracle.set_afloat(wading)

func place(p: Vector2i, dir: String, y: float) -> void:
	grid_pos = p
	position = Vector3(p.x + 0.5, y, p.y + 0.5)
	face(dir)

func face(dir: String) -> void:
	facing = dir
	if sprite:
		sprite.set_facing(dir)
	if _bike:
		_bike.rotation_degrees.y = 90.0 if dir in ["up", "down"] else 0.0  # end-on up and down the screen, side-on across it

## Run mode "toggle": a fresh press of the run key flips the latch. "hold" never latches.
static func next_run_latch(mode: String, latched: bool, pressed: bool) -> bool:
	if mode != "toggle":
		return false
	return not latched if pressed else latched

static func is_running(mode: String, latched: bool, held: bool) -> bool:
	return latched if mode == "toggle" else held

## Back outdoors after riding in: hop back on the bike if it is allowed here (`refusal` from FieldMoves.bike_refusal).
static func resume_bike(rode_in: bool, refusal: String) -> bool:
	return rode_in and refusal == ""

func busy() -> bool:
	return moving or Router.busy

func _physics_process(delta: float) -> void:
	_bump_cooldown = maxf(0.0, _bump_cooldown - delta)
	if forced_dir == "" and not Router.busy:  # (presses mid-step still count)
		_run_latched = next_run_latch(Settings.run_mode, _run_latched, Input.is_action_just_pressed("run"))
	if busy():
		return
	if forced_dir == "" and Input.is_action_just_pressed("confirm"):
		overworld.interact(GridMotion.step(grid_pos, facing))
		return
	if forced_dir == "" and Input.is_action_just_pressed("menu"):
		overworld.open_pause()
		return
	if forced_dir == "" and Input.is_action_just_pressed("bike") and overworld.has_method("toggle_bike"):
		overworld.toggle_bike()
		return
	if forced_dir == "" and Input.is_action_just_pressed("photo"):
		PhotoMode.start(overworld)
		return
	if forced_dir == "" and Input.is_action_just_pressed("fly") and overworld.has_method("try_fly"):
		overworld.try_fly()
		return
	var dir := forced_dir if forced_dir != "" else _input_dir()
	if dir == "":
		_held_dir = ""
		_held_t = 0.0
		sprite.walking = false
		_was_running = false
		return
	if dir != _held_dir:
		_held_dir = dir
		_held_t = 0.0
		if dir != facing and forced_dir == "":
			face(dir)
			return
	_held_t += delta
	if dir != facing:
		face(dir)
	if forced_dir == "" and _held_t < TURN_GRACE and not sprite.walking:
		return
	try_step(dir, is_running(Settings.run_mode, _run_latched, Input.is_action_pressed("run")))

func _input_dir() -> String:
	for d in ["up", "down", "left", "right"]:
		if Input.is_action_pressed("move_" + d):
			return d
	return ""

## A little puff of dust kicked up on breaking into a run (not on Low quality).
func _puff() -> void:
	if Settings.quality == "low":
		return
	if _dust == null:
		_dust = CPUParticles3D.new()
		_dust.one_shot = true
		_dust.emitting = false
		_dust.amount = 8
		_dust.lifetime = 0.5
		_dust.explosiveness = 0.85
		_dust.direction = Vector3(0, 1, 0)
		_dust.spread = 70.0
		_dust.initial_velocity_min = 0.35
		_dust.initial_velocity_max = 0.7
		_dust.gravity = Vector3(0, 0.3, 0)
		_dust.damping_min = 1.0
		_dust.damping_max = 1.5
		var grow := Curve.new()
		grow.add_point(Vector2(0, 0.5))
		grow.add_point(Vector2(1, 1.3))
		_dust.scale_amount_curve = grow
		var fade := Gradient.new()
		fade.colors = PackedColorArray([Color(0.82, 0.76, 0.66, 0.7), Color(0.82, 0.76, 0.66, 0.0)])
		_dust.color_ramp = fade
		var q := QuadMesh.new()
		q.size = Vector2(0.22, 0.22)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.vertex_color_use_as_albedo = true
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.albedo_texture = SkyAndLight._soft_texture()
		q.material = m
		_dust.mesh = q
		_dust.position = Vector3(0, 0.08, 0)
		add_child(_dust)
	_dust.restart()

## Attempts one step. Returns false (and bumps) if blocked.
## A ledge hop: straight line from start to dest with a small arc on top (no drift).
static func hop_pos(start: Vector3, dest: Vector3, t: float) -> Vector3:
	return start.lerp(dest, t) + Vector3(0, sin(t * PI) * 0.35, 0)

func try_step(dir: String, running := false) -> bool:
	face(dir)
	var target := GridMotion.step(grid_pos, dir)
	var verdict: String = overworld.can_enter(target, GridMotion.dir_vec(dir))
	if verdict == "cut":
		overworld.cut_bramble(target)
		return false
	if verdict == "push":
		overworld.push_crate(target, GridMotion.dir_vec(dir))  # then the tile is free to step into
		verdict = "ok"
	if verdict == "blocked":
		sprite.walking = false
		if _bump_cooldown <= 0.0:
			Audio.sfx("bump")
			_bump_cooldown = 0.35
		if overworld.has_method("blocked_hint"):
			overworld.blocked_hint(target)
		return false
	if verdict == "ok" and overworld.has_method("door_ahead"):
		overworld.door_ahead(target)  # a building's door swings open as you step up to it
	moving = true
	sprite.walking = true
	var run_on_foot := running and not on_bike and not wading
	sprite.walk_rate = CharSprite.RUN_RATE if run_on_foot else CharSprite.WALK_RATE
	if run_on_foot and not _was_running and verdict != "ledge":
		_puff()
	_was_running = run_on_foot
	var speed := BIKE_SPEED if on_bike else ((PADDLE_SPEED if wading else RUN_SPEED) if running else WALK_SPEED)
	var secs := 1.0 / speed
	var hop := verdict == "ledge"
	if hop:
		target = target + GridMotion.dir_vec(dir)
		secs = HOP_SECS
	var from := grid_pos
	_step_to = target
	_step_start = position
	_step_dest = Vector3(target.x + 0.5, overworld.ground_y(target), target.y + 0.5)
	_step_secs = secs
	_step_t = 0.0
	_step_hop = hop
	step_started.emit(from, target)
	await step_finished
	return true

## How far through the step under way (0..1); 1 when standing still.
func step_fraction() -> float:
	return clampf(_step_t / _step_secs, 0.0, 1.0) if moving else 1.0

func _step_pos(t: float) -> Vector3:
	return Player.hop_pos(_step_start, _step_dest, t) if _step_hop else _step_start.lerp(_step_dest, t)

func _process(delta: float) -> void:
	if moving:
		_advance(delta)

## Moves the step under way on by `delta` seconds. At the end of it, a direction still held carries straight on
## into the next step with whatever time is left over, so a long walk is one smooth glide.
func _advance(delta: float) -> void:
	_step_t += delta
	if _step_t < _step_secs:
		position = _step_pos(_step_t / _step_secs)
		return
	var spare := _step_t - _step_secs
	position = _step_dest
	grid_pos = _step_to
	moving = false
	var held := forced_dir if forced_dir != "" else _input_dir()
	if held == "":
		sprite.walking = false
	step_finished.emit(grid_pos)
	if held != "" and not busy():
		_keep_walking(held, spare)

func _keep_walking(dir: String, spare: float) -> void:
	_held_dir = dir
	try_step(dir, is_running(Settings.run_mode, _run_latched, Input.is_action_pressed("run")))
	if moving:  # carry the spare time over (never a whole step: a long hitch just loses it)
		_step_t = minf(spare, _step_secs * 0.5)
		position = _step_pos(_step_t / _step_secs)
