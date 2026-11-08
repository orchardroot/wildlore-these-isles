extends TestCase
## On-screen prompts name the player's real buttons: default keys, a remapped key, and the pad.

const BASIC := [["confirm", "Choose"], ["cancel", "Back"]]

func test_default_keyboard() -> void:
	var b := InputSetup.defaults()
	assert_eq(InputSetup.hint_text(b, false, BASIC), "Z  Choose        X  Back")
	assert_eq(InputSetup.hint_text(b, false, [["updown", "Choose"], ["leftright", "Change"], ["menu", "Close"], ["run", "Filter"]]),
		"Up / Down  Choose        Left / Right  Change        Esc  Close        Shift  Filter")

func test_remapped_key_shows_the_new_name() -> void:
	var r := InputSetup.rebound(InputSetup.defaults(), "confirm", "key", KEY_E)
	assert_eq(r.error, "")
	assert_eq(InputSetup.hint_text(r.bindings, false, BASIC), "E  Choose        X  Back")
	var m := InputSetup.rebound(InputSetup.defaults(), "move_up", "key", KEY_I)
	assert_eq(InputSetup.hint_name(m.bindings, "updown", false), "I / Down")

func test_pad_mode_uses_pad_names() -> void:
	var b := InputSetup.defaults()
	assert_eq(InputSetup.hint_text(b, true, BASIC), "A  Choose        B  Back")
	assert_eq(InputSetup.hint_text(b, true, [["updown", "Browse"], ["shoulders", "Jump 10"], ["run", "Filter"], ["menu", "Close"]]),
		"D-pad Up / Down  Browse        LB / RB  Jump 10        X  Filter        Start  Close")
	var r := InputSetup.rebound(b, "confirm", "pad", JOY_BUTTON_LEFT_STICK)
	assert_eq(InputSetup.hint_text(r.bindings, true, BASIC), "L-Stick  Choose        B  Back")

func test_move_names_all_four_ways() -> void:
	var b := InputSetup.defaults()
	assert_eq(InputSetup.hint_name(b, "move", false), "Arrows")
	assert_eq(InputSetup.hint_name(b, "move", true), "D-pad")
	var m := InputSetup.rebound(b, "move_up", "key", KEY_I)
	assert_eq(InputSetup.hint_name(m.bindings, "move", false), "I / Left / Down / Right")

func test_device_only_entries_and_literals() -> void:
	var e := [["=Enter", "Done", "kbd"], ["cancel", "Delete", "pad"], ["confirm", "Pick"]]
	assert_eq(InputSetup.hint_text(InputSetup.defaults(), false, e), "Enter  Done        Z  Pick")
	assert_eq(InputSetup.hint_text(InputSetup.defaults(), true, e), "B  Delete        A  Pick")

func test_device_follows_the_last_input() -> void:
	var k := InputEventKey.new()
	var jb := InputEventJoypadButton.new()
	var drift := InputEventJoypadMotion.new()
	drift.axis_value = 0.1
	var push := InputEventJoypadMotion.new()
	push.axis_value = 0.9
	assert_eq(InputDevice.device_for(jb, false), true)
	assert_eq(InputDevice.device_for(k, true), false)
	assert_eq(InputDevice.device_for(drift, false), false, "stick drift is ignored")
	assert_eq(InputDevice.device_for(push, false), true)
	assert_eq(InputDevice.device_for(InputEventMouseMotion.new(), true), true, "mouse says nothing")

func test_plain_text_entries_have_no_trailing_gap() -> void:
	assert_eq(InputSetup.hint_text(InputSetup.defaults(), false, [["=Type a name", ""], ["=Enter", "Done"]]), "Type a name        Enter  Done")
