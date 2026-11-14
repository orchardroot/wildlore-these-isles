extends TestCase
## 3.0 Wider Isles, region R3: the Lancashire coast off Liverpool's north side. Sefton Coast (Crosby, Formby,
## Southport, Martin Mere) and Blackpool, a cul-de-sac scaled from par 18, its quests run end to end on the
## fake host, its plaques, items, shop and world map entries.

const ZONES := ["sefton_coast", "blackpool"]
const FLOOR := 18
const MINE_PREFIXES := ["sef_", "bp_"]
const DIALOGUE := ["sefton_coast", "blackpool", "blackpool_ballroom", "blackpool_wintergardens", "blackpool_rockfactory",
	"blackpool_depot", "blackpool_chippy", "blackpool_pub", "crosby_coastguard", "southport_tearooms", "southport_atkinson",
	"martin_mere_hide"]

func _run(h: FakeStoryHost, zone: String, script: String) -> void:
	StoryData.clear_cache()
	h.zone = zone
	await Commands.new(h, script).run(StoryData.script(zone, script))

func _bag(h: FakeStoryHost, item: String) -> int:
	return Bag.new(h.data.bag).count(item)

func _my_trainers() -> Array:
	var out := []
	for path in JsonUtil.list_json("res://data/trainers"):
		var id: String = str(path).get_file().get_basename()
		for p in MINE_PREFIXES:
			if id.begins_with(p):
				out.append(id)
	return out

# ---------------------------------------------------------------- the map

func test_zones_load_scaled_from_liverpools_band() -> void:
	for id in ZONES:
		var z := ZoneData.load_id(id)
		assert_eq(z.scaled_floor, FLOOR, id)
		assert_true(z.parse_errors.is_empty(), id)
	assert_eq(ZoneData.load_id("blackpool").kind, "town")
	assert_eq(ZoneData.load_id("sefton_coast").kind, "route")
	assert_eq(ZoneData.load_id("blackpool").region, "lancashire")
	assert_eq(ZoneData.load_id("sefton_coast").region, "merseyside")

func test_joined_at_liverpool_north_only_a_cul_de_sac() -> void:
	var liv := ZoneData.load_id("liverpool")
	assert_eq(str(liv.edges.north.to), "sefton_coast")
	assert_eq(str(liv.edges.east.to), "chat_moss", "the old edges stay")
	assert_eq(str(liv.edges.south.to), "wirral_way")
	var sef := ZoneData.load_id("sefton_coast")
	assert_eq(sef.edges.keys().size(), 2)
	assert_eq(str(sef.edges.south.to), "liverpool")
	assert_eq(str(sef.edges.north.to), "blackpool")
	var bp := ZoneData.load_id("blackpool")
	assert_eq(bp.edges.keys(), ["south", "east"], "Blackpool is the end of the line, bar the wave 55 road over Pendle Hill")
	assert_eq(str(bp.edges.south.to), "sefton_coast")
	assert_eq(str(bp.edges.east.to), "pendle_hill")
	assert_eq(liv.spawn, Vector2i(27, 24), "Liverpool's spawn is unchanged")

func test_every_trainer_here_is_scaled() -> void:
	var ids := _my_trainers()
	assert_true(ids.size() >= 6, "at least six trainers, got %d" % ids.size())
	var legend_party := 0
	for id in ids:
		var t: Dictionary = JsonUtil.read("res://data/trainers/%s.json" % id)
		assert_eq(int(t.get("scaled_floor", -1)), FLOOR, id)
		legend_party = maxi(legend_party, t.party.size())
	assert_eq(legend_party, 6, "a local legend with a full party")
	assert_true(bool(JsonUtil.read("res://data/trainers/bp_twinkletoes.json").get("double", false)), "the dance contest is a double")

func test_blackpool_has_the_sights_and_a_station() -> void:
	var bp := ZoneData.load_id("blackpool")
	var styles := {}
	for p in bp.props:
		if p.get("type") == "building":
			styles[str(p.style)] = true
	for s in ["blackpool_tower", "big_one", "blackpool_tram", "pier_pavilion", "guest_house"]:
		assert_true(styles.has(s), s)
		assert_true(s in Landmarks.SPECIAL, s + " is drawn by Landmarks")
	assert_true(bp.station != Vector2i(-1, -1))
	var interiors := 0
	for w in bp.warps:
		interiors += 1
	assert_true(interiors >= 8, "Sanctuary, shop and six or more places to go in")
	assert_true(Travel.world_map().towns.has("blackpool"))
	assert_true(Travel.world_map().places.has("sefton_coast"))

func test_new_meshes_build() -> void:
	for s in ["blackpool_tower", "big_one", "blackpool_tram", "pier_pavilion", "veranda_shop", "guest_house"]:
		var m: Array = Landmarks.building(6, 4, s, 2, 7)
		assert_true(m[0] is ArrayMesh and (m[0] as ArrayMesh).get_surface_count() > 0, s)
	assert_true(Landmarks.statue(Landmarks.IRON_MAN).get_surface_count() > 0, "the iron men")

func test_plaques_unique_and_plentiful() -> void:
	var seen := {}
	for path in JsonUtil.list_json("res://data/zones"):
		var d: Dictionary = JsonUtil.read(path)
		for s in d.get("signs", []):
			if s.has("plaque"):
				assert_false(seen.has(str(s.plaque)), "plaque id %s is unique" % s.plaque)
				seen[str(s.plaque)] = d.id
	var count := {"blackpool": 0, "sefton_coast": 0}
	for pid in seen:
		if count.has(seen[pid]):
			assert_true(str(pid).begins_with("lancashire_"), pid)
			count[seen[pid]] += 1
	assert_true(count.blackpool >= 8, "Blackpool plaques: %d" % count.blackpool)
	assert_true(count.sefton_coast >= 3, "Sefton plaques: %d" % count.sefton_coast)

func test_regional_items_in_the_shops() -> void:
	var items := ItemDB.load_default()
	for id in ["blackpool_rock", "chippy_tea", "potted_shrimps", "kiss_me_quick_hat", "illuminations_bulb"]:
		assert_false(items.get_item(id).is_empty(), id)
	var stock: Array = JsonUtil.read("res://data/shops/blackpool_corner_shop.json").stock
	for id in ["blackpool_rock", "chippy_tea", "kiss_me_quick_hat"]:
		assert_has(stock, id)
	assert_has(JsonUtil.read("res://data/shops/southport_tearooms.json").stock, "potted_shrimps")

# ---------------------------------------------------------------- quests

func test_every_quest_flag_is_set_by_our_scripts() -> void:
	var text := ""
	for z in DIALOGUE:
		text += FileAccess.get_file_as_string("res://data/dialogue/%s.json" % z)
	var q: Dictionary = JsonUtil.read("res://data/quests/lancashire.json")
	assert_true(q.quests.size() >= 2 and q.quests.size() <= 5)
	for quest in q.quests:
		var flags := [str(quest.start_flag), str(quest.done_flag)]
		for st in quest.steps:
			flags.append(str(st.flag))
			assert_true(FileAccess.file_exists("res://data/zones/%s.json" % st.zone), st.zone)
		for f in flags:
			assert_true(f.begins_with("q_lancashire_"), f)
			assert_true(text.contains("\"%s\"" % f), "%s is set somewhere" % f)

func test_switch_on_night_end_to_end() -> void:
	var h := FakeStoryHost.new()
	h.data.clock_minutes = 12 * 60
	await _run(h, "blackpool_depot", "depot_doreen")
	assert_eq(h.data.flag("q_lancashire_lights_started"), true)
	await _run(h, "blackpool", "bp_alf")
	assert_eq(h.data.flag("q_lancashire_lights_1"), true, "beat Alf for the fuses")
	await _run(h, "sefton_coast", "sef_pier_keeper")
	assert_eq(h.data.flag("q_lancashire_lights_2"), true, "bulbs from Southport Pier")
	h.choices = [1, 1, 1]  # a wrong answer first: no stand-in
	await _run(h, "blackpool_wintergardens", "wg_norman")
	assert_false(h.data.flag("q_lancashire_lights_3") == true)
	h.choices = [0, 1, 1]
	await _run(h, "blackpool_wintergardens", "wg_norman")
	assert_eq(h.data.flag("q_lancashire_lights_3"), true, "three right: the stand-in")
	await _run(h, "blackpool", "bp_compere")
	assert_false(h.data.flag("q_lancashire_lights_done") == true, "not in daylight")
	h.data.clock_minutes = 22 * 60
	await _run(h, "blackpool", "bp_compere")
	assert_eq(h.data.flag("q_lancashire_lights_done"), true)
	assert_eq(_bag(h, "illuminations_bulb"), 1)
	assert_eq(_bag(h, "blackpool_rock"), 5)

func test_ballroom_contest_is_a_double_after_a_tune() -> void:
	var h := FakeStoryHost.new()
	await _run(h, "blackpool_ballroom", "ball_mc")
	assert_eq(h.data.flag("q_lancashire_ballroom_started"), true)
	await _run(h, "blackpool_ballroom", "ball_mc")
	assert_false(h.data.flag("q_lancashire_ballroom_done") == true, "no music yet")
	await _run(h, "blackpool_ballroom", "ball_organist")
	await _run(h, "blackpool_ballroom", "ball_mc")
	assert_eq(h.data.flag("q_lancashire_ballroom_done"), true)
	assert_true(bool(h.last_battle.opts.get("double", false)), "two by two")

func test_brambles_day_out() -> void:
	var h := FakeStoryHost.new()
	await _run(h, "blackpool", "bp_donkey_jack")
	await _run(h, "blackpool", "bp_icecream")
	assert_eq(h.data.flag("q_lancashire_donkey_1"), true)
	await _run(h, "sefton_coast", "sef_donkey")
	await _run(h, "blackpool", "bp_donkey_jack")
	assert_eq(h.data.flag("q_lancashire_donkey_done"), true)
	assert_eq(_bag(h, "horseshoe"), 1)

func test_squirrel_survey_needs_four_reds_and_a_caught_natterjack() -> void:
	var h := FakeStoryHost.new()
	await _run(h, "sefton_coast", "sef_ranger")
	for k in ["a", "b", "c"]:
		await _run(h, "sefton_coast", "sef_squirrel_" + k)
	assert_false(h.data.flag("q_lancashire_squirrels_1") == true, "three is not four")
	await _run(h, "sefton_coast", "sef_squirrel_d")
	assert_eq(h.data.flag("q_lancashire_squirrels_1"), true)
	h.choices = [0]
	h.battle_results = [{"result": "win"}]  # knocked out, not caught
	await _run(h, "sefton_coast", "sef_natterjack")
	assert_false(h.data.flag("q_lancashire_squirrels_2") == true)
	h.choices = [0]
	h.battle_results = [{"result": "caught"}]
	await _run(h, "sefton_coast", "sef_natterjack")
	assert_eq(h.data.flag("q_lancashire_squirrels_2"), true)
	await _run(h, "sefton_coast", "sef_ranger")
	assert_eq(h.data.flag("q_lancashire_squirrels_done"), true)
	assert_eq(_bag(h, "oak_acorn"), 1)

func test_rock_factory_job() -> void:
	var h := FakeStoryHost.new()
	await _run(h, "blackpool_rockfactory", "rock_boss")
	await _run(h, "blackpool_rockfactory", "rock_apprentice")
	await _run(h, "blackpool_rockfactory", "rock_boss")
	assert_eq(h.data.flag("q_lancashire_rock_done"), true)
	assert_eq(_bag(h, "blackpool_rock"), 6)
