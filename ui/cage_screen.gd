extends CasinoBase
## The cashier's cage at the Palace: buy chips with money from your purse, cash them back. Chips aren't limited;
## stakes are (see Punt).

const BUYS := [10, 50, 100, 500]

var _purse_l: Label
var _chips_l: Label
var _stack: Control
var _buttons: Array = []

func _build() -> void:
	set_title("The Cage")
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 28)
	content.add_child(root)
	# left: the window, with the chips stacked up behind the grille
	var win := felt_panel(Color("2a1f1a"), BRASS, 24)
	win.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(win)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	win.add_child(v)
	v.add_child(serif(30, BRASS, "Cashier"))
	var note := UIKit.label("Chips at face value, no commission, no questions. Well, one question, and the doorman asked it.", 22, UIKit.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	_stack = Control.new()
	_stack.custom_minimum_size = Vector2(0, 230 if not UIKit.big_text() else 110)  # shorter stacks make room for Large text
	_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stack.draw.connect(_draw_stack)
	v.add_child(_stack)
	var nums := HBoxContainer.new()
	nums.add_theme_constant_override("separation", 40)
	v.add_child(nums)
	var a := VBoxContainer.new()
	a.add_child(UIKit.label("Purse", 22, UIKit.MUTED))
	_purse_l = serif(40, UIKit.CREAM)
	a.add_child(_purse_l)
	nums.add_child(a)
	var b := VBoxContainer.new()
	b.add_child(UIKit.label("Chips", 22, UIKit.MUTED))
	_chips_l = serif(40, UIKit.GOLD)
	b.add_child(_chips_l)
	nums.add_child(b)
	# right: what you can do
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(380, 0)
	col.add_theme_constant_override("separation", 10)
	root.add_child(col)
	for n in BUYS:
		var bt := make_button("Buy %s of chips" % Purse.text(n), _buy.bind(n), 380)
		col.add_child(bt)
		_buttons.append(bt)
	var cash := make_button("Cash in all my chips", _cash, 380)
	col.add_child(cash)
	_buttons.append(cash)
	var leave := make_button("Leave the cage", func(): close(null), 380)
	col.add_child(leave)
	_buttons.append(leave)
	col.add_child(UIKit.fill())
	var lim := UIKit.label("", 20, UIKit.MUTED)
	lim.name = "Limit"
	lim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(lim)
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])
	fit_side(col)
	fit_side(v, 48)
	set_hints([["updown", "Choose"], ["confirm", "Select"], ["cancel", "Leave"]])
	_update()

func setup(arg: String) -> void:
	if arg == "dev":
		_dev = true

func _uses_left_right() -> bool:
	return false

func _update() -> void:
	_purse_l.text = Purse.text(Purse.balance(Game.data))
	_chips_l.text = Purse.text(Punt.chips(Game.data))
	var lim: Label = find_child("Limit", true, false)
	lim.text = "Daily stake limit %s, with %s left today. It grows with every Stone you win." % [Purse.text(Punt.limit(Game.data)), Purse.text(Punt.left_today(Game.data))]
	refresh_header()
	_stack.queue_redraw()

func _buy(n: int) -> void:
	if not Punt.buy_chips(Game.data, n):
		Audio.sfx("bump")
		banner("Your purse says no.", LOSE, 34)
		return
	commit()
	Audio.sfx("shop_bell")
	_update()

func _cash() -> void:
	var n := Punt.cash_chips(Game.data)
	if n <= 0:
		banner("Nothing to cash. The cashier admires your restraint.", UIKit.CREAM, 28)
		return
	commit()
	Audio.sfx("item")
	banner("Cashed %s" % Purse.text(n), UIKit.GOLD, 46)
	_update()

## Stacks of chips behind the grille, one stack per denomination, as tall as you're holding.
func _draw_stack() -> void:
	var r := _stack.get_rect()
	var chips := Punt.chips(Game.data)
	var denoms := [500, 100, 50, 25, 10, 5]
	var x := 40.0
	var base := r.size.y - 30
	for dv in denoms:
		var n := mini(chips / dv, 14)
		chips -= (chips / dv) * dv
		for k in n:
			var c := Vector2(x, base - k * 9)
			_stack.draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.45))
			CasinoBase.draw_chip(_stack, Vector2(c.x, c.y / 0.45), 30, dv)
			_stack.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if n > 0:
			x += 76
	# the brass grille in front
	for gx in range(0, int(r.size.x), 36):
		_stack.draw_line(Vector2(gx, 0), Vector2(gx, r.size.y), Color(BRASS, 0.35), 2)
	_stack.draw_line(Vector2(0, r.size.y - 4), Vector2(r.size.x, r.size.y - 4), BRASS, 4)
