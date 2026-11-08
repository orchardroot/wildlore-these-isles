class_name GazetteerTab
extends RefCounted
## The Journal's Gazetteer tab: how many heritage plaques you've read and what the next milestone brings, then every
## place with plaques, nation by nation, with its count. Confirm opens a place: its plaques, the ones you've read
## shown as they look on their lecterns, to read again. Cancel goes back out. See Gazetteer.

const PANEL := Color("1d2230f0")
const ENAMEL := Color("23488f")
const BRONZE := Color("a9864f")
const ROW_H := 54

var _menu: MenuBase
var _list_col: VBoxContainer
var _detail: VBoxContainer
var _buttons: Array = []
var _groups: Array = []
var _rows: Array = []         # places mode: [town dict]; plaques mode: [plaque dict]
var _town: Dictionary = {}    # the place opened, {} for the list of places
var _place_at := 0            # the place to come back to
var _isles := false           # the These Isles page is open (see TheseIsles)
var _themes: Array = []
var _dsc: ScrollContainer     # the detail panel's scroller (a long topic reads on with Confirm)

func _init(menu: MenuBase) -> void:
	_menu = menu

func build(parent: Control) -> void:
	_groups = Gazetteer.grouped(Game.data)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 12)
	parent.add_child(col)
	col.add_child(_summary())
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 22)
	col.add_child(row)
	var lp := UIKit.panel(PANEL, 12)
	lp.custom_minimum_size = Vector2(500, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_col.add_theme_constant_override("separation", 4)
	sc.add_child(_list_col)
	var dp := UIKit.panel(PANEL, 18)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(dp)
	var dsc := ScrollContainer.new()
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dp.add_child(dsc)
	_dsc = dsc
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 10)
	dsc.add_child(_detail)
	UIKit.keep_fitted(_detail)  # a long plaque steps its words down to fit the panel
	_places()

## The strip along the top: the total, a bar, your title and the next milestone.
func _summary() -> PanelContainer:
	var d: GameStateData = Game.data
	var all := Gazetteer.all()
	var n := Gazetteer.count(d)
	var p := UIKit.panel(PANEL, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)
	var big := UIKit.label(str(n), 40, UIKit.GOLD)
	big.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(big)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 6)
	h.add_child(mid)
	var top := HBoxContainer.new()
	top.add_child(UIKit.label("of %d heritage plaques read" % all.size(), 22, UIKit.CREAM))
	top.add_child(UIKit.fill())
	var t := Gazetteer.title(d)
	if t != "":
		top.add_child(UIKit.chip(t, UIKit.GOLD.darkened(0.2), UIKit.SLATE, 16))
	mid.add_child(top)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.max_value = maxi(1, all.size())
	bar.value = n
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIKit.GOLD
	fill.set_corner_radius_all(4)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("2c3446")
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	mid.add_child(bar)
	var nm := Gazetteer.next_milestone(d)
	var next := "Every plaque read. Somebody give this person a blue plaque of their own."
	if not nm.is_empty():
		var gift := Gazetteer.reward_text(nm, Game.items)
		next = "Next: %d read makes you a %s%s." % [int(nm.target), str(nm.title), (", with " + gift) if gift != "" else ""]
		if str(nm.flag) == "gazetteer_50":
			next = next.trim_suffix(".") + ", and Kit will want to hear about it."
	var nl := UIKit.fit_label(next, 900, 19, 15, UIKit.MUTED)
	mid.add_child(nl)
	# Poets' Corner (4.5): the plaques on writers, musicians and artists, counted again on their own
	var pc := PoetsCorner.count(d)
	if pc > 0:
		var pt := PoetsCorner.title(d)
		mid.add_child(UIKit.fit_label("Poets' Corner: %d of %d plaques on the arts read%s." % [pc, PoetsCorner.total(), (", " + pt) if pt != "" else ""], 900, 19, 15, UIKit.MUTED))
	return p

# --- the list of places -------------------------------------------------------------

func _places() -> void:
	_town = {}
	_dsc.remove_meta("pages")
	UIKit.clear(_list_col)
	_buttons.clear()
	_rows.clear()
	_isles = false
	if _groups.is_empty():
		_list_col.add_child(UIKit.label("No plaques anywhere. Somebody's nicked them.", 22, UIKit.MUTED))
		return
	_rows.append({"isles": true})
	_list_col.add_child(_isles_button(0))
	_rows.append(ISLES_ROW)  # the How these isles work page heads the list (IslesWorkView)
	_list_col.add_child(_place_button(_rows.size() - 1))
	for g in _groups:
		var head := HBoxContainer.new()
		var hl := UIKit.label(str(g.name), 19, UIKit.MUTED)
		hl.uppercase = true
		head.add_child(hl)
		head.add_child(UIKit.fill())
		head.add_child(UIKit.label("%d / %d" % [int(g.read), int(g.total)], 19, UIKit.MUTED))
		if not _rows.is_empty():
			_list_col.add_child(UIKit.spacer(6))
		_list_col.add_child(head)
		for t in g.towns:
			_rows.append(t)
			_list_col.add_child(_place_button(_rows.size() - 1))
	UIKit.wrap_focus(_buttons)
	_place_at = clampi(_place_at, 0, _buttons.size() - 1)
	UIKit.focus_later(_buttons[_place_at])
	_show_row(_rows[_place_at])
	_menu.set_hints([["leftright", "Tabs"], ["updown", "Places"], ["confirm", "Open"], ["cancel", "Back"]])

func _row_button(i: int, on_focus: Callable, on_press: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.focus_neighbor_left = NodePath(".")
	b.focus_neighbor_right = NodePath(".")
	b.focus_entered.connect(func():
		Audio.sfx("cursor")
		on_focus.call(i))
	b.pressed.connect(func(): on_press.call(i))
	_buttons.append(b)
	return b

func _inner(b: Button) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	return h

func _place_button(i: int) -> Button:
	var t: Dictionary = _rows[i]
	var b := _row_button(i, func(k: int):
		_place_at = k
		_show_row(_rows[k]), func(k: int): _open(k))
	var h := _inner(b)
	if t.has("isles_work"):
		_isles_row(h)
		return b
	var full := int(t.read) == int(t.total)
	var nm := UIKit.label(str(t.name), 24, UIKit.GOLD if full else (UIKit.CREAM if int(t.read) > 0 else UIKit.MUTED))
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.clip_text = true
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nm)
	h.add_child(_pips(int(t.read), int(t.total)))
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

## A row of little plaques, filled for the ones read (a number past eight).
func _pips(read: int, total: int) -> Control:
	if total > 8:
		var l := UIKit.label("%d / %d" % [read, total], 20, UIKit.GOLD if read == total else UIKit.MUTED)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return l
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for k in total:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(12, 16)
		r.color = (UIKit.GOLD if read == total else ENAMEL.lightened(0.3)) if k < read else Color("454d63")
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(r)
	return h

func _show_row(t: Dictionary) -> void:
	if t.has("isles"):
		_show_isles_summary()
	else:
		_show_place(t)

func _show_place(t: Dictionary) -> void:
	UIKit.clear(_detail)
	if t.has("isles_work"):
		IslesWorkView.summary(_detail, Game.data)
		return
	var name := UIKit.label(str(t.name), 34)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(name)
	var nation := str(t.plaques[0].nation) if not t.plaques.is_empty() else ""
	_detail.add_child(UIKit.label("%s    %d of %d read" % [Standing.name_of(nation), int(t.read), int(t.total)], 20, UIKit.MUTED))
	_detail.add_child(UIKit.spacer(2))
	for p in t.plaques:
		var read := Gazetteer.is_read(Game.data, str(p.id))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 16)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.color = ENAMEL.lightened(0.3) if read else Color("454d63")
		h.add_child(dot)
		h.add_child(UIKit.label(str(p.title) if read else "Not yet found", 22, UIKit.CREAM if read else UIKit.MUTED))
		_detail.add_child(h)
	var tip := UIKit.label("Plaques stand beside the landmarks they're about, on lecterns or up on the wall. Open a place to read the ones you've found again." if int(t.read) > 0 \
		else "None read here yet. Plaques stand beside the landmarks they're about, on lecterns or up on the wall.", 19, UIKit.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(UIKit.spacer(4))
	_detail.add_child(tip)

# --- one place's plaques -------------------------------------------------------------

func _open(i: int) -> void:
	_place_at = i
	if _rows[i].has("isles"):
		_open_isles()
		return
	if _rows[i].has("isles_work"):
		_open_isles_work()
		return
	_town = _rows[i]
	UIKit.clear(_list_col)
	_buttons.clear()
	_rows = _town.plaques.duplicate()
	var head := UIKit.label("< " + str(_town.name), 22, UIKit.GOLD)
	_list_col.add_child(head)
	for k in _rows.size():
		var p: Dictionary = _rows[k]
		var read := Gazetteer.is_read(Game.data, str(p.id))
		var b := _row_button(k, func(j: int): _show_plaque(_rows[j]), func(_j: int): pass)
		var h := _inner(b)
		var mk := ColorRect.new()
		mk.custom_minimum_size = Vector2(10, 30)
		mk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mk.color = ENAMEL.lightened(0.3) if read else Color("454d63")
		mk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(mk)
		var l := UIKit.label(str(p.title) if read else "Not yet found", 24, UIKit.CREAM if read else UIKit.MUTED)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(l)
		_list_col.add_child(b)
	Audio.sfx("confirm")
	UIKit.wrap_focus(_buttons)
	var first := 0
	for k in _rows.size():
		if Gazetteer.is_read(Game.data, str(_rows[k].id)):
			first = k
			break
	UIKit.focus_later(_buttons[first])
	_show_plaque(_rows[first])
	_menu.set_hints([["updown", "Plaques"], ["cancel", "All places"]])

## A plaque read before, as it looks on its board: enamel, a bronze edge, cream letters. One not found yet says where.
func _show_plaque(p: Dictionary) -> void:
	UIKit.clear(_detail)
	if not Gazetteer.is_read(Game.data, str(p.id)):
		_detail.add_child(UIKit.label("Not yet found", 32, UIKit.MUTED))
		var l := UIKit.label("There's a plaque you haven't read somewhere in %s. Look beside its landmarks, and up on the walls." % str(p.town_name), 22)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(l)
		return
	var board := PanelContainer.new()
	var sb := UIKit.box(ENAMEL, BRONZE, 4, 10, 20)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	board.add_theme_stylebox_override("panel", sb)
	_detail.add_child(board)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	board.add_child(col)
	var title := UIKit.label(str(p.title), 30, Color("f2ead2"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(Color("f2ead2"), 0.5)
	col.add_child(rule)
	var t := UIKit.label(str(p.text).trim_prefix("BLUE PLAQUE: "), 23, Color("f2ead2"))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(t)
	_detail.add_child(UIKit.label(_where(p), 19, UIKit.MUTED))

func _where(p: Dictionary) -> String:
	var zi: Dictionary = ZoneIndex.get_index().zones
	var here := str(zi.get(str(p.zone), {}).get("name", p.zone))
	return here if str(p.zone) == str(p.town) else "%s, %s" % [here, str(p.town_name)]

## Opens one place straight away (the Journal's setup("gazetteer:<town>"), for screenshots). "isles" opens These
## Isles, and "isles:<theme>" one of its themes.
func open_town(town: String) -> void:
	if town == "isles" or town.begins_with("isles:"):
		_place_at = 0
		_open_isles()
		var th := town.substr(6)
		for k in _themes.size():
			if str(_themes[k].id) == th:
				UIKit.focus_later(_buttons[k])
				_show_theme(_themes[k])
		return
	if town.begins_with("isles_work"):  # "isles_work[:<topic id>]"
		_open_isles_work(town.get_slice(":", 1))
		return
	for i in _rows.size():
		if str(_rows[i].get("town", "")) == town:
			_open(i)
			return

## Cancel inside a place goes back to the list of places (and the event stops there). Left and right inside a place
## are left alone, so they still switch tabs.
func wants_back(event: InputEvent) -> bool:
	if (_town.is_empty() and not _isles) or not (event.is_action_pressed("cancel") or event.is_action_pressed("menu")):
		return false
	Audio.sfx("cancel")
	_rows.clear()
	_places()
	return true

# --- These Isles: the peoples of these isles ---------------------------------------------------------------------

const ISLES_GREEN := Color("2f6b4f")

## The first row of the places list: These Isles, with how much of it you've found.
func _isles_button(i: int) -> Button:
	var tot := TheseIsles.totals(Game.data)
	var b := _row_button(i, func(k: int):
		_place_at = k
		_show_row(_rows[k]), func(k: int): _open(k))
	var h := _inner(b)
	var mk := ColorRect.new()
	mk.custom_minimum_size = Vector2(10, 30)
	mk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mk.color = ISLES_GREEN.lightened(0.3)
	h.add_child(mk)
	var nm := UIKit.label("These Isles", 24, UIKit.GOLD)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nm)
	h.add_child(UIKit.label("%d / %d" % [int(tot.found), int(tot.total)], 20, UIKit.MUTED))
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _show_isles_summary() -> void:
	UIKit.clear(_detail)
	var tot := TheseIsles.totals(Game.data)
	_detail.add_child(UIKit.label("These Isles", 34))
	_detail.add_child(UIKit.label("%d of %d found" % [int(tot.found), int(tot.total)], 20, UIKit.MUTED))
	var l := UIKit.label("Celts, Romans, Saxons and Vikings; Huguenots and Jewish refugees; the Irish who left and the Windrush generation who came; and many more. Plaques to read, people to meet and the odd errand, all round the isles.", 21)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(l)
	var tip := UIKit.label("Open it to see each people's story and what you've still to find.", 19, UIKit.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(tip)

## The list of themes, each with its count; the detail shows the theme's story and what's in it.
func _open_isles() -> void:
	_isles = true
	_town = {}
	_themes = TheseIsles.tally(Game.data)
	UIKit.clear(_list_col)
	_buttons.clear()
	_list_col.add_child(UIKit.label("< These Isles", 22, UIKit.GOLD))
	for k in _themes.size():
		var t: Dictionary = _themes[k]
		var b := _row_button(k, func(j: int): _show_theme(_themes[j]), func(_j: int): pass)
		var h := _inner(b)
		var full := int(t.found) == int(t.total)
		var nm := UIKit.label(str(t.name), 22, UIKit.GOLD if full else (UIKit.CREAM if int(t.found) > 0 else UIKit.MUTED))
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.clip_text = true
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nm)
		h.add_child(_pips(int(t.found), int(t.total)))
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list_col.add_child(b)
	Audio.sfx("confirm")
	UIKit.wrap_focus(_buttons)
	if not _buttons.is_empty():
		UIKit.focus_later(_buttons[0])
		_show_theme(_themes[0])
	_menu.set_hints([["updown", "Peoples"], ["cancel", "All places"]])

const KIND_WORD := {"plaque": "Plaque", "person": "Meet", "quest": "Quest"}

func _show_theme(t: Dictionary) -> void:
	UIKit.clear(_detail)
	var name := UIKit.label(str(t.name), 32)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(name)
	var about := UIKit.label(str(t.about), 20)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(about)
	_detail.add_child(UIKit.label("%d of %d found" % [int(t.found), int(t.total)], 19, UIKit.MUTED))
	for it in t.items:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 16)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.color = ISLES_GREEN.lightened(0.35) if it.found else Color("454d63")
		h.add_child(dot)
		h.add_child(UIKit.label(str(KIND_WORD.get(str(it.kind), "")), 17, UIKit.MUTED))
		var what := str(it.title) if it.found or str(it.kind) != "plaque" else "A plaque not yet found"
		if str(it.kind) == "person" and not it.found:
			what = "Someone to meet"
		var l := UIKit.label("%s, %s" % [what, str(it.where)], 20, UIKit.CREAM if it.found else UIKit.MUTED)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		_detail.add_child(h)
# --- How these isles work (IslesWork, IslesWorkView) ----------------------------------

const ISLES_ROW := {"isles_work": true}

func _isles_row(h: HBoxContainer) -> void:
	var nm := UIKit.label(IslesWorkView.NAME, 24, UIKit.GOLD)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(nm)
	var n := UIKit.label("%d / %d" % [IslesWork.count(Game.data), IslesWork.all().size()], 20, UIKit.MUTED)
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(n)

## The page opened: its topics down the list, the one focused on the right.
func _open_isles_work(focus_id := "") -> void:
	_place_at = 0
	_town = {"isles_work": true, "name": IslesWorkView.NAME}
	_dsc.set_meta("pages", true)  # Confirm reads on down a long topic (TextFitAudit counts that as reachable)
	UIKit.clear(_list_col)
	_buttons.clear()
	_rows = IslesWork.all().duplicate()
	_list_col.add_child(UIKit.label("< " + IslesWorkView.NAME, 22, UIKit.GOLD))
	var first := -1
	for k in _rows.size():
		var t: Dictionary = _rows[k]
		var known := IslesWork.is_learnt(Game.data, t)
		if known and first < 0:
			first = k
		var b := _row_button(k, func(j: int): IslesWorkView.topic(_cleared(), Game.data, _rows[j]), func(_j: int): _read_on())
		var h := _inner(b)
		var mk := ColorRect.new()
		mk.custom_minimum_size = Vector2(10, 30)
		mk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mk.color = IslesWorkView.EDGE if known else Color("454d63")
		mk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(mk)
		var l := UIKit.label(str(t.title), 21, UIKit.CREAM if known else UIKit.MUTED)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.fit_width(l)  # a long title steps down before it trims
		h.add_child(l)
		_list_col.add_child(b)
	Audio.sfx("confirm")
	UIKit.wrap_focus(_buttons)
	for k in _rows.size():
		if str(_rows[k].id) == focus_id:
			first = k
	first = maxi(first, 0)
	UIKit.focus_later(_buttons[first])
	IslesWorkView.topic(_cleared(), Game.data, _rows[first])
	_menu.set_hints([["updown", "Topics"], ["confirm", "Read on"], ["cancel", "All places"]])

func _cleared() -> VBoxContainer:
	UIKit.clear(_detail)
	_dsc.scroll_vertical = 0
	return _detail

## Confirm on a topic: down the card a panel at a time, then back to the top.
func _read_on() -> void:
	var bar := _dsc.get_v_scroll_bar()
	var step := int(_dsc.size.y * 0.8)
	_dsc.scroll_vertical = 0 if _dsc.scroll_vertical + int(_dsc.size.y) >= int(bar.max_value) - 2 else _dsc.scroll_vertical + step
	Audio.sfx("cursor")
