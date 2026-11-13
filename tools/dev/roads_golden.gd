extends SceneTree
## Records, for the game as it stands, the first story step at which each place can be walked to (tests/world/w55_reach.gd).
## tests/world/w55_england_golden.json was made from the unchanged wave 55 base, before any new road; roads must never
## move an existing place earlier. Only rewrite it on purpose, when the story's own gates change.
## Usage: godot --headless --path . -s res://tools/dev/roads_golden.gd -- [out file]

const Reach := preload("res://tests/world/w55_reach.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "res://tests/world/w55_england_golden.json"
	var zones := ZoneData.load_all()
	var r: Dictionary = Reach.first_steps(zones)
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(r, "\t", true))
	f.close()
	print("roads_golden: %d states, %d places, written to %s" % [r.states.size(), r.first.size(), out])
	quit(0)
