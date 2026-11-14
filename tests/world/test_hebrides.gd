extends TestCase
## 3.0 Wider Isles, region hebrides: Harris and Lewis over the Minch from Skye (a ferry from Portree), and Stornoway.

const ZONES := ["harris", "stornoway"]
const LINES := ["skaldling", "skaldwake", "shieldbiter"]
const PIECES := ["king", "queen", "bishop", "knight", "warder"]

func _json(path: String) -> Variant:
	return JsonUtil.read(path)

func _species_ids() -> Dictionary:
	var ids := {}
	for f in DirAccess.get_files_at("res://data/creatures"):
		if f.ends_with(".json"):
			var d: Dictionary = _json("res://data/creatures/" + f)
			for sp in d.species:
				ids[str(sp.id)] = true
	return ids

func test_ferry_from_portree_and_a_road_to_stornoway() -> void:
	var r: Dictionary = Travel.ferries().portree_tarbert
	assert_eq(r.a, "portree")
	assert_eq(r.b, "harris")
	var portree := ZoneData.load_id("portree")
	var harris := ZoneData.load_id("harris")
	assert_eq(portree.ferry.route, "portree_tarbert")
	assert_eq(harris.ferry.route, "portree_tarbert")
	assert_true(portree.walkable(Vector2i(int(portree.ferry.x), int(portree.ferry.y))))
	assert_true(harris.walkable(Vector2i(int(harris.ferry.x), int(harris.ferry.y))))
	assert_eq(Travel.ferry_arrival("portree_tarbert", "portree").zone, "harris")
	assert_eq(Travel.ferry_arrival("portree_tarbert", "harris").zone, "portree")
	var harris_sides: Array = harris.edges.keys()
	harris_sides.sort()
	assert_eq(harris_sides, ["east", "north"], "wave 55 added the Uig road east")
	assert_eq(harris.edges.east.to, "uig_road")
	assert_eq(harris.edges.north.to, "stornoway")
	var sw := ZoneData.load_id("stornoway")
	var sw_sides: Array = sw.edges.keys()
	sw_sides.sort()
	assert_eq(sw_sides, ["south", "west"], "wave 55 added the Uig road west")
	assert_eq(sw.edges.west.to, "uig_road")
	assert_eq(sw.edges.south.to, "harris")
	assert_eq(sw.town_id, "stornoway")
	# Skye itself is untouched apart from a few Skaldlings in its water
	assert_eq(ZoneData.load_id("skye").edges.keys().size(), 3, "Portree, Inverness and (wave 55) Trotternish")
	assert_eq(ZoneData.load_id("skye").edges.south.to, "trotternish")

func test_scaled_from_skyes_band() -> void:
	for z in ZONES:
		assert_eq(ZoneData.load_id(z).scaled_floor, 74)
	var n := 0
	for tid in StoryData.trainer_ids():
		if str(tid).begins_with("harris_") or str(tid).begins_with("stornoway_") or str(tid) in ["hebrides_chessmaster", "blue_men"]:
			assert_eq(int(StoryData.trainer(tid).get("scaled_floor", -1)), 74, tid)
			n += 1
	assert_true(n >= 12, "trainers: %d" % n)

func test_every_species_used_exists() -> void:
	var ids := _species_ids()
	for tid in StoryData.trainer_ids():
		if str(tid).begins_with("harris_") or str(tid).begins_with("stornoway_") or str(tid) in ["hebrides_chessmaster", "blue_men"]:
			for m in StoryData.trainer(tid).party:
				assert_true(ids.has(str(m.species)), "%s: %s" % [tid, m.species])
	for z in ZONES:
		for kind in ZoneData.load_id(z).encounters:
			for e in ZoneData.load_id(z).encounters[kind]:
				assert_true(ids.has(str(e.species)), "%s: %s" % [z, e.species])

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
	assert_true(counts.harris >= 3)
	assert_true(counts.stornoway >= 8)

func _flags_set(cmds: Variant, out: Dictionary) -> void:
	if not cmds is Array:
		return
	for c in cmds:
		if not c is Dictionary:
			continue
		if c.get("do") == "set":
			out[str(c.flag)] = true
		for k in ["then", "else"]:
			_flags_set(c.get(k), out)

func test_every_quest_flag_is_set_somewhere() -> void:
	var set_flags := {}
	var dlg := StoryData.all_dialogue()
	for file in dlg:
		for sid in dlg[file]:
			_flags_set(dlg[file][sid], set_flags)
	var q: Dictionary = _json("res://data/quests/hebrides.json")
	assert_eq(q.quests.size(), 3)
	for quest in q.quests:
		var flags := [quest.start_flag, quest.done_flag]
		for st in quest.steps:
			flags.append(st.flag)
		for f in flags:
			assert_true(str(f).begins_with("q_hebrides_"), f)
			assert_true(set_flags.has(f), "nobody sets " + str(f))

func test_chessmen_are_in_the_landscape_only_while_the_quest_runs() -> void:
	var found := {}
	for n in ZoneData.load_id("harris").npcs:
		if str(n.get("sprite", "")) == "creature:shieldbiter":
			assert_eq(n.show_if, "q_hebrides_chess_started")
			found[str(n.hide_if)] = true
	var item_ids := {}
	for it in _json("res://data/items/hebrides.json"):
		item_ids[str(it.id)] = true
	for p in PIECES:
		assert_true(found.has("hebrides_cm_" + p), p)
		assert_true(item_ids.has("lewis_" + p), p)

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
	for id in LINES:
		assert_true(placed.has(id), id)
	for f in ["skaldling", "shieldbiter"]:
		var d: Dictionary = _json("res://data/creatures/%s.json" % f)
		for sp in d.species:
			assert_true(bool(sp.get("appendix", false)), sp.id)
			assert_true(str(sp.dex.fact).length() > 40)

func test_regional_items_in_shop_and_charms_work() -> void:
	var shop: Dictionary = _json("res://data/shops/stornoway_corner_shop.json")
	for id in ["stornoway_black_pudding", "bere_bannock"]:
		assert_true(id in shop.stock, id)
	for id in ["harris_tweed_cap", "ivory_warder", "blue_man_pebble"]:
		assert_true(Charms.is_charm(id), id)
