class_name Noticeboard
extends RefCounted
## The parish noticeboard in every town: a little roofed oak board on two posts, green baize, papers pinned all over.
## Built into the zone like Forage's props (a `noticeboard` prop: x, y and an optional "rot" in degrees, facing
## south by default); facing it and pressing confirm opens the Jobs screen for that town (see Jobs).

const TYPE := "noticeboard"

static var _mesh: ArrayMesh

static func dress(z: ZoneData, zone_node: Node3D) -> void:
	for pr in z.props:
		if str(pr.get("type", "")) != TYPE:
			continue
		var p := Vector2i(int(pr.x), int(pr.y))
		var mi := MeshInstance3D.new()
		mi.name = "Noticeboard_%d_%d" % [p.x, p.y]
		mi.mesh = mesh()
		mi.material_override = Meshes.solid
		mi.position = Vector3(p.x + 0.5, ZoneBuilder.ground_y(z, p), p.y + 0.5)
		mi.rotation.y = deg_to_rad(float(pr.get("rot", 0)))
		zone_node.add_child(mi)

static func at(z: ZoneData, p: Vector2i) -> bool:
	for pr in z.props:
		if str(pr.get("type", "")) == TYPE and int(pr.x) == p.x and int(pr.y) == p.y:
			return true
	return false

## Facing a noticeboard and pressing confirm: the town's jobs. True when it was one.
static func interact(ow: Node, p: Vector2i) -> bool:
	if not at(ow.zone, p):
		return false
	Audio.sfx("confirm")
	if not Contracts.offered(Game.data, str(ow.zone.id)).is_empty():  # a contract notice pinned on top (core/contracts.gd)
		await ScriptRunner.start(ow, [{"do": "contract", "as": "board", "town": str(ow.zone.id)}])
	await Router.open_menu("jobs:" + str(ow.zone.id))
	return true

# --- the mesh -------------------------------------------------------------------

const OAK := Color("6e4a2e")
const OAK_DARK := Color("4a3020")
const OAK_LIGHT := Color("8c6440")
const BAIZE := Color("2f4f3a")
const SLATE := Color("454b55")
const PAPERS := [Color("f3ecd8"), Color("f4e3a1"), Color("d6e4ec"), Color("f1d2cb"), Color("fbfaf4"), Color("e3ecd0")]
const PINS := [Color("c8423a"), Color("2f6fb0"), Color("e0b23a"), Color("3f8a55")]
const INK := Color("6b6a66")

static func mesh() -> ArrayMesh:
	if _mesh == null:
		_mesh = _build()
	return _mesh

static func _build() -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(5150)
	# two oak posts with a little chamfered cap below the roof
	for px in [-0.56, 0.46]:
		Meshes.box(st, Vector3(px, 0, -0.05), Vector3(0.1, 1.68, 0.1), OAK_DARK, OAK)
		Meshes.box(st, Vector3(px - 0.015, 0, -0.065), Vector3(0.13, 0.08, 0.13), OAK_DARK.darkened(0.2))
	# the board: a dark oak back, a raised frame and the green baize
	Meshes.box(st, Vector3(-0.5, 0.6, -0.04), Vector3(1.0, 0.84, 0.06), OAK_DARK)
	Meshes.box(st, Vector3(-0.46, 0.64, 0.02), Vector3(0.92, 0.76, 0.012), BAIZE)
	Meshes.box(st, Vector3(-0.5, 0.6, 0.02), Vector3(1.0, 0.045, 0.035), OAK_LIGHT)
	Meshes.box(st, Vector3(-0.5, 1.395, 0.02), Vector3(1.0, 0.045, 0.035), OAK_LIGHT)
	Meshes.box(st, Vector3(-0.5, 0.6, 0.02), Vector3(0.045, 0.84, 0.035), OAK_LIGHT)
	Meshes.box(st, Vector3(0.455, 0.6, 0.02), Vector3(0.045, 0.84, 0.035), OAK_LIGHT)
	# a narrow ledge along the bottom (for the drawing pins nobody puts back)
	Meshes.box(st, Vector3(-0.5, 0.56, 0.0), Vector3(1.0, 0.04, 0.1), OAK)
	# the papers, each pinned at a slight tilt, with lines of writing and a coloured pin head
	var notes := [[-0.27, 1.08, 0.3, 0.34, -4.0], [0.08, 1.12, 0.26, 0.28, 3.0], [0.31, 0.98, 0.22, 0.28, -2.0],
		[-0.3, 0.78, 0.28, 0.22, 2.5], [0.02, 0.83, 0.3, 0.32, -1.5], [0.3, 0.74, 0.2, 0.18, 5.0]]
	for i in notes.size():
		var n: Array = notes[i]
		var z := 0.034 + i * 0.0025
		var c := Vector2(n[0], n[1])
		var half := Vector2(n[2], n[3]) * 0.5
		var a := deg_to_rad(n[4])
		_paper(st, c, half, a, z, PAPERS[i % PAPERS.size()])
		var lines := int(half.y / 0.035)
		for k in lines:
			var ly := half.y - 0.07 - k * 0.055
			if ly < -half.y + 0.03:
				break
			var lw := half.x * rng.randf_range(0.55, 0.85) if k > 0 else half.x * 0.5
			_paper(st, c + Vector2(-half.x * 0.85 + lw, ly).rotated(a), Vector2(lw, 0.008 if k > 0 else 0.013), a, z + 0.0015, INK if k > 0 else INK.darkened(0.3))
		var pin := c + Vector2(0, half.y - 0.025).rotated(a)
		Meshes.box(st, Vector3(pin.x - 0.016, pin.y - 0.016, z + 0.002), Vector3(0.032, 0.032, 0.02), PINS[i % PINS.size()])
	# the roof: two slate slopes on oak gables, with a ridge
	var rx0 := -0.66
	var rx1 := 0.66
	var eave := 1.56
	var ridge := 1.8
	var zf := 0.2
	var zb := -0.24
	var zr := 0.015
	var under := SLATE.darkened(0.35)
	Meshes._quad(st, Vector3(rx0, ridge, zr), Vector3(rx1, ridge, zr), Vector3(rx1, eave, zf), Vector3(rx0, eave, zf), SLATE.lightened(0.06))
	Meshes._quad(st, Vector3(rx0, eave, zb), Vector3(rx1, eave, zb), Vector3(rx1, ridge, zr), Vector3(rx0, ridge, zr), SLATE.darkened(0.12))
	Meshes._quad(st, Vector3(rx0, eave - 0.04, zf), Vector3(rx1, eave - 0.04, zf), Vector3(rx1, ridge - 0.04, zr), Vector3(rx0, ridge - 0.04, zr), under)
	Meshes._quad(st, Vector3(rx0, ridge - 0.04, zr), Vector3(rx1, ridge - 0.04, zr), Vector3(rx1, eave - 0.04, zb), Vector3(rx0, eave - 0.04, zb), under)
	for x in [rx0, rx1]:
		var s := -1.0 if x < 0 else 1.0
		Meshes._quad(st, Vector3(x, eave - 0.04, zf), Vector3(x, eave, zf), Vector3(x, ridge, zr), Vector3(x, ridge - 0.04, zr), SLATE.darkened(0.2))
		Meshes._quad(st, Vector3(x, eave, zb), Vector3(x, eave - 0.04, zb), Vector3(x, ridge - 0.04, zr), Vector3(x, ridge, zr), SLATE.darkened(0.2))
		# oak gable boards just inside the roof edge
		var gx: float = x - s * 0.08
		Meshes._tri(st, Vector3(gx, eave - 0.06, zf - 0.04), Vector3(gx, ridge - 0.06, zr), Vector3(gx, eave - 0.06, zb + 0.04), OAK)
		Meshes._tri(st, Vector3(gx, eave - 0.06, zb + 0.04), Vector3(gx, ridge - 0.06, zr), Vector3(gx, eave - 0.06, zf - 0.04), OAK.darkened(0.1))
	# slate courses: thin darker lines across each slope
	for k in range(1, 4):
		var t := k / 4.0
		var y := lerpf(eave, ridge, t) + 0.004
		var zz := lerpf(zf, zr, t)
		Meshes._quad(st, Vector3(rx0, y - 0.006, zz + 0.012), Vector3(rx1, y - 0.006, zz + 0.012), Vector3(rx1, y + 0.006, zz - 0.002), Vector3(rx0, y + 0.006, zz - 0.002), SLATE.darkened(0.4))
	Meshes.box(st, Vector3(rx0 - 0.02, ridge - 0.02, zr - 0.035), Vector3(rx1 - rx0 + 0.04, 0.05, 0.07), OAK_DARK)
	# a beam tying the posts under the roof, a dark fascia along the eave, and the painted name board on the frame
	Meshes.box(st, Vector3(-0.58, 1.48, -0.06), Vector3(1.16, 0.08, 0.12), OAK)
	Meshes.box(st, Vector3(rx0, eave - 0.07, zf - 0.03), Vector3(rx1 - rx0, 0.07, 0.035), OAK_DARK)
	Meshes.box(st, Vector3(-0.27, 1.305, 0.034), Vector3(0.54, 0.075, 0.012), Color("efe6cc"))
	for k in 9:
		Meshes.box(st, Vector3(-0.225 + k * 0.051, 1.33, 0.046), Vector3(0.032, 0.026, 0.004), Color("2f3a33"))
	return Meshes._finish(st)

## A flat rectangle facing south (+Z): centre c (x, y), half-size, tilted by `a` radians about the facing axis.
static func _paper(st: SurfaceTool, c: Vector2, half: Vector2, a: float, z: float, col: Color) -> void:
	var pts := []
	for v in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
		var r: Vector2 = c + v.rotated(a)
		pts.append(Vector3(r.x, r.y, z))
	Meshes._quad(st, pts[3], pts[2], pts[1], pts[0], col)
