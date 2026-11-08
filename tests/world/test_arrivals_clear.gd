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
	var bad := []
	for z: ZoneData in zones.values():
		var lands := [z.spawn]
		for src: ZoneData in zones.values():
			for w in src.warps:
				if str(w.get("to", "")) == z.id and w.has("tx"):
					lands.append(Vector2i(int(w.tx), int(w.ty)))
		for n in z.npcs:
			if _fixed(n) and Vector2i(int(n.x), int(n.y)) in lands:
				bad.append("%s/%s" % [z.id, n.get("id", "")])
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
