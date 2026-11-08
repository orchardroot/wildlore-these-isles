class_name FieldSpot
extends RefCounted
## Field spots in the world (see FieldSpots): dresses each spot's small prop into the zone, notices when you come
## within six tiles (so it shows on the map), and plays facing it and pressing confirm. A creature that knows the
## field piece does it with a short bit of business and you get the reward; otherwise a one-line hint names the
## piece and where it is taught. Meshes are built once per prop kind.

static var _mesh_cache := {}

static func dress(z: ZoneData, zone_node: Node3D, data: GameStateData, ow: Node) -> void:
	var list := FieldSpots.for_zone(str(z.id))
	if list.is_empty() or z.kind == "interior":
		return
	Meshes.materials()
	var root := Node3D.new()
	root.name = "FieldSpots"
	zone_node.add_child(root)
	var spots := {}
	for s in list:
		if FieldSpots.gone(data, s):
			continue
		var t := FieldSpots.tile(s)
		spots[t] = s
		z.blocked[t] = true
		var n := MeshInstance3D.new()
		n.mesh = _mesh(str(s.prop))
		n.material_override = Meshes.solid
		n.name = "F_%d_%d" % [t.x, t.y]
		n.position = Vector3(t.x + 0.5, ZoneBuilder.ground_y(z, t), t.y + 0.5)
		n.rotation.y = float(hash(t) % 628) / 100.0 if str(s.prop) in ["molehill", "glint", "cheese", "bog_pool"] else 0.0
		root.add_child(n)
		if str(s.prop) == "stepping_stones" and FieldSpots.is_hop(s) and t < Vector2i(int(s.reward.hop[0]), int(s.reward.hop[1])):  # one bank draws them
			_stones_across(z, root, t, s.reward.hop)
	z.set_meta("field_tiles", spots)
	if spots.is_empty():
		return
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	root.add_child(timer)
	timer.timeout.connect(func():
		if not is_instance_valid(ow) or not is_instance_valid(ow.player):
			return
		for t in spots:
			var s: Dictionary = spots[t]
			if not FieldSpots.known(data, s) and FieldSpots.close_enough(ow.player.grid_pos, t):
				data.set_flag(FieldSpots.seen_key(s), true))

static func _mesh(kind: String) -> ArrayMesh:
	if _mesh_cache.has(kind):
		return _mesh_cache[kind]
	var rng := Meshes._rng(5100 + kind.length() * 7)
	var st := Meshes._st()
	match kind:
		"wall_gap":  # two stubs of drystone wall with a heap of fallen stones between
			Meshes.box(st, Vector3(-0.42, 0, 0), Vector3(0.3, 0.7, 0.34), Color("8f8a7c"))
			Meshes.box(st, Vector3(0.42, 0, 0), Vector3(0.3, 0.7, 0.34), Color("8f8a7c"))
			Meshes.blob(st, Vector3(-0.05, 0.1, 0.02), Vector3(0.2, 0.12, 0.16), Color("7d786b"), rng, 0.25)
			Meshes.blob(st, Vector3(0.12, 0.08, -0.08), Vector3(0.14, 0.09, 0.12), Color("9a9484"), rng, 0.25)
		"sheep_gate":  # a five-bar gate, shut, with two woolly lumps in front
			Meshes.box(st, Vector3(-0.45, 0, 0.3), Vector3(0.07, 0.75, 0.07), Color("6b5a40"))
			Meshes.box(st, Vector3(0.45, 0, 0.3), Vector3(0.07, 0.75, 0.07), Color("6b5a40"))
			for i in 4:
				Meshes.box(st, Vector3(0, 0.12 + i * 0.17, 0.3), Vector3(0.9, 0.05, 0.05), Color("a89878"))
			Meshes.blob(st, Vector3(-0.2, 0.2, -0.12), Vector3(0.22, 0.17, 0.17), Color("ece8dc"), rng, 0.1)
			Meshes.blob(st, Vector3(0.22, 0.2, -0.05), Vector3(0.22, 0.17, 0.17), Color("e2dccc"), rng, 0.1)
			Meshes.blob(st, Vector3(-0.32, 0.22, -0.14), Vector3(0.08, 0.08, 0.08), Color("2a2622"), rng, 0.1)
		"molehill":  # a heap of dark soil with a few worms
			Meshes.blob(st, Vector3(0, 0.16, 0), Vector3(0.38, 0.2, 0.36), Color("4a3a2a"), rng, 0.2)
			Meshes.blob(st, Vector3(0.3, 0.04, 0.2), Vector3(0.1, 0.04, 0.03), Color("c98f86"), rng, 0.1)
			Meshes.blob(st, Vector3(-0.28, 0.04, 0.24), Vector3(0.09, 0.04, 0.03), Color("c98f86"), rng, 0.1)
		"dead_trunk":  # a grey standing trunk with a couple of snapped limbs
			Meshes.cylinder(st, Vector3(0, 0, 0), 0.2, 1.25, 6, Color("77705f"))
			Meshes.box(st, Vector3(0.14, 0.85, 0), Vector3(0.38, 0.07, 0.07), Color("6b6555"))
			Meshes.box(st, Vector3(-0.28, 0.6, 0), Vector3(0.3, 0.06, 0.06), Color("6b6555"))
		"glint":  # a pale ring of ripples and a bright coin-sized gleam
			Meshes.cylinder(st, Vector3(0, 0, 0), 0.34, 0.03, 10, Color("9fc3cf"))
			Meshes.cylinder(st, Vector3(0, 0.03, 0), 0.12, 0.03, 8, Color("fff3b8"))
		"skim_target":  # a post with a bottle on it
			Meshes.box(st, Vector3(0, 0, 0), Vector3(0.12, 0.7, 0.12), Color("6b5a40"))
			Meshes.cylinder(st, Vector3(0, 0.7, 0), 0.07, 0.3, 6, Color("5fa57a"))
		"bog_pool":  # a black pool with a ring of peat
			Meshes.blob(st, Vector3(0, 0.03, 0), Vector3(0.46, 0.05, 0.4), Color("3a2e22"), rng, 0.1)
			Meshes.cylinder(st, Vector3(0, 0.05, 0), 0.3, 0.02, 10, Color("14110e"))
			Meshes.blob(st, Vector3(0.36, 0.08, 0.1), Vector3(0.1, 0.07, 0.08), Color("5a7a3c"), rng, 0.2)
		"coracle":  # a round pitch-black boat, on its side, with a paddle
			Meshes.blob(st, Vector3(0, 0.2, 0), Vector3(0.42, 0.2, 0.38), Color("3b2f26"), rng, 0.08)
			Meshes.box(st, Vector3(0.42, 0, 0.12), Vector3(0.05, 0.6, 0.05), Color("a8895c"))
		"cheese":  # a big wheel of cheese, standing in a hollow
			Meshes.cylinder(st, Vector3(0, 0, 0), 0.4, 0.22, 12, Color("e8b84a"))
			Meshes.cylinder(st, Vector3(0, 0.22, 0), 0.34, 0.03, 12, Color("f1cf70"))
		"stone_slab":  # one flat stone standing proud of the water, for a stepping-stones crossing
			Meshes.blob(st, Vector3(0, 0.02, 0), Vector3(0.36, 0.14, 0.32), Color("a19d94"), rng, 0.04)
		"stepping_stones":  # a short row of flat grey slabs, each a little lower than the last
			for i in 4:
				Meshes.blob(st, Vector3(-0.45 + i * 0.3, 0.04, (i % 2) * 0.14 - 0.07), Vector3(0.2, 0.1 - i * 0.015, 0.18), Color("a19d94"), rng, 0.03)
		_:  # bale: a straw bale with a bowl on it
			Meshes.box(st, Vector3(0, 0, 0), Vector3(0.8, 0.45, 0.5), Color("c9ab5a"))
			Meshes.blob(st, Vector3(0.1, 0.55, 0), Vector3(0.12, 0.1, 0.12), Color("3a3a3e"), rng, 0.05)
	var m: ArrayMesh = Meshes._finish(st)
	_mesh_cache[kind] = m
	return m

## A stepping-stones crossing shows its stones in the water it crosses, from the bank at `t` toward the landing.
## Decoration only: the hop itself is the spot's business.
static func _stones_across(z: ZoneData, root: Node3D, t: Vector2i, hop: Array) -> void:
	var d := Vector2i(signi(int(hop[0]) - t.x), signi(int(hop[1]) - t.y))
	var p := t + d
	while z.in_bounds(p) and not z.walkable(p) and p != Vector2i(int(hop[0]), int(hop[1])):
		var n := MeshInstance3D.new()
		n.mesh = _mesh("stone_slab")
		n.material_override = Meshes.solid
		n.position = Vector3(p.x + 0.5, ZoneBuilder.water_y(z, p), p.y + 0.5)
		n.rotation.y = float(hash(p) % 628) / 100.0
		root.add_child(n)
		p += d

## Facing a spot and pressing confirm. True when it was one of ours.
static func interact(ow: Node, p: Vector2i) -> bool:
	if not ow.zone.has_meta("field_tiles"):
		return false
	var s: Dictionary = ow.zone.get_meta("field_tiles").get(p, {})
	if s.is_empty():
		return false
	Game.data.set_flag(FieldSpots.seen_key(s), true)
	var lead: Creature = FieldSpots.helper(Game.data, str(s.field))
	if lead == null:
		await ow.say(FieldSpots.hint(s))
		return true
	var node: Node3D = ow._zone_node.get_node_or_null("FieldSpots/F_%d_%d" % [p.x, p.y]) if ow._zone_node else null
	var rw: Dictionary = s.reward
	if not FieldSpots.is_hop(s):
		var fits := true
		if rw.has("item") or rw.has("curio"):
			var id := str(rw.get("item", rw.get("curio", "")))
			fits = Bag.new(Game.data.bag).add(id, int(rw.get("qty", 1))) > 0
		if not fits:
			await ow.say(["There is something here, but your bag is full. It will keep."])
			return true
		if rw.has("money"):
			Game.data.money += int(rw.money)
	Audio.cry(lead.species)
	await _act(ow, node, lead, p, str(FieldSpots.VERBS[str(s.field)].anim))
	var lines := FieldSpots.success_lines(s, lead)
	if rw.has("item") or rw.has("curio"):
		var id2 := str(rw.get("item", rw.get("curio", "")))
		lines.append("You take %s." % Game.items.get_item(id2).get("name", id2))
	elif rw.has("money"):
		lines.append("You pocket %s." % Wallet.fmt(int(rw.money)))
	if not FieldSpots.is_hop(s):
		Audio.sfx("item")
	await ow.say(lines)
	Game.data.set_flag(str(s.flag), true)
	Bus.foraged.emit(ow.zone.id)
	if FieldSpots.is_hop(s):
		await _hop(ow, rw.hop)
	elif node:
		ow.zone.blocked.erase(p)
		ow.zone.get_meta("field_tiles").erase(p)
		node.queue_free()
	return true

## The creature does its bit beside the prop: it appears, goes at it, and the prop reacts.
static func _act(ow: Node, node: Node3D, lead: Creature, p: Vector2i, anim: String) -> void:
	var cs := CharSprite.new()
	var holder := Node3D.new()
	holder.add_child(cs)
	ow._zone_node.add_child(holder)
	cs.setup("creature:" + str(lead.species.id))
	cs.set_coat(lead.variant)
	cs.scale = Vector3.ONE * Follower.scale_for(Cries.size_of(lead.species))
	var y := ZoneBuilder.ground_y(ow.zone, p)
	var from := Vector3(ow.player.grid_pos.x + 0.5, y, ow.player.grid_pos.y + 0.5)
	holder.position = from
	var to := Vector3(p.x + 0.5, y, p.y + 0.5) + (from - Vector3(p.x + 0.5, y, p.y + 0.5)).normalized() * 0.7
	var t := holder.create_tween()
	t.tween_property(holder, "position", to, 0.35)
	if node:
		match anim:
			"topple":
				t.tween_property(node, "rotation:z", 1.45, 0.5).set_ease(Tween.EASE_IN)
			"shove":
				t.tween_property(node, "scale", Vector3(1, 0.4, 1), 0.4)
			"rise":
				t.tween_property(node, "position:y", node.position.y + 0.5, 0.4).set_ease(Tween.EASE_OUT)
			"slide":
				t.tween_property(node, "position:z", node.position.z - 0.6, 0.45)
			"hop":
				t.tween_property(node, "rotation:y", node.rotation.y + 3.0, 0.45)
			_:
				t.tween_property(node, "rotation:y", node.rotation.y + 0.6, 0.15)
				t.tween_property(node, "rotation:y", node.rotation.y - 0.6, 0.15)
				t.tween_property(node, "rotation:y", node.rotation.y, 0.1)
	t.tween_property(cs, "position:y", 0.25, 0.1).set_ease(Tween.EASE_OUT)
	t.tween_property(cs, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)
	await t.finished
	holder.queue_free()

## Across the gap inside the zone: a short arc, then the player stands on the far side.
static func _hop(ow: Node, dest: Array) -> void:
	var d := Vector2i(int(dest[0]), int(dest[1]))
	var from: Vector3 = ow.player.position
	var to := Vector3(d.x + 0.5, ZoneBuilder.ground_y(ow.zone, d), d.y + 0.5)
	var t: Tween = ow.player.create_tween()
	t.tween_method(func(f: float): ow.player.position = Player.hop_pos(from, to, f), 0.0, 1.0, 0.7)
	await t.finished
	ow.player.place(d, ow.player.facing, to.y)
	var f := ow.get_node_or_null("Follower")
	if f and f.has_method("_place_behind"):
		f._place_behind()
