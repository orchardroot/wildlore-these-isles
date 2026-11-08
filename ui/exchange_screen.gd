extends MenuBase
## The Stock Exchange terminal: a ticker of the day's headlines, the board's listings with today's price and move,
## a fortnight's chart, dealing with commission inside the position limit, and your portfolio. Opened as
## "exchange:<board>" (manchester, london, edinburgh or dublin; Dublin deals in euros). The Doggerel kiosk
## (crypto_screen.gd) is this screen in a louder shirt. See Markets.

const DAYS := 14
const UP := Color("8fd18a")
const DOWN := Color("e9998c")
const ROW_H := 50
const PORTFOLIO := "_portfolio"
const TICK_SPEED := 70.0   # pixels a second

var _board := "london"
var _cur := "gbp"
var _ids: Array = []
var _mode := "list"        # list | act | qty
var _side := "buy"
var _sel := ""
var _qty := 1
var _last := 0
var _list_col: VBoxContainer
var _rows: Array = []
var _detail: VBoxContainer
var _act_row: HBoxContainer
var _about_label: Label
var _act_buttons: Array = []
var _qty_panel: PanelContainer
var _qty_label: Label
var _total_label: Label
var _limit_label: Label
var _say: Label
var _tick: Ticker
var _panel_bg := Color("1d2230f0")
var _accent := UIKit.GOLD

# --- what the screen deals in (the kiosk overrides these) ----------------------------------------------

func _is_coin() -> bool:
	return false

func _listing_ids() -> Array:
	return Markets.listings(_board)

func _name(id: String) -> String:
	return str(Markets.company(id).get("name", id))

func _price(id: String) -> float:
	return Markets.price_for(Game.data, id)

func _history(id: String) -> Array:
	return Markets.history(Game.data.rng_seed, id, Game.data.day_count, DAYS, Markets.events_of(Game.data))

func _move(id: String) -> float:
	return Markets.change(Game.data.rng_seed, id, Game.data.day_count, Markets.events_of(Game.data))

func _held(id: String) -> int:
	return int(Markets.holding(Game.data, id).n)

func _basis(id: String) -> int:
	return int(Markets.holding(Game.data, id).cost)

func _max_buy(id: String) -> int:
	return Markets.max_buy(Game.data, id)

func _cost(id: String, n: int) -> int:
	return Markets.buy_cost(n, _price(id), _cur)

func _proceeds(id: String, n: int) -> int:
	return Markets.sell_proceeds(n, _price(id), _cur)

func _limit() -> int:
	return Markets.cap(Game.data.badges.size(), _cur)

func _deal(id: String, side: String, n: int) -> Dictionary:
	return Markets.buy(Game.data, id, n) if side == "buy" else Markets.sell(Game.data, id, n)

func _price_text(v: float) -> String:
	return Wallet.fmt_price(v, _cur)

func _headlines() -> Array:
	return Markets.headlines(Game.data, false)

func _greeting() -> String:
	return str(Markets.board(_board).get("line", ""))

func _fee_text(id: String, n: int) -> String:
	var value := ceili(n * _price(id) - 0.000001) if _side == "buy" else floori(n * _price(id) + 0.000001)
	return "incl. %s commission" % UIKit.money_text(Markets.commission(value, _cur), _cur)

# --- building ---------------------------------------------------------------------------------------

func _build() -> void:
	set_title("Stock Exchange")
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	content.add_child(col)
	var strip := PanelContainer.new()
	strip.add_theme_stylebox_override("panel", UIKit.box(Color("0b0d14"), Color(_accent, 0.6), 2, 4, 4))
	col.add_child(strip)
	_tick = Ticker.new()
	_tick.colour = _accent
	strip.add_child(_tick)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	var lp := UIKit.panel(_panel_bg, 8)
	lp.custom_minimum_size = Vector2(500, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_col.add_theme_constant_override("separation", 2)
	sc.add_child(_list_col)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)
	var dp := UIKit.panel(_panel_bg, 14)
	dp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(dp)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 6)
	dp.add_child(_detail)
	_qty_panel = UIKit.panel(Color("2c3446f8"), 10)
	_qty_panel.visible = false
	var qv := VBoxContainer.new()
	_qty_panel.add_child(qv)
	_qty_label = UIKit.label("", 28)
	qv.add_child(_qty_label)
	_total_label = UIKit.label("", 22, _accent)
	_total_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qv.add_child(_total_label)
	_limit_label = UIKit.label("", 18, UIKit.MUTED)
	_limit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qv.add_child(_limit_label)
	right.add_child(_qty_panel)
	_say = UIKit.label("", 21, _accent)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say.custom_minimum_size = Vector2(0, 26)
	right.add_child(_say)

func setup(arg: String) -> void:
	var parts := arg.split(":")  # "<board>", or "<board>:portfolio" / "<board>:buy" (straight there, for screenshots)
	arg = parts[0]
	_board = arg if not Markets.board(arg).is_empty() else "london"
	var b := Markets.board(_board)
	_cur = str(b.get("currency", Wallet.GBP))
	if not _is_coin():
		set_title("%s, %s" % [str(b.get("name", "Stock Exchange")), str(b.get("city", ""))])
	var d: GameStateData = Game.data
	Markets.sync(d)
	var lines := Markets.settle(d).map(func(l): return str(l.text))
	_ids = _listing_ids()
	_draw_list()
	_say.text = " ".join(lines) if not lines.is_empty() else _greeting()
	_tick.text = "".join(_headlines().map(func(h): return "  *  " + str(h).to_upper() + "   "))
	_money()
	_set_hint()
	if parts.size() > 1 and parts[1] == "portfolio":
		_last = _rows.size() - 1
		_sel = PORTFOLIO
		_describe(PORTFOLIO)
		UIKit.focus_later(_rows[_last])
	elif parts.size() > 1 and parts[1] == "buy":
		_pick(_sel)
		_open_qty("buy")

func _money() -> void:
	header_right.text = Wallet.purse_text(Game.data, _cur)

## The headline strip: the text drawn straight onto the strip (no child label to spill out), scrolling left and
## coming round again without a gap.
class Ticker extends Control:
	var text := ""
	var colour := Color.WHITE
	var _x := 0.0
	const SIZE := 20

	func _init() -> void:
		custom_minimum_size = Vector2(0, 28)
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if text == "":
			return
		var w := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
		_x = fposmod(_x - 70.0 * delta, maxf(w, 1.0))
		queue_redraw()

	func _draw() -> void:
		var f: Font = ThemeDB.fallback_font
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
		var y := size.y * 0.5 + SIZE * 0.36
		var x := _x - w
		while x < size.x:
			draw_string(f, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, colour)
			x += maxf(w, 1.0)

func _set_hint() -> void:
	match _mode:
		"list": set_hints([["confirm", "Deal"], ["cancel", "Leave"]])
		"act": set_hints([["confirm", "Choose"], ["cancel", "Back"]])
		"qty": set_hints([["updown", "1"], ["leftright", "10"], ["confirm", "Confirm"], ["cancel", "Back"]])

func _move_colour(m: float) -> Color:
	return UP if m >= 0.0 else DOWN

func _pct(m: float) -> String:
	return "%s%.1f%%" % ["+" if m >= 0.0 else "", m * 100.0]

func _row_label(text: String, size: int, colour: Color, width := 0.0, right := false) -> Label:
	var l := UIKit.label(text, size, colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0.0:
		l.custom_minimum_size = Vector2(width, 0)
		l.clip_text = true
	if right:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

## How wide a column of figures must be for the widest of `texts` at `size` (the player's Text size and font).
func _col_w(texts: Array, size: int, least: float) -> float:
	var w := least
	for t in texts:
		w = maxf(w, ceilf(UIKit.font().get_string_size(str(t), HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.sized(size)).x) + 2.0)
	return w

func _draw_list() -> void:
	UIKit.clear(_list_col)
	_rows.clear()
	# the figures' columns fit their widest entry, so Large text widens them instead of trimming a price
	var id_w := _col_w(_ids, 18, 52.0)
	var price_w := _col_w(_ids.map(func(i): return _price_text(_price(i))), 21, 92.0)
	var pct_w := _col_w(_ids.map(func(i): return _pct(_move(i))), 17, 62.0)
	for id in _ids + [PORTFOLIO]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, maxi(ROW_H, UIKit.line_height(21) + 10))
		UIKit.compact(b, 2)
		b.focus_neighbor_left = NodePath(".")
		b.focus_neighbor_right = NodePath(".")
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 10
		h.offset_right = -10
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if id == PORTFOLIO:
			h.add_child(_row_label("Your portfolio", 24, _accent))
			h.add_child(UIKit.fill())
			h.add_child(_row_label(UIKit.money_text(_portfolio_value(), _cur), 22, UIKit.CREAM, 0.0, true))
		else:
			var m := _move(id)
			h.add_child(_row_label(str(id), 18, UIKit.MUTED, id_w))
			var nm := _row_label(_name(id), 21, UIKit.CREAM, 10.0)
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			UIKit.fit_width(nm)  # a long name steps down before it trims
			h.add_child(nm)
			h.add_child(_row_label("*" if _held(id) > 0 else "", 21, _accent, 12.0))
			h.add_child(_row_label(_price_text(_price(id)), 21, UIKit.CREAM, price_w, true))
			h.add_child(_row_label(_pct(m), 17, _move_colour(m), pct_w, true))
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		var key: String = id
		b.focus_entered.connect(func():
			if _mode != "list":
				return  # a late focus from the list must not redraw a deal in progress
			Audio.sfx("cursor")
			_last = _rows.find(b)
			_sel = key
			_describe(key))
		b.pressed.connect(func():
			Audio.sfx("confirm")
			_pick(key))
		_list_col.add_child(b)
		_rows.append(b)
	UIKit.wrap_focus(_rows)
	_last = clampi(_last, 0, _rows.size() - 1)
	_sel = (_ids + [PORTFOLIO])[_last]
	_describe(_sel)
	UIKit.focus_later(_rows[_last])

func _portfolio_value() -> int:
	return Markets.portfolio_value(Game.data, _cur)

# --- the right-hand panel ---------------------------------------------------------------------------

func _describe(id: String) -> void:
	UIKit.clear(_detail)
	_act_buttons.clear()
	_fit_detail.call_deferred()
	if id == PORTFOLIO:
		_describe_portfolio()
		return
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var nm := UIKit.fit_label(_name(id), 380, 32, 22)
	nm.custom_minimum_size = Vector2(0, 40)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	var chip := UIKit.chip(_sector(id), Color("4a4f5e"), UIKit.CREAM, 16)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(chip)
	_detail.add_child(head)
	var m := _move(id)
	var pl := HBoxContainer.new()
	pl.add_theme_constant_override("separation", 14)
	pl.add_child(UIKit.label(_price_text(_price(id)), 34))
	var mv := UIKit.label("%s today" % _pct(m), 22, _move_colour(m))
	mv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pl.add_child(mv)
	_detail.add_child(pl)
	var chart := PriceChart.new()
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chart.custom_minimum_size = Vector2(240, 120 if not UIKit.big_text() else 80)
	_style_chart(chart)
	_detail.add_child(chart)
	chart.set_values(_history(id), func(v: float) -> String: return _price_text(v))
	var n := _held(id)
	var hold := "You hold none." if n <= 0 else "You hold %d, worth %s (%s)." % [n, UIKit.money_text(floori(n * _price(id)), _cur), _gain_text(floori(n * _price(id)) - _basis(id))]
	_detail.add_child(UIKit.label(hold, 20, UIKit.CREAM if n > 0 else UIKit.MUTED))
	var about := UIKit.label(_about(id), 18, UIKit.MUTED)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(about)
	_about_label = about
	_act_row = HBoxContainer.new()
	_act_row.add_theme_constant_override("separation", 12)
	_detail.add_child(_act_row)
	for e in [["Buy", "buy"], ["Sell", "sell"]]:
		var b := UIKit.pill_button(e[0], 24)
		b.custom_minimum_size = Vector2(140, 44)
		var side: String = e[1]
		b.focus_entered.connect(func(): Audio.sfx("cursor"))
		b.pressed.connect(func():
			Audio.sfx("confirm")
			_open_qty(side))
		b.focus_mode = Control.FOCUS_NONE if _mode != "act" else Control.FOCUS_ALL
		_act_row.add_child(b)
		_act_buttons.append(b)

## The detail pane steps its words down together if the deal slip and the dealer's line leave it too little room.
func _fit_detail() -> void:
	await get_tree().process_frame
	if not is_instance_valid(_detail):
		return
	var right := _detail.get_parent().get_parent() as VBoxContainer
	var room: float = content.size.y - _tick.get_parent().size.y - 10 - 28  # the ticker strip, its gap, the pane's margins
	for c in right.get_children():
		if c != _detail.get_parent() and c.visible:
			room -= c.size.y + right.get_theme_constant("separation")
	UIKit.fit_column(_detail, room)

func _style_chart(_c: PriceChart) -> void:
	pass

func _sector(id: String) -> String:
	return str(Markets.company(id).get("sector", ""))

func _about(id: String) -> String:
	var c := Markets.company(id)
	var div := float(c.get("div", 0.0))
	var tail := (" Dividend about %d%% a year, paid each quarter." % roundi(div * 100.0)) if div > 0.0 else " Pays no dividend."
	return str(c.get("about", "")) + tail

func _gain_text(g: int) -> String:
	return ("up " if g >= 0 else "down ") + UIKit.money_text(absi(g), _cur)

func _describe_portfolio() -> void:
	var d: GameStateData = Game.data
	_detail.add_child(UIKit.label("Your portfolio", 32))
	var any := false
	for cur in [Wallet.GBP, Wallet.EUR]:
		for id in d.markets.get("h", {}):
			if Markets.currency_of(str(id)) != cur:
				continue
			any = true
			var n := int(d.markets.h[id].n)
			var worth := floori(n * Markets.price_for(d, str(id)))
			var g := worth - int(d.markets.h[id].cost)
			var h := HBoxContainer.new()
			h.add_child(_holding_name("%s  x %d" % [Markets.company(str(id)).get("name", id), n]))
			h.add_child(_row_label(Wallet.fmt(worth, cur), 20, UIKit.CREAM, _col_w([Wallet.fmt(worth, cur)], 20, 110.0), true))
			h.add_child(_row_label(("+" if g >= 0 else "") + Wallet.fmt(g, cur), 18, _move_colour(g), _col_w([Wallet.fmt(g, cur) + "+"], 18, 110.0), true))
			_detail.add_child(h)
	var coins := Markets.coin_held(d)
	if coins > 0:
		any = true
		var cv := floori(coins * Markets.coin_price_for(d))
		var g2 := cv - int(d.markets.coin.cost)
		var h2 := HBoxContainer.new()
		h2.add_child(_holding_name("%s  x %d" % [Markets.coin_state(d.rng_seed, d.day_count).name, coins]))
		h2.add_child(_row_label(Wallet.fmt(cv, Wallet.GBP), 20, UIKit.CREAM, _col_w([Wallet.fmt(cv, Wallet.GBP)], 20, 110.0), true))
		h2.add_child(_row_label(("+" if g2 >= 0 else "") + Wallet.fmt(g2, Wallet.GBP), 18, _move_colour(g2), _col_w([Wallet.fmt(g2, Wallet.GBP) + "+"], 18, 110.0), true))
		_detail.add_child(h2)
	if not any:
		var l := UIKit.label("Nothing yet. Every fortune starts with a single share, and most end with one too.", 20, UIKit.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(l)
	_detail.add_child(UIKit.fill())
	var r: Dictionary = d.markets.get("realised", {})
	var bits := []
	for cur in [Wallet.GBP, Wallet.EUR]:
		if int(r.get(cur, 0)) != 0 or cur == Wallet.GBP:
			bits.append(("+" if int(r.get(cur, 0)) >= 0 else "") + Wallet.fmt(int(r.get(cur, 0)), cur))
	for l in [UIKit.label("Banked so far (sales and dividends): %s" % ", ".join(bits), 20, UIKit.GOLD),
			UIKit.label("Deals done: %d.   Limit per company: %s, more with each Stone." % [int(d.markets.get("trades", 0)), UIKit.money_text(_limit(), _cur)], 18, UIKit.MUTED)]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(l)

## A holding's name in the portfolio: takes the room left of its figures and steps down before it trims.
func _holding_name(text: String) -> Label:
	var l := _row_label(text, 20, UIKit.CREAM, 10.0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UIKit.fit_width(l)
	return l

# --- dealing ---------------------------------------------------------------------------------------

func _pick(id: String) -> void:
	if id == PORTFOLIO:
		Audio.sfx("bump")
		_say.text = "That's just your holdings. Pick a company to deal in."
		return
	_sel = id
	_mode = "act"
	for b in _act_buttons:
		b.focus_mode = Control.FOCUS_ALL
	if not _act_buttons.is_empty():
		_act_buttons[0].focus_neighbor_left = NodePath(".")
		_act_buttons[1].focus_neighbor_right = NodePath(".")
		for b in _act_buttons:
			b.focus_neighbor_top = NodePath(".")
			b.focus_neighbor_bottom = NodePath(".")
		UIKit.focus_later(_act_buttons[0])
	_set_hint()

func _open_qty(side: String) -> void:
	var most := _max_buy(_sel) if side == "buy" else _held(_sel)
	if most < 1:
		Audio.sfx("bump")
		if side == "sell":
			_say.text = "You don't hold any to sell."
		elif _price(_sel) <= 0.0:
			_say.text = "Trading's suspended."
		elif floori(_held(_sel) * _price(_sel)) >= _limit() - ceili(_price(_sel)):
			_say.text = "That's your limit for one company. Win another Stone and the brokers will trust you with more."
		else:
			_say.text = "You'd need more %s for even one." % Wallet.name_of(_cur)
		return
	_side = side
	_qty = mini(most, 10)
	_mode = "qty"
	_qty_panel.visible = true
	_about_label.visible = false  # the deal slip takes their room
	_act_row.visible = false
	for b in _act_buttons:
		b.release_focus()
	_say.text = ""
	_refresh_qty()
	_set_hint()
	_fit_detail.call_deferred()

func _max_qty() -> int:
	return _max_buy(_sel) if _side == "buy" else _held(_sel)

func _refresh_qty() -> void:
	_qty = clampi(_qty, 1, maxi(1, _max_qty()))
	_qty_label.text = "%s %d x %s" % ["Buy" if _side == "buy" else "Sell", _qty, _name(_sel)]
	if _side == "buy":
		_total_label.text = "Costs %s, %s" % [UIKit.money_text(_cost(_sel, _qty), _cur), _fee_text(_sel, _qty)]
	else:
		_total_label.text = "You get %s, %s" % [UIKit.money_text(_proceeds(_sel, _qty), _cur), _fee_text(_sel, _qty)]
	_limit_label.text = "Up to %d. Limit %s a holding, more with each Stone." % [_max_qty(), UIKit.money_text(_limit(), _cur)]

func _commit() -> void:
	var r := _deal(_sel, _side, _qty)
	if not r.ok:
		_say.text = str(r.why)
		Audio.sfx("bump")
		return
	Audio.sfx("item")
	if _side == "buy":
		_say.text = "Bought %d %s for %s. The broker winks." % [_qty, _name(_sel), UIKit.money_text(int(r.cost), _cur)]
	else:
		var p := int(r.get("profit", 0))
		_say.text = "Sold %d for %s, %s on what you paid." % [_qty, UIKit.money_text(int(r.got), _cur), _gain_text(p)]
	_qty_panel.visible = false
	_mode = "list"
	_money()
	_draw_list()
	_set_hint()

func _back_to_list() -> void:
	_mode = "list"
	_qty_panel.visible = false
	_describe(_sel)
	_set_hint()
	if not _rows.is_empty():
		UIKit.focus_later(_rows[clampi(_last, 0, _rows.size() - 1)])

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	if _mode == "qty":
		var dlt := 0
		if event.is_action_pressed("move_up"):
			dlt = 1
		elif event.is_action_pressed("move_down"):
			dlt = -1
		elif event.is_action_pressed("move_right"):
			dlt = 10
		elif event.is_action_pressed("move_left"):
			dlt = -10
		if dlt != 0:
			get_viewport().set_input_as_handled()
			var old := _qty
			_qty += dlt
			_refresh_qty()
			if _qty != old:
				Audio.sfx("cursor")
			return
		if event.is_action_pressed("confirm"):
			get_viewport().set_input_as_handled()
			_commit()
			return
	super._input(event)

func _on_cancel() -> void:
	match _mode:
		"qty":
			Audio.sfx("cancel")
			_qty_panel.visible = false
			_about_label.visible = true
			_act_row.visible = true
			_mode = "act"
			_set_hint()
			if not _act_buttons.is_empty():
				UIKit.focus_later(_act_buttons[0 if _side == "buy" else 1])
		"act":
			Audio.sfx("cancel")
			_back_to_list()
		_:
			close(null)
