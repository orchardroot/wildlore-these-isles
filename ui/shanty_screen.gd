extends MenuBase
## A sea shanty in the pub (see Shanties): the line is sung over four beats and the crew heaves on the beats marked
## with a ring. Press Confirm as the playhead reaches each ring. Closes with {"hits": pulls in time, "pulls": n}.
## setup arg: "<shanty id>" (dev: "dev" shows a song part way through).

const RING := Color("e8c45a")
const BEAT := Color("8f7a4a")
const HIT := Color("6fbf73")
const MISSED := Color("c46a6a")

var _song: Dictionary
var _beat: Dictionary
var _targets: Array = []
var _results: Array = []
var _t := 0.0
var _finished := false
var _stage: Control
var _info: Label

func _build() -> void:
	set_title("Singing")
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(900, 260)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["confirm", "Heave"], ["cancel", "Sit down"]])
	_refresh()

func setup(arg: String) -> void:
	_beat = Shanties.beat(Settings.easy_darts)
	_song = Shanties.shanty("haul_away_joe" if arg.begins_with("dev") else arg)
	if _song.is_empty():
		_song = Shanties.shanty("drunken_sailor")
	_targets = Shanties.targets(_song, _interval())
	_results.clear()
	for i in _targets.size():
		_results.append("")
	if arg.begins_with("dev"):
		_t = Shanties.LEAD_IN + _interval() * 5.6
	_refresh()

func _interval() -> float:
	return float(_beat.interval)

func _process(delta: float) -> void:
	if _song.is_empty() or _finished:
		return
	_t += delta
	if Input.is_action_just_pressed("confirm") and not _targets.is_empty():
		var k := Shanties.target_for(_targets, _results, _t, float(_beat.window))
		if k >= 0:
			_results[k] = Shanties.judge(_t - float(_targets[k].t), float(_beat.window))
			Audio.sfx("item")
		else:
			Audio.sfx("cancel")
	for i in _targets.size():  # a pull the window has passed is missed
		if str(_results[i]) == "" and _t > float(_targets[i].t) + float(_beat.window):
			_results[i] = "miss"
	if _t >= Shanties.length(_song, _interval()) + 0.3:
		_finished = true
		var hits := Shanties.hits_of(_results)
		_refresh()
		get_tree().create_timer(1.2).timeout.connect(func():
			await PiecePrompt.after_game(self, "shanty", 100.0 * hits / maxf(1.0, float(_targets.size())))
			close({"hits": hits, "pulls": _targets.size()}))
	_refresh()
	_stage.queue_redraw()

func _on_cancel() -> void:
	close({"hits": Shanties.hits_of(_results), "pulls": _targets.size(), "quit": true})

func _line_now() -> int:
	var n: int = _song.lines.size()
	var b := (_t - Shanties.LEAD_IN) / _interval()
	return clampi(int(floorf(b / float(Shanties.LINE_BEATS))), 0, n - 1) if b >= 0.0 else 0

func _refresh() -> void:
	if _info == null or _song.is_empty():
		return
	var line: Dictionary = _song.lines[_line_now()]
	var tag := "%s (%s)\n" % [str(_song.name), str(_song.kind).to_lower()]
	_info.text = tag + ("Count in..." if _t < Shanties.LEAD_IN else str(line.text))

func _draw_stage() -> void:
	if _song.is_empty():
		return
	var s := _stage.size
	var li := _line_now()
	var step := s.x / float(Shanties.LINE_BEATS + 1)
	var interval := _interval()
	var line: Dictionary = _song.lines[li]
	var base := Shanties.LEAD_IN + float(li * Shanties.LINE_BEATS) * interval
	for b in Shanties.LINE_BEATS:
		var c := Vector2(step * float(b + 1), s.y * 0.5)
		var is_pull: bool = line.pulls.has(b)
		var col := BEAT
		if is_pull:
			for i in _targets.size():
				if int(_targets[i].line) == li and absf(float(_targets[i].t) - (base + float(b) * interval)) < 0.001:
					var r := str(_results[i])
					col = RING if r == "" else (MISSED if r == "miss" else HIT)
		_stage.draw_circle(c, 22.0, col)
		if is_pull:
			_stage.draw_arc(c, 36.0, 0.0, TAU, 32, col, 4.0)
	# the playhead slides between beat centres across the line
	var pos := clampf((_t - base) / interval, 0.0, float(Shanties.LINE_BEATS) - 0.01)
	_stage.draw_line(Vector2(step * (pos + 1.0), s.y * 0.5 - 56.0), Vector2(step * (pos + 1.0), s.y * 0.5 + 56.0), UIKit.CREAM, 3.0)
	# the song so far, as little ticks under the beats
	for k in _results.size():
		var col2 := Color("55504a") if str(_results[k]) == "" else (MISSED if _results[k] == "miss" else HIT)
		_stage.draw_rect(Rect2(20 + k * 18, s.y - 26, 12, 12), col2)
