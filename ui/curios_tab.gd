class_name CuriosTab
extends MenuBase
## The Curios page of the Almanac: the knick-knacks found behind the island's doors, out of 60, each with its
## description and what it would fetch, and a pat on the back at 20, 40 and 60. Unfound ones are blank rows.
## See Search.

const ROW_H := 30

var _detail: VBoxContainer
var _buttons: Array = []
var _ids: Array = []

func _build() -> void:
	var n := Search.found_count(Game.data)
	var total := Search.curio_ids().size()
	set_title("Curios")
	header_right.text = "%d of %d found" % [n, total]
	set_hints([["updown", "Choose"], ["cancel", "Back"]])
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 18)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 12)
	lp.custom_minimum_size = Vector2(440, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 1)
	sc.add_child(list)
	for id in Search.curio_ids():
		var known := ZoneData.flag_on(Game.data.flag(Search.FOUND_PREFIX + str(id)))
		var it: Dictionary = Game.items.get_item(str(id))
		var b := make_button(str(it.get("name", id)) if known else "? ? ?", func(): pass)
		b.custom_minimum_size = Vector2(400, ROW_H)
		b.add_theme_font_size_override("font_size", 19)
		if not known:
			b.add_theme_color_override("font_color", UIKit.MUTED)
		UIKit.compact(b, 1)
		b.focus_entered.connect(_show.bind(str(id)))
		list.add_child(b)
		_buttons.append(b)
		_ids.append(str(id))
	var rp := UIKit.panel(Color("1d2230f0"), 18)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rp)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 10)
	rp.add_child(_detail)
	UIKit.wrap_focus(_buttons)
	if not _buttons.is_empty():
		var first := 0
		for k in _ids.size():
			if ZoneData.flag_on(Game.data.flag(Search.FOUND_PREFIX + str(_ids[k]))):
				first = k
				break
		UIKit.focus_later(_buttons[first])
		_show(str(_ids[first]))

func _show(id: String) -> void:
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	var n := Search.found_count(Game.data)
	var known := ZoneData.flag_on(Game.data.flag(Search.FOUND_PREFIX + id))
	var it: Dictionary = Game.items.get_item(id)
	if known:
		_detail.add_child(UIKit.label(str(it.get("name", id)), 30, UIKit.GOLD))
		var d := UIKit.label(str(it.get("desc", "")), 22, UIKit.CREAM)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(560, 0)
		_detail.add_child(d)
		_detail.add_child(UIKit.label("Worth about %s to a dealer." % Wallet.fmt(int(it.get("price", 0)) / 2), 19, UIKit.MUTED))
	else:
		_detail.add_child(UIKit.label("Not found yet", 28, UIKit.MUTED))
		var u := UIKit.label("Somewhere in a dresser, a display case or down the back of a sofa.", 21, UIKit.MUTED)
		u.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		u.custom_minimum_size = Vector2(560, 0)
		_detail.add_child(u)
	_detail.add_child(UIKit.spacer(8))
	var msg := Search.pat_on_back(n)
	if msg == "":
		msg = "Next pat on the back at %d." % (20 if n < 20 else (40 if n < 40 else 60))
	var m := UIKit.label(msg, 19, UIKit.GOLD)
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m.custom_minimum_size = Vector2(560, 0)
	_detail.add_child(m)
