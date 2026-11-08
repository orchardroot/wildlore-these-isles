extends TestCase

const TMP := "user://test_settings_access.json"

var _saved_path := ""

## Points Settings at a scratch file and resets it, so tests never touch the player's real settings.
func _begin() -> void:
	_saved_path = Settings.path
	Settings.path = TMP
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	Settings.text_speed = "normal"
	Settings.colour_blind = false
	Settings.reduce_flashing = false
	Settings.reset_bindings()

func _end() -> void:
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	Settings.path = _saved_path
	Settings.colour_blind = false
	Settings.reduce_flashing = false
	Settings.text_speed = "normal"
	Settings.bindings = InputSetup.defaults()
	InputSetup.apply(Settings.bindings)

func _types() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/types.json")).types

# --- type glyphs ---------------------------------------------------------------------------------------------

func test_every_type_has_a_glyph_and_colours() -> void:
	for t in _types():
		assert_true(TypeGlyph.SHAPES.has(t), "glyph for " + t)
		assert_true(TypeColours.COLOURS.has(t), "colour for " + t)
		assert_true(TypeColours.CB_COLOURS.has(t), "colour-blind colour for " + t)
	assert_eq(TypeGlyph.SHAPES.size(), _types().size())

func test_glyph_shapes_are_unique_and_look_different() -> void:
	var names := {}
	for t in TypeGlyph.SHAPES:
		assert_false(names.has(TypeGlyph.SHAPES[t]), "shape name reused: " + TypeGlyph.SHAPES[t])
		names[TypeGlyph.SHAPES[t]] = true
	var masks := {}
	for t in _types():
		masks[t] = _mask(t)
		assert_true(_count(masks[t]) >= 12, "%s glyph is not a speck" % t)
	var ts := _types()
	for i in ts.size():
		for j in range(i + 1, ts.size()):
			var diff := 0
			for k in masks[ts[i]].size():
				if masks[ts[i]][k] != masks[ts[j]][k]:
					diff += 1
			assert_true(diff >= 18, "%s and %s glyphs differ in %d of 256 cells" % [ts[i], ts[j], diff])

func _mask(t: String) -> Array:
	var polys := TypeGlyph.polygons(t)
	var out := []
	for y in 16:
		for x in 16:
			var p := Vector2((x + 0.5) / 16.0, (y + 0.5) / 16.0)
			var inside := false
			for poly in polys:
				if Geometry2D.is_point_in_polygon(p, poly):
					inside = true
			out.append(inside)
	return out

func _count(mask: Array) -> int:
	var n := 0
	for m in mask:
		if m:
			n += 1
	return n

func test_type_chip_carries_a_glyph() -> void:
	var chip := UIKit.type_chip("hearth")
	var found := false
	for n in chip.find_children("*", "Control", true, false):
		if n is TypeGlyph:
			found = true
			assert_eq(n.type_id, "hearth")
			assert_true(n.custom_minimum_size.x >= 12 and n.custom_minimum_size.x <= 16)
	assert_true(found, "type_chip has a TypeGlyph")
	chip.free()

# --- colour-blind palette ------------------------------------------------------------------------------------

func test_colour_blind_palette_differs_and_is_distinguishable() -> void:
	var changed := 0
	for t in _types():
		if TypeColours.colour_in(t, true) != TypeColours.colour_in(t, false):
			changed += 1
	assert_true(changed >= 12, "most colours change, got %d" % changed)
	var ts := _types()
	var worst := 1e9
	for i in ts.size():
		for j in range(i + 1, ts.size()):
			var d := TypeColours.distinguishability(TypeColours.colour_in(ts[i], true), TypeColours.colour_in(ts[j], true))
			worst = minf(worst, d)
			assert_true(d >= 12.0, "%s vs %s distance %.1f under normal, deuteranopia and protanopia" % [ts[i], ts[j], d])
	assert_true(worst >= 12.0)

func test_colour_blind_palette_beats_the_default_one() -> void:
	var worst_default := 1e9
	var worst_cb := 1e9
	var ts := _types()
	for i in ts.size():
		for j in range(i + 1, ts.size()):
			worst_default = minf(worst_default, TypeColours.distinguishability(TypeColours.colour_in(ts[i], false), TypeColours.colour_in(ts[j], false)))
			worst_cb = minf(worst_cb, TypeColours.distinguishability(TypeColours.colour_in(ts[i], true), TypeColours.colour_in(ts[j], true)))
	assert_true(worst_cb > worst_default, "cb %.1f vs default %.1f" % [worst_cb, worst_default])

func test_colour_blind_text_keeps_contrast() -> void:
	for t in _types():
		var bg := TypeColours.colour_in(t, true)
		var fg := TypeColours.text_colour_in(t, true)
		assert_true(TypeColours.contrast(bg, fg) >= 4.5, "%s text contrast %.2f" % [t, TypeColours.contrast(bg, fg)])

func test_hp_colours_safe_set_is_distinct() -> void:
	var bands := ["green", "amber", "red"]
	for i in 3:
		for j in range(i + 1, 3):
			assert_true(TypeColours.distinguishability(TypeColours.hp_colour_in(bands[i], true), TypeColours.hp_colour_in(bands[j], true)) >= 20.0, "hp %s vs %s" % [bands[i], bands[j]])

func test_setting_switches_the_palette() -> void:
	_begin()
	var normal := TypeColours.colour("brook")
	Settings.colour_blind = true
	assert_true(TypeColours.colour("brook") != normal)
	assert_eq(TypeColours.colour("brook"), TypeColours.CB_COLOURS.brook)
	var bar := UIKit.hp_bar(10, 10)
	assert_eq(bar.get_theme_stylebox("fill").bg_color, TypeColours.HP_SAFE.green)
	bar.free()
	_end()

# --- remapping -----------------------------------------------------------------------------------------------

func test_defaults_cover_every_action_and_match_the_old_bindings() -> void:
	var d := InputSetup.defaults()
	for a in InputSetup.ACTIONS:
		assert_true(d.has(a) and not d[a].key.is_empty(), a)
	assert_eq(d.confirm.key, [KEY_Z, KEY_ENTER, KEY_SPACE])
	assert_eq(d.cancel.pad, [JOY_BUTTON_B])
	_begin()
	assert_true(InputMap.has_action("fly"))
	assert_true(InputMap.action_has_event("confirm", _key_event(KEY_Z)))
	assert_true(InputMap.action_has_event("ui_accept", _key_event(KEY_Z)), "ui_accept mirrors confirm")
	_end()

func test_remap_persists_across_save_and_load() -> void:
	_begin()
	assert_eq(Settings.rebind("run", "key", KEY_Q), "")
	assert_eq(Settings.rebind("run", "pad", JOY_BUTTON_RIGHT_SHOULDER), "")
	assert_true(InputMap.action_has_event("run", _key_event(KEY_Q)))
	assert_false(InputMap.action_has_event("run", _key_event(KEY_E)))
	Settings.bindings = InputSetup.defaults()
	Settings.load_settings()
	assert_eq(Settings.bindings.run.key[0], KEY_Q)
	assert_eq(Settings.bindings.run.pad[0], JOY_BUTTON_RIGHT_SHOULDER)
	assert_true(InputMap.action_has_event("run", _key_event(KEY_Q)), "applied at load")
	assert_eq(Settings.bindings.confirm.key, [KEY_Z, KEY_ENTER, KEY_SPACE], "others untouched")
	_end()

func test_taking_a_key_moves_it_from_the_other_action() -> void:
	_begin()
	assert_eq(Settings.rebind("run", "key", KEY_TAB), "")  # Tab was a second Menu key
	assert_eq(Settings.bindings.run.key, [KEY_TAB, KEY_SHIFT])
	assert_eq(Settings.bindings.menu.key, [KEY_ESCAPE])
	_end()

func test_cannot_leave_an_action_with_nothing() -> void:
	_begin()
	var before := Settings.bindings.duplicate(true)
	var err := Settings.rebind("bike", "key", KEY_F)
	assert_true(err != "", "F is fly's only key")
	assert_eq(Settings.bindings, before)
	_end()

func test_confirm_and_cancel_cannot_be_unbound_or_merged() -> void:
	_begin()
	# Taking cancel's last pad button for another action is refused.
	assert_true(Settings.rebind("run", "pad", JOY_BUTTON_B) != "", "B is cancel's only pad button")
	assert_true(Settings.rebind("run", "pad", JOY_BUTTON_A) != "", "A is confirm's only pad button")
	assert_eq(Settings.bindings.cancel.pad, [JOY_BUTTON_B])
	assert_eq(Settings.bindings.confirm.pad, [JOY_BUTTON_A])
	# Moving a key from confirm to cancel leaves them on different keys.
	assert_eq(Settings.rebind("cancel", "key", KEY_SPACE), "")
	assert_false(Settings.bindings.confirm.key.has(KEY_SPACE))
	for c in Settings.bindings.confirm.key:
		assert_false(Settings.bindings.cancel.key.has(c))
	# Pure rule check: a merged set is never produced.
	var d := InputSetup.defaults()
	d.confirm.key = [KEY_Z]
	var r := InputSetup.rebound(d, "cancel", "key", KEY_Z)
	assert_true(r.error != "", "cancel onto confirm's only key")
	assert_eq(r.bindings.confirm.key, [KEY_Z])
	# Escape is reserved.
	assert_true(Settings.rebind("confirm", "key", KEY_ESCAPE) != "")
	_end()

func _real_key(code: int, pressed := true) -> InputEventKey:
	var e := InputEventKey.new()  # a real key press carries both codes; built-in ui_* bindings match on keycode
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	return e

func test_remapped_keys_do_not_leave_builtin_ui_bindings() -> void:
	_begin()
	assert_eq(Settings.rebind("cancel", "key", KEY_SPACE), "")
	var space := _real_key(KEY_SPACE, true)
	assert_true(InputMap.event_is_action(space, "cancel"))
	assert_true(InputMap.event_is_action(space, "ui_cancel"), "Space now backs out")
	assert_false(InputMap.event_is_action(space, "ui_accept"), "Space no longer confirms")
	assert_false(InputMap.event_is_action(_real_key(KEY_ESCAPE, true), "ui_accept"))
	# gamepad is mirrored too
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	assert_true(InputMap.event_is_action(a, "ui_accept"))
	var up := InputEventJoypadMotion.new()
	up.axis = JOY_AXIS_LEFT_Y
	up.axis_value = -1.0
	assert_true(InputMap.event_is_action(up, "ui_up"))
	# an arrow taken by Confirm leaves ui_up
	assert_eq(Settings.rebind("confirm", "key", KEY_UP), "")
	assert_false(InputMap.event_is_action(_real_key(KEY_UP, true), "ui_up"), "Up is Confirm now")
	assert_true(InputMap.event_is_action(_real_key(KEY_UP, true), "ui_accept"))
	assert_true(InputMap.event_is_action(_real_key(KEY_W, true), "ui_up"), "W still moves up")
	_end()

func _all_distinct(b: Dictionary, dev: String) -> bool:
	var seen := {}
	for a in InputSetup.ACTIONS:
		if b[a][dev].is_empty() and not InputSetup.may_be_empty(a, dev):
			return false
		for c in b[a][dev]:
			if seen.has(c):
				return false
			seen[c] = true
	return true

func test_sanitise_rejects_fake_keys() -> void:
	var b := InputSetup.sanitise({"confirm": {"key": [1]}})
	assert_eq(b.confirm.key, [KEY_Z, KEY_ENTER, KEY_SPACE])
	assert_true(_all_distinct(b, "key"))

func test_sanitise_keeps_a_valid_set_as_is() -> void:
	var d := InputSetup.defaults()
	d.run.key = [KEY_Q, KEY_SHIFT]
	d.bike.pad = [JOY_BUTTON_LEFT_SHOULDER]
	assert_eq(InputSetup.sanitise(JSON.parse_string(JSON.stringify(d))), d)
	assert_eq(InputSetup.sanitise(JSON.parse_string(JSON.stringify(InputSetup.defaults()))), InputSetup.defaults())

func test_sanitise_keeps_escape_on_menu_only() -> void:
	var b := InputSetup.sanitise({"menu": {"key": [KEY_Z]}})
	assert_true(b.menu.key.has(KEY_ESCAPE), "menu keeps Esc")
	assert_false(b.confirm.key.has(KEY_Z) and b.menu.key.has(KEY_Z), "Z isn't shared")
	assert_true(_all_distinct(b, "key"))
	var c := InputSetup.sanitise({"run": {"key": [KEY_ESCAPE]}, "menu": {"pad": [JOY_BUTTON_A]}})
	assert_false(c.run.key.has(KEY_ESCAPE))
	assert_true(c.menu.pad.has(JOY_BUTTON_START), "menu keeps Start")
	assert_true(_all_distinct(c, "pad"))
	var d := InputSetup.sanitise({"run": {"key": [KEY_Q]}, "bike": {"key": [KEY_Q]}})
	assert_eq(d.run.key, [KEY_SHIFT], "shared code falls back for the device")
	assert_eq(d.bike.key, [KEY_B])

func test_unusable_saved_bindings_fall_back() -> void:
	_begin()
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	f.store_string(JSON.stringify({"bindings": {"confirm": {"key": [KEY_P], "pad": []}, "cancel": {"key": [KEY_P], "pad": [1]}, "run": "junk"}}))
	f.close()
	Settings.load_settings()
	assert_eq(Settings.bindings.confirm.key, [KEY_Z, KEY_ENTER, KEY_SPACE], "shared key falls back")
	assert_eq(Settings.bindings.cancel.key, [KEY_X, KEY_BACKSPACE])
	assert_eq(Settings.bindings.confirm.pad, [JOY_BUTTON_A], "empty list keeps default")
	assert_eq(Settings.bindings.run.key, [KEY_SHIFT])
	_end()

func test_reset_restores_defaults() -> void:
	_begin()
	Settings.rebind("run", "key", KEY_Q)
	Settings.rebind("menu", "pad", JOY_BUTTON_LEFT_SHOULDER)
	Settings.reset_bindings()
	assert_eq(Settings.bindings, InputSetup.defaults())
	assert_true(InputMap.action_has_event("run", _key_event(KEY_SHIFT)))
	assert_false(InputMap.action_has_event("run", _key_event(KEY_Q)))
	Settings.bindings = {}
	Settings.load_settings()
	assert_eq(Settings.bindings, InputSetup.defaults(), "reset is what got saved")
	_end()

func test_controls_screen_lists_every_action_and_rebinds() -> void:
	_begin()
	var scr = load("res://ui/controls_screen.tscn").instantiate()
	scr._ready()  # builds the page without needing it in the tree
	assert_eq(scr._cells.size(), InputSetup.ACTIONS.size() * 2)
	assert_eq(scr._cells["confirm:key"].text, "Z / Enter / Space")
	scr.begin_capture("run", "key")
	scr._armed_at = 0
	assert_true(scr.handle_capture(_key_event(KEY_Q, true)))
	assert_eq(scr._cells["run:key"].text, "Q / Shift")
	assert_eq(scr._capturing, "")
	scr.begin_capture("confirm", "pad")
	scr._armed_at = 0
	var jb := InputEventJoypadButton.new()
	jb.button_index = JOY_BUTTON_B
	jb.pressed = true
	scr.handle_capture(jb)
	assert_eq(scr._cells["confirm:pad"].text, "A", "refused, unchanged")
	scr._reset()
	assert_eq(scr._cells["run:key"].text, "Shift")
	scr.free()
	_end()

func _key_event(code: int, pressed := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = pressed
	return e

# --- text speed and flashing ---------------------------------------------------------------------------------

func test_instant_text_shows_the_whole_line_at_once() -> void:
	_begin()
	Settings.text_speed = "instant"
	assert_true(Settings.is_instant())
	var line := "Oi. That's my sandwich. Also, welcome to Cheshire, you absolute muppet."
	assert_true(int(0.016 * Settings.chars_per_second()) >= line.length(), "one frame types the whole line")
	assert_true(Settings.chars_per_second() > Settings.TEXT_SPEEDS.fast)
	Settings.text_speed = "fast"
	assert_false(Settings.is_instant())
	_end()

func test_reduce_flashing_scales_flashes_down() -> void:
	_begin()
	assert_eq(Settings.flash_scale(), 1.0)
	Settings.reduce_flashing = true
	assert_true(Settings.flash_scale() < 0.5)
	_end()

# --- old files -----------------------------------------------------------------------------------------------

func test_old_settings_file_without_new_keys_loads() -> void:
	_begin()
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	f.store_string('{"text_speed": "fast", "quality": "high", "music_volume": 0.3, "sfx_volume": 0.5}')
	f.close()
	Settings.load_settings()
	assert_eq(Settings.text_speed, "fast")
	assert_eq(Settings.quality, "high")
	assert_near(Settings.music_volume, 0.3)
	assert_false(Settings.colour_blind)
	assert_false(Settings.reduce_flashing)
	assert_eq(Settings.bindings, InputSetup.defaults())
	assert_true(InputMap.action_has_event("confirm", _key_event(KEY_Z)))
	_end()

func test_new_flags_round_trip() -> void:
	_begin()
	Settings.colour_blind = true
	Settings.reduce_flashing = true
	Settings.text_speed = "instant"
	Settings.save_settings()
	Settings.colour_blind = false
	Settings.reduce_flashing = false
	Settings.text_speed = "normal"
	Settings.load_settings()
	assert_true(Settings.colour_blind)
	assert_true(Settings.reduce_flashing)
	assert_eq(Settings.text_speed, "instant")
	_end()
