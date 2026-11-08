class_name TextFitAudit
extends RefCounted
## Dev check for words on screen: walks every visible Label, Button and RichTextLabel under a node and lists the ones
## a player would struggle to read. Run it over every menu with tools/dev/text_audit.gd; tests/ui/test_text_fit.gd
## keeps a handful of key screens clean.
## Kinds:
##   wide     one-line text wider than its own box, drawn over whatever is beside it
##   trimmed  text cut short by clip_text or an ellipsis (the player loses words)
##   lines    wrapped text with more lines than its box shows
##   cut      text partly outside the screen, or outside a clipping parent (a menu's content area, a scroll box sideways)
##   spills   text partly outside the panel it sits in
##   overlap  two pieces of text drawn over each other
##   under    a panel drawn over part of some text
##   small    font below MIN_FONT px at 1280x720
##   box      a framed panel running past the screen or its clip, so its border (and maybe its last lines) is cut
##   stuck    a scroll box with more words than it shows and nothing the keyboard can focus to scroll it

const MIN_FONT := 18
const SLACK := 2.0      # px of rounding and shadow we forgive
const OVERLAP := 4.0    # px both ways before two boxes count as overlapping

## Problems under `root` as dictionaries {path, kind, text, detail}; `screen` is the visible rect.
static func report(root: Node, screen: Rect2) -> Array:
	var texts: Array = []   # [control, ink rect, order, layer]
	var panels: Array = []  # [control, rect, order, layer]
	var out: Array = []
	_walk(root, screen, screen, 0, texts, panels, out, root)
	_overlaps(texts, panels, out, root)
	return out

## One readable line per problem, e.g. "PauseMenu/…/Label  wide  'Settings'  210 > 180".
static func line(p: Dictionary) -> String:
	return "%-7s %s  '%s'  %s" % [p.kind, p.path, p.text, p.detail]

static func _walk(n: Node, clip: Rect2, screen: Rect2, layer: int, texts: Array, panels: Array, out: Array, root: Node) -> void:
	if n is CanvasLayer:
		if not (n as CanvasLayer).visible:
			return
		layer = (n as CanvasLayer).layer
		clip = screen
	elif n is CanvasItem:
		var ci := n as CanvasItem
		if not ci.visible or ci.modulate.a < 0.05 or ci.self_modulate.a < 0.05 and not (n is Container):
			return
	elif n is Window or n is SubViewport:
		return
	if n is Control:
		var c := n as Control
		var r := c.get_global_rect()
		if _text_of(c) != "":
			_check_text(c, r, clip, screen, texts, layer, out, root)
		elif _opaque(c):
			panels.append([c, r.intersection(clip), texts.size() + panels.size(), layer])
			if _framed(c) and not _inside(r, clip) and r.intersects(clip):
				_add(out, c, root, "box", "%s past %s" % [_rs(r), _rs(clip)])
		if c.has_meta("rolls"):  # text that moves through its box on purpose (the credits): judged like a scroll box
			for ch in c.get_children():
				_walk_scrolled(ch, clip, Rect2(clip.position.x, -1e6, clip.size.x, 2e6), screen, layer, texts, panels, out, root)
			return
		if c.clip_contents or c is ScrollContainer:
			if c is ScrollContainer:
				var sc := c as ScrollContainer
				var inner := r
				# a box that scrolls one way may run on that way: only its other edges clip for real
				if sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
					inner = Rect2(inner.position.x, -1e6, inner.size.x, 2e6)
				if sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
					inner = Rect2(-1e6, inner.position.y, 2e6, inner.size.y)
				for ch in sc.get_children():
					_walk_scrolled(ch, clip.intersection(r), inner, screen, layer, texts, panels, out, root)
					if ch is Control and (ch as Control).size.y > r.size.y + SLACK and not _keys_reach(sc):
						_add(out, ch, root, "stuck", "%d px of words in a %d px box only a mouse can scroll" % [ch.size.y, r.size.y])
				return
			clip = clip.intersection(r)
	for ch in n.get_children():
		_walk(ch, clip, screen, layer, texts, panels, out, root)

## Inside a scroll box: what is scrolled out of view is fine (it scrolls), but nothing may stick out the edges that
## don't scroll. `seen` is what is on screen now; `bounds` the box's non-scrolling edges.
static func _walk_scrolled(n: Node, seen: Rect2, bounds: Rect2, screen: Rect2, layer: int, texts: Array, panels: Array, out: Array, root: Node) -> void:
	if n is CanvasItem and (not (n as CanvasItem).visible or (n as CanvasItem).modulate.a < 0.05):
		return
	if n is Control:
		var c := n as Control
		var r := c.get_global_rect()
		if _text_of(c) != "":
			var ink := _ink(c, r)
			if not _inside(ink, bounds):
				_add(out, c, root, "cut", "sideways out of its scroll box (%s in %s)" % [_rs(ink), _rs(bounds)])
			if ink.intersects(seen):
				_check_text(c, r, Rect2(-1e6, -1e6, 2e6, 2e6), screen, texts, layer, out, root, seen)
		elif _opaque(c) and r.intersects(seen):
			panels.append([c, r.intersection(seen), texts.size() + panels.size(), layer])
			if _framed(c) and not _inside(r, bounds):
				_add(out, c, root, "box", "sideways out of its scroll box (%s in %s)" % [_rs(r), _rs(bounds)])
		if c.clip_contents and not c is ScrollContainer:
			bounds = bounds.intersection(r)
			seen = seen.intersection(r)
	for ch in n.get_children():
		_walk_scrolled(ch, seen, bounds, screen, layer, texts, panels, out, root)

static func _check_text(c: Control, r: Rect2, clip: Rect2, screen: Rect2, texts: Array, layer: int, out: Array, root: Node, seen := Rect2()) -> void:
	var fs := _font_size(c)
	if fs < MIN_FONT:
		_add(out, c, root, "small", "%d px" % fs)
	var need := _need(c, r)  # [width the text wants, lines it has, lines it shows]
	if c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF or c is Button:
		if need[0] > r.size.x + SLACK:
			var trims: bool = c.clip_text or c.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
			_add(out, c, root, "trimmed" if trims else "wide", "%d > %d px" % [need[0], r.size.x])
	if need[1] > need[2]:
		_add(out, c, root, "lines", "%d lines, shows %d" % [need[1], need[2]])
	var ink := _ink(c, r)
	if not _inside(ink, screen):
		_add(out, c, root, "cut", "off screen (%s)" % _rs(ink))
	elif not _inside(ink, clip):
		_add(out, c, root, "cut", "outside its clip (%s in %s)" % [_rs(ink), _rs(clip)])
	else:
		var p := _panel_of(c)
		if p != null and not _inside(ink, p.get_global_rect()):
			_add(out, c, root, "spills", "out of %s (%s in %s)" % [p.name, _rs(ink), _rs(p.get_global_rect())])
	texts.append([c, ink.intersection(seen) if seen.has_area() else ink, texts.size(), layer])

## [width the text wants on one line, lines it has, lines its box shows].
static func _need(c: Control, r: Rect2) -> Array:
	if c is Label:
		var l := c as Label
		var f := l.get_theme_font("font")
		var fs := l.get_theme_font_size("font_size")
		var w := 0.0
		for s in _text_of(l).split("\n"):
			w = maxf(w, f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		var lines := l.get_line_count()
		var shows := l.get_visible_line_count()
		if l.max_lines_visible >= 0:
			shows = mini(shows, l.max_lines_visible)
		return [w + _sb_w(l, "normal"), lines, shows]
	if c is Button:
		var b := c as Button
		var f := b.get_theme_font("font")
		var w := f.get_string_size(_text_of(b), HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		w += _sb_w(b, "normal")
		if b.icon != null and not b.expand_icon:
			w += b.icon.get_width() + b.get_theme_constant("h_separation")
		return [w, 1, 1]
	if c is RichTextLabel:
		var t := c as RichTextLabel
		if t.scroll_active or t.fit_content:
			return [0.0, 0, 0]
		var all := t.get_content_height()
		return [0.0, 1 if all <= r.size.y + SLACK else 2, 1]
	return [0.0, 0, 0]

static func _sb_w(c: Control, sb: String) -> float:
	var s := c.get_theme_stylebox(sb)
	return s.get_margin(SIDE_LEFT) + s.get_margin(SIDE_RIGHT) if s != null else 0.0

## Where the letters really are inside the box (a wide label with short text only inks its start).
static func _ink(c: Control, r: Rect2) -> Rect2:
	var fs := _font_size(c)
	var f := c.get_theme_font("normal_font" if c is RichTextLabel else "font")
	if c is RichTextLabel:
		return Rect2(r.position, Vector2(r.size.x, minf(r.size.y, (c as RichTextLabel).get_content_height())))
	var w := 0.0
	var lines := 1
	if c is Label and (c as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
		w = r.size.x
		lines = (c as Label).get_visible_line_count()
	else:
		var parts := _text_of(c).split("\n")
		lines = parts.size()
		for s in parts:
			w = maxf(w, f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		if c is Button:
			w += _sb_w(c, "normal")
	var h := lines * f.get_height(fs) + maxi(0, lines - 1) * c.get_theme_constant("line_spacing")
	if c is Button:
		h = r.size.y
	var x := r.position.x
	var align: int = HORIZONTAL_ALIGNMENT_LEFT
	if c is Label:
		align = (c as Label).horizontal_alignment
	elif c is Button:
		align = (c as Button).alignment
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x += (r.size.x - w) / 2.0
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x += r.size.x - w
	var y := r.position.y
	if c is Label:
		match (c as Label).vertical_alignment:
			VERTICAL_ALIGNMENT_CENTER:
				y += (r.size.y - h) / 2.0
			VERTICAL_ALIGNMENT_BOTTOM:
				y += r.size.y - h
	if (c is Label or c is Button) and (c.clip_text or c.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
		w = minf(w, r.size.x)
		x = maxf(x, r.position.x)
	return Rect2(x, y, w, minf(h, maxf(r.size.y, h)))

static func _overlaps(texts: Array, panels: Array, out: Array, root: Node) -> void:
	for i in texts.size():
		var a: Control = texts[i][0]
		var ra: Rect2 = texts[i][1]
		for j in range(i + 1, texts.size()):
			var b: Control = texts[j][0]
			if texts[j][3] != texts[i][3] or a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			if a.get_parent() == b.get_parent() and a.get_parent() is Container:
				continue  # laid out side by side: only the ink could touch, never the boxes
			if a.rotation != 0.0 or b.rotation != 0.0:
				continue  # hand-set lettering at a slant (a postcard's "Greetings from"): placed to touch
			var x := ra.intersection(texts[j][1])
			if x.size.x > OVERLAP and x.size.y > OVERLAP and not _covered(a, ra, texts[i][2], panels, texts[i][3]):
				_add(out, b, root, "overlap", "over %s (%s)" % [_short(a, root), _rs(x)])
		for p in panels:
			if p[3] < texts[i][3] or (p[3] == texts[i][3] and p[2] <= texts[i][2]):
				continue  # drawn first: it's behind
			var pc: Control = p[0]
			if pc.is_ancestor_of(a) or a.is_ancestor_of(pc):
				continue
			var x: Rect2 = ra.intersection(p[1])
			if x.size.x > OVERLAP and x.size.y > OVERLAP and not p[1].encloses(ra):
				_add(out, a, root, "under", "%s covers %s" % [_short(pc, root), _rs(x)])

## True if a later panel hides all of `r` (a popup open over a list: the list is meant to be hidden).
static func _covered(c: Control, r: Rect2, order: int, panels: Array, layer: int) -> bool:
	for p in panels:
		if (p[3] > layer or p[3] == layer and p[2] > order) and p[1].encloses(r) and not (p[0] as Control).is_ancestor_of(c):
			return true
	return false

## Panels and blocks of colour that hide what is under them.
static func _opaque(c: Control) -> bool:
	if c is PanelContainer or c is Panel:
		var sb := c.get_theme_stylebox("panel")
		return sb is StyleBoxFlat and (sb as StyleBoxFlat).bg_color.a > 0.6 or sb is StyleBoxTexture
	if c is ColorRect:
		return (c as ColorRect).color.a > 0.6 and c.get_global_rect().get_area() < 1280 * 600
	return false

## True if the keyboard can move through a scroll box: it takes focus itself, or something inside it does.
static func _keys_reach(sc: ScrollContainer) -> bool:
	if sc.focus_mode != Control.FOCUS_NONE or sc.has_meta("pages"):  # "pages": the screen scrolls it on a key itself
		return true
	for c in sc.find_children("*", "Control", true, false):
		if (c as Control).focus_mode != Control.FOCUS_NONE and (c as Control).is_visible_in_tree():
			return true
	return false

## A panel with a visible border: cutting it off shows.
static func _framed(c: Control) -> bool:
	var sb := c.get_theme_stylebox("panel")
	return sb is StyleBoxFlat and (sb as StyleBoxFlat).border_width_bottom > 0 and (sb as StyleBoxFlat).border_color.a > 0.3

## The nearest panel holding `c`, if any, whose edges the text should keep inside.
static func _panel_of(c: Control) -> Control:
	var p := c.get_parent()
	while p != null and p is Control:
		if p is ScrollContainer:
			return null
		if (p is PanelContainer or p is Panel) and _opaque(p):
			return p
		p = p.get_parent()
	return null

static func _text_of(c: Control) -> String:
	var t := ""
	if c is Label:
		t = (c as Label).text
		if (c as Label).uppercase:
			t = t.to_upper()
	elif c is Button:
		t = (c as Button).text
	elif c is RichTextLabel:
		t = (c as RichTextLabel).get_parsed_text()
	return t.strip_edges()

static func _font_size(c: Control) -> int:
	return c.get_theme_font_size("normal_font_size" if c is RichTextLabel else "font_size")

static func _inside(r: Rect2, b: Rect2) -> bool:
	return r.position.x >= b.position.x - SLACK and r.position.y >= b.position.y - SLACK \
		and r.end.x <= b.end.x + SLACK and r.end.y <= b.end.y + SLACK

static func _add(out: Array, c: Control, root: Node, kind: String, detail: String) -> void:
	var t := _text_of(c)
	if t == "":  # a panel: name it by the first words inside
		for l in c.find_children("*", "Label", true, false):
			t = _text_of(l)
			if t != "":
				break
	out.append({"path": _short(c, root), "kind": kind, "text": t.replace("\n", " / ").left(40), "detail": detail})

static func _short(c: Node, root: Node) -> String:
	var s := str(root.get_path_to(c)) if root.is_ancestor_of(c) else str(c.get_path())
	s = s.replace("@", "")
	if s.length() > 80:
		s = "…" + s.right(79)
	return s

static func _rs(r: Rect2) -> String:
	return "%d,%d %dx%d" % [r.position.x, r.position.y, r.size.x, r.size.y]
