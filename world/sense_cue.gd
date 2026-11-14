class_name SenseCue
extends Node3D
## Your creature notices things (5.4): within about five tiles of a point of interest or field spot you have not dealt
## with, a small gold mark rises over your follower (or over you, with none) and a soft chime sounds. Once per find,
## never in towns, and never when Hints are off. It reads Discovery.nearby_unfound, so later waves can add flotsam and
## secrets to that list and get the cue for free. Looks at the ground every third step, not every frame.
## The first time you meet a point of interest, a field spot, a plaque or a room of the Visitor's Book, it also says
## one line about what that is (Intros, so Hints off says nothing and a save well under way is never told).

const LOOK_EVERY := 3        # steps between looks
const RISE := 0.5            # how far the mark drifts up
const LIFE := 2.4            # seconds on screen
const HEIGHT := 1.55         # above the ground of whoever carries it
const PLAQUE_RANGE := 3      # tiles: close enough to have noticed the plaque
const ROOMS_FIRST := 3       # rooms walked into before the Visitor's Book is mentioned

static var dev_hold := false  # screenshots (`--sense`): the mark stays where it is and no card follows

var _steps := 0
var _zone_id := ""
var _tiles: Dictionary = {}  # poi id -> the tile it stands on, worked out once per zone

## The overworld's one hook, called on every step the player takes inside a zone.
static func on_step(ow: Node, p: Vector2i) -> void:
	var cue: SenseCue = ow.get_node_or_null("SenseCue")
	if cue == null:
		cue = SenseCue.new()
		cue.name = "SenseCue"
		ow.add_child(cue)
	cue._look(ow, p)

func _look(ow: Node, p: Vector2i) -> void:
	_steps += 1
	if _steps < LOOK_EVERY or ow.zone == null or not Settings.hints or Router.busy or not ow.zone.warp_at(p).is_empty():
		return  # not mid-talk, and never on a doorstep (the door's own business comes first)
	_steps = 0
	var card := _meeting(ow.zone, p)
	if card != "":
		var text := Intros.take(Game.data, card, true)
		if text != "":
			ow.say([text])
			return
	if ow.zone.kind != "route":
		return
	if ow.zone.id != _zone_id:
		_zone_id = ow.zone.id
		_tiles.clear()
	var found := Discovery.nearby_unfound(ow.zone, p, Game.data, _poi_tile.bind(ow.zone))
	if found.is_empty():
		return
	Game.data.set_flag(Discovery.sensed_key(str(found[0].id)), true)
	var carrier: Node3D = ow.follower if ow.follower != null and ow.follower.visible else ow.player
	_show(carrier)
	var first := "poi" if found[0].kind == "poi" else "field_spot"  # the first of each says what it is, once
	var intro := Intros.take(Game.data, first, true) if not dev_hold else ""
	if intro != "":
		await ow.get_tree().create_timer(1.2).timeout
		ow.say([intro])

## The introduction card for something just met, or "": a plaque within a few tiles, or the third room of the
## Visitor's Book. Cards already taken are skipped without work.
func _meeting(zone: ZoneData, p: Vector2i) -> String:
	if Game.data.flag(Intros.FLAG + "plaque") != true:
		for s in zone.signs:
			if str(s.get("plaque", "")) != "" and maxi(absi(int(s.x) - p.x), absi(int(s.y) - p.y)) <= PLAQUE_RANGE:
				return "plaque"
	if zone.kind == "interior" and Game.data.flag(Intros.FLAG + "visitors_book") != true and VisitorsBook.rooms_seen(Game.data) >= ROOMS_FIRST:
		return "visitors_book"
	return ""

func _poi_tile(poi: Dictionary, zone: ZoneData) -> Vector2i:
	var id := str(poi.id)
	if not _tiles.has(id):
		_tiles[id] = Poi.tile(zone, poi)
	return _tiles[id]

func _show(carrier: Node3D) -> void:
	var mark := Label3D.new()
	mark.text = "!"
	mark.font_size = 64
	mark.pixel_size = 0.013
	mark.modulate = Color("ffd166")
	mark.outline_modulate = Color("2a3328")
	mark.outline_size = 14
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.position = Vector3(0, HEIGHT, 0)
	carrier.add_child(mark)
	Audio.sfx_at("cursor", -7.0, 1.9)  # a soft chime
	if dev_hold:
		mark.position.y = HEIGHT + RISE
		return
	var tw := mark.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mark, "position:y", HEIGHT + RISE, LIFE).set_ease(Tween.EASE_OUT)
	tw.tween_property(mark, "modulate:a", 0.0, LIFE * 0.4).set_delay(LIFE * 0.6)
	tw.tween_property(mark, "outline_modulate:a", 0.0, LIFE * 0.4).set_delay(LIFE * 0.6)
	tw.chain().tween_callback(mark.queue_free)
