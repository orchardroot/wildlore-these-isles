extends TestCase
## NightSky: the moon's real phase for a date, where it is, and how many stars show.

func test_julian_day_of_a_known_date() -> void:
	assert_eq(NightSky.julian_day(2000, 1, 1), 2451545, "the J2000 noon")
	assert_eq(NightSky.julian_day(2026, 11, 13) - NightSky.julian_day(2026, 11, 12), 1)

func test_phase_on_dates_with_a_known_moon() -> void:
	# New moon 2026-11-09 and full moon 2026-11-24 (UTC); the phase is read at noon, so allow a day.
	var new_moon := NightSky.moon_phase(2026, 11, 9)
	assert_true(new_moon < 0.04 or new_moon > 0.96, "new moon on the 9th of November 2026 (%.3f)" % new_moon)
	assert_near(NightSky.moon_phase(2026, 11, 24), 0.5, 0.04, "full on the 24th")
	assert_near(NightSky.moon_phase(2026, 11, 16), 0.25, 0.05, "first quarter a week after new")
	assert_near(NightSky.moon_phase(2000, 1, 21), 0.5, 0.04, "full moon of 21 January 2000 (the eclipse)")
	assert_near(NightSky.moon_phase(2024, 4, 9), 0.0, 0.04, "new moon of the April 2024 eclipse")

func test_phase_names() -> void:
	assert_eq(NightSky.phase_name(0.0), "new moon")
	assert_eq(NightSky.phase_name(0.99), "new moon")
	assert_eq(NightSky.phase_name(0.14), "waxing crescent")
	assert_eq(NightSky.phase_name(0.25), "first quarter")
	assert_eq(NightSky.phase_name(0.5), "full moon")
	assert_eq(NightSky.phase_name(0.75), "last quarter")
	assert_eq(NightSky.phase_name(0.88), "waning crescent")

func test_illumination() -> void:
	assert_near(NightSky.illumination(0.0), 0.0, 0.001)
	assert_near(NightSky.illumination(0.25), 0.5, 0.001)
	assert_near(NightSky.illumination(0.5), 1.0, 0.001)
	assert_near(NightSky.illumination(0.75), 0.5, 0.001)

func test_stars_by_the_clock() -> void:
	assert_eq(NightSky.darkness(12 * 60), 0.0, "none at noon")
	assert_eq(NightSky.darkness(18 * 60), 0.0, "nor at six")
	assert_eq(NightSky.darkness(23 * 60), 1.0)
	assert_eq(NightSky.darkness(2 * 60), 1.0)
	var dusk := NightSky.darkness(20 * 60)
	assert_true(dusk > 0.1 and dusk < 0.9, "coming out at dusk")
	assert_true(NightSky.darkness(5 * 60 + 30) < 1.0 and NightSky.darkness(5 * 60 + 30) > 0.0, "going with the dawn")
	assert_eq(NightSky.darkness(8 * 60), 0.0)

func test_cloud_hides_the_stars() -> void:
	assert_eq(NightSky.clearness("clear"), 1.0)
	assert_eq(NightSky.clearness("frost"), 1.0)
	assert_true(NightSky.clearness("downpour") < NightSky.clearness("drizzle"))
	assert_true(NightSky.look(23 * 60, 0.5, "downpour").stars < 0.2)
	assert_eq(NightSky.look(23 * 60, 0.5, "clear").stars, 1.0)
	assert_eq(NightSky.look(12 * 60, 0.5, "clear").stars, 0.0)

func test_a_full_moon_is_up_all_night_and_a_new_moon_never() -> void:
	for h in [21, 23, 1, 3, 5]:
		assert_true(NightSky.moon_up(h * 60, 0.5) > 0.9, "full moon at %d:00" % h)
	assert_true(NightSky.moon_up(12 * 60, 0.5) < 0.01, "not at noon")
	for h in [21, 0, 3]:
		assert_true(NightSky.moon_up(h * 60, 0.0) < 0.01, "no new moon at %d:00" % h)
	assert_true(NightSky.moon_up(20 * 60, 0.25) > 0.9, "a first quarter sits in the evening sky")
	assert_true(NightSky.moon_up(3 * 60, 0.25) < 0.01, "and has set by three")

func test_the_moon_crosses_the_sky_east_to_west() -> void:
	var rising := NightSky.moon_position(19 * 60, 0.5)
	var setting := NightSky.moon_position(5 * 60, 0.5)
	assert_true(rising.x < 0.0 and setting.x > 0.0, "rises on the left, sets on the right")
	assert_true(NightSky.moon_position(0, 0.5).y >= rising.y, "highest at midnight when full")
	for h in range(0, 24):
		var m := NightSky.moon_position(h * 60, 0.5)
		assert_true(m.y > 0.7 and m.y <= 1.0 and absf(m.x) <= 1.78, "on the picture at %d:00" % h)

func test_look_has_what_the_shader_wants() -> void:
	var l := NightSky.look(0, 0.5, "clear")
	for k in ["stars", "moon_on", "moon_phase", "moon_pos"]:
		assert_true(l.has(k), k)
	assert_true(l.moon_on > 0.9)
	assert_eq(NightSky.look(12 * 60, 0.5, "clear").moon_on, 0.0, "no moon painted on the day sky")
