extends SceneTree
## Lists every "the world doesn't match what it says" finding (WorldConsistency), the ones marked fine in
## data/world_consistency.json too, with a count per rule. Usage: godot --headless --path . -s res://tools/world_check.gd

func _initialize() -> void:
	var t := Time.get_ticks_msec()
	var all := WorldConsistency.findings(ZoneData.load_all(), StoryData.all_dialogue())
	var open := WorldConsistency.check(ZoneData.load_all(), StoryData.all_dialogue())
	var per := {}
	for f in all:
		per[f.rule] = int(per.get(f.rule, 0)) + 1
		print("%s | %s | %s | %s" % [f.rule, f.zone, f.key, f.text])
	print("findings: %s, %d open, %d ms" % [str(per), open.size(), Time.get_ticks_msec() - t])
	quit()
