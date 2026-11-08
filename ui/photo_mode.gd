class_name PhotoMode
extends CanvasLayer
## Photo mode (the Photo key, P): the HUD tucks away, the player stands still while the world carries on, and the
## camera can swing a little and zoom. Confirm saves a PNG to Pictures/Wildlore (or user://photos), Cancel leaves.

const YAW_MAX := 40.0       # degrees either side of the usual view
const PITCH_MIN := -14.0    # change from the usual 35 degree look-down
const PITCH_MAX := 24.0
const ZOOM_MIN := 0.55
const ZOOM_MAX := 1.35
const ORBIT_SPEED := Vector2(55.0, 38.0)   # degrees a second at full stick: yaw, pitch
const ZOOM_SPEED := 0.7                    # zoom factor a second
const HINT_SECONDS := 5.0
const FALLBACK_DIR := "user://photos"

const VIGNETTE := "shader_type canvas_item;
void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.35, 0.95, length(d * vec2(1.0, 1.15)));
	COLOR = vec4(0.04, 0.03, 0.05, v * 0.42);
}"

var _ow: Node
var _rig: CameraRig
var _was_busy := false
var _hidden: Array = []
var _hint: Label
var _hint_left := HINT_SECONDS
var _shooting := false
var _done := false
var _toast: SaveToast
var _view := Vector2.ZERO    # yaw, pitch change (degrees)
var _zoom := 1.0

# --- pure rules (tested) ------------------------------------------------------------------------------------------

## The orbit after `dt` seconds of stick input `stick` (-1..1 each way) from `cur` (yaw, pitch change), kept in range.
static func orbit_step(cur: Vector2, stick: Vector2, dt: float) -> Vector2:
	return Vector2(clampf(cur.x + stick.x * ORBIT_SPEED.x * dt, -YAW_MAX, YAW_MAX),
		clampf(cur.y + stick.y * ORBIT_SPEED.y * dt, PITCH_MIN, PITCH_MAX))

static func zoom_step(z: float, amount: float) -> float:
	return clampf(z + amount, ZOOM_MIN, ZOOM_MAX)

## "wildlore_2026-10-07_09-05-03.png" from Time.get_datetime_dict_from_system().
static func photo_name(t: Dictionary) -> String:
	return "wildlore_%04d-%02d-%02d_%02d-%02d-%02d.png" % [t.year, t.month, t.day, t.hour, t.minute, t.second]

## Where photos go: Pictures/Wildlore if there is a Pictures folder (and this isn't a dev run), else user://photos.
static func photo_dir(pictures: String, dev: bool) -> String:
	if pictures != "" and not dev:
		return pictures.path_join("Wildlore")
	return FALLBACK_DIR

## Writes `img` as a new PNG and returns its path, or "" if it could not be saved anywhere.
static func save_image(img: Image, pictures := "", dev := false) -> String:
	var name := photo_name(Time.get_datetime_dict_from_system())
	for dir in [photo_dir(pictures, dev), FALLBACK_DIR]:
		DirAccess.make_dir_recursive_absolute(dir)
		var path: String = dir.path_join(name)
		if img.save_png(path) == OK:
			return path
	return ""

# --- running it ---------------------------------------------------------------------------------------------------

## The Photo key on the overworld: only when nothing else is going on.
static func start(ow: Node) -> void:
	if Router.busy or ow == null or not is_instance_valid(ow) or ow.get("rig") == null or ow.player.moving:
		return
	var pm := PhotoMode.new()
	ow.add_child(pm)
	pm._begin(ow)

func _begin(ow: Node) -> void:
	_ow = ow
	_rig = ow.rig
	layer = 70
	_was_busy = Router.busy
	Router.busy = true  # the player stands still; the world is not paused, so water, clouds and people carry on
	for c in ow.get_children():
		if c is ZoneCard or c is RouteChip or c is PlaceIndicator:
			c.visible = false
			_hidden.append(c)
	for g in [ParishToast.GROUP, SaveToast.GROUP]:  # news and the Saved note stay out of the picture too
		for c in get_tree().get_nodes_in_group(g):
			if c.visible:
				c.visible = false
				_hidden.append(c)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = VIGNETTE
	shade.material = mat
	add_child(shade)
	_hint = UIKit.label("", 22, UIKit.CREAM)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -48
	_hint.offset_bottom = -14
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("shadow_offset_x", 2)
	_hint.add_theme_constant_override("shadow_offset_y", 2)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	UIKit.bind_hint(_hint, [["=Move", "Orbit"], ["=+ / -", "Zoom", "kbd"], ["=LB / RB", "Zoom", "pad"],
		["confirm", "Take photo"], ["cancel", "Done"]])
	_toast = SaveToast.new()
	add_child(_toast)
	Audio.sfx("confirm")
	if dev_wanted():  # screenshots: already swung round a little, hint gone
		set_view(Vector2(24, 8), 0.8)
		_hint_left = 0.0
		for a in DevArgs.user_args():  # --photo-view=yaw,pitch,zoom (e.g. 0,-12,1.35 to see a tall front whole)
			var v := a.trim_prefix("--photo-view=").split(",")
			if a.begins_with("--photo-view=") and v.size() == 3:
				set_view(orbit_step(Vector2(v[0].to_float(), v[1].to_float()), Vector2.ZERO, 0.0), zoom_step(v[2].to_float(), 0.0))

func _process(delta: float) -> void:
	if _done:
		return
	_hint_left -= delta
	_hint.modulate.a = clampf(_hint_left, 0.0, 1.0) if not _shooting else 0.0
	var stick := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	var z := 0.0
	if Input.is_physical_key_pressed(KEY_EQUAL) or Input.is_physical_key_pressed(KEY_KP_ADD) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER):
		z -= 1.0
	if Input.is_physical_key_pressed(KEY_MINUS) or Input.is_physical_key_pressed(KEY_KP_SUBTRACT) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER):
		z += 1.0
	z += Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) - Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	if stick != Vector2.ZERO:
		_hint_left = maxf(_hint_left, 1.5)
	set_view(orbit_step(_view, Vector2(stick.x, stick.y), delta), zoom_step(_zoom, z * ZOOM_SPEED * delta))

func set_view(view: Vector2, zoom: float) -> void:
	_view = view
	_zoom = zoom
	_rig.photo = Vector3(view.x, view.y, zoom)

func _input(event: InputEvent) -> void:
	if _done or _shooting:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		set_view(_view, zoom_step(_zoom, -0.06 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.06))
		return
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		_take()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu") or event.is_action_pressed("photo"):
		get_viewport().set_input_as_handled()
		_leave()

func _take() -> void:
	_shooting = true
	_hint.modulate.a = 0.0
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var place := str(_ow.zone.name)
	var today := Calendar.today_key()
	var path := await Share.export_image(self, img, PhotoMode.photo_name(Time.get_datetime_dict_from_system()), Share.caption(place, today),
		OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), DevArgs.is_dev_session(Game.args, DevArgs.user_args()))
	Audio.sfx("confirm" if path != "" else "bump")
	_toast.flash("Photo saved" if path != "" else "Couldn't save the photo")
	_hint_left = 2.0
	_shooting = false

func _leave() -> void:
	_done = true
	_rig.photo = Vector3(0, 0, 1)
	for c in _hidden:
		if is_instance_valid(c):
			c.visible = true
	Audio.sfx("cancel")
	# let this key press finish (Menu would open the pause menu, Confirm would talk to whoever is ahead)
	await get_tree().process_frame
	await get_tree().physics_frame
	Router.busy = _was_busy
	queue_free()

## Dev switch `--photo` (with --boot): starts photo mode a moment after the zone loads, for screenshots.
static func dev_wanted() -> bool:
	return "--photo" in DevArgs.user_args()
