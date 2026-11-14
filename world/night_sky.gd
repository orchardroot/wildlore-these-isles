class_name NightSky
extends RefCounted
## The sky after dark: how many stars show for the time and weather, where the moon is and what shape it is for
## the date. Pure functions (SkyAndLight feeds them to art/shaders/night_sky.gdshader).

const SYNODIC := 29.530588853        # days from one new moon to the next
const NEW_MOON_JD := 2451550.1       # the new moon of 6 January 2000, 18:14 UTC
const PHASE_NAMES := ["new moon", "waxing crescent", "first quarter", "waxing gibbous", "full moon", "waning gibbous", "last quarter", "waning crescent"]
## How much of the night sky each weather lets through, 0..1.
const CLEARNESS := {"downpour": 0.1, "drizzle": 0.35, "fog": 0.2, "gale": 0.7}

## Julian day number of a calendar date (the Gregorian day count at noon).
static func julian_day(year: int, month: int, day: int) -> int:
	var a := (14 - month) / 12
	var y := year + 4800 - a
	var m := month + 12 * a - 3
	return day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045

## The moon's age through its cycle on a date, 0..1: 0 new, 0.25 first quarter, 0.5 full, 0.75 last quarter.
static func moon_phase(year: int, month: int, day: int) -> float:
	return fposmod((float(julian_day(year, month, day)) - NEW_MOON_JD) / SYNODIC, 1.0)

## "full moon", "waxing crescent" and so on: the eighth of the cycle the phase is in.
static func phase_name(phase: float) -> String:
	return PHASE_NAMES[int(floor(fposmod(phase, 1.0) * 8.0 + 0.5)) % 8]

## How lit the moon's face is, 0 (new) to 1 (full).
static func illumination(phase: float) -> float:
	return 0.5 - 0.5 * cos(TAU * phase)

## How dark the sky is at `minutes` (the game clock), 0..1: the stars come out as the dusk goes, and fade with the dawn.
static func darkness(minutes: int) -> float:
	var h := GameClock.wrap(minutes) / 60.0
	if h >= 19.0:
		return smoothstep(19.0, 21.5, h)
	if h < 6.5:
		return 1.0 - smoothstep(4.5, 6.5, h)
	return 0.0

## How much cloud lets the stars through in a weather, 0..1.
static func clearness(weather: String) -> float:
	return CLEARNESS.get(weather, 1.0)

## The moon's hour angle in hours, -12..12: 0 as it crosses the meridian. It crosses at noon when new and at midnight
## when full (and an hour or so later each day), so a full moon is up all night and a new one never.
static func hour_angle(minutes: int, phase: float) -> float:
	return fposmod(GameClock.wrap(minutes) / 60.0 - (12.0 + phase * 24.0) + 12.0, 24.0) - 12.0

## 0..1: whether the moon is above the horizon at `minutes` (it fades in and out over its first and last half hour or so).
static func moon_up(minutes: int, phase: float) -> float:
	return 1.0 - smoothstep(5.2, 6.2, absf(hour_angle(minutes, phase)))

## Where the moon sits on the picture (x across, -1.78 to 1.78; y up, -1 to 1): it rises on the left, climbs a little and
## sets on the right as the hours go by, always up in the top band where the sky shows.
static func moon_position(minutes: int, phase: float) -> Vector2:
	var ha := hour_angle(minutes, phase)
	return Vector2(clampf(ha / 6.2, -1.0, 1.0) * 1.35, 0.86 + 0.06 * cos(ha * TAU / 24.0 * 2.0))

## What the shader gets for a time and weather: {stars, moon_on, moon_phase, moon_pos}. All zero by day.
static func look(minutes: int, phase: float, weather: String) -> Dictionary:
	var dark := darkness(minutes)
	var clear := clearness(weather)
	return {"stars": dark * clear, "moon_on": dark * moon_up(minutes, phase) * lerpf(0.35, 1.0, clear),
		"moon_phase": phase, "moon_pos": moon_position(minutes, phase)}
