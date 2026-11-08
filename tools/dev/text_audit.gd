extends SceneTree
## Lists words that don't fit on every menu, screen and minigame at 1280x720 (see core/text_fit_audit.gd).
## godot --headless --path . -s res://tools/dev/text_audit.gd -- [screen ...|all] [--kind=wide,cut] [--summary] [--stress]
## Screens are --menu= names, e.g. `pause bag:first travel:all almanac:pieces`; the list is in text_audit_body.gd.
## Exits 1 if anything was found.

func _initialize() -> void:
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP  # a headless window has no size: keep the 1280x720 canvas
	_go.call_deferred()

func _go() -> void:
	var body = load("res://tools/dev/text_audit_body.gd")
	if body == null or not body.can_instantiate():
		quit(2)  # a script error, already printed: run `godot --headless --import` once after adding a class
		return
	var n: int = await body.new().run(self, OS.get_cmdline_user_args())
	quit(1 if n > 0 else 0)
