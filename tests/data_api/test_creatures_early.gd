extends TestCase
## 3.0: ten appendix lines for the first five hours (Macclesfield to Ogwen), so the early routes offer more than
## kin and gale: Bogglet (boggart), Graftling (Manchester bee), Crumblet (Mam Tor, Blue John), Peatling (Lindow
## Man), Bleeplet (Jodrell Bank), Fizzlet (Bonfire Night), Grinalkin (the Cheshire Cat), Dockling (Liverpool's
## docks), Brinelet (Cheshire salt) and Ductling (Pontcysyllte Aqueduct).

const LINES := {
	"bogglet": ["bogglet", "cloughgart"], "graftling": ["graftling", "workhive"], "crumblet": ["crumblet", "shivertor"],
	"peatling": ["peatling", "lindwight"], "bleeplet": ["bleeplet", "skyharker"], "fizzlet": ["fizzlet", "catherwheel"],
	"grinalkin": ["grinalkin"], "dockling": ["dockling", "quayhulk"], "brinelet": ["brinelet", "halitor"],
	"ductling": ["ductling", "aqueduck"],
}
const EARLY := ["macc_forest", "cat_and_fiddle", "goyt_valley", "manchester", "chat_moss", "liverpool", "wirral_way",
	"chester", "dee_valley", "llangollen", "ogwen"]

var dex := Dex.load_default()
var moves := MoveDB.load_default()

func _all() -> Array:
	var out := []
	for line in LINES:
		out.append_array(LINES[line])
	return out

func _bst(sp: Dictionary) -> int:
	var n := 0
	for s in sp.base:
		n += int(sp.base[s])
	return n

func _zone(id: String) -> Dictionary:
	var z = JsonUtil.read("res://data/zones/%s.json" % id)
	return z if z is Dictionary else {}

func _final_of(id: String) -> Dictionary:
	var sp := dex.get_species(id)
	while sp.evolves is Dictionary:
		sp = dex.get_species(str(sp.evolves.to))
	return sp

func test_species_load_in_the_appendix_after_the_200() -> void:
	var order: Array = dex.ids()
	for id in _all():
		assert_true(dex.has(id), id)
		assert_true(Dex.in_appendix(id), "%s is an appendix species" % id)
		assert_true(order.find(id) >= 200, "%s comes after the 200" % id)
	assert_eq(dex.core_ids().size(), 200, "the diploma still counts 200")

func test_lines_chain_up() -> void:
	for line in LINES:
		var ids: Array = LINES[line]
		for i in ids.size():
			var sp := dex.get_species(ids[i])
			if i < ids.size() - 1:
				assert_eq(sp.evolves.to, ids[i + 1], ids[i])
				var lv := int(sp.evolves.level)
				assert_true(lv >= 18 and lv <= 30, "%s evolves in the early game band (%d)" % [ids[i], lv])
			else:
				assert_eq(sp.evolves, null, ids[i])

func test_base_stat_totals_sit_with_comparable_lines() -> void:
	for line in LINES:
		var ids: Array = LINES[line]
		for i in ids.size():
			var b := _bst(dex.get_species(ids[i]))
			if ids.size() == 1:
				assert_true(b >= 440 and b <= 500, "%s is a one-stage lore creature (%d)" % [ids[i], b])
			elif i == 0:
				assert_true(b >= 280 and b <= 330, "%s is a basic (%d)" % [ids[i], b])
			else:
				assert_true(b >= 470 and b <= 500, "%s is a final (%d)" % [ids[i], b])

func test_under_represented_types_and_no_pure_kin_or_gale() -> void:
	var seen := {}
	for id in _all():
		var types: Array = dex.get_species(id).types
		assert_false(types.has("kin") or types.has("gale"), "%s adds no more kin or gale" % id)
		for t in types:
			seen[t] = true
	for t in ["storm", "hearth", "iron", "stone", "brawn", "spirit", "urban", "bog", "tide"]:
		assert_true(seen.has(t), "the early lines cover %s" % t)

func test_learnsets_use_real_moves_with_type_coverage() -> void:
	for id in _all():
		var sp := dex.get_species(id)
		var at_one := 0
		var types_learnt := {}
		for e in sp.learnset:
			assert_true(moves.has(e[1]), "%s learns a real move: %s" % [id, e[1]])
			if int(e[0]) == 1:
				at_one += 1
			var m := moves.get_move(e[1])
			if str(m.get("category", "")) != "status":
				types_learnt[str(m.type)] = true
		assert_true(at_one >= 2, "%s starts with two moves" % id)
		for t in sp.types:
			assert_true(types_learnt.has(t), "%s has an attacking %s move" % [id, t])
		assert_true(types_learnt.size() >= 3, "%s has coverage beyond its own types" % id)
		assert_eq(sp.malformed_learnset, 0, id)

func test_sprites_knacks_and_fieldbook_text() -> void:
	for id in _all():
		for part in ["front", "back", "icon"]:
			assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_%s.png" % [id, part]), "%s %s sprite" % [id, part])
		assert_true(FileAccess.file_exists("res://art/recipes/creatures/%s.json" % id), "%s recipe" % id)
		var sp := dex.get_species(id)
		assert_true(Knacks.id_for_species(sp) != "", "%s has a knack" % id)
		assert_true(str(sp.dex.text).length() > 40 and str(sp.dex.fact).length() > 40, "%s has text and a fact" % id)
		assert_false(str(sp.dex.text).contains("—") or str(sp.dex.fact).contains("—"), "%s: no em-dashes" % id)
	for line in LINES:
		var ids: Array = LINES[line]
		assert_eq(Knacks.id_for_species(dex.get_species(ids[0])), Knacks.id_for_species(dex.get_species(ids[-1])), line)

func test_each_line_is_met_where_its_fieldbook_says_at_the_zone_band() -> void:
	var where := {}
	for zid in EARLY:
		var z := _zone(zid)
		for table in z.get("encounters", {}):
			var band := [999, 0]
			for e in z.encounters[table]:
				if not Dex.in_appendix(str(e.species)):
					band = [mini(band[0], int(e.min)), maxi(band[1], int(e.max))]
			for e in z.encounters[table]:
				if LINES.has(str(e.species)):
					where[e.species] = where.get(e.species, []) + [zid]
					assert_true(int(e.min) >= band[0] - 1 and int(e.max) <= band[1] + 1, "%s in %s %s: levels %d-%d sit in the band %s" % [e.species, zid, table, e.min, e.max, band])
	# w53: homes anywhere can have an "indoor" visitor (IndoorFolk); those count as where it's met too
	for path in JsonUtil.list_json("res://data/zones"):
		var z = JsonUtil.read(path)
		if z is Dictionary and z.get("encounters") is Dictionary:
			for e in z.encounters.get(IndoorFolk.KIND, []):
				if LINES.has(str(e.species)):
					where[e.species] = where.get(e.species, []) + [str(z.id)]
	for line in LINES:
		var got: Array = where.get(line, [])
		assert_true(got.size() >= 1, "%s is met somewhere early" % line)
		var uniq := {}
		for z in got:
			uniq[z] = true
		var hab: Array = dex.get_species(line).habitat.duplicate()
		var keys: Array = uniq.keys()
		hab.sort()
		keys.sort()
		assert_eq(hab, keys, "%s: its Fieldbook habitat is where it's met" % line)

func test_every_early_zone_offers_variety_and_a_strong_pick() -> void:
	for zid in EARLY:
		var z := _zone(zid)
		var types := {}
		var strong := []
		for table in z.get("encounters", {}):
			for e in z.encounters[table]:
				var sp := dex.get_species(str(e.species))
				var other := false
				for t in sp.types:
					if t != "kin" and t != "gale":
						types[t] = true
						other = true
				var fin := _final_of(str(e.species))
				if other and (_bst(fin) >= 470 or (fin.id == sp.id and _bst(sp) >= 440)):
					strong.append(e.species)
		assert_true(types.size() >= 3, "%s offers 3+ types beyond kin and gale: %s" % [zid, types.keys()])
		assert_true(strong.size() >= 1, "%s has at least one strong pick" % zid)
