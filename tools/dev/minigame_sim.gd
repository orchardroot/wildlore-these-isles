extends SceneTree
## Drives the pure cores of the ten wave 48 party-piece games with three bots (sloppy, decent, sharp) over many seeds
## and prints, for normal and Easier minigames, the score spread and how often each bot reaches the silver ("good")
## and gold ("master") thresholds in data/party_pieces/*.json. The scores are the ones each screen hands
## PiecePrompt.after_game, so the rates read straight across to rosettes. Used to set the thresholds in wave 49.
## godot --headless --path . -s res://tools/dev/minigame_sim.gd -- [game,game,...] [runs]
## Games: sheepdog_trials worms cheese pancake snorkel coracle road_bowling poohsticks gurning welly_wang (default all).

const GAMES := ["sheepdog_trials", "worms", "cheese", "pancake", "snorkel", "coracle", "road_bowling", "poohsticks", "gurning", "welly_wang"]
const SKILLS := ["sloppy", "decent", "sharp"]

var _jit: Rng   # the bot's own hands, separate from the game's seed so the two are not entangled

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var games: Array = GAMES if a.is_empty() or a[0] == "all" else Array(a[0].split(","))
	var runs := int(a[1]) if a.size() > 1 else 60
	for g in games:
		var e := PartyPieces.entry(g)
		if e.is_empty():
			print("no piece for ", g)
			continue
		print("\n== %s  (good %s, master %s, %s; %s)" % [g, str(e.good), str(e.master), "lower is better" if bool(e.get("lower_better", false)) else "higher is better", str(e.unit)])
		for easy in [false, true]:
			for sk in SKILLS:
				var scores: Array = []
				for r in runs:
					_jit = Rng.new(r * 131 + 7)
					scores.append(call("_play_" + g, sk, r + 1, easy))
				_report(e, "easy " if easy else "norm ", sk, scores)
		if g == "welly_wang":
			var scores: Array = []
			for r in runs:
				_jit = Rng.new(r * 131 + 7)
				scores.append(_welly_gambler(r + 1))
			_report(e, "norm ", "DIZZY", scores)
	quit(0)

func _report(e: Dictionary, mode: String, sk: String, scores: Array) -> void:
	var lower := bool(e.get("lower_better", false))
	var good := 0
	var master := 0
	for s in scores:
		var v := float(s)
		if (v <= float(e.good)) if lower else (v >= float(e.good)):
			good += 1
		if (v <= float(e.master)) if lower else (v >= float(e.master)):
			master += 1
	var sorted := scores.duplicate()
	sorted.sort()
	var n := sorted.size()
	var q := func(f: float) -> String: return "%.1f" % float(sorted[clampi(int(f * float(n)), 0, n - 1)])
	print("  %s %-7s  p10 %5s  p25 %5s  med %5s  p75 %5s  p90 %5s  | silver %3d%%  gold %3d%%" % [mode, sk, q.call(0.1), q.call(0.25), q.call(0.5), q.call(0.75), q.call(0.9), int(100.0 * good / n), int(100.0 * master / n)])

## A rough normal deviate (sd 1) from the bot's hands.
func _gauss() -> float:
	return (_jit.roll() + _jit.roll() + _jit.roll() - 1.5) * 2.0

# ---- sheepdog trials (score: sheep penned of 7, Longshaw)

func _sheep_goal(st: Dictionary) -> Vector2:
	# like the steady bot in tests/minigames/test_sheepdog_trials.gd, but it works one job at a time the way a person
	# does: any sheep still beyond a gate get walked at that gate (the furthest straggler left for last), then
	# everyone left gets walked at the pen
	var live: Array = []
	for s in st.sheep:
		if not s.penned:
			live.append(s)
	if live.is_empty():
		return Vector2.ZERO
	var goal := Vector2(6.0, 20.0)
	var pts: Array = []
	for g in st.gates:
		var gx := float(g.x)
		var beyond: Array = []
		for s in live:
			if s.p.x > gx:
				beyond.append(s.p)
		if not beyond.is_empty() and pts.is_empty():
			goal = Vector2(gx - 4.0, float(g.y))
			pts = beyond
	if pts.is_empty():
		for s in live:
			pts.append(s.p)
	pts.sort_custom(func(a, b): return (a as Vector2).distance_to(goal) < (b as Vector2).distance_to(goal))
	if pts.size() >= 4:
		pts = pts.slice(0, pts.size() - 1)
	var c := Vector2.ZERO
	for q in pts:
		c += q
	c /= float(pts.size())
	var dir_c: Vector2 = (c - goal).normalized()
	var want: Vector2 = c + dir_c * 9.0
	want = Vector2(minf(want.x, 93.0), clampf(want.y, 2.0, 38.0))
	var to_dog: Vector2 = st.dog - c
	if to_dog.dot(dir_c) < 2.0 and to_dog.length() < 18.0:
		var perp := Vector2(-dir_c.y, dir_c.x)
		if perp.dot(to_dog) < 0.0:   # keep to the side the dog is already on, so it commits to going round
			perp = -perp
		return (perp + to_dog.normalized() * clampf((15.0 - to_dog.length()) * 0.2, -1.0, 1.0)).normalized()
	return (want - st.dog).limit_length(1.0) if (want - st.dog).length() > 1.0 else Vector2.ZERO

func _play_sheepdog_trials(sk: String, seed_: int, easy: bool) -> float:
	# the steady bot from tests/minigames/test_sheepdog_trials.gd, with slower hands, a wobble and the odd dash
	var react := float({"sloppy": 0.6, "decent": 0.3, "sharp": 0.1}[sk])
	var noise := float({"sloppy": 0.6, "decent": 0.3, "sharp": 0.1}[sk])
	var dash_p := float({"sloppy": 0.3, "decent": 0.05, "sharp": 0.0}[sk])
	var st := SheepdogTrials.start(SheepdogTrials.venue("longshaw"), easy, Rng.new(seed_))
	var dt := 1.0 / 30.0
	var mv := Vector2.ZERO
	var dash := false
	var since := 99.0
	while not st.done:
		since += dt
		if since >= float(react):
			since = 0.0
			mv = _sheep_goal(st)
			if mv != Vector2.ZERO:
				mv = mv.rotated(_gauss() * float(noise))
			dash = _jit.roll() < float(dash_p)
		SheepdogTrials.step(st, dt, mv, dash, false)
	return float(st.penned)

# ---- worm charming (score: worms counted in 60 s)

func _play_worms(sk: String, seed_: int, easy: bool) -> float:
	var sd := float({"sloppy": 0.14, "decent": 0.07, "sharp": 0.035}[sk])
	var shoo_at := float({"sloppy": 0.3, "decent": 0.7, "sharp": 1.1}[sk])
	var shoo_p := float({"sloppy": 0.5, "decent": 0.85, "sharp": 1.0}[sk])
	var move_p := float({"sloppy": 0.0, "decent": 0.5, "sharp": 1.0}[sk])
	var st := WormCharming.start(Rng.new(seed_), easy)
	var dt := 1.0 / 60.0
	var p := WormCharming.period()
	var next_beat := p
	var will_shoo := true
	while not st.done:
		WormCharming.step(st, dt)
		var b: Dictionary = st.bird
		if not b.is_empty():
			if float(b.eta) > float(shoo_at) + 0.1:
				will_shoo = _jit.roll() < float(shoo_p)
			elif float(b.eta) < float(shoo_at) and will_shoo:
				WormCharming.shoo(st)
		if float(st.t) >= next_beat:
			if _jit.roll() < float(move_p):
				var best := int(st.cursor)
				for i in st.cells.size():
					if float(st.cells[i]) > float(st.cells[best]) + 0.15:
						best = i
				st.cursor = best
			WormCharming.tap(st, next_beat + _gauss() * float(sd))
			next_beat += p
	return float(st.bucket)

# ---- cheese rolling (score: best of three heats, points)

func _cheese_heat(sk: String, seed_: int, easy: bool) -> int:
	var see := float({"sloppy": 0.0, "decent": 10.0, "sharp": 16.0}[sk])
	var react := float({"sloppy": 0.3, "decent": 0.2, "sharp": 0.0}[sk])
	var lapse := float({"sloppy": 0.0, "decent": 0.15, "sharp": 0.0}[sk])
	var g := CheeseRoll.new(seed_, easy)
	var dt := 1.0 / 60.0
	var steer := 0.0
	var since := 99.0
	var guard := 0
	while not g.done and guard < 6000:
		since += dt
		if since >= float(react):
			since = 0.0
			var best_o = null
			if _jit.roll() >= float(lapse):
				for o in g.obstacles:
					var d: float = float(o.y) - g.y
					if d > 0.0 and d < float(see) and absf(float(o.x) - g.x) < float(o.r) + 0.3 and (best_o == null or d < float(best_o.y) - g.y):
						best_o = o
			if best_o != null:
				steer = 1.0 if g.x >= float(best_o.x) else -1.0
				if absf(g.x) > 0.8:
					steer = -signf(g.x)
			else:
				steer = clampf((float(g.cheese.x) - g.x) * 3.0 - g.camber(g.y), -1.0, 1.0)
		g.step(dt, steer, false)
		guard += 1
	return g.score()

func _play_cheese(sk: String, seed_: int, easy: bool) -> float:
	var best := 0
	for h in CheeseRoll.HEATS:
		best = maxi(best, _cheese_heat(sk, seed_ + h * 31, easy))
	return float(best)

# ---- pancake race (score: seconds, lower better)

func _play_pancake(sk: String, seed_: int, easy: bool) -> float:
	# on keys the lean is all or nothing (Input.get_axis), so the bot holds the key against where it sees the pancake
	# heading (its position `react` seconds ago plus `look` seconds of its drift) once that is `dead` off centre.
	# tools/dev/pancake_probe.gd showed the pan is on a knife edge with this control: 0.08 s of delay is flawless,
	# 0.2 s drops it thirty times. The sloppy one jogs after its first drop.
	var sprint := true
	var dead := float({"sloppy": 0.25, "decent": 0.2, "sharp": 0.15}[sk])
	var react := float({"sloppy": 0.2, "decent": 0.15, "sharp": 0.08}[sk])
	var look := float({"sloppy": 0.3, "decent": 0.5, "sharp": 0.4}[sk])
	var flip_sd := float({"sloppy": 0.35, "decent": 0.2, "sharp": 0.08}[sk])
	var forget := float({"sloppy": 0.15, "decent": 0.0, "sharp": 0.0}[sk])
	var g := Pancake.new(seed_, easy)
	var dt := 1.0 / 60.0
	g.step(dt, 0.0, false, true)
	var tilt := 0.0
	var seen: Array = []     # the pancake's position and speed, frame by frame, for the delayed eye
	var station := -1
	var off := 0.0
	var skip := false
	var guard := 0
	var lag := maxi(1, int(round(react / dt)))
	while not g.done and guard < 20000:
		seen.append(Vector2(g.p, g.pv))
		if seen.size() > lag:
			seen.pop_front()
		var heading: float = (seen[0] as Vector2).x + (seen[0] as Vector2).y * look
		if absf(heading) > dead:
			tilt = signf(heading)   # a lean towards the pancake pushes it back (push = -13 * lean)
		elif absf(heading) < dead * 0.5:
			tilt = 0.0
		if sk == "sloppy" and g.drops > 0:
			sprint = false
		var flip := false
		if g.next_station <= Pancake.STATIONS:
			if station != g.next_station:
				station = g.next_station
				off = _gauss() * float(flip_sd)
				skip = _jit.roll() < float(forget)
			var secs := (Pancake.station_y(g.next_station) - g.y) / maxf(g.v, Pancake.JOG)
			flip = not skip and not g.flipped_here and secs <= off
		g.step(dt, tilt, sprint, flip)
		guard += 1
	return snappedf(g.total(), 0.1)

# ---- bog snorkelling (score: seconds, lower better)

func _play_snorkel(sk: String, seed_: int, easy: bool) -> float:
	var sd := float({"sloppy": 0.2, "decent": 0.11, "sharp": 0.05}[sk])
	var slip := float({"sloppy": 0.08, "decent": 0.02, "sharp": 0.0}[sk])
	var blow_silt := float({"sloppy": 0.8, "decent": 0.5, "sharp": 0.5}[sk])
	var s := Snorkel.fresh(1000 + seed_)
	var side := "l"
	var guard := 0
	while not bool(s.done) and guard < 4000:
		guard += 1
		if float(s.pause) > 0.0:
			Snorkel.tick(s, Snorkel.BEAT)
			continue
		if float(s.silt) > float(blow_silt) or float(s.breath) < 0.3:
			Snorkel.blow(s)
		else:
			if _jit.roll() >= float(slip):
				side = "r" if side == "l" else "l"
			Snorkel.kick(s, side, _gauss() * float(sd), easy)
		Snorkel.tick(s, Snorkel.BEAT)
	return snappedf(float(s.t), 0.1)

# ---- coracle racing (score: seconds with penalties, lower better)

func _play_coracle(sk: String, seed_: int, easy: bool) -> float:
	# Coracle.auto_paddle with a stale eye: the heading it steers by is `react` seconds old
	var skill := float({"sloppy": 0.55, "decent": 0.8, "sharp": 1.0}[sk])
	var react := float({"sloppy": 0.6, "decent": 0.3, "sharp": 0.1}[sk])
	var course: Dictionary = Coracle.venue("ironbridge").course
	var s := Coracle.fresh(course, 1000 + seed_)
	var gl := Coracle.gates(course, easy)
	var side := "l"
	var guard := 0
	var rng := Rng.new(seed_)
	var seen: Array = []
	var lag := maxi(1, int(round(react / 0.05)))
	while not bool(s.done) and guard < 6000:
		guard += 1
		seen.append(float(s.h))
		if seen.size() > lag:
			seen.pop_front()
		if float(s.cool) <= 0.0:
			var gi := mini(int(s.gate), gl.size() - 1)
			var target := float(gl[gi].y) if int(s.gate) < gl.size() else Coracle.centre(course, float(s.p.x))
			var heading_err := wrapf(float(seen[0]), -PI, PI)
			var want := clampf((target - float(s.p.y)) * 0.08, -0.5, 0.5)
			if rng.roll() > float(skill):
				side = "r" if side == "l" else "l"
			elif heading_err < want - 0.05:
				side = "l"
			elif heading_err > want + 0.05:
				side = "r"
			else:
				side = "r" if side == "l" else "l"
			Coracle.paddle(s, side)
		Coracle.step(s, course, gl, 0.05, easy)
	return snappedf(Coracle.score(s), 0.1)

# ---- road bowling (score: throws to the line, lower better, Cork)

func _bowl_pick(v: Dictionary, sk: String, s0: float, y0: float, easy: bool) -> Array:
	# what the player sets before the throw: a search over power and swing with the aim line (sharp), a coarse
	# search (decent), or a straight-ish hard throw bent towards the next bend (sloppy)
	if sk == "sloppy":
		var ahead := RoadBowling.centre(v, s0 + 80.0) - y0
		return [0.75, clampf(ahead / 20.0, -1.0, 1.0) + _gauss() * 0.25]
	var powers: Array = [0.9, 0.7, 0.5, 0.3] if sk == "decent" else [1.0, 0.85, 0.7, 0.55, 0.4, 0.25]
	var swings := 7 if sk == "decent" else 21
	var probe := Rng.new(1)
	var best := [0.7, 0.0]
	var best_sc := -1.0e9
	for pw in powers:
		for k in swings:
			var sw := -1.0 + 2.0 * float(k) / float(swings - 1)
			var r := RoadBowling.throw_bowl(v, s0, y0, pw, sw, false, probe, 0.0, easy)
			var sc := float(r.s1) - s0 + (1000.0 if bool(r.finished) else 0.0) - (40.0 if bool(r.off) else 0.0)
			if sc > best_sc:
				best_sc = sc
				best = [pw, sw]
	var hand := 0.12 if sk == "decent" else 0.04
	return [clampf(float(best[0]) + _gauss() * hand * 0.5, 0.1, 1.0), clampf(float(best[1]) + _gauss() * hand, -1.0, 1.0)]

func _play_road_bowling(sk: String, seed_: int, easy: bool) -> float:
	var v := RoadBowling.venue("cork")
	var rng := Rng.new(seed_)
	var s := 0.0
	var y := 0.0
	for n in RoadBowling.MAX_THROWS:
		var pick := _bowl_pick(v, sk, s, y, easy)
		var r := RoadBowling.throw_bowl(v, s, y, float(pick[0]), float(pick[1]), false, rng, RoadBowling.wobble_scale(easy), easy)
		if bool(r.finished):
			return float(n + 1)
		s = float(r.s1)
		y = float(r.y1)
	return float(RoadBowling.MAX_THROWS)

# ---- poohsticks (score: races won of five, Oxford)

func _play_poohsticks(sk: String, seed_: int, _easy: bool) -> float:
	var v := Poohsticks.venue("oxford")
	var rng := Rng.new(seed_)
	var wins := 0
	for race in Poohsticks.RACES:
		var r := Poohsticks.river(v, rng)
		var lane := 0
		var stick := Poohsticks.stick(1)
		match sk:
			"sharp":
				lane = Poohsticks.best_lane(r)
				stick = Poohsticks.stick(2 if lane == int(r.snag) else 0)
			"decent":
				lane = Poohsticks.local_lane(r, 0.65, _jit)
			_:
				lane = _jit.roll_int(0, Poohsticks.LANES - 1)
		var tl := Poohsticks.local_lane(r, float(v.rival.skill), rng)
		var me := Poohsticks.run(r, lane, stick, rng)
		var them := Poohsticks.run(r, tl, Poohsticks.stick(1), rng)
		if float(me.time) < float(them.time):
			wins += 1
	return float(wins)

# ---- gurning (score: longest clean run)

func _play_gurning(sk: String, seed_: int, easy: bool) -> float:
	# memory: faces up to `hold` are safe; past that each extra face adds `slip` to the chance of a wrong answer
	var hold := int({"sloppy": 3, "decent": 5, "sharp": 7}[sk])
	var slip := float({"sloppy": 0.12, "decent": 0.1, "sharp": 0.07}[sk])
	var rng := Rng.new(seed_)
	var seq := Gurning.start_sequence(rng)
	var slips := 0
	var best := 0
	while slips <= Gurning.slips_allowed(easy) and seq.size() <= Gurning.MAX_LEN:
		var p_wrong := clampf(float(slip) * float(maxi(0, seq.size() - int(hold))), 0.0, 0.7)
		if not easy:
			p_wrong = minf(0.7, p_wrong + 0.01 * float(seq.size()))   # the four second clock adds a little pressure
		var clean := true
		for i in seq.size():
			if _jit.roll() < p_wrong:
				clean = false
				break
		if clean:
			best = seq.size()
			seq = Gurning.extend(seq, rng)
		else:
			slips += 1
	return float(best)

# ---- welly wanging (score: best of three throws, metres)

func _play_welly_wang(sk: String, seed_: int, easy: bool) -> float:
	var spin_at := float({"sloppy": 0.6, "decent": 0.72, "sharp": 0.84}[sk])
	var spin_sd := float({"sloppy": 0.25, "decent": 0.08, "sharp": 0.02}[sk])
	var ang_sd := float({"sloppy": 30.0, "decent": 15.0, "sharp": 7.0}[sk])
	var rng := Rng.new(seed_)
	var best := 0.0
	for i in WellyWang.THROWS:
		var wind := WellyWang.wind(rng)
		var spin := clampf(float(spin_at) + _gauss() * float(spin_sd), 0.15, 1.0)
		var swing := fposmod(WellyWang.IDEAL + _gauss() * float(ang_sd), 360.0)
		var jitter := (rng.roll() - 0.5) * 60.0
		var res := WellyWang.wang(spin, WellyWang.assist(swing, easy), wind, jitter)
		best = maxf(best, float(res.metres))
	return snappedf(best, 0.1)

## The lazy strategy: hold for full spin every time and let go dizzy, aim be damned. If this beats a clean release
## the dizzy penalty is not a penalty.
func _welly_gambler(seed_: int) -> float:
	var rng := Rng.new(seed_)
	var best := 0.0
	for i in WellyWang.THROWS:
		var wind := WellyWang.wind(rng)
		var swing := fposmod(WellyWang.IDEAL + _gauss() * 15.0, 360.0)
		var jitter := (rng.roll() - 0.5) * 60.0
		best = maxf(best, float(WellyWang.wang(1.0, swing, wind, jitter).metres))
	return snappedf(best, 0.1)
