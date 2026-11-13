class_name SkyAndLight
extends Node3D
## Sun, ambient, fog, glow and weather particles, driven by the game clock and the zone's weather.
## The overworld weather is kept in the save (GameStateData.weather_for) and changes mid-zone when it runs out,
## blending over BLEND_SECONDS. Interiors are told the outdoor weather but show none of it.

signal weather_changed(w: String)

const PHASES := {
	# sun colour, sun energy, sun pitch, ambient colour, ambient energy, background, window glow
	"dawn": [Color("ffc59a"), 0.8, -22.0, Color("b9a3c9"), 0.32, Color("e7b7a0"), 0.6],
	"day": [Color("fff4e0"), 0.62, -52.0, Color("c3d4e6"), 0.18, Color("9fc3dc"), 0.0],
	"dusk": [Color("ffa36b"), 0.7, -18.0, Color("a98bb0"), 0.3, Color("d98f74"), 1.2],
	"night": [Color("8fa6d9"), 0.25, -40.0, Color("3b4a78"), 0.3, Color("1b2238"), 2.2],
}
## Indoors: lamp colour, lamp energy, ambient colour, ambient energy. Bright and warm by day; at night the
## room is dimmer and cooler, lit by warmer lamps.
const INTERIOR_PHASES := {
	"dawn": [Color("ffdcb8"), 0.5, Color("c9b8b4"), 0.3],
	"day": [Color("ffe6c4"), 0.6, Color("e8d2b0"), 0.34],
	"dusk": [Color("ffc890"), 0.48, Color("a99ab0"), 0.28],
	"night": [Color("ffb877"), 0.42, Color("6d7599"), 0.25],
}

## Per-phase colour grade: [tonemap exposure, saturation, contrast]. Midday is graded richer
## (the plain filmic default washed bright zones out); dawn, dusk, night and interiors keep DEFAULT_GRADE.
const DEFAULT_GRADE := [0.92, 1.0, 1.04]
const PHASE_GRADE := {
	"day": [0.84, 1.2, 1.14],
}

## What each weather shows, 0..1: rain, fog sheets, blowing leaves, frost flecks, wet ground, frosty ground, slant.
enum { FX_RAIN, FX_FOG, FX_LEAVES, FX_FLECKS, FX_WET, FX_FROST, FX_SLANT, FX_COUNT }
const FX := {
	"drizzle": [0.35, 0.0, 0.0, 0.0, 0.6, 0.0, 0.1],
	"downpour": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.2],
	"fog": [0.0, 1.0, 0.0, 0.0, 0.15, 0.0, 0.0],
	"gale": [0.2, 0.0, 1.0, 0.0, 0.3, 0.0, 1.0],
	"frost": [0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0],
}
const NO_FX := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
const RAIN_MAX := 1400
const BLEND_SECONDS := 8.0

var sun: DirectionalLight3D
var env: Environment
var weather := "clear"
var interior := false
var follow: Node3D
## The weather's visible effects right now (blended), indexed by FX_*. AmbientLife reads gale and frost here.
var fx := PackedFloat32Array(NO_FX)
var _from := "clear"    # blending from this weather to `weather`
var _blend := 1.0
var _zone: ZoneData     # the overworld zone (null in battles): its weather can run out and change
var _low := false
## The overworld's full-screen pass (tilt_shift.gdshader): its haze and vignette follow the time of day.
var post: ShaderMaterial
var _rain: CPUParticles3D
var _fog: CPUParticles3D
var _leaves: CPUParticles3D
var _flecks: CPUParticles3D
var _splash: CPUParticles3D
var _sky_mat: ShaderMaterial    # the backdrop: stars and the moon after dark (art/shaders/night_sky.gdshader, NightSky)
var _flash: ColorRect           # a gentle lift of the whole picture as lightning strikes (never with Reduce Flashing)
var _flash_t := -1.0            # seconds since the strike; < 0 when none
var _strike_in := -1.0          # seconds to the next strike of thunder; < 0 when the weather has none
var _dice := RandomNumberGenerator.new()  # its own dice: the game's rng stays deterministic
const FLASH_PEAK := 0.09

func _ready() -> void:
	sun = DirectionalLight3D.new()
	sun.directional_shadow_max_distance = 40.0
	sun.shadow_blur = 1.5
	sun.rotation_degrees = Vector3(-52, -35, 0)
	add_child(sun)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.glow_intensity = 0.35
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	env.fog_enabled = true
	env.fog_density = 0.002
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	env.adjustment_contrast = 1.04
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED  # the sky is only a backdrop: nothing reflects it
	env.fog_sky_affect = 0.0  # and fog does not paint over it (the haze is the zone's own, in front of the world)
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = load("res://art/shaders/night_sky.gdshader")
	var sky_res := Sky.new()
	sky_res.sky_material = _sky_mat
	sky_res.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky_res
	we.environment = env
	add_child(we)
	_build_flash()
	_dice.randomize()
	_build_particles()
	apply_quality(Settings.quality)

# --- lightning -------------------------------------------------------------------

func _build_flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(0.86, 0.91, 1.0, 0.0)
	var cm := CanvasItemMaterial.new()
	cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_flash.material = cm
	_flash.visible = false
	layer.add_child(_flash)

## The lift at `t` seconds into a strike: a soft flash and a smaller second one a moment after. Zero by 1.2 s.
static func flash_alpha(t: float) -> float:
	if t < 0.0 or t > 1.2:
		return 0.0
	return FLASH_PEAK * minf(t / 0.03, 1.0) * (exp(-t * 7.0) + 0.55 * exp(-pow((t - 0.17) * 12.0, 2.0)))

## Thunder is timed here (it has the weather and the clock): the next strike comes after a gap that suits the weather.
func _arm_strike(first := false) -> void:
	var gap := Ambience.thunder_gap(weather, _dice.randf())
	_strike_in = gap * (0.4 if first else 1.0) if gap > 0.0 else -1.0

func _tick_thunder(delta: float) -> void:
	if _flash_t >= 0.0:
		_flash_t += delta
		_flash.color.a = flash_alpha(_flash_t)
		if _flash_t > 1.2:
			_flash_t = -1.0
			_flash.visible = false
	if _strike_in < 0.0 or _zone == null:
		return
	_strike_in -= delta
	if _strike_in > 0.0:
		return
	var close := _dice.randf() < (0.6 if weather == "downpour" else 0.35)
	var delay := _dice.randf_range(0.3, 1.2) if close else _dice.randf_range(1.5, 3.5)  # light is quicker than sound
	if not interior and not Settings.reduce_flashing:
		_flash_t = 0.0
		_flash.visible = true
	Audio.thunder(close, interior, delay)
	_arm_strike()

# --- particles -------------------------------------------------------------------

func _build_particles() -> void:
	_rain = _emitter(_soft_quad(Vector2(0.02, 0.38), null, false), 600, 0.9)
	_rain.emission_box_extents = Vector3(14, 0.5, 10)
	_rain.direction = Vector3(0.15, -1, 0.05)
	_rain.spread = 3.0
	_rain.initial_velocity_min = 14.0
	_rain.initial_velocity_max = 17.0
	_rain.gravity = Vector3(0, -6, 0)
	_rain.particle_flag_align_y = true  # streaks lean with the wind
	var soft := _soft_texture()
	_fog = _emitter(_soft_quad(Vector2(6.0, 2.4), soft, true), 10, 16.0)
	_fog.emission_box_extents = Vector3(13, 0.6, 9)
	_fog.direction = Vector3(1, 0, 0.1)
	_fog.spread = 10.0
	_fog.initial_velocity_min = 0.2
	_fog.initial_velocity_max = 0.45
	_fog.gravity = Vector3.ZERO
	_fog.preprocess = 16.0
	_fog.scale_amount_min = 0.8
	_fog.scale_amount_max = 1.5
	_fog.color_ramp = _fade_ramp()
	_leaves = _emitter(_soft_quad(Vector2(0.14, 0.1), null, true), 36, 3.2)
	_leaves.emission_box_extents = Vector3(4, 2.5, 9)
	_leaves.direction = Vector3(1, 0.15, 0.25)
	_leaves.spread = 18.0
	_leaves.initial_velocity_min = 5.0
	_leaves.initial_velocity_max = 8.0
	_leaves.gravity = Vector3(0, -0.8, 0)
	_leaves.angular_velocity_min = -360.0
	_leaves.angular_velocity_max = 360.0
	_leaves.angle_max = 360.0
	var autumn := Gradient.new()
	autumn.colors = PackedColorArray([Color("c9762f"), Color("a8552a"), Color("d9a441"), Color("7d8a3a")])
	autumn.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	_leaves.color_initial_ramp = autumn
	_flecks = _emitter(_soft_quad(Vector2(0.11, 0.11), soft, true), 110, 7.0)
	_flecks.emission_box_extents = Vector3(14, 2.0, 10)
	_flecks.direction = Vector3(0.3, -1, 0.1)
	_flecks.spread = 40.0
	_flecks.initial_velocity_min = 0.2
	_flecks.initial_velocity_max = 0.5
	_flecks.gravity = Vector3(0, -0.25, 0)
	_flecks.preprocess = 7.0
	_splash = _emitter(_soft_quad(Vector2(0.05, 0.05), null, true), 18, 0.35)
	_splash.emission_box_extents = Vector3(0.45, 0.0, 0.45)
	_splash.direction = Vector3(0, 1, 0)
	_splash.spread = 35.0
	_splash.initial_velocity_min = 1.0
	_splash.initial_velocity_max = 1.8
	_splash.gravity = Vector3(0, -9, 0)

func _emitter(mesh: Mesh, amount: int, lifetime: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = amount
	p.lifetime = lifetime
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.mesh = mesh
	add_child(p)
	return p

## An unshaded, see-through quad whose colour (and fade) comes from the particle colour.
func _soft_quad(size: Vector2, tex: Texture2D, billboard: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if tex:
		m.albedo_texture = tex
	q.material = m
	return q

static func _soft_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t

## Fades a particle in and out over its life (fog sheets drift in rather than pop).
static func _fade_ramp() -> Gradient:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.7, 1.0])
	return g

# --- weather -------------------------------------------------------------------

## The weather for an overworld zone: the persisted outdoor weather (see GameStateData.weather_for), or the
## --weather dev switch. Interiors get the outdoor weather too (for rain on the roof), shown as none.
func weather_for_zone(z: ZoneData) -> String:
	_zone = z
	var forced: String = Game.args.get("weather", "")
	if forced != "":
		return forced
	var table := Calendar.seasonal_weather(z.weather, Calendar.season_in(z.region))  # frost likelier in the place's winter
	return Game.data.weather_for(z.region, table, z.kind == "interior", Game.rng)

## `smooth`: blend from the current weather over BLEND_SECONDS (a change mid-zone); otherwise switch at once.
func set_weather(w: String, is_interior: bool, smooth := false) -> void:
	if smooth and w != weather and not is_interior:
		_from = weather
		_blend = 0.0
	else:
		_from = w
		_blend = 1.0
	var changed := w != weather
	weather = w
	interior = is_interior
	if changed or _strike_in < 0.0:
		_arm_strike(true)
	var want := maxi(_rain_amount(_from), _rain_amount(w))
	if want > 0 and _rain.amount != want:
		_rain.amount = want  # changing the amount restarts the emitter, so only when it must
	apply_time(Game.local_minutes())

func _rain_amount(w: String) -> int:
	var r: float = FX.get(w, NO_FX)[FX_RAIN]
	if r <= 0.0:
		return 0
	return int(RAIN_MAX * r * (0.5 if _low else 1.0))

## Weather that has run out changes mid-zone (outdoors, overworld only, never while pinned by --weather).
func _check_expiry() -> void:
	if _zone == null or interior or Game.args.get("weather", "") != "" or not Game.data.weather_expired():
		return
	var w := Game.data.weather_for(_zone.region, _zone.weather, false, Game.rng)
	if w != weather:
		set_weather(w, false, true)
		weather_changed.emit(w)

func _fx_now() -> void:
	var a: Array = NO_FX if interior else FX.get(_from, NO_FX)
	var b: Array = NO_FX if interior else FX.get(weather, NO_FX)
	var k := _blend * _blend * (3.0 - 2.0 * _blend)
	for i in FX_COUNT:
		fx[i] = lerpf(a[i], b[i], k)

func _apply_fx() -> void:
	var rain := fx[FX_RAIN]
	var full := float(_rain.amount) / RAIN_MAX
	_rain.emitting = rain > 0.01
	_rain.color = Color(0.8, 0.86, 0.95, 0.45 * clampf(rain / maxf(full, 0.05), 0.0, 1.0))
	_rain.direction = Vector3(lerpf(0.15, 0.9, fx[FX_SLANT]), -1, lerpf(0.05, 0.15, fx[FX_SLANT]))
	_fog.emitting = fx[FX_FOG] > 0.01
	_fog.color = Color(0.86, 0.88, 0.9, 0.45 * fx[FX_FOG])
	_leaves.emitting = fx[FX_LEAVES] > 0.01 and not _low
	_leaves.color = Color(1, 1, 1, fx[FX_LEAVES])
	_flecks.emitting = fx[FX_FLECKS] > 0.01 and not _low
	_flecks.color = Color(0.94, 0.97, 1.0, 0.8 * fx[FX_FLECKS])
	_splash.emitting = fx[FX_RAIN] > 0.6 and follow is Player and not _low
	_splash.color = Color(0.85, 0.9, 1.0, 0.6)
	if Meshes.ground:
		Meshes.ground.set_shader_parameter("wet", fx[FX_WET])
		Meshes.ground.set_shader_parameter("frost", fx[FX_FROST])
	if Meshes.foliage:
		Meshes.foliage.set_shader_parameter("wind_strength", lerpf(0.035, 0.09, fx[FX_SLANT]))
		Meshes.flutter.set_shader_parameter("wind", lerpf(1.0, 2.2, fx[FX_SLANT]))
	apply_touches()

## The quality's switches on the shared materials: shade at the foot of walls, mottled grass and gusts (all off on Low).
func apply_touches() -> void:
	if Meshes.ground:
		Meshes.ground.set_shader_parameter("ao", 0.0 if _low else 1.0)
		Meshes.ground.set_shader_parameter("detail", 0.0 if _low else 1.0)
	if Meshes.foliage:
		Meshes.foliage.set_shader_parameter("gust", 0.0 if _low else lerpf(0.6, 1.0, fx[FX_SLANT]))

## How far into the night it is, for windows going out: 0 until 22:00, 1 by 02:00, back to 0 at 05:00.
static func lateness(minutes: int) -> float:
	var m := GameClock.wrap(minutes)
	if m >= 22 * 60:
		return (m - 22 * 60) / 240.0
	if m < 2 * 60:
		return (m + 120) / 240.0
	if m < 5 * 60:
		return 1.0
	return 0.0

## [sun colour, sun energy, ambient colour, fog density] for a phase under a weather.
static func _look(p: Array, w: String) -> Array:
	var sun_col: Color = p[0]
	var sun_e: float = p[1]
	var amb: Color = p[3]
	var fog_d := 0.002
	match w:
		"drizzle":
			sun_e *= 0.7
			amb = amb.lerp(Color("a7b0bd"), 0.4)
			fog_d = 0.006
		"downpour":
			sun_e *= 0.45
			amb = amb.lerp(Color("8d97a6"), 0.5)
			fog_d = 0.009
		"fog":
			sun_e *= 0.55
			amb = amb.lerp(Color("c9ccd0"), 0.5)
			fog_d = 0.06
		"gale":
			sun_e *= 0.85
			amb = amb.lerp(Color("b4bcc6"), 0.2)
			fog_d = 0.003
		"frost":
			sun_col = sun_col.lerp(Color("dfe9ff"), 0.5)
			amb = amb.lerp(Color("d6e2f2"), 0.25)
		"sunshine":
			sun_e *= 1.2
			sun_col = sun_col.lerp(Color("ffe2a8"), 0.3)
	return [sun_col, sun_e, amb, fog_d]

## Medium and High: the light eases from one part of the day to the next over this many minutes either side of
## each change (GameClock.phase), instead of switching on the minute.
const EASE_MINUTES := 45
const PHASE_ORDER := ["night", "dawn", "day", "dusk"]
const PHASE_STARTS := [21 * 60, 5 * 60, 8 * 60, 18 * 60]

## [phase before, phase after, 0..1 between them] for a time of day; away from a change both are the phase now.
static func phase_mix(minutes: int) -> Array:
	var m := GameClock.wrap(minutes)
	for i in PHASE_STARTS.size():
		var start: int = PHASE_STARTS[i]
		var d := m - start
		if d > GameClock.DAY / 2:
			d -= GameClock.DAY
		elif d < -GameClock.DAY / 2:
			d += GameClock.DAY
		if absi(d) < EASE_MINUTES:
			var before: String = PHASE_ORDER[(i - 1 + PHASE_ORDER.size()) % PHASE_ORDER.size()]
			var k := (d + EASE_MINUTES) / (2.0 * EASE_MINUTES)
			return [before, PHASE_ORDER[i], k * k * (3.0 - 2.0 * k)]
	var ph := GameClock.phase(m)
	return [ph, ph, 0.0]

## The phase's look, eased between neighbours (sun colour, energy and pitch, ambient, background). The window
## glow (index 6) stays with the phase itself: lamps go on and off on the hour, as they always have.
static func blended_phase(minutes: int) -> Array:
	var mix := phase_mix(minutes)
	var a: Array = PHASES[mix[0]]
	var b: Array = PHASES[mix[1]]
	var k: float = mix[2]
	return [(a[0] as Color).lerp(b[0], k), lerpf(a[1], b[1], k), lerpf(a[2], b[2], k), (a[3] as Color).lerp(b[3], k),
		lerpf(a[4], b[4], k), (a[5] as Color).lerp(b[5], k), PHASES[GameClock.phase(minutes)][6]]

## Medium and High: the sun swings from the east in the morning to the west in the evening (degrees of yaw), so
## shadows turn through the day. Low keeps it fixed at -35.
static func sun_yaw(minutes: int) -> float:
	var h := GameClock.wrap(minutes) / 60.0
	return clampf(-35.0 + (h - 12.0) * 4.5, -70.0, 0.0)

## How strongly cloud shadows drift over the ground (ground.gdshader `clouds`) in a weather and phase.
static func cloud_shadows(w: String, ph: String) -> float:
	if ph == "night":
		return 0.0
	var amt: float = {"clear": 0.75, "sunshine": 0.55, "drizzle": 0.5, "gale": 0.9, "frost": 0.4, "downpour": 0.2, "fog": 0.0}.get(w, 0.6)
	return amt * (0.5 if ph != "day" else 1.0)

func apply_time(minutes: int) -> void:
	var ph := GameClock.phase(minutes)
	var p: Array = PHASES[ph] if _low else blended_phase(minutes)
	var amb_e: float = p[4]
	var bg: Color = p[5]
	var to := _look(p, weather)
	var sun_col: Color = to[0]
	var sun_e: float = to[1]
	var amb: Color = to[2]
	var fog_d: float = to[3]
	if _blend < 1.0:
		var from := _look(p, _from)
		var k := _blend * _blend * (3.0 - 2.0 * _blend)
		sun_col = (from[0] as Color).lerp(sun_col, k)
		sun_e = lerpf(from[1], sun_e, k)
		amb = (from[2] as Color).lerp(amb, k)
		fog_d = lerpf(from[3], fog_d, k)
	if interior:
		var ip: Array = INTERIOR_PHASES[ph]
		sun_col = ip[0]
		sun_e = ip[1]
		amb = ip[2]
		amb_e = ip[3]
		fog_d = 0.0
		bg = Color("0e0f13")
	sun.light_color = sun_col
	sun.light_energy = sun_e
	sun.rotation_degrees.x = p[2]
	sun.rotation_degrees.y = -35.0 if _low or interior else sun_yaw(minutes)
	var grade: Array = DEFAULT_GRADE if interior else PHASE_GRADE.get(ph, DEFAULT_GRADE)
	if not _low and not interior:
		var pm := phase_mix(minutes)  # ease the grade too, so 08:00 and 18:00 don't jump
		var ga: Array = PHASE_GRADE.get(pm[0], DEFAULT_GRADE)
		var gb: Array = PHASE_GRADE.get(pm[1], DEFAULT_GRADE)
		grade = [lerpf(ga[0], gb[0], pm[2]), lerpf(ga[1], gb[1], pm[2]), lerpf(ga[2], gb[2], pm[2])]
	env.tonemap_exposure = grade[0]
	env.adjustment_saturation = grade[1]
	env.adjustment_contrast = grade[2]
	env.ambient_light_color = amb
	# Medium/High indoors: no glow pass, which lifts a room's black surround to a murky blue in the Compatibility
	# renderer (the hearth and lamps light the room for real instead, see InteriorLight). Battles (no zone) keep theirs.
	env.glow_enabled = not _low and not (interior and _zone != null)
	env.ambient_light_energy = amb_e
	env.background_color = bg
	env.fog_light_color = bg.lerp(amb, 0.5).darkened(0.25)
	env.fog_density = fog_d
	env.fog_enabled = fog_d > 0.0
	if Meshes.glow:
		var lamps: float = p[6] * (0.6 if interior else 1.0)
		Meshes.glow.emission_energy_multiplier = lamps
		Meshes.glow.albedo_color = Color("3a4658") if lamps == 0.0 else Color("ffd98a")
		Meshes.pool.set_shader_parameter("strength", 0.0 if interior else clampf(p[6] / 2.2, 0.0, 1.0))
		Signage.night(get_tree() if is_inside_tree() else null, 0.0 if interior else p[6])
	if Meshes.windows:
		Meshes.windows.set_shader_parameter("energy", 0.0 if interior else p[6])
		Meshes.windows.set_shader_parameter("lateness", lateness(minutes))
	_fx_now()
	_apply_fx()
	_apply_detail(ph, bg, amb)
	_apply_stars(minutes, bg)

## Stars and the moon behind the diorama once it is dark: a sky backdrop (instead of a flat colour) only while there is
## something to show, so the day costs nothing. Interiors have none. The moon is in its real phase for the date.
func _apply_stars(minutes: int, bg: Color) -> void:
	var t := Calendar.today()
	var look := NightSky.look(minutes, NightSky.moon_phase(Calendar.year(), t.x, t.y), weather)
	var show: bool = not interior and (float(look.stars) > 0.01 or float(look.moon_on) > 0.01)
	env.background_mode = Environment.BG_SKY if show else Environment.BG_COLOR
	if not show:
		return
	_sky_mat.set_shader_parameter("base_colour", bg)
	_sky_mat.set_shader_parameter("top_colour", bg.darkened(0.55))
	_sky_mat.set_shader_parameter("stars", look.stars)
	_sky_mat.set_shader_parameter("twinkle", 0.0 if _low or Settings.reduce_flashing else 1.0)
	_sky_mat.set_shader_parameter("moon_on", look.moon_on)
	_sky_mat.set_shader_parameter("moon_phase", look.moon_phase)
	_sky_mat.set_shader_parameter("moon_pos", look.moon_pos)
	_aim_sky()

## Tells the sky shader where the camera is looking (it lays the stars on the picture, not the world).
func _aim_sky() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var b := cam.global_transform.basis
	_sky_mat.set_shader_parameter("cam_right", b.x)
	_sky_mat.set_shader_parameter("cam_up", b.y)
	_sky_mat.set_shader_parameter("cam_fwd", -b.z)
	_sky_mat.set_shader_parameter("half_tan", tan(deg_to_rad(cam.fov) * 0.5))

## The Medium and High touches that follow the clock and the weather: cloud shadows, the sky in the water, the
## haze over the far side of the screen. Low sets them all to nothing.
func _apply_detail(ph: String, bg: Color, amb: Color) -> void:
	var on := 0.0 if _low else 1.0
	if Meshes.ground:
		Meshes.ground.set_shader_parameter("clouds", 0.0 if _low or interior else lerpf(cloud_shadows(_from, ph), cloud_shadows(weather, ph), _blend))
	if is_inside_tree():
		var sky_col := bg.lerp(Color("eef4f8"), 0.25) if ph == "day" else bg.lerp(amb, 0.3)
		for w in get_tree().get_nodes_in_group(ZoneBuilder.WATER_GROUP):
			var m := (w as MeshInstance3D).material_override as ShaderMaterial
			if m:
				m.set_shader_parameter("detail", 0.0 if interior else on)
				m.set_shader_parameter("sky", sky_col)
	if post:
		# a pale band of air over the top of the screen (the far distance), warmer at dawn and dusk; a soft vignette
		var haze: float = 0.0 if _low or interior else {"day": 0.22, "dawn": 0.3, "dusk": 0.3, "night": 0.18}.get(ph, 0.2)
		if weather == "fog" or weather == "downpour":
			haze += 0.15
		post.set_shader_parameter("haze", haze)
		post.set_shader_parameter("haze_colour", env.fog_light_color.lerp(bg, 0.6).lightened(0.15))
		post.set_shader_parameter("vignette", 0.0 if _low else (0.32 if interior else 0.22))

func _process(delta: float) -> void:
	_tick_thunder(delta)
	if env.background_mode == Environment.BG_SKY:
		_aim_sky()  # the camera glides about; the stars stay on the picture
	if follow:
		var at := follow.global_position
		_rain.global_position = at + Vector3(0, 9, 2)
		_fog.global_position = at + Vector3(0, 0.9, 1.5)
		_leaves.global_position = at + Vector3(-12, 1.5, 1.5)
		_flecks.global_position = at + Vector3(0, 3.5, 1.5)
		_splash.global_position = at + Vector3(0, 0.03, 0)
	if _blend < 1.0:
		_blend = minf(1.0, _blend + delta / BLEND_SECONDS)
		apply_time(Game.local_minutes())
	elif Engine.get_process_frames() % 30 == 0:
		_check_expiry()
		apply_time(Game.local_minutes())

## Low: no shadows or glow, half the rain, no leaves, flecks or splashes, and none of the touches below (it looks
## as the game always has). Medium: 2-split soft shadows and glow; the light eases between times of day and the sun
## swings across the sky; cloud shadows, mottled grass, shade at the foot of walls, gusts in the trees, foam and sky
## in the water, haze and a vignette. High: 4-split shadows, softer still. Safe to call live.
func apply_quality(q: String) -> void:
	sun.shadow_enabled = q != "low"
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if q == "high" else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_blur = 1.5 if q == "low" else (2.6 if q == "high" else 2.0)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM if q == "high" else RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	env.glow_enabled = q != "low" and not (interior and _zone != null)
	var was_low := _low
	_low = q == "low"
	if _low != was_low and _rain != null:
		_fog.amount = 5 if _low else 10
		var want := maxi(_rain_amount(_from), _rain_amount(weather))
		if want > 0:
			_rain.amount = want
		_apply_fx()
	if is_inside_tree() and env != null:
		apply_time(Game.local_minutes())
