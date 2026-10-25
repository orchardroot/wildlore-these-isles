class_name AnimSprite
extends TextureRect
## A creature front sprite (two idle frames) or icon at an integer scale of its 96 (or 32) px size. Never crashes on
## missing art. Front sheets are drawn at a higher resolution than they show (see tools/spritegen/creature.gd), so
## they are filtered smoothly; icons stay crisp.

const PLACEHOLDER_FRONT := "res://art/sprites/creatures/_placeholder_front.png"
const PLACEHOLDER_ICON := "res://art/sprites/creatures/_placeholder_icon.png"
static var _fallback := {}

var species_id := ""
var silhouette := false
var _frames: Array = []
var _frame := 0
var _t := 0.0
var _px := 96

## kind: "front" (96 px frames, animated) or "icon" (32 px). `variant`: an uncommon coat (see CoatArt), "" for none; `form`: a regional form (see FormArt);
## `sex`: "m" or "f", for the sheet of a species whose sexes differ (see Sexes), else the usual one.
func show_species(id: String, kind := "front", scale_factor := 2, as_silhouette := false, variant := "", form := "", sex := "") -> void:
	species_id = id
	silhouette = as_silhouette
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_px = 96 if kind == "front" else 32
	custom_minimum_size = Vector2(_px, _px) * scale_factor
	size = custom_minimum_size
	modulate = Color.BLACK if as_silhouette else Color.WHITE
	_frames = []
	var stem := Sexes.art_id(id, kind, sex)
	var base_sheet := load_sheet(id, kind, sex)
	if form != "" and not as_silhouette:  # a regional form first (see FormArt), then any coat over it
		base_sheet = FormArt.texture(base_sheet, stem + "_" + kind, id, form)
	var sheet := CoatArt.texture(base_sheet, stem + "_" + kind + "#" + form, "" if as_silhouette else variant)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if kind == "front":
		var fp := maxi(1, sheet.get_height())  # frames are square: as wide as the sheet is tall
		if fp > _px:
			texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var n := maxi(1, sheet.get_width() / fp)
		for i in mini(n, 2):
			var a := AtlasTexture.new()
			a.atlas = sheet
			a.region = Rect2(i * fp, 0, fp, fp)
			_frames.append(a)
	else:
		_frames.append(sheet)
	_frame = 0
	texture = _frames[0]
	set_process(_frames.size() > 1)

func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.6:
		_t = 0.0
		_frame = (_frame + 1) % _frames.size()
		texture = _frames[_frame]

## The sprite sheet for a species, a placeholder file, or a runtime "?" if both are missing.
static func load_sheet(id: String, kind: String, sex := "") -> Texture2D:
	if Crossbreeds.is_id(id):  # no file: blended from its parents (ui/crossbreed_art.gd)
		var xt := CrossbreedArt.texture(Crossbreeds.lookup(id), kind)
		if xt != null:
			return xt
	var path := Sexes.sheet_path(id, kind, sex)
	if id != "" and ResourceLoader.exists(path):
		var t = load(path)
		if t is Texture2D:
			return t
	var p := PLACEHOLDER_FRONT if kind == "front" else PLACEHOLDER_ICON
	if ResourceLoader.exists(p):
		var t = load(p)
		if t is Texture2D:
			return t
	return _question_mark(kind)

static func _question_mark(kind: String) -> Texture2D:
	if _fallback.has(kind):
		return _fallback[kind]
	var glyph := ["01110", "10001", "00001", "00110", "00100", "00000", "00100"]
	var px := 96 if kind == "front" else 32
	var frames := 2 if kind == "front" else 1
	var img := Image.create(px * frames, px, false, Image.FORMAT_RGBA8)
	var cell := px / 10
	for f in frames:
		var ox := f * px + (px - 5 * cell) / 2
		var oy := (px - 7 * cell) / 2 + f * 2
		for y in 7:
			for x in 5:
				if glyph[y][x] == "1":
					img.fill_rect(Rect2i(ox + x * cell, oy + y * cell, cell, cell), Color("a9a294"))
	var tex := ImageTexture.create_from_image(img)
	_fallback[kind] = tex
	return tex
