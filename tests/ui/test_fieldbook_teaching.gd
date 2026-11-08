extends TestCase
## Fieldbook teaching (docs/design/fieldbook_teaching.md): a caught entry ends with "In real life", a true note
## about the creature's real-life basis, and its name in Welsh, Irish and Scottish Gaelic in the local ink.

const Pedia = preload("res://ui/pedia_screen.gd")

## The Fieldbook's words box at 1280x720 with the sample party: 682 wide, 296 tall below the picture.
const BOX := Vector2(682, 296)
## fit_block's height estimate adds a shadow pixel or two a line on purpose, so it never promises a fit that
## then wraps once more; this much is forgiven.
const ESTIMATE_SLACK := 20.0

func _sp(real := "", names = {}) -> Dictionary:
	return {"id": "foxling", "name": "Foxling", "real": real, "names": names,
		"dex": {"text": "A fox.", "fact": "Foxes."}}

func _column() -> Array:
	return UIKit.words_box(Pedia.WORD_SIZES, Pedia.WORD_SEP)

func test_names_line_keeps_cy_ga_gd_order_from_whichever_keys_exist() -> void:
	assert_eq(MenuLogic.fieldbook_names_line({"gd": "sionnach", "cy": "llwynog", "ga": "sionnach"}), "cy llwynog · ga sionnach · gd sionnach")
	assert_eq(MenuLogic.fieldbook_names_line({"ga": "madra"}), "ga madra", "one language, no empty slots")
	assert_eq(MenuLogic.fieldbook_names_line({"cy": "ci", "gd": "cù"}), "cy ci · gd cù", "a gap in the middle")
	assert_eq(MenuLogic.fieldbook_names_line({}), "", "a creature based on a place or a machine")
	assert_eq(MenuLogic.fieldbook_names_line({"cy": "  ", "ga": ""}), "", "blank words count as missing")
	assert_eq(MenuLogic.fieldbook_names_line({"en": "fox", "cy": "llwynog"}), "cy llwynog", "only the three languages")

func test_caught_entry_adds_the_real_line_and_the_names() -> void:
	var wb := _column()
	var added: Array = Pedia.add_real_life(wb[1], _sp("Foxes bark.", {"cy": "llwynog", "ga": "sionnach", "gd": "sionnach"}))
	assert_eq(added.size(), 3, "heading, note and names")
	assert_eq(added[0].text, "In real life")
	assert_eq(added[0].get_theme_color("font_color"), UIKit.GOLD, "a small gold heading")
	assert_eq(added[1].text, "Foxes bark.")
	assert_eq(added[1].get_theme_color("font_color"), Pedia.FACT_INK, "the same colour as the fact")
	assert_eq(added[2].text, "cy llwynog · ga sionnach · gd sionnach")
	assert_eq(added[2].get_theme_color("font_color"), Langs.LOCAL_INK, "the names in the warm ink of signs")
	assert_eq(added[2].tooltip_text, "Welsh · Irish · Scottish Gaelic")
	var words: Array = wb[1].get_meta("words")
	assert_eq(words.size(), 3, "all three take part in the shrink-to-fit")
	assert_eq(words[1][1], -2, "the note is the fact's size")
	assert_eq(words[2][1], -3, "the names a touch smaller")
	for l in added:
		assert_eq(l.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "every line wraps")
		assert_false(words.any(func(w): return w[0] == l and w[2]), "nothing is optional: they are the reward for catching it")
	wb[0].free()

func test_empty_names_add_no_line() -> void:
	var wb := _column()
	var added: Array = Pedia.add_real_life(wb[1], _sp("A viaduct is a bridge.", {}))
	assert_eq(added.size(), 2, "the note alone, no empty names slot")
	assert_eq(added[1].text, "A viaduct is a bridge.")
	assert_eq(wb[1].get_child_count(), 2)
	wb[0].free()

func test_a_species_without_either_key_adds_nothing() -> void:
	var wb := _column()
	var sp := _sp()
	sp.erase("real")
	sp.erase("names")
	assert_eq(Pedia.add_real_life(wb[1], sp), [])
	assert_eq(Pedia.add_real_life(wb[1], _sp("  ", {"cy": ""})), [], "blank values are as good as missing")
	assert_eq(Pedia.add_real_life(wb[1], {"id": "x", "names": "llwynog"}), [], "a mistyped names key is skipped, not shown")
	assert_eq(wb[1].get_child_count(), 0)
	wb[0].free()

func test_found_in_line() -> void:
	assert_eq(Pedia.found_in([]), "Found in: somewhere secret")
	assert_eq(Pedia.found_in(["Dee Valley", "Ogwen"]), "Found in: Dee Valley, Ogwen")
	assert_eq(Pedia.found_in(["A", "B", "C", "D", "E"]), "Found in: A, B, C and 2 more")

## Every caught entry, teaching lines included, fits the words box at 1280x720 in at most two boxes' worth at the
## smallest readable size (18 px, UIKit.MIN_TEXT): a long one shrinks that far, then Confirm reads on once.
func test_every_caught_entry_fits_the_words_box() -> void:
	var dex := Dex.load_default()
	var habitats: Dictionary = Pedia.habitat_index()
	var box := Control.new()
	box.size = BOX
	var spill := []
	for id in dex.ids():
		var sp := dex.get_species(id)
		var wb := _column()
		var words: VBoxContainer = wb[1]
		UIKit.add_words(words, Pedia.found_in(MenuLogic.habitats(habitats, id)), -4, Pedia.FACT_INK)
		UIKit.add_words(words, str(sp.dex.text), 0)
		UIKit.add_words(words, "Did you know?", -1, UIKit.GOLD)
		UIKit.add_words(words, str(sp.dex.fact), -2, Pedia.FACT_INK)
		Pedia.add_real_life(words, sp)
		var entries: Array = words.get_meta("words")
		var smallest: int = Pedia.WORD_SIZES[Pedia.WORD_SIZES.size() - 1]
		var need := UIKit._block_height(entries, BOX.x - 16, smallest, Pedia.WORD_SEP, true)
		if need > BOX.y * 2 + ESTIMATE_SLACK:
			spill.append("%s (%d px)" % [id, need])
		UIKit.fit_block(entries, box, Pedia.WORD_SIZES, Pedia.WORD_SEP)
		for e in entries:
			assert_true(e[0].visible, "%s: no line is dropped" % id)
		wb[0].free()
	box.free()
	assert_eq(spill, [], "entries longer than two boxes even at the smallest size")

func test_every_species_names_are_in_the_three_languages_only() -> void:
	var dex := Dex.load_default()
	var with_names := 0
	for id in dex.ids():
		var sp := dex.get_species(id)
		assert_true(str(sp.get("real", "")) != "", "%s has a real-life note" % id)
		var names = sp.get("names", {})
		assert_true(names is Dictionary, "%s names is a dictionary" % id)
		for code in names:
			assert_has(Langs.CREATURE_NAME_CODES, str(code), id)
		if not names.is_empty():
			with_names += 1
	assert_true(with_names > 100, "most creatures have a local name (%d)" % with_names)
