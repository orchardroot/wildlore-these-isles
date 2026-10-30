class_name MapView
extends Control
## Draws the isles from data/world_map.json as a proper wall map: a mottled sea with shallows and ripple lines
## round the coasts, the six nations gently tinted with dashed borders, uplands shaded with little hill marks,
## railways and ferry crossings, towns (visited ones named, the rest a small ring), the player's pin, the
## coast of the nation you're in picked out in gold, and marks for rewilding sites, today's County Show, side
## stories and the post. Also: optional highlighted places (Creaturepedia habitats) and the "Where next?" spot.
## The fills are built once into two meshes (map units) and drawn scaled, so a redraw is cheap.

const SEA := Color("2c5068")
const SEA_DEEP := Color("244459")
const SHALLOW := Color("3b6a80")
const SHALLOWER := Color("4d8193")
const INK := Color("2a3328")
const PAPER := Color("f3ecd6")
const LIT := Color("ffd166")
const PIN := Color("e0574f")
const LAND := {"england": Color("b4bf87"), "wales": Color("9db87c"), "scotland": Color("a9b38e"),
	"northern_ireland": Color("a6bb88"), "ireland": Color("97b97b"), "mann": Color("c1bc88"), "overseas": Color("8c9aa8"), "channel_islands": Color("c4a46a"), "abroad": Color("8c9784")}
const UPLAND := Color(0.42, 0.37, 0.2, 0.09)

var highlight: Array = []   # zone ids to ring in heather purple
var objective := Vector2(-1, -1)  # map units: the "Where next?" spot, ringed in gold; (-1, -1) for none
var zoom := 1.8             # around `centre` (map units); 1.0 shows all the isles
var centre := Vector2(-1, -1)
var cursor := ""            # town id the map cursor sits on ("" for none)
var named_unvisited: Array = []  # unvisited towns that still get a name (the "Where next?" town)
var route := PackedVector2Array()  # map units: the "Route here" polyline, drawn dotted
var marks: Array = []       # MapLogic.marks: rewilding, the show, side stories, the post
var framed := false         # the pause-menu map: a frame, a vignette and a compass
var compass_left := false   # the compass goes top left (the info panel is on the right)
var font: Font
var _italic: FontVariation  # sea and hill names
var _spaced: FontVariation  # NATION NAMES

static var _shapes: Dictionary = {}
static var _shelf: ArrayMesh    # the shallows round every coast
static var _base: ArrayMesh     # land and uplands
static var _paper: ArrayMesh    # the land's mottling (textured with _grain)
static var _ripples: Array = [] # PackedVector2Arrays: faint lines echoing the coast out to sea
static var _grain: ImageTexture

func _ready() -> void:
	clip_contents = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	font = get_theme_default_font()
	_italic = FontVariation.new()
	_italic.base_font = font
	_italic.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.22, 1), Vector2.ZERO)
	_italic.spacing_glyph = 1
	_spaced = FontVariation.new()
	_spaced.base_font = font
	_spaced.spacing_glyph = 6
	resized.connect(queue_redraw)

# --- the data, built once --------------------------------------------------------------------------------------

static func _pv(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(flat.size() / 2)
	for i in out.size():
		out[i] = Vector2(float(flat[i * 2]), float(flat[i * 2 + 1]))
	return out

## The drawing data as PackedVector2Arrays (map units): land and coast per nation ("abroad" is the near
## Continent), borders, uplands ({name, pts, label}), hills (Vector3: x, y, size), rail, ferry_paths (route id ->
## path), seas ({name, x, y}) and nation_labels.
static func shapes() -> Dictionary:
	if not _shapes.is_empty():
		return _shapes
	var m := Travel.world_map()
	var s := {"land": {}, "coast": {}, "borders": [], "uplands": [], "hills": [], "rail": [], "ferry_paths": {},
		"seas": m.get("seas", []), "nation_labels": m.get("nation_labels", {})}
	for key in ["land", "coast"]:
		for n in m.get(key, {}):
			s[key][n] = m[key][n].map(func(f): return _pv(f))
	for f in m.get("borders", []):
		s.borders.append(_pv(f))
	for f in m.get("rail", []):
		s.rail.append(_pv(f))
	for id in m.get("ferry_paths", {}):
		s.ferry_paths[id] = _pv(m.ferry_paths[id])
	for u in m.get("uplands", []):
		s.uplands.append({"name": str(u.name), "pts": _pv(u.pts), "label": u.get("label", [])})
	for h in m.get("hills", []):
		s.hills.append(Vector3(float(h[0]), float(h[1]), float(h[2])))
	_shapes = s
	return s

## Adds a filled polygon (and its holes' worth of nothing) to a mesh being built.
static func _add_fill(arr: Dictionary, ring: PackedVector2Array, col: Color, uv_scale := 0.0) -> void:
	var tris := Geometry2D.triangulate_polygon(ring)
	if tris.is_empty():
		return
	var base: int = arr.v.size()
	for p in ring:
		arr.v.append(p)
		arr.c.append(col)
		arr.uv.append(p * uv_scale)
	for t in tris:
		arr.i.append(base + t)

static func _mesh(arr: Dictionary) -> ArrayMesh:
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = arr.v
	a[Mesh.ARRAY_COLOR] = arr.c
	a[Mesh.ARRAY_TEX_UV] = arr.uv
	a[Mesh.ARRAY_INDEX] = arr.i
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return mesh

static func _new_arr() -> Dictionary:
	return {"v": PackedVector2Array(), "c": PackedColorArray(), "uv": PackedVector2Array(), "i": PackedInt32Array()}

## The outer polygons of a Geometry2D result (holes wind the other way from the biggest piece).
static func _outers(polys: Array) -> Array:
	if polys.is_empty():
		return []
	var big: PackedVector2Array = polys[0]
	for p in polys:
		if p.size() > big.size():
			big = p
	var cw := Geometry2D.is_polygon_clockwise(big)
	return polys.filter(func(p): return Geometry2D.is_polygon_clockwise(p) == cw)

static func _build() -> void:
	if _base != null:
		return
	var s := shapes()
	var shelf := _new_arr()
	var base := _new_arr()
	var paper := _new_arr()
	var all_land: Array = []
	for n in s.land:
		all_land.append_array(s.land[n])
	# shallows: the land grown outwards, opaque so neighbouring islands' shelves merge without seams
	for grow in [[9.0, SHALLOW], [3.5, SHALLOWER]]:
		for ring in all_land:
			for o in _outers(Geometry2D.offset_polygon(ring, grow[0], Geometry2D.JOIN_MITER)):
				_add_fill(shelf, o, grow[1])
	_ripples = []
	for d in [6.0, 14.0]:
		for ring in all_land:
			for o in _outers(Geometry2D.offset_polygon(ring, d, Geometry2D.JOIN_MITER)):
				var closed: PackedVector2Array = o.duplicate()
				closed.append(o[0])
				_ripples.append(closed)
	for n in s.land:
		for ring in s.land[n]:
			_add_fill(base, ring, LAND.get(n, LAND.abroad))
			_add_fill(paper, ring, Color(0.32, 0.26, 0.12, 0.16), 1.0 / 90.0)
	# uplands: clipped to the land, with a darker core
	for u in s.uplands:
		var box := _bounds(u.pts)
		for ring in all_land:
			if not box.intersects(_bounds(ring)):
				continue
			for inset in [0.0, -4.0, -8.0, -13.0]:  # stacked insets: a shade that deepens towards the tops
				var layers: Array = [u.pts] if inset == 0.0 else _outers(Geometry2D.offset_polygon(u.pts, inset))
				for layer in layers:
					for piece in _outers(Geometry2D.intersect_polygons(layer, ring)):
						_add_fill(base, piece, UPLAND)
	_shelf = _mesh(shelf)
	_base = _mesh(base)
	_paper = _mesh(paper)
	_grain = _make_grain()

static func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r.grow(1.0)

## A soft white noise tile (alpha only), for the sea's texture and the land's mottling.
static func _make_grain() -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	var src := noise.get_seamless_image(128, 128)
	var img := Image.create(128, 128, false, Image.FORMAT_LA8)
	for y in 128:
		for x in 128:
			img.set_pixel(x, y, Color(1, 1, 1, src.get_pixel(x, y).r))
	return ImageTexture.create_from_image(img)

# --- where things land ------------------------------------------------------------------------------------------

func _xf() -> Array:
	var m := Travel.world_map()
	var space: Array = m.get("space", [1000, 1300])
	var k := minf(size.x / float(space[0]), size.y / float(space[1])) * zoom
	var c := centre if centre.x >= 0 else Vector2(space[0], space[1]) * 0.5
	var off := size * 0.5 - c * k
	# keep the map on screen: don't scroll past its own edges
	var w := Vector2(space[0], space[1]) * k
	off.x = clampf(off.x, size.x - w.x, 0.0) if w.x > size.x else (size.x - w.x) * 0.5
	off.y = clampf(off.y, size.y - w.y, 0.0) if w.y > size.y else (size.y - w.y) * 0.5
	return [k, off]

## Where a map-space point lands on this control right now.
func screen_pos(map_pos: Vector2) -> Vector2:
	var xf := _xf()
	return _p(map_pos.x, map_pos.y, xf)

func _p(x: float, y: float, xf: Array) -> Vector2:
	return Vector2(x, y) * float(xf[0]) + xf[1]

func _ps(pts: PackedVector2Array, xf: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	var k: float = xf[0]
	var off: Vector2 = xf[1]
	for i in pts.size():
		out[i] = pts[i] * k + off
	return out

## A dashed polyline in screen space whose dashes run on round corners (draw_dashed_line restarts per segment).
func _dashed(pts: PackedVector2Array, col: Color, width: float, dash: float, gap: float) -> void:
	var segs := PackedVector2Array()
	var on := true
	var left := dash
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var len_ab := a.distance_to(b)
		var t := 0.0
		while t < len_ab:
			var step := minf(left, len_ab - t)
			if on:
				segs.append(a.lerp(b, t / len_ab))
				segs.append(a.lerp(b, (t + step) / len_ab))
			t += step
			left -= step
			if left <= 0.001:
				on = not on
				left = dash if on else gap
	if segs.size() >= 2:
		draw_multiline(segs, col, width, true)

# --- drawing ------------------------------------------------------------------------------------------------

func _draw() -> void:
	_build()
	var m := Travel.world_map()
	var s := shapes()
	var xf := _xf()
	var k: float = xf[0]
	var off: Vector2 = xf[1]
	var d: GameStateData = Game.data
	var here := str(d.flag("last_town")) if d.flag("last_town") else ""
	var here_nation := str(m.towns.get(here, {}).get("nation", ""))
	here_nation = "mann" if here_nation == "man" else here_nation
	# the sea, its shelves and texture, then the land
	draw_rect(Rect2(Vector2.ZERO, size), SEA)
	draw_set_transform(off, 0.0, Vector2(k, k))
	draw_mesh(_shelf, null)
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(_grain, Rect2(Vector2.ZERO, size), true, Color(0.75, 0.9, 1.0, 0.07))
	draw_set_transform(off, 0.0, Vector2(k, k))
	for r in _ripples:  # hairlines (negative width): they stay thin whatever the scale
		draw_polyline(r, Color(0.85, 0.95, 1.0, 0.10), -1.0)
	draw_mesh(_base, null)  # over the ripple lines, so they stay out at sea
	draw_mesh(_paper, _grain)
	draw_set_transform(Vector2.ZERO)
	var seen := Rect2(Vector2.ZERO, size).grow(20)
	for v in s.hills:
		var hp := Vector2(v.x, v.y) * k + off
		if seen.has_point(hp):
			_hill(hp, v.z * clampf(k * 1.1, 0.9, 2.0))
	for b in s.borders:  # a soft light band under a dashed ink line
		var pts := _ps(b, xf)
		draw_polyline(pts, Color(PAPER, 0.35), 4.0, true)
		_dashed(pts, Color(INK, 0.55), 1.4, 6.0, 4.0)
	for n in s.coast:
		var col := Color(INK, 0.45) if n == "abroad" else Color(INK, 0.75)
		for c in s.coast[n]:
			draw_polyline(_ps(c, xf), col, 1.3, true)
	if s.coast.has(here_nation):  # the coast of the nation you're in, picked out in gold
		for c in s.coast[here_nation]:
			var pts := _ps(c, xf)
			draw_polyline(pts, Color(LIT, 0.28), 5.0, true)
			draw_polyline(pts, Color(LIT, 0.9), 1.6, true)
	for r in s.rail:
		_dashed(_ps(r, xf), Color("5b4636", 0.5), 1.3, 4.0, 4.0)
	var boats := _draw_ferries(m, s, xf, d)
	if route.size() >= 2:
		var rp := _ps(route, xf)
		_dashed(rp, Color(0, 0, 0, 0.6), 7.0, 3.0, 7.0)
		_dashed(rp, LIT, 4.5, 3.0, 7.0)
	if objective.x >= 0:  # under the town dots and names, so it never hides a label
		var op := _p(objective.x, objective.y, xf)
		draw_arc(op, 16.0, 0, TAU, 28, Color(0, 0, 0, 0.5), 7.0)
		draw_arc(op, 16.0, 0, TAU, 28, LIT, 4.0)
		draw_arc(op, 23.0, 0, TAU, 32, Color(LIT, 0.45), 2.0)
	for zid in highlight:
		var src: Dictionary = m.get("towns", {}).get(zid, m.get("places", {}).get(zid, {}))
		if not src.is_empty():
			draw_arc(_p(float(src.x), float(src.y), xf), 10.0, 0, TAU, 20, UIKit.HEATHER, 4.0)
	_draw_towns(m, xf, d, here, boats)
	if framed:
		_draw_frame()

## A little shaded hill: a lit west face and a shadowed east face.
func _hill(p: Vector2, sz: float) -> void:
	var top := p + Vector2(0, -sz * 0.8)
	var l := p + Vector2(-sz, 0)
	var r := p + Vector2(sz, 0)
	draw_colored_polygon(PackedVector2Array([l, top, p + Vector2(sz * 0.1, 0)]), Color(1, 0.98, 0.85, 0.3))
	draw_colored_polygon(PackedVector2Array([p + Vector2(sz * 0.1, 0), top, r]), Color(0.25, 0.2, 0.1, 0.3))
	draw_polyline(PackedVector2Array([l, top, r]), Color(0.3, 0.24, 0.12, 0.55), 1.0, true)

## Draws the crossings; returns the little boats' rects, so no label sits on one.
func _draw_ferries(m: Dictionary, s: Dictionary, xf: Array, d: GameStateData) -> Array:
	var boats := []
	var routes: Dictionary = Travel.ferries()
	for id in routes:
		var r: Dictionary = routes[id]
		var pts: PackedVector2Array
		if s.ferry_paths.has(id):
			pts = _ps(s.ferry_paths[id], xf)
		else:
			var a: Dictionary = m.towns.get(str(r.a), {})
			var b: Dictionary = m.towns.get(str(r.b), {})
			if a.is_empty() or b.is_empty():
				continue
			pts = PackedVector2Array([_p(float(a.x), float(a.y), xf), _p(float(b.x), float(b.y), xf)])
		var known: bool = d.flag("visited_" + str(r.a)) == true or d.flag("visited_" + str(r.b)) == true
		_dashed(pts, Color(PAPER, 0.85 if known else 0.4), 2.0, 7.0, 5.0)
		if known and pts.size() >= 2:  # a little boat halfway across
			var mid := pts.size() / 2
			var at := pts[mid - 1].lerp(pts[mid], 0.5) if pts.size() % 2 == 0 else pts[mid]
			draw_colored_polygon(PackedVector2Array([at + Vector2(-8, -2), at + Vector2(8, -2), at + Vector2(5, 3), at + Vector2(-5, 3)]), PAPER)
			draw_rect(Rect2(at + Vector2(-2, -7), Vector2(4, 5)), Color("c44d3f"))
			boats.append(Rect2(at + Vector2(-9, -8), Vector2(18, 12)))
	return boats

## Sea, upland and nation names as label items: each sits centred on its spot or not at all, after the towns.
func _name_items(s: Dictionary, xf: Array) -> Array:
	var out := []
	var add := func(id: String, f: Font, txt: String, at: Vector2, fs: int, col: Color) -> void:
		var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs) + Vector2(6, 4)
		out.append({"id": id, "at": at, "size": sz, "spots": [-sz * 0.5], "text": txt, "fs": fs, "font": f, "col": col})
	for sea in s.seas:
		add.call("sea_" + str(sea.name), _italic, str(sea.name), _p(float(sea.x), float(sea.y), xf), 17, Color(0.86, 0.94, 1.0, 0.5))
	for n in s.nation_labels:
		var at: Array = s.nation_labels[n]
		add.call("nation_" + n, _spaced, Standing.name_of(n).to_upper(), _p(float(at[0]), float(at[1]), xf), 20, Color(INK, 0.3))
	for u in s.uplands:
		if u.label.size() == 2:
			add.call("hill_" + str(u.name), _italic, str(u.name), _p(float(u.label[0]), float(u.label[1]), xf), 14, Color(0.3, 0.22, 0.1, 0.75))
	return out

func _centred(f: Font, txt: String, at: Vector2, fsize: int, col: Color) -> void:
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	draw_string(f, at + Vector2(-w * 0.5, fsize * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)

func _draw_towns(m: Dictionary, xf: Array, d: GameStateData, here: String, boats: Array) -> void:
	var blockers: Array = boats.duplicate()
	if framed:  # nothing over the frame: four bands just inside the edge
		var w := size.x
		var h := size.y
		blockers.append_array([Rect2(-100, -100, w + 200, 114), Rect2(-100, h - 14, w + 200, 114),
			Rect2(-100, -100, 114, h + 200), Rect2(w - 14, -100, 114, h + 200)])
	var pin_at := Vector2(-1, -1)
	if here != "" and m.towns.has(here):
		pin_at = _p(float(m.towns[here].x), float(m.towns[here].y), xf)
		blockers.append(Rect2(pin_at + Vector2(-10, -30), Vector2(20, 32)))
	# marks sit in a little row up and right of their place
	var icons: Array = []  # [kind, centre, mark]
	var per_place := {}
	for mk in marks:
		var mp := MapLogic.mark_point(mk)
		if mp.x < 0:
			continue
		var n: int = per_place.get(mk.at, 0)
		per_place[mk.at] = n + 1
		var c := _p(mp.x, mp.y, xf) + Vector2(14 + n * 20, -16)
		if str(mk.at) == here:
			c.x += 8  # round the pin
		icons.append([mk, c])
		blockers.append(Rect2(c - Vector2(10, 10), Vector2(20, 22 if mk.kind == "rewild" else 20)))
	var items: Array = []
	var dots: Array = []
	for town in m.get("towns", {}):
		if not FileAccess.file_exists("res://data/zones/%s.json" % town):
			continue
		var t: Dictionary = m.towns[town]
		var pos := _p(float(t.x), float(t.y), xf)
		var visited: bool = d.flag("visited_" + town) == true
		dots.append([pos, visited])
		blockers.append(Rect2(pos - Vector2(5, 5), Vector2(10, 10)))
		if visited or town in named_unvisited:
			var fs := 16 if visited else 15
			var txt := str(t.name) if visited else str(t.name) + "?"
			var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs) + Vector2(4, 0)
			var item := {"id": town, "at": pos, "size": Vector2(sz.x, fs + 4), "text": txt, "fs": fs, "visited": visited}
			if town == here or town == cursor or not visited:
				items.push_front(item)  # these get first pick of the spots
			else:
				items.append(item)
	for dot in dots:
		if dot[1]:
			draw_circle(dot[0], 6.0, Color(INK, 0.85))
			draw_circle(dot[0], 4.2, PAPER)
		else:
			draw_arc(dot[0], 3.6, 0, TAU, 14, Color(INK, 0.55), 1.6, true)
	var names := _name_items(shapes(), xf)
	var placed := MapLogic.place_labels(items + names, blockers, dots.map(func(dd): return dd[0]))
	for it in names:
		if placed.has(it.id):
			var r: Rect2 = placed[it.id]
			draw_string(it.font, r.position + Vector2(3, r.size.y * 0.5 + it.fs * 0.36), it.text, HORIZONTAL_ALIGNMENT_LEFT, -1, it.fs, it.col)
	for it in items:
		if not placed.has(it.id):
			continue
		var r: Rect2 = placed[it.id]
		var near := Vector2(clampf(it.at.x, r.position.x, r.end.x), clampf(it.at.y, r.position.y, r.end.y))
		if near.distance_to(it.at) > 16.0:  # nudged well away: a fine leader line back to the dot
			draw_line(it.at, near, Color(INK, 0.6), 1.0, true)
		var base := r.position + Vector2(2, r.size.y * 0.5 + it.fs * 0.36)
		var col := INK if it.visited else Color(INK, 0.75)
		draw_string_outline(font, base, it.text, HORIZONTAL_ALIGNMENT_LEFT, -1, it.fs, 5, Color(PAPER, 0.85))
		draw_string(font, base, it.text, HORIZONTAL_ALIGNMENT_LEFT, -1, it.fs, col)
	if cursor != "" and m.towns.has(cursor):
		var cp := _p(float(m.towns[cursor].x), float(m.towns[cursor].y), xf)
		draw_arc(cp, 11.0, 0, TAU, 28, Color(0, 0, 0, 0.55), 5.0, true)
		draw_arc(cp, 11.0, 0, TAU, 28, Color.WHITE, 2.5, true)
	for ic in icons:
		_icon(ic[0], ic[1])
	if pin_at.x >= 0:
		_pin(pin_at)

## The player's pin, its point on the town.
func _pin(at: Vector2) -> void:
	draw_set_transform(at + Vector2(3, -1), 0.0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	var head := at + Vector2(0, -20)
	draw_colored_polygon(PackedVector2Array([at, head + Vector2(-7.5, 3), head + Vector2(7.5, 3)]), Color("a83a34"))
	draw_circle(head, 9.0, Color("a83a34"))
	draw_circle(head, 7.6, PIN)
	draw_circle(head + Vector2(-2, -2), 3.4, Color(1, 1, 1, 0.95))

func _icon(mk: Dictionary, c: Vector2) -> void:
	match str(mk.kind):
		"rewild":  # a leaf, and three pips for Planted, Recovering, Wild
			var leaf := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				leaf.append(c + Vector2(-8 + 16 * t, -sin(t * PI) * 6.5).rotated(-0.5))
			for i in range(11, 0, -1):
				var t := float(i) / 12.0
				leaf.append(c + Vector2(-8 + 16 * t, sin(t * PI) * 6.5).rotated(-0.5))
			draw_colored_polygon(leaf, Color("3f7f3a"))
			draw_polyline(leaf, Color("20401d"), 1.2, true)
			draw_line(c + Vector2(-8, 0).rotated(-0.5), c + Vector2(7, 0).rotated(-0.5), Color("bfe3a6"), 1.2, true)
			for i in 3:
				var pp := c + Vector2(-7 + i * 7, 10)
				draw_circle(pp, 3.0, Color(INK, 0.85))
				draw_circle(pp, 2.0, Color("8fd16e") if int(mk.stage) > i else Color(PAPER, 0.5))
		"show":  # a rosette: ribbons, then a ring of petals and a gold heart
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2, 2), c + Vector2(-8, 12), c + Vector2(-3, 10), c + Vector2(1, 3)]), Color("2f5fb0"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(2, 2), c + Vector2(8, 12), c + Vector2(3, 10), c + Vector2(-1, 3)]), Color("2f5fb0"))
			draw_circle(c, 8.5, Color("7a1f1f"))
			for i in 10:
				draw_circle(c + Vector2(6.2, 0).rotated(TAU * i / 10.0), 2.6, Color("d23c3c"))
			draw_circle(c, 4.2, LIT)
		"side":  # a speech bubble
			var r := Rect2(c - Vector2(9, 7), Vector2(18, 13))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 5), c + Vector2(-8, 11), c + Vector2(1, 5)]), PAPER)
			draw_rect(r, PAPER)
			draw_rect(r, Color(INK, 0.9), false, 1.4)
			for i in 3:
				draw_circle(c + Vector2(-4.5 + i * 4.5, -0.5), 1.4, INK)
		"trail":  # a gold-ringed "?", where a treasure trail ends
			draw_circle(c, 9.5, Color(INK, 0.9))
			draw_circle(c, 8.0, LIT)
			draw_string(ThemeDB.fallback_font, c + Vector2(-4.5, 6.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
		"poi":  # a question mark on a ring; done, the little picture of what it was
			draw_circle(c, 9.0, Color(INK, 0.9))
			draw_circle(c, 7.6, PAPER)
			if not mk.done:
				draw_string(font, c + Vector2(-4.2, 5.4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
			else:
				match str(mk.poi):
					"den":
						draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 4), c + Vector2(-3, -2), c + Vector2(0, -4), c + Vector2(3, -2), c + Vector2(5, 4)]), INK)
					"camp":
						draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 4), c + Vector2(0, -5), c + Vector2(5, 4)]), INK)
					"stone":
						draw_rect(Rect2(c + Vector2(-2.5, -5), Vector2(5, 10)), INK)
					_:
						draw_rect(Rect2(c + Vector2(-4, -2), Vector2(8, 6)), INK)
		"post":  # an envelope with a red seal
			var r := Rect2(c - Vector2(9, 6), Vector2(18, 12))
			draw_rect(r, PAPER)
			draw_rect(r, Color(INK, 0.9), false, 1.4)
			draw_polyline(PackedVector2Array([r.position, c + Vector2(0, 1), r.position + Vector2(18, 0)]), Color(INK, 0.9), 1.2, true)
			draw_circle(c + Vector2(0, 1), 2.4, Color("c44d3f"))

## The wall-map dressing: a soft vignette, a double rule round the edge and a compass rose.
func _draw_frame() -> void:
	var w := size.x
	var h := size.y
	var edge := Color(0.05, 0.08, 0.12, 0.45)
	var clear := Color(0.05, 0.08, 0.12, 0.0)
	var b := 70.0
	for q in [[Vector2(0, 0), Vector2(w, 0), Vector2(w - b, b), Vector2(b, b)], [Vector2(0, h), Vector2(w, h), Vector2(w - b, h - b), Vector2(b, h - b)],
			[Vector2(0, 0), Vector2(0, h), Vector2(b, h - b), Vector2(b, b)], [Vector2(w, 0), Vector2(w, h), Vector2(w - b, h - b), Vector2(w - b, b)]]:
		draw_polygon(PackedVector2Array(q), PackedColorArray([edge, edge, clear, clear]))
	draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), Color(PAPER, 0.55), false, 2.0)
	draw_rect(Rect2(Vector2(11, 11), size - Vector2(22, 22)), Color(PAPER, 0.25), false, 1.0)
	var c := Vector2(54, 112) if compass_left else Vector2(w - 54, 58)  # on the left, clear of the Fly button
	draw_circle(c, 26.0, Color(SEA_DEEP, 0.6))
	draw_arc(c, 26.0, 0, TAU, 32, Color(PAPER, 0.6), 1.5, true)
	draw_arc(c, 21.0, 0, TAU, 32, Color(PAPER, 0.3), 1.0, true)
	for i in 4:
		var dir := Vector2.UP.rotated(TAU * i / 4.0)
		var side := dir.orthogonal() * 5.0
		var tip := c + dir * (22.0 if i == 0 else 17.0)
		draw_colored_polygon(PackedVector2Array([c + side, tip, c]), Color(PAPER, 0.95))
		draw_colored_polygon(PackedVector2Array([c - side, tip, c]), Color(PAPER, 0.45) if i != 0 else Color(PIN, 0.95))
	_centred(font, "N", c + Vector2(0, -36), 15, Color(PAPER, 0.9))
