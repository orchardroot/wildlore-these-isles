extends TestCase
## Session C's Deeds: the two boats and the two allotments parse to the contract, name real zones and items, are
## reachable through a door, and their hauls can't beat the day's takings ceiling at the Ledger's price.

const IDS := ["boat_whitby", "boat_dingle", "allotment_york", "allotment_lancaster"]
const SEASONS := ["spring", "summer", "autumn", "winter"]

func _deed(id: String) -> Dictionary:
	return JsonUtil.read("res://data/deeds/%s.json" % id)

func _zone(id: String) -> Dictionary:
	var z = JsonUtil.read("res://data/zones/%s.json" % id)
	return z if z is Dictionary else {}

func test_deeds_follow_the_contract() -> void:
	var db := ItemDB.load_default()
	for id in IDS:
		var d := _deed(id)
		assert_eq(d.get("id"), id)
		assert_true(str(d.kind) in ["boat", "allotment"])
		assert_eq((d.cost as Array).size(), 3)
		assert_true(int(d.cost[0]) <= int(d.cost[1]) and int(d.cost[1]) <= int(d.cost[2]), id + " cost rises with badges")
		assert_true((d.tiers as Array).size() >= 3 and (d.tiers as Array).size() <= 4)
		assert_true((d.events as Array).size() >= 5, id + " has 5+ events")
		var storm := false
		for e in d.events:
			assert_true(float(e.chance) > 0.0 and float(e.chance) < 0.2 and str(e.line) != "")
			assert_false(str(e.line).contains("—"), "no em-dashes")
			if float(e.mult) == 0.0:
				storm = true
		assert_eq(storm, str(d.kind) == "boat", id + ": only a boat has a lose-the-day event")
		for inp in d.inputs:
			assert_false(db.get_item(str(inp.item)).is_empty(), "%s input %s is a real item" % [id, inp.item])
		assert_false(_zone(str(d.zone)).is_empty())
		assert_eq(str(_zone(str(d.interior)).get("kind")), "interior")

func test_each_deed_has_a_door_and_a_counter() -> void:
	for id in IDS:
		var d := _deed(id)
		var town := _zone(str(d.zone))
		var tile := str(town.rows[int(d.door.y)][int(d.door.x)])
		assert_eq(tile, "D", id + ": the door is a door tile")
		var warped := false
		for w in town.warps:
			if int(w.x) == int(d.door.x) and int(w.y) == int(d.door.y) and str(w.to) == str(d.interior):
				warped = true
		assert_true(warped, id + ": the town warps to the interior")
		var room := _zone(str(d.interior))
		assert_eq(str(room.warps[0].to), str(d.zone))
		var script := ""
		for n in room.npcs:
			if str(n.script).ends_with("skipper") or str(n.script).ends_with("plotholder"):
				script = str(n.script)
		var lines = JsonUtil.read("res://data/dialogue/%s.json" % d.interior).get(script, [])
		var has_cmd := false
		for c in lines:
			if str(c.get("do")) == "deed" and str(c.id) == id:
				has_cmd = true
		assert_true(has_cmd, id + ": the counter opens the Deed screen")

func test_yields_are_real_items_and_cover_every_season() -> void:
	var db := ItemDB.load_default()
	for id in IDS:
		var d := _deed(id)
		for s in SEASONS:
			assert_true((d.yield.get(s, []) as Array).size() >= 3, "%s has a %s yield" % [id, s])
			for line in d.yield[s]:
				var it := db.get_item(str(line.item))
				assert_false(it.is_empty(), "%s: %s exists" % [id, line.item])
				assert_eq(str(it.kind), "fish" if d.kind == "boat" else "produce")

func test_allotment_items_exist_and_seeds_are_cheaper_than_the_crop() -> void:
	var db := ItemDB.load_default()
	var produce := 0
	for id in db.ids():
		var it := db.get_item(id)
		if str(it.kind) == "produce":
			produce += 1
			assert_true(db.get_item(str(it.id)).price > 0)
	assert_true(produce >= 10, "a dozen real British veg")

func test_a_storm_loses_the_catch_and_hauls_are_deterministic() -> void:
	var d := _deed("boat_whitby")
	assert_true(DeedYield.haul(d, "summer", 100, true).is_empty())
	assert_eq(DeedYield.haul(d, "summer", 100), DeedYield.haul(d, "summer", 100))
	assert_false(DeedYield.haul(d, "summer", 100).is_empty())

func test_a_haul_never_beats_the_days_takings() -> void:
	var data := GameStateData.new()
	for id in IDS:
		var d := _deed(id)
		for s in SEASONS:
			for day in range(0, 200):
				var h := DeedYield.haul(d, s, day)
				var w := DeedYield.worth(data, h, str(d.zone))
				assert_true(w <= DeedYield.ceiling(d), "%s %s day %d: haul worth %d vs ceiling %d" % [id, s, day, w, DeedYield.ceiling(d)])

func test_each_hut_is_its_own_building() -> void:
	# w52: York's shed was a second door in the Minster's front, Lancaster's in the Castle, the boat huts in Whitby
	# Station and Dingle's Dolphin Gifts; each now has a little shed or hut of its own
	for id in IDS:
		var d := _deed(id)
		var town := ZoneData.from_dict(_zone(str(d.zone)))
		var b := town.building_at(Vector2i(int(d.door.x), int(d.door.y)))
		assert_eq(str(b.get("style", "")), "net_hut" if str(d.kind) == "boat" else "allotment_shed", id)
		var doors := 0
		for x in range(int(b.x), int(b.x) + int(b.w)):
			for y in range(int(b.y), int(b.y) + int(b.h)):
				doors += 1 if town.tile_at(Vector2i(x, y)) == "door" else 0
		assert_eq(doors, 1, id + ": one door, its own")
		var room := _zone(str(d.interior))
		assert_eq(Vector2i(int(room.warps[0].tx), int(room.warps[0].ty)), Vector2i(int(d.door.x), int(d.door.y) + 1), id + ": out on the step")
