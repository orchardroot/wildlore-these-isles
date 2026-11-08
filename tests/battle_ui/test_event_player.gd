extends TestCase

func _ctx(kind := "wild", trainer := {}) -> Dictionary:
	var a := Fixtures.creature("kindlet", 10)
	var foe := Fixtures.creature("spikkin", 5)
	var b := Fixtures.battle([a], [foe], {"kind": kind, "item_db": ItemDB.load_default()})
	return EventPlayer.make_ctx(b, trainer)

func _lines(ev: Dictionary, ctx := {}) -> Array:
	return EventPlayer.lines_for(ev, ctx if not ctx.is_empty() else _ctx())

func test_type_colours_cover_every_type() -> void:
	for t in Fixtures.chart().types:
		assert_true(TypeColours.COLOURS.has(t), "colour for %s" % t)
	assert_eq(TypeColours.COLOURS.size(), 16)

func test_move_and_foe_naming() -> void:
	assert_eq(_lines({"type": "move", "side": 0, "user": "Kindlet", "move": "kindle"}), ["Kindlet used Kindle!"])
	assert_eq(_lines({"type": "move", "side": 1, "user": "Spikkin", "move": "scrap"}), ["The wild Spikkin used Scrap!"])
	var tr := _ctx("trainer", {"name": "Keeper Maud"})
	assert_eq(EventPlayer.lines_for({"type": "move", "side": 1, "user": "Spikkin", "move": "scrap"}, tr), ["Keeper Maud's Spikkin used Scrap!"])

func test_flail_has_a_name() -> void:
	assert_eq(_lines({"type": "move", "side": 0, "user": "Kindlet", "move": "flail"}), ["Kindlet used Flail!"])

func test_miss_and_no_effect() -> void:
	assert_eq(_lines({"type": "miss", "side": 0}), ["Kindlet's attack missed!"])
	assert_eq(_lines({"type": "no_effect", "side": 1}), ["It doesn't affect the wild Spikkin..."])

func test_damage_lines() -> void:
	assert_eq(_lines({"type": "damage", "side": 1, "amount": 5, "hp": 3, "effectiveness": 2.0, "crit": false}), ["It's super effective!"])
	assert_eq(_lines({"type": "damage", "side": 1, "amount": 5, "hp": 3, "effectiveness": 0.5, "crit": false}), ["It's not very effective..."])
	assert_eq(_lines({"type": "damage", "side": 1, "amount": 5, "hp": 3, "effectiveness": 1.0, "crit": true}), ["Right on the nose! A critical hit!"])
	assert_eq(_lines({"type": "damage", "side": 1, "amount": 5, "hp": 3, "effectiveness": 2.0, "crit": true}), ["Right on the nose! A critical hit!", "It's super effective!"])
	assert_eq(_lines({"type": "damage", "side": 1, "amount": 5, "hp": 3, "effectiveness": 1.0, "crit": false}), [])

func test_stat_lines() -> void:
	assert_eq(_lines({"type": "stat", "side": 0, "stat": "atk", "delta": 1}), ["Kindlet's Attack rose!"])
	assert_eq(_lines({"type": "stat", "side": 0, "stat": "def", "delta": 2}), ["Kindlet's Defence rose sharply!"])
	assert_eq(_lines({"type": "stat", "side": 1, "stat": "spd", "delta": -1}), ["The wild Spikkin's Speed fell!"])
	assert_eq(_lines({"type": "stat", "side": 1, "stat": "spd", "delta": -2}), ["The wild Spikkin's Speed fell harshly!"])
	assert_eq(_lines({"type": "stat", "side": 0, "stat": "atk", "delta": 0}), ["Kindlet's Attack won't go any further!"])

func test_status_lines() -> void:
	assert_eq(_lines({"type": "status", "side": 1, "status": "soaked"}), ["The wild Spikkin is soaked through."])
	assert_eq(_lines({"type": "status", "side": 1, "status": "asleep"}), ["The wild Spikkin is fast asleep."])
	for s in Rules.STATUSES:
		assert_eq(_lines({"type": "status", "side": 0, "status": s}).size(), 1, s)
	assert_eq(_lines({"type": "status_cured", "side": 0, "status": "asleep"}), ["Kindlet woke up!"])
	assert_eq(_lines({"type": "status_cured", "side": 0, "status": "stung"}), ["Kindlet is no longer stung."])

func test_cant_act_and_self_hit() -> void:
	assert_eq(_lines({"type": "cant_act", "side": 0, "reason": "asleep"}), ["Kindlet is fast asleep."])
	assert_eq(_lines({"type": "cant_act", "side": 0, "reason": "chilled"}), ["Kindlet is too cold to move!"])
	assert_eq(_lines({"type": "cant_act", "side": 0, "reason": "mystery"}), ["Kindlet can't move!"])
	assert_eq(_lines({"type": "self_hit", "side": 0, "amount": 3, "hp": 4}), ["Kindlet is muddled and hurt itself!"])

func test_status_damage_faint_switch() -> void:
	assert_eq(_lines({"type": "status_damage", "side": 0, "status": "stung", "amount": 2, "hp": 5}), ["Kindlet is hurt by its stings!"])
	assert_eq(_lines({"type": "status_damage", "side": 1, "status": "hexed", "amount": 2, "hp": 5}), ["The wild Spikkin is hurt by the hex!"])
	assert_eq(_lines({"type": "faint", "side": 1, "user": "Spikkin"}), ["The wild Spikkin fainted!"])
	assert_eq(_lines({"type": "faint", "side": 0, "user": "Kindlet"}), ["Kindlet fainted!"])
	assert_eq(_lines({"type": "switch", "side": 0, "index": 1, "user": "Holtling"}), ["Go! Holtling!"])
	var tr := _ctx("trainer", {"name": "Keeper Maud"})
	assert_eq(EventPlayer.lines_for({"type": "switch", "side": 1, "index": 1, "user": "Dipling"}, tr), ["Keeper Maud sends out Dipling!"])

func test_run_lines() -> void:
	assert_eq(_lines({"type": "run", "side": 0, "success": true}), ["Got away safely!"])
	assert_eq(_lines({"type": "run", "side": 0, "success": false}), ["Couldn't get away!"])
	assert_eq(EventPlayer.lines_for({"type": "run", "side": 0, "success": false}, _ctx("trainer", {"name": "Keeper Maud"})), ["No! There's no running from a keeper battle!"])

func test_item_lines() -> void:
	var ev := {"type": "item", "side": 0, "item": "cup_of_tea", "target": 0, "text": "Kindlet recovered 12 HP."}
	assert_eq(_lines(ev), ["You used a Cup of Tea.", "Kindlet recovered 12 HP."])
	ev = {"type": "item", "side": 0, "item": "nope", "target": 0, "text": "Nothing happened."}
	assert_eq(_lines(ev), ["You used a nope.", "Nothing happened."])

func test_catch_lines() -> void:
	var ev := {"type": "catch", "success": true, "snare_name": "Wicker Snare"}
	assert_eq(_lines(ev), ["You threw a Wicker Snare!", "Gotcha! Spikkin was caught!"])
	ev = {"type": "catch", "success": false}
	assert_eq(_lines(ev), ["You threw a snare!", "Oh no! The wild Spikkin broke free!"])
	ev = {"type": "catch", "success": false, "reason": "trainer"}
	assert_eq(EventPlayer.lines_for(ev, _ctx("trainer", {"name": "Keeper Maud"})), ["You can't snare another keeper's creature!"])

func test_invalid_and_end() -> void:
	assert_eq(_lines({"type": "invalid", "side": 0, "reason": "needs_switch"}), ["Pick a creature to send out first."])
	assert_eq(_lines({"type": "invalid", "side": 0, "reason": "bad_switch"}), ["That creature can't be sent out."])
	assert_eq(_lines({"type": "end", "winner": 0}), [])

func test_every_event_type_has_a_cue() -> void:
	var evs := [
		{"type": "move", "side": 0, "user": "Kindlet", "move": "kindle"}, {"type": "miss", "side": 0}, {"type": "no_effect", "side": 1},
		{"type": "damage", "side": 1, "amount": 5, "hp": 3, "effectiveness": 2.0, "crit": false},
		{"type": "stat", "side": 0, "stat": "atk", "delta": 1}, {"type": "stat", "side": 0, "stat": "atk", "delta": -1},
		{"type": "status", "side": 1, "status": "asleep"}, {"type": "status_cured", "side": 0, "status": "asleep"},
		{"type": "cant_act", "side": 0, "reason": "asleep"}, {"type": "self_hit", "side": 0, "amount": 3, "hp": 4},
		{"type": "status_damage", "side": 0, "status": "stung", "amount": 2, "hp": 5}, {"type": "faint", "side": 1, "user": "Spikkin"},
		{"type": "switch", "side": 0, "index": 0, "user": "Kindlet"}, {"type": "run", "side": 0, "success": true},
		{"type": "end", "winner": 0}, {"type": "item", "side": 0, "item": "cup_of_tea", "target": 0, "text": "x"},
		{"type": "catch", "success": true}, {"type": "invalid", "side": 0, "reason": "needs_switch"},
	]
	var seen := {}
	for ev in evs:
		var cue := EventPlayer.fx_for(ev, _ctx())
		assert_true(cue.has("cue") and str(cue.cue) != "", "cue for %s" % ev.type)
		seen[ev.type] = true
	for t in ["move", "miss", "no_effect", "damage", "stat", "status", "status_cured", "cant_act", "self_hit", "status_damage", "faint", "switch", "run", "end", "item", "catch", "invalid"]:
		assert_true(seen.has(t), "covered %s" % t)

func test_cue_details() -> void:
	var c := EventPlayer.fx_for({"type": "move", "side": 0, "user": "Kindlet", "move": "kindle"}, _ctx())
	assert_eq(c.cue, "attack")
	assert_eq(c.side, 0)
	assert_eq(c.move_type, "hearth")
	c = EventPlayer.fx_for({"type": "damage", "side": 1, "amount": 5, "hp": 3, "effectiveness": 2.0, "crit": true}, _ctx())
	assert_eq(c.cue, "hit")
	assert_eq(c.strength, "strong")
	assert_eq(c.hp, 3)

func test_item_and_switch_cues_carry_what_the_plate_shows() -> void:  # not the creature's end-of-turn state
	var c := EventPlayer.fx_for({"type": "item", "side": 0, "item": "cup_of_tea", "target": 0, "hp": 21, "status": "", "text": "x"}, _ctx())
	assert_eq([c.cue, c.hp, c.status], ["heal", 21, ""])
	c = EventPlayer.fx_for({"type": "switch", "side": 0, "index": 1, "user": "Holtling", "hp": 30, "status": "stung"}, _ctx())
	assert_eq([c.cue, c.hp, c.status], ["switch", 30, "stung"])
	assert_eq(EventPlayer.fx_for({"type": "cure_team", "side": 0, "count": 2, "cured": [0, 1]}, _ctx()).team, [0, 1], "a team cure clears the plates it cured")

func _double_ctx() -> Dictionary:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10), Fixtures.creature("holtling", 10)],
		[Fixtures.creature("spikkin", 5), Fixtures.creature("kindlet", 5)], {"kind": "trainer", "double": true})
	return EventPlayer.make_ctx(b, {"name": "Twin Aoife"})

func test_double_lines_name_the_creature_at_the_position() -> void:
	var cx := _double_ctx()
	assert_eq(EventPlayer.lines_for({"type": "miss", "side": 0, "pos": 1}, cx), ["Holtling's attack missed!"])
	assert_eq(EventPlayer.lines_for({"type": "status", "side": 1, "pos": 1, "status": "soaked"}, cx), ["Twin Aoife's Kindlet is soaked through."])
	assert_eq(EventPlayer.lines_for({"type": "invalid", "side": 0, "pos": 0, "reason": "no_catch_in_doubles"}, cx), ["You can't throw a snare into a double battle!"])
	assert_eq(EventPlayer.lines_for({"type": "invalid", "side": 0, "pos": 1, "reason": "no_run_in_doubles"}, cx), ["There's no running from a double battle!"])

func test_double_cues_carry_positions() -> void:
	var cx := _double_ctx()
	var atk := EventPlayer.fx_for({"type": "move", "side": 0, "pos": 1, "user": "Holtling", "move": "scrap", "target_side": 1, "target_pos": 0, "spread": false}, cx)
	assert_eq([atk.cue, atk.side, atk.pos, atk.target_side, atk.target_pos], ["attack", 0, 1, 1, 0])
	var hit := EventPlayer.fx_for({"type": "damage", "side": 1, "pos": 1, "amount": 3, "hp": 9, "effectiveness": 1.0, "crit": false}, cx)
	assert_eq([hit.cue, hit.side, hit.pos], ["hit", 1, 1])
	var dodge := EventPlayer.fx_for({"type": "miss", "side": 0, "pos": 0, "target_side": 1, "target_pos": 1}, cx)
	assert_eq([dodge.cue, dodge.side, dodge.pos], ["dodge", 1, 1])
	assert_false(EventPlayer.fx_for({"type": "damage", "side": 1, "amount": 3, "hp": 9, "effectiveness": 1.0, "crit": false}, _ctx()).has("pos"), "singles cues unchanged")

func test_doubles_effectiveness_names_the_target() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10), Fixtures.creature("holtling", 10)],
		[Fixtures.creature("spikkin", 5), Fixtures.creature("scuttlet", 5)], {"kind": "trainer", "double": true})
	var ctx := EventPlayer.make_ctx(b, {"name": "Twins"})
	assert_eq(EventPlayer.lines_for({"type": "damage", "side": 1, "pos": 1, "amount": 5, "hp": 3, "effectiveness": 2.0}, ctx),
		["It's super effective on Twins's Scuttlet!"])
