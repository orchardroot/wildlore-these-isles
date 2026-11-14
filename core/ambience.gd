class_name Ambience
extends RefCounted
## What the world sounds like where you stand: the ambience bed and weather layer for a zone, whether the
## music should sound muffled (heard from indoors), town accents, footstep surfaces and interaction sounds.
## Pure functions: Audio plays what these pick. Loops live in res://audio/ambience/ (tools/audio/ambgen.gd).

const BEDS := ["amb_coast", "amb_country", "amb_city", "amb_moor", "amb_cave", "amb_interior", "amb_night",
	"amb_pub", "amb_church", "amb_shop", "amb_home", "amb_works", "amb_night_town", "amb_night_coast", "amb_night_city"]
## Loops that SoundEmitters plays from the spot they come from (a hearth, a clock, a stream, a shore).
const EMITTERS := ["em_fire", "em_clock", "em_stream", "em_shore"]
const LAYERS := ["amb_rain_light", "amb_rain_heavy", "amb_gale", "amb_rain_roof"]

const STAGE_BEDS := {
	"coast": "amb_coast", "docks": "amb_coast", "city": "amb_city",
	"moor": "amb_moor", "bog": "amb_moor", "mountain": "amb_moor", "quarry": "amb_moor",
}
const WEATHER_LAYERS := {"drizzle": "amb_rain_light", "downpour": "amb_rain_heavy", "gale": "amb_gale"}
const RAIN := ["drizzle", "downpour"]
## After dark the day bed swaps for a night one (anything not listed keeps its bed: the moors and caves are the same all night).
const NIGHT_BEDS := {"amb_coast": "amb_night_coast", "amb_city": "amb_night_city"}

## Words in a building's id (its tokens, split at "_") that say what kind of room it is. A room that matches none
## keeps the plain room tone.
const ROOM_WORDS := {
	"pub": ["pub", "inn", "tavern", "taverna", "bar", "club", "arms", "hotel", "royalhotel", "ceilidh", "sessions", "dive", "posada", "kafeneio", "kahvehane", "blackbull", "whiteharte", "nevisinn", "ferryinn", "storeyarms", "pierbar", "lastdrop", "bookies", "strangers", "smugglers", "fleece", "crooked"],
	"church": ["church", "chapel", "cathedral", "abbey", "kirk", "minster", "priory", "shrine", "crypt", "convent", "eglwys", "bethel", "ladychapel", "kevinschurch", "stmary", "stmarys", "stmichael", "stmichaels", "stnicholas", "stmartins", "christchurch", "cloisters", "seion"],
	"shop": ["shop", "boutique", "market", "chippy", "chipper", "bakery", "bakehouse", "books", "bookshop", "tweed", "post", "postoffice", "tearoom", "tearooms", "tea", "teashop", "cafe", "store", "cheese", "butcher", "dairy", "cobbler", "antiques", "giftshop", "craftshop", "tweedshop", "surfshop", "rockshop", "signshop", "creperie", "icecream", "seafood", "pastyshop", "pastyco", "sandwichbar", "apothecary", "jewellery", "cashonly", "kylecafe", "strandcafe", "bridgecafe", "gorgecafe", "scootercafe", "arcade", "oatcakes", "custard", "mustard", "honey", "kippers", "chowder", "tapas", "boxty", "porkpie", "curry", "fish", "templebooks", "poetsbooks", "spanishbooks", "latinbooks", "exchange", "cornexchange", "bank", "selfridges"],
	"works": ["mill", "factory", "forge", "furnace", "foundry", "works", "ironworks", "copperworks", "laceworks", "bikeworks", "balloonworks", "distillery", "engine", "shed", "sheds", "cocklesheds", "workshop", "warehouse", "yard", "dockyard", "hangar", "scutchmill", "flaxmill", "dukesmill", "knottmill", "handsmill", "royalmills", "millgallery", "granary", "creamery", "slatemine", "bigpit", "geevor", "crucible", "riveter", "ripsaw", "rockfactory", "depot", "tramdepot", "weighbridge", "pump", "oast"],
}

## "pub", "church", "shop", "works" or "home" for a room (by its music, then the words in its id), or "" for any other.
static func room_kind(z: ZoneData) -> String:
	if z.kind != "interior" or is_cave(z):
		return ""
	if z.music == "pub" or z.music == "church":
		return z.music
	var toks := z.id.split("_")
	for t in toks:
		if t.ends_with("pub") or t.ends_with("inn") or t.ends_with("arms") or t.ends_with("tavern"):
			return "pub"
	for k in ROOM_WORDS:
		for t in toks:
			if t in ROOM_WORDS[k]:
				return k
	for t in toks:
		if t.begins_with("home") or t in ["house", "cottage", "farm", "farmhouse", "hut", "bothy", "croft", "cartref", "laithe", "blackhouse", "caban", "townhouse", "guesthouse", "parsonage", "h", "h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8"]:
			return "home"
	if z.id.contains("_home_"):
		return "home"
	return ""

## Tile -> footstep sound. Tiles not listed (tall grass, scree, bog, water) keep their own sounds or none.
const FOOTSTEPS := {
	"path": "step_path", "road": "step_stone", "cobbles": "step_stone", "platform": "step_stone",
	"level_crossing": "step_stone", "floor_tile": "step_stone", "door": "step_stone",
	"floor_wood": "step_wood", "sand": "step_sand", "grass": "step_soft", "flowers": "step_soft", "shallow": "step_wet",
}
## Surfaces that go splashy in the rain (sand soaks it up, floors are indoors).
const WETTABLE := ["step_path", "step_stone", "step_soft"]

## {"bed", "layer", "muffle"} for zone `z`. `weather` is the zone's own (always "clear" indoors);
## `outside` is the weather last seen outdoors, which is what drums on the roof.
static func pick(z: ZoneData, weather: String, phase: String, outside: String) -> Dictionary:
	var indoors := z.kind == "interior"
	var cave := is_cave(z)
	var layer := ""
	if not indoors:
		layer = WEATHER_LAYERS.get(weather, "")
	elif not cave and outside in RAIN:
		layer = "amb_rain_roof"
	return {"bed": bed_for(z, phase), "layer": layer, "muffle": indoors and z.music == "", "damp": damp(weather, indoors)}

static func is_cave(z: ZoneData) -> bool:
	return z.dark or z.stage == "cave"

static func bed_for(z: ZoneData, phase: String) -> String:
	if z.ambience != "":
		return "" if z.ambience == "none" else z.ambience
	if z.kind == "interior":
		if is_cave(z):
			return "amb_cave"
		var room := room_kind(z)
		return "amb_" + room if room != "" else "amb_interior"
	var bed: String = STAGE_BEDS.get(z.stage, "amb_country")
	if phase == "night":
		if bed == "amb_country":
			return "amb_night_town" if z.kind == "town" else "amb_night"
		return NIGHT_BEDS.get(bed, bed)
	return bed

## Fog and frost close in on the sound: [low-pass cutoff in Hz, dB] for the ambience bus. Indoors, or in any other weather, it is open.
const DAMP := {"fog": [2800.0, -3.0], "frost": [5000.0, -2.0]}
const OPEN_HZ := 20000.0
## Seconds between strikes of thunder (lo, hi) in the weather that has it.
const THUNDER_GAP := {"downpour": Vector2(28.0, 75.0), "gale": Vector2(55.0, 130.0)}
## The layers that carry on, faintly, into a battle: the rain you were standing in.
const BATTLE_LAYERS := ["amb_rain_light", "amb_rain_heavy", "amb_rain_roof"]
const BATTLE_LAYER_DB := -14.0
## The hours the bells keep (7 to 21), so a town sleeps through the night.
const BELL_HOURS := Vector2i(7, 21)

static func damp(weather: String, indoors: bool) -> Array:
	return [OPEN_HZ, 0.0] if indoors else DAMP.get(weather, [OPEN_HZ, 0.0])

## Seconds until the next strike of thunder in `weather` (`roll` is 0..1), or -1 where there is none.
static func thunder_gap(weather: String, roll: float) -> float:
	if not THUNDER_GAP.has(weather):
		return -1.0
	var g: Vector2 = THUNDER_GAP[weather]
	return lerpf(g.x, g.y, clampf(roll, 0.0, 1.0))

## What a battle keeps of the ambience layer: its level in dB, or -1.0 for silence.
static func battle_layer_db(layer: String) -> float:
	return BATTLE_LAYER_DB if layer in BATTLE_LAYERS else -1.0

## How many strokes the bell gives at `minutes` (the game clock) as the hour turns: 1 to 12, or 0 in the small hours.
static func strokes(minutes: int) -> int:
	var h := (GameClock.wrap(minutes) / 60)
	if h < BELL_HOURS.x or h > BELL_HOURS.y:
		return 0
	return 12 if h % 12 == 0 else h % 12

## Occasional town sounds: "bell" (a cathedral or abbey strikes the hour), "bell_small" (a chapel's), "horn" (ships in the docks).
static func accents(z: ZoneData) -> Array:
	var out: Array = []
	if z.kind != "town":
		return out
	for p in z.props:
		if str(p.get("type", "")) == "building" and str(p.get("style", "")) == "cathedral":
			out.append("bell")
			break
	if "bell" not in out:
		for p in z.props:
			if str(p.get("type", "")) == "building" and str(p.get("style", "")) == "chapel":
				out.append("bell_small")
				break
	if z.stage == "docks":
		out.append("horn")
	return out

## Did the game clock pass an hour mark going from `before` to `now`? Big jumps (a night's sleep, a load) don't count.
static func hour_struck(before: int, now: int) -> bool:
	var gone := posmod(now - before, GameClock.DAY)
	if gone == 0 or gone > 5:
		return false
	return posmod(now, 60) < gone

## The sound for stepping onto `tile`, or "" for none.
static func footstep(tile: String, weather: String, indoors: bool, on_bike: bool) -> String:
	var id: String = FOOTSTEPS.get(tile, "")
	if id == "":
		return ""
	if on_bike:
		return "bike_tyre"
	if not indoors and weather in RAIN and id in WETTABLE:
		return "step_wet"
	return id

## The sound for pressing confirm at a sign (`sign` non-empty) or at an NPC (its def), or "".
static func interact_kind(sign: Dictionary, npc_def: Dictionary) -> String:
	if not sign.is_empty():
		match str(sign.get("kind", "")):
			"radio":
				return "radio_tune"
			"plaque":
				return ""  # a plaque is screwed to the wall
		return "sign_creak"
	if npc_def.is_empty():
		return ""
	match str(npc_def.get("script", "")):
		"shopkeeper":
			return "shop_bell"
		"nurse":
			return "sanctuary_chime"
	return "talk_blip"
