extends MenuBase
## A town project's plans (see TownProjects): what the place needs, the stages and what each costs, what it will change,
## and the counter: pay the next stage, or everything left at once. Opened as "project:<id>" by the `project` story
## command, from the resident who speaks for it. When it is finished the same screen shows the plaque.

var _id := ""
var _cur := Wallet.GBP
var _stmt: VBoxContainer
var _box: VBoxContainer
var _say: Label
var _buttons: Array = []

func _build() -> void:
	set_title("The Town Fund")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 22)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 18)
	lp.custom_minimum_size = Vector2(640, 0)
	row.add_child(lp)
	var lsc := ScrollContainer.new()
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(lsc)
	_stmt = VBoxContainer.new()
	_stmt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stmt.add_theme_constant_override("separation", 8)
	lsc.add_child(_stmt)
	UIKit.keep_fitted(_stmt)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var bp := UIKit.panel(Color("1d2230f0"), 10)
	right.add_child(bp)
	_box = VBoxContainer.new()
	bp.add_child(_box)
	right.add_child(UIKit.fill())
	_say = UIKit.label("", 24, UIKit.GOLD)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_say)

## "project:<id>"
func setup(arg: String) -> void:
	_id = arg
	var p := TownProjects.get_project(_id)
	_cur = TownProjects.cur_of(p) if not p.is_empty() else Wallet.GBP
	set_title(str(p.get("name", "The Town Fund")))
	TownProjects.tick(Game.data, Game.data.day_count)   # anything that has finished building opens now
	_say.text = str(p.get("title", ""))
	_refresh()
	set_hints([["confirm", "Choose"], ["cancel", "Leave"]])

func _local(gbp: int) -> String:
	return Wallet.fmt(Wallet.localise(gbp, _cur), _cur)

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
	var p := TownProjects.get_project(_id)
	UIKit.clear(_stmt)
	UIKit.clear(_box)
	_buttons = []
	header_right.text = UIKit.money_text(Wallet.balance(d, _cur), _cur)
	if p.is_empty():
		_line("There's nothing here.")
		_button("Leave", func(): close(null))
		UIKit.focus_later(_buttons[0])
		return
	_stmt.add_child(UIKit.label(str(p.get("title", p.name)), 28, UIKit.GOLD))
	_line(str(p.text))
	var done := TownProjects.is_done(d, _id)
	var paid := TownProjects.stages_paid(d, _id)
	var f := TownProjects.factor(d)
	_stmt.add_child(UIKit.spacer(4))
	var n := 0
	for s in p.stages:
		var mark := "done" if (done or n < paid) else ("next" if n == paid else "")
		var tail := ""
		if done or n < paid:
			tail = "  (paid)"
		else:
			tail = "  (%s)" % _local(TownProjects.cost_at(p, n, f))
		_line("%d. %s%s" % [n + 1, str(s.name), tail], 20, UIKit.GOLD if mark == "next" else (UIKit.CREAM if mark == "done" else UIKit.MUTED))
		n += 1
	if done:
		_stmt.add_child(UIKit.spacer(6))
		_line("The plaque reads:", 20, UIKit.MUTED)
		_line("\"%s\"" % TownProjects.plaque(d, p), 20)
	else:
		_line("Roughly %s left to find, a little more each time the story moves on. %s" % [_local(TownProjects.cost_left(d, p)), str(p.get("change", ""))], 18, UIKit.MUTED)
	if done:
		_button("Leave", func(): close(null))
	else:
		var why := TownProjects.why_not(d, p)
		var days := TownProjects.days_left(d, _id)
		if days > 0:
			_line("The work goes on: about %d more days." % days, 18, UIKit.MUTED)
		if why == "":
			var nxt := TownProjects.stage_cost(d, p, paid)
			_button("Pay stage %d (%s)" % [paid + 1, _local(nxt)], _pay)
			if (p.stages as Array).size() - paid > 1:
				_button("Pay everything left (%s)" % _local(TownProjects.cost_left(d, p)), _pay_all)
		_button("Leave", func(): close(null))
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])

func _pay() -> void:
	var why := TownProjects.fund(Game.data, _id)
	Audio.sfx("item" if why == "" else "bump")
	var p := TownProjects.get_project(_id)
	_say.text = _stage_line(p) if why == "" else why
	_refresh()

func _pay_all() -> void:
	var why := TownProjects.fund_all(Game.data, _id)
	Audio.sfx("item" if why == "" else "bump")
	_say.text = "That's the lot. Work starts on Monday, or whenever it stops raining." if why == "" else why
	_refresh()

func _stage_line(p: Dictionary) -> String:
	var paid := TownProjects.stages_paid(Game.data, _id)
	return str(p.stages[maxi(0, paid - 1)].get("line", "Paid. Work begins."))
