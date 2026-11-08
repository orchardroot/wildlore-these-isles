extends TestCase
## Words fit on the key screens at 1280x720: nothing cut off, spilling, overlapping, trimmed or below 18 px.
## Menus need running frames to lay out, which this runner doesn't have, so this runs tools/dev/text_audit.gd in a
## second headless Godot (about ten seconds). Run the lot with `godot --headless --path . -s res://tools/dev/text_audit.gd`.

const KEY_SCREENS := ["pause", "bag", "settings", "pedia:spikkin", "summary:0", "almanac", "travel:all", "stats:standing"]
## The ones that were worst with Large text (and the Readable font, which is wider).
const LARGE_SCREENS := ["summary:0", "races:dev", "exchange:london", "map:route"]

func test_key_screens_fit_their_words() -> void:
	_audit(KEY_SCREENS, [], "the key screens")

func test_worst_screens_fit_with_large_text_and_the_readable_font() -> void:
	_audit(LARGE_SCREENS, ["--text=large", "--readable"], "Large text")

func _audit(screens: Array, flags: Array, what: String) -> void:
	var out := []
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "res://tools/dev/text_audit.gd", "--"]
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(args + screens + flags), out, true)
	var log := "\n".join(out)
	var problems := Array(log.split("\n")).filter(func(l): return str(l).get_slice(" ", 0) in screens)
	assert_false(log.contains("SCRIPT ERROR"), "the audit ran cleanly (%s)" % what)
	assert_true(log.contains("text_audit: "), "the audit finished (%s)" % what)
	assert_eq(code, 0, "no text problems on %s:\n%s" % [what, "\n".join(problems)])

func test_fitted_names_allow_for_large_text() -> void:
	var was := Settings.text_size
	Settings.text_size = "large"
	var l := UIKit.fit_label("MWMWMWMWMWMW", 220, 24, 18)
	var fs := l.get_theme_font_size("font_size")
	assert_true(UIKit.font().get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= 220, "fits its width at the drawn size (%d)" % fs)
	assert_eq(UIKit.fit_scaled("Spikkin", 400, 24, 18), 30, "a short name gets the full Large size")
	assert_eq(UIKit.sized(24), 30, "nominal sizes scale like UIKit.label")
	l.free()
	Settings.text_size = was

func test_readable_font_stays_on_the_shared_theme() -> void:
	var was: bool = Settings.readable_font
	Settings.readable_font = true
	Settings.apply_access()
	assert_eq(UIKit.font().resource_path, Access.FONT_PATH, "UIKit measures with the Readable font")
	assert_eq((load("res://ui/theme.tres") as Theme).default_font, UIKit.font(), "and a later load of the theme still has it")
	Settings.readable_font = was
	Settings.apply_access()
	assert_true(UIKit.font() == ThemeDB.fallback_font, "back to the default font")

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
