extends MenuBase
## New game: pick a look and type a name (keyboard or the on-screen letters). Closes with {name, sprite}.
## Nickname mode (Router.open_menu("name:nickname:<party index>") or "name:nickname:ark:<ark index>"): text only,
## names that creature in place and closes with the new nickname ("" means back to its species name),
## or null if backed out without typing anything.

const MAX_LEN := 10
const ROWS := ["ABCDEFGHIJKLM", "NOPQRSTUVWXYZ", "abcdefghijklm", "nopqrstuvwxyz"]

var _name := "Sam"
var _sprite := "player_a"
var _shown: Label
var _looks: Array = []
var _look_row: HBoxContainer
var _label: Label
var _nick: Creature = null  # the creature being nicknamed, in nickname mode

func _build() -> void:
	set_title("Who's setting off?")
	set_hints([["=Type your name, or pick letters", "", "kbd"], ["=Enter", "Done", "kbd"], ["=Backspace", "Delete", "kbd"],
		["=Pick letters", "", "pad"], ["confirm", "Choose", "pad"], ["cancel", "Delete", "pad"]])
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 14)
	content.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	col.add_child(top)
	_look_row = top
	for id in ["player_a", "player_b"]:
		var b := make_button("", func(): _pick_look(id), 150)
		b.custom_minimum_size = Vector2(150, 150)
		var tex := AtlasTexture.new()
		tex.atlas = load("res://art/sprites/chars/%s.png" % id)
		tex.region = Rect2(0, 0, 32, 48)  # facing down, standing
		var s := TextureRect.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		s.set_anchors_preset(Control.PRESET_FULL_RECT)
		s.offset_left = 10
		s.offset_top = 10
		s.offset_right = -10
		s.offset_bottom = -10
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(s)
		top.add_child(b)
		_looks.append(b)
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
			b.custom_minimum_size = Vector2(84, 52)  # thirteen across the frame, each letter centred in its key
			b.alignment = HORIZONTAL_ALIGNMENT_CENTER
			grid.add_child(b)
			keys.append(b)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	col.add_child(bottom)
	for pair in [["Space", func(): _type(" ")], ["Delete", _delete], ["Done", _done_pressed]]:
		var b := make_button(pair[0], pair[1], 200)
		bottom.add_child(b)
	_refresh()
	UIKit.focus_later(keys[0])

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

func _pick_look(id: String) -> void:
	_sprite = id
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
	close({"name": n, "sprite": _sprite})

func _on_cancel() -> void:
	if _nick != null and _name == "":
		close(null)  # nothing typed: back out, nickname unchanged
		return
	_delete()

## Keyboard typing comes first here: letters (Z and X included) and space type, Backspace deletes,
## Enter finishes. Arrows still move round the on-screen letters, and the pad works as everywhere else.
func _input(event: InputEvent) -> void:
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
	for i in _looks.size():
		_looks[i].modulate = Color.WHITE if ["player_a", "player_b"][i] == _sprite else Color(1, 1, 1, 0.45)

## Trims spaces, collapses doubles, caps the length. Empty means "pick something".
static func clean(s: String) -> String:
	var out := s.strip_edges()
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.left(MAX_LEN)
