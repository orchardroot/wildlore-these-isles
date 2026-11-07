extends TestCase
## Creature motion styles (wave 48 A): the choice of style and the idle maths.

func test_override_wins() -> void:
	assert_eq(Motion.style_for({"id": "x", "types": ["stone"], "motion": "pulse"}), "pulse")

func test_word_then_type() -> void:
	assert_eq(Motion.style_for({"id": "sea_jelly", "types": ["tide"]}), "pulse")
	assert_eq(Motion.style_for({"id": "q", "types": ["stone"]}), "stomp")
	assert_eq(Motion.style_for({"id": "q", "types": []}), "bob")

func test_every_style_idles_and_lunges() -> void:
	for s in Motion.STYLES:
		var r := Motion.idle(s, 1.3)
		assert_true(r.pos is Vector2 and r.shadow >= 0.5 and r.shadow <= 1.0)
		assert_true(Motion.lunge_kind(s) in ["dash", "swoop", "strike", "charge", "leap"])

func test_every_species_gets_a_valid_style_and_spread() -> void:
	var counts := {}
	for f in DirAccess.get_files_at("res://data/creatures"):
		if not f.ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures/" + f))
		for sp in d.get("species", []):
			var m := Motion.style_for(sp)
			counts[m] = int(counts.get(m, 0)) + 1
			if sp.has("motion"):
				assert_true(sp.motion in Motion.STYLES, "bad motion on " + str(sp.id))
	print("motion spread: ", counts)
	for s in Motion.STYLES:
		assert_true(counts.get(s, 0) >= 5, "style %s too rare: %s" % [s, counts])

func test_piece_flourish_kinds() -> void:
	assert_eq(FXPieces.kind_for("skimming"), "skip")
	assert_eq(FXPieces.kind_for("never_heard_of_it"), "fanfare")
	assert_true(FXPieces.is_piece({"piece": "darts"}))
	assert_false(FXPieces.is_piece({"id": "shove"}))
