class_name TrumpCard
extends Control
## One Trumps card, drawn once and redrawn only when it changes: a framed card in the colour of the species' first
## type (gold-edged for the rare ones), its name, the front sprite on a tinted ground, its types and five stats as
## pips. `full` is the big card of the table (stats can be picked with the mouse); otherwise a small card for the
## hand strips and the album. Face down it shows the back. See Trumps for the numbers.

signal stat_chosen(stat: String)
signal stat_hovered(stat: String)

const FULL := Vector2(250, 346)
const SMALL := Vector2(112, 140)
const INK := Color("1b1f2e")
const GOLD := Color("e8c872")
const CREAM := Color("f2e8cf")
const MUTED := Color("a9a294")

var species := ""
var card: Dictionary = {}
var face_up := true
var full := true
var silhouette := false
var selected := ""                  # the stat on the cursor (full cards)
var marks: Dictionary = {}          # stat -> "win" | "lose" | "tie" after a comparison
var locked: Array = []              # stats already tied this pair
var picking := false                # the stat rows answer the mouse
var _types: Array = []
var _name := ""
var _sprite: AnimSprite
var _rows: Array = []               # Rect2 per stat, full cards

func _init(is_full := true) -> void:
	full = is_full
	custom_minimum_size = FULL if full else SMALL
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_PASS if full else Control.MOUSE_FILTER_IGNORE
	_sprite = AnimSprite.new()
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)

func show_card(species_id: String, up := true, as_silhouette := false) -> void:
	species = species_id
	face_up = up
	silhouette = as_silhouette
	marks = {}
	locked = []
	selected = ""
	var sp := Trumps.dex().get_species(species_id)
	_types = sp.get("types", [])
	_name = "???" if silhouette else str(sp.get("name", species_id))
	card = Trumps.card(sp) if not sp.is_empty() else {}
	_sprite.visible = up and not sp.is_empty()
	if _sprite.visible:
		_sprite.show_species(species_id, "front", 1, silhouette)
		var s := 124.0 if full else 74.0
		_sprite.pivot_offset = Vector2.ZERO
		_sprite.scale = Vector2(s, s) / _sprite.size  # (a smaller min size doesn't shrink a Control the same frame)
		_sprite.position = Vector2((size.x - s) * 0.5, (52.0 if full else 24.0) + ((128.0 if full else 80.0) - s) * 0.5)
	queue_redraw()

func set_face(up: bool) -> void:
	face_up = up
	_sprite.visible = up and species != ""
	queue_redraw()

func set_selected(stat: String) -> void:
	selected = stat
	queue_redraw()

func set_marks(m: Dictionary) -> void:
	marks = m
	queue_redraw()

func set_locked(l: Array) -> void:
	locked = l
	queue_redraw()

func _tint() -> Color:
	if silhouette or _types.is_empty():
		return Color("5a5f70")
	return TypeColours.colour(str(_types[0]))

func _rare() -> bool:
	return not card.is_empty() and int(card.get("rarity", 0)) >= 9 and not silhouette

func _frame(rect: Rect2, radius: int, bw: int) -> void:
	var sb := UIKit.box(INK, GOLD if _rare() else _tint(), bw, radius, 0)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	draw_style_box(sb, rect)

func _draw() -> void:
	var f: Font = ThemeDB.fallback_font
	if not face_up:
		_draw_back(f)
		return
	if species == "":
		return
	if full:
		_draw_full(f)
	else:
		_draw_small(f)

func _draw_back(f: Font) -> void:
	var r := Rect2(Vector2.ZERO, size)
	var sb := UIKit.box(Color("2a2146"), GOLD.darkened(0.15), 4, 12 if full else 8, 0)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	draw_style_box(sb, r)
	var inset := r.grow(-12.0 if full else -7.0)
	draw_rect(inset, Color("3a2d63"), true)
	draw_rect(inset, GOLD.darkened(0.4), false, 2.0)
	var step := 22.0 if full else 14.0
	var lc := Color("5a4a8a")
	var x := inset.position.x - inset.size.y
	while x < inset.end.x:
		var a := Vector2(x, inset.end.y)
		var b := Vector2(x + inset.size.y, inset.position.y)
		var seg := _clip_line(a, b, inset)
		if seg.size() == 2:
			draw_line(seg[0], seg[1], lc, 1.5)
		var a2 := Vector2(x, inset.position.y)
		var b2 := Vector2(x + inset.size.y, inset.end.y)
		var seg2 := _clip_line(a2, b2, inset)
		if seg2.size() == 2:
			draw_line(seg2[0], seg2[1], lc, 1.5)
		x += step
	var c := size * 0.5
	var d := 66.0 if full else 24.0
	var wx := 1.25 if full else 0.72
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d * wx, 0), c + Vector2(0, d), c + Vector2(-d * wx, 0)]), Color("2a2146"))
	draw_polyline(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d * wx, 0), c + Vector2(0, d), c + Vector2(-d * wx, 0), c + Vector2(0, -d)]), GOLD, 3.0)
	var fs := 26 if full else 16
	var t := "TRUMPS" if full else "T"
	var ts := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(f, c + Vector2(-ts.x * 0.5, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD)

## The piece of the segment a-b inside rect r (a diagonal lattice only needs this crude clip).
func _clip_line(a: Vector2, b: Vector2, r: Rect2) -> Array:
	var t0 := 0.0
	var t1 := 1.0
	var dv := b - a
	for pair in [[-dv.x, a.x - r.position.x], [dv.x, r.end.x - a.x], [-dv.y, a.y - r.position.y], [dv.y, r.end.y - a.y]]:
		var p: float = pair[0]
		var q: float = pair[1]
		if is_zero_approx(p):
			if q < 0.0:
				return []
		else:
			var t: float = q / p
			if p < 0.0:
				t0 = maxf(t0, t)
			else:
				t1 = minf(t1, t)
	if t0 >= t1:
		return []
	return [a + dv * t0, a + dv * t1]

func _draw_full(f: Font) -> void:
	var tint := _tint()
	_frame(Rect2(Vector2.ZERO, size), 14, 6)
	# name plate
	draw_rect(Rect2(8, 8, size.x - 16, 38), tint.darkened(0.35), true)
	var fs := UIKit.fit_size(_name, size.x - 40.0, 26, 15)
	draw_string(f, Vector2(18, 35), _name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, fs, CREAM)
	if _rare():
		draw_string(f, Vector2(size.x - 34, 35), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD)
	# art ground
	var art := Rect2(14, 52, size.x - 28, 128)
	draw_rect(art, tint.darkened(0.55), true)
	draw_rect(Rect2(art.position.x, art.position.y + art.size.y * 0.62, art.size.x, art.size.y * 0.38), tint.darkened(0.7), true)
	draw_rect(art, tint.lightened(0.1), false, 2.0)
	# type tags
	var tx := 16.0
	for t in _types:
		var tn := str(t).to_upper()
		var w := f.get_string_size(tn, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 14.0
		draw_style_box(UIKit.box(TypeColours.colour(str(t)), TypeColours.colour(str(t)).darkened(0.4), 1, 8, 0), Rect2(tx, 186, w, 20))
		draw_string(f, Vector2(tx + 7, 201), tn, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TypeColours.text_colour(str(t)))
		tx += w + 6.0
	# stats
	_rows = []
	var y := 212.0
	for i in Trumps.STATS.size():
		var stat: String = Trumps.STATS[i]
		var rr := Rect2(10, y, size.x - 20, 25)
		_rows.append(rr)
		var v := int(card.get(stat, 0))
		var mk := str(marks.get(stat, ""))
		if mk == "win":
			draw_rect(rr, Color(0.30, 0.65, 0.35, 0.45), true)
		elif mk == "lose":
			draw_rect(rr, Color(0.75, 0.28, 0.25, 0.40), true)
		elif mk == "tie":
			draw_rect(rr, Color(0.9, 0.8, 0.4, 0.3), true)
		if selected == stat:
			draw_rect(rr, Color(GOLD, 0.22), true)
			draw_rect(rr, GOLD, false, 2.0)
		var dim := stat in locked
		var tc := MUTED if dim else CREAM
		draw_string(f, Vector2(18, y + 19), str(Trumps.STAT_NAMES[stat]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, tc)
		for k in 10:
			var pc := GOLD if k < v else Color("2c3246")
			if dim and k < v:
				pc = MUTED.darkened(0.3)
			draw_rect(Rect2(98 + k * 11, y + 6, 9, 13), pc, true)
		draw_string(f, Vector2(size.x - 34, y + 20), str(v), HORIZONTAL_ALIGNMENT_RIGHT, 18, 19, GOLD if not dim else MUTED)
		y += 26.0

func _draw_small(f: Font) -> void:
	var tint := _tint()
	_frame(Rect2(Vector2.ZERO, size), 9, 4)
	draw_rect(Rect2(5, 5, size.x - 10, 20), tint.darkened(0.35), true)
	var fs := UIKit.fit_size(_name, size.x - 16.0, 15, 10)
	draw_string(f, Vector2(9, 20), _name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 14.0, fs, CREAM)
	var art := Rect2(8, 28, size.x - 16, 78)
	draw_rect(art, tint.darkened(0.55), true)
	draw_rect(art, tint.lightened(0.1), false, 1.5)
	if silhouette or card.is_empty():
		return
	var cell := (size.x - 16.0) / 5.0
	for i in 5:
		var stat: String = Trumps.STATS[i]
		var cx := 8.0 + cell * (float(i) + 0.5)
		var s := str(int(card.get(stat, 0)))
		var ss := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		draw_string(f, Vector2(cx - ss.x * 0.5, 124), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD)
		draw_string(f, Vector2(cx - 4, 136), str(Trumps.STAT_NAMES[stat]).substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)

func _row_at(p: Vector2) -> String:
	for i in _rows.size():
		if (_rows[i] as Rect2).has_point(p):
			return Trumps.STATS[i]
	return ""

func _gui_input(event: InputEvent) -> void:
	if not full or not picking or not face_up:
		return
	if event is InputEventMouseMotion:
		var s := _row_at(event.position)
		if s != "" and s not in locked:
			stat_hovered.emit(s)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var s := _row_at(event.position)
		if s != "" and s not in locked:
			stat_chosen.emit(s)
