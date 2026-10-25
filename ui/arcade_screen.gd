extends MenuBase
## The seaside arcade (story command {"do": "arcade"}): three machines in one cabinet row. Up and Down choose the
## machine, Left and Right aim, Confirm drops a coin (or lowers the claw). The pusher's shelf glides to and fro:
## drop where it is. Easier pub games (Settings) slows the shelf, widens the sweet spot and the claw's reach.
## Coins live in the save (Arcade); nothing here ever pays out pounds. setup arg: "<town>" (dev: "dev", "dev:claw", "dev:falls").

const W := 560.0
const H := 380.0
const NAMES := ["2p Coin Pusher", "Claw Grabber", "Penny Falls"]
const SLOTS := [0.2, 0.5, 0.8]
const STEP := 0.55          # across the cabinet per second, holding Left or Right

var _town := "blackpool"
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _machine := 0
var _x := [0.5, 0.5, 0.5]
var _t := 0.0
var _wait := 0.4
var _msg := ""
var _easy := false
var _pusher := Arcade.pusher_new()
var _falls: Dictionary
var _claw_y := 0.0          # 0 up, 1 down: the claw's little drop animation
var _claw_res: Dictionary = {}
var _stage: Control
var _info: Label
var _hint_l: Label

func _build() -> void:
	set_title("Arcade")
	_easy = Settings.easy_darts
	_falls = Arcade.falls_new(_rng)
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	content.add_child(root)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(W + 20.0, H + 20.0)
	root.add_child(holder)
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.draw.connect(_draw_stage)
	holder.add_child(_stage)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 12)
	root.add_child(side)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_info)
	_hint_l = UIKit.label("", 22, UIKit.GOLD)
	_hint_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_hint_l)
	set_hints([["confirm", "Drop"], ["cancel", "Leave"]])
	_msg = "Up and Down change machine. Left and Right aim."
	_refresh()

func setup(arg: String) -> void:
	_town = arg if Arcade.towns().has(arg) else "blackpool"
	if arg.begins_with("dev"):
		var d := Game.data
		Arcade.win_coins(d, 140)
		Arcade.win_tokens(d, 5)
		_machine = {"dev:claw": 1, "dev:falls": 2}.get(arg, 0)
		_x = [0.5, 0.5, 0.5]
		_falls.ledge = [3, 7, 0, 5, 9]
		_t = 0.9
		_pusher.pile = 11
		_msg = ["Drop where the shelf is.", "Line the claw up over a toy, then drop. It is not a strong claw.", "Back a ledge that is filling. They tip when they tip."][_machine]
	_refresh()

func _process(delta: float) -> void:
	_t += delta
	_wait = maxf(0.0, _wait - delta)
	if _claw_res.size() > 0:
		_claw_y = clampf(_claw_y + delta * 2.2, 0.0, 1.0)
	if _wait <= 0.0:
		_claw_res = {} if _claw_y >= 1.0 else _claw_res
		var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if _machine == 2:
			if Input.is_action_just_pressed("move_left"):
				_x[2] = clampf(float(_x[2]) - 1.0 / (Arcade.LANES - 1), 0.0, 1.0)
			elif Input.is_action_just_pressed("move_right"):
				_x[2] = clampf(float(_x[2]) + 1.0 / (Arcade.LANES - 1), 0.0, 1.0)
		elif v.x != 0.0:
			_x[_machine] = clampf(float(_x[_machine]) + v.x * STEP * delta, 0.0, 1.0)
		if Input.is_action_just_pressed("move_up"):
			_switch(-1)
		elif Input.is_action_just_pressed("move_down"):
			_switch(1)
		elif Input.is_action_just_pressed("confirm"):
			_drop()
	_stage.queue_redraw()

func _switch(dir: int) -> void:
	_machine = posmod(_machine + dir, 3)
	_claw_y = 0.0
	_claw_res = {}
	_wait = 0.15
	Audio.sfx("cursor")
	_msg = ["Drop where the shelf is.", "Line the claw up over a toy, then drop. It is not a strong claw.", "Back a ledge that is filling. They tip when they tip."][_machine]
	_refresh()

func _on_cancel() -> void:
	close({})

func _drop() -> void:
	var d := Game.data
	var cost := Arcade.CLAW_COST if _machine == 1 else 1
	if not Arcade.spend(d, cost):
		_msg = "Out of coins. Back to the counter."
		Audio.sfx("cancel")
		_refresh()
		return
	_wait = 0.35
	Audio.sfx("cursor")
	match _machine:
		0:
			var r := Arcade.pusher_drop(_pusher, float(_x[0]), _t, _easy, _rng)
			Arcade.win_coins(d, int(r.out))
			if r.token:
				Arcade.win_tokens(d, 1)
			_msg = "%s%s%s" % ["The shelf was right under it. " if r.sweet else "It lands on the pile. ", "%d come off the front. " % int(r.out) if r.out > 0 else "Nothing moves. ", "A prize token drops out too!" if r.token else ""]
		1:
			var r2 := Arcade.claw_play(float(_x[1]), SLOTS, Arcade.miss_streak(d), _easy, _rng)
			var id := Arcade.claw_result(d, r2, _town, _rng)
			_claw_res = r2
			_claw_y = 0.0
			_wait = 0.9
			_msg = str(r2.line)
			if id != "":
				_msg += " You won %s!" % str(Game.items.get_item(id).get("one", id))
				Audio.sfx("item")
			elif Arcade.miss_streak(d) >= Arcade.PITY:
				_msg += " The attendant has loosened the claw for your next go."
		2:
			var lane := int(roundf(float(_x[2]) * (Arcade.LANES - 1)))
			var r3 := Arcade.falls_drop(_falls, lane, _rng)
			Arcade.win_coins(d, int(r3.out))
			if r3.token:
				Arcade.win_tokens(d, 1)
			_msg = ("The ledge tips and %d coins fall! %s" % [int(r3.out), "And a prize token." if r3.token else ""]) if r3.fell else "Clink. The ledge creeps forward."
	_refresh()

func _refresh() -> void:
	if _info == null:
		return
	var d := Game.data
	_info.text = "%s\nCoins: %d    Tokens: %d\n\n%s" % [NAMES[_machine], Arcade.coins(d), Arcade.tokens(d), _msg]
	_hint_l.text = "A claw go costs %d coins. %d tokens buys a toy at the counter." % [Arcade.CLAW_COST, Arcade.TOKENS_PER_TOY]

# ---- drawing

func _draw_stage() -> void:
	var s := _stage
	var o := Vector2(10, 10)
	s.draw_rect(Rect2(o, Vector2(W, H)), Color("2a1f3d"))
	s.draw_rect(Rect2(o, Vector2(W, H)), Color("e8c872"), false, 4.0)
	for i in 3:
		var col := UIKit.GOLD if i == _machine else Color("6b5a82")
		s.draw_string(ThemeDB.fallback_font, o + Vector2(14 + i * 180, 30), NAMES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
	match _machine:
		0:
			_draw_pusher(o)
		1:
			_draw_claw(o)
		2:
			_draw_falls(o)

func _draw_pusher(o: Vector2) -> void:
	var s := _stage
	var x0 := o.x + 30.0
	var w := W - 60.0
	var shelf := Arcade.shelf_pos(_t, _easy)
	var win := Arcade.window(_easy)
	s.draw_rect(Rect2(x0, o.y + 70, w, 18), Color("4a3a66"))
	var lo := maxf(0.0, shelf - win)
	var hi := minf(1.0, shelf + win)
	s.draw_rect(Rect2(x0 + lo * w, o.y + 70, (hi - lo) * w, 18), Color("e8c872"))
	s.draw_colored_polygon(PackedVector2Array([Vector2(x0 + float(_x[0]) * w, o.y + 108), Vector2(x0 + float(_x[0]) * w - 10, o.y + 90), Vector2(x0 + float(_x[0]) * w + 10, o.y + 90)]), Color("ffffff"))
	var n: int = _pusher.pile
	for i in mini(n, 40):
		var cx := x0 + 40.0 + float(i % 10) * (w - 80.0) / 9.0
		var cy := o.y + 300.0 - float(i / 10) * 26.0
		s.draw_circle(Vector2(cx, cy), 13.0, Color("b87333"))
		s.draw_arc(Vector2(cx, cy), 13.0, 0.0, TAU, 14, Color("5a3414"), 2.0)
	s.draw_string(ThemeDB.fallback_font, Vector2(x0, o.y + 350), "Pile on the shelf: %d" % n, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.CREAM)

func _draw_claw(o: Vector2) -> void:
	var s := _stage
	var x0 := o.x + 30.0
	var w := W - 60.0
	var cols := [Color("8a8a96"), Color("c9886a"), Color("7aa6c9")]
	for i in SLOTS.size():
		var c := Vector2(x0 + float(SLOTS[i]) * w, o.y + 300.0)
		s.draw_circle(c, 34.0, cols[i])
		s.draw_circle(c + Vector2(-11, -8), 4.0, Color.BLACK)
		s.draw_circle(c + Vector2(11, -8), 4.0, Color.BLACK)
	var cx := x0 + float(_x[1]) * w
	var cy := o.y + 70.0 + _claw_y * 170.0
	s.draw_line(Vector2(cx, o.y + 50), Vector2(cx, cy), Color("cccccc"), 3.0)
	s.draw_line(Vector2(cx, cy), Vector2(cx - 22, cy + 28), Color("cccccc"), 5.0)
	s.draw_line(Vector2(cx, cy), Vector2(cx + 22, cy + 28), Color("cccccc"), 5.0)

func _draw_falls(o: Vector2) -> void:
	var s := _stage
	var x0 := o.x + 50.0
	var w := W - 100.0
	for i in Arcade.LANES:
		var cx := x0 + float(i) * w / float(Arcade.LANES - 1)
		var sel := i == int(roundf(float(_x[2]) * (Arcade.LANES - 1)))
		s.draw_rect(Rect2(cx - 32, o.y + 60, 64, 260), Color("3a2c52") if not sel else Color("57437a"))
		for k in int(_falls.ledge[i]):
			s.draw_circle(Vector2(cx, o.y + 300.0 - float(k) * 17.0), 12.0, Color("b87333"))
		if sel:
			s.draw_colored_polygon(PackedVector2Array([Vector2(cx, o.y + 54), Vector2(cx - 10, o.y + 38), Vector2(cx + 10, o.y + 38)]), Color("ffffff"))
