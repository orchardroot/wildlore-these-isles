extends TestCase
## The player's look (4.6): recipes for old saves, the base look, worn items in slot order, delta checks and pronouns.

const WEAR := [
	{"id": "flat_cap", "name": "Flat cap", "kind": "wear", "slot": "hat", "price": 300, "desc": "", "look": {"hat": "flat_cap", "palette": {"hat": "#6a5a40"}}},
	{"id": "aran", "name": "Aran jumper", "kind": "wear", "slot": "top", "price": 900, "desc": "", "look": {"palette": {"top": "#e8e0d0"}, "accessories": ["aran"]}},
	{"id": "wax_coat", "name": "Waxed jacket", "kind": "wear", "slot": "coat", "price": 1200, "desc": "", "look": {"palette": {"top": "#3a4a2a"}, "accessories": ["waxed_jacket"]}},
	{"id": "kilt", "name": "Kilt", "kind": "wear", "slot": "bottom", "price": 1500, "desc": "", "look": {"bottom_style": "kilt", "palette": {"bottom": "#2a3a5a", "accent": "#8a2a2a"}}},
	{"id": "red_wellies", "name": "Red wellies", "kind": "wear", "slot": "shoes", "price": 400, "desc": "", "look": {"palette": {"shoes": "#c83a3a"}, "accessories": ["wellies"]}},
]

func _items() -> ItemDB:
	return ItemDB.from_array(WEAR)

func _data(look := {}) -> GameStateData:
	var d := GameStateData.new()
	d.look = look
	return d

func test_old_save_renders_player_sprite_flag() -> void:
	var d := _data()
	assert_eq(Looks.recipe(d), JsonUtil.read("res://art/recipes/chars/player_a.json"), "no flag: player_a as before")
	d.set_flag("player_sprite", "player_b")
	var r := Looks.recipe(d)
	assert_eq(r.get("hair"), "pony", "player_b kept her ponytail")
	assert_eq(r.palette.get("skin"), "#d8a074")
	assert_true(d.look.is_empty(), "reading never writes the save")

func test_base_of_old_save_matches_its_sprite() -> void:
	var d := _data()
	d.set_flag("player_sprite", "player_b")
	var b := Looks.base(d)
	assert_eq(b.build, "slight")
	assert_eq(b.hair, "pony")
	assert_eq(b.sex, "f", "player_b was always her")
	var him := _data()
	him.set_flag("player_sprite", "player_a")
	assert_eq(Looks.base(him).sex, "m", "player_a was always him")
	assert_eq(Looks.sex(GameStateData.new()), "m", "no flag at all: player_a")
	assert_eq(b.wearing, {})
	assert_eq(Looks.skins()[int(b.skin)].hex, "#d8a074", "the skin index points at player_b's tone")
	assert_eq(Looks.hair_colours()[int(b.hair_colour)].hex, "#8a3a1e")
	# materialising the base renders the same palette as the old sprite
	Looks.ensure(d)
	assert_false(d.look.is_empty())
	var r := Looks.recipe(d)
	for k in ["skin", "hair", "top", "bottom", "shoes", "accent2"]:
		assert_eq(r.palette.get(k), JsonUtil.read("res://art/recipes/chars/player_b.json").palette.get(k), "palette " + k)
	assert_eq(r.build, "child")

func test_new_look_builds_a_recipe() -> void:
	var b := Looks.default_base()
	b.build = "adult"
	b.hair = "afro"
	b.sex = "f"
	var d := _data(b)
	var r := Looks.recipe(d)
	assert_eq(r.build, "adult")
	assert_eq(r.hair, "afro")
	assert_eq(r.hat, "none")
	assert_true("backpack" in r.accessories, "the rucksack stays")
	assert_eq(Looks.valid_recipe(r), true)

func test_wearing_applies_in_slot_order_later_wins() -> void:
	var b := Looks.default_base()
	b.wearing = {"hat": "flat_cap", "top": "aran", "coat": "wax_coat", "bottom": "kilt", "shoes": "red_wellies"}
	var d := _data(b)
	var r := Looks.recipe(d, _items())
	assert_eq(r.hat, "flat_cap")
	assert_eq(r.palette.hat, "#6a5a40")
	assert_eq(r.palette.top, "#3a4a2a", "the coat (later slot) sets the top colour over the jumper")
	assert_true("aran" in r.accessories and "waxed_jacket" in r.accessories, "accessories are unioned")
	assert_eq(r.accessories.count("backpack"), 1, "no duplicates")
	assert_eq(r.bottom_style, "kilt")
	assert_eq(r.palette.shoes, "#c83a3a")
	assert_true("wellies" in r.accessories)
	assert_eq(Looks.worn(d, "hat"), "flat_cap")
	assert_eq(Looks.worn(d, "neck"), "")

func test_wear_and_take_off() -> void:
	var d := _data()
	d.set_flag("player_sprite", "player_a")
	assert_eq(Looks.wear(d, "flat_cap", _items()), "", "wearing an owned-or-not item is the Wardrobe's business, Looks just dresses")
	assert_eq(Looks.worn(d, "hat"), "flat_cap")
	assert_eq(Looks.recipe(d, _items()).hat, "flat_cap")
	assert_eq(Looks.recipe(d, _items()).palette.skin, "#f2c9a0", "ensure kept player_a's skin")
	Looks.take_off(d, "hat")
	assert_eq(Looks.worn(d, "hat"), "")
	assert_eq(Looks.recipe(d, _items()).hat, "none")
	assert_true(Looks.wear(d, "nothing_here", _items()) != "", "an unknown item is refused")

func test_missing_item_is_ignored_not_fatal() -> void:
	var b := Looks.default_base()
	b.wearing = {"hat": "gone_from_the_data"}
	var r := Looks.recipe(_data(b), _items())
	assert_eq(r.hat, "none")

func test_valid_delta() -> void:
	assert_true(Looks.valid_delta({"hat": "flat_cap"}))
	assert_true(Looks.valid_delta({"palette": {"top": "#abcdef", "accent": "#123456"}}))
	assert_true(Looks.valid_delta({"accessories": ["aran", "scarf"], "sleeves": "short", "bottom_style": "kilt"}))
	assert_true(Looks.valid_delta({"hair": "afro"}))
	assert_false(Looks.valid_delta({"hat": "fez"}), "no such hat")
	assert_false(Looks.valid_delta({"accessories": ["jetpack"]}), "no such accessory")
	assert_false(Looks.valid_delta({"palette": {"top": "red"}}), "colours are #rrggbb")
	assert_false(Looks.valid_delta({"palette": {"nose": "#ffffff"}}), "no such palette key")
	assert_false(Looks.valid_delta({"bottom_style": "jeans"}))
	assert_false(Looks.valid_delta({"sleeves": "none"}))
	assert_false(Looks.valid_delta({"build": "adult"}), "a garment never changes your body")
	assert_false(Looks.valid_delta({"accessories": "aran"}), "accessories is a list")
	assert_false(Looks.valid_delta({}), "an empty delta dresses nothing")

func test_every_new_hair_style_is_known_to_the_painter() -> void:
	for h in ["afro", "braids", "locs", "undercut", "mohawk", "buzz", "short", "long", "bob", "bun", "pony", "curly", "spiky", "bald", "windswept"]:
		assert_true(Looks.valid_delta({"hair": h}), h)
		assert_true(Looks.hair_styles().any(func(s): return str(s.id) == h), h + " is offered in the creator")

func test_looks_data_shape() -> void:
	assert_true(Looks.skins().size() >= 8 and Looks.skins().size() <= 10, "8 to 10 skin tones")
	assert_eq(Looks.hair_colours().size(), 12)
	assert_true(Looks.hair_colours().any(func(c): return str(c.id) == "grey"))
	assert_true(Looks.hair_colours().filter(func(c): return c.get("dyed", false)).size() >= 2, "two dyed colours")
	assert_eq(Looks.builds().size(), 2)
	assert_eq(Looks.check(_items()), [], "the sample wear items pass the validator")
	var bad := ItemDB.from_array([{"id": "x", "kind": "wear", "slot": "wing", "price": 10, "look": {"hat": "fez"}}])
	assert_eq(Looks.check(bad).size(), 2, "a bad slot and a bad delta are two errors")

func test_pronoun_forms() -> void:
	var tbl := {"m": ["he", "him", "his", "Mr", "man"], "f": ["she", "her", "her", "Ms", "woman"]}
	for sx in tbl:
		var b := Looks.default_base()
		b.sex = sx
		var d := _data(b)
		var forms := ["he", "him", "his", "Mr", "man"]
		for i in forms.size():
			assert_eq(Looks.pronoun(d, forms[i]), tbl[sx][i], "%s / %s" % [sx, forms[i]])
		assert_eq(Looks.pronoun(d, "He"), str(tbl[sx][0]).capitalize(), "a capital form capitalises")
		assert_eq(Looks.pronoun(d, "Man"), str(tbl[sx][4]).capitalize())
	var old := _data()
	old.set_flag("player_sprite", "player_b")
	assert_eq(Looks.pronoun(old, "Mr"), "Ms", "an old player_b save is Ms")
	assert_eq(Looks.pronoun(_data(), "Mr"), "Mr", "an old player_a save is Mr")
	assert_eq(Looks.pronoun(_data(), "nonsense"), "", "an unknown form is blank, never a crash")
	var junk := Looks.default_base()
	junk.sex = "x"
	assert_eq(Looks.sex(_data(junk)), "m", "junk in the save reads as him, never a crash")

func test_pron_sub_in_dialogue() -> void:
	var b := Looks.default_base()
	b.sex = "f"
	var d := _data(b)
	assert_eq(Looks.sub(d, "{He} said {his} hat was lost, so give it {him}, {Mr} Sam. A fine {man}. {Man} indeed."), "She said her hat was lost, so give it her, Ms Sam. A fine woman. Woman indeed.")
	assert_eq(Looks.sub(d, "no braces here"), "no braces here")
	assert_eq(Looks.sub(d, "{they} stays"), "{they} stays", "there is no third form")

func test_starter_looks_are_the_old_two() -> void:
	var m := Looks.starter("m")
	var f := Looks.starter("f")
	assert_eq(m.sex, "m")
	assert_eq(f.sex, "f")
	assert_eq(f.hair, "pony")
	for sx in ["m", "f"]:
		var r := Looks.from_base(Looks.starter(sx))
		var legacy: Dictionary = JsonUtil.read(Looks.LEGACY[Looks.LEGACY_BY_SEX[sx]])
		assert_eq(r.palette, legacy.palette, sx + " paints the old sprite's colours")
		assert_eq(r.hair, legacy.hair)

func test_save_round_trip_and_old_save_default() -> void:
	var dex := Dex.load_default()
	var b := Looks.default_base()
	b.wearing = {"hat": "flat_cap"}
	var d := _data(b)
	var back := GameStateData.from_dict(d.to_dict(), dex)
	assert_eq(back.look, b)
	var old := GameStateData.from_dict({"player_name": "Sam"}, dex)
	assert_eq(old.look, {}, "a save from before looks has no look, so the sprite flag rules")
	var junk := GameStateData.from_dict({"look": "hat"}, dex)
	assert_eq(junk.look, {}, "junk is dropped")

func test_render_cache_hits_by_recipe_content() -> void:
	var r1 := Looks.recipe(_data(Looks.default_base()))
	var r2 := Looks.recipe(_data(Looks.default_base()))
	LookArt.clear_cache()
	var t1 := LookArt.texture(r1)
	assert_true(t1 is ImageTexture)
	assert_eq(t1.get_width(), 96)
	assert_eq(t1.get_height(), 192)
	assert_true(LookArt.texture(r2) == t1, "an equal recipe is the same texture")
	assert_eq(LookArt.renders, 1, "painted once")
	var r3 := r1.duplicate(true)
	r3.hair = "mohawk"
	assert_false(LookArt.texture(r3) == t1, "a different recipe paints again")
	assert_eq(LookArt.renders, 2)
	var shuffled := {}
	for k in r1.keys():  # same content, keys in another order: still a hit
		shuffled[k] = r1[k]
	shuffled.erase("hair")
	shuffled["hair"] = r1.hair
	assert_true(LookArt.texture(shuffled) == t1)
	assert_eq(LookArt.renders, 2)

func test_preview_dresses_without_saving() -> void:
	var d := _data()
	var r := Looks.preview(d, "kilt", _items())
	assert_eq(r.bottom_style, "kilt")
	assert_true(d.look.is_empty())
	assert_eq(Looks.recipe(d, _items()).get("bottom_style"), "trousers")

func test_worn_names_for_shopkeepers() -> void:
	var b := Looks.default_base()
	b.wearing = {"hat": "flat_cap", "coat": "wax_coat"}
	var d := _data(b)
	assert_eq(Looks.worn_name(d, "hat", _items()), "Flat cap")
	assert_eq(Looks.worn_name(d, "shoes", _items()), "")
