extends MenuBase
## The Almanac's Biology page (wave 45 session N): plain-words explainers that open as you meet each idea (Biology),
## Dr Keir's challenges with your prediction record, and the moor model. Pages on the left, the open one on the right.
## setup("<page id>"), "challenges" or "sim" starts on that row (screenshots).

var _list: VBoxContainer
var _detail: VBoxContainer
var _buttons: Array = []
var _ids: Array = []
var _start := ""

func _build() -> void:
	set_title("Biology")
	header_right.text = "%d of %d pages" % [Biology.open_count(Game.data), Biology.pages().size()]
	set_hints([["updown", "Choose"], ["confirm", "Open"], ["cancel", "Back"]])
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 24)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 12)
	lp.custom_minimum_size = Vector2(400, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 3)
	sc.add_child(_list)
	var rp := UIKit.panel(Color("1d2230f0"), 20)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rp)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 8)
	rp.add_child(_detail)
	_fill()

func setup(arg: String) -> void:
	var at := _ids.find(arg)
	if at >= 0:
		UIKit.focus_later(_buttons[at])
		_show(arg)

func _fill() -> void:
	UIKit.clear(_list)
	_buttons.clear()
	_ids.clear()
	var d: GameStateData = Game.data
	for p in Biology.pages():
		var open := Biology.page_open(d, p)
		_add_row(str(p.id), str(p.title), open)
	_add_row("challenges", "Dr Keir's challenges", Biology.lab_on(d))
	_add_row("sim", "The moor model", true)
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])
	_show(_ids[0])

func _add_row(id: String, text: String, open: bool) -> void:
	var b := make_button(text, _open.bind(id))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 36)
	b.add_theme_font_size_override("font_size", 20)
	UIKit.compact(b, 2)
	if not open:
		b.modulate = Color(1, 1, 1, 0.5)
	b.focus_entered.connect(_show.bind(id))
	_list.add_child(b)
	_buttons.append(b)
	_ids.append(id)

func _open(id: String) -> void:
	if id == "sim":
		await open_child("selection")
		_fill()
		var at := _ids.find("sim")
		UIKit.focus_later(_buttons[at])
		_show("sim")

func _words(text: String, size := 21, colour := UIKit.CREAM) -> Label:
	var l := UIKit.label(text, size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(l)
	return l

## A long page (or Large text) steps its words down together to fit the panel.
func _fit_detail() -> void:
	await get_tree().process_frame
	if is_instance_valid(_detail):
		UIKit.fit_column(_detail, content.size.y - 40)

func _show(id: String) -> void:
	UIKit.clear(_detail)
	_fit_detail.call_deferred()
	var d: GameStateData = Game.data
	match id:
		"challenges":
			_detail.add_child(UIKit.label("Dr Keir's challenges", 32, UIKit.GOLD))
			if not Biology.lab_on(d):
				_words("Ask Dr Keir at the Roslin Institute to set you a challenge.", 22, UIKit.MUTED)
				return
			_words("Before each basket hatches, give the odds of one thing. She scores the odds, not the luck.", 19, UIKit.MUTED)
			for c in Biology.challenges():
				var met := Biology.done(d, str(c.id))
				var h := HBoxContainer.new()
				h.add_child(UIKit.label(str(c.title), 20, UIKit.CREAM if met else UIKit.MUTED))
				h.add_child(UIKit.fill())
				if met:
					h.add_child(UIKit.chip("MET", UIKit.GOLD.darkened(0.25), UIKit.SLATE, 16))
				_detail.add_child(h)
			var rec := Biology.record_lines(d)
			_detail.add_child(UIKit.label("Your record", 22, UIKit.GOLD))
			if rec.is_empty():
				_words("No predictions scored yet.", 20, UIKit.MUTED)
			for l in rec.slice(maxi(0, rec.size() - 4)):
				_words(str(l), 18)
			_words("Good odds come true about as often as they say: being well calibrated.", 17, Color("d8cfb4"))
		"sim":
			_detail.add_child(UIKit.label("The moor model", 32, UIKit.GOLD))
			_words("Natural selection you can watch: predators take the creatures that stand out, the survivors breed, and the colours shift.", 21)
			for id2 in SelectionSim.SCENARIOS:
				_words("%s. %s" % [SelectionSim.SCENARIOS[id2].name, SelectionSim.SCENARIOS[id2].blurb], 19, UIKit.MUTED)
			_words("Press confirm to open it.", 19, Color("d8cfb4"))
		_:
			var p := Biology.page(id)
			_detail.add_child(UIKit.label(str(p.title), 32, UIKit.GOLD))
			if not Biology.page_open(d, p):
				_words(str(p.hint), 22, UIKit.MUTED)
				return
			for t in p.text:
				_words(str(t), 20)
			_detail.add_child(UIKit.spacer(4))
			_words(str(p.story), 18, Color("d8cfb4"))
