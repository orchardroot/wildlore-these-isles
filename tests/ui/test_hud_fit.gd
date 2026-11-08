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

func test_a_long_toast_wraps_into_a_short_panel() -> void:
	var t := _toast("Standing", LONG)
	var s: Vector2 = t._panel.size
	assert_true(s.x <= ParishToast.MAX_W + 60.0, "wraps at its width (%d px)" % s.x)
	assert_true(s.y < 150.0, "two lines, not a word a line (%d px tall)" % s.y)
	assert_near(t._panel.offset_left, -s.x * 0.5, 0.5, "centred")
	t._head.text = "Saved"
	t._body.text = "Short"
	t.lay_out()
	assert_true(t._panel.size.x < 300.0, "a short line after a long one shrinks back (%d px)" % t._panel.size.x)
	t.free()
