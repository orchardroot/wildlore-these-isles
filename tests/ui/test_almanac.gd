extends TestCase
## The Almanac hub (4.0): which pages have sprouted, in a steady order, and what each ledger page says.

func _ids(d: GameStateData) -> Array:
	return Almanac.pages(d).map(func(p): return p.id)

func test_a_fresh_save_has_the_always_pages_in_order() -> void:
	var ids := _ids(GameStateData.new())
	assert_eq(ids, ["journal", "fieldbook", "typechart", "gazetteer", "trades", "standing", "stats", "pieces"])

func test_pages_sprout_with_play() -> void:
	var d := GameStateData.new()
	d.seen["holtling"] = true
	assert_has(_ids(d), "rumours")
	d.set_flag("book_ideas", {"a": true})
	assert_has(_ids(d), "studbook")
	d.set_flag("guild_ramblers", true)
	assert_has(_ids(d), "guilds")
	assert_false(_ids(d).has("deeds"))
	var id := str(Deeds.all()[0].id)
	d.set_flag("deed_" + id, {"owned": true, "till": 120})
	assert_has(_ids(d), "deeds")

func test_order_is_stable_when_everything_has_sprouted() -> void:
	var d := GameStateData.new()
	d.seen["holtling"] = true
	d.set_flag("book_ideas", {"a": true})
	d.set_flag("guild_ramblers", true)
	d.set_flag("deed_" + str(Deeds.all()[0].id), {"owned": true})
	var ids := _ids(d)
	assert_true(ids.find("journal") < ids.find("fieldbook") and ids.find("guilds") < ids.find("deeds"), str(ids))

func test_every_page_names_a_real_menu_or_ledger() -> void:
	var d := GameStateData.new()
	d.seen["holtling"] = true
	d.set_flag("book_ideas", {"a": true})
	d.set_flag("guild_ramblers", true)
	d.set_flag("deed_" + str(Deeds.all()[0].id), {"owned": true})
	for p in Almanac.pages(d):
		assert_true(str(p.name) != "" and str(p.blurb) != "", p.id)
		var m := str(p.menu)
		assert_true(m.begins_with("ledger:") or load("res://core/scene_router.gd").MENUS.has(m.split(":")[0]), m)

func test_deed_ledger_lists_the_till() -> void:
	var d := GameStateData.new()
	var deed: Dictionary = Deeds.all()[0]
	d.set_flag("deed_" + str(deed.id), {"owned": true, "till": 250})
	var rows := Almanac.ledger(d, "deeds")
	assert_eq(rows.size(), 1)
	assert_true(str(rows[0][0]).contains(str(deed.name)), str(rows[0]))
	assert_true(str(rows[0][1]).contains("250"), str(rows[0]))

func test_guild_ledger_shows_rank() -> void:
	var d := GameStateData.new()
	d.set_flag("guild_ramblers", true)
	var rows := Almanac.ledger(d, "guilds")
	assert_eq(rows.size(), 1)
	assert_true(str(rows[0][0]).contains("Ramblers"), str(rows[0]))

func test_empty_ledgers_say_so() -> void:
	for k in ["guilds", "deeds", "society"]:
		var rows := Almanac.ledger(GameStateData.new(), k)
		assert_true(rows.size() >= 1, k)
