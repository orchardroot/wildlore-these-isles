class_name Landmarks
extends RefCounted
## Bigger and stranger meshes for M2: mills, terraces, castles, the Liver Building, stations, an aqueduct,
## plus point props (boats, standing stones, slate heaps). Same rules as Meshes: vertex colour, low poly,
## origin at the footprint's north-west corner for buildings and at the tile centre for props.

const BRICK := Color("9c4a3a")
const DARK_BRICK := Color("7a3a30")
const SANDSTONE := Color("b5654a")   # Chester's red sandstone
const SLATE := Color("4d5563")
const SLATE_WALL := Color("7d838a")
const PEAT := Color("4a3626")
const LIMESTONE := Color("c9c0aa")
const PORTLAND := Color("d8d2c2")    # Liver Building granite and Portland stone, near enough
const IRON := Color("3c4450")
const GLASS := Color.WHITE

## Wider Isles, the Shannon and Limerick (see the Shannon section at the end of the file).
const SHANNON_STYLES := ["shannon_tower_house", "king_johns", "clare_thatch", "limerick_georgian", "airport_terminal", "flying_boat", "hydro_station", "thomond_stadium", "milk_market"]
## Building styles handled here rather than by the generic house in Meshes.building.
const SPECIAL := ["edinburgh_tenement", "glasgow_tenement", "aberdeen_granite", "orkney_flagstone", "highland_sandstone", "harled_cottage", "harbour_row", "dublin_georgian", "ulster_terrace", "kilkenny_limestone", "winding_gear", "valley_terrace", "steam_loco", "ironworks", "whaling_shed", "whaling_tanks", "whalers_church", "whaler_villa", "polar_hut", "research_station", "halley_module", "hangar", "shannon_tower_house", "limerick_georgian", "martyrs_obelisk", "palace_pier", "marble_arch_cave",
	"swansea_market", "glass_tower", "gantry_crane", "cantilever_crane", "titanic", "mill", "castle", "cathedral",
	"liver_building", "station", "aqueduct", "chapel", "terrace", "tudor", "slate_cottage", "lighthouse_house",
	"round_tower", "passage_tomb", "field_barn", "casino", "grandstand", "bookmaker", "bottle_kiln", "potbank",
	"blackpool_tower", "big_one", "blackpool_tram", "pier_pavilion", "veranda_shop", "guest_house", "suspension_bridge",
	"ss_great_britain", "caravel", "hot_air_balloon", "painted_terrace", "bristol_byzantine", "tower_house",
	"tower_house_granite", "thatch_cottage", "irish_shopfront", "turf_stack", "obelisk", "tau_cross", "oast_house",
	"weatherboard", "flint_cottage", "regency", "pavilion", "i360", "canterbury_cathedral", "westgate",
	"windmill_black", "windmill_white", "humber_bridge", "the_deep", "lincoln_cathedral", "tank_memorial", "monolith",
	"limestone_church", "pantile_brick", "pantile_chalk", "georgian_brick", "limestone_house", "trawler",
	"spire_memorial", "canal_tunnel", "leeds_town_hall", "corn_exchange", "market_hall", "abbey_ruin", "parsonage",
	"weavers_cottage", "pennine_church", "football_stadium", "engine_house", "waterfront_museum", "pier", "cave_mouth",
	"three_cliffs", "smeaton_tower", "exeter_cathedral", "city_wall", "cob_thatch", "football_ground", "aquarium",
	"mayflower_steps", "erne_terrace", "watergate", "palladian", "monument_column", "magpie", "flax_mill",
	"blast_furnace", "gault", "flint", "flint_gable", "thatch", "college", "kings_chapel", "portico", "ely_cathedral",
	"norwich_cathedral", "norman_keep", "football_stand", "forth_bridge", "forth_approach", "road_bridge",
	"bridge_girder", "cable_stayed", "crow_step", "culross_palace", "tenement", "st_andrews_ruin", "discovery_ship",
	"va_dundee", "tay_bridge", "caithness_flag", "flag_fence", "mey_castle", "dunrobin", "jog_signpost", "sea_stacks",
	"well_house", "kirk_ruin", "surf_shack", "jog_inn", "flows_lookout", "red_sandstone", "border_stone", "castle_red",
	"painted_pink", "painted_yellow", "painted_blue", "painted_green", "painted_red", "painted_teal", "granite",
	"distillery", "mccaig", "paddle_steamer", "blackhouse", "croft_house", "granite_house", "harbour_white",
	"lews_castle", "cotswold_house", "cotswold_cottage", "wool_church", "oxford_college", "oxford_tower",
	"oxford_church", "radcliffe_camera", "raf_hangar", "control_tower", "raf_aircraft", "raf_block", "gib_house", "gib_rock",
	"europa_lighthouse", "flat_house", "greek_theatre", "raf_terminal",
	"sa_colonial", "jacobs_ladder", "radome", "tin_cottage", "whalebone_arch",
	"pitcairn_house", "boat_shed", "base_hangar", "base_tower", "base_block", "plantation_ruin", "island_church",
	"jersey_granite", "guernsey_granite", "jersey_tower", "little_chapel",
	"andaluz_house", "andaluz_church", "frontier_post", "fort_ruin", "venetian_gate", "venetian_wall", "selimiye", "han",
	"kioski_house", "orthodox_church", "checkpoint_booth", "un_tower", "minster"]

## Doors: where each style's door sits on its tile (see _door and friends), for the swing as you go in.
## {x, w, y, h, z}: left edge and width across the door column, bottom and height, z of the door's face from
## the footprint's south edge. Styles drawn by Meshes.building (and anything unknown) use DOOR_PLAIN.
const DOOR_PLAIN := {"x": 0.22, "w": 0.56, "y": 0.18, "h": 0.9, "z": -0.02}
const DOOR_RECTS := {
	"winding_gear": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.1, "z": -0.05},
	"valley_terrace": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 0.9, "z": -0.02},
	"steam_loco": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 0.9, "z": -0.02},
	"ironworks": {"x": 0.12, "w": 0.76, "y": 0.0, "h": 1.35, "z": -0.5},
	"mill": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.1, "z": -0.02},
	"station": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.0, "z": -0.02},
	"chapel": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.1, "z": -0.02},
	"liver_building": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.2, "z": -0.02},
	"terrace": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 0.9, "z": -0.02},
	"tudor": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 0.9, "z": -0.02},
	"slate_cottage": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 0.9, "z": -0.02},
	"lighthouse_house": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 0.9, "z": -0.02},
	"castle": {"x": 0.2, "w": 0.6, "y": 0.0, "h": 1.1, "z": 0.11},
	"castle_red": {"x": 0.2, "w": 0.6, "y": 0.0, "h": 1.1, "z": 0.11},
	"paddle_steamer": {"x": 0.22, "w": 0.56, "y": 0.7, "h": 0.9, "z": -0.6},
	"cathedral": {"x": 0.15, "w": 0.7, "y": 0.0, "h": 1.3, "z": 0.03},
	"minster": {"x": 0.08, "w": 0.84, "y": 0.0, "h": 1.32, "z": -0.19},
	"glass_tower": {"x": 0.15, "w": 0.7, "y": 0.0, "h": 1.2, "z": 0.02},
	"canal_tunnel": {"x": 0.24, "w": 0.52, "y": 0.0, "h": 0.95, "z": -0.04},
	"leeds_town_hall": {"x": 0.15, "w": 0.7, "y": 0.4, "h": 1.3, "z": -0.94},
	"corn_exchange": {"x": 0.2, "w": 0.6, "y": 0.0, "h": 1.1, "z": -0.02},
	"market_hall": {"x": 0.12, "w": 0.76, "y": 0.2, "h": 1.2, "z": -0.02},
	"abbey_ruin": {"x": 0.2, "w": 0.6, "y": 0.0, "h": 1.2, "z": -0.02},
	"painted_terrace": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 0.9, "z": -0.02},
	"bristol_byzantine": {"x": 0.22, "w": 0.56, "y": 0.2, "h": 1.0, "z": -0.02},
	"football_stadium": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.0, "z": 0.13},
	"swansea_market": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.1, "z": 0.13},
	"engine_house": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.2, "z": -0.12},
	"waterfront_museum": {"x": 0.22, "w": 0.56, "y": 0.16, "h": 1.0, "z": -0.02},
	"cave_mouth": {"x": 0.1, "w": 0.8, "y": 0.0, "h": 1.1, "z": -0.1},
	"palladian": {"x": 0.2, "w": 0.6, "y": 0.15, "h": 1.2, "z": -0.78},
	"marble_arch_cave": {"x": 0.12, "w": 0.76, "y": 0.0, "h": 1.05, "z": -0.1},
	"portico": {"x": 0.15, "w": 0.7, "y": 0.22, "h": 1.3, "z": -0.7},
	"lincoln_cathedral": {"x": 0.15, "w": 0.7, "y": 0.0, "h": 1.3, "z": 0.03},
	"limestone_church": {"x": 0.15, "w": 0.7, "y": 0.0, "h": 1.3, "z": 0.03},
	"the_deep": {"x": 0.2, "w": 0.6, "y": 0.0, "h": 1.0, "z": 0.0},
}
const DOOR_OPEN_ANGLE := -1.75     # radians about the hinge: swings out toward you, about 100 degrees
const DOOR_SWING_SECS := 0.16
const DOOR_WOOD := Color("3b2a22")
static var _doorway_mat: StandardMaterial3D
static var _leaf_mat: StandardMaterial3D

static func door_rect(style: String) -> Dictionary:
	return DOOR_RECTS.get(style, DOOR_PLAIN)

## A door that opens: a dark doorway over the painted door, and a leaf on a hinge ("Hinge", turned by
## DOOR_OPEN_ANGLE to open). Local origin is the door column's south-west corner at ground level.
static func door_swing(style: String) -> Node3D:
	var r := door_rect(style)
	if _doorway_mat == null:
		_doorway_mat = StandardMaterial3D.new()
		_doorway_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_doorway_mat.albedo_color = Color(0.03, 0.025, 0.03)
		_leaf_mat = StandardMaterial3D.new()
		_leaf_mat.albedo_color = DOOR_WOOD
	var root := Node3D.new()
	root.name = "DoorSwing"
	var hole := MeshInstance3D.new()
	hole.name = "Doorway"
	var hm := BoxMesh.new()
	hm.size = Vector3(float(r.w), float(r.h), 0.02)
	hole.mesh = hm
	hole.material_override = _doorway_mat
	hole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hole.position = Vector3(float(r.x) + float(r.w) * 0.5, float(r.y) + float(r.h) * 0.5, float(r.z) + 0.012)
	root.add_child(hole)
	var hinge := Node3D.new()
	hinge.name = "Hinge"
	hinge.position = Vector3(float(r.x), float(r.y), float(r.z) + 0.03)
	root.add_child(hinge)
	var leaf := MeshInstance3D.new()
	leaf.name = "Leaf"
	var lm := BoxMesh.new()
	lm.size = Vector3(float(r.w), float(r.h), 0.05)
	leaf.mesh = lm
	leaf.material_override = _leaf_mat
	leaf.position = Vector3(float(r.w) * 0.5, float(r.h) * 0.5, 0.0)
	hinge.add_child(leaf)
	return root

## Per-window variety for the night: shared by every _window in one building() call.
static var _wr := RandomNumberGenerator.new()
## Chimney tops (local) collected while building, for the smoke.
static var _chimneys := PackedVector3Array()

## A pane's vertex colour: rgb = brightness when lit (0 = an empty, dark room), alpha = how late in the night
## it goes out (1 = burns all night). See SkyAndLight.lateness and art/shaders/windows.gdshader.
static func window_colour(rng: RandomNumberGenerator) -> Color:
	if rng.randf() < 0.15:
		return Color(0, 0, 0, 1)
	var b := rng.randf_range(0.55, 1.0)
	var bedtime := rng.randf_range(0.1, 0.95) if rng.randf() < 0.4 else 1.0
	return Color(b, b, b, bedtime)

## Returns [body_mesh, windows_mesh, chimney tops (PackedVector3Array, local)].
static func building(w: int, d: int, style: String, door_x: int, seed_value: int, region := "") -> Array:
	var rng := Meshes._rng(seed_value)
	var st := Meshes._st()
	var wst := Meshes._st()
	_wr.seed = seed_value * 7 + 3
	_chimneys = PackedVector3Array()
	match style:
		"mill":
			_mill(st, wst, w, d, door_x, rng)
		"castle":
			_castle(st, wst, w, d, door_x, region)
		"castle_red":
			_castle(st, wst, w, d, door_x, region, SANDSTONE.lightened(0.04))  # Carlisle: red sandstone all through
		"red_sandstone":
			# Carlisle's streets: deep red sandstone, slate roofs, a pale string course and stone-framed windows
			_house(st, wst, w, d, door_x, rng, Color("a9503c"), SLATE, 2, true, false)
			Meshes.box(st, Vector3(0.0, 1.28, d), Vector3(w, 0.08, 0.06), Color("d9b79c"))
		"border_stone":
			# the Borders: grey whinstone with crow-stepped gables
			_house(st, wst, w, d, door_x, rng, Color("9a958a"), Color("5b6068"), 2, false, false)
			_crow_steps(st, w, d)
		"cathedral":
			_cathedral(st, wst, w, d, door_x, SANDSTONE)
		"minster":
			MinsterStyle.build(st, wst, w, d, door_x)
		"chapel":
			_chapel(st, wst, w, d, door_x)
		"round_tower":
			_round_tower(st, wst, w, d, door_x)
		"passage_tomb":
			_passage_tomb(st, w, d, door_x)
		"shannon_tower_house", "king_johns", "clare_thatch", "limerick_georgian", "airport_terminal", "flying_boat", "hydro_station", "thomond_stadium", "milk_market":
			_shannon(st, wst, w, d, style, door_x, rng, region)
		"field_barn":
			_field_barn(st, w, d, rng)
		"smeaton_tower":
			_smeaton_tower(st, wst, w, d, door_x)
		"exeter_cathedral":
			_exeter_cathedral(st, wst, w, d, door_x)
		"city_wall":
			_city_wall(st, w, d, rng)
		"cob_thatch":
			_cob_thatch(st, wst, w, d, door_x, rng)
		"football_ground":
			_football_ground(st, wst, w, d, door_x)
		"aquarium":
			_aquarium(st, wst, w, d, door_x)
		"mayflower_steps":
			_mayflower_steps(st, w, d)
		"erne_terrace":
			_erne_terrace(st, wst, w, d, door_x, rng)
		"watergate":
			_watergate(st, wst, w, d)
		"palladian":
			_palladian(st, wst, w, d, door_x)
		"monument_column":
			_monument_column(st, w, d)
		"marble_arch_cave":
			_marble_arch_cave(st, w, d, door_x)
		"tower_house", "tower_house_granite":
			_tower_house(st, wst, w, d, door_x, Color("a59f92") if style == "tower_house_granite" else Color("938d82"), style == "tower_house_granite")
		"thatch_cottage":
			_thatch_cottage(st, wst, w, d, door_x, rng)
		"irish_shopfront":
			_irish_shopfront(st, wst, w, d, door_x, rng)
		"turf_stack":
			_turf_stack(st, w, d, rng)
		"obelisk":
			_obelisk(st, w, d)
		"tau_cross":
			_tau_cross(st, w, d)
		"oast_house", "weatherboard", "flint_cottage", "regency", "pavilion", "i360", "palace_pier", "canterbury_cathedral", "westgate", "windmill_black", "windmill_white":
			_south_east(st, wst, w, d, door_x, rng, style)
		"humber_bridge":
			_humber_bridge(st, w, d)
		"the_deep":
			_the_deep(st, wst, w, d, door_x)
		"lincoln_cathedral":
			_lincoln_cathedral(st, wst, w, d, door_x)
		"tank_memorial":
			_tank_memorial(st, w, d)
		"monolith":
			_monolith(st, w, d)
		"limestone_church":
			_cathedral(st, wst, w, d, door_x, LINCS_LIMESTONE.darkened(0.06))
		"pantile_brick":
			_house(st, wst, w, d, door_x, rng, BRICK.lightened(0.04), PANTILE, 2, false, false)
		"pantile_chalk":
			_house(st, wst, w, d, door_x, rng, CHALK, PANTILE, 1, false, false)
		"georgian_brick":
			_house(st, wst, w, d, door_x, rng, DARK_BRICK.lightened(0.06), SLATE, 3, true, false)
		"limestone_house":
			_house(st, wst, w, d, door_x, rng, LINCS_LIMESTONE, PANTILE.darkened(0.12), 2, false, false)
		"trawler":
			_trawler(st, wst, w, d, door_x)
		"spire_memorial":
			_spire_memorial(st, w, d)
		"forth_bridge", "forth_approach", "road_bridge", "bridge_girder", "cable_stayed", "crow_step", "culross_palace", "tenement", \
				"st_andrews_ruin", "martyrs_obelisk", "discovery_ship", "va_dundee", "tay_bridge":
			_fife(st, wst, w, d, door_x, rng, style)
		"caithness_flag", "flag_fence", "mey_castle", "dunrobin", "jog_signpost", "sea_stacks", "well_house", "kirk_ruin", \
				"surf_shack", "jog_inn", "flows_lookout":
			_far_north(st, wst, style, w, d, door_x, rng)
		"casino":
			_casino(st, wst, w, d, door_x)
		"grandstand":
			_grandstand(st, wst, w, d, door_x)
		"bookmaker":
			_bookmaker(st, wst, w, d, door_x, region)
		"blackhouse", "croft_house", "granite_house", "harbour_white", "lews_castle":
			_hebrides(st, wst, w, d, door_x, rng, style)
		"cotswold_house", "cotswold_cottage", "wool_church", "oxford_college", "oxford_tower", "oxford_church", "radcliffe_camera":
			cotswolds_building(st, wst, w, d, door_x, rng, style)
		"liver_building":
			_liver(st, wst, w, d, door_x)
		"station":
			_station(st, wst, w, d, door_x)
		"aqueduct":
			_aqueduct(st, w, d)
		"gantry_crane":
			_gantry(st, w, d)
		"cantilever_crane":
			_cantilever(st, w, d)
		"titanic":
			_titanic(st, wst, w, d, door_x, rng)
		"glass_tower":
			_glass_tower(st, wst, w, d, door_x)
		"football_stadium":
			_football_stadium(st, wst, w, d, door_x)
		"engine_house":
			_engine_house(st, wst, w, d, door_x)
		"market_hall":
			_market_hall(st, wst, w, d, door_x)
		"waterfront_museum":
			_waterfront_museum(st, wst, w, d, door_x)
		"pier":
			_pier(st, w, d)
		"cave_mouth":
			_cave_mouth(st, w, d, door_x, rng)
		"three_cliffs":
			_three_cliffs(st, w, d, rng)
		"terrace":
			_house(st, wst, w, d, door_x, rng, BRICK, SLATE, 2, true, false)
		"tudor":
			_house(st, wst, w, d, door_x, rng, Color("ece5d2"), Color("5a4a44"), 2, false, true)
		"slate_cottage":
			_house(st, wst, w, d, door_x, rng, SLATE_WALL, SLATE.darkened(0.2), 1, false, false)
		"canal_tunnel":
			_canal_tunnel(st, w, d, door_x)
		"leeds_town_hall":
			_leeds_town_hall(st, wst, w, d, door_x)
		"corn_exchange":
			_corn_exchange(st, wst, w, d, door_x)
		"swansea_market":
			_swansea_market_hall(st, wst, w, d, door_x)
		"abbey_ruin":
			_abbey_ruin(st, w, d, door_x)
		"parsonage":
			_parsonage(st, wst, w, d, door_x)
		"weavers_cottage":
			_weavers_cottage(st, wst, w, d, door_x, rng)
		"pennine_church":
			_cathedral(st, wst, w, d, door_x, GRIT_SOOT.lightened(0.08))
		"bottle_kiln":
			_bottle_kiln(st, w, d, door_x)
		"potbank":
			_potbank(st, wst, w, d, door_x, rng)
		"blackpool_tower":
			_blackpool_tower(st, wst, w, d, door_x)
		"big_one":
			_big_one(st, wst, w, d)
		"blackpool_tram":
			_blackpool_tram(st, wst, w, d)
		"pier_pavilion":
			_pier_pavilion(st, wst, w, d, door_x)
		"veranda_shop":
			_veranda_shop(st, wst, w, d, door_x, rng)
		"guest_house":
			_guest_house(st, wst, w, d, door_x, rng)
		"suspension_bridge":
			_suspension_bridge(st)
		"ss_great_britain":
			_ss_great_britain(st, wst, w, d)
		"caravel":
			_caravel(st, w, d)
		"hot_air_balloon":
			_hot_air_balloon(st, w, d, rng)
		"painted_terrace":
			_painted_terrace(st, wst, w, d, door_x, rng)
		"bristol_byzantine":
			_bristol_byzantine(st, wst, w, d, door_x)
		"magpie":
			_magpie(st, wst, w, d, door_x, rng)
		"flax_mill":
			_flax_mill(st, wst, w, d, door_x)
		"edinburgh_tenement", "glasgow_tenement", "aberdeen_granite", "orkney_flagstone", "highland_sandstone", "harled_cottage", "harbour_row", "dublin_georgian", "ulster_terrace", "kilkenny_limestone":
			StreetsSI.build(st, wst, w, d, door_x, rng, style)
		"raf_hangar":
			OverseasStyles.raf_hangar(st, wst, w, d, door_x)
		"control_tower":
			OverseasStyles.control_tower(st, wst, w, d, door_x)
		"raf_aircraft":
			OverseasStyles.raf_aircraft(st, w, d)
		"raf_block":
			OverseasStyles.raf_block(st, wst, w, d, door_x, rng)
		"raf_terminal":
			OverseasStyles.raf_terminal(st, wst, w, d, door_x)
		"gib_house":
			OverseasStyles.gib_house(st, wst, w, d, door_x, rng)
		"gib_rock":
			OverseasStyles.gib_rock(st, wst, w, d, door_x, rng)
		"europa_lighthouse":
			OverseasStyles.europa_lighthouse(st, wst, w, d, door_x)
		"flat_house":
			OverseasStyles.flat_house(st, wst, w, d, door_x, rng)
		"greek_theatre":
			OverseasStyles.greek_theatre(st, wst, w, d, door_x)
		"whaling_shed", "whaling_tanks", "whalers_church", "whaler_villa", "polar_hut", "research_station", "halley_module", "hangar":
			IceStyles.build(st, wst, w, d, door_x, rng, style)
		"winding_gear":
			ValleyStyles.winding_gear(st, wst, w, d, door_x)
		"valley_terrace":
			ValleyStyles.terrace(st, wst, w, d, door_x, rng)
		"steam_loco":
			ValleyStyles.steam_loco(st, wst, w, d, door_x)
		"ironworks":
			ValleyStyles.ironworks(st, wst, w, d, door_x)
		"sa_colonial":
			SouthAtlanticStyles.colonial(st, wst, w, d, door_x, rng)
		"jacobs_ladder":
			SouthAtlanticStyles.ladder(st, w, d)
		"radome":
			SouthAtlanticStyles.radome(st, wst, w, d, door_x, rng)
		"tin_cottage":
			SouthAtlanticStyles.tin_cottage(st, wst, w, d, door_x, rng)
		"whalebone_arch":
			SouthAtlanticStyles.whalebone_arch(st, w, d)
		"pitcairn_house":
			PacificStyles.house(st, wst, w, d, door_x, rng)
		"boat_shed":
			PacificStyles.boat_shed(st, wst, w, d, door_x)
		"base_hangar":
			PacificStyles.base_hangar(st, wst, w, d, door_x)
		"base_tower":
			PacificStyles.control_tower(st, wst, w, d, door_x)
		"base_block":
			PacificStyles.base_block(st, wst, w, d, door_x, rng)
		"plantation_ruin":
			PacificStyles.plantation_ruin(st, wst, w, d, door_x, rng)
		"island_church":
			PacificStyles.island_church(st, wst, w, d, door_x)
		"jersey_granite":
			IslandStyles.jersey_granite(st, wst, w, d, door_x, rng)
		"guernsey_granite":
			IslandStyles.guernsey_granite(st, wst, w, d, door_x, rng)
		"jersey_tower":
			IslandStyles.jersey_tower(st, wst, w, d, door_x)
		"little_chapel":
			IslandStyles.little_chapel(st, wst, w, d, door_x, rng)
		"andaluz_house", "andaluz_church", "frontier_post", "fort_ruin", "venetian_gate", "venetian_wall", "selimiye", "han", "kioski_house", "orthodox_church", "checkpoint_booth", "un_tower":
			BordersStyles.build(st, wst, w, d, door_x, rng, style)
		"blast_furnace":
			_blast_furnace(st, wst, w, d, door_x)
		"gault", "flint", "flint_gable", "thatch", "college", "kings_chapel", "portico", "ely_cathedral", "norwich_cathedral", "norman_keep", "football_stand":
			ea_building(st, wst, style, w, d, door_x, rng)
		"painted_pink", "painted_yellow", "painted_blue", "painted_green", "painted_red", "painted_teal":
			_house(st, wst, w, d, door_x, rng, PAINTS[style], SLATE, 2, false, false)
			_trim(st, w, d)
		"granite":
			_house(st, wst, w, d, door_x, rng, PAINTS[style], SLATE, 2, false, false)
		"distillery":
			_distillery(st, wst, w, d, door_x, rng)
		"mccaig":
			_mccaig(st, w, d, door_x)
		"paddle_steamer":
			_steamer(st, wst, w, d, door_x)
		_:
			_house(st, wst, w, d, door_x, rng, BRICK, SLATE, 2, false, false)
	return [Meshes._finish(st), Meshes._finish(wst), _chimneys]

## Painted harbour fronts (Tobermory) and Oban's grey-pink granite.
const PAINTS := {"painted_pink": Color("e8a2b4"), "painted_yellow": Color("f0cf6a"), "painted_blue": Color("6fa4d2"),
	"painted_green": Color("8cc48c"), "painted_red": Color("d4605a"), "painted_teal": Color("5fb4ac"), "granite": Color("b9a8a2")}

# --- houses ------------------------------------------------------------------

## A pitched-roof house. terrace: a chimney per two tiles and a door per... one door, but party walls marked.
## tudor: black timber framing over white render, jettied upper floor.
static func _house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator,
		wall: Color, roof: Color, storeys: int, terrace: bool, tudor: bool) -> void:
	var hgt := 1.15 * storeys + 0.2
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), wall)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), wall.darkened(0.3))
	if tudor:
		# jetty: the upper floor oversails the street a little
		Meshes.box(st, Vector3(0.0, 1.2, 0.0), Vector3(w, hgt - 1.2, d + 0.12), wall)
		var beam := Color("2b2422")
		Meshes.box(st, Vector3(0, 1.16, d + 0.06), Vector3(w, 0.1, 0.08), beam)
		Meshes.box(st, Vector3(0, hgt - 0.08, d + 0.06), Vector3(w, 0.1, 0.08), beam)
		for i in range(w + 1):
			Meshes.box(st, Vector3(minf(i, w - 0.08), 0.16, d - 0.02), Vector3(0.08, 1.0, 0.06), beam)
			Meshes.box(st, Vector3(minf(i, w - 0.08), 1.26, d + 0.08), Vector3(0.08, hgt - 1.3, 0.06), beam)
			if i < w:
				# a diagonal brace, as two stepped boxes (keeps the low-poly look)
				Meshes.box(st, Vector3(i + 0.3, 1.5, d + 0.09), Vector3(0.4, 0.07, 0.05), beam)
	_roof(st, w, d, hgt, roof, wall)
	if terrace:
		for i in range(1, w, 2):
			Meshes.box(st, Vector3(i - 0.2, hgt + 0.3, d * 0.5 - 0.2), Vector3(0.4, 0.95, 0.4), wall.darkened(0.25))
			Meshes.box(st, Vector3(i - 0.12, hgt + 1.25, d * 0.5 - 0.12), Vector3(0.1, 0.14, 0.1), Color("a0553c"))
			Meshes.box(st, Vector3(i + 0.04, hgt + 1.25, d * 0.5 - 0.12), Vector3(0.1, 0.14, 0.1), Color("a0553c"))
			Meshes.box(st, Vector3(i - 0.03, 0.16, d - 0.04), Vector3(0.06, hgt - 0.2, 0.05), wall.darkened(0.15))
			_chimneys.append(Vector3(i, hgt + 1.39, d * 0.5 - 0.07))
	else:
		var cx := rng.randf_range(0.6, maxf(0.7, w - 0.9))
		Meshes.box(st, Vector3(cx, hgt + 0.3, d * 0.5 - 0.2), Vector3(0.35, 0.95, 0.4), wall.darkened(0.2) if not tudor else Color("8a4b3b"))
		_chimneys.append(Vector3(cx + 0.175, hgt + 1.25, d * 0.5))
	_door(st, door_x, d + (0.0 if not tudor else 0.0), wall)
	for s in storeys:
		var wy := 0.4 + 1.15 * s
		for x in w:
			if x == door_x and s == 0:
				continue
			_window(st, wst, x + 0.27, wy, d + (0.12 if tudor and s > 0 else 0.0), 0.46, 0.56, wall.lightened(0.2))

static func _roof(st: SurfaceTool, w: float, d: float, hgt: float, roof: Color, wall: Color, rise_k := 0.38) -> void:
	var eave := 0.18
	var rise := minf(1.2, d * rise_k)
	var a := Vector3(-eave, hgt, -eave)
	var b := Vector3(w + eave, hgt, -eave)
	var c := Vector3(w + eave, hgt, d + eave)
	var dd := Vector3(-eave, hgt, d + eave)
	var r0 := Vector3(-eave, hgt + rise, d * 0.5)
	var r1 := Vector3(w + eave, hgt + rise, d * 0.5)
	Meshes._quad(st, r0, r1, c, dd, roof)
	Meshes._quad(st, r1, r0, a, b, roof.darkened(0.15))
	Meshes._tri(st, r0, dd, a, wall.darkened(0.05))
	Meshes._tri(st, r1, b, c, wall.darkened(0.08))
	Meshes._quad(st, dd, c, b, a, roof.darkened(0.4))

static func _door(st: SurfaceTool, door_x: int, d: float, wall: Color, h := 0.9) -> void:
	if door_x < 0:
		return
	Meshes.box(st, Vector3(door_x + 0.22, 0.16, d - 0.08), Vector3(0.56, h, 0.06), Color("3b2a22"))
	Meshes.box(st, Vector3(door_x + 0.15, 0.16 + h, d - 0.09), Vector3(0.7, 0.08, 0.08), wall.lightened(0.2))

## A window on the south face: frame into the body mesh, glass into the glow mesh (lit at night).
static func _window(st: SurfaceTool, wst: SurfaceTool, x: float, y: float, d: float, ww: float, wh: float, frame: Color) -> void:
	Meshes.box(st, Vector3(x, y - 0.06, d - 0.07), Vector3(ww, wh + 0.1, 0.04), frame)
	Meshes.box(wst, Vector3(x + 0.05, y, d - 0.065), Vector3(ww - 0.1, wh - 0.02, 0.04), window_colour(_wr))

# --- industry ----------------------------------------------------------------

## A Lancashire cotton mill: four storeys of windows, a flat roof and a tall round chimney.
static func _mill(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var storeys := 4
	var hgt := 0.95 * storeys + 0.3
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), BRICK, BRICK.darkened(0.35))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.2, d), DARK_BRICK)
	Meshes.box(st, Vector3(-0.05, hgt - 0.12, -0.05), Vector3(w + 0.1, 0.16, d + 0.1), LIMESTONE)
	for s in storeys:
		Meshes.box(st, Vector3(0.0, 0.95 * s + 0.88, d - 0.06), Vector3(w, 0.06, 0.04), LIMESTONE)
		for x in w:
			if x == door_x and s == 0:
				continue
			_window(st, wst, x + 0.22, 0.3 + 0.95 * s, d, 0.56, 0.55, LIMESTONE)
	# water tower at one end and the chimney at the other
	Meshes.box(st, Vector3(0.1, hgt, 0.2), Vector3(1.2, 1.0, 1.2), BRICK.darkened(0.1), LIMESTONE)
	var cx := w - 1.0
	Meshes.cylinder(st, Vector3(cx, 0, d * 0.4), 0.45, hgt + 3.4, 8, DARK_BRICK)
	Meshes.cylinder(st, Vector3(cx, hgt + 3.2, d * 0.4), 0.48, 0.25, 8, LIMESTONE)
	_chimneys.append(Vector3(cx, hgt + 3.5, d * 0.4))
	_door(st, door_x, d, BRICK, 1.1)

## Station building with a glass canopy reaching one tile south over the platform.
static func _station(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var hgt := 1.6
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), BRICK)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), DARK_BRICK)
	_roof(st, w, d, hgt, SLATE, BRICK, 0.3)
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.25, 0.45, d, 0.5, 0.7, LIMESTONE)
	_door(st, door_x, d, BRICK, 1.0)
	# canopy on iron columns over the platform
	var green := Color("2f5a4a")
	for x in range(0, w + 1, 2):
		Meshes.box(st, Vector3(minf(x, w - 0.1), 0, d + 0.85), Vector3(0.1, 1.5, 0.1), green)
	Meshes.box(st, Vector3(0, 1.5, d - 0.05), Vector3(w, 0.08, 1.05), Color("9fb3b8"))
	Meshes.box(st, Vector3(0, 1.4, d + 0.9), Vector3(w, 0.12, 0.08), green)
	# station clock
	Meshes.box(st, Vector3(w * 0.5 - 0.25, 1.05, d + 0.88), Vector3(0.5, 0.36, 0.08), Color("f4efe2"))

# --- grand buildings ---------------------------------------------------------

## Crenellated curtain wall with round corner towers and a gatehouse on the door column.
static func _castle(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, region := "", stone := Color("9d968a")) -> void:
	var wall_h := 2.2
	var t := 0.6
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, wall_h, t), stone)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(t, wall_h, d), stone.darkened(0.04))
	Meshes.box(st, Vector3(w - t, 0, 0), Vector3(t, wall_h, d), stone.darkened(0.04))
	Meshes.box(st, Vector3(0, 0, d - t), Vector3(w, wall_h, t), stone)
	# courtyard
	Meshes.box(st, Vector3(t, 0, t), Vector3(w - 2 * t, 0.05, d - 2 * t), Color("7f8a5a"))
	_merlons(st, 0, w, 0.0, wall_h, stone, true)
	_merlons(st, 0, w, d - t, wall_h, stone, true)
	_merlons(st, 0, d, 0.0, wall_h, stone, false)
	_merlons(st, 0, d, w - t, wall_h, stone, false)
	for c in [Vector2(0.4, 0.4), Vector2(w - 0.4, 0.4), Vector2(0.4, d - 0.4), Vector2(w - 0.4, d - 0.4)]:
		Meshes.cylinder(st, Vector3(c.x, 0, c.y), 0.85, wall_h + 1.0, 8, stone.lightened(0.05))
		Meshes.cylinder(st, Vector3(c.x, wall_h + 1.0, c.y), 0.82, 0.3, 8, stone.darkened(0.1))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.4, 0, d - 0.9), Vector3(1.8, wall_h + 1.0, 1.0), stone.lightened(0.08))
		Meshes.box(st, Vector3(door_x + 0.2, 0, d + 0.05), Vector3(0.6, 1.1, 0.06), Color("2a221e"))
		_window(st, wst, door_x + 0.3, wall_h + 0.2, d + 0.1, 0.4, 0.4, stone.lightened(0.2))
	# a pennant on the first tower, and on the far one too on a bigger castle
	var poles := [Vector2(0.4, 0.4)]
	if w >= 6:
		poles.append(Vector2(w - 0.4, 0.4))
	for p in poles:
		Meshes.box(st, Vector3(p.x - 0.025, wall_h + 1.3, p.y - 0.025), Vector3(0.05, 1.0, 0.05), Color("3b2a22"))
		_pennant(st, Vector3(p.x + 0.03, wall_h + 2.25, p.y), region)

## Pennant cloth colours (also the tests' way of telling one nation's from another's).
const PENNANT_RED := Color("c8102e")
const PENNANT_WHITE := Color("f4f1e8")
const PENNANT_BLUE := Color("0065bd")
const PENNANT_GREEN := Color("1f7a3a")
const PENNANT_ORANGE := Color("ff883e")
const PENNANT_BLACK := Color("1c1c1e")
const PENNANT_GOLD := Color("e0b03a")
const PENNANT_L := 0.78     # hoist to tips
const PENNANT_H := 0.42     # at the hoist; it tapers to the fly
const PENNANT_NOTCH := 0.32 # how far the swallowtail's fork cuts back, as a fraction of the length
## Which pennant a region flies.
const PENNANT_KINDS := {
	"cheshire": "st_george", "peak": "st_george", "manchester": "st_george", "merseyside": "st_george",
	"midlands": "st_george", "south_england": "st_george", "yorkshire": "st_george", "north_east": "st_george",
	"cumbria": "st_george", "lancashire": "st_george", "cornwall": "st_piran", "north_wales": "wales", "mid_wales": "wales",
	"south_wales": "wales", "scotland": "saltire", "ireland": "ireland", "ireland_west": "ireland",
	"ireland_east": "ireland", "man": "man",
	"east_anglia": "st_george",
	"south_east": "st_george",
}

## A castle's swallowtail pennant on its own, the hoist's top at the origin, flying along +x.
static func pennant(region := "") -> ArrayMesh:
	var st := Meshes._st()
	_pennant(st, Vector3.ZERO, region)
	return Meshes._finish(st)

## A tapering, forked pennant hung from `top` (the hoist's top corner), flying east in the XY plane, cloth
## both sides. A grid of cells, each half (upper and lower) squeezed so its fly edge runs from the tip in to
## the fork; a cell takes the colour of the region's design at its centre.
static func _pennant(st: SurfaceTool, top: Vector3, region: String) -> void:
	var kind: String = PENNANT_KINDS.get(region, "")
	var cols := 12
	var rows := 4  # per half
	var yc := top.y - PENNANT_H * 0.5
	for half in 2:
		for r in rows:
			for c in cols:
				var v0 := (r + half * rows) / float(rows * 2)
				var v1 := (r + 1 + half * rows) / float(rows * 2)
				var u0 := c / float(cols)
				var u1 := (c + 1) / float(cols)
				var a := _pennant_pt(top, yc, u0, v0)
				var b := _pennant_pt(top, yc, u1, v0)
				var cc := _pennant_pt(top, yc, u1, v1)
				var d := _pennant_pt(top, yc, u0, v1)
				var mid := (a + b + cc + d) * 0.25
				var col := _pennant_colour(kind, (mid.x - top.x) / PENNANT_L, (v0 + v1) * 0.5)
				Meshes._quad(st, a, b, cc, d, col)
				Meshes._quad(st, a, d, cc, b, col)  # the back

## A point on the pennant: u along its length (0 hoist .. 1 fly edge at this height), v down it (0 .. 1).
static func _pennant_pt(top: Vector3, yc: float, u: float, v: float) -> Vector3:
	var fly := 1.0 - PENNANT_NOTCH * (1.0 - absf(2.0 * v - 1.0))
	var x := u * fly
	var taper := 1.0 - 0.45 * x
	return Vector3(top.x + x * PENNANT_L, yc + (0.5 - v) * PENNANT_H * taper, top.z)

## The design: x along the length (0 .. 1 at the tips), v down it. Crosses sit in the hoist square.
static func _pennant_colour(kind: String, x: float, v: float) -> Color:
	var hoist := x < 0.44
	match kind:
		"st_george":
			if hoist and (absf(x - 0.21) < 0.07 or absf(v - 0.5) < 0.13):
				return PENNANT_RED
			return PENNANT_WHITE
		"st_piran":
			if hoist and (absf(x - 0.21) < 0.07 or absf(v - 0.5) < 0.13):
				return PENNANT_WHITE
			return PENNANT_BLACK
		"saltire":
			if hoist and absf(absf(x - 0.21) / 0.21 - absf(v - 0.5) / 0.5) < 0.3:
				return PENNANT_WHITE
			return PENNANT_BLUE
		"wales":
			if x < 0.16:
				return PENNANT_RED
			return PENNANT_WHITE if v < 0.5 else PENNANT_GREEN
		"ireland":
			if x < 0.33:
				return PENNANT_GREEN
			return PENNANT_WHITE if x < 0.62 else PENNANT_ORANGE
		"man":
			return PENNANT_GOLD if x < 0.16 else PENNANT_RED
	return PENNANT_GOLD if x < 0.16 else PENNANT_RED

static func _merlons(st: SurfaceTool, from: float, to: float, at: float, y: float, col: Color, along_x: bool) -> void:
	var x := from
	while x < to - 0.3:
		if along_x:
			Meshes.box(st, Vector3(x, y, at), Vector3(0.3, 0.3, 0.6), col.lightened(0.05))
		else:
			Meshes.box(st, Vector3(at, y, x), Vector3(0.6, 0.3, 0.3), col.lightened(0.05))
		x += 0.6

## Nave with a steep roof, a square west tower with pinnacles, tall lancet windows.
static func _cathedral(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, stone: Color) -> void:
	var tower_w := mini(3, w - 2)
	var nave_h := 2.6
	Meshes.box(st, Vector3(tower_w, 0, 0.3), Vector3(w - tower_w, nave_h, d - 0.6), stone)
	_roof_at(st, tower_w, w, 0.3, d - 0.3, nave_h, 1.3, SLATE.darkened(0.1), stone)
	var th := 5.6
	Meshes.box(st, Vector3(0, 0, 0), Vector3(tower_w, th, d), stone.darkened(0.04))
	for c in [Vector2(0, 0), Vector2(tower_w - 0.3, 0), Vector2(0, d - 0.3), Vector2(tower_w - 0.3, d - 0.3)]:
		Meshes.box(st, Vector3(c.x, th, c.y), Vector3(0.3, 0.8, 0.3), stone.lightened(0.06))
	_merlons(st, 0, tower_w, d - 0.6, th, stone, true)
	# _window puts its frame across a face at z - 0.05 (a house's front): the nave's front is at d - 0.3 and the
	# tower's at d, so pass those plus 0.05 or the glass sits inside the stone
	# pointed lancets between buttresses (kept under the name band, see Signage.front), a belfry lancet on the tower
	for x in range(tower_w, w):
		MinsterStyle._lancet(st, wst, x + 0.32, 0.6, d - 0.25, 0.36, 1.3, stone.lightened(0.2))
		if x > tower_w:
			Meshes.box(st, Vector3(x - 0.09, 0, d - 0.32), Vector3(0.18, 2.0, 0.3), stone.darkened(0.07))
	MinsterStyle._lancet(st, wst, tower_w * 0.5 - 0.3, 3.4, d + 0.05, 0.6, 1.1, stone.lightened(0.2))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0, d - 0.05), Vector3(0.7, 1.3, 0.08), Color("3b2a22"))

static func _roof_at(st: SurfaceTool, x0: float, x1: float, z0: float, z1: float, h: float, rise: float, roof: Color, wall: Color) -> void:
	var a := Vector3(x0, h, z0)
	var b := Vector3(x1, h, z0)
	var c := Vector3(x1, h, z1)
	var dd := Vector3(x0, h, z1)
	var zm := (z0 + z1) * 0.5
	var r0 := Vector3(x0, h + rise, zm)
	var r1 := Vector3(x1, h + rise, zm)
	Meshes._quad(st, r0, r1, c, dd, roof)
	Meshes._quad(st, r1, r0, a, b, roof.darkened(0.15))
	Meshes._tri(st, r0, dd, a, wall.darkened(0.05))
	Meshes._tri(st, r1, b, c, wall.darkened(0.08))

## A Welsh chapel: grey render, gable to the street, two tall arched windows and a date stone.
static func _chapel(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var wall := Color("a7a59c")
	var h := 2.4
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), wall)
	# gable faces south: ridge runs north-south
	var a := Vector3(-0.15, h, -0.1)
	var b := Vector3(w + 0.15, h, -0.1)
	var c := Vector3(w + 0.15, h, d + 0.1)
	var dd := Vector3(-0.15, h, d + 0.1)
	var r0 := Vector3(w * 0.5, h + 1.1, -0.1)
	var r1 := Vector3(w * 0.5, h + 1.1, d + 0.1)
	Meshes._quad(st, r1, r0, a, dd, SLATE)
	Meshes._quad(st, r0, r1, c, b, SLATE.darkened(0.15))
	Meshes._tri(st, dd, c, r1, wall.lightened(0.04))
	Meshes._tri(st, b, a, r0, wall.darkened(0.06))
	Meshes.box(st, Vector3(w * 0.5 - 0.35, h + 0.2, d - 0.02), Vector3(0.7, 0.35, 0.06), Color("dcd6c4"))
	for x in [0.5, w - 1.0]:
		_window(st, wst, x, 0.5, d, 0.5, 1.5, wall.lightened(0.25))
	_door(st, door_x, d, wall, 1.1)

## An Irish round tower: a tall tapering stone needle with a conical cap, standing at the front of its plot (the door
## faces south); the rest of the footprint is a little walled churchyard.
static func _round_tower(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("a39d8e")
	var r := minf(w, 2.0) * 0.45
	var c := Vector3(w * 0.5, 0, d - r - 0.08)
	var h := 5.6
	Meshes.cylinder(st, c, r, h, 10, stone)
	Meshes.cone(st, c + Vector3(0, h, 0), r * 0.95, 1.3, 10, stone.darkened(0.12), Meshes._rng(41))
	for y in [2.4, 3.6, 4.8]:
		_window(st, wst, c.x - 0.1, y, c.z + r * 0.9 + 0.05, 0.2, 0.32, stone.darkened(0.2))
	if door_x >= 0:  # one door, centred on the tower whichever tile the warp is on
		Meshes.box(st, Vector3(c.x - 0.25, 0.1, c.z + r - 0.12), Vector3(0.5, 0.85, 0.12), Color("3b2a22"))
		Meshes.box(st, Vector3(c.x - 0.31, 0.95, c.z + r - 0.13), Vector3(0.62, 0.08, 0.13), stone.lightened(0.2))
	# churchyard wall round the rest of the plot
	var wall := stone.darkened(0.1)
	var back := c.z - r
	if back > 0.6:
		Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, 0.45, 0.2), wall)
		Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(0.2, 0.45, back), wall)
		Meshes.box(st, Vector3(w - 0.25, 0, 0.05), Vector3(0.2, 0.45, back), wall)

## A Neolithic passage tomb (Newgrange): a low grassy mound ringed at the front by white quartz, with the dark
## passage mouth and its carved entrance stone on the south side.
static func _passage_tomb(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var grass := Color("5f8a3e")
	var quartz := Color("eceae2")
	var c := Vector3(w * 0.5, 0, d * 0.5)
	var rx := w * 0.5
	var rz := d * 0.5
	var sides := 16
	var wall_h := 0.75
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.03, d), grass.darkened(0.05))  # turf in the plot's corners
	# quartz revetment: a band round the whole base (the back is hidden in the grass anyway)
	var lo := _ellipse(c, rx, rz, 0.0, sides)
	var hi := _ellipse(c, rx, rz, wall_h, sides)
	for i in sides:
		var j := (i + 1) % sides
		var col := quartz if lo[i].z > c.z - 0.2 else quartz.darkened(0.25)
		Meshes._quad(st, lo[i], lo[j], hi[j], hi[i], col.darkened(0.05 * (i % 2)))
	# the grassy dome on top, in bands
	var bands := [[0.98, wall_h], [0.85, wall_h + 0.45], [0.62, wall_h + 0.8], [0.3, wall_h + 1.0]]
	var prev := _ellipse(c, rx, rz, wall_h, sides)
	for b in bands.slice(1):
		var ring := _ellipse(c, rx * b[0], rz * b[0], b[1], sides)
		for i in sides:
			var j := (i + 1) % sides
			Meshes._quad(st, prev[i], prev[j], ring[j], ring[i], grass.lightened(0.04 * (i % 3)))
		prev = ring
	for i in sides:
		Meshes._tri(st, prev[i], prev[(i + 1) % sides], Vector3(c.x, wall_h + 1.08, c.z), grass.lightened(0.08))
	# the passage mouth, its lintel stones, and the carved kerbstone lying across the front
	var mx := (door_x + 0.5) if door_x >= 0 else c.x
	var fz := c.z + rz
	Meshes.box(st, Vector3(mx - 0.22, 0.2, fz - 0.06), Vector3(0.44, 0.5, 0.1), Color("1d1a17"))
	Meshes.box(st, Vector3(mx - 0.36, 0.7, fz - 0.08), Vector3(0.72, 0.14, 0.14), Color("8d8678"))
	Meshes.box(st, Vector3(mx - 0.3, 0.86, fz - 0.1), Vector3(0.6, 0.12, 0.12), Color("8d8678"))
	Meshes.box(st, Vector3(mx - 0.55, 0, fz - 0.22), Vector3(1.1, 0.26, 0.24), Color("9a9384"))

static func _ellipse(c: Vector3, rx: float, rz: float, y: float, sides: int) -> Array:
	var pts := []
	for i in sides:
		var a := TAU * i / sides
		pts.append(Vector3(c.x + cos(a) * rx, y, c.z + sin(a) * rz))
	return pts

## The Liver Building: a tall granite block, two clock towers with green domes and a Liver Bird on each.
static func _liver(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var h := 3.6
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), PORTLAND)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.25, d), PORTLAND.darkened(0.25))
	for s in 4:
		for x in w:
			if x == door_x and s == 0:
				continue
			_window(st, wst, x + 0.3, 0.4 + 0.82 * s, d, 0.4, 0.5, PORTLAND.darkened(0.1))
	var rng := Meshes._rng(77)
	var verdigris := Color("6fae96")
	for tx in [0.6, w - 2.0]:
		Meshes.box(st, Vector3(tx, h, d * 0.5 - 0.7), Vector3(1.4, 1.5, 1.4), PORTLAND.lightened(0.04))
		Meshes.box(st, Vector3(tx + 0.25, h + 0.4, d * 0.5 + 0.71), Vector3(0.9, 0.9, 0.04), Color("f2ead2"))
		Meshes.box(st, Vector3(tx + 0.66, h + 0.5, d * 0.5 + 0.74), Vector3(0.06, 0.4, 0.03), Color("2a2a2a"))
		Meshes.cylinder(st, Vector3(tx + 0.7, h + 1.5, d * 0.5), 0.6, 0.5, 8, verdigris)
		Meshes.blob(st, Vector3(tx + 0.7, h + 2.2, d * 0.5), Vector3(0.5, 0.45, 0.5), verdigris, rng, 0.03)
		# the Liver Bird
		Meshes.blob(st, Vector3(tx + 0.7, h + 2.85, d * 0.5), Vector3(0.16, 0.28, 0.14), Color("4f8a6a"), rng, 0.05)
		Meshes.box(st, Vector3(tx + 0.35, h + 2.85, d * 0.5 - 0.03), Vector3(0.7, 0.12, 0.06), Color("4f8a6a"))
	_door(st, door_x, d, PORTLAND, 1.2)

## Pontcysyllte: tall stone piers, round-ish arches, and an iron trough of canal water on top. Runs east-west.
static func _aqueduct(st: SurfaceTool, w: int, d: int) -> void:
	var stone := Color("8f7f6c")
	var h := 3.4
	var pier := 0.5
	for x in range(0, w, 2):
		Meshes.box(st, Vector3(x + 0.75, 0, d * 0.5 - 0.35), Vector3(pier, h, 0.7), stone.lightened(0.04 * (x % 4)))
	for x in range(0, w - 1, 2):
		# a stepped arch between piers
		Meshes.box(st, Vector3(x + 1.2, h - 0.5, d * 0.5 - 0.3), Vector3(1.6, 0.5, 0.6), stone)
		Meshes.box(st, Vector3(x + 1.25, h - 0.75, d * 0.5 - 0.3), Vector3(0.25, 0.25, 0.6), stone)
		Meshes.box(st, Vector3(x + 2.5, h - 0.75, d * 0.5 - 0.3), Vector3(0.25, 0.25, 0.6), stone)
	Meshes.box(st, Vector3(0, h, d * 0.5 - 0.5), Vector3(w, 0.4, 1.0), IRON)
	Meshes.box(st, Vector3(0, h + 0.38, d * 0.5 - 0.4), Vector3(w, 0.04, 0.8), Color("4f7f8f"))
	Meshes.box(st, Vector3(0, h + 0.4, d * 0.5 + 0.42), Vector3(w, 0.35, 0.05), IRON.lightened(0.2))

## Belfast's Samson and Goliath: a huge yellow gantry crane, two box legs straddling the dock and a beam on top.
static func _gantry(st: SurfaceTool, w: int, d: int) -> void:
	var yellow := Color("e8c228")
	var h := 6.5
	for lx in [0.2, w - 0.9]:
		Meshes.box(st, Vector3(lx, 0, d * 0.5 - 0.35), Vector3(0.7, h, 0.7), yellow)
		Meshes.box(st, Vector3(lx - 0.1, 0, d * 0.5 - 0.6), Vector3(0.9, 0.3, 1.2), IRON)  # bogie on the rail
	Meshes.box(st, Vector3(-0.3, h, d * 0.5 - 0.5), Vector3(w + 0.6, 0.9, 1.0), yellow, yellow.lightened(0.1))
	Meshes.box(st, Vector3(w * 0.5 - 0.6, h - 0.8, d * 0.5 - 0.45), Vector3(1.2, 0.8, 0.9), IRON.lightened(0.15))  # trolley
	Meshes.box(st, Vector3(w * 0.5 - 0.05, 1.4, d * 0.5 - 0.05), Vector3(0.1, h - 2.2, 0.1), Color("2a2a2a"))   # hoist cable
	Meshes.box(st, Vector3(w * 0.5 - 0.25, 1.1, d * 0.5 - 0.25), Vector3(0.5, 0.35, 0.5), IRON)                # hook block

## Glasgow's Finnieston Crane: a dark lattice tower on the quay and a hammerhead jib across the top, its long
## arm out over the river to the south (+z) with the hook hanging above the water, the machinery house and
## counterweight on the short tail behind.
static func _cantilever(st: SurfaceTool, w: int, d: int) -> void:
	var steel := Color("2e3236")
	var lit := steel.lightened(0.12)
	var h := 6.8
	var cx := w * 0.5
	var cz := d * 0.5
	# the tower: four legs leaning in, a cross-brace every storey
	var foot := 0.95
	var top := 0.6
	var legs := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for c in legs:
		var a := Vector3(cx + c.x * foot, 0, cz + c.y * foot)
		var b := Vector3(cx + c.x * top, h, cz + c.y * top)
		_strut(st, a, b, 0.14, steel)
	for i in 4:
		var y := 1.2 + i * 1.4
		var r := lerpf(foot, top, y / h)
		Meshes.box(st, Vector3(cx - r, y, cz - r), Vector3(r * 2, 0.1, 0.1), lit)
		Meshes.box(st, Vector3(cx - r, y, cz + r - 0.1), Vector3(r * 2, 0.1, 0.1), lit)
		Meshes.box(st, Vector3(cx - r, y, cz - r), Vector3(0.1, 0.1, r * 2), lit)
		Meshes.box(st, Vector3(cx + r - 0.1, y, cz - r), Vector3(0.1, 0.1, r * 2), lit)
	Meshes.box(st, Vector3(cx - 1.15, 0, cz - 1.15), Vector3(2.3, 0.2, 2.3), Color("8a8478"))  # plinth
	# the jib: a deep box girder from the tail (north) out over the water (south)
	var z0 := cz - 2.2
	var z1 := d + 4.3
	Meshes.box(st, Vector3(cx - 0.45, h, z0), Vector3(0.9, 0.7, z1 - z0), steel, lit)
	Meshes.box(st, Vector3(cx - 0.5, h + 0.7, z0), Vector3(1.0, 0.08, z1 - z0), lit)  # walkway on top
	Meshes.box(st, Vector3(cx - 0.75, h + 0.78, z0 + 0.1), Vector3(1.5, 1.0, 1.6), steel.lightened(0.05))  # machinery house
	Meshes.box(st, Vector3(cx - 0.6, h - 0.9, z0), Vector3(1.2, 0.9, 0.9), Color("4a4e52"))  # counterweight
	# trolley, cable and hook out at the end of the arm
	var hz := z1 - 1.2
	Meshes.box(st, Vector3(cx - 0.35, h - 0.25, hz - 0.35), Vector3(0.7, 0.25, 0.7), IRON.lightened(0.15))
	Meshes.box(st, Vector3(cx - 0.04, 1.3, hz - 0.04), Vector3(0.08, h - 1.55, 0.08), Color("1e1e1e"))
	Meshes.box(st, Vector3(cx - 0.22, 0.95, hz - 0.22), Vector3(0.44, 0.35, 0.44), Color("c8a020"))  # hook block, painted

## A square strut from a to b (a mostly vertical member), built as a skewed box.
static func _strut(st: SurfaceTool, a: Vector3, b: Vector3, t: float, col: Color) -> void:
	var h := t * 0.5
	var lo := [a + Vector3(-h, 0, -h), a + Vector3(h, 0, -h), a + Vector3(h, 0, h), a + Vector3(-h, 0, h)]
	var hi := [b + Vector3(-h, 0, -h), b + Vector3(h, 0, -h), b + Vector3(h, 0, h), b + Vector3(-h, 0, h)]
	for i in 4:
		var j := (i + 1) % 4
		Meshes._quad(st, lo[i], lo[j], hi[j], hi[i], col.darkened(0.06 * (i % 2)))

## Titanic Belfast: four angular ship's prows, one rising toward each corner, flaring out as they climb and clad
## in silver shards, round a glass atrium whose front holds the door. The prows' tips stand highest, like bows.
static func _titanic(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var c := Vector2(w * 0.5, d * 0.5)
	var h := maxf(5.4, d * 0.8)
	var glass := Color("35505f")
	var frame := Color("23303a")
	# the atrium: a glass box between the prows, reaching the front edge for the door
	var aw := minf(3.2, w * 0.3)
	Meshes.box(st, Vector3(c.x - aw * 0.5, 0, c.y - d * 0.2), Vector3(aw, h * 0.7, d * 0.7), glass, frame)
	for r in 3:
		for i in int(aw / 0.5):
			var x := c.x - aw * 0.5 + 0.1 + i * 0.5
			if r == 0 and door_x >= 0 and x >= door_x - 0.3 and x <= door_x + 1.0:
				continue
			Meshes.box(wst, Vector3(x, 0.35 + r * 1.1, d - 0.03), Vector3(0.36, 0.7, 0.04), window_colour(_wr))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.12, 0, d - 0.06), Vector3(0.76, 1.1, 0.08), frame)
	# the prows: a kite in plan (inner corner, two flanks, the bow), pointing at a footprint corner
	var half := Vector2(w * 0.5, d * 0.5)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var o := (corner * half).normalized()
		var perp := Vector2(o.y, -o.x)
		var reach := (corner * half).length() - 0.55
		var flank := reach * 0.5
		var hw := minf(1.4, half.y * 0.42)
		var plan := [c + o * 0.6, c + o * flank + perp * hw, c + o * reach, c + o * flank - perp * hw]
		var tops := [h * 0.8, h * 0.9, h * 1.08, h * 0.9]
		var lo := []
		var hi := []
		for i in 4:
			var p: Vector2 = plan[i]
			# lean out as it climbs: the walls flare, the bow most of all
			var lean: Vector2 = (p - c) * (0.1 if i != 2 else 0.12)
			lo.append(Vector3(p.x, 0, p.y))
			hi.append(Vector3(p.x + lean.x, tops[i], p.y + lean.y))
		hi[2] = Vector3(clampf(hi[2].x, -0.2, w + 0.2), hi[2].y, clampf(hi[2].z, -0.2, d + 0.2))
		for i in 4:
			var j := (i + 1) % 4
			_shards(st, lo[i], lo[j], hi[j], hi[i], 3, 5, rng)
		_shards(st, hi[0], hi[1], hi[2], hi[3], 2, 2, rng, 0.08)  # the deck, darker

## A wall clad in silver shards: the quad a-b-c-d (a, b along the bottom) cut into a cols x rows grid, each
## cell split corner to corner into two triangles of different silvers.
static func _shards(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, cols: int, rows: int, rng: RandomNumberGenerator, dark := 0.0) -> void:
	var base := Color("c4cad0")
	for r in rows:
		for k in cols:
			var u0 := k / float(cols)
			var u1 := (k + 1) / float(cols)
			var v0 := r / float(rows)
			var v1 := (r + 1) / float(rows)
			var p00 := _bilerp(a, b, c, d, u0, v0)
			var p10 := _bilerp(a, b, c, d, u1, v0)
			var p11 := _bilerp(a, b, c, d, u1, v1)
			var p01 := _bilerp(a, b, c, d, u0, v1)
			var s1 := base.lightened(rng.randf_range(0.0, 0.2)).darkened(dark) if rng.randf() < 0.5 else base.darkened(rng.randf_range(0.0, 0.16) + dark)
			var s2 := base.lerp(Color("aebccb"), rng.randf_range(0.2, 0.7)).darkened(dark)
			if (r + k) % 2 == 0:
				Meshes._tri(st, p00, p10, p11, s1)
				Meshes._tri(st, p00, p11, p01, s2)
			else:
				Meshes._tri(st, p00, p10, p01, s2)
				Meshes._tri(st, p10, p11, p01, s1)

static func _bilerp(a: Vector3, b: Vector3, c: Vector3, d: Vector3, u: float, v: float) -> Vector3:
	return a.lerp(b, u).lerp(d.lerp(c, u), v)

## Lord Vane's tower: a tall tapering block of blue glass with a lit grid of windows and a needle spire.
static func _glass_tower(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var glass := Color("4a6e8c")
	var frame := Color("2a3442")
	# [base y, height, inset]. Only a deep footprint is a real tower (Vane's); museums and theatres in this style
	# (the Royal Armouries, Aerospace Bristol...) are low, so the camera never ends up inside one behind it
	var tiers := [[0.0, 4.0, 0.0], [4.0, 4.0, 0.35], [8.0, 3.5, 0.7]] if d >= 8 else [[0.0, 3.2, 0.0], [3.2, 1.8, 0.4]]
	for t in tiers:
		var y0: float = t[0]
		var h: float = t[1]
		var ins: float = t[2]
		Meshes.box(st, Vector3(ins, y0, ins), Vector3(w - 2 * ins, h, d - 2 * ins), glass, glass.lightened(0.2))
		Meshes.box(st, Vector3(ins - 0.05, y0 + h - 0.12, ins - 0.05), Vector3(w - 2 * ins + 0.1, 0.12, d - 2 * ins + 0.1), frame)
		var rows := int(h / 0.7)
		for r in rows:
			for x in range(int(ins) + 0, w - int(ceil(ins))):
				if r == 0 and y0 == 0.0 and x == door_x:
					continue
				Meshes.box(wst, Vector3(x + 0.2, y0 + 0.25 + r * 0.7, d - ins - 0.03), Vector3(0.6, 0.4, 0.04), window_colour(_wr))
	Meshes.box(st, Vector3(w * 0.5 - 0.15, 11.5, d * 0.5 - 0.15), Vector3(0.3, 3.0, 0.3), frame.lightened(0.3))  # spire
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0, d - 0.06), Vector3(0.7, 1.2, 0.08), frame)

# --- point props -------------------------------------------------------------

## A little waterfall where a stream drops a level: a sloping sheet of white water from the upstream (+x) edge
## of its tile, the upper pool's lip, down to a ring of foam on the lower pool. Origin on the lower pool's
## surface (ZoneBuilder stands it there); ZoneBuilder.LEVEL high, so it meets the pool above.
static func cascade(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(9500 + variant)
	var st := Meshes._st()
	var top := ZoneBuilder.LEVEL + 0.05
	var strips := 5
	for i in strips:
		var z0 := -0.46 + i * 0.92 / strips
		var z1 := z0 + 0.92 / strips
		var col := Color("eef6f8") if i % 2 == 0 else Color("b9dde6")
		var lip := 0.52 + rng.randf_range(-0.02, 0.02)
		# white water quickening over the lip of the pool above, then the fall itself
		Meshes._quad(st, Vector3(0.8, top - 0.01, z1), Vector3(0.8, top - 0.01, z0), Vector3(lip, top, z0), Vector3(lip, top, z1), col.lerp(Color("9fcbd8"), 0.4))
		Meshes._quad(st, Vector3(lip, top, z1), Vector3(lip, top, z0), Vector3(0.06, 0.02, z0), Vector3(0.06, 0.02, z1), col)
	for i in 8:
		var z := -0.42 + i * 0.12
		Meshes.blob(st, Vector3(rng.randf_range(-0.2, 0.12), 0.02, z), Vector3(0.17, 0.06, 0.12), Color("f2f8fa"), rng, 0.3)
	return Meshes._finish(st)

# --- the countryside ----------------------------------------------------------

## A Dales field barn (a laithe): rubble stone walls with through-stones sticking out, a stone-slate roof, a
## wide cart door and a row of little forking holes. Nobody goes in: it has no door tile.
static func _field_barn(st: SurfaceTool, w: int, d: int, rng: RandomNumberGenerator) -> void:
	var stone := Color("a39b8b")
	var roof := Color("5d5850")
	var h := 1.25
	for row in 5:
		var y := row * h / 5.0
		var c := stone.lightened(rng.randf_range(-0.08, 0.06))
		Meshes.box(st, Vector3(0.08, y, 0.12), Vector3(w - 0.16, h / 5.0, d - 0.24), c)
	for i in w:
		Meshes.box(st, Vector3(i + 0.35, h * 0.55, d - 0.16), Vector3(0.18, 0.08, 0.1), stone.darkened(0.15))  # through-stones
		Meshes.box(st, Vector3(i + 0.4, h * 0.8, d - 0.13), Vector3(0.12, 0.12, 0.02), Color("2a2622"))       # forking holes
	Meshes.box(st, Vector3(w * 0.5 - 0.4, 0, d - 0.13), Vector3(0.8, 0.85, 0.03), Color("4d3b2c"))  # cart door
	Meshes.box(st, Vector3(w * 0.5 - 0.48, 0.85, d - 0.14), Vector3(0.96, 0.1, 0.06), stone.lightened(0.12))  # lintel
	_roof(st, w, d, h, roof, stone, 0.32)

## Field sheep standing about (point props: no creature, just wool). 0 Herdwick (grey fleece, white face, the
## Lakes), 1 Swaledale (white fleece, black face, the Dales), 2 a Herdwick with its head down grazing.
static func sheep(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(9700 + variant)
	var st := Meshes._st()
	var fleece := Color("e6e1d6") if variant == 1 else Color("8f8a84")
	var face := Color("24211f") if variant == 1 else Color("e9e6df")
	var leg := Color("2a2725")
	for p in [Vector2(-0.14, -0.09), Vector2(0.14, -0.09), Vector2(-0.14, 0.09), Vector2(0.14, 0.09)]:
		Meshes.box(st, Vector3(p.x - 0.03, 0, p.y - 0.03), Vector3(0.06, 0.18, 0.06), leg)
	Meshes.blob(st, Vector3(0, 0.27, 0), Vector3(0.24, 0.13, 0.16), fleece, rng, 0.12)
	var head_y := 0.14 if variant == 2 else 0.34
	Meshes.box(st, Vector3(0.22, head_y - 0.06, -0.06), Vector3(0.14, 0.12, 0.12), face)
	Meshes.box(st, Vector3(0.23, head_y + 0.03, -0.1), Vector3(0.04, 0.03, 0.2), face.darkened(0.1))  # ears
	if variant == 1:
		Meshes.box(st, Vector3(0.24, head_y + 0.02, -0.09), Vector3(0.06, 0.06, 0.03), Color("c9bfa8"))  # curled horn
		Meshes.box(st, Vector3(0.24, head_y + 0.02, 0.06), Vector3(0.06, 0.06, 0.03), Color("c9bfa8"))
	return Meshes._finish(st)

## A five-bar field gate standing open, folded back against the wall beside a gap: the hanging post at the
## gap side (+x), the gate in front of the wall's face (+z). Stand it on the wall tile next to the gap, turned
## (rot) so +x points into the gap. Variant 1 is weathered grey, 2 painted white.
static func field_gate(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var wood: Color = [Color("8a6a46"), Color("8c8a82"), Color("e8e4da")][variant % 3]
	Meshes.box(st, Vector3(0.36, 0, 0.18), Vector3(0.12, 0.86, 0.12), Color("6d5a44") if variant != 2 else wood.darkened(0.1))
	for i in 5:
		Meshes.box(st, Vector3(-0.48, 0.12 + i * 0.13, 0.27), Vector3(0.86, 0.05, 0.04), wood)
	Meshes.box(st, Vector3(-0.48, 0.1, 0.26), Vector3(0.06, 0.62, 0.06), wood.darkened(0.08))
	Meshes.box(st, Vector3(0.28, 0.1, 0.26), Vector3(0.06, 0.62, 0.06), wood.darkened(0.08))
	# the diagonal brace, in short steps
	for i in 6:
		var t := i / 5.0
		Meshes.box(st, Vector3(lerpf(0.24, -0.44, t), lerpf(0.14, 0.6, t), 0.25), Vector3(0.12, 0.05, 0.03), wood.darkened(0.05))
	return Meshes._finish(st)

## Limestone pavement: flat clints split by dark grikes, lying on its tile. Walk over it.
static func limestone_pavement(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(9800 + variant)
	var st := Meshes._st()
	var stone := Color("bdb9ac")
	# two bands of clints, each band split at its own place, so the grikes don't line up like floor tiles
	for j in 2:
		var z0 := -0.5 + j * 0.5 + 0.03
		var cut := rng.randf_range(-0.25, 0.25)
		for part in [[-0.5, cut], [cut, 0.5]]:
			if rng.randf() < 0.1:
				continue  # turf has filled this one in
			var x0: float = part[0] + 0.03
			var x1: float = part[1] - 0.03
			var c := stone.lightened(rng.randf_range(-0.1, 0.06))
			Meshes.box(st, Vector3(x0, 0, z0), Vector3(x1 - x0, rng.randf_range(0.04, 0.08), 0.44 + rng.randf_range(-0.04, 0.0)), c)
	return Meshes._finish(st)

static func standing_stone(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(9100 + variant)
	var st := Meshes._st()
	var g := Color("8e8a80")
	var h := 1.3 + variant * 0.3
	Meshes.box(st, Vector3(-0.22, 0, -0.14), Vector3(0.44, h, 0.28), g.lightened(rng.randf_range(-0.05, 0.05)))
	Meshes.box(st, Vector3(-0.17, h, -0.1), Vector3(0.3, 0.18, 0.2), g.darkened(0.06))
	Meshes.blob(st, Vector3(0.1, h * 0.5, 0.15), Vector3(0.1, 0.12, 0.04), Color("9fae6a"), rng)  # lichen
	return Meshes._finish(st)

## Variants 0 to 2 are slate (or slag); variant 3 is a stack of cut peat.
static func slate_heap(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(9200 + variant)
	var st := Meshes._st()
	var col := PEAT if variant == 3 else SLATE
	for i in 9:
		var y := i * 0.09
		var s := 0.9 - i * 0.08
		Meshes.box(st, Vector3(-s * 0.5 + rng.randf_range(-0.05, 0.05), y, -s * 0.45), Vector3(s, 0.08, s * 0.9), col.lightened(rng.randf_range(-0.08, 0.12)))
	return Meshes._finish(st)

static func scree_rubble(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(9300 + variant)
	var st := Meshes._st()
	for i in 6:
		Meshes.blob(st, Vector3(rng.randf_range(-0.35, 0.35), 0.06, rng.randf_range(-0.35, 0.35)), Vector3(0.12, 0.08, 0.1), Color("8a8780").lightened(rng.randf_range(-0.1, 0.1)), rng, 0.3)
	return Meshes._finish(st)

static func bramble(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(9400 + variant)
	var st := Meshes._st()
	Meshes.blob(st, Vector3(0, 0.35, 0), Vector3(0.5, 0.38, 0.46), Color("3d5e2c"), rng, 0.3)
	Meshes.blob(st, Vector3(0.2, 0.55, 0.1), Vector3(0.28, 0.22, 0.28), Color("4a6b30"), rng, 0.3)
	for i in 7:
		Meshes.box(st, Vector3(rng.randf_range(-0.4, 0.35), rng.randf_range(0.3, 0.7), rng.randf_range(-0.35, 0.4)), Vector3(0.07, 0.07, 0.07), Color("2b1d33") if i % 2 == 0 else Color("b8344a"))
	return Meshes._finish(st)

## One tile of track running east-west: sleepers across, two steel rails along. Rail tops sit at RAIL_TOP.
const RAIL_TOP := 0.12
static func rail_segment() -> ArrayMesh:
	var st := Meshes._st()
	var wood := Color("4a3b2e")
	var steel := Color("7d838b")
	for i in 3:
		Meshes.box(st, Vector3(-0.42 + i * 0.33, 0.0, -0.4), Vector3(0.17, 0.05, 0.8), wood)
	for zr in [-0.25, 0.19]:
		Meshes.box(st, Vector3(-0.5, 0.05, zr), Vector3(1.0, 0.07, 0.06), steel.darkened(0.25), Color("b8bec6"))
	return Meshes._finish(st)

## Level crossing furniture (track east-west, the road crossing north-south): the deck is the tile's own
## ground, this adds plank seams and two red-and-white barrier posts on opposite corners, warning lamps on top.
static func crossing_deck() -> ArrayMesh:
	var st := Meshes._st()
	var seam := Color("4f4233")
	for zz in [-0.33, 0.33]:
		Meshes.box(st, Vector3(-0.5, 0.075, zz - 0.01), Vector3(1.0, 0.01, 0.02), seam)
	for c in [Vector2(-0.44, -0.46), Vector2(0.38, 0.4)]:
		var x: float = c.x
		var zc: float = c.y
		Meshes.box(st, Vector3(x - 0.02, 0.0, zc - 0.02), Vector3(0.1, 0.06, 0.1), Color("3c4450"))
		for i in 4:
			Meshes.box(st, Vector3(x, 0.06 + i * 0.13, zc), Vector3(0.06, 0.13, 0.06), Color("c8102e") if i % 2 == 0 else Color("f2efe6"))
		Meshes.box(st, Vector3(x - 0.06, 0.58, zc - 0.01), Vector3(0.18, 0.08, 0.08), Color("1d1d1d"))
		for dx in [-0.04, 0.08]:
			Meshes.box(st, Vector3(x + dx, 0.6, zc + 0.07), Vector3(0.04, 0.04, 0.012), Color("e0412e"))
	return Meshes._finish(st)

## Buffer stop at the end of a line. Local +X faces along the track (the way trains come from);
## ZoneBuilder turns it to face its line.
static func buffer_stop() -> ArrayMesh:
	var st := Meshes._st()
	var iron := Color("2e3238")
	var red := Color("b3261e")
	# sleepered base and the rails bending up into the frame
	Meshes.box(st, Vector3(-0.42, 0.0, -0.42), Vector3(0.6, 0.06, 0.84), Color("4a3b2e"))
	for zr in [-0.25, 0.19]:
		Meshes.box(st, Vector3(-0.3, 0.06, zr), Vector3(0.12, 0.42, 0.06), iron)
		Meshes.box(st, Vector3(-0.38, 0.06, zr), Vector3(0.5, 0.1, 0.06), iron)
	# the beam, red with a white stripe, and two sprung buffers facing the train
	Meshes.box(st, Vector3(-0.2, 0.28, -0.46), Vector3(0.18, 0.26, 0.92), red)
	Meshes.box(st, Vector3(-0.02, 0.36, -0.3), Vector3(0.005, 0.07, 0.6), Color("f2efe6"))
	for zb in [-0.38, 0.26]:
		Meshes.box(st, Vector3(-0.02, 0.35, zb), Vector3(0.14, 0.08, 0.12), iron)
		Meshes.box(st, Vector3(0.12, 0.32, zb - 0.02), Vector3(0.04, 0.14, 0.16), Color("9aa0a8"))
	# the lamp on top
	Meshes.box(st, Vector3(-0.15, 0.54, -0.06), Vector3(0.1, 0.16, 0.12), iron)
	Meshes.box(st, Vector3(-0.05, 0.6, -0.04), Vector3(0.012, 0.07, 0.08), Color("ff3b2a"))
	return Meshes._finish(st)

## A tunnel mouth: a stone portal with a dark bore, set in a grassy bank (variant 0) or a sooty brick
## tube mouth with no bank (variant 1, the Underground). Local +X faces along the track, out of the tunnel.
## The bore is 0.9 wide and 1.05 high, so a train fits; RailTraffic clips trains at local x = 0.
static func tunnel_portal(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var tube := variant == 1
	var stone := Color("6b3a2e") if tube else Color("8f8270")
	var bank := Color("3a2f2b") if tube else Color("6a5238")
	var bank_top := Color("2a2220") if tube else Color("527f37")
	var dark := Color("0b0b0d")
	# a tube mouth is exactly one tile wide, so two side by side make a double-track tunnel
	var hw := 0.5 if tube else 0.98
	var pier := 0.5 if tube else 0.82
	# the bank (or brickwork) round the bore, running back over the tile behind and stepping up into a knoll
	Meshes.box(st, Vector3(-1.4, 0, -hw), Vector3(1.68, 1.32, hw - 0.46), bank, bank_top)
	Meshes.box(st, Vector3(-1.4, 0, 0.46), Vector3(1.68, 1.32, hw - 0.46), bank, bank_top)
	Meshes.box(st, Vector3(-0.5, 1.05, -0.46), Vector3(0.78, 0.27, 0.92), bank, bank_top)
	Meshes.box(st, Vector3(-1.4, 0, -0.46), Vector3(0.9, 1.32, 0.92), bank, bank_top)
	if not tube:
		Meshes.box(st, Vector3(-1.25, 1.32, -0.8), Vector3(1.35, 0.28, 1.6), bank, bank_top.darkened(0.04))
		Meshes.box(st, Vector3(-1.0, 1.6, -0.5), Vector3(0.85, 0.2, 1.0), bank, bank_top.lightened(0.04))
	# the bore: black lining inside
	Meshes.box(st, Vector3(-0.5, 0, -0.46), Vector3(0.78, 1.05, 0.01), dark)
	Meshes.box(st, Vector3(-0.5, 0, 0.45), Vector3(0.78, 1.05, 0.01), dark)
	Meshes.box(st, Vector3(-0.5, 1.04, -0.46), Vector3(0.78, 0.01, 0.92), dark)
	Meshes.box(st, Vector3(-0.5, 0, -0.46), Vector3(0.02, 1.05, 0.92), dark)
	Meshes.box(st, Vector3(-0.5, 0.0, -0.46), Vector3(0.78, 0.04, 0.92), Color("1a1816"))
	# the portal face: piers, an arch of voussoirs, a parapet
	Meshes.box(st, Vector3(0.28, 0, -pier), Vector3(0.14, 1.05, pier - 0.46), stone)
	Meshes.box(st, Vector3(0.28, 0, 0.46), Vector3(0.14, 1.05, pier - 0.46), stone)
	Meshes.box(st, Vector3(0.28, 1.05, -pier), Vector3(0.14, 0.36, pier * 2), stone)
	for i in 5:
		var zz := -0.46 + i * 0.184
		var lift := 0.05 * (2 - absi(i - 2))
		Meshes.box(st, Vector3(0.4, 0.92 + lift, zz), Vector3(0.03, 0.14, 0.18), stone.lightened(0.1 if i % 2 == 0 else 0.0))
	var top := 0.5 if tube else 0.9
	Meshes.box(st, Vector3(0.24, 1.41, -top), Vector3(0.22, 0.09, top * 2), stone.darkened(0.15))
	return Meshes._finish(st)

## Train cars for RailTraffic, 1.5 long, nose along +X, wheels on y = 0 (the rail top), centred on the origin.
## `cab` puts a driving cab on the +X end (yellow warning panel, windscreen, lamps).
## Window colours carry alpha 0.4 so the train shader can light them up at night.
static func train_car(livery: Color, cab: bool) -> ArrayMesh:
	var st := Meshes._st()
	var under := Color("26282c")
	var roof := Color("b9bec4")
	var win := Color(0.16, 0.2, 0.26, 0.4)
	Meshes.box(st, Vector3(-0.62, 0.0, -0.28), Vector3(0.34, 0.16, 0.56), under)
	Meshes.box(st, Vector3(0.28, 0.0, -0.28), Vector3(0.34, 0.16, 0.56), under)
	Meshes.box(st, Vector3(-0.72, 0.13, -0.33), Vector3(1.44, 0.1, 0.66), under)
	var band := livery.lightened(0.6)
	Meshes.box(st, Vector3(-0.72, 0.23, -0.37), Vector3(1.44, 0.6, 0.74), livery, roof)
	Meshes.box(st, Vector3(-0.725, 0.44, -0.375), Vector3(1.45, 0.34, 0.75), band, roof)
	Meshes.box(st, Vector3(-0.7, 0.83, -0.33), Vector3(1.4, 0.07, 0.66), roof)
	Meshes.box(st, Vector3(-0.66, 0.9, -0.22), Vector3(1.32, 0.04, 0.44), roof.lightened(0.1))
	# windows down both sides, doors by the ends
	var x0 := -0.5
	var x1 := 0.3 if cab else 0.5
	var n := 4 if cab else 5
	for i in n:
		var wx := x0 + (x1 - x0) * (float(i) / float(n - 1)) - 0.08
		for zs in [-0.38, 0.37]:
			Meshes.box(st, Vector3(wx, 0.5, zs), Vector3(0.16, 0.2, 0.01), win)
	for dx in [-0.68, 0.56 if not cab else 0.42]:
		for zs in [-0.38, 0.37]:
			Meshes.box(st, Vector3(dx, 0.24, zs), Vector3(0.12, 0.55, 0.01), livery.darkened(0.25))
	if cab:
		Meshes.box(st, Vector3(0.72, 0.23, -0.36), Vector3(0.05, 0.36, 0.72), Color("e8c21a"))
		Meshes.box(st, Vector3(0.72, 0.59, -0.33), Vector3(0.04, 0.2, 0.66), win)
		Meshes.box(st, Vector3(0.72, 0.79, -0.36), Vector3(0.05, 0.04, 0.72), livery)
		for zl in [-0.28, 0.2]:
			Meshes.box(st, Vector3(0.77, 0.3, zl), Vector3(0.015, 0.06, 0.08), Color(1.0, 0.96, 0.82, 0.4))
	else:
		Meshes.box(st, Vector3(0.72, 0.23, -0.26), Vector3(0.04, 0.55, 0.52), under)
	Meshes.box(st, Vector3(-0.76, 0.23, -0.26), Vector3(0.04, 0.55, 0.52), under)
	return Meshes._finish(st)

## The ferry (variant 0, long, red funnel) or a fishing boat (variant 1).
static func boat(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	if variant == 0:
		Meshes.box(st, Vector3(-2.2, -0.2, -0.7), Vector3(4.4, 0.8, 1.4), Color("1f2b44"), Color("d9d4c6"))
		Meshes.box(st, Vector3(-1.4, 0.6, -0.55), Vector3(2.6, 0.7, 1.1), Color("f2efe6"))
		Meshes.box(st, Vector3(-1.2, 1.3, -0.45), Vector3(1.6, 0.4, 0.9), Color("f2efe6"))
		Meshes.cylinder(st, Vector3(0.6, 1.3, 0), 0.25, 0.7, 8, Color("c8102e"))
		Meshes.cylinder(st, Vector3(0.6, 2.0, 0), 0.22, 0.15, 8, Color("1d1d1d"))
	else:
		Meshes.box(st, Vector3(-0.7, -0.15, -0.35), Vector3(1.4, 0.45, 0.7), Color("2f6b8a"), Color("a8774f"))
		Meshes.box(st, Vector3(-0.2, 0.3, -0.25), Vector3(0.5, 0.45, 0.5), Color("e8e2d4"))
		Meshes.box(st, Vector3(0.45, 0.3, -0.03), Vector3(0.05, 1.0, 0.05), Color("5a4636"))
	return Meshes._finish(st)

## A narrowboat, long and thin, in canal colours.
static func canal_boat(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var body: Color = [Color("2f5a3c"), Color("7a1f2b"), Color("1f3d6b")][variant % 3]
	Meshes.box(st, Vector3(-1.5, -0.15, -0.28), Vector3(3.0, 0.35, 0.56), Color("1d1d1d"))
	Meshes.box(st, Vector3(-1.1, 0.2, -0.25), Vector3(2.3, 0.4, 0.5), body, Color("c9a96b"))
	for i in 4:
		Meshes.box(st, Vector3(-0.9 + i * 0.55, 0.32, 0.25), Vector3(0.22, 0.16, 0.02), Color("f2d38a"))
	Meshes.cylinder(st, Vector3(0.9, 0.6, 0), 0.05, 0.25, 6, Color("1d1d1d"))
	return Meshes._finish(st)

static func bollard() -> ArrayMesh:
	var st := Meshes._st()
	Meshes.cylinder(st, Vector3(0, 0, 0), 0.16, 0.4, 8, Color("2a2f38"))
	Meshes.cylinder(st, Vector3(0, 0.4, 0), 0.2, 0.08, 8, Color("2a2f38"))
	return Meshes._finish(st)

## A Deep Place lever: an iron box on the floor and a long handle with a red knob, leaning back (variant 0) or
## thrown forward (1, pulled). Big and bright on purpose, so it reads from across a dim cave.
static func lever(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(9480)
	Meshes.box(st, Vector3(-0.22, 0, -0.16), Vector3(0.44, 0.22, 0.32), Color("3a3f48"), Color("4a505a"))
	Meshes.box(st, Vector3(-0.17, 0.22, -0.04), Vector3(0.34, 0.02, 0.08), Color("16181c"))  # the slot
	var lean := -1.0 if variant == 0 else 1.0
	for k in 7:  # the handle, a stack of short bars stepping over to one side
		Meshes.box(st, Vector3(-0.035 + lean * k * 0.035, 0.22 + k * 0.08, -0.035), Vector3(0.07, 0.09, 0.07), Color("8a8f98"))
	Meshes.blob(st, Vector3(lean * 0.245, 0.8, 0), Vector3(0.09, 0.09, 0.09), Color("d23a2a"), rng, 0.02)
	return Meshes._finish(st)

static func buoy(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(9500)
	Meshes.blob(st, Vector3(0, 0.05, 0), Vector3(0.25, 0.2, 0.25), Color("d9481f") if variant == 0 else Color("e8c832"), rng, 0.02)
	Meshes.box(st, Vector3(-0.03, 0.2, -0.03), Vector3(0.06, 0.35, 0.06), Color("2a2f38"))
	return Meshes._finish(st)

static func lighthouse() -> ArrayMesh:
	var st := Meshes._st()
	for i in 5:
		Meshes.cylinder(st, Vector3(0, i * 0.6, 0), 0.5 - i * 0.04, 0.6, 10, Color("f2efe6") if i % 2 == 0 else Color("c8102e"))
	Meshes.cylinder(st, Vector3(0, 3.0, 0), 0.4, 0.4, 10, Color("f8e9a0"))
	Meshes.cylinder(st, Vector3(0, 3.4, 0), 0.45, 0.15, 10, Color("1d1d1d"))
	return Meshes._finish(st)

## Big Ben, near enough: a stone shaft, a clock face on every side, a belfry and a tall pointed roof.
static func clock_tower() -> ArrayMesh:
	var st := Meshes._st()
	var stone := Color("c9b98a")
	var gilt := Color("c9a441")
	Meshes.box(st, Vector3(-0.4, 0, -0.4), Vector3(0.8, 0.25, 0.8), stone.darkened(0.2))
	Meshes.box(st, Vector3(-0.33, 0.25, -0.33), Vector3(0.66, 2.75, 0.66), stone)
	for i in 4:
		Meshes.box(st, Vector3(-0.35, 0.6 + i * 0.6, -0.35), Vector3(0.7, 0.05, 0.7), stone.darkened(0.12))
	# the clock stage, a touch wider, with a face on each side
	Meshes.box(st, Vector3(-0.38, 3.0, -0.38), Vector3(0.76, 0.7, 0.76), stone.lightened(0.05))
	for f in [[Vector3(-0.22, 3.12, 0.385), Vector3(0.44, 0.44, 0.02)], [Vector3(-0.22, 3.12, -0.405), Vector3(0.44, 0.44, 0.02)],
			[Vector3(0.385, 3.12, -0.22), Vector3(0.02, 0.44, 0.44)], [Vector3(-0.405, 3.12, -0.22), Vector3(0.02, 0.44, 0.44)]]:
		Meshes.box(st, f[0], f[1], Color("f4ecd2"))
	Meshes.box(st, Vector3(-0.02, 3.33, 0.4), Vector3(0.04, 0.16, 0.02), Color("1d1d1d"))
	Meshes.box(st, Vector3(-0.02, 3.33, 0.4), Vector3(0.12, 0.03, 0.02), Color("1d1d1d"))
	# belfry and spire
	Meshes.box(st, Vector3(-0.3, 3.7, -0.3), Vector3(0.6, 0.35, 0.6), stone.darkened(0.08))
	for i in 5:
		var r := 0.3 - i * 0.06
		Meshes.box(st, Vector3(-r, 4.05 + i * 0.2, -r), Vector3(r * 2.0, 0.2, r * 2.0), SLATE.lightened(0.1 * (i % 2)))
	Meshes.box(st, Vector3(-0.025, 5.05, -0.025), Vector3(0.05, 0.3, 0.05), gilt)
	return Meshes._finish(st)

## The Shard: a tall, tapering spike of pale blue glass, its tip left ragged.
static func shard() -> ArrayMesh:
	var st := Meshes._st()
	var glass := Color("9fc1d6")
	var n := 12
	for i in n:
		var r := 0.48 * (1.0 - float(i) / n) + 0.04
		Meshes.box(st, Vector3(-r, i * 0.45, -r * 0.8), Vector3(r * 2.0, 0.45, r * 1.6), glass.darkened(0.04 * (i % 3)).lightened(0.02 * i))
	for k in 3:
		Meshes.box(st, Vector3(-0.06 + k * 0.05, n * 0.45, -0.03), Vector3(0.03, 0.25 + 0.15 * k, 0.03), glass.lightened(0.2))
	return Meshes._finish(st)

static func statue(variant := 0) -> ArrayMesh:
	if variant == IRON_MAN:
		return iron_man()
	var st := Meshes._st()
	var rng := Meshes._rng(9600 + variant)
	Meshes.box(st, Vector3(-0.35, 0, -0.35), Vector3(0.7, 0.7, 0.7), LIMESTONE)
	var bronze := Color("5d7a62")
	Meshes.box(st, Vector3(-0.12, 0.7, -0.1), Vector3(0.24, 0.7, 0.2), bronze)
	Meshes.blob(st, Vector3(0, 1.55, 0), Vector3(0.13, 0.15, 0.13), bronze, rng, 0.03)
	return Meshes._finish(st)

static func harp() -> ArrayMesh:
	var st := Meshes._st()
	var wood := Color("a8774f")
	Meshes.box(st, Vector3(-0.3, 0, -0.1), Vector3(0.6, 0.12, 0.2), wood)
	Meshes.box(st, Vector3(-0.3, 0, -0.06), Vector3(0.1, 1.3, 0.12), wood)
	Meshes.box(st, Vector3(-0.3, 1.2, -0.06), Vector3(0.6, 0.1, 0.12), wood.darkened(0.1))
	for i in 5:
		Meshes.box(st, Vector3(-0.15 + i * 0.08, 0.12, -0.01), Vector3(0.012, 1.08 - i * 0.12, 0.012), Color("f2e2a0"))
	return Meshes._finish(st)




# --- the South Pennines and Leeds ----------------------------------------------

const GRITSTONE := Color("8c8270")     # Pennine millstone grit, weathered dark
const GRIT_SOOT := Color("6a6152")     # the same, with a century of mill smoke on it
const MOOR_TOP := Color("6b6a42")
const HEATHER_TOP := Color("6e5a5c")
const LEEDS_STONE := Color("c2ab86")   # the cleaned sandstone of the civic buildings

## A canal tunnel portal (Standedge): a gritstone face set into the moor, with a dark horseshoe arch over the
## water (the two columns east of the door, where the canal runs in) and a little gate on the towpath door.
static func _canal_tunnel(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var rng := Meshes._rng(1811)
	var face_z := d - 0.55
	# the hill it burrows into, rising to the back
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 2.1, face_z), MOOR_TOP.darkened(0.1), MOOR_TOP)
	for i in 5:  # the moor rolling over the top, humped and heathery
		var hx := 0.4 + i * (w - 0.8) / 4.0
		Meshes.blob(st, Vector3(hx, 2.1, face_z * 0.45), Vector3(0.95, 0.55 + rng.randf() * 0.35, face_z * 0.55),
			MOOR_TOP.lightened(rng.randf_range(-0.04, 0.06)), rng, 0.15)
	for i in 7:
		Meshes.blob(st, Vector3(rng.randf_range(0.3, w - 0.3), 2.45 + rng.randf() * 0.35, rng.randf_range(0.4, face_z - 0.4)),
			Vector3(0.32, 0.18, 0.28), HEATHER_TOP.lightened(rng.randf_range(-0.05, 0.1)), rng, 0.25)
	# the portal face, with coping and a date stone
	Meshes.box(st, Vector3(0, 0, face_z), Vector3(w, 2.2, 0.55), GRITSTONE, GRITSTONE.lightened(0.1))
	Meshes.box(st, Vector3(-0.08, 2.2, face_z - 0.05), Vector3(w + 0.16, 0.18, 0.66), GRITSTONE.lightened(0.12))
	for wing in [-0.35, float(w)]:  # wing walls stepping down either side
		Meshes.box(st, Vector3(wing, 0, face_z - 0.4), Vector3(0.35, 1.5, 0.95), GRIT_SOOT)
	var ax := float(door_x + 1) if door_x >= 0 else w * 0.5 - 1.0
	var aw := 2.0
	var dark := Color("120f0d")
	# the arch: a dark opening stepped round at the top, ringed with paler voussoirs
	Meshes.box(st, Vector3(ax + 0.1, -0.3, d - 0.03), Vector3(aw - 0.2, 1.25, 0.04), dark)
	for s in [[0.18, 1.4], [0.42, 1.55], [0.7, 1.62]]:
		Meshes.box(st, Vector3(ax + float(s[0]), 0.9, d - 0.03), Vector3(aw - 2.0 * float(s[0]), float(s[1]) - 0.9, 0.04), dark)
	var ring := GRITSTONE.lightened(0.18)
	for i in 7:
		var a := PI * i / 6.0
		var cx := ax + aw * 0.5 - cos(a) * (aw * 0.5 + 0.05)
		var cy := 0.95 + sin(a) * 0.72
		Meshes.box(st, Vector3(cx - 0.11, cy - 0.06, d - 0.06), Vector3(0.22, 0.2, 0.06), ring)
	Meshes.box(st, Vector3(ax + aw * 0.5 - 0.4, 1.78, d - 0.06), Vector3(0.8, 0.3, 0.06), Color("d8cfb8"))  # date stone
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.24, 0.0, d - 0.06), Vector3(0.52, 0.95, 0.05), Color("2f3a2a"))  # towpath gate
		Meshes.box(st, Vector3(door_x + 0.18, 0.95, d - 0.07), Vector3(0.64, 0.08, 0.07), ring)

## Leeds Town Hall: a pale stone palace on a podium, a colonnade along the front, the tall clock tower with its
## ring of columns and dome rising from the middle, and the four lions guarding the steps.
static func _leeds_town_hall(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := LEEDS_STONE
	var rng := Meshes._rng(1858)
	var front := d - 0.5
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.2, d), stone.darkened(0.25))
	Meshes.box(st, Vector3(0.2, 0.2, 0.2), Vector3(w - 0.4, 0.2, d - 0.3), stone.darkened(0.18))   # the steps
	Meshes.box(st, Vector3(0.4, 0.4, 0.4), Vector3(w - 0.8, 2.9, front - 0.8), stone)
	Meshes.box(st, Vector3(0.3, 3.3, 0.3), Vector3(w - 0.6, 0.25, front - 0.5), stone.lightened(0.1))  # cornice
	for x in range(1, w - 1):  # balustrade
		Meshes.box(st, Vector3(x + 0.1, 3.55, front - 0.3), Vector3(0.8, 0.22, 0.12), stone.lightened(0.05))
	# the colonnade across the front
	for i in range(0, w - 1):
		Meshes.cylinder(st, Vector3(i + 1.0, 0.4, front - 0.25), 0.15, 2.8, 8, stone.lightened(0.12))
	Meshes.box(st, Vector3(0.6, 3.1, front - 0.45), Vector3(w - 1.2, 0.25, 0.4), stone.lightened(0.08))
	for x in range(1, w - 1):
		if x != door_x:
			_window(st, wst, x + 0.3, 0.9, front - 0.35, 0.4, 0.9, stone.lightened(0.2))  # the face is at front - 0.4
			_window(st, wst, x + 0.32, 2.2, front - 0.35, 0.36, 0.6, stone.lightened(0.2))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0.4, front - 0.46), Vector3(0.7, 1.5, 0.06), Color("3b2a22"))
		Meshes.box(st, Vector3(door_x + 0.08, 1.9, front - 0.47), Vector3(0.84, 0.16, 0.08), stone.lightened(0.2))
	# the tower: a square shaft, the clock stage, a ring of columns, the dome and its finial
	var cx := w * 0.5
	var cz := front * 0.45
	Meshes.box(st, Vector3(cx - 1.5, 3.3, cz - 1.5), Vector3(3.0, 2.2, 3.0), stone.lightened(0.04))
	Meshes.box(st, Vector3(cx - 1.25, 5.5, cz - 1.25), Vector3(2.5, 1.6, 2.5), stone)
	for f in [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var c: Vector3 = Vector3(cx, 6.3, cz) + f * 1.27
		var sz := Vector3(0.05, 0.9, 0.9) if f.x != 0 else Vector3(0.9, 0.9, 0.05)
		Meshes.box(st, c - sz * 0.5, sz, Color("f4efe2"))
		Meshes.box(st, c - Vector3(0.03, -0.05, 0.03) + f * 0.03, Vector3(0.06, 0.32, 0.06), Color("2a2a2a"))
	Meshes.box(st, Vector3(cx - 1.4, 7.1, cz - 1.4), Vector3(2.8, 0.18, 2.8), stone.lightened(0.12))
	for i in 10:
		var a := TAU * i / 10.0
		Meshes.cylinder(st, Vector3(cx + cos(a) * 1.0, 7.28, cz + sin(a) * 1.0), 0.09, 1.3, 6, stone.lightened(0.1))
	Meshes.cylinder(st, Vector3(cx, 7.28, cz), 0.8, 1.35, 10, stone.darkened(0.05))
	Meshes.box(st, Vector3(cx - 1.15, 8.6, cz - 1.15), Vector3(2.3, 0.15, 2.3), stone.lightened(0.12))
	Meshes.blob(st, Vector3(cx, 8.95, cz), Vector3(0.95, 0.75, 0.95), Color("5f6b6a"), rng, 0.02)
	Meshes.cylinder(st, Vector3(cx, 9.6, cz), 0.22, 0.5, 6, stone.lightened(0.1))
	Meshes.cone(st, Vector3(cx, 10.1, cz), 0.2, 0.6, 6, Color("c9a84a"), rng)
	# the lions, couchant on their plinths along the front steps
	for lx in [1.4, 3.4, w - 3.4, w - 1.4]:
		var lz := d - 0.25
		Meshes.box(st, Vector3(lx - 0.35, 0.2, lz - 0.3), Vector3(0.7, 0.35, 0.5), stone.darkened(0.1))
		Meshes.box(st, Vector3(lx - 0.3, 0.55, lz - 0.28), Vector3(0.6, 0.22, 0.32), Color("8f8576"))
		Meshes.blob(st, Vector3(lx, 0.85, lz - 0.02), Vector3(0.17, 0.17, 0.15), Color("8f8576"), rng, 0.05)

## The Corn Exchange: Brodrick's oval hall in dark rusticated stone, ringed with arched windows under a great
## shallow dome of glass, with a lantern on top.
static func _corn_exchange(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("7d7262")
	var sides := 18
	var c := Vector3(w * 0.5, 0, d * 0.5)
	var rx := w * 0.5 - 0.1
	var rz := d * 0.5 - 0.1
	var h := 2.6
	var lo: Array = _ellipse(c, rx, rz, 0.0, sides)
	var hi: Array = _ellipse(c, rx, rz, h, sides)
	for i in sides:
		var j := (i + 1) % sides
		Meshes._quad(st, lo[i], lo[j], hi[j], hi[i], stone.darkened(0.05 * (i % 2)))
		var mid: Vector3 = (lo[i] + lo[j]) * 0.5
		if mid.z > c.z + rz * 0.2:  # arched windows round the southern half, two storeys
			var p: Vector3 = mid + (mid - c).normalized() * 0.03
			for wy in [0.5, 1.6]:
				Meshes.box(wst, Vector3(p.x - 0.18, wy, p.z - 0.03), Vector3(0.36, 0.65, 0.06), window_colour(_wr))
	var ring: Array = _ellipse(c, rx + 0.08, rz + 0.08, h, sides)
	var ring_hi: Array = _ellipse(c, rx + 0.08, rz + 0.08, h + 0.2, sides)
	for i in sides:
		var j := (i + 1) % sides
		Meshes._quad(st, ring[i], ring[j], ring_hi[j], ring_hi[i], stone.lightened(0.15))
	# the dome: three shallow rings of glass and iron, and the lantern
	var glass := Color("8fa3ad")
	var prev: Array = ring_hi
	for k in [[0.82, 0.55], [0.55, 0.95], [0.22, 1.2]]:
		var nxt: Array = _ellipse(c, rx * float(k[0]), rz * float(k[0]), h + 0.2 + float(k[1]), sides)
		for i in sides:
			var j := (i + 1) % sides
			Meshes._quad(st, prev[i], prev[j], nxt[j], nxt[i], glass.darkened(0.12 * (i % 2)) if float(k[0]) > 0.5 else glass.lightened(0.05))
		prev = nxt
	Meshes.cylinder(st, c + Vector3(0, h + 1.4, 0), 0.35, 0.45, 8, stone.lightened(0.1))
	Meshes.cone(st, c + Vector3(0, h + 1.85, 0), 0.4, 0.35, 8, IRON, Meshes._rng(1863))
	if door_x >= 0:  # a porch out to the street
		Meshes.box(st, Vector3(door_x - 0.1, 0, d - 1.0), Vector3(1.2, 1.6, 1.0), stone.lightened(0.05))
		Meshes.box(st, Vector3(door_x + 0.2, 0, d - 0.03), Vector3(0.6, 1.1, 0.05), Color("3b2a22"))

## Kirkgate Market's 1904 hall: a long pale frontage of arched bays, a gable in the middle with a clock, corner
## turrets with little green domes, and the glass roof of the halls behind.
static func _market_hall(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("d8c9a6")
	var trim := Color("b8a06e")
	var rng := Meshes._rng(1904)
	var h := 2.5
	Meshes.box(st, Vector3(0.05, 0, d - 1.6), Vector3(w - 0.1, h, 1.55), stone)
	Meshes.box(st, Vector3(0, 0, d - 1.65), Vector3(w, 0.2, 1.65), trim.darkened(0.2))
	Meshes.box(st, Vector3(-0.05, h, d - 1.7), Vector3(w + 0.1, 0.18, 1.7), trim)
	# the glass halls behind
	Meshes.box(st, Vector3(0.3, 0, 0.2), Vector3(w - 0.6, 1.9, d - 1.8), Color("7a7f84"))
	_roof_at(st, 0.3, w - 0.3, 0.2, d - 1.6, 1.9, 0.9, Color("9fb3b8"), Color("7a7f84"))
	for x in w:
		if x == door_x:
			continue
		_window(st, wst, x + 0.25, 0.35, d, 0.5, 0.85, trim)
		_window(st, wst, x + 0.3, 1.5, d, 0.4, 0.6, trim)
	# the middle gable with its clock
	var mx := w * 0.5
	Meshes.box(st, Vector3(mx - 1.2, h, d - 0.5), Vector3(2.4, 0.9, 0.45), stone)
	Meshes._tri(st, Vector3(mx - 1.3, h + 0.9, d - 0.05), Vector3(mx + 1.3, h + 0.9, d - 0.05), Vector3(mx, h + 1.6, d - 0.05), stone.lightened(0.05))
	Meshes.box(st, Vector3(mx - 0.3, h + 0.3, d - 0.06), Vector3(0.6, 0.6, 0.04), Color("f4efe2"))
	Meshes.box(st, Vector3(mx - 0.03, h + 0.45, d - 0.03), Vector3(0.06, 0.25, 0.03), Color("2a2a2a"))
	# corner turrets with green domes
	for tx in [0.45, w - 0.45]:
		Meshes.cylinder(st, Vector3(tx, 0, d - 0.55), 0.45, h + 1.1, 8, stone.lightened(0.04))
		Meshes.blob(st, Vector3(tx, h + 1.25, d - 0.55), Vector3(0.42, 0.45, 0.42), Color("5f8a72"), rng, 0.02)
		Meshes.cone(st, Vector3(tx, h + 1.6, d - 0.55), 0.08, 0.4, 5, Color("c9a84a"), rng)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.12, 0.2, d - 0.04), Vector3(0.76, 1.2, 0.05), Color("2f3a2a"))
		Meshes.box(st, Vector3(door_x + 0.05, 1.4, d - 0.05), Vector3(0.9, 0.18, 0.06), trim)

## A roofless Cistercian abbey church (Kirkstall): long nave walls broken by tall lancet gaps, a gabled west
## front, and the crossing tower standing tall with one corner fallen away. Grass grows where the roof was.
static func _abbey_ruin(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("9a8e78")
	var dark := Color("2a2622")
	var h := 2.6
	var t := 0.4
	var z0 := 0.4
	var z1 := d - 0.6
	Meshes.box(st, Vector3(0.2, 0, z0), Vector3(w - 0.4, 0.05, z1 - z0), Color("5c7a3c"))
	# the nave walls, roofless and ragged along the top, with a tall lancet window in every bay
	var rng := Meshes._rng(1152)
	for x in range(0, w):
		for zz in [z0, z1 - t]:
			var top: float = h - rng.randf_range(0.0, 0.5) - (0.6 if x == w - 2 else 0.0)
			Meshes.box(st, Vector3(x, 0, zz), Vector3(1.0, top, t), stone.lightened(rng.randf_range(-0.04, 0.04)))
			if x % 2 == 1 and x < w - 1:
				var face: float = zz + t + 0.01 if zz > z0 else zz - 0.04
				Meshes.box(st, Vector3(x + 0.32, 0.6, face), Vector3(0.36, 1.35, 0.03), dark)
				Meshes.box(st, Vector3(x + 0.4, 1.95, face), Vector3(0.2, 0.18, 0.03), dark)
			Meshes.box(st, Vector3(x - 0.06, 0, zz + (t if zz > z0 else -0.12)), Vector3(0.18, top * 0.8, 0.12), stone.darkened(0.08))  # buttress
	# west front with its gable, and a lower broken east end
	Meshes.box(st, Vector3(0.0, 0, z0), Vector3(t + 0.1, h + 0.3, z1 - z0), stone.darkened(0.04))
	Meshes._tri(st, Vector3(0.0, h + 0.3, z1), Vector3(0.0, h + 0.3, z0), Vector3(0.0, h + 1.6, (z0 + z1) * 0.5), stone.darkened(0.08))
	Meshes._tri(st, Vector3(t + 0.1, h + 0.3, z0), Vector3(t + 0.1, h + 0.3, z1), Vector3(t + 0.1, h + 1.6, (z0 + z1) * 0.5), stone.darkened(0.12))
	Meshes.box(st, Vector3(0.05, 0.8, z1 + 0.01), Vector3(0.35, 1.2, 0.03), dark)
	Meshes.box(st, Vector3(w - t - 0.1, 0, z0), Vector3(t + 0.1, h - 0.6, z1 - z0), stone.darkened(0.06))
	# the crossing tower, east of centre, its top broken off on one side
	var tx := w * 0.62
	Meshes.box(st, Vector3(tx - 0.9, 0, z0), Vector3(1.8, 5.0, z1 - z0), stone)
	Meshes.box(st, Vector3(tx - 0.9, 5.0, z0), Vector3(0.9, 0.9, z1 - z0), stone.lightened(0.05))
	Meshes.box(st, Vector3(tx, 5.0, z0), Vector3(0.9, 0.35, (z1 - z0) * 0.5), stone.lightened(0.02))
	for s in [0.6, 2.1, 3.5]:
		Meshes.box(st, Vector3(tx - 0.25, s + 0.4, z1 + 0.01), Vector3(0.5, 0.95, 0.03), dark)
	# the south door: a round-headed arch through a thick porch
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.1, 0, z1 - 0.05), Vector3(1.2, h, d - z1 + 0.05), stone.lightened(0.06))
		Meshes.box(st, Vector3(door_x + 0.2, 0, d - 0.04), Vector3(0.6, 1.2, 0.05), dark)
		Meshes.box(st, Vector3(door_x + 0.28, 1.2, d - 0.04), Vector3(0.44, 0.15, 0.05), dark)

## The Brontë Parsonage: a plain Georgian house in blackened gritstone, five bays of sash windows, a pedimented
## doorcase in the middle, a stone-slate roof and a chimney stack at each gable.
static func _parsonage(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var wall := GRIT_SOOT
	var hgt := 2.5
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), wall)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.18, d), wall.darkened(0.3))
	for q in [0.0, w - 0.18]:
		Meshes.box(st, Vector3(q, 0.18, d - 0.12), Vector3(0.18, hgt - 0.18, 0.14), wall.lightened(0.12))  # quoins
	_roof(st, w, d, hgt, Color("4d4a44"), wall, 0.3)
	for gx in [0.25, w - 0.85]:
		Meshes.box(st, Vector3(gx, hgt + 0.2, d * 0.5 - 0.3), Vector3(0.6, 1.3, 0.6), wall.darkened(0.1))
		_chimneys.append(Vector3(gx + 0.3, hgt + 1.5, d * 0.5))
	for b in [0.6, 2.0, w * 0.5 - 0.22, w - 2.44, w - 1.04]:
		if door_x < 0 or absf(float(b) + 0.22 - (door_x + 0.5)) > 0.4:
			_window(st, wst, float(b), 0.55, d, 0.44, 0.72, Color("e8e2d4"))
		_window(st, wst, float(b), 1.6, d, 0.44, 0.65, Color("e8e2d4"))
	if door_x >= 0:
		_door(st, door_x, d, wall, 1.0)
		Meshes._tri(st, Vector3(door_x + 0.08, 1.24, d + 0.02), Vector3(door_x + 0.92, 1.24, d + 0.02), Vector3(door_x + 0.5, 1.48, d + 0.02), Color("d8cfb8"))

## Pennine weavers' cottages: a gritstone terrace three storeys high, its top floor lit by a long run of small
## mullioned windows where the handlooms stood, under a stone-slate roof with stacks along the ridge.
static func _weavers_cottage(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var wall := GRITSTONE.darkened(rng.randf_range(0.0, 0.12))
	var hgt := 3.1
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), wall)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), wall.darkened(0.3))
	_roof(st, w, d, hgt, Color("55524b"), wall, 0.28)
	for i in range(1, w, 2):
		Meshes.box(st, Vector3(i - 0.2, hgt + 0.25, d * 0.5 - 0.2), Vector3(0.4, 0.9, 0.4), wall.darkened(0.15))
		_chimneys.append(Vector3(i, hgt + 1.15, d * 0.5))
		Meshes.box(st, Vector3(i - 0.03, 0.16, d - 0.04), Vector3(0.06, hgt - 0.2, 0.05), wall.darkened(0.2))
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.3, 0.4, d, 0.4, 0.55, wall.lightened(0.18))
		_window(st, wst, x + 0.3, 1.35, d, 0.4, 0.5, wall.lightened(0.18))
	# the weaving floor: one long band of lights, split by stone mullions
	Meshes.box(st, Vector3(0.15, 2.18, d - 0.07), Vector3(w - 0.3, 0.62, 0.04), wall.lightened(0.2))
	for x in w:
		for k in 3:
			Meshes.box(wst, Vector3(x + 0.08 + k * 0.3, 2.24, d - 0.065), Vector3(0.22, 0.48, 0.04), window_colour(_wr))
	_door(st, door_x, d, wall)
# --- the Potteries ---------------------------------------------------------------

const POT_BRICK := Color("9c5640")   # Staffordshire red brick, a touch more orange than the mill towns'

## A bottle oven seen whole: the brick hovel swells out from a firemouth plinth and draws in to a neck, held
## by iron hoops (bonts). Stands at the middle of its plot; a door column gives it the dark clammins opening.
static func _bottle_kiln(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var r := minf(w, d) * 0.46
	var c := Vector3(w * 0.5, 0, d * 0.5)
	Meshes.cylinder(st, c, r * 1.04, 0.3, 12, POT_BRICK.darkened(0.3))  # plinth
	_bottle(st, c, r, 1.0, POT_BRICK)
	# a brick porch round the clammins (the oven door), standing proud of the swell of the hovel
	var front := c.z + r * 1.14
	Meshes.box(st, Vector3(c.x - 0.45, 0.0, c.z + r * 0.7), Vector3(0.9, 1.15, front - (c.z + r * 0.7)), POT_BRICK.darkened(0.12))
	Meshes.box(st, Vector3(c.x - 0.5, 1.15, c.z + r * 0.7), Vector3(1.0, 0.1, front - (c.z + r * 0.7) + 0.05), LIMESTONE.darkened(0.15))
	Meshes.box(st, Vector3(c.x - 0.25, 0.0, front - 0.01), Vector3(0.5, 0.8, 0.03), Color("221612"))  # the clammins
	if door_x < 0:
		Meshes.box(st, Vector3(c.x - 0.18, 0.02, front), Vector3(0.36, 0.3, 0.03), Color("9a4426"))  # embers, banked low

## The bottle itself: a lathe of brick rings, radius `r` at the waist, `k` scales the height.
static func _bottle(st: SurfaceTool, c: Vector3, r: float, k: float, brick: Color) -> void:
	var prof := [[1.0, 0.0], [1.06, 0.9], [1.0, 2.0], [0.78, 3.0], [0.46, 3.9], [0.36, 4.5], [0.38, 4.85], [0.46, 4.9], [0.46, 5.1], [0.36, 5.12]]
	var sides := 12
	for i in prof.size() - 1:
		var lo := Meshes._ring(c, r * float(prof[i][0]), c.y + float(prof[i][1]) * k, sides)
		var hi := Meshes._ring(c, r * float(prof[i + 1][0]), c.y + float(prof[i + 1][1]) * k, sides)
		var col: Color = brick.darkened(0.05 * (i % 2))
		if i >= 6:
			col = brick.darkened(0.3)
		for j in sides:
			var n := (j + 1) % sides
			Meshes._quad(st, lo[j], lo[n], hi[n], hi[j], col.darkened(0.06 * (j % 2)))
	for y in [1.1, 2.3, 3.3]:  # the bonts
		var rr := r * (1.07 if y < 2.0 else (0.98 if y < 3.0 else 0.72)) + 0.02
		Meshes.cylinder(st, c + Vector3(0, y * k, 0), rr, 0.1 * k, sides, Color("34363c"))

## A potbank: a two-storey Potteries works front in red brick, a round-headed cart arch on the door, and a bottle
## oven rising out of the yard behind the roof.
static func _potbank(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	_house(st, wst, w, d, door_x, rng, POT_BRICK, SLATE, 2, false, false)
	Meshes.box(st, Vector3(0, 2.38, d - 0.06), Vector3(w, 0.1, 0.1), LIMESTONE)  # cornice
	if door_x >= 0:  # the arch: a stone surround with a stepped round head
		var x0 := float(door_x)
		Meshes.box(st, Vector3(x0 + 0.08, 0.16, d - 0.05), Vector3(0.1, 1.0, 0.08), LIMESTONE)
		Meshes.box(st, Vector3(x0 + 0.82, 0.16, d - 0.05), Vector3(0.1, 1.0, 0.08), LIMESTONE)
		Meshes.box(st, Vector3(x0 + 0.14, 1.12, d - 0.05), Vector3(0.72, 0.1, 0.08), LIMESTONE)
		Meshes.box(st, Vector3(x0 + 0.26, 1.22, d - 0.05), Vector3(0.48, 0.08, 0.08), LIMESTONE)
		Meshes.box(st, Vector3(x0 + 0.4, 1.3, d - 0.05), Vector3(0.2, 0.08, 0.08), LIMESTONE.darkened(0.1))  # keystone
	var kx := (w - 1.2) if door_x < w * 0.5 else 1.2
	_bottle(st, Vector3(kx, 0, minf(1.0, d * 0.35)), minf(0.95, d * 0.32), 0.95, POT_BRICK.darkened(0.08))
# --- the Lancashire coast --------------------------------------------------------

const TOWER_RED := Color("a9442f")
const TERRACOTTA := Color("d9b48a")
## statue variant: one of the cast-iron men on Crosby beach.
const IRON_MAN := 3

## Blackpool Tower: the red-brick and terracotta Tower Buildings, with the red lattice tower rising from the
## roof to a lookout and a flagstaff. Little bulbs on the legs and the lookout go in the window mesh, so the
## whole tower lights up at night like the Illuminations.
static func _blackpool_tower(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var hb := 2.5
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hb, d - 0.1), BRICK, BRICK.darkened(0.3))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.2, d), DARK_BRICK)
	for s in 2:
		Meshes.box(st, Vector3(0.0, 1.15 + s * 1.2, d - 0.06), Vector3(w, 0.1, 0.05), TERRACOTTA)
		for x in w:
			if x == door_x and s == 0:
				continue
			_window(st, wst, x + 0.25, 0.4 + 1.15 * s, d, 0.5, 0.6, TERRACOTTA)
	Meshes.box(st, Vector3(-0.05, hb - 0.1, -0.05), Vector3(w + 0.1, 0.18, d + 0.1), TERRACOTTA)
	# little corner turrets on the front of the buildings
	for tx in [0.0, w - 0.7]:
		Meshes.box(st, Vector3(tx, 0, d - 0.75), Vector3(0.7, hb + 0.5, 0.7), BRICK.lightened(0.05), TERRACOTTA)
		Meshes.box(st, Vector3(tx + 0.15, hb + 0.5, d - 0.6), Vector3(0.4, 0.35, 0.4), TERRACOTTA)
	# a grand arched entrance in terracotta
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.15, 0.2, d - 0.14), Vector3(1.3, 1.45, 0.08), TERRACOTTA)
	_door(st, door_x, d, BRICK, 1.1)
	# the tower: four legs leaning in from the roof, braced every storey
	var cx := w * 0.5
	var cz := maxf(d * 0.5, d - 2.3)  # towards the front, so the lattice shows over the prom
	var top := hb + 7.0
	var foot := minf(1.7, minf(w, d) * 0.42)
	var neck := 0.32
	var legs := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var bulb := Color(1, 0.92, 0.6, 1)
	for c in legs:
		_strut(st, Vector3(cx + c.x * foot, hb, cz + c.y * foot), Vector3(cx + c.x * neck, top, cz + c.y * neck), 0.18, TOWER_RED)
	var levels := 7
	for i in levels:
		var y0 := hb + 0.6 + i * 0.95
		var y1 := y0 + 0.95
		var r0 := lerpf(foot, neck, (y0 - hb) / (top - hb))
		var r1 := lerpf(foot, neck, (y1 - hb) / (top - hb))
		Meshes.box(st, Vector3(cx - r0, y0, cz - r0), Vector3(r0 * 2, 0.08, 0.08), TOWER_RED.lightened(0.08))
		Meshes.box(st, Vector3(cx - r0, y0, cz + r0 - 0.08), Vector3(r0 * 2, 0.08, 0.08), TOWER_RED.lightened(0.08))
		Meshes.box(st, Vector3(cx - r0, y0, cz - r0), Vector3(0.08, 0.08, r0 * 2), TOWER_RED)
		Meshes.box(st, Vector3(cx + r0 - 0.08, y0, cz - r0), Vector3(0.08, 0.08, r0 * 2), TOWER_RED)
		if y1 < top - 1.2:
			# the lattice: a cross on the south face (the one you see), a single brace on the others
			_strut(st, Vector3(cx - r0, y0, cz + r0), Vector3(cx + r1, y1, cz + r1), 0.06, TOWER_RED.darkened(0.1))
			_strut(st, Vector3(cx + r0, y0, cz + r0), Vector3(cx - r1, y1, cz + r1), 0.06, TOWER_RED.darkened(0.1))
			_strut(st, Vector3(cx - r0, y0, cz - r0), Vector3(cx - r1, y1, cz + r1), 0.06, TOWER_RED.darkened(0.15))
			_strut(st, Vector3(cx + r0, y0, cz - r0), Vector3(cx + r1, y1, cz + r1), 0.06, TOWER_RED.darkened(0.15))
		for c in legs:
			Meshes.box(wst, Vector3(cx + c.x * r0 - 0.05, y0 + 0.3, cz + c.y * r0 + 0.02), Vector3(0.1, 0.1, 0.1), bulb)
	# the old ballroom-level platform and the lookout near the top
	var py := hb + 0.6
	Meshes.box(st, Vector3(cx - foot - 0.15, py, cz - foot - 0.15), Vector3(foot * 2 + 0.3, 0.12, foot * 2 + 0.3), TOWER_RED.darkened(0.2))
	var ly := top - 1.4
	var lr := 0.75
	Meshes.box(st, Vector3(cx - lr, ly, cz - lr), Vector3(lr * 2, 0.7, lr * 2), Color("e9dcc0"), TOWER_RED)
	Meshes.box(st, Vector3(cx - lr - 0.08, ly - 0.08, cz - lr - 0.08), Vector3(lr * 2 + 0.16, 0.1, lr * 2 + 0.16), TOWER_RED.darkened(0.2))
	for i in 4:
		Meshes.box(wst, Vector3(cx - lr + 0.12 + i * 0.36, ly + 0.25, cz + lr + 0.005), Vector3(0.24, 0.3, 0.03), Color(1, 0.95, 0.75, 1))
	# the cap: a short spire and a flagstaff with a little flag
	Meshes.box(st, Vector3(cx - neck, top, cz - neck), Vector3(neck * 2, 0.5, neck * 2), TOWER_RED.lightened(0.05))
	for i in 3:
		var r := 0.26 - i * 0.08
		Meshes.box(st, Vector3(cx - r, top + 0.5 + i * 0.3, cz - r), Vector3(r * 2, 0.3, r * 2), TOWER_RED.lightened(0.1 * i))
	Meshes.box(st, Vector3(cx - 0.03, top + 1.4, cz - 0.03), Vector3(0.06, 1.0, 0.06), Color("dcdcdc"))
	Meshes.box(st, Vector3(cx + 0.03, top + 2.0, cz - 0.02), Vector3(0.45, 0.28, 0.04), Color("c8102e"))
	Meshes.box(wst, Vector3(cx - 0.07, top + 0.55, cz + neck), Vector3(0.14, 0.14, 0.05), bulb)

## The Big One at the Pleasure Beach: a long white-legged steel coaster, a lift hill climbing from the west end to
## the top, the famous drop, then a run of smaller camelback hills. Runs east-west along the footprint.
static func _big_one(st: SurfaceTool, wst: SurfaceTool, w: int, d: int) -> void:
	var track := Color("2f6fb3")
	var leg := Color("e8e6df")
	var cz := d * 0.5
	# a height profile over the footprint: [x, height]
	var prof := [[0.2, 0.6], [w * 0.28, 6.0], [w * 0.31, 6.2], [w * 0.42, 0.7], [w * 0.55, 3.6], [w * 0.66, 0.9],
		[w * 0.76, 2.4], [w * 0.86, 0.8], [w - 0.3, 0.6]]
	for i in prof.size() - 1:
		var a := Vector3(prof[i][0], prof[i][1], cz)
		var b := Vector3(prof[i + 1][0], prof[i + 1][1], cz)
		var steps := maxi(1, int(a.distance_to(b) / 0.45))
		for k in steps:
			var p0 := a.lerp(b, float(k) / steps)
			var p1 := a.lerp(b, float(k + 1) / steps)
			# two rails and a spine, as thin slabs between the samples
			for off in [-0.22, 0.22]:
				_strut(st, p0 + Vector3(0, 0, off), p1 + Vector3(0, 0, off), 0.07, track)
			_strut(st, p0 + Vector3(0, -0.12, 0), p1 + Vector3(0, -0.12, 0), 0.1, track.darkened(0.25))
			if k % 2 == 0 and p0.y > 0.5:
				_strut(st, Vector3(p0.x, 0, cz - 0.25), Vector3(p0.x, p0.y - 0.15, cz - 0.08), 0.08, leg)
				_strut(st, Vector3(p0.x, 0, cz + 0.25), Vector3(p0.x, p0.y - 0.15, cz + 0.08), 0.08, leg)
				if p0.y > 2.0:
					Meshes.box(st, Vector3(p0.x - 0.04, p0.y * 0.5, cz - 0.22), Vector3(0.08, 0.06, 0.44), leg.darkened(0.1))
			if k % 3 == 1:
				Meshes.box(wst, Vector3(p0.x - 0.04, p0.y + 0.02, cz + 0.27), Vector3(0.08, 0.08, 0.04), Color(1, 0.85, 0.5, 1))
	# a train of cars cresting the lift hill
	var crest := Vector3(prof[1][0], prof[1][1], cz)
	for i in 3:
		var p := crest + Vector3(-0.45 * (i + 1), -0.45 * (i + 1) * 6.0 / (w * 0.28), 0)
		Meshes.box(st, p + Vector3(-0.2, 0.05, -0.28), Vector3(0.4, 0.28, 0.56), Color("d8352a"), Color("f0c43a"))
	# the station shed at the east end
	Meshes.box(st, Vector3(w - 2.2, 0, 0.1), Vector3(2.0, 0.9, d - 0.2), Color("f2efe6"), Color("2f6fb3"))

## A Blackpool Balloon tram: a double-decker in cream and green, on a footprint one tile wide and three long
## (north-south), with its trolley pole up to the overhead wire.
static func _blackpool_tram(st: SurfaceTool, wst: SurfaceTool, w: int, d: int) -> void:
	var cream := Color("efe3c0")
	var green := Color("3f7a4a")
	var x0 := 0.12
	var bw := w - 0.24
	Meshes.box(st, Vector3(x0, 0.0, 0.1), Vector3(bw, 0.18, d - 0.2), Color("2a2a2a"))
	Meshes.box(st, Vector3(x0, 0.18, 0.15), Vector3(bw, 0.55, d - 0.3), green, cream)
	Meshes.box(st, Vector3(x0, 0.73, 0.15), Vector3(bw, 0.5, d - 0.3), cream)
	Meshes.box(st, Vector3(x0, 1.23, 0.15), Vector3(bw, 0.1, d - 0.3), green)
	Meshes.box(st, Vector3(x0, 1.33, 0.15), Vector3(bw, 0.5, d - 0.3), cream, cream.lightened(0.1))
	# rounded-off ends, near enough
	Meshes.box(st, Vector3(x0 + 0.08, 0.18, 0.05), Vector3(bw - 0.16, 1.6, 0.12), cream.darkened(0.05))
	Meshes.box(st, Vector3(x0 + 0.08, 0.18, d - 0.17), Vector3(bw - 0.16, 1.6, 0.12), cream.darkened(0.05))
	for deck in 2:
		var y := 0.82 + deck * 0.6
		for i in 4:
			Meshes.box(wst, Vector3(x0 - 0.01, y, 0.35 + i * (d - 0.7) / 4.0), Vector3(0.02, 0.3, (d - 0.7) / 4.0 - 0.08), Color(1, 0.95, 0.8, 1))
			Meshes.box(wst, Vector3(x0 + bw - 0.01, y, 0.35 + i * (d - 0.7) / 4.0), Vector3(0.02, 0.3, (d - 0.7) / 4.0 - 0.08), Color(1, 0.95, 0.8, 1))
		Meshes.box(wst, Vector3(x0 + 0.15, y, d - 0.06), Vector3(bw - 0.3, 0.3, 0.02), Color(1, 0.95, 0.8, 1))
	# headlamp and the destination blind
	Meshes.box(wst, Vector3(w * 0.5 - 0.08, 0.4, d - 0.05), Vector3(0.16, 0.12, 0.03), Color(1, 1, 0.85, 1))
	Meshes.box(st, Vector3(x0 + 0.15, 1.6, d - 0.07), Vector3(bw - 0.3, 0.14, 0.03), Color("1d1d1d"))
	_strut(st, Vector3(w * 0.5, 1.83, d * 0.5), Vector3(w * 0.5, 2.5, d * 0.5 - 0.9), 0.05, Color("2a2a2a"))

## A seaside pier pavilion at the end of the boards: white walls, a green dome on top, little pennants.
static func _pier_pavilion(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var white := Color("f3f0e6")
	var green := Color("4f8f7a")
	var hgt := 1.4
	# stilts under the deck, so it reads as standing over the sea
	for x in range(0, w + 1):
		for z in [0.2, d - 0.3]:
			Meshes.box(st, Vector3(minf(x, w - 0.15), -0.8, z), Vector3(0.12, 0.85, 0.12), Color("5a4a3a"))
	Meshes.box(st, Vector3(-0.1, 0, -0.1), Vector3(w + 0.2, 0.12, d + 0.2), Color("8a6a4a"))
	Meshes.box(st, Vector3(0.1, 0.12, 0.1), Vector3(w - 0.2, hgt, d - 0.2), white, white)
	Meshes.box(st, Vector3(0.0, hgt + 0.12, 0.0), Vector3(w, 0.12, d), green)
	var rng := Meshes._rng(4242 + w * 7 + d)
	Meshes.cylinder(st, Vector3(w * 0.5, hgt + 0.24, d * 0.5), minf(w, d) * 0.32, 0.4, 8, white)
	Meshes.cone(st, Vector3(w * 0.5, hgt + 0.64, d * 0.5), minf(w, d) * 0.34, 0.9, 8, green, rng)
	Meshes.box(st, Vector3(w * 0.5 - 0.02, hgt + 1.5, d * 0.5 - 0.02), Vector3(0.04, 0.5, 0.04), Color("dcdcdc"))
	Meshes.box(st, Vector3(w * 0.5 + 0.02, hgt + 1.8, d * 0.5), Vector3(0.3, 0.18, 0.03), Color("c8102e"))
	for x in w:
		if x == door_x:
			continue
		_window(st, wst, x + 0.25, 0.45, d - 0.1, 0.5, 0.6, green)
	for x in range(0, w + 1):
		Meshes.box(wst, Vector3(minf(x, w - 0.1), hgt + 0.18, d + 0.01), Vector3(0.1, 0.1, 0.04), Color(1, 0.9, 0.55, 1))
	_door(st, door_x, d - 0.1, white, 1.0)

## One of the hundred cast-iron men of Another Place on Crosby beach: life size, rust brown, gazing out to sea
## (+z faces front: turn it with "rot" to face the water). Barnacles and weed darken the shins.
static func iron_man() -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(9603)
	var iron := Color("6e4a36")
	var weed := Color("3f4a32")
	Meshes.box(st, Vector3(-0.13, 0, -0.06), Vector3(0.1, 0.32, 0.12), weed)
	Meshes.box(st, Vector3(0.03, 0, -0.06), Vector3(0.1, 0.32, 0.12), weed)
	Meshes.box(st, Vector3(-0.13, 0.32, -0.06), Vector3(0.1, 0.36, 0.12), iron.darkened(0.1))
	Meshes.box(st, Vector3(0.03, 0.32, -0.06), Vector3(0.1, 0.36, 0.12), iron.darkened(0.1))
	Meshes.box(st, Vector3(-0.15, 0.68, -0.08), Vector3(0.3, 0.5, 0.16), iron)
	Meshes.box(st, Vector3(-0.22, 0.7, -0.05), Vector3(0.07, 0.46, 0.1), iron.darkened(0.05))
	Meshes.box(st, Vector3(0.15, 0.7, -0.05), Vector3(0.07, 0.46, 0.1), iron.darkened(0.05))
	Meshes.box(st, Vector3(-0.04, 1.18, -0.04), Vector3(0.08, 0.06, 0.08), iron)
	Meshes.blob(st, Vector3(0, 1.32, 0), Vector3(0.09, 0.11, 0.1), iron.lightened(0.05), rng, 0.04)
	Meshes.box(st, Vector3(-0.02, 1.3, 0.08), Vector3(0.04, 0.04, 0.04), iron.darkened(0.15))
	return Meshes._finish(st)

## Southport's Lord Street: two storeys of pale Victorian stone with an iron-and-glass veranda over the pavement,
## held up on slim painted columns, the shop windows glowing underneath.
static func _veranda_shop(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var stone: Color = [Color("e6dcc6"), Color("d9cbb0"), Color("efe6d4")][rng.randi() % 3]
	var iron: Color = [Color("2f4f46"), Color("3a3f5c"), Color("5a2f36")][rng.randi() % 3]
	var hgt := 2.5
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), stone)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), stone.darkened(0.3))
	Meshes.box(st, Vector3(-0.05, hgt - 0.12, -0.05), Vector3(w + 0.1, 0.18, d + 0.1), stone.lightened(0.1))
	_roof(st, w, d, hgt, SLATE, stone, 0.3)
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.12, 0.3, d, 0.76, 0.85, iron)
		_window(st, wst, x + 0.3, 1.55, d, 0.4, 0.6, stone.darkened(0.1))
	_door(st, door_x, d, stone, 1.0)
	# the veranda: columns at the kerb, a glass roof sloping back to the wall, a fretwork valance
	for x in range(0, w + 1):
		Meshes.box(st, Vector3(minf(x, w - 0.08), 0, d + 0.78), Vector3(0.08, 1.25, 0.08), iron)
	Meshes.box(st, Vector3(-0.05, 1.25, d - 0.02), Vector3(w + 0.1, 0.06, 0.9), Color("b9cfd4"), Color("cfe2e6"))
	Meshes.box(st, Vector3(-0.05, 1.12, d + 0.8), Vector3(w + 0.1, 0.14, 0.05), iron)

## A Blackpool guest house: a tall red-brick terrace with white bay windows on two floors, a painted porch and a
## little board in the window. Seaside pastel trims vary house to house.
static func _guest_house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var trims := [Color("f2efe6"), Color("bfe0dc"), Color("f4d6dc"), Color("f3e3a6")]
	var hgt := 3.3
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), BRICK)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), DARK_BRICK)
	_roof(st, w, d, hgt, SLATE, BRICK, 0.35)
	for x in range(0, w, 2):
		var trim: Color = trims[rng.randi() % trims.size()]
		var bw := minf(1.3, w - x - 0.5)
		var bx := float(x) + 0.35
		if x <= door_x and door_x < x + 2:
			# the porch: a painted surround and a fanlight over the door, a window beside it
			Meshes.box(st, Vector3(door_x + 0.1, 0.16, d - 0.05), Vector3(0.8, 1.2, 0.14), trim)
			var wx := float(x) + (1.25 if door_x == x else 0.2)
			_window(st, wst, wx, 0.45, d, 0.5, 0.6, trim)
		else:
			# a two-storey bay, painted, with a window on each floor
			Meshes.box(st, Vector3(bx, 0.16, d - 0.05), Vector3(bw, 2.2, 0.26), BRICK.lightened(0.04), trim)
			Meshes.box(st, Vector3(bx - 0.04, 1.08, d - 0.05), Vector3(bw + 0.08, 0.1, 0.32), trim)
			Meshes.box(st, Vector3(bx - 0.04, 2.36, d - 0.05), Vector3(bw + 0.08, 0.1, 0.32), trim)
			_window(st, wst, bx + 0.12, 0.42, d + 0.28, bw - 0.24, 0.58, trim)
			_window(st, wst, bx + 0.12, 1.42, d + 0.28, bw - 0.24, 0.58, trim)
		_window(st, wst, bx + 0.25, 2.62, d, bw - 0.5, 0.45, trim)
		Meshes.box(st, Vector3(x + 0.95, hgt + 0.3, d * 0.5 - 0.2), Vector3(0.35, 0.8, 0.4), BRICK.darkened(0.2))
		_chimneys.append(Vector3(x + 1.12, hgt + 1.1, d * 0.5))
	_door(st, door_x, d + 0.1, BRICK, 0.9)

# --- Bristol -----------------------------------------------------------------

## The Clifton Suspension Bridge's span in tiles, tower to tower (the deck is the zone's own bridge-deck tiles).
const CLIFTON_SPAN := 15
const PENNANT := Color("8b8172")      # the towers' Pennant sandstone
const CHAIN := Color("3a3f47")

## A quad seen from both sides (hulls and balloon gores are built from sections, whichever way they wind).
static func _quad2(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	Meshes._quad(st, a, b, c, d, col)
	Meshes._quad(st, d, c, b, a, col)

## A rod from a to b, mostly along x (chains, rails): a box skewed between the two ends, `ty` tall, `tz` deep.
static func _rod(st: SurfaceTool, a: Vector3, b: Vector3, ty: float, tz: float, col: Color) -> void:
	var c := [Vector3(0, ty, -tz), Vector3(0, ty, tz), Vector3(0, -ty, tz), Vector3(0, -ty, -tz)]
	for i in 4:
		var j := (i + 1) % 4
		Meshes._quad(st, a + c[i], b + c[i], b + c[j], a + c[j], col.darkened(0.08 * (i % 2)))

## The Clifton Suspension Bridge, drawn from its north-west footprint tile (the Leigh Woods tower's north leg):
## two tall Pennant stone towers, each an arch the road runs through, CLIFTON_SPAN tiles apart; a pair of iron
## chains sagging between them and on back into the rock; hangers down to the deck and a railing either side.
## The deck itself is the zone's walkable deck row (z 1 to 2 here), so the mesh adds only what stands on it.
static func _suspension_bridge(st: SurfaceTool) -> void:
	var th := 3.4        # tower height above the deck
	var z_n := 0.88      # the chains run just outside the deck's edges
	var z_s := 2.12
	for tx in [0.5, CLIFTON_SPAN + 0.5]:
		# two legs, one each side of the road, tapering a little, with a plain cap: the sphinxes never came
		for lz in [0.22, 2.18]:
			Meshes.box(st, Vector3(tx - 0.5, -0.4, lz), Vector3(1.0, 0.4, 0.6), PENNANT.darkened(0.15))
			Meshes.box(st, Vector3(tx - 0.42, 0, lz + 0.04), Vector3(0.84, th - 0.9, 0.52), PENNANT)
			Meshes.box(st, Vector3(tx - 0.38, th - 0.9, lz + 0.06), Vector3(0.76, 0.6, 0.48), PENNANT.lightened(0.04))
		# the arch over the road and the flat cornice that crowns the tower
		Meshes.box(st, Vector3(tx - 0.42, th - 1.3, 0.62), Vector3(0.84, 1.0, 1.6), PENNANT.lightened(0.02))
		Meshes.box(st, Vector3(tx - 0.42, th - 1.42, 0.78), Vector3(0.84, 0.12, 1.28), PENNANT.darkened(0.25))
		Meshes.box(st, Vector3(tx - 0.5, th - 0.3, 0.2), Vector3(1.0, 0.18, 2.6), PENNANT.lightened(0.1))
		Meshes.box(st, Vector3(tx - 0.46, th - 0.12, 0.26), Vector3(0.92, 0.14, 2.48), PENNANT.darkened(0.05))
		# saddles where the chains ride over the top
		for cz in [z_n, z_s]:
			Meshes.box(st, Vector3(tx - 0.2, th + 0.02, cz - 0.1), Vector3(0.4, 0.14, 0.2), CHAIN.lightened(0.15))
	var segs := 16
	for cz in [z_n, z_s]:
		var prev := Vector3(0.5, th + 0.06, cz)
		for i in range(1, segs + 1):
			var u := float(i) / segs
			var x := 0.5 + u * CLIFTON_SPAN
			var y := 0.55 + (th - 0.5) * pow(2.0 * u - 1.0, 2.0)  # a parabola, as a loaded chain hangs
			var p := Vector3(x, y, cz)
			_rod(st, prev, p, 0.07, 0.06, CHAIN)
			prev = p
		# backstays: on down into the rock behind each tower
		_rod(st, Vector3(0.5, th + 0.06, cz), Vector3(-2.3, -0.3, cz), 0.07, 0.06, CHAIN)
		_rod(st, Vector3(CLIFTON_SPAN + 0.5, th + 0.06, cz), Vector3(CLIFTON_SPAN + 3.3, -0.3, cz), 0.07, 0.06, CHAIN)
		# hangers, one a tile, from the chain down to the deck
		for k in range(1, CLIFTON_SPAN):
			var u := float(k) / CLIFTON_SPAN
			var y := 0.55 + (th - 0.5) * pow(2.0 * u - 1.0, 2.0)
			Meshes.box(st, Vector3(0.48 + k, 0, cz - 0.02), Vector3(0.04, maxf(0.1, y - 0.05), 0.04), CHAIN.lightened(0.1))
	# the deck's girders and railings either side, tower to tower
	for rz in [1.0, 1.96]:
		Meshes.box(st, Vector3(0.9, -0.34, rz - 0.04), Vector3(CLIFTON_SPAN - 0.8, 0.34, 0.08), CHAIN.darkened(0.1))
		Meshes.box(st, Vector3(0.9, 0.42, rz - 0.03), Vector3(CLIFTON_SPAN - 0.8, 0.05, 0.06), Color("d8d2c2"))
		for k in range(1, CLIFTON_SPAN * 2):
			Meshes.box(st, Vector3(0.9 + k * 0.5, 0, rz - 0.02), Vector3(0.03, 0.42, 0.04), Color("cfc8b6"))

## Brunel's SS Great Britain in her dry dock: a long black iron hull with its cream band and gilded bow and
## stern, six masts with their yards, one funnel, all along x; round her waterline the dock's glass "sea".
static func _ss_great_britain(st: SurfaceTool, wst: SurfaceTool, w: int, d: int) -> void:
	var cz := d * 0.5
	var beam := minf(d * 0.42, 1.15)
	var deck := 1.7
	var black := Color("1e2024")
	var cream := Color("e6dcc0")
	var gilt := Color("c9a441")
	# the dock walls and the glass plate at the waterline
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.9, 0.12), Color("8f8574"))
	Meshes.box(st, Vector3(0, 0, d - 0.12), Vector3(w, 0.9, 0.12), Color("8f8574"))
	Meshes.box(st, Vector3(0, 0.86, 0.1), Vector3(w, 0.03, d - 0.2), Color("7fa9a4"), Color("9cc7c1"))
	# the hull: stations from the stern (x = 0.4) to the stem (x = w - 0.1)
	var n := 12
	var secs := []
	for i in n + 1:
		var u := float(i) / n
		var x := lerpf(0.45, w - 0.15, u)
		var half := beam * (sqrt(clampf(u * 6.0, 0.0, 1.0)) * 0.25 + 0.75 if u < 0.7 else cos((u - 0.7) / 0.3 * PI * 0.5) * 0.92 + 0.06)
		var sheer := 0.18 * pow(2.0 * u - 1.0, 2.0)  # the deck line rises a touch fore and aft
		secs.append([Vector3(x, deck + sheer, cz - half), Vector3(x, 1.4, cz - half), Vector3(x, 1.25, cz - half * 0.99),
			Vector3(x, 0.88, cz - half * 0.94), Vector3(x, 0.88, cz + half * 0.94), Vector3(x, 1.25, cz + half * 0.99),
			Vector3(x, 1.4, cz + half), Vector3(x, deck + sheer, cz + half)])
	var bands := [black, cream, black, null, black, cream, black]
	for i in n:
		var a: Array = secs[i]
		var b: Array = secs[i + 1]
		for k in 7:
			if bands[k] == null:
				continue
			_quad2(st, a[k], b[k], b[k + 1], a[k + 1], (bands[k] as Color).darkened(0.1 if k < 3 else 0.0))
		# the deck, planked
		_quad2(st, a[7], b[7], b[0], a[0], Color("b48a5c").darkened(0.05 * (i % 2)))
	# the stern: a flat transom with gilded gallery windows
	var s0: Array = secs[0]
	_quad2(st, s0[0], s0[7], s0[4], s0[3], black.lightened(0.05))
	Meshes.box(st, Vector3(0.38, 1.3, cz - beam * 0.55), Vector3(0.06, 0.2, beam * 1.1), gilt)
	for k in 4:
		Meshes.box(wst, Vector3(0.36, 1.05, cz - beam * 0.5 + 0.08 + k * beam * 0.27), Vector3(0.05, 0.16, beam * 0.16), window_colour(_wr))
	# portholes along the cream band
	for x in range(1, w - 1):
		for side in [-1.0, 1.0]:
			Meshes.box(st, Vector3(x + 0.4, 1.28, cz + side * (beam * 0.995) - 0.03), Vector3(0.12, 0.08, 0.06), Color("2c2a28"))
	# bow: bowsprit, gilded trail boards and figurehead
	var stem: Array = secs[n]
	_rod(st, Vector3(w - 0.2, deck + 0.1, cz), Vector3(w + 1.4, deck + 0.75, cz), 0.05, 0.05, Color("8a6a44"))
	Meshes.box(st, Vector3(w - 0.55, 1.35, cz - 0.16), Vector3(0.45, 0.22, 0.32), gilt)
	Meshes.box(st, Vector3(w - 0.25, 1.1, cz - 0.07), Vector3(0.3, 0.4, 0.14), cream)
	# six masts (Monday to Saturday, as the crew called them) with their yards, and one funnel
	var masts := [0.14, 0.27, 0.42, 0.56, 0.7, 0.84]
	for m in masts.size():
		var mx := lerpf(0.45, w - 0.15, float(masts[m]))
		var mh := 3.4 if m in [1, 2] else 2.9
		Meshes.box(st, Vector3(mx - 0.06, deck, cz - 0.06), Vector3(0.12, mh, 0.12), Color("6d5236"))
		for yd in [0.55, 0.78]:
			Meshes.box(st, Vector3(mx - 0.04, deck + mh * yd, cz - beam * 0.75), Vector3(0.08, 0.06, beam * 1.5), Color("5a4430"))
		# a pair of stays to the deck either side
		_rod(st, Vector3(mx, deck + mh * 0.9, cz), Vector3(mx - 0.5, deck, cz - beam * 0.9), 0.015, 0.015, Color("2a2420"))
		_rod(st, Vector3(mx, deck + mh * 0.9, cz), Vector3(mx - 0.5, deck, cz + beam * 0.9), 0.015, 0.015, Color("2a2420"))
	var fx := lerpf(0.45, w - 0.15, 0.49)
	Meshes.cylinder(st, Vector3(fx, deck, cz), 0.26, 1.5, 10, Color("2a2622"))
	Meshes.cylinder(st, Vector3(fx, deck + 1.3, cz), 0.25, 0.2, 10, Color("6b3a2a"))
	# skylights on the deck over the saloons
	for x in [fx - 1.6, fx + 1.4]:
		Meshes.box(st, Vector3(x, deck, cz - 0.2), Vector3(0.6, 0.18, 0.4), Color("e2d6b4"))

## The Matthew: a little three-masted caravel of John Cabot's day, raised aftcastle, square sails furled on the
## fore and main yards and a lateen on the mizzen. Floats in her footprint (give the tiles a water colour).
static func _caravel(st: SurfaceTool, w: int, d: int) -> void:
	var wood := Color("6b4a2e")
	var dark := Color("4a321e")
	var cz := d * 0.5
	var half := minf(d * 0.36, 0.7)
	var n := 8
	var prev := []
	for i in n + 1:
		var u := float(i) / n
		var x := lerpf(0.2, w - 0.2, u)
		var hb := half * (0.85 + 0.15 * sin(u * PI)) if u < 0.75 else half * cos((u - 0.75) / 0.25 * PI * 0.5) + 0.04
		var top := 0.75 + (0.35 if u < 0.25 else 0.0) + 0.2 * pow(2.0 * u - 1.0, 2.0)
		var sec := [Vector3(x, top, cz - hb), Vector3(x, -0.05, cz - hb * 0.85), Vector3(x, -0.05, cz + hb * 0.85), Vector3(x, top, cz + hb)]
		if i > 0:
			_quad2(st, prev[0], sec[0], sec[1], prev[1], wood)
			_quad2(st, prev[2], sec[2], sec[3], prev[3], wood.darkened(0.06))
			_quad2(st, prev[3], sec[3], sec[0], prev[0], Color("a68458"))
		prev = sec
	Meshes.box(st, Vector3(0.2, 0.75, cz - half), Vector3(w * 0.25, 0.08, half * 2.0), dark)  # the aftcastle rail
	for k in 3:
		Meshes.box(st, Vector3(0.3, 0.45, cz - half - 0.01 + k * 0.0), Vector3(w * 0.9 - 0.4, 0.06, 0.02), Color("c9a441"))
	var mast := Color("5a4430")
	var sail := Color("efe6cc")
	for spec in [[0.78, 2.2], [0.5, 2.7], [0.2, 2.0]]:
		var mx := lerpf(0.2, w - 0.2, float(spec[0]))
		Meshes.box(st, Vector3(mx - 0.05, 0.5, cz - 0.05), Vector3(0.1, float(spec[1]), 0.1), mast)
	for spec in [[0.78, 1.7], [0.5, 2.1]]:
		var mx := lerpf(0.2, w - 0.2, float(spec[0]))
		Meshes.box(st, Vector3(mx - 0.04, float(spec[1]) + 0.45, cz - half * 1.2), Vector3(0.08, 0.06, half * 2.4), mast)
		Meshes.box(st, Vector3(mx - 0.1, float(spec[1]) - 0.35, cz - half * 1.1), Vector3(0.06, 0.8, half * 2.2), sail)
	var lx := lerpf(0.2, w - 0.2, 0.2)
	Meshes._tri(st, Vector3(lx, 2.4, cz), Vector3(lx + 0.8, 0.9, cz), Vector3(lx - 0.6, 0.9, cz), sail.darkened(0.04))
	Meshes._tri(st, Vector3(lx, 2.4, cz), Vector3(lx - 0.6, 0.9, cz), Vector3(lx + 0.8, 0.9, cz), sail.darkened(0.1))
	# a red cross pennant at the main truck
	var mm := lerpf(0.2, w - 0.2, 0.5)
	Meshes.box(st, Vector3(mm + 0.05, 3.0, cz - 0.01), Vector3(0.45, 0.22, 0.02), Color("f2efe6"))
	Meshes.box(st, Vector3(mm + 0.22, 3.0, cz - 0.015), Vector3(0.08, 0.22, 0.03), Color("c8102e"))
	_rod(st, Vector3(w - 0.25, 0.85, cz), Vector3(w + 0.7, 1.3, cz), 0.035, 0.035, mast)

## A hot-air balloon tethered for the Fiesta: a wicker basket on the grass, the burner frame and the envelope
## above, its gores striped in one of the festival's colourways (picked by the building's seed).
const BALLOON_COLOURS := [
	[Color("e8402a"), Color("f6c33a")], [Color("2a6fd6"), Color("f2efe6")], [Color("3aa05a"), Color("f6c33a"), Color("e8402a")],
	[Color("8a3ab0"), Color("f2a33a")], [Color("e04a8a"), Color("f2efe6"), Color("2a6fd6")], [Color("f08a2a"), Color("2a2a2a")]]
static func _hot_air_balloon(st: SurfaceTool, w: int, d: int, rng: RandomNumberGenerator) -> void:
	var c := Vector3(w * 0.5, 0, d * 0.5)
	var wicker := Color("a07848")
	Meshes.box(st, Vector3(c.x - 0.28, 0, c.z - 0.28), Vector3(0.56, 0.5, 0.56), wicker, wicker.darkened(0.35))
	Meshes.box(st, Vector3(c.x - 0.3, 0.46, c.z - 0.3), Vector3(0.6, 0.06, 0.6), Color("5a3a22"))
	Meshes.box(st, Vector3(c.x - 0.12, 0.95, c.z - 0.12), Vector3(0.24, 0.16, 0.24), Color("8a8e94"))  # the burner
	for k in 4:
		var cx := -0.26 if k % 2 == 0 else 0.26
		var czz := -0.26 if k < 2 else 0.26
		_rod(st, Vector3(c.x + cx, 0.5, c.z + czz), Vector3(c.x + cx * 0.8, 1.5, c.z + czz * 0.8), 0.015, 0.015, Color("3a3430"))
	var cols: Array = BALLOON_COLOURS[rng.randi() % BALLOON_COLOURS.size()]
	var sides := 12
	# profile: [radius, height] from the mouth up to the crown
	var prof := [[0.26, 1.5], [0.45, 1.75], [0.72, 2.15], [0.9, 2.65], [0.95, 3.1], [0.86, 3.55], [0.62, 3.9], [0.28, 4.08], [0.0, 4.12]]
	for b in prof.size() - 1:
		var lo := Meshes._ring(c, float(prof[b][0]), float(prof[b][1]), sides)
		var hi := Meshes._ring(c, float(prof[b + 1][0]), float(prof[b + 1][1]), sides)
		for i in sides:
			var j := (i + 1) % sides
			var col: Color = cols[i % cols.size()]
			if b == 0:
				col = col.darkened(0.25)
			_quad2(st, lo[i], lo[j], hi[j], hi[i], col)

## Bristol's painted terraces (Cliftonwood, Hotwells, Totterdown): Georgian and Victorian houses stepping down the
## hill, each one a different bright colour, with white sash windows and a parapet hiding the roof.
const PAINTED := [Color("e8a0b0"), Color("f2d36b"), Color("8cc7d8"), Color("a8d08d"), Color("f0a868"), Color("c6a6dc"), Color("f4ece0"), Color("e07a6a")]
static func _painted_terrace(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var hgt := 2.6
	var start := rng.randi() % PAINTED.size()
	for x in w:
		var col: Color = PAINTED[(start + x * 3) % PAINTED.size()]
		var hh := hgt + (0.12 if x % 2 == 0 else 0.0)
		Meshes.box(st, Vector3(x + 0.02, 0, 0.05), Vector3(0.96, hh, d - 0.1), col)
		Meshes.box(st, Vector3(x, hh, 0.0), Vector3(1.0, 0.16, d), col.lightened(0.15))  # the parapet
		Meshes.box(st, Vector3(x + 0.35, hh + 0.16, d * 0.5 - 0.15), Vector3(0.3, 0.45, 0.3), Color("8a7a6c"))
		_chimneys.append(Vector3(x + 0.5, hh + 0.61, d * 0.5))
		for s in 2:
			if s == 0 and x == door_x:
				continue
			_window(st, wst, x + 0.27, 0.42 + s * 1.15, d, 0.46, 0.62, Color("f4f1ea"))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), Color("6a645c"))
	if door_x >= 0:
		_door(st, door_x, d, Color("f4f1ea"))

## Bristol Byzantine: a Victorian warehouse in red brick, its round arches picked out in yellow and black brick
## (the Granary on Welsh Back is the famous one), with a flat-topped parapet of little arches.
static func _bristol_byzantine(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var hgt := 3.3
	var red := Color("a3483a")
	var yellow := Color("e2c27a")
	var black := Color("2c2624")
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), red)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.2, d), red.darkened(0.3))
	for s in 3:
		var wy := 0.45 + s * 1.0
		Meshes.box(st, Vector3(0.05, wy + 0.78, d - 0.06), Vector3(w - 0.1, 0.06, 0.04), yellow)  # a string course
		for x in w:
			if s == 0 and x == door_x:
				continue
			# a round-arched window: dark voussoirs and a yellow keystone band over the glass
			Meshes.box(st, Vector3(x + 0.22, wy + 0.55, d - 0.075), Vector3(0.56, 0.12, 0.04), black)
			Meshes.box(st, Vector3(x + 0.3, wy + 0.64, d - 0.08), Vector3(0.4, 0.08, 0.04), yellow)
			Meshes.box(wst, Vector3(x + 0.28, wy, d - 0.065), Vector3(0.44, 0.55, 0.04), window_colour(_wr))
	# the arcaded parapet
	for x in range(0, w * 2):
		Meshes.box(st, Vector3(x * 0.5 + 0.05, hgt, d - 0.15), Vector3(0.4, 0.28, 0.15), yellow if x % 2 == 0 else red)
	Meshes.box(st, Vector3(0, hgt + 0.28, 0), Vector3(w, 0.1, d), black.lightened(0.15))
	_door(st, door_x, d, yellow, 1.0)
# --- Swansea and Gower (Wider Isles, R5) -----------------------------------------

## The Liberty: a closed bowl of four stands under a white cantilever roof ring, the pitch inside. Its door is
## the turnstile block in the south stand.
static func _football_stadium(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var clad := Color("8e9aa6")
	var seat := Color("2a3e6a")
	var seat2 := Color("e8ecf0")
	var roof := Color("f2f4f6")
	var h := 2.3
	var t := 1.9  # stand depth: the pitch is inset this far each side
	# the pitch, with its lines
	Meshes.box(st, Vector3(t, 0, t), Vector3(w - 2 * t, 0.06, d - 2 * t), Color("4f8a3e"), Color("5a9a46"))
	Meshes.box(st, Vector3(w * 0.5 - 0.03, 0.06, t), Vector3(0.06, 0.01, d - 2 * t), Color.WHITE)
	Meshes.box(st, Vector3(t + 0.1, 0.06, t + 0.1), Vector3(w - 2 * t - 0.2, 0.01, 0.05), Color.WHITE)
	Meshes.box(st, Vector3(t + 0.1, 0.06, d - t - 0.15), Vector3(w - 2 * t - 0.2, 0.01, 0.05), Color.WHITE)
	# outer walls, with a white band at the top
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, h, 0.3), clad)
	Meshes.box(st, Vector3(0, 0, d - 0.3), Vector3(w, h, 0.3), clad)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(0.3, h, d), clad.darkened(0.05))
	Meshes.box(st, Vector3(w - 0.3, 0, 0), Vector3(0.3, h, d), clad.darkened(0.05))
	for z in [-0.02, float(d)]:
		Meshes.box(st, Vector3(0, h - 0.45, z), Vector3(w, 0.18, 0.04), seat2)
	# raked seating on all four sides: stepped boxes in alternating shades so the rows read
	var steps := 4
	for i in steps:
		var k := float(i) / steps
		var y := 0.25 + k * (h - 0.6)
		var inset := t - (t - 0.3) * k
		var c := seat if i % 2 == 0 else seat.lightened(0.12)
		Meshes.box(st, Vector3(0.3, 0, 0.3), Vector3(w - 0.6, y, inset - 0.3), c)
		Meshes.box(st, Vector3(0.3, 0, d - inset), Vector3(w - 0.6, y, inset - 0.3), c)
		Meshes.box(st, Vector3(0.3, 0, 0.3), Vector3(inset - 0.3, y, d - 0.6), c.darkened(0.05))
		Meshes.box(st, Vector3(w - inset, 0, 0.3), Vector3(inset - 0.3, y, d - 0.6), c.darkened(0.05))
	# the roof: a white ring cantilevered over the stands, on a row of trusses
	var ry := h + 0.5
	Meshes.box(st, Vector3(-0.2, ry, -0.2), Vector3(w + 0.4, 0.14, t + 0.2), roof)
	Meshes.box(st, Vector3(-0.2, ry, d - t), Vector3(w + 0.4, 0.14, t + 0.2), roof)
	Meshes.box(st, Vector3(-0.2, ry, t), Vector3(t + 0.2, 0.14, d - 2 * t), roof)
	Meshes.box(st, Vector3(w - t, ry, t), Vector3(t + 0.2, 0.14, d - 2 * t), roof)
	for x in range(1, w, 2):
		Meshes.box(st, Vector3(x, h, 0.0), Vector3(0.08, 0.5, 0.08), roof.darkened(0.2))
		Meshes.box(st, Vector3(x, h, d - 0.08), Vector3(0.08, 0.5, 0.08), roof.darkened(0.2))
		Meshes.box(st, Vector3(x - 0.04, ry + 0.14, 0.2), Vector3(0.08, 0.22, t - 0.2), roof.darkened(0.1))
		Meshes.box(st, Vector3(x - 0.04, ry + 0.14, d - t), Vector3(0.08, 0.22, t - 0.2), roof.darkened(0.1))
	# floodlights tucked under the roof edge, lit at night
	for x in [t + 0.5, w - t - 1.0]:
		Meshes.box(wst, Vector3(x, ry - 0.12, t - 0.1), Vector3(0.5, 0.1, 0.08), window_colour(_wr))
		Meshes.box(wst, Vector3(x, ry - 0.12, d - t + 0.02), Vector3(0.5, 0.1, 0.08), window_colour(_wr))
	# turnstiles and the glass entrance block on the south side
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 1.0, 0, d - 0.15), Vector3(3.0, 1.4, 0.3), seat)
		Meshes.box(wst, Vector3(door_x - 0.8, 0.3, d + 0.12), Vector3(0.6, 0.8, 0.04), window_colour(_wr))
		Meshes.box(wst, Vector3(door_x + 1.2, 0.3, d + 0.12), Vector3(0.6, 0.8, 0.04), window_colour(_wr))
		_door(st, door_x, d + 0.15, seat, 1.0)

## Hafod-Morfa: the Musgrave engine house, a tall stone box with round-headed windows, beside the roofless shell
## of a smelting shed and a square stone stack, capped in black copper-slag blocks.
static func _engine_house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("8a8278")
	var slag := Color("2a2628")
	var ew := minf(4.0, w * 0.5)
	var ex := clampf(door_x - 1.5, 0.0, w - ew)
	var eh := 3.6
	Meshes.box(st, Vector3(ex, 0, 0.6), Vector3(ew, eh, d - 0.7), stone, stone.lightened(0.1))
	_roof_at(st, ex - 0.1, ex + ew + 0.1, 0.5, d, eh, 0.9, SLATE.darkened(0.15), stone)
	Meshes.box(st, Vector3(ex - 0.05, eh - 0.15, 0.55), Vector3(ew + 0.1, 0.15, d - 0.6), slag)
	for x in [ex + 0.4, ex + ew - 0.9]:
		_window(st, wst, x, 1.8, d - 0.1, 0.5, 1.2, stone.lightened(0.25))
		Meshes.box(st, Vector3(x - 0.05, 3.0, d - 0.15), Vector3(0.6, 0.12, 0.06), stone.lightened(0.25))
	# the roofless works on the wider side: broken walls of uneven height with slag coping
	var left := ex
	var right := w - (ex + ew)
	var rx := ex + ew if right >= left else 0.0
	var rw := right if right >= left else left
	if rw > 0.9:
		var hs := [1.6, 1.1, 1.8, 1.3, 1.5, 0.9]
		var n := int(rw)
		for i in n:
			var hh: float = hs[i % hs.size()]
			Meshes.box(st, Vector3(rx + i, 0, d - 0.35), Vector3(1.0, hh, 0.3), stone.darkened(0.08))
			Meshes.box(st, Vector3(rx + i, hh, d - 0.37), Vector3(1.0, 0.12, 0.34), slag)
			if i % 2 == 0:
				Meshes.box(st, Vector3(rx + i + 0.35, 0.3, d - 0.02), Vector3(0.3, 0.7, 0.04), Color("1e1a18"))
		Meshes.box(st, Vector3(rx + rw - 0.3, 0, 0.6), Vector3(0.3, 1.2, d - 0.9), stone.darkened(0.1))
		Meshes.box(st, Vector3(rx, 0, 0.6), Vector3(rw, 1.0, 0.3), stone.darkened(0.12))
		# the stack: square stone, then brick, very tall
		var sx := rx + rw - 1.0
		Meshes.box(st, Vector3(sx, 0, 0.7), Vector3(0.8, 4.2, 0.8), stone.darkened(0.04))
		Meshes.box(st, Vector3(sx + 0.05, 4.2, 0.75), Vector3(0.7, 2.6, 0.7), DARK_BRICK)
		Meshes.box(st, Vector3(sx - 0.05, 6.8, 0.65), Vector3(0.9, 0.2, 0.9), slag)
	_door(st, door_x, d - 0.1, stone, 1.2)

## Swansea Market: low walls of brick and stone under a long glass barrel roof on white ribs, a grand entrance
## arch on the door.
static func _swansea_market_hall(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var brick := Color("a65a44")
	var dress := Color("d8cdb4")
	var glass := Color("b8d4dc")
	var h := 1.7
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), brick)
	Meshes.box(st, Vector3(0, h - 0.18, 0), Vector3(w, 0.18, d), dress)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.2, d), brick.darkened(0.3))
	# the barrel vault, ridge east-west: eight facets from the south eave over to the north one
	var seg := 8
	var r := d * 0.5
	var cz := d * 0.5
	var rise := minf(1.6, r)
	for i in seg:
		var a0 := PI * i / seg
		var a1 := PI * (i + 1) / seg
		var p0 := Vector3(0, h + sin(a0) * rise, cz + cos(a0) * r)
		var p1 := Vector3(0, h + sin(a1) * rise, cz + cos(a1) * r)
		var shade := glass.darkened(0.12 * float(i) / seg)
		Meshes._quad(st, p0 + Vector3(w, 0, 0), p1 + Vector3(w, 0, 0), p1, p0, shade)
		Meshes._quad(st, p0, p1, p1 + Vector3(w, 0, 0), p0 + Vector3(w, 0, 0), shade.darkened(0.3))
		for x in range(0, w + 1, 2):
			var xx := minf(float(x), w - 0.08)
			Meshes._quad(st, p0 + Vector3(xx + 0.08, 0.02, 0), p1 + Vector3(xx + 0.08, 0.02, 0), p1 + Vector3(xx, 0.02, 0), p0 + Vector3(xx, 0.02, 0), Color.WHITE)
		Meshes._tri(st, Vector3(0, h, cz), p1, p0, dress.darkened(0.05))
		Meshes._tri(st, Vector3(w, h, cz), p0 + Vector3(w, 0, 0), p1 + Vector3(w, 0, 0), dress.darkened(0.08))
	# windows and the entrance arch
	for x in range(1, w - 1, 2):
		if absi(x - door_x) > 1:
			_window(st, wst, x + 0.2, 0.45, d, 0.6, 0.8, dress)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.6, 0, d - 0.1), Vector3(2.2, 2.5, 0.25), dress)
		Meshes.box(st, Vector3(door_x - 0.4, 2.5, d - 0.1), Vector3(1.8, 0.4, 0.25), dress.darkened(0.08))
		Meshes.box(st, Vector3(door_x - 0.5, 1.3, d + 0.15), Vector3(2.0, 0.08, 0.6), Color("2f5a4a"))
		_door(st, door_x, d + 0.15, dress, 1.1)

## The National Waterfront Museum: a red-brick 1901 dock warehouse joined to a long modern hall of slate and glass
## under a saw-tooth roof.
static func _waterfront_museum(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var brick := Color("9a4434")
	var slate := Color("4a5058")
	var frame := Color("3a4048")
	var ww := mini(5, w - 4)
	# the warehouse
	var wh := 3.2
	Meshes.box(st, Vector3(0, 0, 0.2), Vector3(ww, wh, d - 0.2), brick)
	_roof_at(st, -0.1, ww + 0.1, 0.1, d + 0.1, wh, 0.9, SLATE, brick)
	for s in 2:
		Meshes.box(st, Vector3(0, 1.4 + s * 1.4, d - 0.05), Vector3(ww, 0.08, 0.06), LIMESTONE)
		for x in ww:
			_window(st, wst, x + 0.3, 0.4 + s * 1.45, d, 0.4, 0.8, LIMESTONE)
	# the modern hall: slate walls, a glass front, saw-tooth glazing on the roof
	var mh := 2.2
	Meshes.box(st, Vector3(ww, 0, 0.4), Vector3(w - ww, mh, d - 0.4), slate, slate.lightened(0.1))
	for x in range(ww, w):
		if x == door_x:
			continue
		Meshes.box(wst, Vector3(x + 0.08, 0.2, d - 0.02), Vector3(0.84, mh - 0.4, 0.04), window_colour(_wr))
		Meshes.box(st, Vector3(x, 0.15, d - 0.04), Vector3(0.08, mh - 0.3, 0.06), frame)
	for i in range(0, int(d - 0.4)):
		var z0 := 0.4 + i
		Meshes._quad(st, Vector3(ww, mh + 0.6, z0 + 0.8), Vector3(w, mh + 0.6, z0 + 0.8), Vector3(w, mh, z0), Vector3(ww, mh, z0), slate.lightened(0.15))
		Meshes._quad(st, Vector3(ww, mh, z0 + 1.0), Vector3(w, mh, z0 + 1.0), Vector3(w, mh + 0.6, z0 + 0.8), Vector3(ww, mh + 0.6, z0 + 0.8), Color("9ec4d0"))
	Meshes.box(st, Vector3(ww, mh - 0.1, d - 0.05), Vector3(w - ww, 0.15, 0.1), frame)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.3, 1.25, d), Vector3(1.6, 0.08, 0.7), frame)
		_door(st, door_x, d, slate, 1.0)

## Mumbles Pier: a deck on iron legs out over the sea, railings both sides, and the lifeboat house with its slipway
## at the far (south) end. No door: it stands for the view.
static func _pier(st: SurfaceTool, w: int, d: int) -> void:
	var iron := Color("3c4a52")
	var deck := Color("8a6a4a")
	var rail := Color("e8e4dc")
	var dy := 0.55
	var len_ := d - 2.6
	Meshes.box(st, Vector3(0.3, dy, 0), Vector3(w - 0.6, 0.12, len_), deck, deck.lightened(0.1))
	for z in range(0, int(len_) + 1):
		var zz := minf(float(z), len_ - 0.12)
		for x in [0.4, w - 0.55]:
			Meshes.box(st, Vector3(x, -1.2, zz), Vector3(0.14, dy + 1.2, 0.14), iron)
		Meshes.box(st, Vector3(0.4, -0.3, zz), Vector3(w - 0.8, 0.08, 0.08), iron.darkened(0.1))
	for x in [0.3, w - 0.36]:
		Meshes.box(st, Vector3(x, dy + 0.12, 0), Vector3(0.06, 0.5, len_), rail)
	# the lifeboat house on a wider platform
	var hz := len_
	Meshes.box(st, Vector3(-0.2, dy, hz), Vector3(w + 0.4, 0.14, 2.6), deck.darkened(0.1))
	for c in [Vector2(-0.1, hz), Vector2(w - 0.05, hz), Vector2(-0.1, hz + 2.45), Vector2(w - 0.05, hz + 2.45)]:
		Meshes.box(st, Vector3(c.x, -1.2, c.y), Vector3(0.16, dy + 1.2, 0.16), iron)
	Meshes.box(st, Vector3(0.0, dy + 0.14, hz + 0.2), Vector3(w, 1.5, 2.0), Color("f0ece4"))
	_roof_at(st, -0.1, w + 0.1, hz + 0.1, hz + 2.3, dy + 1.64, 0.6, Color("c03a2a"), Color("f0ece4"))
	Meshes.box(st, Vector3(w * 0.5 - 0.5, dy + 0.14, hz + 2.18), Vector3(1.0, 1.1, 0.06), Color("2a3442"))
	# the slipway, down into the sea
	Meshes._quad(st, Vector3(w * 0.5 - 0.5, dy, hz + 2.6), Vector3(w * 0.5 + 0.5, dy, hz + 2.6),
		Vector3(w * 0.5 + 0.5, -0.4, hz + 4.2), Vector3(w * 0.5 - 0.5, -0.4, hz + 4.2), Color("6a6a66"))

## A cave in the limestone cliff: a pale, knobbly outcrop with a black mouth on the door column.
static func _cave_mouth(st: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var lime := Color("b4ae9e")
	# a heap of weathered limestone boulders, banded grey, piled round the black mouth
	Meshes.blob(st, Vector3(w * 0.5, 0.6, d * 0.45), Vector3(w * 0.55, 1.6, d * 0.5), lime.darkened(0.1), rng, 0.3)
	for i in 9:
		var c := Vector3(rng.randf_range(0.3, w - 0.3), rng.randf_range(0.6, 2.4), rng.randf_range(0.4, d - 0.6))
		Meshes.blob(st, c, Vector3(rng.randf_range(0.6, 1.1), rng.randf_range(0.5, 0.9), rng.randf_range(0.5, 0.9)), lime.lightened(rng.randf_range(-0.1, 0.08)), rng, 0.3)
	for x in [0.35, w - 0.35]:
		Meshes.blob(st, Vector3(x, 0.7, d - 0.45), Vector3(0.6, 0.9, 0.5), lime.darkened(0.04), rng, 0.3)
	Meshes.blob(st, Vector3(w * 0.5, 1.7, d - 0.5), Vector3(1.1, 0.5, 0.45), lime.lightened(0.04), rng, 0.25)
	for i in 4:  # ivy and turf hanging over the top
		Meshes.blob(st, Vector3(rng.randf_range(0.4, w - 0.4), 2.6, rng.randf_range(0.6, d - 0.8)), Vector3(0.5, 0.25, 0.5), Color("6a8a4a"), rng, 0.3)
	if door_x >= 0:
		var black := Color("0c0a0a")
		Meshes.box(st, Vector3(door_x + 0.1, 0, d - 0.12), Vector3(0.8, 1.1, 0.06), black)
		Meshes.box(st, Vector3(door_x + 0.25, 1.1, d - 0.12), Vector3(0.5, 0.25, 0.06), black)
		Meshes.box(st, Vector3(door_x - 0.05, 1.25, d - 0.1), Vector3(1.1, 0.25, 0.25), lime.lightened(0.04))

## Three Cliffs Bay: three steep limestone pinnacles in a row on the sand, the middle one tallest, the westmost
## pierced by a sea arch, with a skirt of fallen blocks.
static func _three_cliffs(st: SurfaceTool, w: int, d: int, rng: RandomNumberGenerator) -> void:
	var lime := Color("a9a393")
	var hs := [2.6, 3.3, 2.8]
	for i in 3:
		var cx := (i + 0.5) * w / 3.0
		var cz := d * 0.5
		var h: float = hs[i]
		var hw := w / 6.0 + 0.15
		var a := Vector3(cx - hw, 0, cz + d * 0.45)
		var b := Vector3(cx + hw, 0, cz + d * 0.45)
		var c := Vector3(cx + hw * 0.8, 0, cz - d * 0.45)
		var e := Vector3(cx - hw * 0.8, 0, cz - d * 0.45)
		var top := Vector3(cx + rng.randf_range(-0.15, 0.15), h, cz + 0.1)
		var col := lime.lightened(rng.randf_range(-0.05, 0.06))
		Meshes._tri(st, b, a, top, col)
		Meshes._tri(st, c, b, top, col.darkened(0.1))
		Meshes._tri(st, e, c, top, col.darkened(0.18))
		Meshes._tri(st, a, e, top, col.darkened(0.06))
		# bedding lines: the limestone is tilted in layers
		for k in 3:
			var y := 0.5 + k * 0.6
			var f := 1.0 - y / h
			if f > 0.15:
				Meshes.box(st, Vector3(cx - hw * f, y, cz + d * 0.45 * f - 0.02), Vector3(hw * 2 * f, 0.05, 0.04), col.darkened(0.25))
	# the arch through the western pinnacle
	Meshes.box(st, Vector3(w / 6.0 - 0.25, 0, d * 0.95 - 0.03), Vector3(0.5, 0.7, 0.05), Color("1a1816"))
	for i in 5:
		Meshes.blob(st, Vector3(rng.randf_range(0.2, w - 0.2), 0.15, rng.randf_range(d * 0.7, d)), Vector3(0.25, 0.2, 0.25), lime.darkened(0.08), rng, 0.3)
# --- Devon -----------------------------------------------------------------------

const BEER_STONE := Color("d3c9ad")   # the creamy limestone Exeter Cathedral is built of
const HEAVITREE := Color("94483a")    # Exeter's dark red breccia and sandstone, in the city wall
const COB := Color("eadfc4")          # limewashed cob, the Devon mud-and-straw wall
const THATCH := Color("a8884e")

## Smeaton's Tower: the 1759 Eddystone lighthouse, taken down and rebuilt on Plymouth Hoe in 1882. A curved granite
## tower painted in red and white bands (each band tapers, so the stack curves in), a gallery, a glazed lantern
## and a red cupola. It stands in the middle of its plot on a granite stump, with a little porch to the door.
static func _smeaton_tower(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var red := Color("c23a2e")
	var white := Color("f1ece0")
	var granite := Color("a9a59a")
	var cx := w * 0.5
	var cz := d * 0.5 - 0.15
	Meshes.cylinder(st, Vector3(cx, 0, cz), minf(w, d) * 0.5, 0.35, 14, granite)
	var r := minf(w, d) * 0.42
	var y := 0.35
	for i in 7:
		var h := 0.72
		Meshes.cylinder(st, Vector3(cx, y, cz), r, h, 14, red if i % 2 == 0 else white)
		r *= 0.88
		y += h
	# the gallery: a dark ledge and a railing ring, then the lantern (lit at night) and its cupola
	Meshes.cylinder(st, Vector3(cx, y, cz), r * 1.45, 0.1, 14, Color("2b2b2e"))
	for i in 10:
		var a := TAU * i / 10.0
		Meshes.box(st, Vector3(cx + cos(a) * r * 1.35 - 0.02, y + 0.1, cz + sin(a) * r * 1.35 - 0.02), Vector3(0.04, 0.3, 0.04), Color("2b2b2e"))
	Meshes.cylinder(st, Vector3(cx, y + 0.1, cz), r * 0.95, 0.12, 14, Color("2b2b2e"))
	Meshes.cylinder(wst, Vector3(cx, y + 0.22, cz), r * 0.85, 0.55, 10, Color(1.0, 0.95, 0.75, 1.0))
	Meshes.cylinder(st, Vector3(cx, y + 0.77, cz), r * 0.95, 0.08, 10, red.darkened(0.2))
	Meshes.cone(st, Vector3(cx, y + 0.85, cz), r * 0.85, 0.5, 10, red, Meshes._rng(1759))
	Meshes.box(st, Vector3(cx - 0.03, y + 1.3, cz - 0.03), Vector3(0.06, 0.22, 0.06), Color("c9a441"))
	# small windows up the south face
	var r0 := minf(w, d) * 0.42
	for k in 3:
		var band := 1 + k * 2
		_window(st, wst, cx - 0.12, 0.35 + band * 0.72 + 0.15, cz + r0 * pow(0.88, band) * 0.93 + 0.04, 0.24, 0.32, white)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.1, 0, cz), Vector3(0.8, 1.25, d - cz), granite.lightened(0.05))
		_door(st, door_x, d, granite)

## Exeter Cathedral: a long Gothic nave in pale Beer stone under a grey lead roof, with flying buttresses and tall
## traceried windows, and its two great square Norman towers standing out of the transepts, one in front of the
## nave and one behind, each with corner turrets. The west front's image screen of carved figures is at the left end.
static func _exeter_cathedral(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := BEER_STONE
	var lead := Color("6d7278")
	var nave_h := 2.7
	var z0 := 1.0
	var z1 := d - 1.0
	Meshes.box(st, Vector3(0.6, 0, z0), Vector3(w - 0.9, nave_h, z1 - z0), stone)
	_roof_at(st, 0.6, w - 0.3, z0, z1, nave_h, 1.0, lead, stone)
	# aisles: lower lean-tos either side of the nave
	Meshes.box(st, Vector3(0.6, 0, z1), Vector3(w - 0.9, 1.5, 0.75), stone.darkened(0.04))
	Meshes.box(st, Vector3(0.6, 0, z0 - 0.75), Vector3(w - 0.9, 1.5, 0.75), stone.darkened(0.06))
	# the west front (left end): a gable with the image screen of saints and kings across its foot
	Meshes.box(st, Vector3(0.2, 0, z0 - 0.75), Vector3(0.5, nave_h + 0.4, z1 - z0 + 1.5), stone.lightened(0.04))
	for row in 2:
		for k in 7:
			Meshes.box(st, Vector3(0.12, 0.35 + row * 0.5, z0 - 0.6 + k * (z1 - z0 + 1.2) / 7.0), Vector3(0.1, 0.3, 0.14), stone.darkened(0.25))
	# flying buttresses and tall pointed windows along the south side
	var tx := int(w * 0.55)
	for x in range(1, w - 1):
		if absi(x - tx) <= 1 or x == door_x:
			continue
		Meshes.box(st, Vector3(x + 0.85, 0, z1 + 0.6), Vector3(0.18, 1.9, 0.3), stone.darkened(0.08))
		Meshes.box(st, Vector3(x + 0.85, 1.9, z1 + 0.1), Vector3(0.18, 0.15, 0.7), stone.darkened(0.08))
		_window(st, wst, x + 0.3, 1.65, z1 + 0.02, 0.4, 0.95, stone.lightened(0.15))
		_window(st, wst, x + 0.32, 0.35, z1 + 0.77, 0.36, 0.8, stone.lightened(0.15))
	# the twin Norman towers: square, banded with blind arcading, corner turrets with little lead caps
	for front in [false, true]:
		var tw := 2.2
		var th := 5.0
		var t0 := Vector3(tx - 0.6, 0, z1 - 0.2 if front else 0.0)
		var depth := (d - t0.z) if front else z0 + 0.4
		Meshes.box(st, t0, Vector3(tw, th, depth), stone.darkened(0.02))
		for b in 3:
			var by := 1.6 + b * 1.05
			Meshes.box(st, Vector3(t0.x - 0.03, by, t0.z - 0.03), Vector3(tw + 0.06, 0.08, depth + 0.06), stone.darkened(0.18))
			for k in 4:
				Meshes.box(st, Vector3(t0.x + 0.22 + k * 0.48, by + 0.15, t0.z + depth + 0.01), Vector3(0.22, 0.6, 0.03), stone.darkened(0.3))
		_merlons(st, t0.x, t0.x + tw, t0.z + depth - 0.25, th, stone, true)
		for c in [Vector2(t0.x, t0.z), Vector2(t0.x + tw - 0.35, t0.z), Vector2(t0.x, t0.z + depth - 0.35), Vector2(t0.x + tw - 0.35, t0.z + depth - 0.35)]:
			Meshes.box(st, Vector3(c.x, th, c.y), Vector3(0.35, 0.55, 0.35), stone.lightened(0.05))
			Meshes.cone(st, Vector3(c.x + 0.175, th + 0.55, c.y + 0.175), 0.24, 0.45, 4, lead, Meshes._rng(1133))
		_window(st, wst, t0.x + tw * 0.5 - 0.22, 3.9, t0.z + depth, 0.44, 0.55, stone.lightened(0.15))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.05, 0, z1 + 0.6), Vector3(0.9, 1.35, d - z1 - 0.6), stone.lightened(0.06))
		_door(st, door_x, d, stone, 1.0)

## A run of Exeter's city wall: the Romans built it, and Saxons, Normans and everyone since have patched it; most of
## it still stands. Dark red stone, a broader foot, crenellations along the top. No door.
static func _city_wall(st: SurfaceTool, w: int, d: int, rng: RandomNumberGenerator) -> void:
	var h := 1.7
	var along_x := w >= d
	var length := w if along_x else d
	for i in length:
		var c := HEAVITREE.lightened(rng.randf_range(-0.06, 0.06))
		if along_x:
			Meshes.box(st, Vector3(i, 0, d * 0.5 - 0.42), Vector3(1.0, 0.5, 0.84), c.darkened(0.1))
			Meshes.box(st, Vector3(i, 0.5, d * 0.5 - 0.34), Vector3(1.0, h - 0.5, 0.68), c)
			Meshes.box(st, Vector3(i + 0.1, h, d * 0.5 - 0.34), Vector3(0.38, 0.32, 0.68), c.lightened(0.05))
			Meshes.box(st, Vector3(i + 0.62, h, d * 0.5 - 0.34), Vector3(0.28, 0.2, 0.68), c.lightened(0.05))
		else:
			Meshes.box(st, Vector3(w * 0.5 - 0.42, 0, i), Vector3(0.84, 0.5, 1.0), c.darkened(0.1))
			Meshes.box(st, Vector3(w * 0.5 - 0.34, 0.5, i), Vector3(0.68, h - 0.5, 1.0), c)
			Meshes.box(st, Vector3(w * 0.5 - 0.34, h, i + 0.1), Vector3(0.68, 0.32, 0.38), c.lightened(0.05))
			Meshes.box(st, Vector3(w * 0.5 - 0.34, h, i + 0.62), Vector3(0.68, 0.2, 0.28), c.lightened(0.05))

## A Devon cob cottage: thick limewashed walls of mud and straw on a stone plinth, small deep-set windows and a
## heavy thatch with deep eaves, an eyebrow over the upstairs window and a block-cut ridge. A big stack at one end.
static func _cob_thatch(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var wall := COB.darkened(rng.randf_range(0.0, 0.06))
	var h := 1.55
	Meshes.box(st, Vector3(0.1, 0, 0.1), Vector3(w - 0.2, h, d - 0.2), wall)
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, 0.25, d - 0.1), Color("6d6a62"))  # cob wants "a good hat and good boots"
	for c in [0.02, w - 0.2]:
		Meshes.box(st, Vector3(c, 0.25, d - 0.22), Vector3(0.18, h - 0.3, 0.14), wall.lightened(0.04))
	# thatch: deep eaves, steep, then a thicker block-cut ridge
	var eave := 0.38
	var rise := minf(1.7, d * 0.62)
	var a := Vector3(-eave, h - 0.15, -eave)
	var b := Vector3(w + eave, h - 0.15, -eave)
	var c2 := Vector3(w + eave, h - 0.15, d + eave)
	var dd := Vector3(-eave, h - 0.15, d + eave)
	var r0 := Vector3(-eave * 0.4, h + rise, d * 0.5)
	var r1 := Vector3(w + eave * 0.4, h + rise, d * 0.5)
	Meshes._quad(st, r0, r1, c2, dd, THATCH)
	Meshes._quad(st, r1, r0, a, b, THATCH.darkened(0.15))
	Meshes._tri(st, r0, dd, a, THATCH.darkened(0.08))
	Meshes._tri(st, r1, b, c2, THATCH.darkened(0.1))
	Meshes._quad(st, dd, c2, b, a, THATCH.darkened(0.45))
	Meshes.box(st, Vector3(-eave * 0.3, h + rise - 0.12, d * 0.5 - 0.22), Vector3(w + eave * 0.6, 0.2, 0.44), THATCH.darkened(0.2))
	var stack_x := w - 0.75 if rng.randf() < 0.5 else 0.3
	Meshes.box(st, Vector3(stack_x, h, d * 0.5 - 0.25), Vector3(0.45, rise + 0.5, 0.5), Color("8c8478"))
	_chimneys.append(Vector3(stack_x + 0.22, h + rise + 0.55, d * 0.5))
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.3, 0.55, d - 0.06, 0.4, 0.45, Color("f4efe2"))
	# an eyebrow dormer in the thatch over the middle
	var ex := w * 0.5 - 0.3
	var ez := d + eave - (h + 0.4 - (h - 0.15)) * (d * 0.5 + eave) / (rise + 0.15) - 0.05
	Meshes.box(st, Vector3(ex - 0.1, h + 0.05, ez - 0.45), Vector3(0.8, 0.38, 0.45), THATCH.lightened(0.05))
	_window(st, wst, ex + 0.08, h + 0.1, ez + 0.02, 0.44, 0.24, Color("f4efe2"))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.1, 1.08, d - 0.1), Vector3(0.8, 0.06, 0.3), THATCH.darkened(0.1))  # a little porch hood
		_door(st, door_x, d, wall)

## A football ground seen from the street: a big grey stand with green cladding, a cantilever roof, the club's name
## board and floodlight pylons at the back corners. (Home Park, Plymouth Argyle: the Pilgrims, in green.)
static func _football_ground(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var grey := Color("9aa0a3")
	var green := Color("1f6a3e")
	var h := 2.3
	Meshes.box(st, Vector3(0.05, 0, 0.3), Vector3(w - 0.1, h, d - 0.35), grey)
	for k in 3:
		Meshes.box(st, Vector3(0.0, 0.5 + k * 0.6, d - 0.06), Vector3(w, 0.32, 0.04), green)
	Meshes.box(st, Vector3(-0.1, h, 0.1), Vector3(w + 0.2, 0.12, d), Color("d9dcdc"))
	Meshes.box(st, Vector3(w * 0.5 - 1.2, h - 0.5, d - 0.03), Vector3(2.4, 0.4, 0.04), Color("f2f2ee"))
	for x in w:
		if x != door_x:
			Meshes.box(wst, Vector3(x + 0.2, 0.22, d - 0.02), Vector3(0.6, 0.18, 0.04), window_colour(_wr))
	for c in [Vector2(0.2, 0.2), Vector2(w - 0.2, 0.2)]:
		Meshes.box(st, Vector3(c.x - 0.06, 0, c.y - 0.06), Vector3(0.12, h + 2.6, 0.12), Color("5a6066"))
		Meshes.box(st, Vector3(c.x - 0.35, h + 2.6, c.y - 0.1), Vector3(0.7, 0.4, 0.2), Color("3a3f44"))
		Meshes.box(wst, Vector3(c.x - 0.3, h + 2.65, c.y + 0.1), Vector3(0.6, 0.3, 0.02), Color(1, 1, 1, 1))
	if door_x >= 0:
		_door(st, door_x, d, grey)

## The National Marine Aquarium: a low white building on the harbour edge with a sweep of blue glass across the
## front and a wave-shaped roof.
static func _aquarium(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var white := Color("eef0ee")
	var blue := Color("3a7fa8")
	var h := 1.9
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), white)
	var n := w * 2
	for i in n:
		var x0 := float(i) * w / n
		var y0 := h + 0.25 + sin(float(i) / n * TAU) * 0.25
		Meshes.box(st, Vector3(x0, h, 0.0), Vector3(float(w) / n + 0.01, y0 - h + 0.1, d), blue.darkened(0.1) if i % 2 == 0 else blue)
	for x in w:
		if x != door_x:
			Meshes.box(wst, Vector3(x + 0.08, 0.3, d - 0.07), Vector3(0.84, 1.3, 0.04), Color(0.55, 0.8, 1.0, 1.0))
			Meshes.box(st, Vector3(x, 0.25, d - 0.08), Vector3(0.08, 1.4, 0.05), Color("2a3a4a"))
	if door_x >= 0:
		_door(st, door_x, d, white, 1.1)

## The Mayflower Steps memorial on the Barbican quay: a little granite portico of two Doric columns under a plain
## entablature, on a stepped plinth leading down towards the water. No door.
static func _mayflower_steps(st: SurfaceTool, w: int, d: int) -> void:
	var granite := Color("b9b4a8")
	for k in 3:
		Meshes.box(st, Vector3(0.05 + k * 0.08, k * 0.12, 0.05 + k * 0.06), Vector3(w - 0.1 - k * 0.16, 0.12, d - 0.1 - k * 0.12), granite.darkened(0.06 * (2 - k)))
	var top := 0.36
	for cx in [0.45, w - 0.45]:
		Meshes.box(st, Vector3(cx - 0.17, top, d * 0.5 - 0.17), Vector3(0.34, 0.08, 0.34), granite.lightened(0.04))
		Meshes.cylinder(st, Vector3(cx, top + 0.08, d * 0.5), 0.13, 1.25, 10, granite.lightened(0.08))
		Meshes.box(st, Vector3(cx - 0.17, top + 1.3, d * 0.5 - 0.17), Vector3(0.34, 0.08, 0.34), granite.lightened(0.04))
	Meshes.box(st, Vector3(0.12, top + 1.38, d * 0.5 - 0.2), Vector3(w - 0.24, 0.26, 0.4), granite.lightened(0.06))
	Meshes.box(st, Vector3(0.3, top + 1.43, d * 0.5 + 0.205), Vector3(w - 0.6, 0.14, 0.01), Color("3b3a36"))  # the inscription
	Meshes._tri(st, Vector3(0.12, top + 1.64, d * 0.5 + 0.2), Vector3(w * 0.5, top + 1.95, d * 0.5 + 0.2),
		Vector3(w - 0.12, top + 1.64, d * 0.5 + 0.2), granite.lightened(0.1))  # a low pediment
# --- Fermanagh and the Erne (3.0) --------------------------------------------------

## Irish painted render: each bay of the terrace its own colour, as on an Ulster or Fermanagh main street.
const ERNE_PAINTS := [Color("d9a441"), Color("8fb3c9"), Color("d68c86"), Color("9fb48a"), Color("e8dcb8"), Color("c0694a"),
	Color("4f6f8f"), Color("b0a0c8")]
const PORTLAND_STONE := Color("e2ddcf")

## An Irish main-street terrace: two storeys of painted render, a bay of colour every two tiles, dark painted
## shopfront fascias on the ground floor, sash windows above, slate roof and a chimney on each party wall.
static func _erne_terrace(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var hgt := 2.45
	var bw := 2 if w >= 4 else 1
	var i0 := rng.randi() % ERNE_PAINTS.size()
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), Color("5a5650"))
	var bx := 0
	var k := 0
	var first: Color = ERNE_PAINTS[i0]
	while bx < w:
		var ww := mini(bw, w - bx)
		var col: Color = ERNE_PAINTS[(i0 + k * 3) % ERNE_PAINTS.size()]
		Meshes.box(st, Vector3(bx + 0.02, 0.16, 0.05), Vector3(ww - 0.04, hgt - 0.16, d - 0.1), col)
		# the shopfront: a dark painted fascia, pilasters and a stall riser
		var paint := col.darkened(0.55)
		Meshes.box(st, Vector3(bx + 0.06, 1.02, d - 0.09), Vector3(ww - 0.12, 0.2, 0.07), paint)
		Meshes.box(st, Vector3(bx + 0.06, 0.16, d - 0.08), Vector3(0.08, 0.86, 0.06), paint)
		Meshes.box(st, Vector3(bx + ww - 0.14, 0.16, d - 0.08), Vector3(0.08, 0.86, 0.06), paint)
		if bx > 0:
			Meshes.box(st, Vector3(bx - 0.2, hgt + 0.25, d * 0.5 - 0.2), Vector3(0.4, 0.85, 0.4), col.darkened(0.25))
			Meshes.box(st, Vector3(bx - 0.12, hgt + 1.1, d * 0.5 - 0.1), Vector3(0.1, 0.14, 0.1), Color("a0553c"))
			Meshes.box(st, Vector3(bx + 0.03, hgt + 1.1, d * 0.5 - 0.1), Vector3(0.1, 0.14, 0.1), Color("a0553c"))
			_chimneys.append(Vector3(bx, hgt + 1.24, d * 0.5 - 0.05))
		bx += ww
		k += 1
	_roof(st, w, d, hgt, SLATE, first)
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.2, 0.32, d, 0.6, 0.6, Color("f1ede2"))
		_window(st, wst, x + 0.3, 1.45, d, 0.4, 0.66, Color("f4f1e8"))
	_door(st, door_x, d, Color("f1ede2"))

## Enniskillen Castle's Watergate: two round corbelled turrets with conical caps, joined by a crenellated
## curtain wall with a dark arch, standing at the water's edge.
static func _watergate(st: SurfaceTool, wst: SurfaceTool, w: int, d: int) -> void:
	var stone := Color("a59c88")
	var rng := Meshes._rng(77)
	var zf := d * 0.75
	Meshes.box(st, Vector3(0.6, 0, d * 0.3), Vector3(w - 1.2, 2.1, zf - d * 0.3), stone.darkened(0.04))
	_merlons(st, 0.9, w - 0.9, d * 0.3, 2.1, stone, true)
	Meshes.box(st, Vector3(w * 0.5 - 0.42, 0, zf - 0.02), Vector3(0.84, 1.25, 0.06), Color("1e1b18"))
	Meshes.box(st, Vector3(w * 0.5 - 0.55, 1.25, zf - 0.04), Vector3(1.1, 0.16, 0.08), stone.lightened(0.12))
	for cx in [0.8, w - 0.8]:
		var c := Vector3(cx, 0, d * 0.55)
		Meshes.cylinder(st, c, 0.78, 3.0, 12, stone)
		Meshes.cylinder(st, c + Vector3(0, 2.75, 0), 0.86, 0.45, 12, stone.lightened(0.06))  # the corbelled top
		Meshes.cone(st, c + Vector3(0, 3.18, 0), 0.9, 1.35, 12, SLATE, rng)
		for y in [0.9, 1.9]:
			Meshes.box(st, Vector3(cx - 0.06, y, c.z + 0.66), Vector3(0.12, 0.42, 0.06), Color("1e1b18"))
		Meshes.box(wst, Vector3(cx - 0.12, 2.95, c.z + 0.74), Vector3(0.24, 0.26, 0.04), window_colour(_wr))

## Castle Coole: a pale Portland-stone neoclassical house, a main block with a pedimented portico of four
## columns, a balustraded roofline, and low colonnaded wings either side.
static func _palladian(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := PORTLAND_STONE
	var zf := d - 0.8
	var x0 := 2.4
	var x1 := w - 2.4
	Meshes.box(st, Vector3(0, 0, 0.3), Vector3(w, 0.15, d - 0.3), stone.darkened(0.25))
	Meshes.box(st, Vector3(x0, 0.15, 0.5), Vector3(x1 - x0, 2.65, zf - 0.5), stone)
	Meshes.box(st, Vector3(x0 - 0.08, 2.8, 0.42), Vector3(x1 - x0 + 0.16, 0.14, zf - 0.34), stone.darkened(0.06))
	Meshes.box(st, Vector3(x0, 2.94, zf - 0.14), Vector3(x1 - x0, 0.3, 0.12), stone.lightened(0.04))
	Meshes.box(st, Vector3(x0, 2.94, 0.5), Vector3(x1 - x0, 0.3, 0.12), stone.lightened(0.04))
	_roof_at(st, x0 + 0.15, x1 - 0.15, 0.7, zf - 0.25, 2.94, 0.45, SLATE, stone)
	# windows: two rows across the main block
	for x in range(int(ceil(x0)), int(floor(x1))):
		_window(st, wst, x + 0.3, 1.75, zf, 0.4, 0.62, stone.lightened(0.1))
		if x != door_x and absf(x + 0.5 - w * 0.5) > 1.6:
			_window(st, wst, x + 0.28, 0.5, zf, 0.44, 0.85, stone.lightened(0.1))
	# the portico: steps, four columns, entablature and pediment
	var mx := w * 0.5
	Meshes.box(st, Vector3(mx - 1.7, 0.15, zf), Vector3(3.4, 0.14, 0.72), stone.darkened(0.08))
	for cx in [mx - 1.25, mx - 0.42, mx + 0.42, mx + 1.25]:
		Meshes.cylinder(st, Vector3(cx, 0.29, d - 0.3), 0.15, 2.2, 8, stone.lightened(0.05))
	Meshes.box(st, Vector3(mx - 1.55, 2.45, zf - 0.02), Vector3(3.1, 0.3, 0.75), stone)
	var a := Vector3(mx - 1.6, 2.75, d - 0.08)
	var b := Vector3(mx + 1.6, 2.75, d - 0.08)
	var t := Vector3(mx, 3.35, d - 0.08)
	Meshes._tri(st, a, t, b, stone.lightened(0.04))
	var back := Vector3(0, 0, -0.75)
	Meshes._quad(st, a, a + back, t + back, t, SLATE)
	Meshes._quad(st, t, t + back, b + back, b, SLATE.darkened(0.12))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.2, 0.15, zf - 0.03), Vector3(0.6, 1.2, 0.06), Color("3b2a22"))
	# colonnaded wings and their end pavilions
	for side in [0, 1]:
		var wx := 0.15 if side == 0 else x1 + 0.05
		Meshes.box(st, Vector3(wx, 0.15, 1.3), Vector3(2.2, 1.45, d - 2.6), stone.darkened(0.03))
		Meshes.box(st, Vector3(wx - 0.05, 1.6, 1.2), Vector3(2.3, 0.14, d - 2.0), stone.darkened(0.08))
		for i in 4:
			Meshes.cylinder(st, Vector3(wx + 0.25 + i * 0.57, 0.15, d - 0.95), 0.08, 1.45, 6, stone.lightened(0.05))
		Meshes.box(st, Vector3(wx + (0.0 if side == 0 else 1.5), 0.15, 0.9), Vector3(0.7, 1.9, d - 1.8), stone)
		_window(st, wst, wx + 0.9, 0.55, d - 1.3, 0.4, 0.7, stone.lightened(0.1))

## Cole's Monument: a tall fluted Doric column on a plinth, with the general on top.
static func _monument_column(st: SurfaceTool, w: int, d: int) -> void:
	var stone := Color("b8b0a0")
	var rng := Meshes._rng(1857)
	var c := Vector3(w * 0.5, 0, d * 0.5)
	Meshes.box(st, Vector3(c.x - 0.75, 0, c.z - 0.75), Vector3(1.5, 0.3, 1.5), stone.darkened(0.15))
	Meshes.box(st, Vector3(c.x - 0.6, 0.3, c.z - 0.6), Vector3(1.2, 0.9, 1.2), stone)
	Meshes.box(st, Vector3(c.x - 0.12, 0.3, c.z + 0.6), Vector3(0.24, 0.55, 0.03), Color("3b2a22"))  # the stair door
	Meshes.cylinder(st, c + Vector3(0, 1.2, 0), 0.42, 4.6, 12, stone.lightened(0.04))
	Meshes.box(st, Vector3(c.x - 0.5, 5.75, c.z - 0.5), Vector3(1.0, 0.22, 1.0), stone)
	Meshes.box(st, Vector3(c.x - 0.25, 5.97, c.z - 0.25), Vector3(0.5, 0.2, 0.5), stone.darkened(0.08))
	Meshes.box(st, Vector3(c.x - 0.13, 6.17, c.z - 0.1), Vector3(0.26, 0.6, 0.2), stone.darkened(0.12))
	Meshes.blob(st, c + Vector3(0, 6.9, 0), Vector3(0.12, 0.14, 0.12), stone.darkened(0.12), rng, 0.03)

## The way into the Marble Arch Caves: a grey limestone outcrop with turf on top and a dark mouth at the door.
static func _marble_arch_cave(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var lime := Color("a8a294")
	var rng := Meshes._rng(1895)
	Meshes.blob(st, Vector3(w * 0.5, 0.7, d * 0.4), Vector3(w * 0.5, 1.3, d * 0.42), lime, rng, 0.16)
	Meshes.blob(st, Vector3(w * 0.25, 0.5, d * 0.5), Vector3(w * 0.22, 0.9, d * 0.4), lime.darkened(0.06), rng, 0.2)
	Meshes.blob(st, Vector3(w * 0.78, 0.45, d * 0.5), Vector3(w * 0.2, 0.8, d * 0.38), lime.darkened(0.1), rng, 0.2)
	Meshes.blob(st, Vector3(w * 0.5, 1.85, d * 0.35), Vector3(w * 0.42, 0.35, d * 0.32), Color("5f8a3e"), rng, 0.12)
	var mx := (door_x + 0.5) if door_x >= 0 else w * 0.5
	Meshes.box(st, Vector3(mx - 0.75, 0, d - 0.7), Vector3(0.35, 1.35, 0.6), lime.lightened(0.05))
	Meshes.box(st, Vector3(mx + 0.4, 0, d - 0.7), Vector3(0.35, 1.35, 0.6), lime.lightened(0.02))
	Meshes.box(st, Vector3(mx - 0.8, 1.2, d - 0.75), Vector3(1.6, 0.35, 0.65), lime.lightened(0.08))
	Meshes.box(st, Vector3(mx - 0.4, 0, d - 0.55), Vector3(0.8, 1.2, 0.4), Color("14120f"))
# --- Donegal ------------------------------------------------------------------

## An Irish tower house (Donegal Castle; Glenveagh is the same idea in pale granite): a tall square keep with a
## corbelled parapet, crenellations and two capped corner turrets, and a lower manor wing with Jacobean gables
## and tall chimney stacks. The keep stands at the west end of the plot; `round` adds Glenveagh's round tower.
static func _tower_house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, stone: Color, round := false) -> void:
	var rng := Meshes._rng(4471 + w * 13 + d)
	var kw := clampf(w * 0.45, 2.0, 4.0)
	var kh := 4.4
	var roof := SLATE.darkened(0.1)
	Meshes.box(st, Vector3(0.05, 0, 0.1), Vector3(kw - 0.1, kh, d - 0.15), stone)
	Meshes.box(st, Vector3(0, 0, 0.05), Vector3(kw, 0.3, d - 0.05), stone.darkened(0.25))  # the battered base
	Meshes.box(st, Vector3(-0.08, kh - 0.12, 0.02), Vector3(kw + 0.16, 0.16, d - 0.02), stone.darkened(0.14))  # corbels
	_merlons(st, -0.08, kw + 0.08, d - 0.6, kh + 0.04, stone, true)
	_merlons(st, -0.08, kw + 0.08, 0.02, kh + 0.04, stone, true)
	_merlons(st, 0.6, d - 0.6, -0.08, kh + 0.04, stone, false)
	_merlons(st, 0.6, d - 0.6, kw - 0.52, kh + 0.04, stone, false)
	_roof_at(st, 0.45, kw - 0.45, 0.45, d - 0.45, kh, 0.9, roof, stone)
	Meshes.box(st, Vector3(kw * 0.5 - 0.2, kh, 0.35), Vector3(0.4, 1.3, 0.4), stone.darkened(0.08))
	_chimneys.append(Vector3(kw * 0.5, kh + 1.35, 0.55))
	for cx in [0.15, kw - 0.15]:
		Meshes.cylinder(st, Vector3(cx, kh - 0.7, d - 0.2), 0.3, 1.1, 8, stone.lightened(0.05))
		Meshes.cone(st, Vector3(cx, kh + 0.33, d - 0.2), 0.33, 0.65, 8, roof, rng)
	for y in [1.0, 2.2, 3.35]:
		_window(st, wst, kw * 0.5 - 0.17, y, d, 0.34, 0.5, stone.lightened(0.2))
	if w - kw >= 1.5:
		var wh := 2.3
		Meshes.box(st, Vector3(kw, 0, 0.35), Vector3(w - kw - 0.05, wh, d - 0.4), stone.lightened(0.03))
		Meshes.box(st, Vector3(kw, 0, 0.3), Vector3(w - kw, 0.18, d - 0.3), stone.darkened(0.25))
		_roof_at(st, kw, w - 0.05, 0.35, d - 0.05, wh, 1.05, roof, stone)
		var gx := kw + 0.35
		while gx + 0.85 <= w - 0.2:
			Meshes.box(st, Vector3(gx, wh - 0.05, d - 0.4), Vector3(0.85, 0.55, 0.35), stone.lightened(0.03))
			Meshes._tri(st, Vector3(gx + 0.425, wh + 0.95, d - 0.05), Vector3(gx + 0.85, wh + 0.5, d - 0.05), Vector3(gx, wh + 0.5, d - 0.05), stone.lightened(0.06))
			Meshes._quad(st, Vector3(gx + 0.425, wh + 0.95, d - 0.05), Vector3(gx + 0.425, wh + 0.95, d - 0.6), Vector3(gx + 0.85, wh + 0.5, d - 0.6), Vector3(gx + 0.85, wh + 0.5, d - 0.05), roof)
			Meshes._quad(st, Vector3(gx + 0.425, wh + 0.95, d - 0.6), Vector3(gx + 0.425, wh + 0.95, d - 0.05), Vector3(gx, wh + 0.5, d - 0.05), Vector3(gx, wh + 0.5, d - 0.6), roof.darkened(0.1))
			_window(st, wst, gx + 0.27, wh + 0.05, d, 0.32, 0.38, stone.lightened(0.22))
			gx += 1.35
		Meshes.box(st, Vector3(w - 0.5, wh + 0.2, d * 0.5 - 0.2), Vector3(0.4, 1.5, 0.4), stone.darkened(0.06))
		_chimneys.append(Vector3(w - 0.3, wh + 1.75, d * 0.5))
		for x in range(int(ceil(kw)), w):
			if x == door_x:
				continue
			_window(st, wst, x + 0.22, 0.45, d, 0.56, 0.62, stone.lightened(0.22))
			_window(st, wst, x + 0.3, 1.45, d, 0.4, 0.5, stone.lightened(0.22))
	if round:
		var rc := Vector3(w - 0.75, 0, 0.75)
		Meshes.cylinder(st, rc, 0.7, kh + 0.6, 10, stone.lightened(0.04))
		_merlons(st, w - 1.35, w - 0.15, 0.15, kh + 0.6 - 0.05, stone, true)
		_window(st, wst, rc.x - 0.15, 2.8, rc.z + 0.62, 0.3, 0.45, stone.lightened(0.2))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.12, 1.06, d - 0.1), Vector3(0.76, 0.12, 0.1), stone.lightened(0.18))
		_door(st, door_x, d, stone, 0.9)

## A Donegal thatched cottage: whitewashed, a tarred skirting, one storey, and a golden thatch held down against
## the Atlantic wind by a net of ropes tied to stone pegs under the eaves; a chimney on each gable, a half-door.
static func _thatch_cottage(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var lime := Color("ece8dc")
	var thatch := Color("a98a50")
	var rope := Color("4a3b2a")
	var trim: Color = [Color("b03a2e"), Color("2f5d8a"), Color("2f7a55")][rng.randi() % 3]
	var hgt := 1.2
	var eave := 0.22
	var rise := minf(1.2, d * 0.42)
	Meshes.box(st, Vector3(0.05, 0, 0.1), Vector3(w - 0.1, hgt, d - 0.15), lime)
	Meshes.box(st, Vector3(0.03, 0, d - 0.08), Vector3(w - 0.06, 0.2, 0.05), Color("3d3a36"))  # tarred skirting
	var ry := hgt + rise
	var zr := d * 0.5
	var zf := d + eave
	Meshes._quad(st, Vector3(-eave, ry, zr), Vector3(w + eave, ry, zr), Vector3(w + eave, hgt - 0.05, zf), Vector3(-eave, hgt - 0.05, zf), thatch)
	Meshes._quad(st, Vector3(w + eave, ry, zr), Vector3(-eave, ry, zr), Vector3(-eave, hgt - 0.05, -eave), Vector3(w + eave, hgt - 0.05, -eave), thatch.darkened(0.15))
	Meshes._quad(st, Vector3(-eave, hgt - 0.05, zf), Vector3(w + eave, hgt - 0.05, zf), Vector3(w + eave, hgt - 0.05, -eave), Vector3(-eave, hgt - 0.05, -eave), thatch.darkened(0.45))
	Meshes._tri(st, Vector3(0.05, ry - 0.05, zr), Vector3(0.05, hgt, d - 0.05), Vector3(0.05, hgt, 0.1), lime.darkened(0.06))
	Meshes._tri(st, Vector3(w - 0.05, ry - 0.05, zr), Vector3(w - 0.05, hgt, 0.1), Vector3(w - 0.05, hgt, d - 0.05), lime.darkened(0.1))
	Meshes.box(st, Vector3(-eave, ry - 0.1, zr - 0.16), Vector3(w + eave * 2.0, 0.18, 0.32), thatch.darkened(0.08))  # ridge roll
	Meshes.box(st, Vector3(-eave, hgt - 0.14, zf - 0.12), Vector3(w + eave * 2.0, 0.12, 0.14), thatch.darkened(0.22))  # eave lip
	# the rope net: down the slope every 0.4, and three runs along it
	var lift := Vector3(0, 0.02, 0.012)
	var x := 0.1
	while x < w:
		Meshes._quad(st, Vector3(x, ry, zr) + lift, Vector3(x + 0.035, ry, zr) + lift, Vector3(x + 0.035, hgt - 0.05, zf) + lift, Vector3(x, hgt - 0.05, zf) + lift, rope)
		Meshes.box(st, Vector3(x - 0.02, hgt - 0.34, d - 0.07), Vector3(0.07, 0.08, 0.08), Color("8e887c"))  # stone peg
		x += 0.4
	for t in [0.3, 0.58, 0.84]:
		var y0 := lerpf(ry, hgt - 0.05, t)
		var z0 := lerpf(zr, zf, t)
		var y1 := lerpf(ry, hgt - 0.05, t + 0.03)
		var z1 := lerpf(zr, zf, t + 0.03)
		Meshes._quad(st, Vector3(-eave, y0, z0) + lift, Vector3(w + eave, y0, z0) + lift, Vector3(w + eave, y1, z1) + lift, Vector3(-eave, y1, z1) + lift, rope)
	for cx in [0.12, w - 0.5]:
		Meshes.box(st, Vector3(cx, ry - 0.45, zr - 0.2), Vector3(0.38, 0.85, 0.4), lime.darkened(0.04))
		Meshes.box(st, Vector3(cx - 0.03, ry + 0.38, zr - 0.23), Vector3(0.44, 0.06, 0.46), Color("8e887c"))
		_chimneys.append(Vector3(cx + 0.19, ry + 0.45, zr))
	for i in w:
		if i == door_x:
			continue
		_window(st, wst, i + 0.3, 0.45, d - 0.05, 0.4, 0.46, trim)
	if door_x >= 0:
		_door(st, door_x, d, lime)
		Meshes.box(st, Vector3(door_x + 0.22, 0.16, d - 0.072), Vector3(0.56, 0.44, 0.06), trim)  # the half-door

## An Irish town shopfront: a two-storey house rendered and painted a bright colour, with a dark fascia board and
## cornice over pilasters, big display windows below and sash windows above. Each one picks its own colour.
static func _irish_shopfront(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var cols := [Color("2f5d8a"), Color("b8402f"), Color("e0b53a"), Color("2f7a55"), Color("c25a7c"), Color("6a4c8c"), Color("d9782e"), Color("5aa0a8")]
	var wall: Color = cols[rng.randi() % cols.size()]
	var fascia: Color = [Color("1f2a33"), Color("23402f"), Color("3a1f24")][rng.randi() % 3]
	var hgt := 2.5
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), wall)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), wall.darkened(0.35))
	_roof(st, w, d, hgt, SLATE, wall)
	var cx := rng.randf_range(0.6, maxf(0.7, w - 0.9))
	Meshes.box(st, Vector3(cx, hgt + 0.3, d * 0.5 - 0.2), Vector3(0.35, 0.95, 0.4), wall.darkened(0.25))
	_chimneys.append(Vector3(cx + 0.175, hgt + 1.25, d * 0.5))
	Meshes.box(st, Vector3(0.1, 1.02, d - 0.04), Vector3(w - 0.2, 0.5, 0.08), fascia)
	Meshes.box(st, Vector3(0.04, 1.5, d - 0.07), Vector3(w - 0.08, 0.07, 0.14), fascia.lightened(0.25))
	for px in [0.08, w - 0.24]:
		Meshes.box(st, Vector3(px, 0.0, d - 0.05), Vector3(0.16, 1.04, 0.09), fascia.lightened(0.1))
	for i in w:
		if i != door_x:
			_window(st, wst, i + 0.14, 0.32, d, 0.72, 0.6, fascia)
		_window(st, wst, i + 0.3, 1.78, d, 0.4, 0.52, Color("f0ece0"))
	_door(st, door_x, d, fascia)

## A turf clamp (a rick): sods of peat cut from the bog and stacked to dry, rough and dark, narrowing to the top.
## Nobody goes in: it has no door.
static func _turf_stack(st: SurfaceTool, w: int, d: int, rng: RandomNumberGenerator) -> void:
	var peat := Color("4a3626")
	for layer in 5:
		var ix := 0.1 + layer * 0.17
		var iz := 0.12 + layer * 0.07
		var y := layer * 0.17
		if w - 2.0 * ix < 0.3:
			break
		Meshes.box(st, Vector3(ix, y, iz), Vector3(w - 2.0 * ix, 0.17, d - 2.0 * iz), peat.lightened(rng.randf_range(-0.05, 0.05)))
		var x := ix
		while x < w - ix - 0.12:
			Meshes.box(st, Vector3(x, y + 0.02, d - iz - 0.02), Vector3(0.22, 0.13, 0.05), peat.lightened(rng.randf_range(-0.1, 0.14)))
			x += 0.27

## A slim stone obelisk on a stepped base, the kind a town raises in its square (Donegal's remembers the Four Masters).
static func _obelisk(st: SurfaceTool, w: int, d: int) -> void:
	var stone := Color("aaa69c")
	var c := Vector3(w * 0.5, 0, d * 0.5)
	Meshes.box(st, c + Vector3(-0.48, 0, -0.48), Vector3(0.96, 0.16, 0.96), stone.darkened(0.15))
	Meshes.box(st, c + Vector3(-0.36, 0.16, -0.36), Vector3(0.72, 0.16, 0.72), stone.darkened(0.08))
	Meshes.box(st, c + Vector3(-0.24, 0.32, -0.24), Vector3(0.48, 0.55, 0.48), stone)
	var n := 6
	for i in n:
		var r := lerpf(0.17, 0.1, float(i) / n)
		Meshes.box(st, c + Vector3(-r, 0.87 + i * 0.4, -r), Vector3(r * 2.0, 0.4, r * 2.0), stone.lightened(0.03 * (i % 2)))
	var top := Vector3(c.x, 0.87 + n * 0.4, c.z)
	var s := 0.1
	var pts := [top + Vector3(-s, 0, -s), top + Vector3(s, 0, -s), top + Vector3(s, 0, s), top + Vector3(-s, 0, s)]
	var tip := top + Vector3(0, 0.28, 0)
	for i in 4:
		Meshes._tri(st, pts[i], pts[(i + 1) % 4], tip, stone.lightened(0.1))

## Tory Island's Tau cross: a T-shaped cross of grey stone on a rough plinth, older than anybody can say.
static func _tau_cross(st: SurfaceTool, w: int, d: int) -> void:
	var stone := Color("8f8a7c")
	var c := Vector3(w * 0.5, 0, d * 0.5)
	Meshes.box(st, c + Vector3(-0.32, 0, -0.26), Vector3(0.64, 0.22, 0.52), stone.darkened(0.15))
	Meshes.box(st, c + Vector3(-0.1, 0.22, -0.07), Vector3(0.2, 1.0, 0.14), stone)
	Meshes.box(st, c + Vector3(-0.36, 1.12, -0.07), Vector3(0.72, 0.17, 0.14), stone.lightened(0.05))
	Meshes.box(st, c + Vector3(-0.06, 0.5, 0.06), Vector3(0.09, 0.07, 0.02), Color("b8b24a"))  # lichen
	Meshes.box(st, c + Vector3(0.12, 1.15, 0.06), Vector3(0.1, 0.06, 0.02), Color("c9a640"))
# --- the Shannon and Limerick (Wider Isles) -----------------------------------------------------------------

const CLARE_LIME := Color("f2eee4")     # whitewash
const SHANNON_THATCH := Color("a8844a")
const LIMERICK_BRICK := Color("8e4a38")
const LIMESTONE_GREY := Color("aaa499")  # Limerick's grey limestone

static func _shannon(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, style: String, door_x: int, rng: RandomNumberGenerator, region: String) -> void:
	match style:
		"shannon_tower_house":
			_shannon_tower_house(st, wst, w, d, door_x)
		"king_johns":
			_king_johns(st, wst, w, d, door_x, region)
		"clare_thatch":
			_clare_thatch(st, wst, w, d, door_x, rng)
		"limerick_georgian":
			_georgian(st, wst, w, d, door_x, rng)
		"airport_terminal":
			_airport(st, wst, w, d, door_x)
		"flying_boat":
			_flying_boat(st, w, d)
		"hydro_station":
			_hydro(st, wst, w, d, door_x)
		"thomond_stadium":
			_stadium(st, w, d, door_x)
		"milk_market":
			_milk_market(st, w, d, door_x)

## Bunratty: a tall grey keep with a square tower at each corner, the towers joined high up on the long faces
## by a great arch, and battlements all round.
static func _shannon_tower_house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := LIMESTONE_GREY
	var t := minf(1.5, w * 0.22)
	var keep_h := 4.0 if w >= 6 else 3.2
	var tower_h := keep_h + 1.1
	Meshes.box(st, Vector3(t * 0.5, 0, t * 0.5), Vector3(w - t, keep_h, d - t), stone)
	for c in [Vector2(0, 0), Vector2(w - t, 0), Vector2(0, d - t), Vector2(w - t, d - t)]:
		Meshes.box(st, Vector3(c.x, 0, c.y), Vector3(t, tower_h, t), stone.lightened(0.04))
		_merlons(st, c.x, c.x + t, c.y + t - 0.6, tower_h, stone, true)
	# the arch: a deep recess between the front towers, bridged at the top
	Meshes.box(st, Vector3(t, keep_h - 0.9, d - t * 0.5), Vector3(w - 2 * t, 0.9, t * 0.5), stone.darkened(0.05))
	Meshes.box(st, Vector3(t + 0.1, keep_h - 2.0, d - t * 0.5 - 0.02), Vector3(w - 2 * t - 0.2, 1.1, 0.04), stone.darkened(0.3))
	_merlons(st, t, w - t, d - 0.6, keep_h, stone, true)
	_merlons(st, t, w - t, 0.0, keep_h, stone, true)
	for y in [1.3, 2.4, 3.4]:
		if y + 0.5 < tower_h:
			_window(st, wst, 0.3, y, d, 0.16, 0.42, stone.lightened(0.15))
			_window(st, wst, w - 0.46, y, d, 0.16, 0.42, stone.lightened(0.15))
	_window(st, wst, w * 0.5 - 0.15, keep_h - 1.6, d - t * 0.5, 0.3, 0.5, stone.lightened(0.15))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.2, 0, d - t * 0.5 + 0.01), Vector3(0.6, 1.1, 0.06), Color("2e241e"))
		Meshes.box(st, Vector3(door_x + 0.1, 1.1, d - t * 0.5), Vector3(0.8, 0.12, 0.1), stone.lightened(0.18))

## King John's Castle: a Norman curtain wall on the river with great drum towers at the corners and a
## twin-towered gatehouse in the middle of the front.
static func _king_johns(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, region: String) -> void:
	var stone := Color("9e988a")
	var wall_h := 2.6
	var t := 0.7
	Meshes.box(st, Vector3(0, 0, d - t - 0.4), Vector3(w, wall_h, t), stone)
	Meshes.box(st, Vector3(0, 0, 0.4), Vector3(w, wall_h, t), stone.darkened(0.05))
	Meshes.box(st, Vector3(0.4, 0, 0), Vector3(t, wall_h, d), stone.darkened(0.04))
	Meshes.box(st, Vector3(w - t - 0.4, 0, 0), Vector3(t, wall_h, d), stone.darkened(0.04))
	Meshes.box(st, Vector3(t, 0, t), Vector3(w - 2 * t, 0.05, d - 2 * t), Color("7d8658"))
	_merlons(st, 0.8, w - 0.8, d - t - 0.4, wall_h, stone, true)
	_merlons(st, 0.8, w - 0.8, 0.4, wall_h, stone, true)
	var rr := minf(1.35, d * 0.24)
	for c in [Vector2(rr, rr), Vector2(w - rr, rr), Vector2(rr, d - rr), Vector2(w - rr, d - rr)]:
		Meshes.cylinder(st, Vector3(c.x, 0, c.y), rr, wall_h + 1.6, 10, stone.lightened(0.05))
		for i in 8:
			var a := TAU * i / 8.0
			Meshes.box(st, Vector3(c.x + cos(a) * rr * 0.72 - 0.15, wall_h + 1.6, c.y + sin(a) * rr * 0.72 - 0.15), Vector3(0.3, 0.32, 0.3), stone.lightened(0.08))
		_window(st, wst, c.x - 0.08, 1.8, c.y + rr * 0.9, 0.16, 0.45, stone.lightened(0.2))
	var gx := float(door_x) + 0.5 if door_x >= 0 else w * 0.5
	for s in [-1.0, 1.0]:
		Meshes.cylinder(st, Vector3(gx + s * 1.0, 0, d - 0.9), 0.75, wall_h + 1.2, 8, stone.lightened(0.08))
		_merlons(st, gx + s * 1.0 - 0.6, gx + s * 1.0 + 0.6, d - 1.2, wall_h + 1.2, stone, true)
	Meshes.box(st, Vector3(gx - 0.6, 0, d - 1.1), Vector3(1.2, wall_h + 0.6, 0.9), stone.lightened(0.04))
	if door_x >= 0:
		Meshes.box(st, Vector3(gx - 0.32, 0, d - 0.18), Vector3(0.64, 1.25, 0.06), Color("2a221e"))
		_window(st, wst, gx - 0.15, wall_h - 0.2, d - 0.2, 0.3, 0.4, stone.lightened(0.2))
	Meshes.box(st, Vector3(rr - 0.025, wall_h + 1.9, rr - 0.025), Vector3(0.05, 1.0, 0.05), Color("3b2a22"))
	_pennant(st, Vector3(rr + 0.03, wall_h + 2.85, rr), region)

## A Clare cottage: long and low, whitewashed, a deep golden thatch with a rolled ridge, a red half-door and
## a chimney at each gable.
static func _clare_thatch(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var wall := CLARE_LIME
	var h := 1.15
	Meshes.box(st, Vector3(0.08, 0, 0.12), Vector3(w - 0.16, h, d - 0.24), wall)
	Meshes.box(st, Vector3(0.02, 0, 0.06), Vector3(w - 0.04, 0.14, d - 0.12), Color("8a8478"))
	var straw := SHANNON_THATCH.lightened(rng.randf_range(-0.05, 0.05))
	_roof(st, w, d, h, straw, wall, 0.5)
	var rise := minf(1.2, d * 0.5)
	Meshes.box(st, Vector3(-0.1, h + rise - 0.12, d * 0.5 - 0.16), Vector3(w + 0.2, 0.22, 0.32), straw.darkened(0.12))
	for cx in [0.25, w - 0.65]:
		Meshes.box(st, Vector3(cx, h, d * 0.5 - 0.2), Vector3(0.4, rise + 0.4, 0.4), wall.darkened(0.05))
		_chimneys.append(Vector3(cx + 0.2, h + rise + 0.45, d * 0.5))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.24, 0.14, d - 0.15), Vector3(0.52, 0.45, 0.05), Color("b8322a"))
		Meshes.box(st, Vector3(door_x + 0.24, 0.59, d - 0.14), Vector3(0.52, 0.45, 0.04), Color("9a2a24"))
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.32, 0.42, d - 0.12, 0.36, 0.42, Color("b8322a"))

## A Georgian terrace of Newtown Pery: four storeys of red brick behind a parapet, tall sash windows, and a
## bright front door under a fanlight on every other bay.
static func _georgian(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var brick := LIMERICK_BRICK.lightened(rng.randf_range(-0.05, 0.04))
	var storeys := 4
	var fh := 0.95
	var hgt := fh * storeys + 0.35
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), brick, Color("4a4e58"))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.5, d), LIMESTONE_GREY)        # limestone plinth
	Meshes.box(st, Vector3(-0.04, hgt - 0.12, d - 0.12), Vector3(w + 0.08, 0.16, 0.16), LIMESTONE_GREY)
	for i in range(0, w + 1, 2):
		var sx := minf(float(i), w - 0.4)
		Meshes.box(st, Vector3(sx, hgt, d * 0.5 - 0.25), Vector3(0.4, 0.55, 0.5), brick.darkened(0.15))
		_chimneys.append(Vector3(sx + 0.2, hgt + 0.6, d * 0.5))
	var doors := [Color("b8322a"), Color("1f4f8a"), Color("2d6a3e"), Color("e0b030"), Color("1c1c22")]
	for x in w:
		for s in storeys:
			var tall := 0.62 if s == 1 else (0.52 if s == 0 else 0.42)
			if s == 0 and (x == door_x or (door_x < 0 and x % 2 == 0)):
				var dc: Color = doors[rng.randi_range(0, doors.size() - 1)]
				Meshes.box(st, Vector3(x + 0.26, 0.05, d - 0.06), Vector3(0.48, 0.78, 0.05), dc)
				Meshes.box(st, Vector3(x + 0.22, 0.83, d - 0.07), Vector3(0.56, 0.16, 0.06), Color("f0ead8"))   # fanlight
				Meshes.box(wst, Vector3(x + 0.3, 0.85, d - 0.065), Vector3(0.4, 0.1, 0.04), window_colour(_wr))
				continue
			_window(st, wst, x + 0.33, 0.3 + fh * s + (0.0 if s > 0 else 0.1), d, 0.34, tall, Color("f2eee4"))

## Shannon Airport: a long low terminal with a glass front, and the control tower at the east end.
static func _airport(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var wall := Color("dcdad2")
	var h := 1.6
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), wall, Color("8a8e94"))
	Meshes.box(st, Vector3(-0.1, h - 0.15, -0.1), Vector3(w + 0.2, 0.18, d + 0.4), Color("f4f4f0"))  # canopy edge
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.06, 0.3, d, 0.88, 1.0, Color("6a7480"))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.1, 0.05, d - 0.06), Vector3(0.8, 1.1, 0.05), Color("4a5a68"))
	var tx := w - 1.2
	var tz := d * 0.4
	Meshes.cylinder(st, Vector3(tx, h, tz), 0.42, 2.6, 8, wall)
	Meshes.box(st, Vector3(tx - 0.7, h + 2.6, tz - 0.7), Vector3(1.4, 0.7, 1.4), Color("3e4c5a"))
	Meshes.box(wst, Vector3(tx - 0.72, h + 2.7, tz - 0.72), Vector3(1.44, 0.45, 1.44), window_colour(_wr))
	Meshes.box(st, Vector3(tx - 0.85, h + 3.3, tz - 0.85), Vector3(1.7, 0.12, 1.7), Color("eceae4"))
	Meshes.box(st, Vector3(tx - 0.03, h + 3.42, tz - 0.03), Vector3(0.06, 0.6, 0.06), Color("c83030"))
	Meshes.box(st, Vector3(1.0, h, d * 0.5 - 0.1), Vector3(0.1, 0.8, 0.1), Color("eceae4"))   # flagpole and tricolour
	Meshes.box(st, Vector3(1.1, h + 0.5, d * 0.5 - 0.1), Vector3(0.15, 0.28, 0.02), Color("169b62"))
	Meshes.box(st, Vector3(1.25, h + 0.5, d * 0.5 - 0.1), Vector3(0.15, 0.28, 0.02), Color("f4f1e8"))
	Meshes.box(st, Vector3(1.4, h + 0.5, d * 0.5 - 0.1), Vector3(0.15, 0.28, 0.02), Color("ff883e"))

## The Foynes Clipper: a Boeing 314 flying boat on its cradle, deep hull, high wing with four engines and the
## triple tail, in silver with a blue cheat line.
static func _flying_boat(st: SurfaceTool, w: int, d: int) -> void:
	var silver := Color("c9ced4")
	var blue := Color("2c4c8c")
	var zc := d * 0.5
	var hull_y := 0.55
	for i in 3:   # cradle
		Meshes.box(st, Vector3(1.2 + i * (w - 2.8) / 2.0, 0, zc - 0.5), Vector3(0.3, hull_y, 1.0), Color("4a4038"))
	Meshes.box(st, Vector3(1.0, hull_y, zc - 0.6), Vector3(w - 2.6, 1.15, 1.2), silver)
	Meshes.box(st, Vector3(0.4, hull_y + 0.2, zc - 0.5), Vector3(0.7, 0.85, 1.0), silver.lightened(0.05))   # the nose
	Meshes.box(st, Vector3(0.15, hull_y + 0.45, zc - 0.35), Vector3(0.3, 0.5, 0.7), silver.lightened(0.08))
	Meshes.box(st, Vector3(w - 1.6, hull_y + 0.45, zc - 0.4), Vector3(1.2, 0.6, 0.8), silver)                # tail cone
	Meshes.box(st, Vector3(0.4, hull_y + 0.55, zc + 0.5), Vector3(w - 1.6, 0.1, 0.12), blue)
	Meshes.box(st, Vector3(0.4, hull_y + 0.55, zc - 0.62), Vector3(w - 1.6, 0.1, 0.12), blue)
	Meshes.box(st, Vector3(0.55, hull_y + 0.95, zc - 0.36), Vector3(0.45, 0.22, 0.72), Color("2a3442"))     # cockpit glass
	for x in range(2, w - 2):
		Meshes.box(st, Vector3(x + 0.2, hull_y + 0.75, zc + 0.6), Vector3(0.22, 0.18, 0.02), Color("2a3442"))
	var wx := w * 0.36
	Meshes.box(st, Vector3(wx, hull_y + 1.15, zc - 0.6), Vector3(1.0, 0.25, 1.2), silver.darkened(0.05))      # wing root
	Meshes.box(st, Vector3(wx, hull_y + 1.4, -1.8), Vector3(1.2, 0.12, d + 3.6), silver.lightened(0.04))
	for z in [-1.0, 0.3, d - 0.3, d + 1.0]:
		Meshes.box(st, Vector3(wx - 0.45, hull_y + 1.2, z - 0.2), Vector3(0.75, 0.38, 0.4), silver.darkened(0.12))
		Meshes.box(st, Vector3(wx - 0.5, hull_y + 1.16, z - 0.35), Vector3(0.04, 0.7, 0.7), Color("2a2a2e"))  # propeller
	for z in [-1.4, d + 1.4]:   # wing floats
		Meshes.box(st, Vector3(wx + 0.3, hull_y + 0.85, z - 0.2), Vector3(0.5, 0.25, 0.4), silver.darkened(0.08))
	Meshes.box(st, Vector3(w - 1.0, hull_y + 1.05, zc - 1.4), Vector3(0.7, 0.1, 2.8), silver)                # tailplane
	for z in [zc - 1.35, zc - 0.05, zc + 1.25]:
		Meshes.box(st, Vector3(w - 0.95, hull_y + 1.15, z), Vector3(0.6, 0.85, 0.1), silver.darkened(0.04))

## Ardnacrusha: the Shannon Scheme's power house, a tall pale block with tall windows, the higher intake
## building behind and three great penstocks stepping down to it.
static func _hydro(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var conc := Color("d8d0bc")
	var h := 2.6
	Meshes.box(st, Vector3(0.05, 0, d * 0.4), Vector3(w - 0.1, h, d * 0.6 - 0.05), conc, Color("8a8478"))
	Meshes.box(st, Vector3(0.6, 0, 0.05), Vector3(w - 1.2, h + 1.4, d * 0.32), conc.darkened(0.06), Color("7a7468"))
	for i in 3:
		var px := w * (0.25 + 0.25 * i) - 0.3
		for s in 4:
			Meshes.box(st, Vector3(px, h + 1.0 - s * 0.32, d * 0.3 + s * 0.22), Vector3(0.6, 0.45, 0.32), Color("5a5e64"))
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.32, 0.4, d, 0.36, 1.8, conc.lightened(0.1))
	Meshes.box(st, Vector3(0, h - 0.2, d - 0.08), Vector3(w, 0.25, 0.1), conc.darkened(0.15))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0, d - 0.06), Vector3(0.7, 1.2, 0.05), Color("3a4048"))

## Thomond Park: stands round a green pitch, cantilever roofs over the long sides trimmed in Munster red.
static func _stadium(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var conc := Color("b8b4aa")
	var red := Color("c8102e")
	Meshes.box(st, Vector3(1.0, 0, 1.0), Vector3(w - 2.0, 0.06, d - 2.0), Color("4f8a3a"))
	for i in 3:   # long stands, stepped
		var y := 0.45 * (i + 1)
		Meshes.box(st, Vector3(0.4, 0, d - 1.0 + i * 0.3), Vector3(w - 0.8, y, 0.32), conc.darkened(0.04 * i))
		Meshes.box(st, Vector3(0.4, 0, 0.1 + (2 - i) * 0.3), Vector3(w - 0.8, y, 0.32), conc.darkened(0.04 * i))
	for i in 2:   # end terraces
		Meshes.box(st, Vector3(0.1 + (1 - i) * 0.4, 0, 1.0), Vector3(0.4, 0.4 * (i + 1), d - 2.0), conc)
		Meshes.box(st, Vector3(w - 0.9 + i * 0.4, 0, 1.0), Vector3(0.4, 0.4 * (i + 1), d - 2.0), conc)
	for z in [d - 1.3, 0.0]:
		Meshes.box(st, Vector3(0.3, 2.1, z), Vector3(w - 0.6, 0.12, 1.3), Color("e8e6e0"))
		Meshes.box(st, Vector3(0.3, 2.0, z + (0.0 if z > 0.0 else 1.2)), Vector3(w - 0.6, 0.14, 0.1), red)
	for x in [0.5, w - 0.7]:
		for z in [d - 0.2, 0.2]:
			Meshes.box(st, Vector3(x, 0, z), Vector3(0.12, 2.1, 0.12), Color("7a7a80"))
	for x in [w * 0.5 - 1.4, w * 0.5 + 1.2]:   # the posts
		Meshes.box(st, Vector3(x, 0, d * 0.5 - 0.05), Vector3(0.06, 1.6, 0.06), Color("f4f4f0"))
	Meshes.box(st, Vector3(w * 0.5 - 1.4, 0.5, d * 0.5 - 0.04), Vector3(2.66, 0.05, 0.05), Color("f4f4f0"))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0, d - 0.04), Vector3(0.7, 1.1, 0.06), red.darkened(0.35))

## The Milk Market: a low limestone market house with open arches under a great white peaked canopy.
static func _milk_market(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := LIMESTONE_GREY
	var h := 1.1
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, 0.06, d - 0.1), Color("9a948a"))
	for x in w:
		if x == door_x:
			continue
		Meshes.box(st, Vector3(x, 0, d - 0.3), Vector3(0.22, h, 0.25), stone)
		Meshes.box(st, Vector3(x, 0, 0.05), Vector3(0.22, h, 0.25), stone)
	Meshes.box(st, Vector3(0, h, d - 0.32), Vector3(w, 0.25, 0.3), stone.lightened(0.05))
	Meshes.box(st, Vector3(0, h, 0.05), Vector3(w, 0.25, 0.3), stone.lightened(0.05))
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(0.25, h + 0.25, d - 0.1), stone)
	Meshes.box(st, Vector3(w - 0.3, 0, 0.05), Vector3(0.25, h + 0.25, d - 0.1), stone)
	var canvas := Color("f2f2ec")
	var top := h + 0.25
	var peaks := maxi(1, int(round(w / 4.0)))
	var pw := float(w) / peaks
	for i in peaks:
		var x0 := i * pw
		var c := Vector3(x0 + pw * 0.5, top + 1.5, d * 0.5)
		var corners := [Vector3(x0 - 0.1, top, -0.15), Vector3(x0 + pw + 0.1, top, -0.15), Vector3(x0 + pw + 0.1, top, d + 0.15), Vector3(x0 - 0.1, top, d + 0.15)]
		for k in 4:
			Meshes._tri(st, corners[k], corners[(k + 1) % 4], c, canvas.darkened(0.04 * k))
			Meshes._tri(st, corners[(k + 1) % 4], corners[k], c, canvas.darkened(0.25))
		Meshes.box(st, Vector3(c.x - 0.04, top, c.z - 0.04), Vector3(0.08, 1.8, 0.08), Color("8a8e94"))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.1, h - 0.05, d - 0.33), Vector3(0.8, 0.12, 0.32), Color("2d6a3e"))
# --- Shropshire ------------------------------------------------------------------

## Shropshire black-and-white ("magpie") timber framing: close-set black studs over whitewash on both floors, a
## jettied upper storey, and a row of steep gables to the street with dark barge boards.
static func _magpie(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var wall := Color("f1ece0")
	var beam := Color("231d1b")
	var roof := Color("4f413b")
	var g := 1.2      # ground storey
	var hgt := 2.55   # eaves
	var jut := 0.16   # the jetty
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, g, d - 0.1), wall)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), Color("5b4d44"))
	Meshes.box(st, Vector3(0, g, 0), Vector3(w, hgt - g, d + jut), wall)
	# rails: sill, jetty bressumer, mid rail and wall plate
	Meshes.box(st, Vector3(0, g - 0.06, d - 0.04), Vector3(w, 0.1, 0.08), beam)
	Meshes.box(st, Vector3(0, g, d + jut - 0.02), Vector3(w, 0.12, 0.08), beam)
	Meshes.box(st, Vector3(0, 1.86, d + jut - 0.01), Vector3(w, 0.07, 0.06), beam)
	Meshes.box(st, Vector3(0, hgt - 0.08, d + jut - 0.02), Vector3(w, 0.1, 0.08), beam)
	# close studding, ground floor and upper floor
	var n := int(w / 0.34)
	for i in range(n + 1):
		var x := minf(i * w / float(n), w - 0.06)
		Meshes.box(st, Vector3(x, 0.16, d - 0.03), Vector3(0.06, g - 0.2, 0.05), beam)
	for i in range(w * 2 + 1):
		var x := minf(i * 0.5, w - 0.06)
		Meshes.box(st, Vector3(x, g + 0.1, d + jut - 0.01), Vector3(0.07, hgt - g - 0.16, 0.05), beam)
	# gables to the street: one per two tiles
	var gables := maxi(1, w / 2)
	var gw := float(w) / gables
	var rise := 1.15
	for k in gables:
		var x0 := k * gw
		var x1 := x0 + gw
		var xm := (x0 + x1) * 0.5
		var a := Vector3(x0 - 0.06, hgt, -0.1)
		var b := Vector3(x1 + 0.06, hgt, -0.1)
		var c := Vector3(x1 + 0.06, hgt, d + jut + 0.12)
		var dd := Vector3(x0 - 0.06, hgt, d + jut + 0.12)
		var r0 := Vector3(xm, hgt + rise, -0.1)
		var r1 := Vector3(xm, hgt + rise, d + jut + 0.12)
		Meshes._quad(st, r1, r0, a, dd, roof)
		Meshes._quad(st, dd, a, r0, r1, roof)
		Meshes._quad(st, r0, r1, c, b, roof.darkened(0.15))
		Meshes._quad(st, b, c, r1, r0, roof.darkened(0.15))
		Meshes._tri(st, Vector3(x0, hgt, d + jut), Vector3(x1, hgt, d + jut), Vector3(xm, hgt + rise - 0.06, d + jut), wall)
		Meshes._tri(st, Vector3(xm, hgt + rise - 0.06, d + jut), Vector3(x1, hgt, d + jut), Vector3(x0, hgt, d + jut), wall)
		Meshes._tri(st, b, a, r0, wall.darkened(0.08))
		# a chevron of braces across the upper storey (the Shropshire herringbone), then the gable's king post
		var zf := d + jut + 0.03
		_beam(st, Vector3(x0 + 0.12, g + 0.16, zf), Vector3(xm, hgt - 0.1, zf), 0.07, beam)
		_beam(st, Vector3(x1 - 0.12, g + 0.16, zf), Vector3(xm, hgt - 0.1, zf), 0.07, beam)
		# a king post and stepped barge boards in the gable
		Meshes.box(st, Vector3(xm - 0.03, hgt, d + jut), Vector3(0.06, rise - 0.12, 0.05), beam)
		for t in 4:
			var f := (t + 0.5) / 4.0
			Meshes.box(st, Vector3(x0 + (xm - x0) * f - 0.07, hgt + rise * f - 0.05, d + jut + 0.06), Vector3(0.14, 0.09, 0.06), beam)
			Meshes.box(st, Vector3(x1 - (x1 - xm) * f - 0.07, hgt + rise * f - 0.05, d + jut + 0.06), Vector3(0.14, 0.09, 0.06), beam)
		_window(st, wst, xm - 0.18, hgt + 0.12, d + jut + 0.02, 0.36, 0.32, beam)
	# a tall brick chimney stack at the back
	var cx := rng.randf_range(0.5, maxf(0.6, w - 0.9))
	Meshes.box(st, Vector3(cx, hgt, 0.15), Vector3(0.4, 1.7, 0.4), Color("8a4b3b"))
	_chimneys.append(Vector3(cx + 0.2, hgt + 1.7, 0.35))
	_door(st, door_x, d, wall)
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.25, 0.42, d + 0.02, 0.5, 0.5, beam)
		_window(st, wst, x + 0.22, 1.4, d + jut + 0.02, 0.56, 0.36, beam)

## Ditherington Flax Mill: long, five storeys of red brick with small windows in tidy rows, a low slate roof, a
## pale band at every floor where the iron beams sit inside, and a taller hoist tower in the middle.
static func _flax_mill(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var storeys := 5
	var fh := 0.8
	var hgt := fh * storeys + 0.25
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), BRICK, BRICK.darkened(0.3))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.2, d), DARK_BRICK)
	for s in storeys:
		Meshes.box(st, Vector3(0.0, fh * s + 0.74, d - 0.07), Vector3(w, 0.05, 0.04), LIMESTONE.darkened(0.1))
		for x in w:
			if x == door_x and s == 0:
				continue
			_window(st, wst, x + 0.3, 0.3 + fh * s, d, 0.4, 0.4, LIMESTONE)
	_roof(st, w, d, hgt, SLATE, BRICK, 0.18)
	var tx := w * 0.25 - 0.6
	Meshes.box(st, Vector3(tx, 0, d - 0.25), Vector3(1.2, hgt + 0.7, 0.45), BRICK.lightened(0.04))
	_roof_at(st, tx - 0.05, tx + 1.25, d - 0.3, d + 0.25, hgt + 0.7, 0.35, SLATE, BRICK)
	_window(st, wst, tx + 0.4, hgt + 0.1, d + 0.2, 0.4, 0.4, LIMESTONE)
	_door(st, door_x, d, BRICK, 1.0)

## Darby's Old Furnace at Coalbrookdale: a squat, stepped brick furnace with a glowing casting arch under a black
## cast-iron beam, sheltered by a modern glass-and-steel canopy on slender posts.
static func _blast_furnace(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var brick := Color("8e5442")
	var stone := Color("b49a7a")
	var iron := Color("2b2624")
	var cx := w * 0.5 + 1.0
	var cz := d * 0.5 - 0.3
	for i in 4:
		var r := 1.5 - i * 0.28
		Meshes.box(st, Vector3(cx - r, i * 0.75, cz - r * 0.8), Vector3(r * 2.0, 0.75, r * 1.6), brick.darkened(0.05 * (i % 2)), stone)
	Meshes.cylinder(st, Vector3(cx, 3.0, cz), 0.5, 0.5, 8, brick.darkened(0.15))
	# the casting arch on the south face, glowing, with the dated iron beam over it
	var fz := cz + 1.5 * 0.8
	Meshes.box(st, Vector3(cx - 0.55, 0.05, fz - 0.02), Vector3(1.1, 0.9, 0.05), Color("2a1510"))
	Meshes.box(st, Vector3(cx - 0.4, 0.08, fz + 0.01), Vector3(0.8, 0.45, 0.03), Color("ff8a26"))
	Meshes.box(st, Vector3(cx - 0.75, 0.95, fz - 0.04), Vector3(1.5, 0.16, 0.1), iron)
	Meshes.box(st, Vector3(cx - 0.62, 0.0, fz - 0.06), Vector3(0.14, 0.95, 0.12), iron)
	Meshes.box(st, Vector3(cx + 0.48, 0.0, fz - 0.06), Vector3(0.14, 0.95, 0.12), iron)
	# the canopy: posts and a shallow glazed roof
	var steel := Color("8d969b")
	for p in [Vector2(0.15, 0.15), Vector2(w - 0.25, 0.15), Vector2(0.15, d - 0.25), Vector2(w - 0.25, d - 0.25)]:
		Meshes.box(st, Vector3(p.x, 0, p.y), Vector3(0.1, 4.0, 0.1), steel)
	Meshes.box(st, Vector3(-0.1, 4.0, -0.1), Vector3(w + 0.2, 0.08, d + 0.2), steel.darkened(0.1))
	Meshes.box(st, Vector3(0.1, 4.08, 0.1), Vector3(w - 0.2, 0.03, d - 0.2), Color("9fb7bd"))
	# the museum entrance: a low brick lodge on the door column
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.6, 0, d - 1.2), Vector3(2.2, 1.4, 1.15), brick.lightened(0.05))
		_roof_at(st, door_x - 0.7, door_x + 1.7, d - 1.25, d + 0.0, 1.4, 0.4, SLATE, brick)
		_door(st, door_x, d - 0.05, brick, 1.0)

## A box beam from a to b, thickness t, square to the xy plane, so an arch rib reads at any angle from the side.
static func _beam(st: SurfaceTool, a: Vector3, b: Vector3, t: float, col: Color) -> void:
	var dir := (b - a).normalized()
	var n := Vector3(-dir.y, dir.x, 0.0) * (t * 0.5)
	var zo := Vector3(0, 0, t * 0.5)
	var c := [a - n - zo, a + n - zo, a + n + zo, a - n + zo]
	var e := [b - n - zo, b + n - zo, b + n + zo, b - n + zo]
	for i in 4:
		var j := (i + 1) % 4
		Meshes._quad(st, c[i], c[j], e[j], e[i], col.darkened(0.08 * (i % 2)))

## The Iron Bridge (1779): five semicircular cast-iron ribs under a level deck, the rings in the haunches, stone
## abutments and railings. A walkable point prop on the middle deck tile of a two-row "bridge" crossing five tiles
## of river three levels down: local x -2.5..2.5 is the span, z -0.5..1.5 the deck, y 0 the deck top, -1.6 the water.
static func iron_bridge() -> ArrayMesh:
	var st := Meshes._st()
	var iron := Color("7a3f2e")
	var dark := iron.darkened(0.35)
	var stone := Color("a1907a")
	var span := 2.5
	var water := -1.58
	Meshes._quad(st, Vector3(-span, water, -0.5), Vector3(span, water, -0.5), Vector3(span, water, 1.5), Vector3(-span, water, 1.5), Color("2b3c40"))
	Meshes.box(st, Vector3(-span - 0.05, -0.16, -0.5), Vector3(span * 2 + 0.1, 0.15, 2.0), dark)
	Meshes.box(st, Vector3(-span - 0.05, water - 0.1, -0.55), Vector3(0.35, -water + 0.0, 2.1), stone)
	Meshes.box(st, Vector3(span - 0.3, water - 0.1, -0.55), Vector3(0.35, -water + 0.0, 2.1), stone)
	var segs := 12
	for k in 5:
		var z := -0.42 + k * 0.46
		var outer := k == 0 or k == 4
		var rings := [[span - 0.3, -water - 0.2]]
		if outer:
			rings.append([span - 0.7, -water - 0.55])
			rings.append([span - 1.05, -water - 0.8])
		for ri in rings.size():
			var rx: float = rings[ri][0]
			var ry: float = rings[ri][1]
			var prev := Vector3(-rx, water, z)
			for i in range(1, segs + 1):
				var a := PI - PI * i / segs
				var p := Vector3(cos(a) * rx, water + sin(a) * ry, z)
				_beam(st, prev, p, 0.12 if ri == 0 else 0.07, iron)
				prev = p
		if outer:
			# uprights from the rib to the deck, and a ring in each haunch
			for f in [-0.8, -0.55, 0.55, 0.8]:
				var px: float = f * (span - 0.3)
				var py: float = water + sqrt(maxf(0.0, 1.0 - f * f)) * (-water - 0.2)
				_beam(st, Vector3(px, py, z), Vector3(px, -0.16, z), 0.06, iron)
			for sx in [-1.0, 1.0]:
				var c := Vector3(sx * (span - 0.55), -0.42, z)
				var prev2 := c + Vector3(0.2, 0, 0)
				for i in range(1, 9):
					var a3 := TAU * i / 8.0
					var q := c + Vector3(cos(a3) * 0.2, sin(a3) * 0.2, 0)
					_beam(st, prev2, q, 0.05, iron)
					prev2 = q
	for x in [-1.6, 0.0, 1.6]:
		_beam(st, Vector3(x, -0.3, -0.42), Vector3(x, -0.3, 1.42), 0.06, dark)
	for zr in [-0.48, 1.44]:
		for i in 11:
			Meshes.box(st, Vector3(-span + i * 0.5 - 0.025, 0.0, zr), Vector3(0.05, 0.5, 0.04), dark)
		Meshes.box(st, Vector3(-span, 0.46, zr - 0.01), Vector3(span * 2, 0.05, 0.06), dark)
		Meshes.box(st, Vector3(-span, 0.24, zr), Vector3(span * 2, 0.03, 0.04), dark)
	Meshes.box(st, Vector3(-0.45, -0.15, 1.5), Vector3(0.9, 0.12, 0.03), Color("c9b98a"))
	return Meshes._finish(st)

## A glider soaring over the Long Mynd: long white wings, a slim fuselage and a T-tail, hung high above the hill
## (a walkable point prop). 0 banking one way, 1 the other.
static func glider(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var white := Color("f4f4f0")
	var y := 4.2
	var bank := 0.12 if variant == 0 else -0.12
	Meshes.box(st, Vector3(-0.08, y, -0.6), Vector3(0.16, 0.16, 1.3), white)
	Meshes.box(st, Vector3(-0.06, y + 0.1, -0.45), Vector3(0.12, 0.08, 0.3), Color("6a8fa8"))
	for sx in [-1.0, 1.0]:
		var tip := Vector3(sx * 1.6, y + 0.1 + sx * bank, -0.15)
		Meshes._quad(st, Vector3(0, y + 0.1, -0.25), tip + Vector3(0, 0, -0.06), tip + Vector3(0, 0, 0.08), Vector3(0, y + 0.1, 0.0), white)
		Meshes._quad(st, Vector3(0, y + 0.09, 0.0), tip + Vector3(0, -0.01, 0.08), tip + Vector3(0, -0.01, -0.06), Vector3(0, y + 0.09, -0.25), white.darkened(0.25))
	Meshes.box(st, Vector3(-0.02, y + 0.1, 0.55), Vector3(0.04, 0.3, 0.12), white)
	Meshes.box(st, Vector3(-0.35, y + 0.38, 0.55), Vector3(0.7, 0.03, 0.12), white)
	Meshes.box(st, Vector3(-0.35, y + 0.38, 0.55), Vector3(0.12, 0.031, 0.12), Color("c8102e"))
	return Meshes._finish(st)
# --- East Anglia ---------------------------------------------------------------
# Cambridge's pale stone colleges and gault brick, the Fens' great cathedral, Norfolk flint, pantiles and reed
# thatch, Norwich's spire and keep, and the props of the waterways (punts, wherries, drainage mills).

const KETTON := Color("dacfae")      # Cambridge's pale oolitic limestone
const GAULT := Color("d4c79c")       # gault brick, "Cambridge white"
const FLINT := Color("43464c")
const PANTILE := Color("b0552f")
const REED := Color("a88f55")
const CAEN := Color("e2d9c2")        # Norwich Cathedral's Normandy stone
const LEAD := Color("8f979d")
const TARRED := Color("27282b")
const EA_PROPS := ["windpump", "punt", "maths_bridge", "wherry"]

static func ea_building(st: SurfaceTool, wst: SurfaceTool, style: String, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	match style:
		"gault":
			_house(st, wst, w, d, door_x, rng, GAULT, SLATE, 2, true, false)
		"flint":
			_flint(st, wst, w, d, door_x, rng, false)
		"flint_gable":
			_flint(st, wst, w, d, door_x, rng, true)
		"thatch":
			_thatch(st, wst, w, d, door_x, rng)
		"college":
			_college(st, wst, w, d, door_x)
		"kings_chapel":
			_kings_chapel(st, wst, w, d, door_x)
		"portico":
			_portico(st, wst, w, d, door_x)
		"ely_cathedral":
			_ely(st, wst, w, d, door_x)
		"norwich_cathedral":
			_norwich_cathedral(st, wst, w, d, door_x)
		"norman_keep":
			_norman_keep(st, wst, w, d, door_x)
		"football_stand":
			_football_stand(st, wst, w, d, door_x)

## A window on a face that sits at `face` (z), standing just proud of it.
static func _ewin(st: SurfaceTool, wst: SurfaceTool, x: float, y: float, face: float, ww: float, wh: float, frame: Color) -> void:
	_window(st, wst, x, y, face + 0.08, ww, wh, frame)

## A flat panel seen from both sides (sails, punt poles' blades, banners).
static func _panel(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, e: Vector3, col: Color) -> void:
	Meshes._quad(st, a, b, c, e, col)
	Meshes._quad(st, e, c, b, a, col.darkened(0.15))

## Flint walling: the body in dark flint, the street face peppered with knapped nodules of grey, black and
## blue-white, brick at the corners. Deterministic per building.
static func _flint_face(st: SurfaceTool, rng: RandomNumberGenerator, x0: float, x1: float, y0: float, y1: float, z: float) -> void:
	var y := y0
	while y < y1 - 0.05:
		var x := x0 + rng.randf_range(0.0, 0.12)
		while x < x1 - 0.1:
			var s := rng.randf_range(0.12, 0.2)
			var k := rng.randf()
			var col := FLINT.lightened(0.35) if k < 0.2 else (FLINT.darkened(0.35) if k < 0.55 else Color("5a6068"))
			Meshes._quad(st, Vector3(x, y + s * 0.8, z + 0.012), Vector3(x + s, y + s * 0.8, z + 0.012), Vector3(x + s, y, z + 0.012), Vector3(x, y, z + 0.012), col)
			x += s + rng.randf_range(0.06, 0.14)
		y += rng.randf_range(0.2, 0.27)

## Pantile ridges: the S-shaped clay tiles read from a distance as stripes running down the roof.
static func _pantiles(st: SurfaceTool, w: float, d: float, hgt: float, rise: float) -> void:
	var eave := 0.18
	var x := -eave + 0.06
	while x < w + eave - 0.1:
		var top := Vector3(x, hgt + rise + 0.02, d * 0.5)
		var bot := Vector3(x, hgt + 0.02, d + eave)
		Meshes._quad(st, top, top + Vector3(0.07, 0, 0), bot + Vector3(0.07, 0, 0), bot, PANTILE.darkened(0.25))
		x += 0.24

static func _flint(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, gable: bool) -> void:
	var storeys := 2 if d >= 3 and w >= 4 else 1
	var hgt := 1.15 * storeys + 0.2
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), FLINT)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), DARK_BRICK)
	_flint_face(st, rng, 0.2, w - 0.2, 0.18, hgt - 0.05, d - 0.05)
	for qx in [0.0, w - 0.22]:  # brick quoins, in alternating long and short blocks
		var y := 0.16
		var i := 0
		while y < hgt - 0.05:
			var lw := 0.22 if i % 2 == 0 else 0.15
			Meshes.box(st, Vector3(qx if qx == 0.0 else w - lw, y, d - 0.12), Vector3(lw, 0.13, 0.14), BRICK)
			y += 0.15
			i += 1
	var rise := minf(1.2, d * 0.42)
	_roof(st, w, d, hgt, PANTILE, FLINT, 0.42)
	_pantiles(st, w, d, hgt, rise)
	if gable:
		# Dutch gables in brick at both ends, curved shoulders stepping up past the roof line
		for gx in [-0.05, w - 0.25]:
			var steps := [[0.05, d - 0.05, hgt, hgt + rise * 0.55], [d * 0.18, d * 0.82, hgt + rise * 0.55, hgt + rise * 0.95],
					[d * 0.3, d * 0.7, hgt + rise * 0.95, hgt + rise * 1.3], [d * 0.4, d * 0.6, hgt + rise * 1.3, hgt + rise * 1.45]]
			for s in steps:
				Meshes.box(st, Vector3(gx, s[2], s[0]), Vector3(0.3, s[3] - s[2], s[1] - s[0]), BRICK)
			Meshes.box(st, Vector3(gx - 0.03, hgt + rise * 1.45, d * 0.37), Vector3(0.36, 0.06, d * 0.26), LIMESTONE)
	else:
		Meshes.box(st, Vector3(0.15, hgt + 0.2, d * 0.5 - 0.2), Vector3(0.4, 1.0, 0.4), BRICK)
		_chimneys.append(Vector3(0.35, hgt + 1.2, d * 0.5))
	Meshes.box(st, Vector3(w - 0.6, hgt + 0.25, d * 0.5 - 0.2), Vector3(0.4, 0.95, 0.4), BRICK)
	_chimneys.append(Vector3(w - 0.4, hgt + 1.2, d * 0.5))
	_door(st, door_x, d, BRICK)
	for s in storeys:
		var wy := 0.4 + 1.15 * s
		for x in w:
			if x == door_x and s == 0:
				continue
			Meshes.box(st, Vector3(x + 0.2, wy - 0.12, d - 0.06), Vector3(0.6, 0.72, 0.05), BRICK)
			_ewin(st, wst, x + 0.27, wy, d + 0.02, 0.46, 0.52, Color("efe8d8"))

## Reed thatch: colour-washed walls under a deep, steep, round-shouldered roof with a cut sedge ridge.
static func _thatch(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var wall := Color("ebe2c8")
	var hgt := 1.3
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), wall)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.18, d), FLINT)
	var rise := minf(1.2, d * 0.6)
	_roof(st, w, d, hgt, REED, wall, 0.6)
	# thick eaves and a block-cut ridge in darker sedge
	Meshes.box(st, Vector3(-0.22, hgt - 0.12, d - 0.05), Vector3(w + 0.44, 0.22, 0.32), REED.darkened(0.08))
	Meshes.box(st, Vector3(-0.22, hgt - 0.12, -0.27), Vector3(w + 0.44, 0.22, 0.32), REED.darkened(0.12))
	Meshes.box(st, Vector3(-0.2, hgt + rise - 0.12, d * 0.5 - 0.22), Vector3(w + 0.4, 0.24, 0.44), REED.darkened(0.3))
	var x := 0.3
	while x < w - 0.2:  # the ridge's scalloped edge
		Meshes.box(st, Vector3(x, hgt + rise - 0.26, d * 0.5 + 0.18), Vector3(0.3, 0.14, 0.12), REED.darkened(0.3))
		x += 0.55
	var cx := rng.randf_range(0.8, maxf(0.9, w - 1.0))
	Meshes.box(st, Vector3(cx, hgt + rise - 0.4, d * 0.5 - 0.2), Vector3(0.38, 0.9, 0.4), BRICK)
	_chimneys.append(Vector3(cx + 0.19, hgt + rise + 0.5, d * 0.5))
	_door(st, door_x, d, wall)
	for x2 in w:
		if x2 != door_x:
			_ewin(st, wst, x2 + 0.3, 0.45, d, 0.42, 0.5, Color("f4efe2"))

## A Cambridge college range: pale stone, a battlemented parapet and a gatehouse with two turrets on the door.
static func _college(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var h := 2.5
	Meshes.box(st, Vector3(0.05, 0, 0.1), Vector3(w - 0.1, h, d - 0.2), KETTON)
	Meshes.box(st, Vector3(0, 0, 0.05), Vector3(w, 0.2, d - 0.1), KETTON.darkened(0.25))
	Meshes.box(st, Vector3(0, h - 0.15, d - 0.15), Vector3(w, 0.1, 0.08), KETTON.lightened(0.1))
	_roof_at(st, 0.05, w - 0.05, 0.4, d - 0.4, h, 0.5, SLATE, KETTON)
	_merlons(st, 0, w, d - 0.45, h, KETTON, true)
	for s in 2:
		for x in w:
			if absi(x - door_x) <= 1 and door_x >= 0:
				continue
			_ewin(st, wst, x + 0.3, 0.45 + 1.05 * s, d - 0.1, 0.4, 0.62, KETTON.lightened(0.2))
	if door_x >= 0:
		var gx := door_x - 0.45
		var gh := 3.4
		Meshes.box(st, Vector3(gx, 0, d - 1.2), Vector3(1.9, gh, 1.25), KETTON.lightened(0.04))
		_merlons(st, gx, gx + 1.9, d - 0.6, gh, KETTON, true)
		for tx in [gx, gx + 1.9]:
			Meshes.cylinder(st, Vector3(tx, 0, d - 0.2), 0.3, gh + 0.9, 8, KETTON.lightened(0.08))
			Meshes.cylinder(st, Vector3(tx, gh + 0.9, d - 0.2), 0.3, 0.18, 8, KETTON.darkened(0.08))
		Meshes.box(st, Vector3(door_x + 0.15, 0.1, d + 0.04), Vector3(0.7, 1.15, 0.06), Color("2e2420"))
		Meshes.box(st, Vector3(door_x + 0.08, 1.25, d + 0.04), Vector3(0.84, 0.1, 0.08), KETTON.lightened(0.2))
		_ewin(st, wst, door_x + 0.25, 1.75, d + 0.05, 0.5, 0.75, KETTON.lightened(0.2))
		# a coat of arms over the gate
		Meshes.box(st, Vector3(door_x + 0.35, 2.7, d + 0.06), Vector3(0.3, 0.36, 0.04), Color("b8322a"))
		Meshes.box(st, Vector3(door_x + 0.42, 2.82, d + 0.08), Vector3(0.16, 0.12, 0.03), Color("e0b03a"))

## King's College Chapel: one tall, long stone box, a forest of pinnacled buttresses with huge windows between,
## and four slender corner turrets with ogee caps.
static func _kings_chapel(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := KETTON.lightened(0.04)
	var h := 4.6
	var z0 := 0.35
	var z1 := d - 0.35
	Meshes.box(st, Vector3(0.3, 0, z0), Vector3(w - 0.6, h, z1 - z0), stone)
	_roof_at(st, 0.3, w - 0.3, z0, z1, h, 0.45, LEAD, stone)
	_merlons(st, 0.3, w - 0.3, z1 - 0.3, h, stone, true)
	_merlons(st, 0.3, w - 0.3, z0, h, stone, true)
	var bays := w - 1
	for i in range(bays + 1):
		var bx := 0.3 + (w - 0.6) * float(i) / bays
		Meshes.box(st, Vector3(bx - 0.13, 0, z1 - 0.05), Vector3(0.26, h + 0.25, 0.32), stone.darkened(0.05))
		Meshes.box(st, Vector3(bx - 0.06, h + 0.25, z1 + 0.04), Vector3(0.12, 0.55, 0.12), stone.lightened(0.05))
		if i < bays:
			var wx := bx + 0.2
			var ww := (w - 0.6) / bays - 0.4
			_ewin(st, wst, wx, 0.9, z1 + 0.02, ww, 3.2, stone.lightened(0.15))
			for m in range(1, 3):  # mullions and a transom
				Meshes.box(st, Vector3(wx + ww * m / 3.0 - 0.02, 0.9, z1 + 0.03), Vector3(0.04, 3.2, 0.03), stone.lightened(0.15))
			Meshes.box(st, Vector3(wx, 2.4, z1 + 0.03), Vector3(ww, 0.05, 0.03), stone.lightened(0.15))
	for c in [Vector2(0.3, z0), Vector2(w - 0.3, z0), Vector2(0.3, z1), Vector2(w - 0.3, z1)]:
		Meshes.cylinder(st, Vector3(c.x, 0, c.y), 0.38, h + 1.5, 8, stone.lightened(0.06))
		Meshes.cylinder(st, Vector3(c.x, h + 1.5, c.y), 0.34, 0.15, 8, stone.darkened(0.1))
		Meshes.cone(st, Vector3(c.x, h + 1.65, c.y), 0.3, 0.75, 8, stone.lightened(0.1), Meshes._rng(int(c.x * 7 + c.y)))
		Meshes.box(st, Vector3(c.x - 0.05, h + 2.4, c.y - 0.05), Vector3(0.1, 0.18, 0.1), Color("c9a441"))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0, z1 + 0.25), Vector3(0.7, 1.25, 0.12), Color("2e2420"))
		Meshes.box(st, Vector3(door_x + 0.05, 1.25, z1 + 0.25), Vector3(0.9, 0.12, 0.14), stone.lightened(0.15))

## A Greek-temple museum front (the Fitzwilliam): a stone block behind a row of columns and a pediment.
static func _portico(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("ddd3bb")
	var h := 2.6
	var front := d - 0.7
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, front - 0.05), stone)
	Meshes.box(st, Vector3(0.05, h, 0.05), Vector3(w - 0.1, 0.3, front - 0.05), stone.lightened(0.06))
	Meshes.box(st, Vector3(0, 0, front - 0.1), Vector3(w, 0.22, 0.85), stone.darkened(0.15))
	var cols := maxi(4, w - 2)
	var c0 := 0.9
	var c1 := w - 0.9
	for i in cols:
		var cx := c0 + (c1 - c0) * float(i) / (cols - 1)
		Meshes.cylinder(st, Vector3(cx, 0.22, d - 0.3), 0.14, h - 0.22, 8, stone.lightened(0.08))
	Meshes.box(st, Vector3(0.5, h, front - 0.1), Vector3(w - 1.0, 0.3, 0.8), stone.lightened(0.04))
	var py := h + 0.3
	var pz := d - 0.25
	Meshes._tri(st, Vector3(0.5, py, pz), Vector3(w * 0.5, py + 0.9, pz), Vector3(w - 0.5, py, pz), stone.lightened(0.1))
	Meshes._quad(st, Vector3(w * 0.5, py + 0.9, pz), Vector3(w * 0.5, py + 0.9, 0.2), Vector3(w - 0.5, py, 0.2), Vector3(w - 0.5, py, pz), LEAD)
	Meshes._quad(st, Vector3(0.5, py, pz), Vector3(0.5, py, 0.2), Vector3(w * 0.5, py + 0.9, 0.2), Vector3(w * 0.5, py + 0.9, pz), LEAD.darkened(0.12))
	for x in w:
		if x != door_x:
			_ewin(st, wst, x + 0.3, 0.7, front, 0.4, 1.2, stone.lightened(0.2))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0.22, front - 0.04), Vector3(0.7, 1.4, 0.06), Color("2e2420"))

## Ely, the ship of the Fens: a long Romanesque nave, a tall west tower crowned by its own octagon, and over the
## crossing the great stone Octagon with its timber-and-lead lantern.
static func _ely(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("cfc3a2")
	var nave_h := 3.1
	var tw := 2.6
	Meshes.box(st, Vector3(tw, 0, 0.6), Vector3(w - tw, nave_h, d - 1.2), stone)
	_roof_at(st, tw, w, 0.6, d - 0.6, nave_h, 1.1, LEAD, stone)
	# west tower with corner turrets and its octagonal top stage
	var th := 6.4
	Meshes.box(st, Vector3(0, 0, 0.3), Vector3(tw, th, d - 0.6), stone.darkened(0.03))
	for y in [1.6, 3.2, 4.8]:
		Meshes.box(st, Vector3(-0.03, y, 0.27), Vector3(tw + 0.06, 0.08, d - 0.54), stone.lightened(0.08))
	for c in [Vector2(0.2, 0.5), Vector2(tw - 0.2, 0.5), Vector2(0.2, d - 0.5), Vector2(tw - 0.2, d - 0.5)]:
		Meshes.cylinder(st, Vector3(c.x, 0, c.y), 0.32, th + 0.7, 8, stone.lightened(0.05))
		Meshes.cone(st, Vector3(c.x, th + 0.7, c.y), 0.3, 0.5, 8, stone, Meshes._rng(int(c.y * 13)))
	Meshes.cylinder(st, Vector3(tw * 0.5, th, d * 0.5), 0.95, 1.4, 8, stone.lightened(0.04))
	_merlons(st, tw * 0.5 - 0.6, tw * 0.5 + 0.6, d * 0.5 + 0.55, th + 1.25, stone, true)
	for y in [2.2, 3.8, 5.3]:
		_ewin(st, wst, tw * 0.5 - 0.25, y, d - 0.3, 0.5, 0.8, stone.lightened(0.2))
	# the Octagon at the crossing, and its lantern
	var ox := tw + (w - tw) * 0.55
	var oc := Vector3(ox, 0, d * 0.5)
	Meshes.box(st, Vector3(ox - 1.0, 0, 0.0), Vector3(2.0, nave_h + 0.2, d), stone.darkened(0.02))  # transepts
	_roof_at(st, ox - 1.0, ox + 1.0, 0.0, d, nave_h + 0.2, 1.0, LEAD, stone)
	Meshes.cylinder(st, oc, 1.55, nave_h + 2.0, 8, stone.lightened(0.03))
	Meshes.cylinder(st, oc + Vector3(0, nave_h + 2.0, 0), 1.35, 0.3, 8, LEAD)
	Meshes.cylinder(st, oc + Vector3(0, nave_h + 2.3, 0), 0.8, 1.3, 8, LEAD.lightened(0.15))
	for i in 8:
		var a := TAU * i / 8.0
		_ewin(st, wst, ox + cos(a) * 0.75 - 0.12, nave_h + 2.6, d * 0.5 + sin(a) * 0.75, 0.24, 0.5, LEAD.lightened(0.3))
		Meshes.box(st, Vector3(ox + cos(a) * 1.3 - 0.06, nave_h + 2.0, d * 0.5 + sin(a) * 1.3 - 0.06), Vector3(0.12, 0.6, 0.12), stone.lightened(0.1))
	Meshes.cone(st, oc + Vector3(0, nave_h + 3.6, 0), 0.72, 0.7, 8, LEAD, Meshes._rng(77))
	# the nave's two tiers of round-headed windows
	for x in range(ceili(tw) + 1, w):
		if absf(x + 0.5 - ox) < 1.3:
			continue
		_ewin(st, wst, x + 0.32, 0.55, d - 0.6, 0.36, 0.9, stone.lightened(0.2))
		_ewin(st, wst, x + 0.35, 2.0, d - 0.6, 0.3, 0.6, stone.lightened(0.2))
		Meshes.box(st, Vector3(x - 0.06, 0, d - 0.65), Vector3(0.14, nave_h, 0.18), stone.darkened(0.06))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.1, 0, d - 0.7), Vector3(1.2, 1.7, 0.7), stone.lightened(0.05))
		Meshes.box(st, Vector3(door_x + 0.15, 0, d - 0.02), Vector3(0.7, 1.3, 0.06), Color("2e2420"))

## Norwich Cathedral: a long, pale Norman nave, and a slim spire over the crossing that tops everything in town.
static func _norwich_cathedral(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := CAEN
	var nave_h := 3.2
	Meshes.box(st, Vector3(0.1, 0, 0.6), Vector3(w - 0.2, nave_h, d - 1.2), stone)
	_roof_at(st, 0.1, w - 0.1, 0.6, d - 0.6, nave_h, 1.0, LEAD, stone)
	# west front with a big window and flanking turrets
	Meshes.box(st, Vector3(0, 0, 0.4), Vector3(0.5, nave_h + 0.9, d - 0.8), stone.lightened(0.04))
	for zc in [0.6, d - 0.6]:
		Meshes.cylinder(st, Vector3(0.25, 0, zc), 0.25, nave_h + 1.6, 8, stone.lightened(0.06))
		Meshes.cone(st, Vector3(0.25, nave_h + 1.6, zc), 0.24, 0.6, 8, stone, Meshes._rng(int(zc * 31)))
	# transepts and the crossing tower
	var cx := w * 0.58
	Meshes.box(st, Vector3(cx - 1.0, 0, 0.0), Vector3(2.0, nave_h, d), stone.darkened(0.02))
	_roof_at(st, cx - 1.0, cx + 1.0, 0.0, d, nave_h, 0.9, LEAD, stone)
	var t := 1.8
	var th := 6.0
	Meshes.box(st, Vector3(cx - t * 0.5, 0, d * 0.5 - t * 0.5), Vector3(t, th, t), stone.lightened(0.02))
	for y in [4.1, 4.7, 5.3]:  # Norman blind arcading and roundels round the tower
		for i in 4:
			Meshes.box(st, Vector3(cx - t * 0.5 + 0.15 + i * 0.4, y, d * 0.5 + t * 0.5 + 0.01), Vector3(0.2, 0.42, 0.03), stone.darkened(0.18))
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var p := Vector3(cx + c.x * (t * 0.5 - 0.12), th, d * 0.5 + c.y * (t * 0.5 - 0.12))
		Meshes.cylinder(st, p, 0.14, 0.9, 6, stone.lightened(0.05))
		Meshes.cone(st, p + Vector3(0, 0.9, 0), 0.13, 0.5, 6, stone, Meshes._rng(int(c.x * 3 + c.y * 5 + 9)))
	# the spire: a tall, slim octagonal needle with little lucarnes partway up
	var sp := Vector3(cx, th, d * 0.5)
	Meshes.cone(st, sp, 0.82, 7.2, 8, Color("d3c9b0"), Meshes._rng(1096))
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		Meshes.box(st, Vector3(cx + cos(a) * 0.55 - 0.08, th + 1.4, d * 0.5 + sin(a) * 0.55 - 0.08), Vector3(0.16, 0.35, 0.16), stone.lightened(0.05))
	Meshes.box(st, Vector3(cx - 0.03, th + 7.1, d * 0.5 - 0.03), Vector3(0.06, 0.45, 0.06), Color("c9a441"))
	for x in range(1, w - 1):
		if absf(x + 0.5 - cx) < 1.2:
			continue
		_ewin(st, wst, x + 0.33, 0.6, d - 0.6, 0.34, 0.85, stone.lightened(0.2))
		_ewin(st, wst, x + 0.36, 2.0, d - 0.6, 0.28, 0.65, stone.lightened(0.2))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.1, 0, d - 0.7), Vector3(1.2, 1.6, 0.7), stone.lightened(0.05))
		Meshes.box(st, Vector3(door_x + 0.15, 0, d - 0.02), Vector3(0.7, 1.25, 0.06), Color("2e2420"))

## Norwich Castle: a great square Norman keep refaced in pale stone, its walls covered in blind arcades.
static func _norman_keep(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("d9cba6")
	var h := 4.2
	Meshes.box(st, Vector3(0.2, 0, 0.2), Vector3(w - 0.4, h, d - 0.4), stone)
	Meshes.box(st, Vector3(0.1, 0, 0.1), Vector3(w - 0.2, 0.3, d - 0.2), stone.darkened(0.2))
	for c in [Vector2(0.1, 0.1), Vector2(w - 0.6, 0.1), Vector2(0.1, d - 0.6), Vector2(w - 0.6, d - 0.6)]:
		Meshes.box(st, Vector3(c.x, 0, c.y), Vector3(0.5, h + 0.45, 0.5), stone.lightened(0.05))
	_merlons(st, 0.2, w - 0.2, d - 0.5, h, stone, true)
	_merlons(st, 0.2, w - 0.2, 0.2, h, stone, true)
	_merlons(st, 0.2, d - 0.2, 0.2, h, stone, false)
	_merlons(st, 0.2, d - 0.2, w - 0.5, h, stone, false)
	for row in [[1.3, 0.9], [2.45, 0.7], [3.35, 0.55]]:  # three tiers of blind arches on the south face
		var x := 0.75
		while x < w - 0.85:
			Meshes.box(st, Vector3(x, row[0], d - 0.19), Vector3(0.24, row[1], 0.02), stone.darkened(0.2))
			Meshes.box(st, Vector3(x - 0.05, row[0] + row[1], d - 0.18), Vector3(0.34, 0.06, 0.03), stone.lightened(0.1))
			x += 0.45
	for x in [1.0, w - 1.3]:
		_ewin(st, wst, x, 2.45, d - 0.15, 0.3, 0.5, stone.lightened(0.2))
	if door_x >= 0:
		# the Bigod Tower forebuilding over the entrance
		Meshes.box(st, Vector3(door_x - 0.35, 0, d - 0.55), Vector3(1.7, 2.4, 0.55), stone.lightened(0.04))
		_merlons(st, door_x - 0.35, door_x + 1.35, d - 0.55, 2.4, stone, true)
		Meshes.box(st, Vector3(door_x + 0.18, 0, d + 0.01), Vector3(0.64, 1.2, 0.05), Color("2e2420"))
		Meshes.box(st, Vector3(door_x + 0.1, 1.2, d + 0.01), Vector3(0.8, 0.1, 0.06), stone.lightened(0.15))

## Carrow Road: the back of a stand in yellow and green, a cantilevered roof and four floodlight pylons.
static func _football_stand(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var yellow := Color("f2d21c")
	var green := Color("0f6b3c")
	var h := 2.6
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), green)
	for i in 3:
		Meshes.box(st, Vector3(0.02, 0.5 + i * 0.7, d - 0.08), Vector3(w - 0.04, 0.3, 0.05), yellow)
	Meshes.box(st, Vector3(-0.2, h, -0.1), Vector3(w + 0.4, 0.15, d + 0.25), Color("e8e8e4"))
	for c in [Vector2(0.15, 0.15), Vector2(w - 0.3, 0.15), Vector2(0.15, d - 0.3), Vector2(w - 0.3, d - 0.3)]:
		Meshes.box(st, Vector3(c.x, 0, c.y), Vector3(0.14, h + 2.4, 0.14), Color("b8bcc0"))
		Meshes.box(st, Vector3(c.x - 0.25, h + 2.2, c.y - 0.05), Vector3(0.64, 0.42, 0.22), Color("3c4450"))
		Meshes.box(wst, Vector3(c.x - 0.2, h + 2.25, c.y + 0.17), Vector3(0.54, 0.32, 0.02), Color(1, 1, 1, 1))
	# a canary on the crest over the turnstiles
	var bx := w * 0.5
	Meshes.box(st, Vector3(bx - 0.5, h - 0.05, d + 0.0), Vector3(1.0, 0.7, 0.08), green.darkened(0.2))
	Meshes.box(st, Vector3(bx - 0.18, h + 0.1, d + 0.06), Vector3(0.32, 0.22, 0.04), yellow)
	Meshes.box(st, Vector3(bx + 0.1, h + 0.28, d + 0.06), Vector3(0.14, 0.12, 0.04), yellow)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0, d - 0.02), Vector3(0.7, 1.1, 0.06), Color("1e2a24"))
		Meshes.box(st, Vector3(door_x + 0.05, 1.1, d - 0.02), Vector3(0.9, 0.12, 0.07), yellow)

# --- East Anglia props -----------------------------------------------------------

static func ea_prop(name: String, variant: int) -> ArrayMesh:
	match name:
		"windpump":
			return windpump(variant)
		"punt":
			return punt(variant)
		"maths_bridge":
			return maths_bridge(variant)
		"wherry":
			return wherry(variant)
	return Meshes.rock(0)

## A Norfolk drainage mill: a tapering tarred brick tower, a white boat-shaped cap, a fantail and four white
## sails facing south.
static func windpump(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var tower_h := 3.2
	var sides := 8
	var lo := Meshes._ring(Vector3.ZERO, 0.5, 0.0, sides, PI / 8)
	var hi := Meshes._ring(Vector3.ZERO, 0.32, tower_h, sides, PI / 8)
	for i in sides:
		var j := (i + 1) % sides
		Meshes._quad(st, lo[i], lo[j], hi[j], hi[i], TARRED.lightened(0.06 * (i % 2)))
	Meshes.box(st, Vector3(-0.14, 0, 0.42), Vector3(0.28, 0.6, 0.06), Color("f2efe6"))
	for y in [1.2, 2.2]:
		Meshes.box(st, Vector3(-0.08, y, 0.4 - y * 0.05), Vector3(0.16, 0.22, 0.04), Color("f2efe6"))
	Meshes.cylinder(st, Vector3(0, tower_h, 0), 0.42, 0.08, sides, Color("f2efe6"))  # the gallery
	Meshes.box(st, Vector3(-0.3, tower_h + 0.05, -0.38), Vector3(0.6, 0.32, 0.76), Color("f2efe6"))
	Meshes._quad(st, Vector3(-0.3, tower_h + 0.37, 0.38), Vector3(0.3, tower_h + 0.37, 0.38), Vector3(0.3, tower_h + 0.37, -0.38), Vector3(-0.3, tower_h + 0.37, -0.38), Color("f2efe6"))
	Meshes.box(st, Vector3(-0.22, tower_h + 0.37, -0.32), Vector3(0.44, 0.16, 0.64), Color("e6e2d6"))
	# fantail at the back keeps the sails into the wind
	Meshes.box(st, Vector3(-0.02, tower_h + 0.2, -0.95), Vector3(0.04, 0.04, 0.6), Color("e6e2d6"))
	for k in 4:
		var a := TAU * k / 4.0
		_panel(st, Vector3(0, tower_h + 0.22, -0.95), Vector3(cos(a) * 0.32, tower_h + 0.22 + sin(a) * 0.32, -0.95),
				Vector3(cos(a + 0.5) * 0.32, tower_h + 0.22 + sin(a + 0.5) * 0.32, -0.95), Vector3(0, tower_h + 0.22, -0.95), Color("f2efe6"))
	# the sails, an X from a hub on the front of the cap
	var hub := Vector3(0, tower_h + 0.2, 0.48)
	Meshes.box(st, hub + Vector3(-0.07, -0.07, -0.1), Vector3(0.14, 0.14, 0.14), TARRED)
	var turn := 0.25 * PI + variant * 0.3
	for k in 4:
		var a := turn + k * PI * 0.5
		var dir := Vector3(cos(a), sin(a), 0)
		var side := Vector3(-sin(a), cos(a), 0)
		var r0 := hub + dir * 0.18 + Vector3(0, 0, 0.06)
		var r1 := hub + dir * 1.75 + Vector3(0, 0, 0.06)
		_panel(st, r0 - side * 0.03, r1 - side * 0.03, r1 + side * 0.03, r0 + side * 0.03, Color("f2efe6"))  # the stock
		_panel(st, r0 + dir * 0.15 + side * 0.03, r1 + side * 0.03, r1 + side * 0.36, r0 + dir * 0.15 + side * 0.36, Color("e9e4d6"))
		for s in 5:  # shutters
			var p := r0 + dir * (0.3 + s * 0.28) + Vector3(0, 0, 0.01)
			_panel(st, p + side * 0.03, p + dir * 0.04 + side * 0.03, p + dir * 0.04 + side * 0.36, p + side * 0.36, Color("b9b4a8"))
	return Meshes._finish(st)

## A Cambridge punt: long, flat and varnished, with cushions, a till at the back to stand on, and a pole.
static func punt(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var wood := Color("8a5a32")
	Meshes.box(st, Vector3(-0.38, -0.12, -1.2), Vector3(0.76, 0.3, 2.4), wood, wood.darkened(0.35))
	Meshes.box(st, Vector3(-0.36, 0.14, 0.8), Vector3(0.72, 0.04, 0.4), wood.lightened(0.15))  # the till
	var cushion: Color = [Color("b8322a"), Color("2f5a8a"), Color("3d7a4a")][posmod(variant, 3)]
	Meshes.box(st, Vector3(-0.3, 0.1, -0.9), Vector3(0.6, 0.12, 0.5), cushion)
	Meshes.box(st, Vector3(-0.3, 0.1, -0.2), Vector3(0.6, 0.12, 0.5), cushion.darkened(0.1))
	_strut(st, Vector3(0.25, 0.1, 1.05), Vector3(0.45, 2.6, 0.7), 0.04, Color("c9b48a"))
	return Meshes._finish(st)

## The Mathematical Bridge at Queens': a timber arch made only of straight beams, laid on lines that just touch
## the curve. `variant` is its length in tiles, running east from its tile.
static func maths_bridge(variant := 4) -> ArrayMesh:
	var st := Meshes._st()
	var n := maxi(2, variant)
	var x0 := -0.5
	var x1 := n - 0.5
	var oak := Color("8c7a62")
	var segs := 8
	var deck := []
	for i in segs + 1:
		var t := float(i) / segs
		deck.append(Vector3(lerpf(x0, x1, t), 0.15 + 0.55 * sin(PI * t), 0))
	for i in segs:
		var a: Vector3 = deck[i]
		var b: Vector3 = deck[i + 1]
		Meshes._quad(st, a + Vector3(0, 0.02, -0.42), b + Vector3(0, 0.02, -0.42), b + Vector3(0, 0.02, 0.42), a + Vector3(0, 0.02, 0.42), oak.lightened(0.12))
		Meshes._quad(st, a + Vector3(0, -0.08, 0.42), b + Vector3(0, -0.08, 0.42), b + Vector3(0, -0.08, -0.42), a + Vector3(0, -0.08, -0.42), oak.darkened(0.3))
	for z in [-0.42, 0.42]:
		var off := Vector3(0, 0, z)
		for i in segs:  # top rail, and the arch rib below the deck
			_strut(st, deck[i] + off + Vector3(0, 0.62, 0), deck[i + 1] + off + Vector3(0, 0.62, 0), 0.06, oak)
			_strut(st, deck[i] + off + Vector3(0, -0.2, 0), deck[i + 1] + off + Vector3(0, -0.2, 0), 0.08, oak.darkened(0.15))
		for i in range(0, segs + 1, 2):  # radial posts
			_strut(st, deck[i] + off + Vector3(0, -0.2, 0), deck[i] + off + Vector3(0, 0.62, 0), 0.05, oak.darkened(0.1))
		for i in range(1, segs - 1):  # the tangent beams, crossing each other in the famous lattice
			_strut(st, deck[i] + off + Vector3(0, -0.15, 0), deck[i + 2] + off + Vector3(0, 0.55, 0), 0.04, oak.lightened(0.05))
			_strut(st, deck[i + 2] + off + Vector3(0, -0.15, 0), deck[i] + off + Vector3(0, 0.55, 0), 0.04, oak.lightened(0.05))
	for xe in [x0, x1]:  # brick abutments
		Meshes.box(st, Vector3(xe - 0.3, -0.6, -0.55), Vector3(0.6, 0.8, 1.1), DARK_BRICK)
	return Meshes._finish(st)

## A Norfolk wherry: a black-tarred hull with a single huge black gaff sail and a white-tipped mast.
static func wherry(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var hull := TARRED
	Meshes.box(st, Vector3(-0.45, -0.2, -1.8), Vector3(0.9, 0.55, 3.6), hull, Color("8a6a46"))
	Meshes.box(st, Vector3(-0.35, 0.35, -0.6), Vector3(0.7, 0.3, 1.8), Color("5a4632"))  # hatch covers
	Meshes.box(st, Vector3(-0.06, 0.35, -1.2), Vector3(0.12, 3.6, 0.12), TARRED)
	Meshes.box(st, Vector3(-0.07, 3.8, -1.21), Vector3(0.14, 0.2, 0.14), Color("f2efe6"))
	var sail := Color("1d1c1c") if variant == 0 else Color("4a2a20")
	_panel(st, Vector3(0, 3.7, -1.15), Vector3(0, 3.1, 1.3), Vector3(0, 0.75, 1.5), Vector3(0, 0.75, -1.1), sail)
	return Meshes._finish(st)
# --- the South East: Sussex and Kent (wave 21) ------------------------------------

const CLAY_TILE := Color("86463a")    # Kent and Sussex peg tiles
const WEATHERBOARD := Color("eeeae0")
const SE_FLINT := Color("6c6d72")
const STUCCO := Color("efe4c8")       # Brighton's cream Regency stucco
const SE_CAEN := Color("d6cba8")         # Canterbury's pale Caen stone
const RAGSTONE := Color("a8a596")     # Kentish ragstone

static func _south_east(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, style: String) -> void:
	match style:
		"oast_house":
			_oast(st, wst, w, d, door_x, rng)
		"weatherboard":
			_house(st, wst, w, d, door_x, rng, WEATHERBOARD, CLAY_TILE, 2, false, false)
			_boards(st, w, d, 0.3, 2.4)
		"flint_cottage":
			_se_flint(st, wst, w, d, door_x, rng)
		"regency":
			_regency(st, wst, w, d, door_x)
		"pavilion":
			_pavilion(st, wst, w, d, door_x)
		"i360":
			_i360(st, wst, w, d, door_x)
		"palace_pier":
			_palace_pier_pavilion(st, wst, w, d, door_x)
		"canterbury_cathedral":
			_canterbury(st, wst, w, d, door_x)
		"westgate":
			_westgate(st, wst, w, d, door_x)
		"windmill_black":
			_windmill(st, w, d, true)
		"windmill_white":
			_windmill(st, w, d, false)

## Weatherboarding: thin shadow lines across the south face, from y0 to y1.
static func _boards(st: SurfaceTool, w: int, d: int, y0: float, y1: float) -> void:
	var y := y0
	while y < y1:
		Meshes.box(st, Vector3(0.06, y, d - 0.06), Vector3(w - 0.12, 0.03, 0.025), WEATHERBOARD.darkened(0.18))
		y += 0.2

## An onion dome: a bulb of stacked rings that swells and then draws in to a point, with a gilt finial.
static func _onion(st: SurfaceTool, c: Vector3, r: float, h: float, col: Color) -> void:
	var prof := [[0.0, 0.85], [0.12, 1.1], [0.3, 1.2], [0.5, 1.05], [0.68, 0.7], [0.84, 0.32], [0.95, 0.1]]
	var sides := 10
	var rings := []
	for p in prof:
		rings.append(Meshes._ring(c + Vector3(0, h * float(p[0]), 0), r * float(p[1]), c.y + h * float(p[0]), sides))
	for k in range(prof.size() - 1):
		var shade := col.lightened(0.06 - 0.03 * k)
		for i in sides:
			var j := (i + 1) % sides
			Meshes._quad(st, rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i], shade.darkened(0.06 * (i % 2)))
	var tip := c + Vector3(0, h, 0)
	var top: Array = rings[prof.size() - 1]
	for i in sides:
		Meshes._tri(st, top[i], top[(i + 1) % sides], tip, col.lightened(0.1))
	Meshes.box(st, tip + Vector3(-0.03, 0, -0.03), Vector3(0.06, h * 0.28, 0.06), Color("d8b048"))
	Meshes.box(st, tip + Vector3(-0.07, h * 0.12, -0.07), Vector3(0.14, 0.08, 0.14), Color("e8c050"))

## A Kentish oast: a brick ground floor and weatherboarded stowage under a peg-tile roof, with one or two round
## brick kilns at the east end, each under a steep cone topped by the white wooden cowl and its wind vane.
static func _oast(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var kilns := 2 if w >= 6 else 1
	var kr := minf(0.95, d * 0.42)
	var barn_w := float(w) - kilns * (kr * 2.0 + 0.1)
	var hgt := 2.2
	Meshes.box(st, Vector3(0.05, 0, 0.1), Vector3(barn_w, 1.0, d - 0.2), BRICK)
	Meshes.box(st, Vector3(0.0, 1.0, 0.05), Vector3(barn_w + 0.05, hgt - 1.0, d - 0.1), WEATHERBOARD)
	var y := 1.05
	while y < hgt:
		Meshes.box(st, Vector3(0.0, y, d - 0.07), Vector3(barn_w + 0.05, 0.03, 0.03), WEATHERBOARD.darkened(0.18))
		y += 0.2
	_roof_at(st, -0.1, barn_w + 0.1, -0.1, d + 0.1, hgt, minf(1.1, d * 0.4), CLAY_TILE, WEATHERBOARD)
	# the hop loft's loading door, up under the eaves
	Meshes.box(st, Vector3(barn_w * 0.5 - 0.3, 1.25, d - 0.02), Vector3(0.6, 0.7, 0.06), Color("6a4a32"))
	if door_x >= 0:
		_door(st, door_x, d - 0.05, BRICK)
	for x in range(int(barn_w)):
		if x != door_x:
			_window(st, wst, x + 0.3, 0.35, d - 0.06, 0.4, 0.45, BRICK.lightened(0.25))
	for k in kilns:
		var c := Vector3(barn_w + 0.05 + kr + k * (kr * 2.0 + 0.1), 0, d * 0.5)
		Meshes.cylinder(st, c, kr, 2.3, 12, BRICK.lightened(0.04))
		Meshes.cylinder(st, c + Vector3(0, 2.3, 0), kr * 0.9, 0.12, 12, BRICK.darkened(0.2))
		Meshes.cone(st, c + Vector3(0, 2.4, 0), kr * 0.92, 1.9, 12, CLAY_TILE.darkened(0.05), rng)
		# the cowl: a white hood that turns its back to the wind, its fan board pointing downwind
		var top := c + Vector3(0, 4.05, 0)
		Meshes.box(st, top + Vector3(-0.2, 0, -0.2), Vector3(0.4, 0.42, 0.4), Color("f4f1ea"))
		Meshes._quad(st, top + Vector3(-0.22, 0.42, -0.22), top + Vector3(0.22, 0.42, -0.22), top + Vector3(0.12, 0.62, 0.0), top + Vector3(-0.12, 0.62, 0.0), Color("f4f1ea"))
		Meshes._quad(st, top + Vector3(0.22, 0.42, 0.22), top + Vector3(-0.22, 0.42, 0.22), top + Vector3(-0.12, 0.62, 0.0), top + Vector3(0.12, 0.62, 0.0), Color("e2ddd2"))
		Meshes.box(st, top + Vector3(0.2, 0.18, -0.02), Vector3(0.45, 0.26, 0.04), Color("f4f1ea"))
		Meshes.box(st, top + Vector3(-0.02, 0.62, -0.02), Vector3(0.04, 0.22, 0.04), Color("2a2a30"))

## A Sussex cottage faced in knapped flint, with red brick quoins and window dressings, under a peg-tile roof.
static func _se_flint(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var storeys := 2 if w >= 4 else 1
	_house(st, wst, w, d, door_x, rng, SE_FLINT, CLAY_TILE, storeys, false, false)
	var hgt := 1.15 * storeys + 0.2
	for x in [0.0, w - 0.2]:
		for i in int(hgt / 0.3):
			var long := i % 2 == 0
			Meshes.box(st, Vector3(x - (0.0 if x == 0.0 else (0.12 if long else 0.0)), 0.16 + i * 0.3, d - 0.08), Vector3(0.32 if long else 0.2, 0.28, 0.05), BRICK)
	# knobbly flints catching the light
	for i in w * 10:
		var fx := rng.randf_range(0.25, w - 0.35)
		var fy := rng.randf_range(0.25, hgt - 0.15)
		var g := rng.randf_range(-0.15, 0.25)
		Meshes.box(st, Vector3(fx, fy, d - 0.065), Vector3(0.09, 0.07, 0.02), SE_FLINT.lightened(g) if g > 0 else SE_FLINT.darkened(-g))
	# brick bands under each storey's windows
	for s in storeys:
		Meshes.box(st, Vector3(0.05, 0.28 + 1.15 * s, d - 0.075), Vector3(w - 0.1, 0.07, 0.04), BRICK)

## A Brighton Regency terrace: three storeys of cream stucco with bow fronts, black iron balconies on the first
## floor, and a parapet hiding a shallow slate roof.
static func _regency(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var hgt := 3.5
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), STUCCO)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.2, d), STUCCO.darkened(0.2))
	Meshes.box(st, Vector3(0, hgt, 0), Vector3(w, 0.25, d), STUCCO.lightened(0.04))
	_roof_at(st, 0.2, w - 0.2, 0.2, d - 0.2, hgt + 0.1, 0.4, SLATE, STUCCO)
	Meshes.box(st, Vector3(0, hgt - 0.12, d - 0.1), Vector3(w, 0.12, 0.2), STUCCO.lightened(0.08))  # cornice
	# bow fronts, one per two tiles, round bays that run up all three storeys
	var x := 1.0
	while x < w - 0.5:
		Meshes.cylinder(st, Vector3(x, 0, d - 0.15), 0.62, hgt - 0.15, 10, STUCCO.lightened(0.03))
		x += 2.0
	for s in 3:
		var wy := 0.4 + 1.1 * s
		for i in w:
			if i == door_x and s == 0:
				continue
			_window(st, wst, i + 0.3, wy, d + 0.3, 0.4, 0.62 if s < 2 else 0.5, Color("f6f0e0"))
	# the first-floor balcony, black iron the length of the terrace
	Meshes.box(st, Vector3(0, 1.32, d - 0.05), Vector3(w, 0.05, 0.6), Color("2a2c30"))
	Meshes.box(st, Vector3(0, 1.62, d + 0.5), Vector3(w, 0.04, 0.04), Color("2a2c30"))
	for i in range(0, w * 4 + 1):
		Meshes.box(st, Vector3(i * 0.25, 1.35, d + 0.5), Vector3(0.02, 0.28, 0.02), Color("2a2c30"))
	if door_x >= 0:
		_door(st, door_x, d + 0.05, STUCCO)
		Meshes.box(st, Vector3(door_x + 0.1, 0.0, d + 0.0), Vector3(0.08, 1.1, 0.12), Color("f8f4ea"))
		Meshes.box(st, Vector3(door_x + 0.82, 0.0, d + 0.0), Vector3(0.08, 1.1, 0.12), Color("f8f4ea"))

## The Royal Pavilion: a long cream front with a colonnade, a great onion dome over the central saloon, smaller
## domes over the wings, tented roofs and a crowd of slim minarets.
static func _pavilion(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("efe6cf")
	var h := 1.8
	Meshes.box(st, Vector3(0.05, 0, 0.3), Vector3(w - 0.1, h, d - 0.6), stone)
	Meshes.box(st, Vector3(0, h, 0.25), Vector3(w, 0.12, d - 0.5), stone.lightened(0.05))
	# the colonnade along the garden front, with its little pierced parapet
	Meshes.box(st, Vector3(0, 0, d - 0.35), Vector3(w, 0.12, 0.35), stone.darkened(0.12))
	var cx := 0.2
	while cx < w:
		Meshes.box(st, Vector3(cx, 0.1, d - 0.12), Vector3(0.12, 1.2, 0.12), stone.lightened(0.04))
		cx += 0.7
	Meshes.box(st, Vector3(0, 1.3, d - 0.35), Vector3(w, 0.12, 0.4), stone)
	for i in range(0, w * 3):
		Meshes.box(st, Vector3(i / 3.0 + 0.08, 1.42, d - 0.06), Vector3(0.18, 0.14, 0.04), stone.darkened(0.08))
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.3, 0.3, d - 0.3, 0.4, 0.85, stone.lightened(0.15))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0.1, d - 0.32), Vector3(0.7, 1.05, 0.06), Color("3b2a22"))
	var mid := w * 0.5
	var cz := d * 0.5
	# the saloon's drum and the great dome
	Meshes.cylinder(st, Vector3(mid, h, cz), 1.15, 0.9, 12, stone.lightened(0.02))
	_onion(st, Vector3(mid, h + 0.85, cz), 1.05, 2.4, Color("f4ecd8"))
	# wing domes and tented roofs
	for k in [-1, 1]:
		var wx: float = mid + k * w * 0.3
		Meshes.cylinder(st, Vector3(wx, h, cz), 0.62, 0.55, 10, stone)
		_onion(st, Vector3(wx, h + 0.5, cz), 0.6, 1.5, Color("f4ecd8"))
		var tx: float = mid + k * w * 0.15
		Meshes.cone(st, Vector3(tx, h + 0.1, cz), 0.7, 1.0, 8, Color("e6dcc2"), Meshes._rng(77 + k))
	# minarets: slim columns with tiny onion caps
	for k in [0.0, 0.18, 0.4, 0.6, 0.82, 1.0]:
		var mx := clampf(w * k, 0.25, w - 0.25)
		for zz in [0.35, d - 0.45]:
			Meshes.cylinder(st, Vector3(mx, h, zz), 0.1, 1.1, 6, stone.lightened(0.06))
			_onion(st, Vector3(mx, h + 1.08, zz), 0.13, 0.42, Color("f4ecd8"))

## The British Airways i360: a slender white mast with a ring-shaped glass viewing pod partway up, standing on
## a low glassy pavilion.
static func _i360(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var c := Vector3(w * 0.5, 0, d * 0.5)
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, 0.9, d - 0.1), Color("dfe6ea"))
	Meshes.box(st, Vector3(0, 0.9, 0), Vector3(w, 0.1, d), Color("f4f6f8"))
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.12, 0.15, d, 0.76, 0.6, Color("c8d2d8"))
	_door(st, door_x, d, Color("dfe6ea"), 0.7)
	Meshes.cylinder(st, c + Vector3(0, 0.9, 0), 0.32, 11.0, 12, Color("f2f4f6"))
	Meshes.cylinder(st, c + Vector3(0, 11.9, 0), 0.28, 0.25, 12, Color("c9d0d6"))
	# the pod: a doughnut of glass round the mast, with a white rim above and below
	var py := 4.2
	Meshes.cylinder(st, c + Vector3(0, py, 0), 1.25, 0.08, 16, Color("e8ecef"))
	Meshes.cylinder(st, c + Vector3(0, py + 0.08, 0), 1.2, 0.55, 16, Color("8fb8cc"))
	Meshes.cylinder(st, c + Vector3(0, py + 0.6, 0), 1.08, 0.08, 16, Color("e8ecef"))
	for i in 8:
		var a := TAU * i / 8.0
		Meshes.box(wst, c + Vector3(cos(a) * 1.08 - 0.12, py + 0.15, sin(a) * 1.08 - 0.12), Vector3(0.24, 0.38, 0.24), window_colour(_wr))

## The Palace Pier's end-of-pier pavilion: white boarding, a run of arcade windows and a row of little domes.
static func _palace_pier_pavilion(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var white := Color("f4f1ea")
	var h := 1.5
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), white)
	Meshes.box(st, Vector3(0, h, 0), Vector3(w, 0.14, d), Color("2f5a8a"))
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.2, 0.3, d, 0.6, 0.8, Color("2f5a8a"))
	_door(st, door_x, d, white, 1.0)
	for k in range(w):
		var c := Vector3(k + 0.5, h + 0.14, d * 0.5)
		Meshes.cylinder(st, c, 0.3, 0.25, 8, white)
		_onion(st, c + Vector3(0, 0.25, 0), 0.28, 0.6, Color("f6f2e8") if k % 2 == 0 else Color("d84a3a"))
	# the strings of bulbs along the eaves
	for i in w * 4:
		Meshes.box(wst, Vector3(i * 0.25 + 0.08, h - 0.08, d + 0.02), Vector3(0.07, 0.07, 0.04), Color(1, 0.95, 0.7, 1))

## Canterbury Cathedral: a long pale nave, the two pinnacled west towers, and Bell Harry, the great central tower.
static func _canterbury(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := SE_CAEN
	var lead := Color("6f747a")
	var nave_h := 2.8
	Meshes.box(st, Vector3(2.0, 0, 0.4), Vector3(w - 2.4, nave_h, d - 0.8), stone)
	_roof_at(st, 2.0, w - 0.4, 0.4, d - 0.4, nave_h, 1.2, lead, stone)
	# aisles with buttresses and tall lancets
	Meshes.box(st, Vector3(2.0, 0, d - 0.9), Vector3(w - 2.4, 1.6, 0.6), stone.darkened(0.04))
	for x in range(2, w - 1):
		Meshes.box(st, Vector3(x + 0.85, 0, d - 0.4), Vector3(0.18, 1.8, 0.35), stone.darkened(0.08))
		Meshes.box(st, Vector3(x + 0.88, 1.8, d - 0.38), Vector3(0.12, 0.35, 0.12), stone.lightened(0.06))
		_window(st, wst, x + 0.3, 0.35, d - 0.32, 0.36, 1.05, stone.lightened(0.15))
		_window(st, wst, x + 0.35, 1.85, d - 0.82, 0.3, 0.7, stone.lightened(0.15))
	# the two west towers
	var th := 5.4
	for tz in [0.0, d - 1.6]:
		Meshes.box(st, Vector3(0, 0, tz), Vector3(2.0, th, 1.6), stone.darkened(0.03))
		for c in [Vector2(0, tz), Vector2(1.7, tz), Vector2(0, tz + 1.3), Vector2(1.7, tz + 1.3)]:
			Meshes.box(st, Vector3(c.x, th, c.y), Vector3(0.3, 0.9, 0.3), stone.lightened(0.06))
		_merlons(st, 0, 2.0, tz + 1.0, th, stone, true)
		_window(st, wst, 0.75, 3.6, tz + 1.62, 0.5, 1.0, stone.lightened(0.2))
	Meshes.box(st, Vector3(0, 0, 1.5), Vector3(2.0, 3.2, d - 3.0), stone.darkened(0.03))
	_window(st, wst, 0.6, 1.2, d - 1.58, 0.8, 1.6, stone.lightened(0.2))
	# Bell Harry, over the crossing
	var bx := w * 0.55
	var bh := 7.4
	Meshes.box(st, Vector3(bx - 1.0, 0, d * 0.5 - 1.0), Vector3(2.0, bh, 2.0), stone.lightened(0.03))
	for c in [Vector2(-1.0, -1.0), Vector2(0.75, -1.0), Vector2(-1.0, 0.75), Vector2(0.75, 0.75)]:
		Meshes.box(st, Vector3(bx + c.x, bh, d * 0.5 + c.y), Vector3(0.25, 1.1, 0.25), stone.lightened(0.08))
	_merlons(st, bx - 1.0, bx + 1.0, d * 0.5 + 0.4, bh, stone, true)
	for k in 2:
		_window(st, wst, bx - 0.75 + k * 0.9, 4.6, d * 0.5 + 1.02, 0.5, 1.6, stone.lightened(0.2))
	# transepts reaching out to the south
	Meshes.box(st, Vector3(bx - 0.9, 0, d - 0.9), Vector3(1.8, 2.6, 0.9), stone)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.1, 0, d - 0.3), Vector3(0.8, 1.3, 0.08), Color("3b2a22"))
		Meshes.box(st, Vector3(door_x - 0.1, 0, d - 0.42), Vector3(1.2, 1.7, 0.1), stone.lightened(0.08))

## The Westgate: two round drum towers of Kentish ragstone either side of the gate arch, battlemented on top.
static func _westgate(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := RAGSTONE
	var r := minf(1.05, d * 0.42)
	var h := 3.4
	Meshes.box(st, Vector3(r, 0, 0.3), Vector3(w - 2.0 * r, h - 0.4, d - 0.5), stone.darkened(0.04))
	_merlons(st, r, w - r, d - 0.8, h - 0.4, stone, true)
	for x in [r, w - r]:
		var c := Vector3(x, 0, d - r)
		Meshes.cylinder(st, c, r, h, 12, stone)
		Meshes.cylinder(st, c + Vector3(0, h, 0), r * 0.9, 0.12, 12, stone.lightened(0.05))
		for i in 8:
			var a := TAU * i / 8.0
			Meshes.box(st, c + Vector3(cos(a) * r * 0.78 - 0.13, h + 0.1, sin(a) * r * 0.78 - 0.13), Vector3(0.26, 0.3, 0.26), stone.lightened(0.05))
		_window(st, wst, x - 0.12, 1.8, d + 0.02, 0.24, 0.5, stone.darkened(0.25))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.08, 0, d - 0.2), Vector3(0.84, 1.5, 0.06), Color("231c18"))
		Meshes.box(st, Vector3(door_x - 0.05, 1.5, d - 0.22), Vector3(1.1, 0.18, 0.1), stone.lightened(0.1))

## The burnt-out West Pier: a rusting iron skeleton standing in the sea (a point prop centred on its tile,
## spreading about five tiles east-west and three north-south).
static func pier_ruin() -> ArrayMesh:
	var st := Meshes._st()
	var rust := Color("5a3a2c")
	var rust2 := Color("7a4a32")
	for ix in 6:
		for iz in 3:
			var x := -2.4 + ix * 0.96
			var z := -1.0 + iz * 1.0
			Meshes.box(st, Vector3(x - 0.05, -0.6, z - 0.05), Vector3(0.1, 2.2 - 0.25 * absf(ix - 2.5), 0.1), rust)
	for iz in 3:
		Meshes.box(st, Vector3(-2.45, 1.0, -1.03 + iz), Vector3(4.9, 0.08, 0.06), rust2)
	for ix in 6:
		Meshes.box(st, Vector3(-2.43 + ix * 0.96, 1.25, -1.0), Vector3(0.06, 0.06, 2.0), rust2)
	# the ribs of the old concert hall, a dome of bare iron arches
	for k in 5:
		var a0 := PI * k / 4.0
		var a1 := PI * (k + 1) / 4.0
		for side in [-0.6, 0.0, 0.6]:
			var p0 := Vector3(-0.2 + cos(a0) * 1.4, 1.05 + sin(a0) * 1.1, side)
			var p1 := Vector3(-0.2 + cos(a1) * 1.4, 1.05 + sin(a1) * 1.1, side)
			if k < 4:
				Meshes.box(st, Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), side - 0.03), Vector3(maxf(absf(p1.x - p0.x), 0.06), maxf(absf(p1.y - p0.y), 0.06), 0.06), rust)
	return Meshes._finish(st)

## Jack and Jill: a black tower mill (a tapering tower, only its cap turns) or a white post mill (the whole
## weatherboarded body stands on a post), each with four sails facing south.
static func _windmill(st: SurfaceTool, w: int, d: int, tower: bool) -> void:
	var c := Vector3(w * 0.5, 0, d * 0.5)
	var body := Color("2c2a2a") if tower else Color("f2efe6")
	var hub_y := 2.7
	if tower:
		Meshes.cylinder(st, c, 0.85, 2.6, 10, body)
		Meshes.cone(st, c + Vector3(0, 2.55, 0), 0.75, 0.6, 10, Color("e8e4da"), Meshes._rng(5))
	else:
		Meshes.box(st, c + Vector3(-0.08, 0, -0.08), Vector3(0.16, 1.0, 0.16), Color("5a4a3a"))
		Meshes.box(st, c + Vector3(-0.6, 0, -0.6), Vector3(1.2, 0.5, 1.2), Color("8a7a6a"))
		Meshes.box(st, c + Vector3(-0.55, 1.0, -0.7), Vector3(1.1, 1.6, 1.4), body)
		Meshes.box(st, c + Vector3(-0.6, 2.6, -0.75), Vector3(1.2, 0.25, 1.5), body.darkened(0.12))
		Meshes.box(st, c + Vector3(-0.04, 0.6, 0.6), Vector3(0.08, 0.08, 1.1), Color("6a5a48"))  # tail pole
		hub_y = 2.2
	var hub := c + Vector3(0, hub_y, 0.88 if tower else 0.75)
	Meshes.box(st, hub + Vector3(-0.1, -0.1, 0), Vector3(0.2, 0.2, 0.15), Color("3a3430"))
	var sail := Color("e8e2d2")
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * k
		var dir := Vector3(cos(a), sin(a), 0)
		var side := Vector3(-sin(a), cos(a), 0) * 0.16
		var p0 := hub + dir * 0.15 + Vector3(0, 0, 0.16)
		var p1 := hub + dir * 1.55 + Vector3(0, 0, 0.16)
		Meshes._quad(st, p0 - side, p1 - side, p1 + side, p0 + side, sail)
		Meshes._quad(st, p0 + side, p1 + side, p1 - side, p0 - side, sail.darkened(0.2))
# --- the Humber and Lincoln ----------------------------------------------------

const HUMBER_PANTILE := Color("b4532e")          # the red clay pantiles of East Yorkshire and Lincolnshire roofs
const CHALK := Color("e6e0cf")            # Wolds chalk, limewashed
const LINCS_LIMESTONE := Color("d4c497")  # Lincolnshire limestone, honey-pale

## A rod from a to b with a square section that stays upright (for cables that run nearly level).
static func _humber_rod(st: SurfaceTool, a: Vector3, b: Vector3, t: float, col: Color) -> void:
	var h := t * 0.5
	var lo := [a + Vector3(-h, -h, 0), a + Vector3(h, -h, 0), a + Vector3(h, h, 0), a + Vector3(-h, h, 0)]
	var hi := [b + Vector3(-h, -h, 0), b + Vector3(h, -h, 0), b + Vector3(h, h, 0), b + Vector3(-h, h, 0)]
	for i in 4:
		var j := (i + 1) % 4
		Meshes._quad(st, lo[i], lo[j], hi[j], hi[i], col.darkened(0.08 * (i % 2)))
		Meshes._quad(st, lo[i], hi[i], hi[j], lo[j], col.darkened(0.08 * (i % 2)))

## The Humber Bridge (1981): the deck runs north-south across the plot, out over the estuary; two tall concrete
## towers, each a pair of legs tied by crossbeams, and the main cables sagging between their tops on fine
## hangers, then dropping to the deck at each end.
static func _humber_bridge(st: SurfaceTool, w: int, d: int) -> void:
	var conc := Color("cdcac0")
	var cable := Color("eceae4")
	var deck_y := 1.2
	var cx := w * 0.5
	var dw := minf(w - 0.6, 1.6)
	Meshes.box(st, Vector3(cx - dw * 0.5, deck_y, 0), Vector3(dw, 0.24, d), Color("bdbcb6"), Color("5e6064"))
	Meshes.box(st, Vector3(cx - 0.04, deck_y + 0.245, 0), Vector3(0.08, 0.01, d), Color("e8e2b0"))  # the white line
	var th := 7.2
	var tz := [1.4, d - 1.4]
	var legs := [cx - dw * 0.5 - 0.2, cx + dw * 0.5 - 0.08]
	for z in tz:
		for lx in legs:
			Meshes.box(st, Vector3(lx, -0.8, z - 0.22), Vector3(0.28, th + 0.8, 0.44), conc)
		for y in [deck_y - 0.25, th * 0.5, th - 0.3]:
			Meshes.box(st, Vector3(legs[0], y, z - 0.17), Vector3(legs[1] - legs[0] + 0.28, 0.3, 0.34), conc.darkened(0.06))
	for lx in legs:
		var x: float = lx + 0.14
		var segs := 12
		var prev := Vector3(x, th - 0.1, tz[0])
		for i in range(1, segs + 1):
			var u := float(i) / segs
			var sag := 4.0 * u * (1.0 - u)
			var p := Vector3(x, th - 0.1 - sag * (th - deck_y - 1.0), lerpf(tz[0], tz[1], u))
			_humber_rod(st, prev, p, 0.08, cable)
			if i < segs:
				Meshes.box(st, Vector3(x - 0.015, deck_y + 0.24, p.z - 0.015), Vector3(0.03, p.y - deck_y - 0.24, 0.03), cable.darkened(0.15))
			prev = p
		_humber_rod(st, Vector3(x, th - 0.1, tz[0]), Vector3(x, deck_y + 0.3, 0.0), 0.08, cable)
		_humber_rod(st, Vector3(x, th - 0.1, tz[1]), Vector3(x, deck_y + 0.3, float(d)), 0.08, cable)
	# piers under the deck between the towers and the shore
	for z in [0.4, d - 0.4]:
		Meshes.box(st, Vector3(cx - 0.3, -0.8, z - 0.2), Vector3(0.6, deck_y + 0.8, 0.4), conc.darkened(0.1))

## One wall of an extruded outline: quads from each point to the next, between heights from `lo` and `hi`.
## `pts` run clockwise seen from above with north up (x east, z south); faces point outward.
static func _walls(st: SurfaceTool, pts: Array, lo: Array, hi: Array, col: Color) -> void:
	for i in pts.size():
		var j := (i + 1) % pts.size()
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[j]
		var shade := 0.12 * absf(q.x - p.x) / maxf(0.01, (q - p).length())
		Meshes._quad(st, Vector3(q.x, hi[j], q.y), Vector3(p.x, hi[i], p.y), Vector3(p.x, lo[i], p.y), Vector3(q.x, lo[j], q.y),
			col.darkened(0.12 - shade))

## The Deep (2002): a grey, shard-like aquarium whose prow juts up and out over the Humber at the east end,
## its flanks in slanting bands of aluminium and glass.
static func _the_deep(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var clad := Color("a2aab0")
	var dark := Color("566068")
	# outline seen from above, clockwise from the north-west corner
	var pts := [Vector2(0.1, 0.7), Vector2(w - 1.8, 0.1), Vector2(w + 0.25, d * 0.55), Vector2(w - 1.1, d - 0.05), Vector2(0.1, d - 0.05)]
	var lo := [0.0, 0.0, 0.9, 0.0, 0.0]
	var hi := []
	for p in pts:
		hi.append(lerpf(1.3, 4.4, clampf(p.x / w, 0.0, 1.0)))
	hi[2] = 5.3  # the prow's tip stands highest
	_walls(st, pts, lo, hi, clad)
	var c := Vector3.ZERO
	for i in pts.size():
		c += Vector3(pts[i].x, hi[i], pts[i].y)
	c /= pts.size()
	c.y += 0.25
	for i in pts.size():
		var j := (i + 1) % pts.size()
		Meshes._tri(st, c, Vector3(pts[i].x, hi[i], pts[i].y), Vector3(pts[j].x, hi[j], pts[j].y), clad.lightened(0.1 if i % 2 == 0 else 0.0))
	# the underside of the overhanging prow
	Meshes._tri(st, Vector3(pts[1].x, 0.0, pts[1].y), Vector3(pts[3].x, 0.0, pts[3].y), Vector3(pts[2].x, 0.9, pts[2].y), dark)
	# slanting bands of glass and dark panels climbing toward the prow
	var south_z := d - 0.06
	for i in 7:
		var x := 0.5 + i * (w - 2.0) / 7.0
		var y := 0.35 + i * 0.4
		_window(st, wst, x, y, south_z, 0.7, 0.2, dark)
		Meshes.box(st, Vector3(x, y + 0.42, south_z - 0.02), Vector3(0.7, 0.08, 0.04), dark)
	_door(st, door_x, south_z, clad, 1.0)

## Lincoln Cathedral: a long nave under a steep lead roof, a crossing tower and two west towers with pinnacles,
## all in pale Lincolnshire limestone. Its central spire made it the tallest building in the world until it
## blew down in 1548; the towers stand bare now.
static func _lincoln_cathedral(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := LINCS_LIMESTONE
	var lead := Color("6c7378")
	var nave_h := 2.8
	var west := 2.6
	Meshes.box(st, Vector3(west, 0, 0.7), Vector3(w - west - 0.2, nave_h, d - 1.4), stone)
	_roof_at(st, west, w - 0.2, 0.7, d - 0.7, nave_h, 1.3, lead, stone)
	# buttresses and tall lancets down the south side
	for x in range(int(west) + 1, w - 1):
		Meshes.box(st, Vector3(x - 0.1, 0, d - 0.85), Vector3(0.2, nave_h - 0.2, 0.3), stone.darkened(0.08))
		_window(st, wst, x + 0.3, 0.6, d - 0.65, 0.36, 1.5, stone.lightened(0.15))
	# the transept and the crossing tower
	var tx := west + (w - west) * 0.42
	Meshes.box(st, Vector3(tx - 0.9, 0, 0.1), Vector3(1.8, nave_h, d - 0.2), stone.darkened(0.03))
	_roof_at(st, tx - 0.9, tx + 0.9, 0.1, d - 0.1, nave_h, 1.0, lead, stone)
	_window(st, wst, tx - 0.35, 1.5, d - 0.05, 0.7, 1.0, stone.lightened(0.15))
	var ct := 2.0
	var th := 8.2
	var cz := d * 0.5 - ct * 0.5
	Meshes.box(st, Vector3(tx - ct * 0.5, 0, cz), Vector3(ct, th, ct), stone.lightened(0.04))
	for k in 2:
		_window(st, wst, tx - 0.6 + k * 0.8, th - 2.8, cz + ct + 0.05, 0.3, 1.8, stone.lightened(0.2))
	for p in [Vector2(0, 0), Vector2(ct - 0.3, 0), Vector2(0, ct - 0.3), Vector2(ct - 0.3, ct - 0.3)]:
		Meshes.box(st, Vector3(tx - ct * 0.5 + p.x, th, cz + p.y), Vector3(0.3, 1.1, 0.3), stone.lightened(0.08))
		Meshes.box(st, Vector3(tx - ct * 0.5 + p.x + 0.08, th + 1.1, cz + p.y + 0.08), Vector3(0.14, 0.5, 0.14), stone.lightened(0.12))
	_merlons(st, tx - ct * 0.5, tx + ct * 0.5, cz + ct - 0.6, th, stone, true)
	# the west front: a wide screen wall with a tower rising behind each end
	Meshes.box(st, Vector3(0, 0, 0.3), Vector3(west, nave_h + 0.9, d - 0.6), stone.lightened(0.02))
	for z in [0.2, d - 1.5]:
		Meshes.box(st, Vector3(0.4, 0, z), Vector3(1.3, 6.6, 1.3), stone.lightened(0.05))
		for p in [Vector2(0, 0), Vector2(1.05, 0), Vector2(0, 1.05), Vector2(1.05, 1.05)]:
			Meshes.box(st, Vector3(0.4 + p.x, 6.6, z + p.y), Vector3(0.25, 0.9, 0.25), stone.lightened(0.1))
		_window(st, wst, 0.85, 4.6, z + 1.35, 0.4, 1.3, stone.lightened(0.2))
	for k in 3:
		_window(st, wst, 0.35 + k * 0.7, 1.6, d - 0.25, 0.3, 1.4, stone.lightened(0.2))
	if door_x >= 0:  # on the transept front when the door falls inside it, else on the nave
		var fz := d - 0.1 if absf(door_x + 0.5 - tx) < 0.95 else d - 0.7
		Meshes.box(st, Vector3(door_x + 0.15, 0, fz - 0.03), Vector3(0.7, 1.3, 0.08), Color("3b2a22"))

## A solid outline extruded along z (front cap at z1 faces south), for the tank's rhomboid sides.
## `pts` (x, y) run clockwise seen from the south.
static func _prism(st: SurfaceTool, pts: Array, z0: float, z1: float, col: Color) -> void:
	for i in range(1, pts.size() - 1):
		Meshes._tri(st, Vector3(pts[0].x, pts[0].y, z1), Vector3(pts[i].x, pts[i].y, z1), Vector3(pts[i + 1].x, pts[i + 1].y, z1), col)
		Meshes._tri(st, Vector3(pts[0].x, pts[0].y, z0), Vector3(pts[i + 1].x, pts[i + 1].y, z0), Vector3(pts[i].x, pts[i].y, z0), col.darkened(0.1))
	for i in pts.size():
		var j := (i + 1) % pts.size()
		Meshes._quad(st, Vector3(pts[i].x, pts[i].y, z0), Vector3(pts[j].x, pts[j].y, z0), Vector3(pts[j].x, pts[j].y, z1),
			Vector3(pts[i].x, pts[i].y, z1), col.lightened(0.06) if pts[j].y >= pts[i].y - 0.01 and absf(pts[j].y - pts[i].y) < 0.05 else col.darkened(0.05))

## The Lincoln tank memorial: a Mark IV on a stone plinth, its tracks running right round the rhomboid hull,
## a gun sponson on each flank. The first tanks were built in Lincoln in 1915 and 1916.
static func _tank_memorial(st: SurfaceTool, w: int, d: int) -> void:
	var drab := Color("5f6648")
	var track := Color("33312c")
	Meshes.box(st, Vector3(0.15, 0, 0.2), Vector3(w - 0.3, 0.35, d - 0.4), LIMESTONE, LIMESTONE.lightened(0.1))
	var y0 := 0.35
	var prof := [Vector2(0.2, y0 + 0.45), Vector2(0.55, y0 + 1.05), Vector2(w - 0.5, y0 + 1.05), Vector2(w - 0.08, y0 + 0.4),
		Vector2(w - 0.5, y0 + 0.02), Vector2(0.5, y0 + 0.02)]
	var z0 := 0.3
	var z1 := d - 0.3
	_prism(st, prof, z0, z0 + 0.36, track)
	_prism(st, prof, z1 - 0.36, z1, track)
	var inner := [Vector2(0.6, y0 + 0.3), Vector2(0.8, y0 + 0.95), Vector2(w - 0.8, y0 + 0.95), Vector2(w - 0.5, y0 + 0.3)]
	_prism(st, inner, z0 + 0.3, z1 - 0.3, drab)
	Meshes.box(st, Vector3(w * 0.5 - 0.35, y0 + 0.95, d * 0.5 - 0.3), Vector3(0.7, 0.22, 0.6), drab.lightened(0.05))  # the cab
	for z in [z0 - 0.12, z1 - 0.06]:  # sponsons with their stubby guns
		Meshes.box(st, Vector3(w * 0.5 - 0.3, y0 + 0.35, z), Vector3(0.6, 0.4, 0.18), drab.darkened(0.05))
	Meshes.box(st, Vector3(w * 0.5 - 0.04, y0 + 0.5, z1 + 0.1), Vector3(0.08, 0.08, 0.3), Color("2a2a26"))
	for i in 6:  # track plates down the visible side
		Meshes.box(st, Vector3(0.6 + i * (w - 1.2) / 6.0, y0 + 0.03, z1 + 0.005), Vector3(0.04, 0.3, 0.02), track.lightened(0.2))

## The Rudston Monolith: Britain's tallest standing stone, a weathered slab of gritstone about 7.6 metres high,
## lichened and slightly leaning, in a little fenced patch of churchyard grass.
static func _monolith(st: SurfaceTool, w: int, d: int) -> void:
	var rng := Meshes._rng(9177)
	var g := Color("a49e8c")
	var cx := w * 0.5
	var cz := d * 0.5
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, 0.04, d - 0.1), Color("6f8d45"))
	Meshes.box(st, Vector3(cx - 0.32, 0, cz - 0.16), Vector3(0.64, 1.6, 0.34), g)
	Meshes.box(st, Vector3(cx - 0.28, 1.6, cz - 0.14), Vector3(0.55, 1.4, 0.3), g.lightened(0.04))
	Meshes.box(st, Vector3(cx - 0.22, 3.0, cz - 0.12), Vector3(0.44, 0.7, 0.26), g.darkened(0.04))
	Meshes.box(st, Vector3(cx - 0.12, 3.7, cz - 0.08), Vector3(0.24, 0.25, 0.18), Color("6d6a5e"))  # the lead cap
	Meshes.blob(st, Vector3(cx + 0.12, 1.1, cz + 0.17), Vector3(0.14, 0.2, 0.04), Color("c2b45a"), rng)
	Meshes.blob(st, Vector3(cx - 0.15, 2.4, cz + 0.15), Vector3(0.1, 0.14, 0.04), Color("9fae6a"), rng)

## A Hull sidewinder trawler (the Arctic Corsair, 1960) moored bow to the north: a black hull with a rising
## bow, white superstructure and wheelhouse aft, a buff funnel, a foremast and the trawl gallows along the side.
## The door is a gangway in the stern.
static func _trawler(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var hull := Color("23262b")
	var white := Color("e9e6dc")
	var cx := w * 0.5
	var pts := [Vector2(cx, 0.05), Vector2(w - 0.25, 1.8), Vector2(w - 0.3, d - 0.25), Vector2(0.3, d - 0.25), Vector2(0.25, 1.8)]
	var lo := [-0.6, -0.6, -0.6, -0.6, -0.6]
	var hi := [1.35, 0.9, 0.95, 0.95, 0.9]
	_walls(st, pts, lo, hi, hull)
	var deck := Color("8c7a62")
	var c := Vector3(cx, 0.9, d * 0.5)
	for i in pts.size():
		var j := (i + 1) % pts.size()
		Meshes._tri(st, c, Vector3(pts[i].x, hi[i] - 0.05, pts[i].y), Vector3(pts[j].x, hi[j] - 0.05, pts[j].y), deck)
	Meshes.box(st, Vector3(0.28, 0.75, 1.8), Vector3(0.04, 0.12, d - 2.1), Color("a8322a"))  # a red line along the sheer
	Meshes.box(st, Vector3(w - 0.32, 0.75, 1.8), Vector3(0.04, 0.12, d - 2.1), Color("a8322a"))
	# superstructure aft, the wheelhouse on top
	var sz := d * 0.5
	Meshes.box(st, Vector3(0.45, 0.9, sz), Vector3(w - 0.9, 0.85, d * 0.32), white)
	Meshes.box(st, Vector3(0.6, 1.75, sz + 0.1), Vector3(w - 1.2, 0.6, 1.0), white.lightened(0.04))
	for k in 2:
		_window(st, wst, 0.75 + k * (w - 1.5) * 0.5, 1.85, sz + 1.1, 0.4, 0.3, white)
		_window(st, wst, 0.7 + k * (w - 1.4) * 0.5, 1.15, sz + d * 0.32, 0.35, 0.3, white)
	Meshes.box(st, Vector3(cx - 0.25, 1.75, sz + d * 0.22), Vector3(0.5, 0.95, 0.5), Color("d6b04c"))  # the funnel
	Meshes.box(st, Vector3(cx - 0.26, 2.5, sz + d * 0.22 - 0.01), Vector3(0.52, 0.2, 0.52), Color("1c1c1c"))
	# foremast with a crosstree, and the trawl gallows on the starboard side
	Meshes.box(st, Vector3(cx - 0.05, 0.9, d * 0.22), Vector3(0.1, 2.8, 0.1), Color("cfc8b8"))
	Meshes.box(st, Vector3(cx - 0.5, 3.0, d * 0.22), Vector3(1.0, 0.07, 0.07), Color("cfc8b8"))
	for gz in [d * 0.3, d * 0.8]:
		Meshes.box(st, Vector3(w - 0.4, 0.9, gz), Vector3(0.08, 0.9, 0.08), Color("3d5a78"))
		Meshes.box(st, Vector3(w - 0.4, 1.75, gz), Vector3(0.45, 0.08, 0.08), Color("3d5a78"))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.2, 0.0, d - 0.3), Vector3(0.6, 0.9, 0.06), Color("3b2a22"))

## The Spire at the International Bomber Command Centre near Lincoln: a slim, tapering spire of weathering steel
## as tall as a Lancaster's wings are wide, on a low stone base.
static func _spire_memorial(st: SurfaceTool, w: int, d: int) -> void:
	var steel := Color("8a4a2c")
	var cx := w * 0.5
	var cz := d * 0.5
	Meshes.box(st, Vector3(0.1, 0, 0.1), Vector3(w - 0.2, 0.18, d - 0.2), LIMESTONE)
	var n := 10
	for i in n:
		var r := 0.34 * (1.0 - float(i) / n) + 0.03
		Meshes.box(st, Vector3(cx - r, 0.18 + i * 0.62, cz - r * 0.45), Vector3(r * 2.0, 0.62, r * 0.9), steel.lightened(0.04 * (i % 2)))
# --- Fife and the Forth (3.0 Wider Isles) -------------------------------------

const FORTH_RED := Color("a8382a")     # the Forth Bridge's famous red oxide
const GRANITE := Color("9a958c")
const FIFE_PANTILE := Color("b4552f")       # Fife's orange clay pantiles
const HARLS := [Color("ece6d8"), Color("e6d3a8"), Color("dcb8a4"), Color("e9dfc8")]
const CULROSS_OCHRE := Color("d6a548")  # "Culross yellow"
const DUNDEE_STONE := Color("a98d72")
const FORTH_DECK := 1.7                # rail deck height of the Forth Bridge

static func _fife(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, style: String) -> void:
	match style:
		"forth_bridge":
			_forth_bridge(st, w, d)
		"forth_approach":
			_forth_approach(st, w, d)
		"road_bridge":
			_bridge_girder(st, w, d)
			_suspension(st, d)
		"bridge_girder":
			_bridge_girder(st, w, d)
		"cable_stayed":
			_cable_stayed(st)
		"crow_step":
			_crow_step(st, wst, w, d, door_x, rng, HARLS[rng.randi() % HARLS.size()], 2)
		"culross_palace":
			_crow_step(st, wst, w, d, door_x, rng, CULROSS_OCHRE, 2)
		"tenement":
			_house(st, wst, w, d, door_x, rng, DUNDEE_STONE, SLATE, 3, true, false)
			for s in [1, 2]:
				Meshes.box(st, Vector3(0, 1.15 * s + 0.2, d - 0.03), Vector3(w, 0.07, 0.06), DUNDEE_STONE.lightened(0.15))
		"st_andrews_ruin":
			_st_andrews_ruin(st, w, d, door_x, rng)
		"martyrs_obelisk":
			_martyrs_obelisk(st, w, d)
		"discovery_ship":
			_discovery(st, wst, w, d, door_x)
		"va_dundee":
			_va_dundee(st, wst, w, d, door_x)
		"tay_bridge":
			_tay_bridge(st, w, d)

## A box turned `yaw` radians about its own vertical centre line (for the V&A's twisting slabs).
static func _rbox(st: SurfaceTool, c: Vector3, s: Vector3, yaw: float, col: Color) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var b := Basis(Vector3.UP, yaw)
	var lo := []
	var hi := []
	for k in [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]:
		var o: Vector3 = b * Vector3(k.x, 0, k.y)
		lo.append(c + o)
		hi.append(c + o + Vector3(0, s.y, 0))
	for i in 4:
		var j := (i + 1) % 4
		Meshes._quad(st, lo[i], lo[j], hi[j], hi[i], col.darkened(0.06 * (i % 2)))
	Meshes._quad(st, hi[3], hi[2], hi[1], hi[0], col.lightened(0.08))

## A straight member from a to b with a square section (any direction).
static func _fife_beam(st: SurfaceTool, a: Vector3, b: Vector3, t: float, col: Color) -> void:
	var dir := (b - a).normalized()
	var side := dir.cross(Vector3.UP)
	if side.length() < 0.1:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized() * t * 0.5
	var up := side.cross(dir).normalized() * t * 0.5
	var c := [side + up, -side + up, -side - up, side - up]
	for i in 4:
		var j := (i + 1) % 4
		Meshes._quad(st, a + c[i], a + c[j], b + c[j], b + c[i], col.darkened(0.08 * (i % 2)))

## One of the Forth Bridge's three double cantilevers (1890): a tall red tower on granite caissons, tapering to the
## top, with a cantilever arm reaching north and south (straight top ties, curved bottom tubes) and half of the
## suspended span that joins it to the next tower. Towers sit 12 tiles apart, north-south.
static func _forth_bridge(st: SurfaceTool, w: int, d: int) -> void:
	var cx := w * 0.5
	var cz := d * 0.5
	var top := 6.2
	var reach := 4.6
	var half := 6.0
	Meshes.box(st, Vector3(0.1, -0.8, 0.1), Vector3(w - 0.2, 1.05, d - 0.2), GRANITE, GRANITE.lightened(0.05))
	for c in [Vector2(-1.3, -0.5), Vector2(1.3, -0.5), Vector2(-1.3, 0.5), Vector2(1.3, 0.5)]:
		Meshes.cylinder(st, Vector3(cx + c.x, 0.2, cz + c.y), 0.42, 0.3, 8, GRANITE.lightened(0.08))
	var red := FORTH_RED
	var lit := red.lightened(0.12)
	# the tower: four legs leaning in, braced with Xs on the faces
	var base := [Vector2(-1.3, -0.5), Vector2(1.3, -0.5), Vector2(1.3, 0.5), Vector2(-1.3, 0.5)]
	var crown := [Vector2(-0.45, -0.3), Vector2(0.45, -0.3), Vector2(0.45, 0.3), Vector2(-0.45, 0.3)]
	var legs := []
	for i in 4:
		legs.append([Vector3(cx + base[i].x, 0.3, cz + base[i].y), Vector3(cx + crown[i].x, top, cz + crown[i].y)])
		_fife_beam(st, legs[i][0], legs[i][1], 0.24, red)
	var levels := [0.3, 2.2, 4.2, top]
	for li in 3:
		var y0: float = levels[li]
		var y1: float = levels[li + 1]
		for pair in [[0, 1], [3, 2]]:
			_fife_beam(st, _leg_at(legs[pair[0]], y0, top), _leg_at(legs[pair[1]], y1, top), 0.11, lit)
			_fife_beam(st, _leg_at(legs[pair[1]], y0, top), _leg_at(legs[pair[0]], y1, top), 0.11, lit)
	for y in [2.2, 4.2, top]:
		for i in 4:
			_fife_beam(st, _leg_at(legs[i], y, top), _leg_at(legs[(i + 1) % 4], y, top), 0.1, lit)
	# the arms, north (-1) and south (+1)
	for s in [-1.0, 1.0]:
		for side in [-1.0, 1.0]:
			var tip_x: float = cx + side * 0.7
			var tip_z: float = cz + s * reach
			# the bottom tube: a sagging curve from the caisson out to the tip
			var prev := Vector3(cx + side * 1.3, 0.35, cz + s * 0.5)
			for k in [0.3, 0.6, 1.0]:
				var p := Vector3(lerpf(cx + side * 1.3, tip_x, k), lerpf(0.35, FORTH_DECK - 0.15, k * k), lerpf(cz + s * 0.5, tip_z, k))
				_fife_beam(st, prev, p, 0.26, red)
				prev = p
			# the top tie, from the crown down to the tip
			_fife_beam(st, Vector3(cx + side * 0.45, top, cz + s * 0.3), Vector3(tip_x, FORTH_DECK + 0.35, tip_z), 0.16, red)
			# web posts between tie and tube
			for k in [0.35, 0.65]:
				var zz := lerpf(cz + s * 0.5, tip_z, k)
				var yt := lerpf(top, FORTH_DECK + 0.35, k)
				var yb := lerpf(0.35, FORTH_DECK - 0.15, k * k)
				var xx := lerpf(cx + side * 1.3, tip_x, k)
				_fife_beam(st, Vector3(xx, yb, zz), Vector3(xx, yt, zz), 0.09, lit)
			# the suspended half span's top chord and its braces
			_fife_beam(st, Vector3(tip_x, FORTH_DECK + 0.35, tip_z), Vector3(tip_x, FORTH_DECK + 0.35, cz + s * half), 0.12, red)
			for k in 3:
				var zz := lerpf(tip_z, cz + s * half, (k + 0.5) / 3.0)
				_fife_beam(st, Vector3(tip_x, FORTH_DECK - 0.1, zz), Vector3(tip_x, FORTH_DECK + 0.35, zz + s * 0.3), 0.07, lit)
		# the deck through the arm and the suspended half span
		Meshes.box(st, Vector3(cx - 0.75, FORTH_DECK - 0.2, minf(cz, cz + s * half)), Vector3(1.5, 0.25, half), red.darkened(0.25))
	# the two rails along the top of the deck
	for rx in [-0.25, 0.25]:
		Meshes.box(st, Vector3(cx + rx - 0.03, FORTH_DECK + 0.05, cz - half), Vector3(0.06, 0.05, half * 2), Color("5a5048"))

## A point on a tower leg ([bottom, top]) at height y.
static func _leg_at(leg: Array, y: float, top: float) -> Vector3:
	var a: Vector3 = leg[0]
	var b: Vector3 = leg[1]
	return a.lerp(b, clampf((y - a.y) / (top - a.y), 0.0, 1.0))

## The Forth Bridge's approach viaduct: tall granite piers carrying a red lattice girder at the bridge's deck height.
static func _forth_approach(st: SurfaceTool, w: int, d: int) -> void:
	var cx := w * 0.5
	var z := 0.6
	while z < d:
		Meshes.box(st, Vector3(cx - 0.45, -0.2, z - 0.3), Vector3(0.9, FORTH_DECK - 0.1, 0.6), GRANITE)
		Meshes.box(st, Vector3(cx - 0.55, FORTH_DECK - 0.35, z - 0.38), Vector3(1.1, 0.12, 0.76), GRANITE.lightened(0.1))
		z += 1.5
	Meshes.box(st, Vector3(cx - 0.75, FORTH_DECK - 0.2, -0.2), Vector3(1.5, 0.25, d + 0.4), FORTH_RED.darkened(0.25))
	for side in [-1.0, 1.0]:
		_fife_beam(st, Vector3(cx + side * 0.7, FORTH_DECK + 0.35, -0.2), Vector3(cx + side * 0.7, FORTH_DECK + 0.35, d + 0.2), 0.12, FORTH_RED)
		var k := 0.0
		while k < d:
			_fife_beam(st, Vector3(cx + side * 0.7, FORTH_DECK - 0.1, k), Vector3(cx + side * 0.7, FORTH_DECK + 0.35, k + 0.4), 0.07, FORTH_RED.lightened(0.12))
			k += 0.8

## A road bridge's side girder (the Forth and Tay road bridges): a deep grey box beside the deck, down into the
## water, with a parapet rail on top. One tile wide, running north-south.
static func _bridge_girder(st: SurfaceTool, w: int, d: int) -> void:
	var grey := Color("7f868c")
	Meshes.box(st, Vector3(0.0, -0.75, -0.02), Vector3(w, 0.95, d + 0.04), grey, grey.lightened(0.1))
	Meshes.box(st, Vector3(0.0, 0.2, -0.02), Vector3(w, 0.06, d + 0.04), Color("c8c4b8"))  # footway kerb
	for side in [0.08, w - 0.14]:
		Meshes.box(st, Vector3(side, 0.26, -0.02), Vector3(0.06, 0.45, d + 0.04), Color("4c5258"))
	var z := 0.5
	while z < d:
		Meshes.box(st, Vector3(w * 0.5 - 0.3, -0.75, z - 0.2), Vector3(0.6, 0.2, 0.4), grey.darkened(0.2))
		z += 2.0

## The Forth Road Bridge (1964): two tall portal towers across the deck and the main cables sagging between them,
## with hangers down to both girders. Drawn from the west girder; the deck is three tiles, the east girder at x + 4.
static func _suspension(st: SurfaceTool, d: int) -> void:
	var grey := Color("8d9499")
	var xs := [0.5, 4.5]
	var t1 := d * 0.27
	var t2 := d * 0.73
	var top := 6.4
	for tz in [t1, t2]:
		for x in xs:
			Meshes.box(st, Vector3(x - 0.22, -0.7, tz - 0.25), Vector3(0.44, top + 0.7, 0.5), grey)
		for y in [2.6, 4.6, top - 0.2]:
			Meshes.box(st, Vector3(xs[0], y, tz - 0.18), Vector3(xs[1] - xs[0], 0.3, 0.36), grey.darkened(0.08))
	for x in xs:
		var pts := []
		var n := 24
		for i in n + 1:
			var z := d * float(i) / n
			var y := 0.0
			if z < t1:
				y = lerpf(0.7, top, pow(z / t1, 1.6))
			elif z > t2:
				y = lerpf(0.7, top, pow((d - z) / (d - t2), 1.6))
			else:
				var u := (z - t1) / (t2 - t1) * 2.0 - 1.0
				y = lerpf(1.3, top, u * u)
			pts.append(Vector3(x, y, z))
		for i in n:
			_fife_beam(st, pts[i], pts[i + 1], 0.12, Color("5c6268"))
			if pts[i].y > 0.9:
				Meshes.box(st, Vector3(x - 0.02, 0.25, pts[i].z - 0.02), Vector3(0.04, pts[i].y - 0.25, 0.04), Color("6a7076"))

## The Queensferry Crossing (2017): a slim single tower with fans of stay cables both ways along the deck.
## One tile footprint; the deck reaches six tiles north and south to meet the next tower.
static func _cable_stayed(st: SurfaceTool) -> void:
	var pale := Color("c9cdd0")
	var top := 7.4
	var deck := 1.5
	Meshes.box(st, Vector3(0.05, -0.8, 0.05), Vector3(0.9, deck + 0.8, 0.9), pale.darkened(0.15))
	Meshes.box(st, Vector3(0.28, deck, 0.2), Vector3(0.44, top - deck, 0.6), pale)
	Meshes.box(st, Vector3(0.33, top, 0.25), Vector3(0.34, 0.25, 0.5), pale.lightened(0.05))
	Meshes.box(st, Vector3(-0.45, deck - 0.25, -5.5), Vector3(1.9, 0.28, 12.0), pale.darkened(0.25), pale.darkened(0.05))
	for side in [-0.35, 1.35]:
		for k in 5:
			var off := 1.0 + k * 1.1
			for s in [-1.0, 1.0]:
				_fife_beam(st, Vector3(0.5, top - 0.3 - k * 0.45, 0.5), Vector3(side, deck, 0.5 + s * off), 0.035, Color("e8ecee"))

## A Fife house: harled walls, an orange pantiled roof and crow-stepped gables, two storeys, a chimney on a gable.
static func _crow_step(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, wall: Color, storeys: int) -> void:
	_house(st, wst, w, d, door_x, rng, wall, FIFE_PANTILE, storeys, false, false)
	var hgt := 1.15 * storeys + 0.2
	var rise := minf(1.2, d * 0.38)
	var steps := 3
	var s := (d * 0.5 + 0.18) / steps
	var stone := wall.darkened(0.12)
	for gx in [-0.2, w - 0.12]:
		for k in steps:
			var y := hgt + rise * float(k + 1) / steps + 0.14
			Meshes.box(st, Vector3(gx, hgt - 0.05, d + 0.18 - (k + 1) * s), Vector3(0.32, y - hgt + 0.05, s), stone, stone.lightened(0.15))
			Meshes.box(st, Vector3(gx, hgt - 0.05, -0.18 + k * s), Vector3(0.32, y - hgt + 0.05, s), stone, stone.lightened(0.15))
		Meshes.box(st, Vector3(gx - 0.02, hgt + rise, d * 0.5 - 0.25), Vector3(0.36, 0.55, 0.5), stone.darkened(0.05))
	Meshes.box(st, Vector3(-0.18, hgt + rise - 0.04, d * 0.5 - 0.07), Vector3(w + 0.36, 0.1, 0.14), FIFE_PANTILE.darkened(0.2))

## St Andrews Cathedral's ruins: the east gable with its two pinnacled turrets and tall empty lancets (turned to face
## the street), stumps of the nave walls behind, and St Rule's Tower standing whole at the back.
static func _st_andrews_ruin(st: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var stone := Color("a39a88")
	var dark := Color("2a2622")
	var gx0 := maxf(0.4, door_x - 1.5)
	var gx1 := minf(float(w) - 0.4, door_x + 2.5)
	var gh := 5.2
	Meshes.box(st, Vector3(gx0, 0, d - 0.55), Vector3(gx1 - gx0, gh, 0.45), stone)
	var mid := (gx0 + gx1) * 0.5
	Meshes._tri(st, Vector3(gx0, gh, d - 0.1), Vector3(gx1, gh, d - 0.1), Vector3(mid, gh + 1.0, d - 0.1), stone.lightened(0.04))
	Meshes._tri(st, Vector3(gx1, gh, d - 0.55), Vector3(gx0, gh, d - 0.55), Vector3(mid, gh + 1.0, d - 0.55), stone.darkened(0.06))
	Meshes._quad(st, Vector3(gx0, gh, d - 0.55), Vector3(gx0, gh, d - 0.1), Vector3(mid, gh + 1.0, d - 0.1), Vector3(mid, gh + 1.0, d - 0.55), stone)
	Meshes._quad(st, Vector3(gx1, gh, d - 0.1), Vector3(gx1, gh, d - 0.55), Vector3(mid, gh + 1.0, d - 0.55), Vector3(mid, gh + 1.0, d - 0.1), stone.darkened(0.04))
	for x in [gx0 - 0.35, gx1 - 0.35]:
		Meshes.box(st, Vector3(x, 0, d - 0.7), Vector3(0.7, gh + 1.4, 0.7), stone.darkened(0.04))
		var c := Vector3(x + 0.35, gh + 2.7, d - 0.35)
		var r := [Vector3(x, gh + 1.4, d), Vector3(x + 0.7, gh + 1.4, d), Vector3(x + 0.7, gh + 1.4, d - 0.7), Vector3(x, gh + 1.4, d - 0.7)]
		for i in 4:
			Meshes._tri(st, r[i], r[(i + 1) % 4], c, stone.lightened(0.06) if i == 0 else stone.darkened(0.05 * i))
	# tall lancets in two tiers, open to the sky
	var span := gx1 - gx0
	for i in 3:
		var lx := gx0 + span * (0.2 + 0.3 * i) - 0.2
		Meshes.box(st, Vector3(lx, 0.9, d - 0.08), Vector3(0.4, 1.7, 0.04), dark)
		Meshes.box(st, Vector3(lx, 3.0, d - 0.08), Vector3(0.4, 1.5, 0.04), dark)
	Meshes.box(st, Vector3(mid - 0.35, 4.75, d - 0.08), Vector3(0.7, 0.7, 0.04), dark)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.18, 0, d - 0.08), Vector3(0.64, 0.75, 0.04), dark)
	# the ruined nave walls running back, broken off at random heights
	for side in [gx0 + 0.1, gx1 - 0.5]:
		var z := d - 0.6
		while z > 0.4:
			Meshes.box(st, Vector3(side, 0, z - 0.8), Vector3(0.4, rng.randf_range(0.5, 2.6), 0.8), stone.darkened(rng.randf_range(0.0, 0.1)))
			z -= 0.9
	# St Rule's Tower: tall, square, plain and older than the rest
	var tx := 0.3 if gx0 > 2.5 else w - 2.0
	Meshes.box(st, Vector3(tx, 0, 0.3), Vector3(1.6, 7.6, 1.6), stone.lightened(0.06))
	Meshes.box(st, Vector3(tx - 0.08, 7.6, 0.22), Vector3(1.76, 0.18, 1.76), stone.lightened(0.12))
	for y in [5.6, 6.6]:
		Meshes.box(st, Vector3(tx + 0.6, y, 1.88), Vector3(0.4, 0.6, 0.04), dark)

## The Martyrs' Monument (1842): an obelisk on a stepped base.
static func _martyrs_obelisk(st: SurfaceTool, w: int, d: int) -> void:
	var stone := Color("c2b8a4")
	var c := Vector3(w * 0.5, 0, d * 0.5)
	Meshes.box(st, c + Vector3(-0.48, 0, -0.48), Vector3(0.96, 0.2, 0.96), stone.darkened(0.15))
	Meshes.box(st, c + Vector3(-0.36, 0.2, -0.36), Vector3(0.72, 0.5, 0.72), stone.darkened(0.05))
	var b := 0.24
	var t := 0.13
	var h0 := 0.7
	var h1 := 4.2
	var lo := [c + Vector3(-b, h0, -b), c + Vector3(b, h0, -b), c + Vector3(b, h0, b), c + Vector3(-b, h0, b)]
	var hi := [c + Vector3(-t, h1, -t), c + Vector3(t, h1, -t), c + Vector3(t, h1, t), c + Vector3(-t, h1, t)]
	var apex := c + Vector3(0, h1 + 0.35, 0)
	for i in 4:
		var j := (i + 1) % 4
		Meshes._quad(st, lo[i], lo[j], hi[j], hi[i], stone.darkened(0.06 * (i % 2)))
		Meshes._tri(st, hi[i], hi[j], apex, stone.lightened(0.05))

## RRS Discovery (built in Dundee, 1901): a black wooden barque with a buff funnel, three masts with furled sails
## and a bowsprit, bow to the east. A gangway comes down to the quay on the south side at the door.
static func _discovery(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var hull := Color("1f1d1e")
	var band := Color("e6dcc4")
	var deck := Color("b08a5c")
	var spar := Color("b98e52")
	var rope := Color("2a2420")
	var cz := d * 0.5
	var hw := d * 0.5 - 0.12
	var top := 1.25
	var bot := -0.6
	var s0 := 1.4
	var s1 := w - 2.2
	Meshes.box(st, Vector3(s0, bot, cz - hw), Vector3(s1 - s0, top - bot, hw * 2), hull, deck)
	Meshes.box(st, Vector3(s0, top - 0.32, cz + hw - 0.01), Vector3(s1 - s0, 0.1, 0.03), band)
	# bow (east): the sides close to a stem; stern (west): a rounded counter
	var bow := Vector3(w - 0.1, top + 0.15, cz)
	var bowk := Vector3(w - 0.9, bot, cz)
	for s in [-1.0, 1.0]:
		var a := Vector3(s1, top, cz + s * hw)
		var b := Vector3(s1, bot, cz + s * hw)
		if s > 0:
			Meshes._quad(st, a, b, bowk, bow, hull)
		else:
			Meshes._quad(st, bow, bowk, b, a, hull.darkened(0.1))
		var sa := Vector3(s0, top, cz + s * hw)
		var sb := Vector3(s0, bot, cz + s * hw)
		var ta := Vector3(0.25, top + 0.1, cz + s * hw * 0.55)
		var tb := Vector3(0.8, bot + 0.2, cz + s * hw * 0.4)
		if s > 0:
			Meshes._quad(st, sb, sa, ta, tb, hull.darkened(0.05))
		else:
			Meshes._quad(st, tb, ta, sa, sb, hull.darkened(0.12))
	Meshes._tri(st, Vector3(s1, top, cz - hw), Vector3(s1, top, cz + hw), bow, deck)
	Meshes._quad(st, Vector3(0.25, top + 0.1, cz - hw * 0.55), Vector3(0.25, top + 0.1, cz + hw * 0.55), Vector3(s0, top, cz + hw), Vector3(s0, top, cz - hw), deck)
	Meshes.box(st, Vector3(0.2, bot + 0.2, cz - hw * 0.55), Vector3(0.12, top - bot - 0.1, hw * 1.1), hull.darkened(0.1))
	# bulwark rail and the deckhouse
	Meshes.box(st, Vector3(s0, top, cz + hw - 0.08), Vector3(s1 - s0, 0.25, 0.08), hull.lightened(0.08))
	Meshes.box(st, Vector3(s0, top, cz - hw), Vector3(s1 - s0, 0.25, 0.08), hull.lightened(0.08))
	Meshes.box(st, Vector3(w * 0.36, top, cz - 0.45), Vector3(2.2, 0.55, 0.9), Color("c9b48c"))
	_window(st, wst, w * 0.36 + 0.4, top + 0.15, cz + 0.45, 0.3, 0.25, Color("8a6a44"))
	_window(st, wst, w * 0.36 + 1.4, top + 0.15, cz + 0.45, 0.3, 0.25, Color("8a6a44"))
	# the funnel between fore and main masts
	Meshes.cylinder(st, Vector3(w * 0.47, top, cz), 0.32, 1.9, 10, Color("d8b85a"))
	Meshes.cylinder(st, Vector3(w * 0.47, top + 1.85, cz), 0.3, 0.25, 10, Color("1e1e1e"))
	# masts, yards with furled sails, and some rigging
	var masts := [[w * 0.74, 6.6], [w * 0.57, 7.1], [w * 0.24, 6.2]]
	for mi in masts.size():
		var mx: float = masts[mi][0]
		var mh: float = masts[mi][1]
		Meshes.cylinder(st, Vector3(mx, top, cz), 0.11, mh, 6, spar)
		var yards := [0.35, 0.58, 0.8] if mi < 2 else [0.55]
		for f in yards:
			var y: float = top + mh * f
			var half: float = 1.25 * (1.15 - f * 0.6)
			Meshes.box(st, Vector3(mx - 0.05, y, cz - half), Vector3(0.1, 0.08, half * 2), spar.darkened(0.1))
			Meshes.box(st, Vector3(mx - 0.09, y + 0.07, cz - half * 0.9), Vector3(0.18, 0.13, half * 1.8), Color("ece4cc"))
		for s in [-1.0, 1.0]:
			_fife_beam(st, Vector3(mx, top + mh * 0.85, cz), Vector3(mx - 0.5, top + 0.2, cz + s * hw), 0.03, rope)
	var mizzen: float = masts[2][0]
	Meshes.box(st, Vector3(mizzen - 1.6, top + 2.4, cz - 0.04), Vector3(1.6, 0.07, 0.08), spar)  # the gaff boom
	Meshes.box(st, Vector3(mizzen - 1.5, top + 0.9, cz - 0.03), Vector3(1.4, 1.4, 0.06), Color("e6dcc2"))  # spanker, brailed
	_fife_beam(st, Vector3(w - 0.3, top + 0.2, cz), Vector3(w + 1.4, top + 1.0, cz), 0.12, spar)  # bowsprit
	_fife_beam(st, Vector3(w + 1.3, top + 0.95, cz), Vector3(w * 0.74, top + 6.4, cz), 0.03, rope)
	_fife_beam(st, Vector3(w * 0.74, top + 6.4, cz), Vector3(w * 0.57, top + 6.9, cz), 0.03, rope)
	_fife_beam(st, Vector3(w * 0.57, top + 6.9, cz), Vector3(w * 0.24, top + 6.0, cz), 0.03, rope)
	# the gangway down to the quay
	if door_x >= 0:
		_fife_beam(st, Vector3(door_x + 0.5, 0.15, d + 0.3), Vector3(door_x + 0.5, top, cz + hw - 0.1), 0.5, Color("8a6a44"))

## V&A Dundee (2018): two inverted, stepped pyramids of horizontal precast slabs, twisting as they rise and
## meeting at the top over a glazed entrance, like a cliff on the Tay.
static func _va_dundee(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var concrete := Color("a7a39a")
	var gap := Color("3e3c3a")
	var cz := d * 0.5
	var layers := 9
	var lh := 0.52
	for side in [-1.0, 1.0]:
		var bx: float = w * 0.5 + side * w * 0.22
		for i in layers:
			var k := float(i) / (layers - 1)
			var sw := lerpf(w * 0.32, w * 0.5, k)
			var sd := lerpf(d * 0.55, d * 0.95, k)
			var yaw: float = side * lerpf(-0.12, 0.2, k)
			var c := Vector3(bx - side * k * w * 0.06, i * lh, cz)
			_rbox(st, c, Vector3(sw * 0.94, lh * 0.55, sd * 0.94), yaw, gap)
			_rbox(st, c + Vector3(0, lh * 0.5, 0), Vector3(sw, lh * 0.5, sd), yaw, concrete.lightened(0.04 * (i % 2)))
	# the glazed gap and entrance between the two
	Meshes.box(st, Vector3(w * 0.5 - 1.0, 0, cz - 0.6), Vector3(2.0, 2.4, 1.4), Color("2c3e48"))
	Meshes.box(wst, Vector3(w * 0.5 - 0.9, 0.2, cz + 0.79), Vector3(1.8, 2.0, 0.04), window_colour(_wr))
	Meshes.box(st, Vector3(w * 0.5 - 1.6, layers * lh - 0.1, cz - d * 0.3), Vector3(3.2, 0.3, d * 0.6), concrete)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.2, 0.0, d - 0.08), Vector3(0.6, 1.0, 0.06), Color("1e2a30"))

## The Tay Rail Bridge (1887) running in along the shore on its paired piers, and beside it the stumps of the
## first bridge, which fell in a storm on 28 December 1879 with a train on it.
static func _tay_bridge(st: SurfaceTool, w: int, d: int) -> void:
	var iron := Color("5e6266")
	var brick := Color("7a5a48")
	var x := 0.5
	while x < w:
		for zz in [0.25, 0.75]:
			Meshes.cylinder(st, Vector3(x, -0.8, zz), 0.13, 2.0, 6, iron)
		Meshes.box(st, Vector3(x - 0.2, 1.1, 0.15), Vector3(0.4, 0.12, 0.7), iron.darkened(0.1))
		Meshes.cylinder(st, Vector3(x + 0.1, -0.8, d - 0.45), 0.26, 1.0, 7, brick)  # the old bridge's stump
		x += 1.6
	Meshes.box(st, Vector3(0, 1.2, 0.1), Vector3(w, 0.35, 0.8), iron, iron.lightened(0.1))
	for zz in [0.1, 0.84]:
		var k := 0.0
		while k < w - 0.5:
			_fife_beam(st, Vector3(k, 1.55, zz), Vector3(k + 0.4, 2.05, zz), 0.06, iron.lightened(0.15))
			_fife_beam(st, Vector3(k + 0.4, 2.05, zz), Vector3(k + 0.8, 1.55, zz), 0.06, iron.lightened(0.15))
			k += 0.8
		Meshes.box(st, Vector3(0, 2.0, zz - 0.03), Vector3(w, 0.08, 0.08), iron.lightened(0.1))
# --- the far north (Caithness and Sutherland) --------------------------------

const CAITHNESS_FLAG := Color("8d8f8a")   # grey-blue Old Red Sandstone flags
const CAITHNESS_ROOF := Color("5b5a55")   # flagstone roofs
const HARL := Color("e2dccd")             # lime harling

static func _far_north(st: SurfaceTool, wst: SurfaceTool, style: String, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	match style:
		"caithness_flag":
			_flag_house(st, wst, w, d, door_x, rng)
		"flag_fence":
			_flag_fence(st, w, d, rng)
		"mey_castle":
			_mey_castle(st, wst, w, d, door_x)
		"dunrobin":
			_dunrobin(st, wst, w, d, door_x)
		"jog_signpost":
			_jog_signpost(st)
		"sea_stacks":
			_sea_stacks(st, w, d)
		"well_house":
			_well_house(st, w, d)
		"kirk_ruin":
			_kirk_ruin(st, w, d, door_x)
		"surf_shack":
			_house(st, wst, w, d, door_x, rng, Color("3f7f95"), Color("d8d2c2"), 1, false, false)
			Meshes.box(st, Vector3(0.3, 0.2, d + 0.02), Vector3(0.18, 1.3, 0.06), Color("e8b030"))   # boards against the wall
			Meshes.box(st, Vector3(w - 0.55, 0.2, d + 0.02), Vector3(0.18, 1.2, 0.06), Color("d84a3a"))
		"jog_inn":
			_jog_inn(st, wst, w, d, door_x, rng)
		"flows_lookout":
			_flows_lookout(st, w, d)

## A Caithness house: walls of thin grey flags laid in courses, a stone-flag roof, crow-stepped gables.
static func _flag_house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var hgt := 2.1 if w >= 5 else 1.3
	for row in 7:
		var y := row * hgt / 7.0
		Meshes.box(st, Vector3(0.05, y, 0.05), Vector3(w - 0.1, hgt / 7.0, d - 0.1), CAITHNESS_FLAG.lightened(rng.randf_range(-0.07, 0.07)))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.14, d), CAITHNESS_FLAG.darkened(0.35))
	_roof(st, w, d, hgt, CAITHNESS_ROOF, CAITHNESS_FLAG, 0.42)
	var rise := minf(1.2, d * 0.42)
	for gx in [-0.12, w - 0.16]:  # crow steps up each gable
		for k in 4:
			var t := k / 4.0
			Meshes.box(st, Vector3(gx, hgt + rise * t, d * 0.5 * t - 0.1), Vector3(0.28, rise * 0.25 + 0.05, d * (1.0 - t) + 0.2), CAITHNESS_FLAG.darkened(0.05))
	Meshes.box(st, Vector3(-0.1, hgt + rise - 0.1, d * 0.5 - 0.25), Vector3(0.3, 0.75, 0.5), CAITHNESS_FLAG.darkened(0.15))  # gable chimney
	_chimneys.append(Vector3(0.05, hgt + rise + 0.65, d * 0.5))
	_door(st, door_x, d, CAITHNESS_FLAG)
	for s in (2 if w >= 5 else 1):
		for x in w:
			if x == door_x and s == 0:
				continue
			_window(st, wst, x + 0.3, 0.4 + 1.0 * s, d, 0.4, 0.5, Color("ece6d8"))

## A Caithness flagstone fence: tall slabs stood on end, edge to edge, no posts and no mortar.
static func _flag_fence(st: SurfaceTool, w: int, d: int, rng: RandomNumberGenerator) -> void:
	var along_x := w >= d
	var n := maxi(w, d) * 2
	for i in n:
		var h := rng.randf_range(0.75, 1.0)
		var c := CAITHNESS_FLAG.lightened(rng.randf_range(-0.1, 0.05))
		if along_x:
			Meshes.box(st, Vector3(i * 0.5 + 0.02, 0, d * 0.5 - 0.05), Vector3(0.46, h, 0.1), c)
		else:
			Meshes.box(st, Vector3(w * 0.5 - 0.05, 0, i * 0.5 + 0.02), Vector3(0.1, h, 0.46), c)

## A four-sided spire (conical roofs, turret caps).
static func _spire(st: SurfaceTool, c: Vector3, r: float, h: float, col: Color) -> void:
	var a := c + Vector3(-r, 0, -r)
	var b := c + Vector3(r, 0, -r)
	var cc := c + Vector3(r, 0, r)
	var dd := c + Vector3(-r, 0, r)
	var top := c + Vector3(0, h, 0)
	Meshes._tri(st, top, cc, dd, col)
	Meshes._tri(st, top, b, cc, col.darkened(0.12))
	Meshes._tri(st, top, a, b, col.darkened(0.25))
	Meshes._tri(st, top, dd, a, col.darkened(0.08))

## Castle of Mey: a harled tower house, a squat battlemented tower and corbelled corner turrets.
static func _mey_castle(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var slate := Color("4f5560")
	Meshes.box(st, Vector3(0.3, 0, 0.3), Vector3(w - 0.6, 2.4, d - 0.6), HARL)
	Meshes.box(st, Vector3(0.2, 0, 0.2), Vector3(w - 0.4, 0.2, d - 0.4), HARL.darkened(0.3))
	_roof_at(st, 0.3, w - 0.3, 0.3, d - 0.3, 2.4, 1.0, slate, HARL)
	var tx := w * 0.5 - 1.0
	Meshes.box(st, Vector3(tx, 0, 0.6), Vector3(2.0, 3.9, 2.0), HARL.darkened(0.03))
	_merlons(st, tx, tx + 2.0, 0.6, 3.9, HARL, true)
	_merlons(st, tx, tx + 2.0, 2.4, 3.9, HARL, true)
	for c in [Vector2(0.3, d - 0.3), Vector2(w - 0.3, d - 0.3), Vector2(0.3, 0.3), Vector2(w - 0.3, 0.3)]:
		Meshes.cylinder(st, Vector3(c.x, 1.7, c.y), 0.38, 1.2, 8, HARL.lightened(0.03))
		_spire(st, Vector3(c.x, 2.9, c.y), 0.42, 0.9, slate)
	for x in w:
		if x != door_x and x > 0 and x < w - 1:
			_window(st, wst, x + 0.32, 0.6, d - 0.2, 0.36, 0.5, Color("f4efe2"))
			_window(st, wst, x + 0.32, 1.6, d - 0.2, 0.36, 0.5, Color("f4efe2"))
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.2, 0, d - 0.28), Vector3(0.6, 1.05, 0.06), DOOR_WOOD)
		Meshes.box(st, Vector3(door_x + 0.1, 1.05, d - 0.3), Vector3(0.8, 0.12, 0.08), Color("b8ad98"))
	_chimneys.append(Vector3(1.0, 3.4, d * 0.5))

## Dunrobin: a pale chateau of a castle, tall pointed spires and steep roofs.
static func _dunrobin(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var wall := Color("ddd6c6")
	var roof := Color("4a5260")
	Meshes.box(st, Vector3(0.1, 0, 0.1), Vector3(w - 0.2, 2.8, d - 0.2), wall)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.3, d), Color("a89d88"))
	_roof_at(st, 0.1, w - 0.1, 0.1, d - 0.1, 2.8, 1.4, roof, wall)
	var towers := [Vector2(0.6, d - 0.6), Vector2(w - 0.6, d - 0.6), Vector2(w * 0.5, 0.8), Vector2(0.6, 0.8), Vector2(w - 0.6, 0.8)]
	var heights := [3.6, 3.6, 4.6, 3.2, 3.2]
	for i in towers.size():
		var t: Vector2 = towers[i]
		var h: float = heights[i]
		var sp := 2.2 if i == 2 else 1.6
		Meshes.box(st, Vector3(t.x - 0.5, 0, t.y - 0.5), Vector3(1.0, h, 1.0), wall.lightened(0.02))
		_spire(st, Vector3(t.x, h, t.y), 0.6, sp, roof)
		Meshes.box(st, Vector3(t.x - 0.03, h + sp, t.y - 0.03), Vector3(0.06, 0.4, 0.06), Color("c8a040"))  # finial
	for s in 2:
		for x in w:
			if x != door_x:
				_window(st, wst, x + 0.3, 0.6 + 1.1 * s, d, 0.4, 0.7, Color("f4efe2"))
	_door(st, door_x, d, wall, 1.2)

## The John o' Groats signpost: a white pole with arms pointing off to far-away places.
static func _jog_signpost(st: SurfaceTool) -> void:
	var white := Color("f2f0ea")
	Meshes.box(st, Vector3(0.38, 0, 0.38), Vector3(0.24, 0.15, 0.24), Color("6a6a66"))
	Meshes.box(st, Vector3(0.45, 0, 0.45), Vector3(0.1, 2.3, 0.1), white)
	var arms := [1.0, 1.4, 1.8, 2.1]
	for i in arms.size():
		var x0 := 0.5 if i % 2 == 0 else -0.25
		Meshes.box(st, Vector3(x0, arms[i], 0.47), Vector3(0.75, 0.2, 0.06), white)
		Meshes.box(st, Vector3(x0 + 0.06, arms[i] + 0.06, 0.53), Vector3(0.6, 0.06, 0.01), Color("2a2a2a"))  # the lettering
	Meshes.box(st, Vector3(0.3, 2.3, 0.3), Vector3(0.4, 0.1, 0.4), white)

## The Stacks of Duncansby: pointed sandstone towers on a skerry.
static func _sea_stacks(st: SurfaceTool, w: int, d: int) -> void:
	var rock := Color("8a5a44")
	Meshes.box(st, Vector3(0, -0.4, 0), Vector3(w, 0.5, d), Color("4a3f38"))
	var stacks := [[w * 0.3, d * 0.35, 0.8, 3.6], [w * 0.68, d * 0.55, 0.65, 2.9], [w * 0.45, d * 0.8, 0.45, 2.0]]
	for s in stacks:
		var c := Vector3(float(s[0]), 0, float(s[1]))
		var r: float = s[2]
		var h: float = s[3]
		Meshes.box(st, c + Vector3(-r, 0, -r), Vector3(r * 2, h * 0.55, r * 2), rock)
		Meshes.box(st, c + Vector3(-r * 0.7, h * 0.55, -r * 0.7), Vector3(r * 1.4, h * 0.25, r * 1.4), rock.lightened(0.06))
		_spire(st, c + Vector3(0, h * 0.8, 0), r * 0.7, h * 0.35, rock.lightened(0.1))
		Meshes.box(st, c + Vector3(-r, h * 0.3, r - 0.01), Vector3(r * 2, 0.06, 0.03), Color("f0ece0"))  # the guano line

## The Meadow Well: a little round well-house with a conical stone roof.
static func _well_house(st: SurfaceTool, w: int, d: int) -> void:
	var c := Vector3(w * 0.5, 0, d * 0.5)
	Meshes.cylinder(st, c, 0.85, 1.2, 10, CAITHNESS_FLAG)
	_spire(st, c + Vector3(0, 1.2, 0), 1.0, 0.9, CAITHNESS_ROOF)
	Meshes.box(st, Vector3(w * 0.5 - 0.25, 0.1, d * 0.5 + 0.8), Vector3(0.5, 0.8, 0.08), Color("2a2622"))

## Old St Peter's: roofless walls, a broken south wall, a little bellcote.
static func _kirk_ruin(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("9a9184")
	var h := 2.2
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, h, 0.35), stone)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(0.35, h + 0.8, d), stone.darkened(0.05))
	Meshes.box(st, Vector3(w - 0.35, 0, 0), Vector3(0.35, h + 0.8, d), stone.darkened(0.05))
	for x in w:
		if x != door_x:
			Meshes.box(st, Vector3(x, 0, d - 0.35), Vector3(1, h * (0.6 if x % 2 == 0 else 0.85), 0.35), stone)
	Meshes.box(st, Vector3(w - 0.4, h + 0.8, d * 0.5 - 0.3), Vector3(0.45, 0.7, 0.6), stone)  # bellcote
	Meshes.box(st, Vector3(0.35, 0.02, 0.35), Vector3(w - 0.7, 0.03, d - 0.7), Color("6f8a4c"))

## John o' Groats Inn: a white hotel with an eight-sided tower (Jan de Groot's eight sons) and bright trim.
static func _jog_inn(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	_house(st, wst, w, d, door_x, rng, Color("eeeae0"), SLATE, 2, false, false)
	var c := Vector3(0.75, 0, d - 0.2)
	Meshes.cylinder(st, c, 0.75, 3.6, 8, Color("eeeae0"))
	for k in 3:
		_window(st, wst, c.x - 0.18, 0.5 + k * 1.05, c.z + 0.74, 0.36, 0.5, Color("f4efe2"))
	_spire(st, c + Vector3(0, 3.6, 0), 0.8, 1.1, SLATE)
	var trim := [Color("d84a3a"), Color("2f7fb5"), Color("e8b030")]
	for i in trim.size():
		Meshes.box(st, Vector3(w - 1.0 - i, 2.2, d - 0.02), Vector3(0.9, 0.12, 0.06), trim[i])

## The Flows Lookout at Forsinard: a timber tower with a slatted top, looking out over the bog.
static func _flows_lookout(st: SurfaceTool, w: int, d: int) -> void:
	var larch := Color("a07850")
	for c in [Vector2(0.4, 0.4), Vector2(w - 0.4, 0.4), Vector2(0.4, d - 0.4), Vector2(w - 0.4, d - 0.4)]:
		Meshes.box(st, Vector3(c.x - 0.1, 0, c.y - 0.1), Vector3(0.2, 2.6, 0.2), larch.darkened(0.2))
	for k in 3:
		Meshes.box(st, Vector3(0.2, 0.6 + k * 0.7, d - 0.3), Vector3(w - 0.4, 0.1, 0.1), larch)
	Meshes.box(st, Vector3(0.1, 2.6, 0.1), Vector3(w - 0.2, 0.15, d - 0.2), larch)
	for i in 6:
		Meshes.box(st, Vector3(0.15 + i * (w - 0.3) / 6.0, 2.75, 0.1), Vector3(0.18, 1.0, d - 0.2), larch.lightened(0.08 * (i % 2)))
	Meshes.box(st, Vector3(0.0, 3.75, 0.0), Vector3(w, 0.12, d), larch.darkened(0.3))
# --- the Palace, Aintree and the bookies ---------------------------------------------

## A lit bulb or neon strip: into the windows mesh, burning all night.
static func _bulb(wst: SurfaceTool, o: Vector3, s: Vector3, b := 1.0) -> void:
	Meshes.box(wst, o, s, Color(b, b, b, 1.0))

## The Palace on Douglas promenade: a 1960s seaside hotel-casino in cream render, ribbon windows, a gilt sign band
## along the parapet, a vertical neon blade at the corner and a red canopy over the door, lit underneath.
static func _casino(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var cream := Color("ece2c8")
	var band := Color("f6f1e4")
	var gold := Color("d8b04a")
	var claret := Color("8a1f2c")
	var storeys := 3
	var hgt := 0.95 * storeys + 0.35
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), cream, Color("b8b0a0"))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.2, d), Color("6a645a"))
	# the ground floor: tall plate-glass bays in gilt frames, with cream piers between (room for a blue plaque)
	for x in w:
		if x == door_x:
			continue
		_window(st, wst, x + 0.24, 0.3, d, 0.52, 0.72, gold.darkened(0.25))
	# ribbon windows above, one long band per floor with slim mullions
	for s in range(1, storeys):
		var wy := 0.35 + 0.95 * s
		Meshes.box(st, Vector3(0.0, wy - 0.12, d - 0.04), Vector3(w, 0.08, 0.08), band)
		for x in w:
			_window(st, wst, x + 0.1, wy, d, 0.8, 0.5, band)
	# the parapet; the name goes up on a gilded band above it (Signage.front), with a row of bulbs along the cornice
	Meshes.box(st, Vector3(-0.04, hgt - 0.05, -0.04), Vector3(w + 0.08, 0.14, d + 0.08), band)
	for k in w * 3:
		_bulb(wst, Vector3(0.1 + k * (w - 0.2) / float(w * 3), hgt - 0.02, d + 0.04), Vector3(0.05, 0.05, 0.03))
	# the rooftop plant room
	Meshes.box(st, Vector3(w * 0.5 - 1.0, hgt, 0.3), Vector3(2.0, 0.5, 1.0), cream.darkened(0.12))
	# a neon blade on the east corner: CASINO, top to bottom, in a claret case
	var bx := w - 0.3
	Meshes.box(st, Vector3(bx, 1.2, d - 0.1), Vector3(0.16, 2.0, 0.5), claret)
	for k in 6:
		_bulb(wst, Vector3(bx + 0.17, 1.35 + k * 0.3, d + 0.02), Vector3(0.02, 0.2, 0.26), 1.0 if k % 2 == 0 else 0.8)
	# the canopy over the door: claret, gilt edged, on brass posts, lit along its underside
	if door_x >= 0:
		var cx0 := maxf(0.0, door_x - 0.9)
		var cx1 := minf(float(w), door_x + 1.9)
		var cy := 1.25
		Meshes.box(st, Vector3(cx0, cy, d - 0.05), Vector3(cx1 - cx0, 0.14, 0.95), claret, claret.lightened(0.1))
		Meshes.box(st, Vector3(cx0, cy - 0.04, d + 0.86), Vector3(cx1 - cx0, 0.06, 0.06), gold)
		for px in [cx0 + 0.08, cx1 - 0.14]:
			Meshes.box(st, Vector3(px, 0.0, d + 0.78), Vector3(0.06, cy, 0.06), gold.darkened(0.15))
		var n := int((cx1 - cx0) / 0.25)
		for k in n:
			_bulb(wst, Vector3(cx0 + 0.1 + k * 0.25, cy - 0.03, d + 0.8), Vector3(0.05, 0.03, 0.05))
		Meshes.box(st, Vector3(door_x + 0.12, 0.005, d - 0.02), Vector3(0.76, 0.02, 1.0), Color("a8202e"))  # the red carpet
		_door(st, door_x, d, cream, 0.95)
		Meshes.box(wst, Vector3(door_x + 0.28, 0.24, d - 0.055), Vector3(0.44, 0.78, 0.03), Color(0.95, 0.8, 0.5, 1.0))  # lit lobby

## A racecourse grandstand, "not to scale": a bar along the ground floor, tiers of green seats climbing to the back,
## a white cantilever roof edged with a green and white striped valance, a cupola with a clock, and a white rail.
static func _grandstand(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var white := Color("f2efe6")
	var stone := Color("d6cfbd")
	var green := Color("2f6a45")
	var base := 1.15
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, base, d - 0.1), stone)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), stone.darkened(0.3))
	for x in w:
		if x != door_x:
			_window(st, wst, x + 0.2, 0.32, d, 0.6, 0.6, white)
	Meshes.box(st, Vector3(-0.05, base, -0.05), Vector3(w + 0.1, 0.1, d + 0.1), white)
	# the tiers: rows of green seats with white gangways, climbing to the back wall
	var tiers := 5
	var step := (d - 0.3) / tiers
	for k in tiers:
		var z0 := d - 0.15 - (k + 1) * step
		var y := base + 0.1 + k * 0.28
		Meshes.box(st, Vector3(0.1, base, z0), Vector3(w - 0.2, y - base + 0.28, step), stone.darkened(0.05), green.darkened(0.08 * (k % 2)))
		for x in range(2, w - 1, 3):  # a gangway every few tiles
			Meshes.box(st, Vector3(x, y + 0.27, z0), Vector3(0.22, 0.02, step), white)
	var top := base + 0.1 + tiers * 0.28
	Meshes.box(st, Vector3(0.05, base, 0.05), Vector3(w - 0.1, top + 0.9 - base, 0.2), stone.darkened(0.1))  # the back wall
	for x in [0.05, w - 0.25]:  # side screens
		Meshes.box(st, Vector3(x, base, 0.05), Vector3(0.2, top + 0.7 - base, d - 0.2), white)
	# the roof, cantilevered from the back, a little higher at the front
	var ry := top + 0.95
	Meshes._quad(st, Vector3(-0.1, ry + 0.25, d + 0.3), Vector3(w + 0.1, ry + 0.25, d + 0.3), Vector3(w + 0.1, ry, -0.1), Vector3(-0.1, ry, -0.1), white)
	Meshes._quad(st, Vector3(-0.1, ry - 0.06, -0.1), Vector3(w + 0.1, ry - 0.06, -0.1), Vector3(w + 0.1, ry + 0.19, d + 0.3), Vector3(-0.1, ry + 0.19, d + 0.3), Color("c9c4b8"))
	for x in range(0, w + 1, 3):  # slim white columns
		Meshes.box(st, Vector3(minf(x, w - 0.08), base, d - 0.25), Vector3(0.08, ry - base + 0.15, 0.08), white)
	var stripes := int(w / 0.5)
	for k in stripes:  # the valance
		Meshes.box(st, Vector3(-0.1 + k * (w + 0.2) / stripes, ry - 0.08, d + 0.28), Vector3((w + 0.2) / stripes, 0.3, 0.04), green if k % 2 == 0 else white)
	# the cupola and its clock, and a flag
	var cx := w * 0.5
	Meshes.box(st, Vector3(cx - 0.45, ry + 0.2, 0.6), Vector3(0.9, 0.7, 0.9), white)
	Meshes.box(st, Vector3(cx - 0.25, ry + 0.38, 1.51), Vector3(0.5, 0.42, 0.02), Color("1d2a22"))
	Meshes.box(st, Vector3(cx - 0.02, ry + 0.58, 1.53), Vector3(0.04, 0.16, 0.01), white)
	Meshes.box(st, Vector3(cx - 0.02, ry + 0.58, 1.53), Vector3(0.12, 0.03, 0.01), white)
	Meshes.box(st, Vector3(cx - 0.55, ry + 0.9, 0.5), Vector3(1.1, 0.08, 1.1), green)
	Meshes.box(st, Vector3(cx - 0.35, ry + 0.98, 0.7), Vector3(0.7, 0.15, 0.7), green.darkened(0.15))
	Meshes.box(st, Vector3(cx - 0.02, ry + 1.13, 1.03), Vector3(0.04, 0.8, 0.04), white)
	Meshes.box(st, Vector3(cx + 0.02, ry + 1.6, 1.04), Vector3(0.45, 0.28, 0.02), green)
	# a white running rail along the front, with a gap at the door
	for x in w:
		if x == door_x:
			continue
		Meshes.box(st, Vector3(x, 0.55, d + 0.12), Vector3(1.0, 0.06, 0.05), white)
		Meshes.box(st, Vector3(x + 0.45, 0.0, d + 0.12), Vector3(0.05, 0.6, 0.05), white)
	_door(st, door_x, d, stone, 0.95)

## A betting shop on a high street: a brick terrace with a coloured fascia, a dark plate-glass window of posters,
## flats above and a slate roof. The fascia's colour depends on the region.
static func _bookmaker(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, region := "") -> void:
	var brick := Color("8e4a3a") if region != "scotland" else Color("9a6a5a")  # Glasgow's red sandstone, near enough
	var fascia := Color("1f5a3a") if region == "scotland" else (Color("b8262c") if region in ["ireland", "ni"] else Color("2f5fb0"))
	var hgt := 2.6
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), brick)
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), brick.darkened(0.35))
	_roof(st, w, d, hgt, SLATE, brick, 0.34)
	var chim := w - 1.2
	Meshes.box(st, Vector3(chim, hgt + 0.3, d * 0.5 - 0.2), Vector3(0.4, 0.95, 0.4), brick.darkened(0.2))
	_chimneys.append(Vector3(chim + 0.2, hgt + 1.25, d * 0.5))
	# the shopfront: pilasters, a dark window of posters and odds, and the fascia board with its lettering
	Meshes.box(st, Vector3(0.05, 0.16, d - 0.06), Vector3(w - 0.1, 1.1, 0.08), Color("1d1d22"))
	for x in [0.0, w - 0.16]:
		Meshes.box(st, Vector3(x, 0.0, d - 0.1), Vector3(0.16, 1.45, 0.16), fascia.darkened(0.25))
	for x in w:
		if x == door_x:
			continue
		Meshes.box(wst, Vector3(x + 0.12, 0.3, d - 0.01), Vector3(0.76, 0.85, 0.03), Color(0.75, 0.75, 0.75, 0.9))
		Meshes.box(st, Vector3(x + 0.2, 0.55, d + 0.025), Vector3(0.22, 0.3, 0.01), Color("f2e2a0"))   # a poster
		Meshes.box(st, Vector3(x + 0.5, 0.45, d + 0.025), Vector3(0.24, 0.44, 0.01), fascia.lightened(0.35))
	Meshes.box(st, Vector3(-0.02, 1.2, d - 0.06), Vector3(w + 0.04, 0.46, 0.14), fascia, fascia.lightened(0.1))  # the name is painted on (Signage)
	# flats upstairs
	for x in w:
		_window(st, wst, x + 0.28, 1.75, d, 0.44, 0.6, Color("e8e2d4"))
	_door(st, door_x, d, fascia, 0.95)
## Crow-stepped gables (Scots and Border houses): little stair-steps up both slopes of each gable end.
static func _crow_steps(st: SurfaceTool, w: int, d: int) -> void:
	var hgt := 1.15 * 2 + 0.2
	var rise := minf(1.2, d * 0.38)
	var wall := Color("9a958a").darkened(0.06)
	for xe in [-0.18, w + 0.18 - 0.14]:
		for side in [-1.0, 1.0]:
			for k in 3:
				var run := (d * 0.5) / 3.0
				var z0: float = d * 0.5 + (run * k if side > 0 else -run * (k + 1))
				var top := hgt + rise * (1.0 - (run * k) / (d * 0.5))
				Meshes.box(st, Vector3(xe, hgt - 0.02, z0), Vector3(0.14, top - hgt + 0.12, run), wall)
# --- the west Highlands --------------------------------------------------------------------------------

## White trim along a painted house: plinth and eaves band, so the colour reads as paint.
static func _trim(st: SurfaceTool, w: int, d: int) -> void:
	var white := Color("f4f0e6")
	Meshes.box(st, Vector3(-0.02, 0.0, d - 0.03), Vector3(w + 0.04, 0.2, 0.08), white)
	Meshes.box(st, Vector3(-0.02, 2.4, d - 0.03), Vector3(w + 0.04, 0.12, 0.08), white)

## A whitewashed distillery: slate roof, a pagoda ventilator on the ridge and a tall square stack at the back.
static func _distillery(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var wall := Color("d2cab6")
	_house(st, wst, w, d, door_x, rng, wall, SLATE, 2, false, false)
	var hgt := 2.5
	var px := w * 0.3
	Meshes.box(st, Vector3(px - 0.5, hgt + 0.3, d * 0.5 - 0.5), Vector3(1.0, 0.8, 1.0), wall.lightened(0.1))
	Meshes.cone(st, Vector3(px, hgt + 1.1, d * 0.5), 0.95, 0.9, 4, SLATE.darkened(0.1), rng)
	Meshes.box(st, Vector3(w - 1.3, 0.0, 0.2), Vector3(0.7, hgt + 2.6, 0.7), Color("8a5a48"))
	_chimneys.append(Vector3(w - 0.95, hgt + 2.6, 0.55))

## McCaig's Tower: a drum of grey granite with two tiers of dark arches and a parapet, the door at the south.
static func _mccaig(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("8f8c85")
	var r := minf(w, d) * 0.5 - 0.15
	var c := Vector3(w * 0.5, 0.0, d - r - 0.02)
	var h := 3.4
	Meshes.cylinder(st, Vector3(c.x, 0.0, c.z), r, h, 20, stone)
	var dark := Color("2a2826")
	for tier in 2:
		var y := 0.65 + tier * 1.45
		var rr := r * (1.0 - 0.15 * y / h) + 0.02
		for i in range(-3, 4):
			var a := PI * 0.5 + i * 0.3
			var p := Vector3(c.x + cos(a) * rr, y, c.z + sin(a) * rr)
			Meshes.box(st, Vector3(p.x - 0.22, y, p.z - 0.1), Vector3(0.44, 0.8, 0.14), dark)
			Meshes.box(st, Vector3(p.x - 0.15, y + 0.8, p.z - 0.1), Vector3(0.3, 0.14, 0.14), dark)
	var top := r * 0.85
	for i in 16:
		var a := TAU * i / 16
		Meshes.box(st, Vector3(c.x + cos(a) * (top - 0.15) - 0.17, h, c.z + sin(a) * (top - 0.15) - 0.17), Vector3(0.34, 0.34, 0.34), stone.lightened(0.08))
	var ring := _ellipse(c, top * 0.82, top * 0.82, h + 0.02, 16)
	for i in 16:
		Meshes._tri(st, ring[i], ring[(i + 1) % 16], Vector3(c.x, h + 0.02, c.z), Color("6f8a4a"))
	_door(st, door_x, d, stone, 1.1)

## The Maid of the Loch: a low dark hull, a white deck-house, paddle boxes, a buff funnel with a black top.
static func _steamer(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var hull := Color("2b2f3a")
	var white := Color("f0ece0")
	Meshes.box(st, Vector3(0.1, 0.0, 0.5), Vector3(w - 0.2, 0.7, d - 0.7), hull, Color("a68a66"))
	Meshes.box(st, Vector3(1.4, 0.7, 0.8), Vector3(w - 2.8, 0.9, d - 1.4), white)
	Meshes.box(st, Vector3(1.8, 1.6, 0.9), Vector3(w - 3.6, 0.5, d - 1.6), white.darkened(0.05))
	var mid := w * 0.5
	Meshes.box(st, Vector3(mid - 1.0, 0.4, d - 0.55), Vector3(2.0, 1.0, 0.55), white.darkened(0.1))
	Meshes.box(st, Vector3(mid - 1.0, 0.4, 0.0), Vector3(2.0, 1.0, 0.55), white.darkened(0.1))
	Meshes.cylinder(st, Vector3(mid - 0.9, 1.6, d * 0.5), 0.34, 1.2, 8, Color("d8b878"))
	Meshes.cylinder(st, Vector3(mid - 0.9, 2.8, d * 0.5), 0.3, 0.3, 8, Color("1d1d1d"))
	Meshes.cylinder(st, Vector3(mid + 0.9, 1.6, d * 0.5), 0.34, 1.2, 8, Color("d8b878"))
	Meshes.cylinder(st, Vector3(mid + 0.9, 2.8, d * 0.5), 0.3, 0.3, 8, Color("1d1d1d"))
	Meshes.box(st, Vector3(w - 1.2, 0.7, d * 0.5 - 0.03), Vector3(0.06, 1.8, 0.06), Color("5a4636"))
	for x in range(2, w - 2, 1):
		_window(st, wst, x + 0.27, 0.95, d - 0.53, 0.46, 0.4, white.darkened(0.15))
	Meshes.box(st, Vector3(door_x + 0.22, 0.7, d - 0.66), Vector3(0.56, 0.9, 0.08), DOOR_WOOD)


# --- the Outer Hebrides (Harris, Lewis, Stornoway) -------------------------------------------------------------

const LEWIS_GREY := Color("8c8a84")
const CROFT_BLACK := Color("34373d")

static func _hebrides(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, style: String) -> void:
	match style:
		"blackhouse":
			_blackhouse(st, wst, w, d, door_x)
		"croft_house":
			_croft_house(st, wst, w, d, door_x, rng)
		"granite_house":
			_house(st, wst, w, d, door_x, rng, LEWIS_GREY.lightened(rng.randf_range(-0.04, 0.06)), SLATE, 2, false, false)
		"harbour_white":
			_house(st, wst, w, d, door_x, rng, HARLS[0].lightened(0.04), SLATE.darkened(0.1), 2, false, false)
		"lews_castle":
			_lews_castle(st, wst, w, d, door_x)

## A blackhouse (taigh dubh): drystone walls a yard thick, rounded at the corners, with a hipped thatch roof set
## on the wall head so the rain runs off outside the stone. Ropes weighted with stones hold the thatch down in the
## gale, and there is no chimney: the peat smoke seeps up through the straw.
static func _blackhouse(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("7f7b70")
	var thatch := Color("8e7545")
	var rope := Color("4a3b2a")
	var hgt := 0.95
	Meshes.box(st, Vector3(0.12, 0, 0.12), Vector3(w - 0.24, hgt, d - 0.24), stone, stone.darkened(0.2))
	for cx in [0.14, w - 0.14]:
		for cz in [0.14, d - 0.14]:
			Meshes.cylinder(st, Vector3(cx, 0, cz), 0.24, hgt, 7, stone.darkened(0.04))
	var y := 0.28
	while y < hgt - 0.1:
		Meshes.box(st, Vector3(0.08, y, d - 0.16), Vector3(w - 0.16, 0.03, 0.05), stone.darkened(0.3))
		y += 0.27
	Meshes.box(st, Vector3(-0.02, hgt - 0.08, -0.02), Vector3(w + 0.04, 0.14, d + 0.04), stone.lightened(0.1))
	var e := 0.2
	var rh := hgt + minf(0.95, d * 0.4)
	var r0 := Vector3(0.5, rh, d * 0.5)
	var r1 := Vector3(w - 0.5, rh, d * 0.5)
	var a := Vector3(-e, hgt - 0.05, -e)
	var b := Vector3(w + e, hgt - 0.05, -e)
	var c := Vector3(w + e, hgt - 0.05, d + e)
	var dd := Vector3(-e, hgt - 0.05, d + e)
	Meshes._quad(st, r0, r1, c, dd, thatch)
	Meshes._quad(st, r1, r0, a, b, thatch.darkened(0.15))
	Meshes._tri(st, r0, dd, a, thatch.darkened(0.08))
	Meshes._tri(st, r1, b, c, thatch.darkened(0.2))
	Meshes._quad(st, dd, c, b, a, thatch.darkened(0.5))
	Meshes.box(st, Vector3(0.4, rh - 0.08, d * 0.5 - 0.12), Vector3(w - 0.8, 0.14, 0.24), thatch.darkened(0.1))  # ridge
	var lift := Vector3(0, 0.02, 0.012)
	var x := 0.3
	while x < w - 0.1:
		var tx := clampf(x, 0.5, w - 0.5)
		Meshes._quad(st, Vector3(tx, rh, d * 0.5) + lift, Vector3(tx + 0.035, rh, d * 0.5) + lift, Vector3(x + 0.035, hgt - 0.05, d + e) + lift, Vector3(x, hgt - 0.05, d + e) + lift, rope)
		Meshes.box(st, Vector3(x - 0.05, hgt - 0.3, d + e - 0.04), Vector3(0.12, 0.14, 0.1), stone.lightened(0.05))  # the weighting stone
		x += 0.5
	_chimneys.append(Vector3(w * 0.5, rh + 0.05, d * 0.5))  # the smoke finds its own way out
	for i in w:
		if i != door_x and i % 2 == 0:
			_window(st, wst, i + 0.35, 0.45, d - 0.1, 0.28, 0.3, Color("d9d3c4"))
	_door(st, door_x, d - 0.1, stone, 0.8)

## A Hebridean croft house: a long white-harled cottage with a black felt roof, a chimney on each gable, a little
## porch and small sash windows either side of the door.
static func _croft_house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var wall := HARLS[0].lightened(0.05)
	var hgt := 1.45
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), wall, wall.darkened(0.1))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), wall.darkened(0.3))
	_roof(st, w, d, hgt, CROFT_BLACK, wall, 0.5)
	for cx in [0.04, w - 0.4]:
		Meshes.box(st, Vector3(cx, hgt - 0.1, d * 0.5 - 0.2), Vector3(0.36, 1.25, 0.4), wall.darkened(0.12))
		Meshes.box(st, Vector3(cx - 0.03, hgt + 1.15, d * 0.5 - 0.23), Vector3(0.42, 0.07, 0.46), Color("8e887c"))
		_chimneys.append(Vector3(cx + 0.18, hgt + 1.25, d * 0.5))
	var trim: Color = [Color("2f5d8a"), Color("b03a2e"), Color("2f7a55"), Color("e8e2d2")][rng.randi() % 4]
	for i in w:
		if i != door_x:
			_window(st, wst, i + 0.25, 0.5, d, 0.5, 0.6, trim)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.08, 0.0, d - 0.04), Vector3(0.84, 1.15, 0.32), wall)  # the porch
		Meshes.box(st, Vector3(door_x + 0.02, 1.15, d - 0.06), Vector3(0.96, 0.1, 0.4), CROFT_BLACK)
		Meshes.box(st, Vector3(door_x + 0.28, 0.0, d + 0.24), Vector3(0.44, 0.95, 0.06), trim)

## Lews Castle, Stornoway: a Tudor-Gothic pile in grey stone with battlements, a tall corner tower, a gabled
## entrance and rows of mullioned windows, built in the 1850s on the money from the Mathesons' China trade.
static func _lews_castle(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var stone := Color("8e8a80")
	var hgt := 2.6
	Meshes.box(st, Vector3(0.05, 0, 0.1), Vector3(w - 0.1, hgt, d - 0.2), stone, stone.darkened(0.25))
	Meshes.box(st, Vector3(0, 0, 0.05), Vector3(w, 0.2, d - 0.1), stone.darkened(0.25))
	Meshes.box(st, Vector3(-0.04, hgt - 0.08, 0.04), Vector3(w + 0.08, 0.14, d - 0.08), stone.lightened(0.12))
	_merlons(st, 0, w, 0.04, hgt + 0.06, stone, true)
	_merlons(st, 0, w, d - 0.64, hgt + 0.06, stone, true)
	_merlons(st, 0, d, 0.0, hgt + 0.06, stone, false)
	_merlons(st, 0, d, w - 0.6, hgt + 0.06, stone, false)
	# the great tower at the west front corner, and a lesser one at the east, each ringed with merlons
	for t in [Vector3(0.9, 0, d - 1.1), Vector3(w - 0.9, 0, d - 1.1)]:
		var th := 4.4 if t.x < 2.0 else 3.6
		Meshes.cylinder(st, t, 0.95, th, 8, stone.lightened(0.04))
		Meshes.cylinder(st, t + Vector3(0, th, 0), 1.08, 0.28, 8, stone.lightened(0.14))
		for k in 8:
			var ang := TAU * k / 8.0
			Meshes.box(st, t + Vector3(cos(ang) * 0.95 - 0.12, th + 0.28, sin(ang) * 0.95 - 0.12), Vector3(0.24, 0.26, 0.24), stone.lightened(0.18))
	# the gabled entrance bay
	var cx := door_x + 0.5
	Meshes.box(st, Vector3(cx - 1.0, 0, d - 0.9), Vector3(2.0, hgt + 0.7, 0.95), stone.lightened(0.06))
	Meshes._tri(st, Vector3(cx - 1.0, hgt + 0.7, d - 0.05), Vector3(cx + 1.0, hgt + 0.7, d - 0.05), Vector3(cx, hgt + 1.55, d - 0.05), stone.lightened(0.1))
	Meshes.box(st, Vector3(cx - 0.35, 0.0, d + 0.04), Vector3(0.7, 1.35, 0.07), Color("2a221e"))
	Meshes.box(st, Vector3(cx - 0.5, 1.35, d + 0.03), Vector3(1.0, 0.12, 0.1), stone.lightened(0.25))
	for i in w:
		if absi(i - door_x) > 1 and i > 1 and i < w - 2:
			_window(st, wst, i + 0.3, 0.55, d - 0.1, 0.4, 0.7, stone.lightened(0.25))
			_window(st, wst, i + 0.3, 1.65, d - 0.1, 0.4, 0.7, stone.lightened(0.25))
	_window(st, wst, cx - 0.2, 1.9, d + 0.06, 0.4, 0.55, stone.lightened(0.25))
# --- The Cotswolds and Oxford (3.0 Wider Isles) -------------------------------------------------------------
# Honey-gold oolitic limestone with steep stone-slate roofs and end-stack chimneys for the villages; softer,
# greyer Headington and Taynton stone, parapets, gate towers and lead domes for Oxford.

const COTS_HONEY := Color("d8b46c")   # Cotswold limestone, honey-gold in low sun
const COTS_SLATE := Color("85765c")   # stone slates, lichened grey-ochre
const OX_STONE := Color("c8b07e")     # Oxford's college stone, a little greyer than the Cotswold gold
const OX_LEAD := Color("6f7e78")      # lead roofs and domes, weathered green-grey
const COTS_PROPS := ["sighs_bridge", "cheese_wheel"]

static func cotswolds_building(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, style: String) -> void:
	match style:
		"cotswold_house":
			_cots_house(st, wst, w, d, door_x, rng, 2)
		"cotswold_cottage":
			_cots_house(st, wst, w, d, door_x, rng, 1)
		"wool_church":
			_wool_church(st, wst, w, d, door_x, rng)
		"oxford_college":
			_oxford_college(st, wst, w, d, door_x, rng)
		"oxford_tower":
			_oxford_tower(st, wst, w, d, door_x, rng)
		"oxford_church":
			_oxford_church(st, wst, w, d, door_x, rng)
		"radcliffe_camera":
			_radcliffe(st, wst, w, d, door_x, rng)

## A gabled roof with its ridge running north-south, the gable facing south (a dormer, a porch).
static func _gable_roof(st: SurfaceTool, x0: float, x1: float, zb: float, zf: float, h: float, rise: float, roof: Color, wall: Color) -> void:
	var a := Vector3(x0, h, zb)
	var b := Vector3(x1, h, zb)
	var c := Vector3(x1, h, zf)
	var dd := Vector3(x0, h, zf)
	var r0 := Vector3((x0 + x1) * 0.5, h + rise, zb)
	var r1 := Vector3((x0 + x1) * 0.5, h + rise, zf)
	Meshes._quad(st, r1, r0, a, dd, roof)
	Meshes._quad(st, r0, r1, c, b, roof.darkened(0.15))
	Meshes._tri(st, dd, c, r1, wall.lightened(0.03))
	Meshes._tri(st, b, a, r0, wall.darkened(0.06))

## A Cotswold wool church: wide and airy, with big traceried windows, buttresses, a stone-slate nave roof, a south
## porch and a battlemented west tower with a pinnacle at each corner (the wool merchants paid for the lot).
static func _wool_church(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var stone := COTS_HONEY.lightened(0.03)
	var light := stone.lightened(0.16)
	var tw := mini(3, w - 3)
	var nave_h := 2.7
	Meshes.box(st, Vector3(tw, 0, 0.3), Vector3(w - tw, nave_h, d - 0.6), stone, stone.darkened(0.1))
	_roof_at(st, tw, w, 0.3, d - 0.3, nave_h, 1.25, COTS_SLATE, stone)
	for x in range(tw + 1, w, 2):
		Meshes.box(st, Vector3(x - 0.08, 0, d - 0.42), Vector3(0.16, 2.3, 0.18), stone.darkened(0.06))
	for x in range(tw, w):
		if absi(x - door_x) > 1:
			_window(st, wst, x + 0.2, 0.55, d - 0.2, 0.6, 1.75, light)
	var th := 5.6
	Meshes.box(st, Vector3(0, 0, 0.1), Vector3(tw, th, d - 0.2), stone.lightened(0.02), stone.darkened(0.1))
	for y in [1.9, 3.6]:
		Meshes.box(st, Vector3(-0.03, y, 0.07), Vector3(tw + 0.06, 0.08, d - 0.14), light)
	_window(st, wst, tw * 0.5 - 0.22, 4.0, d, 0.44, 1.3, light)
	_window(st, wst, tw * 0.5 - 0.22, 0.8, d, 0.44, 1.0, light)
	Meshes.box(st, Vector3(-0.07, th, 0.03), Vector3(tw + 0.14, 0.18, d - 0.06), light)
	_merlons(st, 0.0, float(tw), d - 0.12, th + 0.18, stone, true)
	_merlons(st, 0.0, float(tw), 0.08, th + 0.18, stone, true)
	for c in [Vector2(-0.05, 0.05), Vector2(tw - 0.25, 0.05), Vector2(-0.05, d - 0.35), Vector2(tw - 0.25, d - 0.35)]:
		Meshes.box(st, Vector3(c.x, th + 0.18, c.y), Vector3(0.3, 0.4, 0.3), light)
		Meshes.cone(st, Vector3(c.x + 0.15, th + 0.58, c.y + 0.15), 0.18, 0.7, 4, light, rng)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x - 0.1, 0, d - 0.5), Vector3(1.2, 1.7, 0.66), stone.lightened(0.03))
		_gable_roof(st, door_x - 0.16, door_x + 1.16, d - 0.55, d + 0.2, 1.7, 0.55, COTS_SLATE, stone)
		Meshes.box(st, Vector3(door_x + 0.22, 0, d + 0.14), Vector3(0.56, 1.2, 0.05), Color("3b2a22"))

## A Cotswold house or cottage: honey limestone, a steep stone-slate roof with gabled dormers, a chimney on each
## gable end, and pale mullioned windows. storeys 1 gives the low cottage, with its eaves almost to the door.
static func _cots_house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, storeys: int) -> void:
	var hgt := 1.15 * storeys + 0.2
	var wall := COTS_HONEY.darkened(rng.randf_range(0.0, 0.06))
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), wall, wall.darkened(0.1))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.16, d), wall.darkened(0.28))
	if storeys > 1:
		Meshes.box(st, Vector3(-0.02, 1.3, d - 0.03), Vector3(w + 0.04, 0.07, 0.07), wall.lightened(0.14))
	_roof(st, w, d, hgt, COTS_SLATE, wall, 0.64)
	var rise := minf(1.2, d * 0.64)
	for cx in [0.08, w - 0.48]:
		Meshes.box(st, Vector3(cx, hgt, d * 0.5 - 0.2), Vector3(0.4, rise + 0.55, 0.4), wall.darkened(0.12))
		Meshes.box(st, Vector3(cx - 0.03, hgt + rise + 0.55, d * 0.5 - 0.23), Vector3(0.46, 0.08, 0.46), wall.lightened(0.12))
		_chimneys.append(Vector3(cx + 0.2, hgt + rise + 0.7, d * 0.5))
	if storeys > 1 and w >= 3:
		var slope := rise / (d * 0.5 + 0.18)
		var zf := d - 0.2
		var yb := hgt + slope * (d + 0.18 - zf) - 0.05
		for i in range(0, w - 1, 2):
			var x0 := i + 0.55
			Meshes.box(st, Vector3(x0, yb, zf - 0.5), Vector3(0.7, 0.62, 0.5), wall.lightened(0.04))
			_gable_roof(st, x0 - 0.06, x0 + 0.76, zf - 0.55, zf + 0.06, yb + 0.62, 0.32, COTS_SLATE.darkened(0.05), wall)
			_window(st, wst, x0 + 0.17, yb + 0.1, zf + 0.04, 0.36, 0.38, wall.lightened(0.3))
	_door(st, door_x, d, wall)
	var pale := wall.lightened(0.3)
	for s in storeys:
		var wy := 0.42 + 1.15 * s
		for x in w:
			if x == door_x and s == 0:
				continue
			_window(st, wst, x + 0.2, wy, d, 0.6, 0.5, pale)
			Meshes.box(st, Vector3(x + 0.47, wy - 0.04, d - 0.045), Vector3(0.05, 0.56, 0.04), pale)

## An Oxford college front: three storeys of golden stone, a crenellated parapet, a gate tower with an oriel window
## and pinnacles over the door, and a lead roof set back out of sight.
static func _oxford_college(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var hgt := 3.3
	var stone := OX_STONE.darkened(rng.randf_range(0.0, 0.05))
	var light := stone.lightened(0.16)
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, hgt, d - 0.1), stone, stone.darkened(0.12))
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.22, d), stone.darkened(0.3))
	for y in [1.15, 2.25]:
		Meshes.box(st, Vector3(-0.03, y, d - 0.04), Vector3(w + 0.06, 0.07, 0.08), light)
	Meshes.box(st, Vector3(-0.05, hgt - 0.1, d - 0.3), Vector3(w + 0.1, 0.16, 0.34), light)
	_merlons(st, 0.0, float(w), d - 0.2, hgt + 0.06, stone, true)
	# the roof, a low lead pitch behind the parapet with stacks along its ridge
	_roof_at(st, 0.15, w - 0.15, 0.15, d - 0.3, hgt, 0.85, OX_LEAD.darkened(0.05), stone)
	var sx := 0.8
	while sx < w - 0.6:
		Meshes.box(st, Vector3(sx, hgt + 0.55, d * 0.5 - 0.1), Vector3(0.36, 0.7, 0.36), stone.darkened(0.12))
		Meshes.box(st, Vector3(sx - 0.03, hgt + 1.22, d * 0.5 - 0.13), Vector3(0.42, 0.08, 0.42), light)
		_chimneys.append(Vector3(sx + 0.18, hgt + 1.35, d * 0.5 + 0.08))
		sx += 2.6
	var has_gate := door_x >= 0 and w >= 5
	if has_gate:
		var gx := door_x - 0.55
		Meshes.box(st, Vector3(gx, 0, d - 0.4), Vector3(2.1, hgt + 1.1, 0.55), stone.lightened(0.05), stone)
		Meshes.box(st, Vector3(gx - 0.06, hgt + 1.1, d - 0.45), Vector3(2.22, 0.16, 0.65), light)
		_merlons(st, gx, gx + 2.1, d - 0.22, hgt + 1.26, stone, true)
		Meshes.box(st, Vector3(gx + 0.4, 1.35, d + 0.1), Vector3(1.3, 0.7, 0.3), light)  # the oriel
		Meshes.box(wst, Vector3(gx + 0.5, 1.45, d + 0.405), Vector3(1.1, 0.5, 0.04), window_colour(_wr))
		Meshes.box(st, Vector3(gx + 0.38, 2.05, d + 0.08), Vector3(1.34, 0.1, 0.34), stone.darkened(0.1))
		Meshes.box(st, Vector3(door_x + 0.12, 2.8, d + 0.05), Vector3(0.76, 0.9, 0.08), stone.darkened(0.18))  # a niche for the founder
		Meshes.box(st, Vector3(door_x + 0.32, 2.85, d + 0.1), Vector3(0.36, 0.7, 0.06), light)
		for px in [gx - 0.02, gx + 1.82]:
			Meshes.box(st, Vector3(px, hgt + 1.26, d - 0.42), Vector3(0.3, 0.4, 0.3), light)
			Meshes.cone(st, Vector3(px + 0.15, hgt + 1.66, d - 0.27), 0.19, 0.5, 4, light, rng)
	for x in w:
		if has_gate and absi(x - door_x) <= 1:
			continue
		for y in [0.5, 1.6, 2.65]:
			_window(st, wst, x + 0.22, y, d, 0.56, 0.62 if y < 2.0 else 0.5, light)
			Meshes.box(st, Vector3(x + 0.47, y - 0.04, d - 0.045), Vector3(0.06, 0.7, 0.04), light)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.12, 0.2, d + 0.12 if has_gate else d - 0.1), Vector3(0.76, 1.15, 0.06), Color("2a1f1a"))
		Meshes.box(st, Vector3(door_x + 0.06, 1.35, d + 0.1 if has_gate else d - 0.12), Vector3(0.88, 0.1, 0.1), light)

## A square Oxford tower: stone stages with string courses, a clock on the face, paired belfry windows and a
## battlemented top with a pinnacle at each corner (Carfax, Magdalen).
static func _oxford_tower(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var th := 6.4
	var tx := 0.25
	var tw := w - 0.5
	var td := d - 0.5
	var stone := OX_STONE.darkened(0.03)
	var light := stone.lightened(0.16)
	Meshes.box(st, Vector3(0.1, 0, 0.1), Vector3(w - 0.2, 0.3, d - 0.2), stone.darkened(0.25))
	Meshes.box(st, Vector3(tx, 0, 0.25), Vector3(tw, th, td), stone, stone.darkened(0.12))
	for y in [1.7, 3.3, 5.0]:
		Meshes.box(st, Vector3(tx - 0.03, y, 0.22), Vector3(tw + 0.06, 0.08, td + 0.06), light)
	var fz := 0.25 + td
	_window(st, wst, w * 0.5 - 0.5, 4.0, fz + 0.1, 0.36, 1.0, light)
	_window(st, wst, w * 0.5 + 0.14, 4.0, fz + 0.1, 0.36, 1.0, light)
	_window(st, wst, w * 0.5 - 0.2, 0.9, fz + 0.1, 0.4, 0.9, light)
	# the clock face and its hands
	Meshes.box(st, Vector3(w * 0.5 - 0.4, 2.15, fz - 0.01), Vector3(0.8, 0.8, 0.06), Color("e9e2cf"))
	Meshes.box(st, Vector3(w * 0.5 - 0.03, 2.5, fz + 0.05), Vector3(0.06, 0.28, 0.03), Color("26221e"))
	Meshes.box(st, Vector3(w * 0.5 - 0.03, 2.5, fz + 0.05), Vector3(0.22, 0.06, 0.03), Color("26221e"))
	Meshes.box(st, Vector3(tx - 0.08, th, 0.17), Vector3(tw + 0.16, 0.2, td + 0.16), light)
	_merlons(st, tx, tx + tw, 0.17, th + 0.2, stone, true)
	_merlons(st, tx, tx + tw, fz - 0.05, th + 0.2, stone, true)
	_merlons(st, 0.25, 0.25 + td, tx - 0.05, th + 0.2, stone, false)
	_merlons(st, 0.25, 0.25 + td, tx + tw - 0.25, th + 0.2, stone, false)
	for c in [Vector2(tx - 0.08, 0.17), Vector2(tx + tw - 0.2, 0.17), Vector2(tx - 0.08, fz - 0.12), Vector2(tx + tw - 0.2, fz - 0.12)]:
		Meshes.box(st, Vector3(c.x, th + 0.2, c.y), Vector3(0.28, 0.35, 0.28), light)
		Meshes.cone(st, Vector3(c.x + 0.14, th + 0.55, c.y + 0.14), 0.18, 0.6, 4, light, rng)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.2, 0.3, fz - 0.06), Vector3(0.6, 0.9, 0.08), Color("2a1f1a"))

## The University Church of St Mary the Virgin: a Gothic nave and a west tower topped by a tall, slim spire,
## the one the skyline's "dreaming spires" are named for (more or less).
static func _oxford_church(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var tw := mini(3, w - 2)
	var nave_h := 2.5
	var stone := OX_STONE.darkened(0.02)
	var light := stone.lightened(0.15)
	Meshes.box(st, Vector3(tw, 0, 0.3), Vector3(w - tw, nave_h, d - 0.6), stone, stone.darkened(0.1))
	_roof_at(st, tw, w, 0.3, d - 0.3, nave_h, 1.2, OX_LEAD, stone)
	var th := 4.7
	Meshes.box(st, Vector3(0.1, 0, 0.1), Vector3(tw - 0.2, th, d - 0.2), stone.lightened(0.02), stone.darkened(0.1))
	Meshes.box(st, Vector3(0.0, th, 0.0), Vector3(tw, 0.2, d), light)
	Meshes.cone(st, Vector3(tw * 0.5, th + 0.2, d * 0.5), minf(tw, d) * 0.46, 4.2, 8, stone.lightened(0.08), rng)
	for c in [Vector2(0.0, 0.0), Vector2(tw - 0.3, 0.0), Vector2(0.0, d - 0.3), Vector2(tw - 0.3, d - 0.3)]:
		Meshes.box(st, Vector3(c.x, th + 0.2, c.y), Vector3(0.3, 0.45, 0.3), light)
		Meshes.cone(st, Vector3(c.x + 0.15, th + 0.65, c.y + 0.15), 0.17, 0.7, 4, light, rng)
	for x in range(tw, w):
		_window(st, wst, x + 0.3, 0.55, d - 0.2, 0.4, 1.5, light)
	_window(st, wst, tw * 0.5 - 0.22, 2.8, d, 0.44, 1.3, light)
	_window(st, wst, tw * 0.5 - 0.22, 0.9, d, 0.44, 1.0, light)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.15, 0, d - 0.05), Vector3(0.7, 1.3, 0.08), Color("3b2a22"))

## The Radcliffe Camera (1749): a round, domed library on a rusticated base, a ring of columns, an attic with
## windows, a lead dome and a lantern. Footprint about 7 x 7; the door faces south.
static func _radcliffe(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var cx := w * 0.5
	var cz := d * 0.5
	var stone := OX_STONE.lightened(0.07)
	Meshes.box(st, Vector3(0.1, 0, 0.1), Vector3(w - 0.2, 0.14, d - 0.2), stone.darkened(0.2))
	Meshes.cylinder(st, Vector3(cx, 0.14, cz), 3.0, 0.7, 16, stone.darkened(0.08))
	Meshes.cylinder(st, Vector3(cx, 0.84, cz), 2.62, 2.0, 16, stone)
	for i in 16:
		var a := TAU * i / 16.0
		Meshes.cylinder(st, Vector3(cx + cos(a) * 2.82, 0.84, cz + sin(a) * 2.82), 0.1, 2.0, 5, stone.lightened(0.12))
	Meshes.cylinder(st, Vector3(cx, 2.84, cz), 3.0, 0.2, 16, stone.lightened(0.14))
	Meshes.cylinder(st, Vector3(cx, 3.04, cz), 2.4, 0.95, 16, stone.lightened(0.03))
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		Meshes.box(wst, Vector3(cx + cos(a) * 2.38 - 0.16, 3.2, cz + sin(a) * 2.38 - 0.16), Vector3(0.32, 0.5, 0.32), window_colour(_wr))
	Meshes.cylinder(st, Vector3(cx, 3.99, cz), 2.52, 0.14, 16, stone.lightened(0.16))
	for k in [[2.25, 0.42], [1.95, 0.4], [1.55, 0.38], [1.1, 0.34], [0.62, 0.3]]:
		var y: float = 4.13 + (2.25 - float(k[0])) * 0.75
		Meshes.cylinder(st, Vector3(cx, y, cz), k[0], k[1], 16, OX_LEAD.lightened(0.04 * (2.25 - k[0])))
	Meshes.cylinder(st, Vector3(cx, 5.35, cz), 0.36, 0.55, 8, stone.lightened(0.1))
	Meshes.cone(st, Vector3(cx, 5.9, cz), 0.44, 0.55, 8, OX_LEAD, rng)
	if door_x >= 0:
		Meshes.box(st, Vector3(cx - 0.34, 0.14, cz + 2.98), Vector3(0.68, 1.15, 0.08), Color("2a1f1a"))
		Meshes.box(st, Vector3(cx - 0.45, 1.3, cz + 2.96), Vector3(0.9, 0.1, 0.12), stone.lightened(0.2))

# --- Cotswolds and Oxford props ------------------------------------------------------------------------------

static func cots_prop(name: String, variant: int) -> ArrayMesh:
	match name:
		"sighs_bridge":
			return sighs_bridge(variant)
		"cheese_wheel":
			return cheese_wheel(variant)
	return Meshes.rock(0)

## Hertford's Bridge of Sighs: an enclosed stone gallery with traceried windows on an arch, between the two halves
## of the college. `variant` is the width of the lane it crosses, in tiles, running east from its tile.
static func sighs_bridge(variant := 3) -> ArrayMesh:
	var st := Meshes._st()
	var n := maxi(1, variant)
	var x0 := -0.5
	var x1 := n - 0.5
	var stone := OX_STONE.lightened(0.04)
	var light := stone.lightened(0.18)
	var glass := Color("37444a")
	for xe in [x0 - 0.55, x1 - 0.05]:  # the college walls the bridge springs from
		Meshes.box(st, Vector3(xe, 0, -0.5), Vector3(0.6, 3.1, 1.0), stone.darkened(0.04))
	# the arch beneath: stepped stones over a clear opening
	var segs := 6
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var xa := lerpf(x0, x1, t0)
		var xb := lerpf(x0, x1, t1)
		var yy := maxf(1.55 + 0.4 * sin(PI * t0), 1.55 + 0.4 * sin(PI * t1))
		Meshes.box(st, Vector3(xa, yy, -0.4), Vector3(xb - xa, 1.7 - yy, 0.8), stone.darkened(0.06))
	Meshes.box(st, Vector3(x0, 1.7, -0.4), Vector3(x1 - x0, 1.15, 0.8), stone)
	Meshes.box(st, Vector3(x0 - 0.02, 1.62, -0.44), Vector3(x1 - x0 + 0.04, 0.1, 0.88), light)
	Meshes.box(st, Vector3(x0 - 0.02, 2.82, -0.44), Vector3(x1 - x0 + 0.04, 0.12, 0.88), light)
	var x := x0 + 0.12
	while x < x1 - 0.3:  # the traceried windows, both faces
		for z in [0.4, -0.45]:
			Meshes.box(st, Vector3(x, 1.95, z), Vector3(0.26, 0.55, 0.05), glass)
			Meshes.box(st, Vector3(x + 0.11, 1.95, z + (0.02 if z > 0 else -0.01)), Vector3(0.04, 0.55, 0.04), light)
			Meshes.box(st, Vector3(x + 0.02, 2.5, z + (0.01 if z > 0 else 0.0)), Vector3(0.22, 0.12, 0.05), glass)
		x += 0.38
	var mx := x0
	while mx < x1 - 0.3:
		Meshes.box(st, Vector3(mx, 2.94, -0.44), Vector3(0.3, 0.26, 0.2), stone.lightened(0.05))
		Meshes.box(st, Vector3(mx, 2.94, 0.24), Vector3(0.3, 0.26, 0.2), stone.lightened(0.05))
		mx += 0.6
	return Meshes._finish(st)

## A Double Gloucester: 0 a whole wheel with a wedge out of it, 1 a stack of three, 2 the prize wheel on its edge
## (the cheese-rolling at Cooper's Hill), wrapped in a ribbon.
static func cheese_wheel(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rind := Color("c97a2c")
	var paste := Color("e9a63c")
	match variant:
		1:
			for k in 3:
				Meshes.cylinder(st, Vector3(0, k * 0.24, 0), 0.36 - k * 0.03, 0.23, 12, rind.lightened(0.05 * k))
				Meshes.cylinder(st, Vector3(0, k * 0.24 + 0.19, 0), 0.33 - k * 0.03, 0.05, 12, paste)
		2:
			var pts := []
			for k in 12:
				var a := -TAU * k / 12.0
				pts.append(Vector2(sin(a) * 0.4, 0.42 + cos(a) * 0.4))
			_prism(st, pts, -0.13, 0.13, rind)
			Meshes.box(st, Vector3(-0.41, 0.4, -0.15), Vector3(0.82, 0.07, 0.3), Color("c8323a"))  # the ribbon
			Meshes.box(st, Vector3(-0.04, 0.0, -0.15), Vector3(0.08, 0.84, 0.3), Color("c8323a"))
		_:
			Meshes.cylinder(st, Vector3(0, 0, 0), 0.4, 0.3, 14, rind)
			Meshes.cylinder(st, Vector3(0, 0.26, 0), 0.36, 0.06, 14, paste)
			Meshes.box(st, Vector3(0.05, 0.0, 0.0), Vector3(0.4, 0.32, 0.18), paste.darkened(0.12))  # the cut wedge
	return Meshes._finish(st)
