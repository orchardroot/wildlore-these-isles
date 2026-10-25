extends TestCase
## Male and female creatures: the words, a sex for every creature of a sexed kindred (old saves included), the sprite
## lookup that prefers a `_f` / `_m` sheet, the dimorph recipes and the Fieldbook notes, the pairing words.

const Creature_ := preload("res://tools/spritegen/creature.gd")
const RECIPES := "res://art/recipes/creatures/"

func _recipe(id: String) -> Dictionary:
	var f := FileAccess.open(RECIPES + id + ".json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

func test_words_and_signs_per_sex() -> void:
	assert_eq(Sexes.word("m"), "Male")
	assert_eq(Sexes.word("f"), "Female")
	assert_eq(Sexes.word(""), "", "a kindred without sexes shows nothing, never a dash")
	assert_eq(Sexes.glyph("m"), "♂")
	assert_eq(Sexes.glyph("f"), "♀")
	assert_eq(Sexes.glyph(""), "")
	assert_true(Sexes.colour("m") != Sexes.colour("f"))
	var c := Fixtures.creature("grinalkin", 5)
	assert_eq(Sexes.word_of(c), "")
	assert_eq(UIKit.sex_word(c), "")

func test_the_mark_is_there_for_a_sexed_creature_and_nothing_for_the_rest() -> void:
	var c := Fixtures.creature("stagmor", 5)
	assert_true(Sexes.valid(c.sex))
	var mk := UIKit.sex_mark(c, 22)
	assert_true(mk.visible)
	assert_eq(mk.custom_minimum_size, Vector2(22, 22))
	assert_eq(mk.tooltip_text, Sexes.word(c.sex))
	mk.free()
	var bare := UIKit.sex_mark(Fixtures.creature("grinalkin", 5), 22)
	assert_false(bare.visible)
	assert_eq(bare.custom_minimum_size, Vector2.ZERO)
	bare.free()

func test_every_species_of_a_sexed_kindred_is_made_with_a_sex() -> void:
	var dex := Fixtures.dex()
	var checked := 0
	for id in dex.ids():
		var sp: Dictionary = dex.get_species(id)
		if Crossbreeds.is_id(str(id)):
			continue
		var c := Creature.create(sp, 5, Rng.new(7), Fixtures.moves())
		var mode := Genetics.sex_mode(Genetics.kindred_of(c))
		if mode == "none":
			assert_eq(c.sex, "", "%s has no sex" % id)
		else:
			assert_true(Sexes.valid(c.sex), "%s should have a sex, has '%s'" % [id, c.sex])
			checked += 1
	assert_true(checked > 100, "plenty of sexed species checked (%d)" % checked)

func test_an_old_save_with_no_sex_gets_one_that_never_changes() -> void:
	var c := Fixtures.creature("stagmor", 9)
	var d := c.to_dict()
	d.erase("sex")
	d.erase("genome")
	var a := Creature.from_dict(d, Fixtures.dex())
	var b := Creature.from_dict(d, Fixtures.dex())
	assert_true(Sexes.valid(a.sex))
	assert_eq(a.sex, b.sex, "the same old save always gets the same sex")
	# a genome without a sex: the ginger chromosomes decide (one copy is male in beasts)
	var d2 := c.to_dict()
	d2["sex"] = ""
	var g: Array = c.genome.ginger
	var back := Creature.from_dict(d2, Fixtures.dex())
	assert_eq(back.sex, "m" if str(g[1]) == "Y" else "f")
	assert_eq(back.sex, c.sex, "and it is the sex it was made with")
	var fowl := Fixtures.creature("capercaillie", 9)
	var d3 := fowl.to_dict()
	d3["sex"] = ""
	assert_eq(Creature.from_dict(d3, Fixtures.dex()).sex, fowl.sex, "fowl read the same chromosomes the other way")
	# a kindred without sexes stays without
	var bare := Fixtures.creature("grinalkin", 5).to_dict()
	assert_eq(Creature.from_dict(bare, Fixtures.dex()).sex, "")

func test_lookup_prefers_the_sex_sheet_when_there_is_one() -> void:
	assert_eq(Sexes.art_id("stagmor", "front", "f"), "stagmor_f")
	assert_eq(Sexes.art_id("stagmor", "back", "f"), "stagmor_f")
	assert_eq(Sexes.art_id("stagmor", "icon", "f"), "stagmor_f")
	assert_eq(Sexes.art_id("stagmor", "front", "m"), "stagmor", "no male sheet: the usual one is the male")
	assert_eq(Sexes.art_id("stagmor", "front", ""), "stagmor")
	assert_eq(Sexes.art_id("redbreast", "front", "f"), "redbreast", "a species that does not differ")
	assert_eq(Sexes.sheet_path("stagmor", "front", "f"), "res://art/sprites/creatures/stagmor_f.png")
	assert_eq(Sexes.sheet_path("stagmor", "back", "f"), "res://art/sprites/creatures/stagmor_f_back.png")
	assert_eq(Sexes.sheet_path("stagmor", "back", "m"), "res://art/sprites/creatures/stagmor_back.png")
	var sp := Fixtures.dex().get_species("stagmor")
	assert_true(CreatureArt.texture(sp, false, "f") != CreatureArt.texture(sp, false, "m"), "the hind and the stag are drawn differently")
	assert_true(CreatureArt.texture(sp, true, "f") != CreatureArt.texture(sp, true, ""))
	assert_eq(CreatureArt.texture(sp, false, "m"), CreatureArt.texture(sp, false, ""))
	assert_true(CreatureArt.icon(sp, "f") != CreatureArt.icon(sp, "m"))
	var plain := Fixtures.dex().get_species("redbreast")
	assert_eq(CreatureArt.texture(plain, false, "f"), CreatureArt.texture(plain, false, ""))

func test_dimorph_apply_drops_sets_and_adds() -> void:
	var base := {"palette": {"a": "#111111"}, "back_over": [3], "back_hide": [1],
		"layers": [{"shape": "circle", "r": 3, "colour": "a"}, {"shape": "circle", "r": 4, "colour": "a"},
			{"shape": "circle", "r": 5, "colour": "a"}, {"shape": "circle", "r": 6, "colour": "a"}],
		"face_layers": [{"shape": "circle", "r": 1, "colour": "a"}, {"shape": "circle", "r": 2, "colour": "a"}],
		"dimorph": {"f": {"palette": {"a": "#ffffff", "b": "#222222"}, "drop": [0], "set": {"2": {"r": 9}},
			"add_layers": [{"shape": "circle", "r": 7, "colour": "b"}], "drop_face": [1], "anim": "shift"}}}
	var f := Creature_.apply_dimorph(base, "f")
	assert_eq(f.layers.size(), 4, "one dropped, one added")
	assert_eq(f.layers[1].r, 9, "set changes the layer the base index names")
	assert_eq(f.palette.a, "#ffffff")
	assert_eq(f.palette.b, "#222222")
	assert_eq(f.back_over, [2], "index lists follow the layers they name")
	assert_eq(f.back_hide, [0])
	assert_eq(f.face_layers.size(), 1)
	assert_eq(f.anim, "shift")
	assert_false(f.has("dimorph"))
	assert_eq(base.layers.size(), 4, "the base is untouched")
	assert_eq(Creature_.apply_dimorph(base, "m"), {}, "no male overrides, no male sheet")

func test_forty_species_have_dimorph_art_and_a_true_looking_note() -> void:
	var notes: Dictionary = Sexes.notes()
	assert_true(notes.size() >= 40, "40 or more species with a note (%d)" % notes.size())
	var with_recipe := 0
	for id in notes:
		var r := _recipe(str(id))
		assert_true(r.has("dimorph"), "%s has a dimorph recipe" % id)
		var n := str(notes[id])
		assert_true(n.length() > 30 and n.length() < 260, "%s note is one short line" % id)
		assert_false(n.contains("—") or n.contains("–"), "%s note has no dashes" % id)
		var sp := Fixtures.dex().get_species(str(id))
		assert_false(sp.is_empty(), "%s is a real species" % id)
		var c := Fixtures.creature(str(id), 5)
		assert_true(Sexes.valid(c.sex), "%s belongs to a kindred with sexes" % id)
		for sx in r.get("dimorph", {}):
			assert_true(sx in ["m", "f"], "%s: dimorph key %s" % [id, sx])
			var out := Creature_.apply_dimorph(r, str(sx))
			assert_false(out.is_empty(), "%s %s applies" % [id, sx])
			var n_layers: int = (r.layers as Array).size()
			for i in r.dimorph[sx].get("drop", []):
				assert_true(int(i) >= 0 and int(i) < n_layers, "%s %s drops layer %d that exists" % [id, sx, int(i)])
			for key in r.dimorph[sx].get("set", {}):
				assert_true(int(key) < n_layers, "%s %s sets layer %s that exists" % [id, sx, key])
			for kind in ["", "_back", "_icon"]:
				assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_%s%s.png" % [id, sx, kind]), "%s_%s%s.png was rendered" % [id, sx, kind])
		with_recipe += 1
	assert_true(with_recipe >= 40)

func test_every_dimorph_recipe_has_a_note() -> void:
	var dir := DirAccess.open(RECIPES)
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var id := f.get_basename()
		if _recipe(id).has("dimorph"):
			assert_true(Sexes.note(id) != "", "%s has a dimorph recipe and so needs a Males and females line" % id)

func test_fieldbook_remembers_which_sexes_you_have_met() -> void:
	var d := GameStateData.new()
	var m := Fixtures.creature("stagmor", 5)
	var f := Fixtures.creature("stagmor", 6)
	m.sex = "m"
	f.sex = "f"
	assert_eq(Sexes.seen_sexes(d, "stagmor"), "")
	Sexes.record_seen(d, m)
	assert_eq(Sexes.seen_sexes(d, "stagmor"), "m")
	assert_false(Sexes.seen_both(d, "stagmor"))
	Sexes.record_seen(d, m)
	assert_eq(Sexes.seen_sexes(d, "stagmor"), "m", "meeting the same sex twice changes nothing")
	Sexes.record_seen(d, f)
	assert_true(Sexes.seen_both(d, "stagmor"))
	# a creature you already hold counts, so a Fieldbook from before this still knows
	var d2 := GameStateData.new()
	d2.party = [m]
	assert_eq(Sexes.seen_sexes(d2, "stagmor"), "m")
	# a species with no note records nothing
	var plain := Fixtures.creature("redbreast", 5)
	Sexes.record_seen(d, plain)
	assert_eq(Sexes.seen_sexes(d, "redbreast"), "")

func test_pairing_says_plainly_what_a_pair_needs() -> void:
	var a := Fixtures.creature("moolet", 5)
	var b := Fixtures.creature("moolet", 5)
	a.sex = "m"
	b.sex = "m"
	a.nickname = "Bruce"
	b.nickname = "Clive"
	assert_eq(PairingLogic.RULE, "A pair needs one male and one female.")
	var why := PairingLogic.sex_refusal(a, b)
	assert_true(why.contains("Bruce") and why.contains("Clive") and why.contains("both male"), why)
	assert_true(why.contains(PairingLogic.RULE))
	b.sex = "f"
	assert_eq(PairingLogic.sex_refusal(a, b), "", "a male and a female have no sex trouble")
	b.sex = ""
	assert_true(PairingLogic.sex_refusal(a, b).contains("Clive has no male or female side"))
	var d := GameStateData.new()
	b.sex = "m"
	var v := PairingLogic.verdict(d, "farm", a, b)
	assert_false(v.ok)
	assert_true(str(v.why).contains("both male"), "the verdict names why: " + str(v.why))
	assert_true(PairingLogic.pick_prompt(a).contains("Pick a female"))
	b.sex = "f"
	assert_true(PairingLogic.pick_prompt(b).contains("Pick a male"))
	assert_true(PairingLogic.pick_prompt(null).contains(PairingLogic.RULE))
	assert_eq(PairingLogic.sex_desc(a), "male")
