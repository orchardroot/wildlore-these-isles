extends TestCase
## The validator rule: the coracle must never open a way the story keeps shut (data_api/ride_check.gd).

## A river runs down the middle; the only land crossing is a bridge with a Warden on it (a story gate).
## The player arrives on the west bank and the east bank holds the exit.
func _zone(extra := {}) -> ZoneData:
	var rows := [
		"..~..",
		"..~..",
		"..=..",
		"..~..",
		"..~.."]
	var warden := {"id": "w", "x": 2, "y": 2, "script": "gate", "hide_if": "badge_urban"}
	var d := {"id": "rz", "name": "R", "kind": "route", "rows": rows, "spawn": [0, 2], "npcs": [warden],
		"warps": [{"x": 4, "y": 2, "to": "rz", "tx": 3, "ty": 2}], "props": [], "signs": [], "edges": {}}
	d.merge(extra, true)
	return ZoneData.from_dict(d)

func test_a_gate_npc_is_the_hide_if_wall_not_the_quest_giver() -> void:
	assert_true(RideCheck.is_gate({"x": 1, "y": 1, "hide_if": "badge_frost"}))
	assert_true(RideCheck.is_gate({"x": 1, "y": 1, "hide_if": "ch7_judged"}))
	assert_true(RideCheck.is_gate({"x": 1, "y": 1, "hide_if": "moot_won"}))
	assert_true(RideCheck.is_gate({"x": 1, "y": 1, "hide_if": "trainer_strachan_1"}))
	assert_false(RideCheck.is_gate({"x": 1, "y": 1, "hide_if": "q_pennines_whit_tuba"}), "a quest step")
	assert_false(RideCheck.is_gate({"x": 1, "y": 1, "hide_if": "caught_nessie"}), "a legend")
	assert_false(RideCheck.is_gate({"x": 1, "y": 1, "hide_if": "badge_frost", "move": "wander"}), "people who move are not walls")
	assert_false(RideCheck.is_gate({"x": 1, "y": 1, "hide_if": "badge_frost", "show_if": "ch1"}))
	assert_false(RideCheck.is_gate({"x": 1, "y": 1}))

func test_a_river_round_a_warden_is_a_leak() -> void:
	var z := _zone()
	var all := {"rz": z}
	assert_true(RideCheck.has_water(z))
	var found := RideCheck.leaks(all, z)
	assert_false(found.is_empty(), "the coracle goes round the Warden")
	assert_eq(found[0].what, "w:4,2")
	assert_true(RideCheck.problems(all)[0].contains("warp at 4,2"))

func test_a_no_ride_rect_closes_the_leak_and_only_there() -> void:
	var z := _zone({"no_ride": [[2, 0, 1, 2], [2, 3, 1, 2]]})
	var all := {"rz": z}
	assert_eq(RideCheck.leaks(all, z), [])
	assert_eq(RideCheck.problems(all), [])
	assert_true(z.can_ride(Vector2i(2, 0), ["brook_wade"]) == false)

func test_no_warden_no_problem() -> void:
	var z := _zone({"npcs": []})
	assert_eq(RideCheck.leaks({"rz": z}, z), [], "with the bridge open walking gets there anyway")

func test_an_edge_with_the_river_on_it_is_no_way_round() -> void:
	var z := ZoneData.from_dict({"id": "rz", "name": "R", "kind": "route", "rows": ["...~~", "...~~", "...~~"], "spawn": [0, 1],
		"npcs": [], "edges": {"east": {"to": "rz"}}, "props": [], "signs": [], "warps": []})
	var all := {"rz": z}
	assert_false(z.reachable(Vector2i(0, 1), RideCheck.RIDING).has(Vector2i(4, 1)), "the border river is shut at the edge")
	assert_eq(RideCheck.leaks(all, z), [])

func test_a_gate_held_by_an_ability_is_not_skipped_by_a_boat() -> void:
	# a player who has Brook-wade but not Fell-scramble must not paddle round a scree gate
	var rows := [
		"..~..",
		"..~..",
		"../..",
		"..~..",
		"..~.."]
	var z := ZoneData.from_dict({"id": "rz", "name": "R", "kind": "route", "rows": rows, "spawn": [0, 2], "npcs": [], "props": [], "signs": [], "edges": {},
		"warps": [{"x": 4, "y": 2, "to": "rz", "tx": 3, "ty": 2, "gate": "fell_scramble"}]})
	var all := {"rz": z}
	var found := RideCheck.leaks(all, z)
	assert_true(found.any(func(l): return l.what == "w:4,2" and l.without == "fell_scramble"), "round the scree by river: %s" % [found])

func test_bad_rects_are_reported() -> void:
	var z := _zone({"npcs": [], "no_ride": [[1, 2, 0, 1], [9, 9, 1, 1]]})
	var errs := RideCheck.problems({"rz": z})
	assert_eq(errs.size(), 2)

func test_inverness_keeps_its_bridge_gate() -> void:
	var all := ZoneData.load_all()
	assert_false(all["inverness"].no_ride.is_empty(), "the Kessock works are walled off from the sea")
	assert_eq(RideCheck.leaks(all, all["inverness"]), [])
