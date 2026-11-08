extends SceneTree
## Dev probe (wave 48 V): a frame-driven run of the field spot paths on a real Overworld in wirral_way.
## Usage: godot --headless --path . -s res://tools/dev/field_spot_probe.gd   (exit 1 on a FAIL)

var _fails := 0
var _lines: Array = []

func _initialize() -> void:
	call_deferred("_go")

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		_fails += 1

# stands in for the Autopilot: dialogue lines are logged instead of waiting on a key
class Pilot:
	var lines: Array
	func log_line(_who: String, text: String) -> void:
		lines.append(text)
	func menu_result(_m: String):
		return null

func _teach(c: Creature, game: String) -> void:
	var G = root.get_node("Game")
	var mv := PartyPieces.move_of(game)
	if not c.has_move(mv):
		if c.moves.size() >= 4:
			c.moves.pop_back()
		c.moves.append(c.make_move_slot(mv, G.moves))

func _go() -> void:
	await process_frame
	await process_frame
	var G = root.get_node("Game")
	G.new_game()
	var FS = load("res://world/field_spot.gd")
	var pilot := Pilot.new()
	pilot.lines = _lines
	Engine.set_meta("autopilot", pilot)
	var c := Creature.create(G.dex.get_species("holtling"), 20, G.rng, G.moves)
	G.data.party = [c]
	var ow: Node = load("res://world/overworld.tscn").instantiate()
	root.add_child(ow)
	await process_frame
	ow.load_zone("wirral_way", Vector2i(13, 56), "n")
	for i in 20:
		await process_frame
	print("player at ", ow.player.grid_pos)
	var hop: Dictionary = FieldSpots.all().filter(func(s): return s.id == "fs_wirral_way_paddle_x1")[0]
	var item: Dictionary = FieldSpots.all().filter(func(s): return s.id == "fs_wirral_way_round_up")[0]
	var curio: Dictionary = FieldSpots.all().filter(func(s): return s.id == "fs_wirral_way_roll")[0]
	# --- unknown path
	_lines.clear()
	var did: bool = await FS.interact(ow, FieldSpots.tile(hop))
	check(did, "spot at the coracle is ours")
	check(_lines.size() > 0 and "Coracle" in " ".join(_lines) or "coracle" in " ".join(_lines).to_lower(), "hint names the piece: " + " | ".join(_lines))
	check(not ZoneData.flag_on(G.data.flag(str(hop.flag))), "hint sets no flag")
	check(ow.player.grid_pos == Vector2i(13, 56), "player did not move")
	# --- known: hop
	PartyPieces.record(G.data, "coracle", 30.0)
	_teach(c, "coracle")
	_lines.clear()
	var t0 := Time.get_ticks_msec()
	await FS.interact(ow, FieldSpots.tile(hop))
	check(ZoneData.flag_on(G.data.flag(str(hop.flag))), "hop flag set")
	check(ow.player.grid_pos == Vector2i(int(hop.reward.hop[0]), int(hop.reward.hop[1])), "player hopped to %s, at %s" % [hop.reward.hop, ow.player.grid_pos])
	check(_lines.size() > 0 and not "{lead}" in " ".join(_lines) and "Holtling" in " ".join(_lines), "success text names the lead: " + " | ".join(_lines))
	check(not ow.zone.blocked.has(FieldSpots.tile(hop)) == false, "hop spot remains (usable again)")
	# --- known: item once
	ow.load_zone("wirral_way", Vector2i(39, 55), "n")
	for i in 10:
		await process_frame
	PartyPieces.record(G.data, "sheepdog_trials", 5.0)
	_teach(c, "sheepdog_trials")
	var n0: int = Bag.new(G.data.bag).count("cream_tea") if Bag.new(G.data.bag).has_method("count") else -1
	_lines.clear()
	await FS.interact(ow, FieldSpots.tile(item))
	check(ZoneData.flag_on(G.data.flag(str(item.flag))), "item flag set")
	var n1: int = Bag.new(G.data.bag).count("cream_tea") if n0 >= 0 else -1
	check(n1 == n0 + 1, "cream tea paid once (%d -> %d)" % [n0, n1])
	check(FieldSpots.gone(G.data, item) and not ow.zone.get_meta("field_tiles").has(FieldSpots.tile(item)), "spot removed")
	var again: bool = await FS.interact(ow, FieldSpots.tile(item))
	check(not again and Bag.new(G.data.bag).count("cream_tea") == n1, "second press does nothing and pays nothing")
	print("DONE fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
