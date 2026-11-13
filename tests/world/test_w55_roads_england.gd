extends TestCase
## Wave 55, roads-england: new roads in England and over the Welsh and Scottish borders are a choice of road, never a
## sequence break. tests/world/w55_england_golden.json records, for the unchanged game, the first story step at which
## every place can be walked to (see w55_reach.gd). With the new roads in, no old place may open earlier, and none
## later either: the story's own gates still hold. The rest checks each road is a proper place: joined both ways,
## wildlife, trainers, plaques, and the gate it carries where it joins places that open at different steps.

const Reach := preload("res://tests/world/w55_reach.gd")
const GOLDEN := "res://tests/world/w55_england_golden.json"
## zone id -> [existing zone, side on that zone, existing zone, side on that zone, gate flag or ""]. The gate flag is the
## story flag of the existing gate between the two ends; "" where both ends open at the same step.
const NEW_ZONES := {
	"pendle_hill": ["haworth", "west", "blackpool", "east", ""],
	"swaledale": ["lake_district", "east", "north_york_moors", "west", ""],
	"humber_bridge": ["hull", "south", "lincoln", "north", ""],
	"hadrians_wall_path": ["carlisle", "east", "hadrians_wall", "west", ""],
	"reivers_road": ["carlisle", "north", "scottish_borders", "south", ""],
}

func _golden() -> Dictionary:
	var d = JsonUtil.read(GOLDEN)
	return d if d is Dictionary else {}

func test_golden_is_there() -> void:
	var g := _golden()
	assert_true(g.has("first") and g.first.size() > 100, "the golden file lists the places the story walks to")
	assert_eq(g.states[0], "start")
	assert_eq(g.states[g.states.size() - 1], "game_complete")

func test_no_road_opens_a_place_early() -> void:
	var g := _golden()
	var zones := ZoneData.load_all()
	var now: Dictionary = Reach.first_steps(zones)
	assert_eq(now.states, g.states, "the story steps are as recorded")
	var early := []
	var late := []
	for zid in g.first:
		if not zones.has(zid):
			continue
		var was := int(g.first[zid])
		var is_now := int(now.first.get(zid, 99))
		if is_now < was:
			early.append("%s: step %d -> %d (%s -> %s)" % [zid, was, is_now, g.states[was], g.states[is_now]])
		elif is_now > was:
			late.append("%s: step %d -> %d" % [zid, was, is_now])
	assert_eq(early, [], "places the story reaches later are now walkable earlier")
	assert_eq(late, [], "places that used to be reachable at a step are now cut off")
	for zid in NEW_ZONES:
		assert_true(now.first.has(zid), zid + " can be walked to by the end of the story")

func test_each_road_joins_its_two_places_both_ways() -> void:
	var zones := ZoneData.load_all()
	for zid in NEW_ZONES:
		var spec: Array = NEW_ZONES[zid]
		var z: ZoneData = zones[zid]
		assert_eq(z.validate(zones), [], zid + " validates")
		assert_eq(z.kind, "route", zid)
		assert_eq(z.edges.size(), 2, zid + " has the two edges and no more")
		var ends := []
		for i in [0, 2]:
			var a: ZoneData = zones[spec[i]]
			var side: String = spec[i + 1]
			assert_eq(str(a.edges[side].to), zid, "%s %s leads on to %s" % [spec[i], side, zid])
			var back: String = ZoneData.OPPOSITE[side]
			assert_eq(str(z.edges[back].to), spec[i], "%s leads back to %s" % [zid, spec[i]])
			assert_eq(int(a.edges[side].offset), -int(z.edges[back].offset), "%s: the offsets mirror" % zid)
			ends.append(spec[i])
		assert_true(ends[0] != ends[1], zid + " joins two different places")

func test_each_road_is_a_place_worth_the_walk() -> void:
	var zones := ZoneData.load_all()
	var plaque_ids := {}
	for zid in NEW_ZONES:
		var z: ZoneData = zones[zid]
		assert_true(z.scaled_floor > 0, zid + " scales with the story")
		var n := 0
		for k in z.encounters:
			n += z.encounters[k].size()
		assert_true(n >= 6, "%s has %d encounter entries" % [zid, n])
		for k in z.encounters:
			for e in z.encounters[k]:
				assert_true(int(e.min) >= z.scaled_floor - 2 and int(e.max) <= z.scaled_floor + 6, "%s %s level %d-%d is near its floor %d" % [zid, e.species, int(e.min), int(e.max), z.scaled_floor])
		var plaques := 0
		for s in z.signs:
			if s.has("plaque"):
				plaques += 1
				assert_true(str(s.plaque).begins_with("w55e_"), str(s.plaque))
				assert_false(plaque_ids.has(s.plaque), "duplicate plaque " + str(s.plaque))
				plaque_ids[s.plaque] = true
				assert_false("—" in str(s.text) or "–" in str(s.text), "no dashes in " + str(s.plaque))
		assert_true(plaques >= 2, "%s has %d plaques" % [zid, plaques])
		assert_true(z.signs.size() >= plaques + 3, zid + " has plain signs too")
		var trainers := 0
		for npc in z.npcs:
			if npc.has("trainer"):
				trainers += 1
				var t = JsonUtil.read("res://data/trainers/%s.json" % npc.trainer)
				assert_true(t is Dictionary and int(t.get("scaled_floor", 0)) == z.scaled_floor, "%s: trainer %s is scaled" % [zid, npc.trainer])
				assert_false("—" in JSON.stringify(t), "no dashes in trainer " + str(npc.trainer))
		assert_true(trainers >= 4, "%s has %d trainers" % [zid, trainers])
		assert_true(Travel.world_map().places.has(zid), zid + " is on the world map")
		assert_true(Poi.for_zone(zid).size() >= 2, zid + " has something off the path")
		assert_true(FieldSpots.for_zone(zid).size() >= 1, zid + " has a field spot")

func test_gates_carry_the_existing_flag() -> void:
	var zones := ZoneData.load_all()
	for zid in NEW_ZONES:
		var flag: String = NEW_ZONES[zid][4]
		var gates := 0
		for npc in zones[zid].npcs:
			if npc.has("hide_if") and str(npc.get("script", "")).ends_with("_gate"):
				gates += 1
				assert_eq(str(npc.hide_if), flag, "%s: its gate opens on the same flag as the existing one" % zid)
		if flag == "":
			assert_eq(gates, 0, zid + " joins places that open together, so no gate")
		else:
			assert_true(gates >= 3, "%s has a wall of gate people (%d)" % [zid, gates])

func test_each_road_builds() -> void:
	Meshes.materials()
	for zid in NEW_ZONES:
		var root := ZoneBuilder.build(ZoneData.load_id(zid))
		assert_true(root != null, zid)
		root.free()
