class_name WordsTab
extends RefCounted
## The Fieldbook's "Words of the Isles" tab (after the Stud Book, once a local word has been met): one row per
## language, then in the detail panel each word met and what it means (see Langs). Same shape as CasebookTab.

static func _zone_names() -> Dictionary:
	var out := {}
	var zs: Dictionary = ZoneIndex.get_index().zones
	for zid in zs:
		out[zid] = str(zs[zid].name)
	return out

static func _glossary() -> Array:
	return Langs.glossary(Game.data, _zone_names())

static func ids() -> Array:
	return _glossary().map(func(g): return str(g.code))

static func visible(data: GameStateData) -> bool:
	return not Langs.glossary(data, {}).is_empty()

static func row(id: String, h: HBoxContainer) -> void:
	h.add_child(UIKit.chip(id.to_upper(), UIKit.HEATHER.darkened(0.25), UIKit.CREAM, 16))
	h.add_child(UIKit.label(str(Langs.NAMES.get(id, id)), 26, UIKit.CREAM))

static func show(id: String, detail: VBoxContainer) -> void:
	UIKit.clear(detail)
	for g in _glossary():
		if str(g.code) != id:
			continue
		var e := LangLessons.endonym(id)
		detail.add_child(UIKit.label(str(g.language) + ((" · " + e) if e != "" else ""), 34, UIKit.GOLD))
		var met: Array = g.rows
		var intro := UIKit.label("%d words met. Where there's a local name, you'll see it on the town banner and the signs." % met.size(), 20, UIKit.MUTED)
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # wraps rather than widen the panel
		intro.custom_minimum_size = Vector2(300, 0)
		detail.add_child(intro)
		_lessons(id, detail)
		detail.add_child(UIKit.spacer(4))
		var rows := VBoxContainer.new()
		rows.add_theme_constant_override("separation", 2)
		for w in met:
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 12)
			line.add_child(UIKit.label(str(w.word), 24, Langs.LOCAL_INK))
			line.add_child(UIKit.label(str(w.meaning), 20, UIKit.MUTED))
			if str(w.get("say", "")) != "":
				line.add_child(UIKit.label("say " + str(w.say), 16, Color("b9c7e6")))
			rows.add_child(line)
		var sc := ScrollContainer.new()  # a long list scrolls rather than run off the panel; Confirm reads on down it
		sc.name = "WordsScroll"
		sc.set_meta("pages", true)
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.add_child(rows)
		detail.add_child(sc)

## Lessons, certificates and revision for a language that has teachers (4.5, LangLessons).
static func _lessons(id: String, detail: VBoxContainer) -> void:
	var all := LangLessons.lessons(id)
	if all.is_empty():
		return
	var d: GameStateData = Game.data
	var certs := LangLessons.certs(d, id).map(func(lv): return "level %d" % lv)
	var line := "Lessons %d of %d%s" % [LangLessons.lessons_done(d, id), all.size(), (". Certificates: " + ", ".join(certs)) if not certs.is_empty() else ""]
	detail.add_child(UIKit.label(line, 20, UIKit.CREAM))
	if not LangLessons.learnt_words(d, id).is_empty():
		var due := LangLessons.due_count(d, id)
		detail.add_child(UIKit.label(("%d word%s due for revision. Press confirm to revise." % [due, "" if due == 1 else "s"]) if due > 0
			else "Nothing due. Press confirm for a little practice.", 18, UIKit.GOLD))
	else:
		var nxt := LangLessons.next_anywhere(d, id)
		if not nxt.is_empty():
			detail.add_child(UIKit.label("A teacher, %s, gives the first lesson." % str(nxt.teacher.name), 18, UIKit.MUTED))
	for a in LangLessons.about(id).slice(0, 2):
		var l := UIKit.label(str(a), 18, Color("d8cfb4"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(300, 0)
		detail.add_child(l)

## Confirm on a language row: a revision round, once there are words learnt.
static func can_revise(id: String) -> bool:
	return not LangLessons.learnt_words(Game.data, id).is_empty()
