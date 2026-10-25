extends RefCounted
## Character renderer: recipe -> 96x192 walk sheet (3 columns x 4 rows of 32x48).
## Rows: down, left, right, up. Columns: step-left, stand, step-right. Right row is the left row mirrored.
##
## Recipe: {"id", "build": "child"|"adult"|"elder",
##   "palette": {skin, hair, top, bottom, shoes, accent, accent2},
##   "hair": short|long|bob|bun|pony|curly|spiky|bald|side, "hat": none|cap|beanie|swimcap|sunhat|bucket|headband,
##   "bottom_style": trousers|shorts|skirt, "sleeves": long|short,
##   "accessories": [labcoat, glasses, hoodie, gilet, scarf, backpack, cape, apron, phone, binoculars, rod, badge,
##     aran, oilskin, overalls, shawl, lanyard, pin, beard, moustache, grin, glitter, wellies,
##     lantern, hurley, umbrella, fiddle, notebook, waxed_jacket, bagpipes, curling_broom, shinty_stick, clipboard]}
## bottom_style also: kilt. Hats also: welding_visor, bobble_hat, deerstalker.
## Extra hats: witch_hat, panama, hard_hat, flat_cap, helmet, flower_crown, holly_crown, headscarf, turban. Extra hair: windswept.
## Added in plan 6: hats top_hat, tudor_bonnet; accessories hi_vis (vest, accent + accent2 stripes), staff (prop colour).
## Optional palette keys: hat, beard, prop, pin, light (lamp / lantern glow), leaf.
## 4.6 (the player's look, core/looks.gd): hair also afro, braids, locs, undercut, mohawk, buzz. The vocabulary
## below (HAIRS, HATS, BOTTOMS, SLEEVES, ACCESSORIES) is what Looks.valid_delta checks wear items against.

const HAIRS := ["short", "long", "bob", "bun", "pony", "curly", "spiky", "bald", "side", "windswept",
	"afro", "braids", "locs", "undercut", "mohawk", "buzz"]
const HATS := ["none", "cap", "beanie", "swimcap", "sunhat", "bucket", "headband", "welding_visor", "bobble_hat", "deerstalker",
	"witch_hat", "panama", "hard_hat", "flat_cap", "helmet", "flower_crown", "holly_crown", "headscarf", "turban", "top_hat", "tudor_bonnet",
	"sou_wester", "tam", "boater"]
const BOTTOMS := ["trousers", "shorts", "skirt", "kilt"]
const SLEEVES := ["long", "short"]
const ACCESSORIES := ["labcoat", "glasses", "hoodie", "gilet", "scarf", "backpack", "cape", "apron", "phone", "binoculars", "rod", "badge",
	"aran", "oilskin", "overalls", "shawl", "lanyard", "pin", "beard", "moustache", "grin", "glitter", "wellies",
	"lantern", "hurley", "umbrella", "fiddle", "notebook", "waxed_jacket", "bagpipes", "curling_broom", "shinty_stick", "clipboard",
	"hi_vis", "staff", "lamp_pole", "telescope", "tweed_jacket", "smock"]
const VOCAB := {"hair": HAIRS, "hat": HATS, "bottom_style": BOTTOMS, "sleeves": SLEEVES}

const Canvas = preload("res://tools/spritegen/canvas.gd")

const FEET_Y := 45
const SKIN := {"lo": -0.35, "hi": 0.72}
const DIRS := ["down", "left", "right", "up"]
const BUILDS := {
	"child": {"head": [17, 16], "torso": [12, 11], "leg_len": 8, "leg_w": 4, "arm_len": 9, "arm_w": 3, "eye_h": 3},
	"adult": {"head": [15, 14], "torso": [14, 17], "leg_len": 10, "leg_w": 5, "arm_len": 13, "arm_w": 4, "eye_h": 2},
	"elder": {"head": [15, 13], "torso": [15, 16], "leg_len": 9, "leg_w": 5, "arm_len": 12, "arm_w": 4, "eye_h": 2},
}

static func render(recipe: Dictionary) -> Image:
	var out := Image.create(96, 192, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for row in 4:
		var dir: String = DIRS[row]
		for col in 3:
			var step := col - 1
			var cv = _frame("left" if dir == "right" else dir, step, recipe)
			var img: Image = cv.img
			if dir == "right":
				img.flip_x()
			out.blit_rect(img, Rect2i(0, 0, 32, 48), Vector2i(col * 32, row * 48))
	return out

# ---------- helpers ----------

static func _ctx(r: Dictionary, dir: String, step: int) -> Dictionary:
	var b: Dictionary = BUILDS[str(r.get("build", "adult"))]
	var c := {"r": r, "b": b, "dir": dir, "step": step}
	c["bob"] = -1 if step != 0 else 0
	c["hip"] = FEET_Y - int(b.leg_len)
	c["th"] = float(b.torso[1])
	c["tw"] = float(b.torso[0]) - (3.0 if dir == "left" else 0.0)
	c["ttop"] = float(c.hip) + 1.0 - c.th
	c["tcy"] = c.ttop + c.th * 0.5
	c["hw"] = float(b.head[0])
	c["hh"] = float(b.head[1])
	c["hcy"] = c.ttop + 1.0 - c.hh * 0.5
	c["hcx"] = 15.0 if dir == "left" else 16.0
	c["acc"] = r.get("accessories", [])
	c["pal"] = r.get("palette", {})
	return c

static func _col(c: Dictionary, key: String) -> Color:
	var p: Dictionary = c.pal
	var def := {"skin": "#f0c8a0", "hair": "#4a3426", "top": "#5a7ab8", "bottom": "#4a4a5a", "shoes": "#3a2a24", "accent": "#e8e0d0", "accent2": "#8a6a40", "glasses": "#5a4a58"}
	return Canvas.parse_colour(p.get(key, def.get(key, "#ff00ff")))

static func _tn(c: Dictionary, key: String, dark := 0.0) -> Array:
	return Canvas.tones_from("#" + _col(c, key).to_html(false), dark)

static func _has(c: Dictionary, a: String) -> bool:
	return a in c.acc

static func _ell(cv, x: float, y: float, w: float, h: float, tn: Array, shade := true, rim := false, angle := 0.0, extra := {}) -> void:
	var opt := {"shade": shade, "rim": rim}
	opt.merge(extra)
	cv.paint(cv.ellipse_mask(x, y, w, h, angle), tn, opt)

static func _rect(cv, x: float, y: float, w: float, h: float, tn: Array, rnd := 0.0, shade := true, rim := false, angle := 0.0, extra := {}) -> void:
	var opt := {"shade": shade, "rim": rim}
	opt.merge(extra)
	cv.paint(cv.rect_mask(x, y, w, h, angle, rnd), tn, opt)

static func _poly(cv, pts: Array, tn: Array, shade := true, rim := false) -> void:
	cv.paint(cv.poly_mask(pts), tn, {"shade": shade, "rim": rim})

static func _limb(cv, x0: float, y0: float, x1: float, y1: float, w: float, tn: Array, rim := false) -> void:
	var dx := x1 - x0
	var dy := y1 - y0
	var l := sqrt(dx * dx + dy * dy)
	var ang := -rad_to_deg(atan2(dx, dy))
	_rect(cv, (x0 + x1) * 0.5, (y0 + y1) * 0.5, w, l, tn, minf(w * 0.4, 2.0), true, rim, ang)

# ---------- frame ----------

static func _frame(dir: String, step: int, r: Dictionary):
	var cv = Canvas.new(32, 48)
	var c := _ctx(r, dir, step)
	_behind(cv, c)
	_legs(cv, c)
	_torso(cv, c)
	_head(cv, c)
	cv.outline()
	return cv

# Things that sit behind the body.
static func _behind(cv, c: Dictionary) -> void:
	var dir: String = c.dir
	var bob: int = c.bob
	var ttop: float = c.ttop
	var th: float = c.th
	var tw: float = c.tw
	var hcy: float = c.hcy
	var hw: float = c.hw
	var hh: float = c.hh
	if _has(c, "backpack") and dir == "left":
		_rect(cv, 16 + tw * 0.5 + 1.5, c.tcy + bob + 1, 6, th - 3, _tn(c, "accent2"), 2, true, true)
	if _has(c, "cape") and dir != "up":
		var capetn := _tn(c, "accent")
		_rect(cv, 16 + (tw * 0.5 + 0.5 if dir == "left" else 0), c.tcy + bob + 3, tw + (0 if dir == "left" else 4), th + 4, capetn, 2, true, false, 0.0, {"pattern": "stripes", "pcol": _tn(c, "accent2"), "period": 4, "angle": 0})
	if _hair_style(c) in ["long"] and dir != "up":
		var hs := _tn(c, "hair")
		if dir == "down":
			_rect(cv, 16, hcy + hh * 0.2 + bob, hw + 1, hh * 0.9 + 6, hs, 3, true)
		else:
			_rect(cv, c.hcx + hw * 0.3, hcy + hh * 0.2 + bob, hw * 0.5, hh * 0.9 + 6, hs, 3, true)
	if _hair_style(c) == "windswept" and dir != "up":
		var wh := _tn(c, "hair")
		if dir == "down":
			_rect(cv, 17.5, hcy + hh * 0.2 + bob, hw + 2, hh * 0.9 + 6, wh, 3, true, false, -6.0)
			_ell(cv, 16.0 - hw * 0.5 - 1, hcy + hh * 0.5 + bob + 3, 4, 9, wh, true, false, 12.0)
		else:
			_ell(cv, c.hcx + hw * 0.5 + 3, hcy + 1 + bob, 11, 5, wh, true, false, -25.0)
			_ell(cv, c.hcx + hw * 0.5 + 4, hcy + 5 + bob, 10, 4, _tn(c, "hair", 0.12), true, false, -10.0)
			_ell(cv, c.hcx + hw * 0.5 + 2, hcy - 3 + bob, 8, 4, wh, true, false, -40.0)
	if _hair_style(c) == "pony" and dir == "left":
		_ell(cv, c.hcx + hw * 0.5 + 1, hcy + 3 + bob, 4, 10, _tn(c, "hair"), true, false, -20.0)
	if _hair_style(c) == "bun" and dir != "up":
		pass
	if _has(c, "rod"):
		var rc := _col(c, "accent2")
		var ox := 0.0
		var hx := 16.0 + (tw * 0.5 + 2.0 if dir != "left" else -1.0)
		var hy: float = c.ttop + 2 + float(c.b.arm_len) + bob
		if dir == "down":
			hx = 16.0 - (tw * 0.5 + 2.0)
		cv.paint(cv.line_mask([Vector2(hx, hy), Vector2(hx + (-8 if dir == "left" else 6), 9)], 1.2), Canvas.tones(rc), {"shade": false})
		if dir == "left":
			cv.paint(cv.line_mask([Vector2(hx - 8, 9), Vector2(hx - 10, 24)], 1.0), Canvas.tones(Color("#e8e8f0")), {"shade": false})

static func _hair_style(c: Dictionary) -> String:
	return str(c.r.get("hair", "short"))

static func _legs(cv, c: Dictionary) -> void:
	var dir: String = c.dir
	var step: int = c.step
	var b: Dictionary = c.b
	var lw := float(b.leg_w)
	var hip: float = c.hip
	var style := str(c.r.get("bottom_style", "trousers"))
	var legkey := "bottom" if style == "trousers" else ("accent2" if style == "kilt" else "skin")
	var shoes := _tn(c, "shoes")
	if dir == "down" or dir == "up":
		for side in [-1, 1]:
			var x: float = 16.0 + side * (lw * 0.5 + 0.5)
			var lift := 2 if (step != 0 and side == step) else 0
			var foot := FEET_Y - lift
			var ln := float(foot) - hip + 1.0
			_rect(cv, x, hip + ln * 0.5 - 0.5, lw, ln, _tn(c, legkey), 1.5, true)
			_ell(cv, x, float(foot) - 0.5, lw + 1.5, 4.0 if dir == "down" else 3.0, shoes, true)
	else:
		var sw := 3.0 * float(step)
		for k in [1, 0]:
			var dx := -sw if k == 1 else sw
			var dark := 0.22 if k == 1 else 0.0
			var foot := float(FEET_Y)
			_limb(cv, 16.0, hip - 0.5, 16.0 + dx, foot - 1.0, lw, _tn(c, legkey, dark))
			_ell(cv, 16.0 + dx - 1.0, foot - 0.5, lw + 3.0, 4.0, _tn(c, "shoes", dark), true)
	if _has(c, "wellies"):
		var wt := _tn(c, "shoes")
		if dir == "down" or dir == "up":
			for side in [-1, 1]:
				var lift2 := 2 if (step != 0 and side == step) else 0
				_rect(cv, 16.0 + side * (lw * 0.5 + 0.5), float(FEET_Y - lift2) - 3.5, lw + 0.5, 7, wt, 1.5, true, true)
		else:
			var sw2 := 3.0 * float(step)
			for k in [1, 0]:
				var dx2 := -sw2 if k == 1 else sw2
				_limb(cv, 16.0 + dx2 * 0.8, float(FEET_Y) - 7.0, 16.0 + dx2, float(FEET_Y) - 1.0, lw + 0.5, _tn(c, "shoes", 0.22 if k == 1 else 0.0), true)
	if style == "shorts":
		_rect(cv, 16, hip + 2.5, lw * 2.0 + 3.0 if dir != "left" else lw + 2.0, 6, _tn(c, "bottom"), 2, true)
	elif style == "skirt":
		var tw: float = c.tw
		var y0: float = hip - 4.0
		var wide := tw * 0.5 + 3.0
		_poly(cv, [Vector2(16 - tw * 0.5, y0), Vector2(16 + tw * 0.5, y0), Vector2(16 + wide, hip + 6), Vector2(16 - wide, hip + 6)], _tn(c, "bottom"), true)
	elif style == "kilt":
		_kilt(cv, c, hip)

static func _kilt(cv, c: Dictionary, hip: float) -> void:
	var tw: float = c.tw
	var wide := tw * 0.5 + 2.5
	cv.paint(cv.poly_mask([Vector2(16 - tw * 0.5, hip - 4.0), Vector2(16 + tw * 0.5, hip - 4.0), Vector2(16 + wide, hip + 5), Vector2(16 - wide, hip + 5)]), _tn(c, "bottom"), {"shade": true, "rim": false, "pattern": "stripes", "pcol": _tn(c, "accent"), "period": 3, "angle": 0})
	_rect(cv, 16, hip - 3.0, tw, 2, _tn(c, "shoes"), 0, false)
	if c.dir == "down":
		_rect(cv, 16, hip - 3.0, 2, 2, Canvas.tones(Color("#c8c0a8")), 0, false)

static func _torso(cv, c: Dictionary) -> void:
	var dir: String = c.dir
	var step: int = c.step
	var b: Dictionary = c.b
	var bob: int = c.bob
	var tw: float = c.tw
	var th: float = c.th
	var ttop: float = c.ttop
	var tcy: float = c.tcy + bob
	var top := _tn(c, "top")
	var aw := float(b.arm_w)
	var alen := float(b.arm_len)
	var sleeves := str(c.r.get("sleeves", "long"))
	var topkey := "top"
	# arms behind torso in the side view (far arm)
	if dir == "left":
		var sx := 16.0
		var sy: float = ttop + 3 + bob
		var sw := -3.0 * float(step)
		_limb(cv, sx, sy, sx - sw * 0.8, sy + alen - 1, aw, _tn(c, "top", 0.22), false)
		_ell(cv, sx - sw * 0.8, sy + alen - 0.5, aw, aw - 0.5, _tn(c, "skin", 0.2), true)
	_rect(cv, 16.0 + (0.0 if dir != "left" else 0.5), tcy, tw, th, top, 3, true, false)
	if _has(c, "aran"):
		_rect(cv, 16.0 + (0.0 if dir != "left" else 0.5), tcy, tw, th, top, 3, true, false, 0.0, _aran_extra(c))
		_rect(cv, 16.0 + (0.0 if dir != "left" else 0.5), tcy + th * 0.5 - 1.0, tw, 2, _tn(c, "top", 0.2), 1, true, false)
	if _has(c, "hoodie"):
		_ell(cv, c.hcx + (1.0 if dir == "left" else 0.0), ttop + 1 + bob, tw - 1 if dir != "left" else tw, 6, _tn(c, "top", 0.1), true, true)
		if dir == "down":
			_rect(cv, 16, tcy + 4, tw - 4, 4, _tn(c, "top", 0.15), 1.5, true, true)
			cv.px(14, int(ttop + 5 + bob), _col(c, "accent"))
			cv.px(18, int(ttop + 5 + bob), _col(c, "accent"))
			cv.px(14, int(ttop + 6 + bob), _col(c, "accent"))
			cv.px(18, int(ttop + 6 + bob), _col(c, "accent"))
	if _has(c, "labcoat"):
		var coat := _tn(c, "accent")
		var cy2: float = tcy + 2.5
		_rect(cv, 16.0 + (0.5 if dir == "left" else 0.0), cy2, tw + 2.0, th + 5.0, coat, 3, true, true)
		if dir == "down":
			_rect(cv, 16, cy2 + 1, 1, th + 3, _tn(c, "accent", 0.35), 0, false)
			_poly(cv, [Vector2(16, ttop + 1 + bob), Vector2(12, ttop + 1 + bob), Vector2(16, ttop + 7 + bob)], _tn(c, "top"), false)
			_poly(cv, [Vector2(16, ttop + 1 + bob), Vector2(20, ttop + 1 + bob), Vector2(16, ttop + 7 + bob)], _tn(c, "top"), false)
			_rect(cv, 12, tcy + 7, 4, 3, _tn(c, "accent", 0.18), 0, false)
			_rect(cv, 20, tcy + 7, 4, 3, _tn(c, "accent", 0.18), 0, false)
	if _has(c, "apron") and dir != "up":
		var ap := _tn(c, "accent")
		var aw2: float = tw - 3.0 if dir == "down" else 5.0
		_rect(cv, 16.0 + (-3.0 if dir == "left" else 0.0), tcy + 4.0, aw2, th * 0.7 + 4.0, ap, 2, true, false)
		if dir == "down":
			_rect(cv, 16 - aw2 * 0.5 + 1, ttop + 3 + bob, 1, 4, _tn(c, "accent", 0.2), 0, false)
			_rect(cv, 16 + aw2 * 0.5 - 1, ttop + 3 + bob, 1, 4, _tn(c, "accent", 0.2), 0, false)
	if _has(c, "gilet"):
		var gl := _tn(c, "accent")
		if dir == "down":
			_rect(cv, 16 - tw * 0.25 - 0.5, tcy + 1, tw * 0.5 - 1.5, th - 3, gl, 2, true, true)
			_rect(cv, 16 + tw * 0.25 + 0.5, tcy + 1, tw * 0.5 - 1.5, th - 3, gl, 2, true, true)
		elif dir == "up":
			_rect(cv, 16, tcy + 1, tw - 1, th - 3, gl, 2, true, true)
		else:
			_rect(cv, 16.5, tcy + 1, tw - 1, th - 3, gl, 2, true, true)
	if _has(c, "overalls"):
		var ov := _tn(c, "bottom")
		if dir == "down":
			_rect(cv, 16, tcy + 3.5, tw - 6, th * 0.55, ov, 1, true, true)
			_rect(cv, 16 - tw * 0.5 + 3.5, ttop + 3 + bob, 2, 6, ov, 0, false)
			_rect(cv, 16 + tw * 0.5 - 3.5, ttop + 3 + bob, 2, 6, ov, 0, false)
			_rect(cv, 16, tcy + 5, 4, 3, _tn(c, "bottom", 0.25), 0, false)
			cv.px(int(16 - tw * 0.5 + 3), int(ttop + 8 + bob), Color("#e8c040"))
			cv.px(int(16 + tw * 0.5 - 4), int(ttop + 8 + bob), Color("#e8c040"))
		elif dir == "up":
			_rect(cv, 16, tcy + 3, tw - 1, th * 0.6, ov, 1, true, true)
		else:
			_rect(cv, 16.5, tcy + 3.5, tw - 2, th * 0.55, ov, 1, true, true)
	if _has(c, "oilskin"):
		var oil := _tn(c, "accent")
		var oy: float = tcy + 2.5
		if dir == "down":
			_rect(cv, 16 - tw * 0.25 - 1.0, oy, tw * 0.5 - 2.0, th + 4.0, oil, 2, true, true)
			_rect(cv, 16 + tw * 0.25 + 1.0, oy, tw * 0.5 - 2.0, th + 4.0, oil, 2, true, true)
		else:
			_rect(cv, 16.0 + (0.5 if dir == "left" else 0.0), oy, tw + 2.0, th + 5.0, oil, 3, true, true)
		_ell(cv, c.hcx + (1.0 if dir == "left" else 0.0), ttop + 1.5 + bob, tw if dir != "left" else tw + 1, 5, _tn(c, "accent", -0.1), true, true)
		if dir == "down":
			for k in range(3):
				cv.px(14, int(ttop + 7 + bob + k * 4), _col(c, "accent2"))
				cv.px(18, int(ttop + 7 + bob + k * 4), _col(c, "accent2"))
	if _has(c, "waxed_jacket"):
		var wax := _tn(c, "accent")
		var wy: float = tcy + 3.5
		_rect(cv, 16.0 + (0.5 if dir == "left" else 0.0), wy - 1.5, tw + 2.0, th + 3.0, wax, 3, true, true)
		_ell(cv, c.hcx + (1.0 if dir == "left" else 0.0), ttop + 1.5 + bob, tw if dir != "left" else tw + 1, 4, _tn(c, "accent", 0.18), true, true)
		if dir == "down":
			_rect(cv, 16, wy + 1, 1, th + 5, _tn(c, "accent", 0.35), 0, false)
			_rect(cv, 12.5, wy + 5, 4, 3, _tn(c, "accent", 0.2), 0, true)
			_rect(cv, 19.5, wy + 5, 4, 3, _tn(c, "accent", 0.2), 0, true)
			for k in range(3):
				cv.px(15, int(ttop + 5 + bob + k * 3), _col(c, "accent2"))
	if _has(c, "tweed_jacket"):
		var tw_ := _tn(c, "accent")
		var ty_: float = tcy + 0.5
		_rect(cv, 16.0 + (0.5 if dir == "left" else 0.0), ty_, tw + 2.0, th + 2.0, tw_, 2, true, true)
		if dir == "down":
			_rect(cv, 16, ty_ + 1, 1, th, _tn(c, "accent", 0.35), 0, false)
			_poly(cv, [Vector2(16, ttop + 1 + bob), Vector2(12, ttop + 1 + bob), Vector2(15, ttop + 8 + bob)], _tn(c, "accent", 0.2), false)
			_poly(cv, [Vector2(16, ttop + 1 + bob), Vector2(20, ttop + 1 + bob), Vector2(17, ttop + 8 + bob)], _tn(c, "accent", 0.2), false)
			cv.px(15, int(ttop + 10 + bob), _col(c, "accent2"))
			cv.px(15, int(ttop + 13 + bob), _col(c, "accent2"))
		else:
			_rect(cv, 16.5, ty_ + 4.0, 3, 3, _tn(c, "accent2"), 0, false)  # elbow patch
	if _has(c, "smock"):
		var sm_ := _tn(c, "accent")
		_rect(cv, 16.0 + (0.5 if dir == "left" else 0.0), tcy + 3.0, tw + 3.0, th + 5.0, sm_, 3, true, true)
		if dir == "down":
			_rect(cv, 16, ttop + 5 + bob, tw - 2, 4, _tn(c, "accent2"), 0, false)  # the smocked yoke
			cv.px(14, int(ttop + 5 + bob), _col(c, "accent"))
			cv.px(18, int(ttop + 7 + bob), _col(c, "accent"))
	if _has(c, "shawl") and dir != "up":
		var sh := _tn(c, "accent")
		var shs := {"pattern": "stripes", "pcol": _tn(c, "accent2"), "period": 4, "angle": 0}
		_ell(cv, c.hcx + (1.0 if dir == "left" else 0.0), ttop + 3 + bob, tw + 4, 8, sh, true, true)
		if dir == "down":
			_poly(cv, [Vector2(16 - tw * 0.5 - 1, ttop + 4 + bob), Vector2(16 + tw * 0.5 + 1, ttop + 4 + bob), Vector2(16, ttop + 11 + bob)], sh, true, true)
			_rect(cv, 16, ttop + 5 + bob, 1, 6, _tn(c, "accent2"), 0, false)
		else:
			_rect(cv, 16.5, tcy + 1, tw, 9, sh, 2, true, true, 0.0, shs)
	elif _has(c, "shawl"):
		_ell(cv, 16, ttop + 4 + bob, tw + 4, 10, _tn(c, "accent"), true, true)
	if _has(c, "lanyard") and dir != "up":
		var lan := _col(c, "accent2")
		if dir == "down":
			cv.paint(cv.line_mask([Vector2(14, ttop + 1 + bob), Vector2(16, tcy + 1), Vector2(18, ttop + 1 + bob)], 1.0), Canvas.tones(lan), {"shade": false})
			_rect(cv, 16, tcy + 3, 4, 5, Canvas.tones(Color("#f4f0e8")), 0, false)
			cv.px(15, int(tcy + 2), lan)
			cv.px(16, int(tcy + 2), lan)
		else:
			cv.paint(cv.line_mask([Vector2(14, ttop + 1 + bob), Vector2(13, tcy + 2)], 1.0), Canvas.tones(lan), {"shade": false})
			_rect(cv, 12.5, tcy + 4, 2, 4, Canvas.tones(Color("#f4f0e8")), 0, false)
	if _has(c, "hi_vis"):
		var hv_x := 16.0 + (0.5 if dir == "left" else 0.0)
		_rect(cv, hv_x, tcy + 0.5, tw - 0.5, th - 3.0, _tn(c, "accent"), 2, true, true)
		_rect(cv, hv_x, tcy - 1.5, tw - 0.5, 1.5, _tn(c, "accent2"), 0, false)
		_rect(cv, hv_x, tcy + 3.5, tw - 0.5, 1.5, _tn(c, "accent2"), 0, false)
		if dir == "down":
			_rect(cv, 16, tcy + 0.5, 1, th - 3.0, _tn(c, "accent2", 0.3), 0, false)
	if _has(c, "pin") and dir == "down":
		var pc := Canvas.parse_colour(c.pal.get("pin", "#d8b030"))
		_ell(cv, 20.5, tcy - 1, 3, 3, Canvas.tones(pc), true, false)
		cv.px(20, int(tcy - 2), pc.lightened(0.5))
	if _has(c, "backpack") and dir == "up":
		_rect(cv, 16, tcy + 1, tw - 1, th - 2, _tn(c, "accent2"), 3, true, true)
		_rect(cv, 16, tcy + 4, tw - 5, 4, _tn(c, "accent2", 0.2), 1, true, true)
	elif _has(c, "backpack") and dir == "down":
		_rect(cv, 16 - tw * 0.5 + 2, tcy - 1, 2, th - 3, _tn(c, "accent2"), 0, false)
		_rect(cv, 16 + tw * 0.5 - 2, tcy - 1, 2, th - 3, _tn(c, "accent2"), 0, false)
	if _has(c, "cape") and dir == "up":
		_rect(cv, 16, tcy + 3, tw + 4, th + 5, _tn(c, "accent"), 2, true, true, 0.0, {"pattern": "stripes", "pcol": _tn(c, "accent2"), "period": 4, "angle": 0})
	if _has(c, "scarf"):
		_ell(cv, c.hcx + (1.0 if dir == "left" else 0.0), ttop + 1.5 + bob, tw - 1 if dir != "left" else tw, 4, _tn(c, "accent"), true, true)
		if dir == "down":
			_rect(cv, 19, ttop + 7 + bob, 3, 8, _tn(c, "accent"), 1, true, true)
		elif dir == "left":
			_rect(cv, 19, ttop + 7 + bob, 3, 7, _tn(c, "accent"), 1, true, true)
		else:
			_rect(cv, 13, ttop + 7 + bob, 3, 8, _tn(c, "accent"), 1, true, true)
	if _has(c, "binoculars") and dir == "down":
		cv.paint(cv.line_mask([Vector2(16 - 4, ttop + 1 + bob), Vector2(16 - 2, tcy + 1), Vector2(16 + 2, tcy + 1), Vector2(16 + 4, ttop + 1 + bob)], 1.0), Canvas.tones(Color("#2a2a30")), {"shade": false})
		_ell(cv, 14.5, tcy + 2, 4, 4, _tn(c, "accent2"), true, true)
		_ell(cv, 17.5, tcy + 2, 4, 4, _tn(c, "accent2"), true, true)
	elif _has(c, "binoculars") and dir == "left":
		_rect(cv, 12.5, tcy + 2, 4, 5, _tn(c, "accent2"), 1, true, true)
	if _has(c, "badge") and dir == "down":
		_ell(cv, 20.5, tcy - 2, 3.5, 3.5, Canvas.tones(Color("#f0c040")), true, false)
		cv.px(20, int(tcy - 3), Color("#4a3a20"))
		cv.px(20, int(tcy - 2), Color("#4a3a20"))
	# arms in front
	if dir == "down" or dir == "up":
		for side in [-1, 1]:
			var x: float = 16.0 + side * (tw * 0.5 + aw * 0.5 - 0.5)
			var sy: float = ttop + 2 + bob + float(side * step)
			var sleeve_len := alen * (0.55 if sleeves == "short" else 0.82)
			var armtone := _tn(c, "top") if not (_has(c, "labcoat") or _has(c, "oilskin") or _has(c, "waxed_jacket")) else _tn(c, "accent")
			if _has(c, "gilet") or _has(c, "apron"):
				armtone = _tn(c, "top")
			_rect(cv, x, sy + (alen - 1) * 0.5, aw, alen - 1, _tn(c, "skin"), 1.5, true, false)
			_rect(cv, x, sy + sleeve_len * 0.5, aw, sleeve_len, armtone, 1.5, true, true, 0.0, _aran_extra(c))
			_ell(cv, x, sy + alen - 1, aw, aw - 0.5, _tn(c, "skin"), true)
			if _has(c, "phone") and dir == "down" and side == -1:
				_rect(cv, x - 1, sy + alen - 3, 3, 5, Canvas.tones(Color("#2a2a34")), 0, false)
				_rect(cv, x - 1, sy + alen - 3, 2, 3, Canvas.tones(Color("#9ad8f8")), 0, false)
	else:
		var sx := 16.0
		var sy: float = ttop + 3 + bob
		var sw := 3.0 * float(step)
		var ex: float = sx - sw * 0.8
		var ey: float = sy + alen - 1
		var sleeve_len := alen * (0.55 if sleeves == "short" else 0.82)
		var sl := sleeve_len / alen
		_limb(cv, sx, sy, ex, ey, aw, _tn(c, "skin"), false)
		_limb(cv, sx, sy, sx + (ex - sx) * sl, sy + (ey - sy) * sl, aw, _tn(c, "accent") if (_has(c, "labcoat") or _has(c, "oilskin") or _has(c, "waxed_jacket")) else _tn(c, "top"), true)
		_ell(cv, ex, ey + 0.5, aw, aw - 0.5, _tn(c, "skin"), true)
		if _has(c, "phone"):
			_rect(cv, ex - 2, ey - 1, 3, 4, Canvas.tones(Color("#2a2a34")), 0, false)
	_props(cv, c)

static func _aran_extra(c: Dictionary) -> Dictionary:
	if not _has(c, "aran"):
		return {}
	return {"pattern": "stripes", "pcol": _tn(c, "accent"), "period": 3, "angle": 0}

## Hand position of the carrying arm (viewer's left in front/back views).
static func _hand(c: Dictionary) -> Vector2:
	var b: Dictionary = c.b
	var alen := float(b.arm_len)
	var bob: int = c.bob
	if c.dir == "left":
		return Vector2(16.0 + 2.4 * float(c.step), float(c.ttop) + 3 + bob + alen - 0.5)
	var side := -1
	var tw: float = c.tw
	var aw := float(b.arm_w)
	return Vector2(16.0 + side * (tw * 0.5 + aw * 0.5 - 0.5), float(c.ttop) + 2 + bob + float(side * c.step) + alen - 1)

static func _line(cv, pts: Array, w: float, col: Color) -> void:
	cv.paint(cv.line_mask(pts, w), Canvas.tones(col), {"shade": false})

static func _props(cv, c: Dictionary) -> void:
	var h := _hand(c)
	var hx := h.x
	var hy := h.y
	var skin := _tn(c, "skin")
	var pcol := Canvas.parse_colour(c.pal.get("prop", "#8a6a40"))
	if _has(c, "lantern"):
		var glow := Canvas.parse_colour(c.pal.get("light", "#ffd860"))
		_line(cv, [Vector2(hx, hy), Vector2(hx, hy + 3)], 1.0, Color("#3a3028"))
		_rect(cv, hx, hy + 7, 6, 8, Canvas.tones(Color("#3a3028")), 1, false)
		_rect(cv, hx, hy + 7, 4, 6, Canvas.tones(glow), 1, false)
		cv.px(int(hx) - 1, int(hy) + 5, Color("#3a3028"))
		cv.px(int(hx), int(hy) + 5, Color("#3a3028"))
		cv.px(int(hx), int(hy) + 6, glow.lightened(0.6))
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "staff"):
		_line(cv, [Vector2(hx, hy - 17), Vector2(hx, FEET_Y - 1)], 1.6, pcol)
		_ell(cv, hx, hy - 17, 3, 3, Canvas.tones(pcol.lightened(0.2)), true, false)
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "lamp_pole"):
		# a lamplighter's long pole, its little flame up above the hat
		var flame := Canvas.parse_colour(c.pal.get("light", "#ffd860"))
		_line(cv, [Vector2(hx - 3, hy - 22), Vector2(hx + 0.5, FEET_Y - 1)], 1.6, pcol)
		_ell(cv, hx - 3.5, hy - 24.5, 3, 4, Canvas.tones(flame), false)
		cv.px(int(hx) - 4, int(hy) - 25, flame.lightened(0.7))
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "telescope"):
		# a brass telescope on a little tripod, pointing up and away at the sky
		var brass := Canvas.parse_colour(c.pal.get("prop", "#c8a050"))
		_line(cv, [Vector2(hx, hy + 2), Vector2(hx - 3, FEET_Y - 1)], 1.0, Color("#3a3028"))
		_line(cv, [Vector2(hx, hy + 2), Vector2(hx + 2, FEET_Y - 1)], 1.0, Color("#3a3028"))
		_line(cv, [Vector2(hx + 1, hy + 1), Vector2(hx - 3, hy - 10)], 3.0, brass.darkened(0.1))
		_line(cv, [Vector2(hx - 3, hy - 10), Vector2(hx - 5, hy - 15)], 2.2, brass.lightened(0.2))
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "hurley"):
		var top := hy - 15.0
		_line(cv, [Vector2(hx + 1, top), Vector2(hx, hy), Vector2(hx - 1.5, FEET_Y - 4)], 1.6, pcol)
		_ell(cv, hx - 2.5, FEET_Y - 2.5, 6, 4, Canvas.tones(pcol.lightened(0.15)), true, true, 20.0)
		_rect(cv, hx + 1, top + 2, 2, 5, Canvas.tones(Color("#e8e0d0")), 0, false)
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "umbrella"):
		var uc := Canvas.parse_colour(c.pal.get("prop", "#243a6a"))
		_line(cv, [Vector2(hx, hy + 1), Vector2(hx, FEET_Y - 2)], 1.0, Color("#3a3a44"))
		_poly(cv, [Vector2(hx - 2, hy + 1), Vector2(hx + 2, hy + 1), Vector2(hx + 1.5, hy + 11), Vector2(hx, hy + 14), Vector2(hx - 1.5, hy + 11)], Canvas.tones(uc), true, true)
		_line(cv, [Vector2(hx, hy - 1), Vector2(hx - 1, hy - 4), Vector2(hx + 1.5, hy - 5)], 1.2, Color("#5a4630"))
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "fiddle"):
		var wood := Canvas.tones(Color("#a8601e"))
		_line(cv, [Vector2(hx, hy - 5), Vector2(hx + 1, hy - 14)], 1.3, Color("#3a2a20"))
		cv.px(int(hx) + 1, int(hy) - 15, Color("#3a2a20"))
		_ell(cv, hx, hy - 1, 7, 9, wood, true, true, 10.0)
		cv.px(int(hx) - 1, int(hy) - 2, Color("#3a2018"))
		cv.px(int(hx) + 1, int(hy), Color("#3a2018"))
		_line(cv, [Vector2(hx - 5, hy + 3), Vector2(hx + 5, hy - 5)], 1.0, Color("#e8dcc0"))
		_ell(cv, hx, hy + 1, 3.5, 3.5, skin, true)
	if _has(c, "clipboard"):
		_rect(cv, hx, hy - 2, 7, 9, Canvas.tones(pcol), 0, true, true)
		_rect(cv, hx, hy - 2, 5, 7, Canvas.tones(Color("#f4f0e0")), 0, false)
		_rect(cv, hx, hy - 6, 3, 2, Canvas.tones(Color("#8a8a92")), 0, false)
		for k in range(3):
			_line(cv, [Vector2(hx - 2, hy - 3 + k * 2), Vector2(hx + 2, hy - 3 + k * 2)], 1.0, Color("#8a8aa0"))
		_ell(cv, hx, hy + 2, 3.5, 3.5, skin, true)
	if _has(c, "shinty_stick"):
		var st := hy - 12.0
		_line(cv, [Vector2(hx + 1, st), Vector2(hx, hy), Vector2(hx - 1, FEET_Y - 5)], 1.4, pcol)
		_rect(cv, hx - 1.5, FEET_Y - 3.0, 5, 3, Canvas.tones(pcol.lightened(0.1)), 1, true, true)
		_rect(cv, hx + 1, st + 3, 2, 4, Canvas.tones(Color("#e8e0d0")), 0, false)
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "curling_broom"):
		_line(cv, [Vector2(hx + 1, hy - 14), Vector2(hx, hy), Vector2(hx - 2, FEET_Y - 5)], 1.3, Color("#8a8a92"))
		_rect(cv, hx + 1, hy - 10, 2, 5, Canvas.tones(pcol), 0, false)
		_poly(cv, [Vector2(hx - 2, FEET_Y - 6), Vector2(hx - 5, FEET_Y), Vector2(hx + 4, FEET_Y), Vector2(hx + 0.5, FEET_Y - 6)], Canvas.tones(Color("#d8c070")), true, true)
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "bagpipes"):
		var bag := Canvas.tones(pcol)
		var tartan := {"pattern": "stripes", "pcol": _tn(c, "accent"), "period": 3, "angle": 0}
		var wood2 := Color("#3a2a22")
		var bx := hx + (3.0 if c.dir == "left" else 5.0)
		_line(cv, [Vector2(bx - 1, hy - 5), Vector2(bx - 4, hy - 20)], 1.2, wood2)
		_line(cv, [Vector2(bx + 1, hy - 5), Vector2(bx + 1, hy - 22)], 1.2, wood2)
		_line(cv, [Vector2(bx + 3, hy - 5), Vector2(bx + 6, hy - 19)], 1.2, wood2)
		_ell(cv, bx, hy - 3, 11, 8, bag, true, true, -15.0, tartan)
		_line(cv, [Vector2(bx - 3, hy), Vector2(bx - 5, hy + 10)], 1.2, Color("#d8c8a0"))
		_ell(cv, hx, hy, 3.5, 3.5, skin, true)
	if _has(c, "notebook"):
		_rect(cv, hx, hy - 1, 5, 7, Canvas.tones(Canvas.parse_colour(c.pal.get("prop", "#8a3a30"))), 0, true, true)
		_rect(cv, hx + 1.5, hy - 1, 1, 6, Canvas.tones(Color("#f4f0e0")), 0, false)
		_ell(cv, hx, hy + 2, 3.5, 3.5, skin, true)

# ---------- head ----------

static func _hair_cap(cx: float, cy: float, hw: float, hh: float, fringe: float, side: bool) -> Array:
	var pts: Array = []
	var a := 180
	while a <= 360:
		var rad := deg_to_rad(float(a))
		pts.append(Vector2(cx + cos(rad) * hw * 0.5, cy + sin(rad) * hh * 0.5))
		a += 15
	var yf := cy - hh * 0.5 + fringe
	if side:
		pts.append(Vector2(cx + hw * 0.5, cy + hh * 0.3))
		pts.append(Vector2(cx + hw * 0.18, cy + hh * 0.06))
		pts.append(Vector2(cx - hw * 0.2, yf))
		pts.append(Vector2(cx - hw * 0.5 + 1.0, yf + 1.0))
	else:
		pts.append(Vector2(cx + hw * 0.5, cy + 1.0))
		pts.append(Vector2(cx + hw * 0.5 - 1.5, yf + 1.5))
		pts.append(Vector2(cx + hw * 0.22, yf))
		pts.append(Vector2(cx, yf + 1.5))
		pts.append(Vector2(cx - hw * 0.22, yf))
		pts.append(Vector2(cx - hw * 0.5 + 1.5, yf + 1.5))
		pts.append(Vector2(cx - hw * 0.5, cy + 1.0))
	return pts

static func _head(cv, c: Dictionary) -> void:
	var dir: String = c.dir
	var bob: int = c.bob
	var hw: float = c.hw
	var hh: float = c.hh
	var cx: float = c.hcx
	var cy: float = c.hcy + bob
	var skin := _tn(c, "skin")
	var hair := _tn(c, "hair")
	var style := _hair_style(c)
	var hat := str(c.r.get("hat", "none"))
	var fringe := 4.0 if hh >= 14.0 else 3.5
	# ears
	if dir != "up":
		if dir == "down":
			_ell(cv, cx - hw * 0.5, cy + 2, 2.5, 3.5, _tn(c, "skin", 0.1), true)
			_ell(cv, cx + hw * 0.5, cy + 2, 2.5, 3.5, _tn(c, "skin", 0.1), true)
	var capped := not style in ["bald", "mohawk"]  # a hair cap over the skull (mohawk and shaved heads show skin)
	if dir == "up":
		if style == "afro":
			_ell(cv, cx, cy - 1.5, hw + 7, hh + 5, hair, true, false)
		_ell(cv, cx, cy, hw, hh, hair, true, false)
		if style in ["mohawk", "undercut"]:
			_ell(cv, cx, cy, hw, hh, skin, true, false, 0.0, SKIN)
			if style == "mohawk":
				_rect(cv, cx, cy - 1, 4, hh * 0.9, hair, 1, true)
			else:
				_ell(cv, cx, cy - 1, hw * 0.72, hh * 0.8, hair, true, false)
		elif style == "braids":
			for k in [-1, 1]:
				_rect(cv, cx + k * hw * 0.3, cy + hh * 0.5 + 3, 2.5, 10, hair, 1, true)
		elif style == "locs":
			for k in [-1.5, -0.5, 0.5, 1.5]:
				_rect(cv, cx + k * hw * 0.22, cy + hh * 0.5 + 3, 1.8, 9, hair, 0.8, true)
		if style == "long":
			_rect(cv, cx, cy + hh * 0.5 + 3, hw, 10, hair, 3, true)
		elif style == "bob":
			_rect(cv, cx, cy + hh * 0.35, hw, hh * 0.6, hair, 3, true)
		elif style == "windswept":
			_rect(cv, cx + 1, cy + hh * 0.5 + 3, hw + 1, 10, hair, 3, true, false, -5.0)
		elif style == "pony":
			_rect(cv, cx, cy + hh * 0.5 + 4, 4, 11, hair, 2, true)
		elif style == "bald":
			_ell(cv, cx, cy, hw, hh, skin, true, false, 0.0, SKIN)
			_ell(cv, cx, cy + 3, hw - 1, hh * 0.5, hair, true, false)
	else:
		if style == "afro":
			_ell(cv, cx + (0.5 if dir == "left" else 0.0), cy - 1.5, hw + 7, hh + 5, hair, true, false)
		_ell(cv, cx, cy, hw, hh, skin, true, false, 0.0, SKIN)
		if dir == "left":
			_ell(cv, cx - hw * 0.5, cy + hh * 0.22, 2, 2, skin, false)
			if capped and style != "undercut":
				_ell(cv, cx + hw * 0.2, cy - 0.5, hw * 0.65, hh * 0.9, hair, true, false)
		if style == "mohawk":
			if dir == "down":
				_rect(cv, cx, cy - hh * 0.5 - 1.0, 4, 7, hair, 1, true)
			else:
				_rect(cv, cx + 0.5, cy - hh * 0.5 + 0.5, hw * 0.8, 5, hair, 1.5, true)
		elif style == "undercut":
			_poly(cv, _hair_cap(cx, cy - 0.5, hw * 0.72, hh * 0.85, fringe - 1.0, dir == "left"), hair, true)
		elif style == "buzz":
			_poly(cv, _hair_cap(cx, cy, hw + (1 if dir == "down" else 0.5), hh + 0.5, 1.5, dir == "left"), hair, false)
		elif capped:
			_poly(cv, _hair_cap(cx, cy, hw + (1 if dir == "down" else 0.5), hh + 0.5, fringe - (0.5 if dir == "left" else 0.0), dir == "left"), hair, true)
		if style == "braids":
			var bx := [cx - hw * 0.5 - 0.5, cx + hw * 0.5 + 0.5] if dir == "down" else [cx + hw * 0.5 + 0.5]
			for x in bx:
				_rect(cv, x, cy + hh * 0.3 + 2, 2.5, hh * 0.9, hair, 1, true, false, 0.0, {"pattern": "stripes", "pcol": _tn(c, "hair", 0.25), "period": 2, "angle": 90})
		elif style == "locs":
			if dir == "down":
				for k in [-2, -1, 1, 2]:
					_rect(cv, cx + k * hw * 0.3, cy + hh * 0.35 + absi(k), 1.8, hh * 0.7, _tn(c, "hair", 0.08 * absi(k)), 0.8, true)
			else:
				for k in 3:
					_rect(cv, cx + hw * 0.5 + 1 - k * 1.5, cy + hh * 0.4 + k * 0.5, 1.8, hh * 0.7, _tn(c, "hair", 0.1 * k), 0.8, true)
		if style == "long" or style == "bob":
			var ln := 6.0 if style == "long" else 3.0
			if dir == "down":
				_rect(cv, cx - hw * 0.5 + 0.5, cy + 2 + ln * 0.3, 2.5, 6 + ln * 0.6, hair, 1, true)
				_rect(cv, cx + hw * 0.5 - 0.5, cy + 2 + ln * 0.3, 2.5, 6 + ln * 0.6, hair, 1, true)
		if style == "curly":
			for k in [-1, 0, 1]:
				_ell(cv, cx + k * hw * 0.38, cy - hh * 0.42, 5, 5, hair, true)
			_ell(cv, cx - hw * 0.5, cy - hh * 0.1, 4, 5, hair, true)
			_ell(cv, cx + hw * 0.5, cy - hh * 0.1, 4, 5, hair, true)
		if style == "spiky":
			for k in [-1, 0, 1]:
				_poly(cv, [Vector2(cx + k * 4 - 2.5, cy - hh * 0.4), Vector2(cx + k * 4 + k * 1.5, cy - hh * 0.5 - 4), Vector2(cx + k * 4 + 2.5, cy - hh * 0.4)], hair, true)
		if dir == "left":
			_ell(cv, cx + hw * 0.12, cy + 2.5, 2.5, 3.5, _tn(c, "skin", 0.12), true)
	if style == "bun":
		_ell(cv, cx + (hw * 0.15 if dir == "left" else 0.0), cy - hh * 0.5 - 1.5, 6, 6, hair, true, false)
	_face(cv, c, cx, cy, hw, hh)
	_facial(cv, c, cx, cy, hw, hh)
	_hat(cv, c, cx, cy, hw, hh, hat)
	if _has(c, "glitter") and dir != "up":
		var gc := [Color("#f8e060"), Color("#f080f0"), Color("#80e8f8")]
		var gp := [Vector2(-5, 3), Vector2(4, 4), Vector2(-3, 6), Vector2(6, 2), Vector2(0, -1)] if dir == "down" else [Vector2(-4, 4), Vector2(-2, 6), Vector2(1, 3)]
		for k in gp.size():
			cv.px(int(round(cx + gp[k].x)), int(round(cy + gp[k].y)), gc[k % 3])

static func _facial(cv, c: Dictionary, cx: float, cy: float, hw: float, hh: float) -> void:
	var dir: String = c.dir
	if dir == "up":
		return
	var eh := int(c.b.eye_h)
	var ey := int(round(cy + hh * 0.12))
	var my := ey + eh + 2
	var bc := Canvas.parse_colour(c.pal.get("beard", c.pal.get("hair", "#4a3426")))
	var btn := Canvas.tones(bc)
	if _has(c, "grin"):
		var skin := _col(c, "skin")
		if dir == "down":
			for k in range(-3, 3):
				cv.px(int(round(cx)) + k, my - 1, skin.darkened(0.45))
			for k in range(-2, 2):
				cv.px(int(round(cx)) + k, my, Color("#fffaf0"))
			cv.px(int(round(cx)) - 3, my - 2, skin.darkened(0.35))
			cv.px(int(round(cx)) + 2, my - 2, skin.darkened(0.35))
		else:
			var gx := int(round(cx - hw * 0.28)) - 1
			for k in range(-1, 3):
				cv.px(gx + k, my - 1, skin.darkened(0.45))
			cv.px(gx, my, Color("#fffaf0"))
			cv.px(gx + 1, my, Color("#fffaf0"))
	if _has(c, "beard"):
		if dir == "down":
			_ell(cv, cx, cy + hh * 0.5 - 1.5, hw - 1, 8, btn, true)
			cv.px(int(round(cx)) - 1, my, bc.darkened(0.5))
			cv.px(int(round(cx)), my, bc.darkened(0.5))
		else:
			_ell(cv, cx - hw * 0.15, cy + hh * 0.5 - 1.5, hw * 0.65, 8, btn, true)
			cv.px(int(round(cx - hw * 0.28)) - 1, my, bc.darkened(0.5))
	if _has(c, "moustache"):
		if dir == "down":
			_rect(cv, cx, float(my) - 0.5, 7, 2, btn, 1, false)
			cv.px(int(round(cx)) - 4, my + 1, bc)
			cv.px(int(round(cx)) + 3, my + 1, bc)
		else:
			_rect(cv, cx - hw * 0.28 + 0.5, float(my) - 0.5, 4, 2, btn, 1, false)

static func _face(cv, c: Dictionary, cx: float, cy: float, hw: float, hh: float) -> void:
	var dir: String = c.dir
	if dir == "up":
		return
	var eh := int(c.b.eye_h)
	var ink := Color("#2a2230")
	var ey := int(round(cy + hh * 0.12))
	var skin := _col(c, "skin")
	var blush := skin.lerp(Color("#f08a8a"), 0.55)
	if dir == "down":
		var gap := 2
		var lx := int(round(cx)) - gap - 2
		var rx := int(round(cx)) + gap
		for ex in [lx, rx]:
			for yy in eh:
				cv.px(ex, ey + yy, ink)
				cv.px(ex + 1, ey + yy, ink)
			if eh >= 3:
				cv.px(ex, ey, Color("#ffffff"))
		cv.px(lx - 1, ey + eh, blush)
		cv.px(lx, ey + eh, blush)
		cv.px(rx + 1, ey + eh, blush)
		cv.px(rx + 2, ey + eh, blush)
		var my := ey + eh + 2
		cv.px(int(round(cx)) - 1, my, skin.darkened(0.35))
		cv.px(int(round(cx)), my, skin.darkened(0.35))
		if _has(c, "glasses"):
			_glasses(cv, c, lx, ey, eh, rx)
	else:
		var ex := int(round(cx - hw * 0.28)) - 1
		for yy in eh:
			cv.px(ex, ey + yy, ink)
			cv.px(ex + 1, ey + yy, ink)
		if eh >= 3:
			cv.px(ex, ey, Color("#ffffff"))
		cv.px(ex + 2, ey + eh, blush)
		cv.px(ex - 1, ey + eh + 2, skin.darkened(0.35))
		cv.px(ex, ey + eh + 2, skin.darkened(0.35))
		if _has(c, "glasses"):
			var fc := _col(c, "glasses")
			for yy in range(-1, eh + 1):
				for xx in range(-1, 3):
					if yy == -1 or yy == eh or xx == -1 or xx == 2:
						cv.px(ex + xx, ey + yy, fc)
			for xx in range(3, 8):
				cv.px(ex + xx, ey - 1, fc)

static func _glasses(cv, c: Dictionary, lx: int, ey: int, eh: int, rx: int) -> void:
	var fc := _col(c, "glasses")
	for ex in [lx, rx]:
		for yy in range(-1, eh + 1):
			for xx in range(-1, 3):
				if yy == -1 or yy == eh or xx == -1 or xx == 2:
					cv.px(ex + xx, ey + yy, fc)
	cv.px(lx + 3, ey, fc)
	cv.px(lx + 4, ey, fc)

static func _hat(cv, c: Dictionary, cx: float, cy: float, hw: float, hh: float, hat: String) -> void:
	var dir: String = c.dir
	var hk := "hat" if c.pal.has("hat") else "accent"
	var col := _tn(c, hk)
	var side := dir == "left"
	var top := cy - hh * 0.5
	match hat:
		"cap":
			_ell(cv, cx + (1.0 if side else 0.0), top + 3.5, hw + 1.5, 8, col, true, true)
			if dir == "down":
				_rect(cv, cx, top + 6.5, hw + 1, 2.5, _tn(c, hk, 0.2), 1, true, true)
			elif side:
				_rect(cv, cx - hw * 0.5 - 1, top + 6.5, 7, 2.5, _tn(c, hk, 0.2), 1, true, true)
		"beanie":
			_ell(cv, cx + (1.0 if side else 0.0), top + 3.5, hw + 1.5, 9, col, true, true)
			_rect(cv, cx + (1.0 if side else 0.0), top + 6.5, hw + 1.5, 3, _tn(c, hk, 0.2), 1, true, true)
			_ell(cv, cx + (1.0 if side else 0.0), top - 1.0, 4, 4, _tn(c, hk, -0.0), true, true)
		"swimcap":
			_ell(cv, cx + (0.5 if side else 0.0), top + 3.5, hw + 1.5, hh * 0.52, col, true, true)
			if dir == "down":
				_rect(cv, cx, top + 7.5, hw + 1, 1, _tn(c, hk, 0.25), 0, false)
				cv.px(int(cx) - 5, int(top + 8), _col(c, hk).darkened(0.3))
				cv.px(int(cx) + 5, int(top + 8), _col(c, hk).darkened(0.3))
			_ell(cv, cx + 2.0, top + 3, 3, 3, _tn(c, "accent2"), true)
		"sunhat":
			_ell(cv, cx, top + 5, hw + 12, 6, col, true, true)
			_ell(cv, cx, top + 2.5, hw - 1, 7, _tn(c, hk, -0.05), true, true)
			_rect(cv, cx, top + 4.5, hw - 1, 2, _tn(c, "accent2"), 0, false)
		"bucket":
			_ell(cv, cx, top + 6, hw + 6, 4, col, true, true)
			_rect(cv, cx, top + 3, hw, 7, col, 2, true, true)
			_rect(cv, cx, top + 5, hw, 1.5, _tn(c, "accent2"), 0, false)
		"witch_hat":
			var wx := cx + (1.0 if side else 0.0)
			_ell(cv, wx, top + 4.5, hw + 12, 5, col, true, true)
			_poly(cv, [Vector2(wx - hw * 0.45, top + 4), Vector2(wx + hw * 0.45, top + 4), Vector2(wx + 2.5, top - 5), Vector2(wx + 6.0, top - 12), Vector2(wx - 1.0, top - 6)], col, true, true)
			_rect(cv, wx, top + 2.5, hw * 0.9, 2.5, _tn(c, "accent"), 0, false)
			_rect(cv, wx + 1, top + 2.5, 3, 3, Canvas.tones(Color("#e8c040")), 0, false)
		"panama":
			var px_ := cx + (1.0 if side else 0.0)
			_ell(cv, px_, top + 5, hw + 10, 5, col, true, true)
			_rect(cv, px_, top + 1.5, hw - 1, 8, _tn(c, hk, -0.05), 3, true, true)
			_rect(cv, px_, top + 3.5, hw - 1, 2, _tn(c, "accent2"), 0, false)
			if dir == "down":
				cv.px(int(px_) - 2, int(top) + 1, _col(c, hk).darkened(0.2))
				cv.px(int(px_) + 2, int(top) + 1, _col(c, hk).darkened(0.2))
		"hard_hat":
			var lx_ := cx + (1.0 if side else 0.0)
			_ell(cv, lx_, top + 3, hw + 2, 9, col, true, true)
			_rect(cv, lx_, top + 6, hw + 5, 2, _tn(c, hk, 0.15), 1, true, true)
			_rect(cv, lx_, top + 0.5, 2, 5, _tn(c, hk, 0.2), 0, false)
			var lamp := Canvas.parse_colour(c.pal.get("light", "#fff0a0"))
			if dir == "down":
				_ell(cv, cx, top + 3, 4, 4, Canvas.tones(Color("#4a4a52")), true, true)
				cv.px(int(cx) - 1, int(top) + 3, lamp)
				cv.px(int(cx), int(top) + 3, lamp)
			elif side:
				_ell(cv, cx - hw * 0.5 - 1, top + 4, 4, 4, Canvas.tones(Color("#4a4a52")), true, true)
				cv.px(int(cx - hw * 0.5) - 2, int(top) + 4, lamp)
		"top_hat":
			var tx := cx + (1.0 if side else 0.0)
			_ell(cv, tx, top + 4.5, hw + 4, 4, col, true, true)
			_rect(cv, tx, top - 3.0, hw - 3, 12, col, 1, true, true)
			_rect(cv, tx, top + 2.0, hw - 3, 2, _tn(c, "accent2"), 0, false)
		"tudor_bonnet":
			var ub := cx + (1.0 if side else 0.0)
			_ell(cv, ub, top + 4.0, hw + 5, 5, col, true, true)
			_ell(cv, ub, top + 1.5, hw + 1, 6, _tn(c, hk, -0.05), true, true)
			_rect(cv, ub, top + 3.5, hw + 1, 1.5, _tn(c, "accent"), 0, false)
		"sou_wester":
			var qx := cx + (1.0 if side else 0.0)
			_ell(cv, qx, top + 3.5, hw + 2, 9, col, true, true)
			if dir == "up":
				_rect(cv, qx, top + 8.5, hw + 5, 5, _tn(c, hk, 0.05), 2, true, true)  # the long brim down the neck
			elif dir == "down":
				_rect(cv, cx, top + 6.5, hw + 3, 2, _tn(c, hk, 0.2), 1, true, true)
			else:
				_rect(cv, cx + 3, top + 8, hw - 2, 4, _tn(c, hk, 0.05), 1, true, true)
		"tam":
			var mx2 := cx + (1.0 if side else 0.0)
			_ell(cv, mx2, top + 3.0, hw + 4, 8, col, true, true)
			_rect(cv, mx2, top + 6.0, hw + 1, 2, _tn(c, "accent2"), 0, false)
			_ell(cv, mx2, top - 1.0, 3, 3, Canvas.tones(Color("#c83a3a")), true)  # the toorie
		"boater":
			var bx := cx + (1.0 if side else 0.0)
			_ell(cv, bx, top + 5, hw + 7, 4, col, true, true)
			_rect(cv, bx, top + 1.5, hw - 2, 7, _tn(c, hk, -0.05), 1, true, true)
			_rect(cv, bx, top + 4.0, hw - 2, 2, _tn(c, "accent2"), 0, false)
		"flat_cap":
			var fx := cx + (1.0 if side else 0.0)
			_ell(cv, fx, top + 3.5, hw + 3, 7, col, true, true)
			_rect(cv, fx, top + 1.5, hw + 1, 3, _tn(c, hk, -0.1), 1, true, false)
			if dir == "down":
				_rect(cv, cx, top + 6.5, hw, 2, _tn(c, hk, 0.25), 1, true, true)
			elif side:
				_rect(cv, cx - hw * 0.5 - 1.5, top + 6.5, 6, 2, _tn(c, hk, 0.25), 1, true, true)
		"helmet":
			var mx := cx + (1.0 if side else 0.0)
			var cage := Color("#44464e")
			_ell(cv, mx, top + 3.5, hw + 2.5, 9, col, true, true)
			if dir == "down":
				_rect(cv, cx - hw * 0.5 - 0.5, cy + 3, 2.5, 8, _tn(c, hk, 0.1), 1, true, true)
				_rect(cv, cx + hw * 0.5 + 0.5, cy + 3, 2.5, 8, _tn(c, hk, 0.1), 1, true, true)
				for k in [-3, 0, 3]:
					for yy in range(int(cy) + 0, int(cy + hh * 0.5) - 1):
						if yy != int(cy + hh * 0.12) and yy != int(cy + hh * 0.12) + 1:
							cv.px(int(round(cx)) + k, yy, cage)
				for k in range(-4, 5):
					cv.px(int(round(cx)) + k, int(cy + hh * 0.5) - 1, cage)
			elif side:
				_rect(cv, cx + 1, cy + 4, 4, 7, _tn(c, hk, 0.1), 1, true, true)
				for yy in range(int(cy), int(cy + hh * 0.5)):
					cv.px(int(cx - hw * 0.5), yy, cage)
				for k in range(0, 5):
					cv.px(int(cx - hw * 0.5) + k, int(cy + hh * 0.5) - 1, cage)
		"bobble_hat":
			var bx2 := cx + (1.0 if side else 0.0)
			_ell(cv, bx2, top + 3.5, hw + 1.5, 9, col, true, true, 0.0, {"pattern": "stripes", "pcol": _tn(c, "accent"), "period": 4, "angle": 0})
			_rect(cv, bx2, top + 6.5, hw + 1.5, 3, _tn(c, hk, 0.2), 1, true, true)
			_ell(cv, bx2, top - 2.0, 6, 6, _tn(c, "accent"), true, true)
		"welding_visor":
			var vx := cx + (1.0 if side else 0.0)
			_ell(cv, vx, top + 3, hw + 2, 9, col, true, true)
			_rect(cv, vx, top + 6, hw + 5, 2, _tn(c, hk, 0.15), 1, true, true)
			_rect(cv, vx, top - 1.5, hw + 1, 4, Canvas.tones(Color("#2a3a34")), 1, true, true)
			_rect(cv, vx, top - 1.5, hw - 2, 2, Canvas.tones(Color("#58c0a0")), 0, false)
		"deerstalker":
			var dx_ := cx + (1.0 if side else 0.0)
			_ell(cv, dx_, top + 2.5, hw + 2, 7, col, true, true)
			_rect(cv, dx_, top + 4.5, hw + 2, 2, _tn(c, hk, 0.12), 1, true, true)
			if dir == "down":
				_rect(cv, cx, top + 5.8, hw - 1, 2, _tn(c, hk, 0.25), 1, true, true)
				_rect(cv, cx - hw * 0.5 - 1, cy + 3, 3, 4, _tn(c, hk, 0.1), 1, true, true)
				_rect(cv, cx + hw * 0.5 + 1, cy + 3, 3, 4, _tn(c, hk, 0.1), 1, true, true)
			elif side:
				_rect(cv, cx - hw * 0.5 - 1.5, top + 5.8, 6, 2, _tn(c, hk, 0.25), 1, true, true)
				_rect(cv, cx + hw * 0.5 + 1, top + 5.8, 5, 2, _tn(c, hk, 0.25), 1, true, true)
				_rect(cv, cx + 2, cy + 3, 4, 4, _tn(c, hk, 0.1), 1, true, true)
			else:
				_rect(cv, cx, top + 8, hw, 2.5, _tn(c, hk, 0.25), 1, true, true)
			cv.px(int(dx_), int(top) - 1, _col(c, hk).darkened(0.3))
			cv.px(int(dx_) + 1, int(top) - 1, _col(c, hk).darkened(0.3))
		"flower_crown", "holly_crown":
			var ccx := cx + (1.0 if side else 0.0)
			var holly := hat == "holly_crown"
			var leaf := Canvas.parse_colour(c.pal.get("leaf", "#3e8a3a"))
			var blooms: Array = [Color("#c83a3a"), Color("#c83a3a"), Color("#c83a3a")] if holly else [Color("#f088b8"), Color("#f4e050"), Color("#ffffff"), Color("#b080e8"), Color("#f08a40")]
			var n := 7
			for k in n:
				var t := float(k) / float(n - 1)
				var ax := ccx + (t - 0.5) * (hw + 1.5)
				var ay := top + 3.0 - sin(t * PI) * 1.5
				_ell(cv, ax, ay + 0.5, 3.5, 3, Canvas.tones(leaf), true)
				if k % 2 == 1 or not holly:
					cv.px(int(round(ax)), int(round(ay)), blooms[k % blooms.size()])
					if not holly:
						cv.px(int(round(ax)) + 1, int(round(ay)), blooms[k % blooms.size()])
		"headscarf":
			# a scarf over the hair, framing the face and falling to the shoulders
			if dir == "up":
				_ell(cv, cx, cy + 0.5, hw + 2, hh + 2, col, true, true)
				_ell(cv, cx, cy + hh * 0.5 + 2.5, hw + 3, 7, _tn(c, hk, 0.08), true, true)
			elif side:
				_ell(cv, cx + hw * 0.32, cy + 1, hw * 0.62, hh + 1.5, col, true, true)
				_ell(cv, cx + 0.5, top + 2, hw + 1.5, 6.5, col, true, true)
				_ell(cv, cx + hw * 0.1, cy + hh * 0.5 + 2.5, hw * 0.9, 6, _tn(c, hk, 0.08), true, true)
			else:
				_ell(cv, cx, top + 2, hw + 3, 6.5, col, true, true)
				_rect(cv, cx - hw * 0.5 - 0.5, cy + 1.5, 3, hh * 0.85, col, 1, true)
				_rect(cv, cx + hw * 0.5 + 0.5, cy + 1.5, 3, hh * 0.85, col, 1, true)
				_ell(cv, cx, cy + hh * 0.5 + 2.5, hw + 3, 6, _tn(c, hk, 0.08), true, true)
		"turban":
			# a dastar: wrapped high and neat, the folds meeting in a point above the brow
			var tx := cx + (1.0 if side else 0.0)
			_ell(cv, tx, top + 0.5, hw + 2.5, 9, col, true, true)
			if dir != "up":
				_poly(cv, [Vector2(tx - 4.0, top + 4.0), Vector2(tx, top - 3.0), Vector2(tx + 4.0, top + 4.0)], _tn(c, hk, 0.15), true)
				_rect(cv, tx, top + 4.5, hw + 1.5, 1.5, _tn(c, hk, 0.2), 0, false)
		"headband":
			_rect(cv, cx + (0.5 if side else 0.0), top + 4.5, hw + 1, 2, col, 0, true)
			if side:
				_rect(cv, cx + hw * 0.5 + 2, top + 7, 2, 4, col, 0, false)
		_:
			pass
