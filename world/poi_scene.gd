class_name PoiScene
extends RefCounted
## The question marks on the routes (see Poi): dresses each poi's prop into the zone, notices when you come within
## six tiles (so its "?" appears on the map), and plays facing it and pressing confirm.

static var _mesh_cache := {}

static func dress(z: ZoneData, zone_node: Node3D, data: GameStateData, ow: Node) -> void:
	var list := Poi.for_zone(str(z.id))
	if list.is_empty() or z.kind == "interior":
		return
	Meshes.materials()
	var root := Node3D.new()
	root.name = "Poi"
	zone_node.add_child(root)
	var spots := {}
	for p in list:
		var t := Poi.tile(z, p)
		spots[t] = p
		z.blocked[t] = true
		var n := MeshInstance3D.new()
		n.mesh = _mesh(str(p.kind))
		n.material_override = Meshes.solid
		n.name = "P_%d_%d" % [t.x, t.y]
		n.position = Vector3(t.x + 0.5, ZoneBuilder.ground_y(z, t), t.y + 0.5)
		n.rotation.y = float(hash(t) % 628) / 100.0
		root.add_child(n)
		var sp := MeshInstance3D.new()
		sp.name = "S_%d_%d" % [t.x, t.y]
		sp.mesh = Forage._cached("sparkle", func(): return Forage._sparkle())
		sp.material_override = Forage._sparkle_material()
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sp.position = Vector3(t.x + 0.5, ZoneBuilder.ground_y(z, t) + 1.3, t.y + 0.5)
		sp.visible = not Poi.done(data, p)
		root.add_child(sp)
		if str(p.kind) == "camp" and not Poi.done(data, p):
			_camp_crew(z, root, t, p)
	z.set_meta("poi_tiles", spots)
	var timer := Timer.new()  # twice a second is plenty to notice a place nearby
	timer.wait_time = 0.5
	timer.autostart = true
	root.add_child(timer)
	timer.timeout.connect(func():
		if not is_instance_valid(ow) or not is_instance_valid(ow.player):
			return
		for t in spots:
			var p: Dictionary = spots[t]
			if not Poi.known(data, p) and Poi.close_enough(ow.player.grid_pos, t):
				data.set_flag(Poi.seen_key(p), true))

const CREW_SPRITES := ["warden_grunt", "hiker", "farmer"]
const CREW_SPOTS := [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(-1, -1)]

## Two or three poachers loitering by the tent: scenery only (the fight is the camp's `interact`), gone once beaten.
static func _camp_crew(z: ZoneData, root: Node3D, t: Vector2i, p: Dictionary) -> void:
	var crew := Node3D.new()
	crew.name = "C_%d_%d" % [t.x, t.y]
	root.add_child(crew)
	var want := clampi(p.get("names", []).size() + 1, 2, 3)
	var i := absi(hash(str(p.id))) % CREW_SPOTS.size()
	var tries := 0
	while crew.get_child_count() < want and tries < CREW_SPOTS.size():
		var at: Vector2i = t + CREW_SPOTS[(i + tries) % CREW_SPOTS.size()]
		tries += 1
		if not z.in_bounds(at) or not z.walkable(at) or z.blocked.has(at):
			continue
		var cs := CharSprite.new()
		var holder := Node3D.new()
		holder.add_child(cs)
		crew.add_child(holder)
		cs.setup(CREW_SPRITES[crew.get_child_count() % CREW_SPRITES.size()])
		cs.set_facing("left" if at.x > t.x else ("right" if at.x < t.x else "up"))
		holder.position = Vector3(at.x + 0.5, ZoneBuilder.ground_y(z, at), at.y + 0.5)

static func _mesh(kind: String) -> ArrayMesh:
	if _mesh_cache.has(kind):
		return _mesh_cache[kind]
	var rng := Meshes._rng(4700 + kind.length())
	var st := Meshes._st()
	match kind:
		"den":  # a dark mound with a black mouth and a few tufts
			Meshes.blob(st, Vector3(0, 0.3, 0), Vector3(0.52, 0.42, 0.48), Color("5a4a34"), rng, 0.15)
			Meshes.box(st, Vector3(-0.2, 0, 0.3), Vector3(0.4, 0.34, 0.12), Color("120e0a"))
			Meshes.blob(st, Vector3(0.3, 0.12, 0.25), Vector3(0.16, 0.12, 0.16), Color("4f6b34"), rng, 0.3)
		"camp":  # a patched ridge tent with a cold fire
			Meshes.cone(st, Vector3(0, 0, 0), 0.62, 1.05, 4, Color("8c7a54"), rng)
			Meshes.box(st, Vector3(-0.1, 0, 0.3), Vector3(0.2, 0.55, 0.06), Color("2a2216"))
			Meshes.blob(st, Vector3(0.7, 0.08, 0.2), Vector3(0.14, 0.08, 0.14), Color("2b2622"), rng, 0.2)
		"stone":  # a standing stone
			st = null
		_:  # a cache: a flat rock with a gap and a tin
			Meshes.blob(st, Vector3(0, 0.25, 0), Vector3(0.45, 0.28, 0.4), Color("7d7a72"), rng, 0.2)
			Meshes.box(st, Vector3(0.12, 0.0, 0.34), Vector3(0.22, 0.16, 0.14), Color("b8452f"))
	var m: ArrayMesh = Landmarks.standing_stone(1) if kind == "stone" else Meshes._finish(st)
	_mesh_cache[kind] = m
	return m

## Facing a poi and pressing confirm. True when it was one of ours.
static func interact(ow: Node, p: Vector2i) -> bool:
	if not ow.zone.has_meta("poi_tiles"):
		return false
	var poi: Dictionary = ow.zone.get_meta("poi_tiles").get(p, {})
	if poi.is_empty():
		return false
	Game.data.set_flag(Poi.seen_key(poi), true)
	match str(poi.kind):
		"den":
			await _den(ow, poi)
		"camp":
			await _camp(ow, poi)
		"stone":
			await _stone(ow, poi)
		_:
			await _cache(ow, poi)
	_refresh(ow, p, poi)
	return true

static func _refresh(ow: Node, p: Vector2i, poi: Dictionary) -> void:
	var sp: Node = ow._zone_node.get_node_or_null("Poi/S_%d_%d" % [p.x, p.y]) if ow._zone_node else null
	if sp:
		sp.visible = not Poi.done(Game.data, poi)
	if Poi.done(Game.data, poi):
		var crew: Node = ow._zone_node.get_node_or_null("Poi/C_%d_%d" % [p.x, p.y]) if ow._zone_node else null
		if crew:
			crew.queue_free()

static func _ask(ow: Node, text: String, yes: String, no: String) -> bool:
	await ScriptRunner.start(ow, [{"do": "choice", "text": text, "options": [yes, no], "set": "poi_ask"}])
	return int(Game.data.flag("poi_ask")) == 0

static func _foe(ow: Node, species: String, level: int, coat := false) -> Creature:
	var foe := Creature.create(Game.dex.get_species(species), level, Game.rng, Game.moves)
	Forms.assign_wild(foe, ow.zone.region, str(ow.zone.id), Game.moves)
	if coat:
		foe.variant = Coats.season_coat(Calendar.today().x)
	Game.data.mark_seen(species)
	return foe

static func _wild(ow: Node, foe: Creature) -> Dictionary:
	return await Router.battle([foe], {"kind": "wild", "weather": ow.weather, "time": Game.phase(), "stage": ow._stage()})

static func _lost(ow: Node, res: Dictionary) -> bool:
	if str(res.get("result", "")) == "lose":
		await ow._after_battle(res)
		return true
	return false

static func _den(ow: Node, poi: Dictionary) -> void:
	if Poi.done(Game.data, poi):
		await ow.say(["The den is empty. Whatever lived here has gone off to think about things."])
		return
	if Game.data.first_able() == null:
		await ow.say(["Something growls in the dark. Best come back with a creature that can stand up."])
		return
	if not await _ask(ow, "A den, and something growls in it. Go in?", "Go in", "Leave it"):
		return
	Audio.sfx("bump")
	await ow.say(["Three pairs of eyes, one after another, then a fourth, further back."])
	for f in Poi.den_fights(ow.zone, Game.rng):
		var res := await _wild(ow, _foe(ow, f.species, int(f.level)))
		if await _lost(ow, res):
			return
		if str(res.get("result", "")) == "ran":
			await ow.say(["You back out of the den, rather quickly."])
			return
	await ow.say(["Something bigger shuffles out of the back. It does not look pleased."])
	var res2 := await _wild(ow, _foe(ow, str(poi.species), Poi.resident_level(ow.zone), true))
	if await _lost(ow, res2):
		return
	Poi.mark_done(Game.data, poi)
	await ow.say(["The den goes quiet. Perhaps it will fill up again in a fortnight."])

static func _camp(ow: Node, poi: Dictionary) -> void:
	if Poi.done(Game.data, poi):
		await ow.say(["The camp is empty, the tent flap flapping and the strongbox open. Someone left a tin of beans."])
		return
	if Game.data.first_able() == null:
		await ow.say(["Voices inside the tent go quiet. You back away."])
		return
	await ow.say(["A poachers' camp. A tent, a cold fire and a padlocked strongbox. Voices, too."])
	for def in Poi.camp_trainers(ow.zone, poi, Game.data.flags):
		for l in def.intro:
			await ow.say([str(l.text)], str(l.who))
		var foes := TrainerParty.build(def, Game.dex, Game.rng, Game.moves, 0, Game.data.flags)
		var res: Dictionary = await Router.battle(foes, {"kind": "trainer", "ai": "trainer", "trainer": def})
		if str(res.get("result", "")) != "win":
			if await _lost(ow, res):
				return
			await ow.say(["You leave. The camp is still there when you come back, and so are they."])
			return
		await ow.say([str(def.win)], str(def.name))
	var box := Poi.strongbox(ow.zone, poi, Game.data.flags)
	Poi.mark_done(Game.data, poi)
	Game.data.money += int(box.money)
	var lines := ["The strongbox gives up its padlock with a kick. Inside: %s." % Wallet.fmt(int(box.money))]
	if str(box.item) != "":
		var got := Bag.new(Game.data.bag).add(str(box.item), 1)
		if got > 0:
			lines.append("And %s." % Game.items.get_item(str(box.item)).get("name", str(box.item)))
	Audio.sfx("item")
	await ow.say(lines)

static func _stone(ow: Node, poi: Dictionary) -> void:
	var lines: Array = poi.lore.duplicate()
	if Poi.done(Game.data, poi):
		await ow.say(["The stone stands there, as it has for a few thousand years. You have had what it has to give."] + lines.slice(1))
		return
	var lead: Creature = Game.data.first_able()
	if lead != null:
		var n := Poi.train(lead, str(poi.stat))
		if n > 0:
			lines.append("%s feels a little more %s for standing near it." % [lead.nickname if lead.nickname != "" else lead.species.name, Poi.stat_name(str(poi.stat))])
			Audio.sfx("item")
	Poi.mark_done(Game.data, poi)
	await ow.say(lines)

static func _cache(ow: Node, poi: Dictionary) -> void:
	if Poi.done(Game.data, poi):
		await ow.say(["Just the hollow, now. And a crisp packet that has been here since 1998."])
		return
	var id := str(poi.item)
	if bool(poi.get("curio", false)):
		var c := Poi.curio_for(poi, Poi.curio_ids())
		if c != "" and Game.items.has(c):
			id = c
	var lines := [str(poi.line)]
	var got := Bag.new(Game.data.bag).add(id, 1)
	if got <= 0:
		await ow.say(["There is something in there, but your bag is full. It will keep."])
		return
	lines.append("You find %s." % Game.items.get_item(id).get("name", id))
	if str(poi.get("paper", "")) != "":
		lines.append(str(poi.paper))
	Poi.mark_done(Game.data, poi)
	Audio.sfx("item")
	await ow.say(lines)
