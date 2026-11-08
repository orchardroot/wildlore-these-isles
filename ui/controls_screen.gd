extends MenuBase
## Settings > Controls: every gameplay action with its keyboard and gamepad buttons. Move to a cell, press Z (or A),
## then press the new key or pad button. Confirm and Cancel can't be unbound or made to share a button.
## Pressing Esc on the keyboard (or waiting a few seconds) cancels a rebind; Esc itself stays the Menu key.

const CAPTURE_SECONDS := 6.0

var _cells := {}              # "action:device" -> Button
var _message: Label
var _capturing := ""          # "action:device" while waiting for a press
var _capture_left := 0.0
var _armed_at := 0

func _build() -> void:
	set_title("Controls")
	set_hints([["updown", "Choose"], ["confirm", "Rebind"], ["cancel", "Back"]])
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 8)
	content.add_child(col)
	var p := UIKit.panel(Color("1d2230f0"), 12)
	col.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(_hdr("Action", 300))
	head.add_child(_hdr("Keyboard", 420))
	head.add_child(_hdr("Gamepad", 0))
	v.add_child(head)
	var rows := []
	for a in InputSetup.ACTIONS:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var name_l := UIKit.label(InputSetup.LABELS[a], 21)
		name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_l.custom_minimum_size = Vector2(292, 0)
		h.add_child(name_l)
		var kb := _cell(a, "key", 420)
		var pad := _cell(a, "pad", 0)
		pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(kb)
		h.add_child(pad)
		v.add_child(h)
		rows.append([kb, pad])
	_link_grid(rows)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	var reset := make_button("Reset to defaults", _reset, 300)
	var back := make_button("Back", func(): close(null), 200)
	for b in [reset, back]:
		b.custom_minimum_size.y = 40
		UIKit.compact(b, 6)
	bottom.add_child(reset)
	bottom.add_child(back)
	v.add_child(bottom)
	# Down from the last cells reaches Reset / Back, and the ends loop round.
	var last_row: Array = rows[rows.size() - 1]
	last_row[0].focus_neighbor_bottom = last_row[0].get_path_to(reset)
	last_row[1].focus_neighbor_bottom = last_row[1].get_path_to(back)
	reset.focus_neighbor_top = reset.get_path_to(last_row[0])
	back.focus_neighbor_top = back.get_path_to(last_row[1])
	reset.focus_neighbor_right = reset.get_path_to(back)
	back.focus_neighbor_left = back.get_path_to(reset)
	reset.focus_neighbor_left = NodePath(".")
	back.focus_neighbor_right = NodePath(".")
	reset.focus_neighbor_bottom = reset.get_path_to(rows[0][0])
	back.focus_neighbor_bottom = back.get_path_to(rows[0][1])
	rows[0][0].focus_neighbor_top = rows[0][0].get_path_to(reset)
	rows[0][1].focus_neighbor_top = rows[0][1].get_path_to(back)
	_message = UIKit.label("Photo mode: the move keys swing the camera, + / - zoom, Confirm takes a photo.  %s anywhere reports a problem." % InputSetup.hint_name(Settings.bindings, "report", false), 20, UIKit.GOLD)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_message)
	_refresh()
	UIKit.focus_later(rows[0][0])

func _hdr(text: String, w: int) -> Label:
	var l := UIKit.label(text, 20, UIKit.MUTED)
	l.custom_minimum_size = Vector2(w, 0)
	if w == 0:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _cell(action: String, device: String, w: int) -> Button:
	var b := UIKit.button("", w)
	b.custom_minimum_size = Vector2(w, 30)
	b.add_theme_font_size_override("font_size", 21)
	UIKit.compact(b, 1)
	b.focus_entered.connect(func(): Audio.sfx("cursor"))
	b.pressed.connect(func(): begin_capture(action, device))
	_cells["%s:%s" % [action, device]] = b
	return b

## Keeps left/right on the row's two cells (no wrapping out of the row).
func _link_grid(rows: Array) -> void:
	for r in rows:
		r[0].focus_neighbor_left = NodePath(".")
		r[0].focus_neighbor_right = r[0].get_path_to(r[1])
		r[1].focus_neighbor_left = r[1].get_path_to(r[0])
		r[1].focus_neighbor_right = NodePath(".")

func _refresh() -> void:
	for key in _cells:
		var parts: PackedStringArray = key.split(":")
		var b: Button = _cells[key]
		if key == _capturing:
			b.text = "Press a %s..." % ("key" if parts[1] == "key" else "pad button")
		else:
			b.text = InputSetup.describe(Settings.bindings, parts[0], parts[1])

## True while a cell waits for its new key (the report key stays quiet so F9 can be bound).
func capturing() -> bool:
	return _capturing != ""

## Starts waiting for the next key (or pad button, for a gamepad cell).
func begin_capture(action: String, device: String) -> void:
	_capturing = "%s:%s" % [action, device]
	_capture_left = CAPTURE_SECONDS
	_armed_at = Time.get_ticks_msec() + 150
	_say("Press the new %s for %s  (Esc cancels)" % ["key" if device == "key" else "pad button", InputSetup.LABELS[action]])
	_refresh()

## Feeds a pressed key or pad button to a waiting rebind. Returns true if the event was consumed.
func handle_capture(event: InputEvent) -> bool:
	if _capturing == "":
		return false
	var parts: PackedStringArray = _capturing.split(":")
	var code := -1
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_end_capture("Cancelled.")
			return true
		if parts[1] == "key":
			code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		else:
			return true  # a pad cell ignores the keyboard
	elif event is InputEventJoypadButton and event.pressed and parts[1] == "pad":
		code = event.button_index
	elif event is InputEventMouseButton and event.pressed:
		_end_capture("Cancelled.")
		return true
	else:
		return event is InputEventKey or event is InputEventJoypadButton
	if Time.get_ticks_msec() < _armed_at:
		return true
	var err := Settings.rebind(parts[0], parts[1], code)
	if err == "":
		Audio.sfx("confirm")
		_end_capture("%s: %s" % [InputSetup.LABELS[parts[0]], InputSetup.describe(Settings.bindings, parts[0], parts[1])])
	else:
		Audio.sfx("cancel")
		_end_capture("Not changed. " + err + ".")
	return true

func _end_capture(msg: String) -> void:
	_capturing = ""
	_say(msg)
	_refresh()

func _reset() -> void:
	Settings.reset_bindings()
	_say("Controls reset to defaults.")
	_refresh()

func _say(text: String) -> void:
	if _message:
		_message.text = text

func _process(delta: float) -> void:
	if _capturing != "":
		_capture_left -= delta
		if _capture_left <= 0.0:
			_end_capture("Cancelled.")

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	if _capturing != "" and handle_capture(event):
		get_viewport().set_input_as_handled()
		return
	super._input(event)
