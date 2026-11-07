extends SceneTree
## Dev probe (wave 48 V): drives PiecePrompt.after_game from a REAL skimming screen, frame by frame (tweens and the
## modal's frame loops need ticks, which the synchronous test runner lacks). Prints PASS/FAIL lines; exits 1 on a FAIL.
## Usage: godot --headless --path . -s res://tools/dev/pieces_flow_probe.gd

var _fails := 0
var Gm

func _initialize() -> void:
	call_deferred("_go")

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		_fails += 1

func _go() -> void:
	await process_frame
	await process_frame
	Gm = root.get_node("Game")
	await _scenario_teach_free_slot()
	await _scenario_teach_full_slots(0)
	await _scenario_teach_full_slots(-1)
	await _scenario_cannot_learn()
	await _scenario_gold_first_play()
	await _scenario_gold_once()
	await _scenario_almanac_reteach()
	print("DONE fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)

func _lead(types_wanted: Array, level := 20, moves := 2) -> Creature:
	for id in Gm.dex.ids():
		var sp = Gm.dex.get_species(id)
		var ok := false
		for t in sp.types:
			if t in types_wanted:
				ok = true
		if ok != (types_wanted.size() > 0 and not types_wanted[0].begins_with("!")):
			continue
		var c := Creature.create(sp, level, Gm.rng, Gm.moves)
		while c.moves.size() > moves:
			c.moves.pop_back()
		return c
	return null

func _incompatible(game: String) -> Creature:
	var types: Array = PartyPieces.entry(game).types
	for id in Gm.dex.ids():
		var sp = Gm.dex.get_species(id)
		var hit := false
		for t in sp.types:
			if t in types:
				hit = true
		if not hit:
			return Creature.create(sp, 20, Gm.rng, Gm.moves)
	return null

func _screen() -> Node:
	var s: Node = load("res://ui/skimming_screen.tscn").instantiate()
	root.add_child(s)
	s.setup("easdale")
	return s

## Finish a real skimming game with `best` skips by running its own _landed on the last throw.
func _finish(s: Node, best: int) -> void:
	s._throws = Skimming.THROWS - 1
	s._best = best - 1
	s._anim = {"hops": [], "t": 99.0, "scale": 1.0, "skips": best, "res": {"skips": best, "sank": false, "hops": [], "distance": 10.0}}
	s._rng = Rng.new(1)
	s._landed()

func _card_text(s: Node) -> String:
	var layer: Node = s.get_child(s.get_child_count() - 1)
	var out := []
	_labels(layer, out)
	return " / ".join(out)

func _labels(n: Node, out: Array) -> void:
	if n is Label and n.text != "":
		out.append(n.text)
	for c in n.get_children():
		_labels(c, out)

func _find_button(n: Node, text: String) -> Button:
	if n is Button and n.text == text and n.is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find_button(c, text)
		if r:
			return r
	return null

func _closed(s: Node) -> bool:
	return s._done

## Waits (frames) until the host shows a card with a button `btn`, returns its text; then presses it.
func _press(s: Node, btn: String, texts: Array) -> bool:
	for i in 600:
		await process_frame
		if not is_instance_valid(s):
			return false
		var b := _find_button(s, btn)
		if b:
			texts.append(_card_text(s))
			b.pressed.emit()
			return true
	return false

func _relearn_pick(slot: int, texts: Array) -> bool:
	for i in 600:
		await process_frame
		var layer: Node = root.get_node("Router")._menu_layer
		if layer.get_child_count() > 0:
			var m: Node = layer.get_child(0)
			if m._mode == "forget" and not m._buttons.is_empty():
				var t := []
				_labels(m, t)
				texts.append(" / ".join(t))
				if slot < 0:   # back out
					m._on_cancel()
				else:
					m._buttons[slot].pressed.emit()
				return true
	return false

func _setup(lead: Creature) -> void:
	Gm.new_game()
	Gm.data.party = [lead]
	Gm.data.pieces = {}

func _scenario_teach_free_slot() -> void:
	print("--- teach into a free slot")
	var lead := _lead(["brook"], 20, 2)
	_setup(lead)
	var s := _screen()
	var texts := []
	_finish(s, 7)
	check(await _press(s, "Teach it", texts), "offer card appears with Teach it")
	check("Teach it Ducks and Drakes?" in texts[0], "offer text names the move: " + texts[0])
	check(await _press(s, "OK", texts), "learned toast appears")
	check("learned" in texts[1], "toast: " + texts[1])
	check(lead.has_move("ducks_and_drakes") and lead.moves.size() == 3, "lead has the move in the free slot")
	check(PartyPieces.rosette(Gm.data, "skimming") == 2 and Gm.data.money == 0 + Gm.data.money, "silver rosette")
	for i in 120:
		await process_frame
	check(s._done, "screen closed after the prompt")
	s.queue_free()

func _scenario_teach_full_slots(slot: int) -> void:
	print("--- teach with 4 moves, slot=%d" % slot)
	var lead := _lead(["brook"], 30, 4)
	_setup(lead)
	check(lead.moves.size() == 4, "lead has 4 moves")
	var old_ids := lead.moves.map(func(m): return str(m.id))
	var s := _screen()
	var texts := []
	_finish(s, 7)
	check(await _press(s, "Teach it", texts), "offer card")
	check(await _relearn_pick(slot, texts), "which-move-makes-way step shows")
	check("makes way for" in texts[1], "text: " + texts[1].substr(0, 120))
	if slot >= 0:
		check(await _press(s, "OK", texts), "post-teach toast")
		check(lead.has_move("ducks_and_drakes") and lead.moves.size() == 4, "move taught, still 4")
		check(str(lead.moves[slot].id) == "ducks_and_drakes" and old_ids[slot] != "ducks_and_drakes", "replaced slot %d" % slot)
		check("learned" in texts[2], "toast: " + texts[2])
	else:
		check(await _press(s, "OK", texts), "post-back-out toast")
		check(not lead.has_move("ducks_and_drakes"), "backing out teaches nothing")
		check("did not learn" in texts[2], "toast: " + texts[2])
		check(PartyPieces.unlocked(Gm.data, "skimming"), "still unlocked for the Almanac")
	for i in 120:
		await process_frame
	check(s._done, "screen closed")
	s.queue_free()

func _scenario_cannot_learn() -> void:
	print("--- lead cannot learn")
	var lead := _incompatible("skimming")
	_setup(lead)
	var s := _screen()
	var texts := []
	_finish(s, 7)
	check(await _press(s, "OK", texts), "toast")
	check("cannot learn" in texts[0] and "Almanac" in texts[0], "message: " + texts[0])
	for i in 120:
		await process_frame
	check(s._done and not lead.has_move("ducks_and_drakes"), "closed, nothing taught")
	s.queue_free()

func _scenario_gold_first_play() -> void:
	print("--- gold in one go (silver + gold together)")
	var lead := _lead(["brook"], 20, 2)
	_setup(lead)
	var money := int(Gm.data.money)
	var s := _screen()
	var texts := []
	_finish(s, 12)
	check(await _press(s, "OK", texts), "gold toast first")
	check("Gold" in texts[0] and "prize" in texts[0], "player is told about the gold/prize: " + texts[0])
	check(Gm.data.money == money + PartyPieces.GOLD_PRIZE, "prize paid once")
	check(await _press(s, "Teach it", texts), "then the offer card")
	await _press(s, "OK", texts)
	for i in 120:
		await process_frame
	s.queue_free()

func _scenario_gold_once() -> void:
	print("--- gold paid once")
	var lead := _lead(["brook"], 20, 2)
	_setup(lead)
	var money := int(Gm.data.money)
	for round in 2:
		var s := _screen()
		var texts := []
		_finish(s, 12)
		if round == 0:
			await _press(s, "OK", texts)
			await _press(s, "Teach it", texts)
			await _press(s, "OK", texts)
		else:
			# already unlocked + gold: nothing to show at all
			for i in 200:
				await process_frame
		for i in 120:
			await process_frame
		s.queue_free()
	check(Gm.data.money == money + PartyPieces.GOLD_PRIZE, "prize once across two gold plays, money=%d" % (Gm.data.money - money))
	check(TrainerStats.get_count(Gm.data, "masters_beaten") == 1, "masters_beaten 1")

func _scenario_almanac_reteach() -> void:
	print("--- almanac re-teach")
	var a := _lead(["brook"], 20, 2)
	var b := _lead(["brook"], 30, 4)
	var o := _incompatible("skimming")
	_setup(a)
	Gm.data.party.append(b)
	Gm.data.party.append(o)
	a.moves.append(a.make_move_slot("ducks_and_drakes", Gm.moves))
	PartyPieces.record(Gm.data, "skimming", 7.0)
	var alm: Node = load("res://ui/almanac_screen.tscn").instantiate()
	root.add_child(alm)
	alm.setup("pieces")
	for i in 5:
		await process_frame
	var row := _find_any_with(alm, "Stone skimming   Silver")
	check(row != null, "page lists skimming with its Silver mark")
	row.focus_entered.emit()
	await process_frame
	await process_frame
	await process_frame
	var seen := []
	_labels(alm, seen)
	check(a.display_name() + " already knows it." in seen, "knower is marked: " + str(seen.filter(func(t): return "know" in t or "cannot" in t)))
	check((o.display_name() + " cannot learn it.") in seen, "incompatible member is marked")
	var btn := _find_button(alm, "Teach %s" % b.display_name())
	check(btn != null, "Teach button for the compatible member with 4 moves")
	btn.pressed.emit()
	var texts := []
	check(await _relearn_pick(2, texts), "which-move-makes-way step from the Almanac")
	for i in 30:
		await process_frame
	check(b.has_move("ducks_and_drakes") and b.moves.size() == 4, "re-taught for free")
	var after := []
	_labels(alm, after)
	check(after.any(func(t): return "learned" in t), "almanac note after teach")
	alm.queue_free()

func _find_any_with(n: Node, text: String) -> Node:
	if (n is Button or n is Label) and n.text.find(text) >= 0:
		return n
	for c in n.get_children():
		var r := _find_any_with(c, text)
		if r:
			return r
	return null
