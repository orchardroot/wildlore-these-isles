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
