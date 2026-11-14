class_name ExamineScene
extends RefCounted
## Facing an examine spot and pressing confirm (see Examine): the text, then any find, once.

static func interact(ow: Node, p: Vector2i) -> bool:
	var ex: Dictionary = ow.zone.examine_at(p)
	if ex.is_empty():
		return false
	var key := Examine.found_flag(str(ow.zone.id), ex)
	var before := ZoneData.flag_on(Game.data.flag(key))
	var res := Examine.read(Game.data, str(ow.zone.id), ex, Game.items)
	if res.gave:
		Audio.sfx("item")
	if not before and ZoneData.flag_on(Game.data.flag(key)):
		Bus.flag_changed.emit(key, true)  # a quest step or the Timeline of Invention may want it
	var lines: Array = res.lines
	if str(ex.get("clue", "")) != "":  # a contract's look-spot: what you work out, at the right hour and in the right weather
		var sky = ow.get("sky")
		var look := Contracts.look(Game.data, str(ex.clue), Game.phase(), str(sky.weather) if sky != null else str(Game.data.weather))
		lines = lines + look.lines
		if look.new:
			Audio.sfx("item")
			lines.append("Journal: a new lead on %s." % str(Contracts.get_contract(str(ex.clue).get_slice(".", 0)).get("title", "the contract")))
			Bus.flag_changed.emit(Contracts.flag(str(ex.clue).get_slice(".", 0), "clue_" + str(ex.clue).get_slice(".", 1)), true)
	await ow.say(lines)
	return true
