extends TestCase
## The bowls and skimming NPCs and plaques are where the venues say, on free walkable tiles, and their dialogue runs
## the right command for the right venue.

const PLACES := {
	"blackpool_bowler": ["blackpool", "bowls", "waterloo"],
	"stoke_bowler": ["stoke", "bowls", "potteries"],
	"sheffield_bowler": ["sheffield", "bowls", "yorkshire"],
	"macc_bowler": ["macclesfield", "bowls", "cheshire"],
	"oban_skimmer": ["oban", "skim", "easdale"],
	"llan_skimmer": ["llanberis", "skim", "padarn"],
}

func _zone(id: String) -> Dictionary:
	return JsonUtil.read("res://data/zones/%s.json" % id)

func test_npcs_stand_on_free_walkable_tiles() -> void:
	for npc_id in PLACES:
		var z := _zone(PLACES[npc_id][0])
		var n := {}
		for c in z.npcs:
			if c.id == npc_id:
				n = c
		assert_false(n.is_empty(), "%s exists" % npc_id)
		var ch: String = str(z.rows[int(n.y)])[int(n.x)]
		assert_true(ZoneData.LEGEND.get(ch, ["", false])[1], "%s stands on a walkable tile (%s)" % [npc_id, ch])
		for c in z.npcs:
			if c.id != npc_id:
				assert_false(int(c.x) == int(n.x) and int(c.y) == int(n.y), "%s shares a tile with %s" % [npc_id, c.id])
		for s in z.signs:
			assert_false(int(s.x) == int(n.x) and int(s.y) == int(n.y), "%s on a sign" % npc_id)
		for w in z.warps:
			assert_false(int(w.x) == int(n.x) and int(w.y) == int(n.y), "%s on a warp" % npc_id)
		for p in z.props:
			if not p.get("walk", false):
				assert_false(int(p.x) == int(n.x) and int(p.y) == int(n.y), "%s inside a prop" % npc_id)

func test_dialogue_starts_the_right_game() -> void:
	for npc_id in PLACES:
		var info: Array = PLACES[npc_id]
		var d = JsonUtil.read("res://data/dialogue/%s.json" % info[0])
		assert_true(d.has(npc_id), "%s has a script" % npc_id)
		var found := false
		for step in d[npc_id]:
			if str(step.get("do", "")) == info[1]:
				found = true
				assert_eq(step.venue, info[2])
			if step.has("text"):
				assert_false("—" in str(step.text), "no em-dashes")
		assert_true(found, "%s runs %s" % [npc_id, info[1]])

func test_each_game_has_a_true_plaque() -> void:
	var list := Gazetteer.build([_zone("blackpool"), _zone("oban")], {})
	var ids := []
	for p in list:
		ids.append(p.id)
	assert_has(ids, "lancashire_crown_green_bowls")
	assert_has(ids, "skimming_easdale")
	for p in list:
		if p.id in ["lancashire_crown_green_bowls", "skimming_easdale"]:
			assert_true(str(p.title) != "" and str(p.text).length() > 80)
			assert_false("—" in str(p.text))
