class_name Footfalls
extends Node3D
## The ground answers your feet (wave 54). Tall grass and flowers part round the player (a shader nudge on the shared
## foliage material) and a few blades fly up as you push through; the shallows ripple; sand takes footprints, and so
## does frost. All of it from a small pool made once per overworld: nothing is allocated while you walk. Off on Low.

const POOL := 10                # prints and ripples alive at once; the oldest is recycled
const PRINT_SECS := 7.0
const RIPPLE_SECS := 1.1
const FROST_WEATHER := "frost"
const FROSTY := ["grass", "tall_grass", "path", "flowers", "cobbles"]
const RUSTLES := ["tall_grass", "flowers"]
const PRINT_COL := {"sand": Color(0.45, 0.36, 0.22), "frost": Color(0.27, 0.34, 0.27)}
const PRINT_ALPHA := {"sand": 0.5, "frost": 0.42}

var _ow: Node
var _pool: Array[MeshInstance3D] = []
var _mats: Array[StandardMaterial3D] = []
var _age := PackedFloat32Array()    # seconds since laid; negative = free
var _life := PackedFloat32Array()   # how long each lives
var _kind: Array[String] = []       # "ripple" or a PRINT_COL key
var _next := 0
var _left_foot := false
var _blades: CPUParticles3D
var _pushed := Vector2(-1000.0, -1000.0)
var _push_on := false
static var _ring_tex: Texture2D
static var _print_tex: Texture2D

## The overworld's one hook: called after each zone is built. Reuses the node between zones.
static func attach(ow: Node) -> Footfalls:
	var f: Footfalls = ow.get_node_or_null("Footfalls")
	if f == null:
		f = Footfalls.new()
		f.name = "Footfalls"
		ow.add_child(f)
		f._ow = ow
		f._make_pool()
		ow.stepped.connect(f._on_step)
		Bus.settings_changed.connect(f._settings)
	f._ow = ow
	f._clear()
	return f

# --- rules (pure, tested) ------------------------------------------------------------

## What this tile and weather leave behind: "rustle", "ripple", "sand", "frost" or "".
static func trace_for(tile: String, weather: String) -> String:
	if tile == "shallow":
		return "ripple"
	if tile == "sand":
		return "sand"
	if weather == FROST_WEATHER and tile in FROSTY:
		return "frost"
	return ""

static func rustles(tile: String) -> bool:
	return tile in RUSTLES

static func active(quality: String, interior: bool) -> bool:
	return quality != "low" and not interior

## 0..1 through its life, for fading: 1 fresh, 0 gone.
static func fade(age: float, life: float) -> float:
	return clampf(1.0 - age / maxf(life, 0.01), 0.0, 1.0)

static func next_slot(i: int, n: int) -> int:
	return (i + 1) % n

# --- nodes -----------------------------------------------------------------------------

static func _textures() -> void:
	if _ring_tex != null:
		return
	var ring := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 15.5
			var a := clampf(1.0 - absf(d - 0.78) / 0.16, 0.0, 1.0)
			ring.set_pixel(x, y, Color(1, 1, 1, a * a))
	_ring_tex = ImageTexture.create_from_image(ring)
	var pr := Image.create(16, 16, false, Image.FORMAT_RGBA8)  # a boot sole: a long oval, a touch wider at the toe
	for y in 16:
		for x in 16:
			var dx := (x - 7.5) / (3.2 + (1.0 if y < 7 else 0.0))
			var dy := (y - 7.5) / 7.0
			pr.set_pixel(x, y, Color(1, 1, 1, 1.0 if dx * dx + dy * dy <= 1.0 else 0.0))
	_print_tex = ImageTexture.create_from_image(pr)

func _make_pool() -> void:
	_textures()
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	for i in POOL:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_texture = _print_tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = m
		mi.rotation_degrees.x = -90.0
		mi.visible = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_pool.append(mi)
		_mats.append(m)
		_kind.append("")
	_age.resize(POOL)
	_life.resize(POOL)
	_age.fill(-1.0)
	_life.fill(1.0)
	_blades = CPUParticles3D.new()
	_blades.emitting = false
	_blades.one_shot = true
	_blades.amount = 6
	_blades.lifetime = 0.5
	_blades.explosiveness = 0.9
	_blades.direction = Vector3(0, 1, 0)
	_blades.spread = 55.0
	_blades.initial_velocity_min = 0.7
	_blades.initial_velocity_max = 1.3
	_blades.gravity = Vector3(0, -4.5, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.1)
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color("6e9c45")
	bm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = bm
	_blades.mesh = q
	add_child(_blades)

func _clear() -> void:
	for i in POOL:
		_age[i] = -1.0
		_pool[i].visible = false
	_set_push(false)
	set_process(_on())

func _on() -> bool:
	return _ow != null and _ow.zone != null and active(Settings.quality, _ow.zone.kind == "interior")

func _settings() -> void:
	_clear()

func _on_step(p: Vector2i, tile: String) -> void:
	if not _on() or _ow.player.on_bike or not _ow.player.visible:
		return
	var y: float = _ow.ground_y(p)
	var trace := trace_for(tile, str(_ow.weather))
	if rustles(tile):
		_blades.position = Vector3(p.x + 0.5, y + 0.2, p.y + 0.5)
		_blades.restart()
	match trace:
		"ripple":
			_lay("ripple", Vector3(p.x + 0.5, y + 0.03, p.y + 0.5), 0.0, RIPPLE_SECS)
		"sand", "frost":
			var f: Vector2i = GridMotion.dir_vec(_ow.player.facing)
			var side := Vector3(-f.y, 0, f.x) * (0.13 if _left_foot else -0.13)
			_left_foot = not _left_foot
			var yaw := rad_to_deg(atan2(float(f.x), float(f.y)))
			_lay(trace, Vector3(p.x + 0.5, y + 0.02, p.y + 0.5) + side, yaw, PRINT_SECS)

func _lay(kind: String, at: Vector3, yaw: float, secs: float) -> void:
	var i := _next
	_next = next_slot(_next, POOL)
	var mi := _pool[i]
	var m := _mats[i]
	_kind[i] = kind
	_age[i] = 0.0
	_life[i] = secs
	mi.position = at
	mi.rotation_degrees.y = yaw
	mi.visible = true
	if kind == "ripple":
		m.albedo_texture = _ring_tex
		m.albedo_color = Color(0.92, 0.97, 1.0, 0.7)
		mi.scale = Vector3(0.3, 0.3, 1.0)
	else:
		m.albedo_texture = _print_tex
		m.albedo_color = Color(PRINT_COL[kind], PRINT_ALPHA[kind])
		mi.scale = Vector3(0.14, 0.26, 1.0)

func _process(delta: float) -> void:
	for i in POOL:
		if _age[i] < 0.0:
			continue
		_age[i] += delta
		var fd := fade(_age[i], _life[i])
		if fd <= 0.0:
			_age[i] = -1.0
			_pool[i].visible = false
			continue
		var c := _mats[i].albedo_color
		if _kind[i] == "ripple":
			var grow := 0.3 + (1.0 - fd) * 0.7
			_pool[i].scale = Vector3(grow, grow, 1.0)
			c.a = 0.7 * fd
		else:
			c.a = float(PRINT_ALPHA[_kind[i]]) * minf(1.0, fd * 3.0)
		_mats[i].albedo_color = c
	_bend()

# --- grass parting ---------------------------------------------------------------------

func _set_push(on: bool) -> void:
	if on == _push_on:
		return
	_push_on = on
	Meshes.foliage.set_shader_parameter("push", 1.0 if on else 0.0)

## Tells the foliage shader where the player's feet are, while they are on screen and the setting allows.
func _bend() -> void:
	var show: bool = _on() and _ow.player.visible and is_visible_in_tree()
	_set_push(show)
	if show:
		var pos: Vector3 = _ow.player.position
		var now := Vector2(pos.x, pos.z)
		if now != _pushed:
			_pushed = now
			Meshes.foliage.set_shader_parameter("pusher", pos)

func _exit_tree() -> void:
	if Meshes.foliage != null:
		Meshes.foliage.set_shader_parameter("push", 0.0)
