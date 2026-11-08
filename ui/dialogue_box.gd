class_name DialogueBox
extends CanvasLayer
## Bottom-of-screen dialogue panel: speaker tab, typewriter text, a bobbing "next" arrow and a choice list.
## `await box.show_text(text, who)` returns once the player has read it and pressed confirm.
## `await box.show_choice(text, options)` returns the chosen index.

enum State { IDLE, TYPING, WAIT, CHOOSING }

const CREAM := Color(0.949, 0.91, 0.812)
const HEATHER := Color(0.608, 0.435, 0.69)
const SLATE := Color(0.114, 0.133, 0.188, 0.95)
const FAST_FORWARD := 6.0   # typing speed multiplier while confirm is held
const DECLINES := ["just looking", "not today", "not yet", "another day", "no thanks", "no, ta", "carry on", "walk past", "leave him"]
const INPUT_GRACE_MS := 180   # ignore the confirm press that opened the conversation

signal _advanced
signal _chosen(index: int)

var state := State.IDLE
var _ui: Control
var _box: PanelContainer
var _label: Label
var _tab: PanelContainer
var _tab_label: Label
var _arrow: Control
var _arrow_tween: Tween
var _choice_panel: PanelContainer
var _choice_labels: Array = []
var _choice_index := 0
var _typed := 0.0
var _total := 0
var _armed_at := 0
var _choice_after_typing := false
var _decline := -1

func _ready() -> void:
	layer = 20
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = load("res://ui/theme.tres")
	add_child(_ui)
	_build_box()
	_build_tab()
	_build_arrow()
	_build_choices()
	_ui.visible = false

func _panel_style(bg: Color, border: Color, radius := 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(3)
	sb.border_color = border
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	return sb

func _build_box() -> void:
	_box = PanelContainer.new()
	_box.anchor_left = 0.0
	_box.anchor_right = 1.0
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = 48
	_box.offset_right = -48
	_box.offset_top = -176
	_box.offset_bottom = -28
	_box.add_theme_stylebox_override("panel", _panel_style(SLATE, CREAM))
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN  # a fourth line grows the box upwards, never off the bottom
	_ui.add_child(_box)
	_box.resized.connect(_seat_tab)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(0, 100)
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_constant_override("line_spacing", 6)
	_box.add_child(_label)

func _build_tab() -> void:
	_tab = PanelContainer.new()
	_tab.anchor_left = 0.0
	_tab.anchor_right = 0.0
	_tab.anchor_top = 1.0
	_tab.anchor_bottom = 1.0
	_tab.offset_left = 76
	_tab.offset_top = -170
	_tab.offset_bottom = -170
	_tab.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var sb := _panel_style(Color(0.33, 0.24, 0.42, 0.97), CREAM, 8)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	_tab.add_theme_stylebox_override("panel", sb)
	_ui.add_child(_tab)
	_tab.resized.connect(_seat_tab)
	_tab_label = Label.new()
	_tab_label.add_theme_font_size_override("font_size", 26)
	_tab.add_child(_tab_label)
	_tab.visible = false

## The speaker's tab sits on the box's top edge, wherever that is: a four-line page grows the box upwards, and a
## tab left at the three-line height would cover the first line.
func _seat_tab() -> void:
	_tab.position.y = _box.position.y - _tab.size.y + 6.0

func _build_arrow() -> void:
	_arrow = Control.new()
	_arrow.anchor_left = 1.0
	_arrow.anchor_right = 1.0
	_arrow.anchor_top = 1.0
	_arrow.anchor_bottom = 1.0
	_arrow.offset_left = -96
	_arrow.offset_top = -62
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tri := Polygon2D.new()
	tri.polygon = PackedVector2Array([Vector2(0, 0), Vector2(26, 0), Vector2(13, 16)])
	tri.color = CREAM
	_arrow.add_child(tri)
	var outline := Line2D.new()
	outline.points = PackedVector2Array([Vector2(0, 0), Vector2(26, 0), Vector2(13, 16)])
	outline.closed = true
	outline.width = 2.0
	outline.default_color = HEATHER
	_arrow.add_child(outline)
	_ui.add_child(_arrow)
	_arrow.visible = false

func _build_choices() -> void:
	_choice_panel = PanelContainer.new()
	_choice_panel.anchor_left = 1.0
	_choice_panel.anchor_right = 1.0
	_choice_panel.anchor_top = 1.0
	_choice_panel.anchor_bottom = 1.0
	_choice_panel.offset_right = -64
	_choice_panel.offset_left = -64
	_choice_panel.offset_top = -196
	_choice_panel.offset_bottom = -196
	_choice_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_choice_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choice_panel.add_theme_stylebox_override("panel", _panel_style(SLATE, HEATHER))
	_ui.add_child(_choice_panel)
	_choice_panel.add_child(VBoxContainer.new())
	_choice_panel.visible = false

## Types `text` out, then waits for confirm. `who` shows in the name tab (hidden when empty).
func show_text(text: String, who := "") -> void:
	if Engine.has_meta("autopilot"):
		Engine.get_meta("autopilot").log_line(who, text)
		await get_tree().create_timer(0.05).timeout
		return
	for page in _pages(text):
		_begin(page, who)
		_choice_after_typing = false
		await _advanced

## Types `text`, then offers `options`. Returns the chosen index.
func show_choice(text: String, options: Array, who := "") -> int:
	if Engine.has_meta("autopilot"):
		await get_tree().create_timer(0.05).timeout
		return Engine.get_meta("autopilot").choose_option(text, options)
	var pages := _pages(text)
	for i in pages.size() - 1:  # everything but the last page reads like ordinary dialogue
		_begin(pages[i], who)
		_choice_after_typing = false
		await _advanced
	_begin(pages.back(), who)
	_choice_after_typing = true
	_decline = decline_index(options)
	_fill_choices(options)
	var idx: int = await _chosen
	_choice_panel.visible = false
	return idx

## Splits `text` into pages that each pass `fits`: whole sentences where they fit, words where a sentence alone is
## too long. Joining the pages with spaces gives the text back.
static func paginate(text: String, fits: Callable) -> Array:
	text = text.strip_edges()
	if text == "" or fits.call(text):
		return [text]
	var units := []
	var re := RegEx.new()
	re.compile("[^.!?]+[.!?]+[\"')]*|[^.!?]+$")
	for m in re.search_all(text):
		var sentence := m.get_string().strip_edges()
		if sentence == "":
			continue
		if fits.call(sentence):
			units.append(sentence)
		else:
			units.append_array(sentence.split(" ", false))
	var pages := []
	var cur := ""
	for u in units:
		var trial: String = u if cur == "" else cur + " " + u
		if cur != "" and not fits.call(trial):
			pages.append(cur)
			cur = u
		else:
			cur = trial
	if cur != "":
		pages.append(cur)
	return pages

const MAX_LINES := 4
const SIZES := [30, 26]  # try the usual size, then a touch smaller, before splitting into pages

## Fits the text to the box: the usual size if it fits in MAX_LINES, else a little smaller, else pages at that size.
func _pages(text: String) -> Array:
	var font := _label.get_theme_font("font")
	var width := maxf(_box.size.x, get_viewport().get_visible_rect().size.x - 96.0) - 52.0
	for fs in SIZES:
		var fits := func(t: String) -> bool:
			return font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, width, fs).y <= font.get_height(fs) * MAX_LINES + 2.0
		if fits.call(text) or fs == SIZES.back():
			_label.add_theme_font_size_override("font_size", fs)
			return paginate(text, fits)
	return [text]

func close() -> void:
	queue_free()

func _begin(text: String, who: String) -> void:
	_ui.visible = true
	_label.text = text
	_label.visible_characters = 0
	_total = text.length()
	_typed = 0.0
	_tab.visible = who != ""
	_tab_label.text = who
	_arrow.visible = false
	_choice_panel.visible = false
	_armed_at = Time.get_ticks_msec() + INPUT_GRACE_MS
	state = State.TYPING

func _fill_choices(options: Array) -> void:
	var vb: VBoxContainer = _choice_panel.get_child(0)
	for c in vb.get_children():
		c.queue_free()
	_choice_labels.clear()
	for o in options:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 28)
		l.text = "    " + str(o)
		vb.add_child(l)
		_choice_labels.append(l)
	_choice_index = 0
	_refresh_choices()

func _refresh_choices() -> void:
	for i in _choice_labels.size():
		var l: Label = _choice_labels[i]
		var base: String = l.text.strip_edges().trim_prefix("▶").strip_edges()
		l.text = ("▶ " if i == _choice_index else "    ") + base
		l.add_theme_color_override("font_color", Color.WHITE if i == _choice_index else CREAM.darkened(0.15))

func _process(delta: float) -> void:
	var armed := Time.get_ticks_msec() >= _armed_at
	_tick(delta, Input.is_action_just_pressed("confirm") and armed, Input.is_action_just_pressed("cancel") and armed,
		Input.is_action_pressed("confirm") and armed, int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("move_up")))

## One frame of input handling. `pressed`/`cancel` are fresh presses, `held` is confirm still down, `nav` is -1 up / +1 down.
func _tick(delta: float, pressed: bool, cancel: bool, held: bool, nav := 0) -> void:
	match state:
		State.TYPING:
			_typed += delta * Settings.chars_per_second() * (FAST_FORWARD if held else 1.0)
			var shown := mini(int(_typed), _total)
			if pressed:
				shown = _total
			if shown != _label.visible_characters:
				_label.visible_characters = shown
			if shown >= _total:
				_finish_typing()
		State.WAIT:
			if pressed or cancel:
				_arrow.visible = false
				state = State.IDLE
				_advanced.emit()
		State.CHOOSING:
			if nav != 0:
				_choice_index = posmod(_choice_index + nav, _choice_labels.size())
				_refresh_choices()
			elif pressed:
				state = State.IDLE
				_chosen.emit(_choice_index)
			elif cancel and _decline >= 0:
				state = State.IDLE
				_chosen.emit(_decline)

## The index cancel picks in a choice: the last option, but only when it reads as a polite decline.
## Quiz answers and the like return -1 so a stray cancel can't answer them.
static func decline_index(options: Array) -> int:
	if options.size() < 2:
		return -1
	var last := str(options.back()).to_lower()
	for w in DECLINES:
		if last.contains(w):
			return options.size() - 1
	return -1

func _finish_typing() -> void:
	_label.visible_characters = -1
	if _choice_after_typing:
		_choice_panel.visible = true
		state = State.CHOOSING
		_armed_at = Time.get_ticks_msec() + 120
	else:
		state = State.WAIT
		_arrow.visible = true
		_bob_arrow()

func _bob_arrow() -> void:
	if _arrow_tween:
		_arrow_tween.kill()
	_arrow.offset_top = -62.0
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(_arrow, "offset_top", -55.0, 0.35).set_trans(Tween.TRANS_SINE)
	_arrow_tween.tween_property(_arrow, "offset_top", -62.0, 0.35).set_trans(Tween.TRANS_SINE)
