extends SceneTree
## Dev probe: runs two auto battles with frames (tweens tick), a Sanctuary heal between them, and logs the
## player's plate (hp_shown, bar value, text) against the creature's real HP whenever they disagree.
## Usage: godot --headless --path . -s res://tools/dev/hp_probe.gd -- --battle-auto [--save=/abs/path.json]

var _log := []

func _initialize() -> void:
	call_deferred("_go")

func _go() -> void:
	await process_frame
	await process_frame
	var Game = root.get_node("Game")
	var save_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--save="):
			save_path = a.get_slice("=", 1)
	Game.new_game()
	if save_path != "":
		var txt := FileAccess.get_file_as_string(save_path)
		Game.data = GameStateData.from_dict(JSON.parse_string(txt), Game.dex)
	else:
		Game.data.party = [Creature.create(Game.dex.get_species("kindlet"), 12, Game.rng, Game.moves)]
	print("party: ", Game.data.party.map(func(c): return "%s %d/%d" % [c.species.id, c.hp, c.max_hp()]))
	await _battle("one")
	print("after battle 1: ", Game.data.party.map(func(c): return "%s %d/%d" % [c.species.id, c.hp, c.max_hp()]))
	Game.data.heal_party()
	await process_frame
	await _battle("two")
	print("DONE")
	quit(0)

func _battle(tag: String) -> void:
	var Game = root.get_node("Game")
	var lvl := 12
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--foe-level="):
			lvl = int(a.get_slice("=", 1))
	var foe := [Creature.create(Game.dex.get_species("holtling"), lvl, Game.rng, Game.moves)]
	var scene: Node = load("res://battle_ui/battle_scene.tscn").instantiate()
	root.add_child(scene)
	scene.setup(foe, {"kind": "wild"})
	var done := [false]
	scene.finished.connect(func(_r): done[0] = true)
	var frames := 0
	var last := ""
	while not done[0] and frames < 60 * 90:
		await process_frame
		frames += 1
		var p = scene.hud.plates[Battle.PLAYER]
		if p.creature == null:
			continue
		var c: Creature = p.creature
		var line := "%s f%d vis=%s c.hp=%d max=%d shown=%.1f hp_max=%.0f bar=%.3f text='%s'" % [tag, frames, p.visible, c.hp, c.max_hp(), p.hp_shown, p.hp_max, p.hp_bar.value, p.hp_text.text]
		var bad := absf(p.hp_bar.value - p.hp_shown / maxf(1.0, p.hp_max)) > 0.001 or absf(p.hp_max - c.max_hp()) > 0.5
		var key := "%d %.0f %.0f %s" % [c.hp, p.hp_shown, p.hp_max, p.hp_text.text]
		if key != last or bad:
			print(("MISMATCH " if bad else "") + line)
			last = key
	await process_frame
	scene.queue_free()
	await process_frame
