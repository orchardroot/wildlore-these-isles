class_name PlaceIndicator
extends CanvasLayer
## Stand at a named building's door and its name slides in at the bottom left, with a word for what it is
## ("Paradise Mill · Museum"); walk on and it fades away. The signs on the buildings can then be signs, hidden
## behind a roof now and then like real ones, without having to carry all the reading.

const SLIDE := 18.0      # pixels it slides in from the left
const IN_SECS := 0.22
const OUT_SECS := 0.35
const MARGIN := Vector2(22, 24)

var _panel: PanelContainer
var _name: Label
var _kind: Label
var _dot: Label
var _tween: Tween
var _showing := ""

## The named building whose door you stand at or beside (the tile in front of it, or either side of that):
## {name, kind} with kind from Signage.place_word, or {} for none. Homes and unnamed buildings are not places.
static func place_near(z: ZoneData, p: Vector2i) -> Dictionary:
	if z == null or z.kind == "interior":
		return {}
	for pr in z.props:
		if pr.get("type") != "building" or not pr.has("label") or not pr.get("show_label", true):
			continue
		var bx := int(pr.x)
		var by := int(pr.y)
		if p.x < bx - 1 or p.x > bx + int(pr.w) or p.y != by + int(pr.h):
			continue  # quick reject: not on the row in front of this building
		var door := Signage.door_of(z, pr)
		if int(door[0]) < 0 or absi(p.x - (bx + int(door[0]))) > 1:
			continue
		var label := str(pr.label)
		var style := str(pr.get("style", "red_brick"))
		var kind := str(pr.get("kind", ""))
		if Signage.sign_type(label, style, kind, str(door[1])) == "":
			continue
		return {"name": label, "kind": Signage.place_word(label, style, kind, str(door[1]))}
	return {}

static func text_for(info: Dictionary) -> String:
	var k := str(info.get("kind", ""))
	return str(info.get("name", "")) + ("  ·  " + k if k != "" else "")

func _ready() -> void:
	layer = 4
	get_tree().node_added.connect(func(n: Node) -> void:  # talk and signs cover the corner: step aside till the next step
		if n is DialogueBox:
			hide_place(true))
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = load("res://ui/theme.tres")
	add_child(root)
	_panel = PanelContainer.new()
	var sb := UIKit.box(Color("1d2230e6"), Color(0, 0, 0, 0), 0, 6, 0)
	sb.content_margin_left = 16
	sb.content_margin_right = 18
	sb.content_margin_top = 7
	sb.content_margin_bottom = 8
	sb.border_width_left = 4
	sb.border_color = UIKit.GOLD.darkened(0.15)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	_panel.add_child(h)
	_name = UIKit.label("", 24, UIKit.CREAM)
	_name.add_theme_font_override("font", Signage.font("serif"))
	h.add_child(_name)
	_dot = UIKit.label("·", 22, UIKit.GOLD)
	h.add_child(_dot)
	_kind = UIKit.label("", 20, UIKit.MUTED)
	_kind.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_kind.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_kind)
	_panel.modulate.a = 0.0
	_panel.visible = false
	var ow := get_parent()
	if ow and ow.has_signal("stepped"):
		ow.stepped.connect(_on_stepped)
	Bus.zone_entered.connect(_on_zone_entered)

## A new zone: clear the old place, then (once you stand in the new one) show where you are, if anywhere,
## so stepping out of a door names the building you left.
func _on_zone_entered(_id: String) -> void:
	hide_place(true)
	await get_tree().create_timer(0.6).timeout
	var ow := get_parent()
	if is_instance_valid(ow) and "player" in ow and ow.player:
		_on_stepped(ow.player.grid_pos, "")

func _on_stepped(p: Vector2i, _tile: String) -> void:
	var ow := get_parent()
	var info := place_near(ow.zone, p) if ow and "zone" in ow else {}
	if info.is_empty():
		hide_place()
	else:
		show_place(info)

func show_place(info: Dictionary) -> void:
	var key := text_for(info)
	if key == _showing:
		return
	_showing = key
	_name.text = str(info.name)
	var k := str(info.get("kind", ""))
	_kind.text = k
	_kind.visible = k != ""
	_dot.visible = k != ""
	_panel.visible = true
	_panel.reset_size()
	var vp := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1280, 720)
	var y := vp.y - MARGIN.y - _panel.get_combined_minimum_size().y
	if _tween:
		_tween.kill()
	_panel.position = Vector2(MARGIN.x - SLIDE, y)
	_panel.modulate.a = 0.0
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel, "position:x", MARGIN.x, IN_SECS)
	_tween.tween_property(_panel, "modulate:a", 1.0, IN_SECS)

func hide_place(now := false) -> void:
	if _showing == "":
		return
	_showing = ""
	if _tween:
		_tween.kill()
	if now:
		_panel.modulate.a = 0.0
		_panel.visible = false
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(_panel, "modulate:a", 0.0, OUT_SECS)
	_tween.tween_property(_panel, "position:x", MARGIN.x - SLIDE * 0.5, OUT_SECS)
	_tween.chain().tween_callback(func() -> void: _panel.visible = false)
