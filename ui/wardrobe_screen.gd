extends MenuBase
## The Wardrobe (4.6): what you're wearing, slot by slot, from the clothes in your Bag (kind "wear"), with you in the
## middle from all four sides. At a mirror (setup "mirror": Mum's house, see LooksMirror) your hair style and colour
## are free to change too; from the pause menu they're shown but fixed. Left / Right or Confirm changes a row;
## "Nothing" takes it off. Dev: `--menu=wardrobe[:mirror]`.

const SLOT_NAMES := {"hat": "Hat", "top": "Top", "bottom": "Bottom", "shoes": "Shoes", "coat": "Coat", "neck": "Neck", "face": "Face", "hands": "Hands", "back": "Back"}
const SCALE := 4.0

var _mirror := false
var _rows: Array = []        # [{key, button}] in focus order
var _frames: Dictionary = {} # facing -> TextureRect
var _items: ItemDB
var _bag: Bag
var _rows_col: VBoxContainer
var _say: Label

func _build() -> void:
	set_title("Wardrobe")
	set_hints([["leftright", "Change"], ["confirm", "Next"], ["cancel", "Done"]])
	_items = Game.items
	_bag = Bag.new(Game.data.bag)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 26)
	content.add_child(row)
	var left := UIKit.panel(Color("1d2230f0"), 16)
	left.custom_minimum_size = Vector2(32 * SCALE * 2 + 60, 0)
	row.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	left.add_child(lv)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lv.add_child(grid)
	for facing in ["down", "left", "right", "up"]:
		var tr := LookArt.frame_rect(_recipe(), facing, SCALE)
		grid.add_child(tr)
		_frames[facing] = tr
	_say = UIKit.label("", 22, UIKit.MUTED)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(_say)
	var right := UIKit.panel(Color("1d2230f0"), 14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var sc := ScrollContainer.new()  # eleven rows and two buttons: the list scrolls with the focus
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	right.add_child(sc)
	_rows_col = VBoxContainer.new()
	_rows_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_col.add_theme_constant_override("separation", 4)
	sc.add_child(_rows_col)
	_draw_rows()

func setup(arg: String) -> void:
	_mirror = arg == "mirror"
	_draw_rows()

func _recipe() -> Dictionary:
	return Looks.recipe(Game.data, _items)

func _base() -> Dictionary:
	return Looks.base(Game.data)

## The choices a row cycles through, as [value, shown name] pairs. A slot's are Nothing plus the clothes you own
## for it (and whatever's on, so it can always come off).
func _choices(key: String) -> Array:
	match key:
		"hair":
			return Looks.hair_styles().map(func(h): return [str(h.id), str(h.name)])
		"hair_colour":
			var out := []
			for i in Looks.hair_colours().size():
				out.append([i, str(Looks.hair_colours()[i].name)])
			return out
	var out := [["", "Nothing"]]
	var owned := _bag.items_of_kind("wear", _items).filter(func(id): return str(_items.get_item(id).get("slot", "")) == key)
	var on := Looks.worn(Game.data, key)
	if on != "" and not on in owned:
		owned.push_front(on)
	for id in owned:
		out.append([id, str(_items.get_item(id).get("name", id))])
	return out

func _current(key: String) -> Variant:
	match key:
		"hair":
			return str(_base().hair)
		"hair_colour":
			return int(_base().hair_colour)
	return Looks.worn(Game.data, key)

func _shown(key: String) -> String:
	var cur = _current(key)
	for ch in _choices(key):
		if ch[0] == cur:
			return str(ch[1])
	return "Nothing"

func _draw_rows() -> void:
	UIKit.clear(_rows_col)
	_rows.clear()
	var b := _base()
	if _mirror:
		_rows_col.add_child(UIKit.label("In the mirror", 22, UIKit.MUTED))
		for key in ["hair", "hair_colour"]:
			_add_row(key, "Hair" if key == "hair" else "Hair colour")
		_rows_col.add_child(UIKit.spacer(6))
	else:
		var hc := str(Looks.hair_colours()[clampi(int(b.hair_colour), 0, Looks.hair_colours().size() - 1)].name).to_lower()
		var hs := "short"
		for h in Looks.hair_styles():
			if str(h.id) == str(b.hair):
				hs = str(h.name).to_lower()
		_rows_col.add_child(UIKit.label("Hair: %s, %s. Change it in the mirror at home." % [hs, hc], 22, UIKit.MUTED))
	_rows_col.add_child(UIKit.label("Wearing", 22, UIKit.MUTED))
	for slot in Looks.SLOTS:
		_add_row(slot, str(SLOT_NAMES[slot]))
	_rows_col.add_child(UIKit.spacer(6))
	var off := make_button("Take it all off", _take_all_off)
	off.custom_minimum_size = Vector2(0, 40)
	_rows_col.add_child(off)
	_rows.append({"key": "", "button": off})
	var done := make_button("Done", func(): close(null))
	done.custom_minimum_size = Vector2(0, 40)
	_rows_col.add_child(done)
	_rows.append({"key": "", "button": done})
	UIKit.wrap_focus(_rows.map(func(r): return r.button))
	_refresh()
	UIKit.focus_later(_rows[0].button)

func _add_row(key: String, name: String) -> void:
	var b := make_button("", func(): _cycle(key, 1))
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 24)
	b.set_meta("row_name", name)
	_rows_col.add_child(b)
	_rows.append({"key": key, "button": b})

func _cycle(key: String, dir: int) -> void:
	var ch := _choices(key)
	if ch.size() <= 1 and key in Looks.SLOTS:
		_say.text = "Nothing to wear there yet. The boutiques round the Isles sell clothes."
		Audio.sfx("bump")
		return
	var cur = _current(key)
	var i := 0
	for k in ch.size():
		if ch[k][0] == cur:
			i = k
	i = posmod(i + dir, ch.size())
	var v = ch[i][0]
	match key:
		"hair":
			Looks.set_hair(Game.data, str(v), int(_base().hair_colour))
		"hair_colour":
			Looks.set_hair(Game.data, str(_base().hair), int(v))
		_:
			if str(v) == "":
				Looks.take_off(Game.data, key)
			else:
				Looks.wear(Game.data, str(v), _items)
	_say.text = ""
	_refresh()

func _take_all_off() -> void:
	for slot in Looks.SLOTS:
		Looks.take_off(Game.data, slot)
	_say.text = "Back to basics."
	_refresh()

func _refresh() -> void:
	var r := _recipe()
	for facing in _frames:
		_frames[facing].texture = LookArt.frame(r, facing)
	for row in _rows:
		if str(row.key) != "":
			row.button.text = "%s:  %s" % [str(row.button.get_meta("row_name")), _shown(str(row.key))]

func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	var dir := 0
	if event.is_action_pressed("move_right"):
		dir = 1
	elif event.is_action_pressed("move_left"):
		dir = -1
	if dir != 0:
		var f := get_viewport().gui_get_focus_owner()
		for row in _rows:
			if row.button == f and str(row.key) != "":
				get_viewport().set_input_as_handled()
				_cycle(str(row.key), dir)
				return
	super._input(event)
