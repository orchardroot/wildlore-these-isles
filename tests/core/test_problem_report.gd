extends TestCase
## The report key's report: folder names, the battle and dialogue snapshot, and what lands on disk.

const TMP := "user://test_reports"

func _wipe(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_wipe(dir.path_join(sub))
	for f in d.get_files():
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)

func test_folder_name_sorts_by_time() -> void:
	var n := ProblemReport.folder_name({"year": 2026, "month": 11, "day": 8, "hour": 9, "minute": 5, "second": 3})
	assert_eq(n, "2026-11-08_09-05-03")

func test_a_taken_folder_gets_a_suffix() -> void:
	_wipe(TMP)
	var dt := {"year": 2026, "month": 11, "day": 8, "hour": 9, "minute": 5, "second": 3}
	var first := ProblemReport.new_folder(TMP, dt)
	assert_eq(first, TMP.path_join("2026-11-08_09-05-03"))
	DirAccess.make_dir_recursive_absolute(first)
	assert_eq(ProblemReport.new_folder(TMP, dt), TMP.path_join("2026-11-08_09-05-03_2"))
	_wipe(TMP)

func test_creature_brief_has_species_and_hp() -> void:
	var c := Fixtures.creature("kindlet", 10)
	c.hp = 7
	var b := ProblemReport.creature_brief(c)
	assert_eq(b.species, "kindlet")
	assert_eq(b.level, 10)
	assert_eq(b.hp, 7)
	assert_eq(b.max_hp, c.max_hp())
	assert_eq(b.status, "")

func test_battle_brief_covers_both_sides_and_the_last_lines() -> void:
	var mine := [Fixtures.creature("spikkin", 10), Fixtures.creature("holtling", 9)]
	var b := Fixtures.battle(mine, [Fixtures.creature("kindlet", 8)], {"weather": "rain"})
	var lines := []
	for i in 10:
		lines.append("line %d" % i)
	var r := ProblemReport.battle_brief(b, lines)
	assert_eq(r.kind, "wild")
	assert_eq(r.weather, "rain")
	assert_eq(r.player.size(), 2)
	assert_eq(r.player[0].species, "spikkin")
	assert_true(r.player[0].out, "the lead is out")
	assert_false(r.player[1].out, "the bench isn't")
	assert_eq(r.foe[0].species, "kindlet")
	assert_eq(r.log.size(), ProblemReport.LOG_LINES)
	assert_eq(r.log[r.log.size() - 1], "line 9")

func test_menu_names_map_scene_files_back_to_router_names() -> void:
	var menus := {"pause": "res://ui/pause_menu.tscn", "settings": "res://ui/settings_screen.tscn"}
	var names := ProblemReport.menu_names(["res://ui/pause_menu.tscn", "res://ui/settings_screen.tscn", "res://ui/odd.tscn"], menus)
	assert_eq(names, ["pause", "settings", "odd"])

func test_shown_text_is_only_what_has_typed_out() -> void:
	assert_eq(ProblemReport.shown_text("Hello there", -1), "Hello there")
	assert_eq(ProblemReport.shown_text("Hello there", 5), "Hello")
	assert_eq(ProblemReport.shown_text("Hello", 0), "")

func test_play_time_reads_as_hours_minutes_seconds() -> void:
	assert_eq(ProblemReport.play_time(3725.6), "1h 02m 05s")
	assert_eq(ProblemReport.play_time(0.0), "0h 00m 00s")

func test_info_fills_gaps_and_keeps_known_facts() -> void:
	var i := ProblemReport.info({"version": "5.2.1", "zone": "york", "tile": Vector2i(4, 9), "clock": 13 * 60 + 5, "play_seconds": 61.0, "junk": 1})
	assert_eq(i.version, "5.2.1")
	assert_eq(i.zone, "york")
	assert_eq(i.tile, [4, 9], "a tile is a plain pair in JSON")
	assert_eq(i.clock, "13:05")
	assert_eq(i.time_of_day, "day")
	assert_eq(i.play_time, "0h 01m 01s")
	assert_eq(i.battle, null)
	assert_eq(i.note, "")
	assert_false(i.has("junk"), "only the known fields")
	assert_true(i.has("menus") and i.has("dialogue") and i.has("weather"))

func test_note_is_one_tidy_line() -> void:
	assert_eq(ProblemReport.tidy_note("  stuck\non a fence  "), "stuck on a fence")
	assert_eq(ProblemReport.tidy_note("x".repeat(500)).length(), ProblemReport.NOTE_MAX)

func test_write_puts_three_files_in_the_folder_and_a_note_after() -> void:
	_wipe(TMP)
	var dir := TMP.path_join("r1")
	var img := Image.create(8, 6, false, Image.FORMAT_RGB8)
	var save := {"player_name": "Sam", "_scratch": 1}
	assert_eq(ProblemReport.write(dir, ProblemReport.info({"zone": "york"}), save, img), OK)
	assert_true(FileAccess.file_exists(dir.path_join("shot.png")))
	var info = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("info.json")))
	assert_eq(info.zone, "york")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("save.json")))
	assert_eq(saved.player_name, "Sam")
	assert_false(saved.has("_scratch"), "the same payload the save system writes")
	assert_eq(int(saved.version), SaveSystem.VERSION)
	assert_eq(ProblemReport.add_note(dir, "the fence"), OK)
	info = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("info.json")))
	assert_eq(info.note, "the fence")
	assert_eq(info.zone, "york", "the rest is kept")
	_wipe(TMP)

func test_write_without_a_picture_still_writes_the_facts() -> void:
	_wipe(TMP)
	var dir := TMP.path_join("r2")
	assert_eq(ProblemReport.write(dir, ProblemReport.info({}), {}, null), OK)
	assert_false(FileAccess.file_exists(dir.path_join("shot.png")))
	assert_true(FileAccess.file_exists(dir.path_join("info.json")))
	_wipe(TMP)
