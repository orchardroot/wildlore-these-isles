class_name Npc
extends Node3D
## A character on the grid. Stands, wanders or paces, talks, and (if a trainer) spots the player and challenges them.
## `interact` and trainer challenges hand the actual conversation to ScriptRunner and return straight away:
## a whiteout rebuilds the zone and frees every NPC, so nothing here may wait on a run.
## Idle life: a still townsperson glances about now and then and turns to look at the player passing close by.
## An optional `"routine"` (core/routines.gd) moves them between spots in the zone by weekday, hour and season.
## An optional `"times": ["dawn", "day", "dusk", "night"]` keeps hours: they are only out in those phases.
## Close to the player they may wear a bubble (NpcBubble: an errand, a Regular's heart, a child spotting your
## follower), and outdoors in drizzle or a downpour they put an umbrella up.

const STEP_SPEED := 3.0      # tiles per second
const NOTICE_RANGE := 2      # tiles: a still NPC turns to look at the player this close
const REACT_EVERY := 0.35    # seconds between looks at bubbles and umbrella (never per frame)
const BUBBLE_Y := 1.95
const BROLLY_Y := 1.7
const SCHEDULE_FAR := 9      # tiles: someone coming out or going home only does it out of the player's sight

static var _dev_talk_done := false

var def: Dictionary = {}
var grid_pos := Vector2i.ZERO
var facing := "down"
var sprite: CharSprite
var ow: Node
var home := Vector2i.ZERO

var _mode := "still"
var _timer := 3.0
var _stepping := false
var _talking := false
var _challenging := false
var _pace_dirs: Array = []
var _pace_i := 0
var _rest := "down"          # the way a still NPC stands when nothing has caught their eye
var _looking := false        # turned away from `_rest` by idle life
var _look_t := 0.0           # seconds until turning back to `_rest`
var _glance_t := 6.0         # seconds until the next idle glance
var _react_t := 0.0          # seconds until bubbles and umbrella are looked at again
var _bubble: Sprite3D
var _bubble_kind := ""
var _bubble_tween: Tween
var _umbrella: Node3D
var _spot_left := 0.0        # seconds the sparkle still has to show
var _spot_cool := 0.0        # seconds before this child notices the follower again

func setup(d: Dictionary, overworld: Node) -> void:
	def = d
	ow = overworld
	grid_pos = Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))
	home = grid_pos
	facing = str(d.get("facing", "down"))
	_rest = facing
	_glance_t = randf_range(4.0, 10.0)
	_mode = str(d.get("move", "still"))
	sprite = CharSprite.new()
	add_child(sprite)
	sprite.setup(str(d.get("sprite", "")))
	sprite.set_facing(facing)
	position = Vector3(grid_pos.x + 0.5, ow.ground_y(grid_pos), grid_pos.y + 0.5)
	_timer = randf_range(2.0, 5.0)
	_react_t = randf_range(0.0, REACT_EVERY)
	if _mode == "pace":
		_build_pace()
	_dev_talk()

func _build_pace() -> void:
	var path: Array = def.get("path", [])
	if path.is_empty():
		path = [facing, facing, facing]
	_pace_dirs = path.duplicate()
	var back := path.duplicate()
	back.reverse()
	for d in back:
		_pace_dirs.append(_opposite(str(d)))

static func _opposite(d: String) -> String:
	return {"up": "down", "down": "up", "left": "right", "right": "left"}.get(d, d)

func face(dir: String) -> void:
	facing = dir
	_rest = dir
	_looking = false
	sprite.set_facing(dir)

## Turn without changing the way they normally stand (idle glances, looking at the player).
func _turn(dir: String) -> void:
	facing = dir
	sprite.set_facing(dir)

## Is a schedule-free NPC, or one keeping `times`, out in this phase?
static func shown_at(d: Dictionary, phase: String) -> bool:
	var times: Array = d.get("times", [])
	return times.is_empty() or phase in times

## Should this NPC be in the world now: flag gating ("hide_if": absent once set, "show_if": present once set)
## and their hours.
static func should_spawn(d: Dictionary, data: GameStateData, phase: String) -> bool:
	if d.has("hide_if") and data.flag(str(d.hide_if)):
		return false
	if d.has("show_if") and not data.flag(str(d.show_if)):
		return false
	return shown_at(d, phase)

## The def with their routine's spot for now applied (the def itself for anyone without a routine).
static func placed(d: Dictionary) -> Dictionary:
	return Routines.placed(d, Calendar.weekday_today(), Calendar.season_today(), Game.local_minutes())

## Close enough to catch a still NPC's eye.
static func notices(at: Vector2i, player_pos: Vector2i) -> bool:
	var d := player_pos - at
	return d != Vector2i.ZERO and maxi(absi(d.x), absi(d.y)) <= NOTICE_RANGE

## The time of day changed: people with `times` go home or come out, each only once the player is far enough
## away not to see them pop. Cheap; the overworld calls it now and then. Retries until everyone is settled.
static func sync_schedule(ow: Node) -> void:
	var phase := Game.phase()
	var stamp := phase + Routines.stamp(Calendar.weekday_today(), Calendar.season_today(), Game.local_minutes())
	if ow.zone == null or Router.busy or str(ow.get_meta("npc_phase", "")) == stamp:
		return
	var settled := true
	for d in ow.zone.npcs:
		if not d.has("times") and not d.has("routine"):
			continue
		var want := should_spawn(d, Game.data, phase)
		var here: Node = null
		for n in ow.npcs:
			if is_instance_valid(n) and str(n.def.get("id", "")) == str(d.get("id", "")):
				here = n
		var spot := placed(d)
		var dest := Vector2i(int(spot.get("x", 0)), int(spot.get("y", 0)))
		var moving: bool = want and here != null and here.grid_pos != dest  # a routine sends them elsewhere
		if want == (here != null) and not moving:
			continue
		var p: Vector2i = here.grid_pos if here else dest
		var gap: Vector2i = p - ow.player.grid_pos
		var gap2: Vector2i = dest - ow.player.grid_pos
		if maxi(absi(gap.x), absi(gap.y)) < SCHEDULE_FAR or ((here == null or moving) and (ow.occupied(dest) or maxi(absi(gap2.x), absi(gap2.y)) < SCHEDULE_FAR)):
			settled = false
			continue
		if here:
			ow.npcs.erase(here)
			here.queue_free()
		if want:
			var n := Npc.new()
			ow.add_child(n)
			n.setup(spot, ow)
			ow.npcs.append(n)
	if settled:
		ow.set_meta("npc_phase", stamp)

func face_toward(p: Vector2i) -> void:
	if p != grid_pos:
		face(GridMotion.facing_from(p - grid_pos))

func is_trainer() -> bool:
	return str(def.get("trainer", "")) != ""

func _process(delta: float) -> void:
	_react(delta)
	if _mode == "still":
		_idle(delta)
		return
	if _stepping or _talking or _challenging or Router.busy or ow.player.moving:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	if _mode == "wander":
		_timer = randf_range(2.0, 5.0)
		var dir: String = ["up", "down", "left", "right"].pick_random()
		var target := GridMotion.step(grid_pos, dir)
		if maxi(absi(target.x - home.x), absi(target.y - home.y)) <= int(def.get("radius", ZoneData.WANDER_RADIUS)):
			_step(dir)
		else:
			face(dir)
	elif _mode == "pace" and not _pace_dirs.is_empty():
		_timer = randf_range(0.5, 1.0)
		if await _step(_pace_dirs[_pace_i]):
			_pace_i = (_pace_i + 1) % _pace_dirs.size()

## Every REACT_EVERY seconds: an umbrella if it is raining, and the bubble that suits who they are to you.
func _react(delta: float) -> void:
	_spot_left -= delta
	_spot_cool -= delta
	_react_t -= delta
	if _react_t > 0.0:
		return
	_react_t = REACT_EVERY
	var umbrella := NpcBubble.umbrella_for(str(ow.weather), ow.zone.kind, def)
	if umbrella != (_umbrella != null):
		if umbrella:
			_umbrella = NpcBubble.make_umbrella(str(def.get("id", "")), BROLLY_Y)
			add_child(_umbrella)
		else:
			_umbrella.queue_free()
			_umbrella = null
	var want := ""
	var pp: Vector2i = ow.player.grid_pos
	if not (_talking or _challenging or Router.busy) and NpcBubble.in_range(grid_pos, pp):
		want = NpcBubble.kind_for(ow.zone.id, def, Game.data)
		if want == "" and _spotted_follower():
			want = NpcBubble.SPARK
	_set_bubble(want)

## A child within sight of your follower notices it: a sparkle for a few seconds, then not again for a while.
func _spotted_follower() -> bool:
	if _spot_left > 0.0:
		return true
	if _spot_cool > 0.0 or not NpcBubble.is_child(def) or not Settings.follower:
		return false
	var f: Follower = ow.follower
	if f == null or not f.visible or not NpcBubble.in_range(grid_pos, f.tile, NpcBubble.SPOT_RANGE):
		return false
	_spot_left = NpcBubble.SPOT_SECS
	_spot_cool = NpcBubble.SPOT_COOL
	if _mode == "still" and not _looking and f.tile != grid_pos:
		_turn(GridMotion.facing_from(f.tile - grid_pos))
		_looking = true
		_look_t = 1.5
	return true

func _set_bubble(kind: String) -> void:
	if kind == _bubble_kind:
		return
	_bubble_kind = kind
	if _bubble_tween:
		_bubble_tween.kill()
		_bubble_tween = null
	if _bubble:
		_bubble.queue_free()
		_bubble = null
	if kind == "":
		return
	var y := BUBBLE_Y + (0.3 if _umbrella else 0.0)
	_bubble = NpcBubble.make_bubble(kind, y)
	add_child(_bubble)
	if not Settings.reduce_flashing:  # a gentle bob
		_bubble_tween = create_tween().set_loops()
		_bubble_tween.tween_property(_bubble, "position:y", y + 0.08, 0.7).set_trans(Tween.TRANS_SINE)
		_bubble_tween.tween_property(_bubble, "position:y", y, 0.7).set_trans(Tween.TRANS_SINE)

## A still townsperson: look at the player when they come close, glance about now and then, and settle back.
## Trainers never do this (their facing is their line of sight).
func _idle(delta: float) -> void:
	if is_trainer() or _talking or _challenging or Router.busy:
		return
	var pp: Vector2i = ow.player.grid_pos
	if notices(grid_pos, pp):
		var toward := GridMotion.facing_from(pp - grid_pos)
		if facing != toward:
			_turn(toward)
		_looking = true
		_look_t = 0.9
		return
	if _looking:
		_look_t -= delta
		if _look_t <= 0.0:
			_looking = false
			_turn(_rest)
			_glance_t = randf_range(5.0, 11.0)
		return
	_glance_t -= delta
	if _glance_t <= 0.0:
		var away: Array = ["up", "down", "left", "right"].filter(func(d): return d != _rest)
		_turn(away.pick_random())
		_looking = true
		_look_t = randf_range(0.8, 1.6)

func _can_step(target: Vector2i) -> bool:
	return ow.can_enter(target, target - grid_pos) == "ok" and target != ow.player.grid_pos \
		and ow.zone.warp_at(target).is_empty()

## One step. Never into a blocked tile or the player. Returns whether it moved.
func _step(dir: String, keep_walking := false) -> bool:
	face(dir)
	var target := GridMotion.step(grid_pos, dir)
	if not _can_step(target):
		return false
	_stepping = true
	grid_pos = target   # claim the tile at once so nobody walks into it
	sprite.walking = true
	var dest := Vector3(target.x + 0.5, ow.ground_y(target), target.y + 0.5)
	var tw := create_tween()
	tw.tween_property(self, "position", dest, 1.0 / STEP_SPEED)
	await tw.finished
	position = dest
	if not keep_walking:
		sprite.walking = false
	_stepping = false
	return true

## Scripted walk: a list of directions. Blocked steps are skipped.
func walk(path: Array) -> void:
	for d in path:
		if not await _step(str(d), true):
			await get_tree().create_timer(0.15).timeout
	sprite.walking = false

func interact(player: Node) -> void:
	if _talking or _challenging:
		return
	_talking = true
	if is_trainer() or _mode != "still":
		face_toward(player.grid_pos)
	elif player.grid_pos != grid_pos:
		_turn(GridMotion.facing_from(player.grid_pos - grid_pos))  # and back to how they stand, once you go
		_looking = true
		_look_t = 0.9
	var tid := str(def.get("trainer", ""))
	var cmds: Array = []
	if tid != "":
		if Game.data.flag("trainer_" + tid):
			var t := StoryData.trainer(tid)
			cmds = [{"do": "say", "who": t.name, "text": t.after if t.after != "" else "..."}]
		else:
			cmds = StoryData.trainer_script(tid)
	elif def.has("script"):
		cmds = StoryData.script(str(def.get("script_file", ow.zone.id)), str(def.script))  # side stories keep their own file
	elif def.has("text"):
		cmds = [{"do": "say", "who": str(def.get("name", "")), "text": str(def.text)}]
	if cmds.is_empty():
		cmds = StoryData.script(ow.zone.id, "nothing_to_say")
	ScriptRunner.start(ow, cmds, str(def.get("id", "")), Callable(self, "_talk_done"))

func _talk_done() -> void:
	_talking = false

## Called by the overworld after every player step. True if this trainer has spotted the player and taken over.
func check_sight(player_pos: Vector2i) -> bool:
	if not is_trainer() or _challenging or _talking or Router.busy:
		return false
	if not Sight.triggers(def, Game.data, grid_pos, facing, player_pos, Callable(self, "_blocks_sight")):
		return false
	_challenging = true
	Router.busy = true   # synchronously, so the overworld stops its own step handling
	_challenge(player_pos)
	return true

func _blocks_sight(p: Vector2i) -> bool:
	if not ow.zone.in_bounds(p) or not ow.zone.walkable(p):
		return true
	var other: Node = ow.npc_at(p)
	return other != null and other != self

func _challenge(player_pos: Vector2i) -> void:
	Audio.sfx("alert")
	if ow.get("rig") and ow.rig.has_method("nudge"):
		ow.rig.nudge(global_position)  # the camera leans in toward them while the "!" shows
	await _bubble()
	await walk(Sight.approach_path(grid_pos, facing, player_pos))
	face_toward(ow.player.grid_pos)
	ow.player.face(_opposite(facing))
	var tid := str(def.trainer)
	_challenging = false
	_talking = true
	ScriptRunner.start(ow, StoryData.trainer_script(tid), str(def.get("id", "")), Callable(self, "_talk_done"))

func _bubble() -> void:
	var l := Label3D.new()
	l.text = "!"
	l.font_size = 96
	l.outline_size = 24
	l.modulate = Color(1.0, 0.86, 0.25)
	l.outline_modulate = Color(0.25, 0.1, 0.05)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.012
	l.position = Vector3(0, 1.9, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", 2.1, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.55)
	await tw.finished
	l.queue_free()

## Dev switch: `-- --talk=<npc_id>` runs that NPC's conversation as soon as the zone is ready.
func _dev_talk() -> void:
	if _dev_talk_done or "--talk=" + str(def.get("id", "")) not in DevArgs.user_args():
		return
	_dev_talk_done = true
	await get_tree().create_timer(0.4).timeout
	while Router.busy:
		await get_tree().process_frame
	if "--nurse-seen" in DevArgs.user_args():  # with a Sanctuary nurse: pretend this is a return visit (screenshots)
		Game.data.set_flag("nurse_seen_" + Game.data.zone_id)
	interact(ow.player)
