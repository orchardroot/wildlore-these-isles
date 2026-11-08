class_name DeepMeshes
extends RefCounted
## The pieces of a Deep Place (DeepPlace) drawn as what their lines say they are: a closed gate is a cave gate, a
## grille, a timber gate, a barrier, a slab or a door; a lever is a lever, a sluice wheel, a winch, a weir board or a
## crack in the rock; a crate is a boulder, a tub, a block or a column-end; a plate is a plate. One tile each, y = 0
## at the floor, same vertex-colour rules as Meshes. A gate always faces the camera, across local X, so it reads as a
## gate even in a passage that runs east and west.
## The variant packs the look's index in DeepPlace's lists, times two, plus 1 when pulled or pressed.

const IRON := Color("2d3138")
const RUST := Color("6b4a35")
const TIMBER := Color("6a4a30")
const LIME := Color("9d978a")
const BASALT := Color("3d3f45")
const FLOWSTONE := Color("c9b994")
const BRASS := Color("b8923a")
const DARK := Color("0d0c0c")

static func mesh(kind: String, variant: int) -> ArrayMesh:
	var looks: Array = DeepPlace.LOOKS.get(kind, [])
	var look: String = looks[clampi(variant / 2, 0, looks.size() - 1)] if not looks.is_empty() else ""
	var on := variant % 2 == 1
	match kind:
		"deep_gate":
			return gate(look)
		"deep_lever":
			return lever(look, on)
		"deep_crate":
			return crate(look)
		"deep_plate":
			return plate(on)
	return Landmarks.lever(0)

# --- gates (closed; an open gate is just the room's floor) ----------------------------------------------------

static func gate(look: String) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(8800 + look.hash() % 97)
	match look:
		"cave_gate", "grille":
			var bar := IRON if look == "cave_gate" else RUST
			var tall := 2.1 if look == "cave_gate" else 1.9
			for x in 7:  # upright bars, with rails top, middle and bottom
				Meshes.box(st, Vector3(-0.45 + x * 0.145, 0, -0.03), Vector3(0.04, tall, 0.04), bar.lightened(0.05 * (x % 2)))
			for y in [0.05, tall * 0.5, tall - 0.08]:
				Meshes.box(st, Vector3(-0.5, float(y), -0.04), Vector3(1.0, 0.07, 0.06), bar.darkened(0.1))
			if look == "grille":
				for y in [tall * 0.25, tall * 0.75]:  # a grille is a lattice, not just bars
					Meshes.box(st, Vector3(-0.5, float(y), -0.035), Vector3(1.0, 0.035, 0.05), bar)
			else:
				Meshes.box(st, Vector3(0.1, tall * 0.5 - 0.12, 0.02), Vector3(0.1, 0.13, 0.06), BRASS)  # the padlock
		"timber_gate":
			for x in 5:  # heavy planks, two ledges and a brace, a chain across
				Meshes.box(st, Vector3(-0.48 + x * 0.192, 0, -0.06), Vector3(0.18, 1.6, 0.1), TIMBER.lightened(rng.randf_range(-0.06, 0.06)))
			for y in [0.25, 1.2]:
				Meshes.box(st, Vector3(-0.5, float(y), 0.04), Vector3(1.0, 0.14, 0.06), TIMBER.darkened(0.15))
			for k in 6:
				Meshes.box(st, Vector3(-0.4 + k * 0.14, 0.39 + k * 0.135, 0.05), Vector3(0.16, 0.14, 0.05), TIMBER.darkened(0.1))
			for k in 8:
				Meshes.box(st, Vector3(-0.48 + k * 0.12, 0.8 + 0.04 * (k % 2), 0.1), Vector3(0.1, 0.05, 0.04), IRON.lightened(0.2))
		"barrier":
			Meshes.box(st, Vector3(-0.46, 0, -0.08), Vector3(0.16, 1.1, 0.16), Color("3a3f48"))
			Meshes.box(st, Vector3(0.36, 0, -0.06), Vector3(0.1, 0.8, 0.12), Color("3a3f48"))
			for k in 6:  # the arm, striped red and white, resting on its post
				Meshes.box(st, Vector3(-0.42 + k * 0.155, 0.82, -0.04), Vector3(0.155, 0.09, 0.08), Color("c8322a") if k % 2 == 0 else Color("efe9dc"))
		"oak_door":
			for side in [-0.5, 0.36]:  # a stone frame, the door banded in iron
				Meshes.box(st, Vector3(float(side), 0, -0.12), Vector3(0.14, 2.1, 0.24), LIME)
			Meshes.box(st, Vector3(-0.5, 1.9, -0.12), Vector3(1.0, 0.2, 0.24), LIME.darkened(0.05))
			Meshes.box(st, Vector3(-0.36, 0, -0.05), Vector3(0.72, 1.9, 0.1), Color("5b3d24"))
			for y in [0.3, 0.95, 1.6]:
				Meshes.box(st, Vector3(-0.36, float(y), 0.04), Vector3(0.72, 0.07, 0.03), IRON)
			Meshes.box(st, Vector3(0.18, 0.9, 0.05), Vector3(0.08, 0.08, 0.05), IRON.lightened(0.3))
		_:  # "slab", "basalt_slab", "flowstone": a stone slab standing across the way
			var stone: Color = {"basalt_slab": BASALT, "flowstone": FLOWSTONE}.get(look, LIME)
			Meshes.box(st, Vector3(-0.5, 0, -0.22), Vector3(1.0, 2.0, 0.44), stone, stone.lightened(0.1))
			for k in 4:  # weathered lumps and bands on the face
				var c := Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(0.3, 1.7), 0.22)
				Meshes.blob(st, c, Vector3(0.18, 0.12, 0.05), stone.lightened(rng.randf_range(-0.08, 0.08)), rng, 0.2)
			if look == "basalt_slab":
				for x in 3:
					Meshes.box(st, Vector3(-0.34 + x * 0.33, 0, 0.21), Vector3(0.02, 2.0, 0.02), stone.darkened(0.3))
	return Meshes._finish(st)

# --- levers -------------------------------------------------------------------------------------------------

static func lever(look: String, on: bool) -> ArrayMesh:
	if look == "lever":
		return Landmarks.lever(int(on))
	var st := Meshes._st()
	var rng := Meshes._rng(8900 + look.hash() % 97)
	match look:
		"wheel":  # a sluice wheel on an iron post, green with age: a solid rim, four spokes, a brass hub
			Meshes.box(st, Vector3(-0.08, 0, -0.08), Vector3(0.16, 0.66, 0.16), IRON)
			Meshes.box(st, Vector3(-0.2, 0, -0.2), Vector3(0.4, 0.08, 0.4), IRON.darkened(0.1))
			var turn := 0.4 if on else 0.0
			var verdigris := Color("4f6b55")
			for i in 16:
				var a := TAU * i / 16.0 + turn
				Meshes.box(st, Vector3(cos(a) * 0.3 - 0.06, 0.9 + sin(a) * 0.3 - 0.06, 0.04), Vector3(0.12, 0.12, 0.08), verdigris.lightened(0.06 * (i % 2)))
			for i in 4:
				var a := PI * i / 4.0 + turn
				for k in 5:
					var r := (k - 2) * 0.06
					Meshes.box(st, Vector3(cos(a) * r - 0.03, 0.9 + sin(a) * r - 0.03, 0.06), Vector3(0.06, 0.06, 0.04), verdigris.darkened(0.1))
			Meshes.box(st, Vector3(-0.07, 0.83, 0.05), Vector3(0.14, 0.14, 0.1), BRASS)
		"winch":  # a dark iron drum on two timber trestles, rope wound round it, a crank on the side
			for x in [-0.44, 0.34]:
				Meshes.box(st, Vector3(float(x), 0, -0.3), Vector3(0.1, 0.1, 0.6), TIMBER.darkened(0.1))
				Meshes.box(st, Vector3(float(x), 0, -0.06), Vector3(0.1, 0.82, 0.12), TIMBER)
			for i in 12:  # the drum, round its axle along x, rope over part of it (more when wound)
				var a := TAU * i / 12.0
				var rope := i < (9 if on else 4)
				Meshes.box(st, Vector3(-0.34, 0.6 + sin(a) * 0.22 - 0.06, cos(a) * 0.22 - 0.06), Vector3(0.68, 0.12, 0.12), Color("7a6a4c") if rope else IRON.lightened(0.1))
			Meshes.box(st, Vector3(-0.38, 0.54, -0.06), Vector3(0.76, 0.12, 0.12), IRON)  # the axle
			Meshes.box(st, Vector3(0.44, 0.57, -0.03), Vector3(0.1, 0.06, 0.06), IRON)
			var up := 0.28 if on else -0.28
			Meshes.box(st, Vector3(0.5, 0.6 + minf(up, 0.0), -0.03), Vector3(0.05, absf(up), 0.06), IRON)
			Meshes.box(st, Vector3(0.5, 0.6 + up - 0.03, -0.03), Vector3(0.05, 0.06, 0.2), RUST.lightened(0.2))
		"board":  # a weir board in a timber frame: down in the slot, or lifted out on its handle
			for x in [-0.45, 0.35]:
				Meshes.box(st, Vector3(float(x), 0, -0.08), Vector3(0.1, 1.2, 0.16), TIMBER.darkened(0.1))
			var lift := 0.5 if on else 0.0
			Meshes.box(st, Vector3(-0.35, lift, -0.04), Vector3(0.7, 0.55, 0.08), TIMBER.lightened(0.08))
			Meshes.box(st, Vector3(-0.04, 0.55 + lift, -0.03), Vector3(0.08, 0.25, 0.06), IRON)
			Meshes.box(st, Vector3(-0.15, 0.78 + lift, -0.03), Vector3(0.3, 0.06, 0.06), IRON)
		"handle":  # a brass handle in a little wall box, up or down
			Meshes.box(st, Vector3(-0.18, 0, -0.14), Vector3(0.36, 0.95, 0.28), Color("3a3f48"))
			Meshes.box(st, Vector3(-0.14, 0.4, 0.14), Vector3(0.28, 0.4, 0.02), Color("23262c"))
			var hy := 0.72 if not on else 0.44
			Meshes.box(st, Vector3(-0.03, hy - 0.02, 0.14), Vector3(0.06, 0.06, 0.12), BRASS)
			Meshes.box(st, Vector3(-0.1, hy - 0.04, 0.24), Vector3(0.2, 0.08, 0.06), BRASS.lightened(0.15))
		"column":  # a short basalt column, six-sided, with a dark hollow in its face
			Meshes.cylinder(st, Vector3(0, 0, 0), 0.32, 1.3, 6, BASALT)
			Meshes.box(st, Vector3(-0.09, 0.55, 0.22), Vector3(0.18, 0.24, 0.06), DARK)
		_:  # "crack", "hollow": a lump of rock with a dark split in it, found by lantern light
			var rock := Color("6f685d")
			Meshes.blob(st, Vector3(0, 0.35, 0), Vector3(0.42, 0.4, 0.38), rock, rng, 0.2)
			Meshes.blob(st, Vector3(0.18, 0.2, 0.15), Vector3(0.25, 0.22, 0.22), rock.lightened(0.06), rng, 0.2)
			Meshes.box(st, Vector3(-0.05, 0.15, 0.3), Vector3(0.09, 0.45, 0.1), DARK)
			Meshes.box(st, Vector3(-0.12, 0.3, 0.32), Vector3(0.24, 0.08, 0.08), DARK)
			if on:
				Meshes.box(st, Vector3(-0.2, 0, 0.3), Vector3(0.18, 0.12, 0.14), rock.darkened(0.1))  # the loose flake, out
	return Meshes._finish(st)

# --- crates and plates --------------------------------------------------------------------------------------

static func crate(look: String) -> ArrayMesh:
	var st := Meshes._st()
	var rng := Meshes._rng(9000 + look.hash() % 97)
	match look:
		"boulder":
			Meshes.blob(st, Vector3(0, 0.36, 0), Vector3(0.42, 0.38, 0.4), Color("8a8476"), rng, 0.15)
		"tub":  # a colliery tram: an iron tub on four wheels on a length of rail, coal heaped in it
			for z in [-0.3, 0.27]:
				Meshes.box(st, Vector3(-0.5, 0, float(z) - 0.02), Vector3(1.0, 0.04, 0.04), Color("6d737c"))
			Meshes.box(st, Vector3(-0.38, 0.12, -0.28), Vector3(0.76, 0.42, 0.56), Color("4a3f36"), Color("4a3f36"))
			for x in [-0.38, 0.34]:
				Meshes.box(st, Vector3(float(x), 0.12, -0.3), Vector3(0.04, 0.44, 0.6), IRON)
			for wx in [-0.24, 0.24]:
				for wz in [-0.3, 0.27]:
					Meshes.cylinder(st, Vector3(float(wx), 0.0, float(wz)), 0.12, 0.03, 8, IRON)
			Meshes.blob(st, Vector3(0, 0.56, 0), Vector3(0.32, 0.12, 0.22), Color("1c1c1e"), rng, 0.3)
		"column":  # a loose column-end of basalt lying on its side
			Meshes.box(st, Vector3(-0.42, 0, -0.25), Vector3(0.84, 0.5, 0.5), BASALT, BASALT.lightened(0.12))
			Meshes.box(st, Vector3(-0.42, 0.5, -0.12), Vector3(0.84, 0.1, 0.24), BASALT.lightened(0.05))
			Meshes.box(st, Vector3(0.42, 0.05, -0.2), Vector3(0.02, 0.5, 0.4), BASALT.lightened(0.2))
		_:  # "block" on a timber skid, "slab" on a little iron bogie: dressed stone, chisel lines on top
			var slab := look == "slab"
			var base := 0.12
			for z in [-0.3, 0.22]:
				Meshes.box(st, Vector3(-0.44, 0, float(z)), Vector3(0.88, base, 0.08), IRON if slab else TIMBER)
			if slab:
				for wx in [-0.28, 0.28]:
					for wz in [-0.32, 0.3]:
						Meshes.cylinder(st, Vector3(float(wx), 0.0, float(wz)), 0.08, 0.03, 8, IRON.lightened(0.15))
			var tall := 0.36 if slab else 0.56
			Meshes.box(st, Vector3(-0.4, base, -0.36), Vector3(0.8, tall, 0.72), LIME, LIME.lightened(0.12))
			for k in 3:
				Meshes.box(st, Vector3(-0.3 + k * 0.25, base + tall, -0.3), Vector3(0.03, 0.01, 0.6), LIME.darkened(0.2))
	return Meshes._finish(st)

## An iron plate set flush in the floor in a stone rim; pressed, it sits lower and darker.
static func plate(pressed: bool) -> ArrayMesh:
	var st := Meshes._st()
	Meshes.box(st, Vector3(-0.42, 0, -0.42), Vector3(0.84, 0.03, 0.84), Color("5a554c"))
	var top := 0.035 if pressed else 0.07
	Meshes.box(st, Vector3(-0.33, 0, -0.33), Vector3(0.66, top, 0.66), IRON.lightened(0.0 if pressed else 0.2))
	for k in 3:
		Meshes.box(st, Vector3(-0.25 + k * 0.2, top, -0.25), Vector3(0.1, 0.01, 0.5), IRON.lightened(0.35 if not pressed else 0.1))
	return Meshes._finish(st)
