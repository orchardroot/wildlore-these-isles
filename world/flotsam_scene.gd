class_name FlotsamScene
extends RefCounted
## Flotsam in the world (see Flotsam): dresses each unfound crate, pot, bottle or cache into the zone and plays facing
## it and pressing confirm. The floating ones ride the swell and stand solid on their tile until taken. Meshes are built
## once per kind.

static var _mesh_cache := {}

static func dress(z: ZoneData, zone_node: Node3D, data: GameStateData) -> void:
	var list := Flotsam.for_zone(str(z.id))
	if list.is_empty() or z.kind == "interior":
		return
	Meshes.materials()
	var root := Node3D.new()
	root.name = "Flotsam"
	zone_node.add_child(root)
	var here := {}
	for f in list:
		if Flotsam.found(data, f):
			continue
		var t := Flotsam.tile(f)
		here[t] = f
		z.blocked[t] = true
		var n := MeshInstance3D.new()
		n.mesh = _mesh(str(f.kind))
		n.name = "FL_%d_%d" % [t.x, t.y]
		var floating := Flotsam.is_floating(f)
		n.material_override = Meshes.bobbing if floating else Meshes.solid
		n.position = Vector3(t.x + 0.5, ZoneBuilder.water_y(z, t) if floating else ZoneBuilder.ground_y(z, t), t.y + 0.5)
		n.rotation.y = float(hash(t) % 628) / 100.0
		if str(f.kind) == "bottle":
			n.rotation.z = 1.25  # lying on the swell, cork up
		root.add_child(n)
	z.set_meta("flotsam_tiles", here)

static func _mesh(kind: String) -> ArrayMesh:
	if _mesh_cache.has(kind):
		return _mesh_cache[kind]
	var rng := Meshes._rng(5400 + kind.length() * 11)
	var st := Meshes._st()
	match kind:
		"crate":  # a slatted fish box, low in the water, with a rope strap and a pale lid
			Meshes.box(st, Vector3(-0.26, -0.12, -0.2), Vector3(0.52, 0.34, 0.4), Color("8a6a3e"), Color("c1a06a"))
			Meshes.box(st, Vector3(-0.28, -0.04, -0.22), Vector3(0.56, 0.05, 0.44), Color("5b432a"))
			Meshes.box(st, Vector3(-0.28, 0.1, -0.22), Vector3(0.56, 0.05, 0.44), Color("5b432a"))
			Meshes.cylinder(st, Vector3(0, -0.11, 0), 0.5, 0.02, 10, Color("dbe9ee"))  # foam ring
		"pot":  # a wicker lobster creel with a red float
			Meshes.cylinder(st, Vector3(0, -0.12, 0), 0.3, 0.34, 9, Color("a07a4c"))
			Meshes.cylinder(st, Vector3(0, 0.0, 0), 0.31, 0.04, 9, Color("5b432a"))
			Meshes.cylinder(st, Vector3(0, 0.14, 0), 0.26, 0.04, 9, Color("5b432a"))
			Meshes.blob(st, Vector3(0.36, 0.0, 0.1), Vector3(0.1, 0.09, 0.1), Color("d9482b"), rng, 0.05)
			Meshes.box(st, Vector3(0.28, -0.02, 0.08), Vector3(0.1, 0.02, 0.02), Color("c9b27a"))
			Meshes.cylinder(st, Vector3(0, -0.11, 0), 0.5, 0.02, 10, Color("dbe9ee"))
		"bottle":  # green glass, cork, and a curl of paper inside
			Meshes.cylinder(st, Vector3(0, -0.15, 0), 0.075, 0.24, 8, Color("4f9a6a"))
			Meshes.cylinder(st, Vector3(0, 0.09, 0), 0.04, 0.13, 8, Color("5aa877"))
			Meshes.cylinder(st, Vector3(0, 0.22, 0), 0.035, 0.05, 6, Color("b88b55"))
			Meshes.cylinder(st, Vector3(0, -0.1, 0), 0.04, 0.12, 6, Color("f2ecd8"))
			Meshes.cylinder(st, Vector3(0, -0.2, 0), 0.26, 0.02, 10, Color("dbe9ee"))
		_:  # cache: a little cairn with a tin tucked in beside it
			Meshes.blob(st, Vector3(-0.1, 0.1, 0), Vector3(0.24, 0.12, 0.2), Color("8f8a7c"), rng, 0.15)
			Meshes.blob(st, Vector3(-0.1, 0.26, 0.01), Vector3(0.16, 0.1, 0.14), Color("a19d94"), rng, 0.15)
			Meshes.blob(st, Vector3(-0.1, 0.38, 0), Vector3(0.09, 0.07, 0.08), Color("7d786b"), rng, 0.15)
			Meshes.box(st, Vector3(0.12, 0, -0.1), Vector3(0.26, 0.16, 0.2), Color("7a8a94"), Color("b8c4cb"))
			Meshes.box(st, Vector3(0.12, 0.1, -0.1), Vector3(0.26, 0.03, 0.2), Color("c06a3a"))
	var m: ArrayMesh = Meshes._finish(st)
	_mesh_cache[kind] = m
	return m

## Facing a find and pressing confirm. True when it was one of ours.
static func interact(ow: Node, p: Vector2i) -> bool:
	if not ow.zone.has_meta("flotsam_tiles"):
		return false
	var f: Dictionary = ow.zone.get_meta("flotsam_tiles").get(p, {})
	if f.is_empty():
		return false
	var id := str(f.reward.item)
	var qty := int(f.reward.qty)
	var name := str(Game.items.get_item(id).get("name", id))
	if Bag.new(Game.data.bag).add(id, qty) <= 0:
		await ow.say(["There is something here, but your bag is full. It will keep, and so will the current."])
		return true
	if Flotsam.is_floating(f):
		Audio.sfx_at("splash", -6.0, 1.3)
	Audio.sfx("item")
	var node: Node3D = ow._zone_node.get_node_or_null("Flotsam/FL_%d_%d" % [p.x, p.y]) if ow._zone_node else null
	if node:  # it lifts clear of the water and goes
		var tw := node.create_tween()
		tw.tween_property(node, "position:y", node.position.y + 0.5, 0.25).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector3.ZERO, 0.15)
		tw.tween_callback(node.queue_free)
	Game.data.set_flag(str(f.flag), true)
	ow.zone.blocked.erase(p)
	ow.zone.get_meta("flotsam_tiles").erase(p)
	await ow.say(Flotsam.lines(f) + ["You take %s." % name])
	return true
