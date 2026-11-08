extends TestCase

func test_a_building_hides_what_is_just_behind_it() -> void:
	var r := Rect2(10, 10, 6, 3)  # x 10..16, z 10..13
	assert_true(OccluderFade.hides(r, Vector2(12.5, 9.5)), "right behind the back wall")
	assert_true(OccluderFade.hides(r, Vector2(12.5, 7.0)), "a couple of tiles further back, under the roofline")
	assert_false(OccluderFade.hides(r, Vector2(12.5, 5.0)), "far enough back to see over it")
	assert_false(OccluderFade.hides(r, Vector2(12.5, 13.5)), "in front of it")
	assert_false(OccluderFade.hides(r, Vector2(20.5, 9.5)), "off to the side")

func test_a_tall_building_hides_further_behind_it() -> void:
	assert_eq(OccluderFade.reach(3.0), OccluderFade.BEHIND, "a cottage")
	assert_eq(OccluderFade.reach(OccluderFade.HOUSE_TOP), OccluderFade.BEHIND, "a two-storey house")
	assert_true(OccluderFade.reach(6.5) > 5.5, "a four-storey mill hides you from five or six tiles back")
	assert_eq(OccluderFade.reach(40.0), OccluderFade.MAX_BEHIND, "never the whole street")
	var r := Rect2(50, 11, 10, 4)  # Blackpool's Illuminations Depot, with the station door 4.5 tiles behind it
	assert_false(OccluderFade.hides(r, Vector2(55.5, 6.5)))
	assert_true(OccluderFade.hides(r, Vector2(55.5, 6.5), OccluderFade.reach(6.5)))
