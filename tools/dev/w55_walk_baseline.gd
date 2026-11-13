extends SceneTree
## Prints the first story step at which each zone can be walked to (see StoryWalk), as JSON, for the wave 55
## sequence-break tests' baseline. Usage: godot --headless --path . -s res://tools/dev/w55_walk_baseline.gd -- [out file]

func _initialize() -> void:
	var all := ZoneData.load_all()
	var steps := StoryWalk.first_steps(all)
	var keys := steps.keys()
	keys.sort()
	var out := {}
	for k in keys:
		if all[k].kind != "interior":
			out[k] = steps[k]
	var txt := JSON.stringify(out, " ")
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var f := FileAccess.open(args[0], FileAccess.WRITE)
		f.store_string(txt + "\n")
	else:
		print(txt)
	quit(0)
