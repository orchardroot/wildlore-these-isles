class_name DevArgs
extends RefCounted
## Developer command-line switches, passed after `--`. Used for screenshots, quick boots and the playtest bot.

## The user args after `--`, or none at all in a release build (players never get dev switches).
static func user_args(is_debug := OS.is_debug_build()) -> PackedStringArray:
	return OS.get_cmdline_user_args() if is_debug else PackedStringArray()

static func parse(args: PackedStringArray, is_debug := OS.is_debug_build()) -> Dictionary:
	if not is_debug:
		args = PackedStringArray()
	var out := {"shot": "", "shot_delay": 2.0, "boot_zone": "", "boot_pos": Vector2i(-1, -1),
		"battle_species": "", "battle_level": 5, "seed": -1, "clock": -1, "weather": "", "fps": false, "playtest": "", "seconds": 0, "ride": "", "double": false, "train": -1.0,
		"journey": "", "journey_at": 0.5, "intro": "", "intro_at": 0.5, "date": "", "coat": "", "home": "", "quality": "", "text": "", "readable": false}
	for a in args:
		var kv := a.split("=", true, 1)
		var key: String = kv[0]
		var val: String = kv[1] if kv.size() > 1 else ""
		match key:
			"--shot":
				out.shot = val
			"--shot-delay":
				out.shot_delay = val.to_float()
			"--boot":
				var zp := val.split("@")
				out.boot_zone = zp[0]
				if zp.size() > 1:
					var xy := zp[1].split(",")
					if xy.size() == 2:
						out.boot_pos = Vector2i(int(xy[0]), int(xy[1]))
			"--battle":
				var sl := val.split(":")
				out.battle_species = sl[0]
				if sl.size() > 1:
					out.battle_level = int(sl[1])
			"--seed":
				out.seed = int(val)
			"--clock":
				out.clock = GameClock.parse(val)
			"--weather":
				out.weather = val
			"--fps":
				out.fps = true
			"--playtest":
				out.playtest = val
			"--ride":
				out.ride = val
			"--double":
				out.double = true  # with --battle: a 2v2 against the dev_double twins, led by the --battle species
			"--train":
				out.train = val.to_float()  # the first train runs this many seconds after a zone loads
			"--journey":
				out.journey = val  # <train|ferry|fly>:<town>: a travel scene (with --boot, the whole journey from there)
			"--journey-at":
				out.journey_at = val.to_float()  # without --boot: hold the scene this far through (0..1)
			"--intro":
				out.intro = val  # with --boot: a battle transition (grass|ripple|iris|bars|pulse) or vs:<trainer id>, held
			"--intro-at":
				out.intro_at = val.to_float()  # how far through to hold it (0..1)
			"--date":
				out.date = val  # MM-DD or YYYY-MM-DD: pretend it's this date (seasons and festivals, see Calendar)
			"--coat":
				out.coat = val  # an uncommon coat (see Coats) on the --battle foe, the lead and the --menu sample creature
			"--home":
				out.home = val  # with --boot: the garden planted (seed|sprout|growing|ready|mixed) and the trophy shelf filled
			"--seconds":
				out.seconds = int(val)
			"--quality":
				out.quality = val  # low | medium | high: graphics quality for this run only (never saved)
			"--text":
				out.text = val  # normal | large | largest: the Text size setting for this run only (never saved)
			"--readable":
				out.readable = true  # the Readable font setting on, for this run only (never saved)
	return out

## True when any switch that boots straight into the game is present (screenshots, boots, menus, battles,
## talks, the bot). Such runs must never touch the player's real saves.
static func is_dev_session(parsed: Dictionary, cmdline: PackedStringArray) -> bool:
	if parsed.get("shot", "") != "" or parsed.get("boot_zone", "") != "" or parsed.get("battle_species", "") != "" or parsed.get("playtest", "") != "":
		return true
	for a in cmdline:
		if a.begins_with("--menu=") or a.begins_with("--talk=") or a.begins_with("--battle") or a.begins_with("--journey"):
			return true
	return false
