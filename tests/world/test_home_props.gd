extends TestCase
## The regional home pieces (w53): range, settle, box bed.

func test_home_props_build_and_are_registered() -> void:
	for name in HomeProps.NAMES:
		assert_true(name in ZoneBuilder.POINT_PROPS, name + " is registered")
		for v in 2:
			var mesh: ArrayMesh = ZoneBuilder._ctor(name, v)
			assert_true(mesh.get_surface_count() > 0, name + " has geometry")
