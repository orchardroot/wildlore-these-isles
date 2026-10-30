class_name PapersTab
extends RefCounted
## The Almanac's Papers page: every letter, diary page and list you have read off a table, newest region last, with
## the status of any treasure trail (clue open, dug up). Focus a paper to read it again on the right. See Letters.

const PANEL := Color("1d2230f0")
const ROW_H := 44

var _menu: MenuBase
var _detail: VBoxContainer
var _buttons: Array = []
var _papers: Array = []

func _init(menu: MenuBase) -> void:
	_menu = menu

func build(parent: Control) -> void:
	_papers = Letters.read_papers(Game.data)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 520)
	row.add_theme_constant_override("separation", 22)
	parent.add_child(row)
	var lp := UIKit.panel(Color("14182299"), 10)
	lp.custom_minimum_size = Vector2(520, 0)
	lp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lp.add_child(sc)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	sc.add_child(col)
	var dp := UIKit.panel(PANEL, 18)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(dp)
	var dsc := ScrollContainer.new()
	dsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dp.add_child(dsc)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 10)
	dsc.add_child(_detail)
	col.add_child(UIKit.label(Letters.blurb(Game.data), 20, UIKit.GOLD))
	for p in _papers:
		var b: Button = _menu.make_button("%s    %s" % [str(p.title), Letters.status(Game.data, p)], func(): pass)
		b.custom_minimum_size = Vector2(0, ROW_H)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 20)
		b.focus_entered.connect(_show.bind(p))
		col.add_child(b)
		_buttons.append(b)
	if _buttons.is_empty():
		return
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])
	_show(_papers[0])

func _show(p: Dictionary) -> void:
	UIKit.clear(_detail)
	_detail.add_child(UIKit.label(str(p.title), 28, UIKit.GOLD))
	for l in p.get("lines", []):
		var t := UIKit.label(str(l), 21, UIKit.CREAM)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(t)
	if Letters.has_trail(p):
		var dug := Letters.is_dug(Game.data, str(p.id))
		var where := ZoneData.load_id(str(p.trail.get("zone", "")))
		var wn := where.name if where != null else "somewhere"
		var c := UIKit.label(("Dug up, near %s." % wn) if dug else ("Clue: %s  (near %s)" % [str(p.trail.clue), wn]), 19, UIKit.MUTED if dug else UIKit.GOLD)
		c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(UIKit.spacer(6))
		_detail.add_child(c)
