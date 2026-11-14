class_name TypeChartScreen
extends MenuBase
## The type chart: sixteen types down the left; pick one for what it hits hard, what shrugs it off, and what hits it.
## Opened from the Almanac and the pause menu, and from a battle with Menu on the move picker; then
## `setup("Name=brook+kin;Name=hearth")` puts a card up top for the creatures in front of you (see `scope`).
## Every row has a shape as well as a colour (EffectMark), and a type's chip carries its glyph.

const ROW_H := 28

var chart: TypeChart
var _detail: VBoxContainer
var _buttons: Array = []
var _ids: Array = []
var _scroll: ScrollContainer
var _scope: Array = []  # [{"name", "types"}], the creatures in front of you in a battle

func _build() -> void:
	chart = Game.chart if Game.chart != null else TypeChart.load_default()
	set_title("Type chart")
	header_right.text = "Which type beats which"
	set_hints([["updown", "Choose"], ["leftright", "Scroll"], ["cancel", "Back"]])
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 18)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 10)
	lp.custom_minimum_size = Vector2(300, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 1)
	sc.add_child(list)
	for t in chart.types:
		var b := make_button("      " + str(t).capitalize(), func(): pass)
		b.custom_minimum_size = Vector2(270, ROW_H)
		b.add_theme_font_size_override("font_size", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIKit.compact(b, 1)
		var g := TypeGlyph.make(str(t), TypeColours.colour(str(t)), 18)
		g.position = Vector2(10, 6)
		b.add_child(g)
		b.focus_entered.connect(_show.bind(str(t)))
		list.add_child(b)
		_buttons.append(b)
		_ids.append(str(t))
	var rp := UIKit.panel(Color("1d2230f0"), 16)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rp)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.add_child(rs)
	_scroll = rs
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 8)
	rs.add_child(_detail)
	UIKit.wrap_focus(_buttons)
	_start()

## `arg`: "Name=brook+kin;Name=hearth", the creatures in front of you (a battle), or "" for the plain chart.
func setup(arg: String) -> void:
	_scope = parse_scope(arg)
	if content != null:
		_start()

static func parse_scope(arg: String) -> Array:
	var out := []
	for part in arg.split(";", false):
		var kv := part.split("=", true, 1)
		if kv.size() == 2 and kv[1] != "":
			out.append({"name": kv[0], "types": Array(kv[1].split("+", false))})
	return out

## The scope as the menu argument: "typechart:" + this.
static func scope_arg(foes: Array, mine: Array) -> String:
	var bits := []
	for c in foes + mine:
		bits.append("%s=%s" % [str(c.name).replace(";", " ").replace("=", " "), "+".join(c.types)])
	return ";".join(bits)

func _start() -> void:
	if _buttons.is_empty():
		return
	var first := 0
	if not _scope.is_empty() and not _scope[0].types.is_empty():
		first = maxi(0, _ids.find(str(_scope[0].types[0])))  # a battle opens on the foe's first type
	UIKit.focus_later(_buttons[first])
	_show(_ids[first])

func _input(event: InputEvent) -> void:
	if _locked or _scroll == null or not UIKit.reads_on(_scroll) and _scroll.scroll_vertical == 0:
		return
	if event.is_action_pressed("move_right", true):
		_scroll.scroll_vertical += int(_scroll.size.y * 0.7)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left", true):
		_scroll.scroll_vertical -= int(_scroll.size.y * 0.7)
		get_viewport().set_input_as_handled()

func _show(id: String) -> void:
	UIKit.clear(_detail)
	_scroll.scroll_vertical = 0
	if not _scope.is_empty():  # a battle: the creatures in front of you first, the chosen type below
		_detail.add_child(UIKit.label("In this fight", 22, UIKit.GOLD))
		for c in _scope:
			_creature(c)
		_detail.add_child(UIKit.spacer(6))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.add_child(UIKit.type_chip(id, 26))
	head.add_child(UIKit.label("as an attack, and as a defender", 20, UIKit.MUTED))
	_detail.add_child(head)
	_detail.add_child(UIKit.label("A %s move" % id.capitalize(), 22, UIKit.GOLD))
	_group("up1", "Hits hard (x2)", chart.strong_against(id))
	_group("dn1", "Hits weakly (x1/2)", chart.weak_against(id))
	_group("none", "No effect", chart.no_effect_on(id))
	_detail.add_child(UIKit.label("A %s creature" % id.capitalize(), 22, UIKit.GOLD))
	_group("dn1", "Weak to (x2)", chart.weak_to([id]).map(func(w): return w.type))
	_group("up1", "Resists (x1/2)", chart.resists([id]).map(func(w): return w.type))
	_group("up2", "Immune to", chart.immune([id]).map(func(w): return w.type))

## One labelled row: a shape, the words, and a chip for each type ("Nothing" when the list is empty).
func _group(kind: String, words: String, ids: Array) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var slot := Control.new()  # a fixed slot, so one and two arrows line the words up alike
	slot.custom_minimum_size = Vector2(40, 18)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var mk := EffectMark.make(kind, 18)
	slot.add_child(mk)
	h.add_child(slot)
	var l := UIKit.label(words, 20, UIKit.CREAM)
	l.custom_minimum_size = Vector2(230, 0)
	h.add_child(l)
	if ids.is_empty():
		h.add_child(UIKit.label("nothing", 20, UIKit.MUTED))
	else:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 4)
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for t in ids:
			flow.add_child(UIKit.type_chip(str(t), 17))
		h.add_child(flow)
	_detail.add_child(h)

## A creature in the fight: its types, then what it is weak to, resists and is immune to.
func _creature(c: Dictionary) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(UIKit.label(str(c.name), 21, UIKit.CREAM))
	for t in c.types:
		h.add_child(UIKit.type_chip(str(t), 17))
	_detail.add_child(h)
	_group("dn1", "Weak to", chart.weak_to(c.types).map(func(w): return w.type))
	_group("up1", "Resists", chart.resists(c.types).map(func(w): return w.type))
	if not chart.immune(c.types).is_empty():
		_group("up2", "Immune to", chart.immune(c.types).map(func(w): return w.type))
