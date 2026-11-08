extends TestCase
## Critical hits: the stage table, the damage maths, the high-crit flag and charm, the words, the AI, determinism.

func _move(id: String) -> Dictionary:
	return Fixtures.moves().get_move(id)

func _crit_rng() -> FixedRng:
	var r := FixedRng.new()
	r.f = 0.0  # every chance comes up, and the lowest damage roll
	return r

func _hit(att: Creature, def: Creature, mv: Dictionary, rng: Rng, pct := DamageCalc.CRIT_CHANCE) -> Dictionary:
	return DamageCalc.compute(att, def, mv, Fixtures.chart(), "clear", rng, pct)

func test_stage_table() -> void:
	assert_eq(DamageCalc.crit_percent(0), DamageCalc.CRIT_CHANCE)
	assert_true(absf(DamageCalc.crit_percent(0) - 100.0 / 24.0) < 0.001, "about 1 in 24")
	assert_eq(DamageCalc.crit_percent(1), 12.5)  # 1 in 8
	assert_eq(DamageCalc.crit_percent(2), 50.0)
	assert_eq(DamageCalc.crit_percent(3), 100.0)
	assert_eq(DamageCalc.crit_percent(9), 100.0, "clamped")
	assert_eq(DamageCalc.crit_percent(-2), DamageCalc.CRIT_CHANCE, "clamped")

func test_a_crit_does_one_and_a_half_times() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var d := Fixtures.creature("spikkin", 10)
	var plain: Dictionary = _hit(a, d, _move("kindle"), FixedRng.new())
	var crit: Dictionary = _hit(a, d, _move("kindle"), FixedRng.new(), 100.0)
	assert_false(plain.crit)
	assert_true(crit.crit)
	assert_eq(crit.damage, floori(18 * 1.5))

func test_crit_ignores_positive_defence_and_negative_attack_stages() -> void:
	var a := Fixtures.creature("kindlet", 30)
	var d := Fixtures.creature("spikkin", 30)
	var mv := _move("kindle")
	var base: int = _hit(a, d, mv, _crit_rng(), 100.0).damage
	d.stages["ward"] = 3
	a.stages["lore"] = -3
	assert_eq(_hit(a, d, mv, _crit_rng(), 100.0).damage, base, "a crit shrugs off both")
	assert_true(_hit(a, d, mv, FixedRng.new(), 0.0).damage < _hit(Fixtures.creature("kindlet", 30), Fixtures.creature("spikkin", 30), mv, FixedRng.new(), 0.0).damage, "a plain hit does not")

func test_crit_keeps_the_attackers_boosts_and_defenders_drops() -> void:
	var a := Fixtures.creature("kindlet", 30)
	var d := Fixtures.creature("spikkin", 30)
	var mv := _move("kindle")
	var base: int = _hit(a, d, mv, _crit_rng(), 100.0).damage
	a.stages["lore"] = 2
	d.stages["ward"] = -2
	assert_true(_hit(a, d, mv, _crit_rng(), 100.0).damage > base)

func test_same_seed_same_crits() -> void:
	var a := Fixtures.creature("kindlet", 20)
	var d := Fixtures.creature("spikkin", 20)
	var run := func(seed_value: int) -> Array:
		var r := Rng.new(seed_value)
		var out := []
		for i in 40:
			var res: Dictionary = _hit(a, d, _move("kindle"), r, 25.0)
			out.append([res.crit, res.damage])
		return out
	assert_eq(run.call(7), run.call(7))
	assert_true(run.call(7) != run.call(8))
	assert_true(run.call(7).any(func(x): return x[0]) and run.call(7).any(func(x): return not x[0]), "some of each")

func test_high_crit_rate_over_many_rolls() -> void:
	var r := Rng.new(49)
	var plain := 0
	var high := 0
	for i in 4000:
		plain += int(r.chance(DamageCalc.crit_percent(0)))
		high += int(r.chance(DamageCalc.crit_percent(1)))
	assert_true(plain > 4000 / 24 * 0.8 and plain < 4000 / 24 * 1.2, "about 1 in 24, got %d" % plain)
	assert_true(high > 500 * 0.85 and high < 500 * 1.15, "about 1 in 8, got %d" % high)

func test_move_and_charm_add_stages() -> void:
	var c := Fixtures.creature("kindlet", 10)
	assert_eq(DamageCalc.crit_stage(c, _move("kindle")), 0)
	assert_eq(DamageCalc.crit_stage(c, {"crit": 1}), 1)
	c.held = "white_heather"
	assert_eq(Charms.crit_stages(c), 1)
	assert_eq(DamageCalc.crit_stage(c, {"crit": 1}), 2)
	c.held = "horseshoe"
	assert_eq(Charms.crit_stages(c), 0)

func test_flagged_moves_and_validator_range() -> void:
	for id in ["treble_twenty", "peregrine_plunge", "kestrel_dive", "flint_flick"]:
		var mv := _move(id)
		assert_eq(int(mv.get("crit", 0)), 1, id)
		assert_true(str(mv.category) != "status", id)

func test_move_text_says_so() -> void:
	assert_true("High chance of a critical hit." in MoveText.describe(_move("treble_twenty")))
	assert_true("High chance of a critical hit." in MoveText.describe({"category": "physical", "effect": {"id": "none"}, "crit": 1}))
	assert_false("critical" in MoveText.describe(_move("kindle")))

func test_the_ai_likes_a_high_crit_move_a_little() -> void:
	var me := Fixtures.creature("kindlet", 20)
	var foe := Fixtures.creature("spikkin", 20)
	var b := Fixtures.battle([me], [foe])
	var mv: Dictionary = _move("kindle").duplicate()
	var plain := BattleAI.attack_score(b, me, foe, mv)
	mv["crit"] = 1
	var keen := BattleAI.attack_score(b, me, foe, mv)
	assert_true(keen > plain and keen < plain * 1.1, "%f vs %f" % [keen, plain])

func test_a_battle_hit_reports_the_crit() -> void:
	var me := Fixtures.creature("kindlet", 20)
	var foe := Fixtures.creature("spikkin", 20)
	var b := Fixtures.battle([me], [foe], {"rng": Rng.new(3)})
	var seen := false
	for i in 200:
		foe.hp = foe.max_hp()
		var ev := b.take_turn({"type": "move", "slot": 0}, {"type": "move", "slot": 0})
		for e in ev:
			if e.type == "damage" and bool(e.get("crit", false)):
				seen = true
	assert_true(seen, "a crit shows up in the event stream")
