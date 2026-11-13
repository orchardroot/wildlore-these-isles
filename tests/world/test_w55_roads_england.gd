extends TestCase
## Wave 55, roads-england: new roads in England and over the Welsh and Scottish borders are a choice of road, never a
## sequence break. tests/world/w55_england_golden.json records, for the unchanged game, the first story step at which
## every place can be walked to (see w55_reach.gd). With the new roads in, no old place may open earlier, and none
## later either: the story's own gates still hold.

const Reach := preload("res://tests/world/w55_reach.gd")
const GOLDEN := "res://tests/world/w55_england_golden.json"
## The new zones this session adds (filled in as each road is built).
const NEW_ZONES := []

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

func test_every_new_zone_can_be_reached() -> void:
	var zones := ZoneData.load_all()
	var now: Dictionary = Reach.first_steps(zones)
	for zid in NEW_ZONES:
		assert_true(zones.has(zid), zid + " exists")
		assert_true(now.first.has(zid), zid + " can be walked to by the end of the story")
