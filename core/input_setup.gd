class_name InputSetup
extends RefCounted
## Registers the game's input actions in code (keyboard and gamepad), so project.godot stays readable.
## The bindings are data: `defaults()` gives the factory set, Settings stores the player's and calls `apply`.

const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "confirm", "cancel", "menu", "run", "bike", "fly", "photo", "report"]
const LABELS := {
	"move_up": "Move up", "move_down": "Move down", "move_left": "Move left", "move_right": "Move right",
	"confirm": "Confirm", "cancel": "Cancel", "menu": "Menu", "run": "Run", "bike": "Bike", "fly": "Fly", "photo": "Photo mode", "report": "Report a problem",
}
## Actions that may have no button on a device (the report key has no pad button until the player gives it one).
const OPTIONAL := {"report": ["pad"]}
## Confirm and cancel can never be left empty or share a button, or menus become impossible to use.
const ESSENTIAL := ["confirm", "cancel"]
const KEYS := {
	"move_up": [KEY_UP, KEY_W], "move_down": [KEY_DOWN, KEY_S],
	"move_left": [KEY_LEFT, KEY_A], "move_right": [KEY_RIGHT, KEY_D],
	"confirm": [KEY_Z, KEY_ENTER, KEY_SPACE], "cancel": [KEY_X, KEY_BACKSPACE],
	"menu": [KEY_ESCAPE, KEY_TAB], "run": [KEY_SHIFT], "bike": [KEY_B], "fly": [KEY_F], "photo": [KEY_P], "report": [KEY_F9],
}
const PAD_BUTTONS := {
	"move_up": [JOY_BUTTON_DPAD_UP], "move_down": [JOY_BUTTON_DPAD_DOWN],
	"move_left": [JOY_BUTTON_DPAD_LEFT], "move_right": [JOY_BUTTON_DPAD_RIGHT],
	"confirm": [JOY_BUTTON_A], "cancel": [JOY_BUTTON_B], "menu": [JOY_BUTTON_START], "run": [JOY_BUTTON_X], "bike": [JOY_BUTTON_Y], "fly": [JOY_BUTTON_BACK], "photo": [JOY_BUTTON_RIGHT_STICK],
}
const PAD_AXES := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
}
const PAD_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y", JOY_BUTTON_BACK: "Back", JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start", JOY_BUTTON_LEFT_STICK: "L-Stick", JOY_BUTTON_RIGHT_STICK: "R-Stick",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_DPAD_UP: "D-pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-pad Down", JOY_BUTTON_DPAD_LEFT: "D-pad Left", JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
	JOY_BUTTON_MISC1: "Misc", JOY_BUTTON_TOUCHPAD: "Touchpad",
}

static func defaults() -> Dictionary:
	var out := {}
	for a in ACTIONS:
		out[a] = {"key": KEYS[a].duplicate(), "pad": PAD_BUTTONS.get(a, []).duplicate()}
	return out

## Turns whatever was read from a settings file into a complete, safe binding set. It starts from the defaults
## and replays what was loaded under the same rules as `rebound`: codes that aren't real keys or buttons are
## dropped, Esc belongs to Menu alone and Menu always keeps Esc (and Start), a code another action claims is taken
## from an action the file said nothing about. Per device (keyboard, pad), if anything ends up empty or two
## actions share a button, that whole device falls back to the defaults.
static func sanitise(raw) -> Dictionary:
	var out := defaults()
	if not (raw is Dictionary):
		return out
	for dev in ["key", "pad"]:
		var loaded := {}
		for a in ACTIONS:
			var entry = raw.get(a)
			if not (entry is Dictionary) or not (entry.get(dev) is Array):
				continue
			var clean := []
			for v in entry[dev]:
				if (v is float or v is int) and _usable(dev, int(v), a) and not clean.has(int(v)):
					clean.append(int(v))
			if not clean.is_empty():
				loaded[a] = clean
		var claimed := {}
		for a in loaded:
			for c in loaded[a]:
				claimed[c] = true
		var set := {}
		for a in ACTIONS:
			if loaded.has(a):
				set[a] = loaded[a]
			else:
				set[a] = defaults()[a][dev].filter(func(c): return not claimed.has(c))
		var guard: int = KEY_ESCAPE if dev == "key" else JOY_BUTTON_START
		if not set.menu.has(guard):
			set.menu.push_front(guard)
		var seen := {}
		var ok := true
		for a in ACTIONS:
			if set[a].is_empty() and not may_be_empty(a, dev):
				ok = false
			for c in set[a]:
				if seen.has(c):
					ok = false
				seen[c] = true
		if ok:
			for a in ACTIONS:
				out[a][dev] = set[a]
	return out

static func may_be_empty(action: String, device: String) -> bool:
	return device in OPTIONAL.get(action, [])

static func _usable(dev: String, code: int, action: String) -> bool:
	if dev == "key":
		if code == KEY_ESCAPE:
			return action == "menu"
		var nm := OS.get_keycode_string(code)
		return code > 0 and nm != "" and OS.find_keycode_from_string(nm) == code  # junk codes name themselves "Unknown"
	return code >= 0 and code < JOY_BUTTON_SDL_MAX

## Pure rule check: the binding set after giving `action` the new `code` as its main button on `device`.
## Returns {"bindings": Dictionary, "error": String}. The new button becomes the first one; the action's other
## buttons stay. A button used by another action is taken from it, unless that leaves it with nothing.
static func rebound(current: Dictionary, action: String, device: String, code: int) -> Dictionary:
	if not (action in ACTIONS) or not (device in ["key", "pad"]):
		return {"bindings": current, "error": "Unknown control"}
	if device == "key" and code == KEY_ESCAPE:
		return {"bindings": current, "error": "Esc is kept for backing out"}
	var b: Dictionary = current.duplicate(true)
	for other in ACTIONS:
		if other == action or not b[other][device].has(code):
			continue
		b[other][device].erase(code)
		if b[other][device].is_empty() and not may_be_empty(other, device):
			return {"bindings": current, "error": "%s needs a %s button" % [LABELS[other], "key" if device == "key" else "pad"]}
	var mine: Array = b[action][device]
	mine.erase(code)
	mine.push_front(code)
	for c in b.confirm[device]:
		if b.cancel[device].has(c):
			return {"bindings": current, "error": "Confirm and Cancel can't share a button"}
	return {"bindings": b, "error": ""}

static func key_name(code: int) -> String:
	return OS.get_keycode_string(code)

static func pad_name(button: int) -> String:
	return PAD_NAMES.get(button, "Button %d" % button)

static func describe(b: Dictionary, action: String, device: String) -> String:
	var parts := []
	for c in b[action][device]:
		parts.append(key_name(c) if device == "key" else pad_name(c))
	return " / ".join(parts) if not parts.is_empty() else "-"

## Short names for on-screen prompts.
const SHORT_KEYS := {"Escape": "Esc", "BackSpace": "Backspace"}
## Prompt entries that name two buttons at once: kind -> [first action, second action] (the pad's shoulders are fixed).
const PAIR_ACTIONS := {"updown": ["move_up", "move_down"], "leftright": ["move_left", "move_right"]}

## The name a prompt shows for `action` on a device: its first (main) button.
static func hint_name(b: Dictionary, action: String, pad: bool) -> String:
	if PAIR_ACTIONS.has(action):
		var a := hint_name(b, PAIR_ACTIONS[action][0], pad)
		var z := hint_name(b, PAIR_ACTIONS[action][1], pad)
		if pad and a.begins_with("D-pad ") and z.begins_with("D-pad "):
			z = z.trim_prefix("D-pad ")
		return "%s / %s" % [a, z]
	if action == "shoulders":
		return "LB / RB" if pad else hint_name(b, "leftright", false)
	if action == "move":  # all four ways: "Arrows" or "D-pad" when they are, else the four buttons
		var four: Array = ["move_up", "move_left", "move_down", "move_right"].map(func(a): return hint_name(b, a, pad))
		if pad and four.all(func(n): return str(n).begins_with("D-pad ")):
			return "D-pad"
		if not pad and four == ["Up", "Left", "Down", "Right"]:
			return "Arrows"
		return " / ".join(four)
	var codes: Array = b.get(action, {}).get("pad" if pad else "key", [])
	if codes.is_empty():
		return "-"
	if pad:
		return pad_name(int(codes[0]))
	var n := key_name(int(codes[0]))
	return SHORT_KEYS.get(n, n)

## Renders prompt entries as "Z  Choose        X  Back". Each entry is [action, label] or [action, label, "kbd"|"pad"]
## (shown on that device only). An action starting with "=" is literal text (a key that can't be rebound).
static func hint_text(b: Dictionary, pad: bool, entries: Array) -> String:
	var parts := []
	for e in entries:
		if e.size() > 2 and e[2] != ("pad" if pad else "kbd"):
			continue
		var act: String = e[0]
		var nm: String = act.substr(1) if act.begins_with("=") else hint_name(b, act, pad)
		parts.append("%s  %s" % [nm, e[1]] if e[1] != "" else nm)
	return "        ".join(parts)

## Registers the actions with the given bindings (the factory set if none are given). Safe to call again.
static func apply(b: Dictionary = {}) -> void:
	InputMap.load_from_project_settings()  # drops our actions and any earlier mirroring into the ui_* ones
	register(b)

static func register(b: Dictionary = {}) -> void:
	if b.is_empty():
		b = defaults()
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.4)
		InputMap.action_erase_events(action)
		for k in b[action]["key"]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		for p in b[action]["pad"]:
			var j := InputEventJoypadButton.new()
			j.button_index = p
			InputMap.action_add_event(action, j)
		if PAD_AXES.has(action):
			var m := InputEventJoypadMotion.new()
			m.axis = PAD_AXES[action][0]
			m.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, m)
	# Godot's built-in UI actions drive Buttons and lists. Wipe their stock keys (Space, Enter, arrows...) so a key
	# the player gave to another action can't also confirm or back out, then mirror the game's own bindings.
	# Esc stays on ui_cancel: it is reserved for Menu and never bound to anything else.
	for ui in ["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]:
		InputMap.action_erase_events(ui)
	for pair in [["ui_accept", "confirm"], ["ui_cancel", "cancel"], ["ui_up", "move_up"], ["ui_down", "move_down"], ["ui_left", "move_left"], ["ui_right", "move_right"]]:
		for e in InputMap.action_get_events(pair[1]):
			InputMap.action_add_event(pair[0], e)
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	InputMap.action_add_event("ui_cancel", esc)
