extends MenuBase
## New game: make yourself (male or female, body, skin, hair, hair colour, top colour, or Randomise; see Looks) and type a
## name (keyboard or the on-screen letters), with you shown from all four sides as you go. Closes with
## {name, sprite, look}: `look` is the base look the save keeps, `sprite` the old player_a flag for the fallback path.
## Nickname mode (Router.open_menu("name:nickname:<party index>") or "name:nickname:ark:<ark index>"): text only,
## names that creature in place and closes with the new nickname ("" means back to its species name),
## or null if backed out without typing anything.

const MAX_LEN := 10
const ROWS := ["ABCDEFGHIJKLM", "NOPQRSTUVWXYZ", "abcdefghijklm", "nopqrstuvwxyz"]

const CHOOSERS := [["sex", "You"], ["build", "Body"], ["skin", "Skin"], ["hair", "Hair"], ["hair_colour", "Hair colour"], ["top", "Top"]]
const PREVIEW_SCALE := 2.5

var _name := "Sam"
var _sprite := "player_a"
var _base: Dictionary = Looks.starter("m")
var _touched := false  # once any other slider has moved, switching sex keeps your choices (else it follows the sex's starter)
var _shown: Label
var _looks: Array = []       # the creator's controls (hidden in nickname mode)
var _choosers: Array = []    # [{key, button}]
var _frames: Dictionary = {} # facing -> TextureRect
var _look_row: HBoxContainer
var _label: Label
var _nick: Creature = null  # the creature being nicknamed, in nickname mode

func _build() -> void:
	set_title("Who's setting off?")
	set_hints([["=Type your name, or pick letters", "", "kbd"], ["=Enter", "Done", "kbd"], ["=Backspace", "Delete", "kbd"],
		["=Pick letters", "", "pad"], ["confirm", "Choose", "pad"], ["cancel", "Delete", "pad"]])
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	content.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	col.add_child(top)
	_look_row = top
	# you, from all four sides, painted live from the look (LookArt)
	var pv := UIKit.panel(Color("1d2230f0"), 10)
	top.add_child(pv)
	_looks.append(pv)
	var pg := GridContainer.new()
	pg.columns = 2
	pg.add_theme_constant_override("h_separation", 10)
	pg.add_theme_constant_override("v_separation", 6)
	pv.add_child(pg)
	for facing in ["down", "left", "right", "up"]:
		var tr := LookArt.frame_rect(Looks.from_base(_base), facing, PREVIEW_SCALE)
		pg.add_child(tr)
		_frames[facing] = tr
	# the choosers: Left / Right or Confirm cycles each one
	var ch_col := VBoxContainer.new()
	ch_col.add_theme_constant_override("separation", 4)
	ch_col.custom_minimum_size = Vector2(330, 0)
	top.add_child(ch_col)
	_looks.append(ch_col)
	for pair in CHOOSERS:
		var key: String = pair[0]
		var b := make_button("", func(): _cycle(key, 1))
		b.add_theme_font_size_override("font_size", 24)
		b.set_meta("row_name", pair[1])
		ch_col.add_child(b)
		_slim(b, 36)
		_choosers.append({"key": key, "button": b})
	var rnd := make_button("Randomise", _randomise)
	rnd.add_theme_font_size_override("font_size", 24)
	ch_col.add_child(rnd)
	_slim(rnd, 36)
	_choosers.append({"key": "", "button": rnd})
	var nm := VBoxContainer.new()
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	_label = UIKit.label("Name", 24, UIKit.MUTED)
	nm.add_child(_label)
	_shown = UIKit.label("", 56, UIKit.GOLD)
	_shown.clip_text = true  # a long name never pushes the keyboard wider than the screen
	nm.add_child(_shown)
	var grid := GridContainer.new()
	grid.columns = 13
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	var keys := []
	for row in ROWS:
		for ch in row:
			var b := make_button(ch, func(): _type(ch), 64)
			b.custom_minimum_size = Vector2(84, 40)  # thirteen across the frame, each letter centred in its key
			b.alignment = HORIZONTAL_ALIGNMENT_CENTER
			grid.add_child(b)
			_slim(b, 40)
			keys.append(b)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	col.add_child(bottom)
	for pair in [["Space", func(): _type(" ")], ["Delete", _delete], ["Done", _done_pressed]]:
		var b := make_button(pair[0], pair[1], 200)
		bottom.add_child(b)
		_slim(b, 44)
	_refresh()
	UIKit.focus_later(_choosers[0].button)

func setup(arg: String) -> void:
	_nick = nickname_target(Game.data, arg)
	if _nick == null:
		return
	set_title("A name for %s?" % _nick.species.name)
	set_hints([["=Type a name, or pick letters", "", "kbd"], ["=Enter", "Done", "kbd"], ["=Backspace", "Delete", "kbd"],
		["=Pick letters", "", "pad"], ["confirm", "Choose", "pad"], ["cancel", "Delete", "pad"], ["=Blank", "Use the species name"]])
	_name = _nick.nickname
	_label.text = "Nickname"
	for b in _looks:
		b.visible = false
	var icon := AnimSprite.new()
	icon.show_species(_nick.species.id, "front", 2, false, _nick.variant, _nick.form, _nick.sex)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_look_row.add_child(icon)
	_look_row.move_child(icon, 0)
	if Sexes.valid(_nick.sex):  # "Female", with her sign, beside the picture
		var sx := HBoxContainer.new()
		sx.add_theme_constant_override("separation", 6)
		sx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sx.add_child(UIKit.sex_mark(_nick, 26))
		sx.add_child(UIKit.label(UIKit.sex_word(_nick), 24, Sexes.colour(_nick.sex)))
		_look_row.add_child(sx)
		_look_row.move_child(sx, 1)
	_refresh()

## The creature a "nickname:<i>" / "nickname:ark:<i>" argument points at, or null.
static func nickname_target(d: GameStateData, arg: String) -> Creature:
	var parts := arg.split(":")
	if parts.size() < 2 or parts[0] != "nickname":
		return null
	var list: Array = d.party
	var idx := parts[1]
	if parts[1] == "ark" and parts.size() > 2:
		list = d.ark
		idx = parts[2]
	if not idx.is_valid_int() or int(idx) < 0 or int(idx) >= list.size():
		return null
	return list[int(idx)]

## Sets (or, if blank or just the species name, clears) a creature's nickname.
static func apply_nickname(c: Creature, text: String) -> void:
	var n := clean(text)
	c.nickname = "" if n == "" or n == str(c.species.name) else n

## A button `h` px tall: the theme's top and bottom padding go, so the creator and the keyboard share one screen.
## Once the button is in the tree, so it sees the theme's boxes (the pause menu does the same).
static func _slim(b: Button, h: int) -> void:
	for state in ["normal", "hover", "focus", "pressed", "hover_pressed", "disabled"]:
		var sb := b.get_theme_stylebox(state)
		if sb == null:
			continue
		sb = sb.duplicate()
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
		b.add_theme_stylebox_override(state, sb)
	b.custom_minimum_size.y = h

## The values a chooser cycles through, as [value, shown name] pairs.
static func choices(key: String) -> Array:
	match key:
		"sex":
			return Looks.SEXES.map(func(x): return [x, Looks.SEX_NAMES[x]])
		"build":
			return Looks.builds().map(func(b): return [str(b.id), str(b.name)])
		"skin":
			return _indexed(Looks.skins())
		"hair":
			return Looks.hair_styles().map(func(h): return [str(h.id), str(h.name)])
		"hair_colour":
			return _indexed(Looks.hair_colours())
		"top":
			return _indexed(Looks.tops())
	return []

static func _indexed(list: Array) -> Array:
	var out := []
	for i in list.size():
		out.append([i, str(list[i].name)])
	return out

## The base look with chooser `key` moved `dir` steps round its choices (wrapping).
static func cycled(base: Dictionary, key: String, dir: int) -> Dictionary:
	var ch := choices(key)
	if ch.is_empty():
		return base
	var i := 0
	for k in ch.size():
		if ch[k][0] == base.get(key):
			i = k
	var out := base.duplicate(true)
	out[key] = ch[posmod(i + dir, ch.size())][0]
	return out

## A random base look (every chooser rolled).
static func random_base(rng: RandomNumberGenerator) -> Dictionary:
	var out := Looks.default_base()
	for pair in CHOOSERS:
		var ch := choices(pair[0])
		out[pair[0]] = ch[rng.randi_range(0, ch.size() - 1)][0]
	return out

func _cycle(key: String, dir: int) -> void:
	if key == "sex" and not _touched:  # the starting look follows the sex until you've moved something yourself
		_base = Looks.starter(str(cycled(_base, key, dir).sex))
	else:
		_base = cycled(_base, key, dir)
		_touched = _touched or key != "sex"
	_refresh()

func _randomise() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_base = random_base(rng)
	_touched = true
	_refresh()

func _type(ch: String) -> void:
	if _name.length() < MAX_LEN:
		_name += ch
	_refresh()

func _delete() -> void:
	_name = _name.left(maxi(0, _name.length() - 1))
	_refresh()

func _done_pressed() -> void:
	var n := clean(_name)
	if _nick != null:
		apply_nickname(_nick, n)
		Audio.sfx("confirm")
		_done = true
		closed.emit(_nick.nickname)
		return
	if n == "":
		Audio.sfx("bump")
		return
	close({"name": n, "sprite": _sprite, "look": _base})

func _on_cancel() -> void:
	if _nick != null and _name == "":
		close(null)  # nothing typed: back out, nickname unchanged
		return
	_delete()

## Keyboard typing comes first here: letters (Z and X included) and space type, Backspace deletes,
## Enter finishes. Arrows still move round the on-screen letters, and the pad works as everywhere else.
func _input(event: InputEvent) -> void:
	if _nick == null and not _locked and not _done:  # Left / Right on a chooser cycles it (pad and keyboard alike)
		var dir := 0
		if event.is_action_pressed("move_right"):
			dir = 1
		elif event.is_action_pressed("move_left"):
			dir = -1
		if dir != 0:
			var f := get_viewport().gui_get_focus_owner()
			for c in _choosers:
				if c.button == f and str(c.key) != "":
					get_viewport().set_input_as_handled()
					_cycle(str(c.key), dir)
					return
	var k := event as InputEventKey
	if k != null and k.pressed and not _locked and not _done:
		var ch := typed_char(k)
		if ch != "":
			_type(ch)
			get_viewport().set_input_as_handled()
			return
		if k.keycode == KEY_BACKSPACE:
			_delete()
			get_viewport().set_input_as_handled()
			return
		if k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
			_done_pressed()
			get_viewport().set_input_as_handled()
			return
	super._input(event)

## The character a key types, or "" for keys that don't type (Enter, arrows, modifiers).
static func typed_char(k: InputEventKey) -> String:
	if k.ctrl_pressed or k.meta_pressed or k.alt_pressed or k.unicode == 0:
		return ""
	var ch := char(k.unicode)
	if k.unicode == 32 or (k.unicode < 127 and ((ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or ch == "-" or ch == "'")):
		return ch
	return ""

func _refresh() -> void:
	_shown.text = _name + ("_" if _name.length() < MAX_LEN else "")
	if _nick != null:
		return
	var r := Looks.from_base(_base)
	for facing in _frames:
		_frames[facing].texture = LookArt.frame(r, facing)
	for c in _choosers:
		if str(c.key) == "":
			continue
		var shown := ""
		for ch in choices(str(c.key)):
			if ch[0] == _base.get(str(c.key)):
				shown = str(ch[1])
		c.button.text = "%s:  %s" % [str(c.button.get_meta("row_name")), shown]

## Trims spaces, collapses doubles, caps the length. Empty means "pick something".
static func clean(s: String) -> String:
	var out := s.strip_edges()
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.left(MAX_LEN)
