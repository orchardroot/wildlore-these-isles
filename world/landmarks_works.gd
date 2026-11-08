class_name WorksStyles
extends RefCounted
## Small working buildings: an allotment shed, a tarred boat hut, a stone tower windmill (Llynnon), a waterwheel on
## its stone case (Laxey), Brunel's pumping house at Starcross and a Cornish engine house with its round stack.
## Called from Landmarks.building (see the "allotment_shed" arm there). Same rules as Landmarks: vertex colour, low
## poly, origin at the footprint's north-west corner, door on the south.

const STYLES := ["allotment_shed", "net_hut", "tower_mill", "water_wheel", "pumping_house", "cornish_engine"]
const TIMBER := Color("6b4a32")     # creosoted shed boards
const TAR := Color("2b2826")        # tarred boards
const FELT := Color("3d3f42")       # roofing felt
const PANTILE := Color("b4532e")
const RED_SANDSTONE := Color("a4553f")
const GRANITE := Color("8f8a80")

static func build(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, style: String) -> void:
	match style:
		"allotment_shed":
			_shed(st, wst, w, d, door_x, rng, false)
		"net_hut":
			_shed(st, wst, w, d, door_x, rng, true)
		"tower_mill":
			_tower_mill(st, w, d, door_x)
		"water_wheel":
			_water_wheel(st, w, d, door_x)
		"pumping_house":
			_pumping_house(st, wst, w, d, door_x)
		"cornish_engine":
			_cornish_engine(st, wst, w, d, door_x)

## A plot-holder's shed (creosoted boards, a felt roof, a green door, a water butt) or a fisher's hut (tarred black
## boards, red pantiles, an oar and a coil of rope by the door). One storey, a little over head height.
static func _shed(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, hut: bool) -> void:
	var wall := TAR if hut else TIMBER
	var h := 1.25
	Meshes.box(st, Vector3(0.1, 0, 0.2), Vector3(w - 0.2, h, d - 0.3), wall)
	var y := 0.18
	while y < h:  # the boards
		Meshes.box(st, Vector3(0.1, y, d - 0.12), Vector3(w - 0.2, 0.03, 0.03), wall.darkened(0.3) if not hut else wall.lightened(0.12))
		y += 0.2
	_roof(st, w, d, h, PANTILE if hut else FELT, wall)
	var dx := door_x if door_x >= 0 else w / 2
	Meshes.box(st, Vector3(dx + 0.22, 0.0, d - 0.12), Vector3(0.56, 0.95, 0.06), Color("2f5d3a") if not hut else Color("6e2a22"))
	for x in w:
		if x != dx:
			Landmarks._window(st, wst, x + 0.3, 0.55, d - 0.06, 0.4, 0.35, Color("d8d2c2"))
			break
	if hut:
		Meshes.box(st, Vector3(dx + 0.85, 0.0, d - 0.02), Vector3(0.06, 1.2, 0.06), Color("c9b48a"))  # an oar
		Meshes.cylinder(st, Vector3(dx - 0.2 if dx > 0 else dx + 1.3, 0.0, d + 0.1), 0.2, 0.12, 8, Color("b39a6a"))  # rope
	else:
		Meshes.cylinder(st, Vector3(w - 0.25, 0.0, d - 0.05), 0.2, 0.6, 8, Color("2e4a36"))  # the water butt
		Meshes.box(st, Vector3(0.15, 0.0, d - 0.05), Vector3(0.3, 0.25, 0.3), Color("8a5a3a").lightened(rng.randf_range(0.0, 0.1)))  # a seed tray

## A pitched roof over a shed whose walls sit in from the plot's edges.
static func _roof(st: SurfaceTool, w: int, d: int, h: float, roof: Color, wall: Color) -> void:
	Landmarks._roof_at(st, -0.02, w + 0.02, 0.08, d - 0.0, h, 0.45, roof, wall)

## A stone tower windmill (Melin Llynnon, 1776): a tapering round tower, a dark boat-shaped cap and four sails to
## the south, the door at the foot of the tower.
static func _tower_mill(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var r := minf(1.4, minf(w, d) * 0.4)
	var cx := clampf(door_x + 0.5 if door_x >= 0 else w * 0.5, r, w - r)
	var c := Vector3(cx, 0, d - r - 0.04)
	var stone := Color("d6d0c2")
	Meshes.cylinder(st, c, r, 3.3, 12, stone)
	var top := r * 0.85
	Meshes.box(st, c + Vector3(-top - 0.05, 3.25, -top - 0.05), Vector3(top * 2 + 0.1, 0.12, top * 2 + 0.1), Color("6a6460"))  # the curb
	var cap := Color("2e2b2a")
	Meshes.box(st, c + Vector3(-top * 0.8, 3.37, -top), Vector3(top * 1.6, 0.4, top * 2.0), cap)
	Meshes.box(st, c + Vector3(-top * 0.5, 3.77, -top * 0.9), Vector3(top, 0.22, top * 1.8), cap.lightened(0.08))
	Meshes.box(st, c + Vector3(-0.05, 1.8, -r - 0.6), Vector3(0.1, 0.1, 0.8), Color("4a3a2e"))  # the tail pole, north
	var hub := c + Vector3(0, 3.6, top + 0.12)
	Meshes.box(st, hub + Vector3(-0.12, -0.12, 0), Vector3(0.24, 0.24, 0.2), Color("3a3430"))
	var sail := Color("e8e2d2")
	var frame := Color("5a4a3a")
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * k
		var dir := Vector3(cos(a), sin(a), 0)
		var side := Vector3(-sin(a), cos(a), 0) * 0.22
		var p0 := hub + dir * 0.3 + Vector3(0, 0, 0.2)
		var p1 := hub + dir * 2.0 + Vector3(0, 0, 0.2)
		Meshes._quad(st, p0 - side, p1 - side, p1 + side, p0 + side, sail)
		Meshes._quad(st, p0 + side, p1 + side, p1 - side, p0 - side, sail.darkened(0.2))
		Meshes._quad(st, hub - side * 0.2 + Vector3(0, 0, 0.21), hub + dir * 2.05 - side * 0.2 + Vector3(0, 0, 0.21), hub + dir * 2.05 + side * 0.2 + Vector3(0, 0, 0.21), hub + side * 0.2 + Vector3(0, 0, 0.21), frame)
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.24, 0.0, d - 0.1), Vector3(0.52, 1.0, 0.08), Color("3b2a22"))
		Meshes.box(st, Vector3(door_x + 0.18, 1.0, d - 0.12), Vector3(0.64, 0.08, 0.1), stone.lightened(0.15))
	for y in [1.6, 2.5]:  # small windows up the tower
		Meshes.box(st, c + Vector3(-0.15, y, r * (1.0 - y / 3.3 * 0.15) - 0.02), Vector3(0.3, 0.38, 0.06), Color("23201e"))

## The Laxey Wheel (Lady Isabella, 1854): a big red wheel with white spokes turning against a white stone wheel case,
## a tall pier at one side with the stair to its gallery. Not to scale: the real one is 22 m across.
static func _water_wheel(st: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var white := Color("ece8de")
	var red := Color("b23a2e")
	var pier_x := w - 1.2
	var base_h := 1.3
	# the stone case: a low block across the front (the door is in it) and the tall pier at the east end
	Meshes.box(st, Vector3(0.0, 0, d - 1.4), Vector3(w, base_h, 1.35), white, white.darkened(0.08))
	Meshes.box(st, Vector3(pier_x, 0, 0.3), Vector3(1.15, 4.4, d - 1.6), white, white.darkened(0.05))
	Meshes.box(st, Vector3(pier_x - 0.08, 4.4, 0.22), Vector3(1.31, 0.12, d - 1.44), Color("2a2a2a"))  # the gallery
	for i in 4:  # the gallery rail
		Meshes.box(st, Vector3(pier_x - 0.05 + i * 0.4, 4.52, 0.25), Vector3(0.05, 0.35, 0.05), Color("2a2a2a"))
	Meshes.box(st, Vector3(pier_x - 0.05, 4.84, 0.25), Vector3(1.25, 0.05, 0.05), Color("2a2a2a"))
	# the wheel: a red rim of short boxes, white spokes, a hub on the axle into the pier
	var c := Vector3(pier_x * 0.5, 2.15, 1.25)
	var rad := minf(1.95, pier_x * 0.5 + 0.35)
	var n := 20
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var o := Vector3(cos(a0), sin(a0), 0)
		var p := Vector3(cos(a1), sin(a1), 0)
		var inner := rad - 0.22
		var f := Vector3(0, 0, 0.22)
		_both(st, c + o * inner + f, c + p * inner + f, c + p * rad + f, c + o * rad + f, red)
		_both(st, c + o * rad - f, c + p * rad - f, c + p * inner - f, c + o * inner - f, red.darkened(0.2))
		_both(st, c + o * rad + f, c + p * rad + f, c + p * rad - f, c + o * rad - f, red.darkened(0.1))
		if i % 2 == 0:  # buckets round the rim
			Meshes.box(st, c + o * (rad + 0.02) - Vector3(0.06, 0.06, 0.2), Vector3(0.12, 0.12, 0.4), red.darkened(0.35))
	for k in 8:
		var a := TAU * k / 8.0
		var dir := Vector3(cos(a), sin(a), 0)
		var side := Vector3(-sin(a), cos(a), 0) * 0.05
		var z := Vector3(0, 0, 0.12)
		_both(st, c - side + z, c + dir * (rad - 0.2) - side + z, c + dir * (rad - 0.2) + side + z, c + side + z, white)
	Meshes.box(st, c + Vector3(-0.18, -0.18, -0.2), Vector3(0.36, 0.36, 0.45), Color("3a3430"))
	Meshes.box(st, Vector3(c.x, c.y - 0.06, c.z - 0.05), Vector3(pier_x - c.x, 0.12, 0.12), Color("3a3430"))  # the axle
	if door_x >= 0:
		Meshes.box(st, Vector3(door_x + 0.22, 0.0, d - 0.07), Vector3(0.56, 0.95, 0.06), Color("3b2a22"))
		Meshes.box(st, Vector3(door_x + 0.15, 0.95, d - 0.08), Vector3(0.7, 0.08, 0.08), Color("9a958a"))
	Meshes.box(st, Vector3(-0.02, base_h, d - 1.42), Vector3(w + 0.04, 0.1, 1.39), Color("9a958a"))  # coping

## A quad seen from either side (the wheel's rim and spokes are thin plates).
static func _both(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	Meshes._quad(st, a, b, c, d, col)
	Meshes._quad(st, d, c, b, a, col.darkened(0.1))

## Starcross (1846): the pumping house of Brunel's atmospheric railway, in red sandstone with round-headed windows,
## and its square Italianate chimney tower at the east end.
static func _pumping_house(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var tw := 1.0
	var bw := w - tw - 0.1
	var h := 2.1
	Meshes.box(st, Vector3(0.05, 0, 0.1), Vector3(bw, h, d - 0.15), RED_SANDSTONE, RED_SANDSTONE.darkened(0.2))
	Landmarks._roof_at(st, -0.1, bw + 0.2, 0.0, d + 0.05, h, 0.5, Color("4d5563"), RED_SANDSTONE)
	Meshes.box(st, Vector3(0.0, 0, d - 0.1), Vector3(bw + 0.1, 0.2, 0.08), RED_SANDSTONE.darkened(0.3))
	for i in int(bw / 0.8):
		var x := 0.3 + i * 0.8
		if door_x >= 0 and absf(x + 0.2 - (door_x + 0.5)) < 0.5:
			continue
		Landmarks._window(st, wst, x, 0.6, d - 0.04, 0.4, 0.9, Color("c9a07e"))
		Meshes.box(st, Vector3(x - 0.04, 1.5, d - 0.11), Vector3(0.48, 0.12, 0.06), Color("c9a07e"))  # the round head, squared off
	# the tower: square, with a band and a bracketed cornice near the top
	var tx := w - tw
	Meshes.box(st, Vector3(tx, 0, 0.6), Vector3(tw, 4.6, tw), RED_SANDSTONE.lightened(0.04), RED_SANDSTONE.darkened(0.25))
	Meshes.box(st, Vector3(tx - 0.06, 2.2, 0.54), Vector3(tw + 0.12, 0.12, tw + 0.12), Color("c9a07e"))
	Meshes.box(st, Vector3(tx - 0.1, 4.45, 0.5), Vector3(tw + 0.2, 0.2, tw + 0.2), Color("c9a07e"))
	for y in [2.9, 3.6]:
		Meshes.box(st, Vector3(tx + 0.35, y, 0.6 + tw - 0.02), Vector3(0.3, 0.5, 0.05), Color("23201e"))
	if door_x >= 0:
		Landmarks._door(st, door_x, d + 0.03, RED_SANDSTONE, 1.1)

## A Cornish engine house: a tall, narrow granite house that held the beam engine, its gable ends standing, the
## thick "bob wall" to the front with a high arch, and a round stack at one corner, brick at the top.
static func _cornish_engine(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var ew := minf(2.4, w - 1.0)
	var ex := clampf((door_x + 0.5 if door_x >= 0 else w * 0.5) - ew * 0.5, 0.0, w - ew - 0.9)
	var h := 3.4
	Meshes.box(st, Vector3(ex, 0, 0.3), Vector3(ew, h, d - 0.35), GRANITE, GRANITE.darkened(0.2))
	# the gable ends, roofless between them
	var g := 0.8
	for z in [0.3, d - 0.2]:
		Meshes._tri(st, Vector3(ex, h, z + 0.15), Vector3(ex + ew, h, z + 0.15), Vector3(ex + ew * 0.5, h + g, z + 0.15), GRANITE.darkened(0.04))
		Meshes._tri(st, Vector3(ex + ew, h, z - 0.0), Vector3(ex, h, z - 0.0), Vector3(ex + ew * 0.5, h + g, z - 0.0), GRANITE.darkened(0.1))
	# brick dressings round the openings, a big arched opening up high where the beam came out
	Meshes.box(st, Vector3(ex + ew * 0.5 - 0.35, 2.2, d - 0.08), Vector3(0.7, 0.9, 0.06), Color("1e1b1a"))
	Meshes.box(st, Vector3(ex + ew * 0.5 - 0.42, 3.1, d - 0.09), Vector3(0.84, 0.12, 0.08), Color("8a4b3b"))
	for x in [ex + 0.25, ex + ew - 0.65]:
		Meshes.box(st, Vector3(x, 1.0, d - 0.08), Vector3(0.4, 0.7, 0.06), Color("1e1b1a"))
		Meshes.box(st, Vector3(x - 0.05, 1.7, d - 0.09), Vector3(0.5, 0.1, 0.08), Color("8a4b3b"))
	# the stack: round, granite below and brick above, at the back corner
	var sc := Vector3(ex + ew + 0.45, 0, 0.75)
	Meshes.cylinder(st, sc, 0.42, 3.6, 10, GRANITE.darkened(0.05))
	Meshes.cylinder(st, sc + Vector3(0, 3.6, 0), 0.36, 1.9, 10, Color("8a4b3b"))
	Meshes.cylinder(st, sc + Vector3(0, 5.5, 0), 0.34, 0.12, 10, Color("6a3a2e"))
	if door_x >= 0:
		Landmarks._door(st, door_x, d + 0.04, GRANITE, 1.0)
