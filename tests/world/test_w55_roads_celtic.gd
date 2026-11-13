extends TestCase
## Wave 55, roads-celtic: new roads in Wales, Ireland, Northern Ireland and the Isle of Man must never be a sequence
## break. At every story step the places a player can walk to (tests/support/w55_reach.gd) are the same as in the game
## before the roads, apart from the new routes themselves (zones the baseline does not know).
##
## The baseline is tests/fixtures/w55_roads_celtic_reach.json, written from the unchanged game (delete it and run
## tools/test.sh w55_roads_celtic to write it: that first run fails on purpose). Never regenerate it to make a failure
## go away.

const Reach := preload("res://tests/support/w55_reach.gd")
const BASELINE := "res://tests/fixtures/w55_roads_celtic_reach.json"

func _sets(zones: Dictionary) -> Array:
	var out := []
	var cache := {}
	var gates := Reach.gate_flags(zones)
	var last_sig := ""
	var last_ids := []
	for step in Reach.story_steps(zones):
		var flags := {}
		var used := []
		for f in step.flags:
			flags[f] = true
			if gates.has(f):
				used.append(f)
		used.sort()
		# only the flags that stand an NPC in the way, and where the player may start, can change what is reachable
		var sig := ",".join(PackedStringArray(used)) + "|" + ",".join(PackedStringArray(step.seeds))
		if sig != last_sig:
			last_sig = sig
			last_ids = Reach.reach(zones, flags, step.seeds, cache).keys().filter(func(id): return zones[id].kind != "interior")
			last_ids.sort()
		out.append(last_ids)
	return out

func test_the_set_of_places_at_each_story_step_is_unchanged() -> void:
	var zones := ZoneData.load_all()
	var sets := _sets(zones)
	if not FileAccess.file_exists(BASELINE):
		var ids := zones.keys().filter(func(id): return zones[id].kind != "interior")
		ids.sort()
		var f := FileAccess.open(BASELINE, FileAccess.WRITE)
		f.store_string(JSON.stringify({"zones": ids, "steps": sets}, "", false))
		f.close()
		fail("baseline written to " + BASELINE + "; commit it")
		return
	var base = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
	assert_true(base is Dictionary, "baseline loads")
	var known := {}
	for id in base.zones:
		known[id] = true
	assert_eq(sets.size(), base.steps.size(), "one set per story step")
	for i in mini(sets.size(), base.steps.size()):
		var now := {}
		for id in sets[i]:
			if known.has(id):
				now[id] = true
		var was := {}
		for id in base.steps[i]:
			was[id] = true
		for id in now:
			assert_true(was.has(id), "step %d: %s is reachable earlier than before (a sequence break)" % [i, id])
		for id in was:
			assert_true(now.has(id), "step %d: %s is no longer reachable" % [i, id])

func test_the_baseline_reaches_ireland_and_wales_so_the_check_means_something() -> void:
	if not FileAccess.file_exists(BASELINE):
		return
	var base = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
	var last: Array = base.steps[base.steps.size() - 1]
	for id in ["cardiff", "swansea", "limerick", "bushmills", "dublin", "derry"]:
		assert_true(id in last, id + " is reachable by the end")
	var first: Array = base.steps[0]
	assert_false("cardiff" in first, "Cardiff is not open on the first step")
	assert_false("derry" in first, "Derry is not open on the first step")
