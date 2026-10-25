class_name ZoneBuilder
extends RefCounted
## Turns a ZoneData grid into a little 3D diorama: one merged ground mesh, MultiMeshes for repeated props,
## buildings, water. Tile (x, y) has its centre at world (x + 0.5, h * 0.5, y + 0.5); rows run south (+z).

const LEVEL := 0.5          # world units per height level
const SKIRT := 1.6          # how far the diorama's outer edge drops
const GROUND_COLOURS := {
	"grass": Color("527f37"), "tall_grass": Color("4f8035"), "path": Color("b9a57c"), "road": Color("55575d"),
	"cobbles": Color("9a8f80"), "sand": Color("cdb57f"), "flowers": Color("5c8f3c"), "shallow": Color("8fa39a"),
	"water": Color("6b7f6a"), "door": Color("c8b48a"), "building": Color("b9a98a"), "floor_wood": Color("7f5a3d"),
	"floor_tile": Color("bdb6a2"), "counter": Color("9a6b43"), "ledge_south": Color("5c8f3c"), "cliff": Color("8c8270"),
	"tree_oak": Color("4f8035"), "tree_pine": Color("4a7634"), "hedge": Color("557f37"), "drystone_wall": Color("5c8f3c"),
	"fence": Color("5c8f3c"), "rock": Color("5c8f3c"),
	"bramble": Color("4f7a35"), "deep_water": Color("34504f"), "scree": Color("8b8780"), "platform": Color("a39a8a"),
	"rail": Color("6e655c"), "level_crossing": Color("7a6650"), "sea": Color("2f4a5c"), "bog": Color("4a3b2a"),
}
const DEEP := ["deep_water", "sea"]
const SIDE_EARTH := Color("6a5238")
const SIDE_ROCK := Color("7d7462")
const CROSSING_DECK := 0.075
const PLATFORM := 0.16       # platforms stand proud of the track
const COPING := Color("d8d2c2")
const SAFETY_LINE := Color("e3c02a")
## Paved tiles: darker and shinier in the rain (vertex alpha 0 in the ground mesh, see ground.gdshader).
const HARD := ["road", "cobbles", "platform", "level_crossing", "door"]
## A bridge deck (a legend_extra tile with "deck": n, the level of the water or ground n below it): its edges
## are a slab this deep instead of an embankment, with the riverbed and the water drawn down at level n.
const DECK_SLAB := 0.3
const DECK_EDGE := Color("4a4f57")

## The level below a bridge deck tile, or -1 for ordinary ground.
static func deck_under(z: ZoneData, p: Vector2i) -> int:
	return int(z.legend_extra.get(z.char_at(p), {}).get("deck", -1))

## Surface height of a tile's ground (water beds sit lower).
static func ground_y(z: ZoneData, p: Vector2i) -> float:
	var t := z.tile_at(p)
	var base := z.height_at(p) * LEVEL
	match t:
		"water":
			return base - 0.4
		"deep_water", "sea":
			return base - 0.6
		"bog":
			return base - 0.08
		"shallow":
			return base - 0.14
		"cliff":
			return base + LEVEL
		"level_crossing":
			return base + CROSSING_DECK  # planked up to the rails
		"platform":
			return base + PLATFORM
	return base

static func build(z: ZoneData) -> Node3D:
	Meshes.materials()
	var root := Node3D.new()
	root.name = "Zone_" + z.id
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(z.id)
	root.add_child(_ground(z, rng))
	var wp := CaribStyles.water_pair(z, false, [Color(0.13, 0.32, 0.42), Color(0.36, 0.62, 0.66)])
	var water := _water(z, ["water", "shallow"], wp[0], wp[1])
	if water:
		root.add_child(water)
	var dp := CaribStyles.water_pair(z, true, [Color(0.07, 0.2, 0.3), Color(0.2, 0.42, 0.52)])
	var deep := _water(z, DEEP, dp[0], dp[1])
	if deep:
		deep.name = "DeepWater"
		root.add_child(deep)
	_props(z, root, rng)
	_buildings(z, root)
	if z.kind == "interior":
		root.add_child(_interior_walls(z))
	return root

# --- ground --------------------------------------------------------------------

static func _ground(z: ZoneData, rng: RandomNumberGenerator) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var occ := occluders(z)
	for y in z.height:
		for x in z.width:
			var p := Vector2i(x, y)
			var t := z.tile_at(p)
			if t == "void":
				continue
			var gy := ground_y(z, p)
			var col: Color = GROUND_COLOURS.get(t, Color("ff00ff"))
			var ex: Dictionary = z.legend_extra.get(z.char_at(p), {})
			if ex.has("colour"):
				col = Color(str(ex.colour))
			col = _vary(t, col, x, y, rng)
			var x0 := float(x)
			var z0 := float(y)
			var a := 0.0 if t in HARD else 1.0
			var soft := 0.0 if z.kind == "interior" else float(SOFT_GROUND.get(t, 0.0))
			_ground_quad(st, Vector3(x0, gy, z0), Vector3(x0 + 1, gy, z0), Vector3(x0 + 1, gy, z0 + 1), Vector3(x0, gy, z0 + 1),
				[_paint(col, x0, z0, a), _paint(col, x0 + 1, z0, a), _paint(col, x0 + 1, z0 + 1, a), _paint(col, x0, z0 + 1, a)],
				[corner_ao(occ, z.width, p, Vector2i(0, 0), gy), corner_ao(occ, z.width, p, Vector2i(1, 0), gy),
				corner_ao(occ, z.width, p, Vector2i(1, 1), gy), corner_ao(occ, z.width, p, Vector2i(0, 1), gy)], soft)
			st.set_uv(Vector2.ZERO)  # sides, lines and ledges: no shade baked, no mottling
			if ex.get("bridge", false):
				continue  # a bridge deck: no earth under it, the bridge prop draws its own sides
			# side faces wherever the neighbour is lower (or missing: the diorama skirt)
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				var q: Vector2i = p + d
				var outside := not z.in_bounds(q) or z.tile_at(q) == "void"
				if outside and z.kind == "interior":
					continue  # rooms float in darkness, no diorama skirt
				var ny := -SKIRT if outside else ground_y(z, q)
				if ny >= gy - 0.001:
					continue
				var side := SIDE_ROCK if t == "cliff" or gy - ny > LEVEL * 1.5 else SIDE_EARTH
				if ex.has("side"):
					side = Color(str(ex.side))  # legend_extra: chalk cliffs and the like
				var lip := col.darkened(0.15)
				if ex.has("deck"):
					ny = maxf(ny, gy - DECK_SLAB)
					side = DECK_EDGE
				if t == "platform":
					side = Color("7a5a48")  # brick platform wall, white coping
					lip = COPING
				_side(st, x0, z0, d, gy, ny, side, lip)
			if t == "platform":
				# yellow safety line along any edge that faces the track
				for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
					if z.is_rail(p + d):
						var c := Vector3(x0 + 0.5 + d.x * 0.36, gy + 0.004, z0 + 0.5 + d.y * 0.36)
						var hx := 0.5 if d.x == 0 else 0.05
						var hz := 0.5 if d.y == 0 else 0.05
						Meshes._quad(st, c + Vector3(-hx, 0, -hz), c + Vector3(hx, 0, -hz), c + Vector3(hx, 0, hz), c + Vector3(-hx, 0, hz), SAFETY_LINE)
			if ex.has("deck"):  # the riverbed far below
				var by := int(ex.deck) * LEVEL - 0.6
				Meshes.quad4(st, Vector3(x0, by, z0), Vector3(x0 + 1, by, z0), Vector3(x0 + 1, by, z0 + 1), Vector3(x0, by, z0 + 1),
					GROUND_COLOURS.deep_water, GROUND_COLOURS.deep_water, GROUND_COLOURS.deep_water, GROUND_COLOURS.deep_water)
			if t == "ledge_south":
				Meshes.box(st, Vector3(x0, gy - 0.18, z0 + 0.82), Vector3(1.0, 0.18, 0.18), SIDE_EARTH, col.darkened(0.1))
	st.index()
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = st.commit()
	mi.material_override = Meshes.ground
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

## Ground that the Medium and High graphics mottle (ground.gdshader `detail`): 1 grassland, 0.5 paths, sand and
## scree. Paving, floors and water stay as painted.
const SOFT_GROUND := {
	"grass": 1.0, "tall_grass": 1.0, "flowers": 1.0, "ledge_south": 1.0, "tree_oak": 1.0, "tree_pine": 1.0,
	"hedge": 1.0, "drystone_wall": 1.0, "fence": 1.0, "rock": 1.0, "bramble": 1.0,
	"path": 0.5, "sand": 0.5, "scree": 0.5, "bog": 0.5,
}
## How much a tile shades the ground at its foot (fake ambient occlusion, ground.gdshader `ao`): walls and
## buildings fully, hedges, trees and rocks a little. Indoors the void beyond the floor is the room's walls.
const OCCLUDERS := {"building": 1.0, "drystone_wall": 0.7, "counter": 0.6, "hedge": 0.5, "tree_oak": 0.35,
	"tree_pine": 0.35, "rock": 0.35, "bramble": 0.3}

## Per tile, packed row by row: [how much it shades its neighbours, its ground height].
static func occluders(z: ZoneData) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(z.width * z.height * 2)
	for y in z.height:
		for x in z.width:
			var p := Vector2i(x, y)
			var t := z.tile_at(p)
			var w: float = OCCLUDERS.get(t, 0.0)
			if t == "void":
				w = 1.0 if z.kind == "interior" else 0.0
			var i := (y * z.width + x) * 2
			out[i] = w
			out[i + 1] = -99.0 if t == "void" else ground_y(z, p)
	return out

## The baked shade (0 open .. 1 tucked in) at one corner of tile p (`c` is (0|1, 0|1)) for ground at height gy:
## the three other tiles meeting at that corner each add their shade, and so does a bank rising above gy.
static func corner_ao(occ: PackedFloat32Array, width: int, p: Vector2i, c: Vector2i, gy: float) -> float:
	var height := occ.size() / 2 / maxi(1, width)
	var sum := 0.0
	for dy in [-1, 0]:
		for dx in [-1, 0]:
			var q := Vector2i(p.x + c.x + dx, p.y + c.y + dy)
			if q == p or q.x < 0 or q.y < 0 or q.x >= width or q.y >= height:
				continue
			var i := (q.y * width + q.x) * 2
			var w := occ[i]
			if occ[i + 1] > gy + 0.2:
				w = maxf(w, clampf((occ[i + 1] - gy) * 1.2, 0.0, 1.0))  # the foot of a bank or cliff
			sum += w
	return clampf(sum * 0.5, 0.0, 1.0)

## A ground quad like Meshes.quad4, with the baked shade per corner in UV.x and the soft-ground mark in UV.y.
static func _ground_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, cols: Array, aos: Array, soft: float) -> void:
	var n := (c - a).cross(b - a).normalized()
	var v := [a, b, c, d]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_color(cols[i])
		st.set_normal(n)
		st.set_uv(Vector2(aos[i], soft))
		st.add_vertex(v[i])

static func _side(st: SurfaceTool, x0: float, z0: float, d: Vector2i, top: float, bottom: float, col: Color, lip: Color) -> void:
	var a: Vector3
	var b: Vector3
	match d:
		Vector2i(0, 1):
			a = Vector3(x0, 0, z0 + 1)
			b = Vector3(x0 + 1, 0, z0 + 1)
		Vector2i(0, -1):
			a = Vector3(x0 + 1, 0, z0)
			b = Vector3(x0, 0, z0)
		Vector2i(1, 0):
			a = Vector3(x0 + 1, 0, z0 + 1)
			b = Vector3(x0 + 1, 0, z0)
		_:
			a = Vector3(x0, 0, z0)
			b = Vector3(x0, 0, z0 + 1)
	var mid := maxf(bottom, top - 0.12)
	Meshes._quad(st, Vector3(a.x, top, a.z), Vector3(b.x, top, b.z), Vector3(b.x, mid, b.z), Vector3(a.x, mid, a.z), lip)
	Meshes._quad(st, Vector3(a.x, mid, a.z), Vector3(b.x, mid, b.z), Vector3(b.x, bottom, b.z), Vector3(a.x, bottom, a.z), col)

static var _noise: FastNoiseLite

## Low-frequency colour drift across the ground so it reads as painted, not tiled.
static func _paint(col: Color, x: float, z: float, alpha := 1.0) -> Color:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.frequency = 0.09
		_noise.seed = 7
	var n := _noise.get_noise_2d(x, z)
	var warm := Color(col.r * 1.06, col.g * 1.02, col.b * 0.9)
	var cool := Color(col.r * 0.9, col.g * 0.97, col.b * 1.08)
	var out := col.lerp(warm if n > 0.0 else cool, absf(n) * 0.9).lightened(n * 0.06)
	out.a = alpha
	return out

static func _vary(t: String, col: Color, x: int, y: int, rng: RandomNumberGenerator) -> Color:
	match t:
		"cobbles":
			col = col.darkened(rng.randf_range(0.0, 0.07))
		"floor_tile":
			col = col.darkened(0.08) if (x + y) % 2 == 0 else col
		"floor_wood":
			col = col.darkened(0.07) if x % 2 == 0 else col.lightened(0.03)
		"road":
			pass
	return col.lightened(rng.randf_range(-0.02, 0.02))

# --- water ---------------------------------------------------------------------

## Surface height of water on a tile (boats float here).
static func water_y(z: ZoneData, p: Vector2i) -> float:
	return z.height_at(p) * LEVEL - (0.05 if z.tile_at(p) == "shallow" else 0.1)

static func _water(z: ZoneData, kinds: Array, deep_col: Color, shallow_col: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	for y in z.height:
		for x in z.width:
			var p := Vector2i(x, y)
			var t := z.tile_at(p)
			var under := deck_under(z, p) if "water" in kinds else -1
			if t not in kinds and under < 0:
				continue
			any = true
			var wy := water_y(z, p) if under < 0 else under * LEVEL - 0.1
			# green channel: 0 where the corner touches land (water.gdshader's shore foam), white for open water
			var v := [Vector3(x, wy, y), Vector3(x + 1, wy, y), Vector3(x + 1, wy, y + 1), Vector3(x, wy, y + 1)]
			var cs := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(Color(1, 1.0 - shore_at(z, p, cs[i]), 1))
				st.set_normal(Vector3.UP)
				st.add_vertex(v[i])
	if not any:
		return null
	st.index()
	var mi := MeshInstance3D.new()
	mi.name = "Water"
	mi.mesh = st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://art/shaders/water.gdshader")
	mat.set_shader_parameter("deep", deep_col)
	mat.set_shader_parameter("shallow", shallow_col)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.add_to_group(WATER_GROUP)  # SkyAndLight sets its detail and the sky's colour in it
	return mi

const WATER_GROUP := "zone_water"
const WATERY := ["water", "shallow", "deep_water", "sea"]

## 1 when any tile meeting at corner `c` of water tile p is dry land (a bridge deck counts as water: its river
## runs on underneath). The zone's edge counts as more water.
static func shore_at(z: ZoneData, p: Vector2i, c: Vector2i) -> float:
	for dy in [-1, 0]:
		for dx in [-1, 0]:
			var q := Vector2i(p.x + c.x + dx, p.y + c.y + dy)
			if not z.in_bounds(q):
				continue
			var t := z.tile_at(q)
			if t not in WATERY and t != "void" and deck_under(z, q) < 0:
				return 1.0
	return 0.0

# --- props ---------------------------------------------------------------------

## Tile name -> [mesh constructor name, variants, foliage?]
const TILE_PROPS := {
	"tree_oak": ["oak", 3, true], "tree_pine": ["pine", 3, true], "hedge": ["hedge_segment", 2, true],
	"drystone_wall": ["wall_segment", 3, false], "fence": ["fence_segment", 1, false], "rock": ["rock", 3, false],
	"flowers": ["flower_patch", 3, true], "tall_grass": ["tall_grass_tuft", 3, true], "counter": ["counter", 1, false],
	"bramble": ["bramble", 2, true], "scree": ["scree_rubble", 3, false], "rail": ["rail_segment", 1, false],
	"level_crossing": ["crossing_deck", 1, false],
	"bog": ["reeds", 3, true],
}
const LINEAR := ["hedge", "drystone_wall", "fence", "rail"]
## Point props (one tile, blocking unless "walk": true). Floating ones sit on the water surface.
const POINT_PROPS := ["lamp_post", "bench", "bush", "birch", "oak", "pine", "rock", "market_stall", "planter", "phone_box",
	"post_box", "bookshelf", "potted_plant", "table", "bed", "standing_stone", "slate_heap", "boat", "canal_boat", "bollard",
	"buoy", "lighthouse", "statue", "harp", "clock_tower", "shard", "buffer_stop", "tunnel_portal",
	"bunting", "flagpole", "washing_line", "hanging_basket", "rug", "fireplace", "wall_picture", "clock", "kitchen_dresser",
	"fryer", "menu_board", "piano", "telescope", "plant_stand", "sofa", "display_case", "cascade", "sheep",
	"field_gate", "limestone_pavement", "window", "cat_bowl", "owl_perch", "kettle_table", "specimen_shelf", "wall_map", "mirror",
	# the Keeper venues (Dressing.VENUE_PROPS)
	"stadium_stand", "rugby_posts", "floodlight", "puddle", "pitch_line", "gantry_crane", "ship_ribs", "steel_plates",
	"hall_stage", "tea_urn", "stacked_chairs", "currach", "lobster_pots", "harbour_arch", "fae_lantern", "toadstool_ring",
	"clootie_tree", "curling_house", "curling_stones", "brick_arch", "band_kit", "stage_light", "slate_stack", "slate_wagon",
	"crypt_arch", "candelabra", "tomb_chest", "brazier", "city_window", "enclosure_banner", "creature_cage", "loom",
	# Shropshire: the Iron Bridge over its "bridge" deck tiles, gliders over the Long Mynd
	"iron_bridge", "glider",
	# East Anglia (Landmarks.EA_PROPS)
	"windpump", "punt", "maths_bridge", "wherry",
	# the Cotswolds and Oxford (Landmarks.COTS_PROPS)
	"sighs_bridge", "cheese_wheel",
	# the South East
	"pier_ruin",
	# the far south (IceStyles.PROPS)
	"penguin", "seal", "iceberg", "tussac", "skidoo", "headstone", "catcher_hulk", "twin_otter",
	# British Overseas Territories (CaribStyles.PROPS)
	"palm", "cannon", "salt_heap", "buried_roof",
	"slot_machine", "roulette_table", "card_table", "tote_board", "velvet_rope", "horse_statue"]
## Cloth meshes that ripple (flutter shader) and glow meshes that add light (firelight shader).
const CLOTH := ["bunting", "flag", "washing_line"]
const FLOATING := ["boat", "canal_boat", "buoy", "punt", "wherry", "iceberg", "catcher_hulk"]

## Tall grass with "prop": "short" is cropped grass: low tufts, but still somewhere for a creature to hide.
static func tuft_height(prop_name: String) -> float:
	return 0.5 if prop_name == "short" else 1.0

static func _props(z: ZoneData, root: Node3D, rng: RandomNumberGenerator) -> void:
	var buckets := {}  # "ctor:variant" -> Array[Transform3D]
	for y in z.height:
		for x in z.width:
			var p := Vector2i(x, y)
			var t := z.tile_at(p)
			var extra: Dictionary = z.legend_extra.get(z.char_at(p), {})
			var prop_name: String = extra.get("prop", "")
			var spec: Array = []
			if prop_name in ["heather", "reeds", "none", "gritstone"]:
				if prop_name == "none":
					continue
				spec = [{"heather": "heather_tuft", "gritstone": "gritstone_edge"}.get(prop_name, prop_name), 3, prop_name != "gritstone"]
			elif prop_name == "pavement":
				spec = ["limestone_pavement", 3, false]  # limestone pavement laid over a walkable tile
			elif CaribStyles.TILE_PROPS.has(prop_name):
				spec = CaribStyles.TILE_PROPS[prop_name]  # palms on a sandy tile
			else:
				if prop_name != "":
					t = {"oak": "tree_oak", "pine": "tree_pine", "birch": "tree_oak", "bush": "rock", "rock": "rock"}.get(prop_name, t)
				if not TILE_PROPS.has(t):
					continue
				spec = TILE_PROPS[t]
			var variant := rng.randi() % int(spec[1])
			var basis := Basis()
			if t in ZoneData.RAIL_TILES:
				if z.rail_axis(p) == Vector2i(0, 1):
					basis = Basis(Vector3.UP, PI / 2)
			elif t in LINEAR:
				var ns := z.tile_at(p + Vector2i(0, -1)) == t or z.tile_at(p + Vector2i(0, 1)) == t
				var ew := z.tile_at(p + Vector2i(-1, 0)) == t or z.tile_at(p + Vector2i(1, 0)) == t
				if ns and not ew:
					basis = Basis(Vector3.UP, PI / 2)
			elif prop_name == "gritstone":
				pass  # an edge faces south, square to the tile, so a row of them makes one crag
			elif prop_name == "pavement":
				basis = Basis(Vector3.UP, PI * 0.5 * (rng.randi() % 4))  # slabs keep square to the tile
			elif t != "counter":
				basis = Basis(Vector3.UP, rng.randf() * TAU)
				var s := rng.randf_range(0.9, 1.15) if t.begins_with("tree") else 1.0
				basis = basis.scaled(Vector3(s, s, s))
				basis = basis.scaled(Vector3(1, tuft_height(prop_name), 1))
			var origin := Vector3(x + 0.5, ground_y(z, p), y + 0.5)
			if t == "level_crossing":
				origin.y = z.height_at(p) * LEVEL
				_add(buckets, "rail_segment:0", Transform3D(basis, origin))
			if t.begins_with("tree"):
				origin += Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
			var key := "%s:%d" % [spec[0], variant]
			if not buckets.has(key):
				buckets[key] = []
			buckets[key].append(Transform3D(basis, origin))
	for s in z.signs:
		var sp := Vector2i(int(s.x), int(s.y))
		match str(s.get("kind", "")):
			"radio":  # a wireless set on a sideboard (world/wireless_meshes.gd)
				var on_counter := z.tile_at(sp) == "counter"  # no sideboard then: it stands on the counter (0.9 high, set 0.5 up)
				_add(buckets, "radio:%d" % int(on_counter), Transform3D(Basis(), Vector3(sp.x + 0.5, ground_y(z, sp) + (0.4 if on_counter else 0.0), sp.y + 0.5)))
			"plaque":  # a round plaque on the south wall of the building tile, "dx" tiles from its centre
				_add(buckets, "plaque:%d" % int(bool(s.get("green", false))),
					Transform3D(Basis(), Vector3(sp.x + 0.5 + float(s.get("dx", 0.0)), ground_y(z, sp), sp.y + 0.955)))
			_:
				var post := "sign_post:0"
				if str(s.get("plaque", "")) != "":  # a Gazetteer plaque: a heritage lectern, green in Ireland (PlaqueMeshes)
					post = "lectern:%d" % int(Standing.nation_for_zone(z.id) == "ireland")
				_add(buckets, post, Transform3D(Basis(), Vector3(sp.x + 0.5, ground_y(z, sp), sp.y + 0.5)))
	for pr in z.props:
		var pt: String = pr.get("type", "")
		if pt in POINT_PROPS:
			var pos := Vector2i(int(pr.x), int(pr.y))
			var py := prop_y(z, pt, pos)
			var rot := deg_to_rad(float(pr.get("rot", 0)))
			if pt in ZoneData.RAIL_CAPS:
				py = z.height_at(pos) * LEVEL
				if not pr.has("rot"):
					rot = cap_angle(z.cap_inward(pos))
			var tr := Transform3D(Basis(Vector3.UP, rot), Vector3(pos.x + 0.5, py, pos.y + 0.5))
			if pt in CONTACT_SHADOWED:  # a soft shadow on the floor, so furniture sits on it rather than hovering
				_add(buckets, "contact_shadow:0", Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.8)), Vector3(pos.x + 0.5, py + 0.012, pos.y + 0.5)))
			if pt == "rug":
				# w x h tiles from the anchor tile's north-west corner, flat on the floor
				var rw := float(pr.get("w", 1))
				var rh := float(pr.get("h", 1))
				tr = Transform3D(Basis.from_scale(Vector3(rw, 1, rh)), Vector3(pos.x + rw * 0.5, py, pos.y + rh * 0.5))
			var variant := int(pr.get("variant", 0))
			_add(buckets, "%s:%d" % [pt, variant], tr)
			match pt:
				"lamp_post":
					_add(buckets, "lamp_bulb:0", tr)
					_add(buckets, "lamp_pool:0", lamp_pool(z, pos))
				"flagpole":
					_add(buckets, "flag:%d" % variant, tr)
				"fireplace":
					_add(buckets, "fireplace_fire:0", tr)
			if Dressing.VENUE_GLOWS.has(pt):
				_add(buckets, "%s:%d" % [Dressing.VENUE_GLOWS[pt], variant], tr)
	for key in buckets:
		var parts: PackedStringArray = key.split(":")
		var mesh: ArrayMesh = _ctor(parts[0], int(parts[1]))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		var list: Array = buckets[key]
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Props_" + key.replace(":", "_")
		mmi.multimesh = mm
		var foliage := parts[0] in ["heather_tuft", "reeds", "bramble", "birch", "bush"]
		for tname in TILE_PROPS:
			if TILE_PROPS[tname][0] == parts[0]:
				foliage = TILE_PROPS[tname][2]
		if parts[0] == "contact_shadow":
			mmi.material_override = _contact_material()
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif parts[0] == "lamp_bulb":
			mmi.material_override = Meshes.glow
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif parts[0] == "lamp_pool":
			mmi.material_override = Meshes.pool
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif parts[0] == "fireplace_fire" or parts[0] in Dressing.VENUE_GLOWS.values():
			mmi.material_override = Meshes.firelight
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif parts[0] in CLOTH:
			mmi.material_override = Meshes.flutter
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif parts[0] in FLOATING:
			mmi.material_override = Meshes.bobbing_calm if parts[0] == "canal_boat" else Meshes.bobbing
		else:
			mmi.material_override = Meshes.foliage if foliage else Meshes.solid
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if parts[0] in ["tall_grass_tuft", "flower_patch", "plaque"] else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(mmi)

const POOL_SIZE := 3.4
## The pool of light under the lamp post on tile p, a little above the ground so it never z-fights. The pool is
## flat, so next to water or a drop (a bridge parapet, a quay, a cliff edge) it would hang in the air as a
## glowing disc: there it shrinks and keeps to the lamp's own side, or to its own tile when the drop is all round.
static func lamp_pool(z: ZoneData, p: Vector2i) -> Transform3D:
	var gy := ground_y(z, p)
	var away := Vector2.ZERO
	var drops := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q := p + Vector2i(dx, dy)
			if (dx == 0 and dy == 0) or not z.in_bounds(q):
				continue
			if ground_y(z, q) < gy - 0.2 or z.tile_at(q) in ["water", "shallow", "deep_water", "sea"]:
				away -= Vector2(dx, dy)
				drops += 1
	var centre := Vector3(p.x + 0.5, gy + 0.04, p.y + 0.5)
	if drops == 0:
		return Transform3D(Basis.from_scale(Vector3.ONE * POOL_SIZE), centre)
	if away.length() < 0.5:
		return Transform3D(Basis.from_scale(Vector3.ONE * 1.2), centre)
	var dir := away.normalized()
	return Transform3D(Basis.from_scale(Vector3.ONE * 2.2), centre + Vector3(dir.x, 0, dir.y) * 0.6)

## Where a point prop stands on tile p: the water's surface for boats, buoys and waterfalls, else the ground.
static func prop_y(z: ZoneData, pt: String, p: Vector2i) -> float:
	return water_y(z, p) if pt in FLOATING or pt == "cascade" else ground_y(z, p)

## Yaw that turns a mesh's local +X to point along grid direction `d` (x east, y south).
static func cap_angle(d: Vector2i) -> float:
	return atan2(-float(d.y), float(d.x))

static func _add(buckets: Dictionary, key: String, tr: Transform3D) -> void:
	if not buckets.has(key):
		buckets[key] = []
	buckets[key].append(tr)

## Furniture that gets a soft contact shadow on the floor (characters have their own blob).
const CONTACT_SHADOWED := ["table", "bench", "sofa", "bed", "bookshelf", "kitchen_dresser", "piano", "display_case",
	"specimen_shelf", "plant_stand", "potted_plant", "kettle_table", "fryer", "telescope", "stacked_chairs", "tea_urn",
	"market_stall", "statue", "tomb_chest", "loom", "harp"]

static var contact_material: StandardMaterial3D

static func _contact_shadow_mesh() -> ArrayMesh:
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	q.orientation = PlaneMesh.FACE_Y
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, q.get_mesh_arrays())
	return am

static func _contact_material() -> StandardMaterial3D:
	if contact_material == null:
		contact_material = StandardMaterial3D.new()
		contact_material.albedo_texture = CharSprite._blob_tex()
		contact_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		contact_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		contact_material.albedo_color = Color(0, 0, 0, 0.38)
	return contact_material

static func _ctor(name: String, variant: int) -> ArrayMesh:
	match name:
		"contact_shadow":
			return _contact_shadow_mesh()
		"oak":
			return Meshes.oak(variant)
		"pine":
			return Meshes.pine(variant)
		"birch":
			return Meshes.birch(variant)
		"bush":
			return Meshes.bush(variant)
		"rock":
			return Meshes.rock(variant)
		"hedge_segment":
			return Meshes.hedge_segment(variant)
		"wall_segment":
			return Meshes.wall_segment(variant)
		"fence_segment":
			return Meshes.fence_segment()
		"flower_patch":
			return Meshes.flower_patch(variant)
		"tall_grass_tuft":
			return Meshes.tall_grass_tuft(variant)
		"heather_tuft":
			return Meshes.heather_tuft(variant)
		"gritstone_edge":
			return Meshes.gritstone_edge(variant)
		"reeds":
			return Meshes.reeds(variant)
		"lamp_post":
			return Meshes.lamp_post()
		"lamp_bulb":
			return Meshes.lamp_bulb()
		"bench":
			return Meshes.bench()
		"sign_post":
			return Meshes.sign_post()
		"radio":
			return WirelessMeshes.radio(variant)
		"plaque":
			return WirelessMeshes.plaque(variant == 1)
		"lectern":
			return PlaqueMeshes.lectern(variant)
		"market_stall":
			return Meshes.market_stall(variant)
		"bookshelf":
			return Meshes.bookshelf(variant)
		"potted_plant":
			return Meshes.potted_plant(variant)
		"table":
			return Meshes.table(variant)
		"bed":
			return Meshes.bed(variant)
		"planter":
			return Meshes.planter(variant)
		"phone_box":
			return Meshes.phone_box(variant)
		"post_box":
			return Meshes.post_box()
		"counter":
			return Meshes.counter()
		"standing_stone":
			return Landmarks.standing_stone(variant)
		"slate_heap":
			return Landmarks.slate_heap(variant)
		"scree_rubble":
			return Landmarks.scree_rubble(variant)
		"bramble":
			return Landmarks.bramble(variant)
		"rail_segment":
			return Landmarks.rail_segment()
		"crossing_deck":
			return Landmarks.crossing_deck()
		"buffer_stop":
			return Landmarks.buffer_stop()
		"tunnel_portal":
			return Landmarks.tunnel_portal(variant)
		"cascade":
			return Landmarks.cascade(variant)
		"sheep":
			return Landmarks.sheep(variant)
		"field_gate":
			return Landmarks.field_gate(variant)
		"limestone_pavement":
			return Landmarks.limestone_pavement(variant)
		"boat":
			return Landmarks.boat(variant)
		"canal_boat":
			return Landmarks.canal_boat(variant)
		"bollard":
			return Landmarks.bollard()
		"buoy":
			return Landmarks.buoy(variant)
		"lighthouse":
			return Landmarks.lighthouse()
		"statue":
			return Landmarks.statue(variant)
		"harp":
			return Landmarks.harp()
		"clock_tower":
			return Landmarks.clock_tower()
		"shard":
			return Landmarks.shard()
		"iron_bridge":
			return Landmarks.iron_bridge()
		"glider":
			return Landmarks.glider(variant)
		"pier_ruin":
			return Landmarks.pier_ruin()
		"lamp_pool":
			return Dressing.pool_quad()
		"bunting":
			return Dressing.bunting(variant)
		"flagpole":
			return Dressing.flagpole(variant)
		"flag":
			return Dressing.flag(variant)
		"washing_line":
			return Dressing.washing_line(variant)
		"hanging_basket":
			return Dressing.hanging_basket(variant)
		"rug":
			return Dressing.rug(variant)
		"fireplace":
			return Dressing.fireplace()
		"fireplace_fire":
			return Dressing.fireplace_fire()
		"wall_picture":
			return Dressing.wall_picture(variant)
		"clock":
			return Dressing.clock()
		"kitchen_dresser":
			return Dressing.kitchen_dresser()
		"fryer":
			return Dressing.fryer()
		"menu_board":
			return Dressing.menu_board()
		"piano":
			return Dressing.piano()
		"telescope":
			return Dressing.telescope()
		"plant_stand":
			return Dressing.plant_stand(variant)
		"sofa":
			return Dressing.sofa(variant)
		"display_case":
			return Dressing.display_case(variant)
		"window":
			return Dressing.window()
		"cat_bowl":
			return Dressing.cat_bowl()
		"owl_perch":
			return Dressing.owl_perch()
		"kettle_table":
			return Dressing.kettle_table()
		"specimen_shelf":
			return Dressing.specimen_shelf(variant)
		"wall_map":
			return Dressing.wall_map()
		"mirror":
			return LooksMirror.mesh()
	if name in CaribStyles.PROPS:
		return CaribStyles.prop(name, variant)
	if name in Landmarks.COTS_PROPS:
		return Landmarks.cots_prop(name, variant)
	if name in Landmarks.EA_PROPS:
		return Landmarks.ea_prop(name, variant)
	if name in IceStyles.PROPS:
		return IceStyles.prop(name, variant)
	if name in Dressing.VENUE_PROPS or name in Dressing.VENUE_GLOWS.values():
		return Dressing.venue_prop(name, variant)
	push_warning("ZoneBuilder: unknown prop mesh '%s'" % name)
	return Meshes.rock(0)

# --- buildings -----------------------------------------------------------------

## Also records every chimney top (world space) as the root's "chimneys" meta, for AmbientLife's smoke.
static func _buildings(z: ZoneData, root: Node3D) -> void:
	var chimneys := PackedVector3Array()
	var bodies := []  # of {pr, body, door_x}: their names go up as signs once every building stands (Signage)
	for pr in z.props:
		if pr.get("type") != "building":
			continue
		var bx := int(pr.x)
		var by := int(pr.y)
		var w := int(pr.w)
		var d := int(pr.h)
		var door_x := -1
		for x in range(bx, bx + w):
			if z.tile_at(Vector2i(x, by + d - 1)) == "door":
				door_x = x - bx
		var meshes: Array = Meshes.building(w, d, str(pr.get("style", "red_brick")), door_x, hash(z.id) + bx * 31 + by, str(pr.get("pennant_region", z.region)))  # a castle may fly its own colours
		# stand on the door's ground, so on a slope the door meets the path rather than sinking into the hill
		var gy := z.height_at(Vector2i(bx + door_x, by + d - 1) if door_x >= 0 else Vector2i(bx, by)) * LEVEL
		var body := MeshInstance3D.new()
		body.name = "Building_%d_%d" % [bx, by]
		body.mesh = meshes[0]
		body.material_override = Meshes.solid
		body.position = Vector3(bx, gy, by)
		root.add_child(body)
		if meshes.size() > 2:
			for c in meshes[2]:
				chimneys.append(body.position + c)
		var win := MeshInstance3D.new()
		win.mesh = meshes[1]
		win.material_override = Meshes.windows
		win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(win)
		bodies.append({"pr": pr, "body": body, "door_x": door_x})
	Signage.build(z, root, bodies)
	root.set_meta("chimneys", chimneys)

# --- interiors -----------------------------------------------------------------

## Cave interiors (a dark zone or the "cave" stage) get rough rock walls and stalactites, not plaster.
static func is_cave(z: ZoneData) -> bool:
	return z.kind == "interior" and (z.dark or z.stage == "cave")

static func _interior_walls(z: ZoneData) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cave := is_cave(z)
	var plaster := Color("6f685d") if cave else Color("cfc3a8")
	var skirting := Color("4a443c") if cave else Color("6b4a32")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(z.id + "_rock")
	for y in z.height:
		for x in z.width:
			var p := Vector2i(x, y)
			if z.tile_at(p) != "void":
				continue
			var south := z.tile_at(p + Vector2i(0, 1))
			var north := z.tile_at(p + Vector2i(0, -1))
			var east := z.tile_at(p + Vector2i(1, 0))
			var west := z.tile_at(p + Vector2i(-1, 0))
			var floor_s := south != "" and south != "void"
			var floor_n := north != "" and north != "void"
			var floor_e := east != "" and east != "void"
			var floor_w := west != "" and west != "void"
			if cave and (floor_s or floor_e or floor_w or floor_n):
				_rock(st, p, rng, plaster)
				continue
			if floor_s:
				Meshes.box(st, Vector3(x, 0, y + 0.6), Vector3(1, 2.4, 0.4), plaster, plaster.darkened(0.3))
				Meshes.box(st, Vector3(x, 0, y + 0.95), Vector3(1, 0.2, 0.06), skirting)
			elif floor_e or floor_w:
				var ox := x + (0.7 if floor_e else 0.0)
				Meshes.box(st, Vector3(ox, 0, y), Vector3(0.3, 1.2, 1), plaster.darkened(0.08), plaster.darkened(0.3))
			elif floor_n:
				Meshes.box(st, Vector3(x, 0, y), Vector3(1, 0.25, 0.3), plaster.darkened(0.1), skirting)
	if cave:
		_stalactites(st, z, rng)
	st.index()
	var mi := MeshInstance3D.new()
	mi.name = "Walls"
	mi.mesh = st.commit()
	mi.material_override = Meshes.solid
	return mi

## One tile of cave wall: uneven stacked blocks of stone, a different height and tint each.
static func _rock(st: SurfaceTool, p: Vector2i, rng: RandomNumberGenerator, base: Color) -> void:
	for i in 3:
		var w := rng.randf_range(0.35, 0.6)
		var h := rng.randf_range(1.6, 2.6)
		var ox := rng.randf_range(0.0, 1.0 - w)
		var oz := rng.randf_range(0.0, 1.0 - w)
		var c := base.lightened(rng.randf_range(-0.12, 0.1))
		Meshes.box(st, Vector3(p.x + ox, 0, p.y + oz), Vector3(w, h, w), c, c.lightened(0.1))

## Cones of rock hanging over scattered floor tiles, a few tiles per room.
static func _stalactites(st: SurfaceTool, z: ZoneData, rng: RandomNumberGenerator) -> void:
	for y in z.height:
		for x in z.width:
			var t := z.tile_at(Vector2i(x, y))
			if t == "void" or t == "" or rng.randf() > 0.07:
				continue
			var c := Color("857d70")
			for k in 3:
				var half := 0.12 - k * 0.04
				var length := 0.3 + rng.randf() * 0.15
				Meshes.box(st, Vector3(x + 0.5 - half, 2.5 - (k + 1) * length, y + 0.5 - half), Vector3(half * 2, length, half * 2), c.darkened(k * 0.08))
