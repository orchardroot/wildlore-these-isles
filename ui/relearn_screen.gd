extends MenuBase
## The move relearner (story command {"do": "relearn"}): pick a team member, pick a move from its learnset at or
## below its level that it has forgotten (or never had room for), then a move to replace if all four slots are full.
## Closes with {"creature": display name, "move": move id} once a move is learned, or null if backed out.
## Dev/screenshot arg: "<party index>[:<move id>]" jumps straight to that creature's list (or the replace step).

var _mode := "party"         # party | moves | forget
var _who := 0                # party index being taught
var _teaching := false       # a chapbook from the Bag: backing out of the forget step leaves altogether
var _new_move := ""          # move id waiting for a slot
var _list_col: VBoxContainer
var _side: VBoxContainer
var _note: Label
var _buttons: Array = []
var _party_cursor := 0
var _move_cursor := 0

func _build() -> void:
	set_title("Remembering moves")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 24)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 12)
	lp.custom_minimum_size = Vector2(700, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_col.add_theme_constant_override("separation", 8)
	sc.add_child(_list_col)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var sp := UIKit.panel(Color("1d2230f0"), 18)
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(sp)
	_side = VBoxContainer.new()
	_side.add_theme_constant_override("separation", 10)
	sp.add_child(_side)
	_note = UIKit.label("", 24, UIKit.GOLD)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_note)
	_show_party()

func setup(arg: String) -> void:
	if arg == "":
		return
	var parts := arg.split(":")
	if parts[0] == "teach" and parts.size() == 3 and parts[1].is_valid_int() and int(parts[1]) < party().size():  # from the Bag: a chapbook for one creature, all slots full
		_who = int(parts[1])
		_teaching = true
		_pick_move(parts[2])
		return
	if not parts[0].is_valid_int() or int(parts[0]) < 0 or int(parts[0]) >= party().size():
		return
	_party_cursor = int(parts[0])
	_pick_creature(_party_cursor)
	if parts.size() > 1 and parts[1] in Progression.relearnable(party()[_who]):
		_pick_move(parts[1])

# ---- step 1: who

func _show_party() -> void:
	_mode = "party"
	header_right.text = ""
	set_hints([["confirm", "Choose"], ["cancel", "Back"]])
	_note.text = "Who needs reminding?"
	_reset_list()
	for i in party().size():
		var c: Creature = party()[i]
		var n := Progression.relearnable(c).size()
		var b := _row_button(func(): _focus_creature(i), func(): _pick_creature(i))
		var h := _row_box(b)
		var icon := AnimSprite.new()
		icon.show_species(c.species.id, "icon", 2, false, c.variant, c.form, c.sex)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(icon)
		h.add_child(UIKit.sex_mark(c, 22))
		h.add_child(UIKit.label(c.display_name(), 28))
		h.add_child(UIKit.fill())
		h.add_child(UIKit.label(("%d to remember" % n) if n > 0 else "nothing new", 22, UIKit.GOLD if n > 0 else UIKit.MUTED))
		h.add_child(UIKit.label("Lv %d" % c.level, 24, UIKit.CREAM))
		_ignore_mouse(h)
	_finish_list(_party_cursor)

func _focus_creature(i: int) -> void:
	_party_cursor = i
	var c: Creature = party()[i]
	UIKit.clear(_side)
	var s := AnimSprite.new()
	s.show_species(c.species.id, "front", 2, false, c.variant, c.form, c.sex)
	s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_side.add_child(s)
	var n := UIKit.label(c.display_name(), 34)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side.add_child(n)
	_side.add_child(UIKit.label("Knows", 22, UIKit.MUTED))
	for m in c.moves:
		_side.add_child(UIKit.label(str(Game.moves.get_move(m.id).get("name", m.id)), 24))

func _pick_creature(i: int) -> void:
	if Progression.relearnable(party()[i]).is_empty():
		Audio.sfx("bump")
		_note.text = "%s remembers everything it ever learned. Sharp as a tack." % party()[i].display_name()
		return
	_who = i
	_move_cursor = 0
	_show_moves()

# ---- step 2: which move

func _show_moves() -> void:
	_mode = "moves"
	var c: Creature = party()[_who]
	header_right.text = c.display_name()
	set_hints([["confirm", "Remember this one"], ["cancel", "Back"]])
	_note.text = "Which move should %s remember?" % c.display_name()
	_reset_list()
	for id in Progression.relearnable(c):
		var info: Dictionary = Game.moves.get_move(id)
		var b := _row_button(func(): _describe(id), func(): _pick_move(id))
		var h := _row_box(b)
		var chip := UIKit.type_chip(str(info.get("type", "kin")), 16)
		chip.custom_minimum_size = Vector2(96, 0)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(chip)
		h.add_child(UIKit.label(str(info.get("name", id)), 28))
		h.add_child(UIKit.fill())
		h.add_child(UIKit.label("PP %d" % int(info.get("pp", 10)), 22, UIKit.MUTED))
		_ignore_mouse(h)
	_finish_list(_move_cursor)

func _describe(id: String) -> void:
	_move_cursor = maxi(0, Progression.relearnable(party()[_who]).find(id))
	UIKit.clear(_side)
	var info: Dictionary = Game.moves.get_move(id)
	_side.add_child(UIKit.label(str(info.get("name", id)), 34))
	_side.add_child(UIKit.types_row([str(info.get("type", "kin"))], 20))
	var power := int(info.get("power", 0))
	_side.add_child(UIKit.label("%sAccuracy %d  ·  PP %d" % [("Power %d  ·  " % power) if power > 0 else "", int(info.get("accuracy", 100)), int(info.get("pp", 10))], 22, UIKit.GOLD))
	var d := UIKit.label(MoveText.describe(info), 22, Color("d8cfb4"))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(d)

func _pick_move(id: String) -> void:
	_new_move = id
	var c: Creature = party()[_who]
	if c.moves.size() < Rules.MAX_MOVES:
		_learn(0)
		return
	_show_forget()

# ---- step 3: what to forget (only when all four slots are full)

func _show_forget() -> void:
	_mode = "forget"
	var c: Creature = party()[_who]
	var new_name := str(Game.moves.get_move(_new_move).get("name", _new_move))
	set_hints([["confirm", "Forget this one"], ["cancel", "Back"]])
	_note.text = "%s can only hold four moves. Which one makes way for %s?" % [c.display_name(), new_name]
	_describe(_new_move)
	_reset_list()
	for i in c.moves.size():
		var id := str(c.moves[i].id)
		var info: Dictionary = Game.moves.get_move(id)
		var b := _row_button(func(): pass, func(): _learn(i))
		var h := _row_box(b)
		var chip := UIKit.type_chip(str(info.get("type", "kin")), 16)
		chip.custom_minimum_size = Vector2(96, 0)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(chip)
		h.add_child(UIKit.label(str(info.get("name", id)), 28))
		h.add_child(UIKit.fill())
		h.add_child(UIKit.label("PP %d/%d" % [int(c.moves[i].pp), int(c.moves[i].max_pp)], 22, UIKit.MUTED))
		_ignore_mouse(h)
	_finish_list(0)

func _learn(slot: int) -> void:
	var c: Creature = party()[_who]
	var old := str(Game.moves.get_move(c.moves[slot].id).get("name", "")) if c.moves.size() >= Rules.MAX_MOVES else ""
	Progression.relearn(c, _new_move, slot, Game.moves)
	Audio.sfx("heal")
	_done = true  # not close(): that plays the back-out sound
	closed.emit({"creature": c.display_name(), "move": _new_move, "forgot": old})

# ---- shared bits

func _reset_list() -> void:
	UIKit.clear(_list_col)
	_buttons.clear()

func _row_button(on_focus: Callable, on_press: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 72)
	b.focus_entered.connect(func():
		Audio.sfx("cursor")
		on_focus.call())
	b.pressed.connect(func():
		Audio.sfx("confirm")
		on_press.call())
	_list_col.add_child(b)
	_buttons.append(b)
	return b

func _row_box(b: Button) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -14
	h.add_theme_constant_override("separation", 14)
	b.add_child(h)
	return h

func _ignore_mouse(h: Control) -> void:
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in h.get_children():
		k.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _finish_list(focus: int) -> void:
	if _buttons.is_empty():
		_list_col.add_child(UIKit.label("Nobody here to remind.", 28, UIKit.MUTED))
		return
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[clampi(focus, 0, _buttons.size() - 1)])

func _on_cancel() -> void:
	match _mode:
		"forget":
			Audio.sfx("cancel")
			if _teaching:
				close(null)
				return
			_show_moves()
		"moves":
			Audio.sfx("cancel")
			_show_party()
		_:
			close(null)
