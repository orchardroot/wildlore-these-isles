extends TestCase
## Wave 48 Q (the critic): HP bars that must agree with the numbers, and the map's route line along real legs.

const Summary = preload("res://ui/summary_screen.gd")

# --- HP bars -----------------------------------------------------------------------------------------------

func test_summary_hp_row_bar_is_current_over_max() -> void:
	var c := Fixtures.creature("kindlet", 30)
	c.hp = c.max_hp() - 7
	var screen = Summary.new()
	var mid: Control = screen._middle(c)
	var bars := _bars(mid)
	var hp_bars := bars.filter(func(b: ProgressBar): return int(b.max_value) == c.max_hp())
	assert_eq(hp_bars.size(), 1, "one bar is scaled to the creature's max HP")
	if hp_bars.size() == 1:
		var b: ProgressBar = hp_bars[0]
		assert_eq(int(b.value), c.hp, "and it is filled to its current HP")
	c.hp = c.max_hp()
	var full := _bars(screen._middle(c)).filter(func(b: ProgressBar): return int(b.max_value) == c.max_hp())
	assert_true(full.size() == 1 and full[0].ratio > 0.999, "a healed creature's bar is full")
	screen.free()

func _bars(n: Node) -> Array:
	var out := []
	if n is ProgressBar:
		out.append(n)
	for ch in n.get_children():
		out.append_array(_bars(ch))
	return out

func test_plate_shows_a_fresh_creature_full_even_mid_drain() -> void:
	var hud := BattleHUD.new()
	runner.root.add_child(hud)  # in the tree, so the plate's tweens are real ones
	if hud.plates.is_empty():
		hud._ready()
	var p: BattleHUD.Plate = hud.plates[Battle.PLAYER]
	var tired := Fixtures.creature("kindlet", 20)
	tired.hp = 3
	p.set_creature(tired)
	assert_near(p.hp_bar.value, 3.0 / tired.max_hp(), 0.001)
	p.tween_hp(0.0, 1.0)  # the drain that finishes it off is still running...
	var fresh := Fixtures.creature("spikkin", 20)  # ...when the next one comes in at full health
	p.set_creature(fresh)
	assert_eq(p.hp_shown, float(fresh.hp))
	assert_near(p.hp_bar.value, 1.0, 0.0001, "the plate's bar is full")
	assert_eq(p.hp_text.text, "%d / %d" % [fresh.hp, fresh.max_hp()])
	assert_true(p._hp_tween == null or not p._hp_tween.is_valid(), "the old drain is dead, so it can't pull the new bar down")
	hud.free()

func test_a_regional_form_keeps_a_full_creature_full() -> void:
	var c := Fixtures.creature("volet", 20)  # Skomer volets lean +4 HP
	var before := c.max_hp()
	Forms.apply(c, "skomer")
	assert_eq(c.form, "skomer")
	assert_true(c.max_hp() > before, "the form raises the max")
	assert_eq(c.hp, c.max_hp(), "a wild one appears at full health, so its plate's bar starts full")
	var hurt := Fixtures.creature("volet", 20)
	hurt.hp = 10
	Forms.apply(hurt, "skomer")
	assert_eq(hurt.hp, 10, "a hurt one keeps its wounds")

# --- the map's route line ----------------------------------------------------------------------------------

static func _rail() -> Array:
	return [PackedVector2Array([Vector2(0, 0), Vector2(50, 0), Vector2(100, 0)]), PackedVector2Array([Vector2(100, 0), Vector2(100, 50)])]

func test_rail_leg_runs_along_the_line_between_two_stations() -> void:
	var leg := MapLogic.rail_leg(_rail(), Vector2(0, 5), Vector2(104, 55))
	assert_eq(Array(leg), [Vector2(0, 0), Vector2(50, 0), Vector2(100, 0), Vector2(100, 50)], "across the join of two drawn lines")
	var mid := MapLogic.rail_leg(_rail(), Vector2(25, 3), Vector2(103, 20))
	assert_eq(Array(mid), [Vector2(25, 0), Vector2(50, 0), Vector2(100, 0), Vector2(100, 20)], "stations part way along a stretch join it there")
	var branch := [PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]), PackedVector2Array([Vector2(50, 2), Vector2(50, 60)])]
	assert_eq(Array(MapLogic.rail_leg(branch, Vector2(0, 0), Vector2(50, 60))), [Vector2(0, 0), Vector2(50, 0), Vector2(50, 2), Vector2(50, 60)], "a branch line that stops just short of the main line is joined to it")
	assert_eq(MapLogic.rail_leg(_rail(), Vector2(0, 5), Vector2(300, 300)).size(), 0, "a station off the network draws straight")

func test_route_legs_follow_rail_and_ferry_but_walks_go_straight() -> void:
	var zones := {"a": {"pos": Vector2(0, 5)}, "b": {"pos": Vector2(104, 55)}, "c": {"pos": Vector2(150, 60)}, "d": {"pos": Vector2(250, 60)}}
	var g := {"walk": {"b": {"c": true}, "c": {"b": true}}, "station": {"a": "gb", "b": "gb"}, "ferry": {"c": ["d", "cd"], "d": ["c", "cd"]}, "kind": {}}
	var ferry := {"cd": PackedVector2Array([Vector2(250, 60), Vector2(200, 40), Vector2(150, 60)])}  # drawn d to c
	var pts := MapLogic.route_legs(["a", "b", "c", "d"], zones, g, _rail(), ferry)
	assert_eq(Array(pts), [Vector2(0, 5), Vector2(0, 0), Vector2(50, 0), Vector2(100, 0), Vector2(100, 50), Vector2(104, 55), Vector2(150, 60), Vector2(200, 40), Vector2(250, 60)])
	assert_eq(Array(MapLogic.route_legs(["b", "c"], zones, g, _rail(), ferry)), [Vector2(104, 55), Vector2(150, 60)], "a walk is town to town")
	assert_eq(Array(MapLogic.route_points(["a", "b"], zones)), [Vector2(0, 5), Vector2(104, 55)], "the plain points still work")

func test_real_rail_hops_follow_the_drawn_railway() -> void:
	var s := MapView.shapes()
	var pairs := 0
	var straight := []
	var g := ZoneGraph.shared()
	var stations: Array = g.station.keys()
	for i in mini(stations.size(), 12):
		for j in range(i + 1, mini(stations.size(), 12)):
			var a: String = stations[i]
			var b: String = stations[j]
			if g.station[a] != g.station[b]:
				continue
			var pa: Vector2 = ZoneIndex.get_index().zones.get(a, {}).get("pos", Vector2(-1, -1))
			var pb: Vector2 = ZoneIndex.get_index().zones.get(b, {}).get("pos", Vector2(-1, -1))
			if pa.x < 0 or pb.x < 0:
				continue
			if MapLogic._snap(MapLogic._rail_net(s.rail), pa).is_empty() or MapLogic._snap(MapLogic._rail_net(s.rail), pb).is_empty():
				continue  # a station with no railway drawn to it (Cairnryan) is drawn straight, by design
			pairs += 1
			if MapLogic.rail_leg(s.rail, pa, pb).size() < 2:
				straight.append("%s-%s" % [a, b])
	assert_true(pairs > 0, "some station pairs to check")
	assert_eq(straight, [], "every same-island station pair is joined by drawn railway")
