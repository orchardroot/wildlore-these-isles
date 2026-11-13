extends TestCase
## See it, then fight it: a roamer near the player on the zone's table is the creature a grass encounter finds.

func test_nearest_listed_roamer_within_range() -> void:
	var spots := [["a", Vector2i(10, 10)], ["b", Vector2i(7, 5)], ["c", Vector2i(5, 8)]]
	assert_eq(RoamingCreatures.nearest_listed(spots, Vector2i(5, 5), ["a", "b", "c"], 4), 1, "b is 2 away, c is 3")
	assert_eq(RoamingCreatures.nearest_listed(spots, Vector2i(5, 5), ["a", "c"], 4), 2, "b isn't on the table")
	assert_eq(RoamingCreatures.nearest_listed(spots, Vector2i(5, 5), ["a"], 4), -1, "a is too far")
	assert_eq(RoamingCreatures.nearest_listed([], Vector2i(5, 5), ["a"], 4), -1)

func test_level_is_pulled_into_the_species_range() -> void:
	var z := ZoneData.new()
	z.encounters = {"grass": [{"species": "a", "min": 4, "max": 6}, {"species": "b", "min": 9, "max": 9}]}
	assert_eq(RoamingCreatures.level_in_table(z, "a", 12), 6)
	assert_eq(RoamingCreatures.level_in_table(z, "a", 5), 5)
	assert_eq(RoamingCreatures.level_in_table(z, "b", 3), 9)
	assert_eq(RoamingCreatures.level_in_table(z, "zz", 3), 3, "not on the table: untouched")
