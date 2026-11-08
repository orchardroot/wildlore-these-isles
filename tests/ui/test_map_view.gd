extends TestCase
## The drawn world map: real coastlines (and the islands people look for), labels that never overprint, and the
## little marks for rewilding sites, today's County Show, side stories and the post.

func _lonlat(lon: float, lat: float) -> Vector2:  # the projection tools/map/world_map.py uses
	return Vector2((lon + 11.0) / 13.0 * 1000.0, (59.5 - lat) / 9.7 * 1300.0)

func _on_land(p: Vector2) -> String:
	for n in MapView.shapes().land:
		for ring in MapView.shapes().land[n]:
			if Geometry2D.is_point_in_polygon(p, ring):
				return n
	return ""

func test_every_shape_can_be_filled() -> void:
	var s := MapView.shapes()
	for n in ["england", "wales", "scotland", "northern_ireland", "ireland", "mann"]:
		assert_true(s.land.has(n), n)
		assert_true(s.coast.has(n), n + " has a coast")
	for n in s.land:
		for ring in s.land[n]:
			assert_true(ring.size() >= 3 and not Geometry2D.triangulate_polygon(ring).is_empty(), "%s ring of %d points fills" % [n, ring.size()])

func test_the_islands_people_look_for_are_there() -> void:
	assert_eq(_on_land(_lonlat(-4.5, 54.22)), "mann", "the Isle of Man")
	assert_eq(_on_land(_lonlat(-4.38, 53.28)), "wales", "Anglesey")
	assert_eq(_on_land(_lonlat(-6.2, 57.35)), "scotland", "Skye")
	assert_eq(_on_land(_lonlat(-3.2, 59.03)), "scotland", "Orkney")
	assert_eq(_on_land(_lonlat(-6.5, 58.2)), "scotland", "Lewis")
	assert_eq(_on_land(_lonlat(-4.6, 53.8)), "", "the Irish Sea is wet")
	assert_eq(_on_land(_lonlat(-1.08, 53.96)), "england", "York")
	assert_eq(_on_land(_lonlat(-7.5, 53.4)), "ireland")
	assert_eq(_on_land(_lonlat(-6.8, 54.6)), "northern_ireland")

func test_towns_sit_on_or_by_the_land() -> void:
	var towns: Dictionary = Travel.world_map().towns
	for t in towns:
		var p := Vector2(float(towns[t].x), float(towns[t].y))
		var near := _on_land(p) != ""
		for d in [Vector2(6, 0), Vector2(-6, 0), Vector2(0, 6), Vector2(0, -6)]:
			near = near or _on_land(p + d) != ""
		assert_true(near, "%s is on the map's land" % t)

func test_labels_never_overlap_each_other_or_blockers() -> void:
	var marker := Rect2(95, 95, 20, 20)
	var items := []
	for i in 6:  # six names crowded round nearly the same spot
		items.append({"id": "t%d" % i, "at": Vector2(100 + i * 4, 100 + (i % 2) * 3), "size": Vector2(90, 20)})
	var placed := MapLogic.place_labels(items, [marker])
	assert_eq(placed.size(), 6, "everyone found a spot")
	var rects: Array = placed.values()
	for i in rects.size():
		assert_false(rects[i].intersects(marker), "clear of the marker")
		for j in range(i + 1, rects.size()):
			assert_false(rects[i].intersects(rects[j]), "labels %d and %d" % [i, j])

func test_a_lone_label_sits_just_right_of_its_dot() -> void:
	var placed := MapLogic.place_labels([{"id": "york", "at": Vector2(200, 200), "size": Vector2(50, 20)}], [])
	var r: Rect2 = placed.york
	assert_true(r.position.x > 200 and r.position.x < 215, str(r))
	assert_true(r.get_center().y > 190 and r.get_center().y < 210, str(r))

func test_a_label_never_sits_nearer_someone_elses_dot() -> void:
	# a town just to the right: the label goes left rather than sit beside the neighbour
	var dots := [Vector2(200, 200), Vector2(262, 200)]
	var placed := MapLogic.place_labels([{"id": "a", "at": dots[0], "size": Vector2(40, 20)}], [], dots)
	var r: Rect2 = placed.a
	assert_true(r.end.x <= 200, "left of its dot: %s" % r)

func test_marks_for_rewilding_the_show_side_stories_and_post() -> void:
	var d := GameStateData.new()
	assert_eq(MapLogic.marks(d, {}), [], "nothing on a fresh map")
	var site: Dictionary = Rewild.sites()[0]
	d.set_flag(Rewild.flag_key(str(site.id)), 2)
	d.set_flag("last_town", "buxton")
	var side: Dictionary = SideStories.sides()[0]
	d.set_flag(str(side.after))
	d.set_flag("badge_x")
	d.badges = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
	if side.has("needs"):
		d.set_flag(str(side.needs))
	var card: Dictionary = Postcards.cards()[0]
	d.set_flag(str(card.after))
	var m := MapLogic.marks(d, {"town": "york", "name": "The Great Yorkshire Show"})
	var by_kind := {}
	for k in m:
		by_kind[k.kind] = k
	assert_eq(by_kind.rewild.at, str(site.zone))
	assert_eq(by_kind.rewild.stage, 2)
	assert_eq(by_kind.show.at, "york")
	assert_eq(by_kind.side.at, str(side.zone))
	assert_eq(by_kind.post.at, "buxton", "the post waits wherever you are")
	for k in m:
		assert_true(MapLogic.mark_point(k).x >= 0, "%s has a place on the map" % k.kind)

func test_a_met_but_untouched_site_still_shows() -> void:
	var d := GameStateData.new()
	var site: Dictionary = Rewild.sites()[1]
	d.set_flag(Rewild.flag_key(str(site.id)) + "_met")
	var m := MapLogic.marks(d, {})
	assert_eq(m.size(), 1)
	assert_eq(m[0].stage, 0)

func test_every_town_comes_out_from_under_the_panels() -> void:
	# w52: the info panel (left or right) and the strip along the bottom keep a part of the view; the map scrolls in
	# what is left, so a picked town (Dingle in the far west, London low down) is never under either
	var v := MapView.new()
	v.size = Vector2(1180, 550)
	v.zoom = 2.4
	var towns: Dictionary = Travel.world_map().towns
	for t in towns:
		v.centre = Vector2(float(towns[t].x), float(towns[t].y))
		for left in [true, false]:
			v.inset = Rect2(428.0 if left else 0.0, 0.0, 0.0 if left else 428.0, 90.0)
			var free := Rect2(v.inset.position, v.size - v.inset.position - v.inset.size)
			assert_true(free.grow(-4).has_point(v.screen_pos(v.centre)), "%s clear of a panel on the %s" % [t, "left" if left else "right"])
	v.free()
