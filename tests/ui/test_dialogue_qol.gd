extends TestCase

func _box(st: int) -> DialogueBox:
	var b := DialogueBox.new()
	b._ready()
	b._total = 20
	b.state = st
	return b

func test_cancel_advances_a_finished_line() -> void:
	var b := _box(DialogueBox.State.WAIT)
	var hit := [0]
	b._advanced.connect(func(): hit[0] += 1)
	b._tick(0.016, false, false, false)
	assert_eq(hit[0], 0, "nothing without input")
	b._tick(0.016, false, true, false)
	assert_eq(hit[0], 1, "cancel advances")
	assert_eq(b.state, DialogueBox.State.IDLE)
	b.free()

func test_cancel_does_not_skip_typing() -> void:
	var b := _box(DialogueBox.State.TYPING)
	b._label.text = "x".repeat(20)
	b._tick(0.0, false, true, false)
	assert_eq(b.state, DialogueBox.State.TYPING)
	b.free()

func test_holding_confirm_types_faster() -> void:
	var a := _box(DialogueBox.State.TYPING)
	var h := _box(DialogueBox.State.TYPING)
	a._tick(0.1, false, false, false)
	h._tick(0.1, false, false, true)
	assert_true(h._typed > a._typed * 2.0, "held confirm fast-forwards")
	a.free()
	h.free()

func test_decline_index_only_for_polite_declines() -> void:
	assert_eq(DialogueBox.decline_index(["Heal my team", "Open the Ark", "Just looking"]), 2)
	assert_eq(DialogueBox.decline_index(["Yes, a rematch", "Not today"]), 1)
	assert_eq(DialogueBox.decline_index(["Five", "Six", "Seven", "Eight"]), -1, "quiz answers are never auto-picked")
	assert_eq(DialogueBox.decline_index(["Roam anyway", "Ask about the fog"]), -1)

func test_cancel_in_choice_picks_decline() -> void:
	var b := _box(DialogueBox.State.CHOOSING)
	b._fill_choices(["Heal", "Just looking"])
	b._decline = DialogueBox.decline_index(["Heal", "Just looking"])
	var got := [-1]
	b._chosen.connect(func(i): got[0] = i)
	b._tick(0.016, false, true, false)
	assert_eq(got[0], 1)
	b.free()

func test_choices_stand_above_the_box_and_clear_of_the_speaker() -> void:
	# a four-line page grows the box up to y 472: the list sits above that, not at the three-line height
	assert_eq(DialogueBox.choice_bottom(472.0, Rect2(), 700.0), 472.0 - DialogueBox.CHOICE_GAP)
	var tab := Rect2(76, 431, 220, 47)
	assert_eq(DialogueBox.choice_bottom(472.0, tab, 700.0), 472.0 - DialogueBox.CHOICE_GAP, "a short list keeps right of the tab")
	assert_eq(DialogueBox.choice_bottom(472.0, tab, 200.0), 431.0 - DialogueBox.CHOICE_GAP, "a wide one goes over it")

func test_a_long_choice_list_scrolls() -> void:
	assert_eq(DialogueBox.choice_window(4, 3, 6, 0), 0, "all fit: no scrolling")
	assert_eq(DialogueBox.choice_window(14, 0, 7, 0), 0)
	assert_eq(DialogueBox.choice_window(14, 7, 7, 0), 1, "down past the last row moves the window one")
	assert_eq(DialogueBox.choice_window(14, 13, 7, 1), 7, "wrapping to the end shows the end")
	assert_eq(DialogueBox.choice_window(14, 3, 7, 7), 3, "up past the first row moves it back")
	var f := ThemeDB.fallback_font
	var rows := DialogueBox.choice_rows(720.0, f, 28, 30, 26)
	assert_true(rows >= 5 and rows < 14, "a sensible number fit at 1280x720 (%d)" % rows)
	assert_true(DialogueBox.choice_rows(720.0, f, 35, 38, 33) < rows, "fewer at Large text")

func test_choices_show_a_window_with_more_arrows() -> void:
	var b := DialogueBox.new()
	b._ready()
	var opts := []
	for i in 14:
		opts.append("Town %d" % i)
	b._fill_choices(opts)
	var shown := b._choice_labels.filter(func(l): return l.visible).size()
	assert_eq(shown, b._rows, "only the window shows")
	assert_true(b._rows < 14 and b._more_down.visible, "with arrows")
	for i in 13:
		b._choice_index = i + 1
		b._refresh_choices()
	assert_true(b._choice_labels[13].visible and not b._choice_labels[0].visible, "scrolled to the end")
	b._fill_choices(["Yes", "No"])
	assert_false(b._more_up.visible, "a short list after a long one: no arrows")
	assert_true(is_instance_valid(b._more_up), "the arrows survive a refill")
	b.free()
