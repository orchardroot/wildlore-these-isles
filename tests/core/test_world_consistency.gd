extends TestCase
## WorldConsistency: each rule catches its case on a small made-up zone, and leaves the fixed version alone.

func _zone(id: String, kind: String, rows: Array, extra := {}) -> ZoneData:
	var d := {"id": id, "name": id.capitalize(), "region": "", "kind": kind, "music": "", "weather": {}, "props": [],
		"warps": [], "edges": {}, "npcs": [], "encounters": {}, "signs": [], "spawn": [1, 1], "rows": rows}
	d.merge(extra, true)
	return ZoneData.from_dict(d)

func _rules(zones: Dictionary, dialogue := {}) -> Array:
	return WorldConsistency.findings(zones, dialogue).map(func(f): return "%s:%s:%s" % [f.rule, f.zone, f.key])

func test_a_lever_by_the_desk_wants_a_lever() -> void:
	var rows := ["xxxxxx", "x++++x", "x++++x", "x+D++x", "xxxxxx"]
	var talk := {"room": {"guide": [{"do": "say", "who": "Gwen", "text": "Pull the lever by the desk."}]}}
	var npc := [{"id": "guide", "x": 1, "y": 1, "script": "guide"}]
	var bare := _zone("room", "interior", rows, {"npcs": npc, "props": [{"type": "table", "x": 3, "y": 1}]})
	assert_true("object:room:lever" in _rules({"room": bare}, talk))
	var fixed := _zone("room", "interior", rows, {"npcs": npc, "props": [{"type": "table", "x": 3, "y": 1}],
		"deep": {"levers": [{"id": "g", "x": 4, "y": 1, "on": "Clunk."}]}})
	assert_false("object:room:lever" in _rules({"room": fixed}, talk))

func test_upstairs_in_a_room_with_one_door() -> void:
	var z := _zone("shop", "interior", ["xxxx", "x++x", "x+Dx", "xxxx"], {"signs": [{"x": 1, "y": 1, "text": "More upstairs."}],
		"warps": [{"x": 2, "y": 2, "to": "town", "tx": 1, "ty": 1}]})
	assert_true("stairs:shop:upstairs" in _rules({"shop": z}))

func test_a_cave_needs_a_mouth_and_a_warp_needs_a_way_in() -> void:
	var cave := _zone("hole", "interior", ["xxxx", "x++x", "x+Dx", "xxxx"], {"dark": true, "name": "Hole Cave"})
	var rows := ["......", "......", "......", "......", "......"]
	var cottage := _zone("town", "town", rows, {"warps": [{"x": 2, "y": 2, "to": "hole", "tx": 2, "ty": 2}],
		"props": [{"type": "building", "style": "red_brick", "x": 1, "y": 1, "w": 3, "h": 2}]})
	assert_true("cave:town:hole" in _rules({"town": cottage, "hole": cave}))
	var mouth := _zone("town", "town", rows, {"warps": [{"x": 2, "y": 2, "to": "hole", "tx": 2, "ty": 2}],
		"props": [{"type": "building", "style": "cave_mouth", "x": 1, "y": 1, "w": 3, "h": 2}]})
	assert_eq(_rules({"town": mouth, "hole": cave}).filter(func(r): return r.begins_with("cave:")), [])
	var nothing := _zone("town", "town", rows, {"warps": [{"x": 2, "y": 2, "to": "hole", "tx": 2, "ty": 2}]})
	assert_true("entrance:town:hole" in _rules({"town": nothing, "hole": cave}))
	var hole := _zone("town", "town", rows, {"warps": [{"x": 2, "y": 2, "to": "hole", "tx": 2, "ty": 2}],
		"props": [{"type": "cave_cleft", "x": 2, "y": 2, "walk": true}]})
	assert_eq(_rules({"town": hole, "hole": cave}), [])

func test_a_warp_behind_brambles_wants_a_hint() -> void:
	var rows := ["........", "........", "%%%%%%%%", "........", "........"]
	var gated := _zone("lane", "route", rows, {"warps": [{"x": 3, "y": 4, "to": "barn", "tx": 1, "ty": 1}],
		"props": [{"type": "building", "style": "field_barn", "x": 2, "y": 3, "w": 3, "h": 2}]})
	assert_true("blocker:lane:barn" in _rules({"lane": gated}))
	var signed := _zone("lane", "route", rows, {"warps": [{"x": 3, "y": 4, "to": "barn", "tx": 1, "ty": 1}],
		"props": [{"type": "building", "style": "field_barn", "x": 2, "y": 3, "w": 3, "h": 2}],
		"signs": [{"x": 5, "y": 1, "text": "Brambles. Hedge-lay, from the Brook Stone, clears them."}]})
	assert_false("blocker:lane:barn" in _rules({"lane": signed}))

func test_leftovers_in_text() -> void:
	var z := _zone("t", "town", ["...", "..."], {"signs": [{"x": 0, "y": 0, "text": "Hello {nmae} and and TODO .."}]})
	var got := WorldConsistency.findings({"t": z}, {}).map(func(f): return f.text)
	assert_eq(got.size(), 4, str(got))  # the brace, TODO, the doubled word, the stray dots
	var fine := _zone("t", "town", ["...", "..."], {"signs": [{"x": 0, "y": 0, "text": "{greeting} Mind the gap... it bites."}]})
	assert_eq(WorldConsistency.findings({"t": fine}, {}), [])

func test_deep_place_looks_must_be_known() -> void:
	var z := _zone("c", "interior", ["xxxx", "x++x", "x++x", "xxxx"], {"deep": {"gates": [{"x": 1, "y": 1, "by": [], "line": "Shut.", "look": "portcullis"}]}})
	assert_eq(DeepPlace.problems(z).size(), 1)

func test_the_lever_by_the_desk_is_by_the_desk() -> void:
	var rows := ["xxxxxx", "x++++x", "x++++x", "x+D++x", "xxxxxx"]
	var talk := {"room": {"guide": [{"do": "say", "who": "Gwen", "text": "The lever by the desk works it."}]}}
	var npc := [{"id": "guide", "x": 2, "y": 1, "script": "guide"}]
	var far := _zone("room", "interior", rows, {"npcs": npc, "props": [{"type": "table", "x": 1, "y": 1}],
		"deep": {"levers": [{"id": "g", "x": 4, "y": 3, "on": "Clunk."}]}})
	assert_true(_rules({"room": far}, talk).any(func(r): return r.begins_with("near:room:")), "across the room is not by the desk")
	var close := _zone("room", "interior", rows, {"npcs": npc, "props": [{"type": "table", "x": 3, "y": 1}],
		"deep": {"levers": [{"id": "g", "x": 4, "y": 1, "on": "Clunk."}]}})
	assert_false(_rules({"room": close}, talk).any(func(r): return r.begins_with("near:room:")))
