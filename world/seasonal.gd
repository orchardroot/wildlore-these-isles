class_name Seasonal
extends Node3D
## The real-world season and festivals (see Calendar) dressed onto the overworld: tinted tree canopies (via the
## foliage shader), falling leaves in autumn woods, pumpkins on town doorsteps for Halloween, fireworks over
## towns on Bonfire Night, a lit tree in the square at Christmas and a flag out on the national days.
## One of these hangs under each zone's scenery node; everything here is cheap (a few MultiMeshes and
## CPU particles) and the Compatibility renderer is fine with all of it.

const WOODED_TREES := 8          # this many trees makes a zone wooded enough for falling leaves
const LEAF_COLOURS := [Color("d9a441"), Color("c9762f"), Color("a8552a"), Color("e0b83a")]
const BULB_COLOURS := [Color("ff4a3d"), Color("ffd23f"), Color("3fa8ff"), Color("4fe07a"), Color("ff7ad9")]
const FIREWORK_COLOURS := [Color("ff5a4a"), Color("ffd84a"), Color("7ad0ff"), Color("b07aff"), Color("7aff9a"), Color("ff8ad8")]
const NATION_FLAG := {"wales": 0, "scotland": 1, "ireland": 2}  # Dressing.FLAGS: dragon, saltire, tricolour

var follow: Node3D
var _leaves: CPUParticles3D
var _bursts: Array = []
var _burst_wait := 1.0
var _rng := RandomNumberGenerator.new()

## Sets the foliage shader to today's season, as `region` keeps it (Calendar.foliage_tint_in). Called when the
## shared materials are made and again as each zone is dressed, so a palm on St Helena stays green in November.
static func tint(foliage: ShaderMaterial, region := "") -> void:
	var t := Calendar.today()
	var k := Calendar.foliage_tint_in(region, t.x, t.y)
	foliage.set_shader_parameter("spring", k.x)
	foliage.set_shader_parameter("autumn", k.y)
	foliage.set_shader_parameter("winter", k.z)

## The same season on the ground: ochre autumn grass, pale winter, fresh spring (ground.gdshader).
static func tint_ground(ground: ShaderMaterial, region := "") -> void:
	var t := Calendar.today()
	var k := Calendar.foliage_tint_in(region, t.x, t.y)
	ground.set_shader_parameter("spring", k.x)
	ground.set_shader_parameter("autumn", k.y)
	ground.set_shader_parameter("winter", k.z)

## Dresses a freshly built zone for the date. `follow` is the player (leaves and fireworks stay round them).
static func dress(z: ZoneData, zone_node: Node3D, follow_node: Node3D) -> void:
	if Meshes.foliage != null:
		tint(Meshes.foliage, z.region)
	if Meshes.ground != null:
		tint_ground(Meshes.ground, z.region)
	if z.kind == "interior":
		return
	var season := Calendar.season_today()
	var festival := Calendar.festival_today()
	var s := Seasonal.new()
	s.name = "Seasonal"
	s.follow = follow_node
	s._rng.seed = hash(z.id)
	var low := Settings.quality == "low"
	if Calendar.season_in(z.region) == "autumn" and not low and tree_count(z) >= WOODED_TREES and not z.region.begins_with("overseas_"):  # palms drop no leaves
		s._add_leaves()
	if z.kind == "town" and Calendar.festival_here(festival, z.region):
		match festival:
			"halloween":
				s._add_pumpkins(z)
			"bonfire_night":
				s._add_fireworks(2 if low else 3)
			"christmas":
				s._add_christmas(z)
			_:
				s._add_flag(z, NATION_FLAG.get(Calendar.nation_for_region(z.region), 6))
	if s.get_child_count() == 0:
		s.free()
		return
	zone_node.add_child(s)

static func tree_count(z: ZoneData) -> int:
	var n := 0
	for row in z.tiles:
		for t in row:
			if t == "tree_oak" or t == "tree_pine":
				n += 1
	for pr in z.props:
		if str(pr.get("type", "")) in ["oak", "birch", "pine"]:
			n += 1
	return n

## Doorsteps: the tile in front of each door into a building (a warp on a building's bottom row).
static func doorsteps(z: ZoneData) -> Array:
	var out := []
	for w in z.warps:
		var door := Vector2i(int(w.x), int(w.y))
		var step := door + Vector2i(0, 1)
		if z.tile_at(door) == "door" and z.walkable(step):
			out.append(door)
	return out

## A good spot for a centrepiece in the town square: an open tile (all eight neighbours walkable, nothing on
## it or round it) as near as it can be to the middle of the benches, stalls and lamps. (-1, -1) if none.
static func square_spot(z: ZoneData) -> Vector2i:
	var busy := {}
	var centre := Vector2.ZERO
	var count := 0
	for pr in z.props:
		var p := Vector2i(int(pr.get("x", -9)), int(pr.get("y", -9)))
		busy[p] = true
		if str(pr.get("type", "")) in ["bench", "market_stall", "lamp_post", "planter", "statue"]:
			centre += Vector2(p)
			count += 1
	for w in z.warps:
		busy[Vector2i(int(w.x), int(w.y))] = true
	for n in z.npcs:  # keep clear of where folk stand, pace and wander
		var at := Vector2i(int(n.get("x", -9)), int(n.get("y", -9)))
		var r := ZoneData.WANDER_RADIUS if str(n.get("move", "")) == "wander" else 0
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				busy[at + Vector2i(dx, dy)] = true
		for step in n.get("path", []):
			at += ZoneData.STEPS.get(str(step), Vector2i.ZERO)
			busy[at] = true
	for s in z.signs:
		busy[Vector2i(int(s.x), int(s.y))] = true
	busy[z.spawn] = true
	centre = centre / count if count > 0 else Vector2(z.width, z.height) * 0.5
	var best := Vector2i(-1, -1)
	var best_d := INF
	for y in range(2, z.height - 2):
		for x in range(2, z.width - 2):
			var p := Vector2i(x, y)
			if z.tile_at(p) not in ["cobbles", "path", "grass", "flowers"]:
				continue
			var open := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var q := p + Vector2i(dx, dy)
					if busy.has(q) or not z.walkable(q) or z.height_at(q) != z.height_at(p) or z.tile_at(q) == "door":
						open = false
			if not open:
				continue
			var d := Vector2(p).distance_squared_to(centre)
			if d < best_d:
				best_d = d
				best = p
	return best

# --- autumn ------------------------------------------------------------------------

func _add_leaves() -> void:
	var p := CPUParticles3D.new()
	p.name = "FallingLeaves"
	p.amount = 26
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(11, 0.5, 8)
	p.direction = Vector3(0.4, -1, 0.1)
	p.spread = 25.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.6
	p.gravity = Vector3(0.12, -0.28, 0)
	p.angular_velocity_min = -160.0
	p.angular_velocity_max = 160.0
	p.angle_max = 360.0
	var g := Gradient.new()
	g.colors = PackedColorArray(LEAF_COLOURS)
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	p.color_initial_ramp = g
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	fade.offsets = PackedFloat32Array([0.0, 0.12, 0.85, 1.0])
	p.color_ramp = fade
	p.mesh = _particle_quad(Vector2(0.13, 0.09), false)
	add_child(p)
	_leaves = p
	_leaves.emitting = true

# --- Halloween -------------------------------------------------------------------

func _add_pumpkins(z: ZoneData) -> void:
	var shells := []
	var faces := []
	var pools := []
	for door in doorsteps(z):
		var side := 1.0 if (door.x + door.y) % 2 == 0 else -1.0
		var gy := ZoneBuilder.ground_y(z, door + Vector2i(0, 1))
		var at := Vector3(door.x + 0.5 + side * 0.62, gy, door.y + 1.2)
		var tr := Transform3D(Basis(Vector3.UP, _rng.randf_range(-0.3, 0.3)).scaled(Vector3.ONE * 1.8), at)
		shells.append(tr)
		faces.append(tr)
		if _rng.randf() < 0.5:  # and a little one beside it
			var small := Transform3D(Basis(Vector3.UP, _rng.randf_range(-0.4, 0.4)).scaled(Vector3.ONE * 1.15), at + Vector3(side * 0.34, 0, 0.08))
			shells.append(small)
			faces.append(small)
		pools.append(Transform3D(Basis.from_scale(Vector3(1.4, 1, 1.4)), at + Vector3(0, 0.03, 0.2)))
	_multi("Pumpkins", pumpkin_mesh(), shells, Meshes.solid)
	_multi("PumpkinFaces", pumpkin_face_mesh(), faces, Meshes.glow)
	_multi("PumpkinGlow", Dressing.pool_quad(), pools, Meshes.pool)

static func pumpkin_mesh() -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(3110)
	var orange := Color("d9752a")
	for i in 5:
		var a := TAU * i / 5.0
		var c := Vector3(cos(a) * 0.06, 0.13, sin(a) * 0.05)
		Meshes.blob(st, c, Vector3(0.11, 0.12, 0.11), orange.lightened(0.06 * (i % 2)), rng, 0.08)
	Meshes.box(st, Vector3(-0.02, 0.24, -0.02), Vector3(0.04, 0.07, 0.04), Color("4f5a2a"))
	return Meshes._finish(st)

## The carved face, on the side toward the camera (+z): dark by day, lit from inside after dark (Meshes.glow).
static func pumpkin_face_mesh() -> ArrayMesh:
	var st := Meshes._st()
	var z := 0.185
	var n := Vector3(0, 0, 1)
	var tris := [
		[Vector3(-0.09, 0.15, z), Vector3(-0.02, 0.15, z), Vector3(-0.055, 0.2, z)],   # eyes
		[Vector3(0.02, 0.15, z), Vector3(0.09, 0.15, z), Vector3(0.055, 0.2, z)],
		[Vector3(-0.1, 0.12, z), Vector3(0.0, 0.065, z), Vector3(0.1, 0.12, z)],            # grin (listed point-down so it faces out too)
		[Vector3(-0.03, 0.12, z), Vector3(0.03, 0.12, z), Vector3(0.0, 0.142, z)],         # a notch carved up from the grin
	]
	for t in tris:
		for v in [t[0], t[2], t[1]]:
			st.set_color(Color.WHITE)
			st.set_normal(n)
			st.add_vertex(v)
	return Meshes._finish(st)

# --- Bonfire Night ------------------------------------------------------------------

func _add_fireworks(count: int) -> void:
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
	fade.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var quad := _particle_quad(Vector2(0.3, 0.3), true)
	for i in count:
		var p := CPUParticles3D.new()
		p.name = "Firework%d" % i
		p.amount = 64
		p.lifetime = 1.8
		p.one_shot = true
		p.explosiveness = 1.0
		p.emitting = false
		p.direction = Vector3.UP
		p.spread = 180.0
		p.initial_velocity_min = 3.4
		p.initial_velocity_max = 3.8
		p.gravity = Vector3(0, -0.9, 0)
		p.damping_min = 2.6
		p.damping_max = 3.0
		p.color_ramp = fade
		p.mesh = quad
		add_child(p)
		_bursts.append(p)

func _launch() -> void:
	var p: CPUParticles3D = _bursts[_rng.randi() % _bursts.size()]
	if p.emitting:
		return
	var at := follow.global_position if follow else Vector3.ZERO
	# the camera looks down at 35 degrees, so "over the rooftops" is low and just north of you, or it's off-screen
	p.global_position = at + Vector3(_rng.randf_range(-7, 7), _rng.randf_range(2.8, 3.6), _rng.randf_range(-2.6, -0.8))
	p.color = FIREWORK_COLOURS[_rng.randi() % FIREWORK_COLOURS.size()]
	p.restart()

# --- Christmas and national days ------------------------------------------------------

func _add_christmas(z: ZoneData) -> void:
	var spot := square_spot(z)
	var bulbs := []
	var colours := []
	if spot.x >= 0:
		z.blocked[spot] = true
		var at := Vector3(spot.x + 0.5, ZoneBuilder.ground_y(z, spot), spot.y + 0.5)
		var tree := MeshInstance3D.new()
		tree.name = "ChristmasTree"
		tree.mesh = Meshes.pine(0)
		tree.material_override = Meshes.foliage
		tree.transform = Transform3D(Basis.from_scale(Vector3(1.25, 1.55, 1.25)), at)
		add_child(tree)
		var star := MeshInstance3D.new()
		star.mesh = _star_mesh()
		star.material_override = _bulb_material()
		star.position = at + Vector3(0, 3.6, 0)
		add_child(star)
		for i in 26:  # a spiral of fairy lights round the tree
			var f := i / 26.0
			var a := f * TAU * 3.2
			var r := lerpf(0.72, 0.18, f)
			bulbs.append(at + Vector3(cos(a) * r, 0.65 + f * 2.7, sin(a) * r))
			colours.append(BULB_COLOURS[i % BULB_COLOURS.size()])
	for pr in z.props:
		if str(pr.get("type", "")) != "lamp_post":
			continue
		var p := Vector2i(int(pr.x), int(pr.y))
		var top := Vector3(p.x + 0.5, ZoneBuilder.prop_y(z, "lamp_post", p) + 1.36, p.y + 0.5)
		for k in 5:
			var a := TAU * k / 5.0 + p.x
			bulbs.append(top + Vector3(cos(a) * 0.16, 0.0, sin(a) * 0.16))
			colours.append(BULB_COLOURS[(k + p.x) % BULB_COLOURS.size()])
	if bulbs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bulb := SphereMesh.new()
	bulb.radius = 0.05
	bulb.height = 0.1
	bulb.radial_segments = 6
	bulb.rings = 3
	mm.mesh = bulb
	mm.instance_count = bulbs.size()
	for i in bulbs.size():
		mm.set_instance_transform(i, Transform3D(Basis(), bulbs[i]))
		mm.set_instance_color(i, colours[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "FairyLights"
	mmi.multimesh = mm
	mmi.material_override = _bulb_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _add_flag(z: ZoneData, variant: int) -> void:
	var spot := square_spot(z)
	if spot.x < 0:
		return
	z.blocked[spot] = true
	var tr := Transform3D(Basis(), Vector3(spot.x + 0.5, ZoneBuilder.ground_y(z, spot), spot.y + 0.5))
	_multi("FestivalPole", Dressing.flagpole(), [tr], Meshes.solid)
	_multi("FestivalFlag", Dressing.flag(variant), [tr], Meshes.flutter)

static func _star_mesh() -> ArrayMesh:
	var st := Meshes._st()
	for i in 5:
		var a := TAU * i / 5.0 + PI / 2
		var b := a + TAU / 10.0
		var c := a - TAU / 10.0
		var tip := Vector3(cos(a) * 0.2, sin(a) * 0.2, 0)
		for v in [Vector3.ZERO, Vector3(cos(c) * 0.08, sin(c) * 0.08, 0), tip, Vector3.ZERO, tip, Vector3(cos(b) * 0.08, sin(b) * 0.08, 0)]:
			st.set_color(Color("ffe27a"))
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(v)
	return Meshes._finish(st)

# --- shared bits ------------------------------------------------------------------------

func _multi(node_name: String, mesh: Mesh, transforms: Array, mat: Material) -> void:
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

static var _bulb_mat: StandardMaterial3D
static func _bulb_material() -> StandardMaterial3D:
	if _bulb_mat == null:
		_bulb_mat = StandardMaterial3D.new()
		_bulb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_bulb_mat.vertex_color_use_as_albedo = true
		_bulb_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _bulb_mat

## A quad coloured by the particle: unshaded and additive for light (fireworks), otherwise lit like the scene
## so it dims after dark (leaves).
static func _particle_quad(size: Vector2, additive: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if additive else BaseMaterial3D.SHADING_MODE_PER_VERTEX
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if additive:
		m.albedo_texture = SkyAndLight._soft_texture()  # round soft sparks
	q.material = m
	return q

func _process(delta: float) -> void:
	if follow == null:
		return
	if _leaves:
		_leaves.global_position = follow.global_position + Vector3(0, 4.5, 1.0)
	if _bursts.is_empty():
		return
	_burst_wait -= delta
	if _burst_wait > 0.0:
		return
	_burst_wait = _rng.randf_range(0.5, 1.6)
	if GameClock.phase(Game.local_minutes()) in ["dusk", "night"]:
		_launch()
