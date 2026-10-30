class_name DataValidator
extends RefCounted
## Cross-checks all game data. Returns human-readable errors; an empty array means valid.

static func validate(chart: TypeChart, dex: Dex, moves: MoveDB, items: ItemDB = null) -> Array:
	var errors := chart.validate()
	for id in moves.duplicates:
		errors.append("move id '%s' defined more than once" % id)
	for id in dex.duplicates:
		errors.append("species id '%s' defined more than once" % id)
	for id in moves.ids():
		errors.append_array(_check_move(moves.get_move(id), chart))
	for id in dex.ids():
		errors.append_array(_check_species(dex.get_species(id), chart, dex, moves, items))
	if items != null:
		errors.append_array(_check_items(items, dex))
		errors.append_array(Chapbooks.problems(items, moves))
	return errors

static func _check_move(m: Dictionary, chart: TypeChart) -> Array:
	var e := []
	var id: String = m.get("id", "?")
	if str(m.get("name", "")) == "":
		e.append("move %s: missing name" % id)
	if m.get("type") not in chart.types:
		e.append("move %s: unknown type '%s'" % [id, m.get("type")])
	if m.get("category") not in Rules.CATEGORIES:
		e.append("move %s: unknown category '%s'" % [id, m.get("category")])
	if m.get("category") != "status" and int(m.power) <= 0:
		e.append("move %s: damaging move needs power > 0" % id)
	if int(m.accuracy) < 1 or int(m.accuracy) > 100:
		e.append("move %s: accuracy must be 1..100" % id)
	if int(m.pp) < 1 or int(m.pp) > 64:
		e.append("move %s: pp must be 1..64" % id)
	var fx: Dictionary = m.get("effect", {})
	if fx.get("id") not in Rules.EFFECTS:
		e.append("move %s: unknown effect '%s'" % [id, fx.get("id")])
	elif fx.id == "stat":
		if fx.get("stat") not in Rules.STAGE_STATS:
			e.append("move %s: unknown stat '%s'" % [id, fx.get("stat")])
		if int(fx.get("stages", 0)) == 0:
			e.append("move %s: stat effect needs non-zero stages" % id)
	elif fx.id == "status" and fx.get("status") not in Rules.STATUSES:
		e.append("move %s: unknown status '%s'" % [id, fx.get("status")])
	if int(fx.get("chance", 100)) < 1 or int(fx.get("chance", 100)) > 100:
		e.append("move %s: effect chance must be 1..100" % id)
	if int(m.get("priority", 0)) < -3 or int(m.get("priority", 0)) > 3:
		e.append("move %s: priority must be -3..3" % id)
	if fx.get("target", "foe") not in ["self", "foe"]:
		e.append("move %s: effect target must be self or foe" % id)
	e.append_array(MoveFX.check(m))
	return e

static func _check_species(sp: Dictionary, chart: TypeChart, dex: Dex, moves: MoveDB, items: ItemDB = null) -> Array:
	var e := []
	var id: String = sp.get("id", "?")
	if str(sp.get("name", "")) == "":
		e.append("species %s: missing name" % id)
	var types: Array = sp.get("types", [])
	if types.size() < 1 or types.size() > 2:
		e.append("species %s: needs 1 or 2 types" % id)
	for t in types:
		if t not in chart.types:
			e.append("species %s: unknown type '%s'" % [id, t])
	if types.size() == 2 and types[0] == types[1]:
		e.append("species %s: repeats a type" % id)
	for s in Rules.STATS:
		var v: int = sp.base[s]
		if v < 1 or v > 255:
			e.append("species %s: base %s must be 1..255" % [id, s])
	if sp.get("growth") not in Rules.GROWTH_RATES:
		e.append("species %s: unknown growth '%s'" % [id, sp.get("growth")])
	if sp.catch_rate < 1 or sp.catch_rate > 255:
		e.append("species %s: catch_rate must be 1..255" % id)
	if sp.has("legend") and not sp.legend is bool:
		e.append("species %s: legend must be true or false" % id)
	if sp.catch_rate <= 3 and sp.get("legend", false) != true:
		e.append("species %s: catch_rate %d is legend territory, so mark it \"legend\": true" % [id, sp.catch_rate])
	if sp.base_xp < 1:
		e.append("species %s: base_xp must be positive" % id)
	for cb in sp.get("chapbooks", []):
		if not moves.has(str(cb)):
			e.append("species %s: chapbooks move '%s' does not exist" % [id, cb])
	if sp.learnset.is_empty():
		e.append("species %s: empty learnset" % id)
	if int(sp.get("malformed_learnset", 0)) > 0:
		e.append("species %s: %d malformed learnset entries (need [level, move_id])" % [id, sp.malformed_learnset])
	for entry in sp.learnset:
		if entry[0] < 1 or entry[0] > Rules.MAX_LEVEL:
			e.append("species %s: learnset level %d out of range" % [id, entry[0]])
		if not moves.has(entry[1]):
			e.append("species %s: learnset move '%s' does not exist" % [id, entry[1]])
	var evo = sp.evolves
	if evo != null:
		var target: String = evo.get("to", "")
		if not dex.has(target):
			e.append("species %s: evolves into unknown species '%s'" % [id, target])
		elif target == id:
			e.append("species %s: evolves into itself" % id)
		if evo.has("level") and (int(evo.level) < 1 or int(evo.level) > Rules.MAX_LEVEL):
			e.append("species %s: evolution level must be 1..100" % id)
		if not evo.has("level") and not evo.has("item") and not evo.has("friendship"):
			e.append("species %s: evolution needs a level, an item or friendship" % id)
		if evo.has("season") and str(evo.season) not in ["spring", "summer", "autumn", "winter"]:
			e.append("species %s: evolution season '%s' is not a season" % [id, evo.season])
		if evo.has("zone"):
			for z in (evo.zone if evo.zone is Array else [evo.zone]):
				if not FileAccess.file_exists("res://data/zones/%s.json" % str(z)):
					e.append("species %s: evolution zone '%s' does not exist" % [id, z])
		if evo.has("flag") and str(evo.flag) == "":
			e.append("species %s: evolution flag is empty" % id)
		for key in ["item", "early_item"]:
			if evo.has(key) and items != null:
				var it := items.get_item(str(evo[key]))
				if it.is_empty():
					e.append("species %s: evolves with unknown item '%s'" % [id, evo[key]])
				elif it.kind != "evo":
					e.append("species %s: '%s' is not an evolution item" % [id, evo[key]])
	var d: Dictionary = sp.get("dex", {})
	if str(d.get("text", "")) == "" or str(d.get("fact", "")) == "":
		e.append("species %s: needs Creaturepedia text and a real-world fact" % id)
	e.append_array(_check_teaching(sp))
	return e

## The Fieldbook teaching keys (docs/design/fieldbook_teaching.md), both optional: `real` is a non-empty sentence
## with no em-dash that doesn't just repeat the fact; `names` holds only cy, ga and gd, each a non-empty string.
static func _check_teaching(sp: Dictionary) -> Array:
	var e := []
	var id: String = sp.get("id", "?")
	if sp.has("real"):
		var real = sp.real
		if not (real is String) or str(real).strip_edges() == "":
			e.append("species %s: real, if present, is a non-empty sentence" % id)
		elif EM_DASH in str(real):
			e.append("species %s: em-dash in real" % id)
		elif str(real) == str(sp.get("dex", {}).get("fact", "")):
			e.append("species %s: real repeats the fact" % id)
	if sp.has("names"):
		var names = sp.names
		if not (names is Dictionary):
			e.append("species %s: names must be a dictionary of language code to name" % id)
		else:
			for code in names:
				if str(code) not in Langs.CREATURE_NAME_CODES:
					e.append("species %s: names has unknown language '%s' (cy, ga or gd)" % [id, code])
				elif not (names[code] is String) or str(names[code]).strip_edges() == "":
					e.append("species %s: names.%s must be a non-empty string" % [id, code])
				elif EM_DASH in str(names[code]):
					e.append("species %s: em-dash in names.%s" % [id, code])
	return e

const EM_DASH := char(0x2014)  # the em-dash: the house style has none, in data or in prose

const ITEM_KINDS := ["heal", "meal", "cure", "revive", "pp", "snare", "evo", "charm", "repel", "key", "material", "fish", "produce", "wear", "chapbook", "curio"]
const EXTRA_SNARES := ["night", "water", "fae", "hazel", "creel"]

static func _check_items(db: ItemDB, dex: Dex) -> Array:
	var e := []
	for id in db.duplicates:
		e.append("item id '%s' defined more than once" % id)
	for id in db.ids():
		e.append_array(_check_item(db.get_item(id), dex))
	for sid in db.shops:
		e.append_array(_check_shop(sid, db.shops[sid], db))
	return e

static func _check_item(it: Dictionary, dex: Dex) -> Array:
	var e := []
	var id: String = it.get("id", "?")
	var kind: String = it.get("kind", "")
	if str(it.get("name", "")) == "":
		e.append("item %s: missing name" % id)
	if str(it.get("desc", "")) == "":
		e.append("item %s: missing desc" % id)
	if kind not in ITEM_KINDS:
		e.append("item %s: unknown kind '%s'" % [id, kind])
	if int(it.get("price", 0)) < 0:
		e.append("item %s: price must be 0 or more" % id)
	match kind:
		"heal", "pp":
			if int(it.get("amount", 0)) < 1:
				e.append("item %s: %s item needs amount >= 1" % [id, kind])
		"meal":
			for p in Meals.problems(it):
				e.append("item %s: %s" % [id, p])
			if str(it.get("effect_text", "")) == "":
				e.append("item %s: a dish documents its effect (effect_text)" % id)
		"revive":
			var a := int(it.get("amount", 0))
			if a < 1 or a > 100:
				e.append("item %s: revive amount is a percentage, 1..100" % id)
		"cure":
			var cures: Array = it.get("cures", [])
			if cures.is_empty():
				e.append("item %s: cure item needs a cures list" % id)
			for s in cures:
				if s not in Rules.STATUSES:
					e.append("item %s: unknown status '%s'" % [id, s])
		"charm":
			var fx = it.get("charm", {})
			if not (fx is Dictionary) or str(fx.get("effect", "")) not in Charms.EFFECTS:
				e.append("item %s: charm needs a known effect" % id)
		"repel":
			if int(it.get("steps", 0)) < 1:
				e.append("item %s: repel item needs steps >= 1" % id)
		"snare":
			var sn: String = it.get("snare", "")
			if not Catching.SNARES.has(sn) and sn not in EXTRA_SNARES:
				e.append("item %s: unknown snare '%s'" % [id, sn])
		"evo":
			var evolves: Dictionary = it.get("evolves", {})
			for from in evolves:
				if not dex.has(str(from)):
					e.append("item %s: evolves unknown species '%s'" % [id, from])
				if not dex.has(str(evolves[from])):
					e.append("item %s: evolves into unknown species '%s'" % [id, evolves[from]])
	return e

static func _check_shop(sid: String, shop: Dictionary, db: ItemDB) -> Array:
	var e := []
	if str(shop.get("name", "")) == "":
		e.append("shop %s: missing name" % sid)
	var stock: Array = shop.get("stock", [])
	if stock.is_empty():
		e.append("shop %s: empty stock" % sid)
	for item_id in stock:
		var it := db.get_item(str(item_id))
		if it.is_empty():
			e.append("shop %s: unknown item '%s'" % [sid, item_id])
		elif int(it.price) <= 0:
			e.append("shop %s: '%s' has no price" % [sid, item_id])
	return e
