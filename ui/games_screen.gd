extends MenuBase
## Highland games, hurling and shinty (see Games). One screen, four events chosen by the setup arg:
##   "caber"          hold Confirm to build the run-up, let go in the gold; three tosses judged by clock face
##   "tug:<atk>"      tap Confirm on the beat to heave; <atk> is the lead creature's Attack
##   "hurling" | "shinty"   a marker drifts around the goal; Confirm strikes; five shots against a leaning keeper
## Closes with {"won": bool, "score": int} ({"quit": true} too if you walk out). "dev" after a colon shows a game under way.

const GRASS := Color("3f7a3c")
const POST := Color("f2f2ee")
const GOLD := Color("e8c45a")
const GOOD := Color("6fbf73")
const BAD := Color("c46a6a")

var _kind := "caber"
var _e: Dictionary
var _easy := false
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _t := 0.0
var _wait := 0.6
var _over := false
var _msg := ""
var _stage: Control
var _info: Label
# caber
var _held := -1.0           # seconds Confirm has been held, -1 when not
var _toss := 0
var _total := 0
var _last_offset := -1
# tug
var _atk := Games.NO_LEAD_ATK
var _rope := 0.0
var _next_beat := Games.TUG_BEAT
var _tapped := false
var _flash := 0.0
# goal
var _shot := 0
var _score := 0
var _keeper: Dictionary
var _aim := Vector2.ZERO
var _result: Dictionary = {}

func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(900, 330)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["confirm", "Go"], ["cancel", "Walk away"]])
	_refresh()

func setup(arg: String) -> void:
	var p := arg.split(":")
	_kind = p[0] if p.size() > 0 and Games.EVENTS.has(p[0]) else "caber"
	_e = Games.event(_kind)
	_easy = Settings.easy_darts
	if _kind == "tug" and p.size() > 1 and p[1] != "dev":
		_atk = int(p[1])
	set_title(str(_e.get("name", "Games")))
	_keeper = Games.keeper(_rng, _easy)
	if "dev" in p:
		_toss = 1
		_total = 20
		_shot = 2
		_score = 3
		_rope = 0.25
		_held = 1.0
	_refresh()

func _process(delta: float) -> void:
	if _over or _e.is_empty():
		return
	_t += delta
	_wait = maxf(0.0, _wait - delta)
	_flash = maxf(0.0, _flash - delta)
	match _kind:
		"caber":
			_process_caber(delta)
		"tug":
			_process_tug(delta)
		_:
			_process_goal(delta)
	_stage.queue_redraw()

func _process_caber(delta: float) -> void:
	if _wait > 0.0:
		return
	if _held < 0.0:
		if Input.is_action_just_pressed("confirm"):
			_held = 0.0
		return
	_held += delta
	var power := Games.caber_power(_held, _easy)
	if Input.is_action_just_released("confirm") or power >= 1.0:
		_release(power)

func _release(power: float) -> void:
	_last_offset = Games.caber_offset(power, _easy)
	var pts := Games.caber_points(_last_offset)
	_total += pts
	_toss += 1
	_held = -1.0
	_wait = 1.2
	_msg = "%s: %d points." % [Games.clock_name(_last_offset).capitalize(), pts]
	Audio.sfx("item" if pts >= 8 else "deny")
	if _toss >= int(_e.tosses):
		_finish(_total >= int(_e.target), _total)
	_refresh()

func _process_tug(delta: float) -> void:
	if _wait > 0.0:
		return
	_rope = Games.tug_step(_rope, delta, _easy)
	var beat_t := fmod(_t, Games.TUG_BEAT)
	if Input.is_action_just_pressed("confirm"):
		var off := minf(beat_t, Games.TUG_BEAT - beat_t)
		var q := Games.tug_judge(off, _easy)
		_rope = Games.tug_tap(_rope, _atk, q)
		_flash = 0.25
		_msg = "Heave!" if q >= 1.0 else ("Ragged." if q > 0.0 else "Off the beat.")
		Audio.sfx("item" if q > 0.0 else "deny")
	if absf(_rope) >= 1.0 or _t >= Games.TUG_SECONDS:
		_finish(_rope > 0.0, int(round(_rope * 100.0)))

func _process_goal(delta: float) -> void:
	_aim = Vector2(sin(_t * 1.7) * 1.15 + sin(_t * 0.6) * 0.15, 0.8 + sin(_t * 2.3) * 0.7)
	if _wait > 0.0:
		return
	if Input.is_action_just_pressed("confirm"):
		var r := Games.shot(_aim, int(_keeper.zone), _kind)
		_score += int(r.pts)
		_shot += 1
		_wait = 1.3
		_msg = {"goal": "GOAL!", "point": "A point over the bar.", "saved": "Saved!", "wide": "Wide.", "over": "Over the bar. No points in this game."}.get(r.kind, "")
		Audio.sfx("item" if int(r.pts) > 0 else "deny")
		_keeper = Games.keeper(_rng, _easy)
		if _shot >= int(_e.shots):
			_finish(_score >= int(_e.target), _score)
		_refresh()

func _finish(won: bool, score: int) -> void:
	_over = true
	_result = {"won": won, "score": score}
	_msg += "  " + ("Well played." if won else "Not this time.")
	_refresh()
	get_tree().create_timer(1.6).timeout.connect(func():
		await PiecePrompt.after_game(self, _kind, float(score) if (won or _kind != "tug") else 0.0)
		close(_result))

func _on_cancel() -> void:
	if _over:
		return
	close({"won": false, "score": 0, "quit": true})

func _refresh() -> void:
	if _info == null or _e.is_empty():
		return
	var head := ""
	match _kind:
		"caber":
			head = "Toss %d of %d. Total %d, you need %d. Hold Confirm, let go in the gold." % [mini(_toss + 1, int(_e.tosses)), int(_e.tosses), _total, int(_e.target)]
		"tug":
			head = "Tap Confirm on the beat. Drag the marker over the line on the right before the whistle."
		_:
			head = "Shot %d of %d. Score %d, you need %d. Watch the keeper's lean, then strike." % [mini(_shot + 1, int(_e.shots)), int(_e.shots), _score, int(_e.target)]
	_info.text = head + "\n" + _msg

func _draw_stage() -> void:
	if _e.is_empty():
		return
	var s := _stage.size
	_stage.draw_rect(Rect2(0, s.y * 0.7, s.x, s.y * 0.3), GRASS)
	match _kind:
		"caber":
			_draw_caber(s)
		"tug":
			_draw_tug(s)
		_:
			_draw_goal(s)

func _draw_caber(s: Vector2) -> void:
	# the run-up bar with the gold sweet spot, and a clock face for the last toss
	var bar := Rect2(60, 60, s.x - 120, 36)
	_stage.draw_rect(bar, Color(0, 0, 0, 0.35))
	var w := 0.1 if _easy else 0.06
	_stage.draw_rect(Rect2(bar.position.x + bar.size.x * (Games.CABER_SWEET - w), bar.position.y, bar.size.x * w * 2.0, bar.size.y), GOLD)
	var power := Games.caber_power(maxf(_held, 0.0), _easy)
	_stage.draw_rect(Rect2(bar.position.x, bar.position.y + 8, bar.size.x * power, bar.size.y - 16), GOOD)
	var c := Vector2(s.x * 0.5, s.y * 0.5 + 40)
	_stage.draw_arc(c, 70.0, 0.0, TAU, 48, POST, 3.0)
	_stage.draw_string(ThemeDB.fallback_font, c + Vector2(-14, -80), "12", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, POST)
	if _last_offset >= 0:
		var ang := -PI * 0.5 + float(_last_offset) * TAU / 12.0
		_stage.draw_line(c, c + Vector2(cos(ang), sin(ang)) * 62.0, GOLD, 5.0)

func _draw_tug(s: Vector2) -> void:
	var y := s.y * 0.5
	var mid := s.x * 0.5
	_stage.draw_line(Vector2(80, y), Vector2(s.x - 80, y), Color("c9b27c"), 8.0)
	_stage.draw_line(Vector2(mid, y - 60), Vector2(mid, y + 60), POST, 3.0)
	var x := mid + _rope * (s.x * 0.5 - 100.0)
	_stage.draw_circle(Vector2(x, y), 20.0, BAD if _flash <= 0.0 else GOLD)
	# the beat: a ring that closes on the line every TUG_BEAT seconds
	var ph := fmod(_t, Games.TUG_BEAT) / Games.TUG_BEAT
	_stage.draw_arc(Vector2(mid, y + 110), 14.0 + 40.0 * (1.0 - ph), 0.0, TAU, 32, GOLD, 3.0)
	_stage.draw_arc(Vector2(mid, y + 110), 14.0, 0.0, TAU, 32, POST, 2.0)

func _draw_goal(s: Vector2) -> void:
	var cx := s.x * 0.5
	var ground := s.y * 0.7
	var half := 220.0
	var bar_y := ground - 170.0
	_stage.draw_line(Vector2(cx - half, ground), Vector2(cx - half, bar_y - 120.0), POST, 6.0)
	_stage.draw_line(Vector2(cx + half, ground), Vector2(cx + half, bar_y - 120.0), POST, 6.0)
	_stage.draw_line(Vector2(cx - half, bar_y), Vector2(cx + half, bar_y), POST, 6.0)
	# the keeper stands in the middle and leans towards where he is thinking of going
	var lean := (int(_keeper.lean) - 1) * 70.0
	_stage.draw_rect(Rect2(cx + lean - 22, ground - 110, 44, 110), Color("d83a2a"))
	_stage.draw_circle(Vector2(cx + lean, ground - 125), 14.0, Color("e8b890"))
	var p := Vector2(cx + _aim.x * half, ground - _aim.y * 170.0)
	_stage.draw_arc(p, 14.0, 0.0, TAU, 24, GOLD, 3.0)
	_stage.draw_line(p - Vector2(20, 0), p + Vector2(20, 0), GOLD, 2.0)
	_stage.draw_line(p - Vector2(0, 20), p + Vector2(0, 20), GOLD, 2.0)
