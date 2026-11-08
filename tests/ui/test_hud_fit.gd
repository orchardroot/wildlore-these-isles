extends TestCase
## The overworld HUD at 1280x720: toasts, the zone card, the route chip and the place chip keep to their own corners.

const LONG := "Someone in England has noticed you. Help out and they'll count you as one of their own."

func _toast(head: String, body: String) -> ParishToast:
	var t := ParishToast.new()
	t._ready()
	t._head.text = head
	t._body.text = body
	t.lay_out()
	return t

func _lines(l: Label, w: float) -> int:
	var f := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	return roundi(f.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, w, fs).y / f.get_height(fs))

func test_a_long_toast_wraps_into_a_short_panel() -> void:
	var t := _toast("Standing", LONG)
	var s: Vector2 = t._panel.size
	assert_true(s.x <= ParishToast.MAX_W + 60.0, "wraps at its width (%d px)" % s.x)
	assert_eq(_lines(t._body, t._body.size.x), 2, "two lines")
	assert_true(s.y < 150.0, "two lines, not a word a line (%d px tall)" % s.y)
	assert_near(t._panel.offset_left, -s.x * 0.5, 0.5, "centred")
	t._head.text = "Saved"
	t._body.text = "Short"
	t.lay_out()
	assert_true(t._panel.size.x < 300.0, "a short line after a long one shrinks back (%d px)" % t._panel.size.x)
	t.free()

func test_route_chip_steps_below_a_box_that_reaches_it() -> void:
	var chip := Rect2(RouteChip.MARGIN, Vector2(420, 48))
	assert_eq(RouteChip.clear_y(chip, Rect2()), RouteChip.MARGIN.y, "nothing up: its usual place")
	assert_eq(RouteChip.clear_y(chip, Rect2(560, 22, 300, 100)), RouteChip.MARGIN.y, "a narrow card leaves it be")
	assert_eq(RouteChip.clear_y(chip, Rect2(300, 36, 680, 150)), 186.0 + RouteChip.GAP, "a wide card: just below it")
	assert_eq(RouteChip.clear_y(chip, Rect2(300, 22, 680, 80)), RouteChip.MARGIN.y, "a short box ending above it")

func test_wrapped_lines_come_out_even() -> void:
	var t := _toast("Quest complete", "Does the Archaeologist's House Route Still Run? And another few words")
	var w := ParishToast.wrap_width(t._body)
	assert_true(w < ParishToast.MAX_W, "narrower than the most it may take (%d px)" % w)
	assert_eq(_lines(t._body, w), _lines(t._body, ParishToast.MAX_W), "no more lines than at full width")
	t.free()
