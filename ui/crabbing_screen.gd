extends MenuBase
## Crabbing off the harbour wall (see Crabbing): lower the line, watch the crabs climb on to the bacon, and press
## Confirm to haul while it is fullest; they let go again if you dither. Hauled crabs go in the bucket; the caller
## counts and releases them. Closes with {"bucket": [...], "used": bait spent}.
## setup arg: "free:<bait>:<spot>" or "comp:<hauls>:<spot>" (dev: "dev" shows a line with crabs on).

const SKY := Color("a8c4d8")
const SEA := Color("3d6f86")
const WALL := Color("8b8a84")
const CRAB := Color("d9702e")

var _mode := "free"
var _spot := ""
var _total := 8
var _used := 0
var _bucket: Array = []
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _plan: Dictionary
var _t := 0.0
var _down := false
var _wait := 0.5
var _lock := 0.0
var _msg := "Press Confirm to lower the line."
var _stage: Control
var _info: Label

func _build() -> void:
	set_title("Crabbing")
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(560, 420)
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(360, 0)
	root.add_child(side)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_info)
	set_hints([["confirm", "Lower / haul"], ["cancel", "Put the kit away"]])
	_refresh()

func setup(arg: String) -> void:
	var p := arg.split(":")
	_mode = p[0] if p.size() > 0 else "free"
	_total = int(p[1]) if p.size() > 1 else 8
	_spot = p[2] if p.size() > 2 else ""
	if arg.begins_with("dev"):
		_down = true
		_plan = {"interval": 1.0, "hold": 3.0, "max": 5}
		_t = 3.2
		_used = 2
		_bucket = Crabbing.catch_for(5, "summer", Rng.new(3))
	_refresh()

func _process(delta: float) -> void:
	_wait = maxf(0.0, _wait - delta)
	_lock = maxf(0.0, _lock - delta)
	if _down:
		_t += delta
		if _t > Crabbing.empty_at(_plan):
			_down = false
			_lock = 1.2
			_used += 1
			_msg = "They've all let go. A clean line and no bacon."
			_after_use()
			_refresh()
	_stage.queue_redraw()
	if _wait > 0.0 or _lock > 0.0 or not Input.is_action_just_pressed("confirm"):
		return
	if not _down:
		_plan = Crabbing.plan(Settings.easy_darts, _rng)
		_t = 0.0
		_down = true
		_msg = "Watch the bacon. Press Confirm when the line is fullest."
		Audio.sfx("splash")
	else:
		_haul()
	_refresh()

func _on_cancel() -> void:
	close({"bucket": _bucket, "used": _used})

func _haul() -> void:
	var n := Crabbing.on_line(_t, _plan)
	_down = false
	_used += 1
	_lock = 1.0
	if n <= 0:
		_msg = "Nothing. The crabs have had your bait and gone. Cheeky."
	else:
		var got := Crabbing.catch_for(mini(n, Crabbing.bucket_size() - _bucket.size()), Calendar.season_today(), _rng)
		_bucket.append_array(got)
		Audio.sfx("item")
		_msg = "%d on the line: %s." % [n, ", ".join(PackedStringArray(Crabbing.tally(got)))]
	_after_use()

func _after_use() -> void:
	if _used >= _total or _bucket.size() >= Crabbing.bucket_size():
		_msg += " That's the lot."
		get_tree().create_timer(1.6).timeout.connect(func():
			await PiecePrompt.after_game(self, "crabbing", float(_bucket.size()))
			close({"bucket": _bucket, "used": _used}))
		_lock = 5.0

func _refresh() -> void:
	if _info == null:
		return
	var left := _total - _used
	var comp := "\nCompetition: highest score wins." if _mode == "comp" else ""
	_info.text = "Bucket: %d of %d\n%s: %d%s\n\n%s" % [_bucket.size(), Crabbing.bucket_size(), "Hauls left" if _mode == "comp" else "Bait left", left, comp, _msg]

func _draw_stage() -> void:
	var s := _stage.size
	_stage.draw_rect(Rect2(0, 0, s.x, s.y * 0.28), SKY)
	_stage.draw_rect(Rect2(0, s.y * 0.28, s.x, s.y * 0.72), SEA)
	_stage.draw_rect(Rect2(0, s.y * 0.2, s.x, s.y * 0.1), WALL)
	var lx := s.x * 0.45
	var top := s.y * 0.2
	var depth := s.y * 0.72 if _down else s.y * 0.3
	_stage.draw_line(Vector2(lx, top), Vector2(lx, depth), Color("f3ecd8"), 2.0)
	_stage.draw_circle(Vector2(lx, depth), 9.0, Color("c46a6a"))   # the bacon rind
	if _down:
		var n := Crabbing.on_line(_t, _plan)
		for i in n:
			var ang := -PI * 0.5 + (float(i) - float(n - 1) * 0.5) * 0.7
			_draw_crab(Vector2(lx, depth) + Vector2(cos(ang), -sin(ang)) * -34.0 + Vector2(0, 8), 1.0)
		var full := n >= int(_plan.max)
		_stage.draw_string(ThemeDB.fallback_font, Vector2(10, s.y - 12), "On the line: %d%s" % [n, "  (full!)" if full else ""], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.CREAM)
	# the bucket on the wall, filling with a crab or two for every few caught
	var b := Rect2(s.x * 0.75, s.y * 0.1, 70, 60)
	_stage.draw_rect(b, Color("c0392b"))
	_stage.draw_rect(Rect2(b.position.x, b.position.y, 70, 8), Color("7e2318"))
	for i in mini(_bucket.size(), 8):
		_draw_crab(Vector2(b.position.x + 12 + (i % 4) * 15, b.position.y + 28 + (i / 4) * 16), 0.45)

func _draw_crab(c: Vector2, k: float) -> void:
	_stage.draw_circle(c, 13.0 * k, CRAB)
	for sgn in [-1.0, 1.0]:
		_stage.draw_circle(c + Vector2(sgn * 17.0 * k, -9.0 * k), 6.0 * k, CRAB)
		for j in 3:
			_stage.draw_line(c + Vector2(sgn * 10.0 * k, (j - 1) * 6.0 * k), c + Vector2(sgn * 21.0 * k, (j - 1) * 9.0 * k + 5.0 * k), CRAB.darkened(0.3), 2.0 * k)
