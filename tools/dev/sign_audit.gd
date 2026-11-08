extends SceneTree
## Lists building signs whose lettering is cut, from the building's door with the default camera: hidden by a
## building in front, wider than its building, or off the screen edge. See SignSight.audit.
##   .godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/sign_audit.gd -- [zone ...]
## The game's classes are loaded once the autoloads are up (as tests/run_tests.gd does), not named here.

func _initialize() -> void:
	call_deferred("_go")

func _go() -> void:
	var zone_data = load("res://data_api/zone_data.gd")
	var builder = load("res://world/zone_builder.gd")
	var sight = load("res://world/sign_sight.gd")
	var only := OS.get_cmdline_user_args()
	var ids := []
	for f in DirAccess.get_files_at("res://data/zones"):
		if f.ends_with(".json") and (only.is_empty() or f.get_basename() in only):
			ids.append(f.get_basename())
	ids.sort()
	var signs := 0
	var bad := 0
	var moved := []
	for id in ids:
		var z = zone_data.load_id(id)
		if z == null or z.kind == "interior":
			continue
		var root: Node3D = builder.build(z)
		for r in sight.audit(z, root):
			signs += 1
			if r.moved:
				moved.append("%s/%s" % [r.zone, r.label])
			if float(r.hidden) > 0.0 or r.wide or float(r.off) > 0.0:
				bad += 1
				print("%-22s %-34s hidden %3d%%  off %3d%%%s" % [r.zone, r.label, int(float(r.hidden) * 100), int(float(r.off) * 100), "  WIDER THAN BUILDING" if r.wide else ""])
		root.free()
	print("on a board in front, no wall to show them: %s" % ", ".join(moved))
	print("sign_audit: %d of %d signs cut, %d moved off their wall" % [bad, signs, moved.size()])
	quit()
