extends Node
## Autoload Settings: player preferences, stored in user://settings.json.

const DEFAULT_PATH := "user://settings.json"
const TEXT_SPEEDS := {"slow": 30.0, "normal": 60.0, "fast": 120.0, "instant": 100000.0}  # characters per second
const BATTLE_SPEEDS := {"normal": 1.0, "fast": 1.5, "fastest": 2.0}  # Engine.time_scale while a battle is open

var path := DEFAULT_PATH   # tests point this somewhere else so they never touch the player's file
var text_speed := "normal"
var battle_speed := "normal"  # normal | fast | fastest: how quickly battle animations and pauses play
var quality := "medium"     # low | medium | high
var music_volume := 0.7
var sfx_volume := 0.8
var run_mode := "hold"     # hold | toggle: hold the run key, or press it once to latch running on and off
var ambience_volume := 0.7  # background beds, weather, trains and town bells (see Ambience)
var colour_blind := false   # palette safe for deuteranopia and protanopia
var reduce_flashing := false  # gentle hit flashes, less shake, no strobing evolution
var follower := true        # the party lead walks behind you in the overworld (see Follower)
var travel_scenes := "on"   # on | short | off: the little scenes for trains, ferries and the Raven (see Journey)
var easy_fishing := false   # fishing: a wider, slower sweet spot on the bite bar
var easy_darts := false     # darts: a steadier reticle and the checkout shown; crabbing: slower nibbles, a longer wait to haul; ringing: a slower beat, wider timing; walling: shows where each stone goes; shanties: a slower beat; conkers: a wider sweet spot
var local_languages := "on"  # on | off: the local language (Welsh, Irish...) beside English where the place uses it (see Langs)
var text_size := "normal"   # normal | large | largest: UI text scale (see Access)
var readable_font := false  # a dyslexia-friendly typeface (Atkinson Hyperlegible) for the interface
var hints := true          # first-time introductions to each system (see Intros)
var damage_numbers := true  # battle: the damage taken drifts up beside the plate
var bindings := {}        # action -> {"key": [physical keycodes], "pad": [joypad buttons]}, see InputSetup
var _theme: Theme         # the shared UI theme, kept loaded so apply_access's changes stick

func _ready() -> void:
	load_settings()

func chars_per_second() -> float:
	return TEXT_SPEEDS.get(text_speed, 60.0)

func battle_time_scale() -> float:
	return BATTLE_SPEEDS.get(battle_speed, 1.0)

func is_instant() -> bool:
	return text_speed == "instant"

## 1.0 normally; `gentle` when "reduce flashing" is on. Used to scale shakes and flash brightness.
func flash_scale(gentle := 0.3) -> float:
	return gentle if reduce_flashing else 1.0

## Reads the settings file (missing keys keep their defaults) and applies the key bindings.
func load_settings() -> void:
	bindings = InputSetup.defaults()
	if FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			text_speed = str(d.get("text_speed", text_speed))
			if not TEXT_SPEEDS.has(text_speed):
				text_speed = "normal"
			battle_speed = str(d.get("battle_speed", battle_speed))
			if not BATTLE_SPEEDS.has(battle_speed):
				battle_speed = "normal"
			quality = str(d.get("quality", quality))
			music_volume = float(d.get("music_volume", music_volume))
			sfx_volume = float(d.get("sfx_volume", sfx_volume))
			run_mode = str(d.get("run_mode", run_mode))
			if run_mode not in ["hold", "toggle"]:
				run_mode = "hold"
			ambience_volume = clampf(float(d.get("ambience_volume", ambience_volume)), 0.0, 1.0)
			colour_blind = bool(d.get("colour_blind", colour_blind))
			reduce_flashing = bool(d.get("reduce_flashing", reduce_flashing))
			follower = bool(d.get("follower", follower))
			easy_fishing = bool(d.get("easy_fishing", easy_fishing))
			easy_darts = bool(d.get("easy_darts", easy_darts))
			damage_numbers = bool(d.get("damage_numbers", damage_numbers))
			local_languages = str(d.get("local_languages", local_languages))
			if local_languages not in ["on", "off"]:
				local_languages = "on"
			text_size = str(d.get("text_size", text_size))
			if not Access.TEXT_SIZES.has(text_size):
				text_size = "normal"
			readable_font = bool(d.get("readable_font", readable_font))
			hints = bool(d.get("hints", hints))
			travel_scenes = str(d.get("travel_scenes", travel_scenes))
			if travel_scenes not in ["on", "short", "off"]:
				travel_scenes = "on"
			bindings = InputSetup.sanitise(d.get("bindings", {}))
	InputSetup.apply(bindings)
	_sync_languages()
	apply_access()

func apply_access() -> void:
	# held here: an unreferenced theme is freed and the next load() reads it plain from disk, so the Readable font
	# set at startup was lost before the first screen loaded it
	_theme = load("res://ui/theme.tres")
	Access.apply_theme(_theme, text_size, readable_font)

func save_settings() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"text_speed": text_speed, "battle_speed": battle_speed, "quality": quality, "music_volume": music_volume,
			"sfx_volume": sfx_volume, "ambience_volume": ambience_volume, "run_mode": run_mode, "colour_blind": colour_blind, "reduce_flashing": reduce_flashing,
			"travel_scenes": travel_scenes, "follower": follower, "damage_numbers": damage_numbers, "local_languages": local_languages, "hints": hints, "easy_fishing": easy_fishing, "easy_darts": easy_darts, "text_size": text_size, "readable_font": readable_font, "bindings": bindings}))
	_sync_languages()
	Bus.settings_changed.emit()

## Rebinds one slot. `device` is "key" or "pad"; `code` a physical keycode or joypad button.
## Returns "" on success or a short reason it was refused (nothing changes then).
func rebind(action: String, device: String, code: int) -> String:
	var r := InputSetup.rebound(bindings, action, device, code)
	if r.error != "":
		return r.error
	bindings = r.bindings
	InputSetup.apply(bindings)
	save_settings()
	return ""

func reset_bindings() -> void:
	bindings = InputSetup.defaults()
	InputSetup.apply(bindings)
	save_settings()

func languages_on() -> bool:
	return Langs.setting_on(local_languages)

func _sync_languages() -> void:
	Langs.enabled = languages_on()
