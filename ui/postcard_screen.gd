extends MenuBase
## A postcard from Kit (see Postcards). setup("new:<id>,<id>") shows freshly collected cards one by one;
## setup("album") (the Postcard Album in the Bag) browses every card collected so far, Left/Right between them.
## setup("album:<id>") opens the album on that card, setup("<id>[:back]") shows one (screenshots).
## The front is the place itself (PostcardPicture); Confirm turns the card over to Kit's writing, the stamp and
## the postmark.

const CARD := Vector2(780, 520)  # with its tilt and shadow, clear of the hint bar
const PAPER := Color("f4ecd9")
const INK := Color("22305a")
const PRINT := Color("8a7d64")
const HAND := preload("res://art/fonts/caveat/Caveat.ttf")
const SERIF := preload("res://art/fonts/libre_baskerville/LibreBaskerville.ttf")
## Stamp panels by the nation the card was posted in.
const STAMP_COLOURS := {"england": Color("b23a3a"), "wales": Color("2f7a4a"), "scotland": Color("2f5c9a"),
	"ireland": Color("2f8a6a"), "northern_ireland": Color("6a4a8a"), "mann": Color("a8742a"), "overseas": Color("2f5fa8"), "channel_islands": Color("b8892a")}

var _ids: Array = []
var _i := 0
var _album := false
var _back := false
var _turning := false
var _card: Control
var _front: Control
var _picture: TextureRect
var _place_label: Label
var _back_side: Control

func _build() -> void:
	set_title("Post from Kit")
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(centre)
	var holder := Control.new()
	holder.custom_minimum_size = CARD
	centre.add_child(holder)
	_card = Control.new()
	_card.size = CARD
	_card.pivot_offset = CARD / 2.0
	_card.rotation = deg_to_rad(-1.2)
	holder.add_child(_card)
	_front = _build_front()
	_card.add_child(_front)
	_back_side = PostcardBack.new()
	_back_side.size = CARD
	_back_side.visible = false
	_card.add_child(_back_side)

func setup(arg: String) -> void:
	var cards := Postcards.cards()
	if arg.begins_with("new:"):
		_ids = Array(arg.substr(4).split(",", false)).filter(func(id): return not Postcards.card(id).is_empty())
	elif arg.begins_with("album"):
		_album = true
		_ids = Postcards.collected(Game.data)
		var want := arg.get_slice(":", 1) if arg.contains(":") else ""
		_i = maxi(0, _ids.find(want))
	else:
		var parts := arg.split(":")
		_ids = [parts[0]] if not Postcards.card(parts[0]).is_empty() else ([cards[0].id] if not cards.is_empty() else [])
		_back = parts.size() > 1 and parts[1] == "back"
	_show()

func _show() -> void:
	if _ids.is_empty():
		set_title("Postcard Album")
		header_right.text = "Empty"
		_card.visible = false
		var none := UIKit.label("No postcards yet. Kit will write once there's something to write about.", 26, UIKit.MUTED)
		none.set_anchors_preset(Control.PRESET_CENTER)
		content.add_child(none)
		set_hints([["cancel", "Back"]])
		return
	var c := Postcards.card(str(_ids[_i]))
	if _album:
		set_title("Postcard Album")
		header_right.text = "%d of %d    %d / %d collected" % [_i + 1, _ids.size(), _ids.size(), Postcards.cards().size()]
	else:
		set_title("Post from %s" % Game.data.rival_name)
		header_right.text = "%d of %d" % [_i + 1, _ids.size()] if _ids.size() > 1 else str(c.get("place", ""))
	_place_label.text = str(c.get("place", "")).to_upper()
	var pf := _place_label.get_theme_font("font")
	var ps := 62
	while ps > 40 and pf.get_string_size(_place_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ps).x > _place_label.size.x:
		ps -= 2  # a long place name steps down rather than lose its end off the card
	_place_label.add_theme_font_size_override("font_size", ps)
	_back_side.set_card(c, Postcards.card_index(str(c.id)) + 1, Postcards.cards().size(), str(Game.data.flag(Postcards.flag_key(str(c.id))) if Game.data.flag(Postcards.flag_key(str(c.id))) != null else Calendar.today_key()))
	_front.visible = not _back
	_back_side.visible = _back
	_picture.texture = null
	_set_hints()
	var tex := await PostcardPicture.render(self, c, Vector2i(CARD) * 2 - Vector2i(64, 64))
	if is_instance_valid(_picture) and _ids.size() > _i and str(_ids[_i]) == str(c.id):
		_picture.texture = tex

func _set_hints() -> void:
	var turn := "Read it" if not _back else "Look at the picture"
	if _album:
		set_hints([["leftright", "Browse"], ["confirm", turn], ["photo", "Save picture"], ["cancel", "Back"]])
	elif _back and _i < _ids.size() - 1:
		set_hints([["confirm", "Next card"], ["cancel", "Close"]])
	elif _back:
		set_hints([["confirm", "Done"], ["cancel", "Close"]])
	else:
		set_hints([["confirm", "Turn it over"], ["cancel", "Close"]])

func _input(event: InputEvent) -> void:
	if _locked or _done or _turning:
		return
	if event.is_action_pressed("photo") and _album and not _ids.is_empty():
		get_viewport().set_input_as_handled()
		_export()
		return
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		if _ids.is_empty():
			return
		if _back and not _album:
			if _i < _ids.size() - 1:
				Audio.sfx("confirm")
				_i += 1
				_back = false
				_show()
			else:
				close(null)
			return
		_turn()
		return
	if _album and _ids.size() > 1:
		var d := 0
		if event.is_action_pressed("move_left"):
			d = -1
		elif event.is_action_pressed("move_right"):
			d = 1
		if d != 0:
			get_viewport().set_input_as_handled()
			Audio.sfx("cursor")
			_i = posmod(_i + d, _ids.size())
			_back = false
			_show()
			return
	super._input(event)

## Saves the picture side as a PNG with its caption (see Share).
func _export() -> void:
	var tex: Texture2D = _picture.texture
	if tex == null:
		Audio.sfx("bump")
		return
	var c := Postcards.card(str(_ids[_i]))
	var place := str(c.get("place", ""))
	var day := Calendar.today_key()
	var path := await Share.export_image(self, tex.get_image(), Share.file_name("postcard", place, day), "Greetings from " + Share.caption(place, day),
		OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), DevArgs.is_dev_session(Game.args, DevArgs.user_args()))
	Audio.sfx("confirm" if path != "" else "bump")

## Turns the card over: squash to an edge, swap sides, open out again.
func _turn() -> void:
	_turning = true
	Audio.sfx("cursor")
	var tw := create_tween()
	tw.tween_property(_card, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	_back = not _back
	_front.visible = not _back
	_back_side.visible = _back
	_set_hints()
	tw = create_tween()
	tw.tween_property(_card, "scale:x", 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_turning = false

# --- the front -------------------------------------------------------------------

func _build_front() -> Control:
	var f := Panel.new()
	f.size = CARD
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f6efdf")
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 22
	sb.shadow_offset = Vector2(6, 10)
	f.add_theme_stylebox_override("panel", sb)
	var frame := Panel.new()  # the photograph, inset in its white border
	frame.position = Vector2(16, 16)
	frame.size = CARD - Vector2(32, 32)
	frame.clip_contents = true
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color("c9a27a")
	frame.add_theme_stylebox_override("panel", fsb)
	f.add_child(frame)
	_picture = TextureRect.new()
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame.add_child(_picture)
	var shade := TextureRect.new()  # a warm fade at the foot for the lettering, and a little vignette
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.texture = _fade()
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame.add_child(shade)
	var greet := Label.new()
	greet.text = "Greetings from"
	greet.add_theme_font_override("font", HAND)
	greet.add_theme_font_size_override("font_size", 44)
	greet.add_theme_color_override("font_color", Color("fff3d6"))
	greet.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.08, 0.6))
	greet.add_theme_constant_override("shadow_offset_x", 2)
	greet.add_theme_constant_override("shadow_offset_y", 2)
	greet.position = Vector2(30, frame.size.y - 150)
	greet.rotation = deg_to_rad(-4)
	frame.add_child(greet)
	_place_label = Label.new()
	var fv := FontVariation.new()
	fv.base_font = SERIF
	fv.spacing_glyph = 4
	fv.variation_embolden = 0.5
	_place_label.add_theme_font_override("font", fv)
	_place_label.add_theme_font_size_override("font_size", 62)
	_place_label.add_theme_color_override("font_color", Color("fff6e2"))
	_place_label.add_theme_color_override("font_outline_color", Color("7a2e22"))
	_place_label.add_theme_constant_override("outline_size", 10)
	_place_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.05, 0.05, 0.55))
	_place_label.add_theme_constant_override("shadow_offset_x", 4)
	_place_label.add_theme_constant_override("shadow_offset_y", 5)
	_place_label.position = Vector2(28, frame.size.y - 104)
	_place_label.size = Vector2(frame.size.x - 56, 90)
	_place_label.clip_text = true
	frame.add_child(_place_label)
	return f

static func _fade() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0.2, 0.1, 0.05, 0.0), Color(0.2, 0.1, 0.05, 0.0), Color(0.18, 0.08, 0.06, 0.62)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	return t

# --- the back --------------------------------------------------------------------

## The written side: paper, the message in Kit's hand, the stamp and postmark, and who it's to.
class PostcardBack extends Control:
	var card: Dictionary = {}
	var number := 1
	var total := 16
	var date := ""
	var _msg: Label
	var _stamp_tex: Texture2D

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_msg = Label.new()
		_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_msg.add_theme_font_override("font", load("res://art/fonts/caveat/Caveat.ttf"))
		_msg.add_theme_color_override("font_color", Color("22305a"))
		_msg.add_theme_constant_override("line_spacing", -6)
		_msg.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		_msg.add_theme_constant_override("outline_size", 0)
		add_child(_msg)

	func set_card(c: Dictionary, n: int, of: int, stamped: String) -> void:
		card = c
		number = n
		total = of
		date = stamped
		_stamp_tex = AnimSprite.load_sheet(str(c.get("stamp", "")), "front")
		var lines: Array = c.get("text", []).duplicate()
		if str(c.get("ps", "")) != "":
			lines.append("\nP.S. " + str(c.ps))
		var rival := "Kit"
		var player := "you"
		if Game and Game.data:
			rival = Game.data.rival_name
			player = Game.data.player_name
		var body := "\n".join(PackedStringArray(lines)).replace("{player}", player).replace("{rival}", rival)
		body += "\n          " + str(c.get("sign", "Love, {rival} x")).replace("{rival}", rival)
		_msg.text = body
		_msg.position = Vector2(size.x * 0.05, size.y * 0.1)
		_msg.size = Vector2(size.x * 0.48, size.y * 0.84)
		_fit()
		queue_redraw()

	## The biggest hand that fits the left half.
	func _fit() -> void:
		for fs in [34, 32, 30, 28, 26, 24, 22, 20]:
			_msg.add_theme_font_size_override("font_size", fs)
			if _msg.get_line_count() * (_msg.get_line_height() - 6) <= size.y * 0.84:  # the label grows to fit, so not its own size
				return

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# shadow, paper, a faint fibre
		draw_rect(Rect2(Vector2(6, 10), size), Color(0, 0, 0, 0.28))
		draw_rect(Rect2(Vector2.ZERO, size), Color("f4ecd9"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 7 + number
		for i in 260:
			var p := Vector2(rng.randf() * w, rng.randf() * h)
			draw_line(p, p + Vector2(rng.randf_range(-6, 6), rng.randf_range(-2, 2)), Color(0.55, 0.45, 0.3, 0.07), 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color("d8ccb2"), false, 2.0)
		var serif: Font = load("res://art/fonts/libre_baskerville/LibreBaskerville.ttf")
		var hand: Font = load("res://art/fonts/caveat/Caveat.ttf")
		var print_col := Color("8a7d64")
		var rule := Color("cbbfa4")
		# POST CARD across the top, the divider, and the small print up the divider
		_spaced(serif, "POST CARD", Vector2(w * 0.5, 34), 15, print_col, 6.0)
		var dx := w * 0.575
		draw_line(Vector2(dx, 56), Vector2(dx, h - 30), rule, 2.0)
		draw_set_transform(Vector2(dx - 8, h - 36), -PI / 2.0, Vector2.ONE)
		draw_string(serif, Vector2.ZERO, "Wildlore Postcards   No. %d of %d   %s" % [number, total, str(card.get("place", ""))],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, print_col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the address, on ruled lines
		var player := "You"
		if Game and Game.data:
			player = Game.data.player_name
		var addr := [player, "Wherever you've got to,", "c/o the nearest post box,", "Wildlore"]
		for i in addr.size():
			var y := h * 0.56 + i * 50.0
			draw_line(Vector2(dx + 28, y + 8), Vector2(w - 34, y + 8), rule, 1.5)
			draw_string(hand, Vector2(dx + 40 + i * 10.0, y), addr[i], HORIZONTAL_ALIGNMENT_LEFT, w - dx - 50 - i * 10.0, 29, Color("22305a"))
		_draw_stamp(Vector2(w - 150, 46))
		_draw_postmark(Vector2(w - 200, 176), serif)

	func _spaced(font: Font, text: String, centre: Vector2, fs: int, col: Color, gap: float) -> void:
		var widths := []
		var total_w := 0.0
		for ch in text:
			var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			widths.append(cw)
			total_w += cw + gap
		var x := centre.x - (total_w - gap) / 2.0
		for i in text.length():
			draw_string(font, Vector2(x, centre.y), text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			x += widths[i] + gap

	## A perforated stamp, slightly askew: the nation's colour, a creature from round there, "1st".
	func _draw_stamp(at: Vector2) -> void:
		var sw := 112.0
		var sh := 132.0
		draw_set_transform(at + Vector2(sw, sh) / 2.0, deg_to_rad(3.0), Vector2.ONE)
		var r := Rect2(-sw / 2.0, -sh / 2.0, sw, sh)
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.18))
		draw_rect(r, Color("fbf7ee"))
		var hole := 4.2
		var step := 11.0
		var x := r.position.x
		while x <= r.end.x + 0.1:
			draw_circle(Vector2(x, r.position.y), hole, Color("f4ecd9"))
			draw_circle(Vector2(x, r.end.y), hole, Color("f4ecd9"))
			x += step
		var y := r.position.y
		while y <= r.end.y + 0.1:
			draw_circle(Vector2(r.position.x, y), hole, Color("f4ecd9"))
			draw_circle(Vector2(r.end.x, y), hole, Color("f4ecd9"))
			y += step
		var panel := r.grow(-12)
		var col: Color = STAMP_COLOURS.get(str(card.get("nation", "england")), STAMP_COLOURS.england)
		draw_rect(panel, col)
		draw_rect(Rect2(panel.position, Vector2(panel.size.x, panel.size.y * 0.45)), col.lightened(0.12))
		if _stamp_tex:
			var px := float(_stamp_tex.get_height())  # the first square frame of the sheet
			var region := Rect2(0, 0, px, px)
			var s := minf(panel.size.x, panel.size.y) * 0.98
			RenderingServer.canvas_item_set_default_texture_filter(get_canvas_item(), RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST if px <= 96.0 else RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR)
			draw_texture_rect_region(_stamp_tex, Rect2(panel.get_center() - Vector2(s, s) / 2.0 + Vector2(0, -4), Vector2(s, s)), region)
		var serif: Font = load("res://art/fonts/libre_baskerville/LibreBaskerville.ttf")
		draw_string(serif, panel.position + Vector2(6, panel.size.y - 6), "1st", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fbf7ee"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## A round postmark with the town and the date, and wavy cancellation lines across the stamp.
	func _draw_postmark(c: Vector2, serif: Font) -> void:
		var ink := Color(0.16, 0.14, 0.24, 0.62)
		draw_arc(c, 50.0, 0, TAU, 48, ink, 2.5)
		draw_arc(c, 42.0, 0, TAU, 48, ink, 1.5)
		var town := str(card.get("postmark", card.get("place", ""))).to_upper()
		var fs := 13
		var tw := serif.get_string_size(town, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		while tw > 66.0 and fs > 8:
			fs -= 1
			tw = serif.get_string_size(town, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(serif, c + Vector2(-tw / 2.0, -10), town, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
		var d := Postcards.postmark_date(date)
		var dw := serif.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_line(c + Vector2(-34, -2), c + Vector2(34, -2), ink, 1.2)
		draw_string(serif, c + Vector2(-dw / 2.0, 16), d, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
		for k in 5:
			var pts := PackedVector2Array()
			var y0 := c.y - 34.0 + k * 15.0
			var x := c.x + 56.0
			while x < c.x + 200.0:
				pts.append(Vector2(x, y0 + sin((x - c.x) * 0.09) * 4.0))
				x += 5.0
			draw_polyline(pts, ink, 2.0, true)
