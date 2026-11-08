class_name SaveToast
extends CanvasLayer
## A small "Saved" note in the bottom-right corner that fades after a moment. Never takes input. Also says
## "Reported" (F9) and "Photo saved". Two at once stack rather than overlap, and while a dialogue box covers the
## bottom of the screen the note goes to the top-right corner instead.

const SLATE := Color(0.114, 0.133, 0.188, 0.88)
const CREAM := Color(0.949, 0.91, 0.812)
const GROUP := "save_toast"
const EDGE := 20.0
const STACK_GAP := 8.0

var _panel: PanelContainer
var _label: Label
var _tween: Tween
var _top := false  # sitting top-right (a dialogue box is up)

func _ready() -> void:
	layer = 60
	add_to_group(GROUP)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -20
	_panel.offset_right = -20
	_panel.offset_top = -20
	_panel.offset_bottom = -20
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var sb := StyleBoxFlat.new()
	sb.bg_color = SLATE
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(CREAM, 0.5)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_panel.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	_label = l
	l.text = "Saved"
	l.add_theme_font_size_override("font_size", Access.scaled(22, Settings.text_size))
	l.add_theme_color_override("font_color", CREAM)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(l)
	add_child(_panel)
	_panel.modulate.a = 0.0

## Fades in, holds, fades out. Safe to call again while showing (it just restarts).
func flash(text := "Saved") -> void:
	_label.text = text
	_seat()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.15)
	_tween.tween_interval(1.2)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.6)

## On screen (or fading)?
func showing() -> bool:
	return _panel.modulate.a > 0.01 or (_tween != null and _tween.is_running())

## Bottom right, or top right while someone is talking; above (or below) any other note already showing there.
func _seat() -> void:
	_panel.reset_size()
	var top := talking(get_tree())
	var shift := 0.0
	for t in get_tree().get_nodes_in_group(GROUP):
		if t != self and t.visible and t.showing() and t._top == top:
			shift += t._panel.size.y + STACK_GAP
	_top = top
	var y := EDGE + shift
	var sz := _panel.get_combined_minimum_size()
	_panel.anchor_top = 0.0 if top else 1.0
	_panel.anchor_bottom = _panel.anchor_top
	_panel.grow_vertical = Control.GROW_DIRECTION_END if top else Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = -EDGE - sz.x
	_panel.offset_right = -EDGE
	_panel.offset_top = y if top else -y - sz.y
	_panel.offset_bottom = y + sz.y if top else -y

## Is a dialogue box up?
static func talking(tree: SceneTree) -> bool:
	for n in tree.get_nodes_in_group(DialogueBox.GROUP):
		if (n as DialogueBox).up():
			return true
	return false
