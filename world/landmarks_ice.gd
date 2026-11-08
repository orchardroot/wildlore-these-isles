class_name IceStyles
extends RefCounted
## The far south (South Georgia, the British Antarctic Territory): rusting whaling-station sheds and oil tanks,
## a white Norwegian church, timber polar huts, steel research stations and Halley's modules on legs; plus the
## wildlife and kit that stand about outside them. Called from Landmarks.building and ZoneBuilder (see "whaling_shed"
## and ICE_PROPS there). Same rules as Landmarks: vertex colour, low poly, origin at the footprint's north-west
## corner, door on the south.

const STYLES := ["whaling_shed", "whaling_tanks", "whalers_church", "whaler_villa", "polar_hut", "research_station", "halley_module", "hangar"]
const PROPS := ["penguin", "seal", "iceberg", "tussac", "skidoo", "headstone", "catcher_hulk", "twin_otter"]
const RUST := Color("8a4a34")
const IRON := Color("a9a69f")
const WHITE_BOARD := Color("e8e4da")
const HUT_ROOF := Color("9b3f33")

static func build(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator, style: String) -> void:
	match style:
		"whaling_shed":
			_shed(st, wst, w, d, door_x, rng)
		"whaling_tanks":
			_tanks(st, w, d, rng)
		"whalers_church":
			_church(st, wst, w, d, door_x)
		"whaler_villa":
			Landmarks._house(st, wst, w, d, door_x, rng, WHITE_BOARD, Color("6a3a30"), 2, false, false)
			Meshes.box(st, Vector3(0.0, 0.16, d - 0.02), Vector3(w, 0.1, 0.18), WHITE_BOARD.darkened(0.25))  # the veranda boards
		"polar_hut":
			Landmarks._house(st, wst, w, d, door_x, rng, Color("d9d2bf"), HUT_ROOF, 1, false, false)
			Meshes.box(st, Vector3(0.0, 0.0, 0.0), Vector3(w, 0.22, d), Color("5a4a40"))  # raised on a timber plinth
		"research_station":
			_station(st, wst, w, d, door_x)
		"halley_module":
			_module(st, wst, w, d, door_x)
		"hangar":
			_hangar(st, wst, w, d, door_x)

## A long shed of corrugated iron gone the colour of an old tin: rust walls, paler roof, a high ridge, and a tall
## iron stack at the back (the whale-oil factory at Grytviken, now a museum piece).
static func _shed(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int, rng: RandomNumberGenerator) -> void:
	var h := 1.9
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), RUST)
	for i in range(1, w * 3):  # corrugation: thin vertical ribs on the south face
		Meshes.box(st, Vector3(i / 3.0, 0.15, d - 0.06), Vector3(0.05, h - 0.2, 0.04), RUST.darkened(0.18))
	Landmarks._roof(st, w, d, h, IRON.darkened(0.1), RUST, 0.3)
	Meshes.box(st, Vector3(w * 0.7, h, d * 0.3), Vector3(0.45, 2.6, 0.45), RUST.darkened(0.3))
	Meshes.box(st, Vector3(w * 0.7 - 0.05, h + 2.6, d * 0.3 - 0.05), Vector3(0.55, 0.14, 0.55), Color("2a2624"))
	Landmarks._chimneys.append(Vector3(w * 0.7 + 0.22, h + 2.7, d * 0.3 + 0.22))
	Landmarks._door(st, door_x, d, RUST, 1.2)
	for x in w:
		if x != door_x:
			Landmarks._window(st, wst, x + 0.3, 0.9, d, 0.4, 0.5, RUST.darkened(0.35))

## A row of cylindrical oil tanks on a low stone footing, rust-streaked, with a catwalk and ladder.
static func _tanks(st: SurfaceTool, w: int, d: int, rng: RandomNumberGenerator) -> void:
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.18, d), Color("6a665f"))
	var n := maxi(1, w / 2)
	var r := minf(d * 0.42, w / float(n) * 0.46)
	for i in n:
		var c := Vector3((i + 0.5) * w / float(n), 0.18, d * 0.5)
		Meshes.cylinder(st, c, r, 2.4, 9, RUST.lightened(rng.randf_range(-0.06, 0.06)))
		Meshes.cylinder(st, c + Vector3(0, 2.4, 0), r * 0.84, 0.25, 9, RUST.darkened(0.25))
		Meshes.box(st, Vector3(c.x + r * 0.55, 0.18, c.z - 0.04), Vector3(0.06, 2.4, 0.06), Color("3a3430"))  # a ladder rail
	Meshes.box(st, Vector3(0.2, 2.5, d * 0.5 - 0.06), Vector3(w - 0.4, 0.06, 0.12), Color("3a3430"))

## The Norwegian Lutheran church (1913): a plain white board nave, a dark steep roof, and a little square belfry
## with a spire on the front gable.
static func _church(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var wall := WHITE_BOARD.lightened(0.04)
	var roof := Color("4a4f58")
	var h := 1.9
	Meshes.box(st, Vector3(0.05, 0, 0.3), Vector3(w - 0.1, h, d - 0.4), wall)
	Meshes.box(st, Vector3(0, 0, 0.25), Vector3(w, 0.16, d - 0.3), wall.darkened(0.3))
	Landmarks._roof_at(st, -0.1, w + 0.1, 0.25, d + 0.1, h, 1.4, roof, wall)
	for x in range(0, w):
		if x != door_x:
			Landmarks._window(st, wst, x + 0.3, 0.7, d, 0.34, 0.9, wall.darkened(0.25))
	# the tower over the door, boarded white from the ground up, with louvred belfry openings and a tall dark spire
	var tw := 1.2
	var bx := clampf((door_x + 0.5 if door_x >= 0 else w * 0.5) - tw * 0.5, 0.0, w - tw)
	var th := h + 1.5
	Meshes.box(st, Vector3(bx, 0, d - 1.15), Vector3(tw, th, 1.1), wall)
	Meshes.box(st, Vector3(bx + 0.35, th - 0.75, d - 0.07), Vector3(0.5, 0.5, 0.04), roof.darkened(0.25))
	Meshes.box(st, Vector3(bx - 0.06, th, d - 1.21), Vector3(tw + 0.12, 0.12, 1.22), roof)
	Meshes.cone(st, Vector3(bx + tw * 0.5, th + 0.1, d - 0.6), 0.72, 2.4, 8, roof, Meshes._rng(7))
	Meshes.box(st, Vector3(bx + tw * 0.5 - 0.03, th + 2.45, d - 0.63), Vector3(0.06, 0.35, 0.06), Color("c9a24a"))  # the finial
	Landmarks._door(st, door_x, d, wall, 1.1)

## A modern station on piles, clad in orange and grey panels with a band of windows, a flat roof and a wind mast.
static func _station(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var clad := Color("c9582d")
	var grey := Color("8d939c")
	Meshes.box(st, Vector3(0.1, 0, 0.1), Vector3(0.2, 0.5, 0.2), grey.darkened(0.3))
	Meshes.box(st, Vector3(w - 0.3, 0, 0.1), Vector3(0.2, 0.5, 0.2), grey.darkened(0.3))
	Meshes.box(st, Vector3(0.1, 0, d - 0.3), Vector3(0.2, 0.5, 0.2), grey.darkened(0.3))
	Meshes.box(st, Vector3(w - 0.3, 0, d - 0.3), Vector3(0.2, 0.5, 0.2), grey.darkened(0.3))
	Meshes.box(st, Vector3(0.0, 0.5, 0.0), Vector3(w, 1.9, d), clad, clad.lightened(0.08))
	Meshes.box(st, Vector3(0.0, 0.5, d - 0.02), Vector3(w, 0.5, 0.06), grey)
	Meshes.box(st, Vector3(0.0, 2.2, d - 0.02), Vector3(w, 0.2, 0.06), grey)
	for x in w:
		if x != door_x:
			Landmarks._window(st, wst, x + 0.2, 1.3, d + 0.02, 0.6, 0.55, grey.darkened(0.2))
	Meshes.box(st, Vector3(door_x + 0.2, 0.0, d - 0.9), Vector3(0.6, 0.5, 0.9), Color("6a665f"))  # steps up to the door
	Landmarks._door(st, door_x, d + 0.02, grey, 1.2)
	Meshes.box(st, Vector3(w - 0.6, 2.4, 0.5), Vector3(0.07, 1.8, 0.07), Color("d8d8dc"))  # wind mast
	Meshes.box(st, Vector3(w - 0.9, 4.0, 0.46), Vector3(0.6, 0.06, 0.06), Color("d8d8dc"))

## One of Halley VI's modules: a bright cladded box lifted high on legs with ski feet, so the snow can drift under it
## and the whole station can be hauled away from a calving ice shelf. Blue sleeping modules; a taller red hub.
static func _module(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var blue := Color("3f74b8")
	var red := Color("c8402c")
	var col := red if w >= 5 else blue
	for lx in [0.3, w - 0.5]:
		for lz in [0.4, d - 0.6]:
			Meshes.box(st, Vector3(lx, 0.1, lz), Vector3(0.18, 1.0, 0.18), Color("6a707a"))
			Meshes.box(st, Vector3(lx - 0.18, 0.0, lz - 0.2), Vector3(0.54, 0.1, 0.6), Color("2c2e34"))  # a ski
	Meshes.box(st, Vector3(0.0, 1.1, 0.0), Vector3(w, 1.5, d), col, col.lightened(0.1))
	Meshes.box(st, Vector3(0.0, 2.15, 0.0), Vector3(w, 0.1, d), col.darkened(0.3))
	for x in w:
		if x != door_x:
			Landmarks._window(st, wst, x + 0.25, 1.65, d + 0.02, 0.5, 0.5, Color("e8eef4"))
	Meshes.box(st, Vector3(door_x + 0.1, 0.0, d - 0.1), Vector3(0.8, 0.1, 1.0), Color("b8bcc4"))  # the ramp
	Landmarks._beam(st, Vector3(door_x + 0.1, 0.1, d + 0.9), Vector3(door_x + 0.1, 1.1, d - 0.02), 0.5, Color("b8bcc4"))
	Landmarks._door(st, door_x, d + 0.02, Color("e8eef4"), 1.1)

## An aircraft hangar: a long low box with a barrel roof (three flat panels) and a huge door.
static func _hangar(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var skin := Color("b4bcc6")
	var h := 1.5
	Meshes.box(st, Vector3(0.05, 0, 0.05), Vector3(w - 0.1, h, d - 0.1), skin)
	Meshes.box(st, Vector3(0.0, 0, 0.0), Vector3(w, 0.16, d), skin.darkened(0.35))
	Meshes.box(st, Vector3(0.05, h, 0.05), Vector3(w - 0.1, 0.35, d - 0.1), skin.lightened(0.04))
	Meshes.box(st, Vector3(0.05, h + 0.35, 0.4), Vector3(w - 0.1, 0.3, d - 0.8), skin.lightened(0.08))
	Meshes.box(st, Vector3(door_x - 0.9, 0.16, d - 0.05), Vector3(2.8, 1.25, 0.06), Color("c8402c"))
	Meshes.box(st, Vector3(door_x - 0.9, 1.35, d - 0.06), Vector3(2.8, 0.06, 0.08), Color("e8eef4"))
	Landmarks._chimneys.append(Vector3(w * 0.5, h + 0.9, d * 0.5))

# --- point props -----------------------------------------------------------------

static func prop(name: String, variant: int) -> ArrayMesh:
	match name:
		"penguin":
			return penguin(variant)
		"seal":
			return seal(variant)
		"iceberg":
			return iceberg(variant)
		"tussac":
			return tussac(variant)
		"skidoo":
			return skidoo()
		"headstone":
			return headstone()
		"catcher_hulk":
			return catcher_hulk()
		"twin_otter":
			return twin_otter()
	return Meshes.rock(0)

## A penguin facing south. 0 king (orange ear patches), 1 gentoo (white eye flash, orange bill), 2 emperor (taller,
## gold throat), 3 a brown chick.
static func penguin(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41 + variant)
	var s: float = [0.95, 0.8, 1.15, 0.6][clampi(variant, 0, 3)]
	var back := Color("2b2d38") if variant < 3 else Color("7a5a3c")
	var belly := Color("f2f0ec") if variant < 3 else Color("9a7a54")
	var acc: Color = [Color("f0a830"), Color("e8762a"), Color("f4c84a"), Color("2c2830")][clampi(variant, 0, 3)]
	Meshes.blob(st, Vector3(0, 0.36 * s, 0), Vector3(0.19, 0.36, 0.16) * s, back, rng, 0.06)
	Meshes.blob(st, Vector3(0, 0.33 * s, 0.07 * s), Vector3(0.13, 0.3, 0.1) * s, belly, rng, 0.04)
	Meshes.blob(st, Vector3(0, 0.74 * s, 0.01), Vector3(0.1, 0.1, 0.1) * s, back, rng, 0.05)
	if variant != 3:
		Meshes.box(st, Vector3(-0.13 * s, 0.7 * s, 0.0), Vector3(0.05, 0.1, 0.06) * s, acc)
		Meshes.box(st, Vector3(0.08 * s, 0.7 * s, 0.0), Vector3(0.05, 0.1, 0.06) * s, acc)
		Meshes.box(st, Vector3(-0.04 * s, 0.52 * s, 0.1 * s), Vector3(0.08, 0.07, 0.04) * s, acc.lightened(0.15))
	Meshes.box(st, Vector3(-0.025 * s, 0.7 * s, 0.1 * s), Vector3(0.05, 0.035, 0.1) * s, Color("e8762a") if variant == 1 else Color("3a3430"))
	Meshes.box(st, Vector3(-0.22 * s, 0.3 * s, -0.04), Vector3(0.05, 0.3, 0.12) * s, back.lightened(0.1))
	Meshes.box(st, Vector3(0.17 * s, 0.3 * s, -0.04), Vector3(0.05, 0.3, 0.12) * s, back.lightened(0.1))
	Meshes.box(st, Vector3(-0.1 * s, 0.0, 0.0), Vector3(0.08, 0.04, 0.14), Color("3a3430"))
	Meshes.box(st, Vector3(0.03 * s, 0.0, 0.0), Vector3(0.08, 0.04, 0.14), Color("3a3430"))
	return Meshes._finish(st)

## A seal lying on the beach, facing south. 0 elephant seal (big, grey-brown, a drooping nose), 1 Weddell (mottled).
static func seal(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(53 + variant)
	var hide := Color("5c564f") if variant == 0 else Color("4a525e")
	var s := 1.0 if variant == 0 else 0.75
	Meshes.blob(st, Vector3(0, 0.26 * s, -0.1), Vector3(0.34, 0.26, 0.62) * s, hide, rng, 0.08)
	Meshes.blob(st, Vector3(0, 0.3 * s, 0.48 * s), Vector3(0.18, 0.2, 0.2) * s, hide.lightened(0.06), rng, 0.05)
	Meshes.box(st, Vector3(-0.22 * s, 0.05, -0.1), Vector3(0.44, 0.1, 0.7) * s, hide.lightened(0.25))  # the pale belly
	Meshes.box(st, Vector3(-0.2 * s, 0.0, 0.0), Vector3(0.4, 0.05, 0.9) * s, hide.darkened(0.25))
	if variant == 0:
		Meshes.box(st, Vector3(-0.05, 0.2, 0.66), Vector3(0.1, 0.16, 0.12), hide.darkened(0.12))  # the proboscis
	else:
		for i in 4:
			Meshes.box(st, Vector3(-0.2 + 0.1 * i, 0.5 * s, -0.2 + 0.18 * (i % 2)), Vector3(0.06, 0.02, 0.06), Color("dfe3e8"))
	Meshes.box(st, Vector3(-0.08 * s, 0.38 * s, 0.64 * s), Vector3(0.05, 0.05, 0.03), Color("14101a"))
	Meshes.box(st, Vector3(0.03 * s, 0.38 * s, 0.64 * s), Vector3(0.05, 0.05, 0.03), Color("14101a"))
	return Meshes._finish(st)

## An iceberg: a jagged blue-white mass, 0 small, 1 medium, 2 big (three overlapping lumps).
static func iceberg(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(67 + variant)
	var n := 1 + clampi(variant, 0, 2)
	for i in n:
		var r := Vector3(0.5 + 0.25 * variant - 0.1 * i, 0.55 + 0.25 * variant, 0.5 + 0.2 * variant)
		Meshes.blob(st, Vector3(-0.5 * i + 0.3 * (n - 1) * 0.5, r.y * 0.55, 0.3 * (i % 2)), r, Color("e4f2f8"), rng, 0.3)
	Meshes.cylinder(st, Vector3(0, -0.2, 0), 0.5 + 0.2 * variant, 0.3, 7, Color("9cc4d8"))
	return Meshes._finish(st)

## A tussac tussock: a hummock of golden-green leaves arching out like a fountain, on a peaty stalk.
static func tussac(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(79 + variant)
	Meshes.cylinder(st, Vector3(0, 0, 0), 0.26, 0.32, 6, Color("5a4630"))
	for i in 15:
		var a := TAU * i / 15.0 + rng.randf() * 0.3
		var reach := rng.randf_range(0.35, 0.62)
		var up := rng.randf_range(0.6, 0.95)
		var col := Color("8a9a4a").lightened(rng.randf_range(-0.08, 0.14)) if i % 3 else Color("b6a850")
		Landmarks._beam(st, Vector3(cos(a) * 0.08, 0.3, sin(a) * 0.08), Vector3(cos(a) * reach, up, sin(a) * reach), 0.05, col)
	return Meshes._finish(st)

static func skidoo() -> ArrayMesh:
	var st := Meshes._st()
	Meshes.box(st, Vector3(-0.24, 0.0, -0.4), Vector3(0.16, 0.14, 0.9), Color("2c2e34"))
	Meshes.box(st, Vector3(0.08, 0.0, -0.4), Vector3(0.16, 0.14, 0.9), Color("2c2e34"))
	Meshes.box(st, Vector3(-0.24, 0.14, -0.35), Vector3(0.48, 0.34, 0.7), Color("c8402c"), Color("d85a42"))
	Meshes.box(st, Vector3(-0.2, 0.48, 0.1), Vector3(0.4, 0.22, 0.04), Color("bfe0ea"))
	Meshes.box(st, Vector3(-0.26, 0.5, 0.18), Vector3(0.52, 0.05, 0.05), Color("2c2e34"))
	Meshes.box(st, Vector3(-0.14, 0.48, -0.3), Vector3(0.28, 0.1, 0.3), Color("2c2e34"))
	return Meshes._finish(st)

## Shackleton's grave: a plain granite headstone in a low kerb, with a few stones laid on top.
static func headstone() -> ArrayMesh:
	var st := Meshes._st()
	var granite := Color("8d8c92")
	Meshes.box(st, Vector3(-0.38, 0.0, -0.3), Vector3(0.76, 0.1, 0.9), granite.darkened(0.2))
	Meshes.box(st, Vector3(-0.28, 0.1, -0.1), Vector3(0.56, 0.62, 0.14), granite, granite.lightened(0.12))
	Meshes.box(st, Vector3(-0.22, 0.72, -0.08), Vector3(0.44, 0.08, 0.1), granite.darkened(0.1))
	for x in [-0.15, 0.0, 0.14]:
		Meshes.box(st, Vector3(x, 0.1, 0.25), Vector3(0.09, 0.05, 0.09), Color("4a4a52"))
	return Meshes._finish(st)

## A rusting whale catcher aground on the shore: a tapering hull with a raised bow, a bridge, a funnel and a gun
## platform. Spreads about five tiles east-west, bow to the east.
static func catcher_hulk() -> ArrayMesh:
	var st := Meshes._st()
	var rust := Color("7a4632")
	var dark := Color("3a2e2a")
	Meshes.box(st, Vector3(-2.5, 0.0, -0.6), Vector3(4.2, 0.9, 1.2), rust)
	Meshes._tri(st, Vector3(1.7, 0.0, -0.6), Vector3(1.7, 0.9, -0.6), Vector3(2.7, 1.1, 0.0), rust.lightened(0.05))
	Meshes._tri(st, Vector3(1.7, 0.9, 0.6), Vector3(1.7, 0.0, 0.6), Vector3(2.7, 1.1, 0.0), rust.darkened(0.1))
	Meshes._quad(st, Vector3(1.7, 0.9, -0.6), Vector3(1.7, 0.9, 0.6), Vector3(2.7, 1.1, 0.0), Vector3(2.7, 1.1, 0.0), rust.lightened(0.1))
	Meshes.box(st, Vector3(-2.5, 0.9, -0.55), Vector3(4.2, 0.06, 1.1), dark)
	Meshes.box(st, Vector3(-0.6, 0.96, -0.4), Vector3(1.1, 0.7, 0.8), rust.lightened(0.1))
	Meshes.box(st, Vector3(-0.55, 1.66, -0.35), Vector3(1.0, 0.1, 0.7), dark)
	Meshes.cylinder(st, Vector3(-1.5, 0.96, 0.0), 0.28, 1.2, 7, dark)
	Meshes.box(st, Vector3(1.2, 0.96, -0.1), Vector3(0.5, 0.2, 0.2), dark)  # the harpoon gun
	Landmarks._beam(st, Vector3(1.2, 1.1, 0.0), Vector3(1.9, 1.4, 0.0), 0.08, dark)
	Landmarks._beam(st, Vector3(0.0, 1.66, 0.0), Vector3(0.1, 2.5, 0.0), 0.06, dark)  # a broken mast
	return Meshes._finish(st)

## A Twin Otter on its skis (a hangar prop): red and white, a high wing on struts, a tall tail, two engines.
static func twin_otter() -> ArrayMesh:
	var st := Meshes._st()
	var white := Color("eceaf0")
	var red := Color("c8302a")
	Meshes.box(st, Vector3(-0.35, 0.35, -1.6), Vector3(0.7, 0.7, 2.8), white, white.lightened(0.05))
	Meshes.box(st, Vector3(-0.36, 0.55, -1.6), Vector3(0.72, 0.15, 2.8), red)
	Meshes._tri(st, Vector3(-0.3, 0.45, 1.2), Vector3(0.3, 0.45, 1.2), Vector3(0.0, 0.55, 1.7), white)
	Meshes.box(st, Vector3(-0.06, 0.7, -1.7), Vector3(0.12, 0.9, 0.5), red)
	Meshes.box(st, Vector3(-0.5, 0.95, -1.5), Vector3(1.0, 0.07, 0.4), white.darkened(0.08))
	Meshes.box(st, Vector3(-1.9, 1.15, -0.5), Vector3(3.8, 0.1, 0.7), white.darkened(0.04))
	for x in [-1.0, 0.8]:
		Meshes.box(st, Vector3(x, 0.8, -0.35), Vector3(0.2, 0.3, 0.5), Color("5a5e68"))
		Meshes.box(st, Vector3(x - 0.04, 0.55, -0.4), Vector3(0.04, 0.55, 0.04), Color("2c2e34"))
	Meshes.box(st, Vector3(-0.4, 0.05, 0.1), Vector3(0.1, 0.1, 1.2), Color("2c2e34"))  # skis
	Meshes.box(st, Vector3(0.3, 0.05, 0.1), Vector3(0.1, 0.1, 1.2), Color("2c2e34"))
	Meshes.box(st, Vector3(-0.35, 0.8, 1.0), Vector3(0.7, 0.18, 0.04), Color("5a7a98"))  # windscreen
	return Meshes._finish(st)
