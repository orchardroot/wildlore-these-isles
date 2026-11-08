class_name BattleMessage
extends PanelContainer
## The bottom text box. Lines type out at the player's text speed; confirm completes a line, then skips the pause.
## Holding confirm fast-forwards: lines type and pause HOLD_SPEEDUP times quicker while it is held down.

const HOLD_SPEEDUP := 4.0
const SIZES := [30, 26, 23]  # the usual size; smaller only when a line would need a third row the box hasn't got
const ROOM := 98.0           # px of text height inside the box (134 less its padding and border)
const WIDTH := 1196.0        # px of text width inside it

var label: Label
var _typing := false
var _waiting := false
var _skip := false
var _shown := 0.0

func _ready() -> void:
	var sb: StyleBoxFlat = (load("res://ui/theme.tres") as Theme).get_stylebox("panel", "PanelContainer").duplicate()
	sb.set_content_margin_all(16)
	sb.bg_color.a = 1.0
	add_theme_stylebox_override("panel", sb)
	position = Vector2(24, 566)
	size = Vector2(1232, 134)
	label = Label.new()
	label.add_theme_font_size_override("font_size", 30)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.visible_characters = 0
	add_child(label)

func _process(delta: float) -> void:
	if _typing:
		_shown += delta * Settings.chars_per_second() * _hold_mult()
		label.visible_characters = int(_shown)
		if _shown >= label.text.length():
			label.visible_characters = -1
			_typing = false

## Held confirm (polled, not just the press) speeds everything in the box up.
func _hold_mult() -> float:
	return HOLD_SPEEDUP if Input.is_action_pressed("confirm") or Input.is_action_pressed("ui_accept") else 1.0

func _input(event: InputEvent) -> void:
	if not (_typing or _waiting):
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
		if _typing:
			_shown = 1e9
		else:
			_skip = true
		get_viewport().set_input_as_handled()

## The size `text` is set at so all of it fits the box: a long line takes a smaller size rather than grow the box
## off the bottom of the screen. Measured once per line, never per frame.
static func size_for(text: String, font: Font, width := WIDTH) -> int:
	for fs in SIZES:
		if font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, fs).y <= ROOM:
			return fs
	return SIZES.back()

func _set_text(text: String) -> void:
	label.text = text
	_fit()

func _fit() -> void:
	var w := label.custom_minimum_size.x if label.custom_minimum_size.x > 0.0 else WIDTH
	label.add_theme_font_size_override("font_size", size_for(label.text, label.get_theme_font("font"), w))

## A picker opened over the box (`rect`, empty when it closed): the words keep to the part of the box left of it.
func make_room(rect: Rect2) -> void:
	var box := Rect2(position, size)
	var room := 0.0
	if rect.has_area() and rect.intersects(box) and rect.position.x > box.position.x + 200.0:
		room = minf(WIDTH, rect.position.x - box.position.x - 16.0 - 14.0)
	label.custom_minimum_size.x = room
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if room > 0.0 else Control.SIZE_EXPAND_FILL
	_fit()

## Shows text and pauses long enough to read it (plus `hold` seconds).
func say(text: String, hold := 0.0) -> void:
	_set_text(text)
	label.visible_characters = 0
	_shown = 0.0
	_typing = true
	while _typing:
		await get_tree().process_frame
	var wait := 0.3 + text.length() * 0.014 + hold
	var t := 0.0
	_waiting = true
	_skip = false
	while t < wait and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time() * _hold_mult()
	_waiting = false

## Shows text immediately and leaves it up (a prompt while a menu is open).
func prompt(text: String) -> void:
	_set_text(text)
	label.visible_characters = -1
	_typing = false

func clear() -> void:
	label.text = ""
