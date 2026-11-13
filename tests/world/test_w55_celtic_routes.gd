extends TestCase
## Wave 55, roads-celtic: what every new route has (two ends that join up, a gate where the story needs one, six or more
## wild things, trainers, plaques, signs, something off the path) and nothing that reads like a dash. The sequence-break
## proof is in test_w55_roads_celtic.gd.

## route -> [the two places it joins, the flag the road is shut by until (or "")]. Only routes whose zone file exists
## are checked, so a route can be added to the list as it is built.
const ROUTES := {
	"aberglaslyn": [["yr_wyddfa", "cambrian_coast"], "ch3_ddraig_woke"],
	"pen_y_gwryd": [["ogwen", "yr_wyddfa"], ""],
	"llyn_tegid": [["llangollen", "aberystwyth"], "ch3_ddraig_woke"],
	"glamorgan_coast": [["swansea", "cardiff"], ""],
	"healy_pass": [["cork", "ring_of_kerry"], ""],
	"golden_vale": [["kilkenny", "limerick"], ""],
	"clare_road": [["burren", "limerick"], ""],
	"hook_head": [["wicklow", "comeraghs"], ""],
	"lower_bann": [["bushmills", "lough_neagh"], "badge_iron"],
	"erne_shore": [["donegal_town", "enniskillen"], "badge_iron"],
}

func _built() -> Array:
	var out := []
	for id in ROUTES:
		if FileAccess.file_exists("res://data/zones/%s.json" % id):
			out.append(id)
	return out

## Set once the wave's routes are in: the brief asks for eight to ten.
const MIN_ROUTES := 8

func test_enough_routes_are_built() -> void:
	assert_true(_built().size() >= MIN_ROUTES, "routes built: %d" % _built().size())

func test_each_route_joins_the_two_places_it_says() -> void:
	var zones := ZoneData.load_all()
	for id in _built():
		var z: ZoneData = zones[id]
		var want: Array = ROUTES[id][0]
		assert_eq(z.edges.size(), 2, id + " has two edges")
		var ends := []
		for side in z.edges:
			var to := str(z.edges[side].to)
			ends.append(to)
			assert_true(zones.has(to), id + " -> " + to)
			var back: Dictionary = zones[to].edges.get(ZoneData.OPPOSITE[side], {})
			assert_eq(str(back.get("to", "")), id, "%s: %s has the edge back" % [id, to])
		ends.sort()
		var sorted_want := want.duplicate()
		sorted_want.sort()
		assert_eq(ends, sorted_want, id + " joins the right places")
		assert_eq(z.kind, "route", id)
		assert_true(z.scaled_floor >= 2, id + " lifts with the story")
		assert_true(z.walkable(z.spawn), id + " spawn")

func test_each_route_has_wild_things_trainers_plaques_and_something_off_the_path() -> void:
	var zones := ZoneData.load_all()
	var plaques := {}
	for zid in zones:
		for sg in zones[zid].signs:
			if str(sg.get("plaque", "")) != "" and zid not in _built():
				plaques[str(sg.plaque)] = true
	for id in _built():
		var z: ZoneData = zones[id]
		assert_true(z.encounters.get("grass", []).size() >= 6, id + " grass encounters")
		assert_true(z.encounters.get("water", []).size() >= 3, id + " water encounters")
		var dex := Dex.load_default()
		for table in z.encounters.values():
			for e in table:
				assert_true(dex.has(str(e.species)), "%s: %s exists" % [id, e.species])
		var trainers := 0
		for n in z.npcs:
			if n.has("trainer"):
				trainers += 1
				var t: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/trainers/%s.json" % n.trainer))
				assert_true(t is Dictionary and int(t.get("scaled_floor", 0)) >= 2 and not t.party.is_empty(), id + " trainer " + str(n.trainer))
		assert_true(trainers >= 3, id + " trainers: %d" % trainers)
		var mine := 0
		for sg in z.signs:
			assert_false("—" in str(sg.text) or "–" in str(sg.text), id + " sign has a dash")
			if str(sg.get("plaque", "")) != "":
				mine += 1
				assert_false(plaques.has(str(sg.plaque)), "plaque id is unique: " + str(sg.plaque))
				plaques[str(sg.plaque)] = true
				assert_true(str(sg.get("title", "")) != "" and str(sg.text).length() > 120, id + " plaque " + str(sg.plaque))
		assert_true(mine >= 2, id + " plaques: %d" % mine)
		assert_true(z.signs.size() >= mine + 3, id + " signs")
		assert_true(Poi.for_zone(id).size() >= 1, id + " has a point of interest")
		assert_true(FieldSpots.for_zone(id).size() >= 1, id + " has a field spot")
		var places: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_map.json")).places
		assert_true(places.has(id), id + " is on the world map")

func test_people_have_something_to_say_and_no_dashes() -> void:
	var zones := ZoneData.load_all()
	for id in _built():
		var z: ZoneData = zones[id]
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/%s.json" % id))
		assert_true(d is Dictionary, id + " has a dialogue file")
		for n in z.npcs:
			if n.has("script"):
				assert_true(d.has(str(n.script)), "%s: %s has its script" % [id, n.id])
		assert_false("—" in JSON.stringify(d) or "–" in JSON.stringify(d), id + " dialogue has a dash")
		for n in z.npcs:
			if n.has("trainer"):
				var t: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/trainers/%s.json" % n.trainer))
				assert_false("—" in JSON.stringify(t) or "–" in JSON.stringify(t), str(n.trainer) + " has a dash")

func test_a_gated_route_is_shut_by_the_flag_the_existing_gate_uses() -> void:
	var zones := ZoneData.load_all()
	for id in _built():
		var z: ZoneData = zones[id]
		var flag := str(ROUTES[id][1])
		var wardens := 0
		for n in z.npcs:
			if str(n.get("script", "")) == "gate_" + id:
				wardens += 1
				assert_eq(str(n.get("hide_if", "")), flag, id + " warden hides with the right flag")
		assert_eq(wardens, 3 if flag != "" else 0, id + " wardens")

func test_every_edge_arrival_is_walkable() -> void:
	var zones := ZoneData.load_all()
	for id in _built():
		var z: ZoneData = zones[id]
		for side in z.edges:
			var target: ZoneData = zones[str(z.edges[side].to)]
			for b in z._border(side):
				if z.walkable(b):
					assert_true(target.walkable(z.edge_arrival(side, b, target)), "%s %s edge %s lands on foot" % [id, side, b])

const Reach := preload("res://tests/support/w55_reach.gd")
## The place on the far side of each gated road, the one the story has not opened yet.
const BEYOND := {"aberglaslyn": "cambrian_coast", "llyn_tegid": "aberystwyth", "lower_bann": "bushmills", "erne_shore": "donegal_town"}

## The sequence test has teeth: take the Wardens off a gated road and the place beyond it opens a step early.
func test_a_gated_road_without_its_wardens_would_be_a_sequence_break() -> void:
	var zones := ZoneData.load_all()
	var steps := Reach.story_steps(zones)
	var cache := {}
	for id in _built():
		var flag := str(ROUTES[id][1])
		if flag == "":
			continue
		var at := 0
		for i in steps.size():
			if flag in steps[i].flags:
				at = i - 1
				break
		var flags := {}
		for f in steps[at].flags:
			flags[f] = true
		var beyond := str(BEYOND[id])
		assert_false(Reach.reach(zones, flags, steps[at].seeds, cache).has(beyond), "%s: %s stays shut before %s" % [id, beyond, flag])
		var z: ZoneData = zones[id]
		var wardens: Array = z.npcs
		z.npcs = wardens.filter(func(n): return str(n.get("script", "")) != "gate_" + id)
		assert_true(Reach.reach(zones, flags, steps[at].seeds, cache).has(beyond), "%s: without Wardens %s would open early" % [id, beyond])
		z.npcs = wardens  # the next road is judged with this one back in place
