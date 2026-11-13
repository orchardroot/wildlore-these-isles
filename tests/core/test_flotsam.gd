extends TestCase
## Flotsam (wave 54): the finds for the coracle, their data, and the validator rules that keep them out of walking reach.

func _items() -> ItemDB:
	return ItemDB.load_default()

func _zone(rows: Array, spawn := [0, 0]) -> ZoneData:
	return ZoneData.from_dict({"id": "fz", "name": "F", "kind": "route", "rows": rows, "spawn": spawn})

func _find(x: int, y: int, kind := "crate", item := "pasty") -> Dictionary:
	return {"id": "fl_fz_1", "zone": "fz", "x": x, "y": y, "kind": kind, "text": ["A crate."], "reward": {"item": item, "qty": 1}, "flag": "flotsam_fz_1"}

func _errors(z: ZoneData, f: Dictionary) -> Array:
	return Flotsam.check({"fz": z}, _items(), [f])

func _has(errs: Array, needle: String) -> bool:
	for e in errs:
		if needle in e:
			return true
	return false

const LAKE := [
	"..........",
	"..~~~~~~..",
	"..~~~~~~..",
	"..~~~~~~..",
	"..~~~~~~..",
	".........."]

func test_a_find_in_the_middle_of_a_lake_is_fine() -> void:
	assert_eq(_errors(_zone(LAKE), _find(4, 2)), [])

func test_a_find_beside_the_bank_can_be_reached_on_foot() -> void:
	assert_true(_has(_errors(_zone(LAKE), _find(2, 1)), "within reach of the bank"))

func test_a_find_on_dry_land_you_can_walk_to_is_refused() -> void:
	assert_true(_has(_errors(_zone(LAKE), _find(0, 5, "cache")), "can be walked to"))

func test_an_islet_cache_is_fine() -> void:
	var z := _zone([
		"..........",
		"..~~~~~~..",
		"..~~~~~~..",
		"..~~.~~~..",
		"..~~~~~~..",
		"..........."], [0, 0])
	assert_eq(_errors(z, _find(4, 3, "cache", "honeycomb")), [])

func test_a_find_in_a_narrow_channel_would_cork_it() -> void:
	var z := _zone(["...", ".~.", ".~.", ".~.", "..."])
	assert_true(_has(_errors(z, _find(1, 2)), "narrow channel"))

func test_a_find_on_a_wall_or_off_the_water_is_refused() -> void:
	assert_true(_has(_errors(_zone(LAKE), _find(0, 0)), "not water a coracle can float on"))

func test_rewards_are_small_real_items() -> void:
	var bad := _find(4, 2, "crate", "no_such_item")
	assert_true(_has(_errors(_zone(LAKE), bad), "real item"))
	var rich := _find(4, 2)
	rich.reward = {"money": 5000}
	assert_true(_has(_errors(_zone(LAKE), rich), "never money"))
	var dash := _find(4, 2)
	dash.text = ["Bad — dash."]
	assert_true(_has(_errors(_zone(LAKE), dash), "dashes"))

func test_no_flotsam_on_the_water_at_an_edge() -> void:
	var rows := ["~~~~..", "~~~~..", "~~~~..", "~~~~.."]
	var z := ZoneData.from_dict({"id": "fz", "name": "F", "kind": "route", "rows": rows, "spawn": [5, 0], "edges": {"west": {"to": "x"}}})
	assert_true(_has(Flotsam.check({"fz": z}, _items(), [_find(0, 1)]), "not water a coracle"), "the current's too strong at an edge")

func test_the_real_finds_are_sound() -> void:
	var zones := ZoneData.load_all()
	assert_eq(Flotsam.check(zones, _items()), [])

func test_there_are_about_sixty_in_forty_zones() -> void:
	var zs := {}
	var kinds := {}
	for f in Flotsam.all():
		zs[f.zone] = true
		kinds[f.kind] = int(kinds.get(f.kind, 0)) + 1
	assert_true(Flotsam.all().size() >= 55 and Flotsam.all().size() <= 75, "about 60: %d" % Flotsam.all().size())
	assert_true(zs.size() >= 40, "%d zones" % zs.size())
	for k in Flotsam.KINDS:
		assert_true(int(kinds.get(k, 0)) >= 8, "%s: %s" % [k, kinds])
	for f in Flotsam.all():
		assert_false(f.reward.has("money"), f.id)

func test_found_is_a_flag_and_an_old_save_has_none() -> void:
	var f: Dictionary = Flotsam.all()[0]
	var d := GameStateData.new()
	assert_false(Flotsam.found(d, f))
	assert_eq(Flotsam.found_count(d), 0)
	d.set_flag(str(f.flag), true)
	assert_true(Flotsam.found(d, f))
	var back := GameStateData.from_dict(d.to_dict(), Dex.load_default())
	assert_true(Flotsam.found(back, f), "a find stays found")
	assert_eq(Flotsam.found_count(back), 1)

func test_meshes_build_for_every_kind() -> void:
	for k in Flotsam.KINDS:
		var m: ArrayMesh = FlotsamScene._mesh(k)
		assert_true(m.get_surface_count() > 0, k)

func test_swimmers_and_fliers_keep_pace_with_the_coracle() -> void:
	assert_true(Follower.swims(["brook"]))
	assert_true(Follower.swims(["kin", "tide"]))
	assert_true(Follower.swims(["gale", "fae"]))
	assert_false(Follower.swims(["hearth"]))
	assert_false(Follower.swims([]))
	assert_true(Follower.water_dip(["brook"], true) < 0.0, "a swimmer sits low")
	assert_true(Follower.water_dip(["gale"], true) > 0.0, "a flier hovers")
	assert_eq(Follower.water_dip(["hearth"], true), 0.0)
	assert_eq(Follower.water_dip(["brook"], false), 0.0)
	var a := {"enabled": true, "lead": true, "kind": "route", "area": 2000, "bike": false, "wading": true, "shown": true, "npc": false, "placed": true}
	assert_false(Follower.should_show(a.enabled, a.lead, a.kind, a.area, a.bike, a.wading, a.shown, a.npc, a.placed), "a land creature stays hidden")
	assert_true(Follower.should_show(a.enabled, a.lead, a.kind, a.area, a.bike, a.wading, a.shown, a.npc, a.placed, true), "a swimmer comes too")
	assert_false(Follower.should_show(a.enabled, a.lead, a.kind, a.area, true, a.wading, a.shown, a.npc, a.placed, true), "but not on the bike")
