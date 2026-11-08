class_name PiecesTab
extends RefCounted
## The Almanac's Party Pieces page (wave 48): every minigame in the Isles with where it is played, your rosette, your
## best, and the move it teaches. A piece you have won can be taught again to any party member who can learn it, free.
## See PartyPieces and PiecePrompt.

const PANEL := Color("1d2230f0")
const ROW_H := 40
const MARKS := ["-", "Bronze", "Silver", "Gold"]

var _menu: MenuBase
var _detail: VBoxContainer
var _buttons: Array = []
var _ids: Array = []
var _note: Label

func _init(menu: MenuBase) -> void:
	_menu = menu

func build(parent: Control) -> void:
	_ids = PartyPieces.ids()
	_ids.sort_custom(func(a, b): return str(PartyPieces.entry(str(a)).name) < str(PartyPieces.entry(str(b)).name))
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 560)
	row.add_theme_constant_override("separation", 22)
	parent.add_child(row)
	var lp := UIKit.panel(Color("14182299"), 10)
	lp.custom_minimum_size = Vector2(380, 0)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lp.size_flags_stretch_ratio = 0.8
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
	col.add_theme_constant_override("separation", 3)
	sc.add_child(col)
	var dp := UIKit.panel(PANEL, 18)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dp.size_flags_stretch_ratio = 1.2
	dp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(dp)
	var dsc := ScrollContainer.new()
	dsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dp.add_child(dsc)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 8)
	dsc.add_child(_detail)
	var got := _ids.filter(func(i): return PartyPieces.unlocked(Game.data, str(i))).size()
	var intro := UIKit.label("%d of %d pieces learnt. A silver rosette at a game and your lead creature picks up its piece." % [got, _ids.size()], 18, UIKit.GOLD)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(intro)
	var lg: Button = _menu.make_button("Isles Games League card", func(): _menu.open_child("league"))
	lg.custom_minimum_size = Vector2(0, ROW_H)
	lg.alignment = HORIZONTAL_ALIGNMENT_LEFT
	lg.add_theme_font_size_override("font_size", 20)
	lg.focus_entered.connect(_show_league)
	col.add_child(lg)
	_buttons.append(lg)
	for id in _ids:
		var e := PartyPieces.entry(str(id))
		var b: Button = _menu.make_button("%s   %s" % [str(e.name), MARKS[PartyPieces.rosette(Game.data, str(id))]], func(): pass)
		b.custom_minimum_size = Vector2(0, ROW_H)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 20)
		b.focus_entered.connect(_show.bind(str(id)))
		col.add_child(b)
		_buttons.append(b)
	if _buttons.is_empty():
		return
	UIKit.wrap_focus(_buttons)
	# focus once the list has its size, or follow_focus scrolls it to the bottom on opening
	var first: Button = _buttons[1] if _buttons.size() > 1 else _buttons[0]
	_menu.get_tree().process_frame.connect(func(): UIKit.focus_later(first), CONNECT_ONE_SHOT)
	if not _ids.is_empty():
		_show(str(_ids[0]))

func _line(text: String, size := 21, colour := UIKit.CREAM) -> Label:
	var t := UIKit.label(text, size, colour)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(t)
	return t

func _show_league() -> void:
	UIKit.clear(_detail)
	_line("Isles Games League", 30, UIKit.GOLD)
	_line("A stamp for every game you have played, venue by venue: %d of %d so far." % [GamesLeague.stamps(Game.data), GamesLeague.total()])
	var goal := GamesLeague.next_goal(Game.data)
	if not goal.is_empty():
		_line("The Isles Games Society writes again at %s." % str(goal.label), 19, UIKit.MUTED)
	_line("Press Confirm to open the card.", 19, UIKit.MUTED)

func _show(id: String) -> void:
	UIKit.clear(_detail)
	var e := PartyPieces.entry(id)
	var st := PartyPieces.state(Game.data, id)
	var rose := PartyPieces.rosette(Game.data, id)
	var mv: Dictionary = Game.moves.get_move(str(e.move))
	_line(str(e.name), 30, UIKit.GOLD)
	_line("Played at: %s." % str(e.where), 20, UIKit.MUTED)
	var lower := bool(e.get("lower_better", false))
	var best := "not played yet" if int(st.plays) == 0 else "%s (played %d time%s)" % [_num(float(st.best)), int(st.plays), "" if int(st.plays) == 1 else "s"]
	_line("Rosette: %s.   Best, %s: %s." % [MARKS[rose] if rose > 0 else "none yet", str(e.unit), best])
	_line("Silver needs %s%s, gold %s%s (to beat %s)." % [_num(float(e.good)), " or under" if lower else " or more", _num(float(e.master)), " or under" if lower else " or more", str(e.master_name)], 19, UIKit.MUTED)
	_detail.add_child(UIKit.spacer(6))
	var known := PartyPieces.unlocked(Game.data, id)
	_line(("The piece: %s" % str(mv.get("name", "?"))) if known else "The piece: %s (win silver to learn it)" % str(mv.get("name", "?")), 24, UIKit.GOLD)
	_line(MoveText.describe(mv), 19)
	var types: Array = e.get("types", [])
	_line("Suits: %s." % ("any creature" if types.is_empty() else ", ".join(PackedStringArray(types))), 19, UIKit.MUTED)
	if str(e.get("field", "")) != "":
		_line("A field piece: out in the world it can \"%s\" what blocks the way." % str(e.field), 19, UIKit.MUTED)
	if not known:
		return
	_detail.add_child(UIKit.spacer(4))
	_line("Teach it, free:", 21, UIKit.GOLD)
	for i in Game.data.party.size():
		var c: Creature = Game.data.party[i]
		if c.has_move(str(e.move)):
			_line("%s already knows it." % c.display_name(), 19, UIKit.MUTED)
		elif PartyPieces.can_learn(c, id, Game.moves):
			var b: Button = _menu.make_button("Teach %s" % c.display_name(), _teach.bind(id, i))
			b.custom_minimum_size = Vector2(0, ROW_H)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			_detail.add_child(b)
		else:
			_line("%s cannot learn it." % c.display_name(), 19, UIKit.MUTED)
	_note = _line("", 20, UIKit.GOLD)

func _teach(id: String, idx: int) -> void:
	var c: Creature = Game.data.party[idx]
	var mname := str(Game.moves.get_move(PartyPieces.move_of(id)).get("name", "it"))
	var ok: bool = await PiecePrompt.teach(_menu, id, idx)
	_show(id)
	if is_instance_valid(_note):
		_note.text = ("%s learned %s!" % [c.display_name(), mname]) if ok else ("%s did not learn %s." % [c.display_name(), mname])

static func _num(v: float) -> String:
	return str(int(v)) if v == floorf(v) else "%.1f" % v
