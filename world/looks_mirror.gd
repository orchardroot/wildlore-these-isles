class_name LooksMirror
extends RefCounted
## A mirror on a wall (zone prop {"type": "mirror", "x", "y", "rot"}: rot 90 hangs it on the west wall, -90 the
## east, 0 the north). Looking in it runs the zone's "mirror" dialogue script (a line, then the Wardrobe with the
## hair free to change), or just opens the Wardrobe where there is no script. Mum's house has the first one (4.6).

const TYPE := "mirror"

static func prop_at(z: ZoneData, p: Vector2i) -> Dictionary:
	for pr in z.props:
		if str(pr.get("type", "")) == TYPE and int(pr.get("x", -1)) == p.x and int(pr.get("y", -1)) == p.y:
			return pr
	return {}

static func interact(ow: Node, p: Vector2i) -> bool:
	if prop_at(ow.zone, p).is_empty():
		return false
	var cmds: Array = StoryData.script(str(ow.zone.id), "mirror")
	if cmds.is_empty():
		cmds = [{"do": "wardrobe", "mirror": true}]
	await ScriptRunner.start(ow, cmds)
	return true

## An oval looking glass in a wooden frame, hung at face height on the tile's north edge (rotate for other walls).
static func mesh() -> ArrayMesh:
	var st := Meshes._st()
	var frame := Color("6a4a2a")
	var glass := Color("b9d4de")
	var z := -0.5
	Meshes.box(st, Vector3(-0.24, 0.72, z), Vector3(0.48, 0.66, 0.04), frame)
	Meshes.box(st, Vector3(-0.19, 0.77, z + 0.035), Vector3(0.38, 0.56, 0.012), glass)
	Meshes.box(st, Vector3(-0.15, 1.12, z + 0.04), Vector3(0.18, 0.14, 0.012), glass.lightened(0.35))  # a gleam, top left
	Meshes.box(st, Vector3(0.05, 0.8, z + 0.04), Vector3(0.1, 0.3, 0.012), glass.darkened(0.12))
	Meshes.box(st, Vector3(-0.03, 1.38, z), Vector3(0.06, 0.05, 0.03), frame.darkened(0.3))  # the hook
	return Meshes._finish(st)
