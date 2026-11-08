extends SceneTree
## Lists words that don't fit on every menu, screen and minigame at 1280x720 (see core/text_fit_audit.gd).
## godot --headless --path . -s res://tools/dev/text_audit.gd -- [screen ...|all] [--kind=wide,cut] [--summary] [--stress] [--text=large]
## Screens are --menu= names, e.g. `pause bag:first travel:all almanac:pieces`; the list is in text_audit_body.gd.
## Exits 1 if anything was found.

func _initialize() -> void:
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP  # a headless window has no size: keep the 1280x720 canvas
	_go.call_deferred()

## A script error inside a screen stops the coroutine without quitting: never leave a headless Godot running.
func _watchdog(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
	printerr("text_audit: gave up after %d s (a script error above?)" % seconds)
	quit(3)

func _go() -> void:
	var screens := Array(OS.get_cmdline_user_args()).filter(func(a): return not str(a).begins_with("--"))
	_watchdog(60.0 + 8.0 * (130 if screens.is_empty() or screens == ["all"] else screens.size()))
	var body = load("res://tools/dev/text_audit_body.gd")
	if body == null or not body.can_instantiate():
		quit(2)  # a script error, already printed: run `godot --headless --import` once after adding a class
		return
	var n: int = await body.new().run(self, OS.get_cmdline_user_args())
	quit(1 if n > 0 else 0)
