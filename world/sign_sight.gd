class_name SignSight
extends RefCounted
## Can a building's name be read from where you stand to read it? Signs hang on fronts that a taller or deeper
## neighbour to the south can hide from the camera (the camera looks north and down). This casts sight lines
## from a point on a front to the camera's eye, standing at the building's door, against the buildings' own
## meshes: Signage uses it to keep a name on the part of its front you can see, and the tests and
## tools/dev/sign_audit.gd use it to list any that are still cut. Built once per zone build, never per frame.

const STEP := 0.1          # tiles between the columns sampled along a front
const MIN_RUN := 1.2       # narrower than this, a clear stretch of front is no place for a name

var _items := []   # of {aabb: AABB (world), pos: Vector3, mesh: Mesh, rect: Rect2 (footprint), tm: TriangleMesh (made on first use)}
var _bounds := Rect2()
var _at := Vector2(-INF, -INF)  # where the player stands (eye): buildings that go see-through then don't hide

## `bodies` is ZoneBuilder's [{pr, body, door_x}] (each body a MeshInstance3D placed by translation only).
static func make(z: ZoneData, bodies: Array) -> SignSight:
	var s := SignSight.new()
	s._bounds = Rect2(0, 0, z.width, z.height)
	for b in bodies:
		var mi := b.body as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := mi.mesh.get_aabb()
		box.position += mi.position
		var pr: Dictionary = b.pr
		s._items.append({"aabb": box, "pos": mi.position, "mesh": mi.mesh, "tm": null,
			"rect": Rect2(int(pr.x), int(pr.y), int(pr.w), int(pr.h))})
	return s

## Where the camera's eye is with the player on tile `p` standing at ground height `gy`. Sight lines checked after
## this look past any building that goes see-through with the player there (OccluderFade), as the game does.
func eye(p: Vector2i, gy: float) -> Vector3:
	_at = Vector2(p.x + 0.5, p.y + 0.5)
	return CameraRig.eye_for(_bounds, Vector3(p.x + 0.5, gy, p.y + 0.5))

## Does any building stand between `from` and the eye?
func blocked(from: Vector3, to: Vector3) -> bool:
	var seg := AABB(from, Vector3.ZERO).expand(to)
	for it in _items:
		if not (it.aabb as AABB).intersects(seg) or OccluderFade.hides(it.rect, _at):
			continue
		if it.tm == null:
			it.tm = (it.mesh as Mesh).generate_triangle_mesh()
			if it.tm == null:
				continue
		var o: Vector3 = it.pos
		if not (it.tm as TriangleMesh).intersect_segment(from - o, to - o).is_empty():
			return true
	return false

## The share (0..1) of the points from..to (a line across a sign, world units) hidden from `eye`.
func hidden_share(a: Vector3, b: Vector3, eye_at: Vector3, samples := 9) -> float:
	var n := 0
	for i in samples:
		if blocked(a.lerp(b, (i + 0.5) / samples), eye_at):
			n += 1
	return float(n) / samples

## Where on a front its name can go and be read from `eye_at`. `f` is Signage.front's band (footprint
## coordinates), `body` the building's own MeshInstance3D. With `flush`, the board finds the front's real face
## first (a jettied upper floor, Chester's Rows, a stuccoed front all stand proud of the footprint) and keeps off
## anything sticking out further (a porch, an oriel, a bay): it goes on the plane most of the front sits on.
## Then columns every STEP that a building (its own eaves too) hides from the eye are out. Returns {z, x0, x1}
## for the widest stretch left, preferring the one nearest `near_x` when two tie, or {} when none is MIN_RUN wide.
func place(f: Dictionary, body: MeshInstance3D, eye_at: Vector3, near_x: float, flush: bool) -> Dictionary:
	var x0: float = f.x0
	var x1: float = f.x1
	var lo: float = f.lo
	var hi: float = f.hi
	var n := int(floor((x1 - x0) / STEP)) + 1
	var plane: float = f.z
	var face := PackedFloat32Array()
	face.resize(n)
	face.fill(-INF)
	if flush:
		var own = _item(body)
		if own != null:
			var depths := []
			for i in n:
				var x := x0 + i * STEP
				for k in 6:  # every 0.08 or so up the band: a string course or a lintel can be thin
					var y := lo + 0.02 + (hi - lo - 0.04) * k / 5.0
					var hit := (own.tm as TriangleMesh).intersect_segment(Vector3(x, y, plane + 2.0), Vector3(x, y, plane - 0.6))
					if not hit.is_empty():
						face[i] = maxf(face[i], float(hit.position.z))
				if face[i] > -INF:
					depths.append(face[i])
			if not depths.is_empty():
				depths.sort()
				plane = maxf(plane, float(depths[depths.size() / 2]) + 0.01)
	var base := body.position
	var ys := [lo + (hi - lo) * 0.3, lo + (hi - lo) * 0.75]
	var best := {}
	var best_score := -INF
	var start := -1
	for i in n + 1:
		var ok := false
		# a column is out if something stands proud of the board there, or (flush) no wall stands behind it
		if i < n and face[i] <= plane + 0.05 and (not flush or face[i] >= plane - 0.4):
			var x := x0 + i * STEP
			ok = true
			for y in ys:
				if blocked(base + Vector3(x, float(y), plane + 0.035), eye_at):  # about where the lettering sits
					ok = false
					break
		if ok and start < 0:
			start = i
		elif not ok and start >= 0:
			var a := x0 + start * STEP
			var b := x0 + (i - 1) * STEP
			# a wide stretch wins; between two near enough the same, the one by the door
			var score := (b - a) - absf((a + b) * 0.5 - near_x) * 0.02
			if b - a >= minf(MIN_RUN, (x1 - x0) * 0.6) and score > best_score:
				best_score = score
				best = {"z": plane, "x0": a, "x1": b}
			start = -1
	return best

## Is any of `points` (world) hidden from `eye_at`?
func any_hidden(points: Array, eye_at: Vector3) -> bool:
	for p in points:
		if blocked(p, eye_at):
			return true
	return false

## How far forward (footprint z) the building's own mesh reaches between x0 and x1 at heights y0..y1: a porch, a
## veranda, a bow front. -INF where nothing does.
func reach(body: MeshInstance3D, x0: float, x1: float, y0: float, y1: float, z_from: float) -> float:
	var own = _item(body)
	var out := -INF
	if own == null:
		return out
	var x := x0
	while x <= x1 + 0.001:
		for y in [y0, (y0 + y1) * 0.5, y1]:
			var hit := (own.tm as TriangleMesh).intersect_segment(Vector3(x, y, z_from), Vector3(x, y, -1.0))
			if not hit.is_empty():
				out = maxf(out, float(hit.position.z))
		x += 0.2
	return out

func _item(body: MeshInstance3D) -> Variant:
	for it in _items:
		if it.mesh == body.mesh:
			if it.tm == null:
				it.tm = (it.mesh as Mesh).generate_triangle_mesh()
			return it if it.tm != null else null
	return null

# --- the audit (tests, tools/dev/sign_audit.gd) ------------------------------------------------------------

## Every sign's lettering in a built zone (`root` from ZoneBuilder.build), checked from its building's door:
## [{zone, label, text, hidden (share of the lettering hidden), wide (lettering wider than the building),
## off (share of the lettering off screen)}], one per name.
static func audit(z: ZoneData, root: Node3D) -> Array:
	var bodies := []
	for pr in z.props:
		if pr.get("type") != "building":
			continue
		var body := root.get_node_or_null("Building_%d_%d" % [int(pr.x), int(pr.y)])
		if body:
			bodies.append({"pr": pr, "body": body})
	var sight := make(z, bodies)
	var out := []
	for b in bodies:
		var pr: Dictionary = b.pr
		var body: Node3D = b.body
		var door := Signage.door_of(z, pr)
		var dx := int(door[0]) if int(door[0]) >= 0 else int(pr.w) / 2
		var stand := Vector2i(int(pr.x) + dx, int(pr.y) + int(pr.h))
		var eye_at := sight.eye(stand, ZoneBuilder.ground_y(z, stand))
		for l in body.get_children():
			if not (l is Label3D and l.has_meta("caps")):
				continue
			var lab := l as Label3D
			var c: Vector3 = body.position + (lab.get_meta("caps") as Vector3)
			var size: Vector2 = lab.get_meta("size")
			var ax := lab.transform.basis.x.normalized() * size.x * 0.5
			var ay := lab.transform.basis.y.normalized() * size.y * 0.4
			var nz := lab.transform.basis.z.normalized() * 0.02
			var hid := 0.0
			for k in [-1.0, 0.0, 1.0]:
				hid = maxf(hid, sight.hidden_share(c - ax + ay * k + nz, c + ax + ay * k + nz, eye_at, 11))
			out.append({"zone": z.id, "label": str(pr.label), "text": lab.text.replace("\n", " / "), "hidden": hid,
				"wide": size.x > float(pr.w) + 0.01, "off": off_screen(sight._bounds, stand, ZoneBuilder.ground_y(z, stand), c - ax, c + ax)})
	return out

## The share of the line a..b outside a 16:9 view with the player at `stand` (0 when all of it shows).
static func off_screen(bounds: Rect2, stand: Vector2i, gy: float, a: Vector3, b: Vector3) -> float:
	var eye_at := CameraRig.eye_for(bounds, Vector3(stand.x + 0.5, gy, stand.y + 0.5))
	var basis := Basis.from_euler(Vector3(-deg_to_rad(CameraRig.PITCH), 0, 0))
	var t := tan(deg_to_rad(15.0))
	var n := 0
	for i in 11:
		var q := basis.inverse() * (a.lerp(b, i / 10.0) - eye_at)
		var dz := maxf(-q.z, 0.001)
		if absf(q.x / (dz * t * 16.0 / 9.0)) > 0.98 or absf(q.y / (dz * t)) > 0.98:
			n += 1
	return n / 11.0
