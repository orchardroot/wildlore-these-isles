extends MenuBase
## Drystone walling (see Walling): choose a stone from the pile, turn it, and set it in the gap; stones must rest on
## the ground or other stones. Closes with {"built": true|false}.
## setup arg: "<level>" (easy | normal | hard); dev shows a half-built wall.

const STONE := [Color("8f8c84"), Color("a39d90"), Color("7d7a72"), Color("9a9488"), Color("b0aa9c"), Color("85817a")]

var _level := "normal"
var _backs := 0   # stones taken back (a clean wall earns the gold)
var _puzzle: Dictionary
var _grid: Array
var _stones: Array = []   # [{w, h, placed, x, y}] the player's pile
var _sel := 0
var _turned := false
var _cur := Vector2i.ZERO
var _msg := "Fit every stone. The wall can't hang in mid-air."
var _stage: Control
var _info: Label
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _show_hint := false
var _order: Array = []     # indices of placed stones, latest last

func _build() -> void:
	set_title("Drystone walling")
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(620, 420)
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(340, 0)
	root.add_child(side)
	_info = UIKit.label("", 24, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_info)
	set_hints([["confirm", "Set stone"], ["run", "Turn"], ["bike", "Next stone"], ["fly", "Take last back"], ["cancel", "Leave it"]])
	_refresh()

func setup(arg: String) -> void:
	_level = arg.split(":")[0] if arg != "" else "normal"
	if _level == "dev":
		_level = "normal"
	_show_hint = Settings.easy_darts
	_puzzle = Walling.generate(_level, _rng)
	_grid = Walling.empty_grid(int(_puzzle.w), int(_puzzle.h))
	var pile: Array = _puzzle.stones.duplicate()
	for i in pile.size():
		var s: Dictionary = pile[i]
		_stones.append({"w": int(s.w), "h": int(s.h), "placed": false, "x": 0, "y": 0, "home": Walling.hint_for(s)})
	_stones.shuffle()
	_cur = Vector2i(0, int(_puzzle.h) - 1)
	_refresh()

func _size_of(i: int) -> Vector2i:
	var s: Dictionary = _stones[i]
	return Vector2i(s.h, s.w) if _turned else Vector2i(s.w, s.h)

func _next_free(from: int, step: int) -> int:
	for k in range(1, _stones.size() + 1):
		var i := posmod(from + step * k, _stones.size())
		if not _stones[i].placed:
			return i
	return from

func _process(_delta: float) -> void:
	if _stones.is_empty():
		return
	for pair in [["move_left", Vector2i(-1, 0)], ["move_right", Vector2i(1, 0)], ["move_up", Vector2i(0, -1)], ["move_down", Vector2i(0, 1)]]:
		if Input.is_action_just_pressed(pair[0]):
			_cur += pair[1]
			_cur.x = clampi(_cur.x, 0, int(_puzzle.w) - 1)
			_cur.y = clampi(_cur.y, 0, int(_puzzle.h) - 1)
	if Input.is_action_just_pressed("run"):
		_turned = not _turned
	if Input.is_action_just_pressed("bike"):
		_sel = _next_free(_sel, 1)
		_turned = false
	if Input.is_action_just_pressed("fly"):
		_take_back()
	if Input.is_action_just_pressed("confirm"):
		_set_stone()
	_stage.queue_redraw()

func _set_stone() -> void:
	if _stones[_sel].placed:
		return
	var sz := _size_of(_sel)
	if not Walling.can_place(_grid, _cur.x, _cur.y, sz.x, sz.y):
		_msg = "It won't sit there. Stones need something under them."
		_refresh()
		return
	Walling.place(_grid, _sel + 1, _cur.x, _cur.y, sz.x, sz.y)
	_stones[_sel].placed = true
	_stones[_sel].x = _cur.x
	_stones[_sel].y = _cur.y
	_order.append(_sel)
	Audio.sfx("item")
	if Walling.solved(_grid):
		_msg = "That's a wall."
		_refresh()
		get_tree().create_timer(1.0).timeout.connect(func():
			await PiecePrompt.after_game(self, "walling", 1.0 if _backs > 0 else 2.0)
			close({"built": true}))
		return
	_sel = _next_free(_sel, 1)
	_turned = false
	_msg = ""
	_refresh()

func _take_back() -> void:
	if _order.is_empty():
		return
	_backs += 1
	var last: int = _order.pop_back()
	Walling.remove(_grid, last + 1)
	_stones[last].placed = false
	_sel = last
	_turned = false
	_msg = "Stone back on the pile."
	_refresh()

func _on_cancel() -> void:
	close({"built": false})

func _refresh() -> void:
	if _info == null or _puzzle.is_empty():
		return
	var left := _stones.filter(func(s): return not s.placed).size()
	_info.text = "Stones left: %d\nGap still open: %d\n\n%s" % [left, Walling.open_cells(_grid), _msg]

func _draw_stage() -> void:
	if _puzzle.is_empty():
		return
	var w := int(_puzzle.w)
	var h := int(_puzzle.h)
	var cell := minf(46.0, (_stage.size.x - 20.0) / float(w))
	var origin := Vector2(10, 40)
	_stage.draw_rect(Rect2(origin - Vector2(6, 6), Vector2(w, h) * cell + Vector2(12, 12)), Color("3a3f2c"))
	for y in h:
		for x in w:
			var v := int(_grid[y][x])
			var r := Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell))
			if v != 0:
				_stage.draw_rect(r.grow(-1), STONE[v % STONE.size()])
			else:
				_stage.draw_rect(r.grow(-1), Color("26291d"))
	# the stone in hand, ghosted at the cursor
	if not _stones.is_empty() and not _stones[_sel].placed:
		var sz := _size_of(_sel)
		var ok := Walling.can_place(_grid, _cur.x, _cur.y, sz.x, sz.y)
		var col := Color(0.4, 0.8, 0.4, 0.55) if ok else Color(0.8, 0.35, 0.35, 0.55)
		_stage.draw_rect(Rect2(origin + Vector2(_cur) * cell, Vector2(sz) * cell), col)
		if _show_hint:
			var hm: Vector2i = _stones[_sel].home
			_stage.draw_rect(Rect2(origin + Vector2(hm) * cell, Vector2(_stones[_sel].w, _stones[_sel].h) * cell), Color(1, 1, 1, 0.25), false, 3.0)
	# the pile along the bottom
	var px := 10.0
	var py := origin.y + float(h) * cell + 30.0
	for i in _stones.size():
		if _stones[i].placed:
			continue
		var s: Dictionary = _stones[i]
		var pr := Rect2(Vector2(px, py), Vector2(s.w, s.h) * 18.0)
		_stage.draw_rect(pr, STONE[(i + 1) % STONE.size()])
		if i == _sel:
			_stage.draw_rect(pr.grow(3), UIKit.GOLD, false, 2.0)
		px += float(s.w) * 18.0 + 10.0
		if px > _stage.size.x - 80.0:
			px = 10.0
			py += 50.0
