class_name BattleFX
extends Node3D
## Plays EventPlayer cues on the diorama and HUD: lunges, hits, particle bursts, camera swoops, the snare throw.

const STATUS_COLOURS := {
	"soaked": Color("5aa7e0"), "chilled": Color("bfeaf5"), "muddled": Color("e08fc0"),
	"hexed": Color("9a6fd0"), "stung": Color("c8d84a"), "asleep": Color("8aa0c8"),
}

var dio: Diorama
var hud: BattleHUD
var sky: SkyAndLight  # weather moves change the battle sky

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _actor(side: int, pos := 0) -> CreatureActor:
	return dio.actor(side, pos)

## Move animations by category and effect (see template_for): a lunge for physical hits, a projectile or a beam
## in the type colour for special ones, a cloud over the target for status moves, an aura for moves on oneself,
## a plume and a sky flash for weather calls, a thread back to the attacker for drains, a self-burst for recoil
## and one small burst per hit for multi-hits. Anything unrecognised plays the old lunge.
## Every spark comes from one pool of billboard quads, moved by hand in _process (no particle nodes, no
## per-frame allocations: the pool only grows to its high-water mark, capped at POOL_MAX, then reuses the oldest).

const POOL_MAX := 240
## Special moves of these types fire a beam; the rest throw a projectile.
const BEAM_TYPES := ["storm", "frost", "fae", "spirit", "night", "iron"]
## The 14 move shapes (data/moves "fx": {"shape"}); every move plays one of them in its type's palette.
const SHAPES := ["bolt", "volley", "beam", "slash", "pounce", "burst", "cloud", "rain", "quake", "wave", "self", "song", "bite", "wing"]
## Particle textures (index into PARTICLE_TEX): 0 soft glow, 1 ring, 2 star, 3 shard, 4 drop, 5 note, 6 leaf.
const TEX_N := 7
## One look per type: [core, highlight, particle texture index].
const PALETTE := {
	"kin": [Color("c9b48a"), Color("f6ead0"), 2], "hedgerow": [Color("5fae4a"), Color("c8f09a"), 6],
	"brook": [Color("4a94dc"), Color("bfe6ff"), 4], "tide": [Color("2f72b8"), Color("a8e0f0"), 4],
	"hearth": [Color("f0701f"), Color("ffe08a"), 0], "gale": [Color("a8cce6"), Color("f2fbff"), 6],
	"storm": [Color("8070e0"), Color("fff8a8"), 3], "frost": [Color("86d8e8"), Color("f4feff"), 3],
	"stone": [Color("a08a68"), Color("e2d2b0"), 3], "bog": [Color("708a36"), Color("c4d86a"), 4],
	"iron": [Color("98a2b0"), Color("ffcf7a"), 3], "urban": [Color("8a8c9a"), Color("e8e6f4"), 2],
	"fae": [Color("e888d0"), Color("fff0fa"), 2], "spirit": [Color("9070cc"), Color("e8dcff"), 1],
	"brawn": [Color("d04a3a"), Color("ffd8b0"), 2], "night": [Color("4a4a8a"), Color("b8b0ff"), 1],
}
## Weather calls: [flash colour, the tint the battle sky keeps while it lasts].
const WEATHER_LOOK := {
	"drizzle": [Color("d6e4f5"), Color(0.8, 0.85, 0.92)],
	"downpour": [Color("eef3ff"), Color(0.6, 0.65, 0.75)],
	"fog": [Color("e8eaec"), Color(0.92, 0.93, 0.94)],
	"gale": [Color("e2eaf0"), Color(0.86, 0.9, 0.95)],
	"frost": [Color("e8f6ff"), Color(0.92, 0.98, 1.08)],
	"sunshine": [Color("fff0b0"), Color(1.12, 1.05, 0.9)],
	"clear": [Color.WHITE, Color(1, 1, 1)],
}
enum { FREE, FLY, PATH, HANG }

var _quad: QuadMesh
var _soft: Texture2D
var _tex: Array[Texture2D] = []
var _hit_tint := Color.WHITE  # the type colour of the attack in flight: the hit flash and burst take it
var _sigs: FXSignatures
var _sparks: Array[MeshInstance3D] = []
var _mats: Array[StandardMaterial3D] = []
var _mode := PackedInt32Array()
var _from := PackedVector3Array()
var _to := PackedVector3Array()
var _vel := PackedVector3Array()
var _age := PackedFloat32Array()
var _life := PackedFloat32Array()
var _grav := PackedFloat32Array()
var _arc := PackedFloat32Array()
var _alpha := PackedFloat32Array()
var _next := 0
var _live := 0
var _rng := RandomNumberGenerator.new()
var _multi := false        # the move in flight is a multi-hit: each hit gets its own small burst
var _flash: ColorRect
var _sky_tween: Tween

## The animation a move plays: "lunge", "projectile", "beam", "cloud", "aura" or "weather".
static func template_for(move: Dictionary) -> String:
	if move.is_empty():
		return "lunge"
	var eff: Dictionary = move.get("effect", {})
	match str(move.get("category", "physical")):
		"special":
			return "beam" if str(move.get("type", "")) in BEAM_TYPES else "projectile"
		"status":
			var id := str(eff.get("id", ""))
			if id == "set_weather":
				return "weather"
			if str(eff.get("target", "foe")) == "self" or id in ["heal_self", "protect", "cure_team"]:
				return "aura"
			return "cloud"
	return "lunge"

## The shape a move plays: its data "fx" shape, or one derived from the old template for moves without one.
static func shape_for(move: Dictionary) -> String:
	var sh := str(move.get("fx", {}).get("shape", ""))
	if sh in SHAPES:
		return sh
	return {"projectile": "bolt", "beam": "beam", "cloud": "cloud", "aura": "self", "weather": "cloud"}.get(template_for(move), "pounce")

## [core, highlight, texture index] for a type, with the move's own optional "fx.colour" overriding the core.
static func palette_for(type_id: String, move := {}) -> Array:
	var p: Array = PALETTE.get(type_id, [Color("f4ecd8"), Color.WHITE, 0]).duplicate()
	var c := str(move.get("fx", {}).get("colour", ""))
	if c != "":
		p[0] = Color(c)
	return p

## Particle count scaled down when "reduce flashing" is on.
func _n(count: int) -> int:
	return maxi(4, int(count * Settings.flash_scale(0.5)))

## Generates the 32x32 particle textures once (ring, star, shard, drop, note, leaf); index 0 is the soft glow.
func _textures() -> void:
	if not _tex.is_empty():
		return
	_tex.resize(TEX_N)
	_tex[0] = _soft
	for k in range(1, TEX_N):
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var u := (x - 15.5) / 15.5
				var v := (y - 15.5) / 15.5
				var a := 0.0
				match k:
					1: a = clampf(1.0 - absf(sqrt(u * u + v * v) - 0.78) * 7.0, 0.0, 1.0)
					2: a = clampf(1.0 - (minf(absf(u), absf(v)) * 5.0 + sqrt(u * u + v * v) * 0.6), 0.0, 1.0)
					3: a = clampf((1.0 - (absf(u) * 2.4 + absf(v) * 0.8)) * 3.0, 0.0, 1.0)
					4: a = 1.0 if (sqrt(u * u + (v - 0.3) * (v - 0.3)) < 0.6 or (v < 0.3 and v > -1.0 and absf(u) < (v + 1.0) * 0.46)) else 0.0
					5: a = 1.0 if (sqrt((u + 0.25) * (u + 0.25) + (v - 0.55) * (v - 0.55)) < 0.4 or (absf(u - 0.1) < 0.12 and v < 0.55 and v > -0.8) or (v < -0.6 and v > -0.85 and u > 0.0 and u < 0.7)) else 0.0
					6: a = 1.0 if (u * u * 3.0 + v * v * 0.6 < 0.5) else 0.0
				img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
		_tex[k] = ImageTexture.create_from_image(img)

## A puff of little billboard sparks thrown out from `pos` (world space), falling under `gravity` and fading.
## Hand-animated quads rather than a particle node, so they always appear exactly where they are aimed.
func burst(pos: Vector3, colour: Color, amount := 16, speed := 3.5, size := 0.16, life := 0.6, gravity := -4.0, up := Vector3.UP, tex := 0) -> void:
	var cone := 1.0 if up == Vector3.UP else 0.35
	for i in amount:
		var dir := (up + Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * cone).normalized()
		_spawn(pos, dir * _rng.randf_range(speed * 0.5, speed), colour.lightened(_rng.randf_range(0.0, 0.35)), size, life, gravity, FLY, 0.0, Vector3.ZERO, 0.0, false, 1.0, tex)

## How many pool sparks are alive (tests, and a sanity check on the pool).
func live_sparks() -> int:
	return _live

func pool_size() -> int:
	return _sparks.size()

func _spawn(pos: Vector3, vel: Vector3, col: Color, size: float, life: float, grav := 0.0, mode := FLY, delay := 0.0,
		to := Vector3.ZERO, arc := 0.0, soft := false, stretch := 1.0, tex := 0) -> void:
	var i := _slot()
	var m := _sparks[i]
	var mat := _mats[i]
	if _mode[i] == FREE:
		_live += 1
	_mode[i] = mode
	_from[i] = pos
	_to[i] = to
	_vel[i] = vel
	_age[i] = -delay
	_life[i] = life
	_grav[i] = grav
	_arc[i] = arc
	_alpha[i] = col.a
	mat.albedo_color = Color(col.r, col.g, col.b, col.a if mode != HANG else 0.0)
	mat.albedo_texture = (_tex[tex] if tex > 0 and tex < _tex.size() else _soft) if (soft or tex > 0) else null
	m.scale = Vector3(size, size * stretch, 1.0)
	m.global_position = pos
	m.visible = delay <= 0.0

## A free pool slot: grows the pool up to POOL_MAX, then takes the next one round the ring (the oldest, roughly).
func _slot() -> int:
	var n := _sparks.size()
	for k in n:
		var i := (_next + k) % n
		if _mode[i] == FREE:
			_next = (i + 1) % n
			return i
	if n < POOL_MAX:
		_grow()
		return n
	var j := _next
	_next = (_next + 1) % n
	return j

func _grow() -> void:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
		_soft = SkyAndLight._soft_texture()
		_textures()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.disable_fog = true
	var m := MeshInstance3D.new()
	m.mesh = _quad
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visible = false
	dio.add_child(m)
	_sparks.append(m)
	_mats.append(mat)
	for arr in [_mode, _from, _to, _vel, _age, _life, _grav, _arc, _alpha]:
		arr.resize(_sparks.size())
	_mode[_sparks.size() - 1] = FREE

func _process(delta: float) -> void:
	if _live == 0:
		return
	for i in _sparks.size():
		var mode := _mode[i]
		if mode == FREE:
			continue
		var t := _age[i] + delta
		_age[i] = t
		if t < 0.0:
			continue
		var m := _sparks[i]
		var life := _life[i]
		if t >= life:
			m.visible = false
			_mode[i] = FREE
			_live -= 1
			continue
		m.visible = true
		var k := t / life
		var a := 1.0 - k
		var p: Vector3
		if mode == PATH:
			p = _from[i].lerp(_to[i], k) + Vector3(0, sin(k * PI) * _arc[i], 0) + _vel[i] * t
			a = minf(1.0, (1.0 - k) * 5.0)
		else:
			p = _from[i] + _vel[i] * t + Vector3(0, 0.5 * _grav[i] * t * t, 0)
			if mode == HANG:
				a = minf(1.0, k * 5.0) * minf(1.0, (1.0 - k) * 2.5)
		m.global_position = p
		_mats[i].albedo_color.a = a * _alpha[i]

func _chest(side: int, pos := 0) -> Vector3:
	return _actor(side, pos).world_centre()

## Plays one cue. `battle` is only used to look up the creature a switch brings in (and, in doubles, where an
## item's target stands). Double-battle cues carry "pos" (and attacks "target_side" / "target_pos" / "spread").
func play(cue: Dictionary, battle: Battle) -> void:
	var side := int(cue.get("side", 0))
	var pos := int(cue.get("pos", 0))
	if str(cue.cue) not in ["hit", "attack", "none"]:
		_hit_tint = Color.WHITE
		_multi = false  # the multi-hit's blows are over: a later recoil or status hit gets the full burst
	for a in DevArgs.user_args():  # --fx-freeze=<cue>:<secs> stops time that long into the first such cue (screenshots)
		if a.begins_with("--fx-freeze=") and a.get_slice("=", 1).get_slice(":", 0) == str(cue.cue) and not has_meta("froze"):
			set_meta("froze", true)
			get_tree().create_timer(float(a.get_slice(":", 1))).timeout.connect(func(): Engine.time_scale = 0.0)
	match str(cue.cue):
		"attack":
			var move: Dictionary = battle.move_db.get_move(str(cue.get("move", ""))) if battle != null and battle.move_db != null else {}
			for a in DevArgs.user_args():  # --fx-move=<id>: every attack looks like that move (screenshots only)
				if a.begins_with("--fx-move=") and battle != null:
					move = battle.move_db.get_move(a.get_slice("=", 1))
					cue.move_type = str(move.get("type", cue.move_type))
					cue["dev_weather"] = str(move.get("effect", {}).get("weather", ""))
			await _attack(side, str(cue.move_type), pos, int(cue.get("target_side", 1 - side)), int(cue.get("target_pos", 0)), bool(cue.get("spread", false)), move)
			if str(cue.get("dev_weather", "")) != "":  # the stand-in move's weather arrives too
				await play({"cue": "weather", "weather": cue.dev_weather, "turns": 5}, battle)
		"hit":
			await _hit(side, int(cue.hp), str(cue.strength), pos)
		"dodge":
			await _actor(side, pos).dodge()
		"shrug":
			await _actor(side, pos).nod()
		"stat_up", "stat_down":
			var up: bool = cue.cue == "stat_up"
			Audio.sfx("stat_up" if up else "stat_down")
			burst(_actor(side, pos).global_position + Vector3(0, 0.3 if up else 2.0, 0), Color("7fe07a") if up else Color("e07a7a"), 14, 2.0, 0.14, 0.9, 1.5 if not up else -1.0, Vector3.UP if up else Vector3.DOWN)
			await _wait(0.55)
		"status":
			var col: Color = STATUS_COLOURS.get(str(cue.status), Color.WHITE)
			burst(_chest(side, pos), col, 18, 2.5, 0.16, 0.8, -1.0)
			hud.set_status(side, str(cue.status), pos)
			await _wait(0.5)
		"cure":
			burst(_chest(side, pos), Color("fff2b0"), 14, 2.5, 0.14, 0.7, -2.0)
			hud.set_status(side, "", pos)
			await _wait(0.4)
		"idle":
			await _actor(side, pos).nod()
		"faint":
			Audio.sfx("faint")
			await _actor(side, pos).faint()
		"switch":
			await _switch(side, battle.parties[side][int(cue.index)], pos)
		"run":
			Audio.sfx("run")
			await _actor(Battle.PLAYER).slip_away()
		"heal":
			Audio.sfx("heal")
			var at := 0
			if battle.double:
				at = maxi(0, battle.active[side].find(int(cue.get("target", 0))))
			burst(_actor(side, at).global_position + Vector3(0, 0.2, 0), Color("8fe89a"), 18, 2.2, 0.15, 1.0, 1.0, Vector3.UP)
			if cue.has("hp"):
				hud.tween_hp(side, int(cue.hp), 0.5, at)
			await _wait(0.5)
		"protect":
			Audio.sfx("bump")
			burst(_chest(side, pos), Color("cfe3ff"), 20, 1.6, 0.18, 0.6, 0.0)
			await _actor(side, pos).nod()
		"knack":
			burst(_actor(side, pos).global_position + Vector3(0, 0.25, 0), Color("ffd870"), 14, 1.8, 0.13, 0.8, 0.8, Vector3.UP)
			await _wait(0.35)
		"weather":
			var w := str(cue.weather)
			var called := int(cue.get("turns", 0)) > 0 and w != "clear"
			if called:
				_weather_call(w)
			_weather_sky(w, called)
			hud.set_weather(w, int(cue.get("turns", 0)))
			await _wait(1.1 if called else 0.4)
		"catch":
			await _catch(bool(cue.success), int(cue.wobbles))
		"end", "none":
			pass

func _attack(side: int, type_id: String, pos := 0, t_side := -1, t_pos := 0, spread := false, move := {}) -> void:
	var other := 1 - side if t_side < 0 else t_side
	var tpl := template_for(move)
	var shape := shape_for(move)
	var eff := str(move.get("effect", {}).get("id", ""))
	_multi = eff == "multi_hit"
	var pal := palette_for(type_id, move)
	var col: Color = pal[0] if type_id != "" else Color("f4ecd8")
	_hit_tint = (pal[1] as Color).lerp(col, 0.4) if type_id != "" else Color.WHITE
	var actor := _actor(side, pos)
	var hit_pos := [0, 1] if spread else [t_pos]
	if tpl == "aura" or shape == "self":
		dio.swoop_to_target(side, pos)
	elif tpl == "weather":
		dio.swoop_home(0.45)
	else:
		dio.swoop_to_attacker(side, pos, t_pos)
	await _wait(0.4)
	var voice := AudioIds.attack_sfx(type_id)
	if shape in ["cloud", "self", "song"] or tpl == "weather":
		Audio.sfx_at(voice, -5.0, 1.15)  # status moves: a lighter touch of the type's voice
	else:
		Audio.sfx(voice)
	if tpl == "weather":
		actor.cast()
		_plume(actor.global_position + Vector3(0, 1.2, 0), col)
		await _wait(0.5)
	else:
		if _sigs == null:
			_sigs = FXSignatures.new()
			_sigs.fx = self
		if _sigs.has_move(str(move.get("id", ""))):
			await _sigs.play(str(move.id), side, pos, other, hit_pos, t_pos, pal, col)
		else:
			await play_shape(shape, side, pos, other, hit_pos, t_pos, spread, pal, col)
		if eff == "recoil":
			get_tree().create_timer(0.24).timeout.connect(func(): burst(_chest(side, pos), Color("ffb070"), 16, 3.0, 0.17, 0.45, -3.0))
	if eff == "drain":  # life drawn back along a thread while the hit lands
		var back := col.lerp(Color("9ff09a"), 0.5)
		get_tree().create_timer(0.35).timeout.connect(func():
			for p in hit_pos:
				_thread(_chest(other, p), _chest(side, pos), back))

## The aim point of a lunge: the target's home (or the middle of both foes for a spread move).
func _aim(other: int, t_pos: int, spread: bool) -> Vector3:
	if spread:
		return _actor(other, 0).home.lerp(_actor(other, 1).home, 0.5)
	return _actor(other, t_pos).home

## The sparks where a move lands: type-flavoured, skipped for a multi-hit (each blow has its own small burst).
func _impact(other: int, hit_pos: Array, pal: Array, n := 22, delay := 0.0) -> void:
	if _multi:
		return
	var go := func():
		for p in hit_pos:
			var at := _chest(other, p)
			burst(at, pal[0], _n(n), 4.5, 0.2, 0.5, -4.0, Vector3.UP, int(pal[2]))
			burst(at, pal[1], _n(n / 3), 3.0, 0.14, 0.4, -2.0)
	if delay <= 0.0:
		go.call()
	else:
		get_tree().create_timer(delay).timeout.connect(go)

## Dust thrown flat along the ground from a creature's feet.
func _dust(feet: Vector3, col: Color) -> void:
	for i in _n(14):
		var ang := TAU * i / 14.0
		_spawn(feet + Vector3(0, 0.12, 0), Vector3(cos(ang) * 2.4, 0.6, sin(ang) * 1.5), col.lerp(Color("c8b898"), 0.5), _rng.randf_range(0.3, 0.5), 0.5, -1.0, FLY, 0.0, Vector3.ZERO, 0.0, true)

## Plays one move shape from `side` at `other` (see SHAPES). Every shape ends within about 0.7 s.
func play_shape(shape: String, side: int, pos: int, other: int, hit_pos: Array, t_pos: int, spread: bool, pal: Array, col: Color) -> void:
	var actor := _actor(side, pos)
	var hi: Color = pal[1]
	var tx: int = pal[2]
	var u := _chest(side, pos)
	match shape:
		"bolt":
			actor.cast()
			burst(u, col, _n(8), 1.6, 0.12, 0.4, 0.0, Vector3.UP, tx)
			await _wait(0.16)
			for p in hit_pos:
				_projectile(u, _chest(other, p), col, tx)
			await _wait(0.42)
			_impact(other, hit_pos, pal)
		"volley":
			actor.cast()
			await _wait(0.1)
			for i in 4:
				for p in hit_pos:
					var tp := _chest(other, p) + Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.3, 0.4), 0)
					_spawn(u, Vector3.ZERO, col.lightened(0.2), 0.34, 0.3, 0.0, PATH, 0.09 * i, tp, 0.25 + 0.1 * i, true, 1.0, tx)
					_spawn(u, Vector3.ZERO, Color.WHITE, 0.14, 0.3, 0.0, PATH, 0.09 * i, tp, 0.25 + 0.1 * i, true)
				get_tree().create_timer(0.09 * i + 0.3).timeout.connect(func():
					for p in hit_pos:
						burst(_chest(other, p), col, _n(8), 3.0, 0.14, 0.35, -3.0, Vector3.UP, tx))
			await _wait(0.65)
		"beam":
			actor.cast()
			burst(u, col, _n(8), 1.6, 0.12, 0.4, 0.0, Vector3.UP, tx)
			await _wait(0.16)
			for p in hit_pos:
				_beam(u, _chest(other, p), col)
			await _wait(0.3)
			_impact(other, hit_pos, pal)
		"slash":
			actor.lunge(_aim(other, t_pos, spread))
			await _wait(0.14)
			for p in hit_pos:
				_slash(_chest(other, p), hi, col, tx)
			await _wait(0.34)
			_impact(other, hit_pos, pal, 14)
		"pounce":
			burst(actor.global_position + Vector3(0, 0.2, 0), col, _n(8), 2.0, 0.14, 0.5, -1.0, Vector3.UP, tx)
			_impact(other, hit_pos, pal, 22, 0.2)
			await actor.lunge(_aim(other, t_pos, spread))
		"burst":
			actor.cast()
			await _wait(0.14)
			for p in hit_pos:
				_ring(_chest(other, p), col, hi, tx)
			await _wait(0.5)
		"cloud":
			actor.cast()
			await _wait(0.12)
			for p in hit_pos:
				_cloud(_chest(other, p) + Vector3(0, 0.9, 0), col)
			await _wait(0.7)
		"rain":
			actor.cast()
			await _wait(0.1)
			for p in hit_pos:
				var tp := _chest(other, p)
				for i in _n(16):
					_spawn(tp + Vector3(_rng.randf_range(-0.8, 0.8), 2.6 + _rng.randf_range(0.0, 0.5), _rng.randf_range(-0.3, 0.3)), Vector3(0, -11.0, 0), col.lightened(_rng.randf_range(0.0, 0.4)), 0.22, 0.28, 0.0, FLY, _rng.randf() * 0.3, Vector3.ZERO, 0.0, false, 2.2, 4 if tx != 3 else 3)
			_impact(other, hit_pos, pal, 20, 0.4)
			await _wait(0.7)
		"quake":
			actor.cast()
			await _wait(0.12)
			dio.shake = 0.5 * Settings.flash_scale(0.2)
			_dust(actor.global_position, col)
			for p in hit_pos:
				var feet := _actor(other, p).global_position
				_dust(feet, col)
				burst(feet + Vector3(0, 0.2, 0), col.lerp(hi, 0.3), _n(8), 3.5, 0.2, 0.55, -9.0, Vector3.UP, 3)
			await _wait(0.55)
		"wave":
			actor.cast()
			await _wait(0.1)
			for p in hit_pos:
				var tp := _chest(other, p)
				var across := (tp - u).cross(Vector3.UP).normalized()
				for i in _n(14):
					var c := col.lerp(hi, _rng.randf_range(0.0, 0.5))
					_spawn(u, across * sin(i * 1.7) * 1.1, c, _rng.randf_range(0.2, 0.38), 0.4, 0.0, PATH, 0.03 * i, tp, 0.4 + 0.3 * sin(i * 0.9), true, 1.0, tx)
			await _wait(0.5)
			_impact(other, hit_pos, pal, 18)
			await _wait(0.1)
		"self":
			actor.cast()
			_aura(actor.global_position, col, tx)
			await _wait(0.6)
		"song":
			actor.cast()
			await _wait(0.1)
			for p in hit_pos:
				var tp := _chest(other, p) + Vector3(0, 0.4, 0)
				var across := (tp - u).cross(Vector3.UP).normalized()
				for i in 7:
					_spawn(u + Vector3(0, 0.8, 0), across * sin(i * 2.1) * 0.8, col.lerp(hi, 0.5 * (i % 2)), 0.34, 0.6, 0.0, PATH, 0.07 * i, tp, 0.6 + 0.12 * i, true, 1.0, 5)
				get_tree().create_timer(0.55).timeout.connect(func():
					burst(tp, hi, _n(10), 2.0, 0.22, 0.4, 1.0, Vector3.UP, 2))
			await _wait(0.7)
		"bite":
			actor.lunge(_aim(other, t_pos, spread))
			await _wait(0.12)
			for p in hit_pos:
				var tp := _chest(other, p)
				for i in 5:
					var x := (i - 2) * 0.22
					_spawn(tp + Vector3(x, 0.9, 0.2), Vector3.ZERO, hi, 0.3, 0.16, 0.0, PATH, 0.0, tp + Vector3(x, 0.12, 0.2), 0.0, true, 1.0, 3)
					_spawn(tp + Vector3(x, -0.8, 0.2), Vector3.ZERO, hi, 0.3, 0.16, 0.0, PATH, 0.0, tp + Vector3(x, -0.12, 0.2), 0.0, true, 1.0, 3)
			await _wait(0.2)
			_impact(other, hit_pos, pal, 16)
			await _wait(0.2)
		"wing":
			actor.lunge(_aim(other, t_pos, spread))
			for i in _n(10):
				_spawn(u, Vector3(_rng.randf_range(-1, 1), _rng.randf_range(0.3, 1.2), _rng.randf_range(-0.5, 0.5)), hi, 0.22, 0.5, -0.5, FLY, 0.02 * i, Vector3.ZERO, 0.0, false, 1.0, 6)
			await _wait(0.2)
			for p in hit_pos:
				_slash(_chest(other, p), hi, col, 6, true)
			await _wait(0.3)
			_impact(other, hit_pos, pal, 14)
		_:
			await actor.lunge(_aim(other, t_pos, spread))

## A curved streak across a target (a claw or a blade), drawn as a fan of stretched sparks. `wide` for a wing sweep.
func _slash(at: Vector3, hi: Color, col: Color, tx := 3, wide := false) -> void:
	var span := 1.2 if wide else 0.9
	for i in _n(14):
		var k := float(i) / 13.0
		var p := at + Vector3(lerpf(-span, span, k), lerpf(span, -span, k) * 0.9 + sin(k * PI) * 0.3, 0.3)
		_spawn(p, Vector3.ZERO, (hi if i % 2 == 0 else col).lightened(0.2), 0.42 if not wide else 0.3, 0.3, 0.0, HANG, k * 0.12, Vector3.ZERO, 0.0, true, 1.0, tx)
		_spawn(p, Vector3.ZERO, Color.WHITE, 0.14, 0.22, 0.0, HANG, k * 0.12, Vector3.ZERO, 0.0, true)

## An expanding ring of light on a target, a second ring close behind it.
func _ring(at: Vector3, col: Color, hi: Color, tx := 0) -> void:
	_spawn(at, Vector3.ZERO, Color(hi.r, hi.g, hi.b, 0.7), 1.8, 0.25, 0.0, HANG, 0.0, Vector3.ZERO, 0.0, true)
	for wave in 2:
		for i in _n(18):
			var ang := TAU * i / 18.0
			_spawn(at, Vector3(cos(ang), sin(ang) * 0.8, 0.0) * (4.2 - wave * 1.2), (col if wave == 0 else hi).lightened(0.15), 0.2 if tx == 0 else 0.3, 0.42, 0.0, FLY, 0.1 * wave, Vector3.ZERO, 0.0, false, 1.0, tx)

## An orb of sparks (a bright core and a trail) arcing from `a` to `b`.
func _projectile(a: Vector3, b: Vector3, col: Color, tx := 0) -> void:
	a = a.lerp(b, 0.12)  # leave from just in front, so the orb is not huge right under the camera
	var arc := clampf(a.distance_to(b) * 0.12, 0.3, 1.0)
	_spawn(a, Vector3.ZERO, Color(col.r, col.g, col.b, 0.85), 1.1, 0.42, 0.0, PATH, 0.0, b, arc, true)
	_spawn(a, Vector3.ZERO, col.lightened(0.6), 0.55 if tx == 0 else 0.7, 0.42, 0.0, PATH, 0.0, b, arc, true, 1.0, tx)
	_spawn(a, Vector3.ZERO, Color(1, 1, 1, 0.95), 0.28, 0.42, 0.0, PATH, 0.0, b, arc, true)
	for i in 18:
		var jit := Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6))
		_spawn(a, jit, col.lightened(_rng.randf_range(0.1, 0.4)), _rng.randf_range(0.05, 0.11), 0.42, 0.0, PATH, 0.012 * i, b, arc)

## A line of light from `a` to `b` that flickers along its length and fades.
func _beam(a: Vector3, b: Vector3, col: Color) -> void:
	a = a.lerp(b, 0.1)
	var n := 36
	var across := (b - a).cross(Vector3.UP).normalized()
	var glow := col.lightened(0.3)
	for i in n:
		var k := float(i) / (n - 1)
		var at := a.lerp(b, k)
		var wob := (across * sin(k * 21.0) + Vector3.UP * cos(k * 17.0)) * 0.12
		_spawn(at + wob, across * _rng.randf_range(-0.25, 0.25), Color(glow.r, glow.g, glow.b, 0.9), 0.55, 0.5, 0.0, HANG, k * 0.14, Vector3.ZERO, 0.0, true)
		_spawn(at, Vector3.ZERO, Color(1, 1, 1, 1.0), 0.3, 0.42, 0.0, HANG, k * 0.14, Vector3.ZERO, 0.0, true)
		if i % 3 == 0:
			_spawn(at + wob * 2.0, across * _rng.randf_range(-1.0, 1.0) + Vector3.UP * 0.6, glow, 0.08, 0.5, -1.0, FLY, k * 0.14 + 0.05)

## A slow puffy cloud over a target, dropping a few motes.
func _cloud(at: Vector3, col: Color) -> void:
	for i in 13:
		var off := Vector3(_rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.2, 0.3), _rng.randf_range(-0.4, 0.4))
		var drift := Vector3(_rng.randf_range(-0.25, 0.25), 0.08, 0.0)
		var c := col.lerp(Color("f2f0f6"), _rng.randf_range(0.2, 0.6))  # lit tops, darker hearts
		_spawn(at + off, drift, Color(c.r, c.g, c.b, _rng.randf_range(0.6, 0.85)), _rng.randf_range(0.55, 1.0), 1.25, 0.0, HANG, 0.025 * i, Vector3.ZERO, 0.0, true)
	for i in 14:
		var off := Vector3(_rng.randf_range(-0.7, 0.7), -0.25, _rng.randf_range(-0.3, 0.3))
		_spawn(at + off, Vector3(0, -0.5, 0), col.lightened(0.45), 0.12, 0.9, -2.5, FLY, 0.25 + 0.035 * i)

## A rising ring of light around a creature buffing or healing itself.
func _aura(feet: Vector3, col: Color, tex := 0) -> void:
	for i in 18:
		var ang := TAU * i / 18.0
		var r := Vector3(cos(ang), 0, sin(ang)) * 0.9
		_spawn(feet + r + Vector3(0, 0.15, 0), Vector3(0, _rng.randf_range(1.4, 2.4), 0) - r * 0.2, col.lightened(0.3), 0.15 if tex == 0 else 0.26, 0.85, 0.5, FLY, 0.015 * i, Vector3.ZERO, 0.0, false, 1.0, tex)
	_spawn(feet + Vector3(0, 1.0, 0), Vector3(0, 0.3, 0), Color(col.r, col.g, col.b, 0.55), 2.4, 0.8, 0.0, HANG, 0.0, Vector3.ZERO, 0.0, true)

## Sparks thrown up at the sky by a weather caller.
func _plume(at: Vector3, col: Color) -> void:
	for i in 24:
		var v := Vector3(_rng.randf_range(-0.8, 0.8), _rng.randf_range(6.0, 9.0), _rng.randf_range(-0.8, 0.8))
		_spawn(at, v, (col if i % 3 else Color.WHITE).lightened(_rng.randf_range(0.0, 0.3)), 0.17, 0.85, -3.0, FLY, 0.012 * i)

## Motes drawn along a sagging thread from the drained target back to the attacker.
func _thread(from: Vector3, to: Vector3, col: Color) -> void:
	for i in 16:
		_spawn(from, Vector3(0, _rng.randf_range(-0.1, 0.1), 0), col.lightened(_rng.randf_range(0.1, 0.4)), 0.24, 0.6, 0.0, PATH, 0.03 * i, to, -0.5, true)

## A weather call: a full-screen flash in the weather's colour, the call sound, and a ramp of its particles.
func _weather_call(w: String) -> void:
	var look: Array = WEATHER_LOOK.get(w, WEATHER_LOOK.clear)
	Audio.sfx_at("weather_call", 0.0, {"sunshine": 1.15, "downpour": 0.85, "fog": 0.9, "frost": 1.1}.get(w, 1.0))
	if _flash == null:
		var layer := CanvasLayer.new()
		layer.layer = 1  # over the stage, under the battle UI
		add_child(layer)
		_flash = ColorRect.new()
		_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_flash)
	var c: Color = look[0]
	_flash.color = Color(c.r, c.g, c.b, 0.6 * Settings.flash_scale(0.25))
	var tw := _flash.create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not dio.is_interior():
		_weather_particles(w)

## The stage-wide burst of a weather arriving: it builds over about 1.4 s, densest at the end (the ramp).
func _weather_particles(w: String) -> void:
	var o := dio.global_position
	match w:
		"drizzle", "downpour":
			var n := 34 if w == "drizzle" else 70
			for i in n:
				var at := o + Vector3(_rng.randf_range(-8, 8), _rng.randf_range(6.5, 9.0), _rng.randf_range(-6, 4))
				_spawn(at, Vector3(1.2, -15.0, 0), Color(0.8, 0.88, 1.0, 0.75), 0.05, 0.6, 0.0, FLY, 1.4 * sqrt(_rng.randf()), Vector3.ZERO, 0.0, false, 9.0)
		"fog":
			for i in 14:
				var at := o + Vector3(_rng.randf_range(-8, 8), _rng.randf_range(0.4, 2.2), _rng.randf_range(-5, 3))
				_spawn(at, Vector3(0.7, 0, 0), Color(0.92, 0.93, 0.95, 0.55), _rng.randf_range(3.0, 4.5), 2.4, 0.0, HANG, 0.08 * i, Vector3.ZERO, 0.0, true)
		"gale":
			var leaf := [Color("c9762f"), Color("a8552a"), Color("d9a441"), Color("7d8a3a")]
			for i in 40:
				var at := o + Vector3(-9.0, _rng.randf_range(0.3, 4.0), _rng.randf_range(-5, 3))
				_spawn(at, Vector3(_rng.randf_range(11, 15), _rng.randf_range(-0.5, 1.5), _rng.randf_range(-1, 1)), leaf[i % 4], 0.14, 1.4, -1.0, FLY, 1.2 * sqrt(_rng.randf()))
		"frost":
			for i in 44:
				var at := o + Vector3(_rng.randf_range(-8, 8), _rng.randf_range(4.0, 7.0), _rng.randf_range(-5, 3))
				_spawn(at, Vector3(0.4, -2.2, 0), Color(0.94, 0.98, 1.0, 0.9), _rng.randf_range(0.08, 0.15), 2.0, 0.0, FLY, 1.2 * sqrt(_rng.randf()), Vector3.ZERO, 0.0, true)
		"sunshine":
			for i in 34:
				var at := o + Vector3(_rng.randf_range(-7, 7), _rng.randf_range(0.2, 2.5), _rng.randf_range(-5, 3))
				_spawn(at, Vector3(0, _rng.randf_range(0.6, 1.2), 0), Color(1.0, 0.9, 0.55, 0.9), _rng.randf_range(0.1, 0.2), 1.6, 0.0, HANG, 0.9 * _rng.randf(), Vector3.ZERO, 0.0, true)

## Moves the battle sky to a new weather: blended over 1.5 s (not the overworld's 8 s, which is two turns long)
## when it was just called, at once otherwise, and tints the painted sky behind the stage to match.
func _weather_sky(w: String, called: bool) -> void:
	if sky != null:
		if called and not dio.is_interior():
			sky.set_weather(w, false, true)
			if _sky_tween and _sky_tween.is_valid():
				_sky_tween.kill()
			_sky_tween = create_tween()
			_sky_tween.tween_property(sky, "_blend", 1.0, 1.5)
			_sky_tween.tween_callback(func(): sky.apply_time(Game.local_minutes()))
		else:
			sky.set_weather(w, dio.is_interior())
	var back := dio.get("_backdrop") as MeshInstance3D
	if back == null or dio.is_interior():
		return
	var bm := back.material_override as StandardMaterial3D
	var look: Array = WEATHER_LOOK.get(w, WEATHER_LOOK.clear)
	if called:
		var f: Color = look[0]
		bm.albedo_color = f.lerp(Color(1.6, 1.6, 1.6), 0.5 * Settings.flash_scale(0.2))
	back.create_tween().tween_property(bm, "albedo_color", look[1], 1.3).set_trans(Tween.TRANS_SINE)

func _hit(side: int, hp: int, strength: String, pos := 0) -> void:
	Audio.sfx("hit")
	dio.swoop_to_target(side, pos)
	var small := _multi  # one small burst per blow of a multi-hit
	dio.shake = {"strong": 1.0, "normal": 0.55, "weak": 0.25}.get(strength, 0.5) * Settings.flash_scale(0.25) * (0.5 if small else 1.0)
	var a := _actor(side, pos)
	var n := 12 if strength == "weak" else 24
	var base := Color("fff2d0") if strength != "strong" else Color("ffd070")
	burst(_chest(side, pos), base.lerp(_hit_tint, 0.55), _n(n / 2 if small else n), 3.0 if small else 4.0, 0.15 if small else 0.2, 0.4)
	var before := hud.shown_hp(side, pos)
	var frac := absf(before - hp) / maxf(1.0, hud.max_hp(side, pos))
	hud.tween_hp(side, hp, clampf(0.35 + frac * 1.4, 0.35, 1.4), pos)
	await a.hit(strength, _hit_tint)
	await _wait(maxf(0.0, clampf(0.35 + frac * 1.4, 0.35, 1.4) - 0.45))

func _switch(side: int, c: Creature, pos := 0) -> void:
	var a := _actor(side, pos)
	if a.sprite.visible:
		await a.pop_out()
	a.show_creature(c, side == Battle.PLAYER)
	hud.set_creature(side, c, pos)
	Audio.sfx("send_out")
	Audio.cry(c.species)
	burst(a.global_position + Vector3(0, 1.0, 0), Color("fff2d0"), 20, 3.0, 0.16, 0.6, -1.0)
	await a.pop_in()

func _snare_mesh() -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = 0.24
	s.height = 0.48
	s.radial_segments = 8
	s.rings = 4
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("b88b4a")
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = m
	var band := MeshInstance3D.new()
	var bm := TorusMesh.new()
	bm.inner_radius = 0.2
	bm.outer_radius = 0.27
	bm.rings = 10
	bm.ring_segments = 5
	band.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color("6b4a32")
	band.material_override = bmat
	mi.add_child(band)
	return mi

func _catch(success: bool, wobbles: int) -> void:
	var foe := _actor(Battle.FOE)
	var me := _actor(Battle.PLAYER)
	var snare := _snare_mesh()
	dio.add_child(snare)
	var start := me.global_position + Vector3(0.6, 1.2, 0.2)
	var end := foe.world_centre()
	snare.position = start
	dio.swoop_to_target(Battle.FOE)
	Audio.sfx("throw")
	var arc := create_tween()
	arc.tween_method(func(t: float):
		snare.position = start.lerp(end, t) + Vector3(0, sin(t * PI) * 2.0, 0)
		snare.rotation.z = t * TAU * 2.0, 0.0, 1.0, 0.7)
	await arc.finished
	burst(end, Color("fff2d0"), 14, 3.0, 0.16, 0.5, -1.0)
	foe.absorb(true)
	var ground := foe.global_position + Vector3(0, 0.26, 0)
	var drop := create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop.tween_property(snare, "position", ground, 0.55)
	await drop.finished
	await _wait(0.25)
	for i in wobbles:
		Audio.sfx("wobble")
		var w := create_tween()
		w.tween_property(snare, "rotation:z", 0.5, 0.14).set_trans(Tween.TRANS_SINE)
		w.tween_property(snare, "rotation:z", -0.5, 0.28).set_trans(Tween.TRANS_SINE)
		w.tween_property(snare, "rotation:z", 0.0, 0.14).set_trans(Tween.TRANS_SINE)
		await w.finished
		await _wait(0.4)
	if success:
		Audio.sfx("caught")
		burst(ground + Vector3(0, 0.3, 0), Color("ffd870"), 30, 4.0, 0.2, 0.9, -3.0)
		foe.sprite.visible = false
		foe.shadow.visible = false
		var dim := create_tween()
		dim.tween_property(snare, "scale", Vector3(1.15, 0.85, 1.15), 0.12)
		dim.tween_property(snare, "scale", Vector3.ONE, 0.15)
		await dim.finished
		await _wait(0.5)
		var away := create_tween()
		away.tween_property(snare, "scale", Vector3.ONE * 0.01, 0.3)
		await away.finished
	else:
		Audio.sfx("broke_free")
		burst(ground + Vector3(0, 0.3, 0), Color("ffffff"), 22, 4.0, 0.18, 0.5, -2.0)
		snare.visible = false
		await foe.absorb(false)
	snare.queue_free()
