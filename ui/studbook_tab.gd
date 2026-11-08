class_name StudBookTab
extends RefCounted
## The Fieldbook's Stud Book tab (after Rumours): one row per idea about inheritance, locked ones greyed with a hint,
## then the Crosses log. The pedia screen owns the list and the focus; this builds the rows and the detail panel.
## Same shape as RumoursTab.

const EXAMPLES := {"coat": ["+c", "+c"], "tint": ["WD", "WD"], "mark": ["Bb", "Bb"], "knack": ["Kk", "Kk"]}

## Row ids: every idea, then "crosses".
static func ids() -> Array:
	var out := StudBook.IDEAS.map(func(i): return str(i.id))
	out.append("crosses")
	return out

## Show the tab once there is anything to put in it.
static func visible(data: GameStateData) -> bool:
	return StudBook.idea_count(data) > 0 or not StudBook.crosses_log(data).is_empty() or Breeding.baskets(data).size() > 0

static func row(id: String, h: HBoxContainer) -> void:
	if id == "crosses":
		h.add_child(UIKit.chip("LOG", UIKit.HEATHER.darkened(0.2), UIKit.CREAM, 18))
		h.add_child(UIKit.label("Crosses", 26, UIKit.CREAM))
		return
	var open := StudBook.unlocked(Game.data, id)
	h.add_child(UIKit.row_label(str(StudBook.idea(id).title), 26, UIKit.CREAM if open else UIKit.MUTED))
	if open:
		h.add_child(UIKit.chip("LEARNT", UIKit.GOLD.darkened(0.25), UIKit.SLATE, 16))

static func _words(detail: VBoxContainer, text: String, size := 22, colour := UIKit.CREAM) -> Label:
	var l := UIKit.label(text, size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(l)
	return l

static func show(id: String, detail: VBoxContainer) -> void:
	UIKit.clear(detail)
	var d: GameStateData = Game.data
	if id == "crosses":
		detail.add_child(UIKit.label("Crosses", 34, UIKit.GOLD))
		_words(detail, "What you expected, and what you got. A few hatchings prove nothing; a lot of them prove the odds.", 20, UIKit.MUTED)
		var lines := StudBook.tally_lines(d)
		if lines.is_empty():
			_words(detail, "Nothing hatched yet.", 22, UIKit.MUTED)
		for l in lines:
			_words(detail, str(l), 20)
		var log := StudBook.crosses_log(d)
		if not log.is_empty():
			detail.add_child(UIKit.spacer(8))
			detail.add_child(UIKit.label("Latest", 22, UIKit.MUTED))
			for l in log.slice(maxi(0, log.size() - 6)):
				_words(detail, str(l), 18, UIKit.MUTED)
		return
	var idea := StudBook.idea(id)
	detail.add_child(UIKit.label(str(idea.title), 34, UIKit.GOLD))
	if not StudBook.unlocked(d, id):
		_words(detail, str(idea.hint), 24, UIKit.MUTED)
		return
	for p in idea.text:
		_words(detail, str(p), 21)
	var ex: Array = EXAMPLES.get(str(idea.square), [])
	if ex.size() == 2:
		detail.add_child(UIKit.spacer(4))
		detail.add_child(UIKit.label("%s, %s x %s" % [PunnettView.locus_name(str(idea.square)), ex[0], ex[1]], 22, UIKit.GOLD))
		var dist := StudBook.expected(str(idea.square), ex[0], ex[1])
		var keys := dist.keys()
		keys.sort()
		for k in keys:
			_words(detail, "%s  %s: %s" % [k, PunnettView.outcome_word(str(idea.square), k), StudBook.odds_words(dist[k])], 20)
	var mine := StudBook.tally_lines(d).filter(func(l): return str(idea.square) != "" and str(l).begins_with(PunnettView.locus_name(str(idea.square))))
	for l in mine:
		_words(detail, "Yours: " + str(l), 18, UIKit.MUTED)
	detail.add_child(UIKit.spacer(4))
	_words(detail, str(idea.story), 19, Color("d8cfb4"))
