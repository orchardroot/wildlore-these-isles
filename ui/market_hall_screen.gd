extends MenuBase
## A Market Hall stall: the price board for the produce, dishes and fish you carry, and a sell flow at the Trade
## Ledger's price (Trade.sell_price) for this town. Opened as "market:<hall zone id>" by the `market` story command.
## Money in is the town's own (euros in the Republic); nothing else is touched, so no loop of sales can print money.

var _hall := ""
var _hall_data: Dictionary = {}
var _town := ""
var _mc := "gbp"
var _bag: Bag
var _rows: Array = []
var _mode := "list"       # list | qty
var _cur := {}
var _qty := 1
var _list_col: VBoxContainer
var _list_scroll: ScrollContainer
var _desc: VBoxContainer
var _qty_panel: PanelContainer
var _qty_label: Label
var _total_label: Label
var _say: Label
var _item_buttons: Array = []
var _last_item := 0

func _build() -> void:
	set_title("Market Hall")
	_bag = Bag.new(Game.data.bag)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 22)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 10)
	lp.custom_minimum_size = Vector2(620, 0)
	lp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(lp)
	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.follow_focus = true
	lp.add_child(_list_scroll)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list_col)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var dp := UIKit.panel(Color("1d2230f0"), 18)
	dp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(dp)
	_desc = VBoxContainer.new()
	_desc.add_theme_constant_override("separation", 10)
	dp.add_child(_desc)
	_qty_panel = UIKit.panel(Color("2c3446f8"), 14)
	_qty_panel.visible = false
	var qv := VBoxContainer.new()
	_qty_panel.add_child(qv)
	_qty_label = UIKit.label("", 34)
	qv.add_child(_qty_label)
	_total_label = UIKit.label("", 26, UIKit.GOLD)
	qv.add_child(_total_label)
	qv.add_child(UIKit.label("Up / Down  1      Left / Right  10", 20, UIKit.MUTED))
	right.add_child(_qty_panel)
	_say = UIKit.label("", 26, UIKit.GOLD)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_say)
	_set_hint()

func setup(arg: String) -> void:
	_hall = arg.split(":")[0]
	_hall_data = MarketHall.hall(_hall)
	if _hall_data.is_empty():
		_say.text = "Shut for the day. Try the next hall."
		return
	_town = str(_hall_data.town)
	set_title(str(_hall_data.name))
	_mc = Wallet.local(Game.data)
	_money()
	var talk := MarketHall.talk(Game.data, _hall)   # the news, or an order elsewhere, in the stall-holder's words
	_say.text = talk if talk != "" else "Have a look at the board. Prices are chalked up fresh."
	_refresh()

func _money() -> void:
	header_right.text = Wallet.purse_text(Game.data, _mc)

func _set_hint() -> void:
	if _mode == "qty":
		set_hints([["confirm", "Sell"], ["cancel", "Back"]])
	else:
		set_hints([["confirm", "Pick"], ["cancel", "Leave"]])

func _refresh() -> void:
	_rows = MarketHall.board(Game.data, _bag.store, func(i): return Game.items.get_item(i), _hall)
	TradeLedger.note_board(Game.data, _hall, _rows)   # the ledger remembers what the board said today
	var order_rows := []
	for o in TradeOrders.see_hall(Game.data, _hall):
		order_rows.append({"id": str(o.id), "name": "Order: %d x %s" % [int(o.qty), TradeOrders.item_name(o)], "n": _bag.count(str(o.item)),
			"sell": TradeOrders.gross(Game.data, o), "buy": 0, "note": "", "order": o})
	_rows = order_rows + _rows
	UIKit.clear(_list_col)
	_item_buttons.clear()
	if _rows.is_empty():
		_list_col.add_child(UIKit.label("Nothing here for the stalls. They buy produce, dishes and fish.", 26, UIKit.MUTED))
		UIKit.clear(_desc)
		return
	for r in _rows:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 56)
		var id: String = r.id
		b.focus_entered.connect(func():
			Audio.sfx("cursor")
			_last_item = _item_buttons.find(b)
			_describe(_last_item))
		b.pressed.connect(func():
			Audio.sfx("confirm")
			_pick(_item_buttons.find(b)))
		b.focus_neighbor_left = NodePath(".")
		b.focus_neighbor_right = NodePath(".")
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 14
		h.offset_right = -14
		h.add_theme_constant_override("separation", 10)
		if r.has("order"):
			h.add_child(UIKit.fit_label(str(r.name), 400, 26, 16, UIKit.CREAM))
		else:
			h.add_child(UIKit.label("%s  x%d" % [r.name, r.n], 26))
		h.add_child(UIKit.fill())
		h.add_child(UIKit.label(UIKit.money_text(_local(int(r.sell)), _mc), 26, UIKit.GOLD))
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		_list_col.add_child(b)
		_item_buttons.append(b)
	UIKit.wrap_focus(_item_buttons)
	_last_item = clampi(_last_item, 0, _item_buttons.size() - 1)
	_describe(_last_item)
	UIKit.focus_later(_item_buttons[_last_item])

func _local(gbp: int) -> int:
	return Wallet.localise(gbp, _mc)

## The board entry: what the stall pays, what it would cost you here and the Ledger's word on the market.
func _describe(i: int) -> void:
	UIKit.clear(_desc)
	if i < 0 or i >= _rows.size():
		return
	var r: Dictionary = _rows[i]
	if r.has("order"):
		_describe_order(r.order, int(r.n))
		return
	var it: Dictionary = Game.items.get_item(str(r.id))
	_desc.add_child(UIKit.label(str(r.name), 36))
	_desc.add_child(UIKit.chip(UIKit.kind_name(str(it.get("kind", ""))), Color("4a4f5e"), UIKit.CREAM, 18))
	var d := UIKit.label(str(it.get("desc", "")), 26)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_child(d)
	_desc.add_child(UIKit.fill())
	if str(r.note) != "":
		_desc.add_child(UIKit.label(str(r.note), 26, UIKit.GOLD))
	_desc.add_child(UIKit.label("Stall pays %s each, you'd pay %s" % [UIKit.money_text(_local(int(r.sell)), _mc), UIKit.money_text(_local(int(r.buy)), _mc)], 22, UIKit.MUTED))
	_desc.add_child(UIKit.label("You have %d" % int(r.n), 24, UIKit.MUTED))

## An order on this hall's board: what is wanted, by when, what it pays and why, and what you can do about it.
func _describe_order(o: Dictionary, held: int) -> void:
	_desc.add_child(UIKit.label("An order", 36))
	_desc.add_child(UIKit.chip("DELIVERY", Color("4a4f5e"), UIKit.CREAM, 18))
	var d := UIKit.label("%d x %s, by %s." % [int(o.qty), TradeOrders.item_name(o), TradeOrders.weekday(int(o.last))], 26)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_child(d)
	_desc.add_child(UIKit.fill())
	var extra := int(round((TradeOrders.premium(Game.data, o) - 1.0) * 100.0))
	var pays := UIKit.label("Pays about %s: the board price and %d%% on top for speed and freshness" % [UIKit.money_text(_local(TradeOrders.gross(Game.data, o)), _mc), extra], 22, UIKit.GOLD)
	pays.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_child(pays)
	var why := TradeOrders.blocked(Game.data, o, held)
	if why == "" or why.begins_with("You need"):
		why = "You have %d." % held + (" Pick to deliver." if why == "" else "")
		if held < int(o.qty) and TradeOrders.can_advance(Game.data, o):
			why += " Pick for an advance of %s." % UIKit.money_text(_local(TradeOrders.advance_amount(Game.data, o)), _mc)
	var note := UIKit.label(why, 22, UIKit.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_child(note)
	if TradeOrders.owed(Game.data) > 0:
		var debt := UIKit.label("You owe the halls %s, off your next delivery." % UIKit.money_text(_local(TradeOrders.owed(Game.data)), _mc), 20, UIKit.MUTED)
		debt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_desc.add_child(debt)

## Pick on an order: deliver if you have the goods, else take an advance if the Trader's credit offers one.
func _pick_order(o: Dictionary) -> void:
	var held := _bag.count(str(o.item))
	var why := TradeOrders.blocked(Game.data, o, held)
	if why == "":
		if not _bag.remove(str(o.item), int(o.qty)):
			return
		var gbp := TradeOrders.deliver(Game.data, o)
		var paid := _local(gbp)
		Wallet.earn(Game.data, paid, _mc)
		TrainerStats.earned(Game.data, gbp)
		_say.text = "Delivered. %s for the lot, and thanks for coming." % UIKit.money_text(paid, _mc)
		econ_tip()
		Audio.sfx("confirm")
	elif why.begins_with("You need") and TradeOrders.can_advance(Game.data, o):
		var adv := TradeOrders.take_advance(Game.data, o)
		Wallet.earn(Game.data, _local(adv), _mc)
		_say.text = "On account, then: %s now, and the rest when you bring them." % UIKit.money_text(_local(adv), _mc)
		Audio.sfx("confirm")
	else:
		_say.text = why
		Audio.sfx("bump")
	_money()
	_refresh()

func _pick(i: int) -> void:
	if i < 0 or i >= _rows.size():
		return
	_cur = _rows[i]
	if _cur.has("order"):
		_pick_order(_cur.order)
		return
	if int(_cur.sell) <= 0:
		_say.text = "Not worth the chalk, that. Keep it."
		Audio.sfx("bump")
		return
	_say.text = ""
	_qty = 1
	_mode = "qty"
	_qty_panel.visible = true
	_refresh_qty()
	_set_hint()

func _refresh_qty() -> void:
	_qty = clampi(_qty, 1, maxi(1, int(_cur.n)))
	_qty_label.text = "%s  x %d" % [_cur.name, _qty]
	_total_label.text = "You get %s" % UIKit.money_text(_local(MarketHall.payout(Game.data, _hall, str(_cur.id), _qty)), _mc)

func _commit() -> void:
	var id := str(_cur.id)
	if not _bag.remove(id, _qty):
		return
	var gbp := MarketHall.settle(Game.data, _hall, id, _qty)   # the glut builds, so a big stack is not a tap
	var paid := _local(gbp)
	Wallet.earn(Game.data, paid, _mc)
	TrainerStats.earned(Game.data, gbp)
	TrainerStats.sold(Game.data, gbp)
	_say.text = "Done. %s for the %s." % [UIKit.money_text(paid, _mc), _cur.name]
	econ_tip()
	Audio.sfx("confirm")
	_money()
	_close_qty()
	_refresh()

func _close_qty() -> void:
	_mode = "list"
	_qty_panel.visible = false
	_set_hint()
	if not _item_buttons.is_empty():
		UIKit.focus_later(_item_buttons[clampi(_last_item, 0, _item_buttons.size() - 1)])

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	if _mode == "qty":
		var d := 0
		if event.is_action_pressed("move_up"):
			d = 1
		elif event.is_action_pressed("move_down"):
			d = -1
		elif event.is_action_pressed("move_right"):
			d = 10
		elif event.is_action_pressed("move_left"):
			d = -10
		if d != 0:
			get_viewport().set_input_as_handled()
			var old := _qty
			_qty = clampi(_qty + d, 1, maxi(1, int(_cur.n)))
			if _qty != old:
				Audio.sfx("cursor")
			_refresh_qty()
			return
		if event.is_action_pressed("confirm"):
			get_viewport().set_input_as_handled()
			_commit()
			return
	super._input(event)

func _on_cancel() -> void:
	if _mode == "qty":
		Audio.sfx("cancel")
		_close_qty()
	else:
		close(null)
