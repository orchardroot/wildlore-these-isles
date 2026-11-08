class_name StandingPanel
extends RefCounted
## The Stats page's right-hand card: where you stand with each of the six nations (tier and a bar to the next),
## then the jobs you're carrying. See Standing and Jobs.

static func build(d: GameStateData, dex: Dex) -> PanelContainer:
	var card := UIKit.panel(Color("1d2230f0"), 14)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	col.add_child(_heading("Standing"))
	var grid := GridContainer.new()  # the nations two abreast, so the jobs below keep their room
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 48)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	for row in Standing.lines(d):
		var nation := VBoxContainer.new()
		nation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nation.add_theme_constant_override("separation", 4)
		var h := HBoxContainer.new()
		h.add_child(UIKit.label(str(row[0]), 24, UIKit.MUTED))
		h.add_child(UIKit.fill())
		h.add_child(UIKit.label(str(row[1]), 24, UIKit.GOLD if int(row[2]) >= Standing.TIER_POINTS[Standing.REGULAR] else UIKit.CREAM))
		nation.add_child(h)
		nation.add_child(_bar(int(row[2])))
		grid.add_child(nation)
	col.add_child(UIKit.spacer(8))
	var held := Jobs.active(d)
	col.add_child(_heading("Jobs in hand  (%d of %d)" % [held.size(), Jobs.SLOTS]))
	if held.is_empty():
		col.add_child(UIKit.label("None. Try a parish noticeboard.", 20, UIKit.MUTED))
	for line in Jobs.pause_lines(d, dex):
		var l := UIKit.label(str(line), 20)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # a long job wraps rather than lose its end
		col.add_child(l)
	return card

static func _heading(t: String) -> Label:
	var l := UIKit.label(t, 20, UIKit.MUTED)
	l.uppercase = true
	return l

## A thin bar from this tier to the next (full at Pillar of the Community).
static func _bar(pts: int) -> ProgressBar:
	var t := Standing.tier_for(pts)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	var lo: int = Standing.TIER_POINTS[t]
	var hi: int = Standing.TIER_POINTS[mini(t + 1, Standing.PILLAR)]
	bar.max_value = maxi(1, hi - lo)
	bar.value = bar.max_value if t >= Standing.PILLAR else pts - lo
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIKit.GOLD
	fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("2c3446")
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	return bar
