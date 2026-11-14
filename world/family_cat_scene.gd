class_name FamilyCatScene
extends RefCounted
## The family cat in the world (rules in core/family_cat.gd, words in data/dialogue/cat_and_fiddle.json "cat_scene" and
## macc_home.json "cat"). On the first walk onto the Cat and Fiddle road she is sat a few tiles ahead and trots up to you;
## at home she is in the window by her bowl. Her NPC is made here, outside the zone's own list, so her sprite can be
## whichever stage she has grown to.

const ID := "family_cat"
const REACH := 4          # tiles ahead she sits, on the road
static var _running := false

## The overworld's one hook in load_zone, after the zone is built: keeps her flags true, then plays whatever is due.
static func arrive(ow: Node) -> void:
	_dev_lead()
	FamilyCat.sync(Game.data, Game.dex)
	if FamilyCat.scene_due(Game.data, str(ow.zone.id)) and not _running:
		_running = true
		_road(ow)
	elif not FamilyCat.note(Game.data).is_empty() and ow.zone.id != FamilyCat.HOME_ZONE:
		var n := FamilyCat.note(Game.data)
		Game.data.set_flag(FamilyCat.NOTE, true)  # once, ever: the note is a nudge, not a nag
		Game.parish.news(str(n[0]), str(n[1]))

## Dev switch `--cat=lead`: she is already with you, at the front of the party (screenshots of her following).
static func _dev_lead() -> void:
	if "--cat=lead" in DevArgs.user_args() and not FamilyCat.has(Game.data) and not Game.data.party.is_empty():
		var c := FamilyCat.make(Game.dex, Game.moves, Game.rng, 12)
		FamilyCat.join(Game.data, c)
		Game.data.party.erase(c)
		Game.data.party.push_front(c)
		Bus.settings_changed.emit()  # the follower looks again at who leads

static func _road(ow: Node) -> void:
	for _i in 600:  # the zone card and fade first (up to ten seconds)
		if not is_instance_valid(ow) or not ow.is_inside_tree():
			_running = false
			return
		if not Router.busy and not ow.player.moving:
			break
		await ow.get_tree().process_frame
	var spot := _spot(ow)
	if spot.x < 0 or not FamilyCat.scene_due(Game.data, str(ow.zone.id)):
		_running = false
		return
	_spawn(ow, "creature:sootkit", spot, "down")
	await ScriptRunner.start(ow, StoryData.script(str(ow.zone.id), "cat_scene"), ID)
	_running = false

## A free tile a few steps off in a straight, clear line from the player (the way they face first), so she is in view
## and trots straight up; failing that any free tile near on a path she can walk. (-1, -1) if there is none.
static func _spot(ow: Node) -> Vector2i:
	var here: Vector2i = ow.player.grid_pos
	var dirs: Array = [GridMotion.dir_vec(ow.player.facing)]
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if d not in dirs:
			dirs.append(d)
	for d in dirs:
		for n in [REACH, REACH - 1, REACH + 1, REACH - 2]:
			var line := true
			for i in range(1, n + 1):
				if not _free(ow, here + d * i):
					line = false
			if line:
				return here + d * n
	for r in range(3, 7):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var p := here + Vector2i(dx, dy)
				if absi(dx) + absi(dy) == r and _free(ow, p) and not Pathfinder.within(ow.zone, p, here, {}).is_empty():
					return p
	return Vector2i(-1, -1)

static func _free(ow: Node, p: Vector2i) -> bool:
	return ow.zone.in_bounds(p) and ow.zone.walkable(p) and ow.zone.warp_at(p).is_empty() and not ow.occupied(p) \
		and ow.zone.tile_at(p) != "tall_grass"

static func _spawn(ow: Node, sprite_id: String, p: Vector2i, facing: String, extra := {}) -> Node:
	var n: Node3D = load("res://world/npc.gd").new()
	ow.add_child(n)
	var def := {"id": ID, "sprite": sprite_id, "x": p.x, "y": p.y, "facing": facing, "move": "still", "name": "Cat"}
	def.merge(extra, true)
	n.setup(def, ow)
	ow.npcs.append(n)
	return n

static func _npc(ow: Node) -> Node:
	for n in ow.npcs:
		if is_instance_valid(n) and str(n.def.get("id", "")) == ID:
			return n
	return null

## What a script asks of the world: "approach" (she walks up to you), "gone" (she is in your party now: no NPC),
## "home" (put her by the bowl at once).
static func act(ow: Node, op: String) -> void:
	var cat := _npc(ow)
	match op:
		"approach":
			if cat == null:
				return
			var path := Pathfinder.within(ow.zone, cat.grid_pos, ow.player.grid_pos, {})
			var dirs := []
			var from: Vector2i = cat.grid_pos
			for p in path.slice(0, maxi(0, path.size() - 1)):  # up to, not onto, the player's tile
				dirs.append(GridMotion.facing_from(p - from))
				from = p
			await cat.walk(dirs)
			cat.face_toward(ow.player.grid_pos)
		"gone":
			if cat != null:
				ow.npcs.erase(cat)
				cat.queue_free()
		"home":
			if cat == null and str(ow.zone.id) == FamilyCat.HOME_ZONE:
				for d in FamilyCat.npcs_for(FamilyCat.HOME_ZONE, Game.data, Game.dex):
					var p := SideStories.nearest_free(ow.zone, Vector2i(int(d.x), int(d.y)))
					_spawn(ow, str(d.sprite), p, str(d.facing), {"script": d.script, "name": d.name})
