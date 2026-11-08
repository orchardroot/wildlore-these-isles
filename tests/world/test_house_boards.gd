extends TestCase
## w51: Gaiman had six houses each with a board reading "GAIMAN" (Roscoff, Baddeck, Boston, Bristol and Tristan's
## Edinburgh the same, Adamstown's said "Home"). A name board on a house you cannot enter should say something
## the town's own name card doesn't; plain homes go without.

func test_no_doorless_house_wears_the_town_name() -> void:
	var bad := []
	for f in DirAccess.get_files_at(ZoneData.DIR):
		if not f.ends_with(".json"):
			continue
		var z := ZoneData.load_id(f.get_basename())
		if z == null or z.kind == "interior":
			continue
		var town := z.name.get_slice(",", 0).strip_edges()
		var doors := z.warps.map(func(w): return Vector2i(int(w.x), int(w.y)))
		for b in z.props:
			if str(b.get("type", "")) != "building" or not b.get("show_label", true):
				continue
			var label := str(b.get("label", ""))
			if label != "Home" and label != town and not (town.begins_with(label + " ") and label.length() > 3):
				continue
			var r := Rect2i(int(b.x), int(b.y), int(b.get("w", 1)), int(b.get("h", 1)))
			if not doors.any(func(d): return r.has_point(d)):
				bad.append("%s %d,%d %s" % [z.id, r.position.x, r.position.y, label])
	assert_eq(bad, [], "houses with the town's name (or 'Home') on a board and no door")
