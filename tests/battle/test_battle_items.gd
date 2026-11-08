extends TestCase

var items := ItemDB.load_default()

func _battle(player: Array, foe: Array, with_db := true) -> Battle:
	var opts := {}
	if with_db:
		opts["item_db"] = items
	return Fixtures.battle(player, foe, opts)

func _move(slot := 0) -> Dictionary:
	return {"type": "move", "slot": slot}

func test_item_heals_before_foe_moves() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var foe := Fixtures.creature("spikkin", 5)
	a.take_damage(12)
	var before := a.hp
	var b := _battle([a], [foe])
	var ev := b.take_turn({"type": "item", "item": "cup_of_tea", "target": 0}, _move())
	assert_eq(ev[0].type, "item")
	assert_eq(ev[0].side, Battle.PLAYER)
	assert_eq(ev[0].item, "cup_of_tea")
	assert_eq(ev[0].target, 0)
	assert_true(str(ev[0].text) != "")
	assert_true(a.hp > before - 1, "healed before being hit (or healed at all)")
	assert_eq(ev[1].type, "move", "foe still acts after")

func test_item_event_carries_the_hp_and_status_it_left() -> void:  # the plate shows these, not the end of the turn
	var a := Fixtures.creature("kindlet", 10)
	a.take_damage(12)
	a.status = "stung"
	var b := _battle([a], [Fixtures.creature("spikkin", 5)])
	var ev := b.take_turn({"type": "item", "item": "cup_of_tea", "target": 0}, _move())
	var healed := int(ev[0].hp)
	assert_true(healed > a.max_hp() - 12, "the hp right after the tea")
	assert_eq(ev[0].status, "stung")
	assert_true(a.hp < healed, "and the turn went on to hurt it")

func test_item_on_benched_revive() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var spare := Fixtures.creature("spikkin", 10)
	spare.take_damage(spare.hp)
	var b := _battle([a, spare], [Fixtures.creature("spikkin", 5)])
	var ev := b.take_turn({"type": "item", "item": "kendal_mint_cake", "target": 1}, _move())
	assert_eq(ev[0].type, "item")
	assert_true(spare.hp > 0)

func test_item_does_not_use_a_turn_slot_for_ordering() -> void:
	# Items resolve before moves even when the foe is far faster.
	var a := Fixtures.creature("kindlet", 5)
	var b := _battle([a], [Fixtures.creature("spikkin", 50)])
	var ev := b.take_turn({"type": "item", "item": "cup_of_tea", "target": 0}, _move())
	assert_eq(ev[0].type, "item")

func test_failed_item_still_emits_event() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var b := _battle([a], [Fixtures.creature("spikkin", 5)])
	var ev := b.take_turn({"type": "item", "item": "cup_of_tea", "target": 0}, _move())
	assert_eq(ev[0].type, "item")
	assert_true(str(ev[0].text) != "")

func test_bad_target_or_unknown_item_does_nothing() -> void:
	var a := Fixtures.creature("kindlet", 10)
	a.take_damage(5)
	var hp := a.hp
	var b := _battle([a], [Fixtures.creature("spikkin", 5)])
	var ev := b.take_turn({"type": "item", "item": "cup_of_tea", "target": 7}, _move())
	assert_eq(ev[0].text, "Nothing happened.")
	ev = b.take_turn({"type": "item", "item": "nope", "target": 0}, _move())
	assert_eq(ev[0].text, "Nothing happened.")
	assert_true(a.hp <= hp)

func test_no_item_db_says_nothing_happened() -> void:
	var a := Fixtures.creature("kindlet", 10)
	a.take_damage(5)
	var hp := a.hp
	var b := _battle([a], [Fixtures.creature("spikkin", 5)], false)
	var ev := b.take_turn({"type": "item", "item": "cup_of_tea", "target": 0}, {"type": "run"})
	assert_eq(ev[0], {"type": "item", "side": 0, "item": "cup_of_tea", "target": 0, "text": "Nothing happened."})
	assert_eq(a.hp, hp)

func test_foe_cannot_use_items() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var foe := Fixtures.creature("spikkin", 10)
	foe.take_damage(5)
	var hp := foe.hp
	var b := _battle([a], [foe])
	var ev := b.take_turn(_move(), {"type": "item", "item": "cup_of_tea", "target": 0})
	assert_eq(foe.hp, hp - ev.filter(func(e): return e.type == "damage" and e.side == Battle.FOE).reduce(func(s, e): return s + e.amount, 0))
	for e in ev:
		if e.type == "item":
			assert_eq(e.side, Battle.FOE)
			assert_eq(e.text, "Nothing happened.")

func test_snare_is_not_an_item_action() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var b := _battle([a], [Fixtures.creature("spikkin", 5)])
	var ev := b.take_turn({"type": "item", "item": "wicker_snare", "target": 0}, _move())
	assert_eq(ev[0].text, "Nothing happened.")
