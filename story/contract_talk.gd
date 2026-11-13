class_name ContractTalk
extends RefCounted
## Contracts in conversation (see Contracts). {"do": "contract", "as": ...} where `as` is one of:
##   board   {town}        the notice on top of a noticeboard: read it, take it, haggle, or leave it
##   poster  {id}          the person who posted it: the story again, a nudge, the report and the fee, the afterword
##   clue    {id, clue}    a witness (a look-spot in a zone is handled by ExamineScene, not here)
##   lair    {id}          the named creature in its lair: what you have worked out, the fight, the decision
## Runs inside Commands through its host, so tests drive it with a fake one.

const THINK := "Think it over"

static func run(cmd: Commands, c: Dictionary) -> void:
	match str(c.get("as", "")):
		"board":
			await board(cmd, str(c.get("town", cmd.host.zone_id())))
		"poster":
			await poster(cmd, str(c.get("id", "")))
		"clue":
			await clue(cmd, str(c.get("id", "")), str(c.get("clue", "")))
		"lair":
			await lair(cmd, str(c.get("id", "")))
		_:
			push_warning("ContractTalk: unknown role '%s'" % c.get("as", ""))

static func _lines(host, who: String, lines: Variant) -> void:
	for l in (lines if lines is Array else [lines]):
		await host.say(who, str(l))

static func _money(host, gbp: int, zone_id: String) -> String:
	var cur := Wallet.currency_for_zone(zone_id)
	return Wallet.fmt(Wallet.localise(gbp, cur), cur)

# --- the board and the poster ----------------------------------------------------------

## The new notice on a board. False when there was none.
static func board(cmd: Commands, town: String) -> bool:
	var host = cmd.host
	var list := Contracts.offered(host.data, town)
	if list.is_empty():
		return false
	await host.say("", "A new notice is pinned over the rest, in careful handwriting.")
	if await host.choice("Read it?", ["Read the notice", "Just the jobs"]) != 0:
		return true
	await _offer(cmd, list[0], town)
	return true

static func _offer(cmd: Commands, c: Dictionary, town: String) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var who := str(c.poster.name)
	await host.say("", "%s. %s, %s." % [str(c.title), who, str(c.poster.role)])
	await _lines(host, who, c.notice)
	await _lines(host, who, c.trouble)
	var fee := Contracts.offer_fee(data, c)
	var options := ["Take it (%s)" % _money(host, fee, town)]
	var share := Contracts.haggle_share(data, c)
	if share > 0.0:
		options.append("Haggle (they know you here)")
	options.append("Leave it for now")
	var pick: int = await host.choice("Take the contract?", options)
	if pick >= options.size() - 1:
		return
	var haggle := pick == 1
	if haggle:
		await host.say(who, str(c.poster.get("haggle", "All right, all right. You've earned a fair price. Done.")))
	var r := Contracts.take(data, str(c.id), haggle)
	if not r.ok:
		return
	if host.has_method("sfx"):
		await host.sfx("confirm")
	await host.say("", "Contract taken: %s, for %s. It is in your Journal." % [str(c.title), _money(host, int(r.fee), town)])

static func poster(cmd: Commands, id: String) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var c := Contracts.get_contract(id)
	if c.is_empty():
		return
	var p: Dictionary = c.poster
	var who := str(p.name)
	match Contracts.state(data, id):
		0:
			if Contracts.available(data, c):
				await host.say(who, "I put a notice up on the board in the square. Have you got a minute?")
				await _offer(cmd, c, str(c.town))
			else:
				await _lines(host, who, p.idle)
		Contracts.TAKEN:
			await _lines(host, who, p.taken)
			var n := Contracts.found(data, c).size()
			await host.say("", "Your Journal: %d of %d leads followed." % [n, (c.clues as Array).size()])
		Contracts.DECIDED:
			await _report(cmd, c)
		_:
			var ch := Contracts.ending(data, c)
			await _lines(host, who, ch.get("after", p.get("closed", "That's all done with now. Thank you again.")))

static func _report(cmd: Commands, c: Dictionary) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var who := str(c.poster.name)
	var ch := Contracts.ending(data, c)
	await _lines(host, who, c.poster.decided)
	await _lines(host, who, ch.poster)
	var r := Contracts.report(data, str(c.id), host.zone_id())
	if not r.ok:
		return
	if int(r.amount) > 0:
		if host.has_method("sfx"):
			await host.sfx("item")
		await host.say("", "%s gives you %s." % [who, Wallet.fmt(int(r.amount), str(r.cur))])
	else:
		await host.say("", "%s offers nothing, and you do not ask." % who)
	for line in r.lines:
		await host.say("", str(line) + ".")
	await host.say("", "Contract closed: %s. The real story is in your Journal." % str(c.title))
	if host.has_method("autosave"):
		host.autosave()

# --- witnesses -------------------------------------------------------------------------

static func clue(cmd: Commands, id: String, clue_id: String) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var c := Contracts.get_contract(id)
	var k := Contracts.clue_of(c, clue_id)
	if k.is_empty():
		return
	var who := str(k.get("who", "Local"))
	var st := Contracts.state(data, id)
	if st == Contracts.TAKEN:
		await _lines(host, who, k.text)
		if Contracts.note_clue(data, id, clue_id):
			if host.has_method("sfx"):
				await host.sfx("item")
			await host.say("", "Journal: a new lead on %s." % str(c.title))
	elif st >= Contracts.DECIDED:
		await _lines(host, who, k.get("after", "That's all sorted now, one way or another. I'm glad of it."))
	else:
		await _lines(host, who, k.idle)

# --- the lair --------------------------------------------------------------------------

## What the clues add up to, in words: the Journal says the same.
static func theory_line(data: GameStateData, c: Dictionary) -> String:
	var t := Contracts.theory(data, c)
	if t.lead.is_empty():
		return "You have nothing solid yet. Anything you go in with is a guess."
	var names: Array = t.lead.map(func(h): return str(Contracts.hypothesis(c, str(h)).name))
	if not t.sure:
		return "You think it is one of these: %s." % " or ".join(names)
	var h := Contracts.hypothesis(c, str(t.lead[0]))
	return "You have worked it out: %s. %s. Bring something that is strong against %s." % [str(h.name), _types_text(h.types), _types_text(Contracts.weak_to(h.types), true)]

static func _types_text(types: Array, plain := false) -> String:
	var names: Array = types.map(func(t): return str(t).capitalize())
	if plain:
		return " or ".join(names) if not names.is_empty() else "nothing in particular"
	return "Types: " + " and ".join(names)

static func lair(cmd: Commands, id: String) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var c := Contracts.get_contract(id)
	if c.is_empty():
		return
	var lr: Dictionary = c.lair
	var nm := str(lr.name)
	if Contracts.state(data, id) != Contracts.TAKEN:
		await host.say("", "%s watches you, and is not interested in you now." % nm)
		return
	if not _on(data, Contracts.flag(id, "lair_seen")):
		await _lines(host, "", lr.intro)
		data.set_flag(Contracts.flag(id, "lair_seen"), true)
	if Contracts.beaten(data, id):
		await _decide(cmd, c)
		return
	await host.say("", theory_line(data, c))
	if await host.choice("Face %s?" % nm, ["Face it", "Not yet"]) != 0:
		return
	var guess := await _ask_guess(host, c)
	data.set_flag(Contracts.flag(id, "guess"), guess)
	if guess == "":
		await host.say("", "You go in with no idea what you are facing. It shows.")
	elif guess == str(c.truth):
		await host.say("", "You know what you are dealing with, and so does it.")
	else:
		await host.say("", "You are sure. It turns out you are wrong, and it is quick to take advantage.")
	var sp: Dictionary = host.dex.get_species(str(lr.species))
	var foe := Creature.create(sp, Contracts.fight_level(data, c, guess), host.rng, host.moves)
	foe.nickname = nm
	data.mark_seen(str(sp.id))
	var result: Dictionary = await host.battle([foe], {"kind": "wild", "no_run": true})
	match str(result.get("result", "")):
		"caught":
			await _finish(cmd, c, str(Contracts.catch_choice(c).get("id", "")))
		"lose":
			await cmd.whiteout()
			cmd._ended = true
		_:
			data.set_flag(Contracts.flag(id, "beaten"), true)
			await _lines(host, "", lr.get("beaten", "%s stands down, breathing hard, and waits to see what you will do." % nm))
			await _decide(cmd, c)

static func _on(data: GameStateData, key: String) -> bool:
	var v: Variant = data.flag(key)
	return v == true or ((v is int or v is float) and v != 0)

static func _ask_guess(host, c: Dictionary) -> String:
	var t := Contracts.theory(host.data, c)
	var open: Array = (c.hypotheses as Array).filter(func(h): return str(h.id) not in t.out)
	var options: Array = open.map(func(h): return str(h.name))
	options.append("I couldn't say")
	var pick: int = await host.choice("What do you reckon it is?", options)
	return str(open[pick].id) if pick < open.size() else ""

static func _decide(cmd: Commands, c: Dictionary) -> void:
	var host = cmd.host
	var menu := Contracts.menu_choices(c)
	var options: Array = menu.map(func(ch): return str(ch.label))
	options.append(THINK)
	var pick: int = await host.choice("%s is beaten, and it is up to you now. What will you do?" % str(c.lair.name), options)
	if pick >= menu.size():
		return
	await _finish(cmd, c, str(menu[pick].id))

static func _finish(cmd: Commands, c: Dictionary, choice_id: String) -> void:
	var host = cmd.host
	var r := Contracts.decide(host.data, str(c.id), choice_id)
	if not r.ok:
		return
	if host.has_method("sfx"):
		await host.sfx("badge")
	await _lines(host, "", r.choice.say)
	await host.say("", "Go and tell %s. It is in your Journal." % str(c.poster.name))
	if host.has_method("autosave"):
		host.autosave()
	# the zone is rebuilt so the creature stands or goes as the flags now say
	var t: Vector2i = host.heal_anchor("player")
	await host.warp(host.zone_id(), t.x, t.y, "down")
