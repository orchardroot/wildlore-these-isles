extends Control
## First-catch popup. Call `await PediaPopup.show_for(self, "binfox")` from anywhere with a node in the tree,
## or instantiate the scene and call setup(species_id), then await its `closed` signal.
class_name PediaPopup

signal closed(result)

const SCENE := "res://ui/pedia_popup.tscn"

var _done := false
var _armed := false

static func show_for(host: Node, species_id: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	host.get_tree().root.add_child(layer)
	var p: Control = load(SCENE).instantiate()
	layer.add_child(p)
	p.setup(species_id)
	await p.closed
	layer.queue_free()

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(species_id: String) -> void:
	var sp: Dictionary = Game.dex.get_species(species_id)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var card := UIKit.panel(Color("1d2230fa"), 28)
	card.custom_minimum_size = Vector2(760, 0)
	centre.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	var head := UIKit.label("NEW FIELDBOOK ENTRY", 24, UIKit.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(Color("2c3446"), Color("4a4f5e"), 2, 10, 8))
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(frame)
	var s := AnimSprite.new()
	s.show_species(species_id, "front", 2)
	s.animate(sp)
	frame.add_child(s)
	var n := UIKit.label(str(sp.get("name", species_id)), 44)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(n)
	var tr := UIKit.types_row(sp.get("types", []), 22)
	tr.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(tr)
	var fact := UIKit.label("Did you know? " + str(sp.get("dex", {}).get("fact", "")), 24, Color("d8cfb4"))
	fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(fact)
	var added := UIKit.label("Added to your Fieldbook.", 28, UIKit.CREAM)
	added.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(added)
	var hint := UIKit.bind_hint(UIKit.label("", 20, UIKit.MUTED), [["confirm", "Continue"]])
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	Audio.sfx("caught")
	await get_tree().create_timer(0.4).timeout  # long enough that a mashed catch button can't skip it
	_armed = true

func _input(event: InputEvent) -> void:
	if _done or not _armed:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_done = true
		Audio.sfx("confirm")
		closed.emit(null)
