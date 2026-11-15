class_name LeagueTab
extends RefCounted
## The Almanac's Walkers' League page: the thirty road champions (core/route_champions.gd) as a list, who you have beaten
## and when, and beside it what is on offer at the focused road: the reason the champion is out there, whether a
## rematch is open this week, how many you have won. The title you hold and the next one sit above the list.

const PANEL := Color("1d2230f0")
const ROW_H := 40
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var _menu: MenuBase
var _detail: VBoxContainer
var _buttons: Array = []
var _rows: Array = []

func _init(menu: MenuBase) -> void:
	_menu = menu

## "2026-11-09" as "9 Nov 2026".
static func date_text(key: String) -> String:
	var p := key.split("-")
	if p.size() != 3 or not p[1].is_valid_int() or int(p[1]) < 1 or int(p[1]) > 12:
		return ""
	return "%d %s %s" % [int(p[2]), MONTHS[int(p[1]) - 1], p[0]]

## The two lines over the list: the title held, and the next one.
static func standing_lines(d: GameStateData) -> Array:
	var n := RouteChampions.beaten_count(d)
	var t := RouteChampions.current_title(d)
	var nx := RouteChampions.next_title(d)
	var lines := ["%d of %d champions beaten. %s" % [n, RouteChampions.total(), ("Title: %s." % str(t.name)) if not t.is_empty() else "No title yet."]]
	if not nx.is_empty():
		lines.append("Next: %s at %d, with this for the shelf at home: %s." % [str(nx.name), int(nx.at), str(nx.keepsake.name)])
	else:
		lines.append("Every road has a champion who has lost to you. Mum has run out of shelf.")
	return lines

## What is said of one road: [[text, colour], ...].
static func detail_lines(r: Dictionary) -> Array:
	if not r.beaten:
		return [["Somebody walks this road who is better than the rest of them. Beat the strongest trainer here to meet your champion.", UIKit.MUTED]]
	var lines := []
	lines.append([str(r.title), UIKit.GOLD])
	lines.append([str(r.reason), UIKit.CREAM])
	var when := date_text(str(r.date))
	lines.append(["First beaten: %s" % (when if when != "" else "before the League kept dates"), UIKit.MUTED])
	lines.append(["Rematches won: %d" % int(r.wins), UIKit.MUTED])
	lines.append(["Rematch: ready, once a week, at your level." if r.open else "Rematch won this week. Back on Monday.", UIKit.GOLD if r.open else UIKit.MUTED])
	return lines

func build(parent: Control) -> void:
	_rows = RouteChampions.rows(Game.data)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 22)
	parent.add_child(row)
	var lp := UIKit.panel(Color("14182299"), 10)
	lp.custom_minimum_size = Vector2(520, 0)
	lp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(lp)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	lp.add_child(left)
	for l in standing_lines(Game.data):
		var t := UIKit.label(str(l), 19, UIKit.GOLD)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(t)
	var sl := UIKit.scroll_list(4)
	left.add_child(sl[0])
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
	for r in _rows:
		var b: Button = _menu.make_button(_row_text(r), func(): pass)
		b.custom_minimum_size = Vector2(0, ROW_H)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_theme_font_size_override("font_size", 20)
		if not r.beaten:
			b.add_theme_color_override("font_color", UIKit.MUTED)
		b.focus_entered.connect(_show.bind(r))
		sl[1].add_child(b)
		_buttons.append(b)
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])
	UIKit.key_scroll(dsc)
	_show(_rows[0])

func _row_text(r: Dictionary) -> String:
	return ("* " if r.beaten else "   ") + str(r.route)  # a star for a champion beaten; the name is beside it

func _show(r: Dictionary) -> void:
	UIKit.clear(_detail)
	_detail.add_child(UIKit.label(str(r.name) if r.beaten else str(r.route), 28, UIKit.GOLD if r.beaten else UIKit.MUTED))
	if r.beaten:
		_detail.add_child(UIKit.label(str(r.route), 20, UIKit.MUTED))
	for l in detail_lines(r):
		var t := UIKit.label(str(l[0]), 21, l[1])
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(t)
