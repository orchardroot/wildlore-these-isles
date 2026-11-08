extends TestCase
## Battle 2.0 move effects: drain, recoil, multi_hit, heal_self, protect, flinch, set_weather, cure_team, and the
## weather bonuses some moves carry ("weather_bonus": stronger, surer or kinder in a given weather).

const TEST_MOVES := [
	{"id": "t_hit", "name": "Hit", "type": "kin", "category": "physical", "power": 60, "accuracy": 100, "pp": 30, "effect": {"id": "none"}},
	{"id": "t_drain", "name": "Drain", "type": "kin", "category": "special", "power": 60, "accuracy": 100, "pp": 30, "effect": {"id": "drain", "frac": 50}},
	{"id": "t_recoil", "name": "Recoil", "type": "kin", "category": "physical", "power": 60, "accuracy": 100, "pp": 30, "effect": {"id": "recoil", "frac": 25}},
	{"id": "t_twice", "name": "Twice", "type": "kin", "category": "physical", "power": 30, "accuracy": 100, "pp": 30, "effect": {"id": "multi_hit", "hits": 2}},
	{"id": "t_flurry", "name": "Flurry", "type": "kin", "category": "physical", "power": 15, "accuracy": 100, "pp": 30, "effect": {"id": "multi_hit", "min": 2, "max": 5}},
	{"id": "t_heal", "name": "Heal", "type": "kin", "category": "status", "power": 0, "accuracy": 100, "pp": 10, "effect": {"id": "heal_self", "frac": 50, "target": "self"}},
	{"id": "t_sunheal", "name": "Sun Heal", "type": "hedgerow", "category": "status", "power": 0, "accuracy": 100, "pp": 10, "effect": {"id": "heal_self", "frac": 50, "target": "self"}, "weather_bonus": {"weather": ["sunshine"], "mult": 1.5}},
	{"id": "t_guard", "name": "Guard", "type": "kin", "category": "status", "power": 0, "accuracy": 100, "pp": 10, "priority": 3, "effect": {"id": "protect", "target": "self"}},
	{"id": "t_bite", "name": "Bite", "type": "kin", "category": "physical", "power": 20, "accuracy": 100, "pp": 30, "effect": {"id": "flinch", "chance": 100}},
	{"id": "t_rain", "name": "Rain", "type": "brook", "category": "status", "power": 0, "accuracy": 100, "pp": 10, "effect": {"id": "set_weather", "weather": "drizzle", "target": "self"}},
	{"id": "t_plump", "name": "Plump", "type": "storm", "category": "special", "power": 40, "accuracy": 100, "pp": 10, "effect": {"id": "set_weather", "weather": "downpour", "target": "self"}},
	{"id": "t_wild", "name": "Wild Swing", "type": "storm", "category": "physical", "power": 60, "accuracy": 50, "pp": 10, "effect": {"id": "none"}, "weather_bonus": {"weather": ["downpour"], "sure_hit": true}},
	{"id": "t_chat", "name": "Chat", "type": "kin", "category": "special", "power": 40, "accuracy": 100, "pp": 10, "effect": {"id": "none"}, "weather_bonus": {"weather": ["drizzle", "fog"], "mult": 2.0}},
	{"id": "t_cure", "name": "Cure", "type": "hedgerow", "category": "status", "power": 0, "accuracy": 100, "pp": 10, "effect": {"id": "cure_team", "target": "self"}},
	{"id": "t_spread", "name": "Spread", "type": "kin", "category": "special", "power": 40, "accuracy": 100, "pp": 10, "target": "all_foes", "effect": {"id": "drain", "frac": 50}},
	{"id": "t_wait", "name": "Wait", "type": "kin", "category": "status", "power": 0, "accuracy": 100, "pp": 30, "effect": {"id": "stat", "target": "self", "stat": "def", "stages": 1}},
]

static var _db: MoveDB

static func db() -> MoveDB:
	if _db == null:
		_db = MoveDB.load_default()
		for m in TEST_MOVES:
			_db.add(MoveDB.normalise(m))
	return _db

static func mon(id: String, move_ids: Array, spd := 50, hp := 120, types := ["kin"], extra := {}) -> Creature:
	var base := {"hp": hp, "atk": 60, "def": 60, "lore": 60, "ward": 60, "spd": spd}
	var e := {"base": base}
	e.merge(extra, true)
	var c := Creature.create(Fixtures.species(id, types, 50, e), 30, FixedRng.new(), db())
	c.moves = []
	for m in move_ids:
		c.moves.append(c.make_move_slot(m, db()))
	return c

static func fight(player: Array, foe: Array, opts := {}) -> Battle:
	var o := {"move_db": db(), "kind": "trainer"}
	o.merge(opts, true)
	return Fixtures.battle(player, foe, o)

static func first(events: Array, type: String) -> Dictionary:
	for e in events:
		if e.type == type:
			return e
	return {}

static func all_of(events: Array, type: String) -> Array:
	return events.filter(func(e): return e.type == type)

const USE := {"type": "move", "slot": 0}

func test_drain_heals_half_the_damage_dealt() -> void:
	var me := mon("me", ["t_drain"], 90)
	var foe := mon("foe", ["t_wait"], 10)
	var b := fight([me], [foe])
	me.hp = 40
	var ev := b.take_turn(USE, USE)
	var dealt := int(first(ev, "damage").amount)
	var heal := first(ev, "heal")
	assert_eq(heal.side, 0)
	assert_eq(heal.reason, "drain")
	assert_eq(int(heal.amount), maxi(1, dealt / 2))
	assert_eq(me.hp, 40 + int(heal.amount))

func test_recoil_hurts_the_user() -> void:
	var me := mon("me", ["t_recoil"], 90)
	var b := fight([me], [mon("foe", ["t_wait"], 10)])
	var ev := b.take_turn(USE, USE)
	var dealt := int(first(ev, "damage").amount)
	var r := first(ev, "recoil")
	assert_eq(r.side, 0)
	assert_eq(int(r.amount), maxi(1, dealt / 4))
	assert_eq(me.hp, me.max_hp() - int(r.amount))

## Last against last: a recoil move that knocks the foe out and then the user too is a win for whoever used it
## (it was the winning blow), not a whiteout for the player.
func test_a_recoil_double_knockout_goes_to_the_user() -> void:
	var me := mon("me", ["t_recoil"], 90)
	var foe := mon("foe", ["t_wait"], 10)
	foe.hp = 5
	me.hp = 1
	var b := fight([me], [foe])
	b.take_turn(USE, USE)
	assert_true(me.is_fainted() and foe.is_fainted(), "both down")
	assert_true(b.over)
	assert_eq(b.winner, Battle.PLAYER)

func test_a_foe_recoil_double_knockout_goes_to_the_foe() -> void:
	var me := mon("me", ["t_wait"], 10)
	var foe := mon("foe", ["t_recoil"], 90)
	me.hp = 5
	foe.hp = 1
	var b := fight([me], [foe])
	b.take_turn(USE, USE)
	assert_eq(b.winner, Battle.FOE)

## A Horseshoe (and a close friend's Hang On) stops a knockout hit; recoil is the user's own doing and isn't one.
func test_a_horseshoe_does_not_stop_recoil() -> void:
	var me := mon("me", ["t_recoil"], 90)
	me.held = "horseshoe"
	me.hp = 1
	var b := fight([me, mon("spare", ["t_wait"])], [mon("foe", ["t_wait"], 10, 250)])
	b.take_turn(USE, USE)
	assert_true(me.is_fainted())

func test_fixed_multi_hit_strikes_twice() -> void:
	var b := fight([mon("me", ["t_twice"], 90)], [mon("foe", ["t_wait"], 10, 250)])
	var ev := b.take_turn(USE, USE)
	assert_eq(all_of(ev, "damage").size(), 2)
	assert_eq(first(ev, "hits").count, 2)

func test_ranged_multi_hit_rolls_two_to_five() -> void:
	var b := fight([mon("me", ["t_flurry"], 90)], [mon("foe", ["t_wait"], 10, 250)])
	var ev := b.take_turn(USE, USE)  # FixedRng rolls 1.0: the top of the range
	assert_eq(all_of(ev, "damage").size(), 5)
	assert_eq(MoveFX.roll_hits({"id": "multi_hit", "min": 2, "max": 5}, FixedRng.new()), 5)
	var low := FixedRng.new()
	low.f = 0.0
	assert_eq(MoveFX.roll_hits({"id": "multi_hit", "min": 2, "max": 5}, low), 2)

func test_multi_hit_stops_when_the_target_drops() -> void:
	var foe := mon("foe", ["t_wait"], 10)
	var b := fight([mon("me", ["t_flurry"], 90)], [foe, mon("foe2", ["t_wait"], 10)])
	foe.hp = 1
	var ev := b.take_turn(USE, USE)
	assert_eq(all_of(ev, "damage").size(), 1)
	assert_eq(first(ev, "hits").count, 1)
	var types := ev.map(func(e): return e.type)
	assert_true(types.find("hits") < types.find("faint"), "\"Hit once!\" comes before the faint: %s" % [types])

func test_heal_self_restores_half_and_fails_at_full() -> void:
	var me := mon("me", ["t_heal"], 90)
	var b := fight([me], [mon("foe", ["t_wait"], 10)])
	me.hp = 10
	var ev := b.take_turn(USE, USE)
	assert_eq(first(ev, "heal").reason, "heal_self")
	assert_eq(me.hp, 10 + me.max_hp() / 2)
	me.hp = me.max_hp()
	ev = b.take_turn(USE, USE)
	assert_true(first(ev, "heal").is_empty())
	assert_eq(first(ev, "fail").side, 0)

func test_sunshine_heals_more_with_a_weather_bonus() -> void:
	var me := mon("me", ["t_sunheal"], 90)
	var b := fight([me], [mon("foe", ["t_wait"], 10)], {"weather": "sunshine"})
	me.hp = 1
	b.take_turn(USE, USE)
	assert_eq(me.hp, 1 + me.max_hp() * 75 / 100)

func test_protect_blocks_then_fails_if_used_again() -> void:
	var me := mon("me", ["t_guard"], 10)
	var foe := mon("foe", ["t_hit"], 90)
	var b := fight([me], [foe])
	var ev := b.take_turn(USE, USE)
	assert_eq(ev[0].type, "move", "protect goes first")
	assert_eq(ev[0].side, 0)
	assert_eq(first(ev, "protect").side, 0)
	assert_eq(first(ev, "protected").side, 0)
	assert_true(first(ev, "damage").is_empty())
	assert_eq(me.hp, me.max_hp())
	ev = b.take_turn(USE, USE)
	assert_eq(first(ev, "fail").side, 0, "a second protect in a row fails")
	assert_false(first(ev, "damage").is_empty())
	var hp := me.hp
	ev = b.take_turn(USE, USE)  # rested a turn (it failed), so it works again
	assert_eq(first(ev, "protected").side, 0)
	assert_eq(me.hp, hp)

func test_flinch_only_when_the_user_moved_first() -> void:
	var b := fight([mon("me", ["t_bite"], 90)], [mon("foe", ["t_hit"], 10, 250)])
	var ev := b.take_turn(USE, USE)
	var stop := first(ev, "cant_act")
	assert_eq(stop.side, 1)
	assert_eq(stop.reason, "flinched")
	assert_true(all_of(ev, "move").size() == 1)
	var slow := fight([mon("me", ["t_bite"], 10, 250)], [mon("foe", ["t_hit"], 90, 250)])
	ev = slow.take_turn(USE, USE)
	assert_true(first(ev, "cant_act").is_empty(), "moving second never flinches")
	ev = b.take_turn(USE, USE)
	assert_eq(first(ev, "cant_act").reason, "flinched", "and the flinch is fresh each turn")

func test_set_weather_lasts_five_turns_then_reverts() -> void:
	var b := fight([mon("me", ["t_rain", "t_wait"], 90)], [mon("foe", ["t_wait"], 10)], {"weather": "fog"})
	var ev := b.take_turn(USE, USE)
	var w := first(ev, "weather")
	assert_eq(w.weather, "drizzle")
	assert_eq(int(w.turns), 5)
	assert_eq(b.weather, "drizzle")
	assert_eq(b.weather_turns, 4, "the turn it was called counts")
	var wait := {"type": "move", "slot": 1}
	for i in 3:
		ev = b.take_turn(wait, USE)
		assert_eq(b.weather, "drizzle")
	ev = b.take_turn(wait, USE)
	assert_eq(first(ev, "weather_end").weather, "fog")
	assert_eq(b.weather, "fog")
	assert_eq(b.weather_turns, 0)

func test_calling_the_weather_you_already_have_fails() -> void:
	var b := fight([mon("me", ["t_rain"], 90)], [mon("foe", ["t_wait"], 10)], {"weather": "drizzle"})
	var ev := b.take_turn(USE, USE)
	assert_eq(first(ev, "fail").side, 0)
	assert_eq(b.weather_turns, 0)

func test_a_damaging_move_can_change_the_weather() -> void:
	var b := fight([mon("me", ["t_plump"], 90)], [mon("foe", ["t_wait"], 10, 250)])
	var ev := b.take_turn(USE, USE)
	assert_false(first(ev, "damage").is_empty())
	assert_eq(first(ev, "weather").weather, "downpour")

func test_weather_bonus_sure_hit() -> void:
	var dry := fight([mon("me", ["t_wild"], 90)], [mon("foe", ["t_wait"], 10, 250)])
	assert_false(first(dry.take_turn(USE, USE), "miss").is_empty(), "50% accuracy misses on a 1.0 roll")
	var wet := fight([mon("me", ["t_wild"], 90)], [mon("foe", ["t_wait"], 10, 250)], {"weather": "downpour"})
	assert_true(first(wet.take_turn(USE, USE), "miss").is_empty())

func test_weather_bonus_power() -> void:
	var mv := db().get_move("t_chat")
	assert_eq(MoveFX.power_in(mv, "clear"), 40)
	assert_eq(MoveFX.power_in(mv, "fog"), 80)
	var a := fight([mon("me", ["t_chat"], 90)], [mon("foe", ["t_wait"], 10, 250)])
	var b := fight([mon("me", ["t_chat"], 90)], [mon("foe", ["t_wait"], 10, 250)], {"weather": "drizzle"})
	var plain := int(first(a.take_turn(USE, USE), "damage").amount)
	var wet := int(first(b.take_turn(USE, USE), "damage").amount)
	assert_true(wet > plain * 3 / 2, "doubled power in drizzle (%d vs %d)" % [wet, plain])

func test_cure_team_clears_every_status_on_the_side() -> void:
	var me := mon("me", ["t_cure"], 90)
	var bench := mon("bench", ["t_wait"])
	me.status = "hexed"
	bench.status = "asleep"
	bench.status_turns = 2
	var b := fight([me, bench], [mon("foe", ["t_wait"], 10)])
	var ev := b.take_turn(USE, USE)
	assert_eq(first(ev, "cure_team").side, 0)
	assert_eq(me.status, "")
	assert_eq(bench.status, "")

func test_doubles_protect_guards_one_position_from_a_spread_move() -> void:
	var p := [mon("pa", ["t_spread"], 10), mon("pb", ["t_wait"], 10)]
	var f := [mon("fa", ["t_guard"], 90), mon("fb", ["t_wait"], 90)]
	var b := fight(p, f, {"double": true})
	p[0].hp = 50
	var ev := b.take_turn([{"type": "move", "slot": 0, "target": 0}, {"type": "move", "slot": 0}], [USE, USE])
	var hits := all_of(ev, "damage")
	assert_eq(hits.size(), 1)
	assert_eq(hits[0].pos, 1)
	assert_eq(first(ev, "protected").pos, 0)
	assert_eq(first(ev, "heal").pos, 0, "the drain still lands from the one it hit")

func test_old_moves_still_work() -> void:
	var b := Fixtures.battle([Fixtures.creature("kindlet", 10)], [Fixtures.creature("spikkin", 10)])
	var ev := b.take_turn(USE, USE)
	assert_eq(all_of(ev, "move").size(), 2)

func test_move_text_describes_new_effects() -> void:
	assert_has(MoveText.describe(db().get_move("t_drain")), "Heals the user by half of the damage dealt")
	assert_has(MoveText.describe(db().get_move("t_recoil")), "recoil")
	assert_has(MoveText.describe(db().get_move("t_flurry")), "2 to 5 times")
	assert_has(MoveText.describe(db().get_move("t_twice")), "twice")
	assert_has(MoveText.describe(db().get_move("t_guard")), "Fails if used twice in a row")
	assert_has(MoveText.describe(db().get_move("t_rain")), "drizzle for 5 turns")
	assert_has(MoveText.describe(db().get_move("t_wild")), "Never misses in a downpour")
	assert_has(MoveText.describe(db().get_move("t_chat")), "Twice as strong in drizzle or fog")

func test_validator_knows_the_new_effects() -> void:
	var bad := MoveDB.from_array([
		{"id": "x", "name": "X", "type": "kin", "category": "status", "power": 0, "accuracy": 100, "pp": 5, "effect": {"id": "set_weather", "weather": "hail", "target": "self"}},
		{"id": "y", "name": "Y", "type": "kin", "category": "physical", "power": 20, "accuracy": 100, "pp": 5, "effect": {"id": "multi_hit", "min": 4, "max": 2}},
		{"id": "z", "name": "Z", "type": "kin", "category": "physical", "power": 20, "accuracy": 100, "pp": 5, "effect": {"id": "drain"}},
		{"id": "ok", "name": "OK", "type": "kin", "category": "physical", "power": 20, "accuracy": 100, "pp": 5, "effect": {"id": "recoil", "frac": 25}},
	])
	var errors := []
	for id in bad.ids():
		errors.append_array(DataValidator._check_move(bad.get_move(id), Fixtures.chart()))
	assert_eq(errors.size(), 3, str(errors))
