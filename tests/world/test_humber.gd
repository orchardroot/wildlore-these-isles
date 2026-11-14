extends TestCase
## Region "humber" (3.0 Wider Isles): York -> Yorkshire Wolds -> Hull, and Nottingham -> Lincoln. Cul-de-sacs, scaled to
## the band of the town they hang off, with quests, plaques and five regional creature lines.

const ZONES := {"yorkshire_wolds": 84, "hull": 84, "lincoln": 88}
const SPECIES := ["lincolnimp", "treadlet", "landship", "borelet", "aegir", "roodstone", "glimmerjaw"]
const STYLES := ["humber_bridge", "the_deep", "lincoln_cathedral", "tank_memorial", "monolith", "limestone_church",
	"pantile_brick", "pantile_chalk", "georgian_brick", "limestone_house", "trawler", "spire_memorial"]

func _zone(id: String) -> Dictionary:
	return JsonUtil.read("res://data/zones/%s.json" % id)

func test_zones_are_scaled_to_their_anchor_band() -> void:
	for id in ZONES:
		var z := _zone(id)
		assert_eq(int(z.get("scaled_floor", -1)), ZONES[id], id)

func test_edges_are_mirrored_cul_de_sacs() -> void:
	var pairs := [["york", "east", "yorkshire_wolds", "west"], ["yorkshire_wolds", "south", "hull", "north"],
		["nottingham", "east", "lincoln", "west"]]
	for p in pairs:
		var a := _zone(p[0])
		var b := _zone(p[2])
		assert_eq(str(a.edges[p[1]].to), p[2], "%s %s" % [p[0], p[1]])
		assert_eq(str(b.edges[p[3]].to), p[0], "%s %s" % [p[2], p[3]])
		assert_eq(int(a.edges[p[1]].get("offset", 0)), -int(b.edges[p[3]].get("offset", 0)), "offsets mirror")
	assert_eq(_zone("hull").edges.size(), 2, "Hull is a dead end bar the wave 55 Humber Bridge")
	assert_eq(str(_zone("hull").edges.south.to), "humber_bridge")
	assert_eq(_zone("lincoln").edges.size(), 2, "Lincoln is a dead end bar the wave 55 Humber Bridge")
	assert_eq(str(_zone("lincoln").edges.north.to), "humber_bridge")

func test_trainers_are_scaled() -> void:
	var n := 0
	for f in DirAccess.get_files_at("res://data/trainers"):
		if f.begins_with("wld_") or f.begins_with("hul_") or f.begins_with("lin_"):
			var t: Dictionary = JsonUtil.read("res://data/trainers/" + f)
			assert_true(t.has("scaled_floor"), f)
			n += 1
	assert_true(n >= 12, "plenty of trainers (%d)" % n)

func test_plaques_unique_and_plentiful() -> void:
	var seen := {}
	for id in ZONES:
		var count := 0
		for s in _zone(id).signs:
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "unique plaque " + str(s.plaque))
				seen[s.plaque] = true
				assert_true(str(s.get("title", "")) != "", "titled")
				assert_false(str(s.text).contains("—"), "no em-dashes")
				count += 1
		assert_true(count >= (3 if id == "yorkshire_wolds" else 8), "%s has %d plaques" % [id, count])

func _dialogue_text() -> String:
	var out := ""
	for f in DirAccess.get_files_at("res://data/dialogue"):
		if f.begins_with("hull") or f.begins_with("lincoln") or f.begins_with("wolds") or f.begins_with("yorkshire_wolds"):
			out += JSON.stringify(JsonUtil.read("res://data/dialogue/" + f))
	return out

func test_every_quest_flag_is_set_somewhere() -> void:
	var text := _dialogue_text()
	var quests: Array = JsonUtil.read("res://data/quests/humber.json").quests
	assert_eq(quests.size(), 4)
	for q in quests:
		var flags := [q.start_flag, q.done_flag]
		for s in q.steps:
			flags.append(s.flag)
		for f in flags:
			assert_true(text.contains("\"flag\":\"%s\"" % f), "%s is set by a script" % f)
			assert_true(str(f).begins_with("q_humber_"), "namespaced " + str(f))

func test_new_species_are_appendix_with_sprites_and_a_home() -> void:
	var order: Array = JsonUtil.read("res://data/dex_order.json")
	var text := _dialogue_text()
	var enc := ""
	for id in ZONES:
		enc += JSON.stringify(_zone(id).encounters)
	for f in ["lincolnimp", "treadlet", "borelet", "roodstone", "glimmerjaw"]:
		for sp in JsonUtil.read("res://data/creatures/%s.json" % f).species:
			assert_true(bool(sp.get("appendix", false)), sp.id + " is appendix")
			assert_true(sp.id in order, sp.id + " in dex order")
			for k in ["front", "back", "icon"]:
				assert_true(ResourceLoader.exists("res://art/sprites/creatures/%s_%s.png" % [sp.id, k]), "%s %s sprite" % [sp.id, k])
	for id in SPECIES:
		var placed := enc.contains("\"%s\"" % id) or text.contains("\"species\":\"%s\"" % id)
		if id == "landship":
			placed = true  # evolves from the Treadlet the museum gives you
		assert_true(placed, id + " can be met")

func test_new_building_styles_build() -> void:
	for s in STYLES:
		assert_true(s in Landmarks.SPECIAL, s)
		var m: Array = Meshes.building(4, 4, s, 1, 7, "yorkshire")
		assert_true((m[0] as ArrayMesh).get_surface_count() > 0, s + " has a body")

func test_hull_phone_boxes_are_cream() -> void:
	var n := 0
	for p in _zone("hull").props:
		if p.type == "phone_box":
			assert_eq(int(p.get("variant", 0)), 1, "cream")
			n += 1
	assert_true(n >= 5)
	assert_true(Meshes.phone_box(1).get_surface_count() > 0)
