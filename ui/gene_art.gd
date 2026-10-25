class_name GeneArt
extends RefCounted
## What a bred creature looks like (docs/design/2026-10-21-breeding.md, 7): the species' own art, or a blend of two
## recipes for a hybrid (tools/spritegen/blend.gd), with its genome's showing applied: Mark thickens or thins the
## patterns, Ginger warms the palette, Frame scales it (size 4 of 8 is the usual 1.0), Tint gives a coat, two tints a
## roan, and a ginger carrier in the two-copy sex a tortoiseshell (see CoatArt.recolour).
## Rendered once per look and cached (the key is the whole look, so equal genomes share a texture), at preview and
## hatch rather than per frame. A creature whose showing is the stock look gets the stock texture, no rendering at all.
##
## GeneArt.texture(c, kind) -> Texture2D, kind "front" (two square frames side by side, 384x192 as rendered here),
## "back" (the same) or "icon" (32x32). Consumers take the frame size from the sheet's height.

const Creature = preload("res://tools/spritegen/creature.gd")
const Blend = preload("res://tools/spritegen/blend.gd")
const RECIPES := "res://art/recipes/creatures/"
const KINDS := ["front", "back", "icon"]
const MAX_CACHED := 48            # looks, not textures: bounded so a long session on a small machine stays small
const FRAME_MIN := 0.9
const FRAME_MAX := 1.1

static var _cache := {}           # look key -> {front, back, icon}
static var _order: Array = []
static var _recipes := {}

static func texture(c: Creature, kind: String) -> Texture2D:
	if not (kind in KINDS):
		kind = "front"
	var look := look_of(c)
	if look.stock:
		return _stock(c, kind)
	var key: String = look.key
	if not _cache.has(key):
		_remember(key, _build(c, look))
	var set: Dictionary = _cache[key]
	return set.get(kind, _stock(c, kind))

## Everything about how a creature looks that the genome decides, and a string that names it. `stock` means
## nothing differs from the species' ordinary art.
static func look_of(c: Creature) -> Dictionary:
	var sh := Genetics.showing(c)
	var variant := str(sh.variant)
	if sh.tortie:
		variant = "tortie" if variant == "" else variant + "+tortie"
	var spec := hybrid_spec(c)
	var frame := int(sh.frame)
	var scale := scale_of(frame)
	var mark := int(sh.mark)
	var hue := float(sh.hue)
	var stock := spec.is_empty() and mark == 1 and hue == 0.0 and frame == 4 and variant == ""
	var body := str(spec.get("body", ""))
	var face := str(spec.get("face", ""))
	return {
		"stock": stock, "spec": spec, "variant": variant, "scale": scale, "mark": mark, "hue": hue,
		"key": "%s|%s|%s|%s|%d|%d|%s" % [Sexes.art_id(str(c.species.get("sprite", c.species.get("id", ""))), "front", c.sex), body, face,
			str(spec.get("palette", "")), mark, frame, "%s|%s" % [variant, hue]],
	}

static func scale_of(frame: int) -> float:
	return lerpf(FRAME_MIN, FRAME_MAX, clampf(float(frame) / 8.0, 0.0, 1.0))

## {body, face, palette} line ids for a hybrid, {} for a purebred. The entry's sprite spec may name a line, or say
## "dam" / "sire" (or nothing) for the first listed line of that parent.
static func hybrid_spec(c: Creature) -> Dictionary:
	if c.hybrid == "":
		return {}
	var h: Dictionary = Genetics.hybrids().get(c.hybrid, {})
	if h.is_empty():
		return {}
	var sp: Dictionary = h.get("sprite", {})
	var dam_lines: Array = h.get("dam_lines", [])
	var sire_lines: Array = h.get("sire_lines", [])
	var body := str(sp.get("body", "dam"))
	var face := str(sp.get("face", "sire"))
	if body == "dam" or body == "":
		body = str(dam_lines[0]) if not dam_lines.is_empty() else ""
	elif body == "sire":
		body = str(sire_lines[0]) if not sire_lines.is_empty() else ""
	if face == "sire" or face == "":
		face = str(sire_lines[0]) if not sire_lines.is_empty() else ""
	elif face == "dam":
		face = str(dam_lines[0]) if not dam_lines.is_empty() else ""
	if body == "" or face == "":
		return {}
	return {"body": body, "face": face, "palette": str(sp.get("palette", "mix"))}

static func recipe(id: String) -> Dictionary:
	if not _recipes.has(id):
		var d = JsonUtil.read(RECIPES + id + ".json")
		_recipes[id] = d if d is Dictionary else {}
	return _recipes[id]

## The recipe for a look, or {} if a parent has none (the species' own art is used then).
static func recipe_for(c: Creature, look: Dictionary) -> Dictionary:
	var spec: Dictionary = look.spec
	var sh := {"mark": look.mark, "hue": look.hue}
	if spec.is_empty():
		var r := recipe(str(c.species.get("sprite", c.species.get("id", ""))))
		return Blend.modify(r, sh) if not r.is_empty() else {}
	var body := recipe(spec.body)
	var face := recipe(spec.face)
	if body.is_empty() or face.is_empty():
		return {}
	return Blend.blend(face, body, spec, sh)

static func _build(c: Creature, look: Dictionary) -> Dictionary:
	var out := {}
	var r := recipe_for(c, look)
	if r.is_empty():
		for k in KINDS:
			out[k] = _stock(c, k)
	else:
		var sheets: Dictionary = Creature.render(r)
		for k in KINDS:
			out[k] = ImageTexture.create_from_image(_finish(sheets[k], k, look))
		return out
	# no recipe (a creature with only a PNG): the stock art still gets its coat and size
	for k in KINDS:
		var base: Texture2D = _stock(c, k)
		var img := base.get_image()
		if img == null or img.is_empty():
			continue
		img = img.duplicate()
		if img.is_compressed():
			img.decompress()
		out[k] = ImageTexture.create_from_image(_finish(img, k, look))
	return out

static func _finish(img: Image, kind: String, look: Dictionary) -> Image:
	var out: Image = img.duplicate()
	out.convert(Image.FORMAT_RGBA8)
	if str(look.variant) != "":
		CoatArt.recolour(out, str(look.variant))
	var s: float = look.scale
	if absf(s - 1.0) > 0.001:
		out = _scaled(out, s, kind)
	return out

## Each square frame (or the 32 px icon) scaled about the feet and clipped to its own box, so it can never bleed.
## A fine sheet is resampled smoothly; the icon and old 96 px art stay crisp.
static func _scaled(img: Image, s: float, kind: String) -> Image:
	var fw := 32 if kind == "icon" else img.get_height()
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var frames := img.get_width() / fw
	var nw := maxi(1, int(round(fw * s)))
	var nh := maxi(1, int(round(img.get_height() * s)))
	for f in frames:
		var part := img.get_region(Rect2i(f * fw, 0, fw, img.get_height()))
		part.resize(nw, nh, Image.INTERPOLATE_BILINEAR if fw > Creature.SIZE else Image.INTERPOLATE_NEAREST)
		var dx := (fw - nw) / 2
		var dy := img.get_height() - nh
		var src := Rect2i(maxi(0, -dx), maxi(0, -dy), mini(nw, fw), mini(nh, img.get_height()))
		out.blit_rect(part, src, Vector2i(f * fw + maxi(0, dx), maxi(0, dy)))
	return out

static func _stock(c: Creature, kind: String) -> Texture2D:
	if kind == "icon":
		return CreatureArt.icon(c.species, c.sex)
	return CreatureArt.texture(c.species, kind == "back", c.sex)

static func _remember(key: String, set: Dictionary) -> void:
	_cache[key] = set
	_order.append(key)
	while _order.size() > MAX_CACHED:
		_cache.erase(_order.pop_front())

static func clear_cache() -> void:
	_cache.clear()
	_order.clear()
	_recipes.clear()
