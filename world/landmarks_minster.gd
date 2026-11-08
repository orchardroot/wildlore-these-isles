class_name MinsterStyle
extends RefCounted
## York Minster ("minster"): a great Gothic church in pale magnesian limestone, seen from its west end. Twin west
## towers with pinnacles and openwork parapets, the great west window between them over a deep pointed portal,
## buttresses up every face, the nave running back under a lead roof to a broad central tower over the crossing,
## and the transepts reaching out either side with tall lancets (and the Rose Window in the south transept's gable).
## The west window's tracery is known as the Heart of Yorkshire for the heart shape in its head.
## Called from Landmarks.building; same rules: vertex colour, low poly, origin at the footprint's north-west corner,
## door on the south face. Signage asks sign_front() where the name board goes (over the door, under the window).

const STONE := Color("ddd4bc")       # magnesian limestone from Tadcaster, pale cream
const LEAD := Color("6f777c")
const DOOR := Color("3b2a22")
const CENTRE_W := 3.4                # the west front's middle bay: door, board, great window
const TOWER_W := 2.4
const TOWER_D := 2.4
const TOWER_H := 6.6
const BAY_H := 4.8
const FRONT_IN := 0.25               # the west front stands this far back from the footprint's south edge
const BOARD_LO := 1.52
const BOARD_HI := 2.12

## The west front's centre: over the door, kept so the towers stay on the plot.
static func centre(w: int, door_x: int) -> float:
	var c := door_x + 0.5 if door_x >= 0 else w * 0.5
	var half := CENTRE_W * 0.5 + TOWER_W
	return clampf(c, minf(half, w * 0.5), maxf(w - half, w * 0.5))

## Where the name board goes, for Signage.front: flat on the middle bay between the portal and the great window.
static func sign_front(w: int, d: int, door_x: int) -> Dictionary:
	var cx := centre(w, door_x)
	return {"mode": "wall", "z": d - FRONT_IN, "lo": BOARD_LO, "hi": BOARD_HI, "x0": cx - CENTRE_W * 0.5 + 0.12, "x1": cx + CENTRE_W * 0.5 - 0.12}

static func build(st: SurfaceTool, wst: SurfaceTool, w: int, d: int, door_x: int) -> void:
	var cx := centre(w, door_x)
	var fz := d - FRONT_IN
	var x0 := cx - CENTRE_W * 0.5      # the middle bay
	var x1 := cx + CENTRE_W * 0.5
	var lx := maxf(0.0, x0 - TOWER_W)  # the towers' outer faces
	var rx := minf(float(w), x1 + TOWER_W)
	var shade := STONE.darkened(0.06)
	# a paved plinth under the whole church
	Meshes.box(st, Vector3(0, 0, 0), Vector3(w, 0.06, d), Color("bdb5a3"))
	# the transepts across the plot, roofed east-west, their south faces with lancets between buttresses
	var tz0 := 0.9
	var tz1 := d - 2.0
	var th := 3.6
	for side in [[0.25, lx], [rx, w - 0.25]]:
		var a: float = side[0]
		var b: float = side[1]
		if b - a < 0.8:
			continue
		Meshes.box(st, Vector3(a, 0, tz0), Vector3(b - a, th, tz1 - tz0), shade)
		Landmarks._roof_at(st, a, b, tz0, tz1, th, 1.4, LEAD, shade)
		var n := maxi(1, int(floor((b - a) / 1.0)))
		var step := (b - a) / n
		for k in n + 1:
			_buttress(st, a + k * step - 0.12, tz1, th - 0.4, shade)
		for k in n:
			_lancet(st, wst, a + k * step + step * 0.5 - 0.18, 0.7, tz1 + 0.05, 0.36, 1.9, shade.lightened(0.15))
		Meshes.box(st, Vector3(a, th - 0.05, tz1 - 0.05), Vector3(b - a, 0.16, 0.2), STONE.lightened(0.04))  # parapet
	# the Rose Window, high in the south transept (on the right of the west front, as you face it)
	if w - 0.25 - rx > 2.8:
		var mx := (rx + w - 0.25) * 0.5
		var gl := Vector3(mx - 1.3, th, tz1)
		var gr := Vector3(mx + 1.3, th, tz1)
		var ga := Vector3(mx, th + 1.5, tz1)
		var back := Vector3(0, 0, -0.5)
		Meshes._tri(st, gl, ga, gr, shade.lightened(0.03))
		Meshes._quad(st, ga + back, ga, gl, gl + back, LEAD.lightened(0.05))
		Meshes._quad(st, ga, ga + back, gr + back, gr, LEAD.darkened(0.1))
		_rose(st, wst, Vector3(mx, th + 0.5, tz1 + 0.03), 0.4)
	# the nave behind the west front, under a steep lead roof, ridge north to south
	var nh := BAY_H - 0.2
	Meshes.box(st, Vector3(x0 + 0.1, 0, 0.3), Vector3(CENTRE_W - 0.2, nh, fz - 0.3), STONE)
	_gable_roof(st, x0 - 0.05, x1 + 0.05, 0.3, fz - 0.1, nh, 1.5, LEAD, STONE)
	# the central tower over the crossing: broad, square, taller than the west towers, with two tall belfry lights
	var ct := 2.9
	var ch := 7.9
	var cz := tz0 + (tz1 - tz0) * 0.5 - ct * 0.5 - 0.3
	Meshes.box(st, Vector3(cx - ct * 0.5, 0, cz), Vector3(ct, ch, ct), STONE.lightened(0.03))
	for k in 2:
		_lancet(st, wst, cx - 0.75 + k * 1.0, ch - 2.6, cz + ct + 0.05, 0.5, 1.8, STONE.lightened(0.18))
	for p in [Vector2(0, 0), Vector2(ct - 0.32, 0), Vector2(0, ct - 0.32), Vector2(ct - 0.32, ct - 0.32)]:
		_buttress(st, cx - ct * 0.5 + p.x, cz + p.y + 0.32, ch - 0.6, STONE)
	_parapet(st, cx - ct * 0.5, cx + ct * 0.5, cz + ct - 0.2, ch, STONE)
	# the west front's middle bay: a gable over the great west window, a deep pointed portal below
	Meshes.box(st, Vector3(x0, 0, fz - 1.0), Vector3(CENTRE_W, BAY_H, 1.0), STONE)
	var apex := Vector3(cx, BAY_H + 1.25, fz)
	Meshes._tri(st, Vector3(x0, BAY_H, fz), apex, Vector3(x1, BAY_H, fz), STONE.lightened(0.03))
	Meshes._quad(st, apex + Vector3(0, 0, -1.0), apex, Vector3(x0, BAY_H, fz), Vector3(x0, BAY_H, fz - 1.0), STONE.darkened(0.04))
	Meshes._quad(st, apex, apex + Vector3(0, 0, -1.0), Vector3(x1, BAY_H, fz - 1.0), Vector3(x1, BAY_H, fz), STONE.darkened(0.08))
	Meshes.box(st, Vector3(cx - 0.08, BAY_H + 1.2, fz - 0.12), Vector3(0.16, 0.55, 0.16), STONE.lightened(0.08))  # the gable cross-pinnacle
	# the great west window: tall and pointed, mullions, and the heart in its head
	var gw := 1.9
	var gy := 2.3
	var gh := 1.75
	_lancet(st, wst, cx - gw * 0.5, gy, fz + 0.06, gw, gh, STONE.lightened(0.12))
	for k in [-0.48, 0.0, 0.48]:
		Meshes.box(st, Vector3(cx + k - 0.035, gy, fz - 0.01), Vector3(0.07, gh + 0.3, 0.05), STONE.lightened(0.12))
	Meshes.box(st, Vector3(cx - gw * 0.5 + 0.05, gy + gh * 0.52, fz - 0.01), Vector3(gw - 0.1, 0.05, 0.05), STONE.lightened(0.12))  # transom
	_heart(st, Vector3(cx, gy + gh + 0.42, fz + 0.03), 0.2, STONE.lightened(0.12))
	# the portal: an arch of moulded orders round a pair of oak doors
	var px := cx - 0.62
	for k in 3:
		var o := 0.12 * k
		Meshes.box(st, Vector3(px + o - 0.1, 0, fz + 0.12 - o * 0.5), Vector3(0.12, 1.32, 0.1), STONE.lightened(0.06 - k * 0.03))
		Meshes.box(st, Vector3(cx + 0.62 - o - 0.02, 0, fz + 0.12 - o * 0.5), Vector3(0.12, 1.32, 0.1), STONE.lightened(0.06 - k * 0.03))
	_arch(st, cx, 1.32, fz + 0.2, 0.72, 0.36, STONE.lightened(0.08))
	if door_x >= 0:
		Meshes.box(st, Vector3(cx - 0.4, 0, fz - 0.02), Vector3(0.8, 1.32, 0.08), DOOR)
		Meshes.box(st, Vector3(cx - 0.01, 0.05, fz + 0.06), Vector3(0.02, 1.22, 0.01), DOOR.darkened(0.3))
		Meshes._tri(st, Vector3(cx - 0.4, 1.32, fz + 0.06), Vector3(cx, 1.6, fz + 0.06), Vector3(cx + 0.4, 1.32, fz + 0.06), DOOR.darkened(0.15))
	# the twin west towers, stepped buttresses up their corners, belfry lights, parapets and pinnacles
	for tx in [lx, x1]:
		var tw := minf(TOWER_W, (x0 - lx) if tx == lx else (rx - x1))
		if tw < 1.0:
			continue
		var tz := fz - TOWER_D
		Meshes.box(st, Vector3(tx, 0, tz), Vector3(tw, TOWER_H, TOWER_D + 0.1), STONE.lightened(0.02))
		for bx in [tx - 0.06, tx + tw - 0.3]:
			_buttress(st, bx, fz + 0.1, TOWER_H - 0.3, STONE)
		_lancet(st, wst, tx + tw * 0.5 - 0.3, 1.1, fz + 0.15, 0.6, 1.5, STONE.lightened(0.15))
		for k in 2:
			_lancet(st, wst, tx + tw * 0.5 - 0.62 + k * 0.72, 4.15, fz + 0.15, 0.5, 1.5, STONE.lightened(0.15))
		Meshes.box(st, Vector3(tx - 0.05, 3.55, fz + 0.06), Vector3(tw + 0.1, 0.1, 0.12), STONE.lightened(0.05))  # string course
		_parapet(st, tx, tx + tw, fz - 0.05, TOWER_H, STONE)
		for p in [tx, tx + tw * 0.5 - 0.11, tx + tw - 0.22]:
			for pz in [tz + 0.02, fz - 0.22]:
				Meshes.box(st, Vector3(p, TOWER_H, pz), Vector3(0.22, 0.85, 0.22), STONE.lightened(0.06))
				Meshes.box(st, Vector3(p + 0.06, TOWER_H + 0.85, pz + 0.06), Vector3(0.1, 0.45, 0.1), STONE.lightened(0.1))
	# buttresses either side of the middle bay, rising to pinnacles at the gable's foot
	for bx in [x0 - 0.02, x1 - 0.26]:
		_buttress(st, bx, fz + 0.2, BAY_H, STONE)
		Meshes.box(st, Vector3(bx + 0.04, BAY_H, fz - 0.12), Vector3(0.2, 0.7, 0.2), STONE.lightened(0.08))

## A stepped buttress against a south face at z, its left edge at x: deep at the foot, shallower higher up.
static func _buttress(st: SurfaceTool, x: float, z: float, h: float, col: Color) -> void:
	Meshes.box(st, Vector3(x, 0, z - 0.2), Vector3(0.28, h * 0.45, 0.42), col.darkened(0.05))
	Meshes.box(st, Vector3(x + 0.02, h * 0.45, z - 0.2), Vector3(0.24, h * 0.35, 0.3), col.darkened(0.03))
	Meshes.box(st, Vector3(x + 0.04, h * 0.8, z - 0.2), Vector3(0.2, h * 0.2, 0.18), col)

## A tall pointed (lancet) window on a south face at z: frame into the body, glass (lit at night) into the
## windows mesh, with a pointed head over the upright part.
static func _lancet(st: SurfaceTool, wst: SurfaceTool, x: float, y: float, z: float, ww: float, wh: float, frame: Color) -> void:
	var rise := ww * 0.6
	Meshes.box(st, Vector3(x, y - 0.06, z - 0.07), Vector3(ww, wh + 0.06, 0.04), frame)
	Meshes._tri(st, Vector3(x, y + wh, z - 0.03), Vector3(x + ww * 0.5, y + wh + rise + 0.06, z - 0.03), Vector3(x + ww, y + wh, z - 0.03), frame)
	var glass := Landmarks.window_colour(Landmarks._wr)
	var gx := x + 0.05
	var gw := ww - 0.1
	Meshes.box(wst, Vector3(gx, y, z - 0.065), Vector3(gw, wh - 0.02, 0.04), glass)
	Meshes._tri(wst, Vector3(gx, y + wh - 0.02, z - 0.024), Vector3(gx + gw * 0.5, y + wh + rise - 0.04, z - 0.024), Vector3(gx + gw, y + wh - 0.02, z - 0.024), glass)

## A pointed arch hood: two sloping stones meeting at the top, over a span of `half` either side of cx.
static func _arch(st: SurfaceTool, cx: float, y: float, z: float, half: float, rise: float, col: Color) -> void:
	var t := 0.1
	Meshes._quad(st, Vector3(cx - half, y + t, z), Vector3(cx, y + rise + t, z), Vector3(cx, y + rise, z), Vector3(cx - half, y, z), col)
	Meshes._quad(st, Vector3(cx, y + rise + t, z), Vector3(cx + half, y + t, z), Vector3(cx + half, y, z), Vector3(cx, y + rise, z), col)

## A heart in stone tracery, centred at c on a south face: two lobes and a point.
static func _heart(st: SurfaceTool, c: Vector3, r: float, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		var lobe := c + Vector3(sx * r * 0.5, r * 0.3, 0)
		for i in 8:
			var a0 := TAU * i / 8.0
			var a1 := TAU * (i + 1) / 8.0
			Meshes._tri(st, lobe, lobe + Vector3(cos(a1), sin(a1), 0) * r * 0.55, lobe + Vector3(cos(a0), sin(a0), 0) * r * 0.55, col)
	Meshes._tri(st, c + Vector3(-r * 1.02, r * 0.25, 0), c + Vector3(r * 1.02, r * 0.25, 0), c + Vector3(0, -r * 0.9, 0), col)

## A rose window: a ring of stone round a wheel of lights, on a south face at c.
static func _rose(st: SurfaceTool, wst: SurfaceTool, c: Vector3, r: float) -> void:
	var glass := Landmarks.window_colour(Landmarks._wr)
	var n := 16
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector3(cos(a0), sin(a0), 0)
		var p1 := Vector3(cos(a1), sin(a1), 0)
		Meshes._quad(st, c + p1 * (r + 0.1), c + p0 * (r + 0.1), c + p0 * r, c + p1 * r, STONE.lightened(0.1))
		Meshes._tri(wst, c - Vector3(0, 0, 0.01), c + p1 * r - Vector3(0, 0, 0.01), c + p0 * r - Vector3(0, 0, 0.01), glass)
	for i in 8:  # spokes
		var a := TAU * i / 8.0
		var p := Vector3(cos(a), sin(a), 0)
		var q := Vector3(-p.y, p.x, 0) * 0.025
		Meshes._quad(st, c + q + Vector3(0, 0, 0.01), c + p * r + q + Vector3(0, 0, 0.01), c + p * r - q + Vector3(0, 0, 0.01), c - q + Vector3(0, 0, 0.01), STONE.lightened(0.1))

## A parapet of little merlons along a south face at z, from a to b, standing on height y.
static func _parapet(st: SurfaceTool, a: float, b: float, z: float, y: float, col: Color) -> void:
	Meshes.box(st, Vector3(a - 0.04, y - 0.12, z - 0.02), Vector3(b - a + 0.08, 0.14, 0.22), col.lightened(0.05))
	var x := a
	while x < b - 0.15:
		Meshes.box(st, Vector3(x, y, z), Vector3(0.15, 0.22, 0.16), col.lightened(0.05))
		x += 0.3

## A pitched roof with its ridge running north to south (gable to the front), over x0..x1 and z0..z1 at height h.
static func _gable_roof(st: SurfaceTool, x0: float, x1: float, z0: float, z1: float, h: float, rise: float, roof: Color, wall: Color) -> void:
	var xm := (x0 + x1) * 0.5
	var r0 := Vector3(xm, h + rise, z0)
	var r1 := Vector3(xm, h + rise, z1)
	Meshes._quad(st, r0, r1, Vector3(x0, h, z1), Vector3(x0, h, z0), roof)
	Meshes._quad(st, r1, r0, Vector3(x1, h, z0), Vector3(x1, h, z1), roof.darkened(0.15))
	Meshes._tri(st, Vector3(x1, h, z0), r0, Vector3(x0, h, z0), wall.darkened(0.1))
