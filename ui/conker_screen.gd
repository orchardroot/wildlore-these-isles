extends MenuBase
## A conkers match (see Conkers): you and your rival take turns to swing. On your turn a marker sweeps the bar; press
## Confirm to stop it as close to the centre as you can. A true blow cracks the other conker, a perfect one cracks it
## twice. First conker to run out of hits breaks. Closes with {"won": bool}.
## setup arg: "<rival id>:<your conker's hits>" (dev: "dev" shows a match part way through).

const GOLD := Color("e8c45a")
const HIT := Color("6fbf73")
const MISSED := Color("c46a6a")
const SWEEP := 1.1       # seconds for the marker to cross the bar and back

var _rival: Dictionary
var _mine := 3
var _theirs := 3
var _my_max := 3
var _their_max := 3
var _turn := "me"        # "me" | "them" | "done"
var _t := 0.0
var _wait := 0.0         # pause after a swing so the result can be read
var _wide := 1.0
var _rng: Rng
var _stage: Control
var _info: Label
var _msg := ""

func _build() -> void:
	set_title("Conkers")
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
	set_hints([["confirm", "Swing"], ["cancel", "Pocket it"]])
	_refresh()

func setup(arg: String) -> void:
	var parts := arg.split(":")
	_rival = Conkers.rival("village" if arg.begins_with("dev") else parts[0])
	if _rival.is_empty():
		_rival = Conkers.rival("playground")
	_my_max = int(parts[1]) if parts.size() > 1 and not arg.begins_with("dev") else 4
	_their_max = int(_rival.hits)
	_mine = _my_max
	_theirs = _their_max
	_wide = 1.5 if Settings.easy_darts else 1.0
	_rng = Rng.new(int(Time.get_ticks_msec()))
	if arg.begins_with("dev"):
		_mine = 2
		_theirs = 2
	_msg = "Your swing."
	_refresh()

## Where the marker is, -1 to 1, bouncing across the bar.
func _marker() -> float:
	return sin(_t / SWEEP * TAU)

func _process(delta: float) -> void:
	if _rival.is_empty() or _turn == "done":
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_next()
		_stage.queue_redraw()
		return
	if _turn == "me":
		_t += delta
		if Input.is_action_just_pressed("confirm"):
			var q := Conkers.swing_quality(_marker(), _wide)
			_theirs = maxi(0, _theirs - Conkers.damage(q))
			_after("You swing: " + _describe(q) + ".", "them")
	else:
		var q2 := Conkers.rival_swing(float(_rival.skill), _rng)
		_mine = maxi(0, _mine - Conkers.damage(q2))
		_after("%s swings: %s." % [str(_rival.who).split(",")[0], _describe(q2)], "me")
	_stage.queue_redraw()

func _describe(q: String) -> String:
	return "a crack that rings" if q == "perfect" else ("a clip" if q == "good" else "a whistle through thin air")

func _after(msg: String, next: String) -> void:
	_msg = msg
	Audio.sfx("item" if "swing" in msg else "cancel")
	_turn = next
	_wait = 1.0
	_refresh()

func _next() -> void:
	if _theirs <= 0 or _mine <= 0:
		_turn = "done"
		var won := _theirs <= 0
		_msg += " Their conker flies apart!" if won else " Yours breaks!"
		_refresh()
		get_tree().create_timer(1.2).timeout.connect(func():
			await PiecePrompt.after_game(self, "conkers", float(maxi(_mine, 0)) if won else 0.0)
			close({"won": won}))
		return
	_t = 0.0
	_refresh()

func _on_cancel() -> void:
	close({"won": false, "quit": true})

func _refresh() -> void:
	if _info == null or _rival.is_empty():
		return
	_info.text = "%s against %s\nYour conker: %d of %d. Theirs: %d of %d.\n%s" % ["You", str(_rival.who), _mine, _my_max, _theirs, _their_max, _msg]

func _draw_stage() -> void:
	if _rival.is_empty():
		return
	var s := _stage.size
	var bar := Rect2(s.x * 0.15, s.y * 0.55, s.x * 0.7, 28.0)
	_stage.draw_rect(bar, Color("3a3226"))
	_stage.draw_rect(Rect2(bar.position.x + bar.size.x * (0.5 - 0.35 * 0.5 * _wide), bar.position.y, bar.size.x * 0.35 * _wide, bar.size.y), HIT.darkened(0.4))
	_stage.draw_rect(Rect2(bar.position.x + bar.size.x * (0.5 - 0.12 * 0.5 * _wide), bar.position.y, bar.size.x * 0.12 * _wide, bar.size.y), GOLD)
	var mx := bar.position.x + bar.size.x * (0.5 + 0.5 * _marker())
	_stage.draw_line(Vector2(mx, bar.position.y - 8), Vector2(mx, bar.position.y + bar.size.y + 8), UIKit.CREAM, 4.0)
	# the two conkers, shrinking as they crack
	_conker(Vector2(s.x * 0.25, s.y * 0.25), float(_mine) / float(maxi(1, _my_max)), GOLD)
	_conker(Vector2(s.x * 0.75, s.y * 0.25), float(_theirs) / float(maxi(1, _their_max)), MISSED)

func _conker(c: Vector2, share: float, ring: Color) -> void:
	var r := 18.0 + 22.0 * clampf(share, 0.0, 1.0)
	_stage.draw_line(Vector2(c.x, 0), Vector2(c.x, c.y - r), Color("c9b27c"), 3.0)
	_stage.draw_circle(c, r, Color("5a2d12"))
	_stage.draw_arc(c, r + 3.0, 0.0, TAU, 32, ring, 3.0)
