class_name PlaceProps
extends RefCounted
## Odd pieces that make a room look like what its lines say it is. Point props (ZoneBuilder.POINT_PROPS), same
## rules as Dressing: vertex colour, low poly, origin at the tile's centre on the floor, the north wall at z = -0.5
## (turn one with "rot": 90 to stand it on the west wall, 270 on the east).

## A plain back door in the wall: a planked leaf in a painted frame, a latch, a worn step.
static func back_door(variant := 0) -> ArrayMesh:
	var st := Meshes._st()
	var paint: Color = [Color("2f4a3a"), Color("5a2a26"), Color("2c3a52")][variant % 3]
	var frame := Color("e3dccb")
	Meshes.box(st, Vector3(-0.36, 0, -0.5), Vector3(0.72, 1.42, 0.06), frame)
	Meshes.box(st, Vector3(-0.3, 0, -0.46), Vector3(0.6, 1.34, 0.04), paint)
	for k in 4:  # the planks
		Meshes.box(st, Vector3(-0.3 + k * 0.15, 0.02, -0.418), Vector3(0.006, 1.3, 0.004), paint.darkened(0.25))
	for y in [0.25, 1.05]:  # ledges
		Meshes.box(st, Vector3(-0.28, y, -0.418), Vector3(0.56, 0.06, 0.012), paint.darkened(0.1))
	Meshes.box(st, Vector3(0.18, 0.66, -0.41), Vector3(0.08, 0.025, 0.02), Color("2a2a2e"))  # the latch
	Meshes.box(st, Vector3(-0.36, 0, -0.44), Vector3(0.72, 0.03, 0.14), Color("9b927f"))  # the step
	return Meshes._finish(st)
