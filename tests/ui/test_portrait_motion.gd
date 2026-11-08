extends TestCase
## Portraits idle in their Motion style (wave 49).

func test_every_style_moves_within_the_frame() -> void:
	for s in Motion.STYLES:
		var lo := Vector2(99, 99)
		var hi := Vector2(-99, -99)
		var sq := 0.0
		for i in 400:
			var f := PortraitMotion.frame_for(s, i * 0.05, 288.0)
			lo = lo.min(f.shift)
			hi = hi.max(f.shift)
			sq = maxf(sq, absf(f.squash.y - 1.0))
			assert_true(f.squash.x > 0.8 and f.squash.y > 0.8, s + " squash")
		assert_true(hi.x - lo.x < 60.0 and hi.y - lo.y < 90.0, s + " travels too far: %s %s" % [lo, hi])
		assert_true(hi.distance_to(lo) > 0.5 or sq > 0.02, s + " does not move")

func test_floaters_rest_at_zero_height_baseline() -> void:
	var f := PortraitMotion.frame_for("hover", 0.0, 288.0)
	assert_true(absf(f.shift.y) < 1.0)

func test_gentle_is_smaller() -> void:
	var a := PortraitMotion.frame_for("hop", 0.3, 288.0, 0.0, 1.0)
	var b := PortraitMotion.frame_for("hop", 0.3, 288.0, 0.0, 0.3)
	assert_true(b.shift.length() <= a.shift.length() + 0.01)

func test_animate_sets_up_a_material() -> void:
	var s := AnimSprite.new()
	s.show_species("longlegs", "front", 2)
	s.animate({"id": "longlegs", "types": ["gale"]})
	assert_true(s.material is ShaderMaterial)
	var q := AnimSprite.new()
	q.show_species("longlegs", "front", 2, true)
	q.animate({"id": "longlegs", "types": ["gale"]})
	assert_true(q.material == null)
	s.free()
	q.free()
