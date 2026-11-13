extends TestCase

const EXPECTED := {
	"cursor": 0.06, "confirm": 0.16, "cancel": 0.16, "bump": 0.12, "door": 0.45, "step_grass": 0.12,
	"hit": 0.25, "hit_super": 0.4, "hit_weak": 0.22, "faint": 0.8, "snare_throw": 0.35, "snare_wobble": 0.4,
	"caught": 0.9, "level_up": 0.8, "heal": 0.9, "badge": 1.4, "evolve": 1.8,
	"cut": 0.3, "splash": 0.6, "scramble": 0.7, "bike_bell": 0.7, "train": 1.4, "ship_horn": 1.6,
	"crow": 0.75, "tomb_light": 1.8, "harp_gliss": 1.9,
	"lantern_on": 1.3, "bog_squelch": 0.55, "bagpipe_drone": 2.0,
	"bell_toll": 3.2, "raven_caw": 0.9, "train_rush": 2.4,
	"step_path": 0.12, "step_stone": 0.1, "step_wood": 0.14, "step_sand": 0.15, "step_soft": 0.12, "step_wet": 0.16, "bike_tyre": 0.2,
	"talk_blip": 0.08, "sign_creak": 0.5, "shop_bell": 0.9, "sanctuary_chime": 1.4, "brake_squeal": 1.6,
	"radio_tune": 2.0,
	"atk_thud": 0.32, "atk_rustle": 0.4, "atk_splash": 0.45, "atk_crackle": 0.5, "atk_whoosh": 0.45, "atk_zap": 0.4,
	"atk_ice": 0.5, "atk_crunch": 0.4, "atk_squelch": 0.42, "atk_clang": 0.55, "atk_shimmer": 0.6, "atk_wail": 0.6,
	"encounter": 1.1, "stat_up": 0.45, "stat_down": 0.45, "weather_call": 1.3,
	"thunder": 6.0, "thunder_far": 6.5, "text_blip": 0.045,
}
const LOOPING := ["title", "town_cheshire", "route_forest", "route_moor", "battle_wild", "battle_trainer", "battle_keeper", "sanctuary",
	"town_city", "town_wales", "route_coast", "route_mountain", "battle_enclosure", "legend"]
## The first-hour tracks (2.1): a 64-bar body after a short intro that plays once, so they loop from past the intro.
const EXTENDED := ["title", "town_cheshire", "route_forest", "route_moor", "battle_wild", "battle_trainer"]

func test_sfx_length_peak_not_silent() -> void:
	for id in EXPECTED:
		var buf := SfxRecipes.render(id)
		var frames_expected: float = float(EXPECTED[id]) * SfxRecipes.SR
		assert_near(float(buf.size()), frames_expected, 1.0, id + " length")
		var p := Synth.peak(buf)
		assert_true(p >= 0.2 and p <= 0.95, "%s peak %s" % [id, str(p)])
		assert_true(Synth.rms(buf) > 0.01, id + " not silent")
		assert_near(buf[buf.size() - 1], 0.0, 0.01, id + " ends at zero")

func test_every_recipe_is_listed() -> void:
	assert_eq(SfxRecipes.ids().size(), EXPECTED.size())
	for id in EXPECTED:
		assert_has(SfxRecipes.ids(), id)

func test_sfx_generation_is_deterministic() -> void:
	for id in ["hit_super", "door", "evolve", "step_grass"]:
		assert_true(SfxRecipes.render(id) == SfxRecipes.render(id), id + " deterministic")

func test_stream_conversion() -> void:
	var s := Synth.to_stream(SfxRecipes.render("confirm"), SfxRecipes.SR)
	assert_eq(s.data.size(), SfxRecipes.render("confirm").size() * 2)
	assert_eq(s.loop_mode, AudioStreamWAV.LOOP_DISABLED)

func test_short_track_renders_and_is_deterministic() -> void:
	var c: Composer = load("res://tools/music/victory.gd").build()
	assert_true(c.errors.is_empty(), "victory melody bar lengths: " + str(c.errors))
	var a := c.render(11025)
	var b: PackedFloat32Array = load("res://tools/music/victory.gd").build().render(11025)
	assert_true(a == b, "music deterministic")
	assert_true(Synth.peak(a) <= 0.95 and Synth.peak(a) >= 0.2)

func test_music_loop_points_inside_data() -> void:
	for id in LOOPING:
		var path := "res://audio/music/%s.wav" % id
		assert_true(ResourceLoader.exists(path), id + " exists")
		var s: AudioStreamWAV = load(path)
		assert_eq(s.loop_mode, AudioStreamWAV.LOOP_FORWARD, id + " loops")
		# The importer may compress the data, so measure frames from the stream length, not the byte count.
		var secs := s.get_length()
		var frames := int(round(secs * s.mix_rate))
		assert_true(s.loop_begin >= 0 and s.loop_begin < s.loop_end, id + " begin < end")
		assert_true(s.loop_end <= frames, id + " end inside data")
		if id in EXTENDED:
			assert_true(secs >= 45.0 and secs <= 120.0, "%s length %s" % [id, str(secs)])
			assert_true(s.loop_begin > 0, id + " loops from after its intro")
		else:
			assert_true(secs >= 30.0 and secs <= 60.0, "%s length %s" % [id, str(secs)])
	var v: AudioStreamWAV = load("res://audio/music/victory.wav")
	assert_eq(v.loop_mode, AudioStreamWAV.LOOP_DISABLED)

func test_sfx_files_exist() -> void:
	for id in EXPECTED:
		assert_true(ResourceLoader.exists("res://audio/sfx/%s.wav" % id), id + " wav exists")

func test_m2_ids_registered_and_files_exist() -> void:
	for id in AudioIds.M2_SFX:
		assert_true(AudioIds.sfx_exists(id), id + " sfx registered and present")
		assert_has(SfxRecipes.ids(), id)
	for id in AudioIds.M2_MUSIC_LOOPING + AudioIds.M2_MUSIC_STINGS:
		assert_true(AudioIds.music_exists(id), id + " music present")

## Rendering is deterministic and identical to the shipped file, so the buffers are checked rather than the importer's output.
func test_m2_music_peak_length_and_loop_seam() -> void:
	for id in AudioIds.M2_MUSIC_LOOPING + AudioIds.M2_MUSIC_STINGS:
		var c: Composer = load("res://tools/music/%s.gd" % id).build()
		assert_true(c.errors.is_empty(), id + " bar lengths: " + str(c.errors))
		var buf := c.render(22050)
		var secs := buf.size() / 22050.0
		var p := Synth.peak(buf)
		assert_true(p >= 0.2 and p <= 0.95, "%s peak %s" % [id, str(p)])
		if id in AudioIds.M2_MUSIC_LOOPING:
			assert_true(c.loop, id + " loops")
			assert_true(secs >= 30.0 and secs <= 60.0, "%s length %s" % [id, str(secs)])
			assert_true(absf(buf[0]) < 0.05, "%s starts near zero (%s)" % [id, str(buf[0])])
			assert_true(absf(buf[buf.size() - 1]) < 0.05, "%s ends near zero (%s)" % [id, str(buf[buf.size() - 1])])
		else:
			assert_true(not c.loop, id + " does not loop")
			assert_true(secs >= 4.0 and secs <= 6.0, "%s length %s" % [id, str(secs)])
			assert_near(buf[buf.size() - 1], 0.0, 0.01, id + " ends at zero")
		var s: AudioStreamWAV = load("res://audio/music/%s.wav" % id)
		assert_near(s.get_length(), secs, 0.05, id + " file length matches the render")
		assert_eq(s.loop_mode, AudioStreamWAV.LOOP_FORWARD if id in AudioIds.M2_MUSIC_LOOPING else AudioStreamWAV.LOOP_DISABLED, id + " loop mode")

func test_no_intro_loops_from_the_start() -> void:
	var c: Composer = load("res://tools/music/victory.gd").build()
	assert_eq(c.intro_bars, 0)
	assert_eq(c.loop_begin_frame(22050), 0)

## The extended tracks: an intro, a 64-bar body, every phrase the right length, and a loop seam that sits on zero.
func test_extended_tracks_have_intro_and_64_bar_body() -> void:
	for id in EXTENDED:
		var c: Composer = load("res://tools/music/%s.gd" % id).build()
		assert_true(c.errors.is_empty(), id + " bar lengths: " + str(c.errors))
		assert_true(c.intro_bars >= 1 and c.intro_bars <= 4, "%s intro bars %d" % [id, c.intro_bars])
		assert_eq(c.bars - c.intro_bars, 64, id + " body bars")
		var buf := c.render(11025)
		var lb := c.loop_begin_frame(11025)
		assert_near(float(lb), c.intro_bars * c.upb * c.unit * 11025.0, 1.0, id + " loop begins at the intro's end")
		assert_true(lb > 0 and lb < buf.size(), id + " loop begin inside the buffer")
		assert_true(absf(buf[lb]) < 0.05, "%s near zero at loop begin (%s)" % [id, str(buf[lb])])
		assert_true(absf(buf[buf.size() - 1]) < 0.05, "%s near zero at the end (%s)" % [id, str(buf[buf.size() - 1])])
		assert_true(Synth.peak(buf) <= 0.95 and Synth.peak(buf) >= 0.2, "%s peak" % id)
