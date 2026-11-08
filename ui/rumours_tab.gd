class_name RumoursTab
extends RefCounted
## The Fieldbook's Rumours tab (the filter after Seen): a "Region stamps" row, then one row of local gossip per
## creature not yet caught that lives in reach, nearest first (see Rumours). The pedia screen owns the list and
## the focus; this builds the rows and fills the detail panel.

## [{species ("" for the stamps row), ...rumour}] for the current game, stamps first.
static func entries() -> Array:
	var info := {}
	for id in Game.dex.ids():
		info[id] = Game.dex.get_species(id)
	var out: Array = [{"species": ""}]
	out.append_array(Rumours.build(Game.data, ZoneIndex.get_index(), info, Game.data.zone_id))
	return out

## The list row's inside: a silhouette (or the icon once seen), "???" or the name, and the place.
static func row(r: Dictionary, h: HBoxContainer) -> void:
	if str(r.species) == "":
		var done := FieldbookGoals.complete_regions(Game.data, ZoneIndex.get_index()).size()
		var st := UIKit.chip("STAMPS", UIKit.GOLD.darkened(0.25), UIKit.SLATE, 18)
		st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(st)
		h.add_child(UIKit.label("Region stamps", 28, UIKit.GOLD))
		h.add_child(UIKit.fill())
		h.add_child(UIKit.label("%d of %d" % [done, FieldbookGoals.region_progress(Game.data, ZoneIndex.get_index()).size()], 22, UIKit.MUTED))
		return
	var ic := AnimSprite.new()
	ic.show_species(str(r.species), "icon", 1, true)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var nm := str(Game.dex.get_species(str(r.species)).get("name", "")) if r.seen else "???"
	h.add_child(UIKit.label(nm, 26, UIKit.CREAM if r.seen else UIKit.MUTED))
	var pl := UIKit.label(str(r.place), 19, Color("d8cfb4"))
	pl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.custom_minimum_size = Vector2(60, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pl)

## The detail panel for a row.
static func show(r: Dictionary, detail: VBoxContainer) -> void:
	UIKit.clear(detail)
	if str(r.species) == "":
		_stamps(detail)
		return
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	detail.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(Color("2c3446"), Color("4a4f5e"), 2, 8, 6))
	top.add_child(frame)
	var s := AnimSprite.new()
	s.show_species(str(r.species), "front", 2, true)
	frame.add_child(s)
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 8)
	top.add_child(info)
	info.add_child(UIKit.label("Heard locally", 22, UIKit.MUTED))
	info.add_child(UIKit.label(str(Game.dex.get_species(str(r.species)).get("name", "")) if r.seen else "Something unknown", 36))
	var where := UIKit.label("%s, %s" % [r.place, FieldbookGoals.region_name(str(r.region))], 22, Color("d8cfb4"))
	where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	where.custom_minimum_size = Vector2(300, 0)
	info.add_child(where)
	detail.add_child(UIKit.spacer(6))
	var quote := PanelContainer.new()
	quote.add_theme_stylebox_override("panel", UIKit.box(Color("2a2f3d"), UIKit.HEATHER.darkened(0.2), 2, 10, 16))
	detail.add_child(quote)
	var t := UIKit.label(str(r.text), 26)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.add_child(t)
	var foot := UIKit.label("Rumours come from the places you've been and the ones just over the hill. Nearest first.", 20, UIKit.MUTED)
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(foot)

## One stamp per region: gold and "COMPLETE" once every creature found there is caught.
static func _stamps(detail: VBoxContainer) -> void:
	detail.add_child(UIKit.label("Region stamps", 34, UIKit.GOLD))
	var how := UIKit.label("Catch everything found in a region for its stamp. %s to scroll through them." % UIKit.key_for("confirm"), 21, UIKit.MUTED)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(how)
	var sc := ScrollContainer.new()  # fifty-odd regions don't fit: Confirm on the stamps row moves in here to scroll
	sc.name = "StampScroll"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.set_meta("pages", true)  # the pedia screen hands it the keys (UIKit.key_scroll); TextFitAudit counts that as reachable
	detail.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	sc.add_child(grid)
	for p in FieldbookGoals.region_progress(Game.data, ZoneIndex.get_index()):
		var done: bool = p.complete
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UIKit.box(Color("3a3222") if done else Color("262b38"),
			UIKit.GOLD if done else Color("4a4f5e"), 2 if done else 1, 6, 5))
		grid.add_child(card)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		card.add_child(h)
		var nl := UIKit.label(str(p.name), 19, UIKit.GOLD if done else UIKit.CREAM)
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.custom_minimum_size = Vector2(120, 0)
		h.add_child(nl)
		if done:
			h.add_child(UIKit.chip("COMPLETE", UIKit.GOLD.darkened(0.15), UIKit.SLATE, 15))
		else:
			h.add_child(UIKit.label("%d / %d" % [p.caught, p.total], 18, UIKit.MUTED))
