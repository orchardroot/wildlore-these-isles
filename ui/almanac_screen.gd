extends MenuBase
## The Almanac: one list of every page that has sprouted (Quest log, Fieldbook, Gazetteer, Casebook, Stud Book, Rumours,
## Trades, Standing, Tallies, Guilds, Deeds, the Building Society), each with a one-line summary, always in the same
## order. Choosing one opens that page; Back returns here on the same row. Guilds, Deeds and the Society statement
## have no screen of their own, so they open as a read-only ledger inside this one. See Almanac.
## setup("ledger:guilds") (and so on) opens straight on a ledger, for screenshots.

const ROW_H := 38
static var _last := "journal"   # reopens on the page you left it on (this session only)

var _list: VBoxContainer
var _buttons: Array = []
var _ids: Array = []
var _ledger := ""

func _build() -> void:
	set_title("Almanac")
	header_right.text = Game.data.player_name
	_show_hub()

func setup(arg: String) -> void:
	if arg.begins_with("ledger:") and content != null:
		_show_ledger(arg.substr(7))

func _clear_content() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()

func _show_hub() -> void:
	_ledger = ""
	_clear_content()
	set_title("Almanac")
	set_hints([["updown", "Choose"], ["confirm", "Open"], ["cancel", "Back"]])
	var card := UIKit.panel(Color("1d2230f0"), 12)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(card)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 3)
	card.add_child(_list)
	_buttons.clear()
	_ids.clear()
	for p in Almanac.pages(Game.data):
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 18)
		var b := make_button(str(p.name), _open.bind(p))
		b.custom_minimum_size = Vector2(330, ROW_H)
		b.add_theme_font_size_override("font_size", 26)
		UIKit.compact(b, 2)
		row.add_child(b)
		var bl := UIKit.fit_label(str(p.blurb), 760, 24, 17, UIKit.MUTED)
		bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(bl)
		_list.add_child(row)
		_buttons.append(b)
		_ids.append(str(p.id))
	UIKit.wrap_focus(_buttons)
	var at := _ids.find(_last)
	UIKit.focus_later(_buttons[maxi(at, 0)])

func _open(p: Dictionary) -> void:
	_last = str(p.id)
	var m := str(p.menu)
	if m.begins_with("ledger:"):
		_show_ledger(m.substr(7))
		return
	await open_child(m)
	_show_hub()

func _show_ledger(kind: String) -> void:
	_ledger = kind
	_clear_content()
	set_title(str(Almanac.NAMES.get(kind, "Almanac")))
	set_hints([["cancel", "Back"]])
	var card := UIKit.panel(Color("1d2230f0"), 16)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(card)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	if kind == "papers":  # a list with the paper beside it (ui/papers_tab.gd)
		PapersTab.new(self).build(col)
		return
	for r in Almanac.ledger(Game.data, kind):
		var h := HBoxContainer.new()
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_theme_constant_override("separation", 24)
		if str(r[0]) != "":
			var k := UIKit.fit_label(str(r[0]), 380, 26, 18, UIKit.MUTED)
			k.custom_minimum_size.x = 380
			h.add_child(k)
		var v := UIKit.fit_label(str(r[1]), 700, 26, 17, UIKit.GOLD)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(v)
		col.add_child(h)

func _on_cancel() -> void:
	if _ledger != "":
		Audio.sfx("cancel")
		_show_hub()
		return
	close(null)
