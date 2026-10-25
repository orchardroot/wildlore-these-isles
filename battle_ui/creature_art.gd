class_name CreatureArt
extends RefCounted
## Finds a creature's battle sprite sheet (two 96x96 idle frames side by side) and never fails:
## real art if present, then the shared placeholder files, then a runtime "?" silhouette in the creature's type colour.

const DIR := "res://art/sprites/creatures/"
const FRAME := 96

static var _cache := {}

## `sex` ("m" or "f") picks the sheet drawn for that sex when the species has one (see Sexes).
static func texture(species: Dictionary, back: bool, sex := "") -> Texture2D:
	var id := str(species.get("sprite", species.get("id", "")))
	var side := "back" if back else "front"
	var stem := Sexes.art_id(id, side, sex)
	var key := "%s/%s" % [stem, side]
	if _cache.has(key):
		return _cache[key]
	if Crossbreeds.is_id(id):  # blended at runtime from its parents (ui/crossbreed_art.gd)
		var xt := CrossbreedArt.texture(species if species.has("crossbreed") else Crossbreeds.lookup(id), side)
		if xt != null:
			_cache[key] = xt
			return xt
	var tex: Texture2D = _load(Sexes.sheet_path(id, side, sex))
	if tex == null:
		tex = _load("%s_placeholder_%s.png" % [DIR, side])
	if tex == null:
		var types: Array = species.get("types", [])
		tex = ImageTexture.create_from_image(placeholder_image(types[0] if not types.is_empty() else "", back))
	_cache[key] = tex
	return tex

static func icon(species: Dictionary, sex := "") -> Texture2D:
	var id := str(species.get("sprite", species.get("id", "")))
	if Crossbreeds.is_id(id):
		var xt := CrossbreedArt.texture(species if species.has("crossbreed") else Crossbreeds.lookup(id), "icon")
		if xt != null:
			return xt
	var tex: Texture2D = _load(Sexes.sheet_path(id, "icon", sex))
	if tex == null:
		tex = _load("%s_placeholder_icon.png" % DIR)
	if tex == null:
		var img := placeholder_image(str(species.get("types", [""])[0]), false)
		img.crop(FRAME, FRAME)
		img.resize(32, 32, Image.INTERPOLATE_NEAREST)
		tex = ImageTexture.create_from_image(img)
	return tex

static func _load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t = load(path)
		if t is Texture2D:
			return t
	if FileAccess.file_exists(path):  # art that has not been imported yet (fresh checkout, headless run)
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

const _QUESTION := ["01110", "10001", "00001", "00110", "00100", "00000", "00100"]

## 192x96 sheet: two frames of a chunky silhouette with a "?" on it.
static func placeholder_image(type_id: String, back: bool) -> Image:
	var img := Image.create(FRAME * 2, FRAME, false, Image.FORMAT_RGBA8)
	var base := TypeColours.of(type_id) if type_id != "" else Color("8c8c8c")
	for f in 2:
		var ox := f * FRAME
		var bob := f * 2
		_ellipse(img, ox + 48, 62 - bob, 28, 24 + bob, base.darkened(0.45))
		_ellipse(img, ox + 48, 34 - bob, 18, 18, base.darkened(0.45))
		_ellipse(img, ox + 48, 62 - bob, 26, 22 + bob, base)
		_ellipse(img, ox + 48, 34 - bob, 16, 16, base.lightened(0.08))
		_ellipse(img, ox + 48, 70 - bob, 20, 12, base.lightened(0.18))
		if not back:
			for ex in [40, 56]:
				_ellipse(img, ox + ex, 32 - bob, 3, 4, Color("1b1d26"))
		var cream := Color("f4ecd8")
		for ry in _QUESTION.size():
			for rx in 5:
				if _QUESTION[ry][rx] == "1":
					img.fill_rect(Rect2i(ox + 38 + rx * 4, 52 - bob + ry * 4, 4, 4), cream if not back else cream.darkened(0.15))
	return img

static func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for y in range(maxi(0, cy - ry), mini(img.get_height(), cy + ry + 1)):
		for x in range(maxi(0, cx - rx), mini(img.get_width(), cx + rx + 1)):
			var dx := float(x - cx) / rx
			var dy := float(y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)
