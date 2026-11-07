class_name FolkArt
extends RefCounted
## Drawing helpers shared by the folk-race screens (cheese rolling, the pancake race): painted skies, hills, bunting,
## crowds and little people, all cheap canvas calls so an old iMac keeps its 60 fps. Static, no autoloads.

const SKIN := [Color("e8c8a0"), Color("c99468"), Color("8d5a3b"), Color("f0d4b4")]
const COATS := [Color("b83a32"), Color("2f6d9a"), Color("e0a82e"), Color("4a8a4e"), Color("8a4a8a"), Color("e8e0cc"), Color("d86a2a")]

## A sky in vertical bands from `top` to `bottom` colours over the rect.
static func sky(ci: CanvasItem, r: Rect2, top: Color, bottom: Color, bands := 14) -> void:
	var h := r.size.y / float(bands)
	for i in bands:
		ci.draw_rect(Rect2(r.position.x, r.position.y + h * i, r.size.x, h + 1.0), top.lerp(bottom, float(i) / float(bands - 1)))

static func sun(ci: CanvasItem, c: Vector2, rad: float, col: Color) -> void:
	for k in 4:
		ci.draw_circle(c, rad * (2.4 - 0.45 * k), Color(col, 0.07 + 0.05 * k))
	ci.draw_circle(c, rad, col)

static func cloud(ci: CanvasItem, c: Vector2, s: float, col := Color(1, 1, 1, 0.85)) -> void:
	for o in [Vector2(-1.1, 0.2), Vector2(-0.4, -0.35), Vector2(0.5, -0.15), Vector2(1.2, 0.25), Vector2(0.0, 0.3)]:
		ci.draw_circle(c + o * s, s * 0.62, col)

## A rolling ridge of hills across the width, as one filled polygon. `seed_v` shifts the shape, `shift` slides it.
static func ridge(ci: CanvasItem, y_base: float, w: float, amp: float, col: Color, seed_v := 0.0, shift := 0.0, freq := 0.011) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, y_base + amp * 3.0))
	var steps := 36
	for i in steps + 1:
		var px := w * float(i) / float(steps)
		var yy := y_base - amp * (0.55 + 0.45 * sin((px + shift) * freq + seed_v)) - amp * 0.25 * sin((px + shift) * freq * 2.3 + seed_v * 1.7)
		pts.append(Vector2(px, yy))
	pts.append(Vector2(w, y_base + amp * 3.0))
	ci.draw_colored_polygon(pts, col)

static func tree(ci: CanvasItem, base: Vector2, s: float, leaf := Color("4f7a3a")) -> void:
	ci.draw_rect(Rect2(base.x - s * 0.07, base.y - s * 0.4, s * 0.14, s * 0.4), Color("5a4430"))
	ci.draw_circle(base + Vector2(0, -s * 0.62), s * 0.34, leaf.darkened(0.15))
	ci.draw_circle(base + Vector2(-s * 0.16, -s * 0.5), s * 0.26, leaf)
	ci.draw_circle(base + Vector2(s * 0.17, -s * 0.52), s * 0.27, leaf.lightened(0.08))

## A string of bunting between two points, sagging, in the given colours.
static func bunting(ci: CanvasItem, a: Vector2, b: Vector2, sag: float, cols: Array = COATS) -> void:
	var prev := a
	var n := 12
	for i in range(1, n + 1):
		var u := float(i) / float(n)
		var p := a.lerp(b, u) + Vector2(0, sin(u * PI) * sag)
		ci.draw_line(prev, p, Color("3a2e22"), 1.5)
		if i < n:
			var c: Color = cols[i % cols.size()]
			ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(-6, 0), p + Vector2(0, 13), p + Vector2(6, 0)]), c)
		prev = p

## A little spectator: head, body and (when cheering) arms up. `s` is body height in pixels.
static func spectator(ci: CanvasItem, foot: Vector2, s: float, idx: int, cheer := 0.0) -> void:
	var coat: Color = COATS[idx % COATS.size()]
	var skin: Color = SKIN[(idx / 3) % SKIN.size()]
	ci.draw_rect(Rect2(foot.x - s * 0.19, foot.y - s * 0.62, s * 0.38, s * 0.62), coat)
	ci.draw_circle(foot + Vector2(0, -s * 0.78), s * 0.17, skin)
	if idx % 5 == 0:
		ci.draw_rect(Rect2(foot.x - s * 0.2, foot.y - s * 0.92, s * 0.4, s * 0.09), coat.darkened(0.3))
	if cheer > 0.0:
		var up := sin(cheer * 9.0 + float(idx)) * 0.5 + 0.5
		ci.draw_line(foot + Vector2(-s * 0.19, -s * 0.5), foot + Vector2(-s * 0.32, -s * (0.75 + 0.2 * up)), skin, maxf(1.5, s * 0.07))
		ci.draw_line(foot + Vector2(s * 0.19, -s * 0.5), foot + Vector2(s * 0.32, -s * (0.75 + 0.2 * (1.0 - up))), skin, maxf(1.5, s * 0.07))

## A round Double Gloucester seen from the side-on, rolling: a rind, a cut face and a spin mark.
static func cheese_wheel(ci: CanvasItem, c: Vector2, rad: float, spin: float) -> void:
	ci.draw_circle(c + Vector2(rad * 0.1, rad * 0.95), rad * 0.9, Color(0, 0, 0, 0.18))
	ci.draw_circle(c, rad, Color("c9892c"))
	ci.draw_circle(c, rad * 0.86, Color("f0c24a"))
	for k in 3:
		var a := spin + TAU * float(k) / 3.0
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * rad * 0.45, rad * 0.11, Color("d9a02e"))
	ci.draw_line(c, c + Vector2(cos(spin), sin(spin)) * rad * 0.86, Color("c9892c"), maxf(1.0, rad * 0.08))
	ci.draw_arc(c, rad * 0.97, 0.0, TAU, 20, Color("a8701e"), maxf(1.0, rad * 0.07))
