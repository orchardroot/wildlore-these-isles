extends MenuBase
## Settings: text speed, battle speed, travel scenes, quality, volumes, accessibility switches and a Controls page. Left/right changes a row; every change is saved at once.

const SPEEDS := ["slow", "normal", "fast", "instant"]
const BATTLE_SPEEDS := ["normal", "fast", "fastest"]
const QUALITIES := ["low", "medium", "high"]
const TRAVEL := ["on", "short", "off"]
const SAMPLE := "Oi. That's my sandwich. Also, welcome to Cheshire."

var _rows: Array = []        # {key, button, value_label}
var _preview: Label
var _chips: HFlowContainer
var _t := 0.0

func _build() -> void:
	set_title("Settings")
	set_hints([["leftright", "Change"], ["confirm", "Select"], ["cancel", "Back"]])
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	content.add_child(col)
	var p := UIKit.panel(Color("1d2230f0"), 8)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(p)
	var sl := UIKit.scroll_list(0)  # whatever room the preview leaves; the last rows scroll into view
	var v: VBoxContainer = sl[1]
	p.add_child(sl[0])
	var buttons := []
	for def in [["text_speed", "Text speed"], ["battle_speed", "Battle speed"], ["travel_scenes", "Travel scenes"], ["quality", "Graphics quality"], ["music_volume", "Music volume"], ["sfx_volume", "Effects volume"], ["ambience_volume", "Ambience volume"], ["run_mode", "Run key"], ["follower", "Follower"], ["colour_blind", "Colour-blind friendly"], ["damage_numbers", "Damage numbers"], ["text_blip", "Text blips"], ["local_languages", "Local languages"], ["hints", "Hints"]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, maxi(30, UIKit.line_height(23)))  # snug rows; taller with Large text so they never overlap
		UIKit.compact(b, 2)
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 18
		h.offset_right = -18
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var k := UIKit.label(def[1], 23)
		k.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(k)
		h.add_child(UIKit.fill())
		var bar: ProgressBar = null
		if def[0].ends_with("volume"):
			bar = ProgressBar.new()
			bar.show_percentage = false
			bar.max_value = 1.0
			bar.custom_minimum_size = Vector2(260, 14)
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bar.add_theme_stylebox_override("fill", UIKit.box(UIKit.HEATHER, Color(0, 0, 0, 0), 0, 3, 0))
			h.add_child(bar)
		var val := UIKit.label("", 23, UIKit.GOLD)
		val.custom_minimum_size = Vector2(190, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(val)
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		var key: String = def[0]
		b.focus_entered.connect(func(): Audio.sfx("cursor"))
		b.pressed.connect(func():
			_change(key, 1)
			Audio.sfx("confirm"))
		b.focus_neighbor_left = NodePath(".")
		b.focus_neighbor_right = NodePath(".")
		v.add_child(b)
		buttons.append(b)
		_rows.append({"key": key, "button": b, "value": val, "bar": bar})
	v.add_child(UIKit.spacer(0))
	var bottom := HBoxContainer.new()  # Controls... and Back side by side, so the page fits with room to spare
	bottom.add_theme_constant_override("separation", 10)
	v.add_child(bottom)
	var controls := make_button("Controls...", func(): await open_child("controls"), 300)
	var access := make_button("Accessibility...", func(): await open_child("accessibility"), 300)
	var report := make_button("Report a bug...", func(): await open_child("report"), 300)
	var back := make_button("Back", func(): close(null), 200)
	for b in [controls, access, report, back]:
		UIKit.compact(b, 6)
		b.custom_minimum_size.y = 34
		b.add_theme_font_size_override("font_size", 25)
		bottom.add_child(b)
		buttons.append(b)
	controls.focus_neighbor_left = NodePath(".")
	controls.focus_neighbor_right = controls.get_path_to(access)
	access.focus_neighbor_left = access.get_path_to(controls)
	access.focus_neighbor_right = access.get_path_to(report)
	access.focus_neighbor_top = access.get_path_to(buttons[buttons.size() - 5])
	report.focus_neighbor_left = report.get_path_to(access)
	report.focus_neighbor_right = report.get_path_to(back)
	report.focus_neighbor_top = report.get_path_to(buttons[buttons.size() - 5])
	back.focus_neighbor_left = back.get_path_to(report)
	back.focus_neighbor_right = NodePath(".")
	back.focus_neighbor_top = back.get_path_to(buttons[buttons.size() - 5])
	UIKit.wrap_focus(buttons)
	controls.focus_neighbor_bottom = controls.get_path_to(buttons[0])
	var pp := UIKit.panel(Color("14182199"), 14)
	col.add_child(pp)
	var pv := VBoxContainer.new()
	pp.add_child(pv)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 20)
	pv.add_child(ph)
	_preview = UIKit.label(SAMPLE, 20)
	_preview.custom_minimum_size = Vector2(420, 0)  # leaves the type chips two rows, not three
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ph.add_child(_preview)
	_chips = HFlowContainer.new()
	_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chips.add_theme_constant_override("h_separation", 6)
	_chips.add_theme_constant_override("v_separation", 6)
	ph.add_child(_chips)
	for r in _rows:
		_paint_row(r)
	UIKit.focus_later(buttons[0])

func _process(delta: float) -> void:
	_t += delta
	var cps := Settings.chars_per_second()
	var n := SAMPLE.length()
	var total := n / cps + 1.2  # type it out, then hold a moment
	if _t > total:
		_t = 0.0
	_preview.visible_characters = mini(n, int(_t * cps))

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	var d := 0
	if event.is_action_pressed("move_left"):
		d = -1
	elif event.is_action_pressed("move_right"):
		d = 1
	if d != 0:
		var f := get_viewport().gui_get_focus_owner()
		for r in _rows:
			if r.button == f:
				get_viewport().set_input_as_handled()
				_change(r.key, d)
				return
	super._input(event)

func _change(key: String, d: int) -> void:
	match key:
		"text_speed":
			Settings.text_speed = SPEEDS[MenuLogic.wrap_index(maxi(0, SPEEDS.find(Settings.text_speed)), d, SPEEDS.size())]
			_t = 0.0
		"battle_speed":
			Settings.battle_speed = BATTLE_SPEEDS[MenuLogic.wrap_index(maxi(0, BATTLE_SPEEDS.find(Settings.battle_speed)), d, BATTLE_SPEEDS.size())]
		"travel_scenes":
			Settings.travel_scenes = TRAVEL[MenuLogic.wrap_index(maxi(0, TRAVEL.find(Settings.travel_scenes)), d, TRAVEL.size())]
		"quality":
			Settings.quality = QUALITIES[MenuLogic.wrap_index(maxi(0, QUALITIES.find(Settings.quality)), d, QUALITIES.size())]
		"music_volume":
			Settings.music_volume = clampf(snappedf(Settings.music_volume + 0.1 * d, 0.1), 0.0, 1.0)
		"sfx_volume":
			Settings.sfx_volume = clampf(snappedf(Settings.sfx_volume + 0.1 * d, 0.1), 0.0, 1.0)
		"run_mode":
			Settings.run_mode = "toggle" if Settings.run_mode == "hold" else "hold"
		"ambience_volume":
			Settings.ambience_volume = clampf(snappedf(Settings.ambience_volume + 0.1 * d, 0.1), 0.0, 1.0)
		"follower":
			Settings.follower = not Settings.follower
		"colour_blind":
			Settings.colour_blind = not Settings.colour_blind
		"reduce_flashing":
			Settings.reduce_flashing = not Settings.reduce_flashing
		"damage_numbers":
			Settings.damage_numbers = not Settings.damage_numbers
		"text_blip":
			Settings.text_blip = not Settings.text_blip
		"local_languages":
			Settings.local_languages = "off" if Settings.local_languages == "on" else "on"
		"hints":
			Settings.hints = not Settings.hints
		"easy_fishing":
			Settings.easy_fishing = not Settings.easy_fishing
		"easy_darts":
			Settings.easy_darts = not Settings.easy_darts
	Settings.save_settings()
	if key == "sfx_volume":
		Audio.sfx("cursor")
	for r in _rows:
		if r.key == key:
			_paint_row(r)

func _paint_row(r: Dictionary) -> void:
	var l: Label = r.value
	match r.key:
		"text_speed":
			l.text = "<  %s  >" % Settings.text_speed.capitalize()
		"battle_speed":
			l.text = "<  %s  >" % Settings.battle_speed.capitalize()
		"travel_scenes":
			l.text = "<  %s  >" % Settings.travel_scenes.capitalize()
		"quality":
			l.text = "<  %s  >" % Settings.quality.capitalize()
		"music_volume":
			l.text = _pct(Settings.music_volume)
			r.bar.value = Settings.music_volume
		"sfx_volume":
			l.text = _pct(Settings.sfx_volume)
			r.bar.value = Settings.sfx_volume
		"run_mode":
			l.text = "<  %s  >" % ("Press to toggle" if Settings.run_mode == "toggle" else "Hold")
		"ambience_volume":
			l.text = _pct(Settings.ambience_volume)
			r.bar.value = Settings.ambience_volume
		"follower":
			l.text = "<  %s  >" % ("On" if Settings.follower else "Off")
		"colour_blind":
			l.text = "<  %s  >" % ("On" if Settings.colour_blind else "Off")
			_fill_chips()
		"reduce_flashing":
			l.text = "<  %s  >" % ("On" if Settings.reduce_flashing else "Off")
		"damage_numbers":
			l.text = "<  %s  >" % ("On" if Settings.damage_numbers else "Off")
		"text_blip":
			l.text = "<  %s  >" % ("On" if Settings.text_blip else "Off")
		"local_languages":
			l.text = "<  %s  >" % ("On" if Settings.local_languages == "on" else "Off")
		"hints":
			l.text = "<  %s  >" % ("On" if Settings.hints else "Off")
		"easy_fishing":
			l.text = "<  %s  >" % ("On" if Settings.easy_fishing else "Off")
		"easy_darts":
			l.text = "<  %s  >" % ("On" if Settings.easy_darts else "Off")

func _pct(v: float) -> String:
	return "<  %d%%  >" % (roundi(v * 10.0) * 10)

## Every type chip in the current palette, so the colour-blind switch shows what it does.
func _fill_chips() -> void:
	UIKit.clear(_chips)
	for t in TypeColours.COLOURS:
		_chips.add_child(UIKit.type_chip(t, 13))
