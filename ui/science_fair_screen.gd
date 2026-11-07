extends MenuBase
## A science fair puzzle (see ScienceFair): binary lamps, a shift cipher or a strand of DNA. Closes with
## {"solved": true|false}. setup arg: "<kind>[:hard]" (binary | cipher | dna); "dev" or "" picks binary.

const LAMP_ON := Color("ffd25e")
const LAMP_OFF := Color("3a3f52")
const BASE_COL := {"A": Color("5fb36b"), "T": Color("d0604f"), "C": Color("4f8fd0"), "G": Color("e0b24a"), "?": Color("454d63")}

var _p: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _cur := 0
var _lamps: Array = []
var _guess := 0
var _answer: Array = []      # dna: the partner letters typed so far ("?" for blank)
var _stage: Control
var _info: Label
var _msg := ""
var _done_puzzle := false

func _build() -> void:
	set_title("Science Fair")
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(0, 300)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	var card := UIKit.panel(Color("1d2230f0"), 14)
	root.add_child(card)
	_info = UIKit.label("", 20, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(_info)

func setup(arg: String) -> void:
	var parts := arg.split(":")
	var kind := parts[0] if parts[0] in ScienceFair.KINDS else "binary"
	_p = ScienceFair.make(kind, _rng, parts.size() > 1 and parts[1] == "hard")
	set_title(str(ScienceFair.TITLES.get(kind, "Science Fair")))
	match kind:
		"binary":
			_lamps = []
			for i in int(_p.bits):
				_lamps.append(false)
			set_hints([["leftright", "Lamp"], ["confirm", "Switch"], ["cancel", "Give up"]])
		"cipher":
			set_hints([["leftright", "Turn the wheel"], ["confirm", "That's it"], ["cancel", "Give up"]])
		"dna":
			_answer = []
			for i in str(_p.strand).length():
				_answer.append("?")
			set_hints([["leftright", "Letter"], ["updown", "A, C, G or T"], ["confirm", "Check"], ["cancel", "Give up"]])
	_refresh()

func _process(_delta: float) -> void:
	if _p.is_empty() or _done_puzzle or _locked:
		return
	var kind := str(_p.kind)
	var lr := 0
	if Input.is_action_just_pressed("move_left"):
		lr = -1
	elif Input.is_action_just_pressed("move_right"):
		lr = 1
	var ud := 0
	if Input.is_action_just_pressed("move_up"):
		ud = -1
	elif Input.is_action_just_pressed("move_down"):
		ud = 1
	var ok := Input.is_action_just_pressed("confirm")
	match kind:
		"binary":
			if lr != 0:
				_cur = clampi(_cur + lr, 0, _lamps.size() - 1)
				Audio.sfx("cursor")
			if ok:
				_lamps[_cur] = not _lamps[_cur]
				Audio.sfx("item")
				if ScienceFair.solved(_p, _lamps):
					_win("%d. Spot on: that's how the Baby would hold it." % int(_p.target))
		"cipher":
			if lr != 0:
				_guess = posmod(_guess + lr, 26)
				Audio.sfx("cursor")
			if ok:
				if ScienceFair.solved(_p, _guess):
					_win("%s. Cracked it. Caesar would be livid." % str(_p.word))
				else:
					Audio.sfx("bump")
					_msg = "That doesn't read as a word yet. Keep turning."
		"dna":
			if lr != 0:
				_cur = clampi(_cur + lr, 0, _answer.size() - 1)
				Audio.sfx("cursor")
			if ud != 0:
				var at := ScienceFair.BASES.find(str(_answer[_cur]))
				_answer[_cur] = ScienceFair.BASES[posmod((at if at >= 0 else (-1 if ud > 0 else 0)) + ud, 4)]
				Audio.sfx("cursor")
			if ok:
				var typed := "".join(PackedStringArray(_answer))
				if ScienceFair.solved(_p, typed):
					_win("Zipped. Every A has its T, every C its G.")
				else:
					Audio.sfx("bump")
					var wrong := 0
					for i in _answer.size():
						if str(_answer[i]) != ScienceFair.partner(str(_p.strand))[i]:
							wrong += 1
					_msg = "%d letter%s don't pair up yet." % [wrong, "" if wrong == 1 else "s"]
	if lr != 0 or ud != 0 or ok:
		_refresh()

func _win(line: String) -> void:
	_done_puzzle = true
	_msg = line
	Audio.sfx("badge")
	_refresh()
	get_tree().create_timer(1.6).timeout.connect(func():
		await PiecePrompt.after_game(self, "science", float(PartyPieces.state(Game.data, "science").plays + 1))
		close({"solved": true}))

func _on_cancel() -> void:
	close({"solved": false})

func _refresh() -> void:
	if _info == null or _p.is_empty():
		return
	var kind := str(_p.kind)
	var lead := ""
	match kind:
		"binary":
			lead = "Make %d. You're showing %d." % [int(_p.target), ScienceFair.lamps_value(_lamps)]
		"cipher":
			lead = "Coded: %s    Wheel turned back %d: %s" % [str(_p.coded), _guess, ScienceFair.decode(_p, _guess)]
		"dna":
			lead = "Write the partner strand underneath."
	_info.text = "%s\n%s%s" % [lead, ("\n" + _msg + "\n") if _msg != "" else "", str(ScienceFair.TIPS.get(kind, ""))]
	_stage.queue_redraw()

func _draw_stage() -> void:
	if _p.is_empty():
		return
	var font := get_theme_default_font()
	var w := _stage.size.x
	match str(_p.kind):
		"binary":
			var n := _lamps.size()
			var cell := minf(110.0, (w - 40.0) / float(n))
			var x0 := (w - cell * n) / 2.0
			var vals := ScienceFair.place_values(n)
			for i in n:
				var c := Vector2(x0 + cell * (i + 0.5), 120)
				var r := cell * 0.36
				_stage.draw_circle(c, r + 4, UIKit.GOLD if i == _cur else Color("262b3a"))
				_stage.draw_circle(c, r, LAMP_ON if _lamps[i] else LAMP_OFF)
				_stage.draw_string(font, c + Vector2(-cell / 2, r + 44), str(vals[i]), HORIZONTAL_ALIGNMENT_CENTER, cell, 26, UIKit.CREAM)
				_stage.draw_string(font, c + Vector2(-cell / 2, -r - 18), "1" if _lamps[i] else "0", HORIZONTAL_ALIGNMENT_CENTER, cell, 24, UIKit.MUTED)
		"cipher":
			var dec := ScienceFair.decode(_p, _guess)
			var coded := str(_p.coded)
			var cell := minf(64.0, (w - 40.0) / float(coded.length()))
			var x0 := (w - cell * coded.length()) / 2.0
			for i in coded.length():
				_stage.draw_string(font, Vector2(x0 + cell * i, 90), coded[i], HORIZONTAL_ALIGNMENT_CENTER, cell, 40, UIKit.MUTED)
				_stage.draw_string(font, Vector2(x0 + cell * i, 170), dec[i], HORIZONTAL_ALIGNMENT_CENTER, cell, 48, UIKit.GOLD)
			# the wheel: the alphabet against itself, shifted
			var a := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			var cw := minf(34.0, (w - 20.0) / 26.0)
			var ax := (w - cw * 26.0) / 2.0
			for i in 26:
				_stage.draw_string(font, Vector2(ax + cw * i, 230), a[i], HORIZONTAL_ALIGNMENT_CENTER, cw, 20, UIKit.CREAM)
				_stage.draw_string(font, Vector2(ax + cw * i, 258), a[posmod(i - _guess, 26)], HORIZONTAL_ALIGNMENT_CENTER, cw, 20, UIKit.GOLD)
		"dna":
			var s := str(_p.strand)
			var cell := minf(80.0, (w - 40.0) / float(s.length()))
			var x0 := (w - cell * s.length()) / 2.0
			for i in s.length():
				var top := Rect2(Vector2(x0 + cell * i + 6, 50), Vector2(cell - 12, 60))
				var bot := Rect2(Vector2(x0 + cell * i + 6, 170), Vector2(cell - 12, 60))
				_stage.draw_rect(top, BASE_COL[s[i]])
				var mine := str(_answer[i])
				_stage.draw_rect(bot, BASE_COL.get(mine, BASE_COL["?"]))
				_stage.draw_line(Vector2(top.get_center().x, 110), Vector2(top.get_center().x, 170), Color("8a90a6"), 3.0)
				_stage.draw_string(font, top.position + Vector2(0, 44), s[i], HORIZONTAL_ALIGNMENT_CENTER, top.size.x, 34, UIKit.SLATE)
				_stage.draw_string(font, bot.position + Vector2(0, 44), mine, HORIZONTAL_ALIGNMENT_CENTER, bot.size.x, 34, UIKit.SLATE if mine != "?" else UIKit.CREAM)
				if i == _cur:
					_stage.draw_rect(bot.grow(4), UIKit.GOLD, false, 3.0)
