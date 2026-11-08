extends MenuBase
## The Isles Games League card (story command {"do": "league"}; wave 48 G5): every minigame venue by region with a
## stamp for each game played, drawn as a stiff card with rosette-coloured stamps, and how far off the next reward
## letter from the Isles Games Society is. Reads GamesLeague (PartyPieces state). Closes with null.
## setup arg: "dev" fills a handful of stamps.

const BRONZE := Color("b8743a")
const SILVER := Color("c4c8d0")
const GOLD_R := Color("e8c872")
const CARD := Color("efe3c2")
const INK := Color("3a2c28")

var _list: VBoxContainer
var _head: Label
var _bar: Control

func _build() -> void:
	set_title("Isles Games League")
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	content.add_child(root)
	_head = UIKit.label("", 28, UIKit.GOLD)
	root.add_child(_head)
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, 42)
	_bar.draw.connect(_draw_bar)
	root.add_child(_bar)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.box(CARD, Color("8a6a4a"), 4, 10, 18))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(card)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	card.add_child(_list)
	set_hints([["cancel", "Close"]])
	_fill()

func setup(arg: String) -> void:
	if arg == "dev":
		GamesLeague.dev_fill(Game.data)
	if _list != null:
		_fill()

func _on_cancel() -> void:
	close(null)

func _fill() -> void:
	UIKit.clear(_list)
	var data: GameStateData = Game.data
	var rows := GamesLeague.rows(data)
	_head.text = "%d of %d stamps" % [GamesLeague.stamps(data), GamesLeague.total()]
	var region := ""
	for r in rows:
		if str(r.region) != region:
			region = str(r.region)
			var hl := UIKit.label(region.to_upper(), 20, Color("7a2a2a"))
			_list.add_child(hl)
			var rule := ColorRect.new()
			rule.color = Color("8a6a4a")
			rule.custom_minimum_size = Vector2(0, 2)
			_list.add_child(rule)
		_list.add_child(_row(r))
	if rows.is_empty():
		_list.add_child(UIKit.label("No games listed yet.", 24, INK))
	_bar.queue_redraw()

func _row(r: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var stamp := Control.new()
	stamp.custom_minimum_size = Vector2(44, 44)
	stamp.draw.connect(func(): _draw_stamp(stamp, r))
	h.add_child(stamp)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.add_child(UIKit.label(str(r.name), 24, INK if bool(r.stamped) else Color("8a7a68")))
	var sub := str(r.where)
	if bool(r.stamped) and float(r.best) > 0.0:
		sub += "  (best %s %s)" % [str(snappedf(float(r.best), 0.1)).trim_suffix(".0"), str(r.unit)]
	var wl := UIKit.label(sub, 16, Color("6a5a48"))
	wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(wl)
	h.add_child(col)
	return h

func _draw_stamp(c: Control, r: Dictionary) -> void:
	var p := Vector2(22, 22)
	if not bool(r.stamped):
		c.draw_arc(p, 17.0, 0.0, TAU, 24, Color("b0a088"), 2.0)
		return
	var col: Color = [Color("6a8a5a"), BRONZE, SILVER, GOLD_R][clampi(int(r.rosette), 0, 3)]
	for k in 12:
		var a := TAU * k / 12.0
		c.draw_circle(p + Vector2(cos(a), sin(a)) * 15.0, 6.0, col.darkened(0.15))
	c.draw_circle(p, 14.0, col)
	c.draw_arc(p, 9.0, 0.0, TAU, 20, col.darkened(0.35), 2.0)
	c.draw_string(ThemeDB.fallback_font, p + Vector2(-5, 7), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col.darkened(0.5))

func _draw_bar() -> void:
	var data: GameStateData = Game.data
	var g := GamesLeague.next_goal(data)
	var w := _bar.size.x
	_bar.draw_rect(Rect2(0, 8, w, 14), Color(0, 0, 0, 0.35))
	if g.is_empty():
		_bar.draw_rect(Rect2(0, 8, w, 14), UIKit.GOLD)
		_bar.draw_string(ThemeDB.fallback_font, Vector2(6, 40), "Every letter earned. The urn is proud.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.CREAM)
		return
	var f := clampf(float(g.have) / maxf(1.0, float(g.need)), 0.0, 1.0)
	_bar.draw_rect(Rect2(0, 8, w * f, 14), UIKit.GOLD)
	_bar.draw_string(ThemeDB.fallback_font, Vector2(6, 40), "Next letter from the Isles Games Society at %s" % str(g.label), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.CREAM)
