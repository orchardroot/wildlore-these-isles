class_name SanctuaryProps
extends RefCounted
## A Sanctuary's furniture, so the room reads as a creature sanctuary and vet's rather than a reading room: the
## restoring cabinet behind the counter, a shelf of medicines and treats, creature baskets, the noticeboard and
## posters. Point props (ZoneBuilder.POINT_PROPS), same rules as Dressing: vertex colour, low poly, origin at the
## tile's centre on the floor, the north wall at z = -0.5.

const GREEN := Color("3fa36b")       # the Sanctuary's cross (Signage._emblem)
const DEEP_GREEN := Color("2f6a4a")
const CREAM := Color("f6f3ea")
const WICKER := Color("b8874a")
const CORK := Color("b98a57")

## The green cross on white, flat on a face looking south at c.
static func _cross(st: SurfaceTool, c: Vector3, r: float) -> void:
	Dressing._disc_z(st, c, r, 12, CREAM)
	var a := r * 0.34
	Meshes.box(st, c + Vector3(-a * 0.5, -r * 0.7, 0.004), Vector3(a, r * 1.4, 0.006), GREEN)
	Meshes.box(st, c + Vector3(-r * 0.7, -a * 0.5, 0.004), Vector3(r * 1.4, a, 0.006), GREEN)

## The restoring cabinet against the north wall: a pale cabinet with the green cross, a tray of six round hollows
## glowing soft green where a team's creatures rest, and a little screen with a heartbeat trace.
static func restorer() -> ArrayMesh:
	var st := Meshes._st()
	var body := Color("e9ece6")
	Meshes.box(st, Vector3(-0.44, 0, -0.5), Vector3(0.88, 0.86, 0.46), body)
	Meshes.box(st, Vector3(-0.44, 0.0, -0.06), Vector3(0.88, 0.08, 0.02), body.darkened(0.25))  # kick plate
	for k in 2:  # cupboard doors
		Meshes.box(st, Vector3(-0.4 + k * 0.41, 0.12, -0.045), Vector3(0.38, 0.62, 0.012), body.darkened(0.06))
	_cross(st, Vector3(0, 0.44, -0.03), 0.12)
	# the sloping tray of six hollows
	var tray := Color("cfd6d0")
	Meshes.box(st, Vector3(-0.42, 0.86, -0.46), Vector3(0.84, 0.06, 0.4), tray)
	for i in 6:
		var c := Vector3(-0.27 + (i % 3) * 0.27, 0.92, -0.34 + (i / 3) * 0.17)
		Meshes.cylinder(st, c, 0.07, 0.012, 10, DEEP_GREEN.darkened(0.2))
		Meshes.blob(st, c + Vector3(0, 0.03, 0), Vector3(0.05, 0.035, 0.05), Color("a6f0c2"), Meshes._rng(41700 + i), 0.05)
	# the screen on its stand, a green trace across it
	Meshes.box(st, Vector3(-0.3, 0.92, -0.5), Vector3(0.6, 0.42, 0.06), Color("394049"))
	Meshes.box(st, Vector3(-0.26, 0.96, -0.44), Vector3(0.52, 0.34, 0.01), Color("16302a"))
	var y := 1.13
	var pts := [Vector2(-0.24, 0), Vector2(-0.08, 0), Vector2(-0.04, 0.09), Vector2(0.0, -0.08), Vector2(0.04, 0.03), Vector2(0.08, 0), Vector2(0.24, 0)]
	for i in pts.size() - 1:
		Dressing._bar(st, Vector3(pts[i].x, y + pts[i].y, -0.428), Vector3(pts[i + 1].x, y + pts[i + 1].y, -0.428), 0.008, Color("7dffb0"))
	return Meshes._finish(st)

## A shelf of medicines and treats against the north wall: brown bottles, rolls of bandage, jars of treats, a stack
## of folded towels and a sack of feed on the floor.
static func shelf(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41800 + variant)
	var frame := Color("e3ddd0")
	Meshes.box(st, Vector3(-0.46, 0, -0.5), Vector3(0.92, 1.6, 0.05), frame.darkened(0.08))
	for sx in [-0.46, 0.42]:
		Meshes.box(st, Vector3(sx, 0, -0.5), Vector3(0.04, 1.6, 0.38), frame)
	Meshes.box(st, Vector3(-0.46, 1.56, -0.5), Vector3(0.92, 0.04, 0.38), frame)
	for row in 3:
		var y := 0.5 + row * 0.36
		Meshes.box(st, Vector3(-0.42, y - 0.04, -0.46), Vector3(0.84, 0.04, 0.34), frame.darkened(0.04))
		var x := -0.4
		while x < 0.3:
			match (rng.randi() + row) % 4:
				0:  # a brown medicine bottle with a white label
					var r := rng.randf_range(0.035, 0.045)
					var h := rng.randf_range(0.13, 0.18)
					Meshes.cylinder(st, Vector3(x + r, y, -0.22), r, h, 6, Color("6b3a1e"))
					Meshes.cylinder(st, Vector3(x + r, y + h * 0.3, -0.22 + 0.004), r * 1.02, h * 0.35, 6, CREAM)
					Meshes.cylinder(st, Vector3(x + r, y + h, -0.22), r * 0.6, 0.04, 6, Color("2a2a2e"))
					x += r * 2.0 + 0.03
				1:  # a roll of bandage
					Meshes.cylinder(st, Vector3(x + 0.05, y, -0.22), 0.05, 0.08, 8, Color("f4f1ea"))
					x += 0.12
				2:  # a jar of treats
					var r2 := 0.06
					Meshes.cylinder(st, Vector3(x + r2, y, -0.22), r2, 0.16, 8, Color("d6ebe6"))
					Meshes.cylinder(st, Vector3(x + r2, y + 0.01, -0.21), r2 * 0.82, 0.1, 8, [Color("c98a3a"), Color("8c3b3b"), Color("e0b83a")][rng.randi() % 3])
					Meshes.cylinder(st, Vector3(x + r2, y + 0.16, -0.22), r2 * 0.9, 0.025, 8, GREEN.darkened(0.2))
					x += r2 * 2.0 + 0.03
				_:  # a box of something, with the cross on it
					Meshes.box(st, Vector3(x, y, -0.3), Vector3(0.14, 0.12, 0.12), CREAM.darkened(0.04))
					Meshes.box(st, Vector3(x + 0.055, y + 0.03, -0.18), Vector3(0.03, 0.06, 0.004), GREEN)
					Meshes.box(st, Vector3(x + 0.04, y + 0.045, -0.18), Vector3(0.06, 0.03, 0.004), GREEN)
					x += 0.17
	# folded towels on the bottom shelf, and a sack of feed beside them
	var towel: Color = [Color("8fc3dc"), Color("e8a0a0"), Color("bfe0b0")][variant % 3]
	for k in 4:
		Meshes.box(st, Vector3(-0.4, 0.04 + k * 0.07, -0.42), Vector3(0.36, 0.065, 0.3), towel if k % 2 == 0 else towel.lightened(0.25))
	Meshes.blob(st, Vector3(0.18, 0.2, -0.28), Vector3(0.17, 0.2, 0.13), Color("c9b48a"), rng, 0.06)
	Meshes.box(st, Vector3(0.1, 0.18, -0.15), Vector3(0.16, 0.1, 0.004), DEEP_GREEN)
	return Meshes._finish(st)

## A round wicker basket with a cushion and a blanket; variant 1 has a creature curled up asleep in it.
static func basket(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(41900 + variant)
	var r := 0.36
	Meshes.cylinder(st, Vector3(0, 0, 0.02), r, 0.2, 14, WICKER)
	for y in [0.06, 0.13]:  # the weave
		Meshes.cylinder(st, Vector3(0, y, 0.02), r + 0.008, 0.025, 14, WICKER.darkened(0.2))
	Meshes.cylinder(st, Vector3(0, 0.2, 0.02), r + 0.02, 0.04, 14, WICKER.lightened(0.1))  # the rim
	var cushion: Color = [Color("c9483f"), Color("2f6f9e"), Color("e0b83a")][variant % 3]
	Meshes.cylinder(st, Vector3(0, 0.12, 0.02), r - 0.05, 0.1, 12, cushion)
	Meshes.box(st, Vector3(-0.2, 0.2, 0.08), Vector3(0.4, 0.04, 0.24), cushion.lightened(0.35))  # the blanket's fold
	if variant % 2 == 1:  # a sleeper, nose tucked into its tail
		var fur := Color("c98a4a")
		Meshes.blob(st, Vector3(0.0, 0.3, 0.0), Vector3(0.2, 0.11, 0.16), fur, rng, 0.06)
		Meshes.blob(st, Vector3(0.12, 0.31, 0.08), Vector3(0.09, 0.08, 0.08), fur.lightened(0.08), rng, 0.04)
		for ex in [0.08, 0.17]:
			Meshes._tri(st, Vector3(ex - 0.03, 0.36, 0.06), Vector3(ex, 0.43, 0.06), Vector3(ex + 0.03, 0.36, 0.06), fur.darkened(0.15))
		Dressing._bar(st, Vector3(-0.16, 0.3, 0.1), Vector3(0.06, 0.29, 0.15), 0.035, fur.darkened(0.1))  # the tail
	return Meshes._finish(st)

## The noticeboard on the north wall: cork in a wooden frame, pinned with cards, a rota and a found-creature poster.
static func noticeboard() -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(42000)
	Meshes.box(st, Vector3(-0.42, 0.95, -0.5), Vector3(0.84, 0.66, 0.04), Dressing.DARK_WOOD)
	Meshes.box(st, Vector3(-0.38, 0.99, -0.46), Vector3(0.76, 0.58, 0.01), CORK)
	var z := -0.448
	var papers := [CREAM, Color("f2e27a"), Color("bfe0f0"), Color("f4c8c8"), Color("d8f0c8")]
	for i in 7:
		var w := rng.randf_range(0.1, 0.18)
		var h := rng.randf_range(0.1, 0.17)
		var x := -0.34 + (i % 4) * 0.18 + rng.randf_range(-0.02, 0.02)
		var y := 1.03 + (i / 4) * 0.26 + rng.randf_range(0.0, 0.04)
		Meshes.box(st, Vector3(x, y, z), Vector3(w, h, 0.004), papers[i % papers.size()])
		for k in 2:  # lines of writing
			Meshes.box(st, Vector3(x + 0.02, y + h - 0.04 - k * 0.035, z + 0.004), Vector3(w - 0.04, 0.008, 0.002), Color("6a6a70"))
		Meshes.box(st, Vector3(x + w * 0.5 - 0.01, y + h - 0.02, z + 0.004), Vector3(0.02, 0.02, 0.01), [Color("c9483f"), GREEN, Color("2f6f9e")][i % 3])
	# a found-creature poster: a photo and big lettering
	Meshes.box(st, Vector3(0.12, 1.3, z - 0.002), Vector3(0.22, 0.24, 0.006), CREAM)
	Meshes.box(st, Vector3(0.15, 1.39, z + 0.004), Vector3(0.16, 0.12, 0.002), Color("8fb0a0"))
	Meshes.blob(st, Vector3(0.23, 1.44, z + 0.008), Vector3(0.04, 0.03, 0.004), Color("c98a4a"), rng, 0.01)
	Meshes.box(st, Vector3(0.15, 1.33, z + 0.004), Vector3(0.16, 0.03, 0.002), Color("c9483f"))
	return Meshes._finish(st)

## A poster on the north wall. 0: the green cross over a creature's outline ("care for them"); 1: a feeding chart.
static func poster(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var z := -0.456
	Meshes.box(st, Vector3(-0.2, 1.05, -0.5), Vector3(0.4, 0.56, 0.04), Color("e9e4d8"))
	if variant % 2 == 0:
		Meshes.box(st, Vector3(-0.17, 1.08, z), Vector3(0.34, 0.5, 0.004), Color("dff0e4"))
		Meshes.blob(st, Vector3(0.0, 1.22, z + 0.006), Vector3(0.12, 0.07, 0.004), DEEP_GREEN.lightened(0.15), Meshes._rng(42100), 0.01)
		Meshes.blob(st, Vector3(0.09, 1.28, z + 0.006), Vector3(0.05, 0.05, 0.004), DEEP_GREEN.lightened(0.15), Meshes._rng(42101), 0.01)
		_cross(st, Vector3(0, 1.44, z + 0.006), 0.07)
		Meshes.box(st, Vector3(-0.12, 1.11, z + 0.006), Vector3(0.24, 0.025, 0.002), DEEP_GREEN)
	else:
		Meshes.box(st, Vector3(-0.17, 1.08, z), Vector3(0.34, 0.5, 0.004), CREAM)
		Meshes.box(st, Vector3(-0.15, 1.5, z + 0.004), Vector3(0.3, 0.05, 0.002), DEEP_GREEN)
		for row in 5:
			for col in 3:
				var c: Color = [Color("e0b83a"), Color("8fc3dc"), Color("c9483f")][(row + col) % 3]
				Meshes.box(st, Vector3(-0.14 + col * 0.1, 1.12 + row * 0.07, z + 0.004), Vector3(0.08, 0.05, 0.002), c.lightened(0.3))
	return Meshes._finish(st)
