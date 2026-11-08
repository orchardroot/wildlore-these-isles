class_name Forms
extends RefCounted
## Regional forms: a few creatures wear a slight local difference depending on where they are caught (Shetland herdlet,
## Irish hare). data/forms.json is {species id: {form id: def}}; a def has
##   name        the suffix shown as "Herdlet (Shetland)"
##   regions     zone regions it spawns in (the zone's "region"); required
##   zones       optional zone ids that narrow the regions (a form can belong to one place within a region)
##   types       optional replacement types: the same count as the base, at most one type changed
##   stat_lean   optional {stat: delta}, net zero, each within +/-STAT_CAP
##   knack       optional knack id that replaces the line's knack
##   move        optional signature move id it is given
##   look        optional {palette {hue (degrees), sat, val (deltas), tint "#rrggbb", tint_amount 0..1}, features [FEATURES]};
##               applied at runtime to the sprite sheets by FormArt, like coats (never baked into spritegen)
##   fact        one true sentence about the real regional variation
## A wild creature met in a form's region has that form; elsewhere it is the base form. Creature.form holds the id ("" for
## the usual one). Breeding is a game simplification: a hatchling takes its dam's form (the Stud Book says so), and
## hybrids never carry one. Forms are keyed per species, so an evolving line needs the form authored at each stage
## (and its baby stage, for breeding); a form its species has no entry for is inert. Forms never count towards the
## Fieldbook's core 200: the Fieldbook notes them in the flag form_<species>_<form> ("seen" or "caught").
## Pure logic: no autoload names (the validator loads things that load this).

const PATH := "res://data/forms.json"
const STAT_CAP := 6
const FEATURES := ["crest", "ears", "speckle", "belly", "stripe"]
const PALETTE_KEYS := ["hue", "sat", "val", "tint", "tint_amount"]
const FLAG_PREFIX := "form_"

static var _data: Dictionary = {}
static var _loaded := false

static func data() -> Dictionary:
	if not _loaded:
		var d = JsonUtil.read(PATH)
		_data = d if d is Dictionary else {}
		_loaded = true
	return _data

## Tests and tools that swap the table.
static func set_data(d: Dictionary) -> void:
	_data = d
	_loaded = true

static func reset() -> void:
	_data = {}
	_loaded = false

## {form id: def} for a species (empty for most).
static func forms_of(species_id: String) -> Dictionary:
	var d: Variant = data().get(species_id, {})
	return d if d is Dictionary and not species_id.begins_with("_") else {}

static func get_form(species_id: String, form_id: String) -> Dictionary:
	var d: Variant = forms_of(species_id).get(form_id, {})
	return d if d is Dictionary else {}

static func has(species_id: String, form_id: String) -> bool:
	return form_id != "" and not get_form(species_id, form_id).is_empty()

## Every (species, form) pair, sorted: [{species, form, def}].
static func all() -> Array:
	var out := []
	for sid in data():
		if str(sid).begins_with("_"):
			continue
		for fid in forms_of(str(sid)):
			out.append({"species": str(sid), "form": str(fid), "def": forms_of(str(sid))[fid]})
	out.sort_custom(func(a, b): return a.species + "/" + a.form < b.species + "/" + b.form)
	return out

static func total() -> int:
	return all().size()

# --- where a form spawns ---------------------------------------------------------------------

## The form a wild `species_id` has in a zone ("" for the base form): a form naming the zone wins over one that only
## names the region.
static func for_place(species_id: String, region: String, zone_id: String) -> String:
	var best := ""
	var forms := forms_of(species_id)
	for fid in forms:
		var f: Dictionary = forms[fid]
		if region not in f.get("regions", []):
			continue
		var zs: Array = f.get("zones", [])
		if zs.is_empty():
			if best == "":
				best = str(fid)
		elif zone_id in zs:
			return str(fid)
	return best

## Gives a freshly made wild creature its regional form for where it was met (and its signature move). Hybrids never.
static func assign_wild(c: Creature, region: String, zone_id: String, moves: MoveDB = null) -> void:
	if c == null or c.hybrid != "" or c.species.is_empty():
		return
	var fid := for_place(str(c.species.id), region, zone_id)
	if fid != "":
		apply(c, fid, moves)

## Puts a form on a creature and gives its signature move (the oldest move makes room). No-op if the species has no such form.
static func apply(c: Creature, form_id: String, moves: MoveDB = null) -> void:
	if c == null or c.species.is_empty() or not has(str(c.species.id), form_id):
		return
	var was_full := c.hp >= c.max_hp()
	c.form = form_id
	# a form that leans HP changes the max: a fresh (full) creature stays full, and nobody sits above the new max,
	# so its battle plate never starts part-drained
	c.hp = c.max_hp() if was_full else mini(c.hp, c.max_hp())
	var mv := str(get_form(str(c.species.id), form_id).get("move", ""))
	if mv == "" or c.has_move(mv) or moves == null or not moves.has(mv):
		return
	if c.moves.size() >= Rules.MAX_MOVES:
		c.moves.remove_at(0)
	c.moves.append(c.make_move_slot(mv, moves))

## Breeding (a simplification: the dam's form, see the Stud Book): a hatchling takes `dam_form` if its own species has
## that form. Hybrids never carry one.
static func inherit(child: Creature, dam_form: String, moves: MoveDB = null) -> void:
	if child == null or child.hybrid != "" or dam_form == "":
		return
	apply(child, dam_form, moves)

# --- what a form changes ----------------------------------------------------------------------

## The creature's types: the form's replacement if it has one.
static func types_for(sp: Dictionary, form_id: String) -> Array:
	if form_id != "":
		var t: Array = get_form(str(sp.get("id", "")), form_id).get("types", [])
		if not t.is_empty():
			return t
	return sp.types

## The stat lean for one stat (0 for the base form).
static func lean(species_id: String, form_id: String, stat: String) -> int:
	if form_id == "":
		return 0
	return int(get_form(species_id, form_id).get("stat_lean", {}).get(stat, 0))

## The knack id the form replaces the line's with ("" for none).
static func knack_for(species_id: String, form_id: String) -> String:
	return str(get_form(species_id, form_id).get("knack", "")) if form_id != "" else ""

static func name_of(species_id: String, form_id: String) -> String:
	return str(get_form(species_id, form_id).get("name", ""))

## "Herdlet (Shetland)"
static func label(base_name: String, species_id: String, form_id: String) -> String:
	var n := name_of(species_id, form_id)
	return base_name if n == "" else "%s (%s)" % [base_name, n]

static func fact_of(species_id: String, form_id: String) -> String:
	return str(get_form(species_id, form_id).get("fact", ""))

static func look_of(species_id: String, form_id: String) -> Dictionary:
	var l: Variant = get_form(species_id, form_id).get("look", {})
	return l if l is Dictionary else {}

## The battle line when a form turns up.
static func intro_line(species_id: String, form_id: String) -> String:
	var n := name_of(species_id, form_id)
	return "" if n == "" else "This one is the %s form." % n

## Region and zone words for the Fieldbook, via `region_name` (a Callable taking a region id).
static func where(species_id: String, form_id: String, region_name: Callable) -> String:
	var f := get_form(species_id, form_id)
	var names := []
	for r in f.get("regions", []):
		var n := str(region_name.call(str(r)))
		if n not in names:
			names.append(n)
	return ", ".join(names)

# --- the Fieldbook ----------------------------------------------------------------------------

static func flag_key(species_id: String, form_id: String) -> String:
	return "%s%s_%s" % [FLAG_PREFIX, species_id, form_id]

static func record_seen(data_: GameStateData, c: Creature) -> void:
	if c == null or c.form == "" or not has(str(c.species.id), c.form):
		return
	var k := flag_key(str(c.species.id), c.form)
	if data_.flag(k) != "caught":
		data_.set_flag(k, "seen")

static func record_caught(data_: GameStateData, c: Creature) -> void:
	if c != null and c.form != "" and has(str(c.species.id), c.form):
		data_.set_flag(flag_key(str(c.species.id), c.form), "caught")

## "seen", "caught" or "".
static func status(data_: GameStateData, species_id: String, form_id: String) -> String:
	var s: Variant = data_.flag(flag_key(species_id, form_id))
	return str(s) if s is String else ""

## [{form, name, regions, status}] for one species, in id order.
static func listing(data_: GameStateData, species_id: String) -> Array:
	var out := []
	var ids := forms_of(species_id).keys()
	ids.sort()
	for fid in ids:
		var f := get_form(species_id, str(fid))
		out.append({"form": str(fid), "name": str(f.get("name", "")), "regions": f.get("regions", []), "status": status(data_, species_id, str(fid))})
	return out

## {"seen": n, "caught": n, "total": n} over the authored forms (seen includes caught).
static func counts(data_: GameStateData) -> Dictionary:
	var out := {"seen": 0, "caught": 0, "total": total()}
	for e in all():
		var s := status(data_, e.species, e.form)
		if s != "":
			out.seen += 1
		if s == "caught":
			out.caught += 1
	return out

## The Stats page row: "2 of 6 caught" (or "None yet").
static func stats_line(data_: GameStateData) -> String:
	var n := counts(data_)
	if n.seen == 0:
		return "None yet"
	return "%d of %d caught" % [n.caught, n.total]

# --- checks (the validator) -------------------------------------------------------------------

## Errors in data/forms.json. `regions` is every region id a zone has.
static func check(dex: Dex, moves: MoveDB, regions: Array, chart: TypeChart = null) -> Array:
	var e := []
	var knacks: Dictionary = Knacks.data().get("knacks", {})
	for sid in data():
		if str(sid).begins_with("_"):
			continue
		if not dex.has(str(sid)):
			e.append("forms.json: unknown species '%s'" % sid)
			continue
		var sp := dex.get_species(str(sid))
		if bool(sp.get("legend", false)) or Dex.is_hybrid(str(sid)):
			e.append("forms.json: %s is a legend or hybrid and cannot have forms" % sid)
		var seen_names := {}
		for fid in forms_of(str(sid)):
			var f := get_form(str(sid), str(fid))
			var tag := "form %s/%s" % [sid, fid]
			if str(fid) != str(fid).to_lower() or str(fid).contains(" "):
				e.append("%s: ids are lower case with no spaces" % tag)
			var nm := str(f.get("name", ""))
			if nm == "":
				e.append("%s: needs a name" % tag)
			elif seen_names.has(nm):
				e.append("%s: name '%s' is used twice on this species" % [tag, nm])
			seen_names[nm] = true
			var rs: Array = f.get("regions", [])
			if rs.is_empty():
				e.append("%s: needs at least one region" % tag)
			for r in rs:
				if str(r) not in regions:
					e.append("%s: unknown region '%s'" % [tag, r])
			if f.has("types"):
				e.append_array(_check_types(tag, sp, f.types, chart))
			if f.has("stat_lean"):
				e.append_array(_check_lean(tag, f.stat_lean))
			var kn := str(f.get("knack", ""))
			if kn != "" and (not knacks.has(kn) or bool(knacks[kn].get("legend", false))):
				e.append("%s: unknown or legend knack '%s'" % [tag, kn])
			var mv := str(f.get("move", ""))
			if mv != "" and not moves.has(mv):
				e.append("%s: unknown move '%s'" % [tag, mv])
			e.append_array(_check_look(tag, f.get("look", {})))
			var fact := str(f.get("fact", ""))
			if fact == "":
				e.append("%s: needs a fact" % tag)
			for t in [nm, fact]:
				if str(t).contains("—"):
					e.append("%s: no em-dashes" % tag)
		# a species' forms may not claim the same zone (the first would always win)
		var claimed := {}
		for fid in forms_of(str(sid)):
			var f := get_form(str(sid), str(fid))
			var zs: Array = f.get("zones", [])
			for r in f.get("regions", []):
				var keys: Array = zs if not zs.is_empty() else ["*"]
				for z in keys:
					var k := "%s|%s" % [r, z]
					if claimed.has(k):
						e.append("form %s/%s: overlaps %s in %s" % [sid, fid, claimed[k], r])
					claimed[k] = str(fid)
	return e

static func _check_types(tag: String, sp: Dictionary, t: Variant, chart: TypeChart) -> Array:
	var e := []
	if not (t is Array) or t.size() != sp.types.size():
		return ["%s: types must keep the base's count (%d)" % [tag, sp.types.size()]]
	var changed := 0
	for x in t:
		if chart != null and str(x) not in chart.types:
			e.append("%s: unknown type '%s'" % [tag, x])
		if x not in sp.types:
			changed += 1
	if changed > 1:
		e.append("%s: changes more than one type" % tag)
	return e

static func _check_lean(tag: String, lean: Variant) -> Array:
	var e := []
	if not (lean is Dictionary):
		return ["%s: stat_lean must be a dictionary" % tag]
	var sum := 0
	for s in lean:
		if str(s) not in Rules.STATS:
			e.append("%s: unknown stat '%s'" % [tag, s])
		var v := int(lean[s])
		sum += v
		if absi(v) > STAT_CAP:
			e.append("%s: %s lean %d is past +/-%d" % [tag, s, v, STAT_CAP])
	if sum != 0:
		e.append("%s: stat_lean must net to zero (is %d)" % [tag, sum])
	return e

static func _check_look(tag: String, look: Variant) -> Array:
	var e := []
	if not (look is Dictionary):
		return ["%s: look must be a dictionary" % tag]
	for f in look.get("features", []):
		if str(f) not in FEATURES:
			e.append("%s: unknown look feature '%s'" % [tag, f])
	var p: Variant = look.get("palette", {})
	if not (p is Dictionary):
		return e + ["%s: look.palette must be a dictionary" % tag]
	for k in p:
		if str(k) not in PALETTE_KEYS:
			e.append("%s: unknown palette key '%s'" % [tag, k])
	if p.has("tint") and not Color.html_is_valid(str(p.tint)):
		e.append("%s: palette tint is not a colour" % tag)
	if absf(float(p.get("hue", 0))) > 90.0 or absf(float(p.get("sat", 0))) > 1.0 or absf(float(p.get("val", 0))) > 1.0 \
			or float(p.get("tint_amount", 0)) < 0.0 or float(p.get("tint_amount", 0)) > 1.0:
		e.append("%s: palette values out of range (hue +/-90, sat and val +/-1, tint_amount 0..1)" % tag)
	return e
