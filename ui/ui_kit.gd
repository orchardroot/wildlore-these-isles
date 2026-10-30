class_name UIKit
extends RefCounted
## Small widget builders shared by every menu, so they all look like one game.

const CREAM := Color("f2e8cf")
const MUTED := Color("a9a294")
const HEATHER := Color("9b6fb0")
const SLATE := Color("1d2230")
const GOLD := Color("e8c872")
const STATUS_COLOURS := {
	"soaked": Color("4a90d9"), "chilled": Color("86d4e0"), "muddled": Color("c9a33c"),
	"hexed": Color("8e6fbf"), "stung": Color("c24a3e"), "asleep": Color("7d7f8a"),
}

static func box(bg: Color, border := Color(0, 0, 0, 0), bw := 0, radius := 6, margin := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.anti_aliasing = false
	return s

static func label(text: String, size := 28, colour := CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", Access.scaled(size, Settings.text_size))
	l.add_theme_color_override("font_color", colour)
	return l

## The largest font size from `big` down to `small` at which `text` fits in `width` px on one line
## (`small` if nothing does). For names and hint bars that must never widen a panel.
static func fit_size(text: String, width: float, big: int, small: int) -> int:
	var f: Font = ThemeDB.fallback_font  # the game's font (ui/theme.tres sets no other)
	for s in range(big, small - 1, -1):
		if f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x <= width:
			return s
	return small

## A label that shrinks its font (down to `small`) so `text` fits `width` on one line.
static func fit_label(text: String, width: float, big := 28, small := 18, colour := CREAM) -> Label:
	var l := label(text, fit_size(text, width, big, small), colour)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l

## A block of wrapped labels that must fit `box` (a ScrollContainer, as a fallback for the very longest): sets the
## biggest body size from `sizes` (biggest first) at which they all fit. `words` holds [label, size offset, optional]
## entries, e.g. a heading one size up from the body; optional ones (a "Did you know?") are left out before the
## text gets any smaller than the last size. `sep` is the box's separation.
static func fit_block(words: Array, box: Control, sizes: Array, sep := 8) -> void:
	if not is_instance_valid(box) or box.size.y <= 0 or words.is_empty():
		return
	var w := box.size.x - 16  # room for a scroll bar, so measuring never promises a fit that then wraps once more
	var body: int = sizes[sizes.size() - 1]
	var keep_all := false
	for size in sizes:
		if _block_height(words, w, size, sep, true) <= box.size.y:
			body = size
			keep_all = true
			break
	if not keep_all:
		for size in sizes:
			body = size
			if _block_height(words, w, size, sep, false) <= box.size.y:
				break
	for e in words:
		if is_instance_valid(e[0]):
			e[0].add_theme_font_size_override("font_size", body + e[1])
			e[0].visible = keep_all or not (e.size() > 2 and e[2])

static func _block_height(words: Array, w: float, size: int, sep: int, with_optional: bool) -> float:
	var f: Font = ThemeDB.fallback_font
	var h := -float(sep)
	for e in words:
		if not with_optional and e.size() > 2 and e[2]:
			continue
		var fs: int = size + e[1]
		var tall := f.get_multiline_string_size(e[0].text, HORIZONTAL_ALIGNMENT_LEFT, w, fs).y
		var lines := maxi(1, roundi(tall / f.get_height(fs)))
		h += tall + (lines - 1) * 3 + sep + 2  # the theme's line spacing, and a shadow pixel or two
	return h

## A ScrollContainer of wrapped words that shrink to fit it (see fit_block): returns [scroll, column].
## Add labels with add_words(); the fit runs once laid out and again whenever the box resizes.
static func words_box(sizes: Array, sep := 8) -> Array:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", sep)
	sc.add_child(col)
	var words: Array = []
	col.set_meta("words", words)
	var fit := func(): fit_block(words, sc, sizes, sep)
	sc.resized.connect(fit)
	sc.ready.connect(func(): fit.call_deferred())
	col.set_meta("sizes", sizes)
	return [sc, col]

## A wrapped line in a words_box column, `offset` sizes from the body text; `optional` lines go first if space is short.
static func add_words(col: VBoxContainer, text: String, offset := 0, colour := CREAM, optional := false) -> Label:
	var sizes: Array = col.get_meta("sizes")
	var l := label(text, sizes[0] + offset, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(l)
	col.get_meta("words").append([l, offset, optional])
	return l

static func spacer(h := 0, w := 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	return c

static func fill() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

static func panel(bg := Color("1d2230f0"), margin := 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, CREAM, 2, 8, margin))
	return p

## A rounded coloured tag: types, statuses, kinds.
static func chip(text: String, bg: Color, fg := Color("f8f1dc"), size := 20, glyph_type := "") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, bg.darkened(0.35), 2, 10, 5))
	var l := label(text.to_upper(), size, fg)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if glyph_type != "":
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 5)
		h.add_child(TypeGlyph.make(glyph_type, fg, maxi(12, mini(16, size - 4))))
		h.add_child(l)
		p.add_child(h)
	else:
		p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p

## The male or female sign for a creature (see ui/sex_mark.gd); an invisible nothing for a kindred without sexes.
static func sex_mark(c: Creature, size := 22) -> SexMark:
	return SexMark.make(c.sex if c != null else "", size)

## "Male" / "Female" / "" for a creature, for words beside the sign.
static func sex_word(c: Creature) -> String:
	return Sexes.word_of(c) if c != null else ""

static func type_chip(t: String, size := 20) -> PanelContainer:
	return chip(t, TypeColours.colour(t), TypeColours.text_colour(t), size, t)

static func status_chip(status: String, size := 18) -> Control:
	if status == "":
		return null
	return chip(status, STATUS_COLOURS.get(status, MUTED), Color("f8f1dc"), size)

static func types_row(types: Array, size := 20) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for t in types:
		h.add_child(type_chip(str(t), size))
	return h

static func hp_bar(hp: int, max_hp: int, width := 200, height := 14) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.min_value = 0
	b.max_value = maxi(1, max_hp)
	b.value = clampi(hp, 0, max_hp)
	b.custom_minimum_size = Vector2(width, height)
	b.add_theme_stylebox_override("background", box(Color("0d0f15"), CREAM, 2, 3, 0))
	b.add_theme_stylebox_override("fill", box(TypeColours.hp_colour(MenuLogic.hp_band(hp, max_hp)), Color(0, 0, 0, 0), 0, 3, 0))
	return b

## Trims a button's padding so long lists fit: transparent at rest, a soft fill and heather outline when focused.
static func compact(b: Button, margin := 4) -> void:
	b.add_theme_stylebox_override("normal", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 4, margin))
	var on := box(Color("2f3548"), HEATHER, 2, 4, margin)
	for state in ["hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, on)

static func button(text: String, min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(min_w, 52)
	return b

## A small framed button for the mouse beside other content (the Fieldbook's Cry): framed at rest, so it reads as a
## button, and lit the same heather as every focused button when hovered or pressed.
static func pill_button(text: String, size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", Access.scaled(size, Settings.text_size))
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var rest := box(Color("2c3446"), Color("5a5f6e"), 2, 12, 4)
	rest.content_margin_left = 14
	rest.content_margin_right = 14
	var on := box(Color("2f3548"), HEATHER, 2, 12, 4)
	on.content_margin_left = 14
	on.content_margin_right = 14
	b.add_theme_stylebox_override("normal", rest)
	b.add_theme_stylebox_override("disabled", rest)
	for state in ["hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, on)
	return b

## Makes the first and last of a vertical run of controls loop round on up/down.
static func wrap_focus(items: Array) -> void:
	if items.size() < 2:
		return
	var first: Control = items[0]
	var last: Control = items[items.size() - 1]
	first.focus_neighbor_top = first.get_path_to(last)
	last.focus_neighbor_bottom = last.get_path_to(first)

static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

static func kind_name(kind: String) -> String:
	return {"heal": "Healing", "meal": "Dishes", "cure": "Remedies", "revive": "Revivals", "pp": "Pudding", "snare": "Snares",
		"repel": "Sachets", "evo": "Curios", "curio": "Bric-a-brac", "charm": "Charms", "key": "Key Items", "material": "Materials", "fish": "Fish", "produce": "Produce", "wear": "Clothes", "chapbook": "Chapbooks"}.get(kind, kind.capitalize())

## "£1,234", or in euros with cur "eur" (see Wallet).
static func money_text(n: int, cur := "gbp") -> String:
	return Wallet.fmt(absi(n), cur)

## Focuses a control next frame, if it is still around by then.
## (A weak reference, because a lambda capturing a freed node is itself an engine error.)
static func focus_later(c: Control) -> void:
	var ref: WeakRef = weakref(c)
	(func():
		var n = ref.get_ref()
		if n != null and n.is_inside_tree() and n.is_visible_in_tree():
			n.grab_focus()).call_deferred()

## Prompt text for the current device and bindings, e.g. hint([["confirm", "Choose"], ["cancel", "Back"]]).
## Also: "menu", "run", "updown", "leftright", "shoulders"; see InputSetup.hint_text.
static func hint(entries: Array) -> String:
	return InputSetup.hint_text(Settings.bindings, InputDevice.pad, entries)

## The current name of one action's button ("Z", or "A" on a pad), for sentences like "Press Z again".
static func key_for(action: String) -> String:
	return InputSetup.hint_name(Settings.bindings, action, InputDevice.pad)

## Keeps `l.text` in step with `entries` as the device or the bindings change. Returns `l`.
static func bind_hint(l: Label, entries: Array) -> Label:
	var upd := func(): l.text = hint(entries)
	upd.call()
	InputDevice.changed.connect(upd)
	Bus.settings_changed.connect(upd)
	l.tree_exiting.connect(func():
		InputDevice.changed.disconnect(upd)
		Bus.settings_changed.disconnect(upd))
	return l
