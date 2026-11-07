extends TestCase
## Worm charming (core/worm_charming.gd): rhythm matters, birds punish mess, and the prize logic.

## mode: "steady" (every beat, dead on, rests patches, shoos), "late" (every beat, a bit off), "sloppy" (random times),
## "unshooed" (steady but never shoos)
func _play(mode: String, seed_: int, easy := false) -> Dictionary:
	var rng := Rng.new(seed_)
	var st := WormCharming.start(rng, easy)
	var dt := 1.0 / 60.0
	var p := WormCharming.period()
	var next_beat := p
	var jit := Rng.new(seed_ + 99)
	while not st.done:
		WormCharming.step(st, dt)
		var t: float = st.t
		if mode != "unshooed" and not (st.bird as Dictionary).is_empty() and float(st.bird.eta) < 0.9 and mode != "sloppy":
			WormCharming.shoo(st)
		if t >= next_beat:
			var at := next_beat
			if mode == "late":
				at += 0.11 * (1.0 if jit.roll() < 0.5 else -1.0)
			elif mode == "sloppy":
				at += (jit.roll() - 0.5) * p
			# the richest patch under the fork or next to it
			var best := int(st.cursor)
			for i in st.cells.size():
				if float(st.cells[i]) > float(st.cells[best]) + 0.15:
					best = i
			st.cursor = best
			WormCharming.tap(st, at)
			next_beat += p
	return st

func _total(mode: String, easy := false) -> int:
	var n := 0
	for s in 4:
		n += int(_play(mode, s + 1, easy).bucket)
	return n / 4

func test_offset_and_judging() -> void:
	var p := WormCharming.period()
	assert_eq(WormCharming.judge(p * 3.0, false), "perfect")
	assert_eq(WormCharming.judge(p * 3.0 + 0.1, false), "good")
	assert_eq(WormCharming.judge(p * 3.5, false), "miss")
	assert_eq(WormCharming.judge(p * 3.0 + 0.15, true), "good", "easier is more forgiving")

func test_steady_beats_sloppy_by_a_mile() -> void:
	var steady := _total("steady")
	var sloppy := _total("sloppy")
	assert_true(steady > sloppy * 2, "steady %d vs sloppy %d" % [steady, sloppy])

func test_a_steady_charmer_lands_near_the_local_and_a_master_can_beat_it() -> void:
	var steady := _total("steady")
	var rival := float(WormCharming.venue("willaston").rival.worms)
	assert_true(steady >= int(rival) and steady <= int(rival * 2.5), "steady %d against a champion on %d" % [steady, int(rival)])

func test_birds_cost_worms_when_not_shooed() -> void:
	var shooed := _total("steady")
	var open := _total("unshooed")
	assert_true(open < shooed, "unshooed %d vs shooed %d" % [open, shooed])

func test_easier_helps_a_slightly_late_charmer() -> void:
	assert_true(_total("late", true) >= _total("late"))

func test_the_bucket_never_goes_negative_and_resets_on_a_new_run() -> void:
	var st := _play("steady", 3)
	assert_true(st.bucket >= 0 and st.stolen >= 0)
	assert_eq(WormCharming.start(Rng.new(1)).bucket, 0)

func test_prize_once_then_a_daily_purse() -> void:
	var d := GameStateData.new()
	var f := WormCharming.finish(d, "willaston", 40, true)
	assert_true(f.first and f.money == 12 and f.record)
	var g := WormCharming.finish(d, "willaston", 30, true)
	assert_eq(g.money, WormCharming.DAILY_PURSE)
	assert_false(g.record)
	assert_eq(WormCharming.finish(d, "willaston", 30, true).money, 0)
