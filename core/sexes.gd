class_name Sexes
extends RefCounted
## Male and female creatures, pure (no autoloads): the words and colours for a creature's sex, which kindreds have
## one, filling in a missing sex on an old save, the sprite lookup for dimorphic species (a `_f` or `_m` file beside
## the usual one, drawn from a recipe's "dimorph" key by tools/spritegen.gd) and the Fieldbook's "Males and females"
## notes (data/dimorphism.json).

const NOTES_PATH := "res://data/dimorphism.json"
const ART_DIR := "res://art/sprites/creatures/"
const MALE_COLOUR := Color("6fa3d8")
const FEMALE_COLOUR := Color("e08aa8")
static var _notes: Dictionary = {}
static var _loaded := false

static func valid(sex: String) -> bool:
	return sex == "m" or sex == "f"

## "Male", "Female" or "" (a kindred that has no sex shows nothing, never a dash).
static func word(sex: String) -> String:
	return {"m": "Male", "f": "Female"}.get(sex, "")

## The sign as text, for logs and tests (the screens draw it, see ui/sex_mark.gd): "♂", "♀" or "".
static func glyph(sex: String) -> String:
	return {"m": "♂", "f": "♀"}.get(sex, "")

static func colour(sex: String) -> Color:
	return MALE_COLOUR if sex == "m" else FEMALE_COLOUR

## Does this creature's kindred have male and female at all?
static func has_sexes(c: Creature) -> bool:
	return not c.species.is_empty() and Genetics.sex_mode(Genetics.kindred_of(c)) != "none"

## "Female", "Male" or "" for a creature that has none to show.
static func word_of(c: Creature) -> String:
	return word(c.sex) if valid(c.sex) else ""

## Gives a creature of a sexed kindred a sex if it has none (an old save, a hand-built one), and returns it. A
## creature with a genome takes the sex its ginger chromosomes say (one copy: male in beasts, female in fowl);
## otherwise its own inborn values decide, the same answer every time.
static func ensure(c: Creature) -> String:
	if valid(c.sex) or not has_sexes(c):
		return c.sex
	var mode := Genetics.sex_mode(Genetics.kindred_of(c))
	var g: Array = c.genome.get("ginger", [])
	if g.size() == 2:
		var one_copy := str(g[1]) in ["Y", "W"]
		c.sex = ("m" if one_copy else "f") if mode == "xy" else ("f" if one_copy else "m")
	else:
		c.sex = str(Genetics.derive(c).sex)
	return c.sex

# --- the sprite lookup ------------------------------------------------------------------------------------

## The file stem for a species' art in one sex: "<id>_f" when that sheet exists, else the plain id.
static func art_id(species_id: String, kind: String, sex: String) -> String:
	if not valid(sex) or species_id == "":
		return species_id
	var stem := species_id + "_" + sex
	return stem if art_exists(stem, kind) else species_id

## "front" is <stem>.png, the others <stem>_back.png and <stem>_icon.png.
static func art_path(stem: String, kind: String) -> String:
	return ART_DIR + stem + (".png" if kind == "front" else "_" + kind + ".png")

static func art_exists(stem: String, kind: String) -> bool:
	var p := art_path(stem, kind)
	return ResourceLoader.exists(p) or FileAccess.file_exists(p)

## Plain files are <id>_front.png; the sexed ones follow the dimorph contract (<id>_f.png). Returns the path to load.
static func sheet_path(species_id: String, kind: String, sex: String) -> String:
	if valid(sex) and species_id != "":
		var stem := species_id + "_" + sex
		if art_exists(stem, kind):
			return art_path(stem, kind)
	return ART_DIR + "%s_%s.png" % [species_id, kind]

# --- the Fieldbook -----------------------------------------------------------------------------------------

static func notes() -> Dictionary:
	if not _loaded:
		_loaded = true
		var d = JsonUtil.read(NOTES_PATH)
		if d is Dictionary:
			_notes = d.get("notes", {})
	return _notes

## The one true line about how the sexes differ, or "" for a species that has no note.
static func note(species_id: String) -> String:
	return str(notes().get(species_id, ""))

static func seen_key(species_id: String) -> String:
	return "sexseen_" + species_id

## Remembers which sexes of a species you have met: a flag holding "m", "f" or "mf".
static func record_seen(data: GameStateData, c: Creature) -> void:
	if c == null or not valid(c.sex) or note(str(c.species.get("id", ""))) == "":
		return
	var k := seen_key(str(c.species.id))
	var have := str(data.flag(k)) if data.flag(k) is String else ""
	if not (c.sex in have):
		data.set_flag(k, "mf" if have != "" else c.sex)

## Which sexes have been met: "", "m", "f" or "mf". Creatures already on the team or in the Ark count too, so a
## Fieldbook from before this was recorded still knows the ones you hold.
static func seen_sexes(data: GameStateData, species_id: String) -> String:
	var v: Variant = data.flag(seen_key(species_id))
	var have := str(v) if v is String else ""
	for list in [data.party, data.ark]:
		for c in list:
			if c.species.get("id", "") == species_id and valid(c.sex) and not (c.sex in have):
				have += c.sex
	return "mf" if have.length() > 1 else have

static func seen_both(data: GameStateData, species_id: String) -> bool:
	return seen_sexes(data, species_id) == "mf"
