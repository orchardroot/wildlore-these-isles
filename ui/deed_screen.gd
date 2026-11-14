extends MenuBase
## A Deed counter (see Deeds): the books on the left (till, store, tier, manager, rates, the last few events), the
## counter on the right (buy, collect, stock the store, upgrade, sell back). Opened as "deed:<deed id>" from the
## counter in the interior by the `deed` story command. Wave 55: "Fit out the place" (upgrades with catches), "A matter
## needs an answer" (the month's decision) and "Let the manager go" are modes of the same screen (see DeedChoices).

var _id := ""
var _cur := Wallet.GBP
var _stmt: VBoxContainer
var _box: VBoxContainer
var _say: Label
var _buttons: Array = []
var _sell_armed := false
var _release_armed := false
var _mode := "books"   # books | fit | ask

func _build() -> void:
	set_title("The Business")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 22)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 18)
	lp.custom_minimum_size = Vector2(600, 0)
	row.add_child(lp)
	_stmt = VBoxContainer.new()
	_stmt.add_theme_constant_override("separation", 8)
	lp.add_child(_stmt)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var bp := UIKit.panel(Color("1d2230f0"), 10)
	right.add_child(bp)
	var bsc := ScrollContainer.new()   # the counter has more to offer now: it scrolls with the focus
	bsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bsc.follow_focus = true
	bsc.custom_minimum_size = Vector2(0, 360)
	bp.add_child(bsc)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bsc.add_child(_box)
	right.add_child(UIKit.fill())
	_say = UIKit.label("", 24, UIKit.GOLD)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_say)

## "deed:<deed id>"
func setup(arg: String) -> void:
	_id = arg
	var d := Deeds.get_deed(_id)
	_cur = Deeds.cur_of(_id)
	set_title(str(d.get("name", "The Business")))
	Deeds.tick(Game.data, Game.data.day_count)
	_say.text = _hello()
	_refresh()
	_set_hint()

func _hello() -> String:
	if Deeds.is_owned(Game.data, _id):
		return "Your place, your books. Collect the till, keep the store full, and watch the rates."
	return "It could be yours. Everything in it, the fryer included. The fryer comes with opinions."

func _local(gbp: int) -> String:
	return Wallet.fmt(Wallet.localise(gbp, _cur), _cur)

func _line(text: String, size := 22, colour := UIKit.CREAM) -> void:
	var l := UIKit.label(text, size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stmt.add_child(l)

func _refresh() -> void:
	var d: GameStateData = Game.data
	UIKit.clear(_stmt)
	UIKit.clear(_box)
	_buttons = []
	header_right.text = UIKit.money_text(Wallet.balance(d, _cur), _cur)
	if _mode == "fit" and Deeds.is_owned(d, _id):
		_refresh_fit()
	elif _mode == "ask" and Deeds.is_owned(d, _id) and not DeedChoices.pending(d, _id).is_empty():
		_refresh_ask()
	else:
		_mode = "books"
		_refresh_books()
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])

func _refresh_books() -> void:
	var d: GameStateData = Game.data
	var deed := Deeds.get_deed(_id)
	_stmt.add_child(UIKit.label("The books", 30, UIKit.GOLD))
	if Deeds.is_owned(d, _id):
		for t in Deeds.summary(d, _id):
			_line(str(t))
		_line("A good day, fully stocked, takes about %s." % _local(Deeds.daily_estimate(d, _id)), 20, UIKit.MUTED)
		var rep := DeedChoices.reputation(d, _id)
		if rep != 0:
			_line("Its name in the town: %s." % _name_word(rep), 20, UIKit.MUTED)
		var rec := Deeds.recent(d, _id)
		if not rec.is_empty():
			_stmt.add_child(UIKit.spacer(6))
			_line("Lately", 22, UIKit.MUTED)
			for t in rec:
				_line(str(t), 18, UIKit.MUTED)
		var p := DeedChoices.pending(d, _id)
		if not p.is_empty():
			_button("A matter needs an answer (%d days)" % int(p.left), _open_ask)
		_button("Collect the till (%s)" % _local(Deeds.till(d, _id)), _collect)
		for inp in deed.get("inputs", []):
			var it := str(inp.item)
			var nm := str(Trade.items().get_item(it).get("name", it))
			_button("Stock %s (store %d, bag %d)" % [nm, Deeds.store_of(d, _id, it), int(d.bag.get(it, 0))], _stock.bind(it))
		var up := Deeds.upgrade_cost(d, _id)
		if up > 0:
			var nxt: Dictionary = deed.tiers[Deeds.tier_of(d, _id) + 1]
			_button("Upgrade: %s (%s)" % [str(nxt.name), _local(up)], _upgrade)
		if not DeedChoices.upgrades(_id).is_empty():
			_button("Fit out the place", _open_fit)
		if Deeds.manager(d, _id) != "":
			_button("Let the manager go", _release)
		_button("Sell the business", _sell)
	else:
		_line(str(deed.get("kind", "")).capitalize() + " in " + str(deed.get("zone", "")).capitalize(), 22, UIKit.MUTED)
		_line("Price today: %s" % _local(Deeds.price(d, _id)))
		_line("Takes about %s a day when stocked. Business rates are %d%% of takings." % [_local(Deeds.daily_estimate(d, _id)), roundi(float(deed.get("rates", 0.0)) * 100.0)])
		_line(Deeds.talk("manager"), 18, UIKit.MUTED)
		_button("Buy it", _buy)
	_button("Leave", func(): close(null))

static func _name_word(rep: int) -> String:
	if rep >= 3:
		return "the place everyone recommends"
	if rep > 0:
		return "well thought of"
	if rep <= -3:
		return "you hear about it, and not kindly"
	return "a bit sniffed at"

func _refresh_fit() -> void:
	var d: GameStateData = Game.data
	_stmt.add_child(UIKit.label("Fitting out", 30, UIKit.GOLD))
	_line("Each of these costs something, and each has a catch. A few shut the door on another.", 18, UIKit.MUTED)
	for u in DeedChoices.upgrades(_id):
		var uid := str(u.id)
		_stmt.add_child(UIKit.spacer(4))
		var own := DeedChoices.has(d, _id, uid)
		_line(("%s (fitted)" if own else "%s") % str(u.name), 22, UIKit.GOLD if own else UIKit.CREAM)
		_line("%s %s" % [str(u.get("text", "")), DeedChoices.describe(u)], 16, UIKit.MUTED)
		var why := DeedChoices.why_not(d, _id, uid)
		if why == "" or why.begins_with("You'd"):
			_button("%s (%s)" % [str(u.name), _local(DeedChoices.cost(d, _id, u))], _fit.bind(uid))
		elif not own:
			_line(why, 16, UIKit.MUTED)
	_button("Back to the books", _back)

func _refresh_ask() -> void:
	var d: GameStateData = Game.data
	var p := DeedChoices.pending(d, _id)
	var ask: Dictionary = p.ask
	_stmt.add_child(UIKit.label(str(ask.title), 30, UIKit.GOLD))
	_line(str(ask.text))
	_line("%d days to answer it, and if you don't, %s." % [int(p.left), _lapse_line(d)], 18, UIKit.MUTED)
	var n := 0
	for o in ask.options:
		n += 1
		var c := DeedChoices.option_cost(d, _id, o)
		_stmt.add_child(UIKit.spacer(4))
		_line("%d. %s" % [n, str(o.label)], 20)
		_button("Answer %d (%s)" % [n, _local(c) if c > 0 else "free"], _answer.bind(str(o.id)))
	_button("Back to the books", _back)

func _lapse_line(d: GameStateData) -> String:
	var t := DeedChoices.manager_traits(d, _id)
	if t.is_empty():
		return "it goes the worst way"
	return "your manager, who is %s, picks" % str(t.label)

func _button(text: String, fn: Callable) -> void:
	var b := make_button(text, fn)
	b.add_theme_font_size_override("font_size", 26)
	_box.add_child(b)
	_buttons.append(b)

func _set_hint() -> void:
	set_hints([["confirm", "Choose"], ["cancel", "Leave"]])

func _done_sfx(ok: bool) -> void:
	Audio.sfx("item" if ok else "bump")

func _buy() -> void:
	var why := Deeds.buy(Game.data, _id)
	_done_sfx(why == "")
	_say.text = Deeds.talk("buy") if why == "" else why
	econ_tip()
	_refresh()

func _collect() -> void:
	var got := Deeds.collect(Game.data, _id)
	_done_sfx(got > 0)
	_say.text = ("Collected %s, after the council took its share." % Wallet.fmt(got, _cur)) if got > 0 else "Nothing in the till yet after rates. Give it a day or two."
	_refresh()

func _stock(item_id: String) -> void:
	var n := Deeds.supply(Game.data, _id, item_id, 99)
	_done_sfx(n > 0)
	_say.text = ("In goes %d." % n) if n > 0 else "Nothing to put in: either the store holds a fortnight already or the bag has none."
	_refresh()

func _upgrade() -> void:
	var why := Deeds.upgrade(Game.data, _id)
	_done_sfx(why == "")
	_say.text = "Done. The takings will notice." if why == "" else why
	_refresh()

func _sell() -> void:
	var d: GameStateData = Game.data
	if not _sell_armed:
		_sell_armed = true
		_say.text = "Sure? You'd get %s for the place (60%% of what you've put in), plus the till. Press again to sell." % _local(roundi(float(_paid()) * Deeds.SELL_BACK))
		Audio.sfx("cursor")
		return
	var got := Deeds.sell_back(d, _id)
	_sell_armed = false
	Audio.sfx("item")
	_say.text = Deeds.talk("sell") + "  (%s)" % Wallet.fmt(got, _cur)
	_refresh()

func _paid() -> int:
	return int(Deeds.state(Game.data, _id).get("paid", 0))

func _open_fit() -> void:
	_mode = "fit"
	_say.text = "Nothing here is free, and nothing is all good news."
	_refresh()

func _open_ask() -> void:
	_mode = "ask"
	_say.text = "Take your time. Not too much of it."
	_refresh()

func _back() -> void:
	_mode = "books"
	_refresh()

func _fit(up_id: String) -> void:
	var why := DeedChoices.buy(Game.data, _id, up_id)
	_done_sfx(why == "")
	_say.text = "Done. Time will tell." if why == "" else why
	_refresh()

func _answer(opt_id: String) -> void:
	var why := DeedChoices.answer(Game.data, _id, opt_id)
	_done_sfx(why == "")
	if why == "":
		var rec := Deeds.recent(Game.data, _id)
		_say.text = str(rec[0]).substr(str(rec[0]).find(":") + 2) if not rec.is_empty() else "Done."
		_mode = "books"
	else:
		_say.text = why
	_refresh()

func _release() -> void:
	var d: GameStateData = Game.data
	if not _release_armed:
		_release_armed = true
		_say.text = "Sure? They'll be told kindly. The till goes back to stopping a month after you leave. Press again."
		Audio.sfx("cursor")
		return
	Deeds.release_manager(d, _id)
	_release_armed = false
	Audio.sfx("item")
	_say.text = "Done. They took it well. They always do, to your face."
	_refresh()
