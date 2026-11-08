class_name ReportKey
extends CanvasLayer
## The report key (F9 unless rebound, see InputSetup): press it anywhere and the frame on screen, where you are and a
## copy of the game go to user://reports/<date_time>/ (see ProblemReport). A toast says so and play carries on.
## A second press within NOTE_WINDOW seconds opens a one-line note box; the game holds still while you type.
## It listens on the window's own input signal, so no menu can swallow the press, and it does nothing per frame.
## Dev: --report-now[=seconds] presses it once (default 3 s in) and then quits; --report-note=<text> adds that note.

const NOTE_WINDOW := 3.0
const TOAST := "Reported. Keep playing."

var _last_dir := ""
var _last_info := {}
var _last_at := -100000
var _task := -1
var _toast: SaveToast
var _note: LineEdit
var _note_panel: PanelContainer
var _was_paused := false

func _ready() -> void:
	layer = 110  # above the Router's fade, so the note box shows even mid-fade
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.window_input.connect(_on_window_input)
	for a in DevArgs.user_args():
		if a == "--report-now" or a.begins_with("--report-now="):
			_dev_press.call_deferred(a.get_slice("=", 1).to_float() if "=" in a else 3.0)

func _exit_tree() -> void:
	_finish_writing()

func _on_window_input(event: InputEvent) -> void:
	if _note != null or not event.is_action_pressed("report"):
		return
	if _rebinding():
		return
	if _last_dir != "" and Time.get_ticks_msec() - _last_at < NOTE_WINDOW * 1000.0:
		open_note()
	else:
		report()

## Settings > Controls waiting for a new key: F9 is being bound, not pressed.
func _rebinding() -> bool:
	for m in get_tree().root.find_children("*", "Control", true, false):
		if m.has_method("capturing") and m.capturing():
			return true
	return false

## Makes a report now. Returns its folder (user://...). The picture is the last frame drawn, taken before the toast.
func report() -> String:
	var shot: Image = null
	if DisplayServer.get_name() != "headless":
		shot = get_viewport().get_texture().get_image()
	var dir := ProblemReport.new_folder(ProblemReport.DIR, Time.get_datetime_dict_from_system())
	DirAccess.make_dir_recursive_absolute(dir)  # claimed now, so a report a second later gets its own folder
	var info := ProblemReport.info(gather())
	var save := SaveSystem.payload_of(Game.data.to_dict())  # a deep copy: the game may change while it's written
	_finish_writing()
	_task = WorkerThreadPool.add_task(func(): ProblemReport.write(dir, info, save, shot))  # PNG encoding off the main thread
	_last_dir = dir
	_last_info = info
	_last_at = Time.get_ticks_msec()
	_flash(TOAST)
	print("report: ", ProjectSettings.globalize_path(dir))
	return dir

## The live facts for info.json (see ProblemReport.FIELDS).
func gather() -> Dictionary:
	var d: GameStateData = Game.data
	var f := {"version": str(ProjectSettings.get_setting("application/config/version", "")),
		"reported_at": Time.get_datetime_string_from_system(false, true), "platform": OS.get_name(),
		"dev_session": DevArgs.is_dev_session(Game.args, DevArgs.user_args()),
		"zone": d.zone_id, "weather": Forecast.current_weather(), "clock": Game.local_minutes(), "time_of_day": Game.phase(),
		"day": d.day_count, "play_seconds": d.play_seconds,
		"menus": ProblemReport.menu_names(Router.open_menus(), Router.MENUS)}
	var cur := get_tree().current_scene
	f.scene = cur.scene_file_path if cur else ""
	var ow = Router.overworld
	if ow != null and is_instance_valid(ow) and ow.get("zone") != null:
		f.zone = ow.zone.id
		f.zone_name = ow.zone.name
		f.weather = ow.weather
		if ow.player:
			f.tile = ow.player.grid_pos
			f.facing = ow.player.facing
	for n in get_tree().root.get_children():
		var flow = n.get("flow")
		if flow is BattleFlow and flow.battle != null:
			f.scene = n.scene_file_path
			f.battle = ProblemReport.battle_brief(flow.battle, flow.log)
			var label: Label = n.msg.label if n.get("msg") != null else null
			if label:
				f.dialogue = ProblemReport.shown_text(label.text, label.visible_characters)
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if n is DialogueBox:
			var s: Dictionary = n.on_screen()
			if s.text != "":
				f.dialogue = (s.who + ": " if s.who != "" else "") + s.text
	return f

## The one-line note box for the report just made. Enter keeps the note, Esc leaves the report as it is.
func open_note() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	Router.hold_menus(true)
	_note_panel = PanelContainer.new()
	_note_panel.theme = load("res://ui/theme.tres")
	_note_panel.set_anchors_preset(Control.PRESET_CENTER)  # mid-screen: clear of the dialogue and battle boxes
	_note_panel.offset_left = -420
	_note_panel.offset_right = 420
	_note_panel.offset_top = -40
	_note_panel.offset_bottom = 40
	var v := VBoxContainer.new()
	_note_panel.add_child(v)
	var l := Label.new()
	l.text = "What went wrong?  Enter keeps the note, Esc skips it."
	l.add_theme_font_size_override("font_size", 20)
	v.add_child(l)
	_note = LineEdit.new()
	_note.max_length = ProblemReport.NOTE_MAX
	_note.add_theme_font_size_override("font_size", 22)
	_note.text_submitted.connect(func(t: String): close_note(t))
	v.add_child(_note)
	add_child(_note_panel)
	_note.grab_focus()

func _input(event: InputEvent) -> void:
	if _note != null and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_note("")

func close_note(text: String) -> void:
	if _note == null:
		return
	_note = null
	_note_panel.queue_free()
	if text.strip_edges() != "":
		_finish_writing()
		ProblemReport.add_note(_last_dir, _last_info, text)
		_flash("Note added.")
	_last_at = -100000  # a third press makes a new report
	Router.hold_menus(false)
	get_tree().paused = _was_paused

func _flash(text: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _toast == null:
		_toast = SaveToast.new()
		add_child(_toast)
		_toast.layer = layer
	_toast.flash(text)

func _finish_writing() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1

## Dev --report-now: `delay` real seconds after the boot has settled, press the report key as a
## player would; with --report-note, press it again and type the note. Real time, as a slow first load can make
## the scene timers jump. The game then quits a second after the report is written.
func _dev_press(delay: float) -> void:
	while not _booted():
		await get_tree().process_frame
	var at := Time.get_ticks_msec() + int(delay * 1000.0)
	while Time.get_ticks_msec() < at:
		await get_tree().process_frame
	_press_key()
	var note := ""
	for a in DevArgs.user_args():
		if a.begins_with("--report-note="):
			note = a.substr(14)
	if note != "":
		at = Time.get_ticks_msec() + 500
		while Time.get_ticks_msec() < at:
			await get_tree().process_frame
		_press_key()
		await get_tree().process_frame
		if _note != null:
			_note.text = note
			_note.text_submitted.emit(note)
	_finish_writing()
	at = Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < at:
		await get_tree().process_frame
	print("report-now: done, quitting")
	get_tree().quit()  # a dev run ends itself once the report is on disk

## A zone, a battle or a menu is up (a dev boot has got where it was going).
func _booted() -> bool:
	if not Router.open_menus().is_empty() or get_tree().root.get_children().any(func(n): return n.get("flow") is BattleFlow):
		return true
	return Router.overworld != null and is_instance_valid(Router.overworld) and Router.overworld.get("zone") != null

func _press_key() -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.physical_keycode = int(Settings.bindings.get("report", {}).get("key", [KEY_F9])[0])
		e.pressed = down
		Input.parse_input_event(e)
