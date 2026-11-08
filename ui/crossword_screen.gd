extends MenuBase
## The daily crossword (story command {"do": "crossword"}): today's grid from Crossword, the clue for the word under
## the cursor and the full list beside it. Arrows move, letters type, Backspace clears, Confirm swaps across and down,
## Run steps a letter through the alphabet (for a pad). Closes with {"solved": true} when every letter is right,
## or null if the player walks out. setup arg "filled" (dev/screenshot) fills in half the grid.

const CELL := 64
const BLOCK := Color("14171f")
const EMPTY := Color("f4ecd2")
const ACTIVE_WORD := Color("f2d98a")
const CURSOR := Color("e8a33d")
const INK := Color("1d2230")

var _puzzle: Dictionary = {}
var _t0 := Time.get_ticks_msec()
var _entry: Array = []          # typed letters, rows of "" or "A".."Z"
var _cells: Array = []          # rows of PanelContainer
var _letters: Array = []        # rows of Label
var _nums: Array = []           # rows of the small clue-number Labels
var _cur := Vector2i.ZERO
var _across := true
var _clue_label: Label
var _status: Label
var _list: VBoxContainer

func _build() -> void:
	set_title("Today's crossword")
	set_hints([["move", "Move"], ["confirm", "Across / down"], ["cancel", "Walk out"]])
	_puzzle = Crossword.today()
	var n := int(_puzzle.get("size", Crossword.SIZE))
	for y in n:
		var r := []
		r.resize(n)
		r.fill("")
		_entry.append(r)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 24)
	content.add_child(row)
	row.add_child(_grid_panel(n))
	row.add_child(_side_panel())
	if not _puzzle.is_empty():
		var w: Dictionary = _puzzle.words[0]
		_cur = Vector2i(int(w.x), int(w.y))
		_across = w.dir == "across"
	_refresh()

func setup(arg: String) -> void:
	if arg == "filled" and not _puzzle.is_empty():
		for w in _puzzle.words:
			var cs := Crossword.cells(w)
			for k in cs.size() / 2:
				_entry[cs[k].y][cs[k].x] = str(w.answer)[k]
		_refresh()

func _grid_panel(n: int) -> Control:
	var p := UIKit.panel(Color("1d2230f0"), 14)
	var g := GridContainer.new()
	g.columns = n
	g.add_theme_constant_override("h_separation", 3)
	g.add_theme_constant_override("v_separation", 3)
	p.add_child(g)
	var big := UIKit.sized(38)  # the letters fill the square at any Text size, but never overflow it
	while big > UIKit.MIN_TEXT and UIKit.font().get_height(big) > CELL - 8:
		big -= 1
	for y in n:
		var cr := []
		var lr := []
		var nr := []
		for x in n:
			var c := PanelContainer.new()
			c.custom_minimum_size = Vector2(CELL, CELL)
			var l := UIKit.label("", 38, INK)
			l.add_theme_font_size_override("font_size", big)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var num := UIKit.label("", 15, INK)
			num.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			c.add_child(num)
			c.add_child(l)
			g.add_child(c)
			cr.append(c)
			lr.append(l)
			nr.append(num)
		_cells.append(cr)
		_letters.append(lr)
		_nums.append(nr)
	return p

func _side_panel() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	var cp := UIKit.panel(Color("1d2230f0"), 12)
	cp.custom_minimum_size = Vector2(0, 110)
	_clue_label = UIKit.label("", 28, UIKit.GOLD)
	_clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cp.add_child(_clue_label)
	col.add_child(cp)
	var lp := UIKit.panel(Color("1d2230f0"), 12)
	lp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	lp.add_child(_list)
	col.add_child(lp)
	for w in _puzzle.get("words", []):
		var l := UIKit.label("%d %s. %s" % [w.n, str(w.dir).capitalize(), w.clue], 18, UIKit.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(l)
	_status = UIKit.label("", 24, Color("8fd19e"))
	col.add_child(_status)
	return col

# ---- the cursor

func _word_at(pos: Vector2i, across: bool) -> Dictionary:
	for w in _puzzle.get("words", []):
		if (w.dir == "across") == across and pos in Crossword.cells(w):
			return w
	return {}

func _open(x: int, y: int) -> bool:
	var n := int(_puzzle.size)
	return x >= 0 and y >= 0 and x < n and y < n and str(_puzzle.grid[y][x]) != ""

func _move(d: Vector2i) -> void:
	var p := _cur
	for step in int(_puzzle.size):  # skip over blocks to the next open cell in that direction
		p += d
		if _open(p.x, p.y):
			_cur = p
			break
	if _word_at(_cur, _across).is_empty():
		_across = not _across
	Audio.sfx("cursor")
	_refresh()

func _type(ch: String) -> void:
	_entry[_cur.y][_cur.x] = ch
	if ch != "":
		var nxt := _cur + (Vector2i(1, 0) if _across else Vector2i(0, 1))
		if _open(nxt.x, nxt.y) and not _word_at(nxt, _across).is_empty():
			_cur = nxt
	_refresh()
	if _all_filled():
		if Crossword.solved(_puzzle, _entry):
			Audio.sfx("heal")
			_status.text = "Every square right. Hand it in."
			_status.add_theme_color_override("font_color", Color("8fd19e"))
			_finish_later()
		else:
			_status.text = "All filled in, but something is off."
			_status.add_theme_color_override("font_color", Color("e08a8a"))

func _all_filled() -> bool:
	for y in int(_puzzle.size):
		for x in int(_puzzle.size):
			if str(_puzzle.grid[y][x]) != "" and str(_entry[y][x]) == "":
				return false
	return true

func _finish_later() -> void:
	await get_tree().create_timer(0.9).timeout
	if _done:
		return
	await PiecePrompt.after_game(self, "crossword", (Time.get_ticks_msec() - _t0) / 1000.0)
	_done = true
	closed.emit({"solved": true})

func _input(event: InputEvent) -> void:
	if _locked or _done or _puzzle.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_A and k <= KEY_Z:
			get_viewport().set_input_as_handled()
			_type(char(k))
			return
		if k == KEY_BACKSPACE or k == KEY_DELETE:
			get_viewport().set_input_as_handled()
			_type("")
			return
	if event.is_action_pressed("move_left"):
		_move(Vector2i(-1, 0))
	elif event.is_action_pressed("move_right"):
		_move(Vector2i(1, 0))
	elif event.is_action_pressed("move_up"):
		_move(Vector2i(0, -1))
	elif event.is_action_pressed("move_down"):
		_move(Vector2i(0, 1))
	elif event.is_action_pressed("confirm"):
		if not _word_at(_cur, not _across).is_empty():
			_across = not _across
		Audio.sfx("confirm")
		_refresh()
	elif event.is_action_pressed("run"):
		var cur := str(_entry[_cur.y][_cur.x])
		_type("A" if cur == "" or cur == "Z" else char(cur.unicode_at(0) + 1))
	else:
		super._input(event)
		return
	get_viewport().set_input_as_handled()

# ---- drawing

func _refresh() -> void:
	if _puzzle.is_empty():
		return
	var word := _word_at(_cur, _across)
	var lit := {}
	for c in Crossword.cells(word) if not word.is_empty() else []:
		lit[c] = true
	var starts := {}
	for w in _puzzle.words:
		starts["%d,%d" % [w.x, w.y]] = w.n
	for y in int(_puzzle.size):
		for x in int(_puzzle.size):
			var open := str(_puzzle.grid[y][x]) != ""
			var bg := BLOCK
			if open:
				bg = CURSOR if Vector2i(x, y) == _cur else (ACTIVE_WORD if lit.has(Vector2i(x, y)) else EMPTY)
			(_cells[y][x] as PanelContainer).add_theme_stylebox_override("panel", UIKit.box(bg, Color("0b0d12"), 1, 2, 4))
			(_letters[y][x] as Label).text = str(_entry[y][x]) if open else ""
			(_nums[y][x] as Label).text = str(starts.get("%d,%d" % [x, y], ""))
	if not word.is_empty():
		_clue_label.text = "%d %s: %s" % [word.n, str(word.dir).capitalize(), word.clue]

func _on_cancel() -> void:
	close(null)
