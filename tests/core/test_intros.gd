extends TestCase
## First-time introductions (4.0): each card appears once, only with Hints on, and old saves have none seen.

func test_first_time_gives_text_then_nothing() -> void:
	var d := GameStateData.new()
	var t := Intros.take(d, "bag", true)
	assert_true(t != "")
	assert_eq(Intros.take(d, "bag", true), "")

func test_hints_off_shows_nothing_and_stays_unseen() -> void:
	var d := GameStateData.new()
	assert_eq(Intros.take(d, "bag", false), "")
	assert_true(Intros.take(d, "bag", true) != "", "turning hints on later still shows it")

func test_unknown_ids_are_quiet() -> void:
	assert_eq(Intros.take(GameStateData.new(), "nonsense", true), "")

func test_cards_are_short_and_plain() -> void:
	for id in Intros.TEXT:
		var s := str(Intros.TEXT[id])
		assert_true(s.length() <= 130, id + ": too long")
		assert_false(s.contains("—"), id + ": em-dash")

func test_every_menu_card_maps_to_text() -> void:
	for m in Intros.MENUS:
		assert_true(Intros.TEXT.has(Intros.MENUS[m]), m)
		assert_true(load("res://core/scene_router.gd").MENUS.has(m), m)

func test_hints_setting_defaults_on() -> void:
	var s: Node = load("res://core/settings.gd").new()
	s.path = "user://__no_such_settings.json"
	s.load_settings()
	assert_true(s.hints)
	s.free()

func test_boat_cards_once_each_and_only_on_water() -> void:
	var d := GameStateData.new()
	assert_eq(Intros.boat_card(d, "grass", true), "")
	assert_eq(Intros.boat_card(d, "deep_water", true), "")
	assert_true(Intros.boat_card(d, "water", true).contains("coracle"))
	assert_eq(Intros.boat_card(d, "water", true), "")
	assert_true(Intros.boat_card(d, "sea", true).contains("Tide Stone"))
	assert_eq(Intros.boat_card(d, "sea", true), "")
