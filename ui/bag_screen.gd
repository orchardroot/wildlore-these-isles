extends MenuBase
## Bag: tabs by item kind, use on a party member via Bag.use_on. With arg "for:<n>" it targets party member n directly;
## "hold:<n>" shows only charms, to give party member n one to hold. Food is shared (it heals and they like you more).

const KIND_ORDER := ["heal", "meal", "cure", "revive", "pp", "snare", "repel", "evo", "charm", "curio", "material", "fish", "produce", "wear", "key"]
const USABLE := ["heal", "cure", "revive", "pp", "evo"]

var _bag: Bag
var _kinds: Array = []
var _tab := 0
var _mode := "list"      # list | pick
var _target := -1        # fixed party index when opened from the Team screen
var _pending := ""       # item id waiting for a party member
var _tabs_row: HBoxContainer
var _list_col: VBoxContainer
var _desc: VBoxContainer
var _picker: VBoxContainer
var _picker_panel: PanelContainer
var _note: Label
var _item_buttons: Array = []
var _pick_buttons: Array = []
var _last_item := 0
var _hold := false       # opened to pick a charm for _target to hold

func _build() -> void:
	set_title("Bag")
	_bag = Bag.new(Game.data.bag)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 12)
	content.add_child(col)
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 10)
	col.add_child(_tabs_row)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 22)
	col.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 12)
	lp.custom_minimum_size = Vector2(620, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	lp.add_child(sc)
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list_col)
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
	_picker_panel = UIKit.panel(Color("1d2230f0"), 10)
	_picker_panel.visible = false
	_picker = VBoxContainer.new()
	_picker_panel.add_child(_picker)
	right.add_child(_picker_panel)
	_note = UIKit.label("", 24, UIKit.GOLD)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_note)
	_rebuild()

func setup(arg: String) -> void:
	if arg.begins_with("tab:"):  # open on one kind's tab (screenshots)
		_tab = maxi(0, _kinds.find(arg.substr(4)))
		_rebuild()
	if arg.begins_with("hold:"):
		_target = int(arg.substr(5))
		_hold = true
		set_title("Hold a charm")
		if _target >= 0 and _target < party().size():
			header_right.text = "for %s" % party()[_target].display_name()
		_rebuild()
	if arg.begins_with("for:"):
		_target = int(arg.substr(4))
		set_title("Use item")
		if _target >= 0 and _target < party().size():
			header_right.text = "on %s" % party()[_target].display_name()
		_rebuild()

## The tabs to show, in KIND_ORDER: only kinds with something in them (a first-hour bag is three tabs, not
## eight), narrowed to charms when picking one to hold and to usable kinds when using on one party member.
static func tab_kinds(bag: Bag, items: ItemDB, hold := false, use_on := false) -> Array:
	var out := []
	for k in KIND_ORDER:
		if hold and k != "charm":
			continue
		if use_on and not hold and k not in USABLE:
			continue
		if items != null and not bag.items_of_kind(k, items).is_empty():
			out.append(k)
	return out

func _rebuild() -> void:
	_kinds = tab_kinds(_bag, Game.items, _hold, _target >= 0)
	_tab = clampi(_tab, 0, maxi(0, _kinds.size() - 1))
	_draw_tabs()
	_draw_list()
	_set_hint()

func _set_hint() -> void:
	var kind: String = _kinds[_tab] if _tab < _kinds.size() else ""
	var verb: String = {"heal": "Share", "charm": "Hold"}.get(kind, "Use")
	if _mode == "pick":
		set_hints([["confirm", "Give to this one" if kind == "charm" else "%s with this one" % verb if kind == "heal" else "Use on this one"], ["cancel", "Back"]])
	elif _kinds.size() > 1:
		set_hints([["leftright", "Switch tab"], ["confirm", verb], ["cancel", "Back"]])
	else:
		set_hints([["confirm", verb], ["cancel", "Back"]])

func _draw_tabs() -> void:
	UIKit.clear(_tabs_row)
	_tabs_row.add_child(UIKit.label("<", 26, UIKit.MUTED))
	for i in _kinds.size():
		var on := i == _tab
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.box(UIKit.HEATHER if on else Color("1d2230cc"), UIKit.CREAM if on else Color("4a4f5e"), 2, 8, 8))
		p.add_child(UIKit.label(UIKit.kind_name(_kinds[i]), 24, Color.WHITE if on else UIKit.MUTED))
		_tabs_row.add_child(p)
	_tabs_row.add_child(UIKit.label(">", 26, UIKit.MUTED))

func _draw_list() -> void:
	UIKit.clear(_list_col)
	_item_buttons.clear()
	if _kinds.is_empty():
		_list_col.add_child(UIKit.label("Nothing here but fluff.", 28, UIKit.MUTED))
		_show_desc("")
		return
	for id in _bag.items_of_kind(_kinds[_tab], Game.items):
		var it: Dictionary = Game.items.get_item(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 56)
		b.focus_entered.connect(func():
			Audio.sfx("cursor")
			_last_item = _item_buttons.find(b)
			_show_desc(id))
		b.pressed.connect(func():
			Audio.sfx("confirm")
			_item_pressed(id))
		b.focus_neighbor_left = NodePath(".")
		b.focus_neighbor_right = NodePath(".")
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 14
		h.offset_right = -14
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var n := UIKit.label(str(it.get("name", id)), 28)
		h.add_child(n)
		h.add_child(UIKit.fill())
		h.add_child(UIKit.label("x %d" % _bag.count(id), 26, UIKit.GOLD))
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		_list_col.add_child(b)
		_item_buttons.append(b)
	UIKit.wrap_focus(_item_buttons)
	_last_item = clampi(_last_item, 0, _item_buttons.size() - 1)
	UIKit.focus_later(_item_buttons[_last_item])

func _show_desc(id: String) -> void:
	UIKit.clear(_desc)
	if id == "":
		return
	var it: Dictionary = Game.items.get_item(id)
	_desc.add_child(UIKit.label(str(it.get("name", id)), 36))
	_desc.add_child(UIKit.chip(UIKit.kind_name(str(it.get("kind", ""))), Color("4a4f5e"), UIKit.CREAM, 18))
	var d := UIKit.label(str(it.get("desc", "")), 26)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_child(d)
	if str(it.get("effect_text", "")) != "":
		var fx := UIKit.label(str(it.effect_text), 22, UIKit.GOLD)
		fx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_desc.add_child(fx)
	_desc.add_child(UIKit.fill())
	if str(it.get("kind", "")) == "repel" and Repel.active(Game.data):
		_desc.add_child(UIKit.label("%d steps of lavender left" % Repel.steps_left(Game.data), 22, UIKit.GOLD))
	if str(it.get("kind", "")) == "meal" and Meals.active(Game.data) == id:
		var left := Meals.steps_left(Game.data)
		_desc.add_child(UIKit.label("Still working%s" % (" (%d steps left)" % left if left > 0 else ""), 22, UIKit.GOLD))
	var price := int(it.get("price", 0))
	if price > 0:
		var cur := Wallet.local(Game.data)  # what a shop here would give for it
		_desc.add_child(UIKit.label("Worth %s" % UIKit.money_text(MenuLogic.sell_price(Wallet.localise(price, cur)), cur), 22, UIKit.MUTED))

func _item_pressed(id: String) -> void:
	var it: Dictionary = Game.items.get_item(id)
	var kind := str(it.get("kind", ""))
	if id == "team_thermos":
		var off: bool = Game.data.flag("thermos_off") != true
		Game.data.set_flag("thermos_off", off)
		_note.text = "Team Thermos: off. Only the fighters get XP." if off else "Team Thermos: on. Everyone shares the XP."
		return
	if id == Postcards.ALBUM:  # Kit's postcards, to read again
		await open_child("postcard:album")
		return
	if kind == "repel":
		var r := Repel.use(Game.data, id, Game.items)
		Audio.sfx("confirm" if r.ok else "bump")
		_note.text = str(r.text)
		if r.ok:
			_rebuild_keep_note()
		return
	if kind == "meal":  # a dish: eaten by you, no one to pick
		var r := Meals.eat(Game.data, id, Game.items)
		Audio.sfx("heal" if r.ok else "bump")
		_note.text = str(r.text)
		if r.ok:
			_rebuild_keep_note()
		return
	if kind == "charm":
		if party().is_empty():
			_note.text = "Nobody to give it to."
			return
		if _target >= 0:
			_use(id, _target)
			return
		_pending = id
		_mode = "pick"
		_note.text = ""
		_open_picker()
		return
	if kind not in USABLE:
		_note.text = {"key": "That one's for keeping, not using.", "material": "That's for making things with, at a kitchen or a bench."}.get(kind, "Best saved for the right moment.")
		return
	if not bool(it.get("field", false)):
		_note.text = "That's one for battle."
		return
	if party().is_empty():
		_note.text = "Nobody to use it on."
		return
	if _target >= 0:
		_use(id, _target)
		return
	_pending = id
	_mode = "pick"
	_note.text = ""
	_open_picker()

func _open_picker(focus := 0) -> void:
	UIKit.clear(_picker)
	_pick_buttons.clear()
	for i in party().size():
		var c: Creature = party()[i]
		var b := UIKit.button("")
		b.custom_minimum_size = Vector2(0, 50)
		b.focus_entered.connect(func(): Audio.sfx("cursor"))
		b.pressed.connect(func():
			Audio.sfx("confirm")
			_use(_pending, i))
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 12
		h.offset_right = -12
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_theme_constant_override("separation", 10)
		var ic := AnimSprite.new()
		ic.show_species(c.species.id, "icon", 1, false, c.variant, c.form, c.sex)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
		h.add_child(UIKit.sex_mark(c, 20))
		h.add_child(UIKit.label(c.display_name(), 24))
		h.add_child(UIKit.fill())
		var hp := UIKit.hp_bar(c.hp, c.max_hp(), 90, 10)
		hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(hp)
		h.add_child(UIKit.label("%d/%d" % [c.hp, c.max_hp()], 20, UIKit.MUTED))
		for ch in h.get_children():
			ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		_picker.add_child(b)
		_pick_buttons.append(b)
	UIKit.wrap_focus(_pick_buttons)
	_picker_panel.visible = true
	UIKit.focus_later(_pick_buttons[clampi(focus, 0, _pick_buttons.size() - 1)])
	_set_hint()

func _close_picker() -> void:
	_mode = "list"
	_picker_panel.visible = false
	_set_hint()
	if not _item_buttons.is_empty():
		_item_buttons[clampi(_last_item, 0, _item_buttons.size() - 1)].grab_focus()

func _use(id: String, idx: int) -> void:
	var c: Creature = party()[idx]
	var r := _bag.give_charm(id, c) if Charms.is_charm(id) else _bag.use_on(id, c, Game.items)
	if r.has("evolve_to"):
		var old_name := c.display_name()
		var to_sp: Dictionary = Game.dex.get_species(str(r.evolve_to))
		Progression.evolve(c, to_sp)
		Game.data.mark_caught(str(to_sp.id))
		r["text"] = "%s evolved into %s!" % [old_name, to_sp.name]
		Audio.sfx("evolve")
	if r.get("ok", false) and not Charms.is_charm(id):
		TrainerStats.note_item(Game.data, id)
	_note.text = str(r.get("text", ""))
	if not r.has("evolve_to"):
		Audio.sfx("heal" if r.get("ok", false) else "bump")
	if _hold and r.get("ok", false):
		close(null)  # back to the Team screen with it held
		return
	if Charms.is_charm(id) and _mode == "pick":
		if r.get("ok", false):
			_rebuild_keep_note()
		_close_picker()
		return
	if _target >= 0:
		_rebuild()
		if r.get("ok", false) and (_kinds.is_empty() or _bag.count(id) == 0):
			_note.text += " That was the last one."
		return
	if _mode != "pick":
		return
	if r.get("ok", false):
		_rebuild_keep_note()
	if MenuLogic.stay_in_picker(r.get("ok", false), _bag.count(id)):
		_open_picker(idx)  # the picker shows HP, so redraw it; stay put so the next one is a single press
	else:
		_note.text += " That was the last one."
		_close_picker()

func _rebuild_keep_note() -> void:
	var n := _note.text
	_rebuild()
	_note.text = n

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	if _mode == "list" and _kinds.size() > 1:
		var d := 0
		if event.is_action_pressed("move_left"):
			d = -1
		elif event.is_action_pressed("move_right"):
			d = 1
		if d != 0:
			get_viewport().set_input_as_handled()
			_tab = MenuLogic.wrap_index(_tab, d, _kinds.size())
			_last_item = 0
			_note.text = ""
			Audio.sfx("cursor")
			_draw_tabs()
			_draw_list()
			_set_hint()  # "Share" food, "Hold" charms, "Use" the rest
			return
	super._input(event)

func _on_cancel() -> void:
	if _mode == "pick":
		Audio.sfx("cancel")
		_close_picker()
	else:
		close(null)
