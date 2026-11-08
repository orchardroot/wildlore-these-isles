class_name FieldMoves
extends RefCounted
## Field abilities from Stones (Hedge-lay, Brook-wade, Fell-scramble) and the bike. Pure rules; the overworld
## and player apply them. Walking into a bramble with Hedge-lay clears it for good; deep water and scree are
## simply walkable once you have the ability.

const FROM_BADGE := {"brook": "hedge_lay", "urban": "brook_wade", "stone": "fell_scramble", "iron": "lantern", "frost": "bog_cross"}
const NAMES := {"hedge_lay": "Hedge-lay", "brook_wade": "Brook-wade", "fell_scramble": "Fell-scramble", "lantern": "Lantern", "bog_cross": "Bog-cross"}
const TILE_ABILITY := {"bramble": "hedge_lay", "deep_water": "brook_wade", "scree": "fell_scramble", "bog": "bog_cross"}
## Where each ability's Stone is won, for the hint when one blocks the way.
const WHERE := {"brook": "Keeper Maud in Buxton", "urban": "Keeper Ray in Liverpool", "stone": "Keeper Eluned in Llanberis",
	"iron": "Keeper Ruairi in Belfast", "frost": "Keeper Isla in Inverness"}
const LIGHT_DIM := 2.0       # tiles of light round you in a dark cave
const LIGHT_LANTERN := 6.0

static func abilities(data: GameStateData) -> Array:
	var out := []
	for b in FROM_BADGE:
		if b in data.badges:
			out.append(FROM_BADGE[b])
	return out

static func has(data: GameStateData, ability: String) -> bool:
	return ability in abilities(data)

## "" if the player may get on the bike here, else what to tell them.
static func bike_refusal(data: GameStateData, zone: ZoneData, wading: bool) -> String:
	if int(data.bag.get("bike", 0)) <= 0:
		return "You haven't got a bike. Yet."
	if zone.kind == "interior":
		return "No cycling indoors. The carpets have suffered enough."
	if wading:
		return "A bike in a river is just a very slow boat."
	return ""

## What stepping onto p means for field abilities: "cut" (bramble, will clear), "wade" (deep water),
## "scramble" (scree), "blocked" (needs an ability you lack) or "" (not a field-ability tile).
static func verdict(data: GameStateData, zone: ZoneData, p: Vector2i) -> String:
	var t := zone.tile_at(p)
	if not TILE_ABILITY.has(t):
		return ""
	if not has(data, TILE_ABILITY[t]):
		return "blocked"
	return {"bramble": "cut", "deep_water": "wade", "scree": "scramble", "bog": "squelch"}[t]

## Why p won't let you through when it wants an ability you haven't got, or "".
static func block_hint(data: GameStateData, zone: ZoneData, p: Vector2i) -> String:
	if verdict(data, zone, p) != "blocked":
		return ""
	var t := zone.tile_at(p)
	var what: String = {"bramble": "Brambles too thick to push through", "deep_water": "Too deep to wade", "scree": "Loose scree, too steep to climb", "bog": "Bog too soft to cross"}.get(t, "Not passable")
	var ability: String = TILE_ABILITY[t]
	var badge: String = FROM_BADGE.find_key(ability)
	return "%s. You'd need %s, which comes with the %s Stone from %s." % [what, NAMES[ability], badge.capitalize(), WHERE[badge]]

## How far you can see in a dark zone.
static func light_radius(data: GameStateData) -> float:
	return LIGHT_LANTERN if has(data, "lantern") else LIGHT_DIM

static func cut_flag(zone_id: String, p: Vector2i) -> String:
	return "cut_%s_%d_%d" % [zone_id, p.x, p.y]

static func cut(data: GameStateData, zone: ZoneData, p: Vector2i) -> void:
	data.set_flag(cut_flag(zone.id, p), true)
	zone.cut(p)

## Re-applies every bramble this save has cleared in this zone (call before building its meshes).
static func apply_cuts(data: GameStateData, zone: ZoneData) -> void:
	var prefix := "cut_%s_" % zone.id
	for k in data.flags:
		var key := str(k)
		if key.begins_with(prefix) and data.flags[k]:
			var xy := key.substr(prefix.length()).split("_")
			if xy.size() == 2:
				zone.cut(Vector2i(int(xy[0]), int(xy[1])))
