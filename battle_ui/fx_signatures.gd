class_name FXSignatures
extends RefCounted
## Hand-written choreography for 16 well-known moves, one per type (wave 47 F). Each layers two or three of BattleFX's
## primitives with a beat between, and finishes inside about 0.7 s. BattleFX.play_shape plays every other move.

## move id -> the method here that plays it. Tests check each is a real move of the type in the comment.
const SEQ := {
	"bolt_from_the_blue": &"_storm",    # storm
	"thorn_volley": &"_hedgerow",       # hedgerow
	"spate_surge": &"_brook",           # brook
	"tidal_surge": &"_tide",            # tide
	"blaze_dash": &"_hearth",           # hearth
	"peregrine_plunge": &"_gale",       # gale
	"cairngorm_blizzard": &"_frost",    # frost
	"quarry_blast": &"_stone",          # stone
	"will_o_wisp": &"_bog",             # bog
	"forge_hammer": &"_iron",           # iron
	"rush_hour": &"_urban",             # urban
	"hollow_hill_hammer": &"_fae",      # fae
	"banshee_shriek": &"_spirit",       # spirit
	"haymaker": &"_brawn",              # brawn
	"moonlit_pounce": &"_night",        # night
	"hurley_swing": &"_kin",            # kin
}

var fx: BattleFX

func has_move(id: String) -> bool:
	return SEQ.has(id)

func play(id: String, side: int, pos: int, other: int, hit_pos: Array, t_pos: int, pal: Array, col: Color) -> void:
	await call(SEQ[id], side, pos, other, hit_pos, t_pos, pal, col)

func _storm(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	await fx._wait(0.2)  # the beat: a dim, held breath, then the strike from above
	for i in 12:
		var k := i / 11.0
		var at := tp + Vector3(sin(k * 9.0) * 0.35, lerpf(3.4, 0.0, k), 0.2)
		fx._spawn(at, Vector3.ZERO, Color(pal[1].r, pal[1].g, pal[1].b, 0.95), 0.6, 0.22, 0.0, BattleFX.HANG, k * 0.06, Vector3.ZERO, 0.0, true)
		fx._spawn(at, Vector3.ZERO, Color.WHITE, 0.25, 0.22, 0.0, BattleFX.HANG, k * 0.06, Vector3.ZERO, 0.0, true)
	await fx._wait(0.1)
	fx._ring(tp, col, pal[1], 3)
	fx._impact(other, hit_pos, pal, 26)
	await fx._wait(0.4)

func _hedgerow(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var u := fx._chest(side, pos)
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	await fx._wait(0.1)
	for i in 5:  # a fan of thorns, then they all land
		var fan := Vector3(0, (i - 2) * 0.35, 0)
		fx._spawn(u, Vector3.ZERO, pal[1], 0.34, 0.3, 0.0, BattleFX.PATH, 0.05 * i, tp + fan, 0.2, true, 1.0, 3)
	await fx._wait(0.36)
	fx.burst(tp, col, fx._n(18), 4.0, 0.2, 0.5, -3.0, Vector3.UP, 6)
	await fx._wait(0.2)

func _brook(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	await fx.play_shape("wave", side, pos, other, hit_pos, t_pos, false, pal, col)
	await fx.play_shape("rain", side, pos, other, hit_pos, t_pos, false, pal, col)

func _tide(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var u := fx._chest(side, pos)
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	for k in 2:  # two swells, the second bigger
		for i in fx._n(12):
			fx._spawn(u + Vector3(0, -0.4, 0), Vector3(0, 0, sin(i) * 0.9), col.lerp(pal[1], k * 0.4), 0.4 + 0.2 * k, 0.4, 0.0, BattleFX.PATH, 0.03 * i + 0.25 * k, tp + Vector3(0, -0.2 + 0.5 * k, 0), 0.5 + 0.5 * k, true, 1.0, 4)
	await fx._wait(0.5)
	fx.burst(tp, pal[1], fx._n(26), 5.0, 0.22, 0.5, -5.0, Vector3.UP, 4)
	fx._impact(other, hit_pos, pal, 14)
	await fx._wait(0.2)

func _hearth(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var a := fx._actor(side, pos)
	var u := fx._chest(side, pos)
	var tp := fx._chest(other, t_pos)
	for i in fx._n(16):  # a trail of embers laid down along the dash
		var k := i / 15.0
		fx._spawn(u.lerp(tp, k), Vector3(0, 0.8, 0), col.lerp(pal[1], k), 0.3, 0.4, 0.5, BattleFX.FLY, k * 0.2, Vector3.ZERO, 0.0, true)
	fx._impact(other, hit_pos, pal, 30, 0.22)
	await a.lunge(fx._aim(other, t_pos, false))

func _gale(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var u := fx._chest(side, pos)
	var tp := fx._chest(other, t_pos)
	for i in fx._n(8):  # rise in a flurry of feathers
		fx._spawn(u, Vector3(randf_range(-1, 1), 3.0, 0), pal[1], 0.24, 0.3, 0.0, BattleFX.FLY, 0.02 * i, Vector3.ZERO, 0.0, false, 1.0, 6)
	await fx._wait(0.25)
	for i in 8:  # then the stoop: a streak from high above
		var k := i / 7.0
		fx._spawn(tp + Vector3(1.4, 3.2, 0).lerp(Vector3.ZERO, k), Vector3.ZERO, col.lightened(0.4), 0.35, 0.2, 0.0, BattleFX.HANG, k * 0.1, Vector3.ZERO, 0.0, true, 2.5, 3)
	await fx._wait(0.2)
	fx._impact(other, hit_pos, pal, 24)
	fx._slash(tp, pal[1], col, 6, true)
	await fx._wait(0.25)

func _frost(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	await fx._wait(0.1)
	for i in fx._n(34):  # a hard slanting snow
		fx._spawn(tp + Vector3(randf_range(-1.6, 1.0), 2.5 + randf(), randf_range(-0.5, 0.5)), Vector3(2.5, -7.0, 0), pal[1], randf_range(0.1, 0.22), 0.4, 0.0, BattleFX.FLY, randf() * 0.4, Vector3.ZERO, 0.0, true, 1.0, 3 if i % 3 else 2)
	fx._spawn(tp, Vector3(0.3, 0, 0), Color(col.r, col.g, col.b, 0.5), 2.6, 0.7, 0.0, BattleFX.HANG, 0.15, Vector3.ZERO, 0.0, true)
	fx._impact(other, hit_pos, pal, 20, 0.45)
	await fx._wait(0.7)

func _stone(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	await fx._wait(0.2)
	fx.dio.shake = 0.6 * Settings.flash_scale(0.2)
	fx._ring(tp, col, pal[1], 3)
	fx.burst(tp, col, fx._n(22), 5.0, 0.26, 0.6, -10.0, Vector3.UP, 3)  # rubble
	fx._dust(fx._actor(other, t_pos).global_position, col)
	await fx._wait(0.5)

func _bog(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var u := fx._chest(side, pos) + Vector3(0, 0.5, 0)
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	for i in 3:  # three wisps circle up, then drift over together
		var off := Vector3(cos(i * 2.1) * 0.7, 0.4 * i, sin(i * 2.1) * 0.4)
		fx._spawn(u + off, Vector3(0, 0.5, 0), pal[1], 0.5, 0.25, 0.0, BattleFX.HANG, 0.0, Vector3.ZERO, 0.0, true)
		fx._spawn(u + off, Vector3.ZERO, col.lightened(0.5), 0.5, 0.4, 0.0, BattleFX.PATH, 0.25, tp + off * 0.5, 0.5, true)
		fx._spawn(u + off, Vector3.ZERO, Color.WHITE, 0.2, 0.4, 0.0, BattleFX.PATH, 0.25, tp + off * 0.5, 0.5, true)
	await fx._wait(0.7)
	fx._impact(other, hit_pos, pal, 20)
	await fx._wait(0.05)

func _iron(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	for i in 6:  # the hammer rises over the target
		fx._spawn(tp + Vector3((i - 2.5) * 0.2, 2.6, 0.2), Vector3(0, 0.3, 0), col.lightened(0.2), 0.34, 0.25, 0.0, BattleFX.HANG, 0.0, Vector3.ZERO, 0.0, false)
	await fx._wait(0.3)
	for i in 6:  # and comes down
		fx._spawn(tp + Vector3((i - 2.5) * 0.2, 2.6, 0.2), Vector3(0, -11.0, 0), pal[1], 0.34, 0.2, 0.0, BattleFX.FLY)
	await fx._wait(0.2)
	fx.dio.shake = 0.6 * Settings.flash_scale(0.2)
	fx.burst(tp, Color("ffb050"), fx._n(26), 6.0, 0.14, 0.5, -8.0, Vector3.UP, 3)  # sparks off the anvil
	fx._impact(other, hit_pos, pal, 14)
	await fx._wait(0.25)

func _urban(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var tp := fx._chest(other, t_pos)
	var u := fx._chest(side, pos)
	fx._actor(side, pos).cast()
	for lane in 3:  # three lanes of headlamps, nose to tail
		for i in 4:
			fx._spawn(u + Vector3(0, lane * 0.4 - 0.4, 0), Vector3.ZERO, pal[1] if i % 2 == 0 else col, 0.3, 0.3, 0.0, BattleFX.PATH, 0.08 * i + 0.06 * lane, tp + Vector3(0, lane * 0.4 - 0.4, 0), 0.0, true, 2.0)
	await fx._wait(0.55)
	fx._impact(other, hit_pos, pal, 24)
	await fx._wait(0.1)

func _fae(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	for i in fx._n(14):  # a fairy ring of stars closes in...
		var ang := TAU * i / 14.0
		fx._spawn(tp + Vector3(cos(ang), sin(ang) * 0.8, 0) * 1.5, Vector3.ZERO, pal[1], 0.28, 0.3, 0.0, BattleFX.PATH, 0.0, tp, 0.0, true, 1.0, 2)
	await fx._wait(0.35)
	fx.burst(tp, col, fx._n(30), 5.0, 0.3, 0.55, -1.0, Vector3.UP, 2)
	fx._impact(other, hit_pos, pal, 14)
	await fx._wait(0.3)

func _spirit(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var u := fx._chest(side, pos)
	var tp := fx._chest(other, t_pos)
	fx._actor(side, pos).cast()
	for w in 3:  # shrieking rings, one after another, travelling out
		for i in fx._n(12):
			var ang := TAU * i / 12.0
			fx._spawn(u + Vector3(0, 0.3, 0), Vector3(cos(ang) * 1.6 + (tp.x - u.x) * 1.3, sin(ang) * 1.1, 0), col.lerp(pal[1], w * 0.3), 0.3, 0.4, 0.0, BattleFX.FLY, 0.14 * w, Vector3.ZERO, 0.0, false, 1.0, 1)
	await fx._wait(0.55)
	fx._impact(other, hit_pos, pal, 16)
	await fx._wait(0.1)

func _brawn(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var a := fx._actor(side, pos)
	a.cast()  # the wind-up everyone can see coming
	await fx._wait(0.25)
	fx.dio.shake = 0.8 * Settings.flash_scale(0.2)
	fx._impact(other, hit_pos, pal, 34, 0.12)
	fx._ring(fx._chest(other, t_pos), col, pal[1], 2)
	await a.lunge(fx._aim(other, t_pos, false))

func _night(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var a := fx._actor(side, pos)
	var tp := fx._chest(other, t_pos)
	for i in fx._n(12):  # a crescent of moonlight hangs, then the pounce
		var k := i / 11.0
		fx._spawn(a.global_position + Vector3(lerpf(-0.8, 0.8, k), 2.0 + sin(k * PI) * 0.6, 0), Vector3.ZERO, pal[1], 0.28, 0.35, 0.0, BattleFX.HANG, k * 0.1, Vector3.ZERO, 0.0, true, 1.0, 2)
	await fx._wait(0.2)
	fx._slash(tp, pal[1], col, 3)
	fx._impact(other, hit_pos, pal, 22, 0.15)
	await a.lunge(fx._aim(other, t_pos, false))

func _kin(side, pos, other, hit_pos, t_pos, pal, col) -> void:
	var a := fx._actor(side, pos)
	var u := fx._chest(side, pos)
	var tp := fx._chest(other, t_pos)
	a.lunge(fx._aim(other, t_pos, false))  # the swing, and the ball it sends off
	await fx._wait(0.14)
	fx._slash(u.lerp(tp, 0.3), pal[1], col, 2)
	await fx._wait(0.1)
	fx._spawn(u.lerp(tp, 0.3), Vector3.ZERO, Color.WHITE, 0.4, 0.22, 0.0, BattleFX.PATH, 0.0, tp, 0.5, true, 1.0, 2)
	await fx._wait(0.3)
	fx._impact(other, hit_pos, pal, 22)
