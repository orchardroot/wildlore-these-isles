class_name AtlasScreen
extends MenuBase
## The Atlas page of the Almanac: a region on the left, and on the right how much of it you have seen, six bars and a
## stamp at half and at all (see Atlas). Opening it pays any stamp an older save has already earned, once, and says so.

const ROW_H := 30

var _scroll: ScrollContainer
var _col: VBoxContainer
var _last := 0
var _detail: VBoxContainer
var _buttons: Array = []
var _regions: Array = []

func _build() -> void:
	var idx := ZoneIndex.get_index()
	var paid := Atlas.collect(Game.data, idx)
	_regions = Atlas.regions(Game.data, idx)
	var t := Discovery.tally(Game.data, idx)
	set_title("Atlas")
	header_right.text = "%d of %d places found" % [t.x, t.y]
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
	for r in _regions:
		var mark: String = {"half": "  ★", "full": "  ★★"}.get(str(r.stamp), "")
		var b := make_button("%s   %d%%%s" % [r.name, int(round(float(r.frac) * 100.0)), mark], func(): pass)
		b.custom_minimum_size = Vector2(400, ROW_H)
		b.add_theme_font_size_override("font_size", 19)
		UIKit.compact(b, 1)
		b.focus_entered.connect(_show.bind(str(r.region)))
		b.focus_entered.connect(func(): _last = _buttons.find(b))
		list.add_child(b)
		_buttons.append(b)
	var rp := UIKit.panel(Color("1d2230f0"), 18)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rp)
	_scroll = ScrollContainer.new()  # Large text outgrows the panel: Right moves in and up and down scroll it
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.set_meta("pages", true)
	rp.add_child(_scroll)
	_col = VBoxContainer.new()
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col.add_theme_constant_override("separation", 8)
	_scroll.add_child(_col)
	_detail = VBoxContainer.new()  # the region on show; the note about stamps just paid sits under it, kept when you move
	_detail.add_theme_constant_override("separation", 8)
	_col.add_child(_detail)
	if _regions.is_empty():
		_detail.add_child(UIKit.label("Nowhere yet", 30, UIKit.MUTED))
		var e := UIKit.label("Step out on to a road and the Atlas starts to fill in.", 22, UIKit.MUTED)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.custom_minimum_size = Vector2(560, 0)
		_detail.add_child(e)
		return
	UIKit.wrap_focus(_buttons)
	UIKit.key_scroll(_scroll, _buttons[0])
	_scroll.focus_entered.connect(func(): _scroll.set_meta("back_to", weakref(_buttons[_last])))
	for b in _buttons:
		b.focus_neighbor_right = b.get_path_to(_scroll)
	UIKit.focus_later(_buttons[0])
	_show(str(_regions[0].region))
	if not paid.is_empty():
		_announce(paid)

func _region(id: String) -> Dictionary:
	for r in _regions:
		if str(r.region) == id:
			return r
	return {}

func _show(id: String) -> void:
	UIKit.clear(_detail)
	var r := _region(id)
	if r.is_empty():
		return
	_detail.add_child(UIKit.row_label(str(r.name), 32, UIKit.GOLD))
	var stamp := str(r.stamp)
	var line := "Stamps: none yet. A stamp comes at half, and another at all of it."
	if stamp == "half":
		line = "Half-stamped. The full stamp comes with all of it."
	elif stamp == "full":
		line = "Fully stamped. Nothing left to find here, on paper."
	var sl := UIKit.label(line, 20, UIKit.GOLD if stamp != "" else UIKit.MUTED)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.custom_minimum_size = Vector2(560, 0)
	_detail.add_child(sl)
	for m in r.rows:
		_detail.add_child(_measure(m))

## One measure: its name and count, and a bar under it.
func _measure(m: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var h := HBoxContainer.new()
	var name := UIKit.row_label(str(m.label), 22, UIKit.CREAM)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name)
	var done: bool = int(m.got) >= int(m.total)
	h.add_child(UIKit.label("%d of %d" % [m.got, m.total], 22, UIKit.GOLD if done else UIKit.MUTED))
	v.add_child(h)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = maxi(1, int(m.total))
	bar.value = int(m.got)
	bar.custom_minimum_size = Vector2(0, 10)
	bar.add_theme_stylebox_override("background", UIKit.box(Color("0d0f15"), Color("4a4f5e"), 1, 3, 0))
	bar.add_theme_stylebox_override("fill", UIKit.box(Color("d8b45a") if done else Color("6fa8dc"), Color(0, 0, 0, 0), 0, 3, 0))
	v.add_child(bar)
	return v

## A line along the bottom of the detail about the stamps just paid.
func _announce(paid: Array) -> void:
	var bits := []
	for p in paid.slice(0, 3):
		var names := []
		for it in p.items:
			names.append(str(Game.items.get_item(str(it.id)).get("name", it.id)))
		bits.append("%s, %s stamp: %s" % [p.name, "half" if p.tier == "half" else "full", ", ".join(names)])
	var more := "" if paid.size() <= 3 else " (and %d more)" % (paid.size() - 3)
	var l := UIKit.label("Stamped, and paid in the bag: " + "; ".join(bits) + more, 19, UIKit.GOLD)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)
	_col.add_child(UIKit.spacer(6))
	_col.add_child(l)
	Audio.sfx("item")
