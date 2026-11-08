class_name TextCheck
extends RefCounted
## Dev check (`--text-check` with `--shot`): lists text on screen that a player can't read whole. A label whose
## words run past its box (and aren't trimmed with an ellipsis), lines a box is too short for, text off the edge
## of the screen, text under a panel drawn after it, and type smaller than MIN_PX. Written beside the PNG as
## <shot>.text.txt; LayoutAudit (`--audit`) covers controls spilling out of their menus.

const MIN_PX := 18      # the smallest type we put in front of a player at 1280x720
const SLACK := 2.0      # px of rounding we forgive
const COVER := 0.25     # a panel over this share of a label's text hides it

## Problems as readable lines.
static func report(root: Node, screen: Rect2) -> Array:
	var items := []  # {c: Control, layer: int, rect: Rect2, text: bool, panel: bool}
	_collect(root, 0, 1.0, items)
	var out := []
	for i in items.size():
		var it: Dictionary = items[i]
		if not it.text:
			continue
		var c: Control = it.c
		var tr := text_rect(c)
		if tr.size.x <= 0.0 or tr.size.y <= 0.0:
			continue
		var name := _name(c)
		var fs := font_size(c)
		if fs > 0 and fs < MIN_PX:
			out.append("%s: %d px type" % [name, fs])
		var spill := overflow(c)
		if spill != "":
			out.append("%s: %s" % [name, spill])
		if not screen.grow(SLACK).encloses(tr):
			out.append("%s: off the screen (%d,%d %dx%d)" % [name, tr.position.x, tr.position.y, tr.size.x, tr.size.y])
		for j in items.size():
			var o: Dictionary = items[j]
			if not o.panel or o.c == c or o.c.is_ancestor_of(c) or c.is_ancestor_of(o.c):
				continue
			var above: bool = int(o.layer) > int(it.layer) or (int(o.layer) == int(it.layer) and j > i)
			if not above:
				continue
			var hit := tr.intersection(o.rect)
			if hit.get_area() > tr.get_area() * COVER:
				out.append("%s: under %s" % [name, _name(o.c)])
				break
	return out

## Every visible control in draw order, with its canvas layer; faded-out ones (alpha down the tree) don't count.
static func _collect(n: Node, layer: int, alpha: float, items: Array) -> void:
	if n is CanvasLayer:
		if not (n as CanvasLayer).visible:
			return
		layer = (n as CanvasLayer).layer
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is CanvasItem:
		alpha *= (n as CanvasItem).modulate.a
	if n is Control:
		var c := n as Control
		if alpha * c.self_modulate.a > 0.05:
			var is_text := (c is Label or c is RichTextLabel or c is Button) and _text(c).strip_edges() != ""
			items.append({"c": c, "layer": layer, "rect": c.get_global_rect(), "text": is_text, "panel": _opaque(c)})
	for ch in n.get_children():
		_collect(ch, layer, alpha, items)

## A control that paints over what is under it: a panel or a solid colour.
static func _opaque(c: Control) -> bool:
	if c is ColorRect:
		return (c as ColorRect).color.a > 0.6
	if c is Panel or c is PanelContainer:
		var sb := c.get_theme_stylebox("panel")
		return sb is StyleBoxFlat and (sb as StyleBoxFlat).bg_color.a > 0.6
	return false

static func _text(c: Control) -> String:
	if c is RichTextLabel:
		return (c as RichTextLabel).get_parsed_text()
	return str(c.get("text"))

static func font_size(c: Control) -> int:
	if c is RichTextLabel:
		return c.get_theme_font_size("normal_font_size")
	return c.get_theme_font_size("font_size")

## Where the words are drawn (the box, less a button's margins), in screen pixels.
static func text_rect(c: Control) -> Rect2:
	var r := c.get_global_rect()
	if c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF and not (c as Label).clip_text:
		var l := c as Label
		var w := l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size(l)).x
		w = minf(w, r.size.x) if l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING else w
		var x := r.position.x
		match l.horizontal_alignment:
			HORIZONTAL_ALIGNMENT_CENTER:
				x += (r.size.x - w) * 0.5
			HORIZONTAL_ALIGNMENT_RIGHT:
				x += r.size.x - w
		return Rect2(x, r.position.y, w, r.size.y)
	return r

## "" when the text fits its box, else what spills: words past the right edge, or lines past the bottom.
static func overflow(c: Control) -> String:
	if c is Label:
		var l := c as Label
		if l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			return ""  # trimmed with an ellipsis on purpose
		var f := l.get_theme_font("font")
		var fs := font_size(l)
		if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var widest := 0.0
			for line in l.text.split("\n"):
				widest = maxf(widest, f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
			if widest > l.size.x + SLACK:
				return "text %d px wide in a %d px box" % [widest, l.size.x]
		elif l.get_visible_line_count() < l.get_line_count():
			return "%d of %d lines show" % [l.get_visible_line_count(), l.get_line_count()]
		return ""
	if c is RichTextLabel:
		var r := c as RichTextLabel
		if not r.scroll_active and not r.fit_content and r.get_content_height() > r.size.y + SLACK:
			return "text %d px tall in a %d px box" % [r.get_content_height(), r.size.y]
		return ""
	if c is Button:
		var b := c as Button
		if b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING or b.autowrap_mode != TextServer.AUTOWRAP_OFF:
			return ""
		var inner := b.size.x - b.get_theme_stylebox("normal").get_minimum_size().x
		var tw := b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size(b)).x
		if b.icon:
			inner -= b.icon.get_width() + b.get_theme_constant("h_separation")
		if tw > inner + SLACK:
			return "text %d px wide in a %d px button" % [tw, inner]
	return ""

static func _name(c: Control) -> String:
	var s := str(c.get_path()).replace("/root/", "")
	if s.length() > 60:
		s = "..." + s.right(57)
	var t := _text(c).replace("\n", " / ")
	if t != "":
		s += " '%s'" % t.left(30)
	return s
