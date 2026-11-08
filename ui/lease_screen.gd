extends MenuBase
## The Enclosure's leases (see Leases). "lease:" opens the auction room at the Exchange: every lot, for sale or held.
## "lease:<id>" opens that lot directly (a ranger on your own land sends you to its estate office). A lot for sale
## offers the sitting itself (bid, bold bid, pass, with the rivals answering); a lot you hold shows the books (upkeep,
## stage, what is coming back) and lets you commission the next stage of rewilding.

var _id := ""
var _auction: Dictionary = {}
var _stmt: VBoxContainer
var _box: VBoxContainer
var _say: Label
var _buttons: Array = []
var _from_list := true

func _build() -> void:
	set_title("The Enclosure's Lots")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 22)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 18)
	lp.custom_minimum_size = Vector2(620, 0)
	row.add_child(lp)
	_stmt = VBoxContainer.new()
	_stmt.add_theme_constant_override("separation", 8)
	lp.add_child(_stmt)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var bp := UIKit.panel(Color("1d2230f0"), 10)
	bp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(bp)
	var sl := UIKit.scroll_list(4)  # ten lots and a Leave button: past the panel, the list scrolls
	_box = sl[1]
	bp.add_child(sl[0])
	_say = UIKit.label("", 24, UIKit.GOLD)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_say)

## "lease:<id>" or "lease:" for the whole room.
func setup(arg: String) -> void:
	_id = arg
	_from_list = arg == ""
	Leases.tick(Game.data, Game.data.day_count)
	_say.text = Leases.talk("hello")
	_refresh()
	set_hints([["confirm", "Choose"], ["cancel", "Back"]])

func _on_cancel() -> void:
	if _id != "" and _from_list:
		_id = ""
		_auction = {}
		_say.text = Leases.talk("hello")
		_refresh()
		return
	close(null)

func _cur(id: String) -> String:
	return Leases.cur_of(id)

func _money(n: int, id: String) -> String:
	return Wallet.fmt(n, _cur(id))

func _line(text: String, size := 22, colour := UIKit.CREAM) -> void:
	var l := UIKit.label(text, size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stmt.add_child(l)

func _button(text: String, fn: Callable) -> void:
	var b := make_button(text, fn)
	b.add_theme_font_size_override("font_size", 26)
	_box.add_child(b)
	_buttons.append(b)

func _refresh() -> void:
	var d: GameStateData = Game.data
	UIKit.clear(_stmt)
	UIKit.clear(_box)
	_buttons = []
	header_right.text = UIKit.money_text(d.money, "gbp") + ("  " + UIKit.money_text(d.euros, "eur") if Wallet.had_euros(d) else "")
	if _id == "":
		_list()
	elif Leases.is_owned(d, _id):
		_estate()
	elif _auction.is_empty():
		_lot()
	else:
		_sitting()
	if _id != "" and not _from_list:
		_button("Leave", func(): close(null))
	elif _id != "":
		_button("Back to the lots", _on_cancel)
	else:
		_button("Leave", func(): close(null))
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])
	(func(): UIKit.fit_column(_stmt, content.size.y - 40)).call_deferred()  # a long statement steps its words down to fit the panel

func _list() -> void:
	var d: GameStateData = Game.data
	_stmt.add_child(UIKit.label("Lots", 30, UIKit.GOLD))
	var n := 0
	for l in Leases.all():
		var id := str(l.id)
		n += 1
		var tag := "held" if Leases.is_owned(d, id) else ("not yet on the market" if Leases.unavailable(d, id) != "" else "reserve %s" % _money(Wallet.localise(Leases.reserve_of(id), _cur(id)), id))
		_line("%s: %s" % [str(l.name), tag], 20, UIKit.MUTED)
		_button("%s%s" % [str(l.name), "  (held)" if Leases.is_owned(d, id) else ""], _open_lot.bind(id))
	if n == 0:
		_line("The catalogue is empty. The auctioneer is eating a biscuit.", 20, UIKit.MUTED)
	_line("Each lot is a real tract of the isles, fenced in the Enclosure's day. Win one and the fence comes down.", 18, UIKit.MUTED)
	var held := Leases.owned(d)
	if not held.is_empty():
		_line("You hold %d." % held.size(), 20, UIKit.MUTED)

func _open_lot(id: String) -> void:
	_id = id
	_auction = {}
	_say.text = Leases.talk("lot") if Leases.unavailable(Game.data, id) == "" else Leases.unavailable(Game.data, id)
	_refresh()

func _lot() -> void:
	var d: GameStateData = Game.data
	var l := Leases.get_lease(_id)
	_stmt.add_child(UIKit.label(str(l.name), 30, UIKit.GOLD))
	_line(str(l.blurb), 20)
	_line("%s, %s. Reserve %s, upkeep %s a week." % [str(l.kind).replace("_", " ").capitalize(), Standing.name_of(str(l.nation)),
		_money(Wallet.localise(Leases.reserve_of(_id), _cur(_id)), _id), _money(Wallet.localise(Leases.upkeep_of(_id), _cur(_id)), _id)], 20, UIKit.MUTED)
	var why := Leases.unavailable(d, _id)
	if why != "":
		_line(why, 20, UIKit.MUTED)
		return
	if Guilds.is_member(d, "trust") and bool(l.get("trust_wants", false)):
		_line("The Trust has been in touch. They like your valuation of it. They'd like it kept for the shoot.", 18, UIKit.MUTED)
	elif Guilds.is_member(d, "ramblers") and bool(l.get("trust_wants", false)):
		_line("Word is the Heritage Trust is coming for this one, and has your name on a list.", 18, UIKit.MUTED)
	_button("Take a paddle", _start)

func _start() -> void:
	_auction = Leases.auction_open(Game.data, _id)
	if _auction.is_empty():
		_say.text = Leases.unavailable(Game.data, _id)
	else:
		_say.text = Leases.talk("open")
	_refresh()

func _sitting() -> void:
	var a := _auction
	_stmt.add_child(UIKit.label(str(Leases.get_lease(_id).name), 30, UIKit.GOLD))
	_line("Reserve %s. Bidding goes up by %s." % [Wallet.fmt(int(a.reserve), str(a.cur)), Wallet.fmt(int(a.step), str(a.cur))], 20, UIKit.MUTED)
	_line("In the room:", 20, UIKit.MUTED)
	for r in a.rivals:
		_line("  %s%s" % [str(r.name), " (out)" if bool(r.get("out", false)) else ""], 20, UIKit.MUTED if bool(r.get("out", false)) else UIKit.CREAM)
	if int(a.bid) > 0:
		_line("Current bid: %s, %s." % [Wallet.fmt(int(a.bid), str(a.cur)), "yours" if str(a.by) == "you" else str(a.by)], 26)
	for t in a.notes:
		_line(str(t), 20)
	if bool(a.over):
		_line("The hammer has fallen.", 24, UIKit.GOLD)
		return
	var mb := Leases.min_bid(a)
	_button("Bid %s" % Wallet.fmt(mb, str(a.cur)), _bid.bind(0))
	_button("Bid boldly: %s" % Wallet.fmt(mb + Leases.BIG_STEPS * int(a.step), str(a.cur)), _bid.bind(Leases.BIG_STEPS))
	_button("Sit on your hands", _pass)

func _bid(extra: int) -> void:
	var why := Leases.bid(_auction, Game.data, extra)
	if why != "":
		Audio.sfx("bump")
		_say.text = why
		return
	if bool(_auction.over) and bool(_auction.won):
		Audio.sfx("badge")
		_say.text = Leases.talk("won")
		Bus.flag_changed.emit(Leases.key_of(_id), true)
		econ_tip()
	else:
		Audio.sfx("cursor")
		_say.text = Leases.talk("raised")
	_refresh()

func _pass() -> void:
	Leases.pass_lot(_auction, Game.data)
	_say.text = Leases.talk("lost")
	_refresh()

func _estate() -> void:
	var d: GameStateData = Game.data
	var l := Leases.get_lease(_id)
	var st := Leases.state(d, _id)
	var stage := Leases.stage(d, _id)
	_stmt.add_child(UIKit.label(str(l.name), 30, UIKit.GOLD))
	_line("Yours. The land is %s." % Rewild.stage_name(stage).to_lower(), 22)
	_line("Upkeep %s a week, next due in %d days.%s" % [_money(Wallet.localise(Leases.upkeep_of(_id), _cur(_id)), _id),
		maxi(0, int(st.get("next", 0)) - d.day_count), (" You are %d weeks behind." % Leases.arrears(d, _id)) if Leases.arrears(d, _id) > 0 else ""], 20, UIKit.MUTED)
	if Leases.pending(d, _id):
		var left := maxi(0, int(st.get("due", 0)) + Leases.SEASON - d.day_count)
		_line("Contractors on site. The next stage settles in %d days." % left, 20, UIKit.MUTED)
	if Guilds.is_member(d, "trust"):
		_line("The Heritage Trust manages it for the shoot while you are a Trustee.", 18, UIKit.MUTED)
	var why := Leases.commission_blocked(d, _id)
	if stage < Rewild.WILD:
		var cost := Wallet.localise(Leases.stage_cost(d, _id), _cur(_id))
		_button("Commission the next stage (%s)" % _money(cost, _id), _commission)
		if why != "":
			_line(why, 18, UIKit.MUTED)

func _commission() -> void:
	var why := Leases.commission(Game.data, _id)
	Audio.sfx("item" if why == "" else "bump")
	_say.text = Leases.talk("commissioned") if why == "" else why
	_refresh()
