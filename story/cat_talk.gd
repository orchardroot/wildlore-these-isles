class_name CatTalk
extends RefCounted
## The family cat's scenes: {"do": "family_cat", "op": ...}. Runs inside Commands through its host (core/family_cat.gd
## holds the rules, world/family_cat_scene.gd the walking). Ops:
##   say      {who, text}  a line with {cat} (her name) and {lead} (the creature beside you) filled in
##   approach            she trots up to you (the road scene)
##   join     {how: "new"|"waiting"}  she joins: at the starter's level on the road, at the story's par from home
##   collect  take her out of the house        leave  put her by the bowl (she keeps the window)

const NAME_PROMPT := "What does the family call her?"

static func run(cmd: Commands, c: Dictionary) -> void:
	var host = cmd.host
	match str(c.get("op", "")):
		"say":
			var t := str(c.get("text", "")).replace("{cat}", FamilyCat.display_name(host.data, host.dex))
			var lead: Creature = host.data.first_able()
			await host.say(cmd._sub(str(c.get("who", ""))), cmd._sub(t.replace("{lead}", lead.display_name() if lead != null else "your companion")))
		"approach":
			if host.has_method("family_cat"):
				await host.family_cat("approach")
		"join":
			await _join(cmd, str(c.get("how", "new")))
		"collect":
			await _collect(cmd)
		"leave":
			await _leave(cmd)
		_:
			push_warning("CatTalk: unknown op '%s'" % c.get("op", ""))

static func _stage(host, op: String) -> void:
	if host.has_method("family_cat"):
		await host.family_cat(op)

static func _join(cmd: Commands, how: String) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	if FamilyCat.has(data):
		return  # one cat, once
	var level := FamilyCat.starter_level(data, host.dex) if how == "new" else FamilyCat.par_level(data)
	var cat := FamilyCat.make(host.dex, host.moves, host.rng, level)
	await host.sfx("catch")
	var where := FamilyCat.join(data, cat)
	if where == "party":
		var pick: int = await host.choice(NAME_PROMPT, [FamilyCat.DEFAULT_NAME, "Something else"])
		if pick == 1:
			await host.open_menu("name:nickname:%d" % FamilyCat.party_index(data))  # the keyboard; backing out keeps the default
		if cat.nickname == "":
			cat.nickname = FamilyCat.DEFAULT_NAME
	FamilyCat.sync(data, host.dex)
	await _stage(host, "gone")
	if where == "party":
		await host.say("", "%s joined your team!" % cat.display_name())
	else:
		await host.say("", "Your team is full, so %s stays at home by her bowl. Collect her whenever there is room." % cat.display_name())
		await _stage(host, "home")

static func _collect(cmd: Commands) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var why := FamilyCat.collect(data, host.dex)
	if why != "":
		await host.say("", why)
		return
	FamilyCat.sync(data, host.dex)
	await host.sfx("catch")
	await _stage(host, "gone")
	await host.say("", "%s hops down and follows you out, tail up." % FamilyCat.display_name(data, host.dex))

static func _leave(cmd: Commands) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var name := FamilyCat.display_name(data, host.dex)
	var why := FamilyCat.leave(data)
	if why != "":
		await host.say("", why)
		return
	FamilyCat.sync(data, host.dex)
	await host.sfx("item")
	await host.say("", "%s heads for her bowl and sits down beside it, looking pleased with the arrangement." % name)
	await _stage(host, "home")
