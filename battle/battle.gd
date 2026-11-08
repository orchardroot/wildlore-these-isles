class_name Battle
extends RefCounted
## One battle, resolved a turn at a time. Pure logic: callers submit actions and render the returned events.
## Event and action shapes are documented in docs/superpowers/plans/2026-10-14-plan-1-foundations-and-battle-core.md (Task 11).
##
## Double battles (opts.double = true): two field positions a side. `active[side]` is an Array of party indices,
## one per position (-1 for an empty position, e.g. a party of one). `take_turn` then takes an Array of actions per
## side, indexed by position; a move action carries `"target"`: the foe position (0 or 1) or "ally". Every event
## about a creature on the field also carries `"pos"` (singles events are unchanged and have no "pos").
## Spread moves (`"target": "all_foes"` in the move data) hit every foe at SPREAD_MULT damage. A move whose target
## fainted earlier in the turn swings at the other foe. Catching and running are refused in doubles.
##
## 2.0: the move effects in MoveFX (drain, recoil, multi_hit, heal_self, protect, flinch, set_weather, cure_team) and
## each species' knack (Knacks, data/knacks.json). A move can change the weather for a few turns (`weather_turns`
## counts down at the end of each turn, then the battle goes back to `base_weather`, the zone's own).

const PLAYER := 0
const FOE := 1
const SPREAD_MULT := 0.75
const FLAIL := {"id": "flail", "name": "Flail", "type": "", "category": "physical", "power": 40, "accuracy": 100, "pp": 1, "priority": 0, "effect": {"id": "none"}}
const SELF_HIT := {"id": "self_hit", "name": "Muddled", "type": "", "category": "physical", "power": 40, "accuracy": 100, "pp": 1, "priority": 0, "effect": {"id": "none"}}

var parties := [[], []]
var active := [[0], [0]]  # per side: the party index at each field position (-1: nobody there)
var double := false
var kind := "wild"
var weather := "clear"
var base_weather := "clear"  # the zone's weather: what a called-up weather fades back to
var weather_turns := 0  # turns left on a called-up weather (0: it is the zone's own)
var knacks_on := true  # opts.knacks = false switches knacks off (older tests that pin exact numbers)
var time := "day"
var chart: TypeChart
var move_db: MoveDB
var item_db: ItemDB  # optional: without it item actions do nothing
var rng: Rng
var over := false
var winner := -1
var caught: Creature = null
var run_attempts := 0
var _pending: Array = []  # events raised before the first turn (a battle that starts already decided)
var _fought := {}  # foe party index -> {player party index: true} for every creature that faced it on the field
var _fielded := {}  # player party indices that have been out on the field (they share a win's friendship)
var _actor := -1  # the side whose action is being played out (-1 between actions)
var _once := {}  # Creature -> {"horseshoe"/"hang_on"/"entered"/"knack": true}: once-a-battle effects
var _guarded := {}  # Creature -> true: protected this turn
var _guarded_last := {}  # the same for last turn (protecting twice running fails)
var _acted := {}  # Creature -> true: has taken its action this turn (a flinch only lands before that)
var _flinched := {}  # Creature -> true: loses its move this turn
## Events from before the first turn (charms that act as the battle starts). The flow plays them after the intro.
var opening: Array = []
## Snare multiplier from a lucky dish (Meals); the flow sets it as a wild battle starts.
var meal_catch := 1.0

func _init(player_party: Array, foe_party: Array, opts: Dictionary) -> void:
	parties = [player_party, foe_party]
	chart = opts.chart
	move_db = opts.move_db
	item_db = opts.get("item_db")
	kind = opts.get("kind", "wild")
	weather = opts.get("weather", "clear")
	base_weather = weather
	knacks_on = bool(opts.get("knacks", true))
	time = opts.get("time", "day")
	double = bool(opts.get("double", false))
	rng = opts.get("rng", Rng.new(opts.get("seed", 0)))
	for side in [PLAYER, FOE]:
		for c in parties[side]:
			c.reset_stages()
		if double:
			var lead := []
			for i in parties[side].size():
				if lead.size() < 2 and not parties[side][i].is_fainted():
					lead.append(i)
			while lead.size() < 2:
				lead.append(-1)
			active[side] = lead
		else:
			active[side] = [maxi(0, _first_able(side))]
	_note_fighters()
	for side in [PLAYER, FOE]:
		for pos in positions():
			_entered(side, pos, opening)
	_check_end(_pending)

## Field positions per side: 2 in a double battle, else 1.
func positions() -> int:
	return 2 if double else 1

## The creature at position 0 (in singles, the one creature fighting).
func current(side: int) -> Creature:
	return current_at(side, 0)

## The creature at a field position, fainted or not; null when the position is empty.
func current_at(side: int, pos: int) -> Creature:
	var party: Array = parties[side]
	var row: Array = active[side]
	if pos < 0 or pos >= row.size():
		return null
	var i: int = row[pos]
	return party[i] if i >= 0 and i < party.size() else null

## Between turns: did this creature protect itself in the turn just played? (A second protect would fail.)
func guarded_last_turn(c: Creature) -> bool:
	return _guarded.has(c)

## The creatures still standing on the field for a side, in position order.
func actives(side: int) -> Array:
	var out := []
	for pos in positions():
		var c := current_at(side, pos)
		if c != null and not c.is_fainted():
			out.append(c)
	return out

## True when some field position on this side must be refilled before the next turn.
func needs_switch(side: int) -> bool:
	for pos in positions():
		if needs_switch_at(side, pos):
			return true
	return false

## In singles: the creature fainted. In doubles: the position is down (or empty) and a reserve can fill it.
func needs_switch_at(side: int, pos: int) -> bool:
	if over:
		return false
	var c := current_at(side, pos)
	if not double:
		return c != null and c.is_fainted()
	if c != null and not c.is_fainted():
		return false
	return _reserve(side) >= 0

## Singles: take_turn(action, action). Doubles: take_turn([action per position], [action per position]).
func take_turn(player_action: Variant, foe_action: Variant) -> Array:
	var ev := _pending
	_pending = []
	if over:
		return ev
	for side in [PLAYER, FOE]:
		if needs_switch(side):
			return [{"type": "invalid", "side": side, "reason": "needs_switch"}]
	_guarded_last = _guarded
	_guarded = {}
	_acted = {}
	_flinched = {}
	for entry in _turn_order([_as_list(player_action), _as_list(foe_action)]):
		if over:
			break
		var side: int = entry.side
		var pos: int = entry.pos
		var me := current_at(side, pos)
		if me == null or me.is_fainted():
			continue
		var a: Dictionary = entry.action
		_acted[me] = true
		_actor = side
		if a.type == "move" and _flinched.has(me):
			ev.append(_at({"type": "cant_act", "side": side, "reason": "flinched"}, pos))
			continue
		match a.type:
			"switch":
				_do_switch(side, int(a.index), ev, pos)
			"item":
				_do_item(side, str(a.get("item", "")), int(a.get("target", 0)), ev)
			"run":
				if side != PLAYER:
					continue
				if double:
					ev.append({"type": "invalid", "side": side, "pos": pos, "reason": "no_run_in_doubles"})
				else:
					_do_run(side, ev)
			"catch":
				if side != PLAYER:
					continue
				if double:
					ev.append({"type": "invalid", "side": side, "pos": pos, "reason": "no_catch_in_doubles"})
				else:
					_do_catch(str(a.get("snare", "wicker")), ev)
			"move":
				_do_move(side, pos, a, ev)
		_check_end(ev)
	_actor = -1
	if not over:
		_end_of_turn(ev)
	return ev

## Bring in a replacement after a faint, between turns. In doubles `pos` picks the position to fill
## (default: the first one that needs it). Returns [{"type": "invalid", ...}] when the index cannot be sent out.
func force_switch(side: int, index: int, pos := -1) -> Array:
	if pos < 0:
		pos = 0
		for p in positions():
			if needs_switch_at(side, p):
				pos = p
				break
	var ev := []
	_do_switch(side, index, ev, pos)
	if ev.is_empty():
		ev.append({"type": "invalid", "side": side, "reason": "bad_switch"})
	return ev

func _as_list(actions: Variant) -> Array:
	if actions is Array:
		return actions
	return [actions] if actions is Dictionary else []

## Who acts in what order: [{"side", "pos", "action"}].
func _turn_order(actions: Array) -> Array:
	if not double:
		var single: Array = [actions[PLAYER][0], actions[FOE][0]]
		return _order(single).map(func(side): return {"side": side, "pos": 0, "action": single[side]})
	var entries := []
	for side in [PLAYER, FOE]:
		var list: Array = actions[side]
		for pos in positions():
			var c := current_at(side, pos)
			if c == null or c.is_fainted() or pos >= list.size() or not (list[pos] is Dictionary) or list[pos].is_empty():
				continue
			var a: Dictionary = list[pos]
			var prio := 10 if a.type != "move" else int(_peek_move(c, int(a.get("slot", 0))).get("priority", 0))
			entries.append({"side": side, "pos": pos, "action": a, "prio": prio, "speed": _speed_of(c), "tie": rng.roll()})
	entries.sort_custom(func(x, y):
		if x.prio != y.prio:
			return x.prio > y.prio
		if x.action.type != "move":  # switches, items: player first, then by position
			return x.side * 2 + x.pos < y.side * 2 + y.pos
		if x.speed != y.speed:
			return x.speed > y.speed
		return x.tie < y.tie)
	return entries

func _order(actions: Array) -> Array:
	var keys := []
	for side in [PLAYER, FOE]:
		var a: Dictionary = actions[side]
		var prio := 10 if a.type != "move" else _priority(side, int(a.slot))
		keys.append([prio, _speed(side)])
	var first := 0
	if keys[0][0] != keys[1][0]:
		first = PLAYER if keys[0][0] > keys[1][0] else FOE
	elif actions[0].type != "move":
		first = PLAYER
	elif keys[0][1] != keys[1][1]:
		first = PLAYER if keys[0][1] > keys[1][1] else FOE
	else:
		first = rng.roll_int(0, 1)
	return [first, 1 - first]

func _priority(side: int, slot: int) -> int:
	return int(_peek_move(current(side), slot).get("priority", 0))

func _speed(side: int) -> float:
	return _speed_of(current(side))

func _speed_of(c: Creature) -> float:
	var s := c.battle_stat("spd") * StatusFX.speed_mult(c)
	return s * Knacks.speed_mult(c, weather) if knacks_on else s

func _peek_move(c: Creature, slot: int) -> Dictionary:
	if slot < 0 or slot >= c.moves.size() or int(c.moves[slot].pp) <= 0:
		return FLAIL
	var move := move_db.get_move(c.moves[slot].id)
	return move if not move.is_empty() else FLAIL  # a save can outlive a renamed move

## Adds the field position to an event in doubles; singles events keep their original shape.
func _at(e: Dictionary, pos: int) -> Dictionary:
	if double:
		e["pos"] = pos
	return e

func _alive_at(side: int, pos: int) -> bool:
	var c := current_at(side, pos)
	return c != null and not c.is_fainted()

## The [side, pos] pairs a move lands on. Empty when there is nobody left to hit.
func _targets(side: int, pos: int, move: Dictionary, a: Dictionary) -> Array:
	var foe := 1 - side
	if not double:
		return [[foe, 0]] if _alive_at(foe, 0) else []
	var out := []
	if str(move.get("target", "")) == "all_foes":
		for p in positions():
			if _alive_at(foe, p):
				out.append([foe, p])
		return out
	var want: Variant = a.get("target", 0)
	if want is String and want == "ally":
		return [[side, 1 - pos]] if _alive_at(side, 1 - pos) else []
	var tp := clampi(int(want), 0, 1)
	for p in [tp, 1 - tp]:  # the chosen foe, or the other one if it has already gone down
		if _alive_at(foe, p):
			return [[foe, p]]
	return []

func _do_move(side: int, pos: int, a: Dictionary, ev: Array) -> void:
	var user := current_at(side, pos)
	var slot := int(a.get("slot", 0))
	var targets := _targets(side, pos, _peek_move(user, slot), a)
	if targets.is_empty():
		return
	var check := StatusFX.before_move(user, rng)
	if check.cured_status != "":
		ev.append(_at({"type": "status_cured", "side": side, "status": check.cured_status}, pos))
	if not check.can_act:
		if check.self_hit:
			var hurt: int = DamageCalc.compute(user, user, SELF_HIT, chart, "clear", rng, 0.0).damage
			user.take_damage(hurt)
			ev.append(_at({"type": "self_hit", "side": side, "amount": hurt, "hp": user.hp}, pos))
			if user.is_fainted():
				_faint(side, pos, ev)
		else:
			ev.append(_at({"type": "cant_act", "side": side, "reason": check.reason}, pos))
		return
	var move := _peek_move(user, slot)
	if move != FLAIL:
		user.moves[slot].pp -= 1
	var mv := _at({"type": "move", "side": side, "user": user.display_name(), "move": move.id}, pos)
	if double:
		mv["target_side"] = targets[0][0]
		mv["target_pos"] = targets[0][1]
		mv["spread"] = targets.size() > 1
	ev.append(mv)
	var fx: Dictionary = move.get("effect", {"id": "none"})
	if move.category == "status" and str(fx.id) in MoveFX.SELF_EFFECTS:
		_self_effect(side, pos, user, move, ev)
		return
	var mult := SPREAD_MULT if targets.size() > 1 else 1.0
	var landed := false
	for k in targets.size():
		var t_side: int = targets[k][0]
		var t_pos: int = targets[k][1]
		var target := current_at(t_side, t_pos)
		if target.is_fainted():
			continue
		if t_side != side and _guarded.has(target):
			ev.append(_at({"type": "protected", "side": t_side}, t_pos))
			continue
		if not _hits(user, move, target):
			var miss := _at({"type": "miss", "side": side}, pos)
			if double:
				miss["target_side"] = t_side
				miss["target_pos"] = t_pos
			ev.append(miss)
			continue
		if move.category != "status":
			if knacks_on and Knacks.immune(target, move):
				ev.append(_knack(t_side, t_pos, target, "immune"))
				continue
			var dealt := _strike(side, pos, user, t_side, t_pos, target, move, mult, ev)
			if dealt < 0:
				continue
			landed = true
			_after_hit(side, pos, user, fx, dealt, ev)
			if user.is_fainted():
				break
		_apply_effect(side, pos, move, t_side, t_pos, k == 0, ev)
	if landed and str(fx.id) == "set_weather" and not user.is_fainted():
		_set_weather(side, pos, user, str(fx.weather), ev, false)

## One damaging move landing on one target: every hit of it (multi_hit strikes several times). Returns the total
## damage dealt, or -1 when the target's types shrug it off entirely.
func _strike(side: int, pos: int, user: Creature, t_side: int, t_pos: int, target: Creature, move: Dictionary, mult: float, ev: Array) -> int:
	var fx: Dictionary = move.get("effect", {"id": "none"})
	var hits := MoveFX.roll_hits(fx, rng) if fx.id == "multi_hit" else 1
	var total := 0
	var landed := 0
	for h in hits:
		if target.is_fainted() or user.is_fainted():
			break
		var crit := DamageCalc.crit_percent(DamageCalc.crit_stage(user, move)) * Weather.crit_mult(weather, side) * (Bond.crit_mult(user) if side == PLAYER else 1.0)
		var km := 1.0
		if knacks_on:
			crit *= Knacks.crit_mult(user)
			km = Knacks.attack_mult(user, target, move, self) * Knacks.defend_mult(target, move, chart.effectiveness(str(move.type), target.types()))
		var res := DamageCalc.compute(user, target, move, chart, weather, rng, crit, mult * km)
		if res.effectiveness == 0.0:
			ev.append(_at({"type": "no_effect", "side": t_side}, t_pos))
			return -1
		var amount: int = res.damage
		var saved := ""
		if amount >= target.hp and target.hp > 1:
			saved = _hangs_on(t_side, target)
			if saved != "":
				amount = target.hp - 1
		var dealt := target.take_damage(amount)
		total += dealt
		landed += 1
		ev.append(_at({"type": "damage", "side": t_side, "amount": dealt, "hp": target.hp, "effectiveness": res.effectiveness, "crit": res.crit}, t_pos))
		if h == 0:
			if Charms.outgoing_mult(user, str(move.type)) != 1.0:
				ev.append(_charm(side, pos, user))
			if Charms.incoming_mult(target, str(move.type)) != 1.0:
				ev.append(_charm(t_side, t_pos, target))
		if saved == "charm":
			ev.append(_charm(t_side, t_pos, target))
		elif saved == "bond":
			ev.append(_at({"type": "bond", "side": t_side, "perk": "hang_on", "text": Bond.message("hang_on", "{name}")}, t_pos))
		elif saved == "knack":
			ev.append(_knack(t_side, t_pos, target, "endure"))
		if target.is_fainted():
			_faint(t_side, t_pos, ev)
			_after_ko(side, pos, user, ev)
		elif dealt > 0:
			_thorns(side, pos, user, t_side, t_pos, target, move, ev)
			_prickly(side, pos, user, t_side, t_pos, target, move, ev)
	if fx.id == "multi_hit":
		ev.append(_at({"type": "hits", "side": side, "count": landed}, pos))
	return total

## Drain and recoil, from the damage one target took.
func _after_hit(side: int, pos: int, user: Creature, fx: Dictionary, dealt: int, ev: Array) -> void:
	if dealt <= 0 or user.is_fainted():
		return
	match str(fx.id):
		"drain":
			var frac := float(fx.get("frac", 50)) * (Knacks.heal_mult(user) if knacks_on else 1.0)
			var back := user.heal(maxi(1, int(dealt * frac / 100.0)))
			if back > 0:
				ev.append(_at({"type": "heal", "side": side, "amount": back, "hp": user.hp, "reason": "drain"}, pos))
		"recoil":
			if knacks_on and Knacks.has_flag(user, "no_recoil"):
				ev.append(_knack(side, pos, user, "recoil"))
				return
			var hurt := user.take_damage(maxi(1, int(dealt * float(fx.get("frac", 25)) / 100.0)))
			ev.append(_at({"type": "recoil", "side": side, "amount": hurt, "hp": user.hp}, pos))
			if user.is_fainted():
				_faint(side, pos, ev)

## Status moves that act on the user or its side: heal_self, protect, set_weather, cure_team.
func _self_effect(side: int, pos: int, user: Creature, move: Dictionary, ev: Array) -> void:
	var fx: Dictionary = move.effect
	match str(fx.id):
		"heal_self":
			var frac := MoveFX.heal_frac(move, weather) * (Knacks.heal_mult(user) if knacks_on else 1.0)
			var back := user.heal(maxi(1, int(user.max_hp() * minf(frac, 100.0) / 100.0)))
			if back <= 0:
				ev.append(_at({"type": "fail", "side": side}, pos))
			else:
				ev.append(_at({"type": "heal", "side": side, "amount": back, "hp": user.hp, "reason": "heal_self"}, pos))
		"protect":
			if _guarded_last.has(user):
				ev.append(_at({"type": "fail", "side": side}, pos))
			else:
				_guarded[user] = true
				ev.append(_at({"type": "protect", "side": side}, pos))
		"set_weather":
			_set_weather(side, pos, user, str(fx.weather), ev, true, int(fx.get("turns", MoveFX.DEFAULT_TURNS)))
		"cure_team":
			var cured := 0
			for c in parties[side]:
				if c.status != "" and not c.is_fainted():
					c.status = ""
					c.status_turns = 0
					cured += 1
			if cured == 0:
				ev.append(_at({"type": "fail", "side": side}, pos))
			else:
				ev.append(_at({"type": "cure_team", "side": side, "count": cured}, pos))

## Calls up a weather for a few turns (a Weather Eye knack makes it last longer). The same weather again fails.
func _set_weather(side: int, pos: int, by: Creature, w: String, ev: Array, say_fail := true, turns := MoveFX.DEFAULT_TURNS) -> void:
	if weather == w:
		if say_fail:
			ev.append(_at({"type": "fail", "side": side}, pos))
		return
	if knacks_on and by != null:
		turns = maxi(turns, Knacks.weather_turns(by))
	weather = w
	weather_turns = turns
	ev.append(_at({"type": "weather", "side": side, "weather": w, "turns": turns}, pos))

func _hits(user: Creature, move: Dictionary, target: Creature = null) -> bool:
	var fx: Dictionary = move.get("effect", {})
	if move.category == "status" and fx.get("target") == "self":
		return true
	if MoveFX.sure_in(move, weather):
		return true
	var acc := float(move.accuracy) * user.stage_mult("acc")
	if not (knacks_on and Knacks.has_flag(user, "keen")):
		acc *= Weather.accuracy_mod(weather)
	if knacks_on and target != null:
		acc *= Knacks.evade_mult(target, weather)
	return rng.chance(acc)

## A move's side effect, on its target or (for "self" effects, once per move) on the user.
func _apply_effect(side: int, pos: int, move: Dictionary, t_side: int, t_pos: int, first: bool, ev: Array) -> void:
	var fx: Dictionary = move.get("effect", {"id": "none"})
	if fx.id not in ["stat", "status", "flinch"]:
		return
	var on_self: bool = fx.get("target", "foe") == "self"
	if on_self and not first:
		return
	var to_side := side if on_self else t_side
	var to_pos := pos if on_self else t_pos
	var who := current_at(to_side, to_pos)
	if who.is_fainted() or not rng.chance(float(fx.get("chance", 100))):
		return
	match fx.id:
		"stat":
			var stages := int(fx.stages)
			if knacks_on and not on_self and stages < 0 and Knacks.blocks_drop(who, str(fx.stat)):
				ev.append(_knack(to_side, to_pos, who, "drop"))
				return
			var applied := who.change_stage(fx.stat, stages)
			ev.append(_at({"type": "stat", "side": to_side, "stat": fx.stat, "delta": applied}, to_pos))
		"status":
			if who.status == "" and knacks_on and Knacks.blocks_status(who, str(fx.status)):
				ev.append(_knack(to_side, to_pos, who, "status"))
				return
			if who.status == "" and _wards_off(to_side, to_pos, who, ev):
				return
			if StatusFX.inflict(who, fx.status, rng):
				ev.append(_at({"type": "status", "side": to_side, "status": fx.status}, to_pos))
		"flinch":
			if _acted.has(who):
				return  # it has already moved this turn
			if knacks_on and Knacks.has_flag(who, "no_flinch"):
				ev.append(_knack(to_side, to_pos, who, "flinch"))
				return
			_flinched[who] = true

func _do_switch(side: int, index: int, ev: Array, pos := 0) -> void:
	var party: Array = parties[side]
	if index < 0 or index >= party.size() or index in active[side] or party[index].is_fainted():
		return
	var out := current_at(side, pos)
	if out != null:
		out.reset_stages()
		if knacks_on and not out.is_fainted():
			var back := out.heal(Knacks.switch_heal(out))
			if back > 0:
				ev.append(_knack(side, pos, out, "switch", {"hp": out.hp, "amount": back}))
	active[side][pos] = index
	_note_fighters()
	# hp as it comes in: the UI plays the turn back after it is all worked out, so the creature's own hp is already the end of it
	ev.append(_at({"type": "switch", "side": side, "index": index, "user": party[index].display_name(), "hp": party[index].hp}, pos))
	_entered(side, pos, ev)

func _do_item(side: int, item_id: String, target: int, ev: Array) -> void:
	if side == FOE:
		_foe_tea(item_id, target, ev)
		return
	var text := "Nothing happened."
	var party: Array = parties[side]
	if side == PLAYER and item_db != null and target >= 0 and target < party.size():
		var item := item_db.get_item(item_id)
		var on_field_fainted: bool = target in active[side] and party[target].is_fainted()
		if str(item.get("kind", "")) == "revive" and on_field_fainted:
			# a fainted creature still holding its spot (doubles, no reserve) must leave the field first
			text = "It can't be revived while it's still on the field."
		elif bool(item.get("battle", false)) and item.get("kind", "") in ["heal", "cure", "revive", "pp"]:
			text = ItemEffects.apply(item, party[target]).text
	ev.append({"type": "item", "side": side, "item": item_id, "target": target, "text": text})

## A keeper's one tea (TrainerParty.TEA on the creature, set from its trainer data): heals it once and is gone.
## Played as a charm-style event (side, item, hp, text with "{name}") so the HP bar rises with no "You used" line.
## A foe can only pour the tea it was given; anything else does nothing.
func _foe_tea(item_id: String, target: int, ev: Array) -> void:
	var party: Array = parties[FOE]
	if item_db == null or target < 0 or target >= party.size():
		return
	var c: Creature = party[target]
	if c.is_fainted() or not c.has_meta(TrainerParty.TEA) or str(c.get_meta(TrainerParty.TEA)) != item_id:
		return
	c.remove_meta(TrainerParty.TEA)
	var item := item_db.get_item(item_id)
	var got := c.heal(int(item.get("amount", 0)))
	var pos := maxi(0, active[FOE].find(target))
	ev.append(_at({"type": "charm", "side": FOE, "item": item_id, "hp": c.hp,
		"text": "{name} stops for a quick %s and gets %d HP back." % [str(item.get("name", item_id)), got]}, pos))

func _do_run(side: int, ev: Array) -> void:
	if kind != "wild" or side != PLAYER:
		ev.append({"type": "run", "side": side, "success": false})
		return
	run_attempts += 1
	var ok := _speed(PLAYER) >= _speed(FOE) or rng.chance(40.0 + 10.0 * run_attempts)
	ev.append({"type": "run", "side": side, "success": ok})
	if ok:
		_finish(-1, ev)

func _do_catch(snare: String, ev: Array) -> void:
	if kind != "wild":
		ev.append({"type": "catch", "success": false, "reason": "trainer"})
		return
	var foe := current(FOE)
	var bonus := catch_bonus()
	if bonus != 1.0:
		var lead: Creature = parties[PLAYER][_first_able(PLAYER)]
		ev.append({"type": "charm", "side": PLAYER, "item": lead.held, "name": lead.display_name(), "text": Charms.message(lead, "{name}")})
	bonus *= meal_catch
	var ok := Catching.attempt(foe, snare, time, rng, bonus)
	ev.append({"type": "catch", "success": ok})
	if ok:
		caught = foe
		_finish(-1, ev)

## A faint names the party `index` and, for a foe, the player's creatures that faced it at any point and are still
## standing (`witnesses`): they split the XP.
func _faint(side: int, pos: int, ev: Array) -> void:
	if side == PLAYER:
		Bond.add(current_at(side, pos), Bond.FAINT)
	var e := _at({"type": "faint", "side": side, "user": current_at(side, pos).display_name()}, pos)
	e["index"] = active[side][pos]
	if side == FOE:
		_note_fighters()
		var seen := []
		for i in _fought.get(active[side][pos], {}):
			if not parties[PLAYER][i].is_fainted():
				seen.append(i)
		seen.sort()
		e["witnesses"] = seen
	ev.append(e)

## Every player creature on the field has now faced every foe on the field: they share that foe's XP.
func _note_fighters() -> void:
	for f in active[FOE]:
		if f < 0:
			continue
		var seen: Dictionary = _fought.get(f, {})
		for p in active[PLAYER]:
			if p >= 0 and not parties[PLAYER][p].is_fainted():
				seen[p] = true
		_fought[f] = seen
	for p in active[PLAYER]:
		if p >= 0:
			_fielded[p] = true

func _end_of_turn(ev: Array) -> void:
	for side in [PLAYER, FOE]:
		for pos in positions():
			var c := current_at(side, pos)
			if c == null or c.is_fainted():
				continue
			var dmg := StatusFX.end_of_turn_damage(c)
			if dmg > 0:
				c.take_damage(dmg)
				ev.append(_at({"type": "status_damage", "side": side, "status": c.status, "amount": dmg, "hp": c.hp}, pos))
				if c.is_fainted():
					_faint(side, pos, ev)
					continue
			var back := Charms.regen(c)
			if back > 0:
				c.heal(back)
				var e := _charm(side, pos, c)
				e["hp"] = c.hp
				e["amount"] = back
				ev.append(e)
			if knacks_on:
				_knack_end_of_turn(side, pos, c, ev)
	if weather_turns > 0:
		weather_turns -= 1
		if weather_turns == 0:
			var was := weather
			weather = base_weather
			ev.append({"type": "weather_end", "weather": weather, "was": was})
	_check_end(ev)

## A knack's end-of-turn turn: weather or steady healing, shaking off a status, a stat creeping up.
func _knack_end_of_turn(side: int, pos: int, c: Creature, ev: Array) -> void:
	var heal := Knacks.turn_heal(c, weather)
	if heal > 0 and c.hp < c.max_hp():
		var back := c.heal(heal)
		ev.append(_knack(side, pos, c, "heal", {"hp": c.hp, "amount": back}))
	var shake := Knacks.int_field(c, "shake")
	if c.status != "" and shake > 0 and rng.chance(float(shake)):
		var old := c.status
		c.status = ""
		c.status_turns = 0
		ev.append(_knack(side, pos, c, "shake"))
		ev.append(_at({"type": "status_cured", "side": side, "status": old}, pos))
	var st := Knacks.end_stage(c)
	if not st.is_empty() and c.stages.get(st.stat, 0) < 6:
		ev.append(_knack(side, pos, c, "end"))
		ev.append(_at({"type": "stat", "side": side, "stat": st.stat, "delta": c.change_stage(st.stat, int(st.stages))}, pos))

func _check_end(ev: Array) -> void:
	if over:
		return
	if _actor >= 0 and _first_able(PLAYER) < 0 and _first_able(FOE) < 0:
		_finish(_actor, ev)  # both out at once (recoil, a Thistle Brooch): the winning blow was the actor's
	elif _first_able(PLAYER) < 0:
		_finish(FOE, ev)
	elif _first_able(FOE) < 0:
		_finish(PLAYER, ev)

func _finish(who: int, ev: Array) -> void:
	over = true
	winner = who
	if who == PLAYER:  # everyone who was out there for the win grows a little closer
		for i in _fielded:
			if not parties[PLAYER][i].is_fainted():
				Bond.add(parties[PLAYER][i], Bond.WIN)
	ev.append({"type": "end", "winner": who})

func _first_able(side: int) -> int:
	var party: Array = parties[side]
	for i in party.size():
		if not party[i].is_fainted():
			return i
	return -1

## The first creature that can fight and is not already on the field, or -1.
func _reserve(side: int) -> int:
	var party: Array = parties[side]
	for i in party.size():
		if not party[i].is_fainted() and i not in active[side]:
			return i
	return -1

# --- charms and friendship ----------------------------------------------------------------

## Snare bonus from the player's lead (the first creature that can fight): a Four-Leaf Clover.
func catch_bonus() -> float:
	var i := _first_able(PLAYER)
	return Charms.catch_mult(parties[PLAYER][i]) if i >= 0 else 1.0

## A charm event: {"type": "charm", "side", "item", "text"}. The text keeps "{name}" (the holder) and "{other}" for
## the event player to fill in, so a wild holder reads "the wild ...".
func _charm(side: int, pos: int, c: Creature) -> Dictionary:
	return _at({"type": "charm", "side": side, "item": c.held, "text": Charms.message(c, "{name}", "{other}")}, pos)

## Who saves a creature from a knockout, once a battle each: "charm" (a horseshoe), "bond" (220+ friendship, the
## player's own only) or "".
func _hangs_on(side: int, c: Creature) -> String:
	var used: Dictionary = _once.get(c, {})
	_once[c] = used
	if knacks_on and Knacks.has_flag(c, "endure_full") and c.hp == c.max_hp():
		return "knack"
	if knacks_on and Knacks.has_flag(c, "endure_once") and not used.has("knack"):
		used["knack"] = true
		return "knack"
	if Charms.endures(c) and not used.has("horseshoe"):
		used["horseshoe"] = true
		return "charm"
	if side == PLAYER and Bond.has_perk(c, "hang_on") and not used.has("hang_on"):
		used["hang_on"] = true
		return "bond"
	return ""

## A status about to land: a Brigid's Cross blocks it, or a close friend may shrug it off. True if it was stopped.
func _wards_off(side: int, pos: int, c: Creature, ev: Array) -> bool:
	if Charms.blocks_status(c):
		ev.append(_charm(side, pos, c))
		return true
	if side == PLAYER and Bond.shrugs(c, rng):
		ev.append(_at({"type": "bond", "side": side, "perk": "shrug", "text": Bond.message("shrug", "{name}")}, pos))
		return true
	return false

## A Thistle Brooch pricks whoever just hit its holder with a physical move.
func _thorns(side: int, pos: int, user: Creature, t_side: int, t_pos: int, target: Creature, move: Dictionary, ev: Array) -> void:
	var hurt := Charms.thorns_damage(target, user, move)
	if hurt <= 0 or user.is_fainted():
		return
	user.take_damage(hurt)
	var e := _charm(t_side, t_pos, target)
	e["other_side"] = side
	e["other_pos"] = pos
	e["amount"] = hurt
	e["hp"] = user.hp
	ev.append(e)
	if user.is_fainted():
		_faint(side, pos, ev)

## Something new on the field: its knack may act (every time it comes out), and an Oak Acorn acts the first time its
## holder comes out in a battle.
func _entered(side: int, pos: int, ev: Array) -> void:
	var c := current_at(side, pos)
	if c == null or c.is_fainted():
		return
	if knacks_on:
		_knack_entry(side, pos, c, ev)
	var used: Dictionary = _once.get(c, {})
	_once[c] = used
	if used.has("entered"):
		return
	used["entered"] = true
	var st := Charms.start_stage(c)
	if st.is_empty():
		return
	var e := _charm(side, pos, c)
	e["stat"] = st.stat
	e["delta"] = c.change_stage(st.stat, int(st.stages))
	ev.append(e)

# --- knacks -------------------------------------------------------------------------------

## A knack event: {"type": "knack", "side", "knack", "name", "text"} (+ "pos" in doubles, + any extra such as "hp").
## The text keeps "{name}" for the event player, like a charm's; "name" is the holder's, as it may be switching out.
func _knack(side: int, pos: int, c: Creature, trigger: String, extra := {}) -> Dictionary:
	var e := _at({"type": "knack", "side": side, "knack": Knacks.id_of(c), "name": c.display_name(), "text": Knacks.message(c, trigger)}, pos)
	e.merge(extra, true)
	return e

## On entry: a weather knack calls its weather, a stat knack nudges the holder or both foes.
func _knack_entry(side: int, pos: int, c: Creature, ev: Array) -> void:
	var w := Knacks.entry_weather(c)
	if w != "" and w != weather:
		ev.append(_knack(side, pos, c, "entry"))
		_set_weather(side, pos, c, w, ev, false)
	var stages := Knacks.entry_stages(c, weather, time)
	if stages.is_empty():
		return
	ev.append(_knack(side, pos, c, "entry"))
	for st in stages:
		if str(st.get("to", "self")) == "self":
			ev.append(_at({"type": "stat", "side": side, "stat": st.stat, "delta": c.change_stage(st.stat, int(st.stages))}, pos))
			continue
		for p in positions():
			var foe := current_at(1 - side, p)
			if foe == null or foe.is_fainted():
				continue
			if int(st.stages) < 0 and Knacks.blocks_drop(foe, str(st.stat)):
				ev.append(_knack(1 - side, p, foe, "drop"))
				continue
			ev.append(_at({"type": "stat", "side": 1 - side, "stat": st.stat, "delta": foe.change_stage(st.stat, int(st.stages))}, p))

## After knocking a foe out: a knack like Cocky raises a stat.
func _after_ko(side: int, pos: int, user: Creature, ev: Array) -> void:
	if not knacks_on or user.is_fainted():
		return
	var st := Knacks.after_ko(user)
	if st.is_empty():
		return
	ev.append(_knack(side, pos, user, "ko"))
	ev.append(_at({"type": "stat", "side": side, "stat": st.stat, "delta": user.change_stage(st.stat, int(st.stages))}, pos))

## A Prickly knack hurts whoever just hit its holder with a physical move.
func _prickly(side: int, pos: int, user: Creature, t_side: int, t_pos: int, target: Creature, move: Dictionary, ev: Array) -> void:
	if not knacks_on or user.is_fainted() or str(move.get("category", "")) != "physical":
		return
	var n := Knacks.int_field(target, "contact_hurt")
	if n <= 0:
		return
	var hurt := user.take_damage(maxi(1, user.max_hp() / n))
	ev.append(_knack(t_side, t_pos, target, "contact", {"other_side": side, "other_pos": pos, "amount": hurt, "hp": user.hp}))
	if user.is_fainted():
		_faint(side, pos, ev)
