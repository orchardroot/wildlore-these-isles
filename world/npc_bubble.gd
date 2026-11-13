class_name NpcBubble
extends RefCounted
## Little signs over people's heads (wave 54), made only for whoever is close enough to see them: a gold "!" over
## someone with an errand or a swap to offer, a heart over a Regular who likes you, a sparkle over a child who has
## spotted your follower. And umbrellas in drizzle and downpours. The decisions are pure (no autoload names) and
## tested; Npc owns the nodes and frees them again when you walk away.

const ASK := "ask"
const HEART := "heart"
const SPARK := "spark"
const RANGE := 6              # tiles: further than this nobody wears a bubble
const SPOT_RANGE := 4         # tiles: how near the follower must be for a child to spot it
const SPOT_SECS := 3.5        # how long the sparkle shows
const SPOT_COOL := 30.0       # seconds before the same child notices again
const LIKES := 2              # Regulars' favour from which the heart shows (the level they turn up in another town)
const CHILD_WORDS := ["kid", "kids", "child", "lad", "boy", "girl", "lass", "scout", "pupil", "schoolkid", "bairn", "wean"]
const WET := ["drizzle", "downpour"]
const BROLLY_COLOURS := [Color("c0392b"), Color("2c3e8c"), Color("2e7d4f"), Color("d9a21b"), Color("7a3b8c"), Color("2b2b33")]

const ART := {
	ASK: ["..##..", "..##..", "..##..", "..##..", "..##..", "......", "..##..", "..##.."],
	HEART: [".##...##.", "####.####", "#########", "#########", ".#######.", "..#####..", "...###...", "....#...."],
	SPARK: ["....#....", "....#....", "..#.#.#..", "...###...", "#########", "...###...", "..#.#.#..", "....#....", "....#...."],
}
const FILL := {ASK: Color("ffd23f"), HEART: Color("ff5a7a"), SPARK: Color("fff3b0")}

static var _givers := {}          # "zone|npc" -> true, for errand starts; built on first use
static var _built_for := -1
static var _tex := {}             # kind -> ImageTexture
static var _brolly_mesh: Mesh
static var _brolly_mats := {}

# --- decisions (pure) ----------------------------------------------------------------

## Does this person look like a child? By id and name words ("sh_conker_kid", "Boy Scout"); never a trainer.
static func is_child(def: Dictionary) -> bool:
	if str(def.get("trainer", "")) != "":
		return false
	var words := (str(def.get("id", "")) + "_" + str(def.get("name", "")).replace(" ", "_")).to_lower().split("_", false)
	for w in words:
		if w in CHILD_WORDS:
			return true
	return false

static func reset() -> void:
	_givers = {}
	_built_for = -1

static func _build() -> void:
	var list := Errands.quests()
	if _built_for == list.size() and _built_for >= 0:
		return
	_built_for = list.size()
	_givers = {}
	for q in list:
		var s: Dictionary = q.start
		_givers["%s|%s" % [s.get("zone", ""), s.get("npc", "")]] = q

## Is there an errand here waiting to be asked for, or a swap (a want they will trade for) open?
static func has_ask(zone_id: String, npc_id: String, data: GameStateData) -> bool:
	_build()
	var q: Variant = _givers.get("%s|%s" % [zone_id, npc_id])
	if q != null and Quests.status(data, q) == Quests.NOT_STARTED:
		return true
	for t in Wants.for_npc(zone_id, npc_id):
		if Wants.is_open(data, t):
			return true
	return false

## The Regular this person is (bound resident, or a spawned "reg_<id>" / "reg_<id>_away" / "reg_<id>_mums"), or "".
static func regular_of(zone_id: String, def: Dictionary) -> String:
	var id := str(def.get("id", ""))
	var bound := Regulars.bound_id(zone_id, id)
	if bound != "":
		return bound
	if id.begins_with(Regulars.PREFIX):
		var rest := id.substr(Regulars.PREFIX.length())
		for suffix in ["_away", "_mums"]:
			if rest.ends_with(suffix):
				rest = rest.left(rest.length() - suffix.length())
		return rest if not Regulars.get_reg(rest).is_empty() else ""
	return ""

## What shows over this person now: ASK, HEART or "". (The sparkle is the follower's, see Npc.)
static func kind_for(zone_id: String, def: Dictionary, data: GameStateData) -> String:
	if str(def.get("trainer", "")) != "":
		return ""
	var id := str(def.get("id", ""))
	if has_ask(zone_id, id, data):
		return ASK
	var reg := regular_of(zone_id, def)
	if reg != "" and Regulars.favour(data, reg) >= LIKES:
		return HEART
	return ""

static func in_range(a: Vector2i, b: Vector2i, r := RANGE) -> bool:
	return maxi(absi(a.x - b.x), absi(a.y - b.y)) <= r

## Folk outdoors put an umbrella up in rain. Animals, trainers and anyone indoors don't.
static func umbrella_for(weather: String, zone_kind: String, def: Dictionary) -> bool:
	return weather in WET and zone_kind != "interior" and str(def.get("trainer", "")) == "" \
		and not str(def.get("sprite", "")).begins_with("creature:")

# --- nodes -----------------------------------------------------------------------------

## The little pixel sign for `kind`: dark outline, nearest-filtered, cached.
static func icon(kind: String) -> Texture2D:
	if _tex.has(kind):
		return _tex[kind]
	var rows: Array = ART[kind]
	var w: int = str(rows[0]).length()
	var img := Image.create(w + 2, rows.size() + 2, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in w:
			if str(rows[y])[x] != "#":
				continue
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					img.set_pixel(x + 1 + ox, y + 1 + oy, Color("2a1a10"))
	for y in rows.size():
		for x in w:
			if str(rows[y])[x] == "#":
				img.set_pixel(x + 1, y + 1, FILL[kind])
	_tex[kind] = ImageTexture.create_from_image(img)
	return _tex[kind]

## A bubble sprite for `kind`, drawn over everything, floating at `y`.
static func make_bubble(kind: String, y: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = icon(kind)
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.shaded = false
	s.pixel_size = 0.035
	s.position = Vector3(0, y, 0)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return s

## An umbrella: a flat cone canopy on a thin stick, one shared mesh, a colour picked from the person's id.
static func make_umbrella(id: String, y: float) -> Node3D:
	if _brolly_mesh == null:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.34
		cone.height = 0.16
		cone.radial_segments = 10
		cone.rings = 1
		_brolly_mesh = cone
	var root := Node3D.new()
	var canopy := MeshInstance3D.new()
	canopy.mesh = _brolly_mesh
	canopy.material_override = _brolly_mat(BROLLY_COLOURS[hash(id) % BROLLY_COLOURS.size()])
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(canopy)
	root.position = Vector3(0.12, y, 0.05)
	return root

static func _brolly_mat(c: Color) -> StandardMaterial3D:
	if not _brolly_mats.has(c):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.8
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_brolly_mats[c] = m
	return _brolly_mats[c]
