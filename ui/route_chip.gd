class_name RouteChip
extends CanvasLayer
## The "Route here" breadcrumb: a small chip top-left in the overworld, "To Buxton · 3 to go" with an arrow
## toward this zone's way out on the route (edge side, door or station). Worked out afresh on each zone entry,
## so wandering off route just re-routes; hidden indoors; cleared with a soft chime on arrival.

const MARGIN := Vector2(22, 118)  # under the toasts and zone card
const GAP := 10.0                 # px kept clear below a toast or name card that would reach across the chip

var _panel: PanelContainer
var _arrow: Label
var _text: Label
var _next := ""
var _mode := ""

func _ready() -> void:
	layer = 4
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = load("res://ui/theme.tres")
	add_child(root)
	_panel = PanelContainer.new()
	var sb := UIKit.box(Color("1d2230e6"), Color(0, 0, 0, 0), 0, 6, 0)
	sb.content_margin_left = 14
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 7
	sb.border_width_left = 4
	sb.border_color = UIKit.GOLD.darkened(0.15)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = MARGIN
	root.add_child(_panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	_panel.add_child(h)
	_arrow = UIKit.label("", 28, UIKit.GOLD)
	h.add_child(_arrow)
	_text = UIKit.label("", 22, UIKit.CREAM)
	_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_text)
	_panel.visible = false
	var ow := get_parent()
	if ow and ow.has_signal("stepped"):
		ow.stepped.connect(func(_p: Vector2i, _t: String) -> void: _refresh(false))
	Bus.zone_entered.connect(func(_id: String) -> void: _on_entered())
	await get_tree().create_timer(0.7).timeout  # the zone has loaded by now
	_refresh(true)

## Where the chip's top goes: MARGIN.y, or just below `box` (a toast or the zone card, empty when there is none)
## when that reaches across the chip's corner. A long route name or Large text makes the chip wide enough to meet them.
static func clear_y(chip: Rect2, box: Rect2) -> float:
	if box.has_area() and box.position.x < chip.end.x + GAP and box.end.x > chip.position.x - GAP \
			and box.position.y < chip.end.y + GAP:
		return maxf(chip.position.y, box.end.y + GAP)
	return chip.position.y

func _process(delta: float) -> void:
	if not _panel.visible:
		return
	var chip := Rect2(Vector2(MARGIN.x, MARGIN.y), _panel.size)
	var y := MARGIN.y
	var card := get_tree().get_first_node_in_group(ZoneCard.GROUP) as ZoneCard
	if card:
		y = maxf(y, clear_y(chip, card.rect()))
	var news := get_tree().get_first_node_in_group(ParishToast.GROUP) as ParishToast
	if news:
		y = maxf(y, clear_y(chip, news.rect()))
	_panel.position.y = move_toward(_panel.position.y, y, delta * 900.0)

func _refresh(recompute: bool) -> void:
	var ow := get_parent()
	if not is_instance_valid(ow) or not "zone" in ow or ow.zone == null or ow.player == null:
		return
	var to = Game.data.flag("route_to")
	if to == null or str(to) == "":
		_panel.visible = false
		return
	if not recompute and _next != "":
		_arrow_only(ow)
		return
	var g := ZoneGraph.guide(ZoneGraph.shared(), ow.zone, ow.player.grid_pos, str(to), Game.data, Travel.town_name(str(to)))
	match str(g.state):
		"arrived":
			Game.data.flags.erase("route_to")
			_next = ""
			_panel.visible = false
			Audio.sfx("confirm")
		"go":
			_next = str(g.next)
			_mode = str(g.mode)
			_text.text = str(g.text)
			_arrow.text = str(g.arrow)
			_panel.visible = true
		_:
			_next = ""
			_panel.visible = false

## Between zones only the arrow moves, as you walk toward (or past) the exit.
func _arrow_only(ow: Node) -> void:
	var ex := ZoneGraph.exit_toward(ow.zone, _next, _mode, ow.player.grid_pos)
	if not ex.is_empty():
		_arrow.text = ZoneGraph.arrow_for(ex, ow.player.grid_pos)

func _on_entered() -> void:
	await get_tree().create_timer(0.7).timeout
	if is_inside_tree():
		_refresh(true)
