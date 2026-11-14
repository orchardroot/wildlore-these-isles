class_name ScriptRunner
extends Node
## Runs story commands in the game: wraps the pure Commands interpreter with a host backed by the real
## overworld, dialogue box, Router and Audio. Router.busy is held for the whole run.

var ow: Node

## Fire-and-forget helper. Safe to call from an NPC that might be freed mid-run (a whiteout rebuilds the zone):
## the run lives on a runner node under the overworld, not on the caller.
## `on_done` (optional) is only called if its target still exists.
static func start(overworld: Node, commands: Array, npc_id := "", on_done := Callable()) -> void:
	var r := ScriptRunner.new()
	r.ow = overworld
	overworld.add_child(r)
	await r.run(commands, npc_id)
	r.queue_free()
	if on_done.is_valid():
		on_done.call()

func run(commands: Array, npc_id := "") -> void:
	Router.busy = true
	var host := Host.new(ow)
	await Commands.new(host, npc_id).run(commands)
	host.close_box()
	Router.busy = false

## The real-game host for Commands.
class Host extends RefCounted:
	var data: GameStateData
	var dex: Dex
	var moves: MoveDB
	var items: ItemDB
	var rng: Rng
	var _ow: Node
	var _box: DialogueBox
	var _who := ""

	func _init(overworld: Node) -> void:
		_ow = overworld
		data = Game.data
		dex = Game.dex
		moves = Game.moves
		items = Game.items
		rng = Game.rng

	func zone_id() -> String:
		return _ow.zone.id

	## The outdoor weather for `when` conditions. Indoors the sky holds the inherited outdoor weather.
	func current_weather() -> String:
		var sky = _ow.get("sky")
		return str(sky.weather) if sky != null else str(data.weather)

	func close_box() -> void:
		if _box and is_instance_valid(_box):
			_box.close()
		_box = null

	func _ensure_box() -> DialogueBox:
		if _box == null or not is_instance_valid(_box):
			_box = load("res://ui/dialogue_box.tscn").instantiate()
			_ow.add_child(_box)
		return _box

	func say(who: String, text: String) -> void:
		_who = who
		await _ensure_box().show_text(text, who)

	func choice(text: String, options: Array) -> int:
		return await _ensure_box().show_choice(text, options, _who)

	func battle(foe_party: Array, opts: Dictionary) -> Dictionary:
		close_box()
		var o := opts.duplicate()
		o["weather"] = _ow.weather
		o["time"] = Game.phase()
		if _ow.has_method("_stage"):
			o["stage"] = _ow.call("_stage")
		var result: Dictionary = await Router.battle(foe_party, o)
		Router.busy = true
		return result

	func easy_trial() -> bool:
		return Settings.easy_fishing  # one "easier timing" option covers fishing and the sheepdog trials

	func sheepdog(lead_speed: int, easy: bool, seed_text: String, label: String) -> Dictionary:
		close_box()
		var st: Dictionary = await SheepdogTrial.play(_ow, lead_speed, easy, seed_text, label)
		Router.busy = true
		return st

	func autosave() -> void:
		Game.autosave()

	func warp(zone: String, x: int, y: int, facing: String) -> void:
		close_box()
		await Router.goto_zone(zone, Vector2i(x, y), facing)
		Router.busy = true

	## A travel scene before the warp (false when scenes are off); see Journey.
	func journey_out(kind: String, info: Dictionary) -> bool:
		close_box()
		var played: bool = await Journey.depart(_ow, kind, info)
		Router.busy = true
		return played

	func journey_in(kind: String, info: Dictionary) -> void:
		await Journey.arrive(_ow, kind, info)
		Router.busy = true

	func open_menu(menu: String) -> Variant:
		close_box()
		var r = await Router.open_menu(menu)
		Router.busy = true
		return r

	func fade(out: bool) -> void:
		if out:
			close_box()
			await Router.fade_out()
		else:
			await Router.fade_in()

	func music(id: String) -> void:
		Audio.play_music(id)

	func zone_music() -> void:
		if _ow.zone and _ow.zone.music != "":
			Audio.play_music(_ow.zone.music, 0.4)

	func sfx(id: String) -> void:
		Audio.sfx(id)

	func wait(seconds: float) -> void:
		await _ow.get_tree().create_timer(seconds).timeout

	func on_flag(key: String, value: Variant) -> void:
		Bus.flag_changed.emit(key, value)

	func _actor(id: String) -> Node:
		if id == "player":
			return _ow.player
		for n in _ow.npcs:
			if is_instance_valid(n) and str(n.def.get("id", "")) == id:
				return n
		return null

	func move_npc(npc: String, path: Array) -> void:
		close_box()
		var a := _actor(npc)
		if a == null:
			push_warning("ScriptRunner: no actor '%s' to move" % npc)
			return
		if a == _ow.player:
			for d in path:
				await a.try_step(str(d))
			return
		await a.walk(path)

	func face_npc(npc: String, dir: String) -> void:
		var a := _actor(npc)
		if a:
			a.face(dir)

	## The family cat's moves in the world: "approach", "gone" or "home" (see FamilyCatScene).
	func family_cat(op: String) -> void:
		close_box()
		await FamilyCatScene.act(_ow, op)

	func face_player(npc: String) -> void:
		var a := _actor(npc)
		if a and a != _ow.player:
			a.face_toward(_ow.player.grid_pos)

	## Where a Sanctuary heal is recorded: the tile in front of the NPC, or the player's tile.
	func heal_anchor(npc: String) -> Vector2i:
		var a := _actor(npc)
		if a and a != _ow.player:
			var front := GridMotion.step(a.grid_pos, a.facing)
			if _ow.zone.walkable(front):
				return front
		return _ow.player.grid_pos
