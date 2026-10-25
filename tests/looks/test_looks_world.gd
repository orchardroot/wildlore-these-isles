extends TestCase
## The look out in the world: the creator's choosers, the pronoun substitution in dialogue, the mirror in Mum's
## house, the wardrobe command, and the letters that call you Mr / Ms / Mx.

const NameEntry = preload("res://ui/name_entry.gd")

func test_creator_choices_cover_the_data() -> void:
	assert_eq(NameEntry.choices("skin").size(), Looks.skins().size())
	assert_eq(NameEntry.choices("hair").size(), Looks.hair_styles().size())
	assert_eq(NameEntry.choices("hair_colour").size(), 12)
	assert_eq(NameEntry.choices("pronouns").map(func(c): return c[0]), ["he", "she", "they"])
	assert_eq(NameEntry.choices("build").map(func(c): return c[0]), ["slight", "adult"])
	assert_eq(NameEntry.choices("top").size(), Looks.tops().size())
	assert_eq(NameEntry.choices("nonsense"), [])

func test_creator_cycles_and_wraps() -> void:
	var b := Looks.default_base()
	b = NameEntry.cycled(b, "pronouns", 1)
	assert_eq(b.pronouns, "he", "they wraps round to he")
	b = NameEntry.cycled(b, "pronouns", -1)
	assert_eq(b.pronouns, "they")
	b = NameEntry.cycled(b, "skin", -1)
	assert_eq(b.skin, 0)
	b = NameEntry.cycled(b, "skin", -1)
	assert_eq(b.skin, Looks.skins().size() - 1, "wraps the other way")
	b = NameEntry.cycled(b, "hair", 1)
	assert_true(Looks.valid_recipe(Looks.from_base(b)))

func test_random_base_is_always_drawable() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 30:
		var b := NameEntry.random_base(rng)
		assert_true(b.pronouns in Looks.PRONOUNS)
		assert_true(Looks.valid_recipe(Looks.from_base(b)), str(b))
		assert_eq(b.wearing, {})

func test_dialogue_substitutes_pronouns() -> void:
	var h := FakeStoryHost.new()
	var b := Looks.default_base()
	b.pronouns = "she"
	h.data.look = b
	h.data.player_name = "Nia"
	await Commands.new(h).run([{"do": "say", "who": "Mum", "text": "{player}? {They} went out. Ask {Mx} {player} {themself}."}])
	assert_eq(h.said, [["Mum", "Nia? She went out. Ask Ms Nia {themself}."]], "known forms swap, unknown braces stay")

func test_wardrobe_command_opens_the_menu() -> void:
	var h := FakeStoryHost.new()
	await Commands.new(h).run([{"do": "wardrobe"}, {"do": "wardrobe", "mirror": true}])
	assert_eq(h.log, [["menu", "wardrobe"], ["menu", "wardrobe:mirror"]])

func test_mums_house_has_a_mirror_and_a_script() -> void:
	var z := ZoneData.load_id("macc_home")
	var pr := LooksMirror.prop_at(z, Vector2i(9, 3))
	assert_eq(str(pr.get("type", "")), "mirror")
	assert_true(z.blocked.has(Vector2i(9, 3)), "you stand in front of it, not in it")
	assert_true(z.tile_at(Vector2i(8, 3)) != "wall", "the tile in front is floor")
	var cmds: Array = StoryData.script("macc_home", "mirror")
	assert_eq(cmds.back().get("do"), "wardrobe")
	assert_eq(cmds.back().get("mirror"), true, "hair is free at the mirror")
	assert_true(LooksMirror.mesh() is ArrayMesh)

func test_mum_has_a_line_for_whoever_you_are() -> void:
	var text := JSON.stringify(StoryData.script("macc_home", "mum"))
	assert_true("{person}" in text, "Mum's line uses {person}")
	assert_false("\u2014" in text, "no em-dashes")

func test_letters_address_mr_ms_mx() -> void:
	var d := GameStateData.new()
	d.player_name = "Nia"
	var b := Looks.default_base()
	b.pronouns = "she"
	d.look = b
	var lines := BuildingSociety.letter_lines(BuildingSociety.letter_ids()[0], d)
	assert_true(str(lines[0]).contains("addressed to Ms Nia"), lines[0])
	assert_false(str(BuildingSociety.letter_lines(BuildingSociety.letter_ids()[0])[0]).contains("addressed"), "without data the old envelope")
	var lease_id := str(Leases.all()[0].id)
	var ll := Leases.letter_lines({"k": "welcome", "l": lease_id, "a": 100, "day": 1}, d)
	assert_true(ll.size() > 1 and str(ll[1]).begins_with("Dear Ms Nia."), str(ll))
	var anon := Leases.letter_lines({"k": "welcome", "l": lease_id, "a": 100, "day": 1})
	assert_true(str(anon[1]).begins_with("Dear Sir or Madam."), str(anon))
	var deed_id := str(Deeds.all()[0].id)
	if deed_id != "":
		for k in ["rates", "tax"]:
			var dl := Deeds.letter_lines(d, {"k": k, "d": deed_id, "a": 100, "day": 1})
			assert_true(str(dl[1]).begins_with("Dear Ms Nia"), str(dl))
			for ln in dl:
				assert_false("{" in str(ln), "every blank filled: " + str(ln))
