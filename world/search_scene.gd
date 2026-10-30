class_name SearchScene
extends RefCounted
## Facing furniture in a room and pressing confirm (see Search): a resident's wry word on the first search of a
## visit, then what you find, or the bare drawer.

static func interact(ow: Node, p: Vector2i) -> bool:
	var prop := Search.prop_at(ow.zone, p)
	if prop.is_empty():
		return false
	var d: GameStateData = Game.data
	var lines: Array = []
	if not Search.searched(d, str(ow.zone.id), p.x, p.y):
		var q := Search.quip(ow.zone, d)
		if q != "":
			lines.append(q)
	var before := Search.found_count(d)
	var res := Search.take(ow.zone, prop, d, Game.items)
	lines.append_array(res.lines)
	if res.gave:
		Audio.sfx("item")
	else:
		Audio.sfx("bump")
	var now := Search.found_count(d)
	if now > before and now in [20, 40, 60]:
		lines.append(Search.pat_on_back(now))
	await ow.say(lines)
	return true
