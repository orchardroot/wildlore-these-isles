extends RefCounted
## A castle: a steady, weathered march in D dorian. Pipe over a drone with a slow drum, and a harp for the cold stone.

const A := "1:4 1:2 2:2 | 3:4 5:4 | 4:4 3:2 2:2 | 1:8 | 5:4 5:2 6:2 | 7:4 1':4 | 7:4 6:2 5:2 | 1:8"
const B := "3':4 2':2 1':2 | 7:4 5:4 | 6:4 5:2 4:2 | 3:8 | 4:4 5:2 6:2 | 7:4 6:4 | 5:4 4:2 3:2 | 1:8"
const CA := [1, 1, 4, 1, 5, 1, 5, 1]
const CB := [1, 5, 4, 3, 4, 5, 5, 1]

static func build() -> Composer:
	var c := Composer.new()
	c.tonic = 50
	c.mode = Composer.MODES["dorian"]
	c.unit = 0.23
	c.upb = 8
	c.seam_fade = 0.012
	c.bars = 32
	for r in 2:
		var b := r * 16
		c.lead("pipe" if r == 0 else "brass", A, b, 8, 0.7)
		c.lead("pipe" if r == 0 else "brass", B, b + 8, 8, 0.7)
		c.arp("harp", CA, b, "0.1.2.1.", 0.3)
		c.arp("harp", CB, b + 8, "0.1.2.1.", 0.3)
		c.drone(b, 16, 0.5)
		c.drums("X...x...", b, 16, 0.6)
	return c
