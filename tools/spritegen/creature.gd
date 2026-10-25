extends RefCounted
## Creature renderer: recipe dictionary -> front/back sheets (two square frames side by side, each 96 art units
## drawn at SCALE pixels per unit, so 384x192) and icon (32x32). Recipes are in art units on a 96 grid.
## Recipe layers are drawn in order with light from the top-left. See art/recipes/creatures/*.json.
## The sheets use the smooth canvas (anti-aliased, soft shading, see smooth_canvas.gd); the icon keeps the crisp
## pixel canvas, so it stays sharp at 32 px.
##
## Layer fields: shape (ellipse|circle|rect|poly|tri|line), at [x,y] (centre), size [w,h], r,
## points [[x,y]..], width (line), angle (deg), round (rect corner radius), colour (palette name
## or #hex), shade (default true), rim (default: on for big layers), pattern, pcolour, period,
## density, n, mirror (also draw reflected about x=48), front_only, back_only.
## Recipe fields: palette, layers, back_layers, face_layers (front only, drawn after the outline),
## eyes, outline, anim ("squash" default or "shift"), bob, icon_box.
## Back view (see back_layers): derived from `layers` seen from behind, tuned with back_over,
## back_hide, back_marks and back_auto.
## Sexes: "dimorph": {"f": {...}, "m": {...}} lists how each sex differs from the base recipe (see apply_dimorph);
## tools/spritegen.gd renders <id>_f.png, <id>_f_back.png and <id>_f_icon.png (and _m) beside the usual files.

const Canvas = preload("res://tools/spritegen/canvas.gd")
const SmoothCanvas = preload("res://tools/spritegen/smooth_canvas.gd")
const SIZE := 96      # art units per frame
const SCALE := 2      # pixels per art unit on the battle sheets (displayed at the old size, filtered)
const AXIS := 96.0

## `scale`: pixels per art unit for the sheets (1 gives the old 192x96 size, still smooth).
static func render(recipe: Dictionary, scale := SCALE) -> Dictionary:
	var front := _sheet(recipe, false, scale)
	var back := _sheet(recipe, true, scale)
	var icon := _icon(recipe)
	return {"front": front, "back": back, "icon": icon}

const DIMORPH_KEYS := ["palette", "drop", "drop_face", "set", "add_layers", "add_face_layers", "add_back_marks"]

## The recipe for one sex ("m" or "f"): the base recipe with its dimorph overrides for that sex applied, or {} if
## the recipe has none for it. Override keys: palette (colours merged in), drop (layer indices removed),
## drop_face (face_layers indices removed), set ({"7": {"colour": ...}}: fields changed on a layer by index),
## add_layers / add_face_layers / add_back_marks (appended), and any other recipe key, which replaces the base one.
## Indices always refer to the base recipe's lists, so overrides read against the file.
static func apply_dimorph(recipe: Dictionary, sex: String) -> Dictionary:
	var all: Dictionary = recipe.get("dimorph", {})
	if not all.has(sex) or not (all[sex] is Dictionary):
		return {}
	var ov: Dictionary = all[sex]
	var r: Dictionary = recipe.duplicate(true)
	r.erase("dimorph")
	var pal: Dictionary = r.get("palette", {})
	for k in ov.get("palette", {}):
		pal[k] = ov["palette"][k]
	if not pal.is_empty():
		r["palette"] = pal
	var set_: Dictionary = ov.get("set", {})
	var layers: Array = r.get("layers", [])
	for key in set_:
		var i := int(key)
		if i >= 0 and i < layers.size():
			for f in set_[key]:
				layers[i][f] = set_[key][f]
	var drop := _ints(ov.get("drop", []))
	var kept: Array = []
	var remap := {}  # base index -> index once the dropped layers are gone
	for i in layers.size():
		if i in drop:
			continue
		remap[i] = kept.size()
		kept.append(layers[i])
	kept.append_array(ov.get("add_layers", []))
	r["layers"] = kept
	for key in ["back_over", "back_hide"]:  # index lists must follow the layers they name
		if r.has(key):
			var moved: Array = []
			for i in _ints(r[key]):
				if remap.has(i):
					moved.append(remap[i])
			r[key] = moved
	var faces: Array = []
	var drop_face := _ints(ov.get("drop_face", []))
	var base_faces: Array = r.get("face_layers", [])
	for i in base_faces.size():
		if not (i in drop_face):
			faces.append(base_faces[i])
	faces.append_array(ov.get("add_face_layers", []))
	if not faces.is_empty():
		r["face_layers"] = faces
	var marks: Array = r.get("back_marks", [])
	marks.append_array(ov.get("add_back_marks", []))
	if not marks.is_empty():
		r["back_marks"] = marks
	for k in ov:
		if not (k in DIMORPH_KEYS):
			r[k] = ov[k]
	return r

static func _palette(recipe: Dictionary, darken: float) -> Dictionary:
	var pal := {}
	for k in recipe.get("palette", {}):
		pal[k] = Canvas.tones_from(recipe["palette"][k], darken)
	return pal

static func _tones_for(name, pal: Dictionary, darken: float) -> Array:
	var s := str(name)
	if pal.has(s):
		return pal[s]
	return Canvas.tones_from(s, darken)

static func _sheet(recipe: Dictionary, is_back: bool, scale := SCALE) -> Image:
	var px := SIZE * scale
	var out := Image.create(px * 2, px, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var layers: Array = recipe.get("layers", [])
	if is_back:
		layers = back_layers(recipe)
	var base = _draw_all(recipe, layers, is_back, null, true, scale)
	var bounds: Rect2i = base.content_bounds()
	out.blit_rect(base.img, Rect2i(0, 0, px, px), Vector2i(0, 0))
	var xf := {"mode": str(recipe.get("anim", "squash")), "bob": float(recipe.get("bob", 2.0)),
		"bottom": float(bounds.end.y - 1), "height": float(bounds.size.y)}
	var f2 = _draw_all(recipe, layers, is_back, xf, true, scale)
	out.blit_rect(f2.img, Rect2i(0, 0, px, px), Vector2i(px, 0))
	return out

## The rear view, derived from the front recipe: everything is seen from the other side, so the
## layers are flipped left to right, and parts tucked behind the body in the front view (a tail,
## a lone wing) come round in front of it. `back_over` (indices into `layers`) overrides which
## parts come forward, [] for none. The body gets a darker countershaded saddle unless
## `back_auto` is false. `back_marks` (back-view coordinates, already seen from behind) are
## markings that only show from behind (a dorsal stripe, the knot of a mask, a tail): drawn last,
## over everything, or straight after the body with "under": true so limbs and head sit on top.
## `back_hide` (indices into `layers`) drops parts the marks replace.
static func back_layers(recipe: Dictionary) -> Array:
	var src: Array = recipe.get("back_layers", recipe.get("layers", []))
	var over: Array = _ints(recipe.get("back_over", _auto_over(src)) if not recipe.has("back_layers") else recipe.get("back_over", []))
	var hide: Array = _ints(recipe.get("back_hide", []))
	var under: Array = []
	var top: Array = []
	var after_body: Array = []
	var body := _body_index(src, hide)
	if recipe.get("back_auto", true) and not recipe.has("back_layers"):
		after_body = _auto_marks(recipe, src, body)
	for m in recipe.get("back_marks", []):
		var l: Dictionary = (m as Dictionary).duplicate(true)
		l["back_only"] = true
		if l.get("under", false) and body >= 0:
			after_body.append(l)
		else:
			top.append(l)
	var over_layers: Array = []
	for i in src.size():
		if not (i in hide):
			var l: Dictionary = _flip_layer(src[i])
			if i in over:
				over_layers.append(l)
			else:
				under.append(l)
		if i == body:
			under.append_array(after_body)
	if body < 0:
		under.append_array(after_body)
	return under + over_layers + top

## Layer indices as ints (JSON numbers arrive as floats, and 1.0 is not `in` [1]).
static func _ints(a: Array) -> Array:
	var out: Array = []
	for v in a:
		out.append(int(v))
	return out

## Layer indices that sit behind the main body in the front view and stick out to one side
## (tails, a single wing or limb): those face the camera from behind.
static func _auto_over(layers: Array) -> Array:
	var main := -1
	var main_area := 0.0
	for i in layers.size():
		var l: Dictionary = layers[i]
		if l.get("front_only", false) or str(l.get("shape", "ellipse")) == "line":
			continue
		var bb := _layer_box(l)
		if bb.get_center().y > 86.0:
			continue
		if bb.get_area() > main_area:
			main_area = bb.get_area()
			main = i
	var out: Array = []
	if main < 0:
		return out
	var mb := _layer_box(layers[main])
	for i in main:
		var l: Dictionary = layers[i]
		if l.get("front_only", false) or l.get("mirror", false) or str(l.get("shape", "ellipse")) == "line":
			continue
		var bb := _layer_box(l)
		var c := bb.get_center()
		# a back-only rump part (scut, tail feathers) tucked under the body by draw order
		if l.get("back_only", false) and absf(c.x - AXIS * 0.5) < 8.0 and c.y > mb.get_center().y \
				and bb.get_area() < main_area * 0.5 and bb.intersects(mb):
			out.append(i)
			continue
		if absf(c.x - AXIS * 0.5) < 12.0 or c.y > 86.0:
			continue
		if bb.get_area() > main_area * 0.75 or not bb.intersects(mb):
			continue
		out.append(i)
	return out

## Index of the body: the biggest plain layer standing above the ground line, or -1.
static func _body_index(layers: Array, hide: Array = []) -> int:
	var body := -1
	var area := 0.0
	for i in layers.size():
		var l: Dictionary = layers[i]
		if i in hide or l.get("front_only", false) or not (str(l.get("shape", "ellipse")) in ["ellipse", "circle"]):
			continue
		var bb := _layer_box(l)
		var c := bb.get_center()
		if c.y > 86.0 or c.y < 50.0 or absf(c.x - AXIS * 0.5) > 4.0:
			continue
		if bb.get_area() > area:
			area = bb.get_area()
			body = i
	return body

## Countershading: animals are darker along the back than the belly, so the body gets a darker
## saddle (the palette's "<colour>2" if the design has one, else a deeper tone of the body colour)
## with a dithered fringe. Skipped for bodies that already carry a pattern.
static func _auto_marks(recipe: Dictionary, layers: Array, bi: int) -> Array:
	if bi < 0:
		return []
	var b: Dictionary = layers[bi]
	if str(b.get("pattern", "none")) in ["spines", "stripes"] or not bool(b.get("shade", true)):
		return []
	var cname := str(b.get("colour", ""))
	var pal: Dictionary = recipe.get("palette", {})
	var dark: String
	if pal.has(cname + "2"):
		dark = cname + "2"
	else:
		var base := Canvas.parse_colour(pal.get(cname, cname)) if not (pal.get(cname, cname) is Dictionary) else Canvas.parse_colour(pal[cname].get("base", "#888888"))
		var t := Canvas.tones(base)
		dark = "#" + base.lerp(t[1], 0.55).to_html(false)
	var bb := _layer_box(b)
	var cx := AXIS - bb.get_center().x
	var cy := bb.get_center().y - bb.size.y * 0.1
	var out: Array = []
	out.append({"shape": "ellipse", "at": [cx, cy], "size": [bb.size.x * 0.66, bb.size.y * 0.62], "colour": cname,
		"pattern": "speckle", "pcolour": dark, "density": 45, "rim": false, "seed": 5})
	out.append({"shape": "ellipse", "at": [cx, cy - bb.size.y * 0.04], "size": [bb.size.x * 0.52, bb.size.y * 0.5], "colour": dark,
		"rim": false, "pattern": str(b.get("pattern", "none")), "pcolour": b.get("pcolour", dark), "density": int(b.get("density", 9))})
	return out

## Rough bounding box of a layer in sprite pixels.
static func _layer_box(l: Dictionary) -> Rect2:
	if l.has("points"):
		var r := Rect2(float(l["points"][0][0]), float(l["points"][0][1]), 0, 0)
		for p in l["points"]:
			r = r.expand(Vector2(float(p[0]), float(p[1])))
		return r
	var at: Array = l.get("at", [48, 48])
	var wh: Array = l["size"] if l.has("size") else [float(l.get("r", 4)) * 2.0, float(l.get("r", 4)) * 2.0]
	var w := float(wh[0])
	var h := float(wh[1])
	if absf(float(l.get("angle", 0.0))) > 30.0:
		var s := maxf(w, h)
		w = s
		h = s
	return Rect2(float(at[0]) - w * 0.5, float(at[1]) - h * 0.5, w, h)

## The same layer seen from behind: reflected about the centre line (a mirrored pair stays a pair).
static func _flip_layer(layer: Dictionary) -> Dictionary:
	var keep_mirror: bool = layer.get("mirror", false)
	var seed_v = layer.get("seed", null)
	var l := _mirror_layer(layer)
	if keep_mirror:
		l["mirror"] = true
	if seed_v == null:
		l.erase("seed")
	else:
		l["seed"] = seed_v
	return l

## Applies the breathing transform to a copy of a layer.
static func _xf_layer(layer: Dictionary, xf) -> Dictionary:
	if xf == null:
		return layer
	var l := layer.duplicate(true)
	var b: float = xf.bottom
	var s := 1.0
	var shift := 0.0
	if xf.mode == "shift":
		shift = xf.bob
	else:
		s = maxf(0.5, (xf.height - xf.bob) / xf.height)
	var ty := func(y: float) -> float: return b - (b - y) * s + shift
	if l.has("at"):
		l["at"] = [l["at"][0], ty.call(float(l["at"][1]))]
	if l.has("points"):
		var np: Array = []
		for p in l["points"]:
			np.append([p[0], ty.call(float(p[1]))])
		l["points"] = np
	if s != 1.0:
		if l.has("size"):
			l["size"] = [l["size"][0], float(l["size"][1]) * s]
		elif l.has("r") and str(l.get("shape", "")) == "circle":
			var r := float(l["r"])
			l["shape"] = "ellipse"
			l["size"] = [r * 2.0, r * 2.0 * s]
	return l

static func _mirror_layer(layer: Dictionary) -> Dictionary:
	var l := layer.duplicate(true)
	if l.has("at"):
		l["at"] = [AXIS - float(l["at"][0]), l["at"][1]]
	if l.has("points"):
		var np: Array = []
		for p in l["points"]:
			np.append([AXIS - float(p[0]), p[1]])
		l["points"] = np
	if l.has("angle"):
		l["angle"] = -float(l["angle"])
	if l.has("angle_p"):
		l["angle_p"] = 180.0 - float(l["angle_p"])
	l["seed"] = int(l.get("seed", 1)) + 7
	l.erase("mirror")
	return l

static func _draw_layer(cv, layer: Dictionary, pal: Dictionary, darken: float, xf) -> void:
	var l := _xf_layer(layer, xf)
	var shape := str(l.get("shape", "ellipse"))
	var m: Dictionary
	var minside := 99.0
	match shape:
		"ellipse", "circle":
			var at: Array = l["at"]
			var wh = [float(l["r"]) * 2.0, float(l["r"]) * 2.0] if l.has("r") and not l.has("size") else l["size"]
			m = cv.ellipse_mask(float(at[0]), float(at[1]), float(wh[0]), float(wh[1]), float(l.get("angle", 0.0)))
			minside = minf(float(wh[0]), float(wh[1]))
		"rect":
			var at: Array = l["at"]
			var wh: Array = l["size"]
			m = cv.rect_mask(float(at[0]), float(at[1]), float(wh[0]), float(wh[1]), float(l.get("angle", 0.0)), float(l.get("round", 0.0)))
			minside = minf(float(wh[0]), float(wh[1]))
		"poly", "tri":
			var pts: Array = []
			for p in l["points"]:
				pts.append(Vector2(float(p[0]), float(p[1])))
			m = cv.poly_mask(pts)
			minside = minf(m.bb.size.x, m.bb.size.y)
		"spikes":
			var at: Array = l["at"]
			var wh: Array = l["size"]
			var pts := _spike_points(float(at[0]), float(at[1]), float(wh[0]) * 0.5, float(wh[1]) * 0.5, int(l.get("count", 9)), float(l.get("len", 8.0)), float(l.get("from", -195.0)), float(l.get("to", 15.0)), int(l.get("seed", 1)))
			m = cv.poly_mask(pts)
			minside = minf(float(wh[0]), float(wh[1]))
		"line":
			var lp: Array = []
			for p in l["points"]:
				lp.append(Vector2(float(p[0]), float(p[1])))
			m = cv.line_mask(lp, float(l.get("width", 2.0)))
			minside = 0.0
		_:
			push_error("spritegen: unknown shape " + shape)
			return
	var opt := {
		"shade": bool(l.get("shade", true)),
		"rim": bool(l.get("rim", minside >= 9.0)),
		"pattern": str(l.get("pattern", "none")),
		"seed": int(l.get("seed", 1)),
		"period": float(l.get("period", 6.0)),
		"angle": float(l.get("pangle", 60.0)),
		"density": int(l.get("density", 9)),
		"n": float(l.get("n", 26)),
	}
	if l.has("pcolour"):
		opt["pcol"] = _tones_for(l["pcolour"], pal, darken)
	cv.paint(m, _tones_for(l.get("colour", "#ff00ff"), pal, darken), opt)

## Polygon of a centre point plus spikes around an elliptical arc (angles in degrees, y down).
static func _spike_points(cx: float, cy: float, rx: float, ry: float, count: int, length: float, from_deg: float, to_deg: float, seed_v: int) -> Array:
	var pts: Array = [Vector2(cx, cy)]
	var step := (to_deg - from_deg) / float(count)
	for i in count:
		var a0 := deg_to_rad(from_deg + step * i)
		var a1 := deg_to_rad(from_deg + step * (i + 1))
		var am := (a0 + a1) * 0.5
		var k := 0.7 + 0.3 * float(Canvas.hash2(i, 3, seed_v) % 3) / 2.0
		pts.append(Vector2(cx + cos(a0) * rx, cy + sin(a0) * ry))
		pts.append(Vector2(cx + cos(am) * (rx + length * k), cy + sin(am) * (ry + length * k)))
	var ae := deg_to_rad(to_deg)
	pts.append(Vector2(cx + cos(ae) * rx, cy + sin(ae) * ry))
	return pts

static func _draw_list(cv, layers: Array, pal: Dictionary, darken: float, xf, is_back: bool) -> void:
	for layer in layers:
		if is_back and layer.get("front_only", false):
			continue
		if (not is_back) and layer.get("back_only", false):
			continue
		_draw_layer(cv, layer, pal, darken, xf)
		if layer.get("mirror", false):
			_draw_layer(cv, _mirror_layer(layer), pal, darken, xf)

## scale 0: the crisp pixel canvas (the icon); otherwise the smooth canvas at that many pixels per art unit.
static func _draw_all(recipe: Dictionary, layers: Array, is_back: bool, xf, with_outline: bool, scale := 0):
	var darken := 0.04 if is_back else 0.0
	var pal := _palette(recipe, darken)
	var cv = Canvas.new(SIZE, SIZE) if scale <= 0 else SmoothCanvas.new(SIZE, SIZE, scale)
	_draw_list(cv, layers, pal, darken, xf, is_back)
	if with_outline:
		var oc = recipe.get("outline", null)
		cv.outline(null if oc == null or str(oc) == "auto" else Canvas.parse_colour(oc))
	if not is_back:
		_draw_list(cv, recipe.get("face_layers", []), pal, darken, xf, false)
		for e in recipe.get("eyes", []):
			_draw_eye(cv, e, pal, xf)
			if e.get("mirror", false):
				var me: Dictionary = e.duplicate(true)
				me["at"] = [AXIS - float(e["at"][0]), e["at"][1]]
				_draw_eye(cv, me, pal, xf)
	return cv

static func _draw_eye(cv, e: Dictionary, pal: Dictionary, xf) -> void:
	var el := _xf_layer({"at": e["at"]}, xf)
	var col := Color.html("#1d1822")
	if e.has("colour"):
		col = _tones_for(e["colour"], pal, 0.0)[0]
	var at: Array = el["at"]
	cv.eye(float(at[0]), float(at[1]), float(e.get("r", 4)), col, bool(e.get("highlight", true)), e.get("pupil", null))

static func _icon(recipe: Dictionary) -> Image:
	var layers: Array = recipe.get("layers", [])
	var raw = _draw_all(recipe, layers, false, null, false)
	var box: Rect2i
	if recipe.has("icon_box"):
		var b: Array = recipe["icon_box"]
		box = Rect2i(int(b[0]), int(b[1]), int(b[2]), int(b[3]))
	else:
		box = raw.content_bounds()
	var side := maxi(box.size.x, box.size.y)
	var ox := box.position.x - (side - box.size.x) / 2.0
	var oy := box.position.y - (side - box.size.y) / 2.0
	var target := 28
	var f := float(side) / float(target)
	var cv = Canvas.new(32, 32)
	for j in target:
		for i in target:
			var x0 := int(floor(ox + i * f))
			var x1 := maxi(x0 + 1, int(floor(ox + (i + 1) * f)))
			var y0 := int(floor(oy + j * f))
			var y1 := maxi(y0 + 1, int(floor(oy + (j + 1) * f)))
			var n := 0
			var cnt := 0
			var rr := 0.0
			var gg := 0.0
			var bb := 0.0
			for y in range(y0, y1):
				for x in range(x0, x1):
					n += 1
					if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
						continue
					var c: Color = raw.img.get_pixel(x, y)
					if c.a > 0.0:
						cnt += 1
						rr += c.r
						gg += c.g
						bb += c.b
			if n > 0 and cnt * 2 >= n:
				cv.img.set_pixel(i + 2, j + 2, Color(rr / cnt, gg / cnt, bb / cnt, 1.0))
	var oc = recipe.get("outline", null)
	cv.outline(null if oc == null or str(oc) == "auto" else Canvas.parse_colour(oc))
	return cv.img
