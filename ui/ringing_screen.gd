extends MenuBase
## Change ringing (see Ringing): the row sounds left to right at a steady beat. Press Confirm as the marker reaches
## your bell (shown gold); the next call is announced a row ahead. Closes with {"hits": rows struck in time, "rows": n}.
## setup arg: "<piece id>" (dev: "dev" shows a piece part way through).

const ROPE := Color("c9b27c")
const BELL := Color("b8923c")
const MINE := Color("e8c45a")
const HIT := Color("6fbf73")
const MISSED := Color("c46a6a")

var _piece: Dictionary
var _rows: Array = []
var _row := 0
var _t := -1.5            # seconds into the current row; negative is the count-in
var _pulled := -1.0       # when the player pulled in this row (-1: not yet)
var _results: Array = []  # per row: "perfect" | "good" | "miss"
var _beat: Dictionary
var _finished := false
var _stage: Control
var _info: Label

func _build() -> void:
	set_title("Ringing chamber")
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(900, 300)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["confirm", "Pull"], ["cancel", "Leave the ropes"]])
	_refresh()

func setup(arg: String) -> void:
	_beat = Ringing.beat(Settings.easy_darts)
	_piece = Ringing.piece("call_changes" if arg.begins_with("dev") else arg)
	if _piece.is_empty():
		_piece = Ringing.piece("rounds")
	_rows = Ringing.rows_for(_piece)
	if arg.begins_with("dev"):
		_row = 3
		_t = 0.2
	_refresh()

func _bell() -> int:
	return int(_piece.bell)

func _interval() -> float:
	return float(_beat.interval)

func _process(delta: float) -> void:
	if _piece.is_empty() or _finished:
		return
	_t += delta
	var row_len := _interval() * Ringing.BELLS
	if Input.is_action_just_pressed("confirm") and _t >= 0.0 and _pulled < 0.0:
		_pulled = _t
		Audio.sfx("item")
	if _t >= row_len + _interval() * 0.5:
		_close_row()
	_stage.queue_redraw()

## Marks the row just rung and moves on (or finishes after the last one).
func _close_row() -> void:
	var place := Ringing.place_of(_rows[_row], _bell())
	var target := _interval() * float(place)
	var res := "miss"
	if _pulled >= 0.0:
		res = Ringing.judge(_pulled - target, float(_beat.window))
	_results.append(res)
	_row += 1
	_t = 0.0
	_pulled = -1.0
	if _row >= _rows.size():
		_finished = true
		var hits := _results.filter(func(r): return r != "miss").size()
		_refresh()
		get_tree().create_timer(1.2).timeout.connect(func():
			await PiecePrompt.after_game(self, "ringing", 100.0 * hits / maxf(1.0, float(_rows.size())))
			close({"hits": hits, "rows": _rows.size()}))
		return
	_refresh()

func _on_cancel() -> void:
	var hits := _results.filter(func(r): return r != "miss").size()
	close({"hits": hits, "rows": _rows.size(), "quit": true})

func _refresh() -> void:
	if _info == null or _piece.is_empty():
		return
	var call: Array = _piece.calls[_row] if _row < _piece.calls.size() else []
	var tag := "Row %d of %d. You ring bell %d.\n" % [mini(_row + 1, _rows.size()), _rows.size(), _bell()]
	_info.text = tag + (Ringing.call_text(call) if _row < _piece.calls.size() else "That's the end of the touch.")

func _draw_stage() -> void:
	if _piece.is_empty() or _rows.is_empty():
		return
	var s := _stage.size
	var row: Array = _rows[mini(_row, _rows.size() - 1)]
	var step := s.x / float(Ringing.BELLS + 1)
	var interval := _interval()
	var stroke := int(floorf(_t / interval)) if _t >= 0.0 else -1
	for i in Ringing.BELLS:
		var bell: int = row[i]
		var c := Vector2(step * float(i + 1), s.y * 0.5)
		var lit := i == stroke
		var col := MINE if bell == _bell() else BELL
		if lit:
			col = col.lightened(0.35)
		_stage.draw_line(Vector2(c.x, 0), Vector2(c.x, c.y - 30.0), ROPE, 3.0)
		_stage.draw_circle(c, 38.0 if lit else 32.0, col)
		_stage.draw_string(ThemeDB.fallback_font, c + Vector2(-8, 9), str(bell), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.BLACK)
		if bell == _bell():
			_stage.draw_string(ThemeDB.fallback_font, c + Vector2(-30, 62), "you", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, MINE)
	# the row so far, as little ticks under the bells
	for k in _results.size():
		var col2 := HIT if _results[k] != "miss" else MISSED
		_stage.draw_rect(Rect2(20 + k * 22, s.y - 26, 16, 16), col2)
