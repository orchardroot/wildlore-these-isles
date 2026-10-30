class_name ScriptHooks
extends RefCounted
## One place where runtime systems add to an NPC's script without editing 1,300 dialogue files: a trade a
## resident offers, a game of Trumps after their chat, a word about the Keeper. Each hook takes the commands the
## NPC would have run and returns the commands to run instead (usually the same list with a few more on the end).
## Hooks are pure: they read `data` and the ids, never autoloads. Add yours as one line in `wrap`.

static func wrap(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	# w47 J: one talk, at most ONE offer prompt (priority: errand > trade you can make > front-room shop > Trumps),
	# plus the one-off lines (keeper gossip, one place on the map) and one unmet-ask line.
	var n := commands.size()
	var trumps: Array = Trumps.hook(zone_id, npc_id, commands, data).slice(n)
	var gossip: Array = KeeperIntel.hook(zone_id, npc_id, commands, data).slice(n)
	var place: Array = Poi.hook(zone_id, npc_id, commands, data).slice(n, n + 2)
	var wants: Dictionary = Wants.parts(zone_id, npc_id, data)
	var errand: Array = _first_errand(Errands.hook(zone_id, npc_id, commands, data).slice(n))
	if trumps.any(func(c): return c is Dictionary and c.get("give", "") == "starter"):
		return commands + trumps  # Mum's gift of the starter cards is a gift, not an offer
	if trumps.is_empty() and gossip.is_empty() and place.is_empty() and errand.is_empty() \
			and wants.trade.is_empty() and wants.asks.is_empty() and wants.shop.is_empty():
		return commands
	var out: Array = commands + gossip + place + wants.asks.slice(0, 1)
	for offer in [errand, wants.trade, wants.shop, trumps]:
		if not offer.is_empty():
			return out + offer
	return out

## Errands appends one entry per errand: a daily ask (1 command) or a step (say, set, and a hand-in on the last).
static func _first_errand(tail: Array) -> Array:
	if tail.is_empty() or str(tail[0].get("do", "")) == "daily":
		return tail.slice(0, 1)
	var end := 2
	if tail.size() > 2 and str(tail[2].get("do", "")) == "trade":
		end = 3
	return tail.slice(0, end)
