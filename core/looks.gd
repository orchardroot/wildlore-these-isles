class_name Looks
extends RefCounted
## The player's look (4.6): who you are and what you're wearing, as a character recipe for the painter in
## tools/spritegen/character.gd. Pure logic (the validator loads it): no autoloads.
##
## `GameStateData.look` is the base look: {"sex": "m"|"f", "build": "slight"|"adult", "skin": <index into
## data/looks.json skins>, "hair": <style id>, "hair_colour": <index into hair_colours>, "top": <index into tops>,
## "wearing": {slot: item_id}} plus optional "colours": {bottom, shoes, accent2} hex overrides (an old save's
## sprite converted). Empty on saves from before 4.6: then the `player_sprite` flag (player_a / player_b) rules and
## nothing changes for them until they visit the mirror or a boutique, when `ensure` converts it losslessly.
##
## Wear items (data/items/wear.json, kind "wear") carry a `slot` and a `look` delta: palette keys to set, scalar keys
## (hat, bottom_style, sleeves, hair) to set and accessories to add. Deltas apply in SLOT_ORDER, later wins.

const Character = preload("res://tools/spritegen/character.gd")

const DATA_PATH := "res://data/looks.json"
const SLOTS := ["hat", "top", "bottom", "shoes", "coat", "neck", "face", "hands", "back"]
const SLOT_ORDER := ["bottom", "shoes", "top", "coat", "neck", "back", "hands", "face", "hat"]
const SEXES := ["m", "f"]
const SEX_NAMES := {"m": "Male", "f": "Female"}
const FORMS := ["he", "him", "his", "Mr", "man"]
const PRONOUN_TABLE := {
	"m": ["he", "him", "his", "Mr", "man"],
	"f": ["she", "her", "her", "Ms", "woman"],
}
const LEGACY := {"player_a": "res://art/recipes/chars/player_a.json", "player_b": "res://art/recipes/chars/player_b.json"}
const LEGACY_BY_SEX := {"m": "player_a", "f": "player_b"}  # the two old sprites: him and her
const PALETTE_KEYS := ["skin", "hair", "top", "bottom", "shoes", "accent", "accent2", "glasses", "hat", "beard", "prop", "pin", "light", "leaf"]

static var _db: Dictionary = {}
static var _legacy: Dictionary = {}

static func db() -> Dictionary:
	if _db.is_empty():
		_db = JsonUtil.read(DATA_PATH)
	return _db

static func skins() -> Array:
	return db().get("skins", [])

static func hair_styles() -> Array:
	return db().get("hair", [])

static func hair_colours() -> Array:
	return db().get("hair_colours", [])

static func builds() -> Array:
	return db().get("builds", [])

static func tops() -> Array:
	return db().get("tops", [])

## A fresh base look: male, slight, fair, short dark hair, a teal top.
static func default_base() -> Dictionary:
	return {"sex": "m", "build": "slight", "skin": 1, "hair": "short", "hair_colour": 1, "top": 0, "wearing": {}}

## The creator's starting look for a sex: the old player_a for him, player_b for her (every slider free after).
static func starter(sex: String) -> Dictionary:
	return _legacy_base(str(LEGACY_BY_SEX.get(sex, "player_a")))

static func _legacy_recipe(sprite: String) -> Dictionary:
	if not LEGACY.has(sprite):
		sprite = "player_a"
	if not _legacy.has(sprite):
		_legacy[sprite] = JsonUtil.read(LEGACY[sprite])
	return _legacy[sprite]

static func _legacy_sprite(data: GameStateData) -> String:
	return str(data.flags.get("player_sprite", "player_a"))

static func _index_of(list: Array, hex: String, fallback: int) -> int:
	for i in list.size():
		if str(list[i].get("hex", "")) == hex:
			return i
	return fallback

## An old save's sprite as a base look, colour for colour.
static func _legacy_base(sprite: String) -> Dictionary:
	var r := _legacy_recipe(sprite)
	var pal: Dictionary = r.get("palette", {})
	var b := default_base()
	b.sex = "f" if sprite == "player_b" else "m"
	b.build = "slight"
	b.skin = _index_of(skins(), str(pal.get("skin", "")), 1)
	b.hair = str(r.get("hair", "short"))
	b.hair_colour = _index_of(hair_colours(), str(pal.get("hair", "")), 1)
	b.top = _index_of(tops(), str(pal.get("top", "")), 0)
	b.colours = {"bottom": str(pal.get("bottom", "#3a4a7a")), "shoes": str(pal.get("shoes", "#f2f0ea")), "accent2": str(pal.get("accent2", "#e8863a"))}
	return b

## The base look: the save's, or an old save's sprite read as one. Never writes.
static func base(data: GameStateData) -> Dictionary:
	if data.look.is_empty():
		return _legacy_base(_legacy_sprite(data))
	var b := default_base()
	b.merge(data.look, true)
	if typeof(b.wearing) != TYPE_DICTIONARY:
		b.wearing = {}
	if not str(b.sex) in SEXES:
		b.sex = "m"
	return b

## Materialises the base on an old save, so the Wardrobe and the boutiques have something to write into.
static func ensure(data: GameStateData) -> void:
	if data.look.is_empty():
		data.look = _legacy_base(_legacy_sprite(data))

static func _hex(list: Array, idx: int, fallback: String) -> String:
	if idx >= 0 and idx < list.size():
		return str(list[idx].get("hex", fallback))
	return fallback

## The undressed recipe a base look paints.
static func from_base(b: Dictionary) -> Dictionary:
	var paint := "child"
	for bd in builds():
		if str(bd.id) == str(b.get("build", "slight")):
			paint = str(bd.get("paint", "child"))
	var defs: Dictionary = db().get("defaults", {})
	var cols: Dictionary = b.get("colours", {})
	return {"id": "player", "build": paint,
		"palette": {"skin": _hex(skins(), int(b.get("skin", 1)), "#f2c9a0"), "hair": _hex(hair_colours(), int(b.get("hair_colour", 1)), "#4a2e22"),
			"top": _hex(tops(), int(b.get("top", 0)), "#2f8c9a"), "bottom": str(cols.get("bottom", defs.get("bottom", "#3a4a7a"))),
			"shoes": str(cols.get("shoes", defs.get("shoes", "#f2f0ea"))), "accent2": str(cols.get("accent2", defs.get("accent2", "#e8863a")))},
		"hair": str(b.get("hair", "short")), "hat": "none", "bottom_style": "trousers", "sleeves": "long", "accessories": ["backpack"]}

## The full recipe to paint: the base look with everything worn on top. `items` defaults to the game's ItemDB.
static func recipe(data: GameStateData, items: ItemDB = null) -> Dictionary:
	var r: Dictionary
	if data.look.is_empty():
		r = _legacy_recipe(_legacy_sprite(data)).duplicate(true)
	else:
		r = from_base(base(data))
	var wearing: Dictionary = base(data).wearing
	if wearing.is_empty():
		return r
	if items == null:
		items = ItemDB.load_default()
	for slot in SLOT_ORDER:
		var id := str(wearing.get(slot, ""))
		if id == "" or not items.has(id):
			continue
		var it := items.get_item(id)
		if str(it.get("kind", "")) != "wear":
			continue
		apply_delta(r, it.get("look", {}))
	return r

## Lays a delta over a recipe in place: palette keys set, scalars set, accessories unioned.
static func apply_delta(r: Dictionary, d: Dictionary) -> void:
	for k in d:
		if k == "palette":
			if not r.has("palette"):
				r["palette"] = {}
			for pk in d.palette:
				r.palette[pk] = str(d.palette[pk])
		elif k == "accessories":
			if not r.has("accessories"):
				r["accessories"] = []
			for a in d.accessories:
				if not str(a) in r.accessories:
					r.accessories.append(str(a))
		else:
			r[k] = d[k]

## The recipe with one more item tried on (a boutique's preview). Never writes.
static func preview(data: GameStateData, item_id: String, items: ItemDB) -> Dictionary:
	var r := recipe(data, items)
	var it := items.get_item(item_id)
	if str(it.get("kind", "")) == "wear":
		apply_delta(r, it.get("look", {}))
	return r

## What's worn in a slot (an item id), or "".
static func worn(data: GameStateData, slot: String) -> String:
	return str(base(data).wearing.get(slot, ""))

## The name of what's worn in a slot, or "" (shopkeepers' lines).
static func worn_name(data: GameStateData, slot: String, items: ItemDB) -> String:
	var id := worn(data, slot)
	return str(items.get_item(id).get("name", id)) if id != "" and items.has(id) else ""

## Puts a wear item on in its slot. Returns "" or why not. Owning it is the caller's check.
static func wear(data: GameStateData, item_id: String, items: ItemDB) -> String:
	var it := items.get_item(item_id)
	if str(it.get("kind", "")) != "wear" or not str(it.get("slot", "")) in SLOTS:
		return "That's not something you can wear."
	ensure(data)
	if typeof(data.look.get("wearing")) != TYPE_DICTIONARY:
		data.look["wearing"] = {}
	data.look.wearing[str(it.slot)] = item_id
	return ""

static func take_off(data: GameStateData, slot: String) -> void:
	ensure(data)
	if typeof(data.look.get("wearing")) == TYPE_DICTIONARY:
		data.look.wearing.erase(slot)

## Hair style and colour, free at the mirror.
static func set_hair(data: GameStateData, style: String, colour: int) -> void:
	ensure(data)
	if hair_styles().any(func(h): return str(h.id) == style):
		data.look["hair"] = style
	data.look["hair_colour"] = clampi(colour, 0, hair_colours().size() - 1)

static func _hex_ok(v) -> bool:
	var s := str(v)
	return s.length() == 7 and s[0] == "#" and s.substr(1).is_valid_hex_number(false)

## A wear item's look delta against the painter's vocabulary: hats, hair, bottom styles, sleeves, accessories,
## palette keys with #rrggbb colours. Nothing else (a garment never changes your build or skin).
static func valid_delta(d: Dictionary) -> bool:
	if d.is_empty():
		return false
	for k in d:
		if k == "palette":
			if typeof(d[k]) != TYPE_DICTIONARY:
				return false
			for pk in d[k]:
				if not str(pk) in PALETTE_KEYS or not _hex_ok(d[k][pk]):
					return false
		elif k == "accessories":
			if typeof(d[k]) != TYPE_ARRAY:
				return false
			for a in d[k]:
				if not str(a) in Character.ACCESSORIES:
					return false
		elif Character.VOCAB.has(k):
			if not str(d[k]) in Character.VOCAB[k]:
				return false
		else:
			return false
	return true

## A whole recipe reads as one the painter knows (the creator and the tests).
static func valid_recipe(r: Dictionary) -> bool:
	if not str(r.get("build", "adult")) in Character.BUILDS.keys():
		return false
	var d := r.duplicate(true)
	for k in ["id", "build"]:
		d.erase(k)
	if d.get("hat", "none") == "none":
		d.erase("hat")
	return d.is_empty() or valid_delta(d)

## The validator: every wear item has a slot, a price and a delta the painter can draw; data/looks.json is sound.
static func check(items: ItemDB) -> Array:
	var errors := []
	for id in items.ids():
		var it := items.get_item(id)
		if str(it.get("kind", "")) != "wear":
			continue
		if not str(it.get("slot", "")) in SLOTS:
			errors.append("wear item '%s': slot '%s' is not one of %s" % [id, it.get("slot", ""), ", ".join(SLOTS)])
		if typeof(it.get("look")) != TYPE_DICTIONARY or not valid_delta(it.get("look", {})):
			errors.append("wear item '%s': look delta is not in the painter's vocabulary (see core/looks.gd)" % id)
		if int(it.get("price", 0)) <= 0:
			errors.append("wear item '%s': needs a price" % id)
	for h in hair_styles():
		if not str(h.get("id", "")) in Character.HAIRS:
			errors.append("looks.json: hair style '%s' is unknown to character.gd" % h.get("id", ""))
	for list in ["skins", "hair_colours", "tops"]:
		for e in db().get(list, []):
			if not _hex_ok(e.get("hex", "")):
				errors.append("looks.json: %s '%s' needs a #rrggbb hex" % [list, e.get("id", "")])
	return errors

## Save data in: a Dictionary with whole-number indexes, or {} for anything else (an old save has none).
static func sanitise(v) -> Dictionary:
	if typeof(v) != TYPE_DICTIONARY:
		return {}
	var out: Dictionary = v.duplicate(true)
	for k in ["skin", "hair_colour", "top"]:
		if out.has(k):
			out[k] = int(out[k])
	if typeof(out.get("wearing", {})) != TYPE_DICTIONARY:
		out["wearing"] = {}
	if out.has("sex") and not str(out.sex) in SEXES:
		out.erase("sex")
	return out

## The player's sex, "m" or "f" (old saves: player_a is him, player_b is her).
static func sex(data: GameStateData) -> String:
	return str(base(data).sex)

## A word for the player's sex: forms he (he / she), him (him / her), his (his / her), Mr (Mr / Ms) and man
## (man / woman). A capitalised form (He, His, Man) capitalises the word. Unknown forms are "".
static func pronoun(data: GameStateData, form: String) -> String:
	var row: Array = PRONOUN_TABLE[sex(data)]
	var i := FORMS.find(form)
	if i >= 0:
		return str(row[i])
	i = FORMS.find(form.to_lower())
	if i < 0 or form == "" or form == "mr":
		return ""
	return str(row[i]).capitalize()

## Dialogue substitution: {he} {him} {his} {Mr} {man} and the capitalised {He} {Him} {His} {Man}.
static func sub(data: GameStateData, s: String) -> String:
	if not "{" in s:
		return s
	for f in FORMS:
		var tag := "{%s}" % f
		if tag in s:
			s = s.replace(tag, pronoun(data, f))
		if f != "Mr":
			var cap := "{%s}" % f.capitalize()
			if cap in s:
				s = s.replace(cap, pronoun(data, f.capitalize()))
	return s
