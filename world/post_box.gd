class_name PostBox
extends RefCounted
## The post boxes in town: while one of Kit's postcards is waiting (see Postcards), every `post_box` prop in the
## zone has a little airmail envelope bobbing over its cap, and facing one collects the post and shows it on
## the postcard screen. Otherwise a post box is just a post box, and says so.

const NODE := "PostBoxes"
const ENVELOPE_Y := 1.55      # above the cap (the box is 1.05 tall)
const BOB := 0.07
const BOB_SECS := 1.1

## Quiet days at the post box, picked by the in-game day.
const EMPTY := [
	"A post box, red as a robin. Nothing in it for you today.",
	"Last collection 5.30pm. No post for you, though.",
	"You peer into the slot. It's dark in there, and postcard-free.",
]
const EMPTY_KIT := [
	"No post today. Kit is probably busy being lost somewhere scenic.",
	"Nothing from Kit today. Give it a Stone or two.",
	"An empty slot. Kit's next card is still being written, or more likely chewed.",
]

static var _tex: Texture2D

## Adds an envelope over each post box in the zone, shown while there's post waiting.
static func dress(z: ZoneData, zone_node: Node3D, data: GameStateData) -> void:
	var boxes := Postcards.post_boxes(z)
	if boxes.is_empty():
		return
	var root := Node3D.new()
	root.name = NODE
	zone_node.add_child(root)
	var show := not Postcards.waiting(data).is_empty() or not BuildingSociety.letters_waiting(data).is_empty() \
			or not Deeds.letters_waiting(data).is_empty() or not Leases.letters_waiting(data).is_empty() or not Regulars.letters_waiting(data).is_empty()
	for p in boxes:
		var n := envelope()
		n.name = "E_%d_%d" % [p.x, p.y]
		n.position = Vector3(p.x + 0.5, ZoneBuilder.ground_y(z, p) + ENVELOPE_Y, p.y + 0.5)
		n.visible = show
		root.add_child(n)
		_bob(n)

## Shows or hides every envelope in the zone (after collecting, or when a card arrives mid-zone).
static func show_waiting(zone_node: Node, waiting: bool) -> void:
	var root := zone_node.get_node_or_null(NODE) if zone_node else null
	if root == null:
		return
	for n in root.get_children():
		n.visible = waiting

## Facing a post box and pressing confirm. True when it was a post box.
static func interact(ow: Node, p: Vector2i) -> bool:
	if not Postcards.is_post_box(ow.zone, p):
		return false
	var mail := BuildingSociety.collect_letters(Game.data)  # Pat when you're behind, Mum's sub
	if not mail.is_empty():
		Audio.sfx("item")
		for id in mail:
			await ow.say(BuildingSociety.letter_lines(str(id), Game.data))
		if Postcards.waiting(Game.data).is_empty():
			show_waiting(ow._zone_node, false)
			return true
	var business := Deeds.collect_letters(Game.data)  # rates bills, statements, the taxman
	if not business.is_empty():
		Audio.sfx("item")
		await ow.say(business)
		if Postcards.waiting(Game.data).is_empty():
			show_waiting(ow._zone_node, false)
			return true
	var estate := Leases.collect_letters(Game.data)  # upkeep, arrears and stages from the Enclosure's solicitors
	if not estate.is_empty():
		Audio.sfx("item")
		await ow.say(estate)
		if Postcards.waiting(Game.data).is_empty():
			show_waiting(ow._zone_node, false)
			return true
	var friends := Regulars.collect_letters(Game.data)  # a Regular's letter once favour is 3
	if not friends.is_empty():
		Audio.sfx("item")
		for id in friends:
			await ow.say(Regulars.letter_lines(str(id), Game.data.player_name))
		if Postcards.waiting(Game.data).is_empty():
			show_waiting(ow._zone_node, false)
			return true
	var had_album := int(Game.data.bag.get(Postcards.ALBUM, 0)) > 0
	var got := Postcards.collect(Game.data, [], Calendar.today_key())
	if got.is_empty():
		var lines: Array = EMPTY_KIT if had_album else EMPTY
		await ow.say([lines[posmod(Game.data.day_count, lines.size())]])
		return true
	show_waiting(ow._zone_node, false)
	Audio.sfx("item")
	var lines := []
	if got.size() == 1:
		lines.append("Tucked in the slot is a postcard with your name on it. Kit's handwriting: nobody else dots an i with a star.")
	else:
		lines.append("A whole bundle of postcards is wedged in the slot, held together with an elastic band. %d of them, all from Kit." % got.size())
	if not had_album:
		lines.append("%s received the Postcard Album! Somewhere to keep them, in the Bag with the key items." % Game.data.player_name)
	await ow.say(lines)
	await Router.open_menu("postcard:new:" + ",".join(got))
	return true

# --- the envelope -----------------------------------------------------------------

static func envelope() -> Node3D:
	var s := Sprite3D.new()
	s.texture = texture()
	s.pixel_size = 0.0066
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var holder := Node3D.new()
	holder.add_child(s)
	return holder

static func _bob(n: Node3D) -> void:
	var s: Node3D = n.get_child(0)
	var tw := s.create_tween().set_loops()
	tw.tween_property(s, "position:y", BOB, BOB_SECS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(s, "position:y", 0.0, BOB_SECS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## An airmail envelope, drawn once: cream paper, red and blue barber-pole border, the flap, a red wax seal,
## a dark outline and a soft shadow so it reads against sky, slate or brick.
static func texture() -> Texture2D:
	if _tex:
		return _tex
	const W := 112
	const H := 80
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var x0 := 6
	var y0 := 6
	var w := W - 14
	var h := H - 16
	# soft shadow, down and right
	for y in range(y0 + 4, y0 + h + 5):
		for x in range(x0 + 4, x0 + w + 5):
			img.set_pixel(x, y, Color(0.05, 0.04, 0.08, 0.35))
	var ink := Color("2a2230")
	var paper := Color("f7f0de")
	var red := Color("c8102e")
	var blue := Color("1f4e96")
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			var ex := x - x0
			var ey := y - y0
			var edge := mini(mini(ex, w - 1 - ex), mini(ey, h - 1 - ey))
			var c := paper
			if edge < 2:
				c = ink
			elif edge < 8:
				c = [red, paper, blue, paper][int(floor((ex + ey) / 6.0)) % 4]
			img.set_pixel(x, y, c)
	# the flap: a V from the top corners down to the middle
	var cx := x0 + w / 2.0
	var tip := y0 + h * 0.58
	for x in range(x0 + 8, x0 + w - 8):
		var t := absf(x - cx) / (w / 2.0 - 8.0)
		var fy := lerpf(tip, y0 + 8.0, t)
		for k in 2:
			img.set_pixel(x, int(fy) + k, Color("b9ad93"))
	# wax seal
	for y in range(-7, 8):
		for x in range(-7, 8):
			var d := sqrt(x * x + y * y)
			if d <= 6.5:
				var c := red.darkened(0.15) if d > 5.0 else red
				if d < 2.4:
					c = red.lightened(0.25)
				img.set_pixel(int(cx) + x, int(tip) + y, c)
	img.generate_mipmaps()
	_tex = ImageTexture.create_from_image(img)
	return _tex
