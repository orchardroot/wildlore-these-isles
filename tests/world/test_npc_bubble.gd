extends TestCase
## Bubbles over heads and umbrellas in the rain (wave 54): who gets which, decided without any nodes.

func test_children_are_found_by_id_and_name() -> void:
	assert_true(NpcBubble.is_child({"id": "sh_conker_kid"}))
	assert_true(NpcBubble.is_child({"id": "scout_x", "name": "Boy Scout"}))
	assert_true(NpcBubble.is_child({"id": "hh3_lad"}))
	assert_false(NpcBubble.is_child({"id": "tea_lady"}), "a lady is not a lad")
	assert_false(NpcBubble.is_child({"id": "poo_scout", "trainer": "poo_scout"}), "trainers keep their sight lines")
	assert_false(NpcBubble.is_child({"id": "silk_fan"}))

func test_errand_giver_wears_a_mark_until_asked() -> void:
	NpcBubble.reset()
	Quests.use([{"id": "q1", "start_flag": "q1_s", "done_flag": "q1_d", "steps": [],
		"start": {"zone": "town", "npc": "giver", "ask": "a", "accept": "b"}}])
	var d := GameStateData.new()
	assert_eq(NpcBubble.kind_for("town", {"id": "giver"}, d), NpcBubble.ASK)
	assert_eq(NpcBubble.kind_for("town", {"id": "someone_else"}, d), "")
	assert_eq(NpcBubble.kind_for("elsewhere", {"id": "giver"}, d), "")
	d.set_flag("q1_s", true)
	assert_eq(NpcBubble.kind_for("town", {"id": "giver"}, d), "", "already asked")
	Quests.reset()
	NpcBubble.reset()

func test_trainers_never_wear_one() -> void:
	NpcBubble.reset()
	Quests.use([{"id": "q1", "start_flag": "a", "done_flag": "b", "steps": [],
		"start": {"zone": "town", "npc": "t", "ask": "a", "accept": "b"}}])
	assert_eq(NpcBubble.kind_for("town", {"id": "t", "trainer": "t"}, GameStateData.new()), "")
	Quests.reset()
	NpcBubble.reset()

func test_regular_hearts_need_favour() -> void:
	var d := GameStateData.new()
	var def := {"id": "reg_ned"}
	assert_eq(NpcBubble.regular_of("whitby", def), "ned")
	assert_eq(NpcBubble.regular_of("dublin", {"id": "reg_ned_away"}), "ned")
	assert_eq(NpcBubble.regular_of("whitby", {"id": "reg_nobody"}), "")
	assert_eq(NpcBubble.kind_for("whitby", def, d), "", "a stranger")
	d.set_flag(Regulars.flag_key("ned"), {"favour": 2})
	assert_eq(NpcBubble.kind_for("whitby", def, d), NpcBubble.HEART)

func test_umbrellas_only_outdoors_in_rain() -> void:
	var person := {"id": "a", "sprite": "villager_1"}
	assert_true(NpcBubble.umbrella_for("drizzle", "town", person))
	assert_true(NpcBubble.umbrella_for("downpour", "route", person))
	assert_false(NpcBubble.umbrella_for("clear", "town", person))
	assert_false(NpcBubble.umbrella_for("gale", "town", person))
	assert_false(NpcBubble.umbrella_for("downpour", "interior", person))
	assert_false(NpcBubble.umbrella_for("downpour", "town", {"sprite": "creature:herdwick"}), "sheep keep their own counsel")
	assert_false(NpcBubble.umbrella_for("downpour", "town", {"sprite": "hiker", "trainer": "x"}))

func test_range() -> void:
	assert_true(NpcBubble.in_range(Vector2i(0, 0), Vector2i(6, 6)))
	assert_false(NpcBubble.in_range(Vector2i(0, 0), Vector2i(7, 0)))
	assert_true(NpcBubble.in_range(Vector2i(0, 0), Vector2i(4, 1), NpcBubble.SPOT_RANGE))
