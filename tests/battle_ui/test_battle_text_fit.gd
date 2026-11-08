extends TestCase
## Battle text fits where it is drawn: the message box never grows off the bottom of the screen, and a picker
## opened over it doesn't sit on the words.

func _font() -> Font:
	return ThemeDB.fallback_font

func test_a_short_line_keeps_the_usual_size() -> void:
	assert_eq(BattleMessage.size_for("Puffkin used Gust!", _font()), BattleMessage.SIZES[0])

func test_a_long_line_gets_smaller_rather_than_taller_than_the_box() -> void:
	var line := "MWMWMWMWMWMW's Hedgerow Tangle wrapped round the wild Puffkin and squeezed. It's super effective, and it will be stuck for a few turns, unable to switch out of the battle."
	var fs := BattleMessage.size_for(line, _font())
	assert_true(fs < BattleMessage.SIZES[0], "smaller (%d)" % fs)
	assert_true(_font().get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, BattleMessage.WIDTH, fs).y <= BattleMessage.ROOM)

func test_words_keep_left_of_a_picker_over_the_box() -> void:
	var m := BattleMessage.new()
	m.position = Vector2(24, 566)
	m.size = Vector2(1232, 134)
	m.label = Label.new()
	m.add_child(m.label)
	m.label.text = "What will MWMWMWMWMWMW do?"
	m.make_room(Rect2(470, 528, 786, 176))  # the move menu
	var room := m.label.custom_minimum_size.x
	assert_true(room > 0.0 and 24.0 + 16.0 + room < 470.0, "the words end before the menu (%d)" % room)
	var fs := m.label.get_theme_font_size("font_size")
	assert_true(_font().get_multiline_string_size(m.label.text, HORIZONTAL_ALIGNMENT_LEFT, room, fs).y <= BattleMessage.ROOM)
	m.make_room(Rect2())
	assert_eq(m.label.custom_minimum_size.x, 0.0, "the whole box again once it closes")
	m.free()
