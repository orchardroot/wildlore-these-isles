class_name StoryValidator
extends RefCounted
## Checks dialogue scripts, trainers and the NPCs that use them against the rest of the data.

const COMMANDS := ["say", "choice", "if", "set", "give_item", "give_creature", "heal", "battle", "move", "face",
	"face_player", "wait", "warp", "shop", "starter", "fade_out", "fade_in", "music", "sfx", "badge", "end", "whiteout", "ark", "rail", "ferry", "legend", "gauntlet", "credits", "daily", "when", "relearn", "sachet_worn", "quiz", "craft", "recipe", "fieldbook_news", "rewild", "standing", "overseas", "overseas_home", "tournament", "bureau", "exchange", "market", "crypto", "casino", "society", "deed", "lease", "regular", "darts", "bowls", "skim", "crab_comp", "breed", "evidence", "casebook", "guild", "ring", "wall", "crossword", "games", "sing", "conkers", "lesson", "say_it", "science", "forecast", "wardrobe"]
const CONDITIONS := ["dawn", "day", "dusk", "night", "rain", "fog", "gale", "frost", "sunshine", "caught_all",
	"caught_25", "caught_50", "caught_100", "caught_150", "caught_200",
	"spring", "summer", "autumn", "winter", "halloween", "bonfire_night", "christmas", "st_patricks", "st_davids", "burns_night"]
## `when` "party_has_<species>" (Commands._party_has): the species must exist. Spelt out here, not read from
## Commands, so the validator stays free of the UI scripts Commands pulls in.
const PARTY_HAS := "party_has_"
const MOVE_MODES := ["still", "wander", "pace"]
const PHASES := ["dawn", "day", "dusk", "night"]
## An NPC with a `times` schedule may only chat: any other command makes it part of the story.
const CHAT_COMMANDS := ["say", "when", "if", "daily"]
## People who must always be at their post, whatever the hour.
const ALWAYS_OUT_SPRITES := ["shopkeeper", "sanctuary_nurse", "rail_guard", "sailor"]
const DIRS := ["up", "down", "left", "right"]

static func validate(dex: Dex, moves: MoveDB, items: ItemDB, zones: Dictionary) -> Array:
	var errors := []
	var dialogue := StoryData.all_dialogue()
	for file in dialogue:
		for sid in dialogue[file]:
			var cmds = dialogue[file][sid]
			if not cmds is Array:
				errors.append("dialogue %s/%s: script is not a list" % [file, sid])
				continue
			errors.append_array(validate_commands(cmds, "dialogue %s/%s" % [file, sid], dex, items, zones))
	for tid in StoryData.trainer_ids():
		errors.append_array(_validate_trainer(tid, dex, moves, items, zones))
	errors.append_array(Crafting.validate(items))
	errors.append_array(Jobs.validate(items, dex, zones))
	errors.append_array(_validate_rewild(dex, items, zones))
	var targets := _npc_targets(dialogue)
	for zid in zones:
		var z: ZoneData = zones[zid]
		var seen_ids := {}
		for n in z.npcs:
			var tag := "zone %s npc '%s': " % [zid, n.get("id", "?")]
			var nid := str(n.get("id", ""))
			if nid == "" or seen_ids.has(nid):
				errors.append(tag + "id is missing or duplicated")
			seen_ids[nid] = true
			if str(n.get("move", "still")) not in MOVE_MODES:
				errors.append(tag + "unknown move mode '%s'" % n.get("move"))
			if str(n.get("facing", "down")) not in DIRS:
				errors.append(tag + "unknown facing")
			var sc := str(n.get("script", ""))
			if sc != "" and StoryData.script(zid, sc).is_empty():
				errors.append(tag + "script '%s' does not exist for this zone" % sc)
			var tr := str(n.get("trainer", ""))
			if tr != "" and not StoryData.trainer_exists(tr):
				errors.append(tag + "trainer '%s' does not exist" % tr)
			if n.has("routine"):
				for e in routine_errors(n, StoryData.script(zid, sc) if sc != "" else [], targets, z, Routines.blocked_tiles_except(z, n)):
					errors.append(tag + e)
			if n.has("times"):
				for e in times_errors(n, StoryData.script(zid, sc) if sc != "" else [], targets):
					errors.append(tag + e)
	return errors

## A schedule (`times`) only suits townsfolk who chat: never a trainer, a shopkeeper, nurse, rail guard or sailor,
## nor anyone whose script does more than talk or whom a story beat moves or turns (`npc_targets`).
static func times_errors(n: Dictionary, cmds: Array, npc_targets: Dictionary) -> Array:
	var errors := []
	var times = n.get("times")
	if not times is Array or times.is_empty():
		errors.append("times must be a list of phases")
	else:
		for t in times:
			if str(t) not in PHASES:
				errors.append("unknown time '%s' (use %s)" % [t, ", ".join(PHASES)])
	if str(n.get("trainer", "")) != "":
		errors.append("a trainer can't keep hours (times)")
	if str(n.get("sprite", "")) in ALWAYS_OUT_SPRITES:
		errors.append("'%s' must always be at their post (no times)" % n.get("sprite"))
	if npc_targets.has(str(n.get("id", ""))):
		errors.append("a story beat moves this NPC, so it can't keep hours (times)")
	var story := _story_commands(cmds)
	if not story.is_empty():
		errors.append("story-critical script (%s) can't have times" % ", ".join(story))
	return errors

## A routine (core/routines.gd) has the same limits as `times`, a still NPC only, and slots on plain tiles clear of doors.
static func routine_errors(n: Dictionary, cmds: Array, npc_targets: Dictionary, z: ZoneData, blocked: Dictionary) -> Array:
	var errors := Routines.errors(n, z, blocked)
	if str(n.get("move", "still")) != "still":
		errors.append("a routine needs move still")
	if str(n.get("trainer", "")) != "":
		errors.append("a trainer can't keep a routine")
	if str(n.get("sprite", "")) in ALWAYS_OUT_SPRITES:
		errors.append("'%s' must always be at their post (no routine)" % n.get("sprite"))
	if npc_targets.has(str(n.get("id", ""))):
		errors.append("a story beat moves this NPC, so it can't keep a routine")
	var story := _story_commands(cmds)
	if not story.is_empty():
		errors.append("story-critical script (%s) can't have a routine" % ", ".join(story))
	return errors

static func _story_commands(cmds: Array, out: Array = []) -> Array:
	for c in cmds:
		if not c is Dictionary:
			continue
		var op := str(c.get("do", ""))
		if op not in CHAT_COMMANDS and op not in out:
			out.append(op)
		_story_commands(c.get("then", []), out)
		_story_commands(c.get("else", []), out)
	return out

## Every NPC id a script moves, turns or heals at (story beats need them there).
static func _npc_targets(dialogue: Dictionary) -> Dictionary:
	var out := {}
	var lists: Array = []
	for file in dialogue:
		for sid in dialogue[file]:
			if dialogue[file][sid] is Array:
				lists.append(dialogue[file][sid])
	for tid in StoryData.trainer_ids():
		lists.append(StoryData.trainer(tid).get("intro", []))
	while not lists.is_empty():
		for c in lists.pop_back():
			if not c is Dictionary:
				continue
			if c.has("npc"):
				out[str(c.npc)] = true
			for k in ["then", "else"]:
				if c.get(k) is Array:
					lists.append(c[k])
	return out

static func validate_commands(cmds: Array, tag: String, dex: Dex, items: ItemDB, zones: Dictionary) -> Array:
	var errors := []
	for c in cmds:
		if not c is Dictionary:
			errors.append("%s: command is not an object" % tag)
			continue
		var op := str(c.get("do", ""))
		if op not in COMMANDS:
			errors.append("%s: unknown command '%s'" % [tag, op])
			continue
		match op:
			"say":
				if str(c.get("text", "")) == "":
					errors.append("%s: say with no text" % tag)
			"choice":
				if c.get("options", []).size() < 2:
					errors.append("%s: choice needs at least two options" % tag)
			"if":
				if str(c.get("flag", "")) == "":
					errors.append("%s: if with no flag" % tag)
				errors.append_array(validate_commands(c.get("then", []), tag, dex, items, zones))
				errors.append_array(validate_commands(c.get("else", []), tag, dex, items, zones))
			"daily":
				if str(c.get("key", "")) == "":
					errors.append("%s: daily with no key" % tag)
				errors.append_array(validate_commands(c.get("then", []), tag, dex, items, zones))
				errors.append_array(validate_commands(c.get("else", []), tag, dex, items, zones))
			"when":
				var cond := str(c.get("cond", ""))
				if cond.begins_with(PARTY_HAS):
					if not dex.has(cond.substr(PARTY_HAS.length())):
						errors.append("%s: when %s names an unknown species" % [tag, cond])
				elif cond.begins_with("has_"):
					if not dex.has(cond.substr(4)):
						errors.append("%s: when has_ names an unknown species '%s'" % [tag, cond.substr(4)])
				elif cond.begins_with("caught_") and dex.has(cond.substr(7)):
					pass
				elif (cond.begins_with("guild_") or cond.begins_with("regular_")) and cond.rsplit("_", true, 1)[1].is_valid_int():
					pass
				elif cond not in CONDITIONS and not Festivals.is_cond(cond):
					errors.append("%s: when with unknown cond '%s'" % [tag, c.get("cond", "")])
				errors.append_array(validate_commands(c.get("then", []), tag, dex, items, zones))
				errors.append_array(validate_commands(c.get("else", []), tag, dex, items, zones))
			"legend":
				if not dex.has(str(c.get("species", ""))):
					errors.append("%s: legend species '%s' does not exist" % [tag, c.get("species", "")])
			"set":
				if str(c.get("flag", "")) == "":
					errors.append("%s: set with no flag" % tag)
			"give_item":
				if not items.has(str(c.get("item", ""))):
					errors.append("%s: give_item '%s' does not exist" % [tag, c.get("item", "")])
			"give_creature":
				if not dex.has(str(c.get("species", ""))):
					errors.append("%s: give_creature '%s' does not exist" % [tag, c.get("species", "")])
			"battle":
				if not StoryData.trainer_exists(str(c.get("trainer", ""))):
					errors.append("%s: battle trainer '%s' does not exist" % [tag, c.get("trainer", "")])
			"warp":
				if not zones.has(str(c.get("zone", ""))):
					errors.append("%s: warp to unknown zone '%s'" % [tag, c.get("zone", "")])
			"overseas_home":
				if Overseas.get_entry(str(c.get("territory", ""))).is_empty():
					errors.append("%s: overseas_home territory '%s' is not in data/overseas" % [tag, c.get("territory", "")])
			"shop":
				if not items.shops.has(str(c.get("id", ""))):
					errors.append("%s: shop '%s' does not exist" % [tag, c.get("id", "")])
			"market":
				if MarketHall.hall(str(c.get("hall", ""))).is_empty():
					errors.append("%s: market hall '%s' is not in data/market_halls.json" % [tag, c.get("hall", "")])
			"breed":
				if str(c.get("act", "")) not in ["pair", "collect", "status", "goal", "challenge", "sim"]:
					errors.append("%s: breed with unknown act '%s'" % [tag, c.get("act", "")])
				if str(c.get("act", "")) == "goal" and Breeding.goal(str(c.get("id", ""))).is_empty():
					errors.append("%s: breed goal '%s' is not in data/breeding.json" % [tag, c.get("id", "")])
			"deed":
				if Deeds.get_deed(str(c.get("id", ""))).is_empty():
					errors.append("%s: deed '%s' is not in data/deeds" % [tag, c.get("id", "")])
			"lease":
				if str(c.get("id", "")) != "" and Leases.get_lease(str(c.get("id", ""))).is_empty():
					errors.append("%s: lease '%s' is not in data/leases" % [tag, c.get("id", "")])
			"guild":
				if not Guilds.IDS.has(str(c.get("id", ""))):
					errors.append("%s: no guild '%s'" % [tag, c.get("id", "")])
			"exchange":
				if Markets.board(str(c.get("board", ""))).is_empty():
					errors.append("%s: no Stock Exchange board '%s'" % [tag, c.get("board", "")])
			"quiz":
				if str(c.get("pub", "")) == "":
					errors.append("%s: quiz with no pub id" % tag)
				if str(c.get("region", "all")) not in PubQuiz.REGIONS:
					errors.append("%s: quiz with unknown region '%s'" % [tag, c.get("region", "")])
			"darts":
				if Darts.league(str(c.get("nation", ""))).is_empty():
					errors.append("%s: darts with no league for nation '%s'" % [tag, c.get("nation", "")])
			"bowls":
				if Bowls.venue(str(c.get("venue", ""))).is_empty():
					errors.append("%s: bowls with no venue '%s'" % [tag, c.get("venue", "")])
			"skim":
				if Skimming.venue(str(c.get("venue", ""))).is_empty():
					errors.append("%s: skim with no venue '%s'" % [tag, c.get("venue", "")])
			"crab_comp":
				if not Crabbing.is_spot(str(c.get("harbour", ""))):
					errors.append("%s: crab_comp at '%s', which is not a crabbing spot" % [tag, c.get("harbour", "")])
			"games":
				for ev in c.get("events", []):
					if Games.event(str(ev)).is_empty():
						errors.append("%s: games with unknown event '%s'" % [tag, ev])
			"wall":
				if not Walling.SIZES.has(str(c.get("level", "normal"))):
					errors.append("%s: wall with unknown level '%s'" % [tag, c.get("level", "")])
				if str(c.get("site", "")) != "" and Rewild.site(str(c.site)).is_empty():
					errors.append("%s: wall at unknown rewilding site '%s'" % [tag, c.site])
			"craft":
				if str(c.get("bench", "")) not in Crafting.BENCHES:
					errors.append("%s: craft at unknown bench '%s'" % [tag, c.get("bench", "")])
			"evidence":
				if not Casebook.is_evidence(str(c.get("id", ""))):
					errors.append("%s: evidence '%s' is in no case" % [tag, c.get("id", "")])
			"casebook":
				if Casebook.get_case(str(c.get("id", ""))).is_empty():
					errors.append("%s: casebook with unknown case '%s'" % [tag, c.get("id", "")])
			"regular":
				if Regulars.get_reg(str(c.get("id", ""))).is_empty():
					errors.append("%s: regular with unknown id '%s'" % [tag, c.get("id", "")])
			"standing":
				if not Standing.is_nation(str(c.get("nation", ""))):
					errors.append("%s: standing with unknown nation '%s'" % [tag, c.get("nation", "")])
				if int(c.get("amount", 0)) < 1:
					errors.append("%s: standing amount must be 1 or more" % tag)
			"recipe":
				var ids = c.get("id", [])
				for id in (ids if ids is Array else [ids]):
					if not Crafting.has(str(id)):
						errors.append("%s: recipe '%s' does not exist" % [tag, id])
			"move":
				for d in c.get("path", []):
					if str(d) not in DIRS:
						errors.append("%s: move path has bad direction '%s'" % [tag, d])
			"rewild":
				if Rewild.site(str(c.get("site", ""))).is_empty():
					errors.append("%s: rewild site '%s' does not exist" % [tag, c.get("site", "")])
			"face":
				if str(c.get("dir", "")) not in DIRS:
					errors.append("%s: face with bad direction" % tag)
			"casino":
				if str(c.get("game", "")) not in Punt.GAMES:
					errors.append("%s: casino with unknown game '%s'" % [tag, c.get("game", "")])
				if str(c.get("game", "")) == "races" and str(c.get("venue", "")) not in Punt.RACE_VENUES:
					errors.append("%s: races at unknown venue '%s'" % [tag, c.get("venue", "")])
			"science":
				if str(c.get("kind", "any")) not in ScienceFair.KINDS + ["any"]:
					errors.append("%s: science with unknown kind '%s'" % [tag, c.get("kind", "")])
			"tournament":
				if str(c.get("id", "")) not in ["show", "show_menu", "moot", "trade"]:
					errors.append("%s: tournament with unknown id '%s'" % [tag, c.get("id", "")])
	return errors

## data/rewild.json: zones, rewards (story commands), task items and trainers, returning species.
static func _validate_rewild(dex: Dex, items: ItemDB, zones: Dictionary) -> Array:
	var errors := []
	for s in Rewild.sites():
		var tag := "rewild %s" % s.get("id", "?")
		if not zones.has(str(s.get("zone", ""))):
			errors.append("%s: zone '%s' does not exist" % [tag, s.get("zone", "")])
		if Rewild.looks(str(s.get("biome", ""))).size() != 4:
			errors.append("%s: biome '%s' needs four stage looks" % [tag, s.get("biome", "")])
		for r in s.get("rewards", []):
			errors.append_array(validate_commands(r, tag + " reward", dex, items, zones))
		for t in Rewild.tasks(s):
			for id in t.get("items", {}):
				if not items.has(str(id)):
					errors.append("%s: task item '%s' does not exist" % [tag, id])
			if t.has("trainer") and not StoryData.trainer_exists(str(t.trainer)):
				errors.append("%s: trainer '%s' does not exist" % [tag, t.trainer])
		for stage in s.get("encounters", []):
			for e in stage:
				if not dex.has(str(e.get("species", ""))):
					errors.append("%s: species '%s' does not exist" % [tag, e.get("species", "")])
	errors.append_array(validate_commands(Rewild._all().get("complete", []), "rewild complete", dex, items, zones))
	return errors

static func _validate_trainer(tid: String, dex: Dex, moves: MoveDB, items: ItemDB, zones: Dictionary) -> Array:
	var errors := []
	var tag := "trainer %s" % tid
	var raw = JsonUtil.read(StoryData.TRAINER_DIR.path_join(tid + ".json"))
	if not raw is Dictionary:
		return ["%s: not a JSON object" % tag]
	if str(raw.get("id", "")) != tid:
		errors.append("%s: id does not match file name" % tag)
	if str(raw.get("name", "")) == "":
		errors.append("%s: no name" % tag)
	if str(raw.get("ai", "trainer")) not in ["trainer", "keeper"]:
		errors.append("%s: unknown ai '%s'" % [tag, raw.get("ai")])
	if raw.get("party", []).is_empty():
		errors.append("%s: empty party" % tag)
	if bool(raw.get("double", false)) and raw.get("party", []).size() < 2:
		errors.append("%s: a double battle needs a party of at least 2" % tag)
	if int(raw.get("money", 0)) < 0:
		errors.append("%s: negative money" % tag)
	if raw.has("scaled_floor") and (int(raw.scaled_floor) < 2 or int(raw.scaled_floor) > Rules.MAX_LEVEL):
		errors.append("%s: scaled_floor %s should be a par level, 2 to %d" % [tag, raw.scaled_floor, Rules.MAX_LEVEL])
	for m in raw.get("party", []):
		var sp := str(m.get("species", ""))
		if not dex.has(sp):
			errors.append("%s: species '%s' does not exist" % [tag, sp])
		var lv := int(m.get("level", 0))
		if lv < 1 or lv > Rules.MAX_LEVEL:
			errors.append("%s: level %d out of range" % [tag, lv])
		var mv: Array = m.get("moves", [])
		if mv.size() > Rules.MAX_MOVES:
			errors.append("%s: too many fixed moves for %s" % [tag, sp])
		for id in mv:
			if not moves.has(str(id)):
				errors.append("%s: move '%s' does not exist" % [tag, id])
	errors.append_array(validate_commands(raw.get("intro", []), tag + " intro", dex, items, zones))
	return errors
