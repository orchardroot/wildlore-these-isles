extends TestCase
## The follower: the party lead trotting one tile behind the player (pure rules only).

func _open(blocked: Array) -> Callable:
	return func(p: Vector2i) -> bool: return not blocked.has(p)

func test_follows_the_tile_the_player_just_left() -> void:
	var f := Vector2i(5, 6)
	var player := Vector2i(5, 5)
	for d in ["down", "down", "left", "up", "right", "right"]:
		var to := GridMotion.step(player, d)
		var nxt := Follower.next_tile(f, player, to)
		assert_eq(nxt, player, "always steps onto the player's previous tile")
		assert_true(maxi(absi(nxt.x - to.x), absi(nxt.y - to.y)) <= 1, "and ends up next to the player")
		f = nxt
		player = to

func test_snaps_when_too_far_to_walk() -> void:
	assert_false(Follower.snaps(Vector2i(3, 3), Vector2i(3, 4)), "one tile: walk")
	assert_false(Follower.snaps(Vector2i(3, 3), Vector2i(3, 3)), "same tile: nothing to do")
	assert_true(Follower.snaps(Vector2i(3, 3), Vector2i(3, 5)), "a ledge hop leaves it two behind: hop")
	assert_true(Follower.snaps(Vector2i(-1, -1), Vector2i(3, 5)), "not placed yet")

func test_hops_down_after_a_ledge() -> void:
	assert_true(Follower.hops(Vector2i(3, 3), Vector2i(3, 5)), "straight down two: a ledge")
	assert_false(Follower.hops(Vector2i(3, 3), Vector2i(4, 4)), "diagonal: a teleport, just appear")
	assert_false(Follower.hops(Vector2i(3, 3), Vector2i(3, 9)), "far away: appear")
	assert_false(Follower.hops(Vector2i(-1, -1), Vector2i(-1, 1)), "not placed yet")

func test_stride_walks_straight_or_hops() -> void:
	var a := Vector3(1.5, 0, 1.5)
	var b := Vector3(1.5, 0, 3.5)
	assert_eq(Follower.stride_pos(a, b, 0.0, false), a)
	assert_eq(Follower.stride_pos(a, b, 1.0, false), b)
	assert_eq(Follower.stride_pos(a, b, 0.5, false), Vector3(1.5, 0, 2.5), "walks in a straight line")
	assert_true(Follower.stride_pos(a, b, 0.5, true).y > 0.2, "a hop lifts off in the middle")
	assert_true(Follower.stride_pos(a, b, 1.0, true).distance_to(b) < 0.001, "and lands on the spot")

func test_reappears_behind_the_player() -> void:
	assert_eq(Follower.behind_tile(Vector2i(5, 5), "down", _open([])), Vector2i(5, 4))
	assert_eq(Follower.behind_tile(Vector2i(5, 5), "left", _open([])), Vector2i(6, 5))
	# behind is a wall: a side tile instead
	var side := Follower.behind_tile(Vector2i(5, 5), "down", _open([Vector2i(5, 4)]))
	assert_true(side in [Vector2i(4, 5), Vector2i(6, 5)], "beside the player, got %s" % side)
	# boxed in on every side: nowhere to stand (hidden until the player moves)
	var boxed := _open([Vector2i(5, 4), Vector2i(4, 5), Vector2i(6, 5), Vector2i(5, 6)])
	assert_eq(Follower.behind_tile(Vector2i(5, 5), "down", boxed), Vector2i(-1, -1))

func _show(over := {}) -> bool:
	var a := {"enabled": true, "lead": true, "kind": "town", "area": 2000, "bike": false, "wading": false,
		"player_shown": true, "npc_here": false, "placed": true}
	a.merge(over, true)
	return Follower.should_show(a.enabled, a.lead, a.kind, a.area, a.bike, a.wading, a.player_shown, a.npc_here, a.placed)

func test_visibility_rules() -> void:
	assert_true(_show(), "out walking in town")
	assert_true(_show({"kind": "route"}))
	assert_false(_show({"enabled": false}), "setting off")
	assert_false(_show({"lead": false}), "nobody able to walk")
	assert_false(_show({"bike": true}), "cycling")
	assert_false(_show({"wading": true}), "on the water")
	assert_false(_show({"player_shown": false}), "journeys and arrival scenes hide the player")
	assert_false(_show({"npc_here": true}), "someone walked onto its tile")
	assert_false(_show({"placed": false}), "nowhere to stand yet")
	assert_false(_show({"kind": "interior", "area": 7 * 8}), "a box room is too cramped")
	assert_true(_show({"kind": "interior", "area": 11 * 9}), "a cottage has room now")
	assert_true(_show({"kind": "interior", "area": 30 * 24}), "a big hall has room")

func test_lead_is_first_healthy_creature() -> void:
	var d := GameStateData.new()
	var a := Fixtures.creature("kindlet", 10)
	var b := Fixtures.creature("spikkin", 10)
	d.party = [a, b]
	assert_eq(Follower.lead_of(d), a)
	a.hp = 0
	assert_eq(Follower.lead_of(d), b, "the lead fainted: the next one takes over")
	b.hp = 0
	assert_eq(Follower.lead_of(d), null)

func test_bigger_creatures_stand_taller() -> void:
	assert_true(Follower.scale_for(0.0) < Follower.scale_for(1.0))
	assert_true(Follower.scale_for(1.0) <= 1.0, "never taller than the player's sprite")
	assert_true(Follower.scale_for(0.0) >= 0.6)

func test_mood_lines_fill_in_the_name_and_vary() -> void:
	var seen := {}
	for i in 40:
		var l := Follower.mood_line("Bramblet", 1.0, "clear", "day", "Macclesfield", "town", i)
		assert_true(l.contains("Bramblet"), l)
		assert_false(l.contains("{"), "no unfilled templates: " + l)
		assert_false(l.contains("—"), "no em-dashes: " + l)
		seen[l] = true
	assert_true(seen.size() >= 6, "plenty of variety, got %d" % seen.size())

func test_mood_lines_follow_the_conditions() -> void:
	var rain := Follower.mood_pool(1.0, "downpour", "day", "route")
	var dry := Follower.mood_pool(1.0, "clear", "day", "route")
	assert_true(rain.any(func(t): return str(t).contains("rain")), "rain lines in the rain")
	assert_false(dry.any(func(t): return str(t).contains("rain")), "and not when dry")
	var hurt := Follower.mood_pool(0.2, "clear", "day", "route")
	assert_true(hurt.any(func(t): return str(t).contains("tired") or str(t).contains("worn")), "low HP shows")
	var night := Follower.mood_pool(1.0, "clear", "night", "route")
	assert_true(night.size() > 0)
	var town := Follower.mood_line("Bramblet", 1.0, "clear", "day", "Macclesfield", "town", 0)
	assert_true(town != "")

func test_about_thirty_templates() -> void:
	assert_true(Follower.template_count() >= 28, "got %d" % Follower.template_count())

func test_mood_line_is_deterministic_per_pick() -> void:
	var a := Follower.mood_line("Kindlet", 0.5, "fog", "dusk", "Buxton", "route", 7)
	var b := Follower.mood_line("Kindlet", 0.5, "fog", "dusk", "Buxton", "route", 7)
	assert_eq(a, b)

func test_curls_up_by_the_fire_or_at_night() -> void:
	assert_false(Follower.curls_up(1.0, true, "day"), "not until the player has stood still a while")
	assert_true(Follower.curls_up(6.0, true, "day"), "by a fire")
	assert_true(Follower.curls_up(6.0, false, "night"), "at night")
	assert_false(Follower.curls_up(6.0, false, "day"), "daytime, no fire: it stays up")

func test_fire_must_be_close() -> void:
	var fires: Array[Vector2i] = [Vector2i(3, 3)]
	assert_true(Follower.by_fire(fires, Vector2i(5, 4)))
	assert_false(Follower.by_fire(fires, Vector2i(20, 20)))
	assert_false(Follower.by_fire([] as Array[Vector2i], Vector2i(0, 0)))
