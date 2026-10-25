extends MenuBase
## Pause menu: Team, Fieldbook, Bag, Wardrobe, Ark (once you've met a Sanctuary nurse), Journal, Almanac (every page of the book, Stats included), Map, Save, Settings and Close,
## with the Keeper card, the time and weather, and "Where next?" beside it.

const ROW_GAP := 4
const ROW_MIN := 42  # eleven rows (Wardrobe and Ark both in) still fit the panel; the label shrinks to 30px then
const ROW_MAX := 66

static var _last_entry := "Team"  # reopens on the entry you left it on (this session only)

var _buttons: Array = []
var _names: Array = []
var _info: VBoxContainer
var _next: VBoxContainer

func _build() -> void:
	set_title("Pause")
	set_hints([["confirm", "Choose"], ["cancel", "Close"]])
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 28)
	content.add_child(row)

	var left := UIKit.panel(Color("1d2230f0"), 14)
	left.custom_minimum_size = Vector2(380, 0)
	row.add_child(left)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", ROW_GAP)
	left.add_child(menu)
	var actions := {"Team": _open_team, "Fieldbook": _open_pedia, "Bag": _open_bag, "Wardrobe": _open_wardrobe, "Ark": _open_ark, "Journal": _open_journal, "Almanac": _open_almanac, "Map": _open_map,
		"Save": _save, "Settings": _open_settings, "Close": func(): close(null)}
	for nm in MenuLogic.pause_entries(MenuLogic.ark_unlocked(Game.data)):
		var b := make_button(nm, actions[nm])
		b.add_theme_font_size_override("font_size", 32)
		b.custom_minimum_size = Vector2(0, ROW_MIN)
		b.focus_entered.connect(func(): _last_entry = nm)
		menu.add_child(b)
		_trim_padding(b)  # once in the tree, so it sees the theme's boxes
		_buttons.append(b)
		_names.append(nm)
	menu.resized.connect(_size_rows.bind(menu))  # rows share the panel's height, however many there are
	UIKit.wrap_focus(_buttons)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var card := UIKit.panel(Color("1d2230f0"), 16)
	right.add_child(card)
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 4)
	card.add_child(_info)
	var next_card := UIKit.panel(Color("1d2230f0"), 14)
	next_card.size_flags_vertical = Control.SIZE_EXPAND_FILL  # takes what the Keeper card leaves; its words shrink to fit
	right.add_child(next_card)
	_next = VBoxContainer.new()
	_next.add_theme_constant_override("separation", 6)
	next_card.add_child(_next)
	_refresh()
	UIKit.focus_later(_button(_last_entry))

## The theme's button boxes without their top and bottom padding: the row height alone sets how tall a row is.
func _trim_padding(b: Button) -> void:
	for state in ["normal", "hover", "focus", "pressed", "hover_pressed", "disabled"]:
		var sb := b.get_theme_stylebox(state)
		if sb == null:
			continue
		sb = sb.duplicate()
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
		b.add_theme_stylebox_override(state, sb)

## Gives each row an equal share of the list's height (between ROW_MIN and ROW_MAX), so nine fit as well as eight.
func _size_rows(menu: VBoxContainer) -> void:
	var h := MenuLogic.row_height(menu.size.y, _buttons.size(), ROW_GAP, ROW_MIN, ROW_MAX)
	for b in _buttons:
		b.custom_minimum_size.y = h
		b.add_theme_font_size_override("font_size", 32 if h >= 46 else 30)

func _button(nm: String) -> Button:
	var i := _names.find(nm)
	return _buttons[i if i >= 0 else 0]

func _refresh() -> void:
	UIKit.clear(_info)
	var d: GameStateData = Game.data
	_info.add_child(UIKit.fit_label(d.player_name, 640, 38, 28))
	_info.add_child(_stat("Money", UIKit.money_text(d.money)))
	if Wallet.had_euros(d):  # once you've been paid in euros, both purses
		_info.add_child(_stat("Euros", UIKit.money_text(d.euros, Wallet.EUR)))
	for line in Wallet.foreign_lines(d):  # any overseas money still in your pockets
		_info.add_child(_stat(str(line[0]), str(line[1])))
	_info.add_child(_stat("Play time", MenuLogic.play_time(d.play_seconds)))
	_info.add_child(_stat("Fieldbook", "%d seen, %d caught" % [d.seen.size(), d.caught.size()]))
	var wod := LangLessons.word_of_day(d, Langs.code_for(d.zone_id, ZoneIndex.get_index()), d.day_count) if Settings.languages_on() else {}
	if not wod.is_empty():  # the word of the day (4.5): from what you've learnt, or a taster of the local language
		var wl := UIKit.fit_label("%s word of the day: %s (%s), %s" % [LangLessons.lang_name(str(wod.code)), str(wod.word.local),
			str(wod.word.say), str(wod.word.english)], 640, 22, 16, Langs.LOCAL_INK)
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_info.add_child(wl)
	var basket := PairingLogic.basket_line(d)  # a pairing in a basket or bundle, walking off its steps (see Breeding)
	if basket != "":
		var bl := UIKit.label(basket, 24, UIKit.GOLD)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_info.add_child(bl)
	header_right.text = _now()  # the time of day and the weather, up in the corner
	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 8)
	badges.add_child(UIKit.label("Badges", 26, UIKit.MUTED))
	badges.add_child(UIKit.spacer(0, 8))
	for i in 10:
		var earned := i < d.badges.size()
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(28, 28)
		dot.color = UIKit.GOLD if earned else Color("2c3446")
		badges.add_child(dot)
	badges.add_child(UIKit.label("%d / 10" % d.badges.size(), 26))
	_info.add_child(badges)
	var team := HBoxContainer.new()
	team.add_theme_constant_override("separation", 6)
	for c in d.party:
		var s := AnimSprite.new()
		s.show_species(c.species.id, "icon", 2, false, c.variant, c.form, c.sex)
		if c.is_fainted():
			s.modulate = Color(0.5, 0.5, 0.5)
		team.add_child(s)
	_info.add_child(team)
	_refresh_next()

## "Where next?", Today's Walk and, after the ending, who's up for a rematch today.
func _refresh_next() -> void:
	UIKit.clear(_next)
	var d: GameStateData = Game.data
	var o := MenuLogic.next_objective(d, Game.dex.core_ids().size())
	if not o.is_empty():
		var head := HBoxContainer.new()
		head.add_child(UIKit.label("Still to do" if o.get("postgame", false) else "Where next?", 22, UIKit.MUTED))
		head.add_child(UIKit.fill())
		head.add_child(UIKit.label(Jobs.summary(d, Game.dex), 20, UIKit.GOLD))  # odd jobs off the noticeboards (the Almanac lists them)
		_next.add_child(head)
	var wb := UIKit.words_box([24, 22, 20, 18], 6)  # however much there is to say, it shrinks to fit the card
	_next.add_child(wb[0])
	var town := str(d.flag("last_town")) if d.flag("last_town") != null else ""
	var colours := {"story": UIKit.CREAM, "quest": Color("c9b3e0"), "here": UIKit.GOLD, "festival": UIKit.GOLD, "deed": UIKit.GOLD, "basket": UIKit.GOLD}
	for s in WhereNext.suggest(d, Game.dex.core_ids().size(), town, {"show": Tournament.today(d)}):  # up to three, the story first
		UIKit.add_words(wb[1], "- " + str(s.text), 0 if s.kind == "story" else -2, colours.get(s.kind, UIKit.CREAM))
	var walk := TodaysWalk.summary(d, Game.dex)
	if walk != "":
		UIKit.add_words(wb[1], walk, -6, UIKit.MUTED)
	var ready := MenuLogic.rematches_ready(d)
	if d.flag("game_complete") == true:
		UIKit.add_words(wb[1], "Rematches today: " + (", ".join(ready) if not ready.is_empty() else "all fought, back tomorrow"), -2, UIKit.GOLD)

## The time of day and the weather here: encounters depend on both.
func _now() -> String:
	var ow = Router.overworld
	var weather := ""
	var indoors := false
	if ow != null and is_instance_valid(ow) and ow.zone != null:
		weather = str(ow.weather)
		indoors = ow.zone.kind == "interior"
	elif Game.args.get("weather", "") != "":
		weather = str(Game.args.weather)
	var clock := Timezones.clock_text(Game.data, Game.data.tz_zone) if Timezones.is_abroad(Game.data.tz_zone) else ""
	return MenuLogic.now_text(Game.local_minutes(), weather, indoors, clock)

func _stat(k: String, v: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_child(UIKit.label(k, 26, UIKit.MUTED))
	h.add_child(UIKit.fill())
	h.add_child(UIKit.label(v, 28))
	return h

func _open_team() -> void:
	await open_child("party")
	_after_child("Team")

func _open_pedia() -> void:
	await open_child("pedia")
	_after_child("Fieldbook")

func _open_bag() -> void:
	await open_child("bag")
	_after_child("Bag")

func _open_wardrobe() -> void:
	await open_child("wardrobe")
	_after_child("Wardrobe")

func _open_ark() -> void:
	await open_child("ark")
	_after_child("Ark")

func _open_journal() -> void:
	await open_child("quests")
	_after_child("Journal")

func _open_almanac() -> void:
	await open_child("almanac")
	_after_child("Almanac")

func _open_settings() -> void:
	await open_child("settings")
	_after_child("Settings")

func _after_child(nm: String) -> void:
	_refresh()
	_button(nm).grab_focus()

func _save() -> void:
	await open_child("save:save")
	_after_child("Save")

func _open_map() -> void:
	var r = await open_child("map")
	if r is Dictionary and r.has("fly"):
		close(r)
		return
	_after_child("Map")
