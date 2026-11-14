class_name RegularTalk
extends RefCounted
## Talking to a Regular: {"do": "regular", "id": id}. Plays whichever scene is waiting (see Regulars.next_beat), then
## offers their favourite if you're carrying it, or passes the time. Runs inside Commands through its host.

const YES_NO := ["Yes", "Not now"]
const NOT_NOW := "Not just yet"

static func run(cmd: Commands, c: Dictionary) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var id := str(c.get("id", ""))
	var r := Regulars.get_reg(id)
	if r.is_empty():
		push_warning("RegularTalk: no regular '%s'" % id)
		return
	var beat := Regulars.next_beat(data, id, host.zone_id())
	match beat:
		"intro":
			await _say_all(cmd, r, r.get("intro", []))
			Regulars.complete(data, id, "intro")
		"meet":
			await _say_all(cmd, r, r.get("meet", []))
			Regulars.complete(data, id, "meet")
		"offer":
			await _offer(cmd, r)
		"mums":
			await RegularMums.run(cmd, r)  # favour 5, at Mum's (story/regular_mums.gd)
			return
		_:
			var l := Regulars.chat_line(data, id)
			if c.get("bound", false) and Regulars.favour(data, id) < 2:
				l = ""  # a resident has already said their piece; chat is for friends
			if l != "":
				await _say_all(cmd, r, [l])
	await _gift(cmd, r)

## Lines may begin "Name: " for the person talking; anything else is narration.
static func _say_all(cmd: Commands, r: Dictionary, lines: Array) -> void:
	var first := Regulars.short_name(r)
	for l in lines:
		var t := str(l)
		var who := ""
		if t.begins_with(first + ": "):
			who = str(r.name)
			t = t.substr(first.length() + 2)
		await cmd.host.say(who, cmd._sub(t))

static func _gift(cmd: Commands, r: Dictionary) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var id := str(r.id)
	if not Regulars.met(data, id):
		return
	var item := Regulars.liked_item(id)
	var nm: String = host.items.get_item(item).get("name", item)
	if not Regulars.can_gift(data, id):
		if Regulars.favour(data, id) < Regulars.MAX_FAVOUR and int(data.bag.get(item, 0)) <= 0:
			await host.say("", str(r.hint))
		return
	if await host.choice("Give %s %s?" % [Regulars.short_name(r), nm], YES_NO) != 0:
		return
	var before := Regulars.favour(data, id)
	Regulars.give_gift(data, id)
	await host.sfx("item")
	await _say_all(cmd, r, r.get("thanks", []))
	var now := Regulars.favour(data, id)
	if now > before:
		await host.say("", "%s thinks well of you now. (Favour %d of %d.)" % [Regulars.short_name(r), now, Regulars.MAX_FAVOUR])

static func _offer(cmd: Commands, r: Dictionary) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var id := str(r.id)
	await _say_all(cmd, r, r.get("offer", []))
	if DeedChoices.character_line(id) != "":
		await host.say("", DeedChoices.character_line(id))   # w55: what they would be like in charge
	var deeds := Regulars.eligible_deeds(data)
	var names := deeds.map(func(d): return str(Deeds.get_deed(str(d)).get("name", d)))
	names.append(NOT_NOW)
	var pick: int = await host.choice("Put %s in charge of..." % Regulars.short_name(r), names)
	if pick < 0 or pick >= deeds.size():
		await host.say(str(r.name), "Ask any time. I'm not going anywhere. Well, I am, but I'll be back.")
		return
	if Regulars.appoint(data, id, str(deeds[pick])):
		await host.sfx("badge")
		await host.say("", "%s is now managing %s." % [str(r.name), names[pick]])
		for l in DeedChoices.manager_lines(DeedChoices.manager_traits(data, str(deeds[pick])), Regulars.short_name(r)).slice(1):
			await host.say("", str(l))
