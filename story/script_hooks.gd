class_name ScriptHooks
extends RefCounted
## One place where runtime systems add to an NPC's script without editing 1,300 dialogue files: a trade a
## resident offers, a game of Trumps after their chat, a word about the Keeper. Each hook takes the commands the
## NPC would have run and returns the commands to run instead (usually the same list with a few more on the end).
## Hooks are pure: they read `data` and the ids, never autoloads. Add yours as one line in `wrap`.

static func wrap(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	var out := commands
	# wave 47 sessions add one line each here, e.g. out = Trades.hook(zone_id, npc_id, out, data)
	out = Trumps.hook(zone_id, npc_id, out, data)
	out = KeeperIntel.hook(zone_id, npc_id, out, data)
	out = Poi.hook(zone_id, npc_id, out, data)  # wave 47 H: a resident mentions a place on the map
	return out
