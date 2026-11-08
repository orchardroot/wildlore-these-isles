extends MenuBase
## The parish noticeboard: today's jobs in this town (two or three, new each real day) and the ones you're carrying
## (three at most). Opening it hands in anything finished for this nation, and at Local the landlord's parcel is
## waiting. Opened as "jobs:<town>" by Noticeboard. See Jobs and Standing.

const PAPER := Color("efe6cc")
const OK := Color("a8d08d")
const ROW_H := 62

var _town := ""
var _nation := "england"
var _rows: Array = []      # [{"kind": "offer"|"held", "job": Dictionary, "slot": int}]
var _buttons: Array = []
var _list_col: VBoxContainer
var _desc: VBoxContainer
var _standing: VBoxContainer
var _say: Label
var _last := 0
var _confirm_drop := -1    # slot waiting for a second press to give up

func _build() -> void:
	set_title("Noticeboard")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 22)
	content.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560 if not UIKit.big_text() else 600, 0)  # long titles need a little more with Large text
	left.add_theme_constant_override("separation", 12)
	row.add_child(left)
	var lp := UIKit.panel(Color("1d2230f0"), 12)
	lp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_col.add_theme_constant_override("separation", 6)
	sc.add_child(_list_col)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var dp := UIKit.panel(Color("1d2230f0"), 18)
	dp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(dp)
	var dsc := ScrollContainer.new()  # whatever the standing card and the landlord's words leave
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dp.add_child(dsc)
	_desc = VBoxContainer.new()
	_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desc.add_theme_constant_override("separation", 8)
	dsc.add_child(_desc)
	UIKit.keep_fitted(_desc)  # a long job steps its words down to fit
	var sp := UIKit.panel(Color("1d2230f0"), 14)
	(left if UIKit.big_text() else right).add_child(sp)  # with Large text the standing card sits under the list, so the job has the room
	_standing = VBoxContainer.new()
	_standing.add_theme_constant_override("separation", 6)
	sp.add_child(_standing)
	_say = UIKit.label("", 22, UIKit.GOLD)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say.custom_minimum_size = Vector2(0, 30)
	_say.resized.connect(_fit_say)
	right.add_child(_say)

## Several hand-ins at once make a long line: it steps down a size or two rather than push the panels off the page.
func _fit_say() -> void:
	var w := maxf(_say.size.x, 200.0)
	var fs := UIKit.sized(22)
	while fs > UIKit.MIN_TEXT and UIKit.font().get_multiline_string_size(_say.text, HORIZONTAL_ALIGNMENT_LEFT, w, fs).y > 90:
		fs -= 1
	if _say.get_theme_font_size("font_size") != fs:
		_say.add_theme_font_size_override("font_size", fs)

func setup(arg: String) -> void:
	_town = arg if arg != "" else str(Game.data.zone_id)
	_nation = Standing.nation_for_zone(_town)
	set_title("%s Noticeboard" % Travel.town_name(_town))
	var news := []
	for r in Jobs.hand_in(Game.data, _nation, Game.items, Game.dex):
		news.append("Handed in: " + Parish.reward_text(r, Game.items) + ".")
		if str(r.tier_line) != "":
			news.append(str(r.tier_line) + "!")
	var parcel := Jobs.landlord_parcel(Game.data, _nation)
	if parcel != "":
		news.append("A parcel from the landlord is pinned up with your name on it: %s. On the house." % Game.items.get_item(parcel).get("name", parcel))
	if not news.is_empty():
		Audio.sfx("item")
	news.append_array(Jobs.held_back(Game.data, _nation, Game.items, Game.dex))
	_say.text = " ".join(news) if not news.is_empty() else _greeting()
	_refresh()

func _greeting() -> String:
	if Jobs.offers(Game.data, _town).is_empty():
		return "Nothing pinned up today but a lost glove and a flyer for line dancing."
	return ["Somebody always needs a hand round here.", "Fresh notices, still smelling of drawing pins.",
		"The parish runs on volunteers and biscuits."][posmod(hash(_town + Calendar.today_key()), 3)]

func _refresh() -> void:
	header_right.text = Wallet.purse_text(Game.data, Wallet.local(Game.data))
	_rows.clear()
	for j in Jobs.offers(Game.data, _town):
		if not Jobs.has_active(Game.data, str(j.id)):
			_rows.append({"kind": "offer", "job": j, "slot": 0})
	for a in Jobs.active(Game.data):
		_rows.append({"kind": "held", "job": a[2], "slot": a[0]})
	UIKit.clear(_list_col)
	_buttons.clear()
	var on := Festivals.whats_on()  # real-date festivals on now or soon (data/festivals.json)
	if not on.is_empty():
		_list_col.add_child(_heading("What's on"))
		for line in on:
			_list_col.add_child(_note(line))
		_list_col.add_child(UIKit.spacer(8))
	_list_col.add_child(_heading("Today's notices"))
	var offers := _rows.filter(func(r): return r.kind == "offer")
	if offers.is_empty():
		_list_col.add_child(_note("All taken. Check back tomorrow."))
	for i in _rows.size():
		if _rows[i].kind == "held" and (i == 0 or _rows[i - 1].kind == "offer"):
			_list_col.add_child(UIKit.spacer(8))
			_list_col.add_child(_heading("In hand  (%d of %d)" % [Jobs.active(Game.data).size(), Jobs.SLOTS]))
		_list_col.add_child(_row_button(i))
	if not _rows.any(func(r): return r.kind == "held"):
		_list_col.add_child(UIKit.spacer(8))
		_list_col.add_child(_heading("In hand  (0 of %d)" % Jobs.SLOTS))
		_list_col.add_child(_note("Nothing yet. Take on up to three jobs at once."))
	_draw_standing()
	if _buttons.is_empty():
		UIKit.clear(_desc)
		set_hints([["cancel", "Done"]])
		return
	UIKit.wrap_focus(_buttons)
	_last = clampi(_last, 0, _buttons.size() - 1)
	UIKit.focus_later(_buttons[_last])

func _heading(t: String) -> Label:
	var l := UIKit.label(t, 20, UIKit.MUTED)
	l.uppercase = true
	return l

func _note(t: String) -> Label:
	var l := UIKit.label(t, 22, UIKit.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _row_button(i: int) -> Button:
	var r: Dictionary = _rows[i]
	var j: Dictionary = r.job
	var done: bool = r.kind == "offer" and Jobs.done_today(Game.data, str(j.id))
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.focus_entered.connect(func():
		Audio.sfx("cursor")
		_last = _buttons.find(b)
		_confirm_drop = -1
		_describe(i))
	b.pressed.connect(func(): _press(i))
	b.focus_neighbor_left = NodePath(".")
	b.focus_neighbor_right = NodePath(".")
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	h.add_theme_constant_override("separation", 10)
	# a little paper slip, the colour of the notice, as the row's marker
	var slip := ColorRect.new()
	slip.custom_minimum_size = Vector2(10, 34)
	slip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slip.color = Noticeboard.PAPERS[posmod(hash(str(j.id)), Noticeboard.PAPERS.size())]
	h.add_child(slip)
	var t := UIKit.label(str(j.get("title", "")), 25, UIKit.MUTED if done else UIKit.CREAM)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	UIKit.fit_width(t)  # a long title steps down before it trims
	h.add_child(t)
	var tag := _tag(r, done)
	if tag[0] != "":
		var chip := UIKit.chip(tag[0], tag[1], UIKit.CREAM, 17)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(chip)
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	_buttons.append(b)
	return b

## The chip on a row: [text, colour].
func _tag(r: Dictionary, done: bool) -> Array:
	if done:
		return ["Done today", Color("3a4152")]
	if r.kind == "offer":
		var pay := int(r.job.get("pay", 1))
		return [["", "Small job", "Proper job", "Big job"][pay], [Color(), Color("4a5a48"), Color("5a5236"), Color("6a4636")][pay]]
	if Jobs.is_ready(Game.data, r.slot, Game.dex):
		return ["Ready", Color("3f6a45")]
	var t := Jobs.progress_text(Game.data, r.slot, Game.dex)
	return [t if "/" in t else "Under way", Color("3a4a66")]

func _describe(i: int) -> void:
	UIKit.clear(_desc)
	var r: Dictionary = _rows[i]
	var j: Dictionary = r.job
	var title := UIKit.label(str(j.get("title", "")), 32)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_child(title)
	_desc.add_child(UIKit.label("Posted by " + str(j.get("poster", "")), 19, UIKit.MUTED))
	var body := UIKit.label(str(j.get("text", "")), 22)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_child(body)
	_desc.add_child(UIKit.spacer(2))
	var s: Dictionary = Jobs.slot(Game.data, r.slot) if r.kind == "held" else {"lvl": Jobs.show_level(Game.data.badges.size())}
	_desc.add_child(_line("The job", Jobs.step_text(j, s, Game.items, Game.dex), UIKit.CREAM))
	if r.kind == "held":
		var ready := Jobs.is_ready(Game.data, r.slot, Game.dex)
		var p := Jobs.progress_text(Game.data, r.slot, Game.dex)
		if ready and str(j.nation) == _nation:
			p = "Ready: confirm to hand it in"
		_desc.add_child(_line("Progress", p, OK if ready else UIKit.CREAM))
	_desc.add_child(_line("Pays", _pay_text(j), UIKit.GOLD))
	var how: String = "Finishes by itself when it's done." if str(j.step.type) in Jobs.AUTO else "Hand it in at any noticeboard in %s." % Standing.name_of(str(j.nation))
	_desc.add_child(UIKit.label(how, 18, UIKit.MUTED))
	_set_row_hint(r)

func _line(k: String, v: String, col: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var kl := UIKit.label(k, 20, UIKit.MUTED)
	kl.custom_minimum_size = Vector2(96, 0)
	h.add_child(kl)
	var vl := UIKit.label(v, 22, col)
	vl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(vl)
	return h

func _pay_text(j: Dictionary) -> String:
	var jc := Wallet.currency_of_nation(str(j.get("nation", "")))  # an Irish job pays in euros
	var bits := [UIKit.money_text(Wallet.localise(Jobs.money_for(j, Game.data.badges.size()), jc), jc)]
	var rw: Dictionary = j.get("reward", {})
	for id in rw.get("items", {}):
		var n := int(rw.items[id])
		var nm := str(Game.items.get_item(str(id)).get("name", id))
		bits.append("%d %s" % [n, nm] if n > 1 else nm)
	if str(rw.get("recipe", "")) != "":
		bits.append("a recipe")
	if str(rw.get("charm", "")) != "":
		bits.append("a charm")
	var pts := int(rw.get("standing", Jobs.STANDING_FOR_PAY.get(int(j.get("pay", 1)), 2)))
	bits.append("%d standing in %s" % [pts, Standing.name_of(str(j.nation))])
	return ", ".join(bits)

func _set_row_hint(r: Dictionary) -> void:
	if r.kind == "offer":
		set_hints([["confirm", "Take it on"], ["cancel", "Done"]])
	elif Jobs.is_ready(Game.data, r.slot, Game.dex) and str(r.job.nation) == _nation:
		set_hints([["confirm", "Hand in"], ["cancel", "Done"]])
	else:
		set_hints([["confirm", "Give up"], ["cancel", "Done"]])

func _press(i: int) -> void:
	if i < 0 or i >= _rows.size():
		return
	var r: Dictionary = _rows[i]
	if r.kind == "offer":
		var err := Jobs.accept(Game.data, str(r.job.id), _town)
		if err != "":
			_say.text = err
			Audio.sfx("bump")
			return
		Audio.sfx("confirm")
		_say.text = "You take the notice down and pocket it. %s will be pleased." % str(r.job.poster).split(",")[0]
		_refresh()
		return
	if Jobs.is_ready(Game.data, r.slot, Game.dex) and str(r.job.nation) == _nation:
		var res := Jobs.complete(Game.data, r.slot, Game.items)
		Audio.sfx("item")
		_say.text = "Handed in: " + Parish.reward_text(res, Game.items) + "." + (" " + str(res.tier_line) + "!" if str(res.tier_line) != "" else "")
		_refresh()
		return
	if _confirm_drop != r.slot:
		_confirm_drop = r.slot
		Audio.sfx("bump")
		_say.text = "Give up on \"%s\"? Press again to take it off your hands." % str(r.job.title)
		return
	Jobs.abandon(Game.data, r.slot)
	_confirm_drop = -1
	Audio.sfx("cancel")
	_say.text = "You pin the notice back up. Somebody else will get to it. Probably."
	_refresh()

## Where you stand with this nation: the tier, a bar to the next one and what the next one brings.
func _draw_standing() -> void:
	UIKit.clear(_standing)
	var d: GameStateData = Game.data
	var t := Standing.tier(d, _nation)
	var h := HBoxContainer.new()
	h.add_child(UIKit.label("Standing in " + Standing.name_of(_nation), 20, UIKit.MUTED))
	h.add_child(UIKit.fill())
	h.add_child(UIKit.label(Standing.tier_name(d, _nation), 24, UIKit.GOLD))
	_standing.add_child(h)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	var lo: int = Standing.TIER_POINTS[t]
	var hi: int = Standing.TIER_POINTS[mini(t + 1, Standing.PILLAR)]
	bar.max_value = maxi(1, hi - lo)
	bar.value = bar.max_value if t >= Standing.PILLAR else Standing.points(d, _nation) - lo
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIKit.GOLD
	fill.set_corner_radius_all(4)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("2c3446")
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	_standing.add_child(bar)
	var left := Standing.to_next(d, _nation)
	var next: String = [
		"Known Face in %d: 5%% off in the shops." % left,
		"Regular in %d: the shops keep something special back for you." % left,
		"Local in %d: 10%% off, and the landlord starts leaving you a parcel." % left,
		"Pillar of the Community in %d: 15%% off and something for the mantelpiece." % left,
		"They'd put up a statue, but you'd only complain about the pigeons."][t]
	var nl := UIKit.label(next, 18, UIKit.MUTED)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_standing.add_child(nl)
