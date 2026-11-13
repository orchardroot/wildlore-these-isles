class_name TypeRows
extends RefCounted
## "Weak to", "Resists" and "No effect from" for a creature's types, as rows of type chips: the Fieldbook species page
## and the Summary share it. A double weakness or resistance carries its "x4" or "x1/4" after the chip. Rows with
## nothing in them are left out. Types come from TypeChart (weak_to, resists, immune), so it always matches battle.

const LABELS := {"weak": "Weak to", "resists": "Resists", "immune": "No effect from"}

## The rows for `types`, as [{"key", "label", "items": [{"type", "mult"}]}], empty ones left out.
static func rows_for(types: Array, chart: TypeChart) -> Array:
	var out := []
	for pair in [["weak", chart.weak_to(types)], ["resists", chart.resists(types)], ["immune", chart.immune(types)]]:
		if not pair[1].is_empty():
			out.append({"key": pair[0], "label": LABELS[pair[0]], "items": pair[1]})
	return out

## A square chip that is only the type's shape on its colour (the name in its tooltip), for a crowded page.
static func glyph_chip(t: String, px := 24) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = TypeColours.colour(t)
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(TypeGlyph.make(t, TypeColours.text_colour(t), px - 8))
	p.tooltip_text = t.capitalize()
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p

## Adds one flowing line per row to `parent`: the label, then a chip per type. `chip_px` is the chip's text size.
## Returns the rows added.
static func add_rows(parent: Control, types: Array, chart: TypeChart, chip_px := 17, label_px := 18, label_colour := Color("a9a294"), glyphs_only := false) -> Array:
	var rows := rows_for(types, chart)
	for r in rows:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 3)
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := UIKit.label(str(r.label), label_px, label_colour)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		flow.add_child(l)
		for it in r.items:
			flow.add_child(glyph_chip(str(it.type), chip_px) if glyphs_only else UIKit.type_chip(str(it.type), chip_px))
			if float(it.mult) >= 4.0 or (float(it.mult) > 0.0 and float(it.mult) <= 0.25):
				var x := UIKit.label(TypeChart.mult_words(float(it.mult)), label_px, label_colour)
				x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				flow.add_child(x)
		parent.add_child(flow)
	return rows
