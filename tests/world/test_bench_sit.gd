extends TestCase
## Sit down: finding the bench, and how much fast-forward an evening gets.

func test_finds_a_bench_on_the_tile() -> void:
	var props := [{"type": "lamp_post", "x": 3, "y": 3}, {"type": "bench", "x": 4, "y": 3}]
	assert_false(BenchSit.bench_at(props, Vector2i(4, 3)).is_empty())
	assert_true(BenchSit.bench_at(props, Vector2i(3, 3)).is_empty(), "a lamp post is not a seat")
	assert_true(BenchSit.bench_at(props, Vector2i(9, 9)).is_empty())

func test_fast_clock_has_a_cap_per_sitting_and_per_day() -> void:
	assert_eq(BenchSit.boost_left(0, 0), BenchSit.SIT_CAP)
	assert_eq(BenchSit.boost_left(0, 100), BenchSit.SIT_CAP - 100)
	assert_eq(BenchSit.boost_left(BenchSit.DAY_CAP - 30, 0), 30, "the day's allowance runs low")
	assert_eq(BenchSit.boost_left(BenchSit.DAY_CAP, 0), 0)
	assert_eq(BenchSit.boost_left(0, 999), 0, "never negative")

func test_fast_clock_stops_before_midnight() -> void:
	assert_true(BenchSit.fast_clock(0, 0, 18 * 60))
	assert_false(BenchSit.fast_clock(0, 0, 23 * 60 + 50))
	assert_false(BenchSit.fast_clock(BenchSit.DAY_CAP, 0, 12 * 60))

func test_minutes_between_never_wraps() -> void:
	assert_eq(BenchSit.minutes_between(100, 160), 60)
	assert_eq(BenchSit.minutes_between(1430, 5), 0)

func test_which_inputs_stand_you_up() -> void:
	var k := InputEventKey.new()
	k.pressed = true
	assert_true(BenchSit.is_stand_event(k))
	k.echo = true
	assert_false(BenchSit.is_stand_event(k), "a key held down isn't a new press")
	var r := InputEventKey.new()
	r.pressed = false
	assert_false(BenchSit.is_stand_event(r), "a release isn't either")
	assert_false(BenchSit.is_stand_event(InputEventMouseMotion.new()))

func test_the_street_carries_on_while_you_sit() -> void:
	var was := Router.busy
	Router.busy = true
	BenchSit.sitting = false
	assert_true(Npc.street_stopped(), "a scene still freezes everyone")
	BenchSit.sitting = true
	assert_false(Npc.street_stopped(), "a seated player does not")
	BenchSit.sitting = false
	Router.busy = was

func test_a_late_sitting_can_run_through_to_dawn_once_a_night() -> void:
	assert_true(BenchSit.night_sitting(21 * 60, 4, 3))
	assert_true(BenchSit.night_sitting(23 * 60 + 30, 4, -1))
	assert_false(BenchSit.night_sitting(20 * 60 + 59, 4, 3), "before nine it is just an evening")
	assert_false(BenchSit.night_sitting(22 * 60, 4, 4), "once a night")
	assert_eq(BenchSit.night_minutes(22 * 60), 2 * 60 + BenchSit.DAWN_STOP)
	assert_true(BenchSit.fast_clock(BenchSit.DAY_CAP, 300, 3 * 60, 22 * 60), "the day's cap and midnight do not stop it")
	assert_true(BenchSit.fast_clock(0, 0, 23 * 60 + 50, 22 * 60))
	assert_false(BenchSit.fast_clock(0, BenchSit.night_minutes(22 * 60), 5 * 60 + 10, 22 * 60), "dawn ends it")
	assert_true(BenchSit.DAWN_STOP >= 5 * 60, "05:10 is inside the dawn window")
	assert_false(BenchSit.fast_clock(0, 0, 23 * 60 + 50), "an ordinary sitting still stops at 23:45")
