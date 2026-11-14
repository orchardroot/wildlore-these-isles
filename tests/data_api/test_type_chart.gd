extends TestCase

var chart := TypeChart.load_default()

func test_sixteen_types() -> void:
	assert_eq(chart.types.size(), 16)

func test_super_effective() -> void:
	assert_eq(chart.multiplier("hearth", "hedgerow"), 2.0)
	assert_eq(chart.multiplier("brook", "hearth"), 2.0)

func test_not_very_effective() -> void:
	assert_eq(chart.multiplier("hearth", "brook"), 0.5)

func test_no_effect() -> void:
	assert_eq(chart.multiplier("kin", "spirit"), 0.0)
	assert_eq(chart.multiplier("storm", "stone"), 0.0)

func test_unlisted_pair_is_neutral() -> void:
	assert_eq(chart.multiplier("kin", "kin"), 1.0)

func test_fae_fears_iron() -> void:
	assert_eq(chart.multiplier("iron", "fae"), 2.0)

func test_dual_types_multiply() -> void:
	assert_eq(chart.effectiveness("iron", ["fae", "frost"]), 4.0)
	assert_eq(chart.effectiveness("storm", ["brook", "stone"]), 0.0)
	assert_eq(chart.effectiveness("hearth", ["hedgerow", "brook"]), 1.0)

func test_typeless_move_is_neutral() -> void:
	assert_eq(chart.effectiveness("", ["hedgerow"]), 1.0)

func test_real_chart_is_valid() -> void:
	assert_eq(chart.validate(), [])

func test_validate_catches_unknown_type() -> void:
	var bad := TypeChart.from_dict({"types": ["a", "b"], "chart": {"a": {"se": ["zz"]}, "b": {"se": ["a"]}}})
	assert_true(bad.validate().size() > 0)

func test_validate_catches_type_with_no_weakness() -> void:
	var bad := TypeChart.from_dict({"types": ["a", "b"], "chart": {"a": {"se": ["a"]}, "b": {"se": ["a"]}}})
	assert_has(bad.validate(), "type 'b' has no weakness")

func test_xp_curves() -> void:
	assert_eq(Rules.xp_for_level("medium", 1), 0)
	assert_eq(Rules.xp_for_level("medium", 10), 1000)
	assert_eq(Rules.xp_for_level("fast", 10), 800)
	assert_eq(Rules.xp_for_level("slow", 10), 1250)

func test_weak_to_resists_immune_for_one_type() -> void:
	var weak := chart.weak_to(["hedgerow"])
	var ids: Array = weak.map(func(w): return w.type)
	for t in ["hearth", "frost", "gale"]:
		assert_true(t in ids, "%s beats hedgerow" % t)
	assert_true(weak.all(func(w): return w.mult == 2.0))
	assert_true(chart.resists(["hedgerow"]).any(func(w): return w.type == "brook"))
	assert_true(chart.immune(["spirit"]).any(func(w): return w.type == "kin"))

func test_dual_types_stack_and_cancel() -> void:
	var weak := chart.weak_to(["fae", "frost"])
	assert_eq(weak[0].type, "iron", "x4 comes first")
	assert_eq(weak[0].mult, 4.0)
	assert_false(chart.weak_to(["hedgerow", "brook"]).any(func(w): return w.type == "hearth"), "weak and resistant cancel out")
	assert_true(chart.immune(["brook", "stone"]).any(func(w): return w.type == "storm"), "an immunity beats the other type")
	assert_false(chart.resists(["brook", "stone"]).any(func(w): return w.type == "storm"), "and is not also a resist")

func test_move_type_rows_and_words() -> void:
	assert_eq(chart.strong_against("hearth"), ["hedgerow", "frost", "iron"].filter(func(t): return t in chart.strong_against("hearth")))
	assert_true("hedgerow" in chart.strong_against("hearth"))
	assert_true("brook" in chart.weak_against("hearth"))
	assert_true("spirit" in chart.no_effect_on("kin"))
	assert_eq(TypeChart.mult_words(4.0), "x4")
	assert_eq(TypeChart.mult_words(2.0), "x2")
	assert_eq(TypeChart.mult_words(0.5), "x1/2")
	assert_eq(TypeChart.mult_words(0.25), "x1/4")
	assert_eq(TypeChart.mult_words(0.0), "No effect")
	assert_eq(TypeChart.mult_words(1.0), "x1")
