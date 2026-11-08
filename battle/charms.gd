class_name Charms
extends RefCounted
## Charms: held items (Creature.held). What each one does lives in data/items/charms.json under "charm":
##   resist      {type, mult}   that type's damage taken x mult
##   boost       {type, mult}   the holder's moves of that type x mult
##   endure      once a battle, a knockout hit leaves it on 1 HP (Battle keeps the once)
##   catch       {mult}         snares x mult while the holder leads the team
##   no_status                  can't be given a status
##   thorns      {frac}         a physical hit costs the attacker 1/frac of its max HP
##   regen       {frac}         1/frac of max HP back at the end of every turn
##   start_stage {stat, stages} the first time it comes out in a battle
##   crit        {stages}       the holder's hits land critical hits a stage more often
## Both sides' charms work (wild creatures can carry one). Pure: no autoloads.

const PATH := "res://data/items/charms.json"
const EFFECTS := ["resist", "boost", "endure", "catch", "no_status", "thorns", "regen", "start_stage", "crit"]
const WILD_CHANCE := 0.02

static var _table: Dictionary = {}

## id -> the charm's item entry.
static func table() -> Dictionary:
	if _table.is_empty():
		# charms.json first, then any regional item file (data/items/<region>.json) that carries a local charm
		var paths: Array = [PATH]
		for p in JsonUtil.list_json(PATH.get_base_dir()):
			if p != PATH:
				paths.append(p)
		for path in paths:
			var arr = JsonUtil.read(path)
			if arr is Array:
				for it in arr:
					if it is Dictionary and str(it.get("kind", "")) == "charm" and not _table.has(str(it.id)):
						_table[str(it.id)] = it
	return _table

static func is_charm(id: String) -> bool:
	return table().has(id)

static func item(id: String) -> Dictionary:
	return table().get(id, {})

static func name_of(id: String) -> String:
	return str(item(id).get("name", id.capitalize()))

## The held charm's effect data, or {} when it holds nothing (or something that isn't a charm).
static func effect(c: Creature) -> Dictionary:
	if c == null or c.held == "":
		return {}
	return item(c.held).get("charm", {})

static func _is(c: Creature, effect_id: String) -> bool:
	return str(effect(c).get("effect", "")) == effect_id

## The battle log line when the holder's charm kicks in ("{name}" the holder, "{other}" the other creature).
static func message(c: Creature, name: String, other := "") -> String:
	return str(item(c.held).get("msg", "")).replace("{name}", name).replace("{other}", other)

static func incoming_mult(defender: Creature, move_type: String) -> float:
	var fx := effect(defender)
	if fx.get("effect") == "resist" and str(fx.get("type", "")) == move_type:
		return float(fx.get("mult", 1.0))
	return 1.0

static func outgoing_mult(attacker: Creature, move_type: String) -> float:
	var fx := effect(attacker)
	if fx.get("effect") == "boost" and str(fx.get("type", "")) == move_type:
		return float(fx.get("mult", 1.0))
	return 1.0

static func catch_mult(lead: Creature) -> float:
	return float(effect(lead).get("mult", 1.0)) if _is(lead, "catch") else 1.0

static func blocks_status(c: Creature) -> bool:
	return _is(c, "no_status")

static func endures(c: Creature) -> bool:
	return _is(c, "endure")

## Damage back to an attacker that hit the holder with a physical move (0 if none).
static func thorns_damage(holder: Creature, attacker: Creature, move: Dictionary) -> int:
	if not _is(holder, "thorns") or str(move.get("category", "")) != "physical":
		return 0
	return maxi(1, attacker.max_hp() / maxi(1, int(effect(holder).get("frac", 8))))

## HP back at the end of a turn (0 if none, or already full).
static func regen(c: Creature) -> int:
	if not _is(c, "regen") or c.is_fainted() or c.hp >= c.max_hp():
		return 0
	return maxi(1, c.max_hp() / maxi(1, int(effect(c).get("frac", 16))))

## {stat, stages} to apply when it first comes out, or {}.
static func start_stage(c: Creature) -> Dictionary:
	if not _is(c, "start_stage"):
		return {}
	var fx := effect(c)
	return {"stat": str(fx.get("stat", "def")), "stages": int(fx.get("stages", 1))}

## Crit stages the holder's charm adds to every damaging move (0 if none).
static func crit_stages(c: Creature) -> int:
	return maxi(0, int(effect(c).get("stages", 1))) if _is(c, "crit") else 0

## Charms a wild creature might be found carrying.
static func wild_pool() -> Array:
	var out := []
	for id in table():
		if bool(table()[id].get("wild", false)):
			out.append(id)
	out.sort()
	return out

## A wild creature rarely carries a charm (you keep it if you catch it). Returns the charm given, or "".
static func maybe_wild(c: Creature, rng: Rng) -> String:
	var pool := wild_pool()
	if pool.is_empty() or rng.roll() >= WILD_CHANCE:
		return ""
	c.held = str(pool[rng.roll_int(0, pool.size() - 1)])
	return c.held
