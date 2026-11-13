extends SceneTree
## Dev: lists every way the coracle skips a story gate (RideCheck), per zone, with how long it took.
## Usage: godot --headless --path . -s res://tools/dev/ride_leaks.gd

func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var zones := ZoneData.load_all()
	print("loaded %d zones in %d ms" % [zones.size(), Time.get_ticks_msec() - t0])
	t0 = Time.get_ticks_msec()
	var n := 0
	for id in zones:
		var seen := {}
		for l in RideCheck.leaks(zones, zones[id]):
			if not seen.has([l.what, l.without]):
				seen[[l.what, l.without]] = true
				print("LEAK %s: %s from %s lacking [%s]" % [id, RideCheck.describe(l.what), l.entry, l.without])
				n += 1
	print("%d leaks in %d ms" % [n, Time.get_ticks_msec() - t0])
	quit()
