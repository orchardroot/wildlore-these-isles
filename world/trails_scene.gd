class_name TrailsScene
extends RefCounted
## Papers on tables and the dig spots they point to (see Letters): `dress` lays a paper on the room's first table or
## dresser (until it is read) and a patch of disturbed earth where an open trail ends; `interact` reads the paper or
## digs the spot, the line then the find.

const ROOT := "Trails"
static var _paper_mesh: ArrayMesh
static var _dig_mesh: ArrayMesh

static func dress(z: ZoneData, zone_node: Node3D, data: GameStateData) -> void:
	var root: Node3D = null
	var here := Letters.at(str(z.id))
	var t := Letters.prop_for(z) if not here.is_empty() else Letters.NONE
	if t != Letters.NONE and not Letters.is_read(data, str(here[0].id)):
		root = _root(zone_node, root)
		var dresser := false
		for pr in z.props:
			if int(pr.x) == t.x and int(pr.y) == t.y and str(pr.type) == "kitchen_dresser":
				dresser = true
		var n := MeshInstance3D.new()
		n.name = "Paper"
		n.mesh = _paper(dresser)
		n.material_override = Meshes.solid
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.position = Vector3(t.x + 0.5, ZoneBuilder.ground_y(z, t), t.y + 0.5)
		n.rotation.y = float(hash(t) % 100) / 100.0 * 0.5 - 0.25
		root.add_child(n)
	for p in Letters.trails_here(data, str(z.id)):
		var d := Letters.dig_tile(z, p.trail)
		if d == Letters.NONE:
			continue
		root = _root(zone_node, root)
		var n := MeshInstance3D.new()
		n.name = "Dig_%d_%d" % [d.x, d.y]
		n.mesh = _dig()
		n.material_override = Meshes.solid
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.position = Vector3(d.x + 0.5, ZoneBuilder.ground_y(z, d) + 0.02, d.y + 0.5)
		n.rotation.y = float(hash(d) % 100) / 100.0 * 3.0
		root.add_child(n)

static func _root(zone_node: Node3D, root: Node3D) -> Node3D:
	if root != null:
		return root
	Meshes.materials()
	root = Node3D.new()
	root.name = ROOT
	zone_node.add_child(root)
	return root

static func _paper(dresser: bool) -> ArrayMesh:
	if _paper_mesh == null:
		_paper_mesh = _build(Vector3(0.14, 0.0, 0.1), Color("f7f2e4"), Vector3(0.3, 0.012, 0.22), Color("b0382c"))
	var m := _paper_mesh
	if dresser:  # the dresser top is a touch higher and its front half is clear
		m = _build(Vector3(0.0, 0.05, -0.28), Color("f7f2e4"), Vector3(0.3, 0.012, 0.22), Color("b0382c"))
	return m

static func _build(at: Vector3, col: Color, size: Vector3, seal: Color) -> ArrayMesh:
	var st := Meshes._st()
	Meshes.box(st, Vector3(0, 0.7, 0) + at - size * Vector3(0.5, 0, 0.5), size, col)
	Meshes.box(st, Vector3(0, 0.7, 0) + at + Vector3(0.07, 0.012, 0.03), Vector3(0.05, 0.012, 0.05), seal)
	return Meshes._finish(st)

static func _dig() -> ArrayMesh:
	if _dig_mesh == null:
		var st := Meshes._st()
		Meshes.box(st, Vector3(-0.32, 0, -0.22), Vector3(0.64, 0.015, 0.44), Color("5b4631"))
		Meshes.box(st, Vector3(-0.2, 0.015, -0.28), Vector3(0.3, 0.015, 0.2), Color("6e573c"))
		Meshes.box(st, Vector3(0.0, 0.015, 0.02), Vector3(0.26, 0.02, 0.18), Color("4a3a28"))
		_dig_mesh = Meshes._finish(st)
	return _dig_mesh

## Facing the paper on the table, or a dig spot, and pressing confirm.
static func interact(ow: Node, p: Vector2i) -> bool:
	var zone: ZoneData = ow.zone
	var zid := str(zone.id)
	var here := Letters.at(zid)
	if not here.is_empty() and Letters.prop_for(zone) == p:
		var res := Letters.read(Game.data, here[0])
		var node: Node = ow._zone_node.get_node_or_null(ROOT + "/Paper") if ow._zone_node else null
		if node:
			node.queue_free()
		if res.first:
			Audio.sfx("item")
		await ow.say(res.lines)
		return true
	for tr in Letters.trails_here(Game.data, zid):
		if Letters.dig_tile(zone, tr.trail) != p:
			continue
		Audio.sfx("step_grass")
		var res := Letters.dig(Game.data, tr, Game.items)
		var node: Node = ow._zone_node.get_node_or_null("%s/Dig_%d_%d" % [ROOT, p.x, p.y]) if ow._zone_node else null
		if node:
			node.queue_free()
		Audio.sfx("item")
		await ow.say(res.lines)
		return true
	return false
