extends TestCase

func test_scale_steps_never_shrink() -> void:
	assert_eq(Access.scaled(20, "normal"), 20)
	assert_eq(Access.scaled(20, "large"), 25)
	assert_eq(Access.scaled(20, "largest"), 30)
	assert_eq(Access.scaled(20, "bogus"), 20)

func test_theme_takes_size_and_font() -> void:
	var t := Theme.new()
	Access.apply_theme(t, "largest", true)
	assert_eq(t.default_font_size, 42)
	assert_true(t.default_font != null)
	Access.apply_theme(t, "normal", false)
	assert_eq(t.default_font_size, 28)
	assert_true(t.default_font == null)

func test_settings_round_trip_and_bad_value() -> void:
	var saved := Settings.path
	Settings.path = "user://test_access.json"
	Settings.text_size = "large"
	Settings.readable_font = true
	Settings.save_settings()
	Settings.text_size = "normal"
	Settings.readable_font = false
	Settings.load_settings()
	assert_eq(Settings.text_size, "large")
	assert_true(Settings.readable_font)
	var f := FileAccess.open(Settings.path, FileAccess.WRITE)
	f.store_string('{"text_size": "huge"}')
	f.close()
	Settings.load_settings()
	assert_eq(Settings.text_size, "normal")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.path = saved
	Settings.text_size = "normal"
	Settings.readable_font = false
	Settings.apply_access()

func test_the_readable_font_outlives_the_first_load() -> void:
	# applied at startup, before any screen holds the theme: it used to be freed and come back plain
	Settings.readable_font = true
	Settings.apply_access()
	for i in 3:
		var l := Label.new()
		l.free()
	var th: Theme = load("res://ui/theme.tres")
	assert_true(th.has_default_font(), "the Readable font is still on the theme when a screen loads it")
	Settings.readable_font = false
	Settings.apply_access()
	assert_false((load("res://ui/theme.tres") as Theme).has_default_font(), "and off again")
