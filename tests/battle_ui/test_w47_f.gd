extends TestCase

func _all_moves() -> Array:
	var out := []
	for f in DirAccess.get_files_at("res://data/moves"):
		if f.ends_with(".json"):
			out.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/" + f)))
	return out

func test_every_move_has_a_valid_shape() -> void:
	var seen := {}
	for m in _all_moves():
		var sh := str(m.get("fx", {}).get("shape", ""))
		assert_true(sh in BattleFX.SHAPES, "%s has shape %s" % [m.id, sh])
		seen[sh] = true
		var c := str(m.fx.get("colour", "#"))
		assert_true(c == "#" or Color.html_is_valid(c), "%s colour" % m.id)
	assert_eq(seen.size(), 14, "all 14 shapes are used")

func test_every_type_has_a_palette() -> void:
	for t in Fixtures.chart().types:
		assert_true(BattleFX.PALETTE.has(t), "palette for %s" % t)
		var p: Array = BattleFX.PALETTE[t]
		assert_eq(p.size(), 3)
		assert_true(int(p[2]) >= 0 and int(p[2]) < BattleFX.TEX_N)
	assert_eq(BattleFX.PALETTE.size(), 16)

func test_signatures_map_to_real_moves_one_per_type() -> void:
	var by_id := {}
	for m in _all_moves():
		by_id[m.id] = m
	var types := {}
	var sigs := FXSignatures.new()
	for id in FXSignatures.SEQ:
		assert_true(by_id.has(id), "%s is a move" % id)
		assert_true(sigs.has_method(FXSignatures.SEQ[id]), "%s has a method" % id)
		types[by_id[id].type] = true
	assert_eq(FXSignatures.SEQ.size(), 16)
	assert_eq(types.size(), 16, "one signature per type")

func test_shape_for_falls_back_and_palette_overrides() -> void:
	assert_eq(BattleFX.shape_for({}), "pounce")
	assert_eq(BattleFX.shape_for({"category": "special", "type": "hearth"}), "bolt")
	assert_eq(BattleFX.shape_for({"fx": {"shape": "rain"}}), "rain")
	assert_eq(BattleFX.palette_for("hearth", {"fx": {"shape": "bolt", "colour": "#00ff00"}})[0], Color("00ff00"))
