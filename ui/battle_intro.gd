class_name BattleIntro
extends CanvasLayer
## The way into a battle. A short transition that suits where it starts (a grass swipe in tall grass, ripples on
## the water, an iris in caves, the dark and indoors, diagonal bars for a trainer, a slow dark pulse for a legend),
## then for the big fights (Keepers, Kit, Directors, the Four Winds, Garside and Vane) a 1.5 s VS splash: both
## sprites, both names, a stripe in the region's colour. Transitions follow battle speed; the splash can be
## skipped with confirm or cancel. Nothing strobes: Reduce flashing turns the legend's pulse into a plain darken.
## Router.battle plays it and takes over (fully dark) once it is done.

signal finished

const STYLES := ["grass", "ripple", "iris", "bars", "pulse"]
const SECONDS := {"grass": 0.55, "ripple": 0.65, "iris": 0.5, "bars": 0.6, "pulse": 1.1}
const VS_CLASSES := ["Keeper", "Rival", "Director", "Wind", "Champion", "Lord"]
const VS_SECONDS := 1.5
const SKIP_ACTIONS := ["confirm", "cancel"]
const WATER_TILES := ["deep_water", "water"]
const CAVE_STAGES := ["cave", "quarry"]
const INK := Color(0.03, 0.03, 0.05)   # Router's fade colour
const REGION_COLOURS := {
	"cheshire": Color("c9a24a"), "peak": Color("8c6b4a"), "manchester": Color("b8433a"), "merseyside": Color("3f6fb5"),
	"north_wales": Color("c8303a"), "mid_wales": Color("3d8b4f"), "south_wales": Color("d0583a"), "midlands": Color("7a5aa8"),
	"south_england": Color("5aa08a"), "cornwall": Color("e0b84a"), "yorkshire": Color("4a86c8"), "north_east": Color("2f3f8f"),
	"cumbria": Color("6f9a5a"), "lancashire": Color("c8452f"), "scotland": Color("2a62b8"), "ireland": Color("2f9e5f"), "ireland_west": Color("5fb06a"),
	"ireland_east": Color("1f7a52"), "man": Color("a3283c"),
	"east_anglia": Color("e0c020"),
}
const DEFAULT_COLOUR := Color("b08a4a")

var style := ""            # a transition, or "" for the VS splash
var duration := 0.5
var elapsed := 0.0
var done := false
var skipped := false
var hold_at := -1.0        # dev screenshots: hold this far through (0..1) and never finish
var reduce := false

var _size := Vector2(1280, 720)
var _root: Control
var _veil: ColorRect
var _centre := Vector2(0.5, 0.55)
var _built := false
var _slammed := false
# the VS splash
var _trainer: Dictionary = {}
var _you_sprite: Variant = "player_a"  # a sheet id, or the player's look recipe (Looks) painted through LookArt
var _you_name := "You"
var _region := ""
var _stripe: Polygon2D
var _them: TextureRect
var _you: TextureRect
var _them_name: Label
var _you_name_label: Label
var _vs: Label

# --- choosing ------------------------------------------------------------------------------------------------

## Which transition: `opts` are Router.battle's, `ctx` what the overworld says about where you are standing
## ({"tile", "dark", "stage", "interior"}; empty with no overworld).
static func choose(opts: Dictionary, ctx: Dictionary) -> String:
	if bool(opts.get("legend", false)):
		return "pulse"
	if str(opts.get("kind", "wild")) == "trainer":
		return "bars"
	if str(ctx.get("tile", "")) in WATER_TILES:
		return "ripple"
	if bool(ctx.get("dark", false)) or str(ctx.get("stage", "")) in CAVE_STAGES or bool(ctx.get("interior", false)):
		return "iris"
	return "grass"

## The big fights get a VS splash first.
static func wants_vs(opts: Dictionary) -> bool:
	if str(opts.get("kind", "wild")) != "trainer":
		return false
	var t = opts.get("trainer", {})
	return t is Dictionary and str(t.get("class", "")) in VS_CLASSES

## Seconds a transition takes at a battle speed (Settings.battle_time_scale).
static func seconds_for(s: String, speed: float) -> float:
	return float(SECONDS.get(s, 0.5)) / maxf(speed, 0.1)

## How much of the screen is covered at progress p (0..1). The shader draws the shape; this drives it.
## The legend's pulse dips twice on the way to dark, unless flashing is reduced (then it only ever darkens).
static func cover(s: String, p: float, reduce_flashing: bool) -> float:
	p = clampf(p, 0.0, 1.0)
	var e := p * p * (3.0 - 2.0 * p)
	if s == "pulse" and not reduce_flashing:
		e = clampf(p + 0.22 * sin(p * TAU * 2.0) * (1.0 - p), 0.0, 1.0)
	return e

static func region_colour(region: String) -> Color:
	return REGION_COLOURS.get(region, DEFAULT_COLOUR)

# --- playing -------------------------------------------------------------------------------------------------

## The whole way in: the transition, then the splash for a big fight. Ends with the screen dark (Router's fade
## then takes over). `host` is where the layers go (Router).
static func play(host: Node, opts: Dictionary, ctx: Dictionary) -> void:
	var t := BattleIntro.new()
	t.setup_transition(choose(opts, ctx), ctx.get("centre", Vector2(0.5, 0.55)), Settings.battle_time_scale(), Settings.reduce_flashing)
	host.add_child(t)
	await t.run()
	if wants_vs(opts):
		var v := BattleIntro.new()
		v.setup_vs(opts.trainer, Looks.recipe(Game.data, Game.items), Game.data.player_name, str(ctx.get("region", "")))
		host.add_child(v)
		t.queue_free()
		await v.run()
		v.queue_free()
	else:
		t.queue_free()

## Dev switch `--intro=<style|vs:trainer>` (with --boot): that transition or splash, held `at` (0..1) of the way.
static func dev_show(host: Node, ow: Node, arg: String, at: float) -> void:
	var ctx: Dictionary = ow.battle_context() if ow else {}
	var t := BattleIntro.new()
	if arg.begins_with("vs:"):
		t.setup_vs(StoryData.trainer(arg.substr(3)), Looks.recipe(Game.data, Game.items), Game.data.player_name, str(ctx.get("region", "")))
	else:
		t.setup_transition(arg, ctx.get("centre", Vector2(0.5, 0.55)), 1.0, Settings.reduce_flashing)
	t.hold_at = clampf(at, 0.0, 1.0)
	host.add_child(t)
	t.advance(0.0)

func setup_transition(s: String, centre_uv: Vector2, speed: float, reduce_flashing: bool) -> void:
	style = s
	_centre = centre_uv
	duration = seconds_for(s, speed)
	reduce = reduce_flashing

## `you_sprite` is a sprite id (a sheet in art/sprites/chars) or the player's recipe Dictionary (see Looks).
func setup_vs(trainer: Dictionary, you_sprite: Variant, you_name: String, region: String) -> void:
	style = ""
	_trainer = trainer
	_you_sprite = you_sprite
	_you_name = you_name if you_name != "" else "You"
	_region = region
	duration = VS_SECONDS

func _ready() -> void:
	layer = 99  # over everything but Router's fade
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _built:
		build_view(get_viewport().get_visible_rect().size)

func run() -> void:
	advance(0.0)
	while not done:
		await get_tree().process_frame
		advance(get_process_delta_time())

func wants_skip(ev: InputEvent) -> bool:
	if style != "" or not ev.is_pressed() or ev.is_echo():
		return false
	for a in SKIP_ACTIONS:
		if ev.is_action_pressed(a):
			return true
	return false

func _input(ev: InputEvent) -> void:
	if done or not wants_skip(ev):
		return
	get_viewport().set_input_as_handled()
	skip()

func skip() -> void:
	skipped = true
	_finish()

func _finish() -> void:
	if done:
		return
	done = true
	finished.emit()

func advance(delta: float) -> void:
	if done:
		return
	elapsed += delta
	if hold_at >= 0.0:
		elapsed = hold_at * duration
	var p := clampf(elapsed / duration, 0.0, 1.0)
	if style != "":
		(_veil.material as ShaderMaterial).set_shader_parameter("amount", cover(style, p, reduce))
	else:
		_pose_vs()
	if elapsed >= duration and hold_at < 0.0:
		_finish()

func build_view(sz: Vector2) -> void:
	_size = sz
	_built = true
	_root = Control.new()
	_root.name = "Root"
	_root.size = sz
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	if style != "":
		_veil = ColorRect.new()
		_veil.size = sz
		_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = load("res://art/shaders/battle_intro.gdshader")
		m.set_shader_parameter("mode", STYLES.find(style))
		m.set_shader_parameter("centre", _centre)
		m.set_shader_parameter("aspect", sz.x / maxf(sz.y, 1.0))
		m.set_shader_parameter("ink", INK)
		m.set_shader_parameter("amount", 0.0)
		_veil.material = m
		_root.add_child(_veil)
	else:
		_build_vs()

# --- the VS splash -------------------------------------------------------------------------------------------

func _build_vs() -> void:
	var W := _size.x
	var H := _size.y
	var k := H / 720.0
	var bg := ColorRect.new()
	bg.size = _size
	bg.color = INK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	var col := region_colour(_region)
	_stripe = Polygon2D.new()
	_stripe.name = "Stripe"
	var t := H * 0.2
	_stripe.polygon = PackedVector2Array([Vector2(-W * 0.2, H * 0.5 - t + H * 0.08), Vector2(W * 1.2, H * 0.5 - t - H * 0.08),
		Vector2(W * 1.2, H * 0.5 + t - H * 0.08), Vector2(-W * 0.2, H * 0.5 + t + H * 0.08)])
	_stripe.color = col.darkened(0.3)
	_root.add_child(_stripe)
	for edge in [-1.0, 1.0]:  # a light rule along each edge of the stripe
		var l := Line2D.new()
		l.width = 6.0 * k
		l.default_color = col.lightened(0.35)
		l.points = PackedVector2Array([Vector2(-W * 0.2, H * 0.5 + edge * t + H * 0.08), Vector2(W * 1.2, H * 0.5 + edge * t - H * 0.08)])
		_stripe.add_child(l)
	_them = _portrait("Them", str(_trainer.get("sprite", "")), "left", k)
	_you = _portrait("You", _you_sprite, "right", k)
	_them_name = _name_label(str(_trainer.get("name", "")), k)
	_you_name_label = _name_label(_you_name, k)
	_vs = UIKit.label("VS", int(120 * k), Color("fff4dc"))
	_vs.name = "VS"
	_vs.add_theme_color_override("font_outline_color", Color("1d2230"))
	_vs.add_theme_constant_override("outline_size", int(18 * k))
	_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_vs.size = Vector2(320, 200) * k
	_vs.pivot_offset = _vs.size * 0.5
	_vs.position = Vector2(W * 0.5, H * 0.5) - _vs.size * 0.5
	_root.add_child(_vs)
	var hint := UIKit.label(UIKit.hint([["confirm", "Skip"]]), int(18 * k), UIKit.MUTED)
	hint.position = Vector2(W - 180 * k, H - 36 * k)
	hint.size = Vector2(160 * k, 28 * k)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(hint)
	_pose_vs()

func _portrait(node_name: String, sprite_id: Variant, facing: String, k: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.name = node_name
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if sprite_id is Dictionary:  # the player's look (4.6)
		tr.texture = LookArt.frame(sprite_id, facing)
		tr.size = Vector2(32, 48) * 6.0 * k
		_root.add_child(tr)
		return tr
	var path := "res://art/sprites/chars/%s.png" % str(sprite_id)
	if not ResourceLoader.exists(path):
		path = "res://art/sprites/chars/_placeholder.png"
	if ResourceLoader.exists(path):
		var sheet: Texture2D = load(path)
		var a := AtlasTexture.new()
		a.atlas = sheet
		var fw := sheet.get_width() / 3.0
		var fh := sheet.get_height() / 4.0
		a.region = Rect2(0, CharSprite.ROWS.get(facing, 0) * fh, fw, fh)
		tr.texture = a
	tr.size = Vector2(32, 48) * 6.0 * k
	_root.add_child(tr)
	return tr

func _name_label(text: String, k: float) -> Label:
	var l := UIKit.label(text, int(34 * k), UIKit.CREAM)
	l.add_theme_color_override("font_outline_color", Color("1d2230"))
	l.add_theme_constant_override("outline_size", int(10 * k))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(520, 50) * k
	_root.add_child(l)
	return l

## Slide the stripe in, the two of you in from either side, then the VS lands. Eased slides only: no flashes.
func _pose_vs() -> void:
	if _stripe == null:
		return
	var W := _size.x
	var H := _size.y
	var e := func(a: float, b: float) -> float:
		var u := clampf((elapsed - a) / (b - a), 0.0, 1.0)
		return 1.0 - pow(1.0 - u, 3.0)
	_stripe.position.x = -W * 1.4 * (1.0 - e.call(0.0, 0.25))
	var them_x := W * 0.66
	var you_x := W * 0.34 - _you.size.x
	var py := H * 0.5 - _them.size.y * 0.62
	_them.position = Vector2(them_x + W * 0.5 * (1.0 - e.call(0.1, 0.4)), py)
	_you.position = Vector2(you_x - W * 0.5 * (1.0 - e.call(0.1, 0.4)), py)
	_them_name.position = Vector2(them_x + _them.size.x * 0.5 - _them_name.size.x * 0.5 + W * 0.5 * (1.0 - e.call(0.2, 0.5)), py + _them.size.y + 4)
	_you_name_label.position = Vector2(you_x + _you.size.x * 0.5 - _you_name_label.size.x * 0.5 - W * 0.5 * (1.0 - e.call(0.2, 0.5)), py + _you.size.y + 4)
	var v: float = e.call(0.35, 0.55)
	_vs.modulate.a = v
	_vs.scale = Vector2.ONE * lerpf(2.2, 1.0, v)
	if v > 0.0 and not _slammed:
		_slammed = true
		if is_inside_tree() and hold_at < 0.0:
			Audio.sfx_at("hit", -6.0)
