class_name EffectMark
extends Control
## The little shape before "Super effective x2" and friends, so a matchup never rests on colour alone: one or two
## up triangles for a hit that lands hard, down triangles for one that is turned aside, a cross for no effect and a
## flat bar for a plain hit. Drawn in code at any size, like TypeGlyph. `kind` is MoveText.cue()'s kind.

const UP := Color("7fdc86")
const DOWN := Color("f09a7a")
const NONE := Color("ff8a7a")
const EVEN := Color("c9c2b0")
const UP_CB := Color("7ab8ff")    # colour-blind palette: blue for good, orange for bad
const DOWN_CB := Color("ffb347")

var kind := "even"
var colour := EVEN

static func make(k: String, px := 16) -> EffectMark:
	var m := EffectMark.new()
	m.kind = k
	m.colour = colour_of(k)
	m.custom_minimum_size = Vector2(px * count(k) + (count(k) - 1) * 2, px)
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m

static func count(k: String) -> int:
	return 2 if k == "up2" or k == "dn2" else 1

static func colour_of(k: String) -> Color:
	var cb := TypeColours.is_colour_blind()
	match k:
		"up1", "up2":
			return UP_CB if cb else UP
		"dn1", "dn2":
			return DOWN_CB if cb else DOWN
		"none":
			return NONE
	return EVEN

func _draw() -> void:
	var n := count(kind)
	var s := size.y
	for i in n:
		var ox := i * (s + 2.0)
		for poly in polygons(kind):
			var pts := PackedVector2Array()
			for p in poly:
				pts.append(Vector2(ox + p.x * s, p.y * s))
			if Geometry2D.triangulate_polygon(pts).size() >= 3:
				draw_colored_polygon(pts, colour)

## The shape in 0..1 coordinates (one copy; up2 and dn2 draw it twice).
static func polygons(k: String) -> Array:
	match k:
		"up1", "up2":
			return [PackedVector2Array([Vector2(0.5, 0.05), Vector2(1.0, 0.92), Vector2(0.0, 0.92)])]
		"dn1", "dn2":
			return [PackedVector2Array([Vector2(0.0, 0.08), Vector2(1.0, 0.08), Vector2(0.5, 0.95)])]
		"none":
			return [_bar(0.12, PI / 4.0), _bar(0.12, -PI / 4.0)]
	return [PackedVector2Array([Vector2(0.05, 0.38), Vector2(0.95, 0.38), Vector2(0.95, 0.62), Vector2(0.05, 0.62)])]

static func _bar(thick: float, angle: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c in [Vector2(-0.5, -thick), Vector2(0.5, -thick), Vector2(0.5, thick), Vector2(-0.5, thick)]:
		out.append(Vector2(0.5, 0.5) + c.rotated(angle) * 1.0)
	return out
