class_name ZoneCard
extends CanvasLayer
## The name of a town or route, with its region underneath, fading in at the top of the screen as you arrive.
## Not shown for interiors, nor when coming back out into the area you were just in.

const REGIONS := {
	"cheshire": "Cheshire", "peak": "The Peak District", "manchester": "Greater Manchester", "merseyside": "Merseyside",
	"north_wales": "North Wales", "mid_wales": "Mid Wales", "south_wales": "South Wales", "midlands": "The Midlands",
	"south_england": "The West Country", "cornwall": "Cornwall", "yorkshire": "Yorkshire", "north_east": "North East England",
	"cumbria": "Cumbria", "lancashire": "Lancashire", "scotland": "Scotland", "ireland": "Ireland", "ireland_west": "The West of Ireland",
	"ireland_east": "The East of Ireland", "man": "Isle of Man", "channel_islands": "The Channel Islands",
	"overseas_south_georgia": "South Georgia", "overseas_antarctic": "British Antarctic Territory",
	"east_anglia": "East Anglia",
	"south_east": "South East England",
	"overseas_ascension": "Ascension Island", "overseas_st_helena": "St Helena", "overseas_tristan": "Tristan da Cunha",
	"overseas_falklands": "Falkland Islands",
	"overseas_bermuda": "Bermuda", "overseas_cayman": "Cayman Islands", "overseas_turks_caicos": "Turks and Caicos Islands",
	"overseas_bvi": "British Virgin Islands", "overseas_anguilla": "Anguilla", "overseas_montserrat": "Montserrat",
	"abroad_patagonia": "Y Wladfa, Patagonia", "abroad_cape_breton": "Cape Breton, Nova Scotia", "abroad_boston": "Boston, Massachusetts",
	"abroad_appalachia": "Appalachia", "abroad_brittany": "Brittany (Breizh)", "overseas_la_linea": "Andalusia, Spain", "overseas_cyprus": "Republic of Cyprus", "overseas_north_cyprus": "Northern Cyprus",
}
## Zones whose region id doesn't name them well.
const OVERRIDES := {
	"london": "South East England", "stonehenge": "Wiltshire", "salisbury_plain": "Wiltshire", "lancaster": "Lancashire",
	"belfast": "Northern Ireland", "bushmills": "Northern Ireland", "derry": "Northern Ireland",
	"antrim_coast": "Northern Ireland", "causeway": "Northern Ireland", "mournes": "Northern Ireland",
	"lough_neagh": "Northern Ireland", "enniskillen": "County Fermanagh",
	"brize_norton": "Oxfordshire", "akrotiri": "Akrotiri Sovereign Base Area", "dhekelia": "Dhekelia Sovereign Base Area",
	"pyla": "The UN buffer zone, Cyprus",
}
const GROUP := "zone_card"
const MAX_W := 640.0  # a long name shrinks a little rather than reach across the route chip (top left)  # ParishToast waits for the card before its news takes the top of the screen
const FADE_IN := 0.5
const HOLD := 2.4
const FADE_OUT := 0.7

var _last := ""
var _panel: PanelContainer
var _name: Label
var _sub: Label
var _local: Label
var _tween: Tween

static func subtitle(zone_id: String, region: String) -> String:
	if not OVERRIDES.has(zone_id) and not REGIONS.has(region) and region.begins_with("overseas_"):
		return Overseas.name_of(region.trim_prefix("overseas_"))  # a registered territory's own name (data/overseas)
	return OVERRIDES.get(zone_id, REGIONS.get(region, ""))

## Records arriving in a zone; true when the card should show. Interiors never count, and don't reset
## the area you came from, so stepping out of a house is not an arrival.
func note(kind: String, zone_id: String) -> bool:
	if kind == "interior":
		return false
	if zone_id == _last:
		return false
	_last = zone_id
	return true

func _ready() -> void:
	layer = 5
	add_to_group(GROUP)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = load("res://ui/theme.tres")
	add_child(root)
	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.add_theme_constant_override("margin_top", 36)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	_panel = UIKit.panel(Color("1d2230e6"), 14)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	_panel.add_child(v)
	_name = UIKit.label("", 38, UIKit.CREAM)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_name)
	_local = UIKit.label("", 26, Langs.LOCAL_INK)  # the place's own name where it has one (see Langs)
	_local.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_local.visible = false
	v.add_child(_local)
	var rule := ColorRect.new()
	rule.color = UIKit.HEATHER
	rule.custom_minimum_size = Vector2(0, 2)
	v.add_child(rule)
	_sub = UIKit.label("", 22, UIKit.MUTED)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_sub)
	_panel.modulate.a = 0.0
	Bus.zone_entered.connect(_on_zone_entered)

func _on_zone_entered(zone_id: String) -> void:
	var z: ZoneData = null
	if Router.overworld and is_instance_valid(Router.overworld) and Router.overworld.zone and Router.overworld.zone.id == zone_id:
		z = Router.overworld.zone
	elif Game.zone_exists(zone_id):
		z = ZoneData.load_id(zone_id)
	if z == null or not note(z.kind, zone_id):
		return
	var idx := ZoneIndex.get_index()
	var b := Langs.banner(zone_id, z.name, Settings.languages_on(), idx)
	if str(b[1]) != "":
		Langs.note_place(Game.data, zone_id, z.name, idx)
	show_card(z.name, subtitle(zone_id, z.region), str(b[1]))

## On screen, or about to be (the card waits for the fade in).
func showing() -> bool:
	return _panel.modulate.a > 0.01 or (_tween != null and _tween.is_running())

## Where the card is, while it is showing (else an empty rect): the route chip steps down out of its way.
func rect() -> Rect2:
	return _panel.get_global_rect() if showing() else Rect2()

func show_card(title: String, sub: String, local := "") -> void:
	_name.text = title
	_name.add_theme_font_size_override("font_size", UIKit.fit_size(title, MAX_W, Access.scaled(38, Settings.text_size), 28))
	_local.text = local
	_local.visible = local != ""
	_sub.text = sub
	_sub.visible = sub != ""
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(0.35)  # let the screen fade in first
	_tween.tween_property(_panel, "modulate:a", 1.0, FADE_IN)
	_tween.tween_interval(HOLD)
	_tween.tween_property(_panel, "modulate:a", 0.0, FADE_OUT)
