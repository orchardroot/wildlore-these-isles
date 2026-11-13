class_name ContractsTab
extends RefCounted
## The Journal's Contracts tab (the list is the quest log's own, see quests_screen.gd): for one contract, who posted
## it and what it pays, then what you have worked out (the working theory, its types and what to bring), each lead
## followed and the ones still to find, and, once you have decided, what you did and the real story behind it.
## Only what the clues justify is shown. See Contracts.

static func _words(detail: VBoxContainer, text: String, size := 21, colour := UIKit.CREAM) -> Label:
	var l := UIKit.label(text, size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(l)
	return l

static func _place(zone: String) -> String:
	var idx := ZoneIndex.get_index()
	var z := Quests.map_zone(zone, idx)
	return str(idx.zones.get(z, {}).get("name", z.capitalize()))

static func empty(detail: VBoxContainer) -> void:
	detail.add_child(UIKit.label("Contracts", 30, UIKit.GOLD))
	_words(detail, "A named person with a real problem pins a contract on a town's notice board, over the odd jobs. Take it, look into it, work out what it is, face it, and decide what to do. What you decide stays decided.", 22)

static func describe(detail: VBoxContainer, c: Dictionary) -> void:
	var d: GameStateData = Game.data
	var id := str(c.id)
	var st := Contracts.state(d, id)
	var t := UIKit.label(str(c.title), 34)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(t)
	_words(detail, "%s, %s. %s." % [str(c.poster.name), _place(str(c.town)), str(c.poster.role)], 20, UIKit.MUTED)
	var status := "Taken. Fee agreed: %s." % Purse.text(Contracts.fee(d, id))
	if st == Contracts.DECIDED:
		status = "Decided. Go and tell %s." % str(c.poster.name)
	elif st >= Contracts.CLOSED:
		status = "Closed."
	_words(detail, status, 22, UIKit.GOLD)
	detail.add_child(UIKit.spacer(2))
	detail.add_child(UIKit.label("What you know", 24, UIKit.MUTED))
	_words(detail, ContractTalk.theory_line(d, c), 22)
	var th := Contracts.theory(d, c)
	if not th.lead.is_empty() and th.sure:
		var h := Contracts.hypothesis(c, str(th.lead[0]))
		_words(detail, "Its kind: %s. Weak to: %s." % [" and ".join((h.types as Array).map(func(x): return str(x).capitalize())), ", ".join(Contracts.weak_to(h.types).map(func(x): return str(x).capitalize()))], 20, UIKit.MUTED)
	for h in c.hypotheses:
		var out: bool = str(h.id) in th.out
		_words(detail, "%s%s" % [str(h.name), " (ruled out)" if out else ""], 20, UIKit.MUTED if out else UIKit.CREAM)
	detail.add_child(UIKit.spacer(2))
	detail.add_child(UIKit.label("Leads", 24, UIKit.MUTED))
	for k in c.clues:
		if Contracts.clue_found(d, id, str(k.id)):
			_words(detail, Contracts.clue_text(k), 20)
		else:
			_words(detail, "Still to find: %s (%s)" % [str(k.hint), _place(str(k.zone))], 20, UIKit.MUTED)
	if st >= Contracts.DECIDED:
		var ch := Contracts.ending(d, c)
		detail.add_child(UIKit.spacer(2))
		detail.add_child(UIKit.label("What you did", 24, UIKit.MUTED))
		_words(detail, str(ch.journal), 21)
		detail.add_child(UIKit.label("The real story", 24, UIKit.MUTED))
		_words(detail, str(c.real), 20, UIKit.GOLD)
	else:
		_words(detail, "Where: %s." % _place(str(c.lair.zone)), 20, UIKit.MUTED)
	var rep := []
	for g in Contracts.GROUPS:
		var r := Contracts.repute(d, str(g))
		if r != 0:
			rep.append("%s %s%d" % [str(Contracts.GROUPS[g]), "+" if r > 0 else "", r])
	if not rep.is_empty():
		detail.add_child(UIKit.spacer(2))
		_words(detail, "How people see you: " + ", ".join(rep) + ".", 19, UIKit.MUTED)
