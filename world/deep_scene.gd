class_name DeepScene
extends RefCounted
## The overworld side of a Deep Place (rules in DeepPlace): face a lever and press Confirm to pull it, and plates
## take the weight of a crate (or you) as you step. A change rebuilds the scenery so gates swing and water drains.
## Facing a closed gate reads its line, so the hint about what opens it is where the player is looking.

static func interact(ow: Node, p: Vector2i) -> bool:
	var gate := DeepPlace.gate_at(ow.zone, p)
	if not gate.is_empty() and not DeepPlace.gate_open(Game.data, str(ow.zone.id), gate):
		await ow.say([str(gate.get("line", "It's shut."))])
		return true
	var lever := DeepPlace.lever_at(ow.zone, p)
	if lever.is_empty():
		return false
	var data: GameStateData = Game.data
	if not DeepPlace.can_find(data, ow.zone, lever):
		await ow.say(["Something is down there in the dark. Without a Lantern you can't make out what."])
		return true
	var on := DeepPlace.pull(data, str(ow.zone.id), lever)
	Audio.sfx("door")
	ow.rebuild_scenery()
	await ow.say([str(lever.get("on" if on else "off", "Clunk. Somewhere, something moves."))])
	var find: Dictionary = lever.get("find", {})
	var found := DeepPlace.flag_key(str(ow.zone.id), str(lever.id) + "_found")
	if on and not find.is_empty() and data.flag(found) != true:  # a pocket behind the lever: its contents, once
		if Bag.new(data.bag).add(str(find.item), int(find.get("n", 1))) > 0:
			data.set_flag(found, true)
			Audio.sfx("item")
			await ow.say(["%s received %s." % [data.player_name, str(Game.items.get_item(str(find.item)).get("name", find.item))]])
		else:
			await ow.say(["Your bag is full. You leave it for later."])
	return true

static func stepped(ow: Node, p: Vector2i) -> void:
	if ow.zone.deep.is_empty():
		return
	var fresh := not DeepPlace.press_plates(Game.data, ow.zone, ow.deep_crates, p).is_empty()
	if fresh or ow.deep_pressed:
		ow.deep_pressed = false
		Audio.sfx("door")
		ow.rebuild_scenery()
		await ow.say(["Click. Stone grinds on stone, a long way off."])
