extends TestCase

const SCRAP := {"type": "move", "slot": 0}

func _types(events: Array) -> Array:
	return events.map(func(e): return e.type)

func _first(events: Array, type: String) -> Dictionary:
	for e in events:
		if e.type == type:
			return e
	return {}

func test_faster_side_moves_first() -> void:
	var b := Fixtures.battle([Fixtures.creature("spikkin", 10)], [Fixtures.creature("kindlet", 10)])
	var ev := b.take_turn(SCRAP, SCRAP)
	assert_eq(_first(ev, "move").side, 1)

func test_priority_beats_speed() -> void:
	var b := Fixtures.battle([Fixtures.creature("holtling", 13)], [Fixtures.creature("kindlet", 13)])
	var ev := b.take_turn({"type": "move", "slot": 3}, {"type": "move", "slot": 0})
	assert_eq(_first(ev, "move").side, 0)
	assert_eq(_first(ev, "move").move, "quick_nip")

func test_damage_faint_and_wild_win() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 30)], [Fixtures.creature("spikkin", 2)])
	var ev := b.take_turn({"type": "move", "slot": 1}, SCRAP)
	assert_has(_types(ev), "faint")
	assert_eq(_first(ev, "faint").side, 1)
	assert_true(b.over)
	assert_eq(b.winner, 0)
	assert_eq(ev.back(), {"type": "end", "winner": 0})
	assert_false("move" in _types(ev.slice(ev.find(_first(ev, "faint")))))

func test_pp_is_spent() -> void:
	var p := Fixtures.creature("kindlet", 10)
	var b := Fixtures.battle([p], [Fixtures.creature("spikkin", 10)])
	b.take_turn(SCRAP, SCRAP)
	assert_eq(p.moves[0].pp, 34)

func test_status_move_inflicts() -> void:
	var b := Fixtures.battle([Fixtures.creature("holtling", 11)], [Fixtures.creature("kindlet", 10)])
	var ev := b.take_turn({"type": "move", "slot": 3}, {"type": "move", "slot": 1})
	assert_eq(_first(ev, "status"), {"type": "status", "side": 1, "status": "soaked"})
	assert_eq(b.current(1).status, "soaked")

func test_stat_move_lowers_foe() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("volet", 10)])  # not Spikkin: Bristleback blocks drops
	b.take_turn({"type": "move", "slot": 1}, {"type": "move", "slot": 3})
	assert_eq(b.current(1).stages.atk, -1)
	assert_eq(b.current(1).stages.def, 1)

func test_switch_goes_first_and_resets_stages() -> void:
	var lead := Fixtures.creature("spikkin", 10)
	var b := Fixtures.battle([lead, Fixtures.creature("holtling", 10)], [Fixtures.creature("kindlet", 10)], {"kind": "trainer"})
	lead.change_stage("atk", 2)  # after construction, which resets stages
	var ev := b.take_turn({"type": "switch", "index": 1}, SCRAP)
	assert_eq(ev[0].type, "switch")
	assert_eq(lead.stages.atk, 0)
	assert_eq(b.current(0).species.id, "holtling")
	assert_eq(_first(ev, "damage").side, 0)

func test_switch_carries_hp_before_the_hit() -> void:  # the UI shows this, then the hit drains it
	var bench := Fixtures.creature("holtling", 10)
	var b := Fixtures.battle([Fixtures.creature("spikkin", 10), bench], [Fixtures.creature("kindlet", 10)], {"kind": "trainer"})
	var full := bench.hp
	var ev := b.take_turn({"type": "switch", "index": 1}, SCRAP)
	assert_eq(int(_first(ev, "switch").hp), full)
	assert_true(bench.hp < full, "and it was hit after coming in")

func test_run_from_wild_when_faster() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("spikkin", 10)])
	var ev := b.take_turn({"type": "run"}, SCRAP)
	assert_eq(_first(ev, "run").success, true)
	assert_true(b.over)
	assert_eq(b.winner, -1)
	assert_false("damage" in _types(ev))

func test_cannot_run_from_trainer() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("spikkin", 10)], {"kind": "trainer"})
	var ev := b.take_turn({"type": "run"}, SCRAP)
	assert_eq(_first(ev, "run").success, false)
	assert_false(b.over)

func test_trainer_brings_out_next_after_faint() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 30)], [Fixtures.creature("spikkin", 2), Fixtures.creature("holtling", 5)], {"kind": "trainer"})
	b.take_turn({"type": "move", "slot": 1}, SCRAP)
	assert_false(b.over)
	assert_true(b.needs_switch(1))
	var ev := b.force_switch(1, 1)
	assert_eq(ev[0].type, "switch")
	assert_false(b.needs_switch(1))
	assert_eq(b.current(1).species.id, "holtling")

func test_player_wipe_means_foe_wins() -> void:
	var b := Fixtures.battle([Fixtures.creature("spikkin", 2)], [Fixtures.creature("kindlet", 30)], {"kind": "trainer"})
	b.take_turn(SCRAP, {"type": "move", "slot": 1})
	assert_true(b.over)
	assert_eq(b.winner, 1)

func test_end_of_turn_status_damage() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("spikkin", 10)])
	b.current(1).status = "stung"
	var ev := b.take_turn({"type": "move", "slot": 1}, {"type": "move", "slot": 3})
	assert_eq(_first(ev, "status_damage").amount, b.current(1).max_hp() / 8)

func test_asleep_creature_cannot_act() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("spikkin", 10)])
	StatusFX.inflict(b.current(1), "asleep", FixedRng.new())
	var ev := b.take_turn({"type": "move", "slot": 1}, SCRAP)
	assert_eq(_first(ev, "cant_act"), {"type": "cant_act", "side": 1, "reason": "asleep"})

func test_side_with_no_able_creature_ends_at_once() -> void:
	var down := Fixtures.creature("kindlet", 10)
	down.hp = 0
	var b := Fixtures.battle([down], [Fixtures.creature("spikkin", 10)])
	assert_true(b.over)
	assert_eq(b.winner, 1)
	assert_eq(b.take_turn(SCRAP, SCRAP), [{"type": "end", "winner": 1}])
	assert_eq(b.take_turn(SCRAP, SCRAP), [])

func test_zero_pp_falls_back_to_flail() -> void:
	var p := Fixtures.creature("kindlet", 10)
	p.moves[0].pp = 0
	var b := Fixtures.battle([p], [Fixtures.creature("spikkin", 10)])
	var ev := b.take_turn(SCRAP, {"type": "move", "slot": 1})
	assert_eq(_first(ev, "move").move, "flail")
	assert_eq(_first(ev, "damage").side, 1)

func test_mutual_wipe_counts_as_player_loss() -> void:
	var p := Fixtures.creature("kindlet", 10)
	var f := Fixtures.creature("spikkin", 10)
	p.hp = 1
	f.hp = 1
	p.status = "stung"
	f.status = "stung"
	var b := Fixtures.battle([p], [f])
	b.take_turn({"type": "move", "slot": 1}, {"type": "move", "slot": 1})
	assert_true(b.over)
	assert_eq(b.winner, 1)

func test_fog_can_cause_a_miss() -> void:
	var r := FixedRng.new()
	r.f = 0.9  # 90 is not under 85
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("spikkin", 10)], {"weather": "fog", "rng": r})
	var ev := b.take_turn({"type": "move", "slot": 2}, {"type": "move", "slot": 1})
	assert_has(_types(ev), "miss")

func test_same_seed_same_battle() -> void:
	var run := func(seed_value: int) -> Array:
		var b := Battle.new([Fixtures.creature("kindlet", 12)], [Fixtures.creature("holtling", 12)],
			{"chart": Fixtures.chart(), "move_db": Fixtures.moves(), "rng": Rng.new(seed_value)})
		var all := []
		while not b.over and all.size() < 200:
			all.append_array(b.take_turn({"type": "move", "slot": 2}, {"type": "move", "slot": 2}))
		return all
	assert_eq(run.call(99), run.call(99))

func test_unknown_move_id_falls_back_to_flail() -> void:
	var p := Fixtures.creature("kindlet", 10)
	p.moves[0].id = "renamed_away"
	var b := Fixtures.battle([p], [Fixtures.creature("spikkin", 10)])
	var ev := b.take_turn(SCRAP, {"type": "move", "slot": 1})
	assert_eq(_first(ev, "move").move, "flail")

func test_force_switch_to_bad_index_is_reported() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 30)], [Fixtures.creature("spikkin", 2), Fixtures.creature("holtling", 5)], {"kind": "trainer"})
	b.take_turn({"type": "move", "slot": 1}, SCRAP)
	assert_eq(b.force_switch(1, 0)[0].type, "invalid")
	assert_eq(b.force_switch(1, 9)[0].type, "invalid")
	assert_true(b.needs_switch(1))

func test_turn_refused_while_a_replacement_is_owed() -> void:
	var p := Fixtures.creature("kindlet", 10)
	var f := Fixtures.creature("spikkin", 10)
	p.hp = 1
	f.hp = 1
	p.status = "stung"
	f.status = "stung"
	var b := Fixtures.battle([p, Fixtures.creature("holtling", 10)], [f, Fixtures.creature("holtling", 10)], {"kind": "trainer"})
	b.take_turn({"type": "move", "slot": 1}, {"type": "move", "slot": 1})
	assert_false(b.over)
	assert_true(b.needs_switch(0) and b.needs_switch(1))
	assert_eq(b.take_turn({"type": "switch", "index": 1}, SCRAP)[0].type, "invalid")
	assert_eq(b.force_switch(0, 1)[0].type, "switch")
	assert_eq(b.force_switch(1, 1)[0].type, "switch")
	assert_has(_types(b.take_turn(SCRAP, SCRAP)), "move")

func test_foe_cannot_catch_or_run() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("spikkin", 10)])
	var r := FixedRng.new()
	r.f = 0.0
	b.rng = r
	b.take_turn({"type": "move", "slot": 1}, {"type": "catch", "snare": "silver"})
	b.take_turn({"type": "move", "slot": 1}, {"type": "run"})
	assert_false(b.over)

func test_empty_party_ends_battle_without_crashing() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [])
	assert_true(b.over)
	assert_eq(b.winner, 0)
	assert_eq(b.current(1), null)
