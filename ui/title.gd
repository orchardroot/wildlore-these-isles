extends Control
## Title screen: Continue, New Game, Settings, Quit. Also checks the game data made it into the build.

var _menu: VBoxContainer

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop())
	var shade := TextureRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.texture = _shade_gradient()
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 24)
	centre.add_child(col)
	var logo := Label.new()
	logo.text = "WILDLORE"
	logo.add_theme_font_size_override("font_size", 120)
	logo.add_theme_constant_override("shadow_offset_x", 6)
	logo.add_theme_constant_override("shadow_offset_y", 6)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(logo)
	var isles := Label.new()
	isles.text = "These Isles"
	isles.add_theme_font_size_override("font_size", 48)
	isles.add_theme_color_override("font_color", UIKit.GOLD)
	isles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(isles)
	var sub := Label.new()
	sub.text = _subtitle()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.8)
	col.add_child(sub)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(panel)
	_menu = VBoxContainer.new()
	panel.add_child(_menu)
	if Game.newest_slot() != "":
		_add("Continue", _on_continue)
	_add("New Game", _on_new)
	if SaveSystem.slot_infos(Game.save_dir).any(func(i): return i.ok):
		_add("Load", _on_load)
	_add("Settings", _on_settings)
	_add("Quit", func(): get_tree().quit())
	_menu.get_child(0).grab_focus()
	Audio.play_music("title")

func _add(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 0)
	b.pressed.connect(cb)
	b.focus_entered.connect(func(): Audio.sfx("cursor"))
	_menu.add_child(b)

func _subtitle() -> String:
	if Game.chart.types.is_empty() or Game.dex.ids().is_empty() or Game.moves.ids().is_empty():
		return "Game data missing from this build"
	return "v%s  ·  %d creatures" % [ProjectSettings.get_setting("application/config/version"), Game.dex.ids().size()]

var _chosen := false

## Only the first press counts: a quick double-press must not start two games at once.
func _claim() -> bool:
	if _chosen:
		return false
	_chosen = true
	for b in _menu.get_children():
		b.disabled = true
	return true

func _on_continue() -> void:
	if not _claim():
		return
	Audio.sfx("confirm")
	if Game.load_slot(Game.newest_slot()):
		Game.skip_next_autosave = true
		Router.goto_zone(Game.data.zone_id, Game.data.pos, Game.data.facing)

func _on_load() -> void:
	if _chosen:
		return
	Audio.sfx("confirm")
	var slot = await Router.open_menu("save:load")
	if slot != null and _claim():
		Game.skip_next_autosave = true
		Router.goto_zone(Game.data.zone_id, Game.data.pos, Game.data.facing)
	elif _menu.get_child_count() > 0:
		_menu.get_child(0).grab_focus()

var _new_confirmed := false

func _on_new() -> void:
	# a fresh journey will replace the autosave once you leave the house: ask once if there's a journey to lose
	if not _new_confirmed and Game.newest_slot() != "" and not _chosen:
		_new_confirmed = true
		for b in _menu.get_children():
			if b.text == "New Game":
				b.text = "Start afresh? Press again"
		Audio.sfx("bump")
		return
	if not _claim():
		return
	Audio.sfx("confirm")
	Game.new_game()
	Game.skip_next_autosave = true
	var who = await Router.open_menu("name")
	if who is Dictionary:
		Game.data.player_name = str(who.name)
		Game.data.set_flag("player_sprite", str(who.sprite))
		if who.get("look") is Dictionary:
			Game.data.look = who.look
	if Game.data.zone_id == "macc_home":
		ColdOpen.then_morning(Router, Game.data)  # the moor at night, then good morning from Mum (ui/cold_open.gd)
	else:
		Router.goto_zone(Game.data.zone_id, Vector2i(-1, -1), "down")

func _on_settings() -> void:
	Audio.sfx("confirm")
	await Router.open_menu("settings")
	_menu.get_child(0).grab_focus()

const BACKDROPS := [["macclesfield", 14.0, 16.0], ["liverpool", 30.0, 14.0], ["llanberis", 32.0, 20.0]]

var _cam: Camera3D
var _focus := Vector2(14.0, 16.0)
var _t := 0.0

## A slowly drifting view over Macclesfield at golden hour, rendered live behind the menu.
func _backdrop() -> Control:
	var box := SubViewportContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.stretch = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	box.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	# a different backdrop most launches: Macclesfield, Liverpool's waterfront or Llanberis under the mountain
	var spots := BACKDROPS.filter(func(b): return Game.zone_exists(b[0]))
	var pick: Array = spots[int(Time.get_unix_time_from_system()) % spots.size()] if not spots.is_empty() else ["testbed", 14.0, 16.0]
	var zid: String = pick[0]
	_focus = Vector2(float(pick[1]), float(pick[2]))
	var zone := ZoneData.load_id(zid)
	world.add_child(ZoneBuilder.build(zone))
	var sky := SkyAndLight.new()
	world.add_child(sky)
	Game.data.clock_minutes = 18 * 60 + 30
	sky.call_deferred("set_weather", "clear", false)
	_cam = Camera3D.new()
	_cam.fov = 34.0
	world.add_child(_cam)
	_cam.current = true
	_place_cam()
	return box

func _process(delta: float) -> void:
	_t += delta
	if _cam:
		_place_cam()

func _place_cam() -> void:
	var x := _focus.x + sin(_t * 0.05) * 10.0
	_cam.position = Vector3(x, 15.0, _focus.y + 24.0)
	_cam.rotation_degrees = Vector3(-32.0, 0.0, 0.0)

func _shade_gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0.08, 0.09, 0.14, 0.15))
	g.set_color(1, Color(0.08, 0.09, 0.14, 0.75))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	return tex
