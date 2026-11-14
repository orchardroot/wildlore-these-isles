class_name TitleCat
extends RefCounted
## The title screen's one egg (see Eggs.feed): a small black cat walks across the bottom of the screen, unhurried, and
## that is all. No sound, no flag, nothing unlocked.

const ICON := "res://art/sprites/creatures/sootkit_icon.png"
const SIZE := 96.0
const SECS := 7.0

static func walk(parent: Control) -> void:
	if not ResourceLoader.exists(ICON) or not is_instance_valid(parent):
		return
	var cat := TextureRect.new()
	cat.texture = load(ICON)
	cat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cat.stretch_mode = TextureRect.STRETCH_SCALE
	cat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat.custom_minimum_size = Vector2(SIZE, SIZE)
	cat.size = Vector2(SIZE, SIZE)
	cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := parent.get_viewport_rect().size
	var y := vp.y - SIZE - 24.0
	cat.position = Vector2(-SIZE, y)
	parent.add_child(cat)
	var tw := cat.create_tween()
	tw.set_parallel(true)
	tw.tween_property(cat, "position:x", vp.x + SIZE, SECS)
	var bob := cat.create_tween().set_loops(int(SECS * 2.5))  # a little step in the stride
	bob.tween_property(cat, "position:y", y - 6.0, 0.2)
	bob.tween_property(cat, "position:y", y, 0.2)
	tw.chain().tween_callback(cat.queue_free)
