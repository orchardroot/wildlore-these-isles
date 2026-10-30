extends Node
## Headless playtest bot. Plays the slice through the real scenes: walks with the pathfinder,
## talks to NPCs, fights with a sensible move picker, catches a couple of creatures, heals when low,
## grinds if the Keeper wins, and checks invariants every frame.
##   godot --headless --path . -- --playtest=slice [--seed=N] [--seconds=N]
##   godot --headless --path . -- --playtest=fuzz --seconds=120 [--seed=N]
##   godot --headless --path . -- --playtest=full [--seed=N]   (the whole story, start to credits; see FULL_BEATS)
##   godot --headless --path . -- --playtest=from:<zone>/<npc>[+N]   (full-mode play from a built save at that beat, for N beats, default 1)
## Exit code 0 on success, 1 on any failure. Prints "PLAYTEST PASS" or "PLAYTEST FAIL: <why>".

const TIME_SCALE := 10.0
const BUSY_LIMIT := 240.0   # game seconds Router may stay busy before we call it a soft-lock

var mode := "slice"
var failures: Array = []
var stats := {"battles": 0, "wins": 0, "losses": 0, "catches": 0, "steps": 0, "cheat_heals": 0, "lines": 0}
var _busy_t := 0.0
var _limit := 0.0
var _elapsed := 0.0
var _rng := RandomNumberGenerator.new()
var _done := false
var _last_beat := 0.0
var _wall_start := 0
## full mode bookkeeping: per key fight losses, grind time per chapter, team at each Keeper
var _fight_id := ""
var _fight_losses := {}
var _fight_order: Array = []
var _grind_time := {}
var _keeper_teams: Array = []
var _chapter := ""
var _bad_grind := {}
var _rail_dest := ""
var _in_rail := false
var _bag_opened := false
var _rz := {}
var _rz_base := {}
var _rz_sig := -1
var _adj := {}
var _rail_guards := {}
var _nurses := {}
var _sailors := {}   # quay zone -> [sailor npc id, zone at the other end]
var _no_route := ""
var _walk_lost := false
var _softlocks: Array = []
var _moot_tries := 0
var _moot_assist := 0   # full heals between Moot fights once the bot has lost the Moot MOOT_ASSIST_AFTER times
const MOOT_ASSIST_AFTER := 3
## After this many lost tries at one story beat the bot gets an in-battle crutch (a creature below a third of its HP
## is topped up, as if from an endless bag of tea) so the rest of the story still gets played. Counted and reported.
const FIGHT_ASSIST_AFTER := 8
var _assist_fight := false
var _assisted: Dictionary = {}   # beat -> in-battle top-ups
var _beat_name := ""
var _from := -1       # from mode: index into FULL_BEATS to start at
var _from_count := 1  # from mode: how many beats to play

func start(m: String) -> void:
	mode = m
	if m.begins_with("from:"):
		var spec := m.substr(5).split("+")
		_from_count = int(spec[1]) if spec.size() > 1 else 1
		mode = "full"
		for i in FULL_BEATS.size():
			if "%s/%s" % [FULL_BEATS[i][0], FULL_BEATS[i][1]] == spec[0]:
				_from = i
		if _from < 0:
			push_error("playtest from: unknown beat '%s'" % spec[0])
			get_tree().quit(1)
			return
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.set_meta("autopilot", self)
	Engine.time_scale = TIME_SCALE
	_rng.seed = maxi(0, int(Game.args.get("seed", 1)))
	_limit = float(Game.args.get("seconds", 0))
	if _limit <= 0.0:
		_limit = {"slice": 6000.0, "m2": 16000.0, "full": 150000.0}.get(mode, 120.0)
	_wall_start = Time.get_ticks_msec()
	Bus.battle_ended.connect(_on_battle_ended)
	Bus.battle_started.connect(func(_k):
		stats.battles += 1
		_busy_t = 0.0  # a gauntlet keeps the Router busy across fights; a new fight is progress
		_fight_id = "")
	_run()

func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta / Engine.time_scale
	_busy_t = _busy_t + delta if Router.busy else 0.0
	if _busy_t > BUSY_LIMIT:
		_fail("Router stuck busy for %d game seconds in %s" % [int(_busy_t), Game.data.zone_id])
	var ow := _ow()
	if ow and ow.zone and ow.player and not ow.player.moving and not Router.busy:
		var p: Vector2i = ow.player.grid_pos
		if ow.zone.in_bounds(p) and not ow.zone.walkable(p, Vector2i.ZERO, FieldMoves.abilities(Game.data)) and ow.zone.tile_at(p) != "ledge_south":
			_fail("player stands on unwalkable %s at %s in %s" % [ow.zone.tile_at(p), p, ow.zone.id])
	if mode != "fuzz" and _elapsed - _last_beat > 120.0:
		_last_beat = _elapsed
		var owh := _ow()
		print("BOT: heartbeat %ds (wall %ds) in %s at %s, team %s, steps %d, battles %d W/L %d/%d, heals %d" % [int(_elapsed), (Time.get_ticks_msec() - _wall_start) / 1000, Game.data.zone_id,
			owh.player.grid_pos if owh and owh.player else Vector2i(-1, -1), Game.data.party.map(func(c): return "%s L%d" % [c.species.id, c.level]),
			stats.steps, stats.battles, stats.wins, stats.losses, stats.cheat_heals])
	if _elapsed > _limit:
		if mode == "fuzz":
			_finish()
		else:
			_fail("time limit %d s reached (in %s)" % [int(_limit), Game.data.zone_id])

# --- scenario ----------------------------------------------------------------

func _run() -> void:
	Game.new_game()
	await Router.goto_zone(Game.data.zone_id, Vector2i(-1, -1), "down")
	await _settle()
	if mode == "fuzz":
		await _fuzz()
		return
	if mode == "doors":
		await _doors()
		_finish()
		return
	if _from >= 0:
		await _build_state_at(_from)
		await _full()
		_finish()
		return
	await _talk("macc_home", "mum")
	await _talk("macc_fieldstation", "garside")
	_check(Game.data.party.size() >= 1, "no starter after Garside")
	_check(Game.data.flag("starter") != null, "starter flag missing")
	print("BOT: starter %s, money %d" % [Game.data.flag("starter"), Game.data.money])
	if mode == "full":
		await _full()
		_finish()
		return
	await _beat("buxton_spa", "maud", "badge_brook", 14)
	if mode == "m2" and not _done:
		await _m2()
	_finish()

## Talks to `npc` until `flag` is set, grinding a bit harder in `grind_zone` before each retry.
func _beat(zone_id: String, npc: String, flag: String, level := 0, grind_zone := "") -> void:
	_restock()
	var attempts := 0
	while not Game.data.flag(flag) and attempts < 4 and not _done:
		attempts += 1
		if level > 0:
			await _grind_to(level + (attempts - 1) * 2, grind_zone)
		await _heal_if_low(1.0)
		await _talk(zone_id, npc)
		var team: Array = Game.data.party.map(func(c): return "%s L%d" % [c.species.id, c.level])
		print("BOT: %s/%s attempt %d -> %s %s, team %s, W/L %d/%d" % [zone_id, npc, attempts, flag, "WON" if Game.data.flag(flag) else "not yet", team, stats.wins, stats.losses])
	_check(Game.data.flag(flag) == true, "%s/%s never set %s in %d attempts" % [zone_id, npc, flag, attempts])

## Buys Wicker Snares (at shop price, if it can afford them) so the team can grow like a real player's.
func _restock() -> void:
	var price := int(Game.items.get_item("wicker_snare").get("price", 200)) if Game.items else 200
	var want := 10 if mode == "full" else 5
	while int(Game.data.bag.get("wicker_snare", 0)) < want and Game.data.money >= price:
		Game.data.money -= price
		Game.data.bag["wicker_snare"] = int(Game.data.bag.get("wicker_snare", 0)) + 1
	if mode == "full" and "urban" in Game.data.badges:
		var iron := int(Game.items.get_item("iron_snare").get("price", 600))
		while int(Game.data.bag.get("iron_snare", 0)) < 5 and Game.data.money >= iron + 2000:
			Game.data.money -= iron
			Game.data.bag["iron_snare"] = int(Game.data.bag.get("iron_snare", 0)) + 1

## M2: Manchester to the Storm Stone, following docs/superpowers/plans/2026-10-14-plan-3-story-beats.md.
func _m2() -> void:
	var starter := str(Game.data.flag("starter"))
	await _beat("manc_bikes", "bev", "bev_bike_given")
	_check(int(Game.data.bag.get("bike", 0)) > 0, "no bike from Bev")
	await _beat("liverpool", "kit", "kit3_done", 19, "chat_moss")
	await _beat("liverpool_club", "keeper_ray", "badge_urban", 22, "chat_moss")
	_check(int(Game.data.bag.get("rail_pass", 0)) > 0, "no rail pass after the Urban Stone")
	await _beat("llanberis", "pryce", "trainer_pryce_1", 27, "ogwen")
	await _beat("llanberis_quarry", "keeper_eluned", "badge_stone", 30, "ogwen")
	await _beat("yr_wyddfa", "pryce_summit", "ch3_ddraig_woke")
	await _beat("cardiff", "kit", "kit4_done", 35, "beacons")
	await _beat("cardiff", "pryce", "trainer_pryce_2", 35, "beacons")
	await _beat("cardiff_arena", "keeper_rhys", "badge_storm", 37, "beacons")
	_check(Game.data.flag("v02_complete") == true, "no end card after the Storm Stone")
	if not _done:
		print("BOT: M2 done with %s, badges %s" % [starter, Game.data.badges])

# --- full: the whole story, start to credits -----------------------------------

## The story in order, from the beat files (docs/superpowers/plans/*-story-beats.md):
## [zone, npc id, flag it sets (or "@zone" for a ferry that lands there), chapter (the Stone being chased)].
## The fights in each beat, and so the level to train towards after a loss, are read from the NPC's own script.
const FULL_BEATS := [
	["buxton_spa", "maud", "badge_brook", "1 brook"],
	["manc_bikes", "bev", "bev_bike_given", "2 urban"],
	["liverpool", "kit", "kit3_done", "2 urban"],
	["liverpool_club", "keeper_ray", "badge_urban", "2 urban"],
	["llanberis", "pryce", "trainer_pryce_1", "3 stone"],
	["llanberis_quarry", "keeper_eluned", "badge_stone", "3 stone"],
	["yr_wyddfa", "pryce_summit", "ch3_ddraig_woke", "4 storm"],
	["cardiff", "kit", "kit4_done", "4 storm"],
	["cardiff", "pryce", "trainer_pryce_2", "4 storm"],
	["cardiff_arena", "keeper_rhys", "badge_storm", "4 storm"],
	["glastonbury", "kit_tor", "kit5_done", "5 fae"],
	["glastonbury_tor", "tor_druid", "trainer_tor_druid", "5 fae"],
	["glastonbury_tor", "keeper_morwen", "badge_fae", "5 fae"],
	["tintagel", "ashcombe", "ashcombe1_done", "6 kin"],
	["geevor", "ashcombe_mine", "ashcombe2_done", "6 kin"],
	["holyhead", "hh_sailor", "@dublin", "6 kin"],
	["dublin", "kerrigan_launch", "ch6_launch", "6 kin"],
	["dublin_hall", "keeper_declan", "badge_kin", "6 kin"],
	["kilkenny", "kerrigan", "kerrigan1_done", "7 tide"],
	["galway", "kit", "kit6_done", "7 tide"],
	["galway_docks", "keeper_nuala", "badge_tide", "7 tide"],
	["newgrange_tomb", "kerrigan_tomb", "ch7_judged", "8 iron"],
	["belfast_yard", "keeper_ruairi", "badge_iron", "8 iron"],
	["causeway", "vane_causeway", "ch8_vane", "9 frost"],
	["belfast", "belfast_sailor", "@cairnryan", "9 frost"],
	["edinburgh", "kit", "kit7_done", "9 frost"],
	["glencoe", "strachan", "strachan1_done", "9 frost"],
	["loch_ness", "strachan_boat", "strachan2_done", "9 frost"],
	["inverness_rink", "keeper_isla", "badge_frost", "9 frost"],
	["aberdeen", "abdn_postie", "ch10_started", "10 spirit"],
	["york_minster_crypt", "keeper_hester", "badge_spirit", "10 spirit"],
	["stonehenge", "kit", "kit8_done", "11 moot"],
	["stonehenge", "wind_aelwen", "moot_won", "11 moot"],
	["underground", "reunion_a", "trainer_reunion_pryce_ashcombe", "12 vane"],
	["underground", "reunion_b", "trainer_reunion_kerrigan_strachan", "12 vane"],
	["vane_tower_top", "vane", "game_complete", "12 vane"],
]
const KEY_FIGHTS := ["keeper_", "kit_", "pryce_", "ashcombe_", "kerrigan_", "strachan_", "vane_", "wind_", "champion_", "reunion_", "tor_druid"]
const MAX_PARTY_FULL := 6

## from mode: a save as if the story had reached beat `idx`. The flags and Stones of every earlier beat, a team of
## five at the story's par level (core/par_level.gd), standing at the zone's spawn.
func _build_state_at(idx: int) -> void:
	var d: GameStateData = Game.data
	d.set_flag("starter", "kindlet")
	for i in idx:
		var f := str(FULL_BEATS[i][2])
		if f.begins_with("@"):
			continue
		d.set_flag(f)
		if f.begins_with("badge_") and not d.badges.has(f.substr(6)):
			d.badges.append(f.substr(6))
	var lv := ParLevel.par(d.flags)
	d.party.clear()
	for sp in ["kindlet", "spikkin", "holtling", "binfox", "hootlet"]:
		d.add_creature(Creature.create(Game.dex.get_species(sp), lv, Game.rng, Game.moves))
	d.heal_party()
	print("BOT: from beat %d (%s/%s), par L%d, badges %s" % [idx, FULL_BEATS[idx][0], FULL_BEATS[idx][1], lv, d.badges])
	await Router.goto_zone(str(FULL_BEATS[idx][0]), Vector2i(-1, -1), "down")
	await _settle()

func _full() -> void:
	_build_rail_guards()
	for bi in FULL_BEATS.size():
		var b: Array = FULL_BEATS[bi]
		if _done:
			return
		if _from >= 0 and (bi < _from or bi >= _from + _from_count):
			continue
		_chapter = b[3]
		if not _grind_time.has(_chapter):
			_grind_time[_chapter] = 0.0
		await _story_beat(str(b[0]), str(b[1]), str(b[2]))
	if _from >= 0:
		_check(_softlocks.is_empty(), "%d possible soft-lock(s), see BOT: SOFTLOCK lines" % _softlocks.size())
		return
	_check(Game.data.flag("game_complete") == true, "game_complete not set after Vane")
	_check(_softlocks.is_empty(), "%d possible soft-lock(s), see BOT: SOFTLOCK lines" % _softlocks.size())
	if not _done:
		print("BOT: credits reached, game_complete set, badges %s" % [Game.data.badges])

func _beat_done(flag: String) -> bool:
	if flag.begins_with("@"):
		return Game.data.zone_id == flag.substr(1)
	return Game.data.flag(flag) == true

## Talks to `npc` until `flag` is set. Before the first try the team trains to four levels under the beat's
## strongest foe (from the NPC's script); after each loss it trains two more and tries again.
func _story_beat(zone_id: String, npc: String, flag: String) -> void:
	_restock()
	_bench_stragglers()
	if not flag.begins_with("@"):
		await _visit_sanctuary(zone_id)
	var ace := _beat_ace_level(zone_id, npc)
	if flag == "moot_won":
		_buy_moot_supplies()
	var attempts := 0
	var max_attempts := 14 if ace > 0 else 3
	while not _beat_done(flag) and attempts < max_attempts and not _done:
		attempts += 1
		if ace > 0:
			# like a player at a steady pace: within a few levels of the fight before the first try,
			# then a bit stronger after each loss
			var t0 := _elapsed
			await _grind_to(mini(ace - 4 + (attempts - 1) * 2, Rules.MAX_LEVEL - 2))
			_grind_time[_chapter] = float(_grind_time.get(_chapter, 0.0)) + _elapsed - t0
			if flag == "moot_won":
				_buy_moot_supplies()
		await _heal_if_low(1.0)
		if flag == "moot_won":
			_moot_tries = attempts
		_assist_fight = attempts > FIGHT_ASSIST_AFTER
		_beat_name = "%s/%s" % [zone_id, npc]
		await _talk(zone_id, npc)
		_assist_fight = false
		print("BOT: %s/%s attempt %d -> %s %s, team %s, W/L %d/%d" % [zone_id, npc, attempts, flag, "DONE" if _beat_done(flag) else "not yet", _team_str(), stats.wins, stats.losses])
	_check(_beat_done(flag), "%s/%s never set %s in %d attempts (flags here: %s)" % [zone_id, npc, flag, attempts, _flag_dump()])
	if flag.begins_with("badge_") and _beat_done(flag):
		_keeper_teams.append("%s: %s" % [flag, _team_str()])
		print("BOT: stone %s won, team %s" % [flag, _team_str()])

func _flag_dump() -> String:
	var keys: Array = Game.data.flags.keys().filter(func(k): return not str(k).begins_with("visited_") and not str(k).begins_with("station_") and not str(k).begins_with("cut_"))
	return ",".join(keys.map(func(k): return str(k)))

## A creature left far behind (more than 12 levels under the best) goes to the Ark, freeing a slot for a catch.
## Only when the party is full, and one at a time, so the team never shrinks below five.
func _bench_stragglers() -> void:
	var best := _strongest().level
	for c in Game.data.party.duplicate():
		if Game.data.party.size() >= MAX_PARTY_FULL and c.level < best - 12:
			Game.data.party.erase(c)
			Game.data.ark.append(c)
			print("BOT: %s L%d goes to the Ark (best is L%d)" % [c.species.id, c.level, best])

## The highest foe level among the fights in an NPC's script (rematches excluded), 0 if it has none.
func _beat_ace_level(zone_id: String, npc_id: String) -> int:
	var z := ZoneData.load_id(zone_id)
	for n in z.npcs:
		if str(n.get("id", "")) != npc_id:
			continue
		var ids := []
		if n.has("trainer"):
			ids.append(str(n.trainer))
		_collect_fights(StoryData.script(zone_id, str(n.get("script", ""))), ids)
		var best := 0
		for id in ids:
			if str(id).ends_with("_rematch"):
				continue
			for m in StoryData.trainer(str(id)).get("party", []):
				best = maxi(best, int(m.level))
		return best
	return 0

func _collect_fights(cmds: Variant, out: Array) -> void:
	if cmds is Dictionary:
		if str(cmds.get("do", "")) == "battle":
			out.append(str(cmds.get("trainer", "")))
		if str(cmds.get("do", "")) == "gauntlet":
			out.append_array(cmds.get("trainers", []))
		for k in cmds:
			if cmds[k] is Array or cmds[k] is Dictionary:
				_collect_fights(cmds[k], out)
	elif cmds is Array:
		for c in cmds:
			_collect_fights(c, out)

## Before the Moot a player stocks up: full-heal teas and revives, as many as the purse allows.
func _buy_moot_supplies() -> void:
	for want in [["kendal_mint_cake", 4], ["cream_tea", 8], ["pork_pie", 10]]:
		var price := int(Game.items.get_item(want[0]).get("price", 99999))
		while int(Game.data.bag.get(want[0], 0)) < want[1] and Game.data.money >= price:
			Game.data.money -= price
			Game.data.bag[want[0]] = int(Game.data.bag.get(want[0], 0)) + 1
	print("BOT: Moot supplies: revives %d, cream teas %d, pork pies %d, money %d" % [int(Game.data.bag.get("kendal_mint_cake", 0)), int(Game.data.bag.get("cream_tea", 0)), int(Game.data.bag.get("pork_pie", 0)), Game.data.money])

## Between Moot fights: is the team worth patching up?
func _team_low() -> bool:
	var hp := 0
	var mx := 0
	for c in Game.data.party:
		if c.is_fainted():
			return true
		hp += c.hp
		mx += c.max_hp()
	return mx > 0 and float(hp) / mx < 0.6

## The bag, opened between Moot fights: revive the fainted, then feed the hurt.
func _use_bag() -> void:
	if _moot_tries > MOOT_ASSIST_AFTER:
		# balance wall: the bot has lost the Moot several times and is too poor to stock up (every loss halves
		# the purse). Patch the team up anyway so the rest of the story still gets played; counted and reported.
		Game.data.heal_party()
		_moot_assist += 1
		print("BOT: Moot assist: full heal between fights (%d so far)" % _moot_assist)
		return
	var bag := Bag.new(Game.data.bag)
	var used := 0
	for c in Game.data.party:
		if c.is_fainted():
			for id in bag.items_of_kind("revive", Game.items):
				if bag.use_on(id, c, Game.items).get("ok", false):
					used += 1
					break
	for c in Game.data.party:
		var guard := 0
		while not c.is_fainted() and float(c.hp) / c.max_hp() < 0.7 and guard < 4:
			guard += 1
			var heals: Array = bag.items_of_kind("heal", Game.items)
			if heals.is_empty():
				break
			heals.sort_custom(func(a, b): return int(Game.items.get_item(a).get("amount", 0)) > int(Game.items.get_item(b).get("amount", 0)))
			if bag.use_on(heals[0], c, Game.items).get("ok", false):
				used += 1
			else:
				break
	print("BOT: opened the bag between Moot fights, used %d items, team %s" % [used, _team_str()])

# --- travel: rail and zone hops --------------------------------------------------

## Town zone -> the NPC whose script runs the `rail` command.
func _build_rail_guards() -> void:
	for zid in _routing_zones():
		var z: ZoneData = _rz[zid]
		if z.station == Vector2i(-1, -1):
			continue
		for n in z.npcs:
			var cmds := StoryData.script(zid, str(n.get("script", "")))
			if JSON.stringify(cmds).contains("\"do\":\"rail\""):
				_rail_guards[zid] = str(n.id)
				break
	for zid in _rz:
		var fz: ZoneData = _rz[zid]
		if fz.ferry.is_empty():
			continue
		var r: Dictionary = Travel.ferries().get(str(fz.ferry.get("route", "")), {})
		for n in fz.npcs:
			if JSON.stringify(StoryData.script(zid, str(n.get("script", "")))).contains("\"do\":\"ferry\""):
				_sailors[zid] = [str(n.id), str(r.b) if str(r.get("a", "")) == zid else str(r.get("a", ""))]
				break
	for zid in _rz:
		if not zid.ends_with("_sanctuary"):
			continue
		for n in _rz[zid].npcs:
			if JSON.stringify(StoryData.script(zid, str(n.get("script", "")))).contains("\"do\":\"heal\""):
				_nurses[zid] = str(n.id)
				break

## Like a player, check in at the Sanctuary nearest the next story beat, so a whiteout lands close by.
func _visit_sanctuary(near_zone: String) -> void:
	var dist := _hops_from(near_zone)
	var best := ""
	for zid in _nurses:
		if dist.has(zid) and (best == "" or int(dist[zid]) < int(dist[best])):
			best = zid
	if best == "" or str(Game.data.last_sanctuary.get("zone", "")) == best:
		return
	await _talk(best, str(_nurses[best]), false)

## Zone adjacency (edges and warps, both ways) for hop counts. Gates are ignored: it is only an estimate.
func _zone_adj() -> Dictionary:
	if _adj.is_empty():
		_adj = ZoneGraph.walk_adj(_routing_zones())
	return _adj

func _hops_from(zid: String) -> Dictionary:
	return ZoneGraph.hops(_zone_adj(), zid)

## Across the sea (say after a whiteout lands on the wrong island): take the nearest ferry that gets there.
func _maybe_ferry(dest_zone: String) -> void:
	var dh := _hops_from(Game.data.zone_id)
	if dh.has(dest_zone):
		return
	var best := ""
	for q in _sailors:
		if dh.has(q) and _hops_from(str(_sailors[q][1])).has(dest_zone) and (best == "" or int(dh[q]) < int(dh[best])):
			best = q
	if best == "":
		return
	print("BOT: ferry from %s to %s (heading for %s)" % [best, _sailors[best][1], dest_zone])
	await _talk(best, str(_sailors[best][0]), false)
	await _settle()

## Takes the train when a station hop saves a long walk: walk to the nearest rail guard, ride to the
## visited station closest to the destination.
func _maybe_rail(dest_zone: String) -> void:
	if int(Game.data.bag.get("rail_pass", 0)) <= 0 or _rail_guards.is_empty():
		return
	var here := Game.data.zone_id
	var dh := _hops_from(here)
	var direct := int(dh.get(dest_zone, 999))
	if direct < 5:
		return
	var dd := _hops_from(dest_zone)
	var best_cost := direct
	var best_from := ""
	var best_to := ""
	for a in _rail_guards:
		if not dh.has(a) or Game.data.flag(Travel.station_flag(a)) != true:
			continue
		for t in Travel.rail_destinations(Game.data, a):
			var cost := int(dh[a]) + int(dd.get(t, 999)) + 2
			if cost < best_cost:
				best_cost = cost
				best_from = a
				best_to = t
	if best_from == "":
		return
	print("BOT: rail from %s to %s (heading for %s, %d hops on foot, %d by train)" % [best_from, best_to, dest_zone, direct, best_cost])
	_in_rail = true
	_rail_dest = best_to
	await _talk(best_from, str(_rail_guards[best_from]), false)
	_rail_dest = ""
	_in_rail = false
	await _settle()

## The bot's own copy of every zone, with the tiles of standing NPCs (Wardens and the like, as the flags
## stand now) marked blocked, so routes through other zones never plan through a gate.
func _routing_zones() -> Dictionary:
	if _rz.is_empty():
		_rz = ZoneData.load_all()
		for id in _rz:
			_rz_base[id] = _rz[id].blocked.duplicate()
	var sig := Game.data.flags.hash()
	if sig != _rz_sig:
		_rz_sig = sig
		for id in _rz:
			var z: ZoneData = _rz[id]
			z.blocked = _rz_base[id].duplicate()
			for n in z.npcs:
				if str(n.get("move", "still")) != "still" or _unbeaten_trainer(n):
					continue
				if n.has("hide_if") and Game.data.flag(str(n.hide_if)):
					continue
				if n.has("show_if") and not Game.data.flag(str(n.show_if)):
					continue
				z.blocked[Vector2i(int(n.x), int(n.y))] = true
	return _rz

## Legs from here to a tile: first over only the zones near the shortest zone-hop path (fast), then the whole map.
func _plan(zone_id: String, target: Vector2i, blocked: Dictionary) -> Array:
	var zones := _routing_zones()
	var here := Game.data.zone_id
	var pos: Vector2i = _ow().player.grid_pos
	if here != zone_id:
		var a := _hops_from(here)
		var b := _hops_from(zone_id)
		if a.has(zone_id):
			var shortest := int(a[zone_id])
			var sub := {}
			for zid in a:
				if b.has(zid) and int(a[zid]) + int(b[zid]) <= shortest + 2:
					sub[zid] = zones[zid]
			var legs := Pathfinder.route(sub, here, pos, zone_id, target, blocked)
			if not legs.is_empty():
				return legs
	var t0 := Time.get_ticks_msec()
	var full := Pathfinder.route(zones, here, pos, zone_id, target, blocked)
	if Time.get_ticks_msec() - t0 > 3000:
		print("BOT: slow route %s %s -> %s %s took %d ms" % [here, pos, zone_id, target, Time.get_ticks_msec() - t0])
	return full

func _team_str() -> String:
	return " ".join(Game.data.party.map(func(c): return "%s L%d" % [c.species.id, c.level]))

func _print_summary() -> void:
	var wall := (Time.get_ticks_msec() - _wall_start) / 1000
	print("BOT: summary game time %s (%d s), bot clock %d s, wall %d s" % [_hms(Game.data.play_seconds), int(Game.data.play_seconds), int(_elapsed), wall])
	var losses := []
	for id in _fight_order:
		losses.append("%s %d" % [id, int(_fight_losses.get(id, 0))])
	print("BOT: summary losses per key fight: %s" % ", ".join(losses))
	var grind := []
	for ch in _grind_time:
		grind.append("ch%s %s" % [ch, _hms(float(_grind_time[ch]) * TIME_SCALE)])
	print("BOT: summary grind time per chapter (game time): %s" % ", ".join(grind))
	for k in _keeper_teams:
		print("BOT: summary team at %s" % k)
	for k in _softlocks:
		print("BOT: summary " + k)
	for k in _assisted:
		print("BOT: summary fight assist at %s: %d in-battle top-ups after %d lost tries" % [k, _assisted[k], FIGHT_ASSIST_AFTER])
	if _moot_assist > 0:
		print("BOT: summary Moot assist: %d full heals between Moot fights after %d lost Moot attempts" % [_moot_assist, MOOT_ASSIST_AFTER])
	print("BOT: summary stats %s" % [stats])

func _hms(sec: float) -> String:
	var s := int(sec)
	return "%dh%02dm%02ds" % [s / 3600, (s / 60) % 60, s % 60]

## Walks to an NPC (across zones if needed) and talks to them, then waits for the script to finish.
## With fatal false a failure just returns false (used for optional trips such as a train ride).
func _talk(zone_id: String, npc_id: String, fatal := true) -> bool:
	for tries in 6:
		if _done:
			return false
		var ow := _ow()
		if Game.data.zone_id == zone_id:
			var n := _npc(npc_id)
			if n == null:
				return _soft_fail("NPC %s not found in %s" % [npc_id, zone_id], fatal)
			var spot := _talk_spot(ow, n)
			if spot.is_empty():
				return _soft_fail("no tile to talk to %s from" % npc_id, fatal)
			if not await _walk_to(zone_id, spot.stand, fatal):
				if _no_route == "":
					return false
				return await _teleport_talk(zone_id, npc_id)
			ow = _ow()
			if Game.data.zone_id == zone_id and ow.player.grid_pos == spot.stand:
				ow.player.face(spot.face)
				await ow.interact(GridMotion.step(ow.player.grid_pos, spot.face))
				await _settle()
				return true
		else:
			if not await _walk_to(zone_id, ZoneData.load_id(zone_id).spawn, fatal):
				if _no_route == "":
					return false
				return await _teleport_talk(zone_id, npc_id)
	return _soft_fail("could not reach %s in %s" % [npc_id, zone_id], fatal)

## Full mode only: the bot can't walk to a story NPC. Records it as a possible soft-lock (with where it stood and
## the flags), then warps beside the NPC so the rest of the story still gets played. The run will fail at the end.
func _teleport_talk(zone_id: String, npc_id: String) -> bool:
	var why := _no_route
	_no_route = ""
	var z := ZoneData.load_id(zone_id)
	var npc_pos := Vector2i(-1, -1)
	for n in z.npcs:
		if str(n.get("id", "")) == npc_id:
			npc_pos = Vector2i(int(n.x), int(n.y))
	var note := "SOFTLOCK? beat %s/%s: %s; player %s %s; flags %s" % [zone_id, npc_id, why, Game.data.zone_id, _ow().player.grid_pos, _flag_dump()]
	print("BOT: " + note)
	_softlocks.append(note)
	if npc_pos == Vector2i(-1, -1):
		_fail("NPC %s not in %s data" % [npc_id, zone_id])
		return false
	for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var stand: Vector2i = npc_pos + d
		if z.walkable(stand, Vector2i.ZERO, FieldMoves.abilities(Game.data)) and z.warp_at(stand).is_empty():
			print("BOT: warping to %s %s to carry on past the soft-lock" % [zone_id, stand])
			await Router.goto_zone(zone_id, stand, GridMotion.facing_from(-d))
			await _settle()
			var ow := _ow()
			ow.player.face(GridMotion.facing_from(-d))
			await ow.interact(npc_pos)
			await _settle()
			return true
	_fail("no tile beside %s in %s to warp to" % [npc_id, zone_id])
	return false

## Trainers who have not been beaten yet walk up and challenge you, so routes may go through them.
func _unbeaten_trainer(def: Dictionary) -> bool:
	var tid := str(def.get("trainer", ""))
	return tid != "" and not Game.data.flag("trainer_" + tid)

func _soft_fail(why: String, fatal: bool) -> bool:
	if fatal:
		_fail(why)
	else:
		print("BOT: gave up: " + why)
	return false

## Where to stand to talk to an NPC: a walkable neighbour, or across a counter.
func _talk_spot(ow: Node, n: Node) -> Dictionary:
	for dir in ["down", "up", "left", "right"]:
		var v := GridMotion.dir_vec(dir)
		var stand: Vector2i = n.grid_pos + v
		if ow.zone.walkable(stand) and not ow.occupied(stand) and ow.zone.warp_at(stand).is_empty():
			return {"stand": stand, "face": GridMotion.facing_from(-v)}
		if ow.zone.tile_at(stand) == "counter":
			var across: Vector2i = stand + v
			if ow.zone.walkable(across) and not ow.occupied(across):
				return {"stand": across, "face": GridMotion.facing_from(-v)}
	return {}

## Walks to a tile. Plans a route once and follows it leg by leg, replanning only when something gets in the
## way (an NPC steps in, a trainer walks up, a whiteout teleports). In full mode long trips take the train.
func _walk_to(zone_id: String, target: Vector2i, fatal := true) -> bool:
	var losses_at_start := int(stats.losses)
	var wander_waits := 0
	var stuck := 0
	var no_route := 0
	if mode == "full" and not _in_rail and Game.data.zone_id != zone_id:
		await _maybe_ferry(zone_id)
		await _maybe_rail(zone_id)
	while not _done:
		await _settle()
		var ow := _ow()
		if Game.data.zone_id == zone_id and ow.player.grid_pos == target:
			return true
		if mode == "full" and int(stats.losses) - losses_at_start >= 2:
			print("BOT: lost twice on the way to %s %s, going back to train" % [zone_id, target])
			_walk_lost = true
			return false
		await _heal_if_low(0.35)
		Pathfinder.abilities = FieldMoves.abilities(Game.data)
		var blocked := {}
		for n in ow.npcs:
			# wanderers step aside, so in full mode only NPCs that stand still are planned round
			if is_instance_valid(n) and n.grid_pos != target and not _unbeaten_trainer(n.def) \
					and (mode != "full" or wander_waits > 3 or str(n.def.get("move", "still")) == "still"):
				blocked[n.grid_pos] = true
		var legs := _plan(zone_id, target, blocked) if mode == "full" else Pathfinder.route(_routing_zones(), Game.data.zone_id, ow.player.grid_pos, zone_id, target, blocked)
		if legs.is_empty() and wander_waits > 3:
			wander_waits = 0  # no way round the wanderers: walk up and wait for them instead
			await _wait(0.5)
			continue
		if legs.is_empty():
			no_route += 1
			if no_route > (20 if fatal else 3):
				if mode == "full" and fatal:
					_no_route = "no route from %s %s to %s %s" % [Game.data.zone_id, ow.player.grid_pos, zone_id, target]
					return false
				return _soft_fail("no route from %s %s to %s %s" % [Game.data.zone_id, ow.player.grid_pos, zone_id, target], fatal)
			await _wait(0.5)
			continue
		no_route = 0
		# follow the legs while the world does what the plan expects
		for leg in legs:
			if _done:
				return false
			ow = _ow()
			if Game.data.zone_id != leg.zone or ow.player.grid_pos != leg.start:
				break
			var deviated := false
			var steps: Array = leg.path.duplicate()
			if leg.exit.kind == "edge":
				steps.append(null)  # the step off the edge
			for p in steps:
				ow = _ow()
				if not ow.player.on_bike and ow.zone.kind != "interior" and FieldMoves.bike_refusal(Game.data, ow.zone, ow.player.wading) == "":
					ow.player.set_bike(true)
				var dir: String = leg.exit.dir if p == null else GridMotion.facing_from(p - ow.player.grid_pos)
				var before: Vector2i = ow.player.grid_pos
				var ok: bool = await ow.player.try_step(dir, true)
				stats.steps += 1
				await _settle()
				await _heal_if_low(0.35)
				ow = _ow()
				if p == null or Game.data.zone_id != leg.zone:
					break  # off the edge, through a door or whited out: the next leg's start check decides
				if not ok or ow.player.grid_pos != p:
					var in_way: Node = ow.npc_at(GridMotion.step(before, dir)) if not ok else null
					if in_way and _unbeaten_trainer(in_way.def):
						# an unbeaten trainer stands in the way (they are planned through): challenge them
						await ow.interact(GridMotion.step(before, dir))
						await _settle()
					elif in_way and str(in_way.def.get("move", "still")) != "still":
						wander_waits += 1  # a wanderer in the way: wait a moment, then try to go round
						stuck += 1
						if stuck > 300:
							return _soft_fail("a wanderer blocks %s in %s heading %s" % [before, Game.data.zone_id, dir], fatal)
						await _wait(1.0)  # game seconds; wanderers take a step every 2 to 5
						if wander_waits % 3 == 0:
							# it may be boxed in by us (a one-tile gap): step back to give it room
							for back in [GridMotion.facing_from(-GridMotion.dir_vec(dir)), "up", "down", "left", "right"]:
								if back != dir and await ow.player.try_step(back, false):
									break
							await _settle()
					elif not ok and Game.data.zone_id == leg.zone and ow.player.grid_pos == before:
						stuck += 1
						if stuck > 30:
							return _soft_fail("blocked repeatedly at %s in %s heading %s" % [before, Game.data.zone_id, dir], fatal)
					deviated = true
					break
				stuck = 0
			if deviated:
				break
	return false

## Walks up and down tall grass until the lead creature reaches `level`. In full mode the grass is picked
## near where the bot stands (see _pick_grind_zone).
func _grind_to(level: int, zone := "") -> void:
	var lead := _strongest()
	if lead == null or _team_level() >= level:
		return
	print("BOT: training the team towards L%d (best %s L%d, team %s)" % [level, lead.display_name(), lead.level, _team_str()])
	var guard := 0
	var grind_zone := zone
	var limit := 30000 if mode == "full" else 4000
	var stall_lv := _team_level()
	var stall_at := 0
	while _team_level() < level and not _done and guard < limit:
		guard += 1
		if _team_level() > stall_lv:
			stall_lv = _team_level()
			stall_at = guard
		elif guard - stall_at > 3000:
			break  # no progress (everyone that can train is at the level cap or can't win here)
		if mode == "full":
			if grind_zone == "" or (guard % 200 == 0 and zone == ""):
				grind_zone = _pick_grind_zone()
			_lead_with_weakest(_area_level(grind_zone))
		else:
			# slice: when levels stop coming (the real-clock weather can favour wilds that outclass the lead),
			# alternate the grind zone and let weaker creatures lead
			var slow := (guard - stall_at) / 300
			_lead_with_weakest(0, 3 * slow)
			if zone == "":
				var hard := _strongest().level >= 9
				grind_zone = "cat_and_fiddle" if hard != (slow % 2 == 1) else "macc_forest"
		var spot := _grass_spot(grind_zone)
		_walk_lost = false
		if not await _walk_to(grind_zone, spot, mode != "full"):
			if not _walk_lost:
				_bad_grind[grind_zone] = true
			grind_zone = ""
			continue
		var ow := _ow()
		for d in ["left", "right"]:
			await _settle()
			await ow.player.try_step(d, false)
			stats.steps += 1
		await _heal_if_low(0.4)
	if guard >= limit:
		print("BOT: gave up training at team level %d (wanted %d), team %s" % [_team_level(), level, _team_str()])

## Mean level of a zone's tall-grass encounters (0 if none).
func _area_level(zid: String) -> int:
	var grass: Array = _routing_zones()[zid].encounters.get("grass", []) if _routing_zones().has(zid) else []
	if grass.is_empty():
		return 0
	var mean := 0.0
	for e in grass:
		mean += (float(e.get("min", 1)) + float(e.get("max", 1))) / 2.0
	return int(mean / grass.size())

## The best place to train from here: tall grass within a few zones, as strong as the team can take.
func _pick_grind_zone() -> String:
	var here := Game.data.zone_id
	var dist := _hops_from(here)
	var cap := _strongest().level + 2
	var best := ""
	var best_score := -9999.0
	for zid in dist:
		if int(dist[zid]) > 5 or _bad_grind.has(zid):
			continue
		var z: ZoneData = _routing_zones()[zid]
		var grass: Array = z.encounters.get("grass", [])
		if grass.is_empty() or zid == "testbed":
			continue
		var mean := 0.0
		for e in grass:
			mean += (float(e.get("min", 1)) + float(e.get("max", 1))) / 2.0
		mean /= grass.size()
		if _grass_spot(zid) == z.spawn and z.tile_at(z.spawn) != "tall_grass":
			_bad_grind[zid] = true
			continue
		var score: float = minf(mean, cap) - 1.5 * int(dist[zid]) - (0.0 if mean <= cap else (mean - cap) * 2.0)
		if score > best_score:
			best_score = score
			best = zid
	if best == "":
		best = "cat_and_fiddle"
	print("BOT: training in %s (from %s)" % [best, here])
	return best

## How strong the team is: the third-best level plus 3 (a lone star doesn't make a team), or the best if there are fewer than 3.
func _team_level() -> int:
	var best := _strongest().level
	# creatures too far behind to train (see _lead_with_weakest) don't hold the team back
	var lv: Array = Game.data.party.filter(func(c): return mode == "full" or c.level >= best - 8).map(func(c): return c.level)
	lv.sort()
	lv.reverse()
	if mode == "full" and lv.size() >= 4:
		# the whole story needs a real team: the mean of the best four (one runaway ace can't carry a Keeper)
		return int(round((lv[0] + lv[1] + lv[2] + lv[3]) / 4.0))
	return lv[0] if lv.size() < 3 else mini(lv[0], lv[2] + 3)

## Like a sensible player: put the lowest-level creature first while training, so the whole team keeps up.
## A creature far below the area's level would just faint, so it never leads more than 8 levels under the best.
## In full mode a creature may also lead if it is no more than 3 levels under the grass it is training in.
func _lead_with_weakest(area_level := 0, slack := 0) -> void:
	var party: Array = Game.data.party
	if party.size() < 2:
		return
	var best := _strongest().level
	var floor_lv := best - 8 - slack
	if mode == "full" and area_level > 0:
		floor_lv = mini(floor_lv, area_level - 3)
	if mode == "full" and party.size() >= 4:
		# train the weakest of the best four, the ones the team level counts
		var lv: Array = party.map(func(c): return c.level)
		lv.sort()
		lv.reverse()
		floor_lv = mini(floor_lv, lv[3])
	var pick := -1
	for i in party.size():
		var c: Creature = party[i]
		if c.is_fainted() or c.level < floor_lv:
			continue
		if pick < 0 or c.level < party[pick].level:
			pick = i
	if pick > 0:
		var c: Creature = party[pick]
		party.remove_at(pick)
		party.insert(0, c)

var _grass_cache := {}

func _grass_spot(zone_id: String) -> Vector2i:
	var key := "%s|%s" % [zone_id, FieldMoves.abilities(Game.data)]
	if not _grass_cache.has(key):
		_grass_cache[key] = _find_grass(zone_id)
	return _grass_cache[key]

func _find_grass(zone_id: String) -> Vector2i:
	var z := ZoneData.load_id(zone_id)
	FieldMoves.apply_cuts(Game.data, z)
	var reach := z.reachable(z.spawn, FieldMoves.abilities(Game.data))  # only grass you can actually walk to
	for y in z.height:
		for x in range(1, z.width - 1):
			var p := Vector2i(x, y)
			if z.tile_at(p) == "tall_grass" and reach.has(p) and reach.has(p + Vector2i(-1, 0)) and reach.has(p + Vector2i(1, 0)):
				return p
	return z.spawn

## Out of battle, top the team up when the lead is low. Counted, since a real player would walk to a Sanctuary.
func _heal_if_low(threshold: float) -> void:
	var lead := Game.data.first_able()
	if lead == null or float(lead.hp) / lead.max_hp() < threshold or Game.data.party.any(func(c): return c.is_fainted()):
		Game.data.heal_party()
		stats.cheat_heals += 1

func _strongest() -> Creature:
	var best: Creature = null
	for c in Game.data.party:
		if best == null or c.level > best.level:
			best = c
	return best

# --- fuzz --------------------------------------------------------------------

func _fuzz() -> void:
	var zones := ZoneData.load_all().keys()
	Game.data.party = [Creature.create(Game.dex.get_species("kindlet"), 12, Game.rng, Game.moves)]
	Game.data.set_flag("starter", "kindlet")
	while not _done:
		await _settle()
		var ow := _ow()
		if _rng.randf() < 0.01:
			var zid: String = zones[_rng.randi() % zones.size()]
			await Router.goto_zone(zid, Vector2i(-1, -1), "down")
			continue
		var d: String = ["up", "down", "left", "right"][_rng.randi() % 4]
		if _rng.randf() < 0.1:
			await ow.interact(GridMotion.step(ow.player.grid_pos, ow.player.facing))
		else:
			await ow.player.try_step(d, _rng.randf() < 0.5)
		stats.steps += 1
		await _heal_if_low(0.3)

# --- autopilot interface (called by dialogue box, router, battle scene) --------

func log_line(_who: String, _text: String) -> void:
	stats.lines += 1

const NO_WORDS := ["not today", "not yet", "no", "no thanks", "no thank you", "maybe later", "later", "leave it", "decline"]

func choose_option(text: String, options: Array) -> int:
	var low: Array = options.map(func(o): return str(o).to_lower().strip_edges().trim_suffix(".").trim_suffix("!"))
	if "carry on" in low:
		# between Moot fights: open the bag once if the team is hurt, then carry on
		if not _bag_opened and (_team_low() or _moot_tries > MOOT_ASSIST_AFTER) and low.has("open your bag"):
			_bag_opened = true
			return low.find("open your bag")
		_bag_opened = false
		return low.find("carry on")
	if mode != "full" or text.begins_with("Sail to") or text.begins_with("Begin the Moot"):
		return 0
	for i in low.size():
		if low[i] in NO_WORDS:
			return i  # skippable optional content: say no
	return 0

func menu_result(menu: String) -> Variant:
	if menu == "starter":
		return ["spikkin", "holtling", "kindlet"][int(Game.args.get("seed", 1)) % 3]
	if menu == "bag":
		_use_bag()
	if menu == "travel:rail":
		_menus_seen.append(menu)
		return _rail_dest if _rail_dest != "" else null
	return null

func choose_action(f: BattleFlow) -> Dictionary:
	_busy_t = 0.0  # a battle asking for a move is not a stuck Router
	var mine := f.battle.current_at(Battle.PLAYER, f.acting_pos) if f.battle.double else f.battle.current(Battle.PLAYER)
	if _assist_fight and f.battle.kind != "wild" and mine and mine.hp * 3 < mine.max_hp():
		mine.hp = mine.max_hp()
		_assisted[_beat_name] = int(_assisted.get(_beat_name, 0)) + 1
	var b := f.battle
	var me := b.current_at(Battle.PLAYER, f.acting_pos) if b.double else b.current(Battle.PLAYER)
	var foe := b.current(Battle.FOE)
	if b.double:
		var standing := b.actives(Battle.FOE)
		if not standing.is_empty():
			foe = standing[0]
	if b.kind != "wild" and f.trainer is Dictionary:
		_fight_id = str(f.trainer.get("id", ""))
	var snare := "iron_snare" if mode == "full" and int(Game.data.bag.get("iron_snare", 0)) > 0 else "wicker_snare"
	var snares := int(Game.data.bag.get(snare, 0))
	var party_cap := MAX_PARTY_FULL if mode == "full" else 4
	if b.kind == "wild" and snares > 0 and Game.data.party.size() < party_cap and foe.hp * 2 < foe.max_hp():
		return {"kind": "item", "item": snare}  # the battle takes the snare out of the bag itself
	# full mode builds a team like a player: a wild creature worth having is worn down gently, not flattened
	var gentle: bool = mode == "full" and b.kind == "wild" and snares > 0 and Game.data.party.size() < party_cap \
		and (Game.data.party.size() < 3 or foe.level >= _strongest().level - 8) and me.hp * 2 > me.max_hp()
	var best := -1
	var best_score := -1.0
	for i in me.moves.size():
		if int(me.moves[i].pp) <= 0:
			continue
		var s := BattleAI.score(b, me, foe, Game.moves.get_move(me.moves[i].id))
		if gentle and s > 0.0:
			s = 1000.0 - s if int(Game.moves.get_move(me.moves[i].id).get("power", 0)) > 0 else -1.0
		if s > best_score:
			best_score = s
			best = i
	var act := {"kind": "fight", "slot": maxi(best, 0)}
	if b.double:
		act["target"] = 0 if b.current_at(Battle.FOE, 0) == foe else 1
	return act

func choose_replacement(f: BattleFlow) -> int:
	var party: Array = f.battle.parties[Battle.PLAYER]
	var best := 0
	var on_field: Array = f.battle.active[Battle.PLAYER] if f.battle.double else []
	for i in party.size():
		if i in on_field:
			continue
		if not party[i].is_fainted() and (party[best].is_fainted() or best in on_field or party[i].hp > party[best].hp):
			best = i
	return best

func choose_forget(c: Creature, move_id: String) -> int:
	var new_power := int(Game.moves.get_move(move_id).get("power", 0))
	var weakest := -1
	var weakest_power := new_power
	for i in c.moves.size():
		var p := int(Game.moves.get_move(c.moves[i].id).get("power", 0))
		if p < weakest_power:
			weakest_power = p
			weakest = i
	return weakest

# --- helpers -------------------------------------------------------------------

func _on_battle_ended(result: Dictionary) -> void:
	if mode != "fuzz" and str(result.get("result", "")) == "lose":
		print("BOT: lost a battle in %s (weather %s)" % [Game.data.zone_id, Router.overworld.weather if Router.overworld else "?"])
	if mode != "fuzz" and _fight_id != "" and KEY_FIGHTS.any(func(k): return _fight_id.begins_with(k)):
		var won := str(result.get("result", "")) == "win"
		if not _fight_losses.has(_fight_id):
			_fight_losses[_fight_id] = 0
			_fight_order.append(_fight_id)
		if not won:
			_fight_losses[_fight_id] += 1
		print("BOT: fight %s result %s team %s" % [_fight_id, "win" if won else "loss", _team_str()])
	_fight_id = ""
	match str(result.get("result", "")):
		"win":
			stats.wins += 1
		"lose":
			stats.losses += 1
		"caught":
			stats.catches += 1

var _menus_seen: Array = []

## Station doors: walking into a station's door opens the ticket office (the rail menu), then steps you back out.
func _doors() -> void:
	Game.data.bag["rail_pass"] = 1
	await Router.goto_zone("manchester", Vector2i(43, 40), "up")
	await _settle()
	var ow := _ow()
	_check(ow.zone.tile_at(Vector2i(43, 39)) == "door", "no station door above 43,40 in manchester")
	ow.player.try_step("up")
	for i in 120:
		await get_tree().process_frame
	_check(_menus_seen.has("travel:rail"), "the station door didn't open the rail menu")
	_check(ow.player.grid_pos == Vector2i(43, 40), "player left at %s, not stepped back out" % ow.player.grid_pos)
	_check(not Router.busy, "Router still busy after the ticket office")
	print("BOT: doors ok, menus %s, player %s" % [_menus_seen, ow.player.grid_pos])

func _ow() -> Node:
	return Router.overworld if Router.overworld and is_instance_valid(Router.overworld) else null

func _npc(id: String) -> Node:
	var ow := _ow()
	for n in ow.npcs:
		if is_instance_valid(n) and n.def.get("id", "") == id:
			return n
	return null

## Waits until nothing is going on (fades, battles, scripts, menus) for a few frames.
func _settle() -> void:
	var calm := 0
	while calm < 3 and not _done:
		await get_tree().process_frame
		var ow := _ow()
		if not Router.busy and ow != null and ow.zone != null and not ow.player.moving:
			calm += 1
		else:
			calm = 0

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _check(cond: bool, why: String) -> void:
	if not cond:
		_fail(why)

func _fail(why: String) -> void:
	if _done:
		return
	failures.append(why)
	_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	Engine.time_scale = 1.0
	var lead := _strongest()
	print("BOT: stats %s, party %s, badges %s, %.0f s" % [stats, Game.data.party.map(func(c): return "%s L%d" % [c.species.id, c.level]), Game.data.badges, _elapsed])
	if mode == "full":
		_print_summary()
	if failures.is_empty():
		print("PLAYTEST PASS")
		get_tree().quit(0)
	else:
		print("PLAYTEST FAIL: " + "; ".join(failures))
		get_tree().quit(1)
