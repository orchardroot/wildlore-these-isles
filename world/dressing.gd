class_name Dressing
extends RefCounted
## Props that make places look lived in: bunting, flags, washing lines, hanging baskets outdoors; rugs,
## fireplaces, pictures, pianos and the like indoors. Same rules as Meshes: vertex colours, y = 0 at the
## origin, one tile unless noted. Anything cloth (bunting, flags, laundry) is built in the local XY plane and
## carries its flutter in the vertex alpha (0 = pinned, 1 = free), see art/shaders/flutter.gdshader. Wall
## things sit against the north wall: their back is at local z = -0.5, so `rot` turns them to another wall.

const IRON := Color("2d3138")
const WOOD := Color("7a5636")
const DARK_WOOD := Color("5a3f2a")
const STONE := Color("9b927f")
const BRASS := Color("c9a441")
const CLOTH := [Color("c9483f"), Color("f2ede2"), Color("2f6f9e"), Color("e0b83a"), Color("3f8a55")]

# --- helpers -------------------------------------------------------------------

static func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)

## A quad with its own flutter alpha per corner.
static func _fquad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, aa: float, ab: float, ac: float, ad: float) -> void:
	var n := Vector3(0, 0, 1)
	for pair in [[a, aa], [b, ab], [c, ac], [a, aa], [c, ac], [d, ad]]:
		st.set_color(_a(col, pair[1]))
		st.set_normal(n)
		st.add_vertex(pair[0])

static func _ftri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, aa: float, ab: float, ac: float) -> void:
	for pair in [[a, aa], [b, ab], [c, ac]]:
		st.set_color(_a(col, pair[1]))
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(pair[0])

## A thin four-sided bar from `a` to `b`.
static func _bar(st: SurfaceTool, a: Vector3, b: Vector3, r: float, col: Color, alpha := 1.0) -> void:
	col = _a(col, alpha)
	var dir := (b - a).normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var s := dir.cross(up).normalized() * r
	var t := dir.cross(s).normalized() * r
	var ring_a := [a + s + t, a - s + t, a - s - t, a + s - t]
	var ring_b := [b + s + t, b - s + t, b - s - t, b + s - t]
	for i in 4:
		var j := (i + 1) % 4
		Meshes._quad(st, ring_a[i], ring_a[j], ring_b[j], ring_b[i], col.darkened(0.06 * i))
	Meshes._quad(st, ring_b[0], ring_b[1], ring_b[2], ring_b[3], col)

## A disc standing in the XY plane at z, facing +z.
static func _disc_z(st: SurfaceTool, c: Vector3, r: float, sides: int, col: Color) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		Meshes._tri(st, c, c + Vector3(cos(a1) * r, sin(a1) * r, 0), c + Vector3(cos(a0) * r, sin(a0) * r, 0), col)

## A flat quad lying on the floor, for rugs and light pools.
static func floor_quad(st: SurfaceTool, x0: float, z0: float, x1: float, z1: float, y: float, col: Color) -> void:
	Meshes._quad(st, Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1), col)

# --- outdoors ------------------------------------------------------------------

## Unit quad (centred, lying flat, UV 0..1) for light pools; the pool shader paints the falloff.
static func pool_quad() -> ArrayMesh:
	var st := Meshes._st()
	for c in [[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, -0.5], [0.5, 0.5], [-0.5, 0.5]]:
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(c[0] + 0.5, c[1] + 0.5))
		st.add_vertex(Vector3(c[0], 0, c[1]))
	return Meshes._finish(st)

## Bunting strung from this tile's centre east for `length` tiles (variant), sagging in the middle. It is meant to
## hang between two lamp posts or from eave to eave, so the ends sit at lamp-top height.
static func bunting(length := 3) -> ArrayMesh:
	var st := Meshes._st()
	var l := float(maxi(length, 1))
	var top := 1.7
	var sag := 0.2 + 0.03 * l
	var steps := int(l * 4.0)
	var prev := Vector3(0, top, 0)
	for i in range(1, steps + 1):
		var x := l * i / steps
		var y := top - sag * 4.0 * (x / l) * (1.0 - x / l)
		var cur := Vector3(x, y, 0)
		_bar(st, prev, cur, 0.012, Color("3a3028"), 0.0)
		prev = cur
	var flags := int(l * 4.0)
	for i in flags:
		var x := l * (i + 0.5) / flags
		var y := top - sag * 4.0 * (x / l) * (1.0 - x / l)
		var c: Color = CLOTH[i % CLOTH.size()]
		_ftri(st, Vector3(x - 0.07, y, 0), Vector3(x + 0.07, y, 0), Vector3(x, y - 0.2, 0), c, 0.0, 0.0, 1.0)
	return Meshes._finish(st)

const FLAG_W := 1.0
const FLAG_H := 0.62
const FLAG_Y := 2.2
const FLAG_COLS := 16
const FLAG_ROWS := 10
## Flag names by variant: Welsh dragon, Saltire, Irish tricolour, Manx triskelion, St George, St Piran, Union.
const FLAGS := ["dragon", "saltire", "tricolour", "triskelion", "st_george", "st_piran", "union"]

static func flagpole(_variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	Meshes.box(st, Vector3(-0.1, 0, -0.1), Vector3(0.2, 0.14, 0.2), STONE)
	Meshes.cylinder(st, Vector3(0, 0.14, 0), 0.035, 2.65, 6, Color("d8d4c8"))
	Meshes.blob(st, Vector3(0, 2.85, 0), Vector3(0.06, 0.06, 0.06), BRASS, Meshes._rng(77), 0.02)
	return Meshes._finish(st)

## The cloth of a flagpole, flying east (+x) from the pole. Pinned at the pole, free at the fly.
static func flag(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var name: String = FLAGS[variant % FLAGS.size()]
	var cw := FLAG_W / FLAG_COLS
	var ch := FLAG_H / FLAG_ROWS
	for r in FLAG_ROWS:
		for c in FLAG_COLS:
			var u := (c + 0.5) / FLAG_COLS
			var v := (r + 0.5) / FLAG_ROWS  # 0 top .. 1 bottom
			var col := _flag_colour(name, u, v)
			var x0 := 0.04 + c * cw
			var y1 := FLAG_Y + FLAG_H - r * ch
			var a0 := float(c) / FLAG_COLS
			var a1 := float(c + 1) / FLAG_COLS
			_fquad(st, Vector3(x0, y1 - ch, 0), Vector3(x0 + cw, y1 - ch, 0), Vector3(x0 + cw, y1, 0), Vector3(x0, y1, 0), col, a0, a1, a1, a0)
	return Meshes._finish(st)

static func _flag_colour(name: String, u: float, v: float) -> Color:
	var a := u - 0.5
	var b := (v - 0.5) * (FLAG_H / FLAG_W) * 1.6  # aspect-corrected so diagonals run corner to corner
	var red := Color("c8102e")
	var white := Color("f4f1e8")
	var blue := Color("1f3f8f")
	match name:
		"dragon":
			var col := white if v < 0.5 else Color("1f7a3a")
			var dx := (u - 0.5) / 0.26
			var dy := (v - 0.5) / 0.3
			if dx * dx + dy * dy < 1.0 or (absf(u - 0.28) < 0.07 and absf(v - 0.22) < 0.13) or (u > 0.66 and u < 0.82 and v > 0.5 and v < 0.62):
				col = red
			return col
		"saltire":
			return white if absf(absf(a) - absf((v - 0.5) * 1.0)) < 0.1 else Color("0065bd")
		"tricolour":
			if u < 0.333:
				return Color("169b62")
			return white if u < 0.667 else Color("ff883e")
		"triskelion":
			var col := red
			var dx := u - 0.5
			var dy := (v - 0.5) * 1.5
			var rad := sqrt(dx * dx + dy * dy)
			var ang := fposmod(atan2(dy, dx) + PI * 0.5, TAU / 3.0)
			if rad < 0.07 or (rad < 0.26 and ang < 0.9 and ang > 0.1 and rad > 0.07 + ang * 0.05):
				col = Color("c9ccd2")
			return col
		"st_george":
			return red if (absf(u - 0.5) < 0.09 or absf(v - 0.5) < 0.14) else white
		"st_piran":
			return white if (absf(u - 0.5) < 0.09 or absf(v - 0.5) < 0.14) else Color("111111")
		"union":
			var dgl := absf(absf(a) - absf((v - 0.5) * 1.0))
			if absf(u - 0.5) < 0.05 or absf(v - 0.5) < 0.09:
				return red
			if absf(u - 0.5) < 0.1 or absf(v - 0.5) < 0.17:
				return white
			if dgl < 0.035:
				return red
			if dgl < 0.1:
				return white
			return blue
	return white

## A washing line `length` tiles (variant) east of this tile's centre between two posts, with a mixed load.
static func washing_line(length := 2) -> ArrayMesh:
	var rng := Meshes._rng(31000 + length)
	var st := Meshes._st()
	var l := float(maxi(length, 1))
	var top := 1.35
	for px in [0.0, l]:
		_bar(st, Vector3(px, 0, 0), Vector3(px, top + 0.08, 0), 0.025, WOOD, 0.0)
	var sag := 0.05 + 0.02 * l
	var steps := int(l * 4.0)
	var prev := Vector3(0, top, 0)
	for i in range(1, steps + 1):
		var x := l * i / steps
		var cur := Vector3(x, top - sag * 4.0 * (x / l) * (1.0 - x / l), 0)
		_bar(st, prev, cur, 0.008, Color("e8e2d4"), 0.0)
		prev = cur
	var x := 0.3
	while x < l - 0.25:
		var y := top - sag * 4.0 * (x / l) * (1.0 - x / l)
		var c: Color = [Color("f2ede2"), Color("c9483f"), Color("2f6f9e"), Color("e0b83a"), Color("d8a0b0"), Color("f2ede2")][rng.randi() % 6]
		match rng.randi() % 4:
			0:  # a sheet
				_fquad(st, Vector3(x - 0.16, y - 0.55, 0), Vector3(x + 0.16, y - 0.55, 0), Vector3(x + 0.16, y, 0), Vector3(x - 0.16, y, 0), c, 1.0, 1.0, 0.1, 0.1)
				x += 0.45
			1:  # a shirt: body and sleeves
				_fquad(st, Vector3(x - 0.09, y - 0.38, 0), Vector3(x + 0.09, y - 0.38, 0), Vector3(x + 0.09, y, 0), Vector3(x - 0.09, y, 0), c, 1.0, 1.0, 0.1, 0.1)
				_fquad(st, Vector3(x - 0.2, y - 0.2, 0), Vector3(x + 0.2, y - 0.2, 0), Vector3(x + 0.2, y - 0.04, 0), Vector3(x - 0.2, y - 0.04, 0), c.darkened(0.05), 1.0, 1.0, 0.2, 0.2)
				x += 0.38
			2:  # trousers
				_fquad(st, Vector3(x - 0.1, y - 0.5, 0), Vector3(x - 0.01, y - 0.5, 0), Vector3(x - 0.01, y, 0), Vector3(x - 0.1, y, 0), c, 1.0, 1.0, 0.1, 0.1)
				_fquad(st, Vector3(x + 0.01, y - 0.5, 0), Vector3(x + 0.1, y - 0.5, 0), Vector3(x + 0.1, y, 0), Vector3(x + 0.01, y, 0), c.darkened(0.04), 1.0, 1.0, 0.1, 0.1)
				x += 0.3
			3:  # socks
				for k in 2:
					var sx := x + k * 0.1
					_fquad(st, Vector3(sx - 0.03, y - 0.16, 0), Vector3(sx + 0.03, y - 0.16, 0), Vector3(sx + 0.03, y, 0), Vector3(sx - 0.03, y, 0), c, 1.0, 1.0, 0.1, 0.1)
				x += 0.28
	return Meshes._finish(st)

## A basket of flowers. Variant 0 hangs from a lamp post on this tile (bracket reaching east); variant 1 hangs
## from the south wall of the building on this tile, over the pavement.
static func hanging_basket(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(32000 + variant)
	var st := Meshes._st()
	var at := Vector3(0.3, 1.3, 0)
	if variant == 1:
		at = Vector3(0, 1.05, 0.62)
		_bar(st, Vector3(0, 1.16, 0.44), Vector3(0, 1.16, 0.62), 0.015, IRON)
		_bar(st, Vector3(0, 0.98, 0.44), Vector3(0, 1.16, 0.62), 0.012, IRON)
	else:
		_bar(st, Vector3(0.03, 1.5, 0), Vector3(0.3, 1.5, 0), 0.015, IRON)
		_bar(st, Vector3(0.03, 1.3, 0), Vector3(0.3, 1.5, 0), 0.012, IRON)
	Meshes.blob(st, at + Vector3(0, -0.06, 0), Vector3(0.13, 0.09, 0.13), Color("5a4632"), rng, 0.05)
	Meshes.blob(st, at + Vector3(0, 0.03, 0), Vector3(0.16, 0.08, 0.16), Color("4c7a39"), rng, 0.25)
	for i in 7:
		var p := at + Vector3(rng.randf_range(-0.12, 0.12), 0.08 + rng.randf_range(0.0, 0.04), rng.randf_range(-0.12, 0.12))
		var c: Color = [Color("d8566b"), Color("9b6fb0"), Color("f2f0e6"), Color("e8d34a"), Color("e0703a")][rng.randi() % 5]
		Meshes.box(st, p - Vector3(0.025, 0, 0.025), Vector3(0.05, 0.045, 0.05), c)
	for i in 3:
		var p := at + Vector3(rng.randf_range(-0.12, 0.12), -0.14, rng.randf_range(-0.12, 0.12))
		Meshes.box(st, p, Vector3(0.025, 0.1, 0.025), Color("4c7a39"))
	return Meshes._finish(st)

# --- indoors -------------------------------------------------------------------

const RUGS := [[Color("8c2f39"), Color("e0c27a")], [Color("2f5a7a"), Color("d8d2c2")], [Color("3f6b4a"), Color("c9a441")], [Color("6a4a7a"), Color("e8d8b8")]]

## A rug filling its tile (the builder stretches it over `w` x `h` tiles), border and centre stripe.
static func rug(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var pal: Array = RUGS[variant % RUGS.size()]
	var main: Color = pal[0]
	var trim: Color = pal[1]
	floor_quad(st, -0.46, -0.46, 0.46, 0.46, 0.012, trim)
	floor_quad(st, -0.4, -0.4, 0.4, 0.4, 0.016, main)
	floor_quad(st, -0.3, -0.3, 0.3, 0.3, 0.02, trim.darkened(0.15))
	floor_quad(st, -0.26, -0.26, 0.26, 0.26, 0.024, main.lightened(0.08))
	return Meshes._finish(st)

static func fireplace() -> ArrayMesh:
	var st := Meshes._st()
	var brick := Color("8a5a48")
	Meshes.box(st, Vector3(-0.46, 0, -0.5), Vector3(0.92, 0.08, 0.5), STONE.darkened(0.1))
	Meshes.box(st, Vector3(-0.42, 0.08, -0.5), Vector3(0.14, 1.0, 0.34), brick)
	Meshes.box(st, Vector3(0.28, 0.08, -0.5), Vector3(0.14, 1.0, 0.34), brick)
	Meshes.box(st, Vector3(-0.42, 1.08, -0.5), Vector3(0.84, 0.18, 0.34), brick)
	Meshes.box(st, Vector3(-0.28, 0.08, -0.5), Vector3(0.56, 1.0, 0.1), Color("1d1a18"))
	Meshes.box(st, Vector3(-0.5, 1.26, -0.5), Vector3(1.0, 0.07, 0.44), WOOD.lightened(0.1))
	Meshes.box(st, Vector3(-0.3, 1.33, -0.5), Vector3(0.6, 0.9, 0.2), brick.darkened(0.08))
	Meshes.box(st, Vector3(-0.22, 0.08, -0.35), Vector3(0.44, 0.07, 0.07), DARK_WOOD)
	return Meshes._finish(st)

## The fire itself and the pool of warm light it throws on the floor, additive, flickering (firelight shader).
static func fireplace_fire() -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(33000)
	for i in 3:
		var x := -0.15 + i * 0.15
		var h := 0.38 - absf(i - 1) * 0.1
		var base := Vector3(x, 0.16, -0.36)
		var tip := base + Vector3(0, h, 0.02)
		Meshes._tri(st, base + Vector3(-0.09, 0, 0), base + Vector3(0.09, 0, 0), tip, Color(1.0, 0.45, 0.1, 1.0))
		var core := base + Vector3(0, 0, 0.01)
		Meshes._tri(st, core + Vector3(-0.045, 0, 0), core + Vector3(0.045, 0, 0), core + Vector3(0, h * 0.65, 0.01), Color(1.0, 0.85, 0.35, 1.0))
	# the pool on the floor: warm in the middle, fading out
	var steps := 10
	for i in steps:
		var a0 := TAU * i / steps
		var a1 := TAU * (i + 1) / steps
		var c := Vector3(0, 0.03, 0.15)
		var p0 := c + Vector3(cos(a0) * 1.15, 0, sin(a0) * 0.8)
		var p1 := c + Vector3(cos(a1) * 1.15, 0, sin(a1) * 0.8)
		for pair in [[c, 0.5], [p1, 0.0], [p0, 0.0]]:
			st.set_color(Color(1.0, 0.55, 0.2, pair[1]))
			st.set_normal(Vector3.UP)
			st.add_vertex(pair[0])
	return Meshes._finish(st)

## A framed picture on the north wall. 0 hills, 1 portrait, 2 seascape.
static func wall_picture(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var frame: Color = [Color("8a6a2e"), Color("3a2a22"), Color("c9a441")][variant % 3]
	Meshes.box(st, Vector3(-0.27, 1.25, -0.5), Vector3(0.54, 0.44, 0.04), frame)
	var z := -0.455
	match variant % 3:
		0:
			Meshes.box(st, Vector3(-0.22, 1.3, z), Vector3(0.44, 0.34, 0.01), Color("9fc3dc"))
			Meshes.box(st, Vector3(-0.22, 1.3, z), Vector3(0.44, 0.15, 0.015), Color("5d8a3f"))
			Meshes.box(st, Vector3(-0.1, 1.44, z), Vector3(0.2, 0.08, 0.02), Color("466d34"))
		1:
			Meshes.box(st, Vector3(-0.22, 1.3, z), Vector3(0.44, 0.34, 0.01), Color("4a3b32"))
			Meshes.blob(st, Vector3(0, 1.5, z + 0.01), Vector3(0.09, 0.1, 0.01), Color("e0b99a"), Meshes._rng(5), 0.02)
			Meshes.box(st, Vector3(-0.13, 1.3, z), Vector3(0.26, 0.1, 0.02), Color("2f3a5a"))
		2:
			Meshes.box(st, Vector3(-0.22, 1.3, z), Vector3(0.44, 0.34, 0.01), Color("c9d8dc"))
			Meshes.box(st, Vector3(-0.22, 1.3, z), Vector3(0.44, 0.16, 0.015), Color("2f6f8a"))
			Meshes.box(st, Vector3(-0.05, 1.44, z), Vector3(0.12, 0.1, 0.02), Color("f2ede2"))
	return Meshes._finish(st)

static func clock() -> ArrayMesh:
	var st := Meshes._st()
	var c := Vector3(0, 1.55, -0.47)
	_disc_z(st, c, 0.24, 10, DARK_WOOD)
	_disc_z(st, c + Vector3(0, 0, 0.012), 0.2, 10, Color("f2ede2"))
	for i in 4:
		var a := TAU * i / 4.0
		Meshes.box(st, c + Vector3(cos(a) * 0.15 - 0.012, sin(a) * 0.15 - 0.012, 0.015), Vector3(0.024, 0.024, 0.01), IRON)
	_bar(st, c + Vector3(0, 0, 0.03), c + Vector3(0.0, 0.14, 0.03), 0.01, IRON)
	_bar(st, c + Vector3(0, 0, 0.035), c + Vector3(0.09, -0.03, 0.035), 0.012, IRON)
	return Meshes._finish(st)

## A pub dartboard on the wall (the north wall; "rot" 270 hangs it on the east): a cabinet back, the black
## surround, the green and red rings and the bull, so the darts pubs show where the game is.
static func dartboard() -> ArrayMesh:
	var st := Meshes._st()
	var c := Vector3(0, 1.5, -0.47)
	Meshes.box(st, Vector3(-0.3, 1.18, -0.5), Vector3(0.6, 0.64, 0.02), DARK_WOOD)
	var rings := [[0.25, Color("1c1c1c")], [0.2, Color("2f7a3a")], [0.185, Color("efe4c8")], [0.15, Color("1c1c1c")],
		[0.12, Color("c0392b")], [0.105, Color("efe4c8")], [0.06, Color("1c1c1c")], [0.035, Color("2f7a3a")], [0.016, Color("c0392b")]]
	for i in rings.size():
		_disc_z(st, c + Vector3(0, 0, 0.004 * i), float(rings[i][0]), 16, rings[i][1])
	return Meshes._finish(st)

static func kitchen_dresser() -> ArrayMesh:
	var st := Meshes._st()
	var blue := Color("3f6a8a")
	Meshes.box(st, Vector3(-0.46, 0, -0.5), Vector3(0.92, 0.7, 0.42), blue)
	Meshes.box(st, Vector3(-0.44, 0.7, -0.5), Vector3(0.88, 0.04, 0.46), blue.lightened(0.15))
	Meshes.box(st, Vector3(-0.44, 0.74, -0.5), Vector3(0.06, 1.0, 0.2), blue)
	Meshes.box(st, Vector3(0.38, 0.74, -0.5), Vector3(0.06, 1.0, 0.2), blue)
	Meshes.box(st, Vector3(-0.44, 1.7, -0.5), Vector3(0.88, 0.06, 0.24), blue.darkened(0.05))
	for y in [0.96, 1.3]:
		Meshes.box(st, Vector3(-0.4, y, -0.46), Vector3(0.8, 0.03, 0.14), blue.lightened(0.1))
		for i in 4:
			Meshes.box(st, Vector3(-0.33 + i * 0.2, y + 0.03, -0.45), Vector3(0.14, 0.14, 0.02), Color("f2ede2"))
	for i in 3:
		Meshes.box(st, Vector3(-0.3 + i * 0.28, 0.74, -0.38), Vector3(0.08, 0.07, 0.08), [Color("c9483f"), Color("e0b83a"), Color("f2ede2")][i])
	Meshes.box(st, Vector3(-0.04, 0.4, -0.08), Vector3(0.08, 0.03, 0.02), BRASS)
	return Meshes._finish(st)

## The chippy's range: a steel counter with two vats and a basket.
static func fryer() -> ArrayMesh:
	var st := Meshes._st()
	var steel := Color("b4bcc4")
	Meshes.box(st, Vector3(-0.46, 0, -0.42), Vector3(0.92, 0.82, 0.84), steel.darkened(0.15), steel)
	for i in 2:
		Meshes.box(st, Vector3(-0.38 + i * 0.4, 0.82, -0.34), Vector3(0.32, 0.03, 0.4), Color("d9a441"))
	Meshes.box(st, Vector3(-0.44, 0.82, 0.26), Vector3(0.88, 0.06, 0.12), steel.lightened(0.1))
	Meshes.box(st, Vector3(-0.3, 0.85, -0.3), Vector3(0.18, 0.08, 0.24), Color("2d3138"))
	_bar(st, Vector3(-0.21, 0.9, -0.3), Vector3(-0.21, 0.95, 0.1), 0.01, Color("2d3138"))
	Meshes.box(st, Vector3(-0.35, 0.9, -0.05), Vector3(0.14, 0.02, 0.14), Color("e8c060"))
	Meshes.box(st, Vector3(0.1, 0.82, -0.42), Vector3(0.24, 0.5, 0.04), steel.lightened(0.1))
	return Meshes._finish(st)

## A chalk menu board on the north wall.
static func menu_board() -> ArrayMesh:
	var st := Meshes._st()
	Meshes.box(st, Vector3(-0.42, 1.0, -0.5), Vector3(0.84, 0.74, 0.05), WOOD)
	Meshes.box(st, Vector3(-0.38, 1.04, -0.455), Vector3(0.76, 0.66, 0.01), Color("2c3a34"))
	var rng := Meshes._rng(34000)
	for i in 5:
		var w := rng.randf_range(0.28, 0.6)
		Meshes.box(st, Vector3(-0.32, 1.58 - i * 0.12, -0.445), Vector3(w, 0.03, 0.01), Color("e8e2d4"))
		Meshes.box(st, Vector3(0.26, 1.58 - i * 0.12, -0.445), Vector3(0.07, 0.03, 0.01), Color("e8e2d4"))
	return Meshes._finish(st)

static func piano() -> ArrayMesh:
	var st := Meshes._st()
	var black := Color("26262c")
	Meshes.box(st, Vector3(-0.46, 0, -0.46), Vector3(0.92, 1.1, 0.4), black)
	Meshes.box(st, Vector3(-0.46, 0.7, -0.08), Vector3(0.92, 0.06, 0.3), black.lightened(0.05))
	for i in 12:
		Meshes.box(st, Vector3(-0.42 + i * 0.07, 0.76, -0.06), Vector3(0.06, 0.02, 0.24), Color("f2ede2"))
	for i in 8:
		Meshes.box(st, Vector3(-0.4 + i * 0.07 + (0.04 if i > 2 else 0.0), 0.78, -0.06), Vector3(0.035, 0.02, 0.14), black)
	for px in [-0.42, 0.34]:
		Meshes.box(st, Vector3(px, 0, -0.08), Vector3(0.08, 0.7, 0.3), black.lightened(0.04))
	Meshes.box(st, Vector3(-0.17, 0.0, 0.26), Vector3(0.34, 0.3, 0.2), DARK_WOOD)
	Meshes.box(st, Vector3(-0.19, 0.3, 0.24), Vector3(0.38, 0.06, 0.24), Color("8c2f39"))
	return Meshes._finish(st)

static func telescope() -> ArrayMesh:
	var st := Meshes._st()
	var hub := Vector3(0, 0.82, 0)
	for ang in [0.0, TAU / 3, 2 * TAU / 3]:
		_bar(st, hub, Vector3(cos(ang) * 0.3, 0, sin(ang) * 0.3), 0.018, WOOD)
	_bar(st, hub + Vector3(-0.2, -0.1, 0.2), hub + Vector3(0.28, 0.5, -0.3), 0.05, BRASS)
	_bar(st, hub + Vector3(0.28, 0.5, -0.3), hub + Vector3(0.38, 0.62, -0.4), 0.065, BRASS.darkened(0.2))
	Meshes.box(st, hub + Vector3(-0.06, -0.08, -0.06), Vector3(0.12, 0.12, 0.12), IRON)
	return Meshes._finish(st)

static func plant_stand(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(35000 + variant)
	var st := Meshes._st()
	for ang in [0.4, 2.5, 4.6]:
		_bar(st, Vector3(0, 0.62, 0), Vector3(cos(ang) * 0.2, 0, sin(ang) * 0.2), 0.015, WOOD)
	Meshes.cylinder(st, Vector3(0, 0.6, 0), 0.22, 0.04, 8, WOOD.lightened(0.1))
	Meshes.cylinder(st, Vector3(0, 0.64, 0), 0.16, 0.22, 8, Color("3f6a8a"))
	Meshes.blob(st, Vector3(0, 1.05, 0), Vector3(0.28, 0.26, 0.28), Color("4c7a39"), rng, 0.3)
	Meshes.blob(st, Vector3(0.18, 0.78, 0.1), Vector3(0.14, 0.2, 0.14), Color("5d8a3f"), rng, 0.3)
	return Meshes._finish(st)

## 0 a sofa, 1 an armchair. Back against the north wall.
static func sofa(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var fabrics := [Color("8c3b3b"), Color("3f6a8a"), Color("4f7a3a")]
	var cloth: Color = fabrics[(variant >> 1) % fabrics.size()]
	var armchair := variant % 2 == 1
	var hw := 0.3 if armchair else 0.44
	Meshes.box(st, Vector3(-hw, 0, -0.45), Vector3(hw * 2, 0.3, 0.8), cloth.darkened(0.15))
	Meshes.box(st, Vector3(-hw + 0.1, 0.3, -0.35), Vector3(hw * 2 - 0.2, 0.12, 0.66), cloth.lightened(0.08))
	Meshes.box(st, Vector3(-hw, 0.3, -0.48), Vector3(hw * 2, 0.5, 0.16), cloth)
	for sx in [-hw, hw - 0.1]:
		Meshes.box(st, Vector3(sx, 0.3, -0.4), Vector3(0.1, 0.24, 0.76), cloth.darkened(0.05))
	return Meshes._finish(st)

## An open glass-style cabinet: four posts, a rim and a few finds on a plinth.
static func display_case(variant := 0) -> ArrayMesh:
	var rng := Meshes._rng(36000 + variant)
	var st := Meshes._st()
	Meshes.box(st, Vector3(-0.4, 0, -0.35), Vector3(0.8, 0.5, 0.7), DARK_WOOD, Color("2f3a5a"))
	for px in [-0.4, 0.36]:
		for pz in [-0.35, 0.31]:
			Meshes.box(st, Vector3(px, 0.5, pz), Vector3(0.04, 0.5, 0.04), BRASS)
	Meshes.box(st, Vector3(-0.4, 1.0, -0.35), Vector3(0.8, 0.04, 0.7), BRASS.darkened(0.1))
	var finds: Array = [Color("e0a83a"), Color("c9c0aa"), Color("8c8270"), Color("6a9a8a"), Color("a8553a")]
	for i in 4:
		var c: Color = finds[rng.randi() % finds.size()]
		Meshes.blob(st, Vector3(rng.randf_range(-0.25, 0.25), 0.6, rng.randf_range(-0.2, 0.2)), Vector3(0.08, 0.07, 0.08), c, rng, 0.25)
	return Meshes._finish(st)

# --- the first hour's rooms (2.1): Mum's window and the cat's bowl, the Field Station's owl, kettle, jars and map ---

## A sash window on the north wall, daylight in the panes, curtains either side and a pot on the sill.
static func window() -> ArrayMesh:
	var st := Meshes._st()
	var frame := Color("f2ede2")
	var glass := Color("bfe0ef")
	Meshes.box(st, Vector3(-0.36, 0.7, -0.5), Vector3(0.72, 0.86, 0.05), frame)
	Meshes.box(st, Vector3(-0.31, 0.75, -0.452), Vector3(0.62, 0.76, 0.01), glass)
	Meshes.box(st, Vector3(-0.31, 1.06, -0.452), Vector3(0.62, 0.45, 0.012), glass.lightened(0.25))  # the sky's brighter up top
	Meshes.box(st, Vector3(-0.31, 0.75, -0.452), Vector3(0.62, 0.12, 0.014), Color("8fb97a"))  # a hedge outside
	Meshes.box(st, Vector3(-0.31, 1.11, -0.445), Vector3(0.62, 0.035, 0.012), frame)  # the sash
	Meshes.box(st, Vector3(-0.0175, 0.75, -0.445), Vector3(0.035, 0.76, 0.012), frame)
	Meshes.box(st, Vector3(-0.42, 0.66, -0.5), Vector3(0.84, 0.05, 0.14), frame.darkened(0.06))  # the sill
	Meshes.cylinder(st, Vector3(0.22, 0.71, -0.42), 0.05, 0.07, 6, Color("b8643c"))
	Meshes.blob(st, Vector3(0.22, 0.82, -0.42), Vector3(0.07, 0.06, 0.07), Color("5d8a3f"), Meshes._rng(37000), 0.25)
	var cloth := Color("c9483f")
	for sx in [-1.0, 1.0]:
		var x0: float = 0.36 * sx - (0.14 if sx > 0 else 0.0)
		Meshes.box(st, Vector3(x0, 0.56, -0.48), Vector3(0.14, 1.06, 0.05), cloth)
		Meshes.box(st, Vector3(x0 + 0.03, 0.56, -0.43), Vector3(0.08, 1.06, 0.01), cloth.lightened(0.12))
	Meshes.box(st, Vector3(-0.52, 1.64, -0.48), Vector3(1.04, 0.03, 0.04), DARK_WOOD)  # the pole
	return Meshes._finish(st)

## The cat's bowls on the kitchen floor: biscuits in the blue one, water in the other. Walk-over size.
static func cat_bowl() -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(37100)
	Meshes.cylinder(st, Vector3(-0.1, 0.0, 0.05), 0.11, 0.06, 10, Color("3f6a8a"))
	for i in 7:
		Meshes.box(st, Vector3(-0.17 + rng.randf() * 0.12, 0.05, -0.02 + rng.randf() * 0.12), Vector3(0.025, 0.02, 0.025), Color("8a5a2e"))
	Meshes.cylinder(st, Vector3(0.14, 0.0, -0.05), 0.09, 0.05, 10, Color("f2ede2"))
	Meshes.cylinder(st, Vector3(0.14, 0.046, -0.05), 0.07, 0.004, 10, Color("8fc3dc"))
	Meshes.box(st, Vector3(-0.26, 0.0, -0.14), Vector3(0.52, 0.006, 0.3), Color("c9a441"))  # a mat, mostly for show
	return Meshes._finish(st)

## Professor Garside's owl on a T-perch: a tawny, unimpressed.
static func owl_perch() -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(37200)
	Meshes.box(st, Vector3(-0.2, 0, -0.2), Vector3(0.4, 0.05, 0.4), DARK_WOOD)
	_bar(st, Vector3(0, 0.05, 0), Vector3(0, 1.0, 0), 0.03, WOOD)
	_bar(st, Vector3(-0.24, 1.0, 0), Vector3(0.24, 1.0, 0), 0.025, WOOD.lightened(0.1))
	var brown := Color("8a6440")
	Meshes.blob(st, Vector3(0, 1.22, 0), Vector3(0.15, 0.2, 0.13), brown, rng, 0.08)
	Meshes.blob(st, Vector3(0, 1.43, 0.01), Vector3(0.13, 0.12, 0.12), brown.lightened(0.05), rng, 0.08)
	var face := Vector3(0, 1.44, 0.125)
	_disc_z(st, face, 0.1, 10, Color("d8c4a0"))
	for ex in [-0.045, 0.045]:
		_disc_z(st, face + Vector3(ex, 0.01, 0.006), 0.028, 8, Color("1d1a18"))
		_disc_z(st, face + Vector3(ex + 0.008, 0.02, 0.009), 0.008, 5, Color("f2ede2"))
	Meshes._tri(st, face + Vector3(-0.015, -0.02, 0.01), face + Vector3(0, -0.06, 0.03), face + Vector3(0.015, -0.02, 0.01), Color("c9a441"))
	for i in 5:  # speckles on the chest
		Meshes.box(st, Vector3(-0.08 + i * 0.035, 1.15 + (i % 2) * 0.06, 0.11), Vector3(0.02, 0.03, 0.02), brown.darkened(0.3))
	for fx in [-0.05, 0.03]:
		Meshes.box(st, Vector3(fx, 1.0, 0.0), Vector3(0.03, 0.035, 0.06), Color("c9a441"))
	return Meshes._finish(st)

## A side table with the kettle (always on) and two mugs, one of them the Professor's.
static func kettle_table() -> ArrayMesh:
	var st := Meshes._st()
	Meshes.box(st, Vector3(-0.36, 0.62, -0.36), Vector3(0.72, 0.05, 0.72), WOOD.lightened(0.05))
	for px in [-0.32, 0.27]:
		for pz in [-0.32, 0.27]:
			Meshes.box(st, Vector3(px, 0, pz), Vector3(0.05, 0.62, 0.05), WOOD)
	var steel := Color("c4ccd2")
	Meshes.cylinder(st, Vector3(-0.08, 0.67, -0.05), 0.14, 0.24, 10, steel)
	Meshes.cylinder(st, Vector3(-0.08, 0.91, -0.05), 0.09, 0.03, 10, steel.darkened(0.15))
	Meshes.box(st, Vector3(-0.1, 0.94, -0.07), Vector3(0.04, 0.03, 0.04), IRON)
	_bar(st, Vector3(-0.08 + 0.1, 0.72, -0.05), Vector3(0.14, 0.86, 0.0), 0.022, steel)  # spout
	_bar(st, Vector3(-0.2, 0.9, -0.05), Vector3(-0.08, 0.98, -0.05), 0.015, IRON)
	_bar(st, Vector3(-0.08, 0.98, -0.05), Vector3(0.04, 0.9, -0.05), 0.015, IRON)
	Meshes.cylinder(st, Vector3(0.2, 0.67, 0.18), 0.05, 0.09, 8, Color("c9483f"))
	Meshes.cylinder(st, Vector3(-0.22, 0.67, 0.22), 0.05, 0.09, 8, Color("f2ede2"))
	Meshes.box(st, Vector3(0.12, 0.67, -0.3), Vector3(0.16, 0.06, 0.1), Color("e0b83a"))  # the biscuit tin
	return Meshes._finish(st)

## Shelves of specimen jars against the north wall: owl pellets, frogspawn, a pickled something.
static func specimen_shelf(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(37300 + variant)
	Meshes.box(st, Vector3(-0.44, 0, -0.5), Vector3(0.88, 1.36, 0.06), DARK_WOOD)
	for sx in [-0.44, 0.4]:
		Meshes.box(st, Vector3(sx, 0, -0.5), Vector3(0.04, 1.36, 0.34), DARK_WOOD)
	Meshes.box(st, Vector3(-0.44, 1.32, -0.5), Vector3(0.88, 0.04, 0.34), DARK_WOOD)
	var glass := Color("d6ebe6")
	var insides := [Color("6f8f3a"), Color("c98a3a"), Color("8c2f39"), Color("4f7a9a"), Color("b8a888"), Color("3f6b4a")]
	for row in 3:
		var y := 0.1 + row * 0.42
		Meshes.box(st, Vector3(-0.4, y - 0.04, -0.46), Vector3(0.8, 0.04, 0.3), WOOD)
		var x := -0.34
		while x < 0.3:
			var r := rng.randf_range(0.045, 0.07)
			var h := rng.randf_range(0.14, 0.26)
			Meshes.cylinder(st, Vector3(x + r, y, -0.3), r, h, 8, glass)
			Meshes.cylinder(st, Vector3(x + r, y + 0.01, -0.3 + 0.012), r * 0.8, h * 0.62, 8, insides[rng.randi() % insides.size()])
			Meshes.cylinder(st, Vector3(x + r, y + h, -0.3), r * 0.9, 0.025, 8, BRASS.darkened(0.2))
			x += r * 2.0 + 0.04
	return Meshes._finish(st)

## A corner shop's shelves against the north wall: tins, packets, jars and bottles, a price strip on each shelf.
static func shop_shelf(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(37400 + variant)
	var frame := Color("e8e2d4")
	Meshes.box(st, Vector3(-0.46, 0, -0.5), Vector3(0.92, 1.6, 0.05), frame.darkened(0.08))
	for sx in [-0.46, 0.42]:
		Meshes.box(st, Vector3(sx, 0, -0.5), Vector3(0.04, 1.6, 0.4), frame)
	Meshes.box(st, Vector3(-0.46, 1.56, -0.5), Vector3(0.92, 0.04, 0.4), frame)
	var labels := [Color("c9483f"), Color("2f6f9e"), Color("e0b83a"), Color("3f8a55"), Color("e8e2d4"), Color("8c3b6a"), Color("d9772f")]
	for row in 4:
		var y := 0.08 + row * 0.38
		Meshes.box(st, Vector3(-0.42, y - 0.04, -0.46), Vector3(0.84, 0.04, 0.36), frame.darkened(0.04))
		Meshes.box(st, Vector3(-0.42, y - 0.06, -0.1), Vector3(0.84, 0.05, 0.012), Color("f2ede2"))  # the price strip
		var x := -0.4
		while x < 0.32:
			var c: Color = labels[rng.randi() % labels.size()]
			match rng.randi() % 3:
				0:  # a tin
					var r := rng.randf_range(0.045, 0.06)
					Meshes.cylinder(st, Vector3(x + r, y, -0.22), r, rng.randf_range(0.1, 0.14), 8, c)
					x += r * 2.0 + 0.02
				1:  # a packet
					var w := rng.randf_range(0.1, 0.15)
					Meshes.box(st, Vector3(x, y, -0.3), Vector3(w, rng.randf_range(0.18, 0.26), 0.12), c)
					x += w + 0.02
				_:  # a bottle
					var r2 := rng.randf_range(0.035, 0.045)
					var h := rng.randf_range(0.16, 0.24)
					Meshes.cylinder(st, Vector3(x + r2, y, -0.22), r2, h, 6, c.darkened(0.25))
					Meshes.cylinder(st, Vector3(x + r2, y + h, -0.22), r2 * 0.45, 0.06, 6, c.darkened(0.4))
					x += r2 * 2.0 + 0.03
	return Meshes._finish(st)

const ISLES_GB := [[-5.7, 50.05], [-5.2, 49.96], [-4.1, 50.35], [-2.45, 50.6], [-1.3, 50.7], [-0.1, 50.8], [1.4, 51.15],
	[1.4, 51.38], [0.9, 51.8], [1.75, 52.5], [1.3, 52.93], [0.3, 52.85], [0.1, 53.6], [-0.1, 54.1], [-0.6, 54.5],
	[-1.4, 55.0], [-2.0, 55.77], [-2.6, 56.05], [-2.6, 56.3], [-2.1, 57.15], [-2.0, 57.69], [-3.5, 57.65],
	[-3.1, 58.45], [-3.4, 58.67], [-5.0, 58.62], [-5.2, 57.9], [-5.8, 57.3], [-5.85, 56.95], [-5.5, 56.4],
	[-5.7, 55.3], [-4.9, 55.7], [-5.1, 54.65], [-3.6, 54.9], [-3.6, 54.4], [-2.9, 54.05], [-3.05, 53.4],
	[-4.6, 53.3], [-4.75, 52.8], [-4.1, 52.4], [-5.3, 51.88], [-4.0, 51.6], [-3.0, 51.55], [-3.3, 51.2],
	[-4.6, 51.1], [-5.1, 50.6]]
const ISLES_IE := [[-7.3, 55.38], [-6.1, 55.2], [-5.7, 54.6], [-6.05, 53.35], [-6.35, 52.2], [-8.3, 51.8], [-9.8, 51.45],
	[-10.3, 52.15], [-9.1, 53.25], [-10.1, 53.5], [-9.9, 54.2], [-8.6, 54.65], [-8.3, 55.15]]
const ISLES_MAN := [[-4.8, 54.05], [-4.35, 54.4], [-4.3, 54.2], [-4.6, 54.05]]

## The Field Station's wall map of the Isles, pinned where the Keepers are. It spans about two tiles.
static func wall_map() -> ArrayMesh:
	var st := Meshes._st()
	var w := 0.9
	var h := 1.0
	var bottom := 0.62
	Meshes.box(st, Vector3(-w * 0.5 - 0.05, bottom - 0.05, -0.5), Vector3(w + 0.1, h + 0.1, 0.04), Color("6b4a32"))
	Meshes.box(st, Vector3(-w * 0.5, bottom, -0.46), Vector3(w, h, 0.01), Color("9fc0cf"))
	var to_wall := func(p: Array) -> Vector3:
		var nx := (float(p[0]) + 10.6) / 12.6
		var ny := (59.0 - float(p[1])) / 9.3
		return Vector3(-w * 0.5 + nx * w, bottom + h - ny * h, -0.445)
	for shape in [ISLES_GB, ISLES_IE, ISLES_MAN]:
		var pts := PackedVector2Array()
		for p in shape:
			pts.append(Vector2(float(p[0]), float(p[1])))
		var idx := Geometry2D.triangulate_polygon(pts)
		for i in range(0, idx.size(), 3):
			var a: Vector3 = to_wall.call(shape[idx[i]])
			var b: Vector3 = to_wall.call(shape[idx[i + 1]])
			var c: Vector3 = to_wall.call(shape[idx[i + 2]])
			Meshes._tri(st, a, b, c, Color("e8dcb0"))
			Meshes._tri(st, a, c, b, Color("e8dcb0"))
	var pins := [[-2.13, 53.26], [-1.91, 53.26], [-2.98, 53.41], [-2.24, 53.48], [-4.13, 53.12], [-3.2, 55.95], [-6.26, 53.35],
		[-5.93, 54.6], [-4.48, 54.15], [-1.08, 53.96], [-2.36, 51.38]]
	for i in pins.size():
		var at: Vector3 = to_wall.call(pins[i])
		var col: Color = Color("c8423a") if i > 0 else Color("2f6fb0")  # blue: you are here
		Meshes.box(st, at + Vector3(-0.012, -0.012, 0.002), Vector3(0.024, 0.024, 0.02), col)
	Meshes.box(st, Vector3(-w * 0.5 + 0.04, bottom + h - 0.1, -0.44), Vector3(0.3, 0.05, 0.005), Color("3a2a22"))  # a title, sort of
	return Meshes._finish(st)

# --- Keeper venues -------------------------------------------------------------
# Each Keeper's room is a real place: a rugby ground, a shipyard, a parish hall, a harbour, a curling rink, a
# cellar club, a quarry, a crypt; plus the Moot's braziers and Vane's penthouse. Backdrops ("..._arch", stands,
# windows) cover the north wall like wall things do. Lights come in two parts: the fitting (solid) and its glow
# (VENUE_GLOWS, additive and flickering through the firelight shader, so it reads the same at any hour).

const VENUE_PROPS := ["stadium_stand", "rugby_posts", "floodlight", "puddle", "pitch_line", "gantry_crane", "ship_ribs",
	"steel_plates", "hall_stage", "tea_urn", "stacked_chairs", "currach", "lobster_pots", "harbour_arch", "fae_lantern",
	"toadstool_ring", "clootie_tree", "curling_house", "curling_stones", "brick_arch", "band_kit", "stage_light",
	"slate_stack", "slate_wagon", "crypt_arch", "candelabra", "tomb_chest", "brazier", "city_window",
	"enclosure_banner", "creature_cage", "loom", "slot_machine", "roulette_table", "card_table", "tote_board", "velvet_rope",
	"horse_statue"]
## prop -> the glow mesh that goes with it (same tile, same variant).
const VENUE_GLOWS := {"floodlight": "floodlight_glow", "fae_lantern": "fae_glow", "stage_light": "stage_glow",
	"candelabra": "candle_glow", "brazier": "brazier_fire", "slot_machine": "slot_glow", "tote_board": "tote_glow"}

static func venue_prop(name: String, variant: int) -> ArrayMesh:
	match name:
		"stadium_stand": return stadium_stand(variant)
		"rugby_posts": return rugby_posts(variant)
		"floodlight": return floodlight()
		"floodlight_glow": return floodlight_glow()
		"puddle": return puddle(variant)
		"pitch_line": return pitch_line(variant)
		"gantry_crane": return gantry_crane()
		"ship_ribs": return ship_ribs()
		"steel_plates": return steel_plates()
		"hall_stage": return hall_stage(variant)
		"tea_urn": return tea_urn()
		"stacked_chairs": return stacked_chairs(variant)
		"currach": return currach()
		"lobster_pots": return lobster_pots(variant)
		"harbour_arch": return harbour_arch(variant)
		"fae_lantern": return fae_lantern(variant)
		"fae_glow": return fae_glow(variant)
		"toadstool_ring": return toadstool_ring(variant)
		"clootie_tree": return clootie_tree(variant)
		"curling_house": return curling_house()
		"curling_stones": return curling_stones(variant)
		"brick_arch": return brick_arch(variant)
		"band_kit": return band_kit(variant)
		"stage_light": return stage_light()
		"stage_glow": return stage_glow(variant)
		"slate_stack": return slate_stack(variant)
		"slate_wagon": return slate_wagon()
		"crypt_arch": return crypt_arch(variant)
		"candelabra": return candelabra()
		"candle_glow": return candle_glow()
		"tomb_chest": return tomb_chest(variant)
		"brazier": return brazier()
		"brazier_fire": return brazier_fire()
		"city_window": return city_window(variant)
		"enclosure_banner": return enclosure_banner()
		"creature_cage": return creature_cage(variant)
		"loom": return loom(variant)
		"slot_machine": return slot_machine(variant)
		"slot_glow": return slot_glow(variant)
		"roulette_table": return roulette_table(variant)
		"card_table": return card_table(variant)
		"tote_board": return tote_board(variant)
		"tote_glow": return tote_glow(variant)
		"velvet_rope": return velvet_rope(variant)
		"horse_statue": return horse_statue(variant)
	return null

## A flat panel at depth z facing the camera (+z), from (x0, y0) to (x1, y1).
static func _panel(st: SurfaceTool, x0: float, y0: float, x1: float, y1: float, z: float, col: Color) -> void:
	Meshes._quad(st, Vector3(x0, y1, z), Vector3(x1, y1, z), Vector3(x1, y0, z), Vector3(x0, y0, z), col)

## An additive pool of light on the floor (or any flat ellipse), bright `col` at the centre, nothing at the rim.
static func _glow_pool(st: SurfaceTool, c: Vector3, rx: float, rz: float, col: Color, strength: float) -> void:
	var steps := 14
	for i in steps:
		var a0 := TAU * i / steps
		var a1 := TAU * (i + 1) / steps
		var p0 := c + Vector3(cos(a0) * rx, 0, sin(a0) * rz)
		var p1 := c + Vector3(cos(a1) * rx, 0, sin(a1) * rz)
		for pair in [[c, strength], [p1, 0.0], [p0, 0.0]]:
			st.set_color(Color(col.r, col.g, col.b, pair[1]))
			st.set_normal(Vector3.UP)
			st.add_vertex(pair[0])

## A glowing disc standing up, facing the camera (lantern panes, lamp faces), fading to its rim.
static func _glow_disc(st: SurfaceTool, c: Vector3, r: float, col: Color, strength: float) -> void:
	var steps := 10
	for i in steps:
		var a0 := TAU * i / steps
		var a1 := TAU * (i + 1) / steps
		for pair in [[c, strength], [c + Vector3(cos(a0) * r, sin(a0) * r, 0), 0.0], [c + Vector3(cos(a1) * r, sin(a1) * r, 0), 0.0]]:
			st.set_color(Color(col.r, col.g, col.b, pair[1]))
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(pair[0])

## A candle-sized flame: an orange tongue with a yellow heart, two crossed so it reads from any side.
static func _flame(st: SurfaceTool, base: Vector3, h: float, w: float) -> void:
	for turn in [0.0, PI * 0.5]:
		var d := Vector3(cos(turn), 0, sin(turn)) * w
		Meshes._tri(st, base - d, base + d, base + Vector3(0, h, 0), Color(1.0, 0.5, 0.12, 1.0))
		Meshes._tri(st, base - d * 0.5, base + d * 0.5, base + Vector3(0, h * 0.62, 0), Color(1.0, 0.88, 0.45, 1.0))

const SKIN := [Color("f0c8a0"), Color("d9a77c"), Color("a8714a"), Color("6e4a32"), Color("f4d4b4")]

# --- Cardiff: the rugby ground, in the rain ----------------------------------------

## One tile of terrace against the north wall, packed. Variant % 3 is the crowd's colours (0 Wales, 1 Ireland,
## 2 Scotland); the rest only reshuffles the faces, so neighbouring tiles don't look cloned.
static func stadium_stand(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41000 + variant)
	var kits: Array = [[Color("c8102e"), Color("f2ede2"), Color("2f8a4a")], [Color("2f8a4a"), Color("f2ede2"), Color("e8892a")],
		[Color("1f4f9a"), Color("f2ede2"), Color("2a3a6a")]][variant % 3]
	var concrete := Color("8d8a84")
	for row in 4:
		var y := 0.25 + row * 0.42
		var depth := 0.95 - row * 0.22
		Meshes.box(st, Vector3(-0.5, 0, -0.5), Vector3(1.0, y, depth), concrete.darkened(0.05 * row), concrete.lightened(0.06))
		var zf := -0.5 + depth - 0.14  # the front of this tier
		for i in 3:
			var x := -0.34 + i * 0.33 + rng.randf_range(-0.04, 0.04)
			var shirt: Color = kits[0] if rng.randf() < 0.6 else kits[rng.randi() % 3]
			Meshes.box(st, Vector3(x - 0.09, y, zf - 0.08), Vector3(0.18, 0.2, 0.14), shirt)
			Meshes.box(st, Vector3(x - 0.06, y + 0.2, zf - 0.06), Vector3(0.12, 0.12, 0.11), SKIN[rng.randi() % SKIN.size()])
			if rng.randf() < 0.35:  # a scarf held up, or a bobble hat
				Meshes.box(st, Vector3(x - 0.13, y + 0.3, zf - 0.02), Vector3(0.26, 0.05, 0.03), kits[1] if rng.randf() < 0.5 else kits[0])
			elif rng.randf() < 0.4:
				Meshes.box(st, Vector3(x - 0.065, y + 0.31, zf - 0.065), Vector3(0.13, 0.06, 0.12), kits[0])
	# the roof's front edge and the back wall it hangs off
	_panel(st, -0.5, 1.9, 0.5, 2.45, -0.48, Color("3a3f48"))
	Meshes.box(st, Vector3(-0.5, 2.3, -0.5), Vector3(1.0, 0.12, 0.7), Color("4a505a"), Color("5c636e"))
	Meshes.box(st, Vector3(-0.5, 2.24, 0.16), Vector3(1.0, 0.06, 0.04), kits[0])
	return Meshes._finish(st)

## Rugby posts, in two halves so each upright blocks its own tile: 0 the left upright with the crossbar running
## east a tile, 1 the right one with it running west. Red padding round the foot of each, as at the Arms Park.
static func rugby_posts(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var white := Color("f2efe6")
	Meshes.box(st, Vector3(-0.17, 0, -0.17), Vector3(0.34, 0.75, 0.34), Color("c8102e"), Color("e0303e"))
	Meshes.box(st, Vector3(-0.12, 0.6, -0.1), Vector3(0.24, 0.1, 0.22), white)  # the sponsor's band, mercifully blank
	Meshes.cylinder(st, Vector3(0, 0.75, 0), 0.05, 2.9, 6, white)
	var dir := 1.0 if variant % 2 == 0 else -1.0
	_bar(st, Vector3(0, 1.25, 0), Vector3(dir * 1.0, 1.25, 0), 0.045, white)
	return Meshes._finish(st)

## A floodlight mast with its bank of lamps tilted down at the pitch.
static func floodlight() -> ArrayMesh:
	var st := Meshes._st()
	var steel := Color("6d737c")
	Meshes.box(st, Vector3(-0.2, 0, -0.2), Vector3(0.4, 0.16, 0.4), Color("8d8a84"))
	for c in [Vector2(-0.1, -0.1), Vector2(0.1, -0.1), Vector2(0.1, 0.1), Vector2(-0.1, 0.1)]:
		_bar(st, Vector3(c.x, 0.16, c.y), Vector3(c.x * 0.4, 3.0, c.y * 0.4), 0.025, steel)
	for i in 6:  # lattice rungs
		var y := 0.5 + i * 0.45
		var k := 1.0 - (y - 0.16) / 2.84 * 0.6
		_bar(st, Vector3(-0.1 * k, y, 0.1 * k), Vector3(0.1 * k, y + 0.2, 0.1 * k), 0.012, steel)
	Meshes.box(st, Vector3(-0.42, 2.95, -0.12), Vector3(0.84, 0.5, 0.1), Color("2d3138"))
	for r in 2:
		for c in 4:
			Meshes.box(st, Vector3(-0.38 + c * 0.2, 3.0 + r * 0.23, -0.02), Vector3(0.16, 0.18, 0.02), Color("e8ecf0"))
	return Meshes._finish(st)

## The floodlight's glare and the cold wash it throws on the wet grass in front of it.
static func floodlight_glow() -> ArrayMesh:
	var st := Meshes._st()
	var cold := Color(0.75, 0.85, 1.0)
	for r in 2:
		for c in 4:
			_glow_disc(st, Vector3(-0.3 + c * 0.2, 3.09 + r * 0.23, 0.02), 0.16, cold, 0.9)
	_glow_pool(st, Vector3(0, 0.02, 1.6), 2.0, 1.8, cold, 0.22)
	return Meshes._finish(st)

## Standing water on the pitch: a dark sheet with a pale glint along its far edge. Walk-over.
static func puddle(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41100 + variant)
	var pts := []
	var n := 9
	for i in n:
		var a := TAU * i / n
		var r := rng.randf_range(0.28, 0.46)
		pts.append(Vector3(cos(a) * r * 1.2, 0.012, sin(a) * r * 0.85))
	var c := Vector3(rng.randf_range(-0.05, 0.05), 0.012, 0)
	for i in n:
		Meshes._tri(st, c, pts[i], pts[(i + 1) % n], Color("3e5262"))
	for i in range(5, 8):  # the glint, on the side away from the camera
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % n]
		Meshes._quad(st, a.lerp(c, 0.25) + Vector3(0, 0.002, 0), b.lerp(c, 0.25) + Vector3(0, 0.002, 0), b.lerp(c, 0.4) + Vector3(0, 0.002, 0), a.lerp(c, 0.4) + Vector3(0, 0.002, 0), Color("9fb6c4"))
	return Meshes._finish(st)

## A painted line on a pitch or the ice, running east from the tile's west edge. Variant % 100 is its length in
## tiles (at least 1); variant / 100 its colour: 0 white, 1 red, 2 blue. Walk-over.
static func pitch_line(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var length := float(maxi(variant % 100, 1))
	var col: Color = [Color("f2f2ea"), Color("c8323a"), Color("2f5fa8")][clampi(floori(variant / 100.0), 0, 2)]
	floor_quad(st, -0.5, -0.045, length - 0.5, 0.045, 0.011, col)
	return Meshes._finish(st)

# --- Belfast: the shipyard --------------------------------------------------------

## A yellow gantry crane straddling the dock, after Samson and Goliath: legs three tiles apart (local x = -1.45
## and +1.45), the girder at the top, the hook down over the slip with a plate on it.
static func gantry_crane() -> ArrayMesh:
	var st := Meshes._st()
	var yellow := Color("e8c21a")
	for sx in [-1.45, 1.45]:
		var x: float = sx
		_bar(st, Vector3(x, 0, -0.55), Vector3(x, 2.5, -0.1), 0.07, yellow)
		_bar(st, Vector3(x, 0, 0.55), Vector3(x, 2.5, 0.1), 0.07, yellow)
		_bar(st, Vector3(x, 0.9, -0.38), Vector3(x, 0.9, 0.38), 0.04, yellow.darkened(0.1))
		Meshes.box(st, Vector3(x - 0.14, 0, -0.65), Vector3(0.28, 0.1, 1.3), Color("2d3138"))  # the bogies on the rail
	Meshes.box(st, Vector3(-1.75, 2.45, -0.22), Vector3(3.5, 0.42, 0.44), yellow, yellow.lightened(0.15))
	for i in 3:  # "H&W", or near enough from down here
		Meshes.box(st, Vector3(-0.42 + i * 0.3, 2.52, 0.225), Vector3(0.2, 0.28, 0.01), Color("2d3138"))
	Meshes.box(st, Vector3(0.25, 2.2, -0.2), Vector3(0.5, 0.25, 0.4), yellow.darkened(0.15))  # the crab
	_bar(st, Vector3(0.5, 2.2, 0), Vector3(0.5, 1.15, 0), 0.012, IRON)
	Meshes.box(st, Vector3(0.4, 1.0, -0.06), Vector3(0.2, 0.15, 0.12), IRON)
	Meshes.box(st, Vector3(0.0, 0.82, -0.3), Vector3(1.0, 0.06, 0.6), Color("6d737c"))  # a hull plate going in
	_bar(st, Vector3(0.5, 1.0, 0), Vector3(0.05, 0.88, -0.25), 0.008, IRON)
	_bar(st, Vector3(0.5, 1.0, 0), Vector3(0.95, 0.88, 0.25), 0.008, IRON)
	return Meshes._finish(st)

## A hull on the slip, half framed and half plated, in red lead primer. It lies north-south, about three tiles.
static func ship_ribs() -> ArrayMesh:
	var st := Meshes._st()
	var primer := Color("a8452e")
	var plate := Color("5d6168")
	Meshes.box(st, Vector3(-0.08, -0.2, -1.6), Vector3(0.16, 0.3, 3.2), primer.darkened(0.2))  # the keel
	for i in 9:
		var z := -1.45 + i * 0.36
		var w := 0.62 - absf(i - 4) * 0.035
		var steps := 5
		var prev := Vector3(-w, 1.1, z)
		for k in range(1, steps + 1):  # a U-frame, port to starboard
			var a := PI * k / steps
			var cur := Vector3(-cos(a) * w, 1.1 - sin(a) * 1.15, z)
			_bar(st, prev, cur, 0.035, primer)
			prev = cur
	# plating over the stern half
	for side in [-1.0, 1.0]:
		var s: float = side
		Meshes._quad(st, Vector3(s * 0.62, 1.05, 0.2), Vector3(s * 0.62, 1.05, 1.6), Vector3(s * 0.25, 0.0, 1.6), Vector3(s * 0.25, 0.0, 0.2), plate)
		Meshes._quad(st, Vector3(s * 0.62, 1.05, 1.6), Vector3(s * 0.62, 1.05, 0.2), Vector3(s * 0.25, 0.0, 0.2), Vector3(s * 0.25, 0.0, 1.6), plate.darkened(0.15))
	_bar(st, Vector3(-0.64, 1.1, -1.5), Vector3(-0.64, 1.1, 1.6), 0.03, primer.lightened(0.1))
	_bar(st, Vector3(0.64, 1.1, -1.5), Vector3(0.64, 1.1, 1.6), 0.03, primer.lightened(0.1))
	return Meshes._finish(st)

## Steel plate stacked on timber bearers, with a riveter's toolbox on top.
static func steel_plates() -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41200)
	for bz in [-0.3, 0.2]:
		Meshes.box(st, Vector3(-0.42, 0, float(bz)), Vector3(0.84, 0.1, 0.12), WOOD)
	for i in 6:
		var off := rng.randf_range(-0.04, 0.04)
		Meshes.box(st, Vector3(-0.4 + off, 0.1 + i * 0.06, -0.36), Vector3(0.8, 0.05, 0.7), Color("6d737c").darkened(rng.randf() * 0.15), Color("8a6a4a") if i == 5 else Color(0, 0, 0, 0))
	Meshes.box(st, Vector3(-0.2, 0.46, -0.1), Vector3(0.3, 0.14, 0.16), Color("c8323a"))
	_bar(st, Vector3(-0.15, 0.6, -0.02), Vector3(0.05, 0.6, -0.02), 0.012, IRON)
	return Meshes._finish(st)

# --- Dublin: the parish hall ------------------------------------------------------

## The hall's stage against the north wall, in three tiles: 0 left (curtain), 1 middle, 2 right (curtain).
static func hall_stage(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var part := variant % 3
	var boards := Color("9a6a3e")
	var velvet := Color("8c1f2a")
	Meshes.box(st, Vector3(-0.5, 0, -0.5), Vector3(1.0, 0.5, 0.9), boards.darkened(0.25), boards)
	for i in 4:
		Meshes.box(st, Vector3(-0.5, 0.5, -0.45 + i * 0.22), Vector3(1.0, 0.005, 0.01), boards.darkened(0.2))
	_panel(st, -0.5, 0.5, 0.5, 2.45, -0.49, Color("1f2a3a"))  # the backcloth
	Meshes.box(st, Vector3(-0.5, 2.05, -0.48), Vector3(1.0, 0.4, 0.14), velvet, velvet.lightened(0.1))  # the pelmet
	Meshes.box(st, Vector3(-0.5, 2.02, -0.34), Vector3(1.0, 0.04, 0.01), BRASS)
	if part != 1:
		var x0 := -0.5 if part == 0 else 0.1
		for f in 4:  # folds
			Meshes.box(st, Vector3(x0 + f * 0.1, 0.5, -0.47 + (f % 2) * 0.05), Vector3(0.1, 1.55, 0.12), velvet.darkened(0.08 * (f % 2)))
		Meshes.box(st, Vector3(x0 + 0.05, 1.05, -0.33), Vector3(0.3, 0.04, 0.03), BRASS)  # the tie-back
	else:
		Meshes.box(st, Vector3(-0.42, 1.55, -0.47), Vector3(0.84, 0.4, 0.02), Color("2f8a4a"))  # a banner: the club crest
		Meshes.box(st, Vector3(-0.12, 1.62, -0.45), Vector3(0.24, 0.26, 0.02), Color("f2ede2"))
		Meshes.box(st, Vector3(-0.06, 1.66, -0.44), Vector3(0.12, 0.18, 0.02), Color("e8892a"))
	return Meshes._finish(st)

## A trestle table in a white cloth: the urn, cups on saucers and a plate of barmbrack. Every hall has one.
static func tea_urn() -> ArrayMesh:
	var st := Meshes._st()
	Meshes.box(st, Vector3(-0.44, 0.66, -0.34), Vector3(0.88, 0.05, 0.68), Color("f2ede2"))
	Meshes.box(st, Vector3(-0.44, 0.42, 0.33), Vector3(0.88, 0.26, 0.01), Color("e8e2d4"))  # the cloth's drop
	for px in [-0.38, 0.33]:
		_bar(st, Vector3(float(px), 0, -0.25), Vector3(float(px) + 0.04, 0.66, 0.0), 0.02, IRON)
		_bar(st, Vector3(float(px), 0, 0.25), Vector3(float(px) + 0.04, 0.66, 0.0), 0.02, IRON)
	var steel := Color("c4ccd2")
	Meshes.cylinder(st, Vector3(-0.2, 0.71, -0.1), 0.15, 0.42, 10, steel)
	Meshes.cylinder(st, Vector3(-0.2, 1.13, -0.1), 0.1, 0.05, 10, steel.darkened(0.2))
	Meshes.box(st, Vector3(-0.22, 0.8, 0.04), Vector3(0.04, 0.05, 0.08), IRON)  # the tap
	for i in 3:
		var x := 0.08 + i * 0.11
		Meshes.cylinder(st, Vector3(x, 0.71, 0.12), 0.05, 0.01, 8, Color("f8f6f0"))
		Meshes.cylinder(st, Vector3(x, 0.72, 0.12), 0.035, 0.06, 8, Color("f8f6f0"))
	Meshes.cylinder(st, Vector3(0.2, 0.71, -0.16), 0.13, 0.01, 10, Color("e0dccf"))
	for i in 3:
		Meshes.box(st, Vector3(0.12 + i * 0.05, 0.72, -0.2), Vector3(0.05, 0.05, 0.09), Color("7a4a2a"))
	return Meshes._finish(st)

## Orange plastic stacking chairs, two stacks of them (variant: how high).
static func stacked_chairs(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var orange := Color("d9762a")
	for s in 2:
		var x := -0.32 + s * 0.42
		var n := 4 + (variant + s) % 3
		for i in n:
			var y := 0.42 + i * 0.07
			Meshes.box(st, Vector3(x - 0.17, y, -0.17), Vector3(0.34, 0.035, 0.32), orange.darkened(0.04 * (i % 2)))
			Meshes.box(st, Vector3(x - 0.17, y + 0.04, -0.2), Vector3(0.34, 0.3, 0.03), orange.darkened(0.04 * (i % 2)))
		for c in [Vector2(-0.15, -0.15), Vector2(0.13, -0.15), Vector2(-0.15, 0.13), Vector2(0.13, 0.13)]:
			_bar(st, Vector3(x + c.x, 0, c.y), Vector3(x + c.x, 0.42, c.y), 0.012, IRON)
	return Meshes._finish(st)

# --- Galway: the docks ------------------------------------------------------------

## A tarred currach, upturned on two trestles to dry, an oar leaning on it. A small one: it keeps to its tile.
static func currach() -> ArrayMesh:
	var st := Meshes._st()
	var tar := Color("1d1f24")
	for tx in [-0.38, 0.38]:
		var x: float = tx
		_bar(st, Vector3(x, 0, -0.22), Vector3(x, 0.4, 0), 0.022, WOOD)
		_bar(st, Vector3(x, 0, 0.22), Vector3(x, 0.4, 0), 0.022, WOOD)
		Meshes.box(st, Vector3(x - 0.04, 0.38, -0.26), Vector3(0.08, 0.04, 0.52), WOOD)
	Meshes.blob(st, Vector3(0, 0.44, 0), Vector3(0.62, 0.2, 0.3), tar, Meshes._rng(41250), 0.04)
	Meshes.box(st, Vector3(-0.6, 0.42, -0.26), Vector3(1.2, 0.035, 0.52), WOOD.darkened(0.35))  # the gunwale, underneath
	_bar(st, Vector3(-0.62, 0.64, 0), Vector3(0.62, 0.64, 0), 0.018, tar.lightened(0.18))  # the keel strip
	_bar(st, Vector3(0.2, 0, 0.42), Vector3(0.45, 0.95, 0.18), 0.018, WOOD.lightened(0.15))
	Meshes.box(st, Vector3(0.15, 0, 0.39), Vector3(0.1, 0.22, 0.03), WOOD.lightened(0.15))
	return Meshes._finish(st)

## Creels stacked on the quay with a coil of rope and a float. Variant: how many.
static func lobster_pots(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41300 + variant)
	var net := Color("3f5a4a")
	var spots := [Vector3(-0.2, 0, -0.15), Vector3(0.2, 0, -0.12), Vector3(0.0, 0.32, -0.13), Vector3(-0.2, 0, 0.22)]
	for i in 3 + variant % 2:
		var p: Vector3 = spots[i]
		Meshes.box(st, p + Vector3(-0.17, 0, -0.14), Vector3(0.34, 0.06, 0.28), WOOD.darkened(0.1))
		for k in 3:
			var hz := -0.1 + k * 0.1
			var prev := p + Vector3(-0.16, 0.06, hz)
			for j in range(1, 5):
				var a := PI * j / 4
				var cur := p + Vector3(-cos(a) * 0.16, 0.06 + sin(a) * 0.24, hz)
				_bar(st, prev, cur, 0.012, net.lightened(rng.randf() * 0.1))
				prev = cur
		Meshes.box(st, p + Vector3(-0.15, 0.06, -0.12), Vector3(0.3, 0.2, 0.24), _a(net.darkened(0.3), 1.0))
	Meshes.cylinder(st, Vector3(0.24, 0, 0.24), 0.14, 0.08, 10, Color("c9a86a"))
	Meshes.blob(st, Vector3(0.3, 0.12, 0.05), Vector3(0.09, 0.09, 0.09), Color("e8602a"), rng, 0.05)
	return Meshes._finish(st)

## The old town wall by the quay, with the Spanish Arch: 0 an arch with the bay through it, 1 plain wall.
static func harbour_arch(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41400 + variant)
	var lime := Color("a8a294")
	if variant % 2 == 0:
		var sky := Color("b8d4dc")
		_panel(st, -0.34, 0, 0.34, 1.0, -0.49, sky)  # the bay through the arch, under a pale sky
		_panel(st, -0.34, 0, 0.34, 0.5, -0.485, Color("4f8aa0"))
		_panel(st, -0.34, 0.48, 0.34, 0.53, -0.483, Color("5d6a5a"))  # Mutton Island, low on the water
		_panel(st, 0.04, 0.24, 0.12, 0.38, -0.482, Color("8a3a2a"))  # a hooker's brown sail
		Meshes.box(st, Vector3(-0.5, 0, -0.5), Vector3(0.16, 1.0, 0.28), lime)
		Meshes.box(st, Vector3(0.34, 0, -0.5), Vector3(0.16, 1.0, 0.28), lime)
		Meshes.box(st, Vector3(-0.5, 1.0, -0.5), Vector3(1.0, 1.45, 0.28), lime)
		var c := Vector3(0, 1.0, -0.218)
		for i in 8:  # the round head painted on as the opening's top, ringed with voussoirs
			var a0 := PI * i / 8
			var a1 := PI * (i + 1) / 8
			Meshes._tri(st, c, c + Vector3(cos(a1) * 0.34, sin(a1) * 0.34, 0), c + Vector3(cos(a0) * 0.34, sin(a0) * 0.34, 0), sky)
			Meshes._quad(st, c + Vector3(cos(a1) * 0.46, sin(a1) * 0.46, 0.001), c + Vector3(cos(a0) * 0.46, sin(a0) * 0.46, 0.001),
				c + Vector3(cos(a0) * 0.34, sin(a0) * 0.34, 0.001), c + Vector3(cos(a1) * 0.34, sin(a1) * 0.34, 0.001), lime.lightened(0.1 if i % 2 == 0 else 0.04))
	else:
		Meshes.box(st, Vector3(-0.5, 0, -0.5), Vector3(1.0, 2.45, 0.28), lime)
		Meshes.cylinder(st, Vector3(0, 0.6, -0.2), 0.07, 0.02, 8, IRON)  # a mooring ring, high and dry
	for i in 10:  # coursed stone
		var y := rng.randf_range(0.1, 2.3)
		var x := rng.randf_range(-0.45, 0.3)
		if variant % 2 == 0 and absf(x + 0.07) < 0.55 and y < 1.55:
			continue
		Meshes.box(st, Vector3(x, y, -0.225), Vector3(rng.randf_range(0.12, 0.2), 0.08, 0.01), lime.darkened(0.12))
	Meshes.box(st, Vector3(-0.5, 0, -0.22), Vector3(1.0, 0.2, 0.03), Color("4a5a3a"))  # weed where the tide comes
	return Meshes._finish(st)

# --- Glastonbury: the fae ------------------------------------------------------------

## A crooked hazel post hung with paper lanterns. The glow is fae_glow.
static func fae_lantern(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var hazel := Color("6b5a3e")
	_bar(st, Vector3(0, 0, 0), Vector3(0.05, 1.0, 0.02), 0.035, hazel)
	_bar(st, Vector3(0.05, 1.0, 0.02), Vector3(-0.04, 1.75, 0), 0.03, hazel)
	_bar(st, Vector3(-0.04, 1.6, 0), Vector3(0.45, 1.85, 0), 0.02, hazel)
	_bar(st, Vector3(-0.02, 1.4, 0), Vector3(-0.42, 1.6, 0.05), 0.02, hazel)
	var paper: Color = [Color("e8d27a"), Color("b8e0a0"), Color("e8b0c8")][variant % 3]
	for p in [Vector3(0.38, 1.55, 0), Vector3(-0.36, 1.33, 0.05)]:
		_bar(st, p + Vector3(0, 0.22, 0), p + Vector3(0, 0.15, 0), 0.005, IRON)
		Meshes.cylinder(st, p - Vector3(0, 0.0, 0), 0.08, 0.15, 8, paper)
	return Meshes._finish(st)

## The lanterns' light: green-gold, never quite steady, and a faint ring of it on the grass.
static func fae_glow(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var col: Color = [Color(1.0, 0.85, 0.4), Color(0.6, 1.0, 0.55), Color(1.0, 0.6, 0.85)][variant % 3]
	for p in [Vector3(0.38, 1.62, 0.1), Vector3(-0.36, 1.4, 0.15)]:
		_glow_disc(st, p, 0.24, col, 0.9)
	_glow_pool(st, Vector3(0, 0.03, 0.1), 1.2, 1.0, col, 0.22)
	return Meshes._finish(st)

## A fairy ring: red-capped toadstools round the tile, spotted. Walk-over (if you dare).
static func toadstool_ring(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41500 + variant)
	var n := 9
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.15, 0.15)
		var r := 0.42 + rng.randf_range(-0.04, 0.04)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		var h := rng.randf_range(0.07, 0.14)
		Meshes.cylinder(st, p, 0.025, h, 5, Color("efe8d8"))
		Meshes.blob(st, p + Vector3(0, h, 0), Vector3(0.07, 0.035, 0.07), Color("c8282e"), rng, 0.05)
		Meshes.box(st, p + Vector3(-0.015, h + 0.025, 0.02), Vector3(0.02, 0.015, 0.02), Color("f8f4ea"))
	return Meshes._finish(st)

## The Holy Thorn, or a cousin: a gnarled hawthorn tied with rag ribbons for wishes (a clootie tree).
static func clootie_tree(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41600 + variant)
	var bark := Color("5a4a3a")
	_bar(st, Vector3(0, 0, 0), Vector3(0.1, 0.8, 0.0), 0.08, bark)
	_bar(st, Vector3(0.1, 0.8, 0.0), Vector3(-0.15, 1.3, 0.05), 0.06, bark)
	_bar(st, Vector3(0.1, 0.8, 0.0), Vector3(0.45, 1.25, -0.05), 0.05, bark)
	var greens := [Color("4f6a3a"), Color("5d7a3f"), Color("6a7a3a")]
	for c in [Vector3(-0.2, 1.5, 0), Vector3(0.45, 1.45, -0.05), Vector3(0.12, 1.7, 0.0), Vector3(-0.4, 1.3, 0.1)]:
		Meshes.blob(st, c, Vector3(0.36, 0.26, 0.32), greens[rng.randi() % 3], rng, 0.22)
		for k in 3:  # haws
			Meshes.box(st, c + Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.15, 0.15), 0.26), Vector3(0.04, 0.04, 0.04), Color("b8202a"))
	for i in 9:  # the clooties
		var at := Vector3(rng.randf_range(-0.5, 0.6), rng.randf_range(1.05, 1.35), rng.randf_range(0.15, 0.3))
		var rag: Color = CLOTH[rng.randi() % CLOTH.size()].lightened(0.1)
		Meshes.box(st, at, Vector3(0.05, 0.22, 0.01), rag)
	return Meshes._finish(st)

# --- Inverness: the curling rink ------------------------------------------------------

## The house: blue, white and red rings painted under the ice, three tiles across, with the tee in the middle.
static func curling_house() -> ArrayMesh:
	var st := Meshes._st()
	var rings := [[1.45, Color("2f5fa8")], [1.05, Color("f4f8fb")], [0.68, Color("c8323a")], [0.24, Color("f4f8fb")]]
	for i in rings.size():
		var r: float = rings[i][0]
		var col: Color = rings[i][1]
		var y := 0.009 + i * 0.003
		var steps := 24
		for k in steps:
			var a0 := TAU * k / steps
			var a1 := TAU * (k + 1) / steps
			Meshes._tri(st, Vector3(0, y, 0), Vector3(cos(a0) * r, y, sin(a0) * r), Vector3(cos(a1) * r, y, sin(a1) * r), col)
	floor_quad(st, -1.5, -0.02, 1.5, 0.02, 0.022, Color("3a3f48"))  # the tee line
	floor_quad(st, -0.02, -1.5, 0.02, 1.5, 0.022, Color("3a3f48"))  # the centre line
	return Meshes._finish(st)

## Granite stones waiting by the hack, red handles and yellow, and a broom. Variant: how many.
static func curling_stones(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var granite := Color("7a7e86")
	var spots := [Vector2(-0.22, -0.15), Vector2(0.18, -0.2), Vector2(-0.12, 0.2), Vector2(0.24, 0.18)]
	for i in 2 + variant % 3:
		var p := Vector3(spots[i].x, 0, spots[i].y)
		Meshes.cylinder(st, p, 0.14, 0.04, 10, granite.darkened(0.15))
		Meshes.cylinder(st, p + Vector3(0, 0.04, 0), 0.15, 0.07, 10, granite)
		Meshes.cylinder(st, p + Vector3(0, 0.11, 0), 0.12, 0.012, 10, granite.lightened(0.15))
		Meshes.box(st, p + Vector3(-0.025, 0.12, -0.09), Vector3(0.05, 0.045, 0.16), Color("c8323a") if i % 2 == 0 else Color("e8c21a"))
	_bar(st, Vector3(0.4, 0, 0.4), Vector3(0.1, 1.05, -0.35), 0.018, Color("2d3138"))  # a broom leaning on nothing
	Meshes.box(st, Vector3(0.32, 0, 0.32), Vector3(0.18, 0.06, 0.1), Color("2f5fa8"))
	return Meshes._finish(st)

# --- Liverpool: the cellar club --------------------------------------------------------

## Brick barrel arches against the north wall, the Cavern way. 0 an arch bay (dark, a poster in it), 1 a pier.
static func brick_arch(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41700 + variant)
	var brick := Color("8a4a32")
	var mortar := Color("4a2e22")
	if variant % 2 == 0:
		_panel(st, -0.5, 0, 0.5, 2.45, -0.49, Color("1d1614"))
		var poster: Color = [Color("e8c21a"), Color("c8323a"), Color("f2ede2")][rng.randi() % 3]
		_panel(st, -0.18, 0.9, 0.18, 1.4, -0.485, poster)
		_panel(st, -0.14, 1.2, 0.14, 1.32, -0.483, Color("1d1614"))
		_panel(st, -0.12, 0.98, 0.1, 1.05, -0.483, Color("1d1614"))
		for i in 9:  # the arch, brick on edge
			var a := PI * i / 8
			var c := Vector3(-cos(a) * 0.5, 1.75 + sin(a) * 0.45, -0.38)
			Meshes.box(st, c + Vector3(-0.06, -0.06, -0.12), Vector3(0.12, 0.12, 0.24), brick.lightened(rng.randf() * 0.1))
		Meshes.box(st, Vector3(-0.5, 2.2, -0.5), Vector3(1.0, 0.25, 0.24), brick)
	else:
		Meshes.box(st, Vector3(-0.5, 0, -0.5), Vector3(1.0, 2.45, 0.3), brick)
		for row in 14:  # courses
			var y := 0.08 + row * 0.17
			Meshes.box(st, Vector3(-0.5, y, -0.205), Vector3(1.0, 0.018, 0.01), mortar)
			var off := 0.0 if row % 2 == 0 else 0.15
			for k in 4:
				Meshes.box(st, Vector3(-0.45 + off + k * 0.3, y - 0.15, -0.205), Vector3(0.018, 0.15, 0.01), mortar)
	return Meshes._finish(st)

## The band's kit: 0 the drums, 1 an amp stack, 2 a mic stand and a guitar on its stand.
static func band_kit(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	match variant % 3:
		0:
			Meshes.cylinder(st, Vector3(0, 0.0, 0), 0.24, 0.0, 12, IRON)
			var bass := Vector3(0, 0.26, 0.05)
			for r in [[0.26, Color("2d3138")], [0.22, Color("f2ede2")]]:
				_disc_z(st, bass + Vector3(0, 0, 0.14 + (0.01 if float(r[0]) < 0.25 else 0.0)), float(r[0]), 14, r[1])
			Meshes.cylinder(st, bass + Vector3(0, -0.26, -0.13), 0.26, 0.0, 12, IRON)
			Meshes.box(st, Vector3(-0.26, 0.0, -0.1), Vector3(0.52, 0.52, 0.3), Color("c8323a"))
			_disc_z(st, bass + Vector3(0, 0.0, 0.16), 0.08, 10, Color("c8323a"))  # the band's name, too small to read
			Meshes.cylinder(st, Vector3(-0.3, 0.55, 0.12), 0.13, 0.1, 10, Color("c8323a"))  # snare
			Meshes.cylinder(st, Vector3(0.2, 0.62, -0.02), 0.11, 0.12, 10, Color("c8323a"))  # tom
			for cx in [-0.42, 0.42]:
				_bar(st, Vector3(float(cx), 0, -0.1), Vector3(float(cx), 0.95, -0.1), 0.012, IRON)
				Meshes.cylinder(st, Vector3(float(cx), 0.95, -0.1), 0.17, 0.015, 10, BRASS)
			Meshes.box(st, Vector3(-0.12, 0, -0.42), Vector3(0.24, 0.45, 0.22), Color("2d3138"))  # the stool
		1:
			Meshes.box(st, Vector3(-0.32, 0, -0.3), Vector3(0.64, 0.62, 0.5), Color("1d1d20"))
			Meshes.box(st, Vector3(-0.3, 0.62, -0.28), Vector3(0.6, 0.42, 0.46), Color("1d1d20"))
			Meshes.box(st, Vector3(-0.28, 0.06, 0.2), Vector3(0.56, 0.5, 0.01), Color("3a3a40"))  # grille
			Meshes.box(st, Vector3(-0.28, 0.82, 0.18), Vector3(0.56, 0.06, 0.01), BRASS)
			for k in 5:
				Meshes.box(st, Vector3(-0.22 + k * 0.1, 0.72, 0.18), Vector3(0.04, 0.04, 0.02), Color("f2ede2"))
			Meshes.box(st, Vector3(-0.26, 0.94, 0.18), Vector3(0.2, 0.05, 0.01), Color("f2ede2"))  # the logo
		_:
			_bar(st, Vector3(-0.15, 0, -0.05), Vector3(-0.15, 1.35, -0.05), 0.012, IRON)
			_bar(st, Vector3(-0.15, 1.35, -0.05), Vector3(-0.1, 1.4, 0.1), 0.01, IRON)
			Meshes.blob(st, Vector3(-0.1, 1.42, 0.12), Vector3(0.035, 0.04, 0.035), Color("8a8e96"), Meshes._rng(3), 0.02)
			for k in 3:
				var a := TAU * k / 3
				_bar(st, Vector3(-0.15, 0.1, -0.05), Vector3(-0.15 + cos(a) * 0.15, 0, -0.05 + sin(a) * 0.15), 0.01, IRON)
			var body := Color("b8402a")
			Meshes.blob(st, Vector3(0.22, 0.32, 0), Vector3(0.16, 0.2, 0.05), body, Meshes._rng(4), 0.04)
			_disc_z(st, Vector3(0.22, 0.36, 0.05), 0.04, 8, Color("1d1614"))
			Meshes.box(st, Vector3(0.2, 0.5, -0.02), Vector3(0.04, 0.5, 0.03), WOOD.darkened(0.2))
			Meshes.box(st, Vector3(0.18, 1.0, -0.02), Vector3(0.08, 0.1, 0.03), WOOD.darkened(0.3))
			_bar(st, Vector3(0.1, 0, -0.1), Vector3(0.22, 0.3, -0.04), 0.012, IRON)
			_bar(st, Vector3(0.34, 0, -0.1), Vector3(0.22, 0.3, -0.04), 0.012, IRON)
	return Meshes._finish(st)

## A par can on a floor stand, aimed back up at the band. The colour is stage_glow's variant.
static func stage_light() -> ArrayMesh:
	var st := Meshes._st()
	for k in 3:
		var a := TAU * k / 3 + 0.4
		_bar(st, Vector3(0, 0.3, 0), Vector3(cos(a) * 0.18, 0, sin(a) * 0.18), 0.012, IRON)
	_bar(st, Vector3(0, 0.3, 0), Vector3(0, 0.55, 0), 0.014, IRON)
	Meshes.box(st, Vector3(-0.1, 0.5, -0.1), Vector3(0.2, 0.2, 0.22), Color("1d1d20"))
	return Meshes._finish(st)

## Stage colour: 0 magenta, 1 cyan, 2 amber, 3 green. A beam of it on the floor towards the band (north).
static func stage_glow(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var col: Color = [Color(1.0, 0.3, 0.75), Color(0.3, 0.8, 1.0), Color(1.0, 0.65, 0.2), Color(0.4, 1.0, 0.45)][variant % 4]
	_glow_disc(st, Vector3(0, 0.62, -0.13), 0.12, col, 1.0)
	_glow_pool(st, Vector3(0, 0.02, -1.1), 1.0, 1.25, col, 0.45)
	return Meshes._finish(st)

# --- Llanberis: the quarry -------------------------------------------------------------

## Dressed roofing slates stacked on edge in rows on a pallet, the blue-purple of Dinorwic. Variant: how full.
static func slate_stack(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41800 + variant)
	var slate := Color("4e5468")
	Meshes.box(st, Vector3(-0.42, 0, -0.36), Vector3(0.84, 0.1, 0.72), WOOD)
	for k in 3 + variant % 2:  # piles of dressed slates, flat, each a little askew
		var c := Vector3(-0.2 + (k % 2) * 0.4, 0.1, -0.16 + (0.32 if k >= 2 else 0.0))
		var h := 10 + rng.randi() % 6
		for i in h:
			var o := Vector3(rng.randf_range(-0.015, 0.015), i * 0.026, rng.randf_range(-0.015, 0.015))
			Meshes.box(st, c + o + Vector3(-0.17, 0, -0.12), Vector3(0.34, 0.022, 0.24), slate.lightened(rng.randf_range(-0.05, 0.08)), Color("6a7088"))
	return Meshes._finish(st)

## A slate wagon on a length of narrow-gauge track, loaded with slabs from the gallery.
static func slate_wagon() -> ArrayMesh:
	var st := Meshes._st()
	var slate := Color("4e5468")
	for rz in [-0.17, 0.17]:
		Meshes.box(st, Vector3(-0.5, 0, float(rz) - 0.02), Vector3(1.0, 0.05, 0.04), Color("6d737c"))
	for i in 4:
		Meshes.box(st, Vector3(-0.45 + i * 0.27, 0, -0.26), Vector3(0.1, 0.03, 0.52), WOOD.darkened(0.2))
	Meshes.box(st, Vector3(-0.36, 0.15, -0.22), Vector3(0.72, 0.1, 0.44), Color("3a3f48"))
	for wx in [-0.24, 0.24]:
		for wz in [-0.19, 0.19]:
			Meshes.cylinder(st, Vector3(float(wx), 0.04, float(wz)), 0.09, 0.03, 8, IRON)
	for cx in [-0.36, 0.3]:
		Meshes.box(st, Vector3(float(cx), 0.25, -0.22), Vector3(0.06, 0.3, 0.44), Color("3a3f48"))
	for i in 4:
		Meshes.box(st, Vector3(-0.3 + i * 0.03, 0.25 + i * 0.07, -0.18), Vector3(0.62 - i * 0.06, 0.06, 0.36), slate.lightened(0.04 * i))
	return Meshes._finish(st)

# --- York: the crypt -------------------------------------------------------------------

## Norman stonework over the north wall: 0 a round arch with a candle niche, 1 a squat pier with chevrons.
static func crypt_arch(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41900 + variant)
	var ashlar := Color("8a8274")
	if variant % 2 == 0:
		_panel(st, -0.5, 0, 0.5, 2.45, -0.49, Color("2a2622"))
		Meshes.box(st, Vector3(-0.5, 0, -0.5), Vector3(0.14, 0.75, 0.3), ashlar)
		Meshes.box(st, Vector3(0.36, 0, -0.5), Vector3(0.14, 0.75, 0.3), ashlar)
		for i in 9:
			var a := PI * i / 8
			var c := Vector3(-cos(a) * 0.43, 0.75 + sin(a) * 0.43, -0.35)
			Meshes.box(st, c + Vector3(-0.07, -0.07, -0.15), Vector3(0.14, 0.14, 0.3), ashlar.lightened(0.05 + rng.randf() * 0.05))
		Meshes.box(st, Vector3(-0.5, 1.25, -0.5), Vector3(1.0, 1.2, 0.26), ashlar)
		for sx in [-0.5, 0.36]:
			Meshes.box(st, Vector3(float(sx), 0.75, -0.5), Vector3(0.14, 0.5, 0.26), ashlar)
		Meshes.box(st, Vector3(-0.16, 0.3, -0.46), Vector3(0.32, 0.04, 0.12), ashlar.lightened(0.1))  # the niche's sill
		Meshes.box(st, Vector3(-0.1, 0.34, -0.44), Vector3(0.2, 0.12, 0.06), Color("efe6cc"))  # a skull, for the ghost walk
		Meshes.box(st, Vector3(-0.06, 0.39, -0.379), Vector3(0.04, 0.035, 0.01), Color("1d1a18"))
		Meshes.box(st, Vector3(0.02, 0.39, -0.379), Vector3(0.04, 0.035, 0.01), Color("1d1a18"))
	else:
		Meshes.box(st, Vector3(-0.5, 0, -0.5), Vector3(1.0, 2.45, 0.26), ashlar)
		Meshes.box(st, Vector3(-0.3, 0, -0.5), Vector3(0.6, 2.45, 0.36), ashlar.lightened(0.04))
		for k in 6:  # zig-zag chevrons, the Normans' favourite joke
			var y := 0.4 + k * 0.3
			_bar(st, Vector3(-0.28, y, -0.13), Vector3(0, y + 0.13, -0.13), 0.025, ashlar.darkened(0.2))
			_bar(st, Vector3(0, y + 0.13, -0.13), Vector3(0.28, y, -0.13), 0.025, ashlar.darkened(0.2))
	for i in 8:  # joints
		var y := rng.randf_range(0.1, 2.35)
		Meshes.box(st, Vector3(rng.randf_range(-0.5, 0.2), y, -0.235 if variant % 2 == 0 else -0.135), Vector3(0.28, 0.012, 0.01), ashlar.darkened(0.25))
	return Meshes._finish(st)

## A wrought-iron candle stand, five candles, wax down its legs. The flames are candle_glow.
static func candelabra() -> ArrayMesh:
	var st := Meshes._st()
	for k in 3:
		var a := TAU * k / 3 + 0.5
		_bar(st, Vector3(0, 0.25, 0), Vector3(cos(a) * 0.2, 0, sin(a) * 0.2), 0.015, IRON)
	_bar(st, Vector3(0, 0.2, 0), Vector3(0, 1.25, 0), 0.022, IRON)
	_bar(st, Vector3(-0.3, 1.2, 0), Vector3(0.3, 1.2, 0), 0.015, IRON)
	_bar(st, Vector3(0, 1.2, -0.2), Vector3(0, 1.2, 0.2), 0.015, IRON)
	for p in [Vector3(-0.3, 1.2, 0), Vector3(0.3, 1.2, 0), Vector3(0, 1.2, -0.2), Vector3(0, 1.2, 0.2), Vector3(0, 1.25, 0)]:
		Meshes.cylinder(st, p, 0.03, 0.16 + (0.06 if p.y > 1.21 else 0.0), 6, Color("efe6cc"))
		Meshes.box(st, p + Vector3(0.02, -0.06, -0.01), Vector3(0.015, 0.08, 0.015), Color("efe6cc"))  # a drip
	return Meshes._finish(st)

## Five small flames and the warm pool they make on the flags.
static func candle_glow() -> ArrayMesh:
	var st := Meshes._st()
	for p in [Vector3(-0.3, 1.36, 0), Vector3(0.3, 1.36, 0), Vector3(0, 1.36, -0.2), Vector3(0, 1.36, 0.2), Vector3(0, 1.47, 0)]:
		_flame(st, p, 0.11, 0.03)
		_glow_disc(st, p + Vector3(0, 0.04, 0.06), 0.16, Color(1.0, 0.7, 0.35), 0.45)
	_glow_pool(st, Vector3(0, 0.03, 0.1), 1.5, 1.3, Color(1.0, 0.6, 0.25), 0.4)
	return Meshes._finish(st)

## A tomb chest with its effigy on the lid, hands together: 0 a knight with his feet on a dog, 1 a lady.
static func tomb_chest(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(42000 + variant)
	var stone := Color("a39a88")
	Meshes.box(st, Vector3(-0.45, 0, -0.32), Vector3(0.9, 0.5, 0.64), stone.darkened(0.08), stone)
	for i in 3:  # weepers' niches on the side
		Meshes.box(st, Vector3(-0.36 + i * 0.27, 0.1, 0.32), Vector3(0.18, 0.3, 0.01), stone.darkened(0.3))
	var fig := stone.lightened(0.08) if variant % 2 == 0 else Color("e0dcd0")
	Meshes.box(st, Vector3(-0.36, 0.5, -0.12), Vector3(0.6, 0.12, 0.24), fig)
	Meshes.blob(st, Vector3(-0.36, 0.62, 0), Vector3(0.09, 0.08, 0.09), fig, rng, 0.04)
	Meshes.box(st, Vector3(-0.48, 0.5, -0.14), Vector3(0.12, 0.1, 0.28), stone.lightened(0.04))  # the pillow
	Meshes.box(st, Vector3(-0.1, 0.62, -0.03), Vector3(0.06, 0.1, 0.06), fig.darkened(0.05))  # hands together
	if variant % 2 == 0:
		Meshes.box(st, Vector3(-0.2, 0.62, 0.08), Vector3(0.48, 0.03, 0.04), fig.darkened(0.1))  # the sword
		Meshes.blob(st, Vector3(0.32, 0.6, 0), Vector3(0.08, 0.07, 0.1), fig.darkened(0.08), rng, 0.08)  # the dog
	else:
		Meshes.box(st, Vector3(0.0, 0.62, -0.12), Vector3(0.28, 0.04, 0.24), fig.darkened(0.04))  # the gown's folds
	return Meshes._finish(st)

# --- the Moot ---------------------------------------------------------------------------

## An iron fire basket on a tripod. The fire is brazier_fire.
static func brazier() -> ArrayMesh:
	var st := Meshes._st()
	for k in 3:
		var a := TAU * k / 3 + 0.3
		_bar(st, Vector3(cos(a) * 0.08, 0.7, sin(a) * 0.08), Vector3(cos(a) * 0.3, 0, sin(a) * 0.3), 0.025, IRON)
	var lo := Meshes._ring(Vector3(0, 0.68, 0), 0.12, 0.68, 8)
	var hi := Meshes._ring(Vector3(0, 0.95, 0), 0.3, 0.95, 8)
	for i in 8:
		var j := (i + 1) % 8
		Meshes._quad(st, lo[i], lo[j], hi[j], hi[i], IRON.lightened(0.05 * (i % 2)))
		Meshes._quad(st, hi[i], hi[j], lo[j], lo[i], IRON.darkened(0.2))
	Meshes.blob(st, Vector3(0, 0.9, 0), Vector3(0.24, 0.06, 0.24), Color("3a2418"), Meshes._rng(5), 0.1)
	return Meshes._finish(st)

static func brazier_fire() -> ArrayMesh:
	var st := Meshes._st()
	for i in 5:
		var a := TAU * i / 5
		_flame(st, Vector3(cos(a) * 0.12, 0.92, sin(a) * 0.12), 0.35 + 0.08 * (i % 2), 0.09)
	_flame(st, Vector3(0, 0.92, 0), 0.55, 0.12)
	_glow_disc(st, Vector3(0, 1.2, 0.15), 0.45, Color(1.0, 0.55, 0.2), 0.5)
	_glow_pool(st, Vector3(0, 0.03, 0), 1.8, 1.8, Color(1.0, 0.55, 0.2), 0.4)
	return Meshes._finish(st)

# --- Vane's penthouse -------------------------------------------------------------------

## Floor-to-ceiling glass on the north wall with London below at dusk. Variant picks the stretch of skyline
## (0 has the Shard, 1 the Gherkin, 2 just offices that all look like the Enclosure owns them).
static func city_window(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(42100 + variant)
	var sky := [Color("f0a868"), Color("c8789a"), Color("5a5a8a"), Color("2a3050")]
	for i in 4:  # dusk, banded
		_panel(st, -0.5, 0.15 + i * 0.57, 0.5, 0.15 + (i + 1) * 0.57, -0.49, sky[i])
	var skyline := Color("2a2f3e")
	var x := -0.5
	while x < 0.5:
		var w := rng.randf_range(0.08, 0.18)
		var h := rng.randf_range(0.35, 0.95)
		var x1 := minf(x + w, 0.5)
		_panel(st, x, 0.15, x1, 0.15 + h, -0.485, skyline.lightened(rng.randf() * 0.08))
		for k in int(h / 0.12):
			if rng.randf() < 0.45:
				var wy := 0.22 + k * 0.12
				_panel(st, x + 0.02, wy, x + 0.045, wy + 0.04, -0.483, Color("f0d080"))
		x = x1 + 0.01
	match variant % 3:
		0:
			Meshes._tri(st, Vector3(-0.1, 0.15, -0.482), Vector3(0.08, 0.15, -0.482), Vector3(-0.03, 1.9, -0.482), Color("4a5068"))
		1:
			Meshes.blob(st, Vector3(0.15, 0.7, -0.48), Vector3(0.09, 0.45, 0.005), Color("3f5a6a"), rng, 0.0)
	for mx in [-0.5, 0.47]:  # mullions
		Meshes.box(st, Vector3(float(mx), 0, -0.5), Vector3(0.03, 2.45, 0.06), Color("1d2028"))
	Meshes.box(st, Vector3(-0.5, 0, -0.5), Vector3(1.0, 0.15, 0.1), Color("1d2028"))
	return Meshes._finish(st)

## The Enclosure's banner on its stand: a long drop of slate grey with the logo, a white cage in a green square.
static func enclosure_banner() -> ArrayMesh:
	var st := Meshes._st()
	var grey := Color("3a4048")
	Meshes.box(st, Vector3(-0.32, 2.32, -0.5), Vector3(0.64, 0.05, 0.1), IRON)
	for sx in [-0.34, 0.31]:  # it stands on its own two feet, which is more than its owner does
		Meshes.box(st, Vector3(float(sx), 0, -0.5), Vector3(0.03, 2.37, 0.03), IRON)
		Meshes.box(st, Vector3(float(sx) - 0.08, 0, -0.62), Vector3(0.19, 0.03, 0.25), IRON)
	_panel(st, -0.28, 0.45, 0.28, 2.32, -0.46, grey)
	Meshes._tri(st, Vector3(-0.28, 0.45, -0.46), Vector3(0.28, 0.45, -0.46), Vector3(0, 0.3, -0.46), grey)
	_panel(st, -0.2, 1.4, 0.2, 1.8, -0.455, Color("2f6a4a"))
	for k in 4:
		_panel(st, -0.15 + k * 0.1, 1.45, -0.13 + k * 0.1, 1.75, -0.45, Color("f2ede2"))
	_panel(st, -0.15, 1.72, 0.17, 1.75, -0.449, Color("f2ede2"))
	_panel(st, -0.15, 1.45, 0.17, 1.48, -0.449, Color("f2ede2"))
	_panel(st, -0.2, 1.12, 0.2, 1.17, -0.455, Color("c9c4b8"))  # the motto, in very small capitals
	return Meshes._finish(st)

## A glass case on a plinth with something wild inside that would rather not be. Variant: its colour.
static func creature_cage(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(42200 + variant)
	Meshes.box(st, Vector3(-0.32, 0, -0.32), Vector3(0.64, 0.5, 0.64), Color("e6e2d6"), Color("f2efe6"))
	var fur: Color = [Color("c98a3a"), Color("6a8a9a"), Color("8a5a8a"), Color("5d8a3f")][variant % 4]
	Meshes.blob(st, Vector3(0, 0.66, 0), Vector3(0.16, 0.14, 0.14), fur, rng, 0.12)
	Meshes.blob(st, Vector3(0.1, 0.8, 0.06), Vector3(0.08, 0.08, 0.08), fur.lightened(0.08), rng, 0.08)
	Meshes.box(st, Vector3(0.12, 0.82, 0.13), Vector3(0.025, 0.025, 0.01), Color("1d1a18"))
	Meshes.box(st, Vector3(0.06, 0.82, 0.13), Vector3(0.025, 0.025, 0.01), Color("1d1a18"))
	for c in [Vector2(-0.28, -0.28), Vector2(0.26, -0.28), Vector2(0.26, 0.26), Vector2(-0.28, 0.26)]:
		Meshes.box(st, Vector3(c.x, 0.5, c.y), Vector3(0.02, 0.62, 0.02), BRASS)
	Meshes.box(st, Vector3(-0.3, 1.12, -0.3), Vector3(0.6, 0.03, 0.6), BRASS)
	Meshes.box(st, Vector3(-0.1, 0.2, 0.32), Vector3(0.2, 0.08, 0.01), BRASS)  # the plaque
	return Meshes._finish(st)

## A handloom for tweed: a heavy wooden frame, the warp running back from the weaver's bench, a length of flecked
## Donegal tweed rolled on the cloth beam at the front and the heddles hung from the top. Variant 1 has heather-
## coloured cloth, 0 a crotal brown.
static func loom(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var oak := WOOD.darkened(0.1)
	for p in [Vector2(-0.42, -0.36), Vector2(0.38, -0.36), Vector2(-0.42, 0.3), Vector2(0.38, 0.3)]:
		Meshes.box(st, Vector3(p.x, 0, p.y), Vector3(0.07, 1.15, 0.07), oak)
	Meshes.box(st, Vector3(-0.44, 1.12, -0.38), Vector3(0.9, 0.07, 0.75), oak.lightened(0.05))  # the castle over the top
	Meshes.box(st, Vector3(-0.42, 0.62, 0.28), Vector3(0.87, 0.08, 0.1), oak.lightened(0.1))    # breast beam
	Meshes.box(st, Vector3(-0.42, 0.5, -0.34), Vector3(0.87, 0.08, 0.08), oak)                   # warp beam at the back
	var cloth: Color = Color("8a5a3a") if variant % 2 == 0 else Color("6a5a7a")
	Meshes.box(st, Vector3(-0.36, 0.4, 0.22), Vector3(0.75, 0.2, 0.1), cloth)                    # the rolled cloth
	var flecks := [Color("e0b53a"), Color("2f7a55"), Color("b03a2e"), Color("f0ece0"), Color("2f5d8a")]
	for i in 10:
		Meshes.box(st, Vector3(-0.34 + i * 0.075, 0.45 + (i % 3) * 0.05, 0.315), Vector3(0.025, 0.025, 0.01), flecks[i % flecks.size()])
	for i in 9:
		var x := -0.34 + i * 0.085
		_bar(st, Vector3(x, 0.66, 0.26), Vector3(x, 0.56, -0.3), 0.006, Color("e8e0cc"))         # the warp threads
	Meshes.box(st, Vector3(-0.36, 0.72, -0.05), Vector3(0.75, 0.3, 0.03), Color("cfc5ae"))       # heddles
	Meshes.box(st, Vector3(-0.38, 0.98, -0.07), Vector3(0.79, 0.04, 0.07), oak)
	Meshes.box(st, Vector3(-0.3, 0, 0.38), Vector3(0.6, 0.38, 0.14), oak.darkened(0.1))          # the bench
	return Meshes._finish(st)

# --- the Palace, Aintree and the bookies ---------------------------------------------
# A casino floor and a betting ring: fruit machines that glow, the roulette wheel, the baize, a wall of race screens.

const BAIZE := Color("2f6a45")
const CHIPS := [Color("c8323a"), Color("2f5fb0"), Color("e8e2d4"), Color("2d3138"), Color("e0b83a")]
const SLOT_COLOURS := [Color("c8323a"), Color("2f5fb0"), Color("7a3fa0"), Color("d8902a")]

## A pub-style fruit machine against the wall: cabinet, a lit top box, three reels behind glass, the nudge buttons
## and the chrome handle. Variant: the cabinet's livery.
static func slot_machine(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var body: Color = SLOT_COLOURS[variant % SLOT_COLOURS.size()]
	var chrome := Color("c9ccd2")
	Meshes.box(st, Vector3(-0.34, 0, -0.42), Vector3(0.68, 0.62, 0.5), Color("1d1d22"))           # plinth
	Meshes.box(st, Vector3(-0.34, 0.62, -0.42), Vector3(0.68, 0.78, 0.42), body, body.darkened(0.3))
	Meshes.box(st, Vector3(-0.36, 0.58, -0.42), Vector3(0.72, 0.08, 0.56), chrome)                 # the button deck
	for k in 4:  # hold and nudge buttons
		Meshes.box(st, Vector3(-0.26 + k * 0.14, 0.66, 0.04), Vector3(0.08, 0.03, 0.06), Color("e04a3a") if k == 3 else Color("f0d040"))
	_panel(st, -0.27, 0.86, 0.27, 1.18, 0.005, Color("101015"))                                      # the reel window
	for r in 3:
		var x := -0.24 + r * 0.17
		_panel(st, x, 0.89, x + 0.14, 1.15, 0.008, Color("f4efe2"))
		Meshes.box(st, Vector3(x + 0.04, 0.99, 0.01), Vector3(0.06, 0.06, 0.01), CHIPS[(r + variant) % 3])  # a symbol
	_panel(st, -0.3, 1.24, 0.3, 1.34, 0.005, body.lightened(0.35))                                   # the win line
	Meshes.box(st, Vector3(-0.36, 1.4, -0.44), Vector3(0.72, 0.36, 0.46), Color("1d1d22"))           # top box
	_panel(st, -0.32, 1.44, 0.32, 1.72, 0.025, body.lightened(0.2))
	Meshes.box(st, Vector3(0.34, 0.95, -0.12), Vector3(0.04, 0.06, 0.06), chrome)                    # the handle
	_bar(st, Vector3(0.39, 0.98, -0.09), Vector3(0.41, 1.32, -0.09), 0.014, chrome)
	Meshes.blob(st, Vector3(0.41, 1.36, -0.09), Vector3(0.045, 0.045, 0.045), Color("c8323a"), Meshes._rng(5), 0.02)
	return Meshes._finish(st)

## The fruit machine's lights: the top box, the win line and a coloured spill on the carpet.
static func slot_glow(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var col: Color = SLOT_COLOURS[variant % SLOT_COLOURS.size()].lightened(0.45)
	_panel(st, -0.3, 1.46, 0.3, 1.7, 0.03, Color(col.r, col.g, col.b, 0.8))
	_panel(st, -0.28, 1.25, 0.28, 1.33, 0.01, Color(1.0, 0.9, 0.55, 0.7))
	_glow_pool(st, Vector3(0, 0.02, 0.35), 0.55, 0.45, col, 0.35)
	return Meshes._finish(st)

## Half of a roulette table, two tiles long east-west. 0: the wheel end (a turned bowl of red and black pockets,
## one green, and a gilt spindle). 1: the layout end (the numbers in their red and black, the zero at the top).
static func roulette_table(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var wood := Color("5a3424")
	var left := variant % 2 == 0
	var x0 := -0.42 if left else -0.5
	var x1 := 0.5 if left else 0.42
	var px := x0 + 0.06 if left else x1 - 0.13
	for pz in [-0.32, 0.24]:
		Meshes.box(st, Vector3(px, 0, pz), Vector3(0.07, 0.72, 0.07), wood)
	Meshes.box(st, Vector3(x0, 0.68, -0.42), Vector3(x1 - x0, 0.08, 0.84), wood, wood.lightened(0.15))  # the rail
	Meshes.box(st, Vector3(x0 + 0.05, 0.7, -0.37), Vector3(x1 - x0 - 0.1, 0.07, 0.74), BAIZE, BAIZE)
	if left:
		var c := Vector3(-0.02, 0.77, 0.0)
		Meshes.cylinder(st, c, 0.36, 0.08, 16, wood.lightened(0.1))
		var n := 18
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var col := Color("1a8a3a") if i == 0 else (Color("b8262c") if i % 2 == 1 else Color("1d1d22"))
			var am := (a0 + a1) * 0.5
			Meshes._tri(st, c + Vector3(cos(a0) * 0.29, 0.07, sin(a0) * 0.29),
				Vector3(c.x + cos(am) * 0.16, c.y + 0.07, c.z + sin(am) * 0.16),
				c + Vector3(cos(a1) * 0.29, 0.07, sin(a1) * 0.29), col)
		Meshes.cylinder(st, c + Vector3(0, 0.07, 0), 0.16, 0.03, 12, Color("8a6a3a"))
		Meshes.cylinder(st, c + Vector3(0, 0.1, 0), 0.04, 0.1, 6, BRASS)
		Meshes.box(st, c + Vector3(-0.1, 0.19, -0.01), Vector3(0.2, 0.02, 0.02), BRASS)
		Meshes.box(st, c + Vector3(0.2, 0.08, 0.12), Vector3(0.03, 0.03, 0.03), Color("f4efe2"))  # the ball
	else:
		var y := 0.775
		Meshes.box(st, Vector3(-0.44, y, -0.3), Vector3(0.1, 0.004, 0.36), Color("1a8a3a"))
		for i in 9:
			for j in 3:
				var red := (i + j) % 2 == 0
				Meshes.box(st, Vector3(-0.32 + i * 0.075, y, -0.3 + j * 0.12), Vector3(0.068, 0.004, 0.11), Color("b8262c") if red else Color("1d1d22"))
		for k in 3:  # the dozens along the front
			Meshes.box(st, Vector3(-0.32 + k * 0.225, y, 0.07), Vector3(0.215, 0.004, 0.08), Color("e8e2d4").darkened(0.25))
		for k in 4:  # a few stacks of chips
			Meshes.cylinder(st, Vector3(-0.25 + k * 0.17, y, 0.24), 0.035, 0.03 + 0.02 * (k % 3), 8, CHIPS[k])
	return Meshes._finish(st)

## A card table. 0 and 1: the left and right halves of a blackjack table (a half-moon of baize with a padded rim,
## the dealer's shoe and chip float, cards dealt to the boxes). 2: a small round table with a big card on a stand,
## for Higher or Lower.
static func card_table(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var wood := Color("5a3424")
	var pad := Color("3a2a22")
	var card := Color("f6f2e6")
	if variant % 3 == 2:
		Meshes.cylinder(st, Vector3(0, 0, 0), 0.08, 0.68, 8, wood)
		Meshes.cylinder(st, Vector3(0, 0.66, 0), 0.4, 0.06, 14, pad)
		Meshes.cylinder(st, Vector3(0, 0.71, 0), 0.34, 0.02, 14, BAIZE)
		Meshes.box(st, Vector3(-0.16, 0.73, -0.14), Vector3(0.32, 0.02, 0.06), BRASS)
		Meshes.box(st, Vector3(-0.15, 0.75, -0.13), Vector3(0.3, 0.42, 0.02), card)                    # the big card
		Meshes.box(st, Vector3(-0.07, 0.88, -0.105), Vector3(0.14, 0.16, 0.01), Color("b8262c"))       # its pip
		Meshes.box(st, Vector3(-0.12, 1.08, -0.105), Vector3(0.05, 0.05, 0.01), Color("b8262c"))
		Meshes.box(st, Vector3(0.05, 0.73, 0.02), Vector3(0.12, 0.012, 0.17), Color("2f4a8a"))        # the next one, face down
		Meshes.cylinder(st, Vector3(-0.18, 0.73, 0.12), 0.035, 0.06, 8, CHIPS[4])
		return Meshes._finish(st)
	var right := variant % 3 == 1
	var sgn := 1.0 if right else -1.0
	for pz in [-0.3, 0.12]:
		Meshes.box(st, Vector3(sgn * 0.3 - 0.035, 0, pz), Vector3(0.07, 0.72, 0.07), wood)
	# the table: a slab on the dealer's side (north), stepping round in a curve to the players' side
	var x0 := -0.5 if right else -0.44
	Meshes.box(st, Vector3(x0, 0.68, -0.38), Vector3(0.94, 0.07, 0.5), pad)
	Meshes.box(st, Vector3(x0 + (0.0 if right else 0.04), 0.7, -0.36), Vector3(0.9, 0.06, 0.46), BAIZE, BAIZE)
	for k in 4:
		var w := 0.9 - k * 0.2
		var x := -0.5 if right else 0.5 - w
		Meshes.box(st, Vector3(x, 0.68, 0.12 + k * 0.07), Vector3(w, 0.07, 0.07), pad)
		Meshes.box(st, Vector3(x + (0.0 if right else 0.03), 0.7, 0.1 + k * 0.07), Vector3(w - 0.03, 0.065, 0.05), BAIZE, BAIZE)
	for k in 2:  # cards dealt to a box or two
		var cx := sgn * (0.06 + k * 0.22)
		Meshes.box(st, Vector3(cx - 0.05, 0.77, 0.0 + k * 0.06), Vector3(0.1, 0.008, 0.14), card)
		Meshes.box(st, Vector3(cx - 0.02, 0.779, 0.03 + k * 0.06), Vector3(0.04, 0.004, 0.04), Color("b8262c") if k == 0 else Color("1d1d22"))
	if right:  # the shoe
		Meshes.box(st, Vector3(0.18, 0.76, -0.32), Vector3(0.18, 0.12, 0.2), Color("1d1d22"))
		Meshes.box(st, Vector3(0.2, 0.8, -0.13), Vector3(0.14, 0.04, 0.02), Color("2f4a8a"))
	else:  # the chip float, in neat columns
		for k in 5:
			Meshes.cylinder(st, Vector3(-0.3 + k * 0.08, 0.76, -0.26), 0.032, 0.05 + 0.02 * (k % 2), 8, CHIPS[k])
	return Meshes._finish(st)

## A bank of race screens on the north wall over an odds board in amber lights.
static func tote_board(_variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var frame := Color("1a1c22")
	Meshes.box(st, Vector3(-0.5, 0.5, -0.5), Vector3(1.0, 1.42, 0.08), frame)
	_panel(st, -0.46, 0.56, 0.46, 0.8, -0.415, Color("120f0a"))  # the odds board
	for i in 2:
		var x := -0.46 + i * 0.47
		_panel(st, x, 0.88, x + 0.45, 1.86, -0.418, Color("0e1014"))
	Meshes.box(st, Vector3(-0.5, 1.92, -0.5), Vector3(1.0, 0.06, 0.12), Color("2f6a45"))  # a green pelmet
	return Meshes._finish(st)

## What's on the screens, lit: turf, a white rail, runners in their silks, and the odds in amber.
static func tote_glow(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(42400 + variant)
	for i in 2:
		var x := -0.44 + i * 0.47
		var z := -0.405
		_panel(st, x, 0.9, x + 0.41, 1.3, z, Color(0.35, 0.65, 0.35, 0.85))    # turf
		_panel(st, x, 1.3, x + 0.41, 1.84, z, Color(0.55, 0.7, 0.9, 0.7))      # sky
		_panel(st, x, 1.24, x + 0.41, 1.26, z + 0.002, Color(1, 1, 1, 0.9))    # the running rail
		for k in 4:
			var rx := x + 0.04 + rng.randf() * 0.33
			var ry := 0.96 + rng.randf() * 0.22
			var silk: Color = CLOTH[rng.randi() % CLOTH.size()]
			_panel(st, rx, ry, rx + 0.04, ry + 0.04, z + 0.004, Color(silk.r, silk.g, silk.b, 1.0))
	for k in 8:  # the odds, in dot-matrix amber
		var w := 0.03 + rng.randf() * 0.06
		var ox := -0.42 + k * 0.105
		_panel(st, ox, 0.6 + (k % 2) * 0.1, ox + w, 0.64 + (k % 2) * 0.1, -0.41, Color(1.0, 0.62, 0.15, 0.9))
	return Meshes._finish(st)

## Two brass posts and a sagging rope between them, across the tile east-west. Variant: red or royal blue.
static func velvet_rope(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rope := Color("8a1f2c") if variant % 2 == 0 else Color("2a3a6a")
	for px in [-0.4, 0.4]:
		Meshes.cylinder(st, Vector3(px, 0, 0), 0.1, 0.04, 10, BRASS.darkened(0.2))
		Meshes.cylinder(st, Vector3(px, 0.04, 0), 0.025, 0.72, 6, BRASS)
		Meshes.blob(st, Vector3(px, 0.8, 0), Vector3(0.045, 0.045, 0.045), BRASS.lightened(0.2), Meshes._rng(7), 0.02)
	var prev := Vector3(-0.4, 0.72, 0)
	for k in range(1, 7):
		var t := float(k) / 6.0
		var p := Vector3(-0.4 + 0.8 * t, 0.72 - sin(t * PI) * 0.16, 0)
		_bar(st, prev, p, 0.022, rope)
		prev = p
	return Meshes._finish(st)

## A bronze racehorse on a stone plinth, mid-stride, head up: Aintree's statue of Red Rum, more or less.
static func horse_statue(_variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(42500)
	var bronze := Color("6a5038")
	var stone := Color("c9c0aa")
	Meshes.box(st, Vector3(-0.42, 0, -0.3), Vector3(0.84, 0.42, 0.6), stone, stone.lightened(0.08))
	Meshes.box(st, Vector3(-0.46, 0.42, -0.34), Vector3(0.92, 0.05, 0.68), stone.lightened(0.1))
	Meshes.box(st, Vector3(-0.16, 0.16, 0.301), Vector3(0.32, 0.14, 0.01), BRASS)  # the name plate
	var y := 0.47
	Meshes.blob(st, Vector3(0, y + 0.54, 0), Vector3(0.32, 0.17, 0.14), bronze, rng, 0.03)         # body
	Meshes.blob(st, Vector3(0.2, y + 0.53, 0), Vector3(0.14, 0.16, 0.13), bronze.lightened(0.05), rng, 0.03)  # chest
	Meshes.blob(st, Vector3(-0.22, y + 0.55, 0), Vector3(0.13, 0.15, 0.13), bronze.darkened(0.05), rng, 0.03)  # quarters
	_bar(st, Vector3(0.24, y + 0.6, 0), Vector3(0.36, y + 0.86, 0), 0.075, bronze)                 # neck
	Meshes.blob(st, Vector3(0.4, y + 0.84, 0), Vector3(0.11, 0.05, 0.05), bronze, rng, 0.03)       # head
	_bar(st, Vector3(0.3, y + 0.86, 0.02), Vector3(0.3, y + 0.94, 0.03), 0.012, bronze)           # ears
	_bar(st, Vector3(0.3, y + 0.86, -0.02), Vector3(0.3, y + 0.94, -0.03), 0.012, bronze)
	for leg in [[0.2, 0.05, 0.12], [0.16, -0.05, -0.08], [-0.2, 0.05, -0.1], [-0.22, -0.05, 0.12]]:
		var top := Vector3(float(leg[0]), y + 0.44, float(leg[1]))
		var foot := Vector3(float(leg[0]) + float(leg[2]), y, float(leg[1]))
		_bar(st, top, foot, 0.035, bronze.darkened(0.1))
	_bar(st, Vector3(-0.28, y + 0.56, 0), Vector3(-0.38, y + 0.36, 0), 0.03, bronze.darkened(0.15))  # tail
	return Meshes._finish(st)
