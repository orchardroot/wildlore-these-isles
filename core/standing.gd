class_name Standing
extends RefCounted
## Standing with the six nations: how far each one counts you as one of its own. Points live in the flags
## `standing_<nation>` (an int, 0 when missing, so old saves start as Strangers everywhere). Jobs off the parish
## noticeboards pay the most; beating a named trainer, a first visit to a town and a pub quiz win add a little.
## Tiers bring perks: a discount in that nation's shops, a little extra stock, a landlord's parcel, a trophy.
## Pure logic (no autoload names): the story validator loads it through Jobs.

const NATIONS := ["england", "wales", "scotland", "northern_ireland", "ireland", "mann", "overseas", "channel_islands", "abroad"]
const NAMES := {"england": "England", "wales": "Wales", "scotland": "Scotland", "northern_ireland": "Northern Ireland",
	"ireland": "Ireland", "mann": "Isle of Man", "overseas": "Britain Overseas",
	"channel_islands": "The Channel Islands", "abroad": "Kin Abroad"}
## How a nation reads at the start of a sentence ("The Isle of Man now counts you as...").
const SENTENCE_NAMES := {"mann": "The Isle of Man", "overseas": "Britain Overseas", "channel_islands": "The Channel Islands", "abroad": "Kin Abroad"}
const FLAG_PREFIX := "standing_"

const STRANGER := 0
const KNOWN_FACE := 1
const REGULAR := 2
const LOCAL := 3
const PILLAR := 4
const TIER_POINTS := [0, 10, 30, 60, 100]
const TIER_NAMES := ["Stranger", "Known Face", "Regular", "Local", "Pillar of the Community"]
## Shop discount by tier (Regular brings stock instead of a bigger discount).
const DISCOUNT := [0.0, 0.05, 0.05, 0.10, 0.15]

## Small awards from around the parish.
const FOR_TRAINER := 1
const FOR_FIRST_VISIT := 1
const FOR_QUIZ_WIN := 2

## Zones in the island of Ireland's north (their region says "ireland"), and their rooms by id prefix.
const NI_ZONES := ["belfast", "bushmills", "derry", "antrim_coast", "causeway", "mournes",
	"lough_neagh", "enniskillen"]

## At Regular, each nation's shops stock one or two things you can't buy elsewhere: [item id, price].
const EXTRA_STOCK := {
	"england": [["horseshoe", 3200], ["hazel_snare", 450]],
	"wales": [["leek", 3200], ["miners_lamp", 3400]],
	"scotland": [["thistle_brooch", 3200], ["creel_snare", 700]],
	"northern_ireland": [["shamrock_pin", 3200], ["creel_snare", 700]],
	"ireland": [["brigid_cross", 3200], ["four_leaf_clover", 3600]],
	"mann": [["selkie_pearl", 3400], ["hazel_snare", 450]],
	"overseas": [["hazel_snare", 450], ["creel_snare", 700]],
	"channel_islands": [["hazel_snare", 450], ["creel_snare", 700]],
	"abroad": [["hazel_snare", 450], ["creel_snare", 700]],
}
## At Local, the landlord leaves a parcel of the local food on the noticeboard once a real day.
const LANDLORD_FOOD := {"england": "pork_pie", "wales": "bara_brith", "scotland": "tablet",
	"northern_ireland": "ulster_fry", "ireland": "barmbrack", "mann": "soda_bread", "overseas": "cup_of_tea", "channel_islands": "jersey_royal", "abroad": "cup_of_tea"}
## At Pillar of the Community: a trophy for the bag (data/items/parish.json) ...
const TROPHY := {"england": "parish_rose", "wales": "parish_lovespoon", "scotland": "parish_quaich",
	"northern_ireland": "parish_linen", "ireland": "parish_claddagh", "mann": "parish_triskelion", "overseas": "parish_airbridge", "channel_islands": "parish_gache", "abroad": "parish_passport"}
## ... and folk greet you as the one who sorted something out.
const PILLAR_LINES := {
	"england": "You're the one who sorted the Herdwicks, aren't you?",
	"wales": "You're the one who got the chapel choir back in tune, aren't you?",
	"scotland": "You're the one who found the laird's good bagpipes, aren't you?",
	"northern_ireland": "You're the one who fixed the bonfire rota, so you are.",
	"ireland": "You're the one who settled the hurling row, aren't you?",
	"mann": "You're the one who said hello to the fairies on the bridge. Every time, they say.",
	"overseas": "You're the one who flew all the way out here with the post. Twice.",
	"channel_islands": "You're the one who got the cows back on the right side of the Channel. Jersey and Guernsey both say it was theirs.",
	"abroad": "You're the one who came all this way to hear where we came from. Sit down, there's tea.",
}

static var _zone_nation := {}

## The nation a zone (or a region name) belongs to: Calendar's four nations, with Northern Ireland and the
## Isle of Man split out. Rooms take their town's nation.
static func nation_for_zone(zone_or_region: String) -> String:
	if _zone_nation.has(zone_or_region):
		return _zone_nation[zone_or_region]
	var out := _work_out(zone_or_region)
	_zone_nation[zone_or_region] = out
	return out

static func _work_out(id: String) -> String:
	for z in NI_ZONES:
		if id == z or id.begins_with(z + "_"):
			return "northern_ireland"
	if id == "man" or id == "douglas" or id.begins_with("douglas_"):
		return "mann"
	if id.begins_with("abroad_"):
		return "abroad"
	if id.begins_with("overseas_") or id == "brize_norton" or id.begins_with("brize_norton_"):
		return "overseas"
	if id in NATIONS:
		return id
	if not FileAccess.file_exists("res://data/zones/%s.json" % id):
		return Calendar.nation_for_region(id)  # a region name
	var zi: Dictionary = ZoneIndex.get_index()
	var town := str(zi.room_town.get(id, ""))
	if town != "" and town != id:
		return nation_for_zone(town)
	var region := str(zi.zones.get(id, {}).get("region", ""))
	if region.begins_with("overseas_"):
		return "overseas"
	if region.begins_with("abroad_"):  # the peoples of these isles abroad (wave 45 L)
		return "abroad"
	if region == "channel_islands":
		return "channel_islands"
	return "mann" if region == "man" else Calendar.nation_for_region(region)

static func is_nation(n: String) -> bool:
	return n in NATIONS

static func name_of(nation: String) -> String:
	return str(NAMES.get(nation, nation.capitalize()))

## How a nation reads in the middle of a sentence ("a Stranger in the Channel Islands").
static func mid_name(nation: String) -> String:
	var n := name_of(nation)
	return "the " + n.substr(4) if n.begins_with("The ") else n

static func points(data: GameStateData, nation: String) -> int:
	var v = data.flag(FLAG_PREFIX + nation)
	return int(v) if (v is int or v is float) else 0

static func tier_for(pts: int) -> int:
	var t := STRANGER
	for i in TIER_POINTS.size():
		if pts >= TIER_POINTS[i]:
			t = i
	return t

static func tier(data: GameStateData, nation: String) -> int:
	return tier_for(points(data, nation))

static func tier_name(data: GameStateData, nation: String) -> String:
	return TIER_NAMES[tier(data, nation)]

## Points still to go to the next tier, or 0 at the top.
static func to_next(data: GameStateData, nation: String) -> int:
	var t := tier(data, nation)
	return 0 if t >= PILLAR else TIER_POINTS[t + 1] - points(data, nation)

## Adds standing; returns the toast line when this reached a new tier ("Wales now counts you as a Regular"), else "".
## Reaching Pillar of the Community puts the nation's trophy in the bag.
static func add(data: GameStateData, nation: String, n: int) -> String:
	if not is_nation(nation) or n <= 0:
		return ""
	n += Guilds.standing_bonus(data, n)   # the Folk Club
	var before := tier(data, nation)
	data.set_flag(FLAG_PREFIX + nation, points(data, nation) + n)
	var after := tier(data, nation)
	if after == before:
		return ""
	if after >= PILLAR and Bag.new(data.bag).count(str(TROPHY[nation])) < 1:
		Bag.new(data.bag).add(str(TROPHY[nation]), 1)
	return tier_line(nation, after)

static func tier_line(nation: String, t: int) -> String:
	var nm := str(SENTENCE_NAMES.get(nation, name_of(nation)))
	var tn: String = TIER_NAMES[clampi(t, 0, PILLAR)]
	if t >= PILLAR:
		return "%s now counts you as a %s" % [nm, tn]
	return "%s now counts you as a%s %s" % [nm, "n" if tn.left(1) in ["A", "E", "I", "O", "U"] else "", tn]

## A shop price in `nation` after your discount (never below 1).
static func price(data: GameStateData, nation: String, base: int) -> int:
	if base <= 0:
		return base
	var d: float = DISCOUNT[tier(data, nation)] if is_nation(nation) else 0.0
	return maxi(1, roundi(base * (1.0 - d)))

## The extra lines a nation's shops stock for you ([[item id, price]]), from Regular up.
static func extra_stock(data: GameStateData, nation: String) -> Array:
	if not is_nation(nation) or tier(data, nation) < REGULAR:
		return []
	return EXTRA_STOCK[nation]

static func extra_price(nation: String, item_id: String) -> int:
	for e in EXTRA_STOCK.get(nation, []):
		if str(e[0]) == item_id:
			return int(e[1])
	return 0

## What a townsperson adds after their hello once you're a Pillar of the Community here, else "".
static func greeting_extra(data: GameStateData, zone_id: String) -> String:
	var n := nation_for_zone(zone_id)
	if not is_nation(n) or tier(data, n) < PILLAR:
		return ""
	return str(PILLAR_LINES[n])

## Rows for the Stats page: [nation name, tier name, points, points to the next tier].
static func lines(data: GameStateData) -> Array:
	var out := []
	for n in NATIONS:
		out.append([name_of(n), tier_name(data, n), points(data, n), to_next(data, n)])
	return out
