extends TestCase
## Words fit on the key screens at 1280x720: nothing cut off, spilling, overlapping, trimmed or below 18 px.
## Menus need running frames to lay out, which this runner doesn't have, so this runs tools/dev/text_audit.gd in a
## second headless Godot (about ten seconds). Run the lot with `godot --headless --path . -s res://tools/dev/text_audit.gd`.

const KEY_SCREENS := ["pause", "bag", "settings", "pedia:spikkin", "summary:0", "almanac", "travel:all", "stats:standing"]

func test_key_screens_fit_their_words() -> void:
	var out := []
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "res://tools/dev/text_audit.gd", "--"]
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(args + KEY_SCREENS), out, true)
	var log := "\n".join(out)
	var problems := Array(log.split("\n")).filter(func(l): return str(l).get_slice(" ", 0) in KEY_SCREENS)
	assert_false(log.contains("SCRIPT ERROR"), "the audit ran cleanly")
	assert_true(log.contains("text_audit: "), "the audit finished")
	assert_eq(code, 0, "no text problems on the key screens:\n" + "\n".join(problems))

func test_small_text_is_floored() -> void:
	var l := UIKit.label("x", 12)
	assert_true(l.get_theme_font_size("font_size") >= UIKit.MIN_TEXT, "no label under %d px" % UIKit.MIN_TEXT)
	assert_eq(UIKit.fit_size("MWMWMWMWMWMWMWMWMWMWMWMW", 100, 38, 12), UIKit.MIN_TEXT, "fit_size stops at the floor")
	l.free()

func test_fit_column_steps_down_then_closes_up() -> void:
	var col := VBoxContainer.new()
	col.size = Vector2(400, 0)
	col.add_theme_constant_override("separation", 10)
	var words := []
	for i in 6:
		var l := UIKit.label("Mendel worked this out with peas in a monastery garden. ".repeat(2), 24)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)
		words.append(l)
	UIKit.fit_column(col, 2000)
	assert_eq(words[0].get_theme_font_size("font_size"), 24, "room to spare: full size")
	UIKit.fit_column(col, 420)
	var fs: int = words[0].get_theme_font_size("font_size")
	assert_true(fs < 24 and fs >= UIKit.MIN_TEXT, "tight: steps down (%d)" % fs)
	UIKit.fit_column(col, 2000)
	assert_eq(words[0].get_theme_font_size("font_size"), 24, "refitting starts from the wanted size")
	UIKit.fit_column(col, 50)
	assert_eq(words[0].get_theme_font_size("font_size"), UIKit.MIN_TEXT, "never below the floor")
	assert_eq(col.get_theme_constant("separation"), 3, "and the gaps close up")
	col.free()
