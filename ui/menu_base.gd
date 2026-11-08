class_name MenuBase
extends Control
## Shared frame for every menu: themed full-screen backdrop, header, hint bar, cancel handling, sounds.
## Subclasses override _build() (once, in _ready), setup(arg) if they take an argument, and _on_cancel().
## The Router awaits `closed(result)`.

signal closed(result)

var title_text := ""
var content: Control          # where subclasses put their layout (inside the margins)
var header_right: Label
var hint_label: Label
const SIDE := 48              # the frame's left and right margin
const HINT_H := 46            # the hint bar's own strip along the bottom
const HINT_FONT := 20         # its text size; shrinks (to HINT_MIN) rather than run off the screen
const HINT_MIN := 15

var _hint_entries: Array = []   # the prompts behind the hint bar, redrawn when the device or bindings change
var _done := false
var _locked := false          # true while a child menu or popup owns input

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_frame()
	_build()

func _build_frame() -> void:
	var g := Gradient.new()
	g.set_color(0, Color("10131d"))
	g.set_color(1, Color("262d42"))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0.35, 1)
	var bg := TextureRect.new()
	bg.texture = tex
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.modulate = Color(1, 1, 1, 0.96)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var rule := ColorRect.new()
	rule.color = UIKit.HEATHER
	rule.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rule.custom_minimum_size = Vector2(0, 6)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
	# The hint bar has its own strip along the bottom, so no menu can draw underneath it.
	var foot := PanelContainer.new()
	foot.name = "HintBar"
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -HINT_H
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := UIKit.box(Color(0.03, 0.035, 0.06, 0.55), Color(UIKit.HEATHER, 0.45), 0, 0, 0)
	fs.border_width_top = 2
	fs.content_margin_left = SIDE
	fs.content_margin_right = SIDE
	foot.add_theme_stylebox_override("panel", fs)
	add_child(foot)
	hint_label = UIKit.label("", HINT_FONT, UIKit.MUTED)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.clip_text = true  # never widens the frame; _fit_hint shrinks the text first
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(hint_label)
	hint_label.resized.connect(_fit_hint)  # the label's own width, once the bar has laid it out (not the bar's)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, SIDE)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", HINT_H + 14)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	col.add_child(head)
	var t := UIKit.label(title_text, 44, UIKit.CREAM)
	t.name = "Title"
	head.add_child(t)
	head.add_child(UIKit.fill())
	header_right = UIKit.label("", 26, UIKit.GOLD)
	header_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(header_right)
	content = Control.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.clip_contents = true  # a last line of defence: a panel that's too tall is cut, never drawn over the hints
	col.add_child(content)
	InputDevice.changed.connect(_redraw_hint)
	Bus.settings_changed.connect(_redraw_hint)

func set_title(t: String) -> void:
	title_text = t
	var l := find_child("Title", true, false)
	if l:
		l.text = t

func set_hint(text: String) -> void:
	_hint_entries = []
	hint_label.text = text
	_fit_hint()

## The hint bar from button prompts, e.g. [["confirm", "Choose"], ["cancel", "Back"]]; see UIKit.hint.
func set_hints(entries: Array) -> void:
	_hint_entries = entries
	hint_label.text = UIKit.hint(entries)
	_fit_hint()

const TIP_SECONDS := 9.0
var _tip_until := 0

## A one-line introduction in the hint bar for a few seconds (see Intros), then the usual prompts come back.
func show_tip(text: String) -> void:
	if not is_instance_valid(hint_label):
		return
	var stamp := Time.get_ticks_msec() + int(TIP_SECONDS * 1000.0)
	_tip_until = stamp
	hint_label.text = text
	hint_label.add_theme_color_override("font_color", UIKit.GOLD)
	_fit_hint()
	get_tree().create_timer(TIP_SECONDS).timeout.connect(_end_tip.bind(stamp))

## Shows anything just noted in the Economist's notebook (see Economist.take_fresh) as a tip.
func econ_tip() -> void:
	var t := Economist.take_fresh()
	if t != "":
		show_tip(t)

func _end_tip(stamp: int) -> void:
	if _tip_until == stamp:
		_tip_until = 0
		hint_label.remove_theme_color_override("font_color")
		_redraw_hint()

func _redraw_hint() -> void:
	if _tip_until != 0 and Time.get_ticks_msec() < _tip_until:
		return  # the tip has the bar for now
	if not _hint_entries.is_empty() and is_instance_valid(hint_label):
		hint_label.text = UIKit.hint(_hint_entries)
		_fit_hint()

## The biggest hint text size (HINT_FONT down to HINT_MIN) that fits the bar on one line.
func _fit_hint() -> void:
	if not is_instance_valid(hint_label):
		return
	var w := hint_label.size.x if hint_label.size.x > SIDE else get_viewport_rect().size.x - SIDE * 2  # before layout it is a sliver
	var fs := UIKit.fit_size(hint_label.text, w, HINT_FONT, HINT_MIN)
	if fs != hint_label.get_theme_font_size("font_size"):
		hint_label.add_theme_font_size_override("font_size", fs)

func _exit_tree() -> void:
	if InputDevice.changed.is_connected(_redraw_hint):
		InputDevice.changed.disconnect(_redraw_hint)
	if Bus.settings_changed.is_connected(_redraw_hint):
		Bus.settings_changed.disconnect(_redraw_hint)

## Override: build the layout into `content`.
func _build() -> void:
	pass

## Override: back out one level (default: close).
func _on_cancel() -> void:
	close(null)

func close(result = null) -> void:
	if _done:
		return
	_done = true
	Audio.sfx("cancel")
	closed.emit(result)

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_on_cancel()

## A button with the standard cursor and confirm sounds.
func make_button(text: String, cb: Callable, min_w := 0) -> Button:
	var b := UIKit.button(text, min_w)
	b.focus_entered.connect(func(): Audio.sfx("cursor"))
	b.pressed.connect(func():
		Audio.sfx("confirm")
		cb.call())
	return b

## Runs a nested menu through the Router with this one locked, then unlocks a frame later
## so the closing key press isn't read twice.
func open_child(name: String) -> Variant:
	_locked = true
	var r = await Router.open_menu(name)
	await get_tree().process_frame
	_locked = false
	return r

func party() -> Array:
	return Game.data.party

## Opens a scene that Router doesn't list (summary, popups) on top of this menu and waits for its `closed`.
func open_local(path: String, arg := "") -> Variant:
	_locked = true
	var scene: Node = load(path).instantiate()
	add_child(scene)
	if scene.has_method("setup"):
		scene.setup(arg)
	var r = await scene.closed
	scene.queue_free()
	await get_tree().process_frame
	_locked = false
	return r
