extends TestCase
## 3.0 Wider Isles, region fife: the Forth bridges, St Andrews and Dundee hang off Edinburgh's north side.

const ZONES := ["forth_bridges", "st_andrews", "dundee"]
const LINES := ["divotling", "hellbunker", "jamlet", "marmalord", "taywraith"]

func _json(path: String) -> Variant:
	return JsonUtil.read(path)

func test_zones_join_edinburgh_as_a_cul_de_sac() -> void:
	var edi := ZoneData.load_id("edinburgh")
	assert_eq(edi.edges.north.to, "forth_bridges")
	assert_eq(edi.edges.west.to, "central_belt")
	var fb := ZoneData.load_id("forth_bridges")
	assert_eq(fb.edges.south.to, "edinburgh")
	assert_eq(fb.edges.north.to, "st_andrews")
	var sa := ZoneData.load_id("st_andrews")
	assert_eq(sa.edges.north.to, "dundee")
	var du := ZoneData.load_id("dundee")
	var du_sides: Array = du.edges.keys()
	du_sides.sort()
	# wave 55 added the Angus coast (east) and Rob Roy Way (west) beside the old St Andrews road
	assert_eq(du_sides, ["east", "south", "west"])
	assert_eq(du.edges.east.to, "angus_coast")
	assert_eq(du.edges.west.to, "rob_roy_way")

func test_scaled_from_edinburgh_band() -> void:
	for z in ZONES:
		assert_eq(ZoneData.load_id(z).scaled_floor, 69)
	for tid in StoryData.trainer_ids():
		if str(tid).begins_with("fb_") or str(tid).begins_with("sta_") or str(tid).begins_with("dun_"):
			assert_eq(int(StoryData.trainer(tid).get("scaled_floor", -1)), 69, tid)

func test_plaques_unique_and_enough() -> void:
	var counts := {}
	var seen := {}
	for z in ZONES:
		counts[z] = 0
		for s in ZoneData.load_id(z).signs:
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "duplicate plaque " + str(s.plaque))
				seen[s.plaque] = true
				assert_true(str(s.get("title", "")) != "")
				counts[z] += 1
	assert_true(counts.forth_bridges >= 3)
	assert_true(counts.st_andrews >= 8)
	assert_true(counts.dundee >= 8)

func _flags_set(cmds: Variant, out: Dictionary) -> void:
	if not cmds is Array:
		return
	for c in cmds:
		if not c is Dictionary:
			continue
		if c.get("do") == "set":
			out[str(c.flag)] = true
		if c.get("do") in ["legend", "gauntlet"] and c.has("flag"):
			out[str(c.flag)] = true
		for k in ["then", "else"]:
			_flags_set(c.get(k), out)

func test_every_quest_flag_is_set_somewhere() -> void:
	var set_flags := {}
	var dlg := StoryData.all_dialogue()
	for file in dlg:
		for sid in dlg[file]:
			_flags_set(dlg[file][sid], set_flags)
	var q: Dictionary = _json("res://data/quests/fife.json")
	assert_eq(q.quests.size(), 3)
	for quest in q.quests:
		var flags := [quest.start_flag, quest.done_flag]
		for st in quest.steps:
			flags.append(st.flag)
		for f in flags:
			assert_true(str(f).begins_with("q_fife_"), f)
			assert_true(set_flags.has(f), "nobody sets " + str(f))

func test_regional_creatures_appendix_sprites_placed() -> void:
	var order: Array = _json("res://data/dex_order.json")
	for id in LINES:
		assert_true(id in order, id)
		assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_front.png" % id), id)
		assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_back.png" % id), id)
	var placed := {}
	for z in ZONES:
		for kind in ZoneData.load_id(z).encounters:
			for e in ZoneData.load_id(z).encounters[kind]:
				placed[str(e.species)] = true
	for id in ["divotling", "hellbunker", "jamlet", "marmalord"]:
		assert_true(placed.has(id), id)
	# the Taywraith is a one-off: the poet's quest legend on the Dundee quay
	var spot := false
	for n in ZoneData.load_id("dundee").npcs:
		spot = spot or str(n.get("sprite", "")) == "creature:taywraith"
	assert_true(spot)
	for f in ["divotling", "jamlet", "taywraith"]:
		var d: Dictionary = _json("res://data/creatures/%s.json" % f)
		for sp in d.species:
			assert_true(bool(sp.get("appendix", false)), sp.id)

func test_regional_items_in_shops_and_charm_works() -> void:
	var shop: Dictionary = _json("res://data/shops/dundee_corner_shop.json")
	for id in ["dundee_cake", "dundee_marmalade", "forfar_bridie"]:
		assert_true(id in shop.stock, id)
	assert_true(Charms.is_charm("featherie"))
	assert_true(Charms.is_charm("hag_stone"))
