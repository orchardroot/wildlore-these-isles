class_name TownProjects
extends RefCounted
## Town projects (wave 55): things worth being rich for. In about fifteen towns something the place needs (a lifeboat
## house, a footbridge, a bandstand, a mill, a ferry) can be paid for by the player, a stage at a time or all at once
## (data/town_projects.json). Each is a real KIND of project for the real place; none is needed for the story.
## Paying is done through a resident of the town (the hook in ScriptHooks.wrap, then the "project:<id>" screen). Each
## stage is paid in full, and the work then takes a few in-game days before the next can be paid. When the last stage's
## work is done the town changes for good:
##   - the flag `project_<id>` is set (a gate or a hidden warp in an existing zone can reveal on it),
##   - the town's standing with you rises (Standing),
##   - the resident says so, and the plaque has your name on it (the screen shows it),
##   - and, where it makes sense, a Deed in the town gains something (deed_fx, read by DeedChoices.fx), or a keepsake
##     comes with the thanks.
## Costs scale with progress (ParLevel), the way Jobs do, so a project is a sink at every stage of the game: an early
## visit is cheap, the end of the story is dear. All sums are STERLING whole pounds; the zone's money (Wallet) decides
## what leaves the purse.
## State is one flag per project, absent until the first stage is paid, so old saves are fine:
##   tp_<id>   {stage (stages paid), ready (day the work paid for so far is done), paid (sterling), name, day}
## Pure logic, no autoloads.

const PATH := "res://data/town_projects.json"
const STATE_PREFIX := "tp_"
const DONE_PREFIX := "project_"
const ROUND := 50
const FACTOR_LO := 0.45
const FACTOR_HI := 1.5

static var _all: Array = []
static var _by_id: Dictionary = {}

static func all() -> Array:
	if _all.is_empty():
		var raw: Variant = JsonUtil.read(PATH)
		_all = raw.get("projects", []) if raw is Dictionary else []
		_by_id = {}
		for p in _all:
			_by_id[str(p.id)] = p
	return _all

static func get_project(id: String) -> Dictionary:
	all()
	return _by_id.get(id, {})

static func in_zone(zone_id: String) -> Array:
	return all().filter(func(p): return str(p.zone) == zone_id)

static func for_npc(zone_id: String, npc_id: String) -> Dictionary:
	for p in all():
		if str(p.zone) == zone_id and str(p.get("npc", "")) == npc_id:
			return p
	return {}

static func _i(d: Variant, k: String) -> int:
	return int(d.get(k, 0)) if d is Dictionary else 0

# --- state ------------------------------------------------------------------------------------

static func state(data: GameStateData, id: String) -> Dictionary:
	var v: Variant = data.flag(STATE_PREFIX + id)
	if not (v is Dictionary):
		return {"stage": 0, "ready": 0, "paid": 0, "name": "", "day": 0}
	return {"stage": _i(v, "stage"), "ready": _i(v, "ready"), "paid": _i(v, "paid"), "name": str(v.get("name", "")), "day": _i(v, "day")}

static func is_done(data: GameStateData, id: String) -> bool:
	return ZoneData.flag_on(data.flag(DONE_PREFIX + id))

static func stages_paid(data: GameStateData, id: String) -> int:
	return state(data, id).stage

static func started(data: GameStateData, id: String) -> bool:
	return stages_paid(data, id) > 0

static func flag_of(id: String) -> String:
	return DONE_PREFIX + id

## Open to the player yet: a few Stones in, the nation's usual arrival, so no project asks for money a visitor can't have.
static func available(data: GameStateData, p: Dictionary) -> bool:
	return data.badges.size() >= int(p.get("badges", 0))

static func done_ids(data: GameStateData) -> Array:
	return all().filter(func(p): return is_done(data, str(p.id))).map(func(p): return str(p.id))

# --- money --------------------------------------------------------------------------------------

## How much dearer the work is as the story goes on: 0.45 at the start, 1.0 at par 60, 1.37 at the end.
static func factor(data: GameStateData) -> float:
	return clampf((40.0 + float(ParLevel.par(data.flags))) / 100.0, FACTOR_LO, FACTOR_HI)

static func cost_at(p: Dictionary, stage: int, f: float) -> int:
	var stages: Array = p.get("stages", [])
	if stage < 0 or stage >= stages.size():
		return 0
	var c := float(p.cost) * float(stages[stage].share) / 100.0 * f
	return maxi(ROUND, roundi(c / float(ROUND)) * ROUND)

static func stage_cost(data: GameStateData, p: Dictionary, stage: int) -> int:
	return cost_at(p, stage, factor(data))

static func cost_left(data: GameStateData, p: Dictionary) -> int:
	var total := 0
	for s in range(stages_paid(data, str(p.id)), (p.get("stages", []) as Array).size()):
		total += stage_cost(data, p, s)
	return total

static func cur_of(p: Dictionary) -> String:
	return Wallet.currency_for_zone(str(p.zone))

static func _days(p: Dictionary, stage: int) -> int:
	return int(p.stages[stage].get("days", 5))

# --- paying -------------------------------------------------------------------------------------

## "" when the next stage can be paid now, else why not.
static func why_not(data: GameStateData, p: Dictionary) -> String:
	var id := str(p.id)
	if is_done(data, id):
		return "It's done, and it's lovely."
	if not available(data, p):
		return "Not yet. They'd want to know you better first."
	var st := state(data, id)
	if st.stage >= (p.stages as Array).size():
		return "Everything is paid for. The work is still going on."
	if st.stage > 0 and data.day_count < st.ready:
		return "The last stage is still being built (%d more days)." % (st.ready - data.day_count)
	return ""

static func _pay(data: GameStateData, p: Dictionary, upto: int) -> String:
	var id := str(p.id)
	var from := stages_paid(data, id)
	var gbp := 0
	var days := 0
	var f := factor(data)
	for s in range(from, upto):
		gbp += cost_at(p, s, f)
		days += _days(p, s)
	var cur := cur_of(p)
	var local := Wallet.localise(gbp, cur)
	if not Wallet.spend(data, local, cur):
		return "You'd need %s for that." % Wallet.fmt(local, cur)
	var old := state(data, id)
	data.set_flag(STATE_PREFIX + id, {"stage": upto, "ready": data.day_count + days, "paid": old.paid + gbp,
		"name": data.player_name, "day": data.day_count})
	return ""

## Pays the next stage. "" or a reason.
static func fund(data: GameStateData, id: String) -> String:
	var p := get_project(id)
	if p.is_empty():
		return "There's no such project."
	var why := why_not(data, p)
	if why != "":
		return why
	return _pay(data, p, stages_paid(data, id) + 1)

## Pays every stage still to pay, at once ("alone", in one go). The work still takes its time, stage after stage.
static func fund_all(data: GameStateData, id: String) -> String:
	var p := get_project(id)
	if p.is_empty():
		return "There's no such project."
	var why := why_not(data, p)
	if why != "":
		return why
	return _pay(data, p, (p.stages as Array).size())

## Days until the work paid for is finished (0 when there is nothing building).
static func days_left(data: GameStateData, id: String) -> int:
	var st := state(data, id)
	return maxi(0, st.ready - data.day_count) if st.stage > 0 and not is_done(data, id) else 0

# --- the days go by -------------------------------------------------------------------------------

## Opens whatever has finished building. Returns lines for the wireless. Cheap: it only looks at projects with money in.
static func tick(data: GameStateData, day: int) -> Array:
	var lines := []
	for p in all():
		var id := str(p.id)
		if is_done(data, id):
			continue
		var st := state(data, id)
		if st.stage >= (p.stages as Array).size() and st.stage > 0 and day >= st.ready:
			lines.append_array(_open(data, p))
	return lines

static func _open(data: GameStateData, p: Dictionary) -> Array:
	var id := str(p.id)
	data.set_flag(DONE_PREFIX + id, true)
	var lines := ["%s: %s" % [str(p.name), str(p.get("opened", "It's open."))]]
	var fx: Dictionary = p.get("effects", {})
	var nation := Standing.nation_for_zone(str(p.zone))
	var tier_line := Standing.add(data, nation, int(fx.get("standing", 4)))
	if tier_line != "":
		lines.append(tier_line + ".")
	var gift := str(fx.get("item", ""))
	if gift != "":
		data.bag[gift] = mini(Bag.MAX_STACK, int(data.bag.get(gift, 0)) + 1)
	return lines

# --- what a finished project does ----------------------------------------------------------------

## What the finished projects in a town give the Deeds there: a dictionary like an upgrade (takings, shield, carry...).
static func deed_fx(data: GameStateData, deed_id: String) -> Dictionary:
	var out := {}
	var zone := str(Deeds.get_deed(deed_id).get("zone", ""))
	for p in in_zone(zone):
		if not is_done(data, str(p.id)):
			continue
		var d: Variant = p.get("effects", {}).get("deed", {})
		if d is Dictionary and d.has(deed_id):
			for k in d[deed_id]:
				var v: Variant = d[deed_id][k]
				if k == "takings":
					out[k] = float(out.get(k, 1.0)) * float(v)
				else:
					out[k] = float(out.get(k, 0.0)) + float(v)
	return out

## The plaque, with the name on it.
static func plaque(data: GameStateData, p: Dictionary) -> String:
	var who := str(state(data, str(p.id)).name)
	return str(p.get("plaque", "")).replace("{player}", who if who != "" else data.player_name)

## Every plaque the player has earned, for a list.
static func plaques(data: GameStateData) -> Array:
	var out := []
	for p in all():
		if is_done(data, str(p.id)):
			out.append("%s: %s" % [str(p.name), plaque(data, p)])
	return out

# --- the resident ------------------------------------------------------------------------------------

## The hook (ScriptHooks.wrap): the resident who speaks for a project adds a line about it to their talk, and a way to
## the plans while there is something to pay. Nothing until the project is open to you; the thanks line after.
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	var p := for_npc(zone_id, npc_id)
	if p.is_empty() or not available(data, p):
		return commands
	var id := str(p.id)
	var who := str(p.get("who", ""))
	var lines: Array = []
	if is_done(data, id):
		lines = p.get("done", [])
		return commands + lines.map(func(l): return {"do": "say", "who": who, "text": str(l).replace("{player}", data.player_name)})
	var st := state(data, id)
	lines = p.get("progress", []) if st.stage > 0 else p.get("ask", [])
	var out: Array = commands + lines.map(func(l): return {"do": "say", "who": who, "text": str(l).replace("{player}", data.player_name)})
	out.append({"do": "project", "id": id})
	return out

# --- checks for the validator ---------------------------------------------------------------------------

static func problems(zones: Dictionary, items: ItemDB) -> Array:
	var errs := []
	var seen := {}
	for p in all():
		var id := str(p.get("id", ""))
		var tag := "town project '%s': " % id
		if id == "" or seen.has(id):
			errs.append(tag + "missing or duplicate id")
		seen[id] = true
		var z: ZoneData = zones.get(str(p.get("zone", "")))
		if z == null:
			errs.append(tag + "zone '%s' is not a zone" % p.get("zone", ""))
		elif not z.npcs.any(func(n): return str(n.get("id", "")) == str(p.get("npc", ""))):
			errs.append(tag + "zone has no npc '%s'" % p.get("npc", ""))
		var stages: Array = p.get("stages", [])
		var share := 0
		for s in stages:
			share += int(s.get("share", 0))
		if stages.size() < 2 or stages.size() > 4 or share != 100:
			errs.append(tag + "needs two to four stages whose shares add up to 100")
		if int(p.get("cost", 0)) < 1000:
			errs.append(tag + "cost is missing")
		for k in ["name", "text", "who", "opened", "plaque"]:
			if str(p.get(k, "")).strip_edges() == "":
				errs.append(tag + "no " + k)
		for k in ["ask", "progress", "done"]:
			if not (p.get(k, []) is Array) or (p.get(k, []) as Array).is_empty():
				errs.append(tag + "no %s lines" % k)
		if "—" in JSON.stringify(p):
			errs.append(tag + "has an em-dash")
		var gift := str(p.get("effects", {}).get("item", ""))
		if gift != "" and not items.has(gift):
			errs.append(tag + "item '%s' is not an item" % gift)
		var dd: Variant = p.get("effects", {}).get("deed", {})
		if dd is Dictionary:
			for did in dd:
				if Deeds.get_deed(str(did)).is_empty() or str(Deeds.get_deed(str(did)).zone) != str(p.get("zone", "")):
					errs.append(tag + "deed '%s' is not a Deed in this town" % did)
		var warps: Variant = p.get("effects", {}).get("warps", [])
		if warps is Array and z != null:
			for w in warps:
				var found := false
				for zw in z.warps:
					if int(zw.x) == int(w.x) and int(zw.y) == int(w.y) and str(zw.get("hidden", {}).get("reveal", "")) == DONE_PREFIX + id:
						found = true
				if not found:
					errs.append(tag + "no hidden warp at %d,%d in the zone that reveals on %s" % [int(w.x), int(w.y), DONE_PREFIX + id])
	return errs
