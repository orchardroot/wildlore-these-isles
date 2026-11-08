extends SceneTree
## How hard is the pancake pan to keep level on keys (the lean is all or nothing)? Sweeps the bot's reaction delay,
## dead band, tap length and lookahead and prints the median time and drops. Background for the wave 49 thresholds.
## godot --headless --path . -s res://tools/dev/pancake_probe.gd

func _initialize() -> void:
	for cfg in [[0.0, 0.05, 99.0, true, 0.0], [0.0, 0.05, 99.0, true, 0.2], [0.0, 0.05, 99.0, true, 0.4], [0.08, 0.15, 99.0, true, 0.3], [0.08, 0.15, 99.0, true, 0.5], [0.15, 0.2, 99.0, true, 0.3], [0.15, 0.2, 99.0, true, 0.5], [0.2, 0.25, 99.0, true, 0.4], [0.3, 0.3, 99.0, true, 0.4], [0.15, 0.2, 99.0, false, 0.3], [0.3, 0.3, 99.0, false, 0.4], [0.15, 0.2, 0.1, true, 0.4]]:
		var times: Array = []
		var drops := 0
		for seed_ in 20:
			var g := _run(seed_ + 1, float(cfg[0]), float(cfg[1]), float(cfg[2]), bool(cfg[3]), float(cfg[4]))
			times.append(g.total())
			drops += g.drops
		times.sort()
		print("delay %.2f dead %.2f pulse %5.2f sprint %-5s look %.1f : median %.1f s, drops/run %.1f" % [cfg[0], cfg[1], cfg[2], str(cfg[3]), cfg[4], times[10], float(drops) / 20.0])
	quit(0)

func _run(seed_: int, react: float, dead: float, pulse: float, sprint: bool, look: float) -> Pancake:
	var g := Pancake.new(seed_, false)
	var dt := 1.0 / 60.0
	g.step(dt, 0.0, false, true)
	var seen: Array = []
	var seen_v: Array = []
	var lag := maxi(1, int(round(react / dt)))
	var tilt := 0.0
	var hold := 0.0
	var guard := 0
	while not g.done and guard < 20000:
		seen.append(g.p)
		seen_v.append(g.pv)
		if seen.size() > lag:
			seen.pop_front()
			seen_v.pop_front()
		var ps := float(seen[0]) + float(seen_v[0]) * look   # where it is heading, by eye
		hold -= dt
		if pulse > 50.0:
			# hold the key while the pancake is off centre (bang-bang with a dead band)
			if absf(ps) > dead:
				tilt = signf(ps)
			elif absf(ps) < dead * 0.5:
				tilt = 0.0
		else:
			if hold <= 0.0:
				tilt = 0.0
				if absf(ps) > dead:
					tilt = signf(ps)
					hold = pulse
		var flip := false
		if g.next_station <= Pancake.STATIONS:
			var secs := (Pancake.station_y(g.next_station) - g.y) / maxf(g.v, Pancake.JOG)
			flip = not g.flipped_here and secs <= 0.0
		g.step(dt, tilt, sprint, flip)
		guard += 1
	return g
