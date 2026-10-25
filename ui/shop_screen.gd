extends MenuBase
## Shop: buy with a quantity, sell at half price. Opened as "shop:<shop_id>"; stock comes from ItemDB.shops.
## It opens straight on the Buy list with the first item described; Back goes to Buy / Sell / Leave.

var _shop: Dictionary = {}
var _bag: Bag
var _mode := "root"      # root | list | qty
var _side := "buy"       # buy | sell
var _ids: Array = []
var _cur := ""           # item id in the quantity chooser
var _qty := 1
var _root_col: VBoxContainer
var _list_col: VBoxContainer
var _list_scroll: ScrollContainer
var _desc: VBoxContainer
var _qty_panel: PanelContainer
var _qty_label: Label
var _total_label: Label
var _say: Label
var _root_buttons: Array = []
var _item_buttons: Array = []
var _last_item := 0
var _nation := ""        # the shop's nation: standing brings a discount and, from Regular, extra stock (see Standing)
var _mc := "gbp"          # the shop's money: euros in the Republic (see Wallet); the other purse pays at the tourist rate
var _mid := 1.175        # today's euros to the pound, for the tourist rate

func _build() -> void:
	set_title("Shop")
	_bag = Bag.new(Game.data.bag)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 22)
	content.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 0)
	left.add_theme_constant_override("separation", 12)
	row.add_child(left)
	var rp := UIKit.panel(Color("1d2230f0"), 10)
	left.add_child(rp)
	_root_col = VBoxContainer.new()
	rp.add_child(_root_col)
	for e in [["Buy", func(): _open_list("buy")], ["Sell", func(): _open_list("sell")], ["Leave", func(): close(null)]]:
		var b := make_button(e[0], e[1])
		b.add_theme_font_size_override("font_size", 32)
		_root_col.add_child(b)
		_root_buttons.append(b)
	UIKit.wrap_focus(_root_buttons)
	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.follow_focus = true
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lp := UIKit.panel(Color("1d2230f0"), 10)
	lp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lp.add_child(_list_scroll)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list_col)
	left.add_child(lp)
	lp.visible = false
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
	_money()
	UIKit.focus_later(_root_buttons[0])
	_set_hint()

func setup(arg: String) -> void:
	var parts := arg.split(":")  # "<shop_id>" or "<shop_id>:buy|sell" (jump straight to a list, handy for screenshots)
	arg = parts[0]
	_shop = Game.items.shops.get(arg, {}) if Game.items != null else {}
	if _shop.is_empty():
		_say.text = "Shut for stocktaking. Back soon."
		set_title("Shop")
		return
	set_title(str(_shop.get("name", "Shop")))
	_nation = Standing.nation_for_zone(str(Game.data.zone_id))
	_mc = Wallet.local(Game.data)  # euros in the Republic, the territory's own money overseas
	Markets.sync(Game.data)
	_mid = Wallet.shop_rate(Game.data, _mc)
	_money()
	var t := Standing.tier(Game.data, _nation)
	_say.text = "Welcome in. Mind the cat." if t == Standing.STRANGER else \
		"Oh, it's you! %s, so that's %d%% off for you." % [Standing.TIER_NAMES[t], roundi(Standing.DISCOUNT[t] * 100)]
	var welcome := _say.text
	_open_list(parts[1] if parts.size() > 1 and parts[1] in ["buy", "sell"] else "buy")
	_say.text = welcome

func _money() -> void:
	header_right.text = Wallet.purse_text(Game.data, _mc)

## Everything you could pay here: this purse plus the other one at the tourist rate.
func _budget() -> int:
	return Wallet.spendable(Game.data, _mc, _mid)

func _set_hint() -> void:
	match _mode:
		"root": set_hints([["confirm", "Choose"], ["cancel", "Leave"]])
		"list": set_hints([["confirm", "Pick"], ["cancel", "Back"]])
		"qty": set_hints([["confirm", "Confirm"], ["cancel", "Back"]])

func _open_list(side: String) -> void:
	_side = side
	_mode = "list"
	_last_item = 0
	_say.text = ""
	_ids = []
	if side == "buy":
		for id in _shop.get("stock", []):
			if Game.items.has(id):
				_ids.append(id)
		for e in Standing.extra_stock(Game.data, _nation):  # kept back under the counter for regulars
			if Game.items.has(str(e[0])) and str(e[0]) not in _ids:
				_ids.append(str(e[0]))
	else:
		for id in _bag.store.keys():
			var it: Dictionary = Game.items.get_item(id)
			if not it.is_empty() and int(it.get("price", 0)) > 0 and str(it.get("kind", "")) != "key" and _bag.count(id) > 0:
				_ids.append(id)
	_draw_list()
	_list_scroll.get_parent().visible = true
	_root_col.get_parent().visible = false
	_set_hint()

func _draw_list() -> void:
	UIKit.clear(_list_col)
	_item_buttons.clear()
	if _ids.is_empty():
		_list_col.add_child(UIKit.label("Nothing to sell. Not even a biscuit." if _side == "sell" else "Sold out of everything.", 26, UIKit.MUTED))
		UIKit.clear(_desc)
		return
	for id in _ids:
		var it: Dictionary = Game.items.get_item(id)
		var price := _buy_price(id)
		var shown := price if _side == "buy" else _sell_price(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 56)
		b.focus_entered.connect(func():
			Audio.sfx("cursor")
			_last_item = _item_buttons.find(b)
			_describe(id))
		b.pressed.connect(func():
			Audio.sfx("confirm")
			_pick(id))
		b.focus_neighbor_left = NodePath(".")
		b.focus_neighbor_right = NodePath(".")
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 14
		h.offset_right = -14
		h.add_theme_constant_override("separation", 10)
		h.add_child(UIKit.label(str(it.get("name", id)), 28))
		h.add_child(UIKit.fill())
		var afford: bool = _side == "sell" or _budget() >= price
		h.add_child(UIKit.label(UIKit.money_text(shown, _mc), 26, UIKit.GOLD if afford else Color("e9998c")))
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		_list_col.add_child(b)
		_item_buttons.append(b)
	UIKit.wrap_focus(_item_buttons)
	_last_item = clampi(_last_item, 0, _item_buttons.size() - 1)
	_describe(_ids[_last_item])  # straight away, so the right panel is never empty while focus catches up
	UIKit.focus_later(_item_buttons[_last_item])

func _describe(id: String) -> void:
	UIKit.clear(_desc)
	var it: Dictionary = Game.items.get_item(id)
	_desc.add_child(UIKit.label(str(it.get("name", id)), 36))
	_desc.add_child(UIKit.chip(UIKit.kind_name(str(it.get("kind", ""))), Color("4a4f5e"), UIKit.CREAM, 18))
	var d := UIKit.label(str(it.get("desc", "")), 26)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_child(d)
	var note := Trade.price_note(Game.data, id, str(Game.data.zone_id))
	if note != "":
		_desc.add_child(UIKit.label("Here: %s" % note, 24, UIKit.GOLD))
	if str(it.get("kind", "")) == "wear":  # a try-on: you, in it, from the front and the side (4.6, see Looks)
		var tryon := HBoxContainer.new()
		tryon.add_theme_constant_override("separation", 16)
		var r := Looks.preview(Game.data, id, Game.items)
		tryon.add_child(LookArt.frame_rect(r, "down", 3.0))
		tryon.add_child(LookArt.frame_rect(r, "right", 3.0))
		var worn := Looks.worn_name(Game.data, str(it.get("slot", "")), Game.items)
		var how := "Trying it on." if worn == "" else "Trying it on, in place of your %s." % worn.to_lower()
		var tl := UIKit.label(how + "\nWear it from the Wardrobe (pause menu) once it's yours.", 22, UIKit.MUTED)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tryon.add_child(tl)
		_desc.add_child(tryon)
	_desc.add_child(UIKit.fill())
	_desc.add_child(UIKit.label("You have %d" % _bag.count(id), 24, UIKit.MUTED))

## What an item costs you here: the standing discount, and the under-the-counter price for a regular's extras.
func _buy_price(id: String) -> int:
	var base := Trade.buy_price(Game.data, id, str(Game.data.zone_id))  # regional: cheap where made, dear far away
	var extra := Standing.extra_price(_nation, id)
	if extra > 0 and (base <= 0 or id not in _shop.get("stock", [])):
		base = extra
	return Wallet.localise(Standing.price(Game.data, _nation, base), _mc)

func _sell_price(id: String) -> int:
	return Wallet.localise(Trade.sell_price(Game.data, id, str(Game.data.zone_id)), _mc)

## What `qty` of the current item fetch in all: each sale poorer than the last when the town is glutted.
func _sell_total(qty: int) -> int:
	return Wallet.localise(Trade.sell_total(Game.data, _cur, str(Game.data.zone_id), qty), _mc)

## Room to carry: trade goods stop at the Trader's Pannier cap, everything else keeps the bag's own limit.
func _owned_for_cap(id: String) -> int:
	return _bag.count(id) + Bag.MAX_STACK - Trade.carry_cap(Game.data, id)

func _pick(id: String) -> void:
	_cur = id
	var price := _buy_price(id)
	var most := MenuLogic.max_buy(_budget(), price, _owned_for_cap(id)) if _side == "buy" else _bag.count(id)
	if most < 1:
		_say.text = "You'd need a bit more cash for that one." if _side == "buy" and _budget() < price else "You can't carry any more of those."
		Audio.sfx("bump")
		return
	_say.text = ""
	_qty = 1
	_mode = "qty"
	_qty_panel.visible = true
	_refresh_qty()
	_set_hint()

func _max_qty() -> int:
	var price := _buy_price(_cur)
	if _side == "buy":
		return MenuLogic.max_buy(_budget(), price, _owned_for_cap(_cur))
	return _bag.count(_cur)

func _unit() -> int:
	return _buy_price(_cur) if _side == "buy" else _sell_price(_cur)

func _refresh_qty() -> void:
	_qty = clampi(_qty, 1, maxi(1, _max_qty()))
	_qty_label.text = "%s  x %d" % [Game.items.get_item(_cur).get("name", _cur), _qty]
	var total := _total_for(_qty)
	_total_label.text = "%s %s" % ["Total" if _side == "buy" else "You get", UIKit.money_text(total, _mc)]
	var short := total - Wallet.balance(Game.data, _mc)
	if _side == "buy" and short > 0 and Wallet.other(_mc) != "" and not _mc in Wallet.PAR_POUNDS:  # the rest from the other purse, at the tourist rate
		_total_label.text += "  (%s at the tourist rate)" % UIKit.money_text(Wallet.foreign_cost(short, _mc, _mid), Wallet.other(_mc))

func _total_for(qty: int) -> int:
	return _unit() * qty if _side == "buy" else _sell_total(qty)

func _commit() -> void:
	var total := _total_for(_qty)
	if _side == "buy":
		var paid := Wallet.pay(Game.data, total, _mc, _mid)
		if not paid.ok:
			_say.text = "Not enough cash for that many."
			Audio.sfx("bump")
			return
		Trade.stamp(Game.data, _cur, _bag.count(_cur), _qty)
		_bag.add(_cur, _qty)
		_say.text = "Lovely. %d x %s, that's %s." % [_qty, Game.items.get_item(_cur).name, UIKit.money_text(total, _mc)]
		if int(paid.foreign) > 0:
			_say.text += " " + _tourist_line(paid)
	else:
		if not _bag.remove(_cur, _qty):
			return
		Trade.record_sale(Game.data, _cur, str(Game.data.zone_id), _qty)
		Wallet.earn(Game.data, total, _mc)
		TrainerStats.earned(Game.data, Wallet.in_sterling(total, _mc))
		TrainerStats.sold(Game.data, Wallet.in_sterling(total, _mc))
		_say.text = "Cheers. %s for the %s." % [UIKit.money_text(total, _mc), Game.items.get_item(_cur).name]
		econ_tip()
	Audio.sfx("confirm")
	_money()
	_mode = "list"
	_qty_panel.visible = false
	_set_hint()
	if _side == "sell":
		_ids = _ids.filter(func(id): return _bag.count(id) > 0)
	_draw_list()

## The shopkeeper on being paid in the wrong money.
func _tourist_line(paid: Dictionary) -> String:
	if _mc != Wallet.GBP and _mc != Wallet.EUR:
		return "Short of %s? Sterling will do, at the tourist rate mind: %s." % [Wallet.name_of(_mc), UIKit.money_text(int(paid.foreign), Wallet.GBP)]
	if _mc == Wallet.EUR:
		return "Short on euros? Sterling's grand, at the tourist rate mind: %s." % UIKit.money_text(int(paid.foreign), Wallet.GBP)
	return "Euros? Go on then, at the tourist rate: %s. Don't tell the bank." % UIKit.money_text(int(paid.foreign), Wallet.EUR)

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
			_qty = clampi(_qty + d, 1, maxi(1, _max_qty()))
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
	match _mode:
		"qty":
			Audio.sfx("cancel")
			_close_qty()
		"list":
			Audio.sfx("cancel")
			_mode = "root"
			_list_scroll.get_parent().visible = false
			_root_col.get_parent().visible = true
			UIKit.clear(_desc)
			_set_hint()
			_root_buttons[0 if _side == "buy" else 1].grab_focus()
		_:
			close(null)
