extends MenuBase
## The Journal (pause menu): three tabs. Active and Done are the Quest Log: each quest's title, town, who asked,
## the gist, the steps so far (ticked, the current one picked out, the rest a surprise) and the reward, with
## "Show on map" ringing where the current step is. Gazetteer is the plaques you've read (ui/gazetteer_tab.gd). Contracts is the
## notice-board contracts taken (ui/contracts_tab.gd).
## setup("done") or setup("gazetteer") opens on that tab, setup("gazetteer:<town>") on that place's plaques. See Quests and Gazetteer.

const TABS := ["active", "done", "gazetteer", "contracts"]
const ROW_H := 62
const OK := Color("a8d08d")
const PANEL := Color("1d2230f0")

static var _tab_kept := 0   # reopens on the tab you left it on (this session only)

var _tab := 0
var _tabs_row: HBoxContainer
var _body: Control
var _list_col: VBoxContainer
var _detail: VBoxContainer
var _dsc: ScrollContainer     # the quest's card: Confirm reads on down a long one first
var _buttons: Array = []
var _quests: Array = []
var _last := {}             # tab -> row index
var _gaz: GazetteerTab

func _build() -> void:
	set_title("Journal")
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 12)
	content.add_child(col)
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 10)
	col.add_child(_tabs_row)
	_body = Control.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_body)
	_tab = _tab_kept
	_show_tab()

func setup(arg: String) -> void:
	if arg in TABS:
		_tab = TABS.find(arg)
		_show_tab()
	elif arg.begins_with("gazetteer:"):  # one place's plaques, opened
		_tab = TABS.find("gazetteer")
		_show_tab()
		_gaz.open_town(arg.substr(10))

func _draw_tabs() -> void:
	UIKit.clear(_tabs_row)
	_tabs_row.add_child(UIKit.label("<", 26, UIKit.MUTED))
	var names := ["Active  %d" % Quests.active(Game.data).size(), "Done  %d" % Quests.done(Game.data).size(), "Gazetteer", "Contracts  %d" % Contracts.open_ones(Game.data).size()]
	for i in TABS.size():
		var on := i == _tab
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.box(UIKit.HEATHER if on else Color("1d2230cc"), UIKit.CREAM if on else Color("4a4f5e"), 2, 8, 8))
		p.add_child(UIKit.label(names[i], 24, Color.WHITE if on else UIKit.MUTED))
		_tabs_row.add_child(p)
	_tabs_row.add_child(UIKit.label(">", 26, UIKit.MUTED))
	var gaz_title := Gazetteer.title(Game.data)
	header_right.text = gaz_title if gaz_title != "" else "%d plaques read" % Gazetteer.count(Game.data)

func _show_tab() -> void:
	_tab_kept = _tab
	_draw_tabs()
	UIKit.clear(_body)
	_buttons.clear()
	_gaz = null
	if TABS[_tab] == "gazetteer":
		_gaz = GazetteerTab.new(self)
		_gaz.build(_body)
		return
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 22)
	_body.add_child(row)
	var lp := UIKit.panel(PANEL, 12)
	lp.custom_minimum_size = Vector2(500, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_col.add_theme_constant_override("separation", 6)
	sc.add_child(_list_col)
	var dp := UIKit.panel(PANEL, 18)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(dp)
	var dsc := ScrollContainer.new()
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dsc.set_meta("pages", true)  # Confirm reads on down it (TextFitAudit counts that as reachable)
	dp.add_child(dsc)
	_dsc = dsc
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 10)
	dsc.add_child(_detail)
	UIKit.keep_fitted(_detail)  # a long quest steps its words down to fit the panel
	_quests = Quests.active(Game.data) if _tab == 0 else (Quests.done(Game.data) if _tab == 1 else Contracts.listed(Game.data))
	for i in _quests.size():
		_list_col.add_child(_row(i))
	if _quests.is_empty():
		_empty()
		set_hints([["leftright", "Tabs"], ["cancel", "Back"]])
		return
	UIKit.wrap_focus(_buttons)
	var at := clampi(int(_last.get(_tab, 0)), 0, _buttons.size() - 1)
	UIKit.focus_later(_buttons[at])
	_describe(at)

func _empty() -> void:
	var msg: String = ["No quests on the go. Folk with something on their mind will ask if you stop for a natter.",
		"Nothing finished yet. Everyone has to start somewhere, usually with somebody's lost cat.", "", "No contracts taken. Look over the notice boards in the towns."][_tab]
	var l := UIKit.label(msg, 22, UIKit.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list_col.add_child(l)
	if _tab == 3:
		ContractsTab.empty(_detail)
		return
	var t := UIKit.label("Quests", 30, UIKit.GOLD)
	_detail.add_child(t)
	var h := UIKit.label("Errands, mysteries and favours from the people you meet. When somebody asks, it goes in here, and so does what you've done about it.", 22)
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(h)

func _row(i: int) -> Button:
	var q: Dictionary = _quests[i]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.focus_neighbor_left = NodePath(".")
	b.focus_neighbor_right = NodePath(".")
	b.focus_entered.connect(func():
		Audio.sfx("cursor")
		_last[_tab] = i
		_describe(i))
	b.pressed.connect(func(): _press(i))
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	h.add_theme_constant_override("separation", 10)
	var mark := QuestMark.new()
	mark.done = _tab == 1 or (_tab == 3 and Contracts.closed(Game.data, str(q.get("id", ""))))
	mark.custom_minimum_size = Vector2(26, 26)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(mark)
	h.add_child(UIKit.row_label(str(q.get("title", "")) + _year_tag(q), 25, UIKit.CREAM))
	var town := UIKit.label(_place(str(q.get("town", ""))), 19, Color("d8cfb4"))
	town.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(town)
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	_buttons.append(b)
	return b

## A zone's name for people: a room says its town.
func _place(zone: String) -> String:
	var idx := ZoneIndex.get_index()
	var z := Quests.map_zone(zone, idx)
	return str(idx.zones.get(z, {}).get("name", z.capitalize()))

## " (2026)" on a festival's quest: the log shows this year's run, and the next year starts it afresh.
func _year_tag(q: Dictionary) -> String:
	var y := Festivals.quest_year(Game.data, q)
	return " (%d)" % y if y > 0 else ""

func _describe(i: int) -> void:
	UIKit.clear(_detail)
	_dsc.scroll_vertical = 0
	var q: Dictionary = _quests[i]
	if _tab == 3:
		ContractsTab.describe(_detail, q)
		_quest_hints(i)
		return
	var title := UIKit.label(str(q.get("title", "")) + _year_tag(q), 34)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(title)
	_detail.add_child(UIKit.label("%s, %s" % [str(q.get("giver", "")), _place(str(q.get("town", "")))], 20, UIKit.MUTED))
	var gist := UIKit.label(str(q.get("summary", "")), 22)
	gist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(gist)
	_detail.add_child(UIKit.spacer(2))
	var steps := VBoxContainer.new()
	steps.add_theme_constant_override("separation", 6)
	_detail.add_child(steps)
	var current := {}
	for s in Quests.log_steps(Game.data, q):
		steps.add_child(_step_line(s))
		if s.current:
			current = s
	_detail.add_child(UIKit.spacer(2))
	var rw := HBoxContainer.new()
	rw.add_theme_constant_override("separation", 14)
	var rk := UIKit.label("Reward", 20, UIKit.MUTED)
	rk.custom_minimum_size = Vector2(90, 0)
	rw.add_child(rk)
	var rv := UIKit.label(str(q.get("reward", "")), 22, UIKit.GOLD)
	rv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rw.add_child(rv)
	_detail.add_child(rw)
	_quest_hints(i)
	_quest_hints_fitted.call_deferred(i)

## Once the card has fitted (UIKit.keep_fitted), a quest that still runs on reads on with Confirm.
func _quest_hints_fitted(i: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_quest_hints(i)

func _quest_hints(i: int) -> void:
	if not is_instance_valid(_dsc) or i >= _quests.size():
		return
	var map := _tab == 0 and not Quests.current_step(Game.data, _quests[i]).is_empty()
	var confirm := [["confirm", "Read on"]] if UIKit.reads_on(_dsc) else ([["confirm", "Show on map"]] if map else [])
	set_hints([["leftright", "Tabs"], ["updown", "Quests"]] + confirm + [["cancel", "Back"]])

## One step: ticked and quiet once done, the current one in a lit box with where it is.
func _step_line(s: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var mark := QuestMark.new()
	mark.done = s.done
	mark.current = s.current
	mark.custom_minimum_size = Vector2(24, 24)
	mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(mark)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	var t := UIKit.label(str(s.text), 22, UIKit.MUTED if s.done else UIKit.CREAM)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(t)
	if s.current and str(s.zone) != "":
		col.add_child(UIKit.label(_place(str(s.zone)), 18, UIKit.GOLD))
	h.add_child(col)
	if not s.current:
		return h
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.box(Color("2a2f3d"), UIKit.HEATHER.darkened(0.1), 2, 8, 10))
	p.add_child(h)
	return p

func _press(i: int) -> void:
	if UIKit.read_on(_dsc):  # down a long quest first
		Audio.sfx("cursor")
		_quest_hints(i)
		return
	if _tab != 0 or i < 0 or i >= _quests.size():
		return
	if Quests.current_step(Game.data, _quests[i]).is_empty():
		return
	await open_child("map:quest:" + str(_quests[i].id))
	if i < _buttons.size():
		_buttons[i].grab_focus()

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	if _gaz != null and _gaz.wants_back(event):
		get_viewport().set_input_as_handled()
		return
	var d := 0
	if event.is_action_pressed("move_left"):
		d = -1
	elif event.is_action_pressed("move_right"):
		d = 1
	if d != 0:
		get_viewport().set_input_as_handled()
		_tab = MenuLogic.wrap_index(_tab, d, TABS.size())
		Audio.sfx("cursor")
		_show_tab()
		return
	super._input(event)

## A round mark: an empty ring for a quest under way, a gold ring with a dot for the current step, a green tick for
## anything done. Drawn, not a glyph, so it looks the same in every font.
class QuestMark:
	extends Control
	var done := false
	var current := false

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 2.0
		if done:
			draw_circle(c, r, Color("3f6a45"))
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.5, 0), c + Vector2(-r * 0.12, r * 0.4), c + Vector2(r * 0.55, -r * 0.42)]), Color("e9f3dc"), 3.0, true)
		elif current:
			draw_arc(c, r, 0, TAU, 24, UIKit.GOLD, 3.0, true)
			draw_circle(c, r * 0.42, UIKit.GOLD)
		else:
			draw_arc(c, r, 0, TAU, 24, UIKit.HEATHER, 3.0, true)
