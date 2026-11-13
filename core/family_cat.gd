class_name FamilyCat
extends RefCounted
## The family cat: a small black house cat who went up on the moor the night the stones hummed and came back slightly
## more than a cat (Sootkit, Grimalkin, Cat-Sith). Only the player can ever have her, and only once: no encounter
## table, trainer, egg, trade or gift produces the line (problems() is the validator's rule), and she can't be released
## or sold. When she isn't in the party she lives at home by her bowl and is collected there.
## A new game meets her on the Cat and Fiddle road (scene_due). A save already past that road finds her waiting at
## home (waiting). Pure logic, no autoloads: the scenes are in world/family_cat_scene.gd and story/cat_talk.gd.
##
## Flags (absent = the old behaviour, so a save from before this has no cat and a perfectly good journey):
##   cat_met          she has joined you (once, for good)
##   family_cat_home  her creature (Creature.to_dict) while she stays at home; absent while she is in the party
##   cat_waiting      derived: an old save's cat is waiting at home to join   cat_with_you  derived: she is in the party
##   cat_note         the one-off "something's waiting at home" note has been shown

const LINE := ["sootkit", "grimalkin", "catsith"]
const DEFAULT_NAME := "Meadow"
const MET := "cat_met"
const HOME := "family_cat_home"
const WAITING := "cat_waiting"
const WITH_YOU := "cat_with_you"
const NOTE := "cat_note"
const ROAD := "cat_and_fiddle"
const HOME_ZONE := "macc_home"
## Data files that may name the line: her own, the lists every species is in, and the two scenes that give her to you.
const ALLOWED := ["res://data/creatures/sootkit.json", "res://data/dex_order.json", "res://data/genes.json",
	"res://data/knacks.json", "res://data/dialogue/macc_home.json", "res://data/dialogue/cat_and_fiddle.json"]

static func is_family_id(id: String) -> bool:
	return id in LINE

static func is_family(c: Creature) -> bool:
	return c != null and is_family_id(str(c.species.get("id", "")))

# --- where she is -----------------------------------------------------------------------

static func party_index(data: GameStateData) -> int:
	for i in data.party.size():
		if is_family(data.party[i]):
			return i
	return -1

static func in_party(data: GameStateData) -> bool:
	return party_index(data) >= 0

## She is the creature walking beside you: first in the party that can still walk.
static func is_lead(data: GameStateData) -> bool:
	return is_family(data.first_able())

static func at_home(data: GameStateData) -> bool:
	return data.flag(HOME) is Dictionary and not (data.flag(HOME) as Dictionary).is_empty()

## Hers, wherever she is: with you, or at home.
static func has(data: GameStateData) -> bool:
	return in_party(data) or at_home(data)

static func met(data: GameStateData) -> bool:
	return data.flag(MET) == true

## Has the story already taken you down the Cat and Fiddle road and on? (Buxton is the town at the far end.)
static func past_road(data: GameStateData) -> bool:
	return data.flag("visited_buxton") == true or not data.badges.is_empty() or ParLevel.par(data.flags) > ParLevel.START + 2

## An old save's cat: not met yet, and you are already past the road, so she is sat in the window at home.
static func waiting(data: GameStateData) -> bool:
	return not met(data) and not data.party.is_empty() and past_road(data)

## The first walk onto the Cat and Fiddle road with a starter: she is there.
static func scene_due(data: GameStateData, zone_id: String) -> bool:
	return zone_id == ROAD and not met(data) and not data.party.is_empty() and not past_road(data)

## Show her at home: waiting, or put by for a while.
static func home_visible(data: GameStateData) -> bool:
	return waiting(data) or at_home(data)

## Keeps the derived flags and the invariants true: she is never in the Ark, never both in the party and at home.
static func sync(data: GameStateData, dex: Dex) -> void:
	for i in range(data.ark.size() - 1, -1, -1):
		if is_family(data.ark[i]):
			var c: Creature = data.ark[i]
			data.ark.remove_at(i)
			if in_party(data) or at_home(data):
				continue  # a second one can't exist; the one you had stays
			data.flags[HOME] = c.to_dict()
	if in_party(data) and at_home(data):
		data.flags.erase(HOME)
	if in_party(data) or at_home(data):
		data.flags[MET] = true
	_mirror(data, WAITING, waiting(data))
	_mirror(data, WITH_YOU, in_party(data))

static func _mirror(data: GameStateData, key: String, on: bool) -> void:
	if on:
		data.flags[key] = true
	else:
		data.flags.erase(key)

## Her creature while she is at home, or null.
static func home_creature(data: GameStateData, dex: Dex) -> Creature:
	return Creature.from_dict(data.flag(HOME), dex) if at_home(data) else null

## The creature to show for her: in the party, at home, or the one she will be.
static func current(data: GameStateData, dex: Dex) -> Creature:
	var i := party_index(data)
	return data.party[i] if i >= 0 else home_creature(data, dex)

static func display_name(data: GameStateData, dex: Dex) -> String:
	var c := current(data, dex)
	return c.display_name() if c != null else DEFAULT_NAME

## Which species a cat of this level is, by the evolution levels (bond may bring them on earlier, in play).
static func species_at(dex: Dex, level: int) -> String:
	return ParLevel.stage(dex, LINE[0], level)

# --- joining ------------------------------------------------------------------------------

## The starter's level: the party member of the starter's line, else the lead. A new game's cat joins at this.
static func starter_level(data: GameStateData, dex: Dex) -> int:
	var sid := str(data.flag("starter")) if data.flag("starter") is String else ""
	var line := str(dex.get_species(sid).get("line", sid)) if dex.has(sid) else ""
	for c in data.party:
		if line != "" and str(c.species.get("line", c.species.get("id", ""))) == line:
			return c.level
	return data.party[0].level if not data.party.is_empty() else ParLevel.START

## An old save's cat: the story's par level, held to the best of the team (she has not been away that long).
static func par_level(data: GameStateData) -> int:
	var best := 1
	for c in data.party:
		best = maxi(best, c.level)
	return clampi(mini(ParLevel.par(data.flags), best), ParLevel.START, Rules.MAX_LEVEL)

## Makes her at `level`, as the stage that level gives (an old save's cat may already be a Grimalkin or more).
static func make(dex: Dex, moves: MoveDB, rng: Rng, level: int) -> Creature:
	var c := Creature.create(dex.get_species(species_at(dex, level)), level, rng, moves)
	c.friendship = 120  # she is family: a good start, never the whole way
	return c

## She joins for good. Into the party if there is room, else she waits at home. Returns "party" or "home".
static func join(data: GameStateData, c: Creature, nickname := DEFAULT_NAME) -> String:
	c.nickname = nickname
	data.mark_caught(str(c.species.id))
	data.flags[MET] = true
	data.flags.erase(HOME)
	var where := "home"
	if data.party.size() < GameStateData.PARTY_MAX:
		data.party.append(c)
		where = "party"
	else:
		data.flags[HOME] = c.to_dict()
	data.flags.erase(WAITING)
	_mirror(data, WITH_YOU, where == "party")
	return where

## Sends her home to her bowl. "" on success, else why not. The team always keeps someone able to fight.
static func leave(data: GameStateData) -> String:
	var i := party_index(data)
	if i < 0:
		return "She isn't with you."
	if data.party.size() <= 1:
		return "You can't travel without a single companion."
	var others := data.party.filter(func(x): return not is_family(x) and not x.is_fainted())
	if others.is_empty():
		return "She's the only one of your team fit to battle. Keep her with you."
	data.flags[HOME] = data.party[i].to_dict()
	data.party.remove_at(i)
	_mirror(data, WITH_YOU, false)
	return ""

## Brings her out of the house and into the party. "" on success, else why not.
static func collect(data: GameStateData, dex: Dex) -> String:
	if not at_home(data):
		return "She isn't at home."
	if data.party.size() >= GameStateData.PARTY_MAX:
		return "Your team is full. Leave someone in the Ark first."
	data.party.append(home_creature(data, dex))
	data.flags.erase(HOME)
	_mirror(data, WITH_YOU, true)
	return ""

const ARK_REASON := "Not the cat. She's family, and she doesn't do boxes. If she needs a rest, ask Mum to keep her by the bowl at home."

## Why she can't be released or boxed in the Ark, or "" if the creature isn't her.
static func keep_reason(c: Creature) -> String:
	return "" if not is_family(c) else "She's family. She would sit on your pillow until you came to your senses."

# --- scenes: what a script and the world ask --------------------------------------------

## The one-off note for a player with a waiting cat who isn't at home: header and text, or [].
static func note(data: GameStateData) -> Array:
	if data.flag(NOTE) == true or not waiting(data):
		return []
	return ["A note from Mum", "Something's been sat in the window since you left. Pop home when you're passing. x"]

## Her NPC for the home zone: in the window by her bowl, waiting or put by. A def for the overworld's side-NPC list.
static func npcs_for(zone_id: String, data: GameStateData, dex: Dex) -> Array:
	if zone_id != HOME_ZONE or not home_visible(data):
		return []
	var c := current(data, dex)
	var sid := str(c.species.id) if c != null else species_at(dex, par_level(data))
	return [{"id": "family_cat", "sprite": "creature:" + sid, "x": 7, "y": 3, "facing": "left", "move": "still",
		"script": "cat", "name": display_name(data, dex)}]

# --- her own lines as the follower ----------------------------------------------------------

const GENERAL := [
	"{name} walks ahead of you, tail up, as if she'd planned the route.",
	"{name} sits down in the middle of the path. You are expected to go round.",
	"{name} looks at something that is not there, then at you, then at something else that is not there.",
	"{name} knocks a pebble off the edge of the path and watches it all the way down.",
	"{name} blinks at you slowly. You blink back. It is the most you have said to each other all day.",
	"{name} washes one paw, then has second thoughts about the whole business.",
	"{name} has a small, private plan, and it involves a hedge.",
	"{name} pretends she was never following you.",
]
const HP_LINES := {
	"high": ["{name} is full of beans and has given a hedge a stern talking-to."],
	"mid": ["{name} is doing fine but would like it noted that she has been on her feet a while."],
	"low": ["{name} is tired and walking very close to your heels, which she would deny."],
}
const WEATHER_LINES := {
	"drizzle": ["{name} picks her way round every puddle and holds you responsible for them."],
	"downpour": ["{name} is wet, furious and dignified about it."],
	"fog": ["{name} watches something in the fog that you can't see, and doesn't like that you can't."],
	"gale": ["{name}'s ears are flat and her whiskers are making a break for it."],
	"frost": ["{name} lifts each paw off the frost in turn, like a very small ballerina."],
	"sunshine": ["{name} finds the one warm patch of path and lies in it, in your way."],
}
const PHASE_LINES := {
	"dawn": ["{name} sits very still and looks east, as if the sun owes her a word."],
	"day": ["{name} dozes with one eye open."],
	"dusk": ["{name}'s eyes have gone the colour of the moor at dusk."],
	"night": ["{name} is wide awake and rather pleased with the dark.", "{name} looks at the moon as if they have met."],
}
const PLACE_LINES := {
	"town": ["{name} has a look round {place} and finds it adequate."],
	"route": ["{name} stalks something in the long grass and gets away with it."],
	"cave": ["{name} can see perfectly well down here, thank you."],
	"interior": ["{name} has found the best chair and is considering it."],
}
## By form: what she is, as she grows.
const STAGE_LINES := {
	"sootkit": ["{name} washes behind one ear. A small black cat, doing small black cat things."],
	"grimalkin": ["{name}'s eyes catch the light in a way eyes don't, and she is unbothered."],
	"catsith": ["{name} walks so quietly that the heather forgets to rustle. The white spot on her chest is very white."],
}
const BOND_LINES := {
	3: ["{name} headbutts your shin in passing, once, like a cheque being signed."],
	4: ["{name} walks so close that you nearly tread on her. She would like you to keep trying."],
	5: ["{name} climbs onto your shoulder at a stile and rides there, purring like a small motor."],
}

## The lines that fit now, hers only.
static func mood_pool(species_id: String, hp_frac: float, weather: String, phase: String, kind: String, friendship: int) -> Array:
	var out: Array = GENERAL.duplicate()
	out.append_array(STAGE_LINES.get(species_id, []))
	out.append_array(BOND_LINES.get(Bond.hearts(friendship), []))
	out.append_array(HP_LINES["low" if hp_frac < 0.35 else ("mid" if hp_frac < 0.75 else "high")])
	out.append_array(WEATHER_LINES.get(weather, []))
	if weather == "clear" or phase != "day":
		out.append_array(PHASE_LINES.get(phase, []))
	out.append_array(PLACE_LINES.get(kind, []))
	return out

static func mood_line(c: Creature, hp_frac: float, weather: String, phase: String, place: String, kind: String, pick: int) -> String:
	var pool := mood_pool(str(c.species.get("id", "")), hp_frac, weather, phase, kind, c.friendship)
	return str(pool[posmod(pick, pool.size())]).replace("{name}", c.display_name()).replace("{place}", place)

# --- the validator's rule ---------------------------------------------------------------------

## Nothing but her own scenes may produce the line: no encounter table, trainer, egg, trade, gift or any other data
## mentions it, and the line is an appendix, non-breeding, habitat-free line. Returns error strings.
static func problems(dex: Dex, zones: Dictionary) -> Array:
	var errors := []
	for id in LINE:
		if not dex.has(id):
			errors.append("family cat: species '%s' is missing" % id)
			continue
		var sp := dex.get_species(id)
		if not bool(sp.get("appendix", false)):
			errors.append("family cat: %s must be an appendix species" % id)
		if not (sp.get("habitat", []) as Array).is_empty():
			errors.append("family cat: %s must have no habitat" % id)
		if bool(sp.get("legend", false)):
			errors.append("family cat: %s must not be a legend" % id)
	var kind: Variant = Genetics.genes().get("kindreds", {}).get(str(Genetics.genes().get("lines", {}).get(LINE[0], "")), {})
	if kind is Dictionary and bool(kind.get("breeds", false)):
		errors.append("family cat: her kindred must not breed (no egg can be hers)")
	for zid in zones:
		for table in zones[zid].encounters:
			for e in zones[zid].encounters[table]:
				if is_family_id(str(e.get("species", ""))):
					errors.append("family cat: zone %s has %s in its %s encounters" % [zid, e.species, table])
	var hits := []
	_scan("res://data", hits)
	for h in hits:
		errors.append("family cat: %s names her line, and only her own scenes may" % h)
	for file in ["macc_home", "cat_and_fiddle"]:
		for sid in StoryData.all_dialogue().get(file, {}):
			for g in _gives(StoryData.script(file, sid)):
				errors.append("family cat: dialogue %s/%s gives %s with give_creature; use family_cat join" % [file, sid, g])
	return errors

static func _gives(cmds: Variant, out: Array = []) -> Array:
	if cmds is Array:
		for c in cmds:
			_gives(c, out)
	elif cmds is Dictionary:
		if str(cmds.get("do", "")) in ["give_creature", "starter"]:
			var sp: Variant = cmds.get("species", "")
			for s in (sp if sp is Array else [sp]):
				if is_family_id(str(s)):
					out.append(str(s))
		for k in ["then", "else"]:
			_gives(cmds.get(k, []), out)
	return out

static func _scan(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		var path := dir.path_join(f)
		if not f.ends_with(".json") or path in ALLOWED:
			continue
		var text := FileAccess.get_file_as_string(path)
		for id in LINE:
			if text.contains('"%s"' % id):
				out.append(path)
				break
	for d in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(d), out)
