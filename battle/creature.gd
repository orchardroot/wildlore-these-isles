class_name Creature
extends RefCounted
## One individual creature: species data plus everything personal to it.

var species: Dictionary
var nickname := ""
var level := 1
var xp := 0
var nature := "steady"
var ivs := {}          # stat -> 0..Rules.IV_MAX
var training := {}     # stat -> 0..Rules.TRAINING_STAT_CAP
var hp := 1
var moves: Array = []  # [{"id": String, "pp": int, "max_pp": int}]
var status := ""
var status_turns := 0
var friendship := 70    # 0..255; grows with levels and walking together
var held := ""          # the charm it is holding (an item id), or ""
var stages := {}       # Rules.STAGE_STATS -> -6..6, reset on switch-out
var variant := ""      # an uncommon coat (see Coats), "" for the usual one; only a look
var genome := {}       # Good Stock makings {locus: [a, b]}, see Genetics; derived from the creature itself when absent
var sex := ""          # "m", "f" or "" (kindreds that do not breed)
var uid := 0           # 0 until it needs an identity (kinship); not yet assigned anywhere
var pedigree := {}     # {sire: node, dam: node}, a node being {uid, sire, dam}
var hybrid := ""       # the Hybrid id if it is one (data/hybrids.json), else ""
var form := ""         # a regional form (see Forms), "" for the usual one

static func create(sp: Dictionary, lvl: int, rng: Rng, move_db: MoveDB) -> Creature:
	var c := Creature.new()
	c.species = sp
	c.level = clampi(lvl, 1, Rules.MAX_LEVEL)
	c.xp = Rules.xp_for_level(sp.growth, c.level)
	for s in Rules.STATS:
		c.ivs[s] = rng.roll_int(0, Rules.IV_MAX)
		c.training[s] = 0
	c.nature = rng.pick(Rules.NATURES.keys())
	var made := Genetics.derive(c)  # what it already is, so loading it later gives the same answer
	c.genome = made.genome
	c.sex = made.sex
	for id in default_moves(sp, c.level):
		c.moves.append(c.make_move_slot(id, move_db))
	c.reset_stages()
	c.hp = c.max_hp()
	return c

## The last four distinct moves learnable at or below `lvl`, in learn order.
static func default_moves(sp: Dictionary, lvl: int) -> Array:
	var ids := []
	for entry in sp.learnset:
		if entry[0] <= lvl and entry[1] not in ids:
			ids.append(entry[1])
	return ids.slice(maxi(0, ids.size() - Rules.MAX_MOVES))

static func from_dict(d: Dictionary, dex: Dex) -> Creature:
	var c := Creature.new()
	c.species = dex.get_species(d.species)
	c.nickname = d.get("nickname", "")
	c.level = int(d.level)
	c.xp = int(d.xp)
	c.nature = d.nature
	for s in Rules.STATS:
		c.ivs[s] = int(d.ivs[s])
		c.training[s] = int(d.training[s])
	c.hp = int(d.hp)
	for m in d.moves:
		c.moves.append({"id": m.id, "pp": int(m.pp), "max_pp": int(m.max_pp)})
	c.status = d.get("status", "")
	c.status_turns = int(d.get("status_turns", 0))
	c.friendship = int(d.get("friendship", 70))
	c.held = str(d.get("held", ""))
	c.variant = str(d.get("variant", ""))
	c.genome = d.get("genome", {}).duplicate(true)
	c.sex = str(d.get("sex", ""))
	c.uid = int(d.get("uid", 0))
	c.pedigree = d.get("pedigree", {}).duplicate(true)
	c.hybrid = str(d.get("hybrid", ""))
	c.form = str(d.get("form", ""))
	if c.genome.is_empty() and not c.species.is_empty():
		var made := Genetics.derive(c)
		c.genome = made.genome
		if c.sex == "":
			c.sex = made.sex
	Sexes.ensure(c)  # a save from before sexes (or a hand-built creature) gets its own, the same every time
	c.reset_stages()
	c.hp = mini(c.hp, c.max_hp())  # base stats can change between versions; never above the (new) max
	return c

func to_dict() -> Dictionary:
	return {"species": species.id, "nickname": nickname, "level": level, "xp": xp, "nature": nature,
		"ivs": ivs.duplicate(), "training": training.duplicate(), "hp": hp,
		"moves": moves.duplicate(true), "status": status, "status_turns": status_turns, "friendship": friendship, "held": held, "variant": variant,
		"genome": genome.duplicate(true), "sex": sex, "uid": uid, "pedigree": pedigree.duplicate(true), "hybrid": hybrid, "form": form}

func make_move_slot(id: String, move_db: MoveDB) -> Dictionary:
	var pp := int(move_db.get_move(id).get("pp", 10))
	return {"id": id, "pp": pp, "max_pp": pp}

func has_move(id: String) -> bool:
	for m in moves:
		if m.id == id:
			return true
	return false

func display_name() -> String:
	return nickname if nickname != "" else species.name

func types() -> Array:
	return Forms.types_for(species, form) if form != "" else species.types

func max_hp() -> int:
	return calc_stat("hp")

func calc_stat(s: String) -> int:
	var core: int = (2 * (species.base[s] + (Forms.lean(str(species.id), form, s) if form != "" else 0)) + 2 * ivs.get(s, 0) + training.get(s, 0) / 4) * level / 100
	if s == "hp":
		return core + level + 10
	return int((core + 5) * nature_mod(s))

func nature_mod(s: String) -> float:
	var n: Array = Rules.NATURES.get(nature, [])
	if n.is_empty():
		return 1.0
	if n[0] == s:
		return 1.1
	if n[1] == s:
		return 0.9
	return 1.0

func reset_stages() -> void:
	for s in Rules.STAGE_STATS:
		stages[s] = 0

func stage_mult(s: String) -> float:
	var st: int = stages.get(s, 0)
	if s == "acc":
		return (3.0 + st) / 3.0 if st >= 0 else 3.0 / (3.0 - st)
	return (2.0 + st) / 2.0 if st >= 0 else 2.0 / (2.0 - st)

func battle_stat(s: String) -> int:
	return maxi(1, int(calc_stat(s) * stage_mult(s)))

func change_stage(s: String, delta: int) -> int:
	var old: int = stages[s]
	stages[s] = clampi(old + delta, -6, 6)
	return stages[s] - old

func is_fainted() -> bool:
	return hp <= 0

func take_damage(n: int) -> int:
	var dealt := mini(n, hp)
	hp -= dealt
	return dealt

func heal(n: int) -> int:
	var healed := mini(n, max_hp() - hp)
	hp += healed
	return healed
