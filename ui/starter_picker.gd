extends MenuBase
## Starter picker: three creatures on plinths, Professor Garside's take on each. Left/right to look, confirm twice.
## Returns the chosen species id through closed(result). It is not optional, so cancel only un-confirms.

const STARTERS := ["spikkin", "holtling", "kindlet"]
const LINES := {
	"spikkin": "Spikkin. Stubborn, prickly and thoroughly dependable. It will hold the line while you work out what you're doing, and then sulk if you thank it.",
	"holtling": "Holtling. Curious, quick and never dry for long. It has already investigated my tea, my boots and, regrettably, my notes.",
	"kindlet": "Kindlet. Warm paws, warmer temper, and a tail that has set off the smoke alarm twice. Keep it away from the filing cabinet.",
}

var _index := 0
var _confirming := false
var _cols: Array = []
var _holders: Array = []
var _line: Label
var _prompt: Label

func _build() -> void:
	set_title("Choose your partner")
	header_right.text = "Professor Garside's field station"
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	content.add_child(col)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	for id in STARTERS:
		var sp: Dictionary = Game.dex.get_species(id)
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		p.add_child(v)
		var holder := VBoxContainer.new()
		holder.custom_minimum_size = Vector2(0, 288)
		holder.alignment = BoxContainer.ALIGNMENT_END
		v.add_child(holder)
		_holders.append(holder)
		var plinth := PanelContainer.new()
		plinth.add_theme_stylebox_override("panel", UIKit.box(Color("8d8579"), Color("5d564c"), 3, 4, 6))
		plinth.custom_minimum_size = Vector2(0, 26)
		plinth.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var pl := Control.new()
		pl.custom_minimum_size = Vector2(300, 8)
		plinth.add_child(pl)
		v.add_child(plinth)
		var n := UIKit.label(str(sp.get("name", id)), 34)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
		var tr := UIKit.types_row(sp.get("types", []), 22)
		tr.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(tr)
		row.add_child(p)
		_cols.append(p)
	var dlg := UIKit.panel(Color("1d2230f8"), 10)
	col.add_child(dlg)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	dlg.add_child(dv)
	var dh := HBoxContainer.new()
	dv.add_child(dh)
	dh.add_child(UIKit.label("Prof. Garside", 22, UIKit.GOLD))
	dh.add_child(UIKit.fill())
	_prompt = UIKit.label("", 22, UIKit.GOLD)
	dh.add_child(_prompt)
	_line = UIKit.label("", 22)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(_line)
	_refresh()

func _refresh() -> void:
	for i in STARTERS.size():
		var on := i == _index
		var p: PanelContainer = _cols[i]
		p.add_theme_stylebox_override("panel", UIKit.box(Color("2c3446f0") if on else Color("1d223099"),
			UIKit.GOLD if (on and _confirming) else (UIKit.HEATHER if on else Color("4a4f5e")), 4 if on else 2, 10, 8))
		p.modulate = Color.WHITE if on else Color(1, 1, 1, 0.6)
		UIKit.clear(_holders[i])
		var s := AnimSprite.new()
		s.show_species(STARTERS[i], "front", 3 if on else 2)
		s.animate(Game.dex.get_species(STARTERS[i]))
		s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_holders[i].add_child(s)
	_line.text = LINES.get(STARTERS[_index], "")
	_update_prompt()
	if _confirming:
		set_hints([["confirm", "Confirm"], ["cancel", "Look again"]])
	else:
		set_hints([["leftright", "Look"], ["confirm", "Choose"]])

## The "Press Z again" sentence names the live button, so it is rebuilt with the hint bar when the device or bindings change.
func _update_prompt() -> void:
	if not _confirming:
		_prompt.text = ""
		return
	var name: String = Game.dex.get_species(STARTERS[_index]).get("name", STARTERS[_index])
	_prompt.text = "Take %s? Press %s again to be sure." % [name, UIKit.key_for("confirm")]

func _redraw_hint() -> void:
	super()
	if is_instance_valid(_prompt):
		_update_prompt()

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	var d := 0
	if event.is_action_pressed("move_left"):
		d = -1
	elif event.is_action_pressed("move_right"):
		d = 1
	if d != 0:
		get_viewport().set_input_as_handled()
		_index = MenuLogic.wrap_index(_index, d, STARTERS.size())
		_confirming = false
		Audio.sfx("cursor")
		_refresh()
	elif event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		if _confirming:
			_done = true
			Audio.sfx("confirm")
			closed.emit(STARTERS[_index])
		else:
			_confirming = true
			Audio.sfx("confirm")
			_refresh()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_on_cancel()

func _on_cancel() -> void:
	if _confirming:
		_confirming = false
		Audio.sfx("cancel")
		_refresh()
