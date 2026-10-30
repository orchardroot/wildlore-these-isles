extends MenuBase
## The Keepers page (an Almanac page, wave 47): every Keeper you have met or whose town you have visited, with
## their portrait, the types they lean on, the types that bite them, the team found out so far (silhouettes for the
## rest), the gossip gathered and whether you have beaten them. See KeeperIntel.

const ROW_H := 34

var _detail: VBoxContainer
var _buttons: Array = []
var _ids: Array = []

func _build() -> void:
	set_title("Keepers")
	var ks := KeeperIntel.known_ids(Game.data)
	header_right.text = "%d of %d" % [ks.size(), KeeperIntel.ids().size()]
	set_hints([["updown", "Choose"], ["cancel", "Back"]])
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 18)
	content.add_child(row)
	var lp := UIKit.panel(Color("1d2230f0"), 12)
	lp.custom_minimum_size = Vector2(300, 0)
	row.add_child(lp)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	lp.add_child(list)
	for k in ks:
		var done := KeeperIntel.beaten(Game.data, str(k))
		var b := make_button(("✓ " if done else "") + KeeperIntel.name_of(str(k)), func(): pass)
		b.custom_minimum_size = Vector2(270, ROW_H)
		b.add_theme_font_size_override("font_size", 21)
		UIKit.compact(b, 1)
		b.focus_entered.connect(_show.bind(str(k)))
		list.add_child(b)
		_buttons.append(b)
		_ids.append(str(k))
	var rp := UIKit.panel(Color("1d2230f0"), 18)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rp)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 8)
	rp.add_child(_detail)
	UIKit.wrap_focus(_buttons)
	if not _buttons.is_empty():
		UIKit.focus_later(_buttons[0])
		_show(_ids[0])

func _portrait(k: String) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var path := "res://art/sprites/chars/keeper_%s.png" % k
	if ResourceLoader.exists(path):
		var sheet: Texture2D = load(path)
		var a := AtlasTexture.new()
		a.atlas = sheet
		var fw := sheet.get_width() / 3.0
		var fh := sheet.get_height() / 4.0
		a.region = Rect2(0, 0, fw, fh)
		tr.texture = a
	tr.custom_minimum_size = Vector2(96, 144)
	return tr

func _chips_row(title: String, ts: Array, gold: bool) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := UIKit.label(title, 20, UIKit.GOLD if gold else UIKit.MUTED)
	l.custom_minimum_size.x = 130
	h.add_child(l)
	for t in ts:
		var c := UIKit.type_chip(str(t), 18)
		if gold:
			c.add_theme_stylebox_override("panel", UIKit.box(TypeColours.colour(str(t)), UIKit.GOLD, 3, 10, 5))
		h.add_child(c)
	return h

func _show(k: String) -> void:
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	var d: GameStateData = Game.data
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	_detail.add_child(top)
	top.add_child(_portrait(k))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 6)
	top.add_child(tv)
	tv.add_child(UIKit.label(KeeperIntel.name_of(k), 32, UIKit.GOLD))
	var done := KeeperIntel.beaten(d, k)
	tv.add_child(UIKit.label("Beaten. The Stone is yours." if done else "Not beaten yet", 20, UIKit.CREAM if done else UIKit.MUTED))
	tv.add_child(UIKit.label("Hall: " + str(KeeperIntel.town(k)).capitalize(), 18, UIKit.MUTED))
	tv.add_child(_chips_row("LEANS ON", KeeperIntel.types(k), false))
	tv.add_child(_chips_row("BITES", KeeperIntel.beats(k, Game.chart), true))
	_detail.add_child(UIKit.label("Team found out", 22, UIKit.GOLD))
	var tm := KeeperIntel.team(k)
	var known := KeeperIntel.team_known(d, k)
	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 14)
	for i in tm.size():
		var sp: Dictionary = Game.dex.get_species(str(tm[i]))
		var col := VBoxContainer.new()
		var img := TextureRect.new()
		img.texture = CreatureArt.icon(sp)
		img.custom_minimum_size = Vector2(64, 64)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var seen: bool = tm[i] in known
		if not seen:
			img.modulate = Color(0.04, 0.04, 0.07, 0.9)  # a silhouette
		col.add_child(img)
		var nm := UIKit.label(str(sp.get("name", "?")) if seen else "?", 15, UIKit.CREAM if seen else UIKit.MUTED)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(nm)
		tr.add_child(col)
	_detail.add_child(tr)
	_detail.add_child(UIKit.label("What they say about %s" % KeeperIntel.name_of(k), 22, UIKit.GOLD))
	var hs := KeeperIntel.hints(d, k)
	if hs.is_empty():
		var none := UIKit.label("Nothing yet. The residents of %s may know more." % KeeperIntel.town(k).capitalize(), 18, UIKit.MUTED)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.custom_minimum_size.x = 640
		_detail.add_child(none)
	for h in hs:
		var l := UIKit.label("“" + str(h) + "”", 17, UIKit.CREAM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 640
		_detail.add_child(l)

func _on_cancel() -> void:
	close(null)
