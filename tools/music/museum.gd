extends RefCounted
## A museum: a hushed waltz in C ionian. Pan pipes over a rippling harp, a soft bell on the first beat of every other bar.

const A := "3:3 5:3 | 1':3 7:2 6:1 | 5:3 3:3 | 2:6 | 3:3 5:3 | 6:3 1':3 | 5:2 4:1 3:2 2:1 | 1:6"
const B := "6:3 1':3 | 3':3 2':2 1':1 | 7:3 5:3 | 1':6 | 4:3 6:3 | 2':3 1':3 | 7:2 6:1 5:2 4:1 | 1:6"
const CA := [1, 4, 1, 5, 1, 6, 5, 1]
const CB := [6, 3, 5, 1, 4, 2, 5, 1]
const BELL := "1':2 r:4 | r:6 | 5:2 r:4 | r:6 | 1':2 r:4 | r:6 | 5:2 r:4 | r:6"

static func build() -> Composer:
	var c := Composer.new()
	c.tonic = 60
	c.mode = Composer.MODES["ionian"]
	c.unit = 0.27
	c.upb = 6
	c.seam_fade = 0.012
	c.bars = 16
	c.lead("pan", A, 0, 8, 0.55)
	c.lead("pan", B, 8, 8, 0.55)
	c.arp("harp", CA, 0, "012321", 0.35)
	c.arp("harp", CB, 8, "012321", 0.35)
	c.lead("bell", BELL, 0, 8, 0.35, -12)
	c.lead("bell", BELL, 8, 8, 0.35, -12)
	c.bass(CA, 0, "x.....", 0.35)
	c.bass(CB, 8, "x.....", 0.35)
	return c
