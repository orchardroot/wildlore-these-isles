extends RefCounted
## At the Largest Text size a screen's panels can come out taller or wider than the room a menu gives them. This
## steps the words under the content area down together (never below UIKit.MIN_TEXT) until what is built fits, and
## starts again from the full sizes whenever the content is rebuilt or resized. It does nothing at Normal or Large,
## and nothing to a screen that already fits. Labels that fit themselves (row_label, fit_width: they clip) and
## anything marked `set_meta("no_squeeze", true)` are left to their own fitting.

const STEPS := [0.92, 0.85, 0.78, 0.72, 0.67, 0.6]

## Called by MenuBase once its frame is built.
static func watch(menu: Control, content: Control) -> void:
	if not UIKit.largest():
		return
	var ref: WeakRef = weakref(content)
	var queue := func():
		var c := ref.get_ref() as Control
		if c == null or c.has_meta("squeeze_queued"):
			return
		c.set_meta("squeeze_queued", true)
		_run.call_deferred(ref)
	content.child_entered_tree.connect(func(_n: Node): queue.call())
	content.resized.connect(queue)
	queue.call()

static func _run(ref: WeakRef) -> void:
	var c := ref.get_ref() as Control
	if c == null or not c.is_inside_tree():
		return
	var tree := c.get_tree()
	await tree.process_frame
	await tree.process_frame
	c = ref.get_ref() as Control
	if c == null or not c.is_inside_tree():
		return
	c.remove_meta("squeeze_queued")
	var words := _words(c)
	for l in words:  # a size the screen has set since we last touched it is the new full size
		if not l.has_meta("sq_now") or l.get_theme_font_size("font_size") != int(l.get_meta("sq_now")):
			l.set_meta("sq_want", l.get_theme_font_size("font_size"))
	if not _overflows(c):
		return
	var from := 0
	for i in STEPS.size():  # a size change reaches a container's minimum size at once: pick the step that should fit
		_apply(words, STEPS[i])
		from = i
		if not _overflows(c, true):
			break
	for i in range(from, STEPS.size()):  # then check it against the real layout, a frame later, and go on if it is not enough
		await tree.process_frame
		c = ref.get_ref() as Control
		if c == null or not c.is_inside_tree() or not _overflows(c):
			return
		if i + 1 < STEPS.size():
			_apply(words, STEPS[i + 1])

static func _apply(words: Array, k: float) -> void:
	for l in words:
		if not is_instance_valid(l):
			continue
		var fs: int = maxi(UIKit.MIN_TEXT, roundi(int(l.get_meta("sq_want")) * k))
		l.add_theme_font_size_override("font_size", fs)
		l.set_meta("sq_now", fs)
		if l is Button and l.custom_minimum_size.y > 0:  # a button sized for the full text gives its height back too
			if not l.has_meta("sq_minh"):
				l.set_meta("sq_minh", l.custom_minimum_size.y)
			var was: float = l.get_meta("sq_minh")
			l.custom_minimum_size.y = minf(was, maxf(_inner_height(l) + 4.0, was * k))  # never taller than it was

## The tallest line of words inside a button (or its own text): the least height it can be given.
static func _inner_height(b: Button) -> float:
	var tall := b.get_theme_font("font").get_height(b.get_theme_font_size("font_size"))
	for l in b.find_children("*", "Label", true, false):
		tall = maxf(tall, l.get_theme_font("font").get_height(l.get_theme_font_size("font_size")))
	for ch in b.get_children():  # a row of stacked lines inside it
		if ch is Control:
			tall = maxf(tall, ch.get_combined_minimum_size().y)
	return tall

static func _words(root: Control) -> Array:
	var out: Array = []
	for n in root.find_children("*", "Control", true, false):
		if not (n is Label or n is Button or n is RichTextLabel):
			continue
		if n.has_meta("no_squeeze") or (n is Label and n.clip_text) or (n is Button and n.clip_text):
			continue
		if n is RichTextLabel:
			continue  # sized by theme overrides of its own; left alone
		out.append(n)
	return out

## True when something under `c` runs past it (a panel taller or wider than its room); `wanted` asks what the
## panels would like (their minimum size) rather than what they have been given.
static func _overflows(c: Control, wanted := false) -> bool:
	for k in c.get_children():
		if k is Control and k.visible and not k is ScrollContainer:
			var sz: Vector2 = k.get_combined_minimum_size() if wanted else k.size
			if sz.y > c.size.y + 1.0 or sz.x > c.size.x + 1.0:
				return true
	return false
