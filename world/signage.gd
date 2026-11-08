class_name Signage
extends RefCounted
## Building names as signs that belong to the building: a painted fascia over a shop, a pub's fascia and its
## hanging sign, the Sanctuary's and the Corner Shop's own branded boards, an enamel name board on a station
## canopy, a carved stone band over a museum's door, a heritage board on posts by a castle or a church, a street
## plate on a terrace. Real geometry, depth tested and lit like the walls they hang on: a sign behind another
## building is hidden, as in life (the place indicator at the bottom of the screen carries the legibility).
## Boards are vertex-coloured boxes merged into one mesh per zone ("Signs"; lamps in "SignLamps", emblems
## that glow at night in "SignsLit"); each name is a Label3D in a bundled OFL font, fitted to its board.

const TYPES := ["", "fascia", "pub", "sanctuary", "chain", "station", "heritage", "tourist", "keeper", "street", "house"]
## Interiors where a keeper waits (each plays the keeper battle music; a test keeps the two in step).
const KEEPER_HALLS := ["belfast_yard", "buxton_spa", "cardiff_arena", "galway_docks", "inverness_rink", "liverpool_club",
	"dublin_hall", "glastonbury_tor", "llanberis_quarry", "york_minster_crypt"]
## Venues that aren't called a pub but serve as one (the taproom at Knott Mill runs the Manchester quiz).
const PUB_VENUES := ["manchester_knottmill"]
const PUB_NAMES := ["Tigh Neachtain", "The Last Drop", "Admiral Benbow", "The Anchor", "The George and Pilgrims", "Cat and Fiddle"]
## Names that only say what the building is: no sign for those.
const GENERIC := ["Home", "House", "Test House", "Cottage", "Farmhouse", "Barn", "Field Barn", "Laithe", "Bothy", "Croft", "Hut", "Flats"]

const FS := 64  # Label3D font size: the em in world units is FS * pixel_size
const SHRINK_OK := 0.8  # a one-line name may shrink this far before it wraps on to two lines
const TIGHT := 0.14  # two-line names sit this much (of an em) closer than the font's own line height

## Heritage shopfront colours, painted boards with gilt or cream lettering.
const GILT := Color("d9b45e")
const CREAM_INK := Color("efe5c9")
const PALETTES := [
	{"board": Color("1f3b2d"), "ink": GILT},        # bottle green
	{"board": Color("1c2944"), "ink": GILT},        # navy
	{"board": Color("5a1d22"), "ink": GILT},        # oxblood
	{"board": Color("19191b"), "ink": GILT},        # black
	{"board": Color("e6dbbe"), "ink": Color("1f3b2d")},  # cream, green letters
	{"board": Color("2b4a4f"), "ink": CREAM_INK},   # dark teal
	{"board": Color("3d2a44"), "ink": CREAM_INK},   # aubergine
]
const SANCTUARY_GREEN := Color("2f6a4a")
const SHOP_NAVY := Color("1d2c4f")
const SHOP_RED := Color("b8352b")
const STONE := Color("ddd5c2")
const STONE_EDGE := Color("b1a792")
const INCISED := Color("3d362d")
const ENAMEL_RED := Color("7c2230")
const ENAMEL_BLUE := Color("1f3e6e")
const ENAMEL_WHITE := Color("f4f2ea")
const BROWN := Color("5e3b20")
const SLATE := Color("3a3f47")
const OAK := Color("3a2a20")
const IRON := Color("343c47")
const POST := Color("26292e")

static var _fonts := {}
static var _re := {}
static var lit: ShaderMaterial  # emblems that glow at night (energy from SkyAndLight)
static var _night := false

# --- which sign ------------------------------------------------------------------------

static func _rx(key: String, pattern: String) -> RegEx:
	if not _re.has(key):
		var r := RegEx.new()
		r.compile(pattern)
		_re[key] = r
	return _re[key]

static func _matches(key: String, pattern: String, s: String) -> bool:
	return _rx(key, pattern).search(s) != null

## The sign a building gets: one of TYPES ("" for none). `kind` is its interior's landmark kind (the zone prop's
## "kind", see tools/zones/building_kinds.py) and `to` the zone its door leads to; both may be "".
static func sign_type(label: String, style: String, kind := "", to := "") -> String:
	var n := label.strip_edges()
	if n == "":
		return ""
	if to in KEEPER_HALLS:
		return "keeper"
	if style == "sanctuary" or n == "Sanctuary" or to.ends_with("_sanctuary"):
		return "sanctuary"
	if style == "shop" or n == "Corner Shop" or to.ends_with("_shop"):
		return "chain"
	if n in GENERIC:
		return ""
	var old := n.begins_with("Old ") or n.begins_with("The Old ")
	if not old and _matches("fascia", "(?i)\\b(shops?|books|bookshop|caf[eé]|caffi|tea rooms|tea shop|chippy|chips|fish supper|bakery|gifts|emporium|parlour|co\\.|company|creamery|bikes|bike works|kippers?|sandwich|wardrobe|tweed|craft|selfridges|mailbox|arcade|(victorian|english|bigg) market|market hall|cone zone|sally lunn's|bettys|jolly's|post office|cash only|surf|strawberry|jet workshop)(?![a-z])", n):
		return "fascia"
	if to in PUB_VENUES or n in PUB_NAMES or _matches("pub", "(?i)\\b(inn|arms|tavern|pub|tap|posada|olde|hotel)\\b", n) \
			or (style != "castle" and _matches("bar", "\\bBar\\b", n)):
		return "pub"
	if _matches("street", "(?i)\\b(street|road|terraces?|crescent|close|lane|rows?|alley|quarter|quays|shambles|grassmarket|town|city)$", n) \
			or _matches("gate", "^[A-Z][a-z]+gate$", n):
		return "street"
	if style == "station" or _matches("rail", "\\b(Railway|Halt|Signal Box|Underground)\\b", n) \
			or (n.ends_with(" Station") and not n.begins_with("Field ") and not n.begins_with("Pumping ")):
		return "station"
	if _matches("tourist", "(?i)(visitor|centre$|exhibition|tours\\b|observatory|oceanworld)", n):
		return "tourist"
	if _matches("house", "(?i)\\b(cottage|farm|bothy|croft|hut|guest house|hostel|lodge|flats|cartref)\\b|^(Bryn|Tŷ|Fferm) ", n):
		return "house"
	if kind in ["home", "cottage"] and not old:
		return "house"
	return "heritage"

## The door column (relative to the footprint, -1 for none) and the zone its warp leads to.
static func door_of(z: ZoneData, pr: Dictionary) -> Array:
	var bx := int(pr.x)
	var by := int(pr.y)
	var row := by + int(pr.h) - 1
	var out := [-1, ""]
	for x in range(bx, bx + int(pr.w)):  # the last door, as ZoneBuilder takes it
		if z.tile_at(Vector2i(x, row)) == "door":
			out = [x - bx, str(z.warp_at(Vector2i(x, row)).get("to", ""))]
	return out

static func type_of(z: ZoneData, pr: Dictionary) -> String:
	if not pr.has("label") or not pr.get("show_label", true):
		return ""
	var door := door_of(z, pr)
	return sign_type(str(pr.label), str(pr.get("style", "red_brick")), str(pr.get("kind", "")), str(door[1]))

const KIND_WORDS := {"museum": "Museum", "library": "Library", "church": "Church", "castle": "Castle", "hall": "Hall",
	"theatre": "Theatre", "mill": "Mill", "school": "School", "workshop": "Workshop", "cafe": "Cafe"}

## A short word for what a building is, for the place indicator ("" when the name already says it).
static func place_word(label: String, style: String, kind := "", to := "") -> String:
	var t := sign_type(label, style, kind, to)
	var word := ""
	match t:
		"sanctuary":
			return "Rest and healing"
		"chain":
			return "Supplies"
		"keeper":
			return "Keeper's Hall"
		"pub":
			word = "Pub"
		"station":
			word = "Railway station"
		"street":
			word = "Street"
		"tourist":
			word = "Visitor attraction"
		"fascia":
			var n := label.to_lower()
			if n.contains("book"):
				word = "Bookshop"
			elif n.contains("tea "):
				word = "Tea room"
			elif n.contains("chip") or n.contains("fish"):
				word = "Chip shop"
			elif n.contains("caf"):
				word = "Cafe"
			elif n.contains("bakery"):
				word = "Bakery"
			elif kind == "cafe":
				word = "Cafe"
			else:
				word = "Shop"
		"heritage":
			word = "Research lab" if _matches("lab", "\\b(Lab|Field Station)\\b", label) else KIND_WORDS.get(kind, "Landmark")
		_:
			return ""
	var last := word.get_slice(" ", word.get_slice_count(" ") - 1).to_lower()
	if label.to_lower().contains(last.trim_suffix("s")) or label == word:
		return ""
	return word

## The fascia colours of a painted shop or pub board: the same building always gets the same.
static func palette(label: String, zone_id: String) -> Dictionary:
	return PALETTES[_pal_index(label, zone_id, false)]

## Pubs keep to the dark boards (the first four); `avoid` is a neighbour's index, so two fronts side by side
## are never painted alike.
static func _pal_index(label: String, zone_id: String, dark: bool, avoid := -1) -> int:
	var n := 4 if dark else PALETTES.size()
	var i := absi(hash(zone_id + "/" + label)) % n
	return (i + 1) % n if i == avoid else i

# --- fonts and fitting ---------------------------------------------------------------------

## "serif" (Libre Baskerville Bold), "caps" (Libre Baskerville, spaced for carved capitals), "sans" (Source Sans 3 Bold).
static func font(name: String) -> Font:
	if not _fonts.has(name):
		var fv := FontVariation.new()
		var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
		match name:
			"sans":
				fv.base_font = load("res://art/fonts/source_sans_3/SourceSans3.ttf")
				fv.variation_opentype = {wght: 700}
			"sans_caps":
				fv.base_font = load("res://art/fonts/source_sans_3/SourceSans3.ttf")
				fv.variation_opentype = {wght: 700}
				fv.spacing_glyph = 4
			"caps":
				fv.base_font = load("res://art/fonts/libre_baskerville/LibreBaskerville.ttf")
				fv.variation_opentype = {wght: 500}
				fv.spacing_glyph = 5
			_:
				fv.base_font = load("res://art/fonts/libre_baskerville/LibreBaskerville.ttf")
				fv.variation_opentype = {wght: 700}
		_fonts[name] = fv
	return _fonts[name]

static func _w(text: String, f: Font) -> float:
	return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x / FS

## Line height in ems.
static func _lh(f: Font) -> float:
	return f.get_height(FS) / FS

## Fits `text` to a board area max_w x max_h (world units), at most `em` high: one line, shrunk a little if
## need be, else broken on a space into two lines. Returns {text, em, lines, width, height}; a line's height
## counts as one em (capitals and descenders), a second line adds the font's line advance, drawn a little tight.
static func fit(text: String, f: Font, em: float, max_w: float, max_h := INF) -> Dictionary:
	var adv := _lh(f) - TIGHT
	var w1 := _w(text, f)
	var e1 := minf(em, minf(max_w / maxf(w1, 0.001), max_h))
	var one := {"text": text, "em": e1, "lines": 1, "width": w1 * e1, "height": e1}
	if e1 >= em * SHRINK_OK - 0.0001 or not text.contains(" "):
		return one
	var words := text.split(" ")
	var best := ""
	var best_w := INF
	for i in range(1, words.size()):
		var a := " ".join(words.slice(0, i))
		var b := " ".join(words.slice(i))
		var lw := maxf(_w(a, f), _w(b, f))
		if lw < best_w:
			best_w = lw
			best = a + "\n" + b
	var e2 := minf(em, minf(max_w / best_w, max_h / (1.0 + adv)))
	if e2 <= e1:
		return one
	return {"text": best, "em": e2, "lines": 2, "width": best_w * e2, "height": (1.0 + adv) * e2}

## How far (in ems) below its box centre a line's capitals are centred: Label3D centres the font's whole line box.
static func _drop(f: Font) -> float:
	return (f.get_ascent(FS) - f.get_descent(FS)) / FS * 0.5 - 0.34

# --- where a front can carry a sign ---------------------------------------------------------

## Where on a building's south front a name can go, in footprint coordinates (origin at the north-west corner):
## mode "wall" (a band at height lo..hi, flat on the face at z), "canopy" (on a station's canopy edge),
## "parapet" (a panel standing on the roofline at lo), "trough" (an aqueduct's iron trough) or "stand" (free-
## standing on posts just in front). x0..x1 is the clear width; hang is the height of a pub sign's bracket.
static func front(style: String, w: int, d: int, door_x: int) -> Dictionary:
	var f := {"mode": "wall", "z": float(d), "lo": 1.1, "hi": 1.55, "x0": 0.18, "x1": w - 0.18, "hang": -1.0}
	match style:
		"station":
			f.merge({"mode": "canopy", "z": d + 1.0, "lo": 1.58, "hi": 2.06, "x0": 0.3, "x1": w - 0.3}, true)
		"mill":
			f.merge({"mode": "parapet", "z": d + 0.05, "lo": 4.14, "hi": 4.62, "x0": 1.6, "x1": w - 1.7, "hang": 2.0}, true)
		"liver_building":
			if w >= 7:
				f.merge({"mode": "parapet", "z": d - 0.05, "lo": 3.6, "hi": 4.05, "x0": 2.2, "x1": w - 2.2}, true)
			else:
				f.mode = "stand"
		"terrace", "lighthouse_house":
			f.merge({"lo": 1.07, "hi": 1.48, "hang": 2.4}, true)
		"tudor":
			f.merge({"z": d + 0.16, "lo": 1.07, "hi": 1.47, "hang": 2.4}, true)
		"slate_cottage":
			f.merge({"z": d + 0.2, "lo": 1.07, "hi": 1.46, "hang": 1.42}, true)
		"thatch_cottage":
			f.merge({"z": d + 0.24, "lo": 0.95, "hi": 1.3, "hang": 1.3}, true)
		"irish_shopfront":
			f.merge({"z": d + 0.05, "lo": 1.08, "hi": 1.46, "hang": 2.3}, true)
		"tower_house", "tower_house_granite":
			f.mode = "stand"
		"chapel":
			f.merge({"lo": 2.08, "hi": 2.46, "x0": 0.25, "x1": w - 0.25}, true)
		"cathedral":
			var tower_w := mini(3, w - 2)
			if door_x >= tower_w:
				f.merge({"z": d - 0.3, "lo": 2.22, "hi": 3.0, "x0": tower_w + 0.15, "x1": w - 0.15}, true)
			else:
				f.merge({"lo": 1.4, "hi": 1.95, "x0": 0.15, "x1": tower_w - 0.15}, true)
		"castle", "castle_red":
			if door_x >= 0:
				f.merge({"z": d + 0.1, "lo": 1.22, "hi": 2.3, "x0": door_x - 0.32, "x1": door_x + 1.32}, true)
			else:
				f.mode = "stand"
		"aqueduct":
			f.merge({"mode": "trough", "z": d * 0.5 + 0.5, "lo": 3.42, "hi": 3.78, "x0": w * 0.5 - 3.0, "x1": w * 0.5 + 3.0}, true)
		"glass_tower", "titanic", "gantry_crane", "cantilever_crane", "round_tower", "passage_tomb", "field_barn":
			f.mode = "stand"
		"casino":  # the Palace: its name in claret on the gilded band along the parapet
			f.merge({"mode": "parapet", "z": d + 0.1, "lo": 3.26, "hi": 3.74, "x0": 0.6, "x1": w - 0.6}, true)
		"grandstand":  # on the striped valance under the roof
			f.merge({"z": d + 0.33, "lo": 3.5, "hi": 3.86, "x0": 0.5, "x1": w - 0.5}, true)
		"bookmaker":  # the shop's painted fascia
			f.merge({"z": d + 0.085, "lo": 1.24, "hi": 1.62, "x0": 0.1, "x1": w - 0.1}, true)
		_:
			if StreetsEW.has_style(style) or CaribStyles.is_house(style) or AbroadStyles.has_style(style):  # a house: the name sits above the ground-floor windows
				f.merge({"lo": 1.1, "hi": 1.5, "hang": 2.3}, true)
			elif style in Landmarks.SPECIAL or CaribStyles.has_style(style):
				f.mode = "stand"
			elif w >= 5 and d >= 3:  # Meshes.building: two storeys
				f.merge({"lo": 1.1, "hi": 1.54, "hang": 2.44}, true)
			else:  # one storey: the board stands proud of the eaves
				f.merge({"z": d + 0.2, "lo": 1.1, "hi": 1.56, "hang": 1.44}, true)
	if style in ["glass_tower", "titanic"]:
		f.mode = "monolith"  # modern: a granite slab by the entrance
	elif f.mode == "wall" and float(f.x1) - float(f.x0) < 1.3:
		f.mode = "stand"  # too narrow a front for a name (a monument drawn as a tiny chapel)
	return f

## Where a pub hangs its picture sign: on a pier between the windows a little along from the door (clear of the
## name over it), never by a plaque, and above bunting strung along the front. {x, top, bottom, z, side} in
## footprint coordinates, or {} for none.
static func hanging_spot(z: ZoneData, pr: Dictionary, door_x: int) -> Dictionary:
	var w := int(pr.w)
	var d := int(pr.h)
	var f := front(str(pr.get("style", "red_brick")), w, d, door_x)
	if door_x < 0 or float(f.hang) < 0.0 or f.mode == "stand":
		return {}
	var bx := int(pr.x)
	var plaques := []
	for s in z.signs:
		if str(s.get("kind", "")) == "plaque" and int(s.y) == int(pr.y) + d - 1:
			plaques.append(int(s.x) - bx + 0.5 + float(s.get("dx", 0.0)))
	var top: float = f.hang
	var board_h := 0.6 if top > 2.0 else 0.4
	var bottom := top - 0.06 - board_h
	if bottom < 1.75 and _bunting_in_front(z, bx, int(pr.y) + d, w):
		return {}  # a one-storey front: the sign would hang in the bunting
	# a window along from the door first, clear of the name over it, then the door's own piers
	for cand in [[door_x + 2, 1], [door_x - 1, -1], [door_x + 1, 1], [door_x, -1]]:
		var x := float(cand[0])
		var side: int = cand[1]
		if x < 0.45 or x > w - 0.45:
			continue
		var clear := true
		for px: float in plaques:
			if absf(px - x) < 0.3:
				clear = false
		if clear:
			return {"x": x, "top": top, "bottom": bottom, "z": float(f.z), "side": side}
	return {}

## Is bunting strung east-west along row `row` (just in front of a building) across its front?
static func _bunting_in_front(z: ZoneData, bx: int, row: int, w: int) -> bool:
	for pr in z.props:
		if pr.get("type") != "bunting" or int(pr.y) != row or int(pr.get("rot", 0)) % 180 != 0:
			continue
		var x0 := int(pr.x) + 0.5
		var x1 := x0 + int(pr.get("variant", 3)) * (-1 if int(pr.get("rot", 0)) % 360 == 180 else 1)
		if minf(x0, x1) < bx + w and maxf(x0, x1) > bx:
			return true
	return false

# --- building them ----------------------------------------------------------------------------

## Collects every sign's geometry into three merged meshes, and their names into Label3Ds on the buildings.
class Kit:
	var st := Meshes._st()      # painted wood, stone, iron, enamel: Meshes.solid
	var gst := Meshes._st()     # lamp housings that light up at night: Meshes.glow
	var lst := Meshes._st()     # emblems that glow at night: Signage.lit
	var counts := [0, 0, 0]
	var base := Vector3.ZERO    # the building's position: geometry is built in footprint coordinates
	var painted := []           # {x, y, i}: painted fronts so far (east edge, street row, palette index)
	var body: Node3D
	var sight: SignSight        # outdoors: which parts of a front the camera can see (null indoors)

	func box(o: Vector3, s: Vector3, col: Color, which := 0) -> void:
		Meshes.box(_st_for(which), base + o, s, col)
		counts[which] += 1

	## A box in a turned or tilted frame: `xf` places the frame (in footprint coordinates), o and s are in it.
	func obox(xf: Transform3D, o: Vector3, s: Vector3, col: Color, which := 0) -> void:
		var t := Transform3D(xf.basis, base + xf.origin)
		var p := []
		for k in 8:
			p.append(t * (o + Vector3(s.x if k & 1 else 0.0, s.y if k & 2 else 0.0, s.z if k & 4 else 0.0)))
		var top := col.lightened(0.08)
		var dst := _st_for(which)
		# corners: bit 0 = +x, bit 1 = +y, bit 2 = +z (same faces and shading as Meshes.box)
		Meshes._quad(dst, p[2], p[3], p[7], p[6], top)
		Meshes._quad(dst, p[6], p[7], p[5], p[4], col)
		Meshes._quad(dst, p[3], p[2], p[0], p[1], col.darkened(0.12))
		Meshes._quad(dst, p[2], p[6], p[4], p[0], col.darkened(0.06))
		Meshes._quad(dst, p[7], p[3], p[1], p[5], col.darkened(0.03))
		counts[which] += 1

	## A flat disc facing +z in the frame xf, centred at c.
	func disc(xf: Transform3D, c: Vector3, r: float, col: Color, which := 0, sides := 16) -> void:
		var t := Transform3D(xf.basis, base + xf.origin)
		var dst := _st_for(which)
		for i in sides:
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			Meshes._tri(dst, t * c, t * (c + Vector3(cos(a1) * r, sin(a1) * r, 0)), t * (c + Vector3(cos(a0) * r, sin(a0) * r, 0)), col)
		counts[which] += 1

	## A flat triangle facing +z in the frame xf (corners anticlockwise as seen from the front).
	func tri(xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, col: Color, which := 0) -> void:
		var t := Transform3D(xf.basis, base + xf.origin)
		Meshes._tri(_st_for(which), t * a, t * c, t * b, col)
		counts[which] += 1

	func _st_for(which: int) -> SurfaceTool:
		return st if which == 0 else (gst if which == 1 else lst)

	## The name, fitted (see Signage.fit), facing +z in the frame xf at local point p. Lit names light up at night.
	func text(xf: Transform3D, p: Vector3, f: Dictionary, fnt: Font, ink: Color, lit_name := false) -> Label3D:
		var l := Label3D.new()
		l.name = "SignText"
		l.text = str(f.text)
		l.font = fnt
		l.font_size = Signage.FS
		l.pixel_size = float(f.em) / Signage.FS
		l.outline_size = 0
		l.modulate = ink
		l.line_spacing = -Signage.TIGHT * Signage.FS if int(f.lines) > 1 else 0.0
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.double_sided = false
		l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		l.shaded = not (lit_name and Signage._night)
		if lit_name:
			l.add_to_group("lit_sign_text")
		var lift := Vector3(0, Signage._drop(fnt) * float(f.em), 0) if int(f.lines) == 1 else Vector3.ZERO
		l.transform = Transform3D(xf.basis, xf.origin + xf.basis * (p + lift))
		# where the lettering is, for SignSight's checks: its centre on the body and its size (capitals, one line)
		l.set_meta("caps", xf.origin + xf.basis * p)
		l.set_meta("size", Vector2(float(f.width), float(f.height) if int(f.lines) > 1 else float(f.em) * 0.72))
		body.add_child(l)
		return l

	func commit(root: Node3D) -> void:
		var mats := [Meshes.solid, Meshes.glow, Signage.lit_material()]
		var names := ["Signs", "SignLamps", "SignsLit"]
		var sts := [st, gst, lst]
		for i in 3:
			if counts[i] == 0:
				continue
			var mi := MeshInstance3D.new()
			mi.name = names[i]
			mi.mesh = Meshes._finish(sts[i])
			mi.material_override = mats[i]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if i == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)

static func lit_material() -> ShaderMaterial:
	if lit == null:
		lit = ShaderMaterial.new()
		lit.shader = load("res://art/shaders/sign_lit.gdshader")
	return lit

## Lamps on (SkyAndLight, as the evening comes): emblems glow, and lit names stop taking the daylight shading.
static func night(tree: SceneTree, lamps: float) -> void:
	lit_material().set_shader_parameter("energy", lamps)
	var on := lamps > 0.0
	if on == _night:
		return
	_night = on
	if tree:
		for l in tree.get_nodes_in_group("lit_sign_text"):
			(l as Label3D).shaded = not on

## Every named building's sign. `bodies` is ZoneBuilder's [{pr, body, door_x}].
static func build(z: ZoneData, root: Node3D, bodies: Array) -> void:
	var kit := Kit.new()
	if z.kind != "interior":
		kit.sight = SignSight.make(z, bodies)
	for b in bodies:
		var pr: Dictionary = b.pr
		var t := type_of(z, pr)
		if t == "":
			continue
		kit.body = b.body
		kit.base = (b.body as Node3D).position
		_sign(kit, z, pr, t, int(b.door_x))
	kit.commit(root)

static func _sign(kit: Kit, z: ZoneData, pr: Dictionary, t: String, door_x: int) -> void:
	var style := str(pr.get("style", "red_brick"))
	var w := int(pr.w)
	var d := int(pr.h)
	var label := str(pr.label)
	var f := front(style, w, d, door_x)
	var mode: String = f.mode
	var stand := {"x": _stand_x(w, door_x), "z": d + 0.2}
	if kit.sight != null and mode in ["wall", "parapet", "canopy", "stand"]:
		# keep the name on the part of the front you can see from its door: on the front's real face, clear of a
		# porch, and out from behind a neighbour standing further forward
		var near_x := door_x + 0.5 if door_x >= 0 else w * 0.5
		var at := Vector2i(int(pr.x) + int(near_x), int(pr.y) + d)
		var eye := kit.sight.eye(at, ZoneBuilder.ground_y(z, at))
		var mi := kit.body as MeshInstance3D
		var tried_wall := mode == "wall"
		if mode != "stand":
			var seen := kit.sight.place(f, mi, eye, near_x, mode == "wall")
			if not seen.is_empty():
				f.merge(seen, true)
			elif mode == "wall":
				mode = "stand"  # no stretch of the front shows: the name goes on a board in front instead
		if mode == "stand":
			stand = _stand_spot(kit, _lectern_fit(label, t), w, d, door_x, eye)
			if not tried_wall and int(stand.hidden) > 0:
				# hidden even so: a name on the wall, where some of the front shows and a wall backs it
				var seen := kit.sight.place(f, mi, eye, near_x, true)
				if not seen.is_empty():
					f.merge(seen, true)
					mode = "wall"
	if t == "station" and mode == "canopy":
		_station(kit, label, f, w, d, z.region)
		return
	match mode:
		"stand":
			_lectern(kit, label, t, float(stand.x), float(stand.z))
			return
		"monolith":
			_monolith(kit, label, w, d, door_x)
			return
		"trough":
			_iron_plate(kit, label, f)
			return
		"parapet":
			_parapet(kit, label, f, style)
			if t == "pub":
				_hanging(kit, z, pr, door_x, label)
			return
	match t:
		"fascia", "pub":
			# never the same colour as the painted front just along the street
			var row := int(pr.y) + d
			var avoid := -1
			for k in kit.painted:
				if k.y == row and absi(int(k.x) - int(pr.x)) <= 16:
					avoid = k.i
			var i := _pal_index(label, z.id, t == "pub", avoid)
			kit.painted.append({"x": int(pr.x) + w, "y": row, "i": i})
			_fascia(kit, label, f, w, door_x, PALETTES[i], "serif", t == "pub")
			if t == "pub":
				_hanging(kit, z, pr, door_x, label)
		"sanctuary":
			_fascia(kit, "SANCTUARY", f, w, door_x, {"board": SANCTUARY_GREEN, "ink": Color("f6f1e2")}, "sans_caps", true, "sanctuary")
		"chain":
			_fascia(kit, "CORNER SHOP", f, w, door_x, {"board": Color("f1ead8"), "ink": SHOP_NAVY, "rule": SHOP_RED}, "sans_caps", true, "chain")
		"keeper":
			_keeper(kit, label, f, w, door_x)
		"station":
			_rail_board(kit, label, f, w, door_x, z.region)
		"street":
			_street_plate(kit, label, f)
		"house":
			_house_plate(kit, label, f, door_x)
		"tourist":
			_brown_board(kit, label, f, w, door_x)
		_:
			_heritage(kit, label, f, w, door_x, style)

## Centre x for a board of width bw on the front: over the door if it fits, kept within x0..x1.
static func _centre(f: Dictionary, bw: float, door_x: int, w: int) -> float:
	var c := door_x + 0.5 if door_x >= 0 else w * 0.5
	return clampf(c, float(f.x0) + bw * 0.5, maxf(float(f.x0) + bw * 0.5, float(f.x1) - bw * 0.5))

## A painted shopfront fascia: moulded cornice, beaded bottom, console brackets at the ends, a fine painted line
## inside the edge, and the name in serif capitals. `emblem` adds the Sanctuary's or the Corner Shop's mark at
## each end; lit fascias get a lamp trough over the cornice and lettering that lights up at night.
static func _fascia(kit: Kit, text: String, f: Dictionary, w: int, door_x: int, pal: Dictionary, fnt_name: String,
		lit_name: bool, emblem := "") -> void:
	var board: Color = pal.board
	var ink: Color = pal.ink
	var fnt := font(fnt_name)
	var span: float = float(f.x1) - float(f.x0)
	var h: float = float(f.hi) - float(f.lo) - 0.09
	var caps := fnt_name.ends_with("caps")  # capitals have no descenders: they can stand taller on the board
	var em := minf(0.34 if caps else 0.3, h * (0.9 if caps else 0.78))
	var mark := 0.0 if emblem == "" else h * 0.95
	var pad := 0.16 + mark
	var fit_w := fit(text, fnt, em, span - pad * 2.0, h * (0.92 if caps else 0.8))
	var bw: float = span if w <= 7 else clampf(float(fit_w.width) + pad * 2.0 + 0.3, minf(2.6, span), span)
	var cx := _centre(f, bw, door_x, w)
	var y0: float = float(f.lo) + 0.035
	var z0: float = f.z
	var dark := board.v > 0.5
	var trim := board.darkened(0.28) if not dark else board.darkened(0.18)
	var x0 := cx - bw * 0.5
	kit.box(Vector3(x0, y0, z0), Vector3(bw, h, 0.05), board, 2 if emblem != "" else 0)  # a branded fascia is a lightbox
	kit.box(Vector3(x0 - 0.05, y0 + h, z0), Vector3(bw + 0.1, 0.035, 0.1), trim)            # cornice
	kit.box(Vector3(x0 - 0.07, y0 + h + 0.035, z0), Vector3(bw + 0.14, 0.03, 0.13), trim.lightened(0.06))
	kit.box(Vector3(x0 - 0.02, y0 - 0.035, z0), Vector3(bw + 0.04, 0.035, 0.075), trim)     # bead
	for ex in [x0 - 0.075, x0 + bw]:  # consoles
		kit.box(Vector3(ex, y0 - 0.1, z0), Vector3(0.075, h + 0.1, 0.11), trim)
		kit.box(Vector3(ex - 0.005, y0 - 0.13, z0), Vector3(0.085, 0.04, 0.12), trim.darkened(0.15))
	var line: Color = pal.get("rule", ink.lerp(board, 0.35))
	var lz := z0 + 0.05
	var inset := 0.045
	kit.box(Vector3(x0 + inset, y0 + h - inset - 0.014, lz), Vector3(bw - inset * 2, 0.014, 0.004), line)
	kit.box(Vector3(x0 + inset, y0 + inset, lz), Vector3(bw - inset * 2, 0.014, 0.004), line)
	kit.box(Vector3(x0 + inset, y0 + inset, lz), Vector3(0.014, h - inset * 2, 0.004), line)
	kit.box(Vector3(x0 + bw - inset - 0.014, y0 + inset, lz), Vector3(0.014, h - inset * 2, 0.004), line)
	var cy := y0 + h * 0.5
	var flat := Transform3D.IDENTITY
	if emblem != "":
		for ex in [x0 + 0.1 + mark * 0.5, x0 + bw - 0.1 - mark * 0.5]:
			_emblem(kit, emblem, Transform3D(Basis(), Vector3(ex, cy, lz + 0.004)), mark * 0.42)
	if lit_name and emblem == "":  # a pub: swan-neck lamps leaning out over the board
		var n := clampi(int(bw / 1.3), 2, 4)
		for k in n:
			var ex := x0 + bw * (k + 0.5) / n
			var top := y0 + h + 0.065
			Dressing._bar(kit.st, kit.base + Vector3(ex, top, z0 + 0.08), kit.base + Vector3(ex, top + 0.07, z0 + 0.2), 0.01, POST)
			kit.box(Vector3(ex - 0.045, top + 0.02, z0 + 0.18), Vector3(0.09, 0.05, 0.08), POST)
			kit.box(Vector3(ex - 0.035, top + 0.005, z0 + 0.19), Vector3(0.07, 0.02, 0.06), Color("3a4658"), 1)
	kit.text(flat, Vector3(cx, cy, lz + 0.006), fit_w, fnt, ink, lit_name)

## The Sanctuary's mark (a white roundel with a green cross, lit at night) or the Corner Shop's (a red roundel
## with a cream basket). Built facing +z in xf, radius r.
static func _emblem(kit: Kit, kind: String, xf: Transform3D, r: float) -> void:
	if kind == "sanctuary":
		kit.disc(xf, Vector3.ZERO, r * 1.08, SANCTUARY_GREEN.darkened(0.3))
		kit.disc(xf, Vector3(0, 0, 0.002), r, Color("f6f3ea"), 2)
		var a := r * 0.34
		kit.obox(xf, Vector3(-a * 0.5, -r * 0.7, 0.004), Vector3(a, r * 1.4, 0.006), Color("3fa36b"), 2)
		kit.obox(xf, Vector3(-r * 0.7, -a * 0.5, 0.004), Vector3(r * 1.4, a, 0.006), Color("3fa36b"), 2)
	else:
		kit.disc(xf, Vector3.ZERO, r * 1.08, SHOP_NAVY)
		kit.disc(xf, Vector3(0, 0, 0.002), r, SHOP_RED, 2)
		var c := Color("f6efdc")
		kit.obox(xf, Vector3(-r * 0.55, -r * 0.45, 0.004), Vector3(r * 1.1, r * 0.55, 0.006), c, 2)       # basket
		kit.obox(xf, Vector3(-r * 0.45, r * 0.1, 0.004), Vector3(r * 0.12, r * 0.4, 0.006), c, 2)         # handle
		kit.obox(xf, Vector3(r * 0.33, r * 0.1, 0.004), Vector3(r * 0.12, r * 0.4, 0.006), c, 2)
		kit.obox(xf, Vector3(-r * 0.45, r * 0.42, 0.004), Vector3(r * 0.9, r * 0.1, 0.006), c, 2)

## A pub's picture sign on a wrought-iron bracket, turned to face the street a little.
static func _hanging(kit: Kit, z: ZoneData, pr: Dictionary, door_x: int, label: String) -> void:
	var spot := hanging_spot(z, pr, door_x)
	if spot.is_empty():
		return
	var x: float = spot.x
	var top: float = spot.top
	var bottom: float = spot.bottom
	var wz: float = spot.z
	var iron := Color("1e2024")
	var reach := 0.62
	kit.box(Vector3(x - 0.05, top - 0.3, wz), Vector3(0.1, 0.36, 0.025), iron)              # wall plate
	kit.box(Vector3(x - 0.016, top - 0.016, wz), Vector3(0.032, 0.032, reach), iron)         # arm
	Dressing._bar(kit.st, kit.base + Vector3(x, top - 0.26, wz + 0.02), kit.base + Vector3(x, top - 0.01, wz + reach * 0.62), 0.012, iron)
	kit.box(Vector3(x - 0.03, top - 0.03, wz + reach - 0.03), Vector3(0.06, 0.06, 0.06), iron.lightened(0.1))  # finial
	var bh := top - 0.06 - bottom
	var bw := bh * 0.82
	var mid := Vector3(x, bottom + bh * 0.5, wz + 0.38)
	var yaw := deg_to_rad(-36.0) * float(spot.side)
	var xf := Transform3D(Basis(Vector3.UP, yaw), mid)
	for hx in [-bw * 0.3, bw * 0.3]:  # the chains (one link each, it is a small sign)
		var top_pt := xf * Vector3(hx, bh * 0.5, 0)
		kit.box(Vector3(top_pt.x - 0.008, top_pt.y, top_pt.z - 0.008), Vector3(0.016, top - 0.016 - top_pt.y, 0.016), iron)
	var frame := Color("2b231d")
	kit.obox(xf, Vector3(-bw * 0.5, -bh * 0.5, -0.025), Vector3(bw, bh, 0.05), frame)
	var field: Color = [Color("2f4f7a"), Color("7a2f2a"), Color("2f5e3a"), Color("8a6a2a"), Color("4a3a5e")][absi(hash(label)) % 5]
	kit.obox(xf, Vector3(-bw * 0.5 + 0.04, -bh * 0.5 + 0.04, 0.025), Vector3(bw - 0.08, bh - 0.08, 0.004), field)
	kit.obox(xf, Vector3(-bw * 0.5 + 0.05, bh * 0.5 - 0.12, 0.029), Vector3(bw - 0.1, 0.06, 0.003), GILT.darkened(0.1))
	_motif(kit, xf, label, bw - 0.08, bh - 0.08, Vector3(0, -0.03, 0.03))

## The picture on a pub sign, chosen from its name: a crown, an anchor, a shamrock, a star, a shield or a pint.
static func _motif(kit: Kit, xf: Transform3D, label: String, mw: float, mh: float, c: Vector3) -> void:
	var n := label.to_lower()
	var m: String = ["tankard", "shield", "star", "crown"][absi(hash(label)) % 4]
	if n.contains("crown") or n.contains("king") or n.contains("royal") or n.contains("george"):
		m = "crown"
	elif n.contains("anchor") or n.contains("harbour") or n.contains("ferry") or n.contains("quay") or n.contains("pier") \
			or n.contains("benbow") or n.contains("dolphin"):
		m = "anchor"
	elif n.contains("arms"):
		m = "shield"
	elif n.contains("tigh") or n.contains("temple") or n.contains("kyteler") or n.contains("plunkett") or n.contains("garavogue") or n.contains("boyne"):
		m = "shamrock"
	var s := minf(mw, mh) * 0.42
	var gold := GILT
	var cream := Color("efe6cf")
	match m:
		"crown":
			var band := c + Vector3(0, -s * 0.55, 0.003)
			kit.obox(xf, band + Vector3(-s * 0.9, 0, 0), Vector3(s * 1.8, s * 0.38, 0.004), gold)
			kit.obox(xf, band + Vector3(-s * 0.9, s * 0.13, 0.001), Vector3(s * 1.8, s * 0.1, 0.004), Color("b8352b"))
			var top := band.y + s * 0.38
			for k in 3:  # three points, the middle one tallest, each with a pearl
				var px := -s * 0.9 + s * 0.9 * k
				var hw := s * 0.42
				var tip := Vector3(c.x + px, top + s * (1.25 if k == 1 else 0.95), band.z)
				var l := Vector3(c.x + clampf(px - hw, -s * 0.9, s * 0.9), top - 0.001, band.z)
				var r := Vector3(c.x + clampf(px + hw, -s * 0.9, s * 0.9), top - 0.001, band.z)
				kit.tri(xf, l, r, tip, gold)
				kit.disc(xf, tip + Vector3(0, s * 0.06, 0.001), s * 0.12, cream)
		"anchor":
			kit.obox(xf, c + Vector3(-s * 0.09, -s * 0.85, 0), Vector3(s * 0.18, s * 1.6, 0.004), cream)
			kit.obox(xf, c + Vector3(-s * 0.55, s * 0.35, 0), Vector3(s * 1.1, s * 0.16, 0.004), cream)
			kit.obox(xf, c + Vector3(-s * 0.85, -s * 0.85, 0), Vector3(s * 1.7, s * 0.18, 0.004), cream)
			kit.obox(xf, c + Vector3(-s * 0.85, -s * 0.85, 0), Vector3(s * 0.18, s * 0.5, 0.004), cream)
			kit.obox(xf, c + Vector3(s * 0.67, -s * 0.85, 0), Vector3(s * 0.18, s * 0.5, 0.004), cream)
			kit.disc(xf, c + Vector3(0, s * 0.85, 0.001), s * 0.2, cream)
		"shamrock":  # three green leaves on a cream roundel
			kit.disc(xf, c, s * 1.05, cream)
			var leaf := Color("2f7a3c")
			for k in 3:
				var ang := PI * 0.5 + TAU * k / 3.0
				kit.disc(xf, c + Vector3(cos(ang) * s * 0.42, sin(ang) * s * 0.42 + s * 0.08, 0.002), s * 0.36, leaf)
			kit.obox(xf, c + Vector3(-s * 0.05, -s * 0.85, 0.002), Vector3(s * 0.1, s * 0.6, 0.003), leaf.darkened(0.2))
		"star":
			for k in 4:
				var b := Basis(Vector3(0, 0, 1), PI * 0.25 * k)
				kit.obox(Transform3D(xf.basis * b, xf * c), Vector3(-s * 0.12, -s, 0), Vector3(s * 0.24, s * 2, 0.004), gold)
			kit.disc(xf, c + Vector3(0, 0, 0.002), s * 0.3, cream)
		"shield":
			kit.obox(xf, c + Vector3(-s * 0.8, -s * 0.3, 0), Vector3(s * 1.6, s * 1.2, 0.004), cream)
			kit.disc(xf, c + Vector3(0, -s * 0.3, 0.0), s * 0.8, cream)
			kit.obox(xf, c + Vector3(-s * 0.8, s * 0.3, 0.002), Vector3(s * 1.6, s * 0.3, 0.004), Color("b8352b"))
			kit.obox(xf, c + Vector3(-s * 0.12, -s * 0.9, 0.002), Vector3(s * 0.24, s * 1.2, 0.004), Color("b8352b"))
		_:  # a pint pot: a tapering glass of ale with a head on it, handle to the right
			var o := c + Vector3(-s * 0.2, 0, 0.003)
			var ale := Color("c98a2e")
			kit.tri(xf, o + Vector3(-s * 0.5, -s * 0.9, 0), o + Vector3(s * 0.5, -s * 0.9, 0), o + Vector3(s * 0.62, s * 0.55, 0), ale)
			kit.tri(xf, o + Vector3(-s * 0.5, -s * 0.9, 0), o + Vector3(s * 0.62, s * 0.55, 0), o + Vector3(-s * 0.62, s * 0.55, 0), ale)
			kit.obox(xf, o + Vector3(-s * 0.66, s * 0.5, 0.001), Vector3(s * 1.32, s * 0.36, 0.004), cream)  # the head
			kit.disc(xf, o + Vector3(-s * 0.32, s * 0.86, 0.001), s * 0.2, cream)
			kit.disc(xf, o + Vector3(s * 0.2, s * 0.88, 0.001), s * 0.24, cream)
			kit.obox(xf, o + Vector3(s * 0.56, s * 0.18, 0), Vector3(s * 0.42, s * 0.13, 0.004), cream.darkened(0.15))  # handle
			kit.obox(xf, o + Vector3(s * 0.56, -s * 0.5, 0), Vector3(s * 0.42, s * 0.13, 0.004), cream.darkened(0.15))
			kit.obox(xf, o + Vector3(s * 0.86, -s * 0.5, 0), Vector3(s * 0.13, s * 0.81, 0.004), cream.darkened(0.15))

## Station: a white-on-enamel name board standing on the canopy's edge (dark red in England and Wales, blue in
## Scotland and Ireland), with a generic rail roundel, and a smaller board on a post at the platform end.
static func _station(kit: Kit, label: String, f: Dictionary, w: int, d: int, region: String) -> void:
	var enamel := ENAMEL_BLUE if region in ["scotland", "ireland", "ireland_west", "ireland_east"] else ENAMEL_RED
	var fnt := font("sans")
	var h: float = float(f.hi) - float(f.lo) - 0.06
	var span: float = float(f.x1) - float(f.x0)
	var mark := h * 0.9
	var fit_w := fit(label, fnt, minf(0.3, h * 0.78), minf(span, 5.0) - mark - 0.4, h * 0.8)
	var bw := minf(span, float(fit_w.width) + mark + 0.5)
	var cx := (float(f.x0) + float(f.x1)) * 0.5
	var y0: float = float(f.lo) + 0.06
	var z0: float = float(f.z) - 0.04
	for px in [cx - bw * 0.36, cx + bw * 0.36]:
		kit.box(Vector3(px - 0.025, float(f.lo) - 0.02, z0 - 0.02), Vector3(0.05, 0.1, 0.04), POST)
	_enamel(kit, Transform3D(Basis(), Vector3(cx, y0 + h * 0.5, z0)), bw, h, enamel)
	var xf := Transform3D(Basis(), Vector3(cx, y0 + h * 0.5, z0 + 0.03))
	_roundel(kit, xf, Vector3(-bw * 0.5 + 0.12 + mark * 0.5, 0, 0.002), mark * 0.4, enamel)
	kit.text(xf, Vector3(mark * 0.5 - 0.02, 0, 0.004), fit_w, fnt, ENAMEL_WHITE)
	# the platform totem, at the west end under the canopy (in front of its beam, so you can see it from the street)
	var tx := 0.55
	var tz := d + 0.75
	kit.box(Vector3(tx - 0.03, 0.0, tz - 0.03), Vector3(0.06, 0.95, 0.06), POST)
	var th := 0.24
	var small := fit(label, fnt, 0.13, 0.9, th * 0.8)
	var tw := float(small.width) + 0.24
	var txf := Transform3D(Basis(), Vector3(tx, 0.95 + th * 0.5, tz))
	_enamel(kit, txf, tw, th, enamel)
	kit.box(Vector3(tx - 0.12, 0.95 + th + 0.01, tz - 0.012), Vector3(0.24, 0.24, 0.024), enamel.darkened(0.2))
	_roundel(kit, Transform3D(Basis(), Vector3(tx, 0.95 + th + 0.13, tz + 0.014)), Vector3.ZERO, 0.095, enamel)
	kit.text(Transform3D(Basis(), Vector3(tx, 0.95 + th * 0.5, tz + 0.03)), Vector3.ZERO, small, fnt, ENAMEL_WHITE)

## An enamel board centred on xf: rolled edge, white keyline.
static func _enamel(kit: Kit, xf: Transform3D, bw: float, h: float, enamel: Color) -> void:
	kit.obox(xf, Vector3(-bw * 0.5 - 0.02, -h * 0.5 - 0.02, -0.02), Vector3(bw + 0.04, h + 0.04, 0.035), enamel.darkened(0.35))
	kit.obox(xf, Vector3(-bw * 0.5, -h * 0.5, 0.0), Vector3(bw, h, 0.025), enamel)
	var k := 0.035
	var t := 0.013
	kit.obox(xf, Vector3(-bw * 0.5 + k, h * 0.5 - k - t, 0.025), Vector3(bw - k * 2, t, 0.003), ENAMEL_WHITE)
	kit.obox(xf, Vector3(-bw * 0.5 + k, -h * 0.5 + k, 0.025), Vector3(bw - k * 2, t, 0.003), ENAMEL_WHITE)
	kit.obox(xf, Vector3(-bw * 0.5 + k, -h * 0.5 + k, 0.025), Vector3(t, h - k * 2, 0.003), ENAMEL_WHITE)
	kit.obox(xf, Vector3(bw * 0.5 - k - t, -h * 0.5 + k, 0.025), Vector3(t, h - k * 2, 0.003), ENAMEL_WHITE)

## A generic rail mark: a white roundel crossed by two rails.
static func _roundel(kit: Kit, xf: Transform3D, c: Vector3, r: float, enamel: Color) -> void:
	kit.disc(xf, c, r, ENAMEL_WHITE)
	kit.obox(xf, c + Vector3(-r * 0.78, r * 0.14, 0.002), Vector3(r * 1.56, r * 0.2, 0.004), enamel)
	kit.obox(xf, c + Vector3(-r * 0.78, -r * 0.34, 0.002), Vector3(r * 1.56, r * 0.2, 0.004), enamel)

## A station name on an enamel board flat on the wall (a signal box, a cliff railway).
static func _rail_board(kit: Kit, label: String, f: Dictionary, w: int, door_x: int, region: String) -> void:
	var enamel := ENAMEL_BLUE if region in ["scotland", "ireland", "ireland_west", "ireland_east"] else ENAMEL_RED
	var fnt := font("sans")
	var h := minf(float(f.hi) - float(f.lo) - 0.04, 0.36)
	var span: float = float(f.x1) - float(f.x0)
	var fit_w := fit(label, fnt, minf(0.3, h * 0.78), span - 0.3, h * 0.8)
	var bw := minf(span, float(fit_w.width) + 0.3)
	var cx := _centre(f, bw, door_x, w)
	var y := float(f.lo) + 0.02 + h * 0.5
	_enamel(kit, Transform3D(Basis(), Vector3(cx, y, float(f.z) + 0.01)), bw, h, enamel)
	kit.text(Transform3D.IDENTITY, Vector3(cx, y, float(f.z) + 0.04), fit_w, fnt, ENAMEL_WHITE)

## A carved name over the door of a museum, library, church or hall: a stone tablet with a moulded frame, the name
## in spaced capitals cut into it. Timber-framed fronts get an oak board instead, and slate cottages a slate one.
static func _heritage(kit: Kit, label: String, f: Dictionary, w: int, door_x: int, style: String) -> void:
	var face := STONE
	var edge := STONE_EDGE
	var ink := INCISED
	var fnt := font("caps")
	if style == "tudor":
		face = OAK
		edge = OAK.darkened(0.3)
		ink = Color("e8dcb8")
		fnt = font("serif")
	elif style == "slate_cottage":
		face = SLATE
		edge = SLATE.darkened(0.3)
		ink = Color("e6e0cf")
	elif style == "stone" or style == "cathedral" or style == "castle" or style == "castle_red" or style == "chapel":
		face = Color("e4dccb")
		edge = Color("9b917e")
	var text := label.to_upper() if fnt == font("caps") else label
	var room: float = float(f.hi) - float(f.lo) - 0.08
	var span: float = float(f.x1) - float(f.x0)
	var em := minf(0.3, room * 0.8)
	var fit_w := fit(text, fnt, em, span - 0.3, room * 0.85)
	var h := minf(room, float(fit_w.height) + 0.11)
	var bw := minf(span, float(fit_w.width) + 0.34)
	var cx := _centre(f, bw, door_x, w)
	var y0: float = float(f.lo) + 0.04
	var z0: float = f.z
	kit.box(Vector3(cx - bw * 0.5 - 0.04, y0 - 0.04, z0), Vector3(bw + 0.08, h + 0.08, 0.045), edge)  # moulding
	kit.box(Vector3(cx - bw * 0.5, y0, z0), Vector3(bw, h, 0.06), face)
	kit.box(Vector3(cx - bw * 0.5 - 0.07, y0 + h + 0.04, z0), Vector3(bw + 0.14, 0.04, 0.09), edge.lightened(0.1))  # hood
	kit.text(Transform3D.IDENTITY, Vector3(cx, y0 + h * 0.5, z0 + 0.064), fit_w, fnt, ink)

## Grand: a keeper's hall gets a black and gold board the width of its front, with lanterns either side.
static func _keeper(kit: Kit, label: String, f: Dictionary, w: int, door_x: int) -> void:
	var fnt := font("caps")
	var text := label.to_upper()
	var span: float = float(f.x1) - float(f.x0)
	var h := minf(float(f.hi) - float(f.lo) - 0.1, 0.5)
	var lamp := 0.3
	var fit_w := fit(text, fnt, minf(0.32, h * 0.8), span - 0.4 - lamp * 2.0, h * 0.85)
	var bw := minf(span - lamp * 2.0, float(fit_w.width) + 0.8)
	var cx := _centre(f, bw + lamp * 2.0, door_x, w)
	var y0: float = float(f.lo) + 0.05
	var z0: float = f.z
	var black := Color("141418")
	var gold := Color("c9a14a")
	var x0 := cx - bw * 0.5
	kit.box(Vector3(x0 - 0.05, y0 - 0.05, z0), Vector3(bw + 0.1, h + 0.1, 0.05), gold.darkened(0.25))
	kit.box(Vector3(x0, y0, z0), Vector3(bw, h, 0.07), black)
	for k in [0.035, 0.07]:
		var t := 0.012
		kit.box(Vector3(x0 + k, y0 + h - k - t, z0 + 0.07), Vector3(bw - k * 2, t, 0.004), gold)
		kit.box(Vector3(x0 + k, y0 + k, z0 + 0.07), Vector3(bw - k * 2, t, 0.004), gold)
		kit.box(Vector3(x0 + k, y0 + k, z0 + 0.07), Vector3(t, h - k * 2, 0.004), gold)
		kit.box(Vector3(x0 + bw - k - t, y0 + k, z0 + 0.07), Vector3(t, h - k * 2, 0.004), gold)
	kit.box(Vector3(x0 - 0.1, y0 + h + 0.05, z0), Vector3(bw + 0.2, 0.05, 0.12), gold.darkened(0.1))  # cornice
	kit.box(Vector3(cx - 0.09, y0 + h + 0.1, z0), Vector3(0.18, 0.1, 0.1), gold)  # keystone
	for lx in [x0 - lamp * 0.5 - 0.06, x0 + bw + lamp * 0.5 + 0.06]:  # lanterns on brackets
		kit.box(Vector3(lx - 0.015, y0 + h * 0.5 + 0.1, z0), Vector3(0.03, 0.03, 0.2), POST)
		kit.box(Vector3(lx - 0.07, y0 + h * 0.5 - 0.12, z0 + 0.1), Vector3(0.14, 0.2, 0.14), Color("3a4658"), 1)
		kit.box(Vector3(lx - 0.09, y0 + h * 0.5 + 0.08, z0 + 0.08), Vector3(0.18, 0.04, 0.18), POST)
		kit.box(Vector3(lx - 0.05, y0 + h * 0.5 - 0.15, z0 + 0.12), Vector3(0.1, 0.03, 0.1), POST)
	kit.text(Transform3D.IDENTITY, Vector3(cx, y0 + h * 0.5, z0 + 0.075), fit_w, fnt, Color("e7c46a"), true)

## A street name plate: black capitals on white, with a black keyline, at the corner of the terrace.
static func _street_plate(kit: Kit, label: String, f: Dictionary) -> void:
	var fnt := font("sans_caps")
	var h := minf(float(f.hi) - float(f.lo) - 0.08, 0.3)
	var fit_w := fit(label.to_upper(), fnt, h * 0.75, float(f.x1) - float(f.x0) - 0.4, h * 0.85)
	var bw := float(fit_w.width) + 0.22
	var cx: float = float(f.x0) + 0.1 + bw * 0.5
	var y := float(f.lo) + 0.06 + h * 0.5
	var xf := Transform3D(Basis(), Vector3(cx, y, float(f.z)))
	kit.obox(xf, Vector3(-bw * 0.5, -h * 0.5, 0), Vector3(bw, h, 0.025), Color("f3f1ea"))
	var k := 0.03
	var t := 0.014
	var ink := Color("17181b")
	kit.obox(xf, Vector3(-bw * 0.5 + k, h * 0.5 - k - t, 0.025), Vector3(bw - k * 2, t, 0.003), ink)
	kit.obox(xf, Vector3(-bw * 0.5 + k, -h * 0.5 + k, 0.025), Vector3(bw - k * 2, t, 0.003), ink)
	kit.obox(xf, Vector3(-bw * 0.5 + k, -h * 0.5 + k, 0.025), Vector3(t, h - k * 2, 0.003), ink)
	kit.obox(xf, Vector3(bw * 0.5 - k - t, -h * 0.5 + k, 0.025), Vector3(t, h - k * 2, 0.003), ink)
	kit.text(xf, Vector3(0, 0, 0.03), fit_w, fnt, ink)

## A house name on a slate over the door.
static func _house_plate(kit: Kit, label: String, f: Dictionary, door_x: int) -> void:
	var fnt := font("serif")
	var h := minf(float(f.hi) - float(f.lo) - 0.06, 0.26)
	var fit_w := fit(label, fnt, h * 0.72, 1.5, h * 0.85)
	var bw := float(fit_w.width) + 0.18
	var cx := _centre(f, bw, door_x, int(float(f.x1) + 0.18))
	var y := float(f.lo) + 0.04 + h * 0.5
	var xf := Transform3D(Basis(), Vector3(cx, y, float(f.z)))
	kit.obox(xf, Vector3(-bw * 0.5, -h * 0.5, 0), Vector3(bw, h, 0.03), SLATE)
	kit.text(xf, Vector3(0, 0, 0.034), fit_w, fnt, Color("ece5d2"))

## A brown tourist sign: white on brown, white keyline, for visitor centres and attractions.
static func _brown_board(kit: Kit, label: String, f: Dictionary, w: int, door_x: int) -> void:
	var fnt := font("sans")
	var h := minf(float(f.hi) - float(f.lo) - 0.06, 0.4)
	var span: float = float(f.x1) - float(f.x0)
	var fit_w := fit(label, fnt, minf(0.3, h * 0.78), span - 0.3, h * 0.8)
	var bw := minf(span, float(fit_w.width) + 0.3)
	var cx := _centre(f, bw, door_x, w)
	var y := float(f.lo) + 0.03 + h * 0.5
	_enamel(kit, Transform3D(Basis(), Vector3(cx, y, float(f.z) + 0.01)), bw, h, BROWN)
	kit.text(Transform3D.IDENTITY, Vector3(cx, y, float(f.z) + 0.04), fit_w, fnt, ENAMEL_WHITE)

## A name on the roofline: painted on a brick panel standing on a mill's cornice (or carved in Portland stone).
static func _parapet(kit: Kit, label: String, f: Dictionary, style: String) -> void:
	var stone := style == "liver_building"
	var fnt := font("caps") if stone else font("sans_caps")
	var text := label.to_upper()
	var h: float = float(f.hi) - float(f.lo)
	var span: float = float(f.x1) - float(f.x0)
	var fit_w := fit(text, fnt, minf(0.36, h * 0.8), span - 0.3, h * 0.85)
	var bw := minf(span, float(fit_w.width) + 0.5)
	var cx: float = (float(f.x0) + float(f.x1)) * 0.5
	var y0: float = f.lo
	var z0: float = float(f.z) - 0.22
	var gold := style == "casino"
	var face := Landmarks.PORTLAND if stone else (Color("d8b04a") if gold else Landmarks.BRICK)
	kit.box(Vector3(cx - bw * 0.5, y0 - 0.02, z0), Vector3(bw, h, 0.22), face)
	kit.box(Vector3(cx - bw * 0.5 - 0.05, y0 + h - 0.02, z0 - 0.03), Vector3(bw + 0.1, 0.07, 0.3), Color("f6f1e4") if gold else Landmarks.LIMESTONE)
	var ink := INCISED if stone else (Color("7a1624") if gold else Color("efe6cf"))
	kit.text(Transform3D.IDENTITY, Vector3(cx, y0 + h * 0.48, z0 + 0.224), fit_w, fnt, ink)

## A cast-iron name plate on an aqueduct's or a bridge's trough: raised cream letters, beaded rim.
static func _iron_plate(kit: Kit, label: String, f: Dictionary) -> void:
	var fnt := font("caps")
	var h: float = float(f.hi) - float(f.lo)
	var fit_w := fit(label.to_upper(), fnt, minf(0.26, h * 0.78), float(f.x1) - float(f.x0) - 0.3, h * 0.84)
	var bw := float(fit_w.width) + 0.34
	var cx: float = (float(f.x0) + float(f.x1)) * 0.5
	var y := float(f.lo) + h * 0.5
	var xf := Transform3D(Basis(), Vector3(cx, y, float(f.z)))
	kit.obox(xf, Vector3(-bw * 0.5, -h * 0.5, 0), Vector3(bw, h, 0.03), IRON.lightened(0.08))
	var rim := IRON.lightened(0.25)
	kit.obox(xf, Vector3(-bw * 0.5, h * 0.5 - 0.03, 0.03), Vector3(bw, 0.03, 0.015), rim)
	kit.obox(xf, Vector3(-bw * 0.5, -h * 0.5, 0.03), Vector3(bw, 0.03, 0.015), rim)
	kit.obox(xf, Vector3(-bw * 0.5, -h * 0.5, 0.03), Vector3(0.03, h, 0.015), rim)
	kit.obox(xf, Vector3(bw * 0.5 - 0.03, -h * 0.5, 0.03), Vector3(0.03, h, 0.015), rim)
	kit.text(xf, Vector3(0, 0, 0.034), fit_w, fnt, Color("e9e0c4"))

## A heritage interpretation board on two posts just in front of a landmark with no wall for a name (a round
## tower, a crane, a monument), its face tipped back toward you; a brown one for an attraction.
static func _lectern(kit: Kit, label: String, t: String, x: float, zf: float) -> void:
	var brown := t == "tourist"
	var fnt := font("sans") if brown else font("serif")
	var face := BROWN if brown else Color("23392d")
	var bw := 1.15
	var bh := 0.62
	var xf := _lectern_frame(x, zf)
	for px in [-bw * 0.36, bw * 0.36]:
		kit.box(Vector3(x + px - 0.03, 0.0, zf - 0.03), Vector3(0.06, 0.6, 0.06), POST)
	kit.obox(xf, Vector3(-bw * 0.5 - 0.03, -bh * 0.5 - 0.03, -0.04), Vector3(bw + 0.06, bh + 0.06, 0.04), POST)
	kit.obox(xf, Vector3(-bw * 0.5, -bh * 0.5, 0.0), Vector3(bw, bh, 0.01), face)
	var ink := ENAMEL_WHITE if brown else Color("efe6cf")
	var fit_w := _lectern_fit(label, t)
	kit.text(xf, Vector3(0, bh * 0.22, 0.014), fit_w, fnt, ink)
	# the "body text" and a picture, too small to read: enough to say what kind of board it is
	kit.obox(xf, Vector3(-bw * 0.5 + 0.07, -bh * 0.5 + 0.07, 0.01), Vector3(bw * 0.38, bh * 0.4, 0.004), Color("8fa89a") if not brown else Color("c9b38f"))
	for k in 4:
		kit.obox(xf, Vector3(-bw * 0.5 + 0.12 + bw * 0.38, -bh * 0.5 + 0.09 + k * 0.065, 0.01), Vector3(bw * 0.42 - (0.08 if k == 3 else 0.0), 0.022, 0.004), ink.darkened(0.25))

## Where a board on posts can stand and be seen from `eye`: beside the door, the other side of it, or mid-front,
## each clear of a porch or a veranda rather than under it. {x, z, hidden (of 15 points on its name)}: the
## first that shows whole, else the one hidden least.
static func _stand_spot(kit: Kit, name_fit: Dictionary, w: int, d: int, door_x: int, eye: Vector3) -> Dictionary:
	var xs := [_stand_x(w, door_x)]
	if door_x >= 0:
		xs.append(clampf(door_x + 0.5 - (float(xs[0]) - door_x - 0.5), 0.6, maxf(0.6, w - 0.6)))
	xs.append(w * 0.5)
	var hy := float(name_fit.height) if int(name_fit.lines) > 1 else float(name_fit.em) * 0.72
	var best := {}
	for x: float in xs:
		var zf := clampf(kit.sight.reach(kit.body as MeshInstance3D, x - 0.6, x + 0.6, 0.15, 2.0, d + 1.2) + 0.3, d + 0.2, d + 0.85)
		var xf := _lectern_frame(x, zf)
		var n := 0
		for k in 5:  # across the name (see _lectern)
			for v in [-0.4, 0.0, 0.4]:
				var u := (k / 4.0 - 0.5) * float(name_fit.width)
				if kit.sight.blocked(kit.base + xf * Vector3(u, 0.136 + v * hy, 0.034), eye):
					n += 1
		if best.is_empty() or n < int(best.hidden):
			best = {"x": x, "z": zf, "hidden": n}
		if n == 0:
			break
	return best

## A lectern's name, fitted to its 1.15 x 0.62 board.
static func _lectern_fit(label: String, t: String) -> Dictionary:
	return fit(label, font("sans") if t == "tourist" else font("serif"), 0.2, 1.15 - 0.14, 0.62 * 0.42)

## The board's face, tipped back toward you, at x and zf on the front.
static func _lectern_frame(x: float, zf: float) -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-50.0)), Vector3(x, 0.62, zf))

## Beside the door (or mid-front without one), on the side with room.
static func _stand_x(w: int, door_x: int) -> float:
	var x := w * 0.5
	if door_x >= 0:
		x = door_x + 0.5 + (1.3 if door_x + 2.0 < w else -1.3)
	return clampf(x, 0.6, maxf(0.6, w - 0.6))

## A modern building's name: white capitals on a dark granite slab standing on a plinth by the entrance.
static func _monolith(kit: Kit, label: String, w: int, d: int, door_x: int) -> void:
	var fnt := font("sans_caps")
	var x := _stand_x(w, door_x)
	var zf := d + 0.28
	var granite := Color("2a2e35")
	var fit_w := fit(label.to_upper(), fnt, 0.2, 1.3, 0.42)
	var bw := maxf(1.0, float(fit_w.width) + 0.3)
	var bh := 0.62
	kit.box(Vector3(x - bw * 0.5 - 0.05, 0.0, zf - 0.14), Vector3(bw + 0.1, 0.1, 0.24), granite.lightened(0.25))
	var xf := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-14.0)), Vector3(x, 0.1 + bh * 0.5, zf))
	kit.obox(xf, Vector3(-bw * 0.5, -bh * 0.5, -0.07), Vector3(bw, bh, 0.14), granite)
	kit.obox(xf, Vector3(-bw * 0.5 + 0.08, -bh * 0.5 + 0.1, 0.07), Vector3(bw - 0.16, 0.014, 0.003), Color("9aa3ad"))
	kit.text(xf, Vector3(0, 0.05, 0.074), fit_w, fnt, Color("f1f1ee"))
