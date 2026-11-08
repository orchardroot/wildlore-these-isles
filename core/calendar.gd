class_name Calendar
extends RefCounted
## Seasons and festivals from the real date (the player's own calendar, not the in-game clock). Pure logic:
## the overworld dresses towns and tints the trees from these, and dialogue `when` conditions read them.
## The --date=MM-DD (or YYYY-MM-DD) dev switch overrides the date for screenshots and for testing the dailies.

const SEASONS := ["spring", "summer", "autumn", "winter"]
const FESTIVALS := ["halloween", "bonfire_night", "christmas", "st_patricks", "st_davids", "burns_night"]
## National days, kept in their own nation (everyone gets Halloween, Bonfire Night and Christmas).
const FESTIVAL_NATION := {"st_patricks": "ireland", "st_davids": "wales", "burns_night": "scotland"}

static var _override := Vector2i(-1, -1)
static var _override_year := -1  # only a full YYYY-MM-DD override pins the year

## Meteorological seasons: spring is March to May, summer June to August, and so on.
static func season_for(month: int, _day: int) -> String:
	match month:
		3, 4, 5:
			return "spring"
		6, 7, 8:
			return "summer"
		9, 10, 11:
			return "autumn"
	return "winter"

## The festival on a date, or "".
static func festival_for(month: int, day: int) -> String:
	if month == 10 and day >= 24:
		return "halloween"
	if month == 11 and day <= 7:
		return "bonfire_night"
	if month == 12:
		return "christmas"
	if month == 1 and day == 25:
		return "burns_night"
	if month == 3 and day == 1:
		return "st_davids"
	if month == 3 and day == 17:
		return "st_patricks"
	return ""

## "ireland", "wales", "scotland" or "england" (everything else, the Isle of Man included) for a zone region.
static func nation_for_region(region: String) -> String:
	if region.begins_with("ireland"):
		return "ireland"
	if region.ends_with("wales"):
		return "wales"
	if region == "scotland":
		return "scotland"
	return "england"

## True when a festival is kept in a region (national days only in their own nation).
static func festival_here(festival: String, region: String) -> bool:
	if festival == "":
		return false
	if festival == "bonfire_night" and region.begins_with("abroad_"):  # Guy Fawkes stayed at home
		return false
	return not FESTIVAL_NATION.has(festival) or FESTIVAL_NATION[festival] == nation_for_region(region)

## "MM-DD" or "YYYY-MM-DD" pins the date (the --date dev switch); "" or anything unreadable goes back to the real date.
static func set_override(date: String) -> void:
	_override = Vector2i(-1, -1)
	_override_year = -1
	var parts := date.split("-")
	if parts.size() < 2 or parts.size() > 3:
		return
	for p in parts:
		if not p.is_valid_int():
			return
	var y := int(parts[0]) if parts.size() == 3 else -1
	var m := int(parts[-2])
	var d := int(parts[-1])
	if m >= 1 and m <= 12 and d >= 1 and d <= 31 and (y == -1 or (y >= 1 and y <= 9999)):
		_override = Vector2i(m, d)
		_override_year = y

## Today as (month, day).
static func today() -> Vector2i:
	if _override.x > 0:
		return _override
	var d := Time.get_date_dict_from_system()
	return Vector2i(int(d.month), int(d.day))

## Today's real date as "YYYY-MM-DD": the key for once-a-day things (rematches, the quiz prize, Today's Walk).
## Honours --date (an MM-DD override keeps this year).
static func today_key() -> String:
	var t := today()
	var y := _override_year if _override_year > 0 else int(Time.get_date_dict_from_system().year)
	return "%04d-%02d-%02d" % [y, t.x, t.y]

## This year (the real one, or the --date=YYYY-MM-DD override).
static func year() -> int:
	return _override_year if _override_year > 0 else int(Time.get_date_dict_from_system().year)

## Today's day of the week, 0 = Sunday (honours --date).
static func weekday_today() -> int:
	var t := today()
	var y := _override_year if _override_year > 0 else int(Time.get_date_dict_from_system().year)
	return int(Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_datetime_dict({"year": y, "month": t.x, "day": t.y, "hour": 12, "minute": 0, "second": 0}))).weekday)

static func season_today() -> String:
	var t := today()
	return season_for(t.x, t.y)

static func festival_today() -> String:
	var t := today()
	return festival_for(t.x, t.y)

## How strongly the trees show the season, each 0..1: (spring blossom, autumn colour, winter frost).
## Autumn deepens from a first touch of gold in early September to full russet by late November.
static func foliage_tint(month: int, day: int) -> Vector3:
	var f := clampf((day - 1) / 30.0, 0.0, 1.0)
	match month:
		3:
			return Vector3(0.3 + 0.4 * f, 0, 0)
		4:
			return Vector3(1, 0, 0)
		5:
			return Vector3(1.0 - 0.6 * f, 0, 0)
		9:
			return Vector3(0, 0.25 + 0.35 * f, 0)
		10:
			return Vector3(0, 0.6 + 0.3 * f, 0)
		11:
			return Vector3(0, 0.9 + 0.1 * f, 0)
		12, 2:
			return Vector3(0, 0, 0.85)
		1:
			return Vector3(0, 0, 1)
	return Vector3.ZERO

## Overseas, the trees and the frost go by the place's own year. In the tropics (and Bermuda's evergreen palms
## and cedars) there is no autumn colour and no frost; south of the equator the seasons run six months behind
## ours, so November in the Falklands is late spring.
const TROPICAL_REGIONS := ["overseas_anguilla", "overseas_ascension", "overseas_bermuda", "overseas_biot", "overseas_bvi",
	"overseas_cayman", "overseas_montserrat", "overseas_pitcairn", "overseas_st_helena", "overseas_turks_caicos"]
const SOUTHERN_REGIONS := ["overseas_falklands", "overseas_south_georgia", "overseas_tristan", "overseas_antarctic", "abroad_patagonia"]

## The month as the seasons in `region` feel it (the same month at home, six on in the far south).
static func local_month(region: String, month: int) -> int:
	return (month + 5) % 12 + 1 if region in SOUTHERN_REGIONS else month

## foliage_tint for a zone's region: none in the tropics, the southern year down south.
static func foliage_tint_in(region: String, month: int, day: int) -> Vector3:
	if region in TROPICAL_REGIONS:
		return Vector3.ZERO
	return foliage_tint(local_month(region, month), day)

## The season the weather keeps in `region` today: "" in the tropics (no winter frosts).
static func season_in(region: String) -> String:
	if region in TROPICAL_REGIONS:
		return ""
	var t := today()
	return season_for(local_month(region, t.x), t.y)

## A zone's weather odds for the season: in winter a frost is twice as likely (and a small chance where the
## zone never usually has one). Returns a copy; an empty table stays empty.
static func seasonal_weather(table: Dictionary, season: String) -> Dictionary:
	if season != "winter" or table.is_empty():
		return table
	var out := table.duplicate()
	var total := 0.0
	for k in table:
		total += float(table[k])
	var frost := float(table.get("frost", 0))
	out["frost"] = frost * 2.0 if frost > 0.0 else total * 0.05
	return out
