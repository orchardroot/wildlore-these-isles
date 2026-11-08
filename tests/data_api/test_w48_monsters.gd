extends TestCase
## Wave 48 M: fourteen new lines (30 species) with silhouettes the dex did not have: a snail with a house on its
## back, a moon jelly, a hagfish that is mostly knot, a peacock-butterfly moth, a teapot golem, a bramble swarm, a
## boggart in the dresser, a post mill, a fen raft spider, a scarecrow, a sunfish, a goose barnacle, a crane fly in
## three stages and a dandelion in three.

const LINES := {
	"whorlet": ["whorlet", "shellhaven"], "moonbell": ["moonbell", "aurelian"], "slipknot": ["slipknot", "gordian"],
	"gawplet": ["gawplet", "argusine"], "brewlet": ["brewlet", "brownbetty"], "brammel": ["brammel", "bramblemaw"],
	"dishwight": ["dishwight", "dresserwight"], "sailet": ["sailet", "postmill"], "raftlet": ["raftlet", "rafterweb"],
	"tattybogle": ["tattybogle", "mawkin"], "dishfin": ["dishfin", "moladisc"], "barnaclet": ["barnaclet", "barnagoose"],
	"leatherjack": ["leatherjack", "husk", "longlegs"], "clocklet": ["clocklet", "dandylion", "clockmaster"]}

var dex := Dex.load_default()

func _ids() -> Array:
	var out := []
	for l in LINES:
		out.append_array(LINES[l])
	return out

func _bst(id: String) -> int:
	var t := 0
	for s in Rules.STATS:
		t += int(dex.get_species(id).base[s])
	return t

func test_thirty_species_in_fourteen_lines() -> void:
	assert_eq(LINES.size(), 14)
	assert_eq(_ids().size(), 30)
	for id in _ids():
		assert_true(dex.has(id), id)
		assert_true(Dex.in_appendix(id), "%s is an appendix species" % id)
		var sp := dex.get_species(id)
		assert_true(str(sp.dex.text) != "" and str(sp.dex.fact) != "" and str(sp.get("real", "")) != "", "%s has its words" % id)
		for k in ["text", "fact"]:
			assert_false("—" in str(sp.dex[k]) or "–" in str(sp.dex[k]), "%s: no dashes in %s" % [id, k])
		assert_false("—" in str(sp.real), "%s real" % id)

func test_evolution_chains_run_in_order() -> void:
	for l in LINES:
		var chain: Array = LINES[l]
		for i in chain.size() - 1:
			assert_eq(str(dex.get_species(chain[i]).evolves.to), chain[i + 1], chain[i])
		assert_eq(dex.get_species(chain[chain.size() - 1]).evolves, null, chain[chain.size() - 1])

func test_stat_totals_sit_with_their_stage_neighbours() -> void:
	for l in LINES:
		var chain: Array = LINES[l]
		assert_true(_bst(chain[0]) >= 295 and _bst(chain[0]) <= 330, "%s basic: %d" % [chain[0], _bst(chain[0])])
		var last: String = chain[chain.size() - 1]
		if chain.size() == 2:
			assert_true(_bst(last) >= 470 and _bst(last) <= 500, "%s: %d" % [last, _bst(last)])
		else:
			assert_true(_bst(chain[1]) > _bst(chain[0]) and _bst(last) > _bst(chain[1]), l)
			assert_true(_bst(last) <= 540, "%s: %d" % [last, _bst(last)])

func test_moves_exist_and_knacks_are_set() -> void:
	var moves := MoveDB.load_default()
	for id in _ids():
		var sp := dex.get_species(id)
		assert_true(sp.learnset.size() >= 5, "%s has a learnset" % id)
		for entry in sp.learnset:
			assert_true(moves.has(str(entry[1])), "%s learns unknown move %s" % [id, entry[1]])
		assert_true(Knacks.id_for_species(sp) != "", "%s has a knack" % id)

func test_sprites_and_recipes_exist() -> void:
	for id in _ids():
		for part in ["front", "back", "icon"]:
			var p := "res://art/sprites/creatures/%s_%s.png" % [id, part]
			assert_true(FileAccess.file_exists(p) or ResourceLoader.exists(p), p)
		assert_true(FileAccess.file_exists("res://art/recipes/creatures/%s.json" % id), "recipe for " + id)

func test_habitats_are_exactly_the_zones_that_roll_them() -> void:
	var where := {}
	for path in JsonUtil.list_json("res://data/zones"):
		var z = JsonUtil.read(path)
		if not z is Dictionary or not z.get("encounters") is Dictionary:
			continue
		for table in z.encounters:
			for e in z.encounters[table]:
				var sid := str(e.get("species", ""))
				if sid in _ids():
					where[sid] = where.get(sid, []) + [str(z.id)]
	for l in LINES:
		var first: String = LINES[l][0]
		var hab: Array = dex.get_species(first).habitat.duplicate()
		var got: Array = where.get(first, []).duplicate()
		hab.sort()
		got.sort()
		assert_true(got.size() >= 2, "%s is met in a few places: %s" % [first, got])
		assert_eq(hab, got, "%s: its Fieldbook habitat is where it is met" % first)
		for later in LINES[l].slice(1):
			assert_false(where.has(later), "%s is only reached by evolving" % later)

func test_each_line_has_its_own_look() -> void:
	# a quick guard against a clone: no two lines share the same type pair and the same palette of knack
	var seen := {}
	for l in LINES:
		var key := "%s|%s" % [",".join(Array(dex.get_species(l).types)), Knacks.id_for_species(dex.get_species(l))]
		assert_false(seen.has(key), "%s repeats %s" % [l, seen.get(key, "")])
		seen[key] = l

func test_the_sexes_that_look_different_have_notes_and_sheets() -> void:
	for id in ["longlegs", "raftlet", "rafterweb"]:
		assert_true(Sexes.note(id) != "", "%s has a Fieldbook note" % id)
		for sex in ["f", "m"]:
			assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_%s.png" % [id, sex]), "%s_%s" % [id, sex])
