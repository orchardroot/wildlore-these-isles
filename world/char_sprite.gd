class_name CharSprite
extends Sprite3D
## A pixel-art character billboard. Sheet: 3 columns x 4 rows of 32x48 (rows down, left, right, up;
## columns step-left, stand, step-right). Falls back to a placeholder when the art is missing.
## Standing still for a few seconds, a character breathes: a one-pixel rise and fall. `walk_rate` is the walk
## cycle's speed (the player's run sets it faster).

const WALK_RATE := 8.0       # walk-cycle frames per second
const RUN_RATE := 13.0
const BREATHE_AFTER := 3.0   # seconds standing before the breathing starts
const BREATHE_PERIOD := 2.6  # seconds per breath

const ROWS := {"down": 0, "left": 1, "right": 2, "up": 3}
const GROUP := "char_sprite"

## Medium and High graphics: characters drawn with char_sprite.gdshader (never lost in shadow, a faint rim) and a
## firmer shadow at their feet. Set by the overworld from the quality setting; Low leaves the plain sprite.
static var crisp := false
static var _shader: Shader

var facing := "down"
var _walk_t := 0.0
var walking := false
var walk_rate := WALK_RATE
var _idle_t := 0.0
var _base_offset := Vector2.ZERO
var _single := false   # "creature:<id>": a wild creature standing in the world, drawn from its 2-frame icon
var _blob: MeshInstance3D

func setup(sprite_id: String) -> void:
	var path := "res://art/sprites/chars/%s.png" % sprite_id
	if not ResourceLoader.exists(path):
		path = "res://art/sprites/chars/_placeholder.png"
	texture = load(path) if ResourceLoader.exists(path) else _fallback()
	hframes = 3
	vframes = 4
	if sprite_id.begins_with("creature:"):
		var cpath := "res://art/sprites/creatures/%s_icon.png" % sprite_id.substr(9)
		if ResourceLoader.exists(cpath):
			texture = load(cpath)
			_single = true
			hframes = maxi(1, texture.get_width() / 32)
			vframes = 1
	pixel_size = 1.0 / 32.0
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = true
	double_sided = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	centered = true
	offset = Vector2(0, 16) if _single else Vector2(0, 24)
	_base_offset = offset
	_apply()
	var blob := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.7, 0.42)
	q.orientation = PlaneMesh.FACE_Y
	blob.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = _blob_tex()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0, 0, 0, 0.45)
	blob.material_override = m
	blob.position = Vector3(0, 0.02, 0)
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blob)
	_blob = blob
	add_to_group(GROUP)
	set_crisp(crisp)

## The player, painted from a look recipe (see Looks and LookArt) instead of a sheet on disk. Cached per recipe.
func setup_recipe(recipe: Dictionary) -> void:
	setup("_placeholder")
	texture = LookArt.texture(recipe)
	set_crisp(crisp)  # the readable-look shader keeps its own copy of the texture

## Every character in the tree switches to (or from) the readable look at once: the quality setting changed.
static func set_crisp_all(tree: SceneTree, on: bool) -> void:
	crisp = on
	if tree:
		for s in tree.get_nodes_in_group(GROUP):
			(s as CharSprite).set_crisp(on)

func set_crisp(on: bool) -> void:
	if on and texture != null:
		if _shader == null:
			_shader = load("res://art/shaders/char_sprite.gdshader")
		var m := material_override as ShaderMaterial
		if m == null:
			m = ShaderMaterial.new()
			m.shader = _shader
			material_override = m
		m.set_shader_parameter("tex", texture)
	else:
		material_override = null
	if _blob:
		var bm := _blob.material_override as StandardMaterial3D
		bm.albedo_color = Color(0, 0, 0, 0.55 if on else 0.45)
		_blob.scale = Vector3(0.9, 1, 0.9) if on else Vector3.ONE

## An uncommon coat on a creature standing in the world (follower, garden visitors); "" leaves it as it is.
func set_coat(variant: String) -> void:
	if _single and variant != "":
		texture = CoatArt.texture(texture, texture.resource_path, variant)
		if material_override:
			set_crisp(true)  # the shader draws its own copy of the texture

func set_facing(dir: String) -> void:
	facing = dir
	_apply()

func _process(delta: float) -> void:
	if walking:
		_walk_t += delta
		_idle_t = 0.0
	else:
		_walk_t = 0.0
		_idle_t += delta
	_apply()
	offset.y = _base_offset.y + breath(_idle_t)

## Pixels to lift a character who has stood still for `idle_t` seconds: 0 or 1, rising on the in-breath.
static func breath(idle_t: float) -> float:
	if idle_t < BREATHE_AFTER:
		return 0.0
	return 1.0 if fmod(idle_t - BREATHE_AFTER, BREATHE_PERIOD) < BREATHE_PERIOD * 0.45 else 0.0

func _apply() -> void:
	if _single:
		frame = (int(_walk_t * 3.0) % hframes) if walking else 0
		return
	var col := 1
	if walking:
		var phase := int(_walk_t * walk_rate) % 4
		col = [0, 1, 2, 1][phase]
	frame = ROWS.get(facing, 0) * 3 + col

static func _fallback() -> Texture2D:
	var img := Image.create(96, 192, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for fy in 4:
		for fx in 3:
			img.fill_rect(Rect2i(fx * 32 + 8, fy * 48 + 8, 16, 38), Color("d0408a"))
	return ImageTexture.create_from_image(img)

static func _blob_tex() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t
