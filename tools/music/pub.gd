extends RefCounted
## The pub: an original border jig in A mixolydian. Fiddle, then whistle, over guitar and a bodhran, a little slower than the session.

const A := "1:2 2:1 3:2 5:1 | 6:2 5:1 3:3 | 1:2 2:1 3:2 5:1 | 6:2 7:1 5:3 | 1':2 7:1 6:2 5:1 | 3:2 5:1 6:3 | 5:2 3:1 2:2 1:1 | 1:5 r:1"
const B := "6:2 6:1 1':2 6:1 | 5:3 3:3 | 6:2 6:1 1':2 3':1 | 2':3 1':3 | 6:2 6:1 1':2 6:1 | 5:2 3:1 5:3 | 6:2 5:1 3:2 2:1 | 1:5 r:1"
const CA := [1, 1, 1, 4, 1, 1, 5, 1]
const CB := [6, 1, 6, 5, 6, 1, 4, 1]

static func build() -> Composer:
	var c := Composer.new()
	c.tonic = 57
	c.mode = Composer.MODES["mixolydian"]
	c.unit = 0.21
	c.upb = 6
	c.seam_fade = 0.012
	c.bars = 32
	for r in 2:
		var b := r * 16
		var inst := "fiddle" if r == 0 else "whistle"
		c.lead(inst, A, b, 8, 0.75)
		c.lead(inst, B, b + 8, 8, 0.75)
		c.strum("guitar", CA, b, "X.xX.x", 0.4)
		c.strum("guitar", CB, b + 8, "X.xX.x", 0.4)
		c.bass(CA, b, "x..o..", 0.55)
		c.bass(CB, b + 8, "x..o..", 0.55)
		c.drums("b.dbd.", b, 16, 0.5)
	return c
