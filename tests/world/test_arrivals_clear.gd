extends TestCase
## w51: a new player's walk round the side content. Stepping into the Exeter passages or the Castle of Mey put you
## on top of the guide; a sign stood in the sea off St Peter Port (and off Dundee and the Exe), so nobody could
## read it. Every arrival tile is clear of standing people, and every sign has somewhere to stand and read it.

const STAND_WITH := ["brook_wade", "fell_scramble", "bog_cross"]

static var _zones: Dictionary = {}

static func _all() -> Dictionary:
	if _zones.is_empty():
		for f in DirAccess.get_files_at(ZoneData.DIR):
			if f.ends_with(".json"):
				var z := ZoneData.load_id(f.get_basename())
				if z != null and z.region != "dev":
					_zones[z.id] = z
	return _zones

## A resident who never moves and is always there (not a story gate that steps aside).
static func _fixed(n: Dictionary) -> bool:
	return str(n.get("move", "")) == "still" and not n.has("show_if") and not n.has("hide_if") and not n.has("times")

func test_nobody_stands_where_you_arrive() -> void:
	var zones := _all()
	var abroad := []  # where a flight or a Channel Islands ferry sets you down (data/overseas)
	for path in JsonUtil.list_json("res://data/overseas"):
		var o = JsonUtil.read(path)
		if o is Dictionary and o.get("arrival") is Dictionary:
			abroad.append(o.arrival)
	assert_true(abroad.size() > 20, "found the overseas arrivals")
	var bad := []
	for z: ZoneData in zones.values():
		var lands := [z.spawn]
		for a in abroad:
			if str(a.get("zone", "")) == z.id:
				lands.append(Vector2i(int(a.x), int(a.y)))
		for src: ZoneData in zones.values():
			for w in src.warps:
				if str(w.get("to", "")) == z.id and w.has("tx"):
					lands.append(Vector2i(int(w.tx), int(w.ty)))
		for n in z.npcs:
			if _fixed(n) and Vector2i(int(n.x), int(n.y)) in lands:
				bad.append("%s/%s" % [z.id, n.get("id", "")])
			# Outdoors, someone right in front of a doorstep hides you as you come out and blocks the way.
			# A trainer waiting there is the point of them.
			elif z.kind != "interior" and _fixed(n) and not n.has("trainer") and Vector2i(int(n.x), int(n.y) - 1) in lands:
				bad.append("%s/%s (in front)" % [z.id, n.get("id", "")])
	assert_eq(bad, [], "people standing on an arrival tile")

func test_every_sign_can_be_read() -> void:
	var bad := []
	for z: ZoneData in _all().values():
		for s in z.signs:
			var p := Vector2i(int(s.x), int(s.y))
			var ok := false
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if z.in_bounds(p + d) and (z.walkable(p + d, Vector2i.ZERO, STAND_WITH) or z.tile_at(p + d) == "bramble"):
					ok = true
			if not ok:
				bad.append("%s %d,%d" % [z.id, p.x, p.y])
	assert_eq(bad, [], "signs with nowhere to stand and read them")

## An oak grew up through a house on Oxford's High Street (by the pancake race) and a flagpole stood in the roof of
## Anguilla's Salt Cottage. Ruins (Jarlshof, Blaenavon) are open to the sky, so rocks and sheep are fine there.
const OPEN_TO_THE_SKY := ["kirk_ruin", "ironworks"]

func test_no_prop_stands_inside_a_building() -> void:
	var bad := []
	for z: ZoneData in _all().values():
		if z.kind == "interior":
			continue
		for b in z.props:
			if str(b.get("type", "")) != "building" or not b.has("w") or str(b.get("style", "")) in OPEN_TO_THE_SKY:
				continue
			var r := Rect2i(int(b.x), int(b.y), int(b.w), int(b.get("h", 1)))
			for p in z.props:
				var t := str(p.get("type", ""))
				if t in ["building", "hanging_basket"] or p.get("walk", false):
					continue
				var at := Vector2i(int(p.get("x", -1)), int(p.get("y", -1)))
				if r.has_point(at) and z.tile_at(at) == "building":
					bad.append("%s %s %d,%d" % [z.id, t, at.x, at.y])
	assert_eq(bad, [], "props inside a building")
