extends SceneTree
## Dev tool: picks plain townsfolk (say-only, no gate, quest, shop or trainer business) in town zones to stroll or
## pace instead of standing, and checks each beat against ZoneData.roamer_problem so nobody corks a lane or a doorstep.
## Usage: godot --headless --path . -s res://tools/life/pick_strollers.gd -- <excluded ids json> <out json>
## Then tools/life/apply_strollers.py writes the picks into data/zones. Deterministic.

const WANT := 3          # moving townsfolk a town should have at least
const WANT_BIG := 4      # ... when it has twelve or more people
const BIG := 12
const PACE_LEN := 2
const DIRS := {"left": Vector2i(-1, 0), "right": Vector2i(1, 0), "up": Vector2i(0, -1), "down": Vector2i(0, 1)}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var excl := {}
	for id in JSON.parse_string(FileAccess.get_file_as_string(args[0])):
		excl[str(id)] = true
	var zones := ZoneData.load_all()
	var ids := zones.keys()
	ids.sort()
	var picks := []
	var towns := 0
	var short := []
	for zid in ids:
		var z: ZoneData = zones[zid]
		if z.kind != "town":
			continue
		towns += 1
		var moving := 0
		var claimed := {}
		for n in z.npcs:
			if str(n.get("move", "still")) != "still":
				moving += 1
			for t in z.roam_tiles(n):
				claimed[t] = true
		var want := WANT_BIG if z.npcs.size() >= BIG else WANT
		var cands := []
		for n in z.npcs:
			if _plain(z, n, excl):
				cands.append(n)
		cands.sort_custom(func(a, b): return hash(str(a.id)) < hash(str(b.id)))
		var i := 0
		for n in cands:
			if moving >= want:
				break
			var shape := _shape(z, n, claimed, i % 2 == 0)
			if shape.is_empty():
				continue
			shape["zone"] = zid
			shape["id"] = str(n.id)
			picks.append(shape)
			for t in z.roam_tiles(n.merged(shape, true)):
				claimed[t] = true
			moving += 1
			i += 1
		if moving < want:
			short.append("%s %d/%d" % [zid, moving, want])
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(picks))
	print("towns %d, picks %d, short: %s" % [towns, picks.size(), short])
	quit()

## A still, ordinary resident: say-only script or plain text, no gating, hours, routine, trainer or story use.
func _plain(z: ZoneData, n: Dictionary, excl: Dictionary) -> bool:
	if str(n.get("move", "still")) != "still" or excl.has(str(n.id)):
		return false
	for k in ["trainer", "hide_if", "show_if", "times", "routine", "script_file"]:
		if n.has(k):
			return false
	if str(n.get("sprite", "")).begins_with("creature:") or str(n.get("sprite", "")) in ["shopkeeper", "sanctuary_nurse", "night_nurse", "rail_guard", "warden_grunt", "kit", "mum"]:
		return false
	if n.has("script"):
		var cmds := StoryData.script(z.id, str(n.script))
		if cmds.is_empty():
			return false
		for c in cmds:
			if str(c.get("do", "")) != "say":
				return false
	elif not n.has("text"):
		return false
	return true

## A beat that corks nothing and overlaps nobody: a short pace or a small wander, or {}.
func _shape(z: ZoneData, n: Dictionary, claimed: Dictionary, pace_first: bool) -> Dictionary:
	var tries := []
	var paces := []
	for d in DIRS:
		var path := []
		for k in PACE_LEN:
			path.append(d)
		paces.append({"move": "pace", "path": path})
	var wanders := [{"move": "wander", "radius": 2}, {"move": "wander", "radius": 1}]
	tries = (paces + wanders) if pace_first else (wanders + paces)
	for t in tries:
		var m: Dictionary = n.merged(t, true)
		if z.roamer_problem(m) != "":
			continue
		var tiles := z.roam_tiles(m)
		if tiles.size() < 3:
			continue
		var clash := false
		for p in tiles:
			if p != Vector2i(int(n.x), int(n.y)) and (claimed.has(p) or z.tile_at(p) in ["tall_grass", "bog", "deep_water", "water", "sea"]):
				clash = true
				break
		if not clash:
			return t
	return {}
