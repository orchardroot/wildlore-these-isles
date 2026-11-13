extends TestCase
## The type chart page, the shared weak/resists rows, the switch menu's verdicts and the places the chart is linked.

func test_scope_round_trips() -> void:
	var arg := TypeChartScreen.scope_arg([{"name": "Holtling", "types": ["brook", "kin"]}], [{"name": "Kindlet", "types": ["hearth"]}])
	assert_eq(arg, "Holtling=brook+kin;Kindlet=hearth")
	var back := TypeChartScreen.parse_scope(arg)
	assert_eq(back.size(), 2)
	assert_eq(back[0].name, "Holtling")
	assert_eq(back[0].types, ["brook", "kin"])
	assert_eq(TypeChartScreen.parse_scope(""), [], "no argument, the plain chart")
	assert_eq(TypeChartScreen.parse_scope("Odd=").size(), 0, "a creature with no types is skipped")
	var odd := TypeChartScreen.scope_arg([{"name": "A;B=C", "types": ["kin"]}], [])
	assert_eq(TypeChartScreen.parse_scope(odd).size(), 1, "a nickname can't break the argument")

func test_chart_is_linked_from_almanac_pause_and_router() -> void:
	assert_true(Almanac.pages(GameStateData.new()).any(func(p): return p.id == "typechart" and p.menu == "typechart"), "always in the Almanac")
	assert_true(MenuLogic.pause_entries(false).has("Types"))
	assert_true(MenuLogic.pause_entries(true).has("Types"))
	assert_true(load("res://core/scene_router.gd").MENUS.has("typechart"))
	assert_true(Intros.TEXT.has("types") and Intros.TEXT.has("typechart"))
	assert_true(ResourceLoader.exists("res://ui/type_chart_screen.tscn"))

func test_type_rows_match_the_chart() -> void:
	var chart := Fixtures.chart()
	var rows := TypeRows.rows_for(["fae", "frost"], chart)
	var weak: Dictionary = rows[0]
	assert_eq(weak.key, "weak")
	assert_eq(weak.items[0].type, "iron", "the x4 leads")
	assert_eq(weak.items[0].mult, 4.0)
	assert_eq(TypeRows.rows_for(["kin"], chart).map(func(r): return r.key), ["weak", "resists", "immune"].filter(func(k): return TypeRows.rows_for(["kin"], chart).any(func(r): return r.key == k)))
	assert_true(TypeRows.rows_for(["spirit"], chart).any(func(r): return r.key == "immune"), "No effect from, when something can't touch it")
	assert_false(TypeRows.rows_for(["hedgerow"], chart).any(func(r): return r.key == "immune"), "an empty row is left out")

func test_every_species_has_a_row_to_show() -> void:
	var chart := Fixtures.chart()
	for id in Fixtures.dex().ids():
		var t: Array = Fixtures.dex().get_species(id).get("types", [])
		assert_false(TypeRows.rows_for(t, chart).is_empty(), "%s has something to say" % id)

func test_switch_menu_verdicts() -> void:
	var chart := Fixtures.chart()
	var moves := Fixtures.moves()
	var me := Fixtures.creature("kindlet", 10)  # Hearth, with Hearth and Kin moves
	var brook_foe := [{"name": "Wet", "types": ["brook"]}]
	var hedge_foe := [{"name": "Prickly", "types": ["hedgerow"]}]
	var vs_brook := MoveText.suit_defence(me, brook_foe, chart)
	assert_eq(vs_brook.words, "Weak to it", "Brook beats Hearth")
	assert_eq(vs_brook.kind, "dn1")
	assert_eq(MoveText.suit_attack(me, hedge_foe, moves, chart).words, "Hits hard", "Hearth beats Hedgerow")
	assert_eq(MoveText.suit_attack(me, brook_foe, moves, chart).words, "Hits evenly", "its Kin moves are the best it has against Brook")
	assert_eq(MoveText.suit_defence(me, hedge_foe, chart).words, "Resists it", "Hedgerow does little to Hearth")
	assert_eq(MoveText.suits(me, [], moves, chart), [], "no foe, no verdict")
	assert_eq(MoveText.suits(me, brook_foe, moves, chart).size(), 2)
	for m in me.moves:
		m.pp = 0
	assert_eq(MoveText.suit_attack(me, brook_foe, moves, chart).words, "No attack moves", "out of PP counts")

func test_effect_marks_have_shapes_for_every_kind() -> void:
	for k in ["up1", "up2", "even", "dn1", "dn2", "none"]:
		assert_false(EffectMark.polygons(k).is_empty(), k)
		assert_eq(EffectMark.count(k), 2 if k in ["up2", "dn2"] else 1)
	assert_true(EffectMark.polygons("up1") != EffectMark.polygons("dn1"), "up and down are different shapes, not different colours")
	assert_true(EffectMark.polygons("none") != EffectMark.polygons("even"))

func test_kit_uses_the_games_type_names() -> void:
	var f := FileAccess.open("res://data/dialogue/macc_fieldstation.json", FileAccess.READ)
	var text := f.get_as_text()
	assert_false(text.contains("Fire beats"), "Hearth, not Fire")
	assert_false(text.contains("Water beats"), "Brook, not Water")
	assert_true(text.contains("Hearth beats Hedgerow") and text.contains("Brook beats Hearth"))

func test_starter_triangle_is_the_real_chart() -> void:
	var chart := Fixtures.chart()
	assert_eq(chart.multiplier("hearth", "hedgerow"), 2.0)
	assert_eq(chart.multiplier("hedgerow", "brook"), 2.0)
	assert_eq(chart.multiplier("brook", "hearth"), 2.0)
