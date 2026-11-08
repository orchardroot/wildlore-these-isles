class_name EventPlayer
extends RefCounted
## Turns Battle events into message lines and animation cues. Pure: no nodes, no autoloads.
## ctx comes from make_ctx(battle, trainer). Events are played right after the Battle call that made them,
## so battle.current_at(side, pos) is still the creature the event is about (a switch carries its own name).
## Its hp, status and stages are not: the Battle has worked out the whole turn, so they are already the end of it.
## Anything a name plate shows comes from the event itself ("hp", "status", "delta").
## Double-battle events carry "pos" (the field position); singles events have none and mean position 0.

const STAT_NAMES := {"atk": "Attack", "def": "Defence", "lore": "Lore", "ward": "Ward", "spd": "Speed", "acc": "Accuracy"}

static func make_ctx(battle: Battle, trainer: Dictionary = {}) -> Dictionary:
	return {"battle": battle, "trainer": trainer}

## Name of the creature on `side`, ready to start a sentence ("Kindlet", "The wild Spikkin", "Keeper Maud's Spikkin").
static func name_of(side: int, ctx: Dictionary, creature_name := "", pos := 0) -> String:
	var b: Battle = ctx.battle
	var n := creature_name
	if n == "":
		var c := b.current_at(side, pos)
		n = c.display_name() if c != null else "???"
	if side == Battle.PLAYER:
		return n
	if b.kind == "wild":
		return "The wild %s" % n
	var t := str(ctx.get("trainer", {}).get("name", ""))
	return "%s's %s" % [t, n] if t != "" else "The rival %s" % n

static func _mid(side: int, ctx: Dictionary, pos := 0) -> String:
	var s := name_of(side, ctx, "", pos)
	return "the" + s.substr(3) if s.begins_with("The ") else s

static func move_name(id: String, ctx: Dictionary) -> String:
	return str(ctx.battle.move_db.get_move(id).get("name", id.capitalize().replace("_", " ")))

static func lines_for(ev: Dictionary, ctx: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var side := int(ev.get("side", 0))
	var pos := int(ev.get("pos", 0))
	match str(ev.type):
		"move":
			out.append("%s used %s!" % [name_of(side, ctx, "", pos), move_name(str(ev.move), ctx)])
		"miss":
			out.append("%s's attack missed!" % name_of(side, ctx, "", pos))
		"no_effect":
			out.append("It doesn't affect %s..." % _mid(side, ctx, pos))
		"damage":
			if bool(ev.get("crit", false)):
				out.append("Right on the nose! A critical hit!")
			var e := float(ev.get("effectiveness", 1.0))
			# in doubles say who took it, since a spread move hits two
			var on := (" on %s" % _mid(side, ctx, pos)) if ev.has("pos") else ""
			if e > 1.0:
				out.append("It's super effective%s!" % on)
			elif e < 1.0 and e > 0.0:
				out.append("It's not very effective%s..." % on)
		"stat":
			var d := int(ev.delta)
			var stat := str(STAT_NAMES.get(ev.stat, ev.stat))
			var who := "%s's %s" % [name_of(side, ctx, "", pos), stat]
			if d == 0:
				out.append("%s won't go any further!" % who)
			elif d > 0:
				out.append("%s rose%s!" % [who, " sharply" if d >= 2 else ""])
			else:
				out.append("%s fell%s!" % [who, " harshly" if d <= -2 else ""])
		"status":
			var n := name_of(side, ctx, "", pos)
			match str(ev.status):
				"soaked": out.append("%s is soaked through." % n)
				"chilled": out.append("%s is chilled to the bone." % n)
				"muddled": out.append("%s is muddled!" % n)
				"hexed": out.append("%s has been hexed!" % n)
				"stung": out.append("%s has been stung!" % n)
				"asleep": out.append("%s is fast asleep." % n)
				_: out.append("%s is %s." % [n, ev.status])
		"status_cured":
			if str(ev.status) == "asleep":
				out.append("%s woke up!" % name_of(side, ctx, "", pos))
			else:
				out.append("%s is no longer %s." % [name_of(side, ctx, "", pos), ev.status])
		"cant_act":
			var n := name_of(side, ctx, "", pos)
			match str(ev.get("reason", "")):
				"asleep": out.append("%s is fast asleep." % n)
				"chilled": out.append("%s is too cold to move!" % n)
				"flinched": out.append("%s flinched and couldn't move!" % n)
				_: out.append("%s can't move!" % n)
		"self_hit":
			out.append("%s is muddled and hurt itself!" % name_of(side, ctx, "", pos))
		"status_damage":
			var n := name_of(side, ctx, "", pos)
			match str(ev.status):
				"stung": out.append("%s is hurt by its stings!" % n)
				"hexed": out.append("%s is hurt by the hex!" % n)
				_: out.append("%s is hurt by being %s!" % [n, ev.status])
		"faint":
			out.append("%s fainted!" % name_of(side, ctx, str(ev.get("user", "")), pos))
		"switch":
			if side == Battle.PLAYER:
				out.append("Go! %s!" % ev.user)
			else:
				var b: Battle = ctx.battle
				var t := str(ctx.get("trainer", {}).get("name", ""))
				if b.kind == "wild" or t == "":
					out.append("The wild %s steps up!" % ev.user)
				else:
					out.append("%s %s out %s!" % [t, verb(t, "sends"), ev.user])
		"run":
			if bool(ev.success):
				out.append("Got away safely!")
			elif ctx.battle.kind != "wild":
				out.append("No! There's no running from a keeper battle!")
			else:
				out.append("Couldn't get away!")
		"item":
			var item: Dictionary = {}
			if ctx.battle.item_db != null:
				item = ctx.battle.item_db.get_item(str(ev.get("item", "")))
			out.append("You used a %s." % item.get("name", str(ev.get("item", "item"))))
			out.append(str(ev.get("text", "")))
		"catch":
			if str(ev.get("reason", "")) == "trainer":
				out.append("You can't snare another keeper's creature!")
			else:
				out.append("You threw a %s!" % ev.get("snare_name", "snare"))
				if bool(ev.success):
					out.append("Gotcha! %s was caught!" % ctx.battle.current(Battle.FOE).display_name())
					if bool(ev.get("clean", false)):
						out.append("A clean catch: not a scratch on it, and fast asleep. Textbook.")
				else:
					match int(ev.get("wobbles", 1)):  # the wobbles come from the real roll, so the words can too
						3: out.append("Argh! So close! %s broke free at the last second!" % name_of(Battle.FOE, ctx))
						0: out.append("%s burst straight out!" % name_of(Battle.FOE, ctx))
						_: out.append("Oh no! %s broke free!" % name_of(Battle.FOE, ctx))
		"invalid":
			match str(ev.get("reason", "")):
				"needs_switch":
					out.append("Pick a creature to send out first.")
				"no_catch_in_doubles":
					out.append("You can't throw a snare into a double battle!")
				"no_run_in_doubles":
					out.append("There's no running from a double battle!")
				_:
					out.append("That creature can't be sent out.")
		"charm", "bond", "knack":
			out.append(charm_text(ev, ctx))
		"heal":
			if str(ev.get("reason", "")) == "drain":
				out.append("%s drained some of the foe's strength!" % name_of(side, ctx, "", pos))
			else:
				out.append("%s got some of its health back." % name_of(side, ctx, "", pos))
		"recoil":
			out.append("%s is hurt by the recoil!" % name_of(side, ctx, "", pos))
		"hits":
			var n := int(ev.get("count", 1))
			out.append("Hit once!" if n == 1 else "Hit %d times!" % n)
		"protect":
			out.append("%s braced itself!" % name_of(side, ctx, "", pos))
		"protected":
			out.append("%s protected itself!" % name_of(side, ctx, "", pos))
		"fail":
			out.append("But it failed!")
		"weather":
			out.append(weather_line(str(ev.weather), int(ev.get("turns", 0))))
		"weather_end":
			out.append(str(WEATHER_END.get(str(ev.get("was", "")), "The weather settles.")))
		"cure_team":
			out.append("%s's team feels right as rain again." % name_of(side, ctx, "", pos) if side == Battle.PLAYER else "%s's side feels right as rain again." % name_of(side, ctx, "", pos))
		"end":
			pass
	return out

## A keeper's verb: "sends" for one, "send" for a pair ("Aoife and Orla send out...").
static func verb(keeper: String, singular: String) -> String:
	return singular.trim_suffix("s") if " and " in keeper or " & " in keeper else singular

const WEATHER_START := {
	"drizzle": "A fine drizzle sets in for %d turns.",
	"downpour": "The heavens open: a proper downpour for %d turns!",
	"fog": "A thick fog rolls in for %d turns.",
	"frost": "A hard frost settles in for %d turns.",
	"sunshine": "The sun comes out for %d turns! Everyone's suddenly in shorts.",
	"gale": "A gale gets up for %d turns. Hold on to your hat!",
	"clear": "The sky clears for %d turns.",
}
const WEATHER_END := {
	"drizzle": "The drizzle eases off.", "downpour": "The downpour dies away.", "fog": "The fog lifts.",
	"frost": "The frost thaws.", "sunshine": "The sun goes back in. Typical.", "gale": "The gale blows itself out.",
	"clear": "The clouds come back.",
}

static func weather_line(w: String, turns: int) -> String:
	return str(WEATHER_START.get(w, "The weather turns for %d turns.")) % turns

## A charm or friendship line: "{name}" is the holder, "{other}" whoever it pricked. Mid-sentence names drop the capital.
static func charm_text(ev: Dictionary, ctx: Dictionary) -> String:
	var side := int(ev.get("side", 0))
	var pos := int(ev.get("pos", 0))
	var t := str(ev.get("text", ""))
	var n := str(ev.get("name", ""))
	var holder := name_of(side, ctx, n, pos) if t.begins_with("{name}") else _mid(side, ctx, pos)
	t = t.replace("{name}", holder)
	if ev.has("other_side"):
		var o_side := int(ev.other_side)
		var o_pos := int(ev.get("other_pos", 0))
		t = t.replace("{other}", name_of(o_side, ctx, "", o_pos) if t.begins_with("{other}") else _mid(o_side, ctx, o_pos))
	return t

## The animation cue for an event: {"cue": String, ...details}. The scene's BattleFX knows how to play each cue.
## In doubles every cue also carries "pos" (and attacks their "target_side" / "target_pos").
static func fx_for(ev: Dictionary, ctx: Dictionary) -> Dictionary:
	var cue := _cue(ev, ctx)
	if ev.has("pos") and cue.has("side"):
		cue["pos"] = int(ev.pos)
		if ev.type == "move":
			cue["target_side"] = int(ev.get("target_side", 1 - int(ev.side)))
			cue["target_pos"] = int(ev.get("target_pos", 0))
			cue["spread"] = bool(ev.get("spread", false))
		elif ev.has("other_pos"):
			cue["pos"] = int(ev.other_pos)
		elif ev.type == "miss":
			cue["side"] = int(ev.get("target_side", 1 - int(ev.side)))
			cue["pos"] = int(ev.get("target_pos", 0))
	return cue

static func _cue(ev: Dictionary, ctx: Dictionary) -> Dictionary:
	var side := int(ev.get("side", 0))
	match str(ev.type):
		"move":
			var mt := str(ctx.battle.move_db.get_move(str(ev.move)).get("type", ""))
			return {"cue": "attack", "side": side, "move_type": mt, "move": str(ev.move)}
		"miss":
			return {"cue": "dodge", "side": 1 - side}
		"no_effect":
			return {"cue": "shrug", "side": side}
		"damage":
			var e := float(ev.get("effectiveness", 1.0))
			var strength := "normal"
			if bool(ev.get("crit", false)) or e > 1.0:
				strength = "strong"
			elif e < 1.0:
				strength = "weak"
			var hit := {"cue": "hit", "side": side, "hp": int(ev.hp), "strength": strength}
			if bool(ev.get("crit", false)):
				hit["crit"] = true  # its own beat on the HUD (a gold flash), on top of the strong hit
			return hit
		"stat":
			return {"cue": "stat_up" if int(ev.delta) > 0 else "stat_down", "side": side, "stat": str(ev.stat)}
		"status":
			return {"cue": "status", "side": side, "status": str(ev.status)}
		"status_cured":
			return {"cue": "cure", "side": side}
		"cant_act":
			return {"cue": "idle", "side": side}
		"self_hit":
			return {"cue": "hit", "side": side, "hp": int(ev.hp), "strength": "normal"}
		"status_damage":
			return {"cue": "hit", "side": side, "hp": int(ev.hp), "strength": "weak"}
		"faint":
			return {"cue": "faint", "side": side}
		"switch":
			var sw := {"cue": "switch", "side": side, "index": int(ev.index)}
			for k in ["hp", "status"]:  # as it came in, not as the turn left it
				if ev.has(k):
					sw[k] = ev[k]
			return sw
		"run":
			return {"cue": "run" if bool(ev.success) else "idle", "side": Battle.PLAYER}
		"end":
			return {"cue": "end", "winner": int(ev.winner)}
		"charm", "bond", "knack":
			if ev.has("other_side"):  # a thistle (or prickly) prick: the attacker takes the hit
				return {"cue": "hit", "side": int(ev.other_side), "hp": int(ev.hp), "strength": "weak"}
			if ev.has("delta"):
				return {"cue": "stat_up" if int(ev.delta) > 0 else "shrug", "side": side, "stat": str(ev.get("stat", ""))}
			if ev.has("hp"):
				return {"cue": "heal", "side": side, "target": ctx.battle.active[side][int(ev.get("pos", 0))], "hp": int(ev.hp)}
			if ev.type == "knack":
				return {"cue": "knack", "side": side}
			return {"cue": "shrug", "side": side}
		"heal":
			return {"cue": "heal", "side": side, "target": ctx.battle.active[side][int(ev.get("pos", 0))], "hp": int(ev.hp)}
		"recoil":
			return {"cue": "hit", "side": side, "hp": int(ev.hp), "strength": "weak"}
		"protect":
			return {"cue": "protect", "side": side}
		"protected":
			return {"cue": "protect", "side": side}
		"fail":
			return {"cue": "idle", "side": side}
		"weather", "weather_end":
			return {"cue": "weather", "weather": str(ev.weather), "turns": int(ev.get("turns", 0))}
		"cure_team":
			return {"cue": "cure", "side": side, "team": ev.get("cured", [int(ev.get("pos", 0))])}
		"item":
			var item := {"cue": "heal", "side": side, "target": int(ev.get("target", 0))}
			for k in ["hp", "status"]:  # the target as the item left it (a turn's later events have moved it on since)
				if ev.has(k):
					item[k] = ev[k]
			return item
		"catch":
			return {"cue": "catch", "success": bool(ev.success), "wobbles": int(ev.get("wobbles", 3))}
	return {"cue": "none"}
