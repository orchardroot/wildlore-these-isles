extends TestCase
## The coracle (wave 54): Brook-wade paddles every river and lake, Tide-ride the sea near a shore, never across a zone
## edge, never in a no_ride rect, never indoors.

const FRESH := ["brook_wade"]
const BOTH := ["brook_wade", "tide_ride"]

func _zone(rows: Array, extra := {}) -> ZoneData:
	var d := {"id": "rz", "name": "R", "kind": "route", "rows": rows, "spawn": [0, 0],
		"encounters": {"water": [{"species": "dolphlet", "min": 20, "max": 20, "weight": 1}]}}
	d.merge(extra, true)
	return ZoneData.from_dict(d)

func test_rivers_and_lakes_need_brook_wade() -> void:
	var z := _zone(["...", ".~.", "..."])
	assert_false(z.walkable(Vector2i(1, 1)), "on foot")
	assert_false(z.walkable(Vector2i(1, 1), Vector2i.ZERO, ["hedge_lay", "tide_ride"]), "the Tide Stone is not a river's")
	assert_true(z.walkable(Vector2i(1, 1), Vector2i.ZERO, FRESH))
	assert_true(z.reachable(Vector2i(0, 0), FRESH).has(Vector2i(2, 2)))
	assert_false(z.reachable(Vector2i(0, 0), []).has(Vector2i(1, 1)))

func test_the_sea_needs_tide_ride_and_a_shore_within_three_tiles() -> void:
	var rows := ["......", "$$$$$$", "$$$$$$", "$$$$$$", "$$$$$$", "$$$$$$"]
	var z := _zone(rows)
	for y in [1, 2, 3]:
		assert_true(z.sea_near_shore(Vector2i(2, y)), "row %d is within three tiles of the grass" % y)
		assert_true(z.walkable(Vector2i(2, y), Vector2i.ZERO, BOTH))
		assert_false(z.walkable(Vector2i(2, y), Vector2i.ZERO, FRESH), "Brook-wade is not a sea-going ability")
	assert_false(z.walkable(Vector2i(2, 4), Vector2i.ZERO, BOTH), "four tiles out is the open sea")
	assert_false(z.walkable(Vector2i(2, 5), Vector2i.ZERO, BOTH))
	assert_false(z.walkable(Vector2i(2, 1)), "no boat, no sea")

func test_void_is_not_a_shore() -> void:
	var z := _zone(["xxxxxx", "$$$$$$", "$$$$$$"])
	assert_false(z.sea_near_shore(Vector2i(2, 1)))

func test_never_across_an_edge() -> void:
	var rows := ["~~~~~", "~...~", "~...~", "~...~", "~~~~~"]
	var edged := _zone(rows, {"edges": {"east": {"to": "other"}}})
	assert_true(edged.can_ride(Vector2i(0, 2), FRESH), "west has no edge: the bank is just a wall")
	assert_false(edged.can_ride(Vector2i(4, 2), FRESH), "the current's too strong at an east edge")
	assert_false(edged.can_ride(Vector2i(4, 0), FRESH), "a corner counts as the east border too")
	assert_true(edged.can_ride(Vector2i(2, 0), FRESH))
	var north := _zone(rows, {"edges": {"north": {"to": "other"}, "south": {"to": "other"}}})
	assert_false(north.can_ride(Vector2i(2, 0), FRESH))
	assert_false(north.can_ride(Vector2i(2, 4), FRESH))
	assert_true(north.can_ride(Vector2i(0, 2), FRESH))
	assert_eq(north.reachable(Vector2i(2, 2), FRESH).has(Vector2i(2, 0)), false)

func test_no_ride_rects_close_only_what_they_cover() -> void:
	var z := _zone(["~~~~~~"], {"no_ride": [[2, 0, 2, 1]]})
	assert_true(z.can_ride(Vector2i(1, 0), FRESH))
	assert_false(z.can_ride(Vector2i(2, 0), FRESH))
	assert_false(z.can_ride(Vector2i(3, 0), FRESH))
	assert_true(z.can_ride(Vector2i(4, 0), FRESH))

func test_no_ride_in_rooms_and_deep_places() -> void:
	assert_false(_zone(["~~"], {"kind": "interior"}).can_ride(Vector2i(0, 0), FRESH))
	assert_false(_zone(["~~"], {"deep": {"levers": []}}).can_ride(Vector2i(0, 0), FRESH))

func test_the_baseline_token_turns_riding_off_but_not_deep_water() -> void:
	var z := _zone(["~o"])
	var base := ZoneData.GATE_ABILITIES
	assert_false(z.walkable(Vector2i(0, 0), Vector2i.ZERO, base), "the validator's layout checks never count a river")
	assert_true(z.walkable(Vector2i(1, 0), Vector2i.ZERO, base), "deep water is still the old Brook-wade crossing")

func test_tide_stone_grants_tide_ride_and_old_saves_get_both() -> void:
	var d := GameStateData.new()
	d.badges = ["brook", "urban", "stone", "iron", "frost", "tide"]
	assert_true(FieldMoves.has(d, "tide_ride"))
	assert_true(FieldMoves.has(d, "brook_wade"))
	d.badges = ["brook"]
	assert_false(FieldMoves.has(d, "tide_ride"))

func test_block_hints_for_water() -> void:
	var d := GameStateData.new()
	var z := _zone(["~~~~~~~~~~", "..........", "$$$$$$$$$$"], {"edges": {"west": {"to": "other"}}})
	assert_true(FieldMoves.block_hint(d, z, Vector2i(3, 0)).contains("Brook-wade"), FieldMoves.block_hint(d, z, Vector2i(3, 0)))
	assert_true(FieldMoves.block_hint(d, z, Vector2i(3, 0)).contains("Keeper Ray in Liverpool"))
	assert_true(FieldMoves.block_hint(d, z, Vector2i(3, 2)).contains("Tide-ride"))
	assert_true(FieldMoves.block_hint(d, z, Vector2i(3, 2)).contains("Keeper Nuala in Galway"))
	d.badges = ["brook", "urban", "tide"]
	assert_eq(FieldMoves.block_hint(d, z, Vector2i(3, 0)), "", "paddle on")
	assert_true(FieldMoves.block_hint(d, z, Vector2i(0, 0)).contains("current"), "the edge tile says why it is shut")
	var open_sea := _zone(["......", "$$$$$$", "$$$$$$", "$$$$$$", "$$$$$$", "$$$$$$"])
	assert_eq(FieldMoves.block_hint(GameStateData.new(), open_sea, Vector2i(2, 5)), "", "far sea is just a wall")
	assert_eq(FieldMoves.verdict(d, open_sea, Vector2i(2, 5)), "")
	assert_eq(FieldMoves.verdict(d, open_sea, Vector2i(2, 2)), "wade")

func test_a_shore_of_bumps_is_one_hint() -> void:
	var z := _zone(["~~~", "..."])
	assert_eq(FieldMoves.hint_key(z, Vector2i(0, 0)), FieldMoves.hint_key(z, Vector2i(2, 0)))
	assert_true(FieldMoves.hint_key(z, Vector2i(0, 1)) is Vector2i, "other tiles keep their own")

func test_water_table_fires_on_any_ride_tile() -> void:
	var z := _zone(["~$"])
	for tile in ["water", "sea", "deep_water"]:
		assert_eq(Encounters.step_chance(tile), 5.0, tile)
		var hit := {}
		for i in 200:
			var e := Encounters.roll(z, tile, "day", "clear", Rng.new(i))
			if not e.is_empty():
				hit = e
		assert_eq(hit.get("species", ""), "dolphlet", tile)
	var bare := ZoneData.from_dict({"id": "b", "rows": ["~"], "spawn": [0, 0]})
	for i in 200:
		assert_true(Encounters.roll(bare, "water", "day", "clear", Rng.new(i)).is_empty(), "no table, no encounter")

func test_ride_tiles_float_at_the_surface() -> void:
	var z := _zone(["~$o."])
	assert_true(ZoneData.RIDE_TILES.has(z.tile_at(Vector2i(0, 0))))
	assert_true(ZoneData.RIDE_TILES.has(z.tile_at(Vector2i(1, 0))))
	assert_true(ZoneData.RIDE_TILES.has(z.tile_at(Vector2i(2, 0))))
	assert_false(ZoneData.RIDE_TILES.has(z.tile_at(Vector2i(3, 0))))
