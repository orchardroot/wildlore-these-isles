extends TestCase
## The ground answers your feet: what each tile leaves behind, and the pool's bookkeeping.

func test_traces_by_tile_and_weather() -> void:
	assert_eq(Footfalls.trace_for("shallow", "clear"), "ripple")
	assert_eq(Footfalls.trace_for("sand", "clear"), "sand")
	assert_eq(Footfalls.trace_for("grass", "frost"), "frost")
	assert_eq(Footfalls.trace_for("path", "frost"), "frost")
	assert_eq(Footfalls.trace_for("grass", "clear"), "")
	assert_eq(Footfalls.trace_for("road", "frost"), "", "tarmac doesn't hold a print")
	assert_eq(Footfalls.trace_for("door", "clear"), "")

func test_grass_and_flowers_rustle() -> void:
	assert_true(Footfalls.rustles("tall_grass"))
	assert_true(Footfalls.rustles("flowers"))
	assert_false(Footfalls.rustles("grass"))

func test_off_on_low_and_indoors() -> void:
	assert_true(Footfalls.active("medium", false))
	assert_true(Footfalls.active("high", false))
	assert_false(Footfalls.active("low", false))
	assert_false(Footfalls.active("high", true))

func test_fade_runs_from_one_to_nothing() -> void:
	assert_near(Footfalls.fade(0.0, 4.0), 1.0)
	assert_near(Footfalls.fade(2.0, 4.0), 0.5)
	assert_eq(Footfalls.fade(9.0, 4.0), 0.0)

func test_pool_recycles_round_robin() -> void:
	var i := 0
	for k in Footfalls.POOL:
		i = Footfalls.next_slot(i, Footfalls.POOL)
	assert_eq(i, 0, "a full lap lands back at the start")
