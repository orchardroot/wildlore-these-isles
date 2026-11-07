class_name Diorama
extends Node3D
## The 3D stage of a battle: a little themed plateau of vertex-coloured low-poly props (same look as the overworld),
## two creature actors (four in a double battle), and a slowly swaying camera that can swoop to whoever is acting.

const PLAYER_POS := Vector3(-2.5, 0, 1.7)
const FOE_POS := Vector3(2.7, 0, -2.5)
## Double battles: the player's pair front-left, the foes' pair back-right. Position 0 is the left one on screen.
const DOUBLE_HOMES := [
	[Vector3(-4.0, 0, 1.2), Vector3(-1.4, 0, 2.5)],
	[Vector3(1.3, 0, -3.1), Vector3(4.0, 0, -1.9)],
]
const STAGES := ["grass", "forest", "moor", "town", "spa_interior", "water", "city", "docks", "coast", "bog", "mountain",
	"quarry", "cave", "castle", "valley"]

var stage := "grass"
var camera: Camera3D
var actors: Array = []  # position 0 actor for each side (the only ones in singles)
var extra_actors: Array = []  # doubles: the position 1 actor for each side
var double := false
var props: Node3D
var focus := Vector3(0.1, 0.9, -0.3)
var dist := 15.0
var az := 0.0           # extra azimuth from swoops (radians)
var pitch := 24.0       # degrees
var shake := 0.0
var _t := 0.0
var _swoop: Tween
var _rng := RandomNumberGenerator.new()
var _sky_acc := 0.0
var _backdrop: MeshInstance3D
var _sky_grad: Gradient

func _ready() -> void:
	Meshes.materials()
	camera = Camera3D.new()
	camera.fov = 27.0
	camera.near = 0.3
	camera.far = 140.0
	add_child(camera)
	camera.current = true
	# A soft cool fill from the camera side, so shaded faces of trees and walls are not black.
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.42
	fill.light_color = Color("cfe0ff")
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-28, 150, 0)
	add_child(fill)
	for side in 2:
		var a := CreatureActor.new()
		a.home = PLAYER_POS if side == Battle.PLAYER else FOE_POS
		a.position = a.home
		add_child(a)
		a.thump.connect(_on_thump)
		actors.append(a)
	_make_backdrop()
	_place_camera()

## A big gradient wall far behind everything, so the horizon is a sky and not a flat colour.
func _make_backdrop() -> void:
	_sky_grad = Gradient.new()
	var tex := GradientTexture2D.new()
	tex.gradient = _sky_grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.height = 128
	tex.width = 4
	var q := QuadMesh.new()
	q.size = Vector2(400, 130)
	_backdrop = MeshInstance3D.new()
	_backdrop.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.disable_fog = true
	_backdrop.material_override = m
	_backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_backdrop.position = Vector3(0, 28, -80)
	add_child(_backdrop)
	_tint_backdrop(background_colour())

func _tint_backdrop(bg: Color) -> void:
	if _sky_grad == null:
		return
	var top := bg.darkened(0.18)
	top.s = clampf(top.s * 1.25, 0.0, 1.0)
	_sky_grad.offsets = PackedFloat32Array([0.0, 0.55, 0.62, 1.0])
	_sky_grad.colors = PackedColorArray([top, bg, bg.lightened(0.3), bg.lightened(0.45)])

## Switch to a double battle layout: four actors. Call before build() so the props keep clear of them.
func set_double(on: bool) -> void:
	double = on
	if on and extra_actors.is_empty():
		for side in 2:
			var a := CreatureActor.new()
			add_child(a)
			a.thump.connect(_on_thump)
			extra_actors.append(a)
	for side in 2:
		for pos in (2 if on else 1):
			var a := actor(side, pos)
			a.home = home_of(side, pos)
			a.position = a.home

## A heavy creature's charge landed: nudge the camera (softer with reduced flashing).
func _on_thump(strength: float) -> void:
	shake = maxf(shake, 0.6 * strength * Settings.flash_scale(0.25))

## The actor at a field position (position 1 only exists in doubles).
func actor(side: int, pos := 0) -> CreatureActor:
	return extra_actors[side] if pos == 1 and double else actors[side]

func home_of(side: int, pos := 0) -> Vector3:
	if double:
		return DOUBLE_HOMES[side][clampi(pos, 0, 1)]
	return PLAYER_POS if side == Battle.PLAYER else FOE_POS

func build(stage_id: String) -> void:
	stage = stage_id if stage_id in STAGES else "grass"
	if props:
		props.queue_free()
	props = Node3D.new()
	props.name = "Props"
	add_child(props)
	_rng.seed = hash(stage) + 11
	match stage:
		"forest": _forest()
		"moor": _moor()
		"town": _town()
		"spa_interior": _spa()
		"water": _water()
		"city": _town(["terrace", "mill", "red_brick", "terrace", "liver_building"])
		"docks": _docks()
		"coast": _coast()
		"bog": _bog()
		"mountain": _mountain()
		"quarry": _quarry()
		"cave": _cave()
		"castle": _castle()
		"valley": _valley()
		_: _grass()
	_hills()

func is_interior() -> bool:
	return stage in ["spa_interior", "cave"]

func background_colour() -> Color:
	return Color("14161c") if is_interior() else Color("9fc3dc")

# --- camera -------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	_sky_acc += delta
	if _sky_acc > 0.5 and camera.environment != null:
		_sky_acc = 0.0
		_tint_backdrop(camera.environment.background_color)
	shake = maxf(0.0, shake - delta * 1.6)
	_place_camera()

func _place_camera() -> void:
	if camera == null:
		return
	var a := az + sin(_t * 0.23) * 0.11 + 0.1
	var p := deg_to_rad(pitch + sin(_t * 0.31) * 1.2)
	var off := Vector3(sin(a) * cos(p), sin(p), cos(a) * cos(p)) * dist
	var jitter := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), 0) * shake * 0.12
	camera.position = focus + off + jitter
	camera.look_at(focus, Vector3.UP)

func swoop(new_focus: Vector3, new_dist: float, new_az: float, new_pitch: float, t := 0.45) -> void:
	if _swoop and _swoop.is_valid():
		_swoop.kill()
	_swoop = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_swoop.tween_property(self, "focus", new_focus, t)
	_swoop.tween_property(self, "dist", new_dist, t)
	_swoop.tween_property(self, "az", new_az, t)
	_swoop.tween_property(self, "pitch", new_pitch, t)

const HOME_FOCUS := Vector3(0.1, 0.9, -0.3)

func swoop_home(t := 0.6) -> void:
	swoop(HOME_FOCUS, 16.5 if double else 15.0, 0.0, 24.0, t)

## Over the shoulder of whoever is acting (for the player: from behind, down the line to the foe).
## In doubles `pos` is the attacker's position and `target_pos` the foe it is aiming at; the camera stays wider
## and straighter there so the partners (and the HUD) stay clear of each other.
func swoop_to_attacker(side: int, pos := 0, target_pos := 0) -> void:
	var mine := home_of(Battle.PLAYER, pos if side == Battle.PLAYER else target_pos)
	var foes := home_of(Battle.FOE, pos if side == Battle.FOE else target_pos)
	if double:
		if side == Battle.PLAYER:
			swoop(HOME_FOCUS.lerp(foes + Vector3(0, 0.9, 0), 0.3), 15.0, -0.1, 23.0)
		else:  # a foe acting: hold the wide shot, so our pair is not pushed under the plates
			swoop(HOME_FOCUS + Vector3(0.4, 0, -0.4), 15.5, 0.05, 23.0)
		return
	if side == Battle.PLAYER:
		swoop(mine.lerp(foes, 0.6) + Vector3(0, 1.0, 0), 10.0, -0.72, 20.0)
	else:
		swoop(mine.lerp(foes, 0.4) + Vector3(0, 1.0, 0), 12.0, 0.15, 22.0)

func swoop_to_target(side: int, pos := 0) -> void:
	var at := home_of(side, pos)
	if double:
		# A gentle lean towards a foe that is hit; for our own pair, the wide shot. Everyone stays in view.
		if side == Battle.FOE:
			swoop(HOME_FOCUS.lerp(at + Vector3(0, 0.9, 0), 0.35), 14.5, 0.0, 23.0, 0.3)
		else:
			swoop(HOME_FOCUS, 15.5, 0.0, 23.0, 0.3)
		return
	if side == Battle.FOE:
		swoop(at + Vector3(0, 1.0, 0), 9.5, -0.5, 20.0, 0.3)
	else:
		swoop(at.lerp(Vector3.ZERO, 0.3) + Vector3(0, 1.0, 0), 10.5, 0.3, 21.0, 0.3)

func intro_swoop() -> void:
	focus = Vector3(1.0, 1.4, -2.0)
	dist = 17.0
	az = 0.7
	pitch = 26.0
	swoop_home(1.6)

# --- building blocks ----------------------------------------------------------

func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

func _commit(st: SurfaceTool, material: Material, parent: Node3D = null, shadow := true) -> MeshInstance3D:
	st.index()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else props).add_child(mi)
	return mi

## A lumpy round plateau: grassy top, earthy sides.
func _plateau(r: float, top: Color, side: Color, thick := 0.9, lip := Color(0, 0, 0, 0), sides := 30) -> void:
	var st := _st()
	var top_pts := []
	var low_pts := []
	for i in sides:
		var t := TAU * i / sides
		var k := 1.0 + _rng.randf_range(-0.035, 0.035)
		top_pts.append(Vector3(cos(t) * r * k, 0, sin(t) * r * 0.86 * k))
		low_pts.append(Vector3(cos(t) * r * 0.82 * k, -thick, sin(t) * r * 0.86 * 0.82 * k))
	for i in sides:
		var j := (i + 1) % sides
		var tint := top
		Meshes._tri(st, Vector3.ZERO, top_pts[i], top_pts[j], tint)
		Meshes._quad(st, top_pts[j], top_pts[i], low_pts[i], low_pts[j], side.darkened(0.06 * (i % 3)))
	if lip.a > 0.0:  # a lighter rim of turf / kerb just inside the edge
		for i in sides:
			var j := (i + 1) % sides
			var a: Vector3 = top_pts[i]
			var b: Vector3 = top_pts[j]
			Meshes._quad(st, b * 0.9 + Vector3(0, 0.012, 0), a * 0.9 + Vector3(0, 0.012, 0), a * 0.98 + Vector3(0, 0.012, 0), b * 0.98 + Vector3(0, 0.012, 0), lip)
	_commit(st, Meshes.solid)

## Soft patches of a second colour on the ground so it is not one flat disc.
func _patches(colours: Array, n: int, r: float, size := 1.4) -> void:
	var st := _st()
	for i in n:
		var t := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * r
		var c := Vector3(cos(t) * d, 0.012 + 0.001 * i, sin(t) * d * 0.86)
		var rad := _rng.randf_range(0.5, 1.0) * size
		var col: Color = colours[_rng.randi() % colours.size()]
		var sides := 7
		for k in sides:
			var a := TAU * k / sides
			var b := TAU * (k + 1) / sides
			Meshes._tri(st, c, c + Vector3(cos(a), 0, sin(a)) * rad, c + Vector3(cos(b), 0, sin(b)) * rad, col)
	_commit(st, Meshes.solid, null, false)

func _place(mesh: Mesh, pos: Vector3, yaw := 0.0, s := 1.0, foliage := false, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Meshes.foliage if foliage else Meshes.solid
	mi.position = pos
	mi.rotation.y = yaw
	mi.scale = Vector3.ONE * s
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	props.add_child(mi)
	return mi

## Points on the back and sides of the plateau (not in front of the camera, where the creatures stand).
func _rim_points(n: int, r_min: float, r_max: float, from_deg := -200.0, to_deg := 20.0) -> Array:
	var out := []
	for i in n:
		var t := deg_to_rad(lerpf(from_deg, to_deg, (i + _rng.randf_range(-0.3, 0.3)) / maxf(1.0, n - 1)))
		var d := _rng.randf_range(r_min, r_max)
		out.append(Vector3(cos(t) * d, 0, sin(t) * d * 0.86))
	return out

func _scatter(maker: Callable, n: int, r_min: float, r_max: float, foliage: bool, s_min := 0.9, s_max := 1.3, from_deg := -200.0, to_deg := 20.0) -> void:
	var i := 0
	for p in _rim_points(n, r_min, r_max, from_deg, to_deg):
		_place(maker.call(i), p, _rng.randf() * TAU, _rng.randf_range(s_min, s_max), foliage)
		i += 1

## Anywhere on the plateau that is clear of the two creatures and the middle of the action.
func _clear_spot(r_max: float) -> Vector3:
	for k in 20:
		var t := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * r_max
		var p := Vector3(cos(t) * d, 0, sin(t) * d * 0.86)
		if p.distance_to(PLAYER_POS) > 2.2 and p.distance_to(FOE_POS) > 2.2 and p.distance_to(Vector3(0, 0, -0.4)) > 1.6:
			if not double or DOUBLE_HOMES.all(func(row): return row.all(func(h): return p.distance_to(h) > 2.0)):
				return p
	return Vector3(-6, 0, -3)

func _tufts(n: int, r: float, flowers := 0) -> void:
	for i in n:
		_place(Meshes.tall_grass_tuft(i), _clear_spot(r), _rng.randf() * TAU, _rng.randf_range(0.9, 1.4), true, false)
	for i in flowers:
		_place(Meshes.flower_patch(i), _clear_spot(r), _rng.randf() * TAU, 1.0, false, false)

func _rocks(n: int, r: float, s_min := 0.7, s_max := 1.4) -> void:
	for i in n:
		_place(Meshes.rock(i), _clear_spot(r), _rng.randf() * TAU, _rng.randf_range(s_min, s_max))

## Distant rolling hills so the plateau floats in a landscape, not a void.
func _hills() -> void:
	if stage in ["spa_interior", "water", "cave", "coast", "docks"]:
		return
	var cols := {"grass": Color("8bb36a"), "forest": Color("476f4a"), "moor": Color("8a7d94"), "town": Color("8fa27a"), "water": Color("7da07a"),
		"city": Color("8a8f8a"), "bog": Color("6f6a45"), "mountain": Color("6f7a6a"), "quarry": Color("5f6670"), "castle": Color("7fa060"), "valley": Color("5f8f4a")}
	var base: Color = cols.get(stage, Color("8bb36a"))
	var st := _st()
	for i in 22:
		var t := deg_to_rad(lerpf(-190.0, 10.0, i / 21.0)) + _rng.randf_range(-0.05, 0.05)
		var d := _rng.randf_range(17.0, 25.0)
		var c := Vector3(cos(t) * d, -2.4, sin(t) * d * 0.7 - 6.0)
		var r := Vector3(_rng.randf_range(5, 8), _rng.randf_range(1.8, 3.4), _rng.randf_range(5, 8))
		Meshes.blob(st, c, r, base.darkened(0.22).lerp(Color("9fb4c8"), 0.06 * (i % 3)), _rng, 0.12)
	var mi := _commit(st, Meshes.solid, null, false)
	mi.name = "Hills"

# --- stages -------------------------------------------------------------------

func _grass() -> void:
	_plateau(9.0, Color("689a46"), Color("6e5037"), 0.9, Color("7aae52"))
	_patches([Color("5f9040"), Color("72a64c"), Color("6a9c46")], 16, 8.0, 1.6)
	_scatter(func(i): return Meshes.oak(i), 7, 6.8, 8.2, true, 0.95, 1.35, -190.0, -20.0)
	_scatter(func(i): return Meshes.bush(i), 9, 5.4, 8.0, true, 0.9, 1.3, -200.0, 15.0)
	for i in 6:  # a wandering hedge-and-fence line at the back
		_place(Meshes.fence_segment(), Vector3(-6.0 + i * 1.0, 0, -6.4 + sin(i * 0.5)), 0.0, 1.05)
	_tufts(26, 7.5, 12)
	_rocks(3, 7.0)

func _forest() -> void:
	_plateau(9.0, Color("55803d"), Color("5b4330"), 0.9, Color("63904a"))
	_patches([Color("7a6a3a"), Color("476f34"), Color("8a7a44"), Color("3f6330")], 22, 8.2, 1.5)
	_scatter(func(i): return Meshes.pine(i), 12, 6.6, 8.8, true, 1.0, 1.5, -200.0, 20.0)
	_scatter(func(i): return Meshes.oak(i), 6, 5.8, 8.4, true, 1.0, 1.4, -190.0, 0.0)
	_scatter(func(i): return Meshes.birch(i), 5, 6.0, 8.0, true, 1.0, 1.3, -170.0, 10.0)
	_scatter(func(i): return Meshes.bush(i), 8, 5.0, 7.6, true, 0.9, 1.4, -200.0, 20.0)
	_tufts(14, 7.0, 4)
	_rocks(4, 7.0, 0.6, 1.2)
	# a fallen log
	var st := _st()
	Meshes.cylinder(st, Vector3(0, 0, 0), 0.32, 2.4, 7, Meshes.TRUNK)
	var log_mi := _commit(st, Meshes.solid)
	log_mi.position = Vector3(-4.8, 0.3, -2.6)
	log_mi.rotation = Vector3(0, 0.6, deg_to_rad(90))

func _moor() -> void:
	_plateau(9.0, Color("766b7c"), Color("5e4f3d"), 0.9, Color("857a86"))
	_patches([Color("857a52"), Color("6f6482"), Color("8a7c92"), Color("66743f")], 26, 8.4, 1.6)
	_scatter(func(i): return Meshes.rock(i), 9, 5.5, 8.6, false, 0.9, 1.9, -200.0, 10.0)
	for i in 8:  # drystone wall
		_place(Meshes.wall_segment(i), Vector3(-7.0 + i * 1.0, 0, -5.8 + i * 0.12), 0.1, 1.05)
	_tufts(30, 7.8, 0)
	_rocks(4, 7.0, 0.5, 1.0)

func _town(styles := ["red_brick", "stone", "cream_render", "white_render", "gritstone"]) -> void:
	_plateau(9.0, Color("a29a8c"), Color("6c6358"), 0.9, Color("c7bfb0"))
	_patches([Color("93897a"), Color("b0a798"), Color("9a9183")], 24, 8.2, 1.1)
	var x := -8.0
	var i := 0
	while x < 7.0:
		var w := 3 + (i % 3)
		var b: Array = Meshes.building(w, 3, styles[i % styles.size()], 1, 40 + i)
		var body := MeshInstance3D.new()
		body.mesh = b[0]
		body.material_override = Meshes.solid
		body.position = Vector3(x, 0, -9.0 + (i % 2) * 0.4)
		body.scale = Vector3.ONE * 1.1
		props.add_child(body)
		var win := MeshInstance3D.new()
		win.mesh = b[1]
		win.material_override = Meshes.glow
		win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(win)
		x += w * 1.1 + 0.15
		i += 1
	for lx in [-5.5, 5.8]:
		_place(Meshes.lamp_post(), Vector3(lx, 0, -4.4), 0.0, 1.3)
		var bulb := _place(Meshes.lamp_bulb(), Vector3(lx, 0, -4.4), 0.0, 1.3, false, false)
		bulb.material_override = Meshes.glow
	_place(Meshes.bench(), Vector3(-5.0, 0, -3.0), 0.5, 1.3)
	_place(Meshes.bench(), Vector3(5.2, 0, -2.2), -0.6, 1.3)
	for k in 5:
		_place(Meshes.bush(k), Vector3(-6.5 + k * 3.2, 0, -5.4), 0.0, 1.3, true)
	_rocks(1, 6.0, 0.4, 0.7)

func _spa() -> void:
	# Tiled floor in cream and sage, a stone back wall with tall glowing windows, columns and a long counter.
	var st := _st()
	var n := 9
	for ix in range(-n, n):
		for iz in range(-6, 5):
			var c := Color("e9dfc8") if (ix + iz) % 2 == 0 else Color("a9bfa4")
			Meshes.box(st, Vector3(ix * 1.0, -0.3, iz * 1.0), Vector3(1.0, 0.3, 1.0), c.darkened(0.04), c)
	_commit(st, Meshes.solid, null, false)
	var wall := _st()
	var wall_col := Color("d8c8a4")
	Meshes.box(wall, Vector3(-11, 0, -7.4), Vector3(22, 6.2, 0.7), wall_col)
	Meshes.box(wall, Vector3(-11, 0, -7.4), Vector3(22, 0.9, 0.9), wall_col.darkened(0.25))
	Meshes.box(wall, Vector3(-11, 0, -7.4), Vector3(0.7, 6.2, 10.0), wall_col.darkened(0.06))
	Meshes.box(wall, Vector3(10.3, 0, -7.4), Vector3(0.7, 6.2, 10.0), wall_col.darkened(0.06))
	var glow := _st()
	for k in range(-4, 5):
		var wx := k * 2.4 - 0.5
		Meshes.box(wall, Vector3(wx - 0.1, 1.2, -6.75), Vector3(1.1, 3.6, 0.1), wall_col.lightened(0.25))
		Meshes.box(glow, Vector3(wx, 1.35, -6.7), Vector3(0.9, 3.3, 0.06), Color.WHITE)
	_commit(wall, Meshes.solid)
	var gm := _commit(glow, Meshes.glow, null, false)
	gm.name = "Windows"
	var col := _st()
	for cx in [-7.0, -3.2, 3.6, 7.4]:
		Meshes.cylinder(col, Vector3(cx, 0, -5.4), 0.5, 5.0, 8, Color("efe6d0"))
		Meshes.box(col, Vector3(cx - 0.7, 0, -5.4 - 0.7), Vector3(1.4, 0.4, 1.4), Color("c9bc9c"))
		Meshes.box(col, Vector3(cx - 0.65, 4.9, -5.4 - 0.65), Vector3(1.3, 0.3, 1.3), Color("c9bc9c"))
	_commit(col, Meshes.solid)
	_place(Meshes.counter(), Vector3(-6.2, 0, -3.8), 0.0, 1.6)
	_place(Meshes.counter(), Vector3(-4.7, 0, -3.8), 0.0, 1.6)
	_place(Meshes.bench(), Vector3(5.4, 0, -3.6), 0.0, 1.5)
	for k in 3:
		_place(Meshes.bush(k), Vector3(6.4 + k * 1.2, 0, -4.2 + k * 0.3), 0.0, 1.1, true)

func _water() -> void:
	# A wooden jetty plateau over a pond, reeds and rocks at its edges.
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 90)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	water.mesh = plane
	var wm := ShaderMaterial.new()
	wm.shader = load("res://art/shaders/water.gdshader")
	water.material_override = wm
	water.position.y = -0.55
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	props.add_child(water)
	_plateau(7.6, Color("8e7650"), Color("5a432c"), 1.4, Color("a98f64"))
	var planks := _st()
	for i in 15:
		var z := -6.0 + i * 0.86
		Meshes.box(planks, Vector3(-7.0, 0.01, z), Vector3(14.0, 0.05, 0.08), Color("5a432c"))
	_commit(planks, Meshes.solid, null, false)
	_patches([Color("7f6944"), Color("9c8358"), Color("86704a")], 16, 7.0, 1.0)
	for i in 8:
		var t := deg_to_rad(lerpf(-200.0, 20.0, i / 7.0))
		var p := Vector3(cos(t) * 7.4, 0, sin(t) * 6.4)
		var st := _st()
		Meshes.cylinder(st, Vector3(0, 0, 0), 0.1, 1.4, 5, Color("5a432c"))
		_commit(st, Meshes.solid).position = p
	_scatter(func(i): return Meshes.tall_grass_tuft(i), 14, 7.0, 8.4, true, 1.6, 2.4, -200.0, 20.0)
	_scatter(func(i): return Meshes.rock(i), 5, 7.8, 9.5, false, 1.5, 2.6, -200.0, 0.0)
	_scatter(func(i): return Meshes.bush(i), 4, 8.0, 9.2, true, 1.5, 2.0, -180.0, -20.0)

# --- M2 stages ----------------------------------------------------------------

## A building (any Meshes/Landmarks style) as a backdrop piece, with lit windows.
func _backdrop_building(w: int, d: int, style: String, pos: Vector3, yaw := 0.0, s := 1.1) -> void:
	var b: Array = Meshes.building(w, d, style, -1, hash(style) + int(pos.x * 7))
	var body := MeshInstance3D.new()
	body.mesh = b[0]
	body.material_override = Meshes.solid
	body.position = pos
	body.rotation.y = yaw
	body.scale = Vector3.ONE * s
	props.add_child(body)
	var win := MeshInstance3D.new()
	win.mesh = b[1]
	win.material_override = Meshes.glow
	win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(win)

func _sea(y := -0.55, deep := Color(0.1, 0.27, 0.38), shallow := Color(0.3, 0.55, 0.62)) -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	water.mesh = plane
	var wm := ShaderMaterial.new()
	wm.shader = load("res://art/shaders/water.gdshader")
	wm.set_shader_parameter("deep", deep)
	wm.set_shader_parameter("shallow", shallow)
	water.material_override = wm
	water.position.y = y
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	props.add_child(water)

func _docks() -> void:
	_sea()
	_plateau(8.6, Color("8d8578"), Color("4f4a44"), 1.3, Color("a9a091"))
	_patches([Color("7f776a"), Color("9a9183")], 14, 7.6, 1.2)
	_backdrop_building(9, 4, "liver_building", Vector3(-6.5, 0, -12.0), 0.0, 1.0)
	_backdrop_building(7, 3, "mill", Vector3(4.5, 0, -11.0), 0.0, 1.0)
	for k in 6:
		_place(Landmarks.bollard(), Vector3(-6.0 + k * 2.4, 0, -6.6), 0.0, 1.3)
	_place(Landmarks.boat(0), Vector3(9.5, -0.55, -3.0), 1.4, 1.0)
	_place(Landmarks.buoy(0), Vector3(-10.0, -0.55, 2.0), 0.0, 1.3)

func _coast() -> void:
	_sea()
	_plateau(8.4, Color("c4ad78"), Color("8a7350"), 1.2, Color("d2bf8e"))
	_patches([Color("c9b47f"), Color("e2d2a0"), Color("b8a777")], 18, 7.4, 1.3)
	_rocks(7, 7.8, 0.8, 1.8)
	_place(Landmarks.lighthouse(), Vector3(-8.5, 0, -7.0), 0.0, 1.3)
	_place(Landmarks.buoy(1), Vector3(10.5, -0.55, -4.0), 0.0, 1.3)
	_place(Landmarks.boat(1), Vector3(-11.0, -0.55, 1.0), 0.6, 1.2)
	for i in 6:
		_place(Meshes.reeds(i), _clear_spot(7.5), _rng.randf() * TAU, 1.2, true, false)  # marram grass

func _bog() -> void:
	_plateau(9.0, Color("6b5a3a"), Color("3f3324"), 0.8, Color("7d6a44"))
	_patches([Color("a8483f"), Color("7f9a3c"), Color("c27a3a"), Color("5f7f35")], 30, 8.4, 1.5)  # sphagnum reds and greens
	var pools := _st()
	for i in 6:
		var p := _clear_spot(7.2)
		Meshes.cone(pools, Vector3(p.x, 0.02, p.z), _rng.randf_range(0.5, 1.0), 0.01, 10, Color("2f4a52"), _rng)
	_commit(pools, Meshes.solid, null, false)
	for i in 14:
		_place(Meshes.reeds(i % 3), _clear_spot(8.0), _rng.randf() * TAU, 1.3, true, false)
	_scatter(func(i): return Meshes.birch(i), 4, 6.8, 8.6, true, 0.8, 1.1, -190.0, -60.0)

func _mountain() -> void:
	_plateau(8.8, Color("7d8a6a"), Color("5d5a52"), 1.1, Color("8f9a7a"))
	_patches([Color("8a8780"), Color("6f7d5c"), Color("9a978e")], 24, 8.0, 1.4)
	_scatter(func(i): return Meshes.rock(i), 12, 5.6, 8.8, false, 1.0, 2.6, -200.0, 15.0)
	for i in 10:
		_place(Landmarks.scree_rubble(i % 3), _clear_spot(7.6), _rng.randf() * TAU, 1.4, false, false)
	_place(Landmarks.standing_stone(1), Vector3(5.5, 0, -6.2), 0.3, 1.2)  # a summit cairn's cousin

func _quarry() -> void:
	_plateau(9.0, Color("6c727c"), Color("454a52"), 1.0, Color("7d848e"))
	_patches([Color("5f6670"), Color("7a828c"), Color("565c66")], 22, 8.2, 1.3)
	var terr := _st()
	for k in 4:  # stepped slate terraces behind
		Meshes.box(terr, Vector3(-16.0 + k * 1.2, -1.0, -15.0 - k * 2.6), Vector3(32.0 - k * 2.4, 1.2 + k * 1.8, 2.6), Color("5a606b").lightened(0.05 * k))
	_commit(terr, Meshes.solid)
	for i in 6:
		_place(Landmarks.slate_heap(i), _clear_spot(7.6), _rng.randf() * TAU, 1.3)

func _cave() -> void:
	var st := _st()
	for ix in range(-9, 9):
		for iz in range(-7, 5):
			var c := Color("3b3a3f").lightened(_rng.randf_range(-0.04, 0.05))
			Meshes.box(st, Vector3(ix, -0.3, iz), Vector3(1.0, 0.3, 1.0), c.darkened(0.1), c)
	_commit(st, Meshes.solid, null, false)
	var walls := _st()
	for i in 26:
		var t := deg_to_rad(lerpf(-200.0, 20.0, i / 25.0))
		Meshes.blob(walls, Vector3(cos(t) * 10.0, 1.5, sin(t) * 7.5 - 2.0), Vector3(2.2, 3.4, 2.0), Color("4a4650"), _rng, 0.25)
	_commit(walls, Meshes.solid)
	var pool := _st()
	Meshes.cone(pool, Vector3(4.5, 0.02, -4.0), 2.0, 0.01, 14, Color("2c5a6a"), _rng)
	_commit(pool, Meshes.glow, null, false)
	for k in 3:
		_place(Landmarks.standing_stone(k), Vector3(-6.0 + k * 1.6, 0, -5.4), 0.2 * k, 1.2)

func _castle() -> void:
	_grass_base()
	_backdrop_building(12, 7, "castle", Vector3(-7.0, 0, -15.0), 0.0, 1.0)
	_scatter(func(i): return Meshes.oak(i), 4, 7.0, 8.4, true, 0.9, 1.2, -60.0, 20.0)

func _valley() -> void:
	_grass_base()
	_backdrop_building(16, 2, "aqueduct", Vector3(-9.0, 0, -12.0), 0.0, 1.0)
	_scatter(func(i): return Meshes.oak(i), 6, 6.8, 8.6, true, 0.9, 1.3, -200.0, 20.0)

func _grass_base() -> void:
	_plateau(9.0, Color("689a46"), Color("6e5037"), 0.9, Color("7aae52"))
	_patches([Color("5f9040"), Color("72a64c"), Color("6a9c46")], 16, 8.0, 1.6)
	_tufts(18, 7.5, 8)
	_rocks(2, 7.0)
