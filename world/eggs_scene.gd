class_name EggsScene
extends RefCounted
## Easter eggs in the world (rules and words in core/eggs.gd, data/eggs.json). Four small hooks into the overworld: facing a
## tile, a step, standing up from a bench, and a bottle's lines. Nothing here announces itself.

static var _steps := 0        # steps taken in this zone, for the things that want you to have been about a while
static var _quiet := false    # a ringing phone you walked past: it rings once a visit, not once a step

## The overworld's hook after a zone is built.
static func arrive(_ow: Node) -> void:
	_steps = 0
	_quiet = false

## Facing a tile and pressing confirm. True when it was one of ours.
static func interact(ow: Node, p: Vector2i) -> bool:
	var cmds := Eggs.spot_script(Game.data, str(ow.zone.id), p)
	if cmds.is_empty():
		return false
	await ScriptRunner.start(ow, cmds)
	return true

## Each step: the grin at dusk, the phone at midnight. Never during a walk the autopilot is running.
static func on_step(ow: Node, p: Vector2i) -> void:
	_steps += 1
	if _quiet or Engine.has_meta("autopilot") or Router.busy or ow.zone == null:
		return
	var cmds := Eggs.step_script(Game.data, str(ow.zone.id), p, ow.zone.props, Game.local_minutes(), _steps)
	if cmds.is_empty():
		return
	_quiet = true  # nothing more this visit unless it was found (below)
	await ScriptRunner.start(ow, cmds)
	if Game.data.flag("egg_grin") == true or Game.data.flag("egg_phone") == true:
		_quiet = false  # found: the other one may still be waiting

## Stood up from the bench at `bench`, having sat from `start_min` to `end_min` (see BenchSit).
static func bench_stood(ow: Node, bench: Vector2i, start_min: int, end_min: int) -> void:
	var cmds := Eggs.bench_script(Game.data, str(ow.zone.id), bench, start_min, end_min)
	if not cmds.is_empty():
		await ScriptRunner.start(ow, cmds)
