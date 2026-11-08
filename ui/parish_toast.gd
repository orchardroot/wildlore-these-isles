class_name ParishToast
extends CanvasLayer
## Parish news at the top of the screen: a job finished, a job ready to hand in, a nation that now counts you as one
## of its own. Slides down, holds, fades. Messages queue and play one at a time, and wait for the town's name card
## to go (they share the top of the screen). A long line wraps rather than run wide over the route chip. Never takes
## input.

const HOLD := 2.6
const MAX_W := 640.0  # px of text before it wraps: the panel then stays clear of the route chip on the left
const BG := Color(0.114, 0.133, 0.188, 0.92)

var _panel: PanelContainer
var _head: Label
var _body: Label
var _queue: Array = []   # [header, text]
var _playing := false

func _ready() -> void:
	layer = 61
	_panel = PanelContainer.new()
	_panel.theme = load("res://ui/theme.tres")
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_top = 22
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.set_corner_radius_all(10)
	sb.border_width_left = 6
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(UIKit.GOLD, 0.85)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)
	_head = UIKit.label("", 18, UIKit.GOLD)
	_head.uppercase = true
	_head.add_theme_constant_override("outline_size", 0)
	col.add_child(_head)
	_body = UIKit.label("", 25, UIKit.CREAM)
	col.add_child(_body)
	add_child(_panel)
	_panel.modulate.a = 0.0

static func text_width(l: Label) -> float:
	return l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x

## Sizes the panel to the text now on it and centres it. A wrapping label works out its height from the width it
## has *now*, so the body is given its wrap width before the panel is measured (else it measured one word a line
## and the panel ran to the bottom of the screen).
func lay_out() -> void:
	var wide := text_width(_body) > MAX_W
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wide else TextServer.AUTOWRAP_OFF
	_body.custom_minimum_size.x = MAX_W if wide else 0.0
	_body.size = Vector2(MAX_W if wide else 0.0, 0.0)
	_body.update_minimum_size()
	_panel.reset_size()
	var w := _panel.size.x
	_panel.offset_left = -w * 0.5
	_panel.offset_right = w * 0.5

## The panel's box on screen (for the HUD checks).
func rect() -> Rect2:
	return _panel.get_global_rect()

func show_news(header: String, text: String) -> void:
	_queue.append([header, text])
	if not _playing:
		_next()

func _next() -> void:
	if _queue.is_empty():
		_playing = false
		return
	_playing = true
	var card := get_tree().get_first_node_in_group(ZoneCard.GROUP) as ZoneCard
	while card != null and is_instance_valid(card) and card.showing():
		await get_tree().create_timer(0.25).timeout
	var m: Array = _queue.pop_front()
	_head.text = m[0]
	_body.text = m[1]
	lay_out()
	_panel.position.y = 8.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "position:y", 22.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(HOLD)
	tw.chain().tween_property(_panel, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(_next)
