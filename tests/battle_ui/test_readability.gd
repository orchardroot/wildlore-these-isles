extends TestCase
## 2.1 battle readability: the weather says what it does, moves say when the sky helps them, crits, stat stages,
## honest snare wobbles and odds in words.

var _items := ItemDB.load_default()

# --- weather -------------------------------------------------------------------------------------------------

func test_sunshine_crit_is_for_both_sides() -> void:
	assert_eq(Weather.crit_mult("sunshine", 0), 2.0)
	assert_eq(Weather.crit_mult("sunshine", 1), 2.0)
	assert_eq(Weather.crit_mult("drizzle", 0), 1.0)

func test_weather_effects_list_boosts_then_drops() -> void:
	var fx := Weather.effects("sunshine")
	assert_eq(fx.map(func(e): return e.type), ["hearth", "hedgerow", "brook"])
	assert_eq(fx.map(func(e): return e.text), ["Hearth +50%", "Hedgerow +50%", "Brook -20%"])
	assert_eq(fx.map(func(e): return e.up), [true, true, false])
	assert_eq(Weather.effects("downpour").map(func(e): return e.text), ["Brook +50%", "Tide +50%", "Hearth -50%"])
	assert_eq(Weather.effects("drizzle").map(func(e): return e.text), ["Brook +10%", "Tide +10%"])
	assert_eq(Weather.effects("fog"), [])
	assert_eq(Weather.effects("clear"), [])

func test_weather_notes_for_the_rules_that_are_not_types() -> void:
	assert_eq(Weather.note("sunshine"), "Critical hits twice as likely, both sides")
	assert_eq(Weather.note("fog"), "Every move 15% less likely to land")
	assert_eq(Weather.note("drizzle"), "")

func test_move_mult_combines_type_and_weather_bonus() -> void:
	var db := Fixtures.moves()
	assert_near(Weather.move_mult("drizzle", db.get_move("dales_drizzle")), 2.2)  # brook +10%, and its own bonus x2
	assert_near(Weather.move_mult("sunshine", db.get_move("kindle")), 1.5)
	assert_near(Weather.move_mult("downpour", db.get_move("kindle")), 0.5)
	assert_near(Weather.move_mult("clear", db.get_move("kindle")), 1.0)
	assert_near(Weather.move_mult("sunshine", db.get_move("snug_as_a_bug")), 1.0, 0.0001, "a status move is never 'stronger'")

func test_move_tag_words() -> void:
	var db := Fixtures.moves()
	assert_eq(Weather.move_tag("sunshine", db.get_move("kindle")), "Stronger in Sunshine")
	assert_eq(Weather.move_tag("downpour", db.get_move("kindle")), "Weaker in a Downpour")
	assert_eq(Weather.move_tag("clear", db.get_move("kindle")), "")
	assert_eq(Weather.move_tag("gale", db.get_move("updraught")), "Stronger in a Gale")

func test_weather_plate_shows_effect_chips_and_note() -> void:
	var hud := BattleHUD.new()
	hud._ready()
	hud.set_weather("sunshine", 0)
	var plate := hud.weather_plate
	assert_eq(plate.chip_texts(), ["Hearth +50%", "Hedgerow +50%", "Brook -20%"])
	assert_true(plate.note_l.visible)
	assert_eq(plate.note_l.text, "Critical hits twice as likely, both sides")
	hud.set_weather("gale", 3)
	assert_eq(plate.chip_texts(), ["Gale +30%"])
	assert_false(plate.note_l.visible)
	hud.free()

# --- move menu -----------------------------------------------------------------------------------------------

func _slot_of(c: Creature, id: String) -> int:
	for i in c.moves.size():
		if c.moves[i].id == id:
			return i
	return -1

func test_move_rows_carry_weather_arrows() -> void:
	var c := Fixtures.creature("kindlet", 10)
	var db := Fixtures.moves()
	var slot := _slot_of(c, "kindle")
	var rows := BattleMenus.move_rows(c, db, "sunshine")
	assert_eq(rows[slot].get("weather"), "sunshine")
	assert_eq(rows[slot].get("weather_dir"), 1)
	rows = BattleMenus.move_rows(c, db, "downpour")
	assert_eq(rows[slot].get("weather_dir"), -1)
	rows = BattleMenus.move_rows(c, db, "clear")
	for r in rows:
		assert_false(r.has("weather"), "no tags under clear skies")

func test_move_footer_says_stronger_in_the_weather() -> void:
	var c := Fixtures.creature("kindlet", 10)
	var slot := _slot_of(c, "kindle")
	var text := BattleMenus.move_footer(c, slot, Fixtures.moves(), "", "sunshine")
	assert_true(text.contains("Stronger in Sunshine"), text)
	assert_false(BattleMenus.move_footer(c, slot, Fixtures.moves(), "", "clear").contains("Stronger"))

# --- crits, stages, numbers ----------------------------------------------------------------------------------

func _ctx() -> Dictionary:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("spikkin", 5)], {"kind": "wild", "item_db": _items})
	return EventPlayer.make_ctx(b)

func test_crit_has_its_own_line_and_cue() -> void:
	var ev := {"type": "damage", "side": 1, "amount": 5, "hp": 3, "effectiveness": 2.0, "crit": true}
	assert_eq(EventPlayer.lines_for(ev, _ctx()), ["Right on the nose! A critical hit!", "It's super effective!"])
	var cue := EventPlayer.fx_for(ev, _ctx())
	assert_true(bool(cue.get("crit", false)))
	assert_eq(cue.strength, "strong")
	ev.crit = false
	assert_false(bool(EventPlayer.fx_for(ev, _ctx()).get("crit", false)), "super effective alone is not a crit")

func test_plate_stage_arrows_follow_events() -> void:
	var hud := BattleHUD.new()
	hud._ready()
	var c := Fixtures.creature("spikkin", 5)
	hud.set_creature(Battle.FOE, c)
	var p := hud.plate(Battle.FOE)
	assert_false(p.stage_row.visible)
	hud.on_event({"type": "stat", "side": 1, "stat": "atk", "delta": 2})
	hud.on_event({"type": "stat", "side": 1, "stat": "spd", "delta": -1})
	hud.on_event({"type": "stat", "side": 1, "stat": "def", "delta": 0})
	assert_true(p.stage_row.visible)
	assert_eq(p.stage_row.stages, {"atk": 2, "spd": -1})
	assert_eq(p.stage_row.labels(), ["ATK +2", "SPD -1"])
	hud.on_event({"type": "stat", "side": 1, "stat": "atk", "delta": -2})
	assert_eq(p.stage_row.labels(), ["SPD -1"])
	hud.set_creature(Battle.FOE, c)  # a switch-in starts level
	assert_false(p.stage_row.visible)
	c.change_stage("lore", 1)
	hud.set_stages(Battle.FOE, c.stages)
	assert_eq(p.stage_row.labels(), ["LOR +1"])
	hud.free()

func test_charm_stage_events_count_too() -> void:
	var hud := BattleHUD.new()
	hud._ready()
	hud.set_creature(Battle.PLAYER, Fixtures.creature("kindlet", 10))
	hud.on_event({"type": "charm", "side": 0, "stat": "def", "delta": 1, "text": "x"})
	assert_eq(hud.plate(Battle.PLAYER).stage_row.labels(), ["DEF +1"])
	hud.free()

func test_damage_numbers_follow_the_setting() -> void:
	var hud := BattleHUD.new()
	hud._ready()
	hud.set_creature(Battle.FOE, Fixtures.creature("spikkin", 5))
	var was := Settings.damage_numbers
	Settings.damage_numbers = true
	assert_eq(hud.number_text({"type": "damage", "side": 1, "amount": 12, "hp": 3}), "-12")
	assert_eq(hud.number_text({"type": "damage", "side": 1, "amount": 0, "hp": 3}), "")
	assert_eq(hud.number_text({"type": "status_damage", "side": 1, "amount": 2, "hp": 3}), "-2")
	assert_eq(hud.number_text({"type": "stat", "side": 1, "stat": "atk", "delta": 1}), "")
	assert_eq(hud.number_text({"type": "knack", "side": 1, "other_side": 0, "amount": 3, "hp": 20, "text": "x"}), "-3", "a prick hurts the attacker")
	assert_eq(hud.number_text({"type": "heal", "side": 0, "amount": 6, "hp": 20, "reason": "drain"}), "+6")
	assert_eq(hud.number_text({"type": "charm", "side": 0, "amount": 2, "hp": 20, "text": "x"}), "+2", "a regen charm")
	assert_eq(hud.number_text({"type": "charm", "side": 0, "stat": "def", "delta": 1, "text": "x"}), "")
	Settings.damage_numbers = false
	assert_eq(hud.number_text({"type": "damage", "side": 1, "amount": 12, "hp": 3}), "")
	Settings.damage_numbers = was
	hud.free()

# --- catching ------------------------------------------------------------------------------------------------

func test_wobbles_come_from_the_real_roll() -> void:
	assert_eq(Catching.wobbles(0.1, 0.3, true), 3)
	# chance 0.3: the thresholds are 0.3^(1/4) = 0.74, 0.3^(1/2) = 0.55, 0.3^(3/4) = 0.41
	assert_eq(Catching.wobbles(0.35, 0.3, false), 3, "a near miss shakes three times")
	assert_eq(Catching.wobbles(0.5, 0.3, false), 2)
	assert_eq(Catching.wobbles(0.6, 0.3, false), 1)
	assert_eq(Catching.wobbles(0.9, 0.3, false), 0, "bursts straight out")
	assert_eq(Catching.wobbles(0.9, 0.0, false), 0)

func test_attempt_remembers_its_roll() -> void:
	var c := Fixtures.creature("spikkin", 5)
	var r := FixedRng.new()
	r.f = 0.42
	Catching.attempt(c, "wicker", "day", r)
	assert_near(Catching.last_roll, 0.42)

func test_catch_lines_for_near_miss_burst_and_clean_catch() -> void:
	var cx := _ctx()
	assert_eq(EventPlayer.lines_for({"type": "catch", "success": false, "wobbles": 3}, cx), ["You threw a snare!", "Argh! So close! The wild Spikkin broke free at the last second!"])
	assert_eq(EventPlayer.lines_for({"type": "catch", "success": false, "wobbles": 0}, cx), ["You threw a snare!", "The wild Spikkin burst straight out!"])
	assert_eq(EventPlayer.lines_for({"type": "catch", "success": false, "wobbles": 2}, cx), ["You threw a snare!", "Oh no! The wild Spikkin broke free!"])
	assert_eq(EventPlayer.lines_for({"type": "catch", "success": true, "clean": true}, cx), ["You threw a snare!", "Gotcha! Spikkin was caught!", "A clean catch: not a scratch on it, and fast asleep. Textbook."])

func test_catch_odds_in_words() -> void:
	assert_eq(MoveText.catch_odds(0.33), "About 1 in 3")
	assert_eq(MoveText.catch_odds(0.1), "About 1 in 10")
	assert_eq(MoveText.catch_odds(0.01), "Under 1 in 50")
	assert_eq(MoveText.catch_odds(0.5), "About 1 in 2")
	assert_eq(MoveText.catch_odds(0.66), "About 2 in 3")
	assert_eq(MoveText.catch_odds(0.76), "About 3 in 4")
	assert_eq(MoveText.catch_odds(0.9), "About 9 in 10")
	assert_eq(MoveText.catch_odds(1.0), "A dead cert")

func test_bag_odds_are_numbers_once_the_species_is_caught() -> void:
	var foe := Fixtures.creature("spikkin", 5)
	var data := GameStateData.new()
	data.party = [Fixtures.creature("kindlet", 10)]
	data.bag = {"wicker_snare": 3}
	var f := BattleFlow.new(data, Fixtures.dex(), Fixtures.moves(), Fixtures.chart(), _items, Rng.new(1), [foe], {}, FakeBattleUI.new())
	var e: Dictionary = f.battle_items().filter(func(x): return x.id == "wicker_snare")[0]
	assert_false(bool(e.get("known", false)))
	assert_eq(BattleMenus.bag_footer(e), "%s  ·  %s" % [MoveText.catch_band(float(e.odds)), e.desc])
	data.mark_caught("spikkin")
	e = f.battle_items().filter(func(x): return x.id == "wicker_snare")[0]
	assert_true(bool(e.known))
	assert_eq(BattleMenus.bag_footer(e), "%s  ·  %s" % [MoveText.catch_odds(float(e.odds)), e.desc])

func test_flow_wobbles_and_clean_flag_from_the_throw() -> void:
	var sp := Fixtures.species("pushover", ["kin"], 50, {"catch_rate": 255})
	var foe := Creature.create(sp, 3, FixedRng.new(), Fixtures.moves())
	foe.status = "asleep"
	var data := GameStateData.new()
	data.party = [Fixtures.creature("kindlet", 10)]
	data.bag = {"wicker_snare": 1}
	var ui := FakeBattleUI.new()
	ui.picks.append({"kind": "item", "item": "wicker_snare"})
	var f := BattleFlow.new(data, Fixtures.dex(), Fixtures.moves(), Fixtures.chart(), _items, Rng.new(3), [foe], {}, ui)
	f.run()
	assert_eq(f.result.result, "caught")
	var catch_ev: Dictionary = {}
	for batch in ui.event_batches:
		for e in batch:
			if e.type == "catch":
				catch_ev = e
	assert_eq(int(catch_ev.wobbles), 3)
	assert_true(bool(catch_ev.get("clean", false)), "full HP and asleep")
