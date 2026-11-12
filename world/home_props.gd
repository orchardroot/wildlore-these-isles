class_name HomeProps
extends RefCounted
## Three regional pieces for homes (w53): a cast-iron range, a high-backed settle and an Orkney box bed.
## Same rules as Dressing: vertex colours, y = 0 at the origin, back against the north wall (z = -0.5).

const NAMES := ["range_cooker", "settle", "box_bed"]

static func mesh(name: String, variant := 0) -> ArrayMesh:
	match name:
		"range_cooker":
			return range_cooker()
		"settle":
			return settle(variant)
		_:
			return box_bed(variant)

## A black range with a rail, a flue going up the wall and the kettle that never leaves it.
static func range_cooker() -> ArrayMesh:
	var st := Meshes._st()
	var iron := Color("26282c")
	Meshes.box(st, Vector3(-0.42, 0, -0.5), Vector3(0.84, 0.86, 0.6), iron)
	Meshes.box(st, Vector3(-0.44, 0.86, -0.5), Vector3(0.88, 0.05, 0.64), iron.lightened(0.12))
	Meshes.box(st, Vector3(-0.34, 0.3, 0.1), Vector3(0.3, 0.28, 0.02), iron.lightened(0.2))
	Meshes.box(st, Vector3(0.06, 0.18, 0.1), Vector3(0.28, 0.4, 0.02), Color("111214"))
	Meshes.box(st, Vector3(-0.36, 0.64, 0.1), Vector3(0.72, 0.03, 0.03), Dressing.BRASS)
	Meshes.box(st, Vector3(-0.1, 0.91, -0.46), Vector3(0.2, 1.6, 0.2), iron.darkened(0.05))
	Meshes.cylinder(st, Vector3(-0.24, 0.91, -0.1), 0.14, 0.16, 8, Color("8a5a48"))
	Meshes.box(st, Vector3(-0.1, 0.91, -0.3), Vector3(0.1, 0.03, 0.18), Dressing.BRASS)
	return Meshes._finish(st)

## A tall wooden settle, back to the wall, a cushion on the seat. Variant 1 is painted.
static func settle(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var wood: Color = Dressing.WOOD if variant == 0 else Color("3f6a5a")
	Meshes.box(st, Vector3(-0.46, 0, -0.45), Vector3(0.92, 0.32, 0.7), wood.darkened(0.1))
	Meshes.box(st, Vector3(-0.46, 0.32, -0.5), Vector3(0.92, 0.95, 0.1), wood)
	Meshes.box(st, Vector3(-0.46, 0.32, -0.45), Vector3(0.08, 0.3, 0.7), wood.lightened(0.05))
	Meshes.box(st, Vector3(0.38, 0.32, -0.45), Vector3(0.08, 0.3, 0.7), wood.lightened(0.05))
	Meshes.box(st, Vector3(-0.36, 0.32, -0.38), Vector3(0.72, 0.1, 0.54), Color("a8493f"))
	return Meshes._finish(st)

## A box bed: a panelled wooden enclosure with a doorway in the front and the quilt just showing.
static func box_bed(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var wood: Color = Color("5a3f2a") if variant == 0 else Color("6f7a6a")
	Meshes.box(st, Vector3(-0.46, 0, -0.5), Vector3(0.92, 0.2, 1.0), wood.darkened(0.1))
	Meshes.box(st, Vector3(-0.46, 0.2, -0.5), Vector3(0.08, 0.9, 1.0), wood)
	Meshes.box(st, Vector3(0.38, 0.2, -0.5), Vector3(0.08, 0.9, 1.0), wood)
	Meshes.box(st, Vector3(-0.46, 0.2, -0.5), Vector3(0.92, 0.9, 0.08), wood.darkened(0.05))
	Meshes.box(st, Vector3(-0.46, 1.0, -0.5), Vector3(0.92, 0.1, 1.0), wood.lightened(0.08))
	Meshes.box(st, Vector3(-0.38, 0.2, -0.42), Vector3(0.76, 0.22, 0.9), Color("a8493f"))
	Meshes.box(st, Vector3(-0.3, 0.42, -0.4), Vector3(0.6, 0.1, 0.24), Color("f2ede2"))
	return Meshes._finish(st)
