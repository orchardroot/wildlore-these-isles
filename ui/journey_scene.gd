class_name JourneyScene
extends CanvasLayer
## One travel scene, flat and side-on like a picture book: the view from a train window, a ferry crossing,
## or a ride on Bran's Raven over the map. It plays for Journey.scene_seconds and always ends; confirm or
## cancel skips it. Each layer's shapes are drawn once and then only slid about, so it is cheap to show.
## It never moves the player or warps: Journey runs it between the usual fades.

signal finished

const SKIP_ACTIONS := ["confirm", "cancel"]
## Scenery by destination (Journey.scheme_for): far hills, near hills, field colours, hedges or walls,
## house walls and roofs, trees, how hilly, how many houses, and extras.
const SCHEMES := {
	"lowland": {"far": "8b9fb0", "mid": "6f9a4c", "fields": ["7fae55", "9bbf5e", "d8c25e", "a98a5a", "5f8f45", "8fb860"],
		"hedge": "3e6b34", "walls": ["b0573f", "a24a35", "c87a55"], "roof": "5a4a48", "tree": "4c7a3a",
		"hills": 0.05, "far_hills": 0.06, "houses": 0.5, "spire": true},
	"moor": {"far": "7d7690", "mid": "8a7a52", "fields": ["8e6f7c", "9a8460", "6f7a48", "a08a5c", "7d6a72"],
		"hedge": "9a968a", "walls": ["8f8a7e", "a39d8f"], "roof": "4b4a50", "tree": "56603c",
		"hills": 0.1, "far_hills": 0.12, "houses": 0.2, "sheep": true},
	"wales": {"far": "6f8296", "mid": "5f8a48", "fields": ["6b9a4e", "5d8a44", "7ea85a", "86a45e"],
		"hedge": "3d5e32", "walls": ["e8e2d4", "9aa0a6"], "roof": "3c4450", "tree": "3f6a36",
		"hills": 0.13, "far_hills": 0.22, "houses": 0.25, "sheep": true, "peaks": true},
	"highland": {"far": "5c6088", "mid": "6d7a4a", "fields": ["7b6a5a", "6d7a4a", "8a7a62", "75705a"],
		"hedge": "4a4a3a", "walls": ["efeae0"], "roof": "3a3d48", "tree": "2f4d34",
		"hills": 0.12, "far_hills": 0.3, "houses": 0.12, "peaks": true, "snow": true, "pines": true, "loch": true},
	"ireland": {"far": "7d95a0", "mid": "4f9a48", "fields": ["4fa04a", "63b052", "3f8a3e", "74b85e"],
		"hedge": "9a968a", "walls": ["f2efe6", "efe4c8"], "roof": "6a5a48", "tree": "3d7a3a",
		"hills": 0.07, "far_hills": 0.1, "houses": 0.3},
	"coast": {"far": "8aa0a8", "mid": "7a9a52", "fields": ["86a65a", "9bbf5e", "c9b25a", "7a9a52"],
		"hedge": "9a968a", "walls": ["f2efe6", "e8d8b0"], "roof": "4a5058", "tree": "5a7a3a",
		"hills": 0.06, "far_hills": 0.05, "houses": 0.3, "sea": true},
	"city": {"far": "8890a0", "mid": "6f8a52", "fields": ["6f9a4c", "7fa055", "5f8a45"],
		"hedge": "3e6b34", "walls": ["9a4a3a", "b0573f", "8a8f99", "a0705a"], "roof": "3e3a3e", "tree": "4c7a3a",
		"hills": 0.03, "far_hills": 0.03, "houses": 1.0, "towers": true},
}
const SKY := {
	"dawn": ["8a8fc0", "f5c49a"], "day": ["5f9fd8", "cfe6f2"], "dusk": ["3f467e", "f09a6a"], "night": ["0b1230", "26315a"],
}
const LAND_TINT := {"dawn": Color(1.0, 0.88, 0.84), "day": Color(1, 1, 1), "dusk": Color(0.9, 0.72, 0.7), "night": Color(0.3, 0.35, 0.55)}
const GREY_WEATHER := ["drizzle", "downpour", "gale", "fog"]
const WINDOW_LIT := Color("ffd27a")
const RAVEN_ROWS := 86      # the battle sprite's top 86 of 96 rows: the rest is the grey perch it stands on in battle

var kind := "train"
var info: Dictionary = {}
var mode := "on"
var phase := "day"          # GameClock phase, for the light
var weather := "clear"
var sprite_id := "player_a"
var look: Dictionary = {}  # the player's recipe (Looks); painted through LookArt when set
var duration := 3.0
var elapsed := 0.0
var playing := false
var done := false
var skipped := false
var hold_at := -1.0         # dev screenshots: hold the scene this far through (0..1) and never finish

var _size := Vector2(1280, 720)
var _root: Control
var _slides: Array = []     # [Painter, px per unit of travel, wrap width]
var _rng := RandomNumberGenerator.new()
var _scheme: Dictionary = {}
var _cues := {}
var _built := false
var _loop: AudioStreamPlayer
# train
var _rain: Painter
var _passing: Painter
# ferry
var _boat: Sprite2D
var _wake: Painter
var _deck: Sprite2D
var _quay_out: Painter
var _quay_in: Painter
var _coast_out: Painter
var _coast_in: Painter
var _waves: Array = []
var _gulls: Array = []      # Line2D Vs
var _gull_base: Array = []
# fly
var _map: MapView
var _raven: Sprite2D
var _rider: Sprite2D
var _shadow: Polygon2D
var _raven_frames: Array = []
var _clouds: Array = []     # [Painter, drift factor]
var _from_pt := Vector2.ZERO
var _to_pt := Vector2.ZERO
var _map_k := 2.4

func setup(k: String, inf: Dictionary, m: String) -> void:
	kind = k
	info = inf
	mode = m
	duration = Journey.scene_seconds(kind, mode)
	if duration <= 0.0:
		duration = 2.0
	_scheme = SCHEMES.get(Journey.scheme_for(str(info.get("to", ""))), SCHEMES.lowland)
	_rng.seed = hash(str(info.get("to", "")) + kind)

func _ready() -> void:
	layer = 90  # over the world and menus, under Router's fade
	process_mode = Node.PROCESS_MODE_ALWAYS

func wants_skip(ev: InputEvent) -> bool:
	if not ev.is_pressed() or ev.is_echo():
		return false
	for a in SKIP_ACTIONS:
		if ev.is_action_pressed(a):
			return true
	return false

func _input(ev: InputEvent) -> void:
	if done or not wants_skip(ev):
		return
	get_viewport().set_input_as_handled()
	skip()

func skip() -> void:
	skipped = true
	_finish()

func _finish() -> void:
	if done:
		return
	done = true
	playing = false
	if _loop:
		_loop.stop()
	finished.emit()

## Starts the scene (building it if need be). Does nothing if it was already skipped.
func play_now() -> void:
	if done:
		return
	if not _built:
		build_view(get_viewport().get_visible_rect().size if is_inside_tree() else _size)
	playing = true
	_root.visible = true
	_start_sound()
	advance(0.0)

func _process(delta: float) -> void:
	advance(minf(delta, 0.1))

## Moves the scene on by `delta` seconds (tests call this directly), ending it when its time is up.
func advance(delta: float) -> void:
	if done or not playing:
		return
	elapsed = duration * hold_at if hold_at >= 0.0 else elapsed + delta
	match kind:
		"train":
			_pose_train()
		"ferry":
			_pose_ferry()
		"fly":
			_pose_fly()
	if hold_at < 0.0 and elapsed >= duration:
		_finish()

# --- building ------------------------------------------------------------------------------------------------

func build_view(sz: Vector2) -> void:
	_size = Vector2(maxf(sz.x, 320.0), maxf(sz.y, 240.0))
	_root = Control.new()
	_root.size = _size
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	match kind:
		"train":
			_build_train()
		"ferry":
			_build_ferry()
		_:
			_build_fly()
	_built = true

func _painter(parent: Node, wrap := 0.0) -> Painter:
	var p := Painter.new()
	p.repeat = Vector2(wrap, 0)
	parent.add_child(p)
	return p

func _slide(p: Painter, speed: float, wrap: float) -> void:
	_slides.append([p, speed, wrap])

func _tint(c: Color) -> Color:
	var t: Color = LAND_TINT.get(phase, Color.WHITE)
	var out := Color(c.r * t.r, c.g * t.g, c.b * t.b, c.a)
	if weather in GREY_WEATHER:
		var g := out.get_luminance()
		out = out.lerp(Color(g, g, g * 1.05, out.a), 0.35) * Color(0.88, 0.88, 0.9, 1.0)
	if weather == "frost":
		out = out.lerp(Color(0.92, 0.94, 0.98, out.a), 0.3)
	return out

func _c(hex: String) -> Color:
	return _tint(Color(hex))

func _sky_colours() -> Array:
	var s: Array = SKY.get(phase, SKY.day)
	var top := Color(s[0])
	var bottom := Color(s[1])
	if weather in GREY_WEATHER:
		top = top.lerp(Color("8a929c") * (0.4 if phase == "night" else 1.0), 0.65)
		bottom = bottom.lerp(Color("b8bec4") * (0.4 if phase == "night" else 1.0), 0.65)
	return [top, bottom]

func _sky(parent: Node, horizon: float) -> void:
	var p := _painter(parent)
	var sc := _sky_colours()
	p.grad(PackedVector2Array([Vector2(0, 0), Vector2(_size.x, 0), Vector2(_size.x, horizon), Vector2(0, horizon)]),
		PackedColorArray([sc[0], sc[0], sc[1], sc[1]]))
	p.rect(Rect2(0, horizon, _size.x, _size.y - horizon), sc[1])
	if weather in GREY_WEATHER:
		return
	if phase == "night":
		for i in 40:
			var at := Vector2(_rng.randf() * _size.x, _rng.randf() * horizon * 0.8)
			p.rect(Rect2(at, Vector2(2, 2)), Color(1, 1, 0.9, _rng.randf_range(0.4, 0.9)))
		p.circle(Vector2(_size.x * 0.78, horizon * 0.3), _size.y * 0.04, Color("f2ecd8"))
	else:
		var sun := Vector2(_size.x * (0.2 if phase == "dawn" else 0.8 if phase == "dusk" else 0.7), horizon * (0.75 if phase != "day" else 0.25))
		p.circle(sun, _size.y * 0.075, Color(1, 0.95, 0.8, 0.25))
		p.circle(sun, _size.y * 0.05, Color("fff4d0") if phase == "day" else Color("ffc27a"))

## A cloud layer, wrapping `w` wide.
func _cloud_layer(parent: Node, w: float, top: float, bottom: float, count: int, alpha: float) -> Painter:
	var p := _painter(parent, w)
	var col := Color(1, 1, 1).lerp(_sky_colours()[1], 1.0 - alpha)
	if weather in GREY_WEATHER:
		col = Color("c4c9ce")
	if phase == "night":
		col = Color(0.32, 0.36, 0.5)
	elif phase == "dusk" or phase == "dawn":
		col = col.lerp(Color("f5b896"), 0.4)
	for i in count:
		var c := Vector2((i + _rng.randf() * 0.6) * w / count, _rng.randf_range(top, bottom))
		var r := _size.y * _rng.randf_range(0.03, 0.06)
		for j in 4:
			p.poly(_ellipse(c + Vector2((j - 1.5) * r * 0.9, -absf(j - 1.5) * r * -0.25 - (r * 0.3 if j in [1, 2] else 0.0)), r, r * 0.6), col)
	return p

static func _ellipse(c: Vector2, rx: float, ry: float, n := 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

## A smooth, wrapping 0..1 wave along a strip (whole sine periods only, so both ends meet).
func _wave_fn(sharp: bool) -> Array:
	var terms := []
	for k in [1, 2, 3, 5, 7]:
		terms.append([k, _rng.randf() * TAU, _rng.randf_range(0.4, 1.0) / sqrt(k)])
	return [terms, sharp]

static func _wave(u: float, fn: Array) -> float:
	var s := 0.0
	var tot := 0.0
	for t in fn[0]:
		if fn[1]:
			s += (1.0 - absf(sin(PI * t[0] * u + t[1]))) * t[2]
		else:
			s += (sin(TAU * t[0] * u + t[1]) * 0.5 + 0.5) * t[2]
		tot += t[2]
	return s / tot

## A wrapping ridge: points along the top, closed down to `floor_y`.
func _ridge_pts(w: float, base: float, amp: float, fn: Array, floor_y: float, step := 16.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := int(ceil(w / step))
	for i in n + 1:
		var x := minf(i * step, w)
		pts.append(Vector2(x, base - amp * _wave(x / w, fn)))
	pts.append(Vector2(w, floor_y))
	pts.append(Vector2(0, floor_y))
	return pts

func _house(p: Painter, x: float, ground: float, s: float, wall: Color, roof: Color, lit: bool) -> void:
	var w := s * _rng.randf_range(0.9, 1.4)
	var h := s * _rng.randf_range(0.6, 0.9)
	p.rect(Rect2(x, ground - h, w, h + s * 0.2), wall)
	p.poly(PackedVector2Array([Vector2(x - s * 0.08, ground - h), Vector2(x + w * 0.5, ground - h - s * 0.45), Vector2(x + w + s * 0.08, ground - h)]), roof)
	var glass := WINDOW_LIT if lit else _c("9fb6c8")
	p.rect(Rect2(x + w * 0.2, ground - h * 0.7, s * 0.16, s * 0.16), glass)
	p.rect(Rect2(x + w * 0.62, ground - h * 0.7, s * 0.16, s * 0.16), glass)
	if _rng.randf() < 0.6:
		p.rect(Rect2(x + w * 0.7, ground - h - s * 0.4, s * 0.1, s * 0.25), roof)  # chimney

func _tree(p: Painter, x: float, ground: float, s: float, col: Color, pine: bool) -> void:
	p.rect(Rect2(x - s * 0.06, ground - s * 0.5, s * 0.12, s * 0.5), _c("5a4636"))
	if pine:
		p.poly(PackedVector2Array([Vector2(x - s * 0.35, ground - s * 0.35), Vector2(x, ground - s * 1.5), Vector2(x + s * 0.35, ground - s * 0.35)]), col)
	else:
		p.poly(_ellipse(Vector2(x, ground - s * 0.75), s * 0.42, s * 0.38, 10), col)
		p.poly(_ellipse(Vector2(x - s * 0.1, ground - s * 0.85), s * 0.22, s * 0.18, 8), col.lightened(0.12))

func _lit() -> bool:
	return phase in ["night", "dusk"]

# --- the train -------------------------------------------------------------------------------------------------

func _build_train() -> void:
	var W := _size.x
	var H := _size.y
	var horizon := H * 0.46
	var strip := ceilf(W * 2.0)
	var outside := Control.new()
	outside.size = _size
	outside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(outside)
	_sky(outside, horizon)
	_slide(_cloud_layer(outside, strip, H * 0.12, H * 0.3, 7, 0.75), 6.0 + (30.0 if weather == "gale" else 0.0), strip)
	# far hills (or a sea glimpse and low headlands, or a skyline)
	var far := _painter(outside, strip)
	var sch := _scheme
	if sch.get("sea", false):
		far.rect(Rect2(0, horizon - H * 0.02, strip, H * 0.12), _c("4f7fa0"))
		for i in 30:
			far.rect(Rect2(_rng.randf() * strip, horizon + _rng.randf() * H * 0.08, H * 0.03, 2), _c("cfe0ea"))
	var far_fn := _wave_fn(sch.get("peaks", false))
	var far_pts := _ridge_pts(strip, horizon + H * 0.02, H * float(sch.far_hills) * 1.6, far_fn, H)
	far.poly(far_pts, _c(sch.far))
	if sch.get("snow", false) and phase != "night":
		_snow_caps(far, strip, horizon + H * 0.02, H * float(sch.far_hills) * 1.6, far_fn)
	if sch.get("towers", false):
		var x := 0.0
		while x < strip:
			var bw := H * _rng.randf_range(0.03, 0.07)
			var bh := H * _rng.randf_range(0.04, 0.16)
			far.rect(Rect2(x, horizon + H * 0.03 - bh, bw, bh + H * 0.02), _c("7a8294"))
			if _lit():
				for j in int(bh / (H * 0.03)):
					far.rect(Rect2(x + bw * 0.3, horizon + H * 0.01 - j * H * 0.03, bw * 0.15, H * 0.01), WINDOW_LIT)
			x += bw + H * _rng.randf_range(0.0, 0.05)
	_slide(far, 28.0, strip)
	# rolling middle distance: patchwork fields, hedges or walls, trees, houses, sheep
	var mid := _painter(outside, strip)
	var base := horizon + H * 0.12
	var amp := H * float(sch.hills) * 1.6
	var fn := _wave_fn(false)
	mid.poly(_ridge_pts(strip, base, amp, fn, H), _c(sch.mid))
	var ground := func(x: float) -> float: return base - amp * _wave(fposmod(x, strip) / strip, fn)
	var fields: Array = sch.fields
	for row in 3:
		var d0 := H * (0.012 + row * 0.045)
		var d1 := d0 + H * 0.045
		var x := 0.0
		while x < strip - 1.0:
			var fw := minf(H * _rng.randf_range(0.18, 0.36), strip - x)
			var pts := PackedVector2Array()
			for k in 5:
				var xx := x + fw * k / 4.0
				pts.append(Vector2(xx, ground.call(xx) + d0 + (k - 2) * row * 0.6))
			for k in 5:
				var xx := x + fw * (4 - k) / 4.0
				pts.append(Vector2(xx, ground.call(xx) + d1))
			mid.poly(pts, _c(fields[_rng.randi() % fields.size()]))
			mid.line(PackedVector2Array([pts[4], pts[5]]), _c(sch.hedge), 3.0)
			x += fw
		var edge := PackedVector2Array()
		for k in int(strip / 32.0) + 1:
			var xx := minf(k * 32.0, strip)
			edge.append(Vector2(xx, ground.call(xx) + d1))
		mid.line(edge, _c(sch.hedge), 3.0)
	if sch.get("loch", false):
		var lx := strip * 0.3
		mid.poly(_ellipse(Vector2(lx, ground.call(lx) + H * 0.03), H * 0.22, H * 0.025, 18), _c("5a7fa8"))
	var walls: Array = sch.walls
	var x2 := H * 0.1
	while x2 < strip - H * 0.2:
		var g: float = ground.call(x2)
		var roll := _rng.randf()
		if roll < float(sch.houses) * 0.35:
			var n := 2 + _rng.randi() % 4
			for k in n:
				var hx := x2 + k * H * 0.07
				if hx < strip - H * 0.1:
					_house(mid, hx, ground.call(hx) + H * 0.01, H * 0.045, _c(walls[_rng.randi() % walls.size()]), _c(sch.roof), _lit())
			if sch.get("spire", false) and _rng.randf() < 0.5:
				var sx := x2 + n * H * 0.07
				var sg: float = ground.call(sx)
				mid.rect(Rect2(sx, sg - H * 0.07, H * 0.03, H * 0.08), _c("a39d8f"))
				mid.poly(PackedVector2Array([Vector2(sx - 2, sg - H * 0.07), Vector2(sx + H * 0.015, sg - H * 0.15), Vector2(sx + H * 0.03 + 2, sg - H * 0.07)]), _c("6a6670"))
			x2 += n * H * 0.07 + H * 0.15
		elif roll < 0.75:
			_tree(mid, x2, g + H * 0.012, H * _rng.randf_range(0.05, 0.075), _c(sch.tree), sch.get("pines", false))
			x2 += H * _rng.randf_range(0.04, 0.14)
		else:
			if sch.get("sheep", false):
				for k in 3:
					var sx := x2 + k * H * 0.025
					mid.poly(_ellipse(Vector2(sx, ground.call(sx) + H * 0.03), H * 0.01, H * 0.007, 8), _c("f2efe6"))
			x2 += H * _rng.randf_range(0.08, 0.2)
	_slide(mid, 150.0, strip)
	if weather == "fog":
		var fog := ColorRect.new()
		fog.size = _size
		fog.color = Color(0.85, 0.87, 0.9, 0.45)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outside.add_child(fog)
	# the train passing the other way (On only): a quick blur of carriages
	if mode == "on":
		_passing = _painter(outside)
		var livery := _c("a3262a" if str(info.get("to", "")).length() % 2 == 0 else "3b6fa8")
		var car := H * 0.55
		for k in 4:
			var cx := k * (car + H * 0.02)
			_passing.rect(Rect2(cx, H * 0.36, car, H * 0.34), livery)
			_passing.rect(Rect2(cx, H * 0.36, car, H * 0.04), _c("e8e2d4"))
			for j in 4:
				_passing.rect(Rect2(cx + car * (0.08 + j * 0.23), H * 0.43, car * 0.17, H * 0.1), WINDOW_LIT if _lit() else _c("9fb6c8"))
		_passing.position.x = W * 3.0
	# the embankment and the telegraph poles, flicking by
	var near := _painter(outside, strip)
	var bank := H * 0.66
	near.poly(_ridge_pts(strip, bank, H * 0.02, _wave_fn(false), H), _c("4d7a3a"))
	near.rect(Rect2(0, bank + H * 0.03, strip, H), _c("3f6a30"))
	var gap := H * 0.5
	var count := int(strip / gap)
	gap = strip / count
	var wire := _c("2a2a2a")
	for i in count:
		var px := i * gap + gap * 0.5
		near.rect(Rect2(px - 4, H * 0.16, 8, bank - H * 0.16 + H * 0.02), _c("5a4030"))
		near.rect(Rect2(px - H * 0.05, H * 0.19, H * 0.1, 5), _c("5a4030"))
		for w_off in [-H * 0.04, H * 0.04]:
			var sag := PackedVector2Array()
			for k in 9:
				var u := k / 8.0
				sag.append(Vector2(px + u * gap, H * 0.19 + 2.0 + (6.0 if w_off > 0.0 else 0.0) + sin(PI * u) * H * 0.035))
			near.line(sag, wire, 2.0)
		if _rng.randf() < 0.5 and i < count - 1:  # (not across the wrap, where the next copy's bank would cut it)
			near.poly(_ellipse(Vector2(px + gap * 0.5, bank + H * 0.01), H * 0.05, H * 0.03, 10), _c("355c2c"))
	_slide(near, 1000.0, strip)
	if weather in ["drizzle", "downpour", "gale"]:
		_rain = _painter(outside)
		_rain.repeat = Vector2(0, H)
		var drops := 40 if weather == "downpour" else 18
		for i in drops:
			var at := Vector2(_rng.randf() * W, _rng.randf() * H)
			_rain.line(PackedVector2Array([at, at + Vector2(-H * 0.03, H * 0.06)]), Color(0.85, 0.9, 1.0, 0.35), 2.0)
		for i in drops:
			_rain.circle(Vector2(_rng.randf() * W, _rng.randf() * H), _rng.randf_range(2.0, 4.0), Color(0.9, 0.95, 1.0, 0.3))
	_window_frame()
	_caption("Next stop: %s" % Travel.town_name(str(info.get("to", ""))))

## The carriage: a wall round a round-cornered window, a table with a cup of tea, a glint on the glass.
func _window_frame() -> void:
	var W := _size.x
	var H := _size.y
	var win := Rect2(W * 0.07, H * 0.09, W * 0.86, H * 0.63)
	var r := H * 0.06
	var f := _painter(_root)
	var wall := _c("d9cdb0") if phase != "night" else Color("6a6458")
	var glint := Color(1, 1, 1, 0.07)
	f.poly(PackedVector2Array([win.position + Vector2(win.size.x * 0.12, 0), win.position + Vector2(win.size.x * 0.2, 0),
		win.position + Vector2(win.size.x * 0.08, win.size.y), win.position + Vector2(0.0, win.size.y)]), glint)
	f.poly(PackedVector2Array([win.position + Vector2(win.size.x * 0.24, 0), win.position + Vector2(win.size.x * 0.27, 0),
		win.position + Vector2(win.size.x * 0.15, win.size.y), win.position + Vector2(win.size.x * 0.12, win.size.y)]), glint)
	f.rect(Rect2(0, 0, W, win.position.y), wall)
	f.rect(Rect2(0, win.end.y, W, H - win.end.y), wall)
	f.rect(Rect2(0, win.position.y, win.position.x, win.size.y), wall)
	f.rect(Rect2(win.end.x, win.position.y, W - win.end.x, win.size.y), wall)
	for corner in [[win.position, Vector2(1, 1)], [Vector2(win.end.x, win.position.y), Vector2(-1, 1)],
			[win.end, Vector2(-1, -1)], [Vector2(win.position.x, win.end.y), Vector2(1, -1)]]:
		var c: Vector2 = corner[0]
		var d: Vector2 = corner[1]
		f.poly(_fillet(c, d, r), wall)
	# the rubber seal round the glass
	var seal := PackedVector2Array()
	for corner in [[Vector2(win.position.x + r, win.position.y + r), PI], [Vector2(win.end.x - r, win.position.y + r), PI * 1.5],
			[Vector2(win.end.x - r, win.end.y - r), 0.0], [Vector2(win.position.x + r, win.end.y - r), PI * 0.5]]:
		for k in 7:
			var a: float = corner[1] + k / 6.0 * PI * 0.5
			seal.append(corner[0] + Vector2(cos(a), sin(a)) * r)
	seal.append(seal[0])
	f.line(seal, Color("2a2a30"), 7.0)
	# a table under the window, and a cup of tea on it
	var top := H * 0.8
	f.rect(Rect2(W * 0.15, top, W * 0.7, H * 0.05), _c("8a5a3a"))
	f.rect(Rect2(W * 0.15, top, W * 0.7, H * 0.008), _c("b07a52"))
	f.rect(Rect2(W * 0.15, top + H * 0.05, W * 0.7, H), _c("5a3a28"))
	var cup := Vector2(W * 0.68, top)
	f.poly(_ellipse(cup + Vector2(0, -H * 0.004), H * 0.05, H * 0.012), Color(0, 0, 0, 0.2))
	f.poly(PackedVector2Array([cup + Vector2(-H * 0.035, -H * 0.075), cup + Vector2(H * 0.035, -H * 0.075),
		cup + Vector2(H * 0.028, -H * 0.005), cup + Vector2(-H * 0.028, -H * 0.005)]), _c("f2efe6"))
	f.poly(_ellipse(cup + Vector2(0, -H * 0.075), H * 0.035, H * 0.009), _c("8a5a3a"))
	var handle := PackedVector2Array()
	for k in 8:
		var a := -PI * 0.5 + k / 7.0 * PI
		handle.append(cup + Vector2(H * 0.032, -H * 0.042) + Vector2(cos(a), sin(a)) * H * 0.018)
	f.line(handle, _c("f2efe6"), 4.0)
	f.rect(Rect2(W * 0.3, top - H * 0.006, H * 0.11, H * 0.006), _c("e8c872"))  # the ticket

## The wall-coloured scrap between a window's square corner and its rounded one.
static func _fillet(c: Vector2, d: Vector2, r: float) -> PackedVector2Array:
	var centre := c + d * r
	var pts := PackedVector2Array([c])
	for k in 9:
		var a := k / 8.0 * PI * 0.5
		pts.append(centre + Vector2(-d.x * cos(a), -d.y * sin(a)) * r)
	return pts

func _snow_caps(p: Painter, w: float, base: float, amp: float, fn: Array) -> void:
	var step := 8.0
	var prev := 0.0
	var cur := _wave(0.0, fn)
	for i in range(1, int(w / step)):
		var nxt := _wave((i + 1) * step / w, fn)
		if cur > prev and cur >= nxt and cur > 0.72:
			var x := i * step
			var y := base - amp * cur
			var s := amp * 0.12
			p.poly(PackedVector2Array([Vector2(x - s * 1.4, y + s), Vector2(x, y), Vector2(x + s * 1.4, y + s), Vector2(x + s * 0.4, y + s * 0.7), Vector2(x - s * 0.5, y + s * 0.8)]), Color("eef2f6"))
		prev = cur
		cur = nxt

func _travel(t: float) -> float:
	# full speed, then braking over the last second (into the station at the other end)
	var b := minf(1.0, duration * 0.4)
	if t <= duration - b:
		return t
	var tau := minf(t, duration) - (duration - b)
	return (duration - b) + tau - 0.425 * tau * tau / b

func _pose_slides(d: float) -> void:
	for s in _slides:
		var p: Painter = s[0]
		p.position.x = -fposmod(d * float(s[1]), float(s[2]))

func _pose_train() -> void:
	_pose_slides(_travel(elapsed))
	if _rain:
		_rain.position = Vector2(0, -_size.y + fposmod(elapsed * _size.y * 0.6, _size.y))
	if _passing:
		var at := duration * 0.3
		var x := _size.x * 1.2 - (elapsed - at) * _size.x * 3.2
		_passing.position.x = x if elapsed >= at else _size.x * 3.0
		_cue("rush", elapsed >= at - 0.25, "train_rush", -2.0)
	_cue("whistle", true, "train", -4.0)
	_cue("brake", elapsed >= duration - minf(1.0, duration * 0.4), "brake_squeal", -6.0)
	if _loop:
		var v := 1.0 - clampf((elapsed - (duration - 1.0)) / 1.0, 0.0, 0.85)
		_loop.pitch_scale = 0.75 + 0.35 * v

# --- the ferry -------------------------------------------------------------------------------------------------

func _build_ferry() -> void:
	var W := _size.x
	var H := _size.y
	var horizon := H * 0.5
	var strip := ceilf(W * 1.5)
	_sky(_root, horizon)
	_slide(_cloud_layer(_root, strip, H * 0.08, H * 0.3, 6, 0.8), 0.05, strip)
	var sea_top := _c("3f6f94")
	var sea_low := _c("244a6a")
	var sea := _painter(_root)
	sea.grad(PackedVector2Array([Vector2(0, horizon), Vector2(W, horizon), Vector2(W, H), Vector2(0, H)]), PackedColorArray([sea_top, sea_top, sea_low, sea_low]))
	# the coast you leave, low on the horizon behind, and the one you're going to, rising ahead
	_coast_out = _painter(_root)
	_coast_out.poly(_ridge_pts(W * 0.9, horizon + 2, H * 0.07, _wave_fn(false), horizon + 2), _c("5f7a6a"))
	_town_row(_coast_out, W * 0.1, W * 0.5, horizon, H * 0.022)
	_coast_in = _painter(_root)
	var in_pts := _ridge_pts(W * 0.9, 0.0, H * 0.09, _wave_fn(false), 0.0)
	_coast_in.poly(in_pts, _c("6a8a62"))
	_town_row(_coast_in, W * 0.35, W * 0.75, 0.0, H * 0.022)
	_coast_in.position.y = horizon + 2
	for i in 3:
		var wp := _painter(_root, strip)
		var y0 := horizon + H * (0.05 + i * 0.14)
		var col := sea_top.lightened(0.25 + i * 0.1)
		for k in 26 + i * 6:
			var x := _rng.randf() * strip
			var y := y0 + _rng.randf() * H * 0.12
			var s := H * (0.012 + i * 0.01)
			wp.line(PackedVector2Array([Vector2(x - s * 2, y), Vector2(x - s, y - s * 0.5), Vector2(x, y), Vector2(x + s, y - s * 0.5), Vector2(x + s * 2, y)]), col, 2.0 + i)
		_waves.append([wp, 0.25 + i * 0.4, strip, y0])
	_quay_out = _harbour(true)
	_quay_in = _harbour(false)
	_wake = _painter(_root)
	for k in 7:
		var wy := k * 3.0
		_wake.line(PackedVector2Array([Vector2(-k * H * 0.06, wy), Vector2(-k * H * 0.06 - H * 0.05, wy + 2.0)]), Color(1, 1, 1, 0.7 - k * 0.09), 5.0 - k * 0.5)
		_wake.line(PackedVector2Array([Vector2(-k * H * 0.06 - H * 0.02, wy + 7.0), Vector2(-k * H * 0.06 - H * 0.06, wy + 9.0)]), Color(1, 1, 1, 0.5 - k * 0.06), 3.0)
	_boat = Sprite2D.new()
	_boat.texture = _boat_texture()
	_boat.centered = true
	_root.add_child(_boat)
	_deck = Sprite2D.new()
	var tex := _char_tex()
	if tex:
		_deck.texture = tex
		_deck.hframes = 3
		_deck.vframes = 4
		_deck.frame = 2 * 3  # facing right, along the deck
		_deck.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_boat.add_child(_deck)
	_deck.position = Vector2(-150, 0)  # feet on the aft deck
	_deck.scale = Vector2(1.4, 1.4)
	var ports := Painter.new()  # a row of portholes along the hull
	for k in 10:
		ports.circle(Vector2(-150 + k * 33, 62), 6.0, WINDOW_LIT if _lit() else Color("9fb6c8"))
	_boat.add_child(ports)
	var near_waves := _painter(_root, strip)
	for k in 24:
		var x := _rng.randf() * strip
		var y := H * 0.64 + _rng.randf() * H * 0.36
		var s := H * 0.03
		near_waves.line(PackedVector2Array([Vector2(x - s * 2, y), Vector2(x - s, y - s * 0.5), Vector2(x, y), Vector2(x + s, y - s * 0.5), Vector2(x + s * 2, y)]), sea_top.lightened(0.5), 4.0)
	_waves.append([near_waves, 1.3, strip, H * 0.64])
	for i in 4:
		var g := Line2D.new()
		g.width = 4.0
		g.default_color = Color("f2efe6") if phase != "night" else Color("9aa0b0")
		g.points = PackedVector2Array([Vector2(-10, 0), Vector2(0, 4), Vector2(10, 0)])
		g.joint_mode = Line2D.LINE_JOINT_ROUND
		_root.add_child(g)
		_gulls.append(g)
		_gull_base.append(Vector2(W * (0.15 + 0.22 * i) + _rng.randf() * 40.0, H * (0.15 + _rng.randf() * 0.15)))
	if weather == "fog":
		var fog := ColorRect.new()
		fog.size = _size
		fog.color = Color(0.85, 0.87, 0.9, 0.35)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(fog)
	var ship := str(Travel.ferries().get(str(info.get("route", "")), {}).get("ship", "the ferry"))
	_caption("Sailing to %s on %s" % [Travel.town_name(str(info.get("to", ""))), ship])
	var card := str(info.get("card", ""))
	if card != "":
		var p := UIKit.panel(Color("1d2230e6"), 12)
		p.position = Vector2(W * 0.1, H * 0.8)
		p.custom_minimum_size = Vector2(W * 0.8, 0)
		p.size = Vector2(W * 0.8, 0)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := UIKit.label(card, 22)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(W * 0.8 - 24, 0)
		p.add_child(l)
		_root.add_child(p)

## A row of little houses along a coast (`ground` is the waterline).
func _town_row(p: Painter, x0: float, x1: float, ground: float, s: float) -> void:
	var x := x0
	while x < x1:
		_house(p, x, ground - s * 0.4, s, _c(["f2efe6", "e8d8b0", "b0573f"][_rng.randi() % 3]), _c("4a5058"), _lit())
		x += s * _rng.randf_range(1.6, 3.0)

## The harbour wall you leave from (left) or come in to (right), with its lighthouse and bollards.
func _harbour(leaving: bool) -> Painter:
	var H := _size.y
	var W := _size.x
	var p := _painter(_root)
	var run_len := W * 1.5
	var top := H * 0.55
	var x0 := -run_len if leaving else 0.0
	var x1 := 0.0 if leaving else run_len
	p.rect(Rect2(x0, top, run_len, H * 0.12), _c("8a8478"))
	p.rect(Rect2(x0, top, run_len, H * 0.015), _c("a8a294"))
	for k in 8:
		var bx := x0 + (k + 0.5) * run_len / 8.0
		p.rect(Rect2(bx - 6, top - 12, 12, 12), _c("2a2f38"))
	var lx := x1 - H * 0.06 if leaving else x0 + H * 0.02
	p.rect(Rect2(lx, top - H * 0.2, H * 0.045, H * 0.2), _c("f2efe6"))
	p.rect(Rect2(lx, top - H * 0.15, H * 0.045, H * 0.03), _c("c8102e"))
	p.rect(Rect2(lx, top - H * 0.08, H * 0.045, H * 0.03), _c("c8102e"))
	p.rect(Rect2(lx - 3, top - H * 0.235, H * 0.045 + 6, H * 0.035), Color("ffd27a") if _lit() else _c("3a3f4f"))
	var hx := x0 + (run_len * 0.55 if leaving else run_len * 0.3)
	for k in 7:
		_house(p, hx + k * H * 0.09, top, H * 0.06, _c(["f2efe6", "e8d8b0", "9fb6c8", "b0573f"][_rng.randi() % 4]), _c("4a5058"), _lit())
	return p

## The ferry prop from the harbours, rendered once side-on from its own little 3D stage.
func _boat_texture() -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return null
	var vp := SubViewport.new()
	vp.size = Vector2i(512, 256)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	Meshes.materials()
	var mi := MeshInstance3D.new()
	mi.mesh = Landmarks.boat(0)
	mi.material_override = Meshes.solid
	vp.add_child(mi)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.9
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.6, -6), Vector3(0, 0.95, 0))
	var sun := DirectionalLight3D.new()
	vp.add_child(sun)
	sun.look_at_from_position(Vector3(2, 4, -3), Vector3.ZERO)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 0.55
	env.environment = e
	vp.add_child(env)
	add_child(vp)
	return vp.get_texture()

func _char_tex() -> Texture2D:
	if not look.is_empty():
		return LookArt.texture(look)
	var path := "res://art/sprites/chars/%s.png" % sprite_id
	if not ResourceLoader.exists(path):
		path = "res://art/sprites/chars/player_a.png"
	return load(path) if ResourceLoader.exists(path) else null

## How far through the crossing (0..1) at scene time `u`: gathering speed out of the harbour, steady across,
## slowing into the other. Short starts and ends out at sea.
func _sail(u: float) -> float:
	if mode != "on":
		u = 0.3 + 0.45 * u
	var a := 0.22
	var vmax := 1.0 / (1.0 - a)
	if u < a:
		return 0.5 * vmax * u * u / a
	if u < 1.0 - a:
		return vmax * (a * 0.5 + (u - a))
	return 1.0 - 0.5 * vmax * (1.0 - u) * (1.0 - u) / a

func _pose_ferry() -> void:
	var W := _size.x
	var H := _size.y
	var u := clampf(elapsed / duration, 0.0, 1.0)
	var dist := W * 6.0
	var s := _sail(u)
	var wx := s * dist
	var speed := clampf((_sail(minf(u + 0.01, 1.0)) - _sail(maxf(u - 0.01, 0.0))) * 50.0, 0.0, 1.5)
	var bob := sin(elapsed * 2.2)
	var boat_x := W * 0.42
	if _boat:
		_boat.position = Vector2(boat_x, H * 0.56 + bob * H * 0.008)
		_boat.rotation = sin(elapsed * 1.7) * 0.02
	for wv in _waves:
		var p: Painter = wv[0]
		p.position = Vector2(-fposmod(wx * float(wv[1]) + elapsed * 12.0, float(wv[2])), sin(elapsed * 1.5 + float(wv[1]) * 3.0) * 3.0)
	_pose_slides(elapsed * 60.0)
	_quay_out.position.x = boat_x - W * 0.26 - wx
	_quay_in.position.x = boat_x + W * 0.28 + dist - wx
	_coast_out.position.x = W * 0.05 - wx * 0.12
	_coast_in.position.x = W * 0.3 + dist * 0.12 - wx * 0.12
	_coast_in.scale.y = lerpf(0.15, 1.0, smoothstep(0.35, 0.9, s))
	_wake.position = Vector2(boat_x - W * 0.15, H * 0.7 + bob * H * 0.008)
	_wake.modulate.a = clampf(speed, 0.0, 1.0)
	for i in _gulls.size():
		var g: Line2D = _gulls[i]
		var b: Vector2 = _gull_base[i]
		g.position = b + Vector2(fposmod(elapsed * (30.0 + i * 8.0), W * 0.2) - W * 0.1 + sin(elapsed * 0.7 + i) * 30.0, sin(elapsed * 1.3 + i * 2.0) * 12.0)
		var flap := sin(elapsed * 9.0 + i * 1.7) * 6.0
		g.set_point_position(0, Vector2(-14, flap))
		g.set_point_position(2, Vector2(14, flap))
	_cue("horn_out", true, "ship_horn", -2.0)
	if mode == "on":
		_cue("horn_in", u >= 0.82, "ship_horn", -4.0)

# --- the Raven -------------------------------------------------------------------------------------------------

func _build_fly() -> void:
	var W := _size.x
	var H := _size.y
	var m := Travel.world_map()
	var towns: Dictionary = m.get("towns", {})
	var to := str(info.get("to", ""))
	var from := str(info.get("from", ""))
	var dest: Dictionary = towns.get(to, {})
	_to_pt = Vector2(float(dest.get("x", 500)), float(dest.get("y", 650)))
	var src: Dictionary = towns.get(from, {})
	_from_pt = Vector2(float(src.x), float(src.y)) if not src.is_empty() and from != to else _to_pt + Vector2(-60, 120)
	var space: Array = m.get("space", [1000, 1300])
	_map_k = maxf(2.0, H / 260.0)
	var sea := ColorRect.new()  # past the map's edges
	sea.size = _size
	sea.color = MapView.SEA
	sea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(sea)
	_map = MapView.new()
	_map.zoom = 1.0
	_map.size = Vector2(float(space[0]), float(space[1])) * _map_k
	_map.objective = _to_pt
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_map)
	var tint := ColorRect.new()
	tint.size = _size
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.color = {"night": Color(0.04, 0.06, 0.2, 0.5), "dusk": Color(0.5, 0.25, 0.2, 0.22), "dawn": Color(0.6, 0.45, 0.4, 0.15)}.get(phase, Color(0, 0, 0, 0))
	if weather in GREY_WEATHER:
		tint.color = tint.color.blend(Color(0.6, 0.62, 0.66, 0.3))
	_root.add_child(tint)
	_shadow = Polygon2D.new()
	_shadow.polygon = _ellipse(Vector2.ZERO, H * 0.09, H * 0.03, 16)
	_shadow.color = Color(0, 0, 0, 0.28)
	_root.add_child(_shadow)
	for i in 2:
		var group := CanvasGroup.new()  # drawn as one, so overlapping puffs don't show their seams
		group.self_modulate = Color(1, 1, 1, 0.55 + i * 0.2)
		_root.add_child(group)
		var cp := _painter(group, W)
		cp.repeat = Vector2(W, H)
		var col := Color(1, 1, 1)
		if phase == "night":
			col = Color(0.55, 0.6, 0.75)
		elif weather in GREY_WEATHER:
			col = Color("d4d8dc")
		for k in 5 + i * 2:
			var c := Vector2(_rng.randf() * W, _rng.randf() * H)
			var r := H * (0.05 + i * 0.03)
			for j in 3:
				cp.poly(_ellipse(c + Vector2((j - 1) * r, (j % 2) * r * 0.3), r, r * 0.6, 14), col)
		_clouds.append([cp, 0.6 + i * 0.9])
	var sheet = load("res://art/sprites/creatures/bran_back.png") if ResourceLoader.exists("res://art/sprites/creatures/bran_back.png") else null
	_raven = Sprite2D.new()
	_raven.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if sheet and sheet.get_height() > 96:  # a fine sheet (see tools/spritegen/creature.gd): brought to the 96 px the rider sits on
		var img: Image = sheet.get_image()
		if img != null and not img.is_empty():
			img = img.duplicate()
			if img.is_compressed():
				img.decompress()
			img.resize(192, 96, Image.INTERPOLATE_LANCZOS)
			sheet = ImageTexture.create_from_image(img)
			_raven.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if sheet:
		for i in 2:
			var a := AtlasTexture.new()
			a.atlas = sheet
			a.region = Rect2(i * 96, 0, 96, RAVEN_ROWS)
			_raven_frames.append(a)
		_raven.texture = _raven_frames[0]
	_raven.scale = Vector2(1.7, 1.7) * (H / 720.0)
	_root.add_child(_raven)
	_rider = Sprite2D.new()
	var tex := _char_tex()
	if tex:
		_rider.texture = tex
		_rider.hframes = 3
		_rider.vframes = 4
		_rider.frame = 3 * 3  # from behind, like the Raven
		_rider.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rider.position = Vector2(0, -16)
	_rider.scale = Vector2(0.6, 0.6)
	_raven.add_child(_rider)
	_caption("Bran's Raven carries you to %s" % Travel.town_name(to))

func _pose_fly() -> void:
	var W := _size.x
	var H := _size.y
	var u := clampf(elapsed / duration, 0.0, 1.0)
	var e := u * u * (3.0 - 2.0 * u)
	var d := _to_pt - _from_pt
	var side := Vector2(-d.y, d.x).normalized() if d.length() > 1.0 else Vector2.ZERO
	var pt := _from_pt + d * e + side * sin(PI * e) * minf(d.length() * 0.12, 60.0)
	var z := 1.0 - 0.35 * sin(PI * u)
	var k := _map_k * z
	var centre := Vector2(W * 0.5, H * 0.52)
	if _map:
		_map.scale = Vector2(z, z)
		_map.position = centre - pt * k
	var dir := d.normalized() if d.length() > 1.0 else Vector2.UP
	for c in _clouds:
		var p: Painter = c[0]
		var off: Vector2 = dir * elapsed * H * 0.25 * float(c[1])
		p.position = Vector2(-fposmod(off.x, W), -fposmod(off.y, H))
	if _raven:
		var lift := sin(PI * u) * H * 0.04
		_raven.position = Vector2(W * 0.5, H * 0.48 - lift + sin(elapsed * 6.0) * 4.0)
		_raven.rotation = clampf(dir.x, -1.0, 1.0) * 0.18 * sin(PI * u)
		var flap := 1.0 + 0.1 * sin(elapsed * 9.0)  # wingbeats
		_raven.scale = Vector2(1.7 * flap, 1.7 * (2.0 - flap)) * (H / 720.0)
		if not _raven_frames.is_empty():
			_raven.texture = _raven_frames[int(elapsed * 5.0) % 2]
		_shadow.position = _raven.position + Vector2(H * 0.06, H * 0.14 + lift * 1.5)
		_shadow.scale = Vector2.ONE * (1.0 - 0.3 * sin(PI * u))
	_cue("caw", true, "raven_caw", 0.0)

# --- shared bits -----------------------------------------------------------------------------------------------

func _caption(text: String) -> void:
	var p := UIKit.panel(Color("1d2230e6"), 10)
	p.position = Vector2(_size.x * 0.07 + 12, _size.y * 0.09 + 12) if kind == "train" else Vector2(24, 20)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(UIKit.label(text, 24, UIKit.GOLD))
	_root.add_child(p)
	var hint := UIKit.label(UIKit.hint([["confirm", "Skip"]]), 18, UIKit.MUTED)
	hint.position = Vector2(_size.x - 160, _size.y - 34)
	hint.size = Vector2(140, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(hint)

## Plays `id` once, the first time `now` is true.
func _cue(key: String, now: bool, id: String, gain_db: float) -> void:
	if not now or _cues.has(key) or hold_at >= 0.0:
		return
	_cues[key] = true
	if is_inside_tree():
		Audio.sfx_at(id, gain_db)

## The bed under the scene: wheels on the rails, the sea and gulls, or the wind.
func _start_sound() -> void:
	if not is_inside_tree() or hold_at >= 0.0:
		return
	var path: String = {"train": "res://audio/ambience/train_run.wav", "ferry": "res://audio/ambience/amb_coast.wav", "fly": "res://audio/ambience/amb_gale.wav"}.get(kind, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	_loop = AudioStreamPlayer.new()
	_loop.stream = load(path)
	_loop.volume_db = linear_to_db(maxf(Settings.ambience_volume, 0.0001)) + (-3.0 if kind == "train" else -8.0)
	add_child(_loop)
	_loop.finished.connect(_loop.play)
	_loop.play()

## One flat layer: its shapes are drawn once (and again `repeat` along, so it can wrap) and then only moved.
class Painter extends Node2D:
	var ops: Array = []
	var repeat := Vector2.ZERO

	func poly(pts: PackedVector2Array, c: Color) -> void:
		if pts.size() >= 3:
			ops.append([0, pts, c])

	func line(pts: PackedVector2Array, c: Color, w: float) -> void:
		ops.append([1, pts, c, w])

	func circle(at: Vector2, r: float, c: Color) -> void:
		ops.append([2, at, r, c])

	func rect(r: Rect2, c: Color) -> void:
		ops.append([3, r, c])

	func grad(pts: PackedVector2Array, cols: PackedColorArray) -> void:
		ops.append([4, pts, cols])

	func _draw() -> void:
		var offs := [Vector2.ZERO]
		if repeat.x > 0.0:
			offs.append(Vector2(repeat.x, 0))
		if repeat.y > 0.0:
			offs.append(Vector2(0, repeat.y))
			if repeat.x > 0.0:
				offs.append(repeat)
		for o in offs:
			draw_set_transform(o)
			for op in ops:
				match op[0]:
					0:
						draw_colored_polygon(op[1], op[2])
					1:
						draw_polyline(op[1], op[2], op[3], true)
					2:
						draw_circle(op[1], op[2], op[3])
					3:
						draw_rect(op[1], op[2])
					4:
						draw_polygon(op[1], op[2])
		draw_set_transform(Vector2.ZERO)
