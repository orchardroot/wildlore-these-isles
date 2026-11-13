class_name SfxRecipes
extends RefCounted
## Sound effect recipes. Each id renders to a buffer of exactly round(LENGTHS[id] * SR) frames, peak set by PEAKS[id].

const SR := 44100

const LENGTHS := {
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
	"thunder": 6.0, "thunder_far": 6.5, "text_blip": 0.045,
	# 2.1 battle voices: one attack per type family (AudioIds.ATTACK_VOICE), the wild sting, stat and weather calls.
	"atk_thud": 0.32, "atk_rustle": 0.4, "atk_splash": 0.45, "atk_crackle": 0.5, "atk_whoosh": 0.45, "atk_zap": 0.4,
	"atk_ice": 0.5, "atk_crunch": 0.4, "atk_squelch": 0.42, "atk_clang": 0.55, "atk_shimmer": 0.6, "atk_wail": 0.6,
	"encounter": 1.1, "stat_up": 0.45, "stat_down": 0.45, "weather_call": 1.3,
}
const PEAKS := {
	"cursor": 0.5, "confirm": 0.6, "cancel": 0.55, "bump": 0.6, "door": 0.6, "step_grass": 0.55,
	"hit": 0.8, "hit_super": 0.9, "hit_weak": 0.5, "faint": 0.42, "snare_throw": 0.6, "snare_wobble": 0.6,
	"caught": 0.8, "level_up": 0.8, "heal": 0.7, "badge": 0.85, "evolve": 0.85,
	"cut": 0.9, "splash": 0.7, "scramble": 0.9, "bike_bell": 0.7, "train": 0.7, "ship_horn": 0.8,
	"crow": 0.75, "tomb_light": 0.7, "harp_gliss": 0.7,
	"lantern_on": 0.7, "bog_squelch": 0.75, "bagpipe_drone": 0.7,
	"bell_toll": 0.8, "raven_caw": 0.75, "train_rush": 0.7,
	"step_path": 0.6, "step_stone": 0.6, "step_wood": 0.6, "step_sand": 0.5, "step_soft": 0.5, "step_wet": 0.6, "bike_tyre": 0.5,
	"talk_blip": 0.45, "sign_creak": 0.6, "shop_bell": 0.6, "sanctuary_chime": 0.6, "brake_squeal": 0.6,
	"radio_tune": 0.6,
	"thunder": 0.85, "thunder_far": 0.6, "text_blip": 0.3,
	"atk_thud": 0.75, "atk_rustle": 0.65, "atk_splash": 0.7, "atk_crackle": 0.7, "atk_whoosh": 0.65, "atk_zap": 0.65,
	"atk_ice": 0.6, "atk_crunch": 0.75, "atk_squelch": 0.5, "atk_clang": 0.8, "atk_shimmer": 0.55, "atk_wail": 0.55,
	"encounter": 0.75, "stat_up": 0.55, "stat_down": 0.55, "weather_call": 0.85,
}

static func ids() -> Array:
	return LENGTHS.keys()

static func _tone(kind: int, f0: float, f1: float, dur: float, a: float, d: float, s: float, r: float, lp := 0.0, duty := 0.5) -> PackedFloat32Array:
	var b := Synth.osc(kind, f0, f1, dur, SR, duty)
	if lp > 0.0:
		Synth.lowpass(b, lp, SR)
	Synth.adsr(b, SR, a, d, s, r)
	return b

## Decaying sine bell with an inharmonic-ish overtone.
static func _bell(f: float, dur: float, k: float) -> PackedFloat32Array:
	var b := Synth.osc(Synth.SINE, f, f, dur, SR)
	var h := Synth.osc(Synth.SINE, f * 2.01, f * 2.01, dur, SR)
	Synth.mix_into(b, h, 0, 0.3)
	Synth.pluck_env(b, SR, 0.002, k)
	return b

static func _noise_burst(dur: float, lp: float, hp: float, k: float, seed: int) -> PackedFloat32Array:
	var n := Synth.noise(dur, SR, seed)
	if lp > 0.0:
		Synth.lowpass(n, lp, SR)
	if hp > 0.0:
		Synth.highpass(n, hp, SR)
	Synth.pluck_env(n, SR, 0.001, k)
	return n

static func _at(sec: float) -> int:
	return Synth.frames(sec, SR)

static func render(id: String) -> PackedFloat32Array:
	var out := Synth.make(Synth.frames(LENGTHS[id], SR))
	match id:
		"cursor":
			Synth.mix_into(out, _tone(Synth.SQUARE, 1250.0, 1250.0, 0.05, 0.002, 0.02, 0.2, 0.025, 4500.0, 0.25), 0)
		"confirm":
			Synth.mix_into(out, _tone(Synth.SQUARE, 660.0, 660.0, 0.07, 0.003, 0.02, 0.6, 0.03, 3500.0, 0.3), 0)
			Synth.mix_into(out, _tone(Synth.SQUARE, 990.0, 990.0, 0.09, 0.003, 0.03, 0.5, 0.05, 3500.0, 0.3), _at(0.07))
		"cancel":
			Synth.mix_into(out, _tone(Synth.SQUARE, 600.0, 600.0, 0.07, 0.003, 0.02, 0.6, 0.03, 2500.0, 0.4), 0)
			Synth.mix_into(out, _tone(Synth.SQUARE, 400.0, 400.0, 0.09, 0.003, 0.03, 0.5, 0.05, 2500.0, 0.4), _at(0.07))
		"bump":
			var t := Synth.osc(Synth.SINE, 170.0, 65.0, 0.12, SR)
			Synth.pluck_env(t, SR, 0.002, 28.0)
			Synth.mix_into(out, t, 0)
			Synth.mix_into(out, _noise_burst(0.05, 700.0, 0.0, 60.0, 5), 0, 0.5)
		"door":
			var thump := Synth.osc(Synth.SINE, 120.0, 60.0, 0.16, SR)
			Synth.pluck_env(thump, SR, 0.002, 20.0)
			Synth.mix_into(out, thump, 0)
			Synth.mix_into(out, _noise_burst(0.1, 1800.0, 200.0, 30.0, 8), 0, 0.5)
			var creak := Synth.osc(Synth.TRI, 240.0, 190.0, 0.22, SR, 0.5, 9.0, 120.0)
			Synth.lowpass(creak, 900.0, SR)
			Synth.adsr(creak, SR, 0.05, 0.05, 0.6, 0.08)
			Synth.mix_into(out, creak, _at(0.08), 0.28)
			Synth.mix_into(out, _noise_burst(0.04, 0.0, 1500.0, 80.0, 9), _at(0.36), 0.35)
		"step_grass":
			var n := Synth.noise(0.12, SR, 12)
			Synth.lowpass(n, 3200.0, SR)
			Synth.highpass(n, 600.0, SR)
			Synth.adsr(n, SR, 0.012, 0.04, 0.3, 0.05)
			Synth.mix_into(out, n, 0)
		"hit":
			var t := Synth.osc(Synth.SINE, 260.0, 70.0, 0.22, SR)
			Synth.pluck_env(t, SR, 0.002, 16.0)
			Synth.mix_into(out, t, 0)
			Synth.mix_into(out, _noise_burst(0.1, 4500.0, 300.0, 35.0, 13), 0, 0.8)
		"hit_super":
			var t := Synth.osc(Synth.SINE, 300.0, 60.0, 0.38, SR)
			Synth.pluck_env(t, SR, 0.002, 9.0)
			Synth.mix_into(out, t, 0)
			Synth.mix_into(out, _noise_burst(0.16, 6000.0, 300.0, 22.0, 14), 0, 1.0)
			var ping := _tone(Synth.SQUARE, 880.0, 1760.0, 0.14, 0.002, 0.04, 0.5, 0.06, 5000.0, 0.25)
			Synth.mix_into(out, ping, _at(0.02), 0.35)
			Synth.mix_into(out, _bell(1320.0, 0.25, 12.0), _at(0.1), 0.3)
		"hit_weak":
			var t := Synth.osc(Synth.SINE, 150.0, 85.0, 0.2, SR)
			Synth.pluck_env(t, SR, 0.003, 18.0)
			Synth.mix_into(out, t, 0)
			Synth.mix_into(out, _noise_burst(0.08, 1300.0, 150.0, 45.0, 15), 0, 0.5)
		"faint":
			var d := Synth.osc(Synth.TRI, 520.0, 110.0, 0.8, SR, 0.5, 6.0, 60.0)
			Synth.lowpass(d, 1600.0, SR)
			Synth.adsr(d, SR, 0.02, 0.2, 0.7, 0.35)
			Synth.mix_into(out, d, 0)
		"snare_throw":
			var w := Synth.noise(0.35, SR, 16)
			Synth.lowpass_sweep(w, 500.0, 4200.0, SR)
			Synth.adsr(w, SR, 0.08, 0.1, 0.6, 0.12)
			Synth.mix_into(out, w, 0, 0.9)
			var s := Synth.osc(Synth.SINE, 300.0, 750.0, 0.3, SR)
			Synth.adsr(s, SR, 0.05, 0.05, 0.5, 0.1)
			Synth.mix_into(out, s, 0, 0.3)
		"snare_wobble":
			var w := Synth.osc(Synth.TRI, 330.0, 300.0, 0.4, SR, 0.5, 7.0, 380.0)
			Synth.lowpass(w, 1800.0, SR)
			Synth.adsr(w, SR, 0.01, 0.1, 0.6, 0.15)
			Synth.mix_into(out, w, 0, 0.8)
			Synth.mix_into(out, _noise_burst(0.03, 0.0, 1800.0, 90.0, 17), 0, 0.3)
		"caught":
			var notes := [523.25, 659.25, 783.99, 1046.5]
			for i in 4:
				Synth.mix_into(out, _bell(float(notes[i]), 0.5, 5.0), _at(0.09 * i), 0.7)
			var chord_at := _at(0.4)
			for f in [523.25, 659.25, 783.99, 1046.5]:
				Synth.mix_into(out, _bell(f, 0.5, 4.5), chord_at, 0.4)
			Synth.mix_into(out, _bell(2093.0, 0.4, 8.0), chord_at, 0.15)
		"level_up":
			var notes := [392.0, 493.88, 587.33, 783.99, 987.77]
			for i in 5:
				var t := _tone(Synth.SQUARE, float(notes[i]), float(notes[i]), 0.12, 0.003, 0.03, 0.6, 0.05, 3800.0, 0.35)
				Synth.mix_into(out, t, _at(0.075 * i), 0.5)
			for f in [783.99, 987.77, 1174.66]:
				var h := _tone(Synth.TRI, f, f, 0.4, 0.01, 0.1, 0.6, 0.25)
				Synth.mix_into(out, h, _at(0.375), 0.45)
		"heal":
			var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
			for i in 5:
				Synth.mix_into(out, _bell(float(notes[i]), 0.55, 4.0), _at(0.11 * i), 0.6)
			Synth.mix_into(out, _bell(2093.0, 0.35, 7.0), _at(0.5), 0.25)
		"badge":
			var seq := [[392.0, 0.0, 0.14], [523.25, 0.16, 0.14], [659.25, 0.32, 0.14]]
			for s in seq:
				var t := Synth.osc(Synth.SAW, float(s[0]), float(s[0]), float(s[2]) + 0.04, SR)
				Synth.lowpass(t, 2200.0, SR)
				Synth.adsr(t, SR, 0.01, 0.03, 0.8, 0.04)
				Synth.mix_into(out, t, _at(float(s[1])), 0.5)
			for f in [392.0, 523.25, 659.25, 783.99]:
				var t := Synth.osc(Synth.SAW, f, f, 0.85, SR, 0.5, 5.5, 12.0, 0.1)
				Synth.lowpass(t, 2400.0, SR)
				Synth.adsr(t, SR, 0.02, 0.15, 0.75, 0.45)
				Synth.mix_into(out, t, _at(0.5), 0.35)
			Synth.mix_into(out, _bell(1568.0, 0.8, 4.0), _at(0.5), 0.2)
		"evolve":
			var g := Synth.osc(Synth.SINE, 220.0, 1760.0, 1.0, SR, 0.5, 11.0, 40.0)
			Synth.adsr(g, SR, 0.15, 0.1, 0.8, 0.15)
			Synth.mix_into(out, g, 0, 0.45)
			var g2 := Synth.osc(Synth.TRI, 330.0, 2640.0, 1.0, SR)
			Synth.lowpass(g2, 3000.0, SR)
			Synth.adsr(g2, SR, 0.2, 0.1, 0.6, 0.2)
			Synth.mix_into(out, g2, 0, 0.2)
			var sp := [880.0, 1108.7, 1318.5, 1760.0, 2217.4, 2637.0]
			for i in 6:
				Synth.mix_into(out, _bell(float(sp[i]), 0.4, 7.0), _at(0.35 + 0.1 * i), 0.3)
			for f in [523.25, 659.25, 783.99, 1046.5]:
				var t := Synth.osc(Synth.TRI, f, f, 0.8, SR)
				Synth.adsr(t, SR, 0.02, 0.2, 0.6, 0.5)
				Synth.mix_into(out, t, _at(1.0), 0.4)
			Synth.mix_into(out, _bell(2093.0, 0.8, 3.0), _at(1.0), 0.25)
		"cut":
			# Two snips of the shears, a twig crack, a rustle of falling bramble.
			for at in [0.0, 0.09]:
				Synth.mix_into(out, _noise_burst(0.05, 0.0, 3000.0, 70.0, 41 + int(at * 100.0)), _at(at), 0.8)
				var snap := Synth.osc(Synth.TRI, 2100.0, 1100.0, 0.04, SR)
				Synth.pluck_env(snap, SR, 0.0005, 80.0)
				Synth.mix_into(out, snap, _at(at), 0.4)
			Synth.mix_into(out, _noise_burst(0.03, 0.0, 1800.0, 90.0, 44), _at(0.17), 0.3)
			var rus := Synth.noise(0.1, SR, 45)
			Synth.lowpass(rus, 3500.0, SR)
			Synth.highpass(rus, 900.0, SR)
			Synth.adsr(rus, SR, 0.02, 0.03, 0.4, 0.05)
			Synth.mix_into(out, rus, _at(0.19), 0.2)
		"splash":
			var w := Synth.noise(0.5, SR, 51)
			Synth.lowpass_sweep(w, 4000.0, 700.0, SR)
			Synth.highpass(w, 150.0, SR)
			Synth.adsr(w, SR, 0.01, 0.12, 0.35, 0.3)
			Synth.mix_into(out, w, 0, 0.9)
			var plop := Synth.osc(Synth.SINE, 300.0, 120.0, 0.15, SR)
			Synth.pluck_env(plop, SR, 0.002, 18.0)
			Synth.mix_into(out, plop, 0, 0.5)
			var drops := [[0.12, 520.0], [0.22, 700.0], [0.31, 610.0], [0.42, 880.0]]
			for dr in drops:
				var bl := Synth.osc(Synth.SINE, float(dr[1]), float(dr[1]) * 1.9, 0.09, SR)
				Synth.pluck_env(bl, SR, 0.002, 30.0)
				Synth.mix_into(out, bl, _at(float(dr[0])), 0.3)
		"scramble":
			# Scree: a rumble underneath and a scatter of stones, thinning out.
			var rum := Synth.noise(0.7, SR, 61)
			Synth.lowpass(rum, 450.0, SR)
			Synth.adsr(rum, SR, 0.05, 0.2, 0.5, 0.35)
			Synth.mix_into(out, rum, 0, 0.7)
			var seed := 7
			var t := 0.0
			var k := 0
			while t < 0.6:
				seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
				var lp := 1200.0 + float(seed % 3000)
				var g := (1.0 - t / 0.7) * 0.7
				Synth.mix_into(out, _noise_burst(0.03, lp, 400.0, 70.0, 70 + k), _at(t), g)
				var st := Synth.osc(Synth.SINE, 500.0 + float((seed >> 8) % 600), 250.0, 0.03, SR)
				Synth.pluck_env(st, SR, 0.0005, 90.0)
				Synth.mix_into(out, st, _at(t), g * 0.4)
				seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
				t += 0.02 + float(seed % 60) / 1000.0 * (1.0 + t)
				k += 1
		"bike_bell":
			for at in [0.0, 0.16]:
				Synth.mix_into(out, _bell(2637.0, 0.5, 6.0), _at(at), 0.7)
				Synth.mix_into(out, _bell(2637.0 * 2.76, 0.4, 9.0), _at(at), 0.3)
				Synth.mix_into(out, _bell(2637.0 * 5.4, 0.2, 18.0), _at(at), 0.12)
		"train":
			# Chuff chuff chuff-chuff, then the whistle.
			for at in [0.0, 0.17, 0.34, 0.45]:
				var ch := Synth.noise(0.11, SR, 81 + int(at * 100.0))
				Synth.lowpass(ch, 1300.0, SR)
				Synth.highpass(ch, 200.0, SR)
				Synth.adsr(ch, SR, 0.015, 0.03, 0.4, 0.05)
				Synth.mix_into(out, ch, _at(at), 0.9)
				var th := Synth.osc(Synth.SINE, 90.0, 55.0, 0.09, SR)
				Synth.pluck_env(th, SR, 0.002, 25.0)
				Synth.mix_into(out, th, _at(at), 0.5)
			for f in [740.0, 932.0]:
				var wh := Synth.osc(Synth.SINE, f, f * 0.98, 0.75, SR, 0.5, 7.0, 12.0, 0.2)
				var wh2 := Synth.osc(Synth.SINE, f * 2.0, f * 2.0, 0.75, SR)
				Synth.mix_into(wh, wh2, 0, 0.18)
				var br := Synth.noise(0.75, SR, 91)
				Synth.highpass(br, 2500.0, SR)
				Synth.mix_into(wh, br, 0, 0.08)
				Synth.adsr(wh, SR, 0.04, 0.1, 0.8, 0.3)
				Synth.mix_into(out, wh, _at(0.65), 0.4)
		"ship_horn":
			for f in [110.0, 165.0, 220.0]:
				var h := Synth.osc(Synth.SAW, f, f * 0.985, 1.5, SR, 0.5, 4.0, 5.0, 0.4)
				var h2 := Synth.osc(Synth.SAW, f * 1.007, f * 0.992, 1.5, SR)
				Synth.mix_into(h, h2, 0, 0.7)
				Synth.lowpass(h, 900.0, SR)
				Synth.adsr(h, SR, 0.08, 0.12, 0.85, 0.35)
				Synth.mix_into(out, h, 0, 0.5)
		"crow":
			# Two harsh caws: a falling saw, chopped by a fast growl, with a rasp of noise on top.
			for cw in [[0.0, 0.24, 780.0, 520.0], [0.33, 0.3, 700.0, 430.0]]:
				var dur: float = cw[1]
				var c := Synth.osc(Synth.SAW, cw[2], cw[3], dur, SR)
				var c2 := Synth.osc(Synth.SAW, float(cw[2]) * 1.5, float(cw[3]) * 1.5, dur, SR)
				Synth.mix_into(c, c2, 0, 0.4)
				for i in c.size():
					c[i] *= 0.55 + 0.45 * sin(TAU * 85.0 * i / SR)
				var rasp := Synth.noise(dur, SR, 61)
				Synth.highpass(rasp, 900.0, SR)
				Synth.lowpass(rasp, 3800.0, SR)
				Synth.mix_into(c, rasp, 0, 0.35)
				Synth.lowpass(c, 2800.0, SR)
				Synth.highpass(c, 300.0, SR)
				Synth.adsr(c, SR, 0.02, 0.05, 0.8, dur * 0.4)
				Synth.mix_into(out, c, _at(cw[0]), 0.7)
		"tomb_light":
			# A rising run of glassy bells over a shimmering, slowly swelling pad.
			var semis := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26]
			for k in semis.size():
				var f := 523.25 * pow(2.0, float(semis[k]) / 12.0)
				var gain := 0.5 + 0.5 * float(k) / semis.size()
				Synth.mix_into(out, _bell(f, 0.85, 4.5), _at(0.02 + k * 0.085), gain * 0.5)
				Synth.mix_into(out, _bell(f * 3.0, 0.4, 9.0), _at(0.02 + k * 0.085), gain * 0.12)
			for f in [1046.5, 1568.0, 2093.0]:
				var sh := Synth.osc(Synth.SINE, f, f * 1.01, 1.6, SR, 0.5, 6.5, 18.0, 0.0)
				Synth.adsr(sh, SR, 0.5, 0.2, 0.6, 0.7)
				Synth.mix_into(out, sh, _at(0.1), 0.12)
		"harp_gliss":
			# Two octaves of D major plucked in a quick sweep, each string ringing on.
			var gl := [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24, 26, 28, 29, 31, 33]
			for k in gl.size():
				var f := 146.83 * pow(2.0, float(gl[k]) / 12.0)
				var s := Synth.osc(Synth.TRI, f, f, 1.2, SR)
				var h := Synth.osc(Synth.SINE, f * 2.0, f * 2.0, 1.2, SR)
				Synth.mix_into(s, h, 0, 0.3)
				Synth.pluck_env(s, SR, 0.002, 3.2)
				Synth.mix_into(out, s, _at(k * 0.04), 0.45 + 0.02 * k)
		"lantern_on":
			# A warm three-note chime, a soft glow underneath, and a few flickering crackles.
			for k in 3:
				var f: float = 659.25 * float([1.0, 1.5, 2.0][k])
				Synth.mix_into(out, _bell(f, 0.9, 4.0), _at(0.02 + k * 0.1), 0.55)
			var glow := _tone(Synth.TRI, 329.6, 329.6, 1.2, 0.15, 0.2, 0.5, 0.6, 1200.0)
			Synth.mix_into(out, glow, 0, 0.3)
			for t in [0.12, 0.31, 0.38, 0.6, 0.83]:
				Synth.mix_into(out, _noise_burst(0.05, 6500.0, 2500.0, 55.0, int(t * 100.0)), _at(t), 0.18)
		"bog_squelch":
			# A wet suck-and-release: a wobbling falling thud, then a smaller bubble, over muddy noise.
			for sq in [[0.0, 240.0, 70.0, 0.32, 1.0], [0.24, 330.0, 110.0, 0.2, 0.55]]:
				var dur: float = sq[3]
				var s := Synth.osc(Synth.SINE, sq[1], sq[2], dur, SR)
				for i in s.size():
					s[i] *= 0.55 + 0.45 * sin(TAU * 31.0 * i / SR)
				Synth.pluck_env(s, SR, 0.004, 7.0)
				Synth.mix_into(out, s, _at(sq[0]), sq[4])
			Synth.mix_into(out, _noise_burst(0.35, 800.0, 120.0, 9.0, 5), 0, 0.5)
		"bagpipe_drone":
			# Tonic, octave and fifth drones swelling in on a bag of air, with a buzzy reed edge, then easing off.
			var d := 2.0
			for dr in [[110.0, 1.0], [55.0, 0.8], [165.0, 0.4]]:
				var f: float = dr[0]
				var s1 := Synth.osc(Synth.SAW, f, f, d, SR)
				var s2 := Synth.osc(Synth.SAW, f * 1.004, f * 1.004, d, SR)
				Synth.mix_into(s1, s2, 0, 0.8)
				Synth.mix_into(out, s1, 0, dr[1])
			var buzz := Synth.osc(Synth.SQUARE, 220.0, 220.0, d, SR, 0.35)
			Synth.mix_into(out, buzz, 0, 0.25)
			Synth.lowpass(out, 900.0, SR)
			Synth.lowpass(out, 900.0, SR)
			Synth.adsr(out, SR, 0.6, 0.2, 0.85, 0.7)
		"bell_toll":
			# A great bell struck once: low hum, strike tone and inharmonic partials ringing out.
			for pt in [[0.5, 0.5, 1.4], [1.0, 1.0, 1.8], [1.19, 0.7, 2.2], [2.0, 0.5, 2.8], [2.74, 0.3, 3.6], [4.1, 0.12, 6.0]]:
				var f: float = 196.0 * float(pt[0])
				var b := Synth.osc(Synth.SINE, f, f, 3.2, SR)
				Synth.pluck_env(b, SR, 0.002, float(pt[2]))
				Synth.mix_into(out, b, 0, pt[1])
			Synth.mix_into(out, _noise_burst(0.05, 2500.0, 400.0, 60.0, 71), 0, 0.3)
		"raven_caw":
			# One deep, rasping kraa and a shorter one: lower and hoarser than the crow, with a slow fall.
			for cw in [[0.0, 0.42, 420.0, 250.0], [0.5, 0.34, 380.0, 210.0]]:
				var dur: float = cw[1]
				var c := Synth.osc(Synth.SAW, cw[2], cw[3], dur, SR)
				var c2 := Synth.osc(Synth.SQUARE, float(cw[2]) * 0.5, float(cw[3]) * 0.5, dur, SR, 0.3)
				Synth.mix_into(c, c2, 0, 0.5)
				for i in c.size():
					c[i] *= 0.5 + 0.5 * sin(TAU * 52.0 * i / SR)
				var rasp := Synth.noise(dur, SR, 77)
				Synth.highpass(rasp, 600.0, SR)
				Synth.lowpass(rasp, 2600.0, SR)
				Synth.mix_into(c, rasp, 0, 0.3)
				Synth.lowpass(c, 1900.0, SR)
				Synth.adsr(c, SR, 0.03, 0.08, 0.75, dur * 0.45)
				Synth.mix_into(out, c, _at(cw[0]), 0.8)
		"train_rush":
			# A train hurtling past: a swelling and fading roar of noise, a driving chug and a distant horn.
			var n := 2.4
			var roar := Synth.noise(n, SR, 93)
			Synth.lowpass(roar, 1400.0, SR)
			Synth.highpass(roar, 90.0, SR)
			for i in roar.size():
				var x := float(i) / roar.size()
				roar[i] *= pow(sin(PI * x), 1.5)
			Synth.mix_into(out, roar, 0, 0.9)
			var at := 0.0
			while at < n - 0.2:
				var amp := pow(sin(PI * at / n), 1.2)
				var ch := Synth.noise(0.07, SR, 200 + int(at * 100.0))
				Synth.lowpass(ch, 1800.0, SR)
				Synth.pluck_env(ch, SR, 0.002, 40.0)
				Synth.mix_into(out, ch, _at(at), 0.8 * amp)
				var th := Synth.osc(Synth.SINE, 80.0, 50.0, 0.08, SR)
				Synth.pluck_env(th, SR, 0.002, 30.0)
				Synth.mix_into(out, th, _at(at), 0.6 * amp)
				at += 0.14
			var horn := Synth.osc(Synth.SAW, 330.0, 310.0, 1.0, SR)
			Synth.lowpass(horn, 1100.0, SR)
			Synth.adsr(horn, SR, 0.08, 0.1, 0.8, 0.5)
			Synth.mix_into(out, horn, _at(0.3), 0.22)
		"step_path":
			# Gravel and packed earth: a soft scuff with a few grains crunching in it.
			var sc := Synth.noise(0.1, SR, 151)
			Synth.lowpass(sc, 2500.0, SR)
			Synth.highpass(sc, 300.0, SR)
			Synth.adsr(sc, SR, 0.006, 0.03, 0.35, 0.05)
			Synth.mix_into(out, sc, 0)
			for g in [[0.0, 152], [0.016, 153], [0.037, 154], [0.06, 155]]:
				Synth.mix_into(out, _noise_burst(0.02, 6000.0, 1500.0, 120.0, g[1]), _at(g[0]), 0.6)
		"step_stone":
			# A heel on cobbles or tarmac: a dull thud and a little click.
			var th := Synth.osc(Synth.SINE, 150.0, 90.0, 0.08, SR)
			Synth.pluck_env(th, SR, 0.001, 45.0)
			Synth.mix_into(out, th, 0, 0.8)
			Synth.mix_into(out, _noise_burst(0.07, 1200.0, 150.0, 55.0, 161), 0, 0.7)
			Synth.mix_into(out, _noise_burst(0.02, 0.0, 2500.0, 150.0, 162), 0, 0.35)
		"step_wood":
			# Boards: a hollow knock with a faint ring.
			var k := Synth.osc(Synth.SINE, 210.0, 170.0, 0.12, SR)
			var h := Synth.osc(Synth.SINE, 430.0, 400.0, 0.12, SR)
			Synth.mix_into(k, h, 0, 0.4)
			Synth.pluck_env(k, SR, 0.001, 30.0)
			Synth.mix_into(out, k, 0, 0.8)
			Synth.mix_into(out, _noise_burst(0.06, 1500.0, 200.0, 60.0, 171), 0, 0.5)
		"step_sand":
			# Sand: a soft shushing give underfoot.
			var sh := Synth.noise(0.14, SR, 181)
			Synth.lowpass(sh, 3000.0, SR)
			Synth.highpass(sh, 500.0, SR)
			Synth.adsr(sh, SR, 0.02, 0.04, 0.5, 0.07)
			Synth.mix_into(out, sh, 0)
		"step_soft":
			# Short grass: a muffled brush.
			var br := Synth.noise(0.11, SR, 191)
			Synth.lowpass(br, 2000.0, SR)
			Synth.highpass(br, 400.0, SR)
			Synth.adsr(br, SR, 0.01, 0.03, 0.4, 0.05)
			Synth.mix_into(out, br, 0)
			var th := Synth.osc(Synth.SINE, 110.0, 80.0, 0.06, SR)
			Synth.pluck_env(th, SR, 0.002, 50.0)
			Synth.mix_into(out, th, 0, 0.3)
		"step_wet":
			# A wet slap: a splat of noise and a small bubble.
			var sp := Synth.noise(0.12, SR, 201)
			Synth.lowpass_sweep(sp, 3500.0, 900.0, SR)
			Synth.highpass(sp, 300.0, SR)
			Synth.adsr(sp, SR, 0.004, 0.04, 0.35, 0.06)
			Synth.mix_into(out, sp, 0)
			var bub := Synth.osc(Synth.SINE, 500.0, 900.0, 0.05, SR)
			Synth.pluck_env(bub, SR, 0.002, 40.0)
			Synth.mix_into(out, bub, _at(0.03), 0.3)
		"bike_tyre":
			# Tyres on the road: a hiss that swells and goes, a little rumble under it.
			var hs := Synth.noise(0.2, SR, 211)
			Synth.lowpass(hs, 5000.0, SR)
			Synth.highpass(hs, 1500.0, SR)
			Synth.adsr(hs, SR, 0.06, 0.04, 0.8, 0.09)
			Synth.mix_into(out, hs, 0)
			var rb := Synth.noise(0.2, SR, 212)
			Synth.lowpass(rb, 200.0, SR)
			Synth.adsr(rb, SR, 0.05, 0.04, 0.8, 0.09)
			Synth.mix_into(out, rb, 0, 1.2)
		"thunder":
			# Close thunder: a sharp crack, then a long rolling rumble that swells twice as it dies away.
			var crack := _noise_burst(0.35, 5000.0, 700.0, 14.0, 301)
			Synth.mix_into(out, crack, 0, 1.0)
			var roll := Synth.noise(5.8, SR, 302)
			Synth.lowpass(roll, 260.0, SR)
			Synth.lowpass(roll, 260.0, SR)
			for i in roll.size():
				var t := float(i) / SR
				roll[i] *= (0.5 * exp(-t * 0.55) + 0.55 * exp(-pow((t - 1.5) / 0.5, 2.0)) + 0.4 * exp(-pow((t - 2.9) / 0.6, 2.0))) * minf(t / 0.05, 1.0)
			Synth.normalise(roll, 0.9)
			Synth.mix_into(out, roll, _at(0.04), 1.0)
			var mid := Synth.noise(3.0, SR, 303)
			Synth.bandpass(mid, 450.0, 1.2, SR)
			Synth.pluck_env(mid, SR, 0.01, 1.3)
			Synth.mix_into(out, mid, _at(0.05), 0.5)
		"thunder_far":
			# Thunder over the next hill: no crack, just a low rumble that comes up slowly and rolls away.
			var far := Synth.noise(6.4, SR, 311)
			Synth.lowpass(far, 150.0, SR)
			Synth.lowpass(far, 150.0, SR)
			for i in far.size():
				var t := float(i) / SR
				far[i] *= (exp(-pow((t - 1.2) / 0.7, 2.0)) + 0.7 * exp(-pow((t - 3.0) / 0.9, 2.0)) + 0.3 * exp(-t * 0.4)) * minf(t / 0.5, 1.0)
			Synth.normalise(far, 0.9)
			Synth.mix_into(out, far, 0, 1.0)
		"text_blip":
			# The tiniest soft tick for each letter of speech: a sine with a little round edge, quieter than the talk blip.
			var tb := _tone(Synth.SINE, 520.0, 560.0, 0.04, 0.004, 0.01, 0.5, 0.02, 1800.0)
			Synth.mix_into(out, tb, 0)
		"talk_blip":
			# A soft rounded blip, rising a touch.
			var bl := _tone(Synth.TRI, 880.0, 990.0, 0.075, 0.006, 0.02, 0.6, 0.04, 2500.0)
			Synth.mix_into(out, bl, 0)
		"sign_creak":
			# An old signboard swinging: a stick-slip creak (a speeding-up train of clicks through a woody resonance).
			var cr := Synth.make(_at(0.45))
			var t := 0.02
			var rate := 45.0
			while t < 0.4:
				cr[_at(t)] = 1.0 - 0.6 * absf(t - 0.2) / 0.2
				t += 1.0 / rate
				rate = minf(rate * 1.035, 140.0)
			Synth.bandpass(cr, 650.0, 7.0, SR)
			var body := cr.duplicate()
			Synth.bandpass(body, 1450.0, 5.0, SR)
			Synth.mix_into(cr, body, 0, 0.5)
			Synth.lowpass(cr, 2500.0, SR)
			Synth.mix_into(out, cr, 0)
		"shop_bell":
			# The little bell on a spring above a shop door: struck, then jingling as it settles.
			for at in [[0.0, 1.0], [0.11, 0.6], [0.2, 0.45], [0.33, 0.25]]:
				Synth.mix_into(out, _bell(2349.3, 0.55, 7.0), _at(at[0]), at[1])
				Synth.mix_into(out, _bell(3135.9, 0.45, 9.0), _at(at[0] + 0.012), at[1] * 0.6)
		"sanctuary_chime":
			# A calm three-note chime.
			var notes := [[1318.5, 0.0], [987.77, 0.16], [1661.2, 0.32]]
			for nt in notes:
				Synth.mix_into(out, _bell(nt[0], 1.05, 3.2), _at(nt[1]), 0.5)
				Synth.mix_into(out, _bell(float(nt[0]) * 0.5, 1.05, 3.0), _at(nt[1]), 0.2)
		"brake_squeal":
			# Steel on steel: a high, slightly wavering squeal over a hiss, sliding down a little as it stops.
			var sq := Synth.osc(Synth.SAW, 2650.0, 2380.0, 1.6, SR, 0.5, 5.5, 25.0, 0.1)
			Synth.lowpass(sq, 4500.0, SR)
			var sq2 := Synth.osc(Synth.SINE, 1320.0, 1190.0, 1.6, SR, 0.5, 4.0, 20.0)
			Synth.mix_into(sq, sq2, 0, 0.5)
			var hs := Synth.noise(1.6, SR, 221)
			Synth.highpass(hs, 2000.0, SR)
			Synth.lowpass(hs, 6000.0, SR)
			Synth.mix_into(sq, hs, 0, 0.25)
			Synth.adsr(sq, SR, 0.25, 0.2, 0.75, 0.5)
			Synth.mix_into(out, sq, 0)
		"radio_tune":
			# A wireless warming up: a whistle swept down to the station, crackle, then a few soft lilting notes under hiss.
			var wh := Synth.osc(Synth.SINE, 2600.0, 780.0, 0.4, SR)
			Synth.adsr(wh, SR, 0.05, 0.1, 0.5, 0.2)
			Synth.mix_into(out, wh, 0, 0.35)
			var cr := Synth.make(_at(0.5))
			var rng := RandomNumberGenerator.new()
			rng.seed = 317
			for i in 22:
				cr[rng.randi_range(0, cr.size() - 1)] = rng.randf_range(-1.0, 1.0)
			Synth.bandpass(cr, 3200.0, 1.2, SR)
			Synth.mix_into(out, cr, _at(0.1), 1.2)
			var tune := Synth.make(_at(2.0))
			for nt in [[349.2, 0.5], [440.0, 0.72], [523.3, 0.94], [587.3, 1.16], [523.3, 1.5], [440.0, 1.68]]:
				var tn := _tone(Synth.TRI, nt[0], nt[0], 0.5, 0.01, 0.1, 0.5, 0.25, 2200.0)
				Synth.mix_into(tune, tn, _at(nt[1]), 0.8)
			Synth.bandpass(tune, 1300.0, 0.7, SR)
			Synth.mix_into(out, tune, 0)
			var hiss := Synth.noise(2.0, SR, 318)
			Synth.highpass(hiss, 2500.0, SR)
			Synth.lowpass(hiss, 6000.0, SR)
			Synth.mix_into(out, hiss, 0, 0.05)
		"atk_thud":
			# A body blow: a whoosh in, then a deep thump with a slap on top.
			var sw := Synth.noise(0.12, SR, 601)
			Synth.bandpass(sw, 900.0, 0.8, SR)
			Synth.adsr(sw, SR, 0.06, 0.02, 0.5, 0.04)
			Synth.mix_into(out, sw, 0, 0.5)
			var t := Synth.osc(Synth.SINE, 180.0, 55.0, 0.24, SR)
			Synth.pluck_env(t, SR, 0.002, 14.0)
			Synth.mix_into(out, t, _at(0.08))
			Synth.mix_into(out, _noise_burst(0.06, 2600.0, 400.0, 55.0, 602), _at(0.08), 0.7)
		"atk_rustle":
			# Leaves thrashed about, a twig snap at the end.
			var n := Synth.noise(0.32, SR, 611)
			Synth.lowpass_sweep(n, 1800.0, 5200.0, SR)
			Synth.highpass(n, 700.0, SR)
			Synth.adsr(n, SR, 0.03, 0.08, 0.6, 0.12)
			Synth.mix_into(out, n, 0, 0.8)
			for k in 3:
				Synth.mix_into(out, _noise_burst(0.03, 0.0, 2200.0, 90.0, 612 + k), _at(0.06 + 0.07 * k), 0.4)
			var snap := Synth.osc(Synth.TRI, 1900.0, 900.0, 0.05, SR)
			Synth.pluck_env(snap, SR, 0.0005, 70.0)
			Synth.mix_into(out, snap, _at(0.3), 0.5)
		"atk_splash":
			# A rising bloop and a slap of water.
			for k in 3:
				var b := Synth.osc(Synth.SINE, 260.0 + 90.0 * k, 700.0 + 160.0 * k, 0.09, SR)
				Synth.pluck_env(b, SR, 0.004, 22.0)
				Synth.mix_into(out, b, _at(0.05 * k), 0.45)
			var w := Synth.noise(0.32, SR, 621)
			Synth.lowpass_sweep(w, 5000.0, 900.0, SR)
			Synth.highpass(w, 200.0, SR)
			Synth.adsr(w, SR, 0.005, 0.1, 0.3, 0.18)
			Synth.mix_into(out, w, _at(0.12), 0.9)
		"atk_crackle":
			# A whoomph of flame and a spit of embers.
			var f := Synth.noise(0.4, SR, 631)
			Synth.lowpass_sweep(f, 400.0, 2400.0, SR)
			Synth.adsr(f, SR, 0.04, 0.12, 0.55, 0.2)
			Synth.mix_into(out, f, 0, 1.0)
			var lo := Synth.osc(Synth.SINE, 90.0, 140.0, 0.3, SR)
			Synth.adsr(lo, SR, 0.03, 0.1, 0.5, 0.15)
			Synth.mix_into(out, lo, 0, 0.5)
			var rng := RandomNumberGenerator.new()
			rng.seed = 632
			for k in 9:
				Synth.mix_into(out, _noise_burst(0.012, 0.0, 2500.0, 250.0, 633 + k), _at(rng.randf_range(0.05, 0.42)), rng.randf_range(0.3, 0.7))
		"atk_whoosh":
			# Wind: a band of noise swept up and back down.
			var w := Synth.noise(0.42, SR, 641)
			var fcs := PackedFloat32Array()
			fcs.resize(w.size())
			for i in w.size():
				fcs[i] = 500.0 + 2600.0 * sin(PI * float(i) / w.size())
			Synth.bandpass(w, 900.0, 2.0, SR, fcs)
			Synth.adsr(w, SR, 0.12, 0.1, 0.7, 0.18)
			Synth.mix_into(out, w, 0, 1.0)
		"atk_zap":
			# A buzzing arc and a crack.
			var z := Synth.osc(Synth.SQUARE, 1400.0, 260.0, 0.3, SR, 0.3, 45.0, 300.0)
			Synth.lowpass(z, 4200.0, SR)
			Synth.adsr(z, SR, 0.002, 0.08, 0.5, 0.15)
			Synth.mix_into(out, z, 0, 0.5)
			Synth.mix_into(out, _noise_burst(0.08, 0.0, 1500.0, 40.0, 651), 0, 0.9)
			Synth.mix_into(out, _noise_burst(0.05, 0.0, 800.0, 60.0, 652), _at(0.14), 0.6)
		"atk_ice":
			# Glassy tinkles over a cold hiss.
			var h := Synth.noise(0.45, SR, 661)
			Synth.highpass(h, 4000.0, SR)
			Synth.adsr(h, SR, 0.02, 0.1, 0.4, 0.25)
			Synth.mix_into(out, h, 0, 0.35)
			var notes := [2637.0, 3136.0, 3520.0, 2349.0, 3951.0]
			for k in 5:
				Synth.mix_into(out, _bell(float(notes[k]), 0.3, 14.0), _at(0.05 * k), 0.4)
		"atk_crunch":
			# Rock on rock: a low knock and a gravelly crunch.
			var t := Synth.osc(Synth.TRI, 120.0, 45.0, 0.3, SR)
			Synth.pluck_env(t, SR, 0.002, 12.0)
			Synth.mix_into(out, t, 0, 0.9)
			var rng := RandomNumberGenerator.new()
			rng.seed = 671
			for k in 14:
				Synth.mix_into(out, _noise_burst(0.02, 3000.0, 300.0, 140.0, 672 + k), _at(0.02 + rng.randf_range(0.0, 0.22)), rng.randf_range(0.3, 0.8))
		"atk_squelch":
			# A wet blorp, pitch falling, with a sucking tail.
			var b := Synth.osc(Synth.SINE, 340.0, 85.0, 0.3, SR, 0.5, 14.0, 120.0)
			Synth.adsr(b, SR, 0.01, 0.1, 0.5, 0.15)
			Synth.mix_into(out, b, 0, 0.9)
			var w := Synth.noise(0.3, SR, 681)
			Synth.lowpass_sweep(w, 600.0, 1600.0, SR)
			Synth.adsr(w, SR, 0.05, 0.1, 0.4, 0.12)
			Synth.mix_into(out, w, _at(0.1), 0.6)
		"atk_clang":
			# Metal struck: inharmonic partials, a hard edge.
			for pair in [[523.0, 1.0], [1187.0, 0.6], [1873.0, 0.4], [2741.0, 0.25]]:
				var p := Synth.osc(Synth.SINE, pair[0], pair[0] * 0.995, 0.55, SR)
				Synth.pluck_env(p, SR, 0.001, 6.0)
				Synth.mix_into(out, p, 0, pair[1] * 0.5)
			Synth.mix_into(out, _noise_burst(0.03, 0.0, 2000.0, 120.0, 691), 0, 0.7)
		"atk_shimmer":
			# Fairy glints running up, a soft swell under them.
			var sw := Synth.osc(Synth.SINE, 660.0, 1320.0, 0.5, SR, 0.5, 7.0, 30.0)
			Synth.adsr(sw, SR, 0.1, 0.1, 0.6, 0.25)
			Synth.mix_into(out, sw, 0, 0.35)
			var notes := [1318.5, 1568.0, 1975.5, 2349.3, 2637.0, 3136.0]
			for k in 6:
				Synth.mix_into(out, _bell(float(notes[k]), 0.3, 10.0), _at(0.045 * k), 0.35)
		"atk_wail":
			# Two detuned sines sliding down, echoing.
			var a := Synth.osc(Synth.SINE, 820.0, 380.0, 0.45, SR, 0.5, 5.0, 40.0)
			var b := Synth.osc(Synth.SINE, 835.0, 372.0, 0.45, SR, 0.5, 5.5, 40.0)
			Synth.mix_into(a, b, 0, 0.8)
			Synth.adsr(a, SR, 0.08, 0.1, 0.6, 0.2)
			Synth.mix_into(out, a, 0, 0.7)
			Synth.mix_into(out, a, _at(0.14), 0.3)
			var h := Synth.noise(0.4, SR, 701)
			Synth.bandpass(h, 1200.0, 3.0, SR)
			Synth.adsr(h, SR, 0.1, 0.1, 0.5, 0.2)
			Synth.mix_into(out, h, 0, 0.3)
		"encounter":
			# Something in the grass: a fiddle stab, a quick run down, and a held question on the fifth.
			for f in [293.66, 440.0, 587.33]:
				var st := Synth.osc(Synth.SAW, f, f, 0.16, SR, 0.5, 6.0, 10.0)
				Synth.lowpass(st, 2800.0, SR)
				Synth.adsr(st, SR, 0.005, 0.05, 0.6, 0.06)
				Synth.mix_into(out, st, 0, 0.35)
			var run := [880.0, 784.0, 698.5, 659.3, 587.3]
			for k in 5:
				var t := _tone(Synth.SQUARE, float(run[k]), float(run[k]), 0.08, 0.003, 0.02, 0.6, 0.03, 3200.0, 0.3)
				Synth.mix_into(out, t, _at(0.18 + 0.055 * k), 0.4)
			for f in [440.0, 659.25]:
				var held := Synth.osc(Synth.SAW, f, f, 0.6, SR, 0.5, 5.5, 14.0, 0.1)
				Synth.lowpass(held, 2400.0, SR)
				Synth.adsr(held, SR, 0.02, 0.15, 0.7, 0.3)
				Synth.mix_into(out, held, _at(0.46), 0.3)
			var thump := Synth.osc(Synth.SINE, 110.0, 50.0, 0.3, SR)
			Synth.pluck_env(thump, SR, 0.002, 12.0)
			Synth.mix_into(out, thump, 0, 0.7)
			Synth.mix_into(out, thump, _at(0.46), 0.5)
		"stat_up":
			for k in 3:
				var f := 523.25 * pow(2.0, [0, 4, 7][k] / 12.0)
				var t := _tone(Synth.TRI, f, f * 1.03, 0.14, 0.004, 0.04, 0.6, 0.06, 4000.0)
				Synth.mix_into(out, t, _at(0.08 * k), 0.6)
			Synth.mix_into(out, _bell(1568.0, 0.25, 10.0), _at(0.2), 0.3)
		"stat_down":
			for k in 3:
				var f := 659.25 * pow(2.0, [0, -4, -8][k] / 12.0)
				var t := _tone(Synth.TRI, f, f * 0.97, 0.14, 0.004, 0.04, 0.6, 0.06, 2600.0)
				Synth.mix_into(out, t, _at(0.08 * k), 0.6)
		"weather_call":
			# The sky answering: a wind swell, a distant rumble, a bright crack at the top.
			var w := Synth.noise(1.2, SR, 711)
			Synth.lowpass_sweep(w, 300.0, 3000.0, SR)
			Synth.adsr(w, SR, 0.5, 0.2, 0.5, 0.45)
			Synth.mix_into(out, w, 0, 0.8)
			var r := Synth.noise(1.0, SR, 712)
			Synth.lowpass(r, 160.0, SR)
			Synth.adsr(r, SR, 0.2, 0.3, 0.6, 0.4)
			Synth.mix_into(out, r, _at(0.25), 2.2)
			Synth.mix_into(out, _noise_burst(0.12, 0.0, 1200.0, 30.0, 713), _at(0.45), 0.6)
			for f in [587.33, 880.0, 1174.66]:
				Synth.mix_into(out, _bell(f, 0.7, 4.0), _at(0.45), 0.25)
		_:
			push_error("unknown sfx " + id)
	Synth.fade_out(out, SR, 0.008)
	Synth.fade_in(out, SR, 0.001)
	Synth.remove_dc(out)
	Synth.normalise(out, PEAKS[id])
	Synth.fade_out(out, SR, 0.004)
	return out
