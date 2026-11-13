class_name CoracleBoat
extends Node3D
## The player's coracle: a round tarred hull over a wicker frame, a withy rim and a little paddle. It rides the
## surface, bobs on the swell, dips its paddle as you move and leaves rings of ripple behind. Shown only while the
## player is afloat (Player.wading); the rider stands in it, and the hull is the same on a river, a lake or the sea.

const SEGMENTS := 14
const TAR := Color("2f2118")
const WICKER := Color("a07a4c")
const WITHY := Color("7d5c38")
const PADDLE_WOOD := Color("8c6a3f")
const BLADE_WOOD := Color("b99a63")
const BOB_HEIGHT := 0.022
const BOB_SPEED := 2.3         # radians per second
const PADDLE_RATE := 9.0       # radians per second of the stroke while moving
const WAKE_Y := 0.1            # ring height over the boat's origin: the water's surface plus a hair

static var _hull_mesh: ArrayMesh
static var _ring_tex: ImageTexture

var _rider: Node3D             # the player's sprite: lifted and lowered with the swell
var _paddle: Node3D
var _wake: CPUParticles3D
var _t := randf() * 6.0
var _stroke := 0.0

## `rider`: the sprite that stands in the boat (it rises and falls with it).
func setup(rider: Node3D) -> void:
	_rider = rider
	var hull := MeshInstance3D.new()
	hull.mesh = _hull()
	hull.material_override = _hull_material()
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hull)
	_paddle = _make_paddle()
	add_child(_paddle)
	visible = false
	set_process(false)

## Afloat or not: the boat appears with the ripples, and stops costing anything when it is away.
func set_afloat(v: bool) -> void:
	visible = v
	set_process(v)
	if v and _wake == null and Settings.quality != "low":
		_wake = _make_wake()
		get_parent().add_child(_wake)
	if _wake:
		_wake.emitting = v
	if not v and _rider:
		_rider.position.y = 0.0

func _process(delta: float) -> void:
	_t += delta
	var pl := get_parent() as Player
	var going := pl != null and pl.moving
	var swell := sin(_t * BOB_SPEED)
	position.y = swell * BOB_HEIGHT
	rotation.z = sin(_t * 1.7) * 0.025
	rotation.x = cos(_t * 1.3) * 0.025
	if _rider:
		_rider.position.y = position.y + 0.02
		if pl:
			pl.sprite.walking = false  # a rider stands; the paddle does the work
	_stroke += delta * (PADDLE_RATE if going else 1.2)
	_paddle.rotation.x = sin(_stroke) * (0.5 if going else 0.06)
	if _wake:
		_wake.speed_scale = 1.5 if going else 0.35

# --- the hull: a lathe over a profile, flat-shaded in vertex colours -----------------

## (radius, height, colour): up the outside from the keel, over the rim, and down the inside to the floor.
static func _profile() -> Array:
	return [
		[0.0, -0.1, TAR], [0.2, -0.095, TAR], [0.33, -0.05, TAR], [0.41, 0.04, TAR], [0.45, 0.16, TAR],
		[0.45, 0.21, WITHY], [0.39, 0.21, WITHY],
		[0.39, 0.12, WICKER], [0.32, 0.04, WICKER], [0.2, 0.0, WICKER], [0.0, 0.0, WICKER]]

static func _hull() -> ArrayMesh:
	if _hull_mesh != null:
		return _hull_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prof := _profile()
	for i in prof.size() - 1:
		var a: Array = prof[i]
		var b: Array = prof[i + 1]
		for s in SEGMENTS:
			var a0 := TAU * s / SEGMENTS
			var a1 := TAU * (s + 1) / SEGMENTS
			var col: Color = (b[2] as Color).lerp(a[2], 0.5)
			col = col.darkened(0.12 * (0.5 + 0.5 * sin(a0 * 2.0)))  # withies catch the light unevenly
			var p00 := Vector3(cos(a0) * a[0], a[1], sin(a0) * a[0])
			var p10 := Vector3(cos(a1) * a[0], a[1], sin(a1) * a[0])
			var p01 := Vector3(cos(a0) * b[0], b[1], sin(a0) * b[0])
			var p11 := Vector3(cos(a1) * b[0], b[1], sin(a1) * b[0])
			for v in [p00, p10, p11, p00, p11, p01]:
				st.set_color(col)
				st.add_vertex(v)
	st.generate_normals()
	_hull_mesh = st.commit()
	return _hull_mesh

static func _hull_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.85
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

## A paddle held out over the right-hand rim: pivots at the hand, blade in the water.
static func _make_paddle() -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(0.44, 0.24, 0.0)
	var arm := Node3D.new()  # tipped outwards so the blade clears the hull
	arm.rotation.z = 0.62
	pivot.add_child(arm)
	var shaft := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.014
	c.bottom_radius = 0.014
	c.height = 0.5
	c.radial_segments = 6
	shaft.mesh = c
	shaft.position = Vector3(0, -0.2, 0)
	shaft.material_override = _flat(PADDLE_WOOD)
	arm.add_child(shaft)
	var blade := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.1, 0.17, 0.02)
	blade.mesh = b
	blade.position = Vector3(0, -0.5, 0)
	blade.material_override = _flat(BLADE_WOOD)
	arm.add_child(blade)
	for n in [shaft, blade]:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pivot

static func _flat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	return m

# --- the wake: flat rings that spread and fade where the boat has been --------------

static func _ring_texture() -> ImageTexture:
	if _ring_tex != null:
		return _ring_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n / 2.0, y + 0.5 - n / 2.0).length() / (n / 2.0)
			var a := clampf(1.0 - absf(d - 0.78) / 0.14, 0.0, 1.0)  # a soft ring near the rim
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	_ring_tex = ImageTexture.create_from_image(img)
	return _ring_tex

func _make_wake() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "CoracleWake"
	p.amount = 7
	p.lifetime = 1.4
	p.local_coords = false          # the rings stay where the boat left them
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
	p.direction = Vector3.UP
	p.spread = 0.0
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.gravity = Vector3.ZERO
	p.position = Vector3(0, WAKE_Y, 0)
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.6))
	grow.add_point(Vector2(1, 2.4))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.92, 0.98, 1.0, 0.0), Color(0.92, 0.98, 1.0, 0.5), Color(0.92, 0.98, 1.0, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	p.color_ramp = fade
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.5)
	q.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _ring_texture()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	p.mesh = q
	p.emitting = false
	return p
