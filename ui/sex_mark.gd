class_name SexMark
extends Control
## The male (blue-ish, circle with an arrow) or female (rose, circle on a cross) sign, drawn with lines so it never
## depends on the UI font having U+2642 / U+2640. Zero-sized and invisible for a creature with no sex.

var sex := ""

static func make(sex_id: String, size := 22) -> SexMark:
	var m := SexMark.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	m.set_sex(sex_id, size)
	return m

## Changes the sign (or hides it with "" or a sex-less kindred's empty string).
func set_sex(sex_id: String, px := 22) -> void:
	sex = sex_id if Sexes.valid(sex_id) else ""
	custom_minimum_size = Vector2(px, px) if sex != "" else Vector2.ZERO
	tooltip_text = Sexes.word(sex)
	visible = sex != ""
	queue_redraw()

func _draw() -> void:
	if sex == "":
		return
	var s := minf(size.x, size.y)
	if s <= 0.0:
		return
	var col := Sexes.colour(sex)
	var w := maxf(2.0, s * 0.11)
	var r := s * 0.27
	if sex == "m":
		var c := Vector2(s * 0.42, s * 0.58)
		draw_arc(c, r, 0.0, TAU, 28, col, w, true)
		var tip := Vector2(s * 0.88, s * 0.12)
		var from := c + (tip - c).normalized() * r
		draw_line(from, tip, col, w, true)
		var h := s * 0.3
		draw_line(tip, tip + Vector2(-h, 0), col, w, true)
		draw_line(tip, tip + Vector2(0, h), col, w, true)
	else:
		var c := Vector2(s * 0.5, s * 0.36)
		draw_arc(c, r, 0.0, TAU, 28, col, w, true)
		var foot := c + Vector2(0, r)
		var low := Vector2(s * 0.5, s * 0.94)
		draw_line(foot, low, col, w, true)
		draw_line(Vector2(s * 0.3, s * 0.74), Vector2(s * 0.7, s * 0.74), col, w, true)
