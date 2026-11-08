extends MenuBase
## Trainer stats: the lifetime tallies (steps, wins, catches, journeys, money, a few daft ones) on the first page,
## and standing with the six nations plus the jobs in hand on the second. See TrainerStats and StandingPanel.

const ONE_COLUMN := 12  # rows that fit in one column
const DAFT_ONES := 9     # the first of the daft ones (cups of tea and so on)

var _page := 0

## "stats:trades" or "stats:standing" opens on that page (handy for screenshots).
func setup(arg: Variant = null) -> void:
	_page = {"standing": 1, "trades": 2, "weekly": 3}.get(str(arg), 0)
	if content != null:  # already built (the router calls this after adding the scene)
		_show_page()

func _build() -> void:
	set_title("Stats")
	header_right.text = Game.data.player_name
	set_hints([["leftright", "Tallies / Standing / Trades / Weekly"], ["cancel", "Back"]])
	_show_page()

func _show_page() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	if _page == 3:
		_show_weekly()
		return
	if _page == 2:
		var trades := TradesPanel.build(Game.data)  # the six Trades and their titles
		trades.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(trades)
		return
	if _page == 1:
		var panel := StandingPanel.build(Game.data, Game.dex)  # standing with the six nations, and jobs in hand
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(panel)
		return
	var card := UIKit.panel(Color("1d2230f0"), 14)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(card)
	# one column while it fits; past ONE_COLUMN rows (the County Shows and anything after), two side by side:
	# the journey on the left, the daft ones and the rest on the right
	var rows := TrainerStats.lines(Game.data)
	rows.append(["Uncommon coats", Coats.stats_line(Game.data)])  # see Coats
	rows.append(["Regional forms", Forms.stats_line(Game.data)])  # see Forms
	rows.append(["Plaques read", Gazetteer.stats_line(Game.data)])  # see Gazetteer
	rows.append(["These Isles", TheseIsles.stats_line(Game.data)])  # peoples of these isles: plaques, people, quests
	var two := rows.size() > ONE_COLUMN
	var split := DAFT_ONES if two else rows.size()
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 40)
	card.add_child(cols)
	var col: VBoxContainer = null
	var cw := content.size.x if content.size.x > 0 else get_viewport_rect().size.x - SIDE * 2  # before the first layout
	for i in rows.size():
		if i == 0 or i == split:
			col = VBoxContainer.new()
			col.add_theme_constant_override("separation", 4)
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cols.add_child(col)
		elif i == 1 or i == DAFT_ONES:  # a little gap before the walking and before the daft ones
			col.add_child(UIKit.spacer(4))
		var h := HBoxContainer.new()
		var k := UIKit.label(rows[i][0], 24 if two else 26, UIKit.MUTED)
		var v := UIKit.label(rows[i][1], 26 if two else 28, UIKit.GOLD if i == 0 else UIKit.CREAM)
		_fit_pair(k, v, (cw - 28 - (40 if two else 0)) / (2.0 if two else 1.0) - 16)
		h.add_child(k)
		h.add_child(UIKit.fill())
		h.add_child(v)
		col.add_child(h)

## A tally and its value step down together until they share a column's width (Large text makes two columns tight).
func _fit_pair(k: Label, v: Label, room: float) -> void:
	var f := ThemeDB.fallback_font
	var ks := k.get_theme_font_size("font_size")
	var vs := v.get_theme_font_size("font_size")
	while ks > UIKit.MIN_TEXT and f.get_string_size(k.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ks).x + f.get_string_size(v.text, HORIZONTAL_ALIGNMENT_LEFT, -1, vs).x > room:
		ks -= 1
		vs = maxi(UIKit.MIN_TEXT, vs - 1)
	k.add_theme_font_size_override("font_size", ks)
	v.add_theme_font_size_override("font_size", vs)

func _input(event: InputEvent) -> void:
	if not _locked and not _done and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
		get_viewport().set_input_as_handled()
		_page = posmod(_page + (1 if event.is_action_pressed("move_right") else -1), 4)
		Audio.sfx("cursor")
		_show_page()
		return
	super._input(event)

## The weekly challenge: this week's rules and the result code for the tallies so far.
func _show_weekly() -> void:
	var week := WeeklyChallenge.this_week()
	var r := WeeklyChallenge.rules(week)
	var card := UIKit.panel(Color("1d2230f0"), 14)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	col.add_child(UIKit.label("Challenge of the week %d" % week, 30, UIKit.GOLD))
	col.add_child(UIKit.label(WeeklyChallenge.describe(r), 26, UIKit.CREAM))
	col.add_child(UIKit.label("Everyone gets the same rules this week. Play by them, then compare codes.", 22, UIKit.MUTED))
	col.add_child(UIKit.spacer(10))
	col.add_child(UIKit.label("Your result code", 22, UIKit.MUTED))
	col.add_child(UIKit.label(WeeklyChallenge.result_code(week, WeeklyChallenge.tallies(Game.data)), 36, UIKit.CREAM))
