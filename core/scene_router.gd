extends Node
## Autoload Router: fades between the title, zones, battles and menus. `busy` freezes the player while anything is happening.

const TITLE := "res://ui/title.tscn"
const OVERWORLD := "res://world/overworld.tscn"
const BATTLE := "res://battle_ui/battle_scene.tscn"
const MENUS := {
	"pause": "res://ui/pause_menu.tscn", "party": "res://ui/party_screen.tscn", "bag": "res://ui/bag_screen.tscn",
	"pedia": "res://ui/pedia_screen.tscn", "shop": "res://ui/shop_screen.tscn", "starter": "res://ui/starter_picker.tscn",
	"settings": "res://ui/settings_screen.tscn", "controls": "res://ui/controls_screen.tscn", "accessibility": "res://ui/accessibility_screen.tscn", "report": "res://ui/report_screen.tscn", "save": "res://ui/save_screen.tscn", "ark": "res://ui/ark_screen.tscn",
	"map": "res://ui/world_map.tscn", "travel": "res://ui/travel_menu.tscn", "name": "res://ui/name_entry.tscn", "credits": "res://ui/credits_screen.tscn",
	"relearn": "res://ui/relearn_screen.tscn", "quiz": "res://ui/quiz_screen.tscn", "stats": "res://ui/stats_screen.tscn",
	"craft": "res://ui/craft_screen.tscn", "jobs": "res://ui/jobs_screen.tscn",
	"postcard": "res://ui/postcard_screen.tscn", "quests": "res://ui/quests_screen.tscn", "cold_open": "res://ui/cold_open.tscn",
	"bureau": "res://ui/bureau_screen.tscn", "exchange": "res://ui/exchange_screen.tscn", "crypto": "res://ui/crypto_screen.tscn",
	"cage": "res://ui/cage_screen.tscn", "fruit": "res://ui/fruit_screen.tscn", "blackjack": "res://ui/blackjack_screen.tscn",
	"roulette": "res://ui/roulette_screen.tscn", "hilo": "res://ui/hilo_screen.tscn", "races": "res://ui/race_screen.tscn", "market": "res://ui/market_hall_screen.tscn", "society": "res://ui/society_screen.tscn", "deed": "res://ui/deed_screen.tscn", "lease": "res://ui/lease_screen.tscn", "darts": "res://ui/darts_screen.tscn", "crabbing": "res://ui/crabbing_screen.tscn", "bowls": "res://ui/bowls_screen.tscn", "skim": "res://ui/skimming_screen.tscn", "ringing": "res://ui/ringing_screen.tscn", "walling": "res://ui/walling_screen.tscn", "pairing": "res://ui/pairing_screen.tscn", "summary": "res://ui/summary_screen.tscn", "crossword": "res://ui/crossword_screen.tscn", "games": "res://ui/games_screen.tscn", "shanty": "res://ui/shanty_screen.tscn", "conkers": "res://ui/conker_screen.tscn", "almanac": "res://ui/almanac_screen.tscn", "lang": "res://ui/lang_screen.tscn", "biology": "res://ui/biology_screen.tscn", "selection": "res://ui/selection_screen.tscn",
	"wardrobe": "res://ui/wardrobe_screen.tscn",
	"arcade": "res://ui/arcade_screen.tscn",
	"fete": "res://ui/fete_screen.tscn",
	"curling": "res://ui/curling_screen.tscn", "wrestling": "res://ui/wrestling_screen.tscn",
	"invention": "res://ui/invention_screen.tscn", "science": "res://ui/science_fair_screen.tscn", "economist": "res://ui/economist_screen.tscn", "forecasting": "res://ui/forecasting_screen.tscn", "trumps": "res://ui/trumps_screen.tscn", "cards": "res://ui/cards_screen.tscn",
}

const DOOR_FADE := Vector2(0.15, 0.2)  # out, in: through a door in about a third of a second

var busy := false
var overworld: Node = null
var _fade: ColorRect
var _menu_layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.03, 0.05, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 50
	add_child(_menu_layer)

func fade_out(t := 0.3) -> void:
	if _fade.color.a >= 0.999:
		return  # already dark (a travel scene ended on black): don't sit on a black screen for nothing
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, t)
	await tw.finished

func fade_in(t := 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, t)
	await tw.finished

func goto_title() -> void:
	busy = true
	await fade_out()
	overworld = null
	Game.clock_running = false
	get_tree().change_scene_to_file(TITLE)
	await get_tree().process_frame
	await fade_in()
	busy = false

## Enters a zone. pos (-1, -1) means the zone's spawn point. `fade` is the seconds each way (doors are quicker).
func goto_zone(zone_id: String, pos: Vector2i, facing := "down", fade := Vector2(0.3, 0.3)) -> void:
	busy = true
	await fade_out(fade.x)
	if overworld == null or not is_instance_valid(overworld):
		get_tree().change_scene_to_file(OVERWORLD)
		await get_tree().process_frame
		await get_tree().process_frame
		overworld = get_tree().current_scene
	overworld.load_zone(zone_id, pos, facing)
	Game.clock_running = true
	Bus.zone_entered.emit(zone_id)
	await fade_in(fade.y)
	busy = false

## Runs a battle on top of the overworld and returns {"result": "win"|"lose"|"ran"|"caught", "caught": Creature}.
func battle(foe_party: Array, opts: Dictionary) -> Dictionary:
	busy = true
	Bus.battle_started.emit(opts.get("kind", "wild"))
	if Engine.has_meta("autopilot") or _fade.color.a >= 0.999:
		await fade_out(0.25)  # the playtest bot, or already dark: no show
	else:
		var ctx: Dictionary = overworld.battle_context() if overworld and is_instance_valid(overworld) and overworld.has_method("battle_context") else {}
		await BattleIntro.play(self, opts, ctx)  # the transition (and the VS splash for a big fight), ending dark
		_fade.color.a = 1.0
	var scene: Node = load(BATTLE).instantiate()
	get_tree().root.add_child(scene)
	if overworld and is_instance_valid(overworld):
		overworld.visible = false
		overworld.process_mode = Node.PROCESS_MODE_DISABLED
	scene.setup(foe_party, opts)
	await fade_in(0.25)
	var result: Dictionary = await scene.finished
	await fade_out(0.3)
	scene.queue_free()
	if overworld and is_instance_valid(overworld):
		overworld.visible = true
		overworld.process_mode = Node.PROCESS_MODE_INHERIT
		if overworld.has_method("on_battle_finished"):
			overworld.on_battle_finished(result)
	if str(result.get("result", "")) == "lose" and overworld and is_instance_valid(overworld):
		# a loss is always followed by a whiteout warp: stay dark and busy so the screen doesn't flash the
		# battle spot before fading back out (goto_zone fades in and clears busy)
		Bus.battle_ended.emit(result)
		return result
	await fade_in(0.3)
	busy = false
	Bus.battle_ended.emit(result)
	return result

## Opens a menu scene (name or "shop:<id>") and waits for its `closed(result)` signal.
func open_menu(menu: String) -> Variant:
	var parts := menu.split(":", true, 1)
	var path: String = MENUS.get(parts[0], "")
	if path == "" or not ResourceLoader.exists(path):
		push_warning("Router: no menu '%s'" % menu)
		return null
	if Engine.has_meta("autopilot"):
		return Engine.get_meta("autopilot").menu_result(menu)
	var was_busy := busy
	busy = true
	var scene: Node = load(path).instantiate()
	_menu_layer.add_child(scene)
	if scene.has_method("setup"):
		scene.setup(parts[1] if parts.size() > 1 else "")
	if scene.has_method("show_tip"):  # the first time you meet a screen, one line about it (the Hints setting)
		var tip := Intros.for_menu(Game.data, parts[0], Settings.hints)
		if tip != "":
			scene.show_tip(tip)
	var result = await scene.closed
	scene.queue_free()
	busy = was_busy
	return result
