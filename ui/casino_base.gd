class_name CasinoBase
extends MenuBase
## Shared frame for the Palace's tables and the bookies: the chips/purse/limit read-out in the header, a stake
## picker, a felt backdrop, the big win/lose banner, and settle() which pays out through Punt and saves at once
## (the result was fixed when the stake went down; saving as soon as it's settled makes reloading pointless).

const FELT := Color("1f4a34")
const FELT_DARK := Color("143223")
const BRASS := Color("d8b04a")
const CLARET := Color("8a1f2c")
const WIN := Color("8fd19e")
const LOSE := Color("e08a8a")
const SERIF := "res://art/fonts/libre_baskerville/LibreBaskerville.ttf"
const HAND := "res://art/fonts/caveat/Caveat.ttf"

var with_chips := true       # casino games stake chips; the bookies stake the purse
var stakes: Array = [5, 10, 25, 50, 100]
var stake_i := 1
var _stake_label: Label
var _banner: Label
var _dev := false

static func serif(size: int, colour := UIKit.CREAM, text := "") -> Label:
	var l := UIKit.label(text, size, colour)
	if ResourceLoader.exists(SERIF):
		l.add_theme_font_override("font", load(SERIF))
	return l

static func hand(size: int, colour := UIKit.CREAM, text := "") -> Label:
	var l := UIKit.label(text, size, colour)
	if ResourceLoader.exists(HAND):
		l.add_theme_font_override("font", load(HAND))
	return l

## A rounded felt (or any colour) table panel with a brass rim.
static func felt_panel(bg := FELT, rim := BRASS, margin := 16) -> PanelContainer:
	var p := PanelContainer.new()
	var s := UIKit.box(bg, rim.darkened(0.15), 3, 18, margin)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	s.anti_aliasing = true
	p.add_theme_stylebox_override("panel", s)
	return p

func _ready() -> void:
	super._ready()
	_banner = serif(54, UIKit.GOLD)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 0.9))
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	refresh_header()
	var odds := Economist.odds_line(str(get_script().resource_path).get_file().get_basename())
	if odds != "":
		show_tip.call_deferred(odds)  # the real odds, every visit (the Economist's notebook has the sums)

func refresh_header() -> void:
	if header_right == null:
		return
	var d := Game.data
	var parts := []
	if with_chips:
		parts.append("Chips " + Purse.text(Punt.chips(d)))
	parts.append("Purse " + Purse.text(Purse.balance(d)))
	parts.append("Today's limit " + Purse.text(Punt.left_today(d)) + " left")
	header_right.text = "   ".join(parts)

## A side column of words and buttons that steps its words down together (UIKit.fit_column) if it is taller than the
## table's room: with Large text. Call once it is built.
func fit_side(side: VBoxContainer) -> void:
	await get_tree().process_frame
	if is_instance_valid(side):
		UIKit.fit_column(side, content.size.y)

## What's available to stake: chips or the purse.
func funds() -> int:
	return Punt.chips(Game.data) if with_chips else Purse.balance(Game.data)

func stake() -> int:
	return int(stakes[stake_i])

## A "Stake  < £10 >" picker. Left/right (or the buttons) change it.
func stake_picker() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIKit.label("Stake", 24, UIKit.MUTED))
	var lb := UIKit.pill_button("<", 24)
	lb.focus_mode = Control.FOCUS_NONE
	lb.pressed.connect(func(): change_stake(-1))
	row.add_child(lb)
	_stake_label = serif(30, UIKit.GOLD)
	_stake_label.custom_minimum_size = Vector2(110, 0)
	_stake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_stake_label)
	var rb := UIKit.pill_button(">", 24)
	rb.focus_mode = Control.FOCUS_NONE
	rb.pressed.connect(func(): change_stake(1))
	row.add_child(rb)
	_show_stake()
	return row

func change_stake(dir: int) -> void:
	var j := clampi(stake_i + dir, 0, stakes.size() - 1)
	if j != stake_i:
		stake_i = j
		Audio.sfx("cursor")
		_show_stake()

func _show_stake() -> void:
	if _stake_label:
		_stake_label.text = Purse.text(stake())
		_stake_label.pivot_offset = _stake_label.size * 0.5
		var tw := create_tween()
		_stake_label.scale = Vector2(1.15, 1.15)
		tw.tween_property(_stake_label, "scale", Vector2.ONE, 0.12)

## Why a stake can't go down right now ("" if it can).
func why_not(amount: int) -> String:
	var d := Game.data
	if amount > Punt.left_today(d):
		return "That's over today's limit. The house likes you solvent. Come back tomorrow."
	if amount > funds():
		return ("Not enough chips. The cage will sort you out." if with_chips else "Not enough in your purse for that.")
	return ""

## Takes a stake; false (and a word from the house) if it can't.
func take_stake(amount: int) -> bool:
	var why := why_not(amount)
	if why != "":
		Audio.sfx("bump")
		banner(why, LOSE, 26)
		return false
	Punt.stake(Game.data, amount, with_chips)
	commit()
	refresh_header()
	return true

## Pays a settled bet and saves straight away. Shows the result banner. Returns the net.
func settle(staked: int, returned: int, label := "") -> int:
	var r := Punt.settle(Game.data, staked, returned, with_chips)
	if Economist.note(Game.data, "house_edge"):
		econ_tip()
	commit()
	refresh_header()
	var net := int(r.net)
	if returned > staked:
		Audio.sfx("level_up" if net >= Punt.BIG_WIN else "heal")
		banner(label if label != "" else "You win " + Purse.text(returned) + "!", UIKit.GOLD, 54 if net >= Punt.BIG_WIN else 46)
	elif returned == staked and returned > 0:
		Audio.sfx("confirm")
		banner(label if label != "" else "Stake back", UIKit.CREAM, 40)
	else:
		Audio.sfx("bump")
		if label != "":
			banner(label, LOSE, 40)
	if not r.lines.is_empty():
		_announce(r.lines)
	return net

func _announce(lines: Array) -> void:
	for line in lines:
		await get_tree().create_timer(1.6).timeout
		if not is_inside_tree():
			return
		Audio.sfx("badge")
		banner(str(line), UIKit.GOLD, 26)

## Saves the game now (a no-op in dev sessions and tests, where autosave is off).
func commit() -> void:
	if not _dev:
		Game.autosave()

## A big centred line that pops in and fades away.
func banner(text: String, colour := UIKit.GOLD, size := 46) -> void:
	_banner.text = text
	_banner.add_theme_font_size_override("font_size", size)
	_banner.add_theme_color_override("font_color", colour)
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.size = Vector2(get_viewport_rect().size.x - 160, 200)
	_banner.position = (get_viewport_rect().size - _banner.size) * 0.5
	_banner.pivot_offset = _banner.size * 0.5
	_banner.scale = Vector2(0.7, 0.7)
	_banner.modulate.a = 1.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.25)
	tw.tween_interval(1.3 if size > 30 else 2.4)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)

func _input(event: InputEvent) -> void:
	if not _locked and not _done and event.is_action_pressed("ui_left") and _stake_label and _stake_label.is_visible_in_tree() and _uses_left_right():
		change_stake(-1)
		get_viewport().set_input_as_handled()
		return
	if not _locked and not _done and event.is_action_pressed("ui_right") and _stake_label and _stake_label.is_visible_in_tree() and _uses_left_right():
		change_stake(1)
		get_viewport().set_input_as_handled()
		return
	super._input(event)

## Override: false when left/right move focus instead of the stake.
func _uses_left_right() -> bool:
	return true

## A playing card: cream face with rank and suit, or a claret back with a gold lattice. For _draw callers.
static func draw_card(ci: CanvasItem, r: Rect2, card: Dictionary, face_up := true) -> void:
	var shadow := Rect2(r.position + Vector2(4, 5), r.size)
	ci.draw_rect(shadow, Color(0, 0, 0, 0.35))
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(r.size.x * 0.08))
	sb.anti_aliasing = true
	if not face_up:
		sb.bg_color = CLARET
		sb.border_color = Color("f2e8cf")
		sb.set_border_width_all(4)
		ci.draw_style_box(sb, r)
		var inner := r.grow(-12)
		for k in range(0, 12):
			var t := float(k) / 11.0
			ci.draw_line(inner.position + Vector2(inner.size.x * t, 0), inner.position + Vector2(0, inner.size.y * t), Color(BRASS, 0.5), 1.5)
			ci.draw_line(inner.end - Vector2(inner.size.x * t, 0), inner.end - Vector2(0, inner.size.y * t), Color(BRASS, 0.5), 1.5)
		return
	sb.bg_color = Color("fbf7ec")
	sb.border_color = Color("c9bfa6")
	sb.set_border_width_all(2)
	ci.draw_style_box(sb, r)
	var suit := int(card.get("suit", 0))
	var red := suit == 1 or suit == 2
	var col := Color("b0202c") if red else Color("1d2230")
	var rank := int(card.get("rank", 1))
	var txt: String = {1: "A", 11: "J", 12: "Q", 13: "K", 14: "A"}.get(rank, str(rank))
	var f: Font = load(SERIF) if ResourceLoader.exists(SERIF) else ThemeDB.fallback_font
	var fs := int(r.size.y * 0.2)
	ci.draw_string(f, r.position + Vector2(r.size.x * 0.08, fs * 1.05), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_suit(ci, r.position + Vector2(r.size.x * 0.08 + fs * 0.32, fs * 1.55), fs * 0.32, suit, col)
	draw_suit(ci, r.get_center() + Vector2(0, r.size.y * 0.06), r.size.x * 0.24, suit, col)
	if rank >= 11 and rank <= 13:
		var crown := r.get_center() + Vector2(0, -r.size.y * 0.2)
		var w := r.size.x * 0.18
		ci.draw_colored_polygon(PackedVector2Array([crown + Vector2(-w, w * 0.5), crown + Vector2(-w, -w * 0.3),
			crown + Vector2(-w * 0.5, w * 0.1), crown + Vector2(0, -w * 0.5), crown + Vector2(w * 0.5, w * 0.1),
			crown + Vector2(w, -w * 0.3), crown + Vector2(w, w * 0.5)]), BRASS)
	ci.draw_string(f, r.end - Vector2(r.size.x * 0.08 + fs * 0.7, r.size.y * 0.06), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

## Spades, hearts, diamonds, clubs as little polygons, centred on `c`, roughly `s` across.
static func draw_suit(ci: CanvasItem, c: Vector2, s: float, suit: int, col: Color) -> void:
	match suit:
		1:  # heart
			ci.draw_circle(c + Vector2(-s * 0.48, -s * 0.2), s * 0.5, col)
			ci.draw_circle(c + Vector2(s * 0.48, -s * 0.2), s * 0.5, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.95, 0), c + Vector2(s * 0.95, 0), c + Vector2(0, s * 1.05)]), col)
		2:  # diamond
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.72, 0), c + Vector2(0, s), c + Vector2(-s * 0.72, 0)]), col)
		3:  # club
			ci.draw_circle(c + Vector2(0, -s * 0.5), s * 0.42, col)
			ci.draw_circle(c + Vector2(-s * 0.5, s * 0.1), s * 0.42, col)
			ci.draw_circle(c + Vector2(s * 0.5, s * 0.1), s * 0.42, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.15, 0), c + Vector2(s * 0.15, 0), c + Vector2(s * 0.35, s), c + Vector2(-s * 0.35, s)]), col)
		_:  # spade
			ci.draw_circle(c + Vector2(-s * 0.45, s * 0.2), s * 0.47, col)
			ci.draw_circle(c + Vector2(s * 0.45, s * 0.2), s * 0.47, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.9, s * 0.05), c + Vector2(s * 0.9, s * 0.05), c + Vector2(0, -s * 1.05)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.15, s * 0.3), c + Vector2(s * 0.15, s * 0.3), c + Vector2(s * 0.35, s * 1.05), c + Vector2(-s * 0.35, s * 1.05)]), col)

## A casino chip: a coloured disc with cream edge spots and a value. For _draw callers.
static func draw_chip(ci: CanvasItem, c: Vector2, r: float, value: int) -> void:
	var col := chip_colour(value)
	ci.draw_circle(c + Vector2(1.5, 2.5), r, Color(0, 0, 0, 0.4))
	ci.draw_circle(c, r, col)
	for k in 6:
		var a := TAU * k / 6.0
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.8, r * 0.16, Color("f2e8cf"))
	ci.draw_circle(c, r * 0.58, col.lightened(0.15))
	var f: Font = ThemeDB.fallback_font
	var t := str(value) if value < 1000 else "%dk" % (value / 1000)
	var fs := int(r * 0.8)
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(f, c + Vector2(-w * 0.5, fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("fbf7ec"))

static func chip_colour(v: int) -> Color:
	if v >= 500:
		return Color("6b3fa0")
	if v >= 100:
		return Color("1d2230")
	if v >= 50:
		return Color("e07a2a")
	if v >= 25:
		return Color("2f7a3a")
	if v >= 10:
		return Color("2f5fb0")
	return Color("b0202c")
