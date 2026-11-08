extends MenuBase
## Settings > Accessibility: text size and the readable font, with a live sample, and a plain list of the other aids
## (colour-blind palette, reduce flashing, easier timing, remappable controls) and where to find them.

const SAMPLE := "Oi. That's my sandwich. Also, welcome to Cheshire."
const NOTES := [
	"Colour-blind friendly is on the Settings page; every type also has its own shape.",
	"Easier fishing and Easier pub games make every timing game kinder: fishing, sheepdogs, darts, crabbing, bells, shanties, walling and conkers.",
	"Every key and gamepad button can be changed under Controls.",
]

var _rows: Array = []   # {key, value}
var _sample: Label

func _build() -> void:
	set_title("Accessibility")
	set_hints([["leftright", "Change"], ["confirm", "Select"], ["cancel", "Back"]])
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	content.add_child(col)
	var p := UIKit.panel(Color("1d2230f0"), 14)
	col.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var buttons := []
	for def in [["text_size", "Text size"], ["readable_font", "Readable font"], ["reduce_flashing", "Reduce flashing"],
			["easy_fishing", "Easier fishing and sheepdogs"], ["easy_darts", "Easier pub games and crafts"]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, maxi(30, UIKit.line_height(23)))  # taller with Large text so rows never overlap
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
		var val := UIKit.label("", 23, UIKit.GOLD)
		val.custom_minimum_size = Vector2(190, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(val)
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		var key: String = def[0]
		b.focus_neighbor_left = NodePath(".")
		b.focus_neighbor_right = NodePath(".")
		b.focus_entered.connect(func(): Audio.sfx("cursor"))
		b.pressed.connect(func():
			_change(key, 1)
			Audio.sfx("confirm"))
		v.add_child(b)
		buttons.append(b)
		_rows.append({"key": key, "button": b, "value": val})
	var back := make_button("Back", func(): close(null), 200)
	v.add_child(UIKit.spacer(6))
	v.add_child(back)
	buttons.append(back)
	UIKit.wrap_focus(buttons)
	var pp := UIKit.panel(Color("14182199"), 14)
	col.add_child(pp)
	var pv := VBoxContainer.new()
	pp.add_child(pv)
	_sample = UIKit.label(SAMPLE, 20)
	_sample.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(_sample)
	for n in NOTES:
		var l := UIKit.label(n, 17, UIKit.HEATHER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pv.add_child(l)
	for r in _rows:
		_paint(r)
	UIKit.focus_later(buttons[0])

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
	if key == "text_size":
		var sizes := Access.TEXT_SIZES.keys()
		Settings.text_size = sizes[MenuLogic.wrap_index(maxi(0, sizes.find(Settings.text_size)), d, sizes.size())]
	elif key == "readable_font":
		Settings.readable_font = not Settings.readable_font
	else:  # the plain on/off toggles
		Settings.set(key, not bool(Settings.get(key)))
	Settings.apply_access()
	Settings.save_settings()
	_sample.add_theme_font_size_override("font_size", Access.scaled(20, Settings.text_size))
	for r in _rows:
		_paint(r)

func _paint(r: Dictionary) -> void:
	var l: Label = r.value
	if r.key == "text_size":
		l.text = "<  %s  >" % Settings.text_size.capitalize()
	else:
		l.text = "<  %s  >" % ("On" if bool(Settings.get(r.key)) else "Off")
