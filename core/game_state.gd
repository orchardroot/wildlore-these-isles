extends Node
## Autoload Game: the current save's data plus the game databases, the clock, saving and dev boot switches.

var data := GameStateData.new()
var dex: Dex
var moves: MoveDB
var chart: TypeChart
var items = null  # ItemDB once data_api/item_db.gd exists
var rng: Rng
var args: Dictionary = {}
var clock_running := false
var save_dir := SaveSystem.DEFAULT_DIR
var autosave_enabled := true
var skip_next_autosave := false  # set by the title: the first zone after New Game or Load must not overwrite "auto"
var _in_battle := false
var _toast: SaveToast
var parish: Parish
var quest_news: QuestNews

## Emitted after each autosave that really wrote the file (the "Saved" toast listens).
signal autosaved

## The game's full title. The project's config/name stays "Wildlore" because Godot names the user:// folder
## (and so every save) after it.
const TITLE := "Wildlore: These Isles"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_title(TITLE)  # config/name stays "Wildlore": it names the save folder
	dex = Dex.load_default()
	moves = MoveDB.load_default()
	chart = TypeChart.load_default()
	if ResourceLoader.exists("res://data_api/item_db.gd"):
		items = load("res://data_api/item_db.gd").load_default()
	args = DevArgs.parse(DevArgs.user_args())
	Calendar.set_override(str(args.get("date", "")))  # --date=MM-DD or YYYY-MM-DD: screenshot any season, festival or day
	if str(args.get("quality", "")) in ["low", "medium", "high"]:
		Settings.quality = str(args.quality)  # --quality: before/after screenshots without touching the player's settings
	var seed_value: int = args.seed if args.seed >= 0 else int(Time.get_unix_time_from_system())
	rng = Rng.new(seed_value)
	data.rng_seed = seed_value
	if DevArgs.is_dev_session(args, DevArgs.user_args()):
		# screenshots, dev boots and the bot never touch the player's real saves
		autosave_enabled = false
		save_dir = "user://saves_dev"
	Bus.battle_started.connect(_on_battle_started)
	Bus.battle_ended.connect(_on_battle_ended)
	Bus.zone_entered.connect(_on_zone_entered)
	TrainerStats.connect_bus(self)
	parish = Parish.connect_bus(self)  # jobs off the noticeboards and standing with the nations
	quest_news = QuestNews.connect_bus(self, parish)  # "New quest", "Quest complete" and the Gazetteer's toasts
	Bus.creature_caught.connect(func(_id: String): TodaysWalk.note_catch(data, Forecast.current_weather()))
	if "--quiet-window" in DevArgs.user_args():
		# screenshot runs (tools/shot.sh): never grab focus, sit off-screen, make no sound
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(0, -4000))
		AudioServer.set_bus_mute(0, true)
	if args.get("fps", false):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)  # measure, don't cap at the refresh rate
	call_deferred("_dev_boot")

func _process(delta: float) -> void:
	data.play_seconds += delta
	if clock_running and not Router.busy:
		_minute_acc += delta
		while _minute_acc >= 1.0:
			_minute_acc -= 1.0
			data.clock_minutes = GameClock.wrap(data.clock_minutes + 1)
			if data.clock_minutes == 0:
				data.day_count += 1
				BuildingSociety.settle(data)  # instalments, savings interest, post from the Building Society
				Deeds.tick(data, data.day_count)  # takings, rates and the post for any Deeds you own
				Leases.tick(data, data.day_count)  # upkeep and the post for any Enclosure leases you hold
	if args.get("fps", false):
		_fps_acc += delta
		if _fps_acc >= 1.0:
			_fps_acc = 0.0
			# dev --fps: uncapped (vsync off) frame rate, with the draw calls, primitives and nodes behind it
			print("FPS %d draws %d prims %d nodes %d" % [Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])

var _minute_acc := 0.0
var _fps_acc := 0.0

func new_game() -> void:
	data = GameStateData.new()
	data.rng_seed = rng.roll_int(0, 2147483647)
	if args.clock >= 0:
		data.clock_minutes = args.clock
	var start := _start_zone()
	data.zone_id = start
	data.last_sanctuary = GameStateData.default_sanctuary() if start != "testbed" else {"zone": start, "pos": [-1, -1]}

## Minutes since midnight where you are: the UK clock at home, local time in an Overseas Territory.
func local_minutes() -> int:
	return Timezones.local_minutes(data, data.tz_zone)

func phase() -> String:
	return GameClock.phase(local_minutes())

func save(slot := "auto") -> Error:
	return SaveSystem.save(slot, data.to_dict(), save_dir)

## Saves to the "auto" slot unless a battle is running or autosave is off (the playtest bot, tests).
func autosave() -> void:
	if autosave_enabled and not _in_battle:
		save("auto")
		autosaved.emit()
		_show_saved_toast()

func _show_saved_toast() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _toast == null or not is_instance_valid(_toast):
		_toast = SaveToast.new()
		add_child(_toast)
	_toast.flash()

func _on_battle_started(_kind: String) -> void:
	_in_battle = true

func _on_battle_ended(_result: Dictionary) -> void:
	_in_battle = false

func _on_zone_entered(zone_id: String) -> void:
	var region := ZoneData.load_id(zone_id).region
	if region != "":  # interiors have none: they keep the clock of the street outside
		data.tz_zone = Timezones.zone_for_region(region)
	TodaysWalk.today(data, items)  # a new real day picks Today's Walk (behind the zone fade, not mid-walk)
	if skip_next_autosave:
		skip_next_autosave = false
		return
	autosave()

## The slot Continue should load: the newest readable one.
func newest_slot() -> String:
	return SaveSystem.newest_slot(save_dir)

func load_slot(slot := "auto") -> bool:
	var d := SaveSystem.load_slot(slot, save_dir)
	if d.is_empty() or d.get("_too_new", false):
		return false
	data = GameStateData.from_dict(d, dex)
	return true

func has_save(slot := "auto") -> bool:
	var d := SaveSystem.load_slot(slot, save_dir)
	return not d.is_empty() and not d.get("_too_new", false)

func zone_exists(id: String) -> bool:
	return FileAccess.file_exists("res://data/zones/%s.json" % id)

func _start_zone() -> String:
	return "macc_home" if zone_exists("macc_home") else ("macclesfield" if zone_exists("macclesfield") else "testbed")

var _cues_fired := false  # --set / --read have run (a screenshot waits for their toast)

func _dev_boot() -> void:
	if args.get("playtest", "") != "":
		var bot: Node = load("res://tools/playtest/bot.gd").new()
		get_tree().root.add_child(bot)
		bot.start(args.playtest)
		return
	if args.shot != "":
		_take_shot()
	var dev_menu := DevMenu.arg(DevArgs.user_args())
	if dev_menu != "":
		DevMenu.boot(self, dev_menu)  # --menu=<name>[:arg], see ui/dev_menu.gd
	elif args.battle_species != "":
		new_game()
		var party := [Creature.create(dex.get_species("kindlet"), 10, rng, moves)]
		data.party = party
		for a in DevArgs.user_args():
			if a.begins_with("--lead=") and dex.has(a.substr(7)):  # dev: our lead is this species (back-sprite shots)
				party[0] = Creature.create(dex.get_species(a.substr(7)), 10, rng, moves)
			if a.begins_with("--held="):  # dev: the lead holds this charm (screenshots of charm messages)
				party[0].held = a.substr(7)
			if a == "--stress":  # dev: worst-case widths (see DevMenu.stress)
				DevMenu.stress(data)
		var foe := [Creature.create(dex.get_species(args.battle_species), args.battle_level, rng, moves)]
		foe[0].variant = str(args.get("coat", ""))
		var opts := {"kind": "wild"}
		if args.get("double", false):
			# A double battle: two of ours against the dev twins, with the --battle species leading theirs.
			var twins := StoryData.trainer("dev_double")
			data.party = [party[0], Creature.create(dex.get_species("holtling"), 10, rng, moves), Creature.create(dex.get_species("spikkin"), 9, rng, moves)]
			for m in twins.party.slice(1):
				foe.append(Creature.create(dex.get_species(m.species), args.battle_level, rng, moves))
			opts = {"kind": "trainer", "ai": "trainer", "double": true, "trainer": twins}
		if args.weather != "":
			opts["weather"] = args.weather
		Router.battle(foe, opts)
	elif args.get("journey", "") != "" and args.boot_zone == "":
		DevJourney.show_scene(self, args.journey)  # --journey=<kind>:<town>, see core/dev_journey.gd
	elif args.boot_zone != "":
		new_game()
		if args.clock >= 0:
			data.clock_minutes = args.clock
		data.party = [Creature.create(dex.get_species("kindlet"), 10, rng, moves)]
		data.party[0].variant = str(args.get("coat", ""))
		HomeBase.dev_setup(data, str(args.get("home", "")), dex)
		for a in DevArgs.user_args():
			if a.begins_with("--rewild="):  # dev: every rewilding site at this stage, 0..3 (screenshots)
				for s in Rewild.sites():
					data.set_flag(Rewild.flag_key(str(s.id)), int(a.substr(9)))
				for l in Leases.all():  # and every lease's land, if it is held (see --lease=)
					data.set_flag(Rewild.flag_key(Leases.site_id(str(l.id))), int(a.substr(9)))
		for a in DevArgs.user_args():
			if a.begins_with("--lease="):  # dev: hold these leases (comma separated ids), post-game
				data.set_flag("game_complete", true)
				for id in a.substr(8).split(",", false):
					data.set_flag(Leases.key_of(id), {"since": data.day_count, "paid": 0, "next": data.day_count + Leases.WEEK, "arrears": 0, "due": 0})
		for a in DevArgs.user_args():
			if a.begins_with("--flag="):  # dev: story flags set before the zone loads (a postcard waiting, a side story)
				for f in a.substr(7).split(",", false):
					data.set_flag(f.get_slice("=", 0), f.get_slice("=", 1) if "=" in f else true)  # k=v sets a string
			elif a.begins_with("--badges="):  # dev: this many Stones held
				for i in int(a.substr(9)):
					data.badges.append("dev_%d" % i)
		if args.ride != "":
			data.bag["bike"] = 1
			data.badges = ["brook", "urban", "stone", "iron"] if args.ride == "lantern" else ["brook", "urban", "stone"]
		await Router.goto_zone(args.boot_zone, args.boot_pos, "down")
		if args.ride == "bike":
			Router.overworld.player.set_bike(true)
		_dev_cues()
		if PhotoMode.dev_wanted():
			await get_tree().create_timer(1.5).timeout
			PhotoMode.start(Router.overworld)
		if args.get("journey", "") != "":
			await get_tree().create_timer(1.0).timeout
			await DevJourney.run(self, args.journey)
		if args.get("intro", "") != "":
			await get_tree().create_timer(0.8).timeout
			BattleIntro.dev_show(Router, Router.overworld, str(args.intro), float(args.get("intro_at", 0.5)))

## Dev --set=<flags> and --read=<plaque>: once the zone is up, set flags as a script would and read a plaque as if
## from its lectern, so the quest and Gazetteer toasts can be screenshotted.
func _dev_cues() -> void:
	for a in DevArgs.user_args():
		if a.begins_with("--set="):
			for f in a.substr(6).split(",", false):
				data.set_flag(f, true)
				Bus.flag_changed.emit(f, true)
		elif a.begins_with("--read="):
			var id := a.substr(7)
			var t := ""
			for pl in Gazetteer.all():
				if str(pl.id) == id:
					t = str(pl.title)
			quest_news.plaque_read(Gazetteer.record(data, id), t)
	_cues_fired = true

func _take_shot() -> void:
	await get_tree().create_timer(float(args.shot_delay), true, false, true).timeout
	if Array(DevArgs.user_args()).any(func(a): return str(a).begins_with("--set=") or str(a).begins_with("--read=")):
		while not _cues_fired:  # a slow boot: wait for the zone, then give the toast time to slide in
			await get_tree().process_frame
		await get_tree().create_timer(2.0, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path: String = args.shot
	if not path.is_absolute_path():
		path = ProjectSettings.globalize_path("res://").path_join(path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("shot: ", path)
	if "--audit" in DevArgs.user_args():  # dev: list what spills out of its menu, beside the PNG
		var lines := LayoutAudit.report(get_tree().root, get_viewport().get_visible_rect())
		var f := FileAccess.open(path.get_basename() + ".audit.txt", FileAccess.WRITE)
		f.store_string("\n".join(lines) + ("\n" if lines else "ok\n"))
		f.close()
	get_tree().quit()
