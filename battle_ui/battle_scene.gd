extends Node3D
## The battle scene. Router.battle() instantiates this, calls setup(foe_party, opts) and awaits `finished`.
## All sequencing lives in BattleFlow; this node is its `ui`: it plays events on the diorama and asks for choices.
## opts: kind ("wild"|"trainer"|"keeper"), stage, weather, ai, trainer {name, money, defeat}, music, double (2v2).
## Dev: pass --battle-auto after `--` and the battle plays itself (for screenshots); --battle-caught marks the foe caught.

signal finished(result: Dictionary)

var dio: Diorama
var sky: SkyAndLight
var hud: BattleHUD
var menus: BattleMenus
var msg: BattleMessage
var fx: BattleFX
var flow: BattleFlow
var auto := false
var opts := {}
var _intro_done := false
var _hidden_2d: CanvasItem
var _dev_stage := ""  # --stage=moor overrides the stage (screenshots)
var _dev_catch := false  # --battle-catch: in auto mode, throw snares instead of fighting
var _dev_ask := false  # --battle-ask: in auto mode, still ask the after-catch questions (screenshots)
var _dev_menu := ""  # --battle-menu=fight|bag|team|target|forget opens that menu straight away (screenshots)
var _dev_cursor := -1  # --battle-cursor=N: the remembered cursor for that menu (screenshots)
var _dev_crit := false  # --battle-crit: every hit is a critical one (screenshots of the crit beat)
var _dev_stages := false  # --battle-stages: both leads start with stat stages and a status (screenshots of the plates)
var _scale_before := -1.0  # Engine.time_scale before the battle sped it up (-1: not sped up)

func _ready() -> void:
	apply_speed()
	auto = "--battle-auto" in DevArgs.user_args()
	for a in DevArgs.user_args():
		if a == "--battle-slow":  # quarter speed, to catch a hit mid-flash in a screenshot
			Engine.time_scale = 0.25
		if a == "--battle-catch":
			_dev_catch = true
		if a == "--battle-ask":
			_dev_ask = true
		if a == "--battle-crit":
			_dev_crit = true
		if a == "--battle-stages":
			_dev_stages = true
		if a.begins_with("--stage="):
			_dev_stage = a.get_slice("=", 1)
		if a.begins_with("--battle-menu="):
			_dev_menu = a.get_slice("=", 1)
		if a.begins_with("--battle-cursor="):  # where the move (or bag) cursor starts (screenshots)
			_dev_cursor = int(a.get_slice("=", 1))
	Meshes.materials()
	dio = Diorama.new()
	add_child(dio)
	sky = SkyAndLight.new()
	add_child(sky)
	fx = BattleFX.new()
	add_child(fx)
	fx.dio = dio
	fx.sky = sky
	var post := CanvasLayer.new()
	post.layer = 1
	add_child(post)
	var tilt := ColorRect.new()
	tilt.set_anchors_preset(Control.PRESET_FULL_RECT)
	tilt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://art/shaders/tilt_shift.gdshader")
	tilt.material = mat
	tilt.visible = Settings.quality != "low"
	post.add_child(tilt)
	var ui := CanvasLayer.new()
	ui.layer = 2
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = load("res://ui/theme.tres")
	ui.add_child(root)
	hud = BattleHUD.new()
	root.add_child(hud)
	fx.hud = hud
	msg = BattleMessage.new()
	root.add_child(msg)
	menus = BattleMenus.new()
	root.add_child(menus)
	menus.opened.connect(msg.make_room)
	menus.closed.connect(msg.make_room.bind(Rect2()))
	if _dev_cursor >= 0:
		menus.remember("bag" if _dev_menu == "bag" else "moves", _dev_cursor)

## The player's battle speed setting: everything in the battle (animations, pauses, text) runs faster.
func apply_speed() -> void:
	if _scale_before < 0.0:
		_scale_before = Engine.time_scale
	Engine.time_scale = Settings.battle_time_scale()

## Back to normal time. Safe to call more than once; _exit_tree calls it too, so no exit path can leave it fast.
func restore_speed() -> void:
	if _scale_before >= 0.0:
		Engine.time_scale = _scale_before
		_scale_before = -1.0

func _exit_tree() -> void:
	restore_speed()
	if _hidden_2d and is_instance_valid(_hidden_2d):
		_hidden_2d.show()

func setup(foe_party: Array, p_opts: Dictionary) -> void:
	# Started from a 2D screen (the title, via --battle): hide it. The overworld is hidden by Router.
	var cs := get_tree().current_scene
	if cs is CanvasItem and cs != self:
		_hidden_2d = cs
		cs.hide()
	opts = p_opts.duplicate()
	if _dev_catch and not foe_party.is_empty():
		foe_party[0].hp = 1
	if "--battle-caught" in DevArgs.user_args():  # screenshots: the foe counts as caught (mark and type hints)
		for c in foe_party:
			Game.data.mark_caught(c.species.id)
	opts["time"] = opts.get("time", Game.phase())
	if bool(opts.get("double", false)):
		dio.set_double(true)
		hud.set_double(true)
	dio.build(_dev_stage if _dev_stage != "" else str(opts.get("stage", "grass")))
	sky.set_weather(str(opts.get("weather", "clear")), dio.is_interior())
	hud.set_weather(str(opts.get("weather", "clear")), 0)
	sky.follow = dio
	dio.camera.environment = sky.env
	_warm_cries(foe_party)
	flow = BattleFlow.new(Game.data, Game.dex, Game.moves, Game.chart, Game.items, Game.rng, foe_party, opts, self)
	if _dev_crit:
		flow.battle.rng = DevCritRng.new(Game.rng)
	flow.species_caught.connect(func(id: String): Bus.creature_caught.emit(id))
	_run()

## Cries are synthesised the first time they are needed: the leads now (the screen is still dark), the rest
## of both teams one a frame after, so a switch-in later never waits on one.
func _warm_cries(foe_party: Array) -> void:
	var rest: Array = []
	for team in [foe_party, Game.data.party]:
		for i in team.size():
			if i < 2:
				Cries.stream_for(team[i].species)
			else:
				rest.append(team[i].species)
	for sp in rest:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		Cries.stream_for(sp)

func _run() -> void:
	var result: Dictionary = await flow.run()
	if auto:
		print("battle result: ", result.result, " | log: ", " / ".join(flow.log))
	await get_tree().create_timer(0.35).timeout
	if str(result.get("result", "")) in ["win", "caught"]:
		Audio.play_music("victory", 0.2)
		await _wait(1.5)
	restore_speed()  # the fade back to the overworld (or the whiteout) runs at normal speed
	finished.emit(result)

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

# --- the flow's ui interface --------------------------------------------------------

func intro(f: BattleFlow) -> void:
	Audio.play_music(AudioIds.battle_music(opts))
	dio.intro_swoop()
	for side in [Battle.FOE, Battle.PLAYER]:
		for pos in f.battle.positions():
			var c := f.battle.current_at(side, pos)
			if c == null:
				continue
			var a := dio.actor(side, pos)
			a.show_creature(c, side == Battle.PLAYER)
			hud.set_creature(side, c, pos)
			_mark_caught(f, side, c, pos)
			a.pop_in()
			Audio.cry(c.species)
			if c.variant != "":
				Audio.sfx("harp_gliss")  # an uncommon coat glints as it appears
		await _wait(0.7 if side == Battle.FOE else 0.9)
	_intro_done = true
	if _dev_stages:
		var me := f.battle.current(Battle.PLAYER)
		var foe := f.battle.current(Battle.FOE)
		me.change_stage("atk", 2)
		me.change_stage("spd", -1)
		foe.change_stage("def", -1)
		foe.status = "soaked"
		_sync_hud(f.battle)

## Dev: a crit chance (the only roll between 4% and 25%) always comes up; every other roll is the game's own.
class DevCritRng extends Rng:
	var base: Rng
	func _init(b: Rng) -> void:
		base = b
	func roll() -> float:
		return base.roll()
	func roll_int(a: int, b: int) -> int:
		return base.roll_int(a, b)
	func roll_range(a: float, b: float) -> float:
		return base.roll_range(a, b)
	func chance(percent: float) -> bool:
		return true if percent > 4.0 and percent < 25.0 else base.chance(percent)
	func pick(arr: Array):
		return base.pick(arr)

## A wild foe the player already owns gets a little snare mark on its plate.
func _mark_caught(f: BattleFlow, side: int, c: Creature, pos: int) -> void:
	hud.set_caught(side, side == Battle.FOE and f.is_wild() and f.is_caught_species(str(c.species.id)), pos)

func say(lines: Array, hold := 0.0) -> void:
	hud.refresh_names()
	for l in lines:
		await msg.say(str(l), hold)

func play_events(events: Array, ctx: Dictionary) -> void:
	var b: Battle = ctx.battle
	for ev in events:
		var cue := EventPlayer.fx_for(ev, ctx)
		var lines := EventPlayer.lines_for(ev, ctx)
		if ev.type == "catch" and cue.cue == "catch" and lines.size() > 1:
			await msg.say(lines[0])
			await fx.play(cue, b)
			for i in range(1, lines.size()):
				await msg.say(lines[i])
			continue
		hud.on_event(ev)  # stat pills, the crit flash, damage numbers
		var flag := [true]
		_cue_task(cue, b, flag)
		for l in lines:
			await msg.say(l)
		if not auto and (ev.type == "no_effect" or (ev.type == "damage" and float(ev.get("effectiveness", 1.0)) != 1.0)):
			var tip := Intros.take(Game.data, "types", Settings.hints)  # the first hit that lands hard or soft: one line on types
			if tip != "":
				await msg.say(tip, 1.5)
		while flag[0]:
			await get_tree().process_frame
	_sync_hud(b)
	if not b.over:
		dio.swoop_home()

func _cue_task(cue: Dictionary, b: Battle, flag: Array) -> void:
	await fx.play(cue, b)
	flag[0] = false

func _sync_hud(b: Battle) -> void:
	hud.sync(b)

func choose_action(f: BattleFlow) -> Dictionary:
	if Engine.has_meta("autopilot"):
		await _wait(0.1)
		return Engine.get_meta("autopilot").choose_action(f)
	var b := f.battle
	var me := b.current_at(Battle.PLAYER, f.acting_pos)
	menus.chart_arg = TypeChartScreen.scope_arg(f.foe_views(), [{"name": me.display_name(), "types": me.types()}])
	if not auto:  # the first battle of each kind says what it is about, once (the Hints setting)
		var tip := Intros.take(Game.data, "battle_wild" if b.kind == "wild" else "battle_keeper", Settings.hints)
		if tip != "":
			await msg.say(tip, 1.5)
	while true:
		msg.prompt("What will %s do?" % me.display_name())
		if auto:
			await _wait(0.9)
			if _dev_catch:
				Game.data.bag["wicker_snare"] = maxi(3, int(Game.data.bag.get("wicker_snare", 0)))
				return {"kind": "item", "item": "wicker_snare"}
			var best := 0
			var power := -1
			for i in me.moves.size():
				var p := int(Game.moves.get_move(me.moves[i].id).get("power", 0))
				if p > power and int(me.moves[i].pp) > 0:
					power = p
					best = i
			return {"kind": "fight", "slot": best, "target": f.default_target()}
		var cmd := ""
		if _dev_menu == "target":  # straight to the target picker with the first move (screenshots)
			_dev_menu = ""
			var aim := await _pick_target(f, 0)
			if aim >= 0:
				return {"kind": "fight", "slot": 0, "target": aim}
			continue
		if _dev_menu == "forget":  # the learn-a-move prompt (screenshots)
			_dev_menu = ""
			await menus.forget(me, "will_o_wisp", Game.moves)
			continue
		if _dev_menu != "":
			cmd = _dev_menu
			_dev_menu = ""
			if Game.data.bag.is_empty():
				Game.data.bag.merge({"cup_of_tea": 3, "wicker_snare": 5, "smelling_salts": 1})
			if Game.data.party.size() < 3:
				Game.data.party.append(Creature.create(Game.dex.get_species("holtling"), 8, Game.rng, Game.moves))
				Game.data.party[1].take_damage(9)
				Game.data.party.append(Creature.create(Game.dex.get_species("spikkin"), 6, Game.rng, Game.moves))
				Game.data.party[2].hp = 0
		else:
			cmd = await menus.command(f.is_wild())
		match cmd:
			"fight":
				var slot := await menus.moves(me, Game.moves, func(i: int) -> Array: return f.move_hint(me, i), b.weather, Game.chart)
				if slot < 0:
					continue
				if not b.double:
					return {"kind": "fight", "slot": slot}
				var aim := await _pick_target(f, slot)
				if aim >= 0:
					return {"kind": "fight", "slot": slot, "target": aim}
			"bag":
				var entries := f.battle_items()
				if entries.is_empty():
					await msg.say(f.empty_bag_text())
					continue
				var i := await menus.bag(entries)
				if i < 0:
					continue
				var e: Dictionary = entries[i]
				if e.kind == "snare":
					return {"kind": "item", "item": e.id}
				var t := await menus.party(b.parties[Battle.PLAYER], b.active[Battle.PLAYER], "item", Game.items.get_item(e.id))
				if t >= 0:
					return {"kind": "item", "item": e.id, "target": t}
			"team":
				var s := await menus.party(b.parties[Battle.PLAYER], b.active[Battle.PLAYER], "switch", {}, Game.moves, f.foe_views(), Game.chart)
				if s >= 0:
					return {"kind": "switch", "index": s}
			"run":
				return {"kind": "run"}
	return {}

## Doubles: ask which foe to aim the move in `slot` at, marking the highlighted one on the diorama and HUD.
## No question when only one foe stands or the move hits both. Returns the foe position, or -1 if cancelled.
func _pick_target(f: BattleFlow, slot: int) -> int:
	var b := f.battle
	var me := b.current_at(Battle.PLAYER, f.acting_pos)
	var mv := Game.moves.get_move(str(me.moves[slot].id)) if slot < me.moves.size() else {}
	var names := []
	for pos in b.positions():
		var c := b.current_at(Battle.FOE, pos)
		names.append(c.display_name() if c != null and not c.is_fainted() else "")
	if str(mv.get("target", "")) == "all_foes" or names.count("") > 0:
		return f.default_target()
	msg.prompt("Aim %s at which one?" % str(mv.get("name", "it")))
	var mark := func(i: int) -> void:
		for pos in b.positions():
			dio.actor(Battle.FOE, pos).set_marked(pos == i)
			hud.set_marked(Battle.FOE, pos, pos == i)
	menus.cursor_moved.connect(mark)
	var aim := await menus.target(names)
	menus.cursor_moved.disconnect(mark)
	mark.call(-1)
	return aim

func choose_replacement(f: BattleFlow) -> int:
	if Engine.has_meta("autopilot"):
		return Engine.get_meta("autopilot").choose_replacement(f)
	var b := f.battle
	var party: Array = b.parties[Battle.PLAYER]
	if auto:
		for i in party.size():
			if not party[i].is_fainted() and i not in b.active[Battle.PLAYER]:
				return i
	msg.prompt("Who will you send out next?")
	var r := -1
	while r < 0:
		r = await menus.party(party, b.active[Battle.PLAYER], "forced", {}, Game.moves, f.foe_views(), Game.chart)
	return r

func choose_forget(c: Creature, move_id: String, _f: BattleFlow) -> int:
	if Engine.has_meta("autopilot"):
		return Engine.get_meta("autopilot").choose_forget(c, move_id)
	if auto:
		return -1
	msg.prompt("%s is trying to learn a new move." % c.display_name())
	return await menus.forget(c, move_id, Game.moves)

## First time this species is caught: the Fieldbook popup with its real-world fact.
func first_catch(c: Creature) -> void:
	if Engine.has_meta("autopilot"):
		return
	await PediaPopup.show_for(self, c.species.id)

## After a catch: "Give it a nickname?" Yes opens the name entry on `target` ("nickname:<i>" or
## "nickname:ark:<i>", wherever the catch landed), which names the creature in place.
func ask_nickname(c: Creature, target: String) -> void:
	if Engine.has_meta("autopilot") or (auto and not _dev_ask):
		return
	msg.prompt("Give %s a nickname?" % c.species.name)
	var yes: bool = await menus.yes_no()
	msg.clear()
	if yes:
		await Router.open_menu("name:" + target)

## After a catch with a full team: the team slot to swap with (that creature goes to the Ark), or -1 to send
## the newcomer to the Ark.
func catch_destination(c: Creature, party: Array) -> int:
	if Engine.has_meta("autopilot") or (auto and not _dev_ask):
		return -1
	while true:
		msg.prompt("Your team is full. What about %s?" % c.display_name())
		if await menus.catch_destination() != 0:
			return -1
		msg.prompt("Swap %s in for who? They'll wait in the Ark." % c.display_name())
		var i: int = await menus.party(party, -1, "swap")
		if i >= 0:
			return i
	return -1

func xp_gained(c: Creature, evs: Array) -> void:
	Audio.sfx("xp")
	await hud.animate_xp(c, evs)
	if evs.any(func(e): return e.type == "level_up"):
		Audio.sfx("level_up")
		var a := dio.actor(Battle.PLAYER, _field_pos(c))
		fx.burst(a.global_position + Vector3(0, 0.4, 0), Color("ffe08a"), 28, 3.5, 0.18, 1.0, 1.0, Vector3.UP)

## Where a player creature stands on the field (0 if it is not out).
func _field_pos(c: Creature) -> int:
	var b := flow.battle
	return maxi(0, b.active[Battle.PLAYER].find(b.parties[Battle.PLAYER].find(c)))

## The evolution sequence: the sprite flickers between old and new, faster and faster. Cancel stops it.
func evolve_anim(c: Creature, to_sp: Dictionary) -> bool:
	var pos := _field_pos(c)
	var a := dio.actor(Battle.PLAYER, pos)
	var active := flow.battle.current_at(Battle.PLAYER, pos)
	var old_tex := CreatureArt.texture(c.species, true)
	var new_tex := CreatureArt.texture(to_sp, true)
	a.show_creature(c, true)
	dio.swoop(a.global_position + Vector3(0, 1.1, 0), 6.5, -0.2, 14.0, 0.6)
	Audio.sfx("evolve")
	var cancelled := false
	var delay := 0.32
	var gentle := Settings.reduce_flashing  # a few slow, soft swaps instead of a speeding-up strobe
	var glow := Color(1.4, 1.4, 1.5) if gentle else Color(3.2, 3.2, 3.6)
	if gentle:
		delay = 0.6
	for i in (6 if gentle else 14):
		a.sprite.texture = new_tex if i % 2 == 0 else old_tex
		a.fit_sheet()
		a.sprite.modulate = glow if i % 2 == 0 else Color(1.12, 1.12, 1.12)
		fx.burst(a.global_position + Vector3(0, 1.1, 0), Color("fff6c0"), 6, 2.0, 0.12, 0.5, 0.5)
		await _wait(delay)
		delay = delay if gentle else maxf(0.07, delay * 0.82)
		if not auto and (Input.is_action_pressed("cancel") or Input.is_action_pressed("ui_cancel")):
			cancelled = true
			break
	if cancelled:
		a.show_creature(active, true)
		dio.swoop_home()
		return false
	a.sprite.texture = new_tex
	a.fit_sheet()
	a.sprite.modulate = glow
	fx.burst(a.global_position + Vector3(0, 1.1, 0), Color("ffe9a0"), 40, 5.0, 0.2, 1.0, -2.0)
	create_tween().tween_property(a.sprite, "modulate", Color(1.12, 1.12, 1.12), 0.5)
	await _wait(0.6)
	if c != active:
		a.show_creature(active, true)
	dio.swoop_home()
	return true
