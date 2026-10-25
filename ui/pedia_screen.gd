extends MenuBase
## Creaturepedia ("Fieldbook"): every species in Dex order. Unseen is "???", seen is a silhouette, caught is the full entry.
## Left/Right (or the pad's shoulder buttons) jump ten entries; Run cycles the filter: All, Caught, Seen, Rumours
## (local gossip about creatures still to catch, and the region stamps: see RumoursTab).
## The Bike key (or the Cry button) plays the creature's cry, once you have met one (see Cries).

const ZONE_DIR := "res://data/zones"
static var _habitats: Dictionary = {}
static var _habitats_loaded := false
static var _last_id := ""      # reopens on the entry you left it on (this session only)
static var _filter := "all"    # all | caught | seen | rumours | studbook, also kept for the session

const PAGE := 10
const MAX_PLACES := 3  # the rest are on the map, so a long list can't push the entry off the bottom
const FILTER_NAMES := {"all": "All", "caught": "Caught", "seen": "Seen", "rumours": "Rumours", "studbook": "Stud Book", "casebook": "Casebook", "words": "Words of the Isles"}

var _all: Array = []           # every species id, Dex order
var _no: Dictionary = {}       # id -> Dex number as shown: "045", or "A01" in the appendix after the 200
var _core := 0                 # how many are in the Fieldbook proper (the appendix is a bonus)
var _extra := 0                # how many in the appendix
var _hybrids := 0              # how many hybrids the book lists (none until you have met one)
var _crosses := 0              # how many crossbreeds you have bred (core/crossbreeds.gd), C01 onwards
var _ids: Array = []           # the ids the current filter shows
var _cur := 0
var _scroll: ScrollContainer
var _list_col: VBoxContainer
var _detail: VBoxContainer
var _buttons: Array = []
var _rumours: Array = []       # the Rumours tab's rows, when it's showing
const WORD_SIZES := [25, 23, 21, 19, 17, 16, 15]  # the body text's size, biggest first, until the entry fits
const WORD_SEP := 6  # between the lines below the picture: snug, so the longest entries fit at 1280x720
const FACT_INK := Color("d8cfb4")  # the fact and the real-life note, a shade quieter than the entry's text

func _build() -> void:
	set_title("Fieldbook")
	_all = Game.dex.ids()
	for id in _all:
		if Dex.in_appendix(id):
			_extra += 1
			_no[id] = "A%02d" % _extra
		else:
			_core += 1
			_no[id] = "%03d" % _core
	var dd: GameStateData = Game.data  # the Hybrids section, H01 onwards: shown once you have bred or met one
	var met := Game.dex.hybrid_ids().any(func(id): return dd.seen.has(id) or dd.caught.has(id))
	if met:
		for id in Game.dex.hybrid_ids():
			_hybrids += 1
			_no[id] = "H%02d" % _hybrids
			_all.append(id)
	for id in Crossbreeds.met(dd):  # the Crossbreeds section: only the ones you have bred, since they are derived
		_crosses += 1
		_no[id] = "C%02d" % _crosses
		_all.append(id)
	set_hints([["updown", "Browse"], ["shoulders", "Jump 10"], ["run", "Filter"], ["bike", "Cry"], ["confirm", "Map"], ["cancel", "Back"]])
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 22)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 10)
	lp.custom_minimum_size = Vector2(440, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lp.add_child(sc)
	_scroll = sc
	_list_col = VBoxContainer.new()
	_list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_col.add_theme_constant_override("separation", 4)
	sc.add_child(_list_col)
	var dp := UIKit.panel(Color("1d2230f0"), 20)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(dp)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 10)
	dp.add_child(_detail)
	_fill_list()

## (Re)builds the list for the current filter and focuses the remembered entry, or the first.
func _fill_list() -> void:
	var d: GameStateData = Game.data
	if _filter == "rumours":
		_rumours = RumoursTab.entries()
		_ids = _rumours.map(func(r): return str(r.species))
	elif _filter == "studbook":
		_ids = StudBookTab.ids()
	elif _filter == "casebook":
		_ids = CasebookTab.ids()
	elif _filter == "words":
		_ids = WordsTab.ids()
	else:
		_ids = MenuLogic.fieldbook_filter(_all, d.seen, d.caught, _filter)
	header_right.text = "%s    Seen %d    Caught %d / %d" % [FILTER_NAMES[_filter], d.seen.size(), FieldbookGoals.caught_count(d), _core]
	var extra_seen := d.seen.keys().filter(func(id): return Dex.in_appendix(id)).size()
	if extra_seen > 0:  # the appendix shows up once you've met something from it
		header_right.text += "    Appendix %d / %d" % [d.caught.keys().filter(func(id): return Dex.in_appendix(id)).size(), _extra]
	if _hybrids > 0:
		header_right.text += "    Hybrids %d / %d" % [d.caught.keys().filter(func(id): return Dex.is_hybrid(id)).size(), _hybrids]
	if _crosses > 0:
		header_right.text += "    Crossbreeds %d" % _crosses
	UIKit.clear(_list_col)
	_buttons.clear()
	for i in _ids.size():
		var b := _rumour_button(i) if _filter == "rumours" else (_book_button(i) if _filter in ["studbook", "casebook", "words"] else _entry_button(i))
		_list_col.add_child(b)
		_buttons.append(b)
	UIKit.wrap_focus(_buttons)
	if _buttons.is_empty():
		UIKit.clear(_detail)
		var none := UIKit.label("Nothing here yet. Get out there with a snare.", 26, UIKit.MUTED)
		_list_col.add_child(none)
		return
	_cur = maxi(0, _ids.find(_last_id))
	UIKit.focus_later(_buttons[_cur])
	_scroll_to_later(_buttons[_cur])

## follow_focus can't scroll before the list has been laid out, so reopening deep in the list scrolls once it has.
func _scroll_to_later(b: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(b) and b.is_inside_tree():
		_scroll.ensure_control_visible(b)

## setup("<species id>") opens on that entry (the filter goes back to All if it would hide it);
## setup("rumours") or setup("stamps") opens the Rumours tab.
func setup(arg: String) -> void:
	if arg in ["studbook", "casebook", "words"]:  # straight to the Stud Book, Casebook or Words tab
		_filter = arg
		_fill_list()
		return
	if arg in ["rumours", "stamps"]:  # straight to the Rumours tab (on its first rumour, or on the stamps)
		_filter = "rumours"
		_fill_list()
		if arg == "rumours" and _ids.size() > 1:
			_last_id = _ids[1]
			_fill_list()
		return
	if arg == "" or not _all.has(arg):
		return
	_last_id = arg
	if not _ids.has(arg):
		_filter = "all"
	_fill_list()

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	var d := 0
	if event.is_action_pressed("move_left") or _shoulder(event, JOY_BUTTON_LEFT_SHOULDER):
		d = -PAGE
	elif event.is_action_pressed("move_right") or _shoulder(event, JOY_BUTTON_RIGHT_SHOULDER):
		d = PAGE
	if d != 0:
		get_viewport().set_input_as_handled()
		if not _buttons.is_empty():
			_buttons[MenuLogic.page_index(_cur, d, _buttons.size())].grab_focus()
		return
	if event.is_action_pressed("bike"):
		get_viewport().set_input_as_handled()
		if not _ids.is_empty() and _filter not in ["studbook", "casebook", "words"]:
			play_cry(_ids[_cur])
		return
	if event.is_action_pressed("run"):
		get_viewport().set_input_as_handled()
		_filter = MenuLogic.next_filter(_filter, StudBookTab.visible(Game.data), CasebookTab.visible(Game.data), WordsTab.visible(Game.data))
		Audio.sfx("cursor")
		_fill_list()
		return
	super._input(event)

## A pad shoulder press, unless the player has bound that button to something else.
func _shoulder(event: InputEvent, button: int) -> bool:
	if not (event is InputEventJoypadButton) or not event.pressed or event.button_index != button:
		return false
	return not InputSetup.ACTIONS.any(func(a): return event.is_action(a))

## Heard it in the wild (seen or caught): play its cry. True if it played.
func play_cry(id: String) -> bool:
	if state_of(id) == "unseen":
		return false
	Audio.cry(Game.dex.get_species(id), 0.0)
	return true

func state_of(id: String) -> String:
	if Game.data.caught.has(id):
		return "caught"
	return "seen" if Game.data.seen.has(id) else "unseen"

func _entry_button(i: int) -> Button:
	var id: String = _ids[i]
	var st := state_of(id)
	var sp: Dictionary = Game.dex.get_species(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 58)
	b.focus_entered.connect(func():
		Audio.sfx("cursor")
		_cur = i
		_last_id = id
		_show(id))
	b.pressed.connect(func():
		if state_of(id) == "unseen":
			return
		Audio.sfx("confirm")
		await open_child("map:species:" + id)
		b.grab_focus())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var no := UIKit.label(str(_no.get(id, "%03d" % (i + 1))), 22, UIKit.MUTED)
	no.custom_minimum_size = Vector2(52, 0)
	h.add_child(no)
	var ic := AnimSprite.new()
	ic.show_species(id if st != "unseen" else "", "icon", 1, st != "caught")
	if st == "unseen":
		ic.modulate = Color(1, 1, 1, 0.35)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	h.add_child(UIKit.label(str(sp.get("name", id)) if st != "unseen" else "???", 28, UIKit.CREAM if st != "unseen" else UIKit.MUTED))
	h.add_child(UIKit.fill())
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(16, 16)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if st == "caught":
		dot.add_theme_stylebox_override("panel", UIKit.box(UIKit.GOLD, UIKit.GOLD.darkened(0.4), 2, 8, 0))
	elif st == "seen":
		dot.add_theme_stylebox_override("panel", UIKit.box(Color(0, 0, 0, 0), UIKit.MUTED, 2, 8, 0))
	else:
		dot.visible = false
	h.add_child(dot)
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

## A Stud Book tab row: an idea (or the Crosses log).
func _book_button(i: int) -> Button:
	var id := str(_ids[i])
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 58)
	b.focus_entered.connect(func():
		Audio.sfx("cursor")
		_cur = i
		_last_id = id
		if _filter == "casebook":
			CasebookTab.show(id, _detail)
		elif _filter == "words":
			WordsTab.show(id, _detail)
		else:
			StudBookTab.show(id, _detail))
	if _filter == "words":
		b.pressed.connect(func():  # revise the language (4.5)
			if not WordsTab.can_revise(id):
				return
			Audio.sfx("confirm")
			await open_child("lang:review:" + id)
			WordsTab.show(id, _detail)
			b.grab_focus())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	h.add_theme_constant_override("separation", 10)
	b.add_child(h)
	if _filter == "casebook":
		CasebookTab.row(id, h)
	elif _filter == "words":
		WordsTab.row(id, h)
	else:
		StudBookTab.row(id, h)
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

## A Rumours tab row: the stamps, or one bit of gossip (Confirm opens the map once you've seen the creature).
func _rumour_button(i: int) -> Button:
	var r: Dictionary = _rumours[i]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 58)
	b.focus_entered.connect(func():
		Audio.sfx("cursor")
		_cur = i
		_last_id = str(r.species)
		RumoursTab.show(r, _detail))
	b.pressed.connect(func():
		if str(r.species) == "" or state_of(str(r.species)) == "unseen":
			return
		Audio.sfx("confirm")
		await open_child("map:species:" + str(r.species))
		b.grab_focus())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	h.add_theme_constant_override("separation", 10)
	b.add_child(h)
	RumoursTab.row(r, h)
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _show(id: String) -> void:
	UIKit.clear(_detail)
	var st := state_of(id)
	var sp: Dictionary = Game.dex.get_species(id)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	_detail.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(Color("2c3446"), Color("4a4f5e"), 2, 8, 6))
	top.add_child(frame)
	var s := AnimSprite.new()
	s.show_species(id if st != "unseen" else "", "front", 2, st == "seen")
	if st == "unseen":
		s.modulate = Color(1, 1, 1, 0.35)
	frame.add_child(s)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	info.add_child(UIKit.label(("Hybrid %s" if Dex.is_hybrid(id) else "Crossbreed %s" if Crossbreeds.is_id(id) else "Appendix %s" if Dex.in_appendix(id) else "No. %s") % str(_no.get(id, "")), 22, UIKit.MUTED))
	info.add_child(UIKit.label(str(sp.get("name", id)) if st != "unseen" else "???", 40))
	if st != "unseen":
		var type_row := HBoxContainer.new()  # the types, and the Cry button beside them (the Bike key does it too)
		type_row.add_theme_constant_override("separation", 12)
		type_row.add_child(UIKit.types_row(sp.get("types", []), 22))
		var cry := UIKit.pill_button("Cry", 20)
		cry.focus_mode = Control.FOCUS_NONE  # the list keeps focus; this is for the mouse
		cry.tooltip_text = "Play its cry (%s)" % UIKit.key_for("bike")
		cry.pressed.connect(func(): play_cry(id))
		type_row.add_child(cry)
		info.add_child(type_row)
		var kid := Knacks.id_for_species(sp)
		var knack_row := HBoxContainer.new()  # the line's knack once caught, and any uncommon coats
		knack_row.add_theme_constant_override("separation", 16)
		if st == "caught" and kid != "":  # 2.0: the knack, here so the entry keeps its height
			var kl := UIKit.label("Knack: %s" % Knacks.name_of(kid), 21, UIKit.GOLD)
			kl.tooltip_text = Knacks.desc_of(kid)
			kl.mouse_filter = Control.MOUSE_FILTER_PASS
			kl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			knack_row.add_child(kl)
		knack_row.add_child(CoatArt.swatch_row(Game.data, id))
		if knack_row.get_child_count() > 1 or knack_row.get_child(0).get_child_count() > 0:
			info.add_child(knack_row)
		else:
			knack_row.free()
		for fm in Forms.listing(Game.data, id):  # regional forms: where each is found, and its fact once met
			var where := Forms.where(id, fm.form, FieldbookGoals.region_name)
			var mark := "caught" if fm.status == "caught" else ("seen" if fm.status == "seen" else "not yet met")
			var fl := UIKit.label("Form: %s, found in %s (%s)" % [fm.name, where, mark], 19, UIKit.GOLD if fm.status == "caught" else UIKit.MUTED)
			fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fl.custom_minimum_size = Vector2(300, 0)
			if fm.status != "":
				fl.tooltip_text = Forms.fact_of(id, fm.form)
				fl.mouse_filter = Control.MOUSE_FILTER_PASS
			info.add_child(fl)
	else:
		var u := UIKit.label("Not met yet. Out there somewhere, being elusive.", 22, UIKit.MUTED)
		u.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		u.custom_minimum_size = Vector2(300, 0)
		info.add_child(u)
	if st == "unseen":
		return
	var evo := evolution_line(sp)
	if evo != "":
		var el := UIKit.label(evo, 21, UIKit.GOLD)
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		el.custom_minimum_size = Vector2(300, 0)
		info.add_child(el)
	# The words below the picture shrink to fit, and scroll if even the smallest size can't (see UIKit.fit_block).
	var wb := UIKit.words_box(WORD_SIZES, WORD_SEP)
	_detail.add_child(wb[0])
	var words: VBoxContainer = wb[1]
	if Dex.is_hybrid(id):  # never found in the wild: what it is, and whether it can have young of its own
		var h: Dictionary = Genetics.hybrids().get(id, {})
		var how: String = {"real": "A real cross.", "folklore": "Folklore: they say.", "invented": "A game invention."}.get(str(h.get("real", "")), "")
		UIKit.add_words(words, "Bred, never found. %s %s" % [how, "Fertile." if h.get("fertile", true) == true else "Cannot have young."], -4, FACT_INK)
	elif Crossbreeds.is_id(id):  # each parent shown, and the biology of why it could happen
		UIKit.add_words(words, Crossbreeds.parents_line(sp), -4, FACT_INK)
	else:
		UIKit.add_words(words, found_in(MenuLogic.habitats(habitat_index(), id)), -4, FACT_INK)
	var dex: Dictionary = sp.get("dex", {})
	if st == "caught":
		UIKit.add_words(words, str(dex.get("text", "")), 0)
		UIKit.add_words(words, "Did you know?", -1, UIKit.GOLD)
		UIKit.add_words(words, str(dex.get("fact", "")), -2, FACT_INK)
		add_real_life(words, sp)
		add_sexes(words, Game.data, id)
		if Crossbreeds.is_id(id):
			UIKit.add_words(words, Crossbreeds.LESSON, -3, UIKit.MUTED)
	else:
		UIKit.add_words(words, "Spotted, but it didn't hang around. Catch one to fill in the rest of the entry.", 0, UIKit.MUTED)

## The teaching lines under the fact, part of the reward for catching one (docs/design/fieldbook_teaching.md):
## "In real life" and a true note about the animal, plant or legend behind the creature, then its name in Welsh,
## Irish and Scottish Gaelic in the warm ink of signs and town banners. Either is left out when the species has
## nothing to say, so a creature based on a place or a machine shows no empty slot. Returns the labels added.
static func add_real_life(words: VBoxContainer, sp: Dictionary) -> Array:
	var added := []
	var real := str(sp.get("real", "")).strip_edges()
	if real != "":
		added.append(UIKit.add_words(words, "In real life", -1, UIKit.GOLD))
		added.append(UIKit.add_words(words, real, -2, FACT_INK))
	var names = sp.get("names", {})
	var line := MenuLogic.fieldbook_names_line(names if names is Dictionary else {})
	if line != "":
		var nl := UIKit.add_words(words, line, -3, Langs.LOCAL_INK)
		nl.tooltip_text = MenuLogic.NAMES_SEP.join(Langs.CREATURE_NAME_CODES.map(func(c): return str(Langs.NAMES.get(c, c))))
		nl.mouse_filter = Control.MOUSE_FILTER_PASS
		added.append(nl)
	return added

## "Males and females": one true line on how the sexes of a species differ, with the two signs lit for the ones
## you have met ("Seen both" when you have). Nothing for a species that has no note. Returns the controls added.
static func add_sexes(words: VBoxContainer, data: GameStateData, id: String) -> Array:
	var added := []
	var note := Sexes.note(id)
	if note == "":
		return added
	added.append(UIKit.add_words(words, "Males and females", -1, UIKit.GOLD))
	added.append(UIKit.add_words(words, note, -2, FACT_INK))
	var met := Sexes.seen_sexes(data, id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for sx in ["m", "f"]:
		var mk := SexMark.make(sx, 22)
		mk.modulate = Color.WHITE if sx in met else Color(1, 1, 1, 0.25)
		row.add_child(mk)
	var status := "Seen both" if met == "mf" else ("Seen the male, not yet the female" if met == "m" else ("Seen the female, not yet the male" if met == "f" else "Neither met yet"))
	row.add_child(UIKit.label(status, 18, UIKit.GOLD if met == "mf" else UIKit.MUTED))
	words.add_child(row)
	added.append(row)
	return added

## "Found in: Dee Valley, Ogwen and 2 more": the first few of a species' habitat labels (the rest are on the map).
static func found_in(zones: Array) -> String:
	if zones.is_empty():
		return "Found in: somewhere secret"
	var where := ", ".join(zones.slice(0, MAX_PLACES))
	if zones.size() > MAX_PLACES:
		where += " and %d more" % (zones.size() - MAX_PLACES)
	return "Found in: " + where

## "Evolves into X at Lv 20" for a species; the target's name stays hidden until you've seen one.
static func evolution_line(sp: Dictionary) -> String:
	var evo = sp.get("evolves")
	if not (evo is Dictionary):
		return ""
	var to := str(evo.get("to", ""))
	var target := ""
	if Game.data.seen.has(to) or Game.data.caught.has(to):
		target = str(Game.dex.get_species(to).get("name", ""))
	var item := ""
	if evo.has("item") and Game.items != null:
		item = str(Game.items.get_item(str(evo.item)).get("name", ""))
	var zone_names := {}
	if evo.has("zone"):
		for z in (evo.zone if evo.zone is Array else [evo.zone]):
			var zd = JsonUtil.read("%s/%s.json" % [ZONE_DIR, str(z)])
			if zd is Dictionary and zd.has("name"):
				zone_names[str(z)] = str(zd.name)
	return MenuLogic.evolution_text(evo, target, item, zone_names)

## species id -> "Zone (time, weather)" labels, scanned once from data/zones/*.json.
static func habitat_index() -> Dictionary:
	if not _habitats_loaded:
		var zones := []
		for path in JsonUtil.list_json(ZONE_DIR):
			var z = JsonUtil.read(path)
			if z is Dictionary and str(z.get("id", "")) != "testbed":  # the dev zone isn't a real place
				zones.append(z)
		_habitats = MenuLogic.habitat_labels(zones)
		_habitats_loaded = true
	return _habitats
