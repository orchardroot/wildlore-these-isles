extends TestCase
## The seaside arcade (core/arcade.gd): the change counter and its daily cap, the 2p pusher, penny falls, the claw,
## the prize counter, and the money check (nothing here can print pounds).

func _d() -> GameStateData:
	var d := GameStateData.new()
	d.money = 20
	return d

func test_change_counter_gives_fifty_two_pence_pieces_a_pound() -> void:
	var d := _d()
	var r := Arcade.buy(d, 2)
	assert_true(r.ok)
	assert_eq(Arcade.coins(d), 100)
	assert_eq(d.money, 18)

func test_daily_cap_and_purse() -> void:
	var d := _d()
	assert_true(Arcade.buy(d, Arcade.DAILY_POUNDS).ok)
	var r := Arcade.buy(d, 1)
	assert_false(r.ok, "past the cap")
	assert_eq(d.money, 20 - Arcade.DAILY_POUNDS, "nothing taken for a refused buy")
	var poor := GameStateData.new()
	poor.money = 1
	assert_false(Arcade.buy(poor, 3).ok)
	assert_eq(poor.money, 1)
	assert_false(Arcade.buy(poor, 0).ok)

func test_cap_resets_on_a_new_real_day() -> void:
	var d := _d()
	Arcade.buy(d, Arcade.DAILY_POUNDS)
	d.set_flag(Arcade.FLAG_DAY, "1999-01-01")
	assert_eq(Arcade.pounds_left(d), Arcade.DAILY_POUNDS)

func test_old_saves_start_empty() -> void:
	var d := GameStateData.new()
	assert_eq(Arcade.coins(d), 0)
	assert_eq(Arcade.tokens(d), 0)
	assert_eq(Arcade.miss_streak(d), 0)

func test_shelf_moves_smoothly_within_bounds() -> void:
	var prev := Arcade.shelf_pos(0.0, false)
	for i in range(1, 400):
		var p := Arcade.shelf_pos(i * 0.05, false)
		assert_true(p >= 0.0 and p <= 1.0)
		assert_true(absf(p - prev) < 0.1, "no jumps")
		prev = p

func test_pusher_sweet_spot_pays_and_conserves_coins() -> void:
	var rng := Rng.new(5)
	var st := Arcade.pusher_new()
	var out := 0
	for i in 200:
		var t := i * 0.9
		var r := Arcade.pusher_drop(st, Arcade.shelf_pos(t, false), t, false, rng)
		assert_true(r.sweet)
		out += int(r.out)
		assert_true(st.pile >= 0)
	assert_true(out > 0)
	assert_true(out <= 200 + Arcade.PUSHER_FLOAT, "never more out than in plus the float")

func test_pusher_wide_window_when_easy() -> void:
	var rng := Rng.new(1)
	var s := Arcade.pusher_drop(Arcade.pusher_new(), Arcade.shelf_pos(0.0, true) + 0.2, 0.0, true, rng)
	var h := Arcade.pusher_drop(Arcade.pusher_new(), Arcade.shelf_pos(0.0, false) + 0.2, 0.0, false, rng)
	assert_true(s.sweet)
	assert_false(h.sweet)

func test_falls_tip_pays_four_fifths() -> void:
	var rng := Rng.new(3)
	var st := Arcade.falls_new(rng)
	var tip: int = st.tip[2]
	var r := {}
	for i in tip:
		r = Arcade.falls_drop(st, 2, rng)
	assert_true(r.fell)
	assert_eq(r.out, tip * 4 / 5)
	assert_eq(st.ledge[2], 0)

func test_claw_misses_when_off_target_and_pity_holds() -> void:
	var rng := Rng.new(9)
	var slots := [0.2, 0.5, 0.8]
	assert_false(Arcade.claw_play(0.35, slots, 0, false, rng).reached)
	var r := Arcade.claw_play(0.5, slots, Arcade.PITY, false, rng)
	assert_true(r.won, "after enough misses the grip holds")
	var wins := 0
	for i in 600:
		if Arcade.claw_play(0.5, slots, 0, false, rng).won:
			wins += 1
	assert_true(wins > 100 and wins < 300, "a weak claw: %d of 600" % wins)

func test_claw_result_tracks_streak_and_gives_a_toy() -> void:
	var d := _d()
	var rng := Rng.new(2)
	Arcade.claw_result(d, {"reached": true, "won": false}, "blackpool", rng)
	assert_eq(Arcade.miss_streak(d), 1)
	var id := Arcade.claw_result(d, {"reached": true, "won": true}, "blackpool", rng)
	assert_true(Arcade.town("blackpool").toys.has(id))
	assert_eq(int(d.bag.get(id, 0)), 1)
	assert_eq(Arcade.miss_streak(d), 0)

func test_prize_counter_swaps_tokens_for_each_toy_once() -> void:
	var d := _d()
	assert_eq(Arcade.redeem(d, "brighton"), "", "no tokens")
	Arcade.win_tokens(d, Arcade.TOKENS_PER_TOY * 3)
	var a := Arcade.redeem(d, "brighton")
	var b := Arcade.redeem(d, "brighton")
	assert_true(a != "" and b != "" and a != b)
	assert_eq(Arcade.redeem(d, "brighton"), "", "counter cleared")
	assert_eq(Arcade.tokens(d), Arcade.TOKENS_PER_TOY)

func test_every_town_toy_is_a_real_valueless_item() -> void:
	var items := {}
	var raw = JsonUtil.read("res://data/items/arcade.json")
	for it in raw:
		items[str(it.id)] = it
	for tid in Arcade.towns():
		assert_false(Arcade.town(tid).toys.is_empty())
		assert_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://data/zones")))
		for id in Arcade.town(tid).toys:
			assert_true(items.has(id), "item %s" % id)
			assert_eq(int(items[id].price), 0, "a toy is worth nothing in a shop")
			assert_eq(str(items[id].kind), "key")

func test_money_check_nothing_prints_pounds() -> void:
	for s in ArcadeSim.STRATEGIES:
		var worst := 0.0
		var rtp_sum := 0.0
		var runs := 40
		for seed_value in runs:
			var r := ArcadeSim.day(s, 100 + seed_value, Arcade.DAILY_POUNDS)
			assert_true(r.money <= -Arcade.DAILY_POUNDS, "%s: pounds only go in (%d)" % [s, r.money])
			assert_true(r.money >= -Arcade.DAILY_POUNDS, "%s: and the cap bounds the loss (%d)" % [s, r.money])
			if r.coins_in > 0:
				rtp_sum += float(r.coins_out) / r.coins_in
				worst = maxf(worst, float(r.coins_out) / r.coins_in)
		if s.begins_with("pusher") or s.begins_with("falls"):
			assert_true(rtp_sum / runs < 1.0, "%s hands back fewer coins than it takes: %s" % [s, rtp_sum / runs])
