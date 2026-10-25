extends MenuBase
## Team: six slots with icon, name, level, HP bar, status, hearts and charm. Actions: Summary, Rename, Switch order,
## Use item, Hold / Take a charm.

var _slots: Array = []        # Buttons for filled slots
var _slot_col: VBoxContainer
var _preview: VBoxContainer
var _actions: VBoxContainer
var _action_buttons: Array = []
var _mode := "list"           # list | actions | swap
var _picked := -1             # slot chosen as the first half of a swap
var _cursor := 0
var _note: Label

func _build() -> void:
	set_title("Team")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 24)
	content.add_child(row)
	_slot_col = VBoxContainer.new()
	_slot_col.add_theme_constant_override("separation", 8)
	_slot_col.custom_minimum_size = Vector2(700, 0)
	row.add_child(_slot_col)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var pp := UIKit.panel(Color("1d2230f0"), 18)
	pp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(pp)
	_preview = VBoxContainer.new()
	_preview.add_theme_constant_override("separation", 8)
	pp.add_child(_preview)
	_actions = VBoxContainer.new()
	var ap := UIKit.panel(Color("1d2230f0"), 10)
	ap.add_child(_actions)
	right.add_child(ap)
	for a in [["Summary", _do_summary], ["Rename", _do_rename], ["Switch order", _do_switch], ["Use item", _do_use], ["Charm", _do_charm], ["Back", _to_list]]:
		var b := make_button(a[0], a[1])
		_actions.add_child(b)
		_action_buttons.append(b)
	UIKit.wrap_focus(_action_buttons)
	_note = UIKit.label("", 24, UIKit.GOLD)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_note)
	_refresh()
	_focus_slot(0)

func _refresh() -> void:
	UIKit.clear(_slot_col)
	_slots.clear()
	var party := party()
	for i in 6:
		if i < party.size():
			var b := _slot_button(party[i], i)
			_slot_col.add_child(b)
			_slots.append(b)
		else:
			var e := PanelContainer.new()
			e.add_theme_stylebox_override("panel", UIKit.box(Color("14182180"), Color("4a4f5e"), 2, 6, 10))
			e.custom_minimum_size = Vector2(0, 84)
			var l := UIKit.label("Room for one more", 22, UIKit.MUTED)
			l.modulate.a = 0.6
			e.add_child(l)
			_slot_col.add_child(e)
	UIKit.wrap_focus(_slots)
	_actions.get_parent().visible = _mode == "actions"
	_set_hint()

func _set_hint() -> void:
	match _mode:
		"list": set_hints([["confirm", "Choose"], ["cancel", "Back"]])
		"actions": set_hints([["confirm", "Select"], ["cancel", "Back"]])
		"swap": set_hints([["confirm", "Swap with here"], ["cancel", "Cancel"]])

func _slot_button(c: Creature, i: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 84)
	b.focus_entered.connect(func():
		_cursor = i
		Audio.sfx("cursor")
		_show_preview(c))
	b.pressed.connect(func():
		Audio.sfx("confirm")
		_slot_pressed(i))
	if _mode == "swap" and i == _picked:
		b.add_theme_stylebox_override("normal", UIKit.box(Color("3b2f4a"), UIKit.HEATHER, 2, 6, 10))
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -14
	h.add_theme_constant_override("separation", 14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var icon := AnimSprite.new()
	icon.show_species(c.species.id, "icon", 2, false, c.variant, c.form, c.sex)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if c.is_fainted():
		icon.modulate = Color(0.55, 0.55, 0.55)
	h.add_child(icon)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 4)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(mid)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(UIKit.sex_mark(c, 24))
	var name_l := UIKit.label(c.display_name(), 28, Color("e9998c") if c.is_fainted() else UIKit.CREAM)
	top.add_child(name_l)
	top.add_theme_constant_override("separation", 14)
	var chip: Control = UIKit.chip("fainted", Color("6b2f2f")) if c.is_fainted() else UIKit.status_chip(c.status)
	if chip:
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(chip)
	top.add_child(UIKit.fill())
	if c.held != "":
		var tok := BondIcons.Token.new(18)
		tok.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tok.tooltip_text = Charms.name_of(c.held)
		top.add_child(tok)
	top.add_child(BondIcons.heart_count(c.friendship, 22))
	top.add_child(UIKit.label("Lv %d" % c.level, 24, UIKit.GOLD))
	mid.add_child(top)
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 12)
	var hp := UIKit.hp_bar(c.hp, c.max_hp(), 330, 14)
	hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(hp)
	bar.add_child(UIKit.label("%d / %d" % [c.hp, c.max_hp()], 20, UIKit.MUTED))
	mid.add_child(bar)
	return b

func _show_preview(c: Creature) -> void:
	UIKit.clear(_preview)
	var s := AnimSprite.new()
	s.show_species(c.species.id, "front", 2, false, c.variant, c.form, c.sex)
	s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_preview.add_child(s)
	var n := UIKit.label(c.display_name(), 36)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Sexes.valid(c.sex):
		var nr := HBoxContainer.new()
		nr.alignment = BoxContainer.ALIGNMENT_CENTER
		nr.add_theme_constant_override("separation", 10)
		nr.add_child(UIKit.sex_mark(c, 30))
		nr.add_child(n)
		_preview.add_child(nr)
	else:
		_preview.add_child(n)
	var tr := UIKit.types_row(c.types())
	tr.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview.add_child(tr)
	var nat := UIKit.label("%s temper" % c.nature.capitalize(), 22, UIKit.MUTED)
	nat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview.add_child(nat)

func _focus_slot(i: int) -> void:
	if _slots.is_empty():
		return
	UIKit.focus_later(_slots[clampi(i, 0, _slots.size() - 1)])

func _slot_pressed(i: int) -> void:
	_charm_label(i)
	if _mode == "swap":
		var order := MenuLogic.reorder(Game.data.party, _picked, i)
		Game.data.party.clear()
		Game.data.party.append_array(order)
		_note.text = "Shuffled. Nobody argued." if _picked != i else ""
		_mode = "list"
		_picked = -1
		_refresh()
		_focus_slot(i)
		return
	_mode = "actions"
	_cursor = i
	_actions.get_parent().visible = true
	_set_hint()
	_action_buttons[0].grab_focus()

func _to_list() -> void:
	_mode = "list"
	_actions.get_parent().visible = false
	_set_hint()
	_focus_slot(_cursor)

func _do_summary() -> void:
	var i := _cursor
	await open_local("res://ui/summary_screen.tscn", str(i))
	_action_buttons[0].grab_focus()

func _do_rename() -> void:
	var i := _cursor
	var old: String = party()[i].display_name()
	var r = await open_child("name:nickname:%d" % i)
	_refresh()
	_actions.get_parent().visible = true
	_show_preview(party()[i])
	if r is String and party()[i].display_name() != old:
		_note.text = "%s it is. They seem pleased." % party()[i].display_name()
	_action_buttons[1].grab_focus()

func _do_switch() -> void:
	if party().size() < 2:
		_note.text = "Only one on the team. Nothing to shuffle."
		return
	_mode = "swap"
	_picked = _cursor
	_note.text = ""
	_refresh()
	_focus_slot(_cursor)

func _do_use() -> void:
	await open_child("bag:for:%d" % _cursor)
	var i := _cursor
	_refresh()
	_actions.get_parent().visible = true
	_show_preview(party()[i])
	_action_buttons[3].grab_focus()

## The charm action says what it will do for this creature.
func _charm_label(i: int) -> void:
	if i >= 0 and i < party().size():
		_action_buttons[4].text = "Take %s" % Charms.name_of(party()[i].held) if party()[i].held != "" else "Hold a charm"

## Take its charm back, or pick one from the bag for it to hold.
func _do_charm() -> void:
	var i := _cursor
	var c: Creature = party()[i]
	var bag := Bag.new(Game.data.bag)
	if c.held != "":
		_note.text = str(bag.take_charm(c).text)
		Audio.sfx("confirm")
	elif Game.items == null or bag.items_of_kind("charm", Game.items).is_empty():
		_note.text = "You haven't any charms to give. Shops in the big towns sell a few."
		Audio.sfx("bump")
		return
	else:
		await open_child("bag:hold:%d" % i)
	_refresh()
	_actions.get_parent().visible = true
	_show_preview(party()[i])
	_charm_label(i)
	_action_buttons[4].grab_focus()

func _on_cancel() -> void:
	match _mode:
		"actions":
			Audio.sfx("cancel")
			_to_list()
		"swap":
			Audio.sfx("cancel")
			var i := _picked
			_mode = "list"
			_picked = -1
			_refresh()
			_focus_slot(i)
		_:
			close(null)
