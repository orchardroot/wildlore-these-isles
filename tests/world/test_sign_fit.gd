extends TestCase
## w51: names that didn't fit their own board. Fitting never cut a name, but on a front with too little room it
## shrank it until it could not be read: St Michael's Tower's keeper board was 0 high between its drum towers, the
## York bars' tablets and the small mills' roofline panels a few centimetres. SignSight.audit now reports how high
## each name is and whether its lettering runs off its board; tools/dev/sign_audit.gd lists both for every zone.

func _labels(node: Node) -> Array:
	var out := []
	for c in node.get_children():
		if c is Label3D:
			out.append(c)
		out.append_array(_labels(c))
	return out

func test_squeezed_names_are_readable_now() -> void:
	Meshes.materials()
	for id in ["glastonbury", "york", "penzance", "exe_estuary", "douglas", "anglesey", "avon_gorge", "liverpool", "belfast"]:
		var z := ZoneData.load_id(id)
		var root := ZoneBuilder.build(z)
		for r in SignSight.audit(z, root):
			assert_true(float(r.em) >= Signage.MIN_EM * 0.75, "%s/%s is %.3f high" % [id, r.label, float(r.em)])
			assert_false(r.overhang, "%s/%s runs off its board" % [id, r.label])
		root.free()

func test_the_york_bars_carry_a_tablet_across_the_gatehouse() -> void:
	Meshes.materials()
	var z := ZoneData.load_id("york")
	var root := ZoneBuilder.build(z)
	for r in SignSight.audit(z, root):
		if r.label.ends_with(" Bar"):
			assert_true(float(r.em) >= 0.2, "%s carved big (%.3f)" % [r.label, float(r.em)])
			assert_false(r.moved, "%s stays on the gate, not a lectern" % r.label)
	root.free()

func test_the_audit_sees_lettering_that_runs_off_its_board() -> void:
	Meshes.materials()
	var z := ZoneData.load_id("liverpool")
	var root := ZoneBuilder.build(z)
	for r in SignSight.audit(z, root):
		assert_false(r.overhang, r.label)
	# make one name three times wider than its board: the audit must say so
	for pr in z.props:
		if str(pr.get("label", "")) == "The Cavern (ish)":
			var l: Label3D = _labels(root.get_node("Building_%d_%d" % [int(pr.x), int(pr.y)]))[0]
			var s: Vector2 = l.get_meta("size")
			l.set_meta("size", Vector2(s.x * 3.0, s.y))
	var over := SignSight.audit(z, root).filter(func(r): return r.overhang)
	assert_eq(over.size(), 1)
	root.free()
