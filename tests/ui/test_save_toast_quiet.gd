extends TestCase
## Autosaves write every time but only say "Saved" once a minute.

func test_first_autosave_shows() -> void:
	assert_true(SaveToast.due(-SaveToast.QUIET_MSEC, 0))

func test_quick_second_one_is_quiet() -> void:
	assert_false(SaveToast.due(1000, 21000))

func test_shows_again_after_a_minute() -> void:
	assert_true(SaveToast.due(1000, 1000 + SaveToast.QUIET_MSEC))
