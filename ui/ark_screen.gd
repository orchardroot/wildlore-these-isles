extends MenuBase
## The Ark: creature storage. Left, the team. Right, the Ark box (30 per box; Prev/Next page through boxes).
## Choose anyone for their options: summary, rename, move across, swap directly with someone on the other side, release.
## "Sort" tidies the whole Ark by Fieldbook number, level or type.

const PER_BOX := 30

var _box := 0
var _left: VBoxContainer
var _right: GridContainer
var _box_label: Label
var _note: Label
var _sort_button: Button
var _sort_next := "dex"        # the order the Sort button will apply next
var _mode := "list"            # list | actions | swap | confirm
var _sel := {}                 # who the open popup (or the swap in progress) is about: {party: bool, i: int}
var _popup: Control
var _lefts: Array = []
var _rights: Array = []

func _build() -> void:
	set_title("The Ark")
	_set_hint()
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 28)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 14)
	lp.custom_minimum_size = Vector2(460, 0)
	row.add_child(lp)
	var lcol := VBoxContainer.new()
	lp.add_child(lcol)
	lcol.add_child(UIKit.label("Your team", 24, UIKit.MUTED))
	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 6)
	lcol.add_child(_left)
	var rcol := VBoxContainer.new()
	rcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rcol.add_theme_constant_override("separation", 10)
	row.add_child(rcol)
	var head := HBoxContainer.new()
	rcol.add_child(head)
	head.add_child(make_button("<", func(): _page(-1), 56))
	_box_label = UIKit.label("", 22, UIKit.CREAM)
	_box_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box_label.clip_text = true  # gives way to the Sort button rather than pushing it off the screen
	_box_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_box_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_box_label)
	head.add_child(make_button(">", func(): _page(1), 56))
	_sort_button = make_button("", _sort, 210)
	head.add_child(_sort_button)
	var rp := UIKit.panel(Color("1d2230f0"), 14)
	rp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rcol.add_child(rp)
	_right = GridContainer.new()
	_right.columns = 6
	_right.add_theme_constant_override("h_separation", 6)
	_right.add_theme_constant_override("v_separation", 4)
	rp.add_child(_right)
	_note = UIKit.label("", 26, UIKit.GOLD)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rcol.add_child(_note)
	_refresh()

## Dev (screenshots): "--menu=ark:sorted" shows the Ark after a Sort, "--menu=ark:options" with someone's options open.
func setup(arg: String) -> void:
	if arg == "sorted":
		_sort()
		_sort()  # by level, the more telling shot
	elif arg == "options":
		_open_actions(false, 1)

static func box_count(ark_size: int) -> int:
	return maxi(1, ceili(float(ark_size + 1) / PER_BOX))

func _set_hint() -> void:
	match _mode:
		"swap":
			set_hints([["confirm", "Swap with this one"], ["cancel", "Cancel the swap"]])
		"actions", "confirm":
			set_hints([["confirm", "Choose"], ["cancel", "Back"]])
		_:
			set_hints([["confirm", "Options"], ["cancel", "Back"]])

func _page(d: int) -> void:
	_box = posmod(_box + d, box_count(Game.data.ark.size()))
	_refresh()

## Sorts the whole Ark by the next order, then offers the one after it.
func _sort() -> void:
	var order := _sort_next
	ArkLogic.sort(Game.data.ark, order, Game.dex.ids())
	_note.text = "Sorted by %s." % ArkLogic.MODE_NAMES[order]
	_sort_next = ArkLogic.next_mode(order)
	_box = 0
	_refresh()
	UIKit.focus_later(_sort_button)

func _refresh(focus_left := -1, focus_right := -1) -> void:
	var data: GameStateData = Game.data
	UIKit.clear(_left)
	UIKit.clear(_right)
	_lefts = []
	for i in data.party.size():
		var b := _creature_button(data.party[i], true)
		b.pressed.connect(_pressed.bind(true, i))
		_left.add_child(b)
		_lefts.append(b)
	var boxes := box_count(data.ark.size())
	_box = clampi(_box, 0, boxes - 1)
	_box_label.text = "Box %d/%d, %d stored" % [_box + 1, boxes, data.ark.size()]
	_sort_button.text = "Sort: %s" % ArkLogic.MODE_NAMES[_sort_next]
	_rights = []
	for j in range(_box * PER_BOX, mini(data.ark.size(), (_box + 1) * PER_BOX)):
		var b := _creature_button(data.ark[j], false)
		b.pressed.connect(_pressed.bind(false, j))
		_right.add_child(b)
		_rights.append(b)
	if _rights.is_empty():
		_right.add_child(UIKit.label("Empty. Plenty of room in here.", 24, UIKit.MUTED))
	_sort_button.disabled = data.ark.size() < 2
	UIKit.wrap_focus(_lefts)
	if focus_right >= 0 and _rights.size() > 0:
		UIKit.focus_later(_rights[mini(focus_right, _rights.size() - 1)])
	elif _lefts.size() > 0:
		UIKit.focus_later(_lefts[clampi(focus_left, 0, _lefts.size() - 1)])

func _creature_button(c: Creature, wide: bool) -> Button:
	var b := UIKit.button("")
	b.focus_entered.connect(func(): Audio.sfx("cursor"))
	b.custom_minimum_size = Vector2(0, 70) if wide else Vector2(100, 78)
	var box: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var s := AnimSprite.new()
	s.show_species(c.species.id, "icon", 2, false, c.variant, c.form, c.sex)
	if c.is_fainted():
		s.modulate = Color(0.5, 0.5, 0.5)
	if wide:  # the team list: icon, name, and the level lined up on the right
		box.add_theme_constant_override("separation", 10)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(s)
		box.add_child(UIKit.sex_mark(c, 22))
		var nm := UIKit.label(c.display_name(), UIKit.fit_size(c.display_name(), 240, 26, 20))  # long names shrink a little first
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		box.add_child(nm)
		var lv := UIKit.label("L%d" % c.level, 24, UIKit.GOLD)
		lv.custom_minimum_size = Vector2(56, 0)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		box.add_child(lv)
		box.offset_right = -12
	else:  # a grid cell: icon over its level, both centred
		box.add_theme_constant_override("separation", -4)
		s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(s)
		var l := UIKit.label("L%d" % c.level, 18)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
	for k in box.get_children():
		k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _creature(party_side: bool, i: int) -> Creature:
	var list: Array = Game.data.party if party_side else Game.data.ark
	return list[i] if i >= 0 and i < list.size() else null

func _focus_creature(party_side: bool, i: int) -> void:
	if party_side:
		_refresh(i)
	else:
		_refresh(-1, i - _box * PER_BOX)

# --- picking ----------------------------------------------------------------------

func _pressed(party_side: bool, i: int) -> void:
	if _mode == "swap":
		_finish_swap(party_side, i)
	elif _mode == "list":
		_open_actions(party_side, i)

func _open_actions(party_side: bool, i: int) -> void:
	var c := _creature(party_side, i)
	if c == null:
		return
	_sel = {"party": party_side, "i": i}
	var buttons := [["Summary", _do_summary], ["Rename", _do_rename]]
	if party_side:
		buttons.append(["Move to the Ark", _do_move])
		buttons.append(["Swap with a stored one", _do_swap])
	else:
		buttons.append(["Join the team", _do_move])
		buttons.append(["Swap with a team member", _do_swap])
	buttons.append(["Release", _do_release])
	buttons.append(["Back", _close_popup])
	_show_popup("%s  L%d" % [c.display_name(), c.level], "", buttons, 0)
	_mode = "actions"
	_set_hint()

## A small centred card with a heading, an optional line and a column of buttons. `focus` picks the one to start on.
func _show_popup(title: String, line: String, buttons: Array, focus: int) -> void:
	_clear_popup()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_STOP
	var p := UIKit.panel(Color("0f1220fa"), 20)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var t := UIKit.label(title, 32, UIKit.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if line != "":
		var l := UIKit.label(line, 24)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(440, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var made := []
	for pair in buttons:
		var b := make_button(pair[0], pair[1], 440)
		v.add_child(b)
		made.append(b)
	UIKit.wrap_focus(made)
	cc.add_child(p)
	content.add_child(cc)
	_popup = cc
	UIKit.focus_later(made[clampi(focus, 0, made.size() - 1)])

func _clear_popup() -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.queue_free()
	_popup = null

func _close_popup() -> void:
	_clear_popup()
	_mode = "list"
	_set_hint()
	_focus_creature(_sel.get("party", true), int(_sel.get("i", 0)))

# --- the options ---------------------------------------------------------------------

func _do_summary() -> void:
	var party_side: bool = _sel.party
	var i: int = _sel.i
	_clear_popup()
	_mode = "list"
	await open_local("res://ui/summary_screen.tscn", str(i) if party_side else "ark:%d" % i)
	_mode = "list"
	_set_hint()
	_focus_creature(party_side, i)

func _do_rename() -> void:
	var party_side: bool = _sel.party
	var i: int = _sel.i
	var old := _creature(party_side, i).display_name()
	_clear_popup()
	_mode = "list"
	var r = await open_child("name:nickname:%d" % i if party_side else "name:nickname:ark:%d" % i)
	_set_hint()
	var now := _creature(party_side, i).display_name()
	if r is String and now != old:
		_note.text = "%s it is. They seem pleased." % now
	_focus_creature(party_side, i)

func _do_move() -> void:
	var party_side: bool = _sel.party
	var i: int = _sel.i
	var why := Game.data.deposit(i) if party_side else Game.data.withdraw(i)
	_clear_popup()
	_mode = "list"
	_set_hint()
	Audio.sfx("bump" if why != "" else "confirm")
	if why != "":
		_note.text = why
		_focus_creature(party_side, i)
		return
	if party_side:
		_note.text = "Safe and sound in the Ark."
		_box = box_count(Game.data.ark.size()) - 1
		_refresh(i)
	else:
		_note.text = "Back on the team."
		_refresh(-1, i - _box * PER_BOX)

func _do_swap() -> void:
	var party_side: bool = _sel.party
	var other: Array = Game.data.ark if party_side else Game.data.party
	_clear_popup()
	if other.is_empty():
		_mode = "list"
		_set_hint()
		_note.text = "Nobody stored to swap with." if party_side else "Nobody on the team to swap with."
		_focus_creature(party_side, _sel.i)
		return
	_mode = "swap"
	_set_hint()
	_note.text = "Swapping %s. Pick %s." % [_creature(party_side, _sel.i).display_name(), "one from the Ark" if party_side else "a team member"]
	if party_side:
		_refresh(-1, 0)
	else:
		_refresh(0)

func _finish_swap(party_side: bool, i: int) -> void:
	if party_side == bool(_sel.party):
		Audio.sfx("bump")
		_note.text = "Pick %s." % ("one from the Ark" if _sel.party else "a team member")
		return
	var pi: int = i if party_side else _sel.i
	var aj: int = _sel.i if party_side else i
	var why := Game.data.swap_with_ark(pi, aj)
	_mode = "list"
	_set_hint()
	Audio.sfx("bump" if why != "" else "confirm")
	if why != "":
		_note.text = why
		_focus_creature(bool(_sel.party), _sel.i)
		return
	_note.text = "Swapped. Nobody argued."
	_focus_creature(true, pi)

func _do_release() -> void:
	var rule := ArkLogic.release_rule(Game.data, _sel.party, _sel.i)
	if not rule.ok:
		Audio.sfx("bump")
		_clear_popup()
		_mode = "list"
		_set_hint()
		_note.text = rule.why
		_focus_creature(_sel.party, _sel.i)
		return
	_ask_release(1, int(rule.confirms))

## Release asks "sure?" (and, for a legend, "really sure?"). The cursor starts on "Keep".
func _ask_release(step: int, of: int) -> void:
	var c := _creature(_sel.party, _sel.i)
	var line := "Let %s go for good? They can't be got back." % c.display_name()
	if of > 1:
		if step == 1:
			line = "%s is a legend. Let them go for good? There is no getting a legend back." % c.display_name()
		else:
			line = "Really? %s will be gone. This is your last chance to change your mind." % c.display_name()
	_show_popup("Release?", line, [["Keep %s" % c.display_name(), _close_popup], ["Release", func(): _release_confirmed(step, of)]], 0)
	_mode = "confirm"
	_set_hint()

func _release_confirmed(step: int, of: int) -> void:
	if step < of:
		_ask_release(step + 1, of)
		return
	var party_side: bool = _sel.party
	var i: int = _sel.i
	var who := _creature(party_side, i).display_name()
	var why := Game.data.release(party_side, i)
	_clear_popup()
	_mode = "list"
	_set_hint()
	Audio.sfx("bump" if why != "" else "confirm")
	_note.text = why if why != "" else "%s wandered off into the wild. Good luck out there." % who
	_focus_creature(party_side, maxi(0, i - 1) if party_side else i)

func _on_cancel() -> void:
	match _mode:
		"actions", "confirm":
			Audio.sfx("cancel")
			_close_popup()
		"swap":
			Audio.sfx("cancel")
			_mode = "list"
			_set_hint()
			_note.text = ""
			_focus_creature(bool(_sel.party), _sel.i)
		_:
			close(null)
