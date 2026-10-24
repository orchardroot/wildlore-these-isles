extends TestCase
## The approved Welsh lessons (wave 46 H): cy_01 to cy_06 all load through the same path the game uses, validate, have
## no duplicate ids, and cy_03 to cy_06 are reachable from their teachers once level 1 is certified.

func _ids() -> Array:
	return LangLessons.lessons("cy").map(func(l): return str(l.id))

func test_all_six_welsh_lessons_load_without_duplicates() -> void:
	LangLessons.reset()
	var ids := _ids()
	assert_eq(ids.size(), 6)
	for n in ["cy_01", "cy_02", "cy_03", "cy_04", "cy_05", "cy_06"]:
		assert_true(n in ids, n)
	var seen := {}
	for w in LangLessons.words("cy"):
		assert_false(seen.has(str(w.id)), "duplicate word id " + str(w.id))
		seen[str(w.id)] = true

func test_welsh_lessons_validate() -> void:
	var zones := ZoneData.load_all()
	assert_eq(LangLessons.check(func(z): return zones.get(z), ZoneIndex.get_index()), [])

func test_sut_mae_and_plis_are_in_level_one() -> void:
	assert_eq(str(LangLessons.word("cy", "sut_mae").local), "Sut mae")
	assert_eq(str(LangLessons.word("cy", "sut_mae").lesson), "cy_01")
	assert_eq(str(LangLessons.word("cy", "plis").local), "Plîs")

func test_the_later_lessons_open_after_the_level_one_certificate() -> void:
	var d := GameStateData.new()
	assert_eq(str(LangLessons.next_lesson(d, "cy_03").get("id", "")), "", "level 2 is shut before the certificate")
	for id in ["cy_01", "cy_02"]:
		LangLessons.learn(d, id)
	assert_true(LangLessons.has_cert(d, "cy", 1))
	assert_eq(str(LangLessons.next_lesson(d, "cy_03").id), "cy_03")
	assert_eq(str(LangLessons.next_lesson(d, "cy_04").id), "cy_04")
	for id in ["cy_03", "cy_04"]:
		LangLessons.learn(d, id)
	assert_true(LangLessons.unlocked(d, "cy", 3))
	assert_eq(str(LangLessons.next_lesson(d, "cy_06").id), "cy_06")

func test_place_name_notes_use_the_standard_derivations() -> void:
	var pont := str(LangLessons.word("cy", "pont").note)
	assert_true(pont.contains("pont + cysyllte") and pont.contains("the joining"))
	var tre := str(LangLessons.word("cy", "tre").note)
	assert_true(tre.contains("Trefor") and tre.contains("personal name"))
	assert_false(tre.contains("fawr"))
