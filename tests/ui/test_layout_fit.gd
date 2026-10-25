extends TestCase
## Menus fit their frame at 1280x720: the pause list sizes its rows to its panel and long names shrink instead of
## widening a panel. (Whole-menu layout needs running frames, which this runner doesn't have: that check is the
## `--audit` screenshot switch, see core/layout_audit.gd.)

func test_row_height_shares_the_panel_and_stays_in_bounds() -> void:
	assert_eq(MenuLogic.row_height(560, 9, 8, 44, 66), 55, "nine rows share 560px")
	assert_eq(MenuLogic.row_height(560, 5, 8, 44, 66), 66, "a short list keeps its tall rows")
	assert_eq(MenuLogic.row_height(300, 9, 8, 44, 66), 44, "never smaller than a readable row")
	assert_eq(MenuLogic.row_height(560, 0, 8, 44, 66), 66, "an empty list is harmless")
	for n in range(1, 12):  # up to eleven rows (Wardrobe and Ark both in), at the pause menu's gap and minimum
		var h := MenuLogic.row_height(531, n, 4, 42, 66)
		assert_true(h * n + 4 * (n - 1) <= 531, "%d rows fit" % n)

func test_pause_entries_always_end_with_close() -> void:
	assert_eq(MenuLogic.pause_entries(false), ["Team", "Fieldbook", "Bag", "Wardrobe", "Journal", "Almanac", "Map", "Save", "Settings", "Close"])
	assert_eq(MenuLogic.pause_entries(true), ["Team", "Fieldbook", "Bag", "Wardrobe", "Ark", "Journal", "Almanac", "Map", "Save", "Settings", "Close"])

func test_fit_size_shrinks_long_text_only() -> void:
	assert_eq(UIKit.fit_size("Spikkin", 300, 38, 24), 38)
	var s := UIKit.fit_size("MWMWMWMWMWMW", 300, 38, 24)
	assert_true(s < 38 and s >= 24, "a wide nickname shrinks (%d)" % s)
	assert_eq(UIKit.fit_size("MWMWMWMWMWMWMWMWMWMWMWMW", 100, 38, 24), 24, "but no smaller than the floor")

func test_fit_block_shrinks_then_drops_optional_lines() -> void:
	var box := Control.new()
	box.size = Vector2(400, 300)
	var body := Label.new()
	body.text = "Snuffles along hedge bottoms at dusk, grumbling to itself."
	var fact := Label.new()
	fact.text = "A hedgehog has around 5,000 to 7,000 spines."
	var words := [[body, 0], [fact, -2, true]]
	UIKit.fit_block(words, box, [25, 21, 17])
	assert_eq(body.get_theme_font_size("font_size"), 25, "short words keep the biggest size")
	assert_true(fact.visible, "and the optional line")
	body.text = "Snuffles along hedge bottoms at dusk. ".repeat(7)
	box.size = Vector2(400, 260)
	UIKit.fit_block(words, box, [25, 21, 17])
	assert_true(body.get_theme_font_size("font_size") <= 21, "long words step down (%d)" % body.get_theme_font_size("font_size"))
	box.size = Vector2(400, 200)
	UIKit.fit_block(words, box, [25, 21, 17])
	assert_false(fact.visible, "too long even at the smallest: the optional line goes first")
	assert_true(body.visible, "never the main text")
	for n in [body, fact, box]:
		n.free()
