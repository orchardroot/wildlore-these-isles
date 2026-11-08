extends TestCase
## The report key (F9): bound like any other action, with no pad button unless the player gives it one.

func test_report_action_is_f9_and_has_no_pad_button() -> void:
	assert_true("report" in InputSetup.ACTIONS)
	var d := InputSetup.defaults()
	assert_eq(d.report.key, [KEY_F9])
	assert_eq(d.report.pad, [])
	assert_eq(InputSetup.describe(d, "report", "pad"), "-")

func test_an_empty_pad_report_survives_sanitise() -> void:
	var d := InputSetup.defaults()
	assert_eq(InputSetup.sanitise(JSON.parse_string(JSON.stringify(d))), d, "the empty pad list doesn't throw the pad back to defaults")
	d.run.pad = [JOY_BUTTON_LEFT_SHOULDER]
	assert_eq(InputSetup.sanitise(JSON.parse_string(JSON.stringify(d))).run.pad, [JOY_BUTTON_LEFT_SHOULDER])

func test_old_settings_without_report_get_f9() -> void:
	var b := InputSetup.sanitise({"run": {"key": [KEY_Q], "pad": [JOY_BUTTON_X]}})
	assert_eq(b.report.key, [KEY_F9])
	assert_eq(b.run.key, [KEY_Q])

func test_report_can_take_and_lose_a_pad_button() -> void:
	var r := InputSetup.rebound(InputSetup.defaults(), "report", "pad", JOY_BUTTON_LEFT_SHOULDER)
	assert_eq(r.error, "")
	assert_eq(r.bindings.report.pad, [JOY_BUTTON_LEFT_SHOULDER])
	var back := InputSetup.rebound(r.bindings, "bike", "pad", JOY_BUTTON_LEFT_SHOULDER)
	assert_eq(back.error, "", "taking report's only pad button is fine: it may have none")
	assert_eq(back.bindings.report.pad, [])
	assert_eq(InputSetup.sanitise(JSON.parse_string(JSON.stringify(r.bindings))), r.bindings)

func test_report_key_cannot_be_left_empty() -> void:
	var r := InputSetup.rebound(InputSetup.defaults(), "photo", "key", KEY_F9)
	assert_true(r.error != "", "the keyboard keeps a report key")
