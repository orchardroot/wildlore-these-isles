extends TestCase
## The battle plays a turn back after the Battle has worked all of it out, so anything a name plate read from a
## creature during playback would show the end of the turn early: a bar dropping before the hit lands, a status
## chip before the move that causes it. These play hundreds of real turns back through the real HUD the way
## BattleScene.play_events does (hud.on_event as each event starts, then its cue's BattleFX.plates) and check that
## a plate only changes on an event about that creature, to the value the event carries, and that every plate
## already matches its creature when the batch is over (the end-of-batch sync is a safety net, never the fix).

const CHARMS := ["", "", "", "thistle_brooch", "shamrock_pin", "horseshoe", "brigid_cross", "oak_acorn"]
const ITEMS := ["cup_of_tea", "flask_of_tea", "smelling_salts", "kendal_mint_cake"]
const STATUSES := ["stung", "hexed", "muddled", "asleep", "soaked"]
## Moves that reach every playback path: drain, recoil, multi-hit, self-heal, team cure, weather, status, stats.
const MOVES := ["whisper", "fog_lure", "chimney_crash", "pit_pony_charge", "brine_spray", "chatter",
	"sing_the_wellerman", "put_the_kettle_on", "lavender_bag", "mizzle", "red_sky_at_night", "drystone_dyke",
	"glare", "bluster", "smoulder", "swoop", "mums_look", "hoot_lullaby", "sea_fret", "scrap", "updraught",
	"kestrel_dive", "bramble_lash", "quick_nip"]

var items := ItemDB.load_default()
var seen := {}  # what the runs covered: event types, plus "charm+hp", "knack+other" and so on
var broke := false  # one report per battle is plenty
var batch: Array = []  # the events being played, for the report

class Run:
	var b: Battle
	var hud: BattleHUD
	var fx: BattleFX
	var ctx: Dictionary
	var label := ""

func test_singles_play_back_in_step() -> void:
	for i in 70:
		_battle(i, false, "wild" if i % 2 == 0 else "trainer")
	for k in ["damage", "self_hit", "status_damage", "recoil", "heal", "item", "item+bench", "switch", "faint",
			"status", "status_cured", "stat", "cure_team", "weather", "charm+hp", "charm+other", "knack+other", "catch", "run"]:
		assert_true(seen.has(k), "the singles runs played a %s" % k)

func test_doubles_play_back_in_step() -> void:
	for i in 50:
		_battle(1000 + i, true, "trainer")
	for k in ["damage", "recoil", "heal", "item", "switch", "faint", "status", "status_cured", "stat", "cure_team",
			"charm+other", "knack+other", "spread"]:
		assert_true(seen.has(k), "the doubles runs played a %s" % k)

## The case the switch fix was for, and its item twin: a turn that changes a creature after the event that shows it.
func test_item_then_hit_drains_from_the_healed_bar() -> void:
	var me := Fixtures.creature("kindlet", 10)
	me.take_damage(15)
	var foe := Fixtures.creature("spikkin", 12)
	foe.moves = [foe.make_move_slot("scrap", Fixtures.moves())]
	var r := _run(Fixtures.battle([me], [foe], {"item_db": items, "kind": "trainer"}), "item then hit")
	var ev := r.b.take_turn({"type": "item", "item": "cup_of_tea", "target": 0}, {"type": "move", "slot": 0})
	r.hud.on_event(ev[0])
	r.fx.plates(EventPlayer.fx_for(ev[0], r.ctx), r.b)
	assert_eq(r.hud.target_hp(Battle.PLAYER), float(ev[0].hp), "the tea shows the tea, not the hit still to come")
	assert_true(r.hud.target_hp(Battle.PLAYER) > me.hp, "the hit has not landed yet")
	_play(r, ev.slice(1))
	assert_eq(r.hud.target_hp(Battle.PLAYER), float(me.hp))
	_free(r)

func test_switch_in_shows_its_status_as_it_came_in() -> void:
	var bench := Fixtures.creature("holtling", 40)
	var foe := Fixtures.creature("kindlet", 12)
	foe.moves = [foe.make_move_slot("swoop", Fixtures.moves())]  # stings
	var r := _run(Fixtures.battle([Fixtures.creature("spikkin", 40), bench], [foe], {"kind": "trainer", "rng": Rng.new(3)}), "switch then sting")
	var ev := []
	for t in 20:  # until a sting lands on the newcomer the turn it comes in
		ev = r.b.take_turn({"type": "switch", "index": 1 - r.b.active[Battle.PLAYER][0]}, {"type": "move", "slot": 0})
		if ev[0].type == "switch" and ev.any(func(e): return e.type == "status"):
			break
		_play(r, ev)
		ev = []
	assert_false(ev.is_empty(), "a sting landed on a switch-in")
	if not ev.is_empty():
		r.fx.plates(EventPlayer.fx_for(ev[0], r.ctx), r.b)
		assert_eq(r.hud.plate(Battle.PLAYER).status, "", "the chip comes with the sting, not with the switch")
		assert_eq(r.b.current(Battle.PLAYER).status, "stung", "though the creature is stung by the end of the turn")
	_free(r)

func test_level_up_grows_the_bar_without_a_dip() -> void:
	var hud := _hud()
	var c := Fixtures.creature("kindlet", 10)
	c.take_damage(10)
	hud.set_creature(Battle.PLAYER, c)
	var p := hud.plate(Battle.PLAYER)
	var before: float = p.hp_bar.value
	Progression.gain_xp(c, Rules.xp_for_level(c.species.growth, 11) - c.xp, Fixtures.moves())
	assert_eq(c.level, 11)
	p.refresh_stats()
	assert_true(p.hp_bar.value >= before - 0.0001, "the new maximum does not land before the HP it brought")
	assert_eq(p.hp_to, float(c.hp))
	assert_eq(p.level_l.text, "Lv 11")
	hud.free()

func test_sync_never_cuts_a_drain_short() -> void:
	var hud := _hud()
	var c := Fixtures.creature("kindlet", 10)
	var b := Fixtures.battle([c], [Fixtures.creature("spikkin", 5)])
	hud.set_creature(Battle.PLAYER, c)
	hud.set_creature(Battle.FOE, b.current(Battle.FOE))
	var p := hud.plate(Battle.PLAYER)
	c.take_damage(9)
	p.hp_to = c.hp  # a hit's drain on its way down, part done
	p.hp_shown = c.hp + 4.0
	hud.sync(b)
	assert_eq(p.hp_shown, c.hp + 4.0, "the hit's own drain carries on: sync leaves a bar that is on its way alone")
	hud.free()

## A HUD out of the tree, as in the playback runs: no tweens, a bar is simply where it was sent.
func _hud() -> BattleHUD:
	var hud := BattleHUD.new()
	hud._ready()
	return hud

# --- the driver ---------------------------------------------------------------------------------------------

func _battle(seed_value: int, double: bool, kind: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mine := []
	var theirs := []
	for i in (3 if double else 2) + rng.randi() % 2:
		mine.append(_creature(rng))
	for i in (2 if double else 1) + (rng.randi() % 2 if kind == "trainer" else 0):
		theirs.append(_creature(rng))
		if kind == "trainer" and rng.randf() < 0.5:
			theirs[-1].set_meta(TrainerParty.TEA, "cup_of_tea")  # a keeper's one tea
	var b := Fixtures.battle(mine, theirs, {"item_db": items, "kind": kind, "double": double, "rng": Rng.new(seed_value)})
	var r := _run(b, "%s %s seed %d" % ["doubles" if double else "singles", kind, seed_value])
	broke = false
	_play(r, b.opening)
	for turn in 30:
		if b.over or broke:
			break
		var pa: Variant = _actions(r, Battle.PLAYER, rng)
		var fa: Variant = BattleAI.choose(b, Battle.FOE, "trainer")
		_play(r, b.take_turn(pa, fa))
		for side in [Battle.PLAYER, Battle.FOE]:
			for pos in b.positions():
				if b.needs_switch_at(side, pos):
					var ev := b.force_switch(side, b._reserve(side), pos)
					_play(r, ev)
	_free(r)

func _creature(rng: RandomNumberGenerator) -> Creature:
	var ids: Array = Fixtures.dex().core_ids()
	var c := Creature.create(Fixtures.dex().get_species(ids[rng.randi() % ids.size()]), rng.randi_range(6, 30), Rng.new(rng.randi()), Fixtures.moves())
	if rng.randf() < 0.7:  # most get moves that reach the rarer paths; the rest keep their own
		c.moves = []
		for i in 4:
			c.moves.append(c.make_move_slot(MOVES[rng.randi() % MOVES.size()], Fixtures.moves()))
	c.held = CHARMS[rng.randi() % CHARMS.size()]
	if rng.randf() < 0.3:
		c.take_damage(c.max_hp() / 2)
	if rng.randf() < 0.2:
		c.status = STATUSES[rng.randi() % STATUSES.size()]
		c.status_turns = 2
	return c

func _actions(r: Run, side: int, rng: RandomNumberGenerator) -> Variant:
	if not r.b.double:
		return _action(r, side, 0, rng)
	var out := []
	for pos in r.b.positions():
		var c := r.b.current_at(side, pos)
		out.append({} if c == null or c.is_fainted() else _action(r, side, pos, rng))
	return out

func _action(r: Run, side: int, pos: int, rng: RandomNumberGenerator) -> Dictionary:
	var b := r.b
	var me := b.current_at(side, pos)
	var party: Array = b.parties[side]
	var roll := rng.randf()
	if roll < 0.14:
		return {"type": "item", "item": ITEMS[rng.randi() % ITEMS.size()], "target": rng.randi() % party.size()}
	if roll < 0.22:
		for i in party.size():
			if i not in b.active[side] and not party[i].is_fainted():
				return {"type": "switch", "index": i}
	if not b.double and b.kind == "wild":
		if roll < 0.26:
			return {"type": "catch", "snare": "wicker"}
		if roll < 0.28:
			return {"type": "run"}
	return {"type": "move", "slot": rng.randi() % maxi(1, me.moves.size()), "target": rng.randi() % 2}

func _run(b: Battle, label: String) -> Run:
	var r := Run.new()
	r.b = b
	r.label = label
	r.hud = BattleHUD.new()
	r.hud._ready()
	r.hud.set_double(b.double)
	r.fx = BattleFX.new()
	r.fx.hud = r.hud
	r.ctx = EventPlayer.make_ctx(b, {"name": "Keeper Test"})
	for side in [Battle.FOE, Battle.PLAYER]:  # as BattleScene.intro does
		for pos in b.positions():
			var c := b.current_at(side, pos)
			if c != null:
				r.hud.set_creature(side, c, pos)
	return r

func _free(r: Run) -> void:
	r.hud.free()
	r.fx.free()

# --- playback and the checks ------------------------------------------------------------------------------

func _play(r: Run, events: Array) -> void:
	batch = events
	for ev in events:
		if broke:
			return
		_note(ev, r)
		var before := _snap(r)
		var cue := EventPlayer.fx_for(ev, r.ctx)
		r.hud.on_event(ev)  # BattleScene.play_events: as the event starts
		r.fx.plates(cue, r.b)  # BattleFX.play: at the cue's moment of contact
		_check_event(r, ev, cue, before, _snap(r))
	if not broke:
		_check_matches(r)

func _note(ev: Dictionary, r: Run) -> void:
	var t := str(ev.type)
	seen[t] = true
	if t in ["charm", "knack"]:
		seen[t + ("+other" if ev.has("other_side") else ("+hp" if ev.has("hp") else ""))] = true
	if t == "item" and int(ev.get("target", -1)) not in r.b.active[Battle.PLAYER]:
		seen["item+bench"] = true
	if t == "move" and bool(ev.get("spread", false)):
		seen["spread"] = true

func _snap(r: Run) -> Dictionary:
	var out := {}
	for side in 2:
		for pos in r.b.positions():
			var p := r.hud.plate(side, pos)
			out["%d:%d" % [side, pos]] = {"c": p.creature, "hp": p.hp_to, "status": p.status, "stages": p.stage_row.stages.duplicate()}
	return out

## Which plate fields this event may change: {"side:pos": [field, ...]}, from the event and its cue alone.
func _allowed(r: Run, ev: Dictionary, cue: Dictionary) -> Dictionary:
	var ok := {}
	var side := int(cue.get("side", 0))
	var pos := int(cue.get("pos", 0))
	match str(cue.cue):
		"hit":
			ok["%d:%d" % [side, pos]] = ["hp"]
		"heal":
			var at := BattleFX.heal_pos(cue, r.b)
			if at >= 0:
				ok["%d:%d" % [side, at]] = ["hp", "status"]
		"status":
			ok["%d:%d" % [side, pos]] = ["status"]
		"cure":
			for p in cue.get("team", [pos]):
				ok["%d:%d" % [side, int(p)]] = ["status"]
		"switch":
			ok["%d:%d" % [side, pos]] = ["c", "hp", "status", "stages"]
	if ev.has("stat") and ev.has("delta") and not ev.has("other_side") and str(ev.type) in ["stat", "charm", "knack", "bond"]:
		var k := "%d:%d" % [int(ev.side), int(ev.get("pos", 0))]
		ok[k] = ok.get(k, []) + ["stages"]
	return ok

func _check_event(r: Run, ev: Dictionary, cue: Dictionary, before: Dictionary, after: Dictionary) -> void:
	var ok := _allowed(r, ev, cue)
	for k in after:
		for field in ["c", "hp", "status", "stages"]:
			if after[k][field] != before[k][field] and field not in ok.get(k, []):
				_broke(r, "plate %s %s went %s -> %s on a %s event %s" % [k, field, _show(before[k][field]), _show(after[k][field]), ev.type, ev])
				return
	var k := "%d:%d" % [int(cue.get("side", 0)), int(cue.get("pos", 0))]
	match str(cue.cue):
		"hit":
			if after[k].hp != float(cue.hp):
				_broke(r, "a hit on %s shows %s, not the event's %s" % [k, after[k].hp, cue.hp])
		"switch":
			var c: Creature = r.b.parties[int(cue.side)][int(cue.index)]
			if after[k].c != c or after[k].hp != float(ev.hp) or after[k].status != str(ev.status) or not after[k].stages.is_empty():
				_broke(r, "a switch-in on %s shows %s, not hp %s status '%s'" % [k, after[k], ev.hp, ev.status])

## Once a batch has played, every plate on the field shows its creature as the Battle left it.
func _check_matches(r: Run) -> void:
	for side in 2:
		for pos in r.b.positions():
			var c := r.b.current_at(side, pos)
			if c == null:
				continue
			var p := r.hud.plate(side, pos)
			var stages := {}
			for s in c.stages:
				if int(c.stages[s]) != 0:
					stages[s] = int(c.stages[s])
			if p.creature != c:
				_broke(r, "plate %d:%d shows %s, the field has %s" % [side, pos, p.creature.display_name(), c.display_name()])
			elif p.hp_to != float(c.hp) and not (side == Battle.FOE and r.b.caught != null):
				_broke(r, "plate %d:%d ends on %s HP, %s has %d" % [side, pos, p.hp_to, c.display_name(), c.hp])
			elif p.status != c.status:
				_broke(r, "plate %d:%d ends on status '%s', %s is '%s'" % [side, pos, p.status, c.display_name(), c.status])
			elif p.stage_row.stages != stages:
				_broke(r, "plate %d:%d ends on stages %s, %s has %s" % [side, pos, p.stage_row.stages, c.display_name(), stages])

func _show(v) -> String:
	return v.display_name() if v is Creature else str(v)

func _broke(r: Run, msg: String) -> void:
	broke = true
	fail("%s: %s\n  the batch: %s" % [r.label, msg, "\n    ".join(batch.map(func(e): return str(e)))])
