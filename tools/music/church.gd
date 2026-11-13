extends RefCounted
## A church: a slow, hymn-like tune in D ionian. Choir and a soft bell over a low drone, the harp barely there.

const A := "1:4 3:4 | 5:6 4:2 | 3:4 2:4 | 1:8 | 6,:4 1:4 | 2:6 3:2 | 4:4 2:4 | 1:8"
const B := "5:4 1':4 | 3':6 2':2 | 1':4 7:4 | 6:8 | 4:4 6:4 | 5:6 4:2 | 3:4 2:4 | 1:8"
const CA := [1, 1, 5, 1, 6, 5, 4, 1]
const CB := [1, 3, 1, 6, 4, 1, 5, 1]
const BELLS := "1':2 r:14 | 5:2 r:14 | 4:2 r:14 | 1:2 r:14"

static func build() -> Composer:
	var c := Composer.new()
	c.tonic = 50
	c.mode = Composer.MODES["ionian"]
	c.unit = 0.36
	c.upb = 8
	c.seam_fade = 0.012
	c.bars = 16
	c.lead("choir", A, 0, 8, 0.7)
	c.lead("choir", B, 8, 8, 0.7)
	c.pad("choir", CA, 0, 0.16, -12)
	c.pad("choir", CB, 8, 0.16, -12)
	c.arp("harp", CA, 0, "0..1..2.", 0.25)
	c.arp("harp", CB, 8, "0..1..2.", 0.25)
	c.lead("bell", BELLS, 0, 8, 0.5, -12)
	c.lead("bell", BELLS, 8, 8, 0.5, -12)
	c.drone(0, 16, 0.3)
	return c
