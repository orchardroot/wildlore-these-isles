class_name ColdOpen
extends Control
## The cold open on a New Game, before Mum's room: the moor at night, a standing stone starting to hum, an antlered
## shape on the skyline under the moon, then morning. About twenty seconds, any time skippable (cancel or menu;
## confirm hurries a caption along). The words and timing are an ordinary story script (`cold_open` in
## data/dialogue/macc_home.json) run by Commands through the small host below, so it's data like everything else.
## The scene is built in its own viewport like the title's backdrop: nothing is visited, nothing is saved.
## Opened as the "cold_open" menu (Router), so `--menu=cold_open` shows it for screenshots.

signal closed(result)

const SEEN_FLAG := "cold_open_seen"
const SCRIPT_PATH := "res://data/dialogue/macc_home.json"
const SCRIPT_KEY := "cold_open"
const ZONE := "cat_and_fiddle"         # the moor road above Macclesfield, the inn dark on the top
## Tile positions (x, z); heights come from the ground. The camera and the look-at point are so far above it.
const STONE := Vector2(37.4, 19.6)      # a stone of our own, in the heather
const LEGEND := Vector2(47.5, 5.5)      # on the skyline, the moon rising behind
const LEGEND_TALL := 2.4
const MOON := Vector3(54.5, 1.7, -8.0)  # low, and straight behind the legend as the camera sees it
const CAM_FROM := Vector3(36.4, 2.7, 28.4)
const CAM_TO := Vector3(36.9, 2.5, 25.8)  # where the slow push in ends
const LOOK := Vector3(44.0, 1.2, 10.0)
const NIGHT := 23 * 60 + 40
const FADE := 1.0
const LINE_MIN := 2.6      # seconds a caption stays up, at least
const LINE_PER_CHAR := 0.042
const LINE_IN := 0.45
const LINE_OUT := 0.35

# --- pure bits (tests) ----------------------------------------------------------------

static func script() -> Array:
	var d = JsonUtil.read(SCRIPT_PATH)
	return d.get(SCRIPT_KEY, []) if d is Dictionary else []

## Seconds the script takes if nobody presses anything.
static func duration(cmds: Array) -> float:
	var t := 0.0
	for c in cmds:
		match str(c.get("do", "")):
			"say":
				t += line_secs(str(c.get("text", ""))) + LINE_IN + LINE_OUT
			"wait":
				t += float(c.get("seconds", 0.5))
			"fade_in", "fade_out":
				t += FADE
	return t

static func line_secs(text: String) -> float:
	return maxf(LINE_MIN, text.length() * LINE_PER_CHAR)

## Only a brand new journey: never twice, never once you've been about.
static func wanted(d: GameStateData) -> bool:
	return d.flag(SEEN_FLAG) != true and d.flag("mum_done") != true

## Plays the cold open (if wanted), then wakes the player up in their room with Mum there to say good morning.
## Static, so it outlives the title screen it was called from.
static func then_morning(router: Node, data: GameStateData) -> void:
	if wanted(data):
		await router.open_menu("cold_open")
	await router.goto_zone(data.zone_id, Vector2i(-1, -1), "right", Vector2(0.01, 1.2))
	var ow: Node = router.overworld
	if ow != null and is_instance_valid(ow) and data.flag("mum_done") != true:
		await ow.get_tree().create_timer(0.4).timeout
		ScriptRunner.start(ow, StoryData.script("macc_home", "mum"), "mum")

# --- the scene ------------------------------------------------------------------------

var _host: Host
var _cam: Camera3D
var _caption: Label
var _fader: ColorRect
var _glow: Sprite3D
var _stone_light: OmniLight3D
var _motes: CPUParticles3D
var _legend: Sprite3D
var _t := 0.0
var _hum := 0.0        # 0..1: how far the stone has woken
var _seen := 0.0       # 0..1: the shape on the skyline
var _seen_to := 0.0
var _says := 0
var _hurry := false
var _clock_was := 0
var _legend_y := 0.0
var _zone: ZoneData

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_clock_was = Game.data.clock_minutes
	Game.data.clock_minutes = NIGHT
	add_child(_world())
	_fader = ColorRect.new()  # under the bars and the caption: the last lines are read on black
	_fader.color = Color(0.0, 0.0, 0.0, 1.0)
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fader)
	_bars()
	_host = Host.new(self, Game.data)
	_run.call_deferred()

func _run() -> void:
	Router.fade_in(0.01)  # our own fader takes over from the title's
	await Commands.new(_host, "").run(script())
	Game.data.set_flag(SEEN_FLAG, true)
	Game.data.clock_minutes = _clock_was
	_fader.color.a = 1.0
	await Router.fade_out(0.01)  # stay dark while the house loads
	closed.emit(null)

func _process(delta: float) -> void:
	_t += delta
	if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("menu"):
		if not _host.skipped:
			_host.skipped = true
			Audio.sfx("cancel")
	if Input.is_action_just_pressed("confirm"):
		_hurry = true
	if _cam:  # a slow push in towards the stone
		var at := CAM_FROM.lerp(CAM_TO, smoothstep(0.0, 24.0, _t))
		_cam.position = at + Vector3(0, _ground(Vector2(at.x, at.z)), 0)
		_cam.look_at(LOOK + Vector3(0, _ground(Vector2(LOOK.x, LOOK.z)), 0))
	if _glow:
		var pulse := 0.75 + 0.25 * sin(_t * 2.6)
		_glow.modulate = Color(0.55, 0.85, 1.0, 0.85 * _hum * pulse)
		_glow.pixel_size = 0.03 + 0.006 * pulse * _hum
		_stone_light.light_energy = 0.5 * _hum * pulse
		_motes.emitting = _hum > 0.3
	if _legend:
		_seen = move_toward(_seen, _seen_to, delta * 0.6)
		_legend.modulate = Color(0.02, 0.02, 0.05, _seen)
		_legend.position.y = _legend_y + 0.04 * sin(_t * 0.9)  # breathing

## The viewport: Goyt Valley under a night sky, our stone, its glow, the moon and the shape against it.
func _world() -> Control:
	var box := SubViewportContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.stretch = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	box.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var zid := ZONE if Game.zone_exists(ZONE) else "testbed"
	var zone := ZoneData.load_id(zid)
	world.add_child(ZoneBuilder.build(zone))
	var sky := SkyAndLight.new()
	world.add_child(sky)
	sky.call_deferred("set_weather", "clear", false)
	_zone = zone
	var gy := _ground(STONE)
	var stone := MeshInstance3D.new()
	stone.mesh = ZoneBuilder._ctor("standing_stone", 1)
	stone.material_override = Meshes.solid
	stone.position = Vector3(STONE.x, gy, STONE.y)
	world.add_child(stone)
	var soft := _soft()
	_glow = _billboard(soft, Vector3(STONE.x, gy + 0.9, STONE.y + 0.15), 0.03)
	_glow.modulate.a = 0.0
	world.add_child(_glow)
	_stone_light = OmniLight3D.new()
	_stone_light.light_color = Color(0.55, 0.85, 1.0)
	_stone_light.omni_range = 3.2
	_stone_light.light_energy = 0.0
	_stone_light.position = Vector3(STONE.x + 0.3, gy + 0.4, STONE.y + 1.1)
	world.add_child(_stone_light)
	_motes = CPUParticles3D.new()  # a few pale specks drifting up off the stone while it hums
	_motes.amount = 14
	_motes.lifetime = 2.6
	_motes.emitting = false
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_motes.emission_box_extents = Vector3(0.35, 0.8, 0.35)
	_motes.direction = Vector3.UP
	_motes.spread = 12.0
	_motes.gravity = Vector3(0, 0.15, 0)
	_motes.initial_velocity_min = 0.15
	_motes.initial_velocity_max = 0.35
	var dot := QuadMesh.new()
	dot.size = Vector2(0.04, 0.04)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dm.albedo_color = Color(0.6, 0.9, 1.0, 0.9)
	dot.material = dm
	_motes.mesh = dot
	_motes.position = Vector3(STONE.x, gy + 1.0, STONE.y)
	world.add_child(_motes)
	var moon := _billboard(_disc(), MOON, 0.06)
	moon.modulate = Color(1.0, 0.97, 0.88, 1.0)
	world.add_child(moon)
	var halo := _billboard(soft, MOON + Vector3(0, 0, -0.2), 0.2)
	halo.modulate = Color(0.7, 0.8, 1.0, 0.22)
	world.add_child(halo)
	var moonlight := DirectionalLight3D.new()  # a cool rim from the moon's side, so the night reads
	moonlight.light_color = Color(0.62, 0.72, 1.0)
	moonlight.light_energy = 0.45
	moonlight.rotation_degrees = Vector3(-28.0, 160.0, 0.0)
	world.add_child(moonlight)
	var tex: Texture2D = load("res://art/sprites/creatures/herne_front.png") if ResourceLoader.exists("res://art/sprites/creatures/herne_front.png") else null
	if tex:
		_legend = Sprite3D.new()
		_legend.texture = tex
		_legend.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		_legend.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR  # a soft edge reads as distance, not pixels
		_legend.shaded = false
		var frame := float(tex.get_height())  # the sheet is two square frames side by side: the first will do
		_legend.region_enabled = true
		_legend.region_rect = Rect2(0, 0, frame, frame)
		_legend.pixel_size = LEGEND_TALL / frame
		_legend.offset = Vector2(0, frame * 0.5)
		_legend_y = _ground(LEGEND)
		_legend.position = Vector3(LEGEND.x, _legend_y, LEGEND.y)
		_legend.modulate = Color(0.02, 0.02, 0.05, 0.0)
		world.add_child(_legend)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	world.add_child(_cam)
	_cam.current = true
	return box

func _ground(p: Vector2) -> float:
	return ZoneBuilder.ground_y(_zone, Vector2i(int(p.x), int(p.y))) if _zone else 0.0

func _billboard(tex: Texture2D, at: Vector3, px: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.pixel_size = px
	s.position = at
	return s

## A hard-edged pale disc, for the moon.
static func _disc() -> GradientTexture2D:
	var t := _soft()
	t.gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.93, 0.93, 0.9, 1), Color(1, 1, 1, 0)])
	t.gradient.offsets = PackedFloat32Array([0.0, 0.9, 0.96])
	return t

static func _soft() -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t

## Letterbox bars, the caption and the skip hint.
func _bars() -> void:
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0.0, 0.0, 0.0, 1.0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.86
		bar.anchor_bottom = 0.11 if top else 1.0
		add_child(bar)
	_caption = UIKit.label("", 30, UIKit.CREAM)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.anchor_left = 0.12
	_caption.anchor_right = 0.88
	_caption.anchor_top = 0.86
	_caption.anchor_bottom = 1.0
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	_caption.modulate.a = 0.0
	add_child(_caption)
	var hint := UIKit.bind_hint(UIKit.label("", 18, UIKit.MUTED), [["cancel", "Skip"]])
	hint.anchor_left = 0.7
	hint.anchor_right = 0.98
	hint.anchor_top = 0.02
	hint.anchor_bottom = 0.09
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(hint)

# --- what the host asks of the scene ----------------------------------------------------

## One caption: fades up, stays a while (or until confirm), fades away. Each one moves the night on a step:
## the second wakes the stone, the third brings the shape onto the skyline and the fourth takes it away.
func caption(text: String) -> void:
	_says += 1
	match _says:
		2:
			_tween_hum()
		3:
			_seen_to = 1.0
		4:
			_seen_to = 0.0
	_caption.text = text
	await _fade_caption(1.0, LINE_IN)
	await hold(line_secs(text))
	await _fade_caption(0.0, LINE_OUT)

func _tween_hum() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_hum", 1.0, 2.5)

func _fade_caption(to: float, secs: float) -> void:
	if _host.skipped:
		_caption.modulate.a = 0.0
		return
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", to, secs)
	await tw.finished

## Waits `secs`, cut short by confirm or a skip.
func hold(secs: float) -> void:
	_hurry = false
	var left := secs
	while left > 0.0 and not _hurry and not _host.skipped:
		await get_tree().process_frame
		left -= get_process_delta_time()

func fade(out: bool) -> void:
	if _host.skipped:
		return
	var tw := create_tween()
	tw.tween_property(_fader, "color:a", 1.0 if out else 0.0, FADE)
	await tw.finished

## The Commands host: only the plain commands a cold open needs. Once skipped, everything returns at once.
class Host extends RefCounted:
	var data: GameStateData
	var dex := Dex.new()  # nothing to look up: an empty Fieldbook keeps {total} and friends happy
	var skipped := false
	var lines: Array = []
	var _view

	func _init(view, d: GameStateData = null) -> void:
		_view = view
		data = d if d != null else GameStateData.new()

	func zone_id() -> String:  # ScriptHooks.wrap asks every host (no zone in a cold open)
		return ""

	func say(_who: String, text: String) -> void:
		if skipped:
			return
		lines.append(text)
		if _view:
			await _view.caption(text)

	func wait(seconds: float) -> void:
		if not skipped and _view:
			await _view.hold(seconds)

	func fade(out: bool) -> void:
		if not skipped and _view:
			await _view.fade(out)

	func music(id: String) -> void:
		if not skipped and _view:
			Audio.play_music(id, 1.5)

	func sfx(id: String) -> void:
		if not skipped and _view:
			Audio.sfx(id)
