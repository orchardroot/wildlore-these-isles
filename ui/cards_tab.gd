class_name CardsTab
extends RefCounted
## The Almanac's Trumps album: every region's set of cards, the ones you hold in full colour and the rest as
## silhouettes, with a prize for finishing a region (Confirm on a finished region to collect it). See Trumps.

const PANEL := Color("1d2230f0")
const ROW_H := 50
const COLS := 6

var _menu: MenuBase
var _groups: Array = []
var _buttons: Array = []
var _list_col: VBoxContainer
var _head: VBoxContainer
var _grid: GridContainer
var _scroll: ScrollContainer
var _at := 0
var _note := ""

func _init(menu: MenuBase) -> void:
	_menu = menu

func build(parent: Control, start_region := "") -> void:
	var d: GameStateData = Game.data
	_groups = Trumps.album(d)
	if start_region != "":
		for i in _groups.size():
			if str(_groups[i].region) == start_region:
				_at = i
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	parent.add_child(col)
	col.add_child(_summary(d))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	var lp := UIKit.panel(PANEL, 10)
	lp.custom_minimum_size = Vector2(340, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_col.add_theme_constant_override("separation", 3)
	sc.add_child(_list_col)
	var dp := UIKit.panel(PANEL, 14)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(dp)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 8)
	dp.add_child(dv)
	_head = VBoxContainer.new()
	_head.add_theme_constant_override("separation", 4)
	dv.add_child(_head)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dv.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_grid)
	_list()

func _summary(d: GameStateData) -> PanelContainer:
	var p := UIKit.panel(PANEL, 10)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)
	var n := Trumps.owned_count(d)
	var all := Trumps.core_ids().size()
	var big := UIKit.label(str(n), 38, UIKit.GOLD)
	big.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(big)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 4)
	h.add_child(mid)
	mid.add_child(UIKit.label("of %d cards collected" % all, 22, UIKit.CREAM))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 9)
	bar.max_value = maxi(1, all)
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
	var w := int(d.trumps.get("wins", 0))
	var l := int(d.trumps.get("losses", 0))
	h.add_child(UIKit.label("%d won, %d lost" % [w, l], 20, UIKit.MUTED))
	return p

func _list() -> void:
	UIKit.clear(_list_col)
	_buttons.clear()
	for i in _groups.size():
		var g: Dictionary = _groups[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, ROW_H)
		b.focus_neighbor_left = NodePath(".")
		b.focus_neighbor_right = NodePath(".")
		b.focus_entered.connect(func():
			Audio.sfx("cursor")
			_show(i))
		b.pressed.connect(func(): _press(i))
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 12
		h.offset_right = -12
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var full: bool = g.complete
		var nl := UIKit.fit_label(str(g.name), 200, 22, 15, UIKit.GOLD if full else UIKit.CREAM)
		nl.custom_minimum_size = Vector2(200, 0)
		h.add_child(nl)
		h.add_child(UIKit.fill())
		var tag := "%d / %d" % [g.have, g.total]
		if full and not g.claimed:
			tag = "PRIZE"
		h.add_child(UIKit.label(tag, 19, UIKit.GOLD if full else UIKit.MUTED))
		b.add_child(h)
		_list_col.add_child(b)
		_buttons.append(b)
	if _buttons.is_empty():
		return
	UIKit.wrap_focus(_buttons)
	_at = clampi(_at, 0, _buttons.size() - 1)
	UIKit.focus_later(_buttons[_at])
	_show(_at)

func _show(i: int) -> void:
	_at = i
	var g: Dictionary = _groups[i]
	UIKit.clear(_head)
	UIKit.clear(_grid)
	var t := HBoxContainer.new()
	t.add_child(UIKit.label(str(g.name), 28, UIKit.GOLD if g.complete else UIKit.CREAM))
	t.add_child(UIKit.fill())
	t.add_child(UIKit.label("%d of %d" % [g.have, g.total], 22, UIKit.MUTED))
	_head.add_child(t)
	var line := ""
	if str(g.region) == "elsewhere":
		line = "Strays and legends: no wild route holds them. Residents in pubs near a Keeper's hall sometimes do."
	elif g.claimed:
		line = "Set complete, prize collected. Well done you."
	elif g.complete:
		line = "Set complete! Press Confirm to collect %s." % Trumps.prize_line(Trumps.prize(str(g.region)), Game.dex)
	else:
		line = "Finish the set for %s." % Trumps.prize_line(Trumps.prize(str(g.region)), Game.dex)
	if _note != "":
		line = _note
	_head.add_child(UIKit.fit_label(line, 760, 19, 14, UIKit.GOLD if g.complete and not g.claimed else UIKit.MUTED))
	for s in g.species:
		var have := Trumps.has_card(Game.data, str(s))
		var c := TrumpCard.new(false)
		c.show_card(str(s), true, not have)
		var cnt := int(Trumps.cards(Game.data).get(str(s), 0))
		if cnt > 1:
			var l := UIKit.label("x%d" % cnt, 15, UIKit.GOLD)
			l.position = Vector2(TrumpCard.SMALL.x - 34, 28)
			c.add_child(l)
		_grid.add_child(c)
	_scroll.scroll_vertical = 0
	_menu.set_hints([["updown", "Regions"], ["confirm", "Collect prize"], ["cancel", "Back"]] if g.complete and not g.claimed else [["updown", "Regions"], ["cancel", "Back"]])

func _press(i: int) -> void:
	var g: Dictionary = _groups[i]
	if not g.complete or g.claimed:
		Audio.sfx("cancel")
		return
	var d: GameStateData = Game.data
	var p := Trumps.prize(str(g.region))
	if str(p.kind) == "chapbook":
		Bag.new(d.bag).add(str(p.item), 1)
		_note = "Prize: %s, in your bag." % str(Game.items.get_item(str(p.item)).get("name", p.item))
	else:
		var cr := Creature.create(Game.dex.get_species(str(p.species)), 10, Game.rng, Game.moves)
		cr.variant = str(p.variant)
		var where := d.add_creature(cr)
		_note = "Prize: %s, %s." % [Trumps.prize_line(p, Game.dex), "joined your team" if where == "party" else "sent to the Ark"]
	d.set_flag(Trumps.FLAG_PRIZE + str(g.region), true)
	Audio.sfx("item")
	_groups = Trumps.album(d)
	_list()
	_note = ""
