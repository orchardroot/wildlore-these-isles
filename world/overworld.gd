extends Node3D
## Hosts one zone at a time: builds it, places the player and NPCs, handles steps, warps, edges,
## signs, interaction, wild encounters, weather and the HD-2D look.

signal stepped(p: Vector2i, tile: String)

var zone: ZoneData
var player: Player
var rig: CameraRig
var sky: SkyAndLight
var weather := "clear"
var encounters := Encounters.new()
var npcs: Array = []
var _zone_node: Node3D
var _tilt: ColorRect
var _dark: ColorRect
var traffic: RailTraffic
var deep_pressed := false  # a crate just latched a plate; the next step says so
var deep_crates := {}   # Deep Places: crate id -> tile now (session only; they reset when you come back in)
var _hinted := {}       # ability-gated tiles already explained this visit
var _rode_in := false   # on the bike when we went indoors (session memory only, not saved)
var ambient: AmbientLife
var follower: Follower
var arrival_scene := ""  # "train": the next zone loads with a train at the platform for you to step off (Journey)
var _door_opened := false  # door_ahead swung a door (and played its sound) for the step now finishing
var _edge_facing := ""     # walked off an edge this way: the next zone's camera glides in

func _ready() -> void:
	sky = SkyAndLight.new()
	add_child(sky)
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.setup(self, Game.data.flags.get("player_sprite", "player_a"))
	player.sprite.setup_recipe(Looks.recipe(Game.data, Game.items))  # the look you chose, and what you're wearing (4.6)
	player.step_finished.connect(_on_step)
	rig = CameraRig.new()
	add_child(rig)
	rig.target = player
	sky.follow = player
	sky.weather_changed.connect(func(w: String): weather = w)  # the weather ran out mid-zone
	ambient = AmbientLife.new()
	add_child(ambient)
	add_child(ZoneCard.new())
	add_child(RouteChip.new())  # the Map's "Route here" breadcrumb
	add_child(PlaceIndicator.new())  # the name of the building whose door you stand at
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_tilt = ColorRect.new()
	_tilt.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tilt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://art/shaders/tilt_shift.gdshader")
	_tilt.material = mat
	layer.add_child(_tilt)
	sky.post = mat
	_dark = ColorRect.new()
	_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dm := ShaderMaterial.new()
	dm.shader = load("res://art/shaders/darkness.gdshader")
	_dark.material = dm
	_dark.visible = false
	layer.add_child(_dark)
	_apply_quality()
	Bus.settings_changed.connect(_apply_quality)

func _apply_quality() -> void:
	_tilt.visible = Settings.quality != "low"
	sky.apply_quality(Settings.quality)
	get_viewport().msaa_3d = Viewport.MSAA_2X if Settings.quality == "high" else Viewport.MSAA_DISABLED
	for il in get_tree().get_nodes_in_group(InteriorLight.GROUP):
		il.apply(Settings.quality)
	CharSprite.set_crisp_all(get_tree(), Settings.quality != "low")

## pos (-1, -1) means the zone's spawn point.
func load_zone(zone_id: String, pos: Vector2i, facing: String) -> void:
	if not Game.zone_exists(zone_id):
		# a save from a zone that no longer exists: back to the last Sanctuary (or Macclesfield)
		push_warning("Overworld: no zone '%s', going to the last Sanctuary" % zone_id)
		var ls: Dictionary = Game.data.last_sanctuary
		zone_id = str(ls.zone) if Game.zone_exists(str(ls.zone)) else "macclesfield"
		pos = Vector2i(int(ls.pos[0]), int(ls.pos[1])) if zone_id == str(ls.zone) else Vector2i(-1, -1)
	zone = ZoneData.load_id(zone_id)
	FieldMoves.apply_cuts(Game.data, zone)
	Rewild.apply(Game.data, zone)  # rewilding sites take their stage's shape
	Leases.apply(Game.data, zone)  # unowned lease land is fenced off with the Enclosure's sign
	deep_crates = DeepPlace.crates_start(zone)
	DeepPlace.apply(Game.data, zone, deep_crates)  # Deep Places: gates, floods and crates as the flags say
	if _zone_node:
		_zone_node.queue_free()
	_build_zone_node()
	for n in npcs:
		n.queue_free()
	npcs.clear()
	_spawn_npcs()
	if pos.x < 0:
		pos = zone.spawn
	pos = zone.landing_near(pos, FieldMoves.abilities(Game.data))  # never set down on a fence the overlays just raised
	player.place(pos, facing, ground_y(pos))
	var arriving := arrival_scene
	arrival_scene = ""
	# hidden only while a travel scene's train stands here for you to step off (Journey.arrive shows you again)
	player.visible = not (arriving == "train" and traffic.stand_at_station())
	var wading_here := zone.tile_at(pos) == "deep_water"
	if zone.kind == "interior":
		_rode_in = _rode_in or player.on_bike  # remember riding in, to hop back on outside
		player.set_bike(false)
	elif _rode_in:
		_rode_in = false
		if Player.resume_bike(true, FieldMoves.bike_refusal(Game.data, zone, wading_here)):
			player.set_bike(true)
	player.set_wading(wading_here)
	Game.data.zone_id = zone_id
	Travel.note_visit(Game.data, zone)
	if zone.kind == "interior" and Game.data.flag(VisitorsBook.seen_flag(zone_id)) != true:  # the Visitor's Book
		var tour := VisitorsBook.note(Game.data, zone_id, zone.kind, ZoneIndex.get_index())
		if not tour.is_empty():
			VisitorsBook.announce(self, tour, Travel.town_name(tour.town), str(Game.items.get_item(tour.item).get("name", "")))
	Game.data.pos = pos
	Game.data.facing = facing
	var outdoor := sky.weather_for_zone(zone)  # kept between zones until it runs out (see GameStateData.weather_for)
	weather = "clear" if zone.kind == "interior" else outdoor
	sky.set_weather(outdoor, zone.kind == "interior")
	ambient.setup(zone, _zone_node, sky)
	RoamingCreatures.attach(self)
	follower = Follower.attach(self)  # the party lead, one tile behind
	rig.configure(zone.width, zone.height, zone.kind == "interior")
	if _edge_facing != "":
		rig.arrive(_edge_facing)
		_edge_facing = ""
	_door_opened = false
	if zone.music != "":
		Audio.play_music(zone.music)
	Audio.enter_zone(self, zone, weather)  # ambience bed, weather layer, muffled music indoors, town bells
	_dark.visible = zone.dark
	_dev_radio()

## Dev switch `--talk=radio[:n]`: the wireless reads Today's Walk as soon as the zone is ready, from line n (screenshots).
func _dev_radio() -> void:
	for a in DevArgs.user_args():
		if a.begins_with("--talk=radio"):
			await get_tree().create_timer(0.6).timeout
			var lines := TodaysWalk.radio_lines(Game.data, Game.dex, Game.items)
			await say(lines.slice(clampi(int(a.get_slice(":", 1)), 0, lines.size() - 1)))
			return

## Dark caves: keep the light circle on the player (and faint glows on every exit) each frame.
func _process(_delta: float) -> void:
	if zone and Engine.get_process_frames() % 60 == 0:
		Npc.sync_schedule(self)  # people with hours go home or come out as the time of day changes
	if _dark == null or not _dark.visible or rig == null or player == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var mat := _dark.material as ShaderMaterial
	var here := cam.unproject_position(player.global_position + Vector3(0, 0.6, 0))
	var r_tiles := FieldMoves.light_radius(Game.data)
	var edge := cam.unproject_position(player.global_position + Vector3(r_tiles, 0.6, 0))
	mat.set_shader_parameter("size", _dark.size)
	mat.set_shader_parameter("centre", here)
	mat.set_shader_parameter("radius", maxf(40.0, here.distance_to(edge)))
	mat.set_shader_parameter("warmth", 1.0 if FieldMoves.has(Game.data, "lantern") else 0.0)
	var lights := []
	for w in zone.warps:
		if lights.size() >= 8:
			break
		if ZoneData.warp_state(w, Game.data) == "hidden":
			continue
		var wp := Vector3(int(w.x) + 0.5, ground_y(Vector2i(int(w.x), int(w.y))) + 0.3, int(w.y) + 0.5)
		var sp := cam.unproject_position(wp)
		var sr := sp.distance_to(cam.unproject_position(wp + Vector3(1.2, 0, 0)))
		lights.append(Vector4(sp.x, sp.y, sr, 0.0))
	while lights.size() < 8:
		lights.append(Vector4(-9999, -9999, 0, 0))
	mat.set_shader_parameter("lights", lights)
	mat.set_shader_parameter("light_count", mini(zone.warps.size(), 8))

func ground_y(p: Vector2i) -> float:
	if not zone.in_bounds(p):
		return 0.0
	if zone.tile_at(p) == "deep_water":
		return ZoneBuilder.water_y(zone, p) - 0.08  # wading: float on the surface, coracle just under
	return ZoneBuilder.ground_y(zone, p)

## "ok", "blocked", "edge" (walking off into a neighbour) or "ledge" (hop down).
func can_enter(p: Vector2i, dir: Vector2i) -> String:
	if not zone.in_bounds(p):
		var side := GridMotion.edge_side(p, zone.width, zone.height)
		return "edge" if zone.edges.has(side) else "blocked"
	if zone.tile_at(p) == "ledge_south":
		var landing := p + Vector2i(0, 1)
		return "ledge" if dir == Vector2i(0, 1) and zone.walkable(landing) and not occupied(landing) else "blocked"
	if DeepPlace.can_push(zone, deep_crates, p, dir):
		return "push"
	var fv := FieldMoves.verdict(Game.data, zone, p)
	if fv == "blocked":
		return "blocked"
	if fv in ["scramble", "squelch"] and player.on_bike and not occupied(p):
		player.set_bike(false)  # scree is on foot
	if fv == "wade" and player.on_bike and not occupied(p) and zone.walkable(p, dir, FieldMoves.abilities(Game.data)):
		player.set_bike(false)  # hop off and push off in the coracle
	if fv == "cut":
		return "blocked" if occupied(p) else "cut"
	if not zone.walkable(p, dir, FieldMoves.abilities(Game.data)) or occupied(p) or not zone.sign_at(p).is_empty():
		return "blocked"
	if traffic and traffic.closed(p):
		return "blocked"  # the level crossing is shut: a train is coming
	return "ok"

## Bumped into a tile that wants an ability you lack: say which, once per tile per visit.
func blocked_hint(p: Vector2i) -> void:
	var why := FieldMoves.block_hint(Game.data, zone, p)
	if why == "" or _hinted.has(p):
		return
	_hinted[p] = true
	await say([why])

## Hedge-lay: clear the bramble for good and rebuild the scenery.
func cut_bramble(p: Vector2i) -> void:
	FieldMoves.cut(Game.data, zone, p)
	Audio.sfx("cut")
	if _zone_node:
		_zone_node.queue_free()
	_build_zone_node()

## The zone's scenery, plus the trains that run through it.
func _build_zone_node() -> void:
	_zone_node = ZoneBuilder.build(zone)
	add_child(_zone_node)
	InteriorLight.dress(zone, _zone_node, player, Settings.quality)  # rooms lit by their hearths and windows (Medium, High)
	Seasonal.dress(zone, _zone_node, player)  # festivals and falling leaves from the real date
	Viaduct.dress(zone, _zone_node)  # railway viaducts striding across (Castlefield)
	OccluderFade.dress(zone, _zone_node, player)  # buildings between the camera and you go see-through
	Forage.dress(zone, _zone_node, Game.data)  # hedgerow pickings and crafting benches
	TrailsScene.dress(zone, _zone_node, Game.data)  # a paper on the table, a dig spot where a trail ends
	CreatureJobsScene.dress(zone, _zone_node, Game.data)  # spots where your lead creature can do a job
	HomeBase.dress(zone, _zone_node, Game.data)  # Mum's trophy shelf, the garden and its visitors
	HomeExtrasScene.dress(zone, _zone_node, Game.data)  # souvenir shelves, plaque boards, bird table, bug hotel, pond
	Noticeboard.dress(zone, _zone_node)  # the parish noticeboard (jobs)
	RewildScene.dress(zone, _zone_node, Game.data)  # rewilding sites: stumps, saplings, pools, marked spots
	ShowRing.dress(zone, _zone_node, Game.data)  # today's County Show, if it's here
	PostBox.dress(zone, _zone_node, Game.data)  # an envelope over the post boxes while Kit's card waits
	traffic = RailTraffic.new()
	traffic.name = "RailTraffic"
	_zone_node.add_child(traffic)
	traffic.setup(zone, _occupied_tiles, float(Game.args.get("train", -1.0)))

## Tiles the player and NPCs stand on or are stepping into (a train waits short of these on a crossing).
func _occupied_tiles() -> Dictionary:
	var out := {}
	if player:
		out[player.grid_pos] = true
		if player.moving:
			out[player.grid_pos + GridMotion.dir_vec(player.facing)] = true
	for n in npcs:
		if is_instance_valid(n):
			out[n.grid_pos] = true
	return out

func toggle_bike() -> void:
	var why := FieldMoves.bike_refusal(Game.data, zone, player.wading)
	if why != "" and not player.on_bike:
		Audio.sfx("bump")
		await say([why])
		return
	player.set_bike(not player.on_bike)
	if player.on_bike:
		Audio.sfx("bike_bell")

func occupied(p: Vector2i) -> bool:
	return npc_at(p) != null

func npc_at(p: Vector2i) -> Node:
	for n in npcs:
		if is_instance_valid(n) and n.grid_pos == p:
			return n
	return null

func _spawn_npcs() -> void:
	if not ResourceLoader.exists("res://world/npc.gd"):
		return
	var npc_script: Script = load("res://world/npc.gd")
	set_meta("npc_phase", Game.phase() + Routines.stamp(Calendar.weekday_today(), Calendar.season_today(), Game.local_minutes()))
	for def in zone.npcs + _side_npcs():  # plus a Keeper out in town with a side story (SideStories)
		if not Npc.should_spawn(def, Game.data, Game.phase()):  # flag gating and hours ("times")
			continue
		var n: Node3D = npc_script.new()
		add_child(n)
		n.setup(Npc.placed(def), self)  # at their routine's spot for now, if they keep one
		npcs.append(n)

## Keepers waiting in this zone with a side story, each on their spot or the nearest free tile to it.
func _side_npcs() -> Array:
	Festivals.rollover(Game.data)  # a festival that has come round again starts its quest afresh
	var out := SideStories.npcs_for(zone.id, Game.data) + Festivals.npcs_for(zone.id) + Regulars.npcs_for(zone.id, Game.data)  # plus whoever's festival is on, and the Regulars
	out.append_array(LangLessons.npcs_for(zone.id))  # language teachers (4.5)
	var taken := {}
	for d in out:
		var p := SideStories.nearest_free(zone, Vector2i(int(d.x), int(d.y)), taken)
		taken[p] = true
		d.x = p.x
		d.y = p.y
	return out

var _friend_steps := 0

func _on_step(p: Vector2i) -> void:
	Game.data.pos = p
	TrainerStats.add(Game.data, "steps")
	_friend_steps += 1
	if _friend_steps >= 128:  # a long walk together makes friends
		_friend_steps = 0
		for c in Game.data.party:
			c.friendship = mini(255, c.friendship + 1)
	Game.data.facing = player.facing
	if not zone.in_bounds(p):
		_cross_edge(p)
		return
	var w := zone.warp_at(p)
	var wstate := ZoneData.warp_state(w, Game.data) if not w.is_empty() else "open"
	if wstate == "locked":
		await say([str(w.locked.get("line", "It's locked."))])
		player.try_step(GridMotion.facing_from(GridMotion.dir_vec(player.facing) * -1))  # back off the doorstep
		return
	if not w.is_empty() and wstate == "open":
		var indoors := zone.tile_at(p) == "door" or zone.kind == "interior"
		if not _door_opened:
			Audio.sfx("door")
		_door_opened = false
		Router.goto_zone(str(w.to), Vector2i(int(w.tx), int(w.ty)), str(w.get("facing", player.facing)),
			Router.DOOR_FADE if indoors else Vector2(0.3, 0.3))
		return
	if zone.tile_at(p) == "door" and str(zone.building_at(p).get("style", "")) == "station":
		if not _door_opened:
			Audio.sfx("door")
		_door_opened = false
		var here := zone
		await ScriptRunner.start(self, [{"do": "rail"}])  # the ticket office
		if not is_inside_tree() or not is_instance_valid(player) or zone != here or player.grid_pos != p:
			return  # took the train (this overworld now shows the town it went to)
		player.try_step("down")  # back out onto the platform
		return
	var tile := zone.tile_at(p)
	stepped.emit(p, tile)
	Audio.footstep(tile, player.on_bike, Input.is_action_pressed("run"))
	var was_wading := player.wading
	player.set_wading(tile == "deep_water")
	if player.wading and not was_wading:
		Audio.sfx("splash")
	if tile == "tall_grass":
		Audio.sfx("step_grass")
	elif tile == "scree":
		Audio.sfx("scramble")
	elif tile == "bog":
		Audio.sfx("bog_squelch")
	await DeepScene.stepped(self, p)  # a plate may have taken your weight
	_check_trainers()
	if Router.busy:
		return
	if Repel.step(Game.data):  # a Lavender Sachet just ran out
		await ScriptRunner.start(self, [{"do": "sachet_worn"}])
		return
	Meals.step(Game.data)  # a lure dish counts its steps down
	if encounters.in_grace():
		encounters.stepped()
		return
	var enc := Encounters.roll(zone, tile, Game.phase(), weather, Game.rng, TodaysWalk.featured_in(Game.data, zone.id), Game.data.flags)
	if not enc.is_empty() and Game.data.first_able() != null and not Repel.blocks(Game.data, int(enc.level)):
		if enc.get("scaled", false):  # off the main line: grown up to suit the level
			enc.species = ParLevel.stage(Game.dex, str(enc.species), int(enc.level))
		var foe := Creature.create(Game.dex.get_species(enc.species), enc.level, Game.rng, Game.moves)
		Charms.maybe_wild(foe, Game.rng)  # now and then one is carrying a charm
		Forms.assign_wild(foe, zone.region, str(zone.id), Game.moves)  # the regional form of where it was met
		foe.variant = Coats.roll(Game.rng, Calendar.today().x, weather, Game.phase())  # about 1 in 96: an uncommon coat
		Game.data.mark_seen(enc.species)
		var result: Dictionary = await Router.battle([foe], {"kind": "wild", "weather": weather, "time": Game.phase(), "stage": _stage()})
		await _after_battle(result)

func _cross_edge(p: Vector2i) -> void:
	var side := GridMotion.edge_side(p, zone.width, zone.height)
	var target_id: String = zone.edges[side].get("to", "")
	var target := ZoneData.load_id(target_id)
	var back := p - GridMotion.dir_vec(player.facing)
	var arrival := zone.edge_arrival(side, back, target)
	_edge_facing = player.facing  # load_zone lets the camera glide in from behind
	Router.goto_zone(target_id, arrival, player.facing)

## The player is about to step onto `p`: if it is a building's door, swing it open onto a dark doorway
## (the step itself carries you in, then a quick fade).
func door_ahead(p: Vector2i) -> void:
	if zone.kind == "interior" or zone.tile_at(p) != "door" or _zone_node == null:
		return
	var b := zone.building_at(p)
	if b.is_empty() or (zone.warp_at(p).is_empty() and str(b.get("style", "")) != "station"):
		return
	var style := str(b.get("style", "red_brick"))
	var swing := Landmarks.door_swing(style)
	var by := int(b.y) + int(b.h)  # the footprint's south edge, where the door face is
	swing.position = Vector3(p.x, zone.height_at(Vector2i(int(b.x), int(b.y))) * ZoneBuilder.LEVEL, by)
	_zone_node.add_child(swing)
	Audio.sfx("door")
	_door_opened = true
	var tw := swing.create_tween()
	tw.tween_property(swing.get_node("Hinge"), "rotation:y", Landmarks.DOOR_OPEN_ANGLE, Landmarks.DOOR_SWING_SECS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if str(b.get("style", "")) == "station":  # the ticket office: you come straight back out, so shut it behind you
		tw.tween_interval(0.6)
		tw.tween_property(swing.get_node("Hinge"), "rotation:y", 0.0, 0.2)
		tw.tween_callback(swing.queue_free)

## What the battle transition needs to know about where the player is standing (see BattleIntro.choose):
## the tile, whether it is dark, a cave stage or indoors, the region (for the VS stripe) and where on screen.
func battle_context() -> Dictionary:
	var ctx := {"tile": zone.tile_at(player.grid_pos) if zone.in_bounds(player.grid_pos) else "", "dark": zone.dark,
		"stage": _stage(), "interior": zone.kind == "interior", "region": zone.region}
	if zone.region == "":  # indoors: the town you are in
		var town = Game.data.flag("last_town")
		if town and Game.zone_exists(str(town)):
			ctx.region = ZoneData.load_id(str(town)).region
	var cam := get_viewport().get_camera_3d()
	var vs := get_viewport().get_visible_rect().size
	if cam and vs.x > 0.0:
		ctx["centre"] = cam.unproject_position(player.global_position + Vector3(0, 0.6, 0)) / vs
	return ctx

func _check_trainers() -> void:
	for n in npcs:
		if is_instance_valid(n) and n.has_method("check_sight"):
			if n.check_sight(player.grid_pos):
				return

func _stage() -> String:
	if zone.stage != "":
		return zone.stage
	if zone.kind == "interior":
		return "spa_interior" if zone.id.contains("spa") else "town"
	if zone.region == "peak" or zone.id.contains("fiddle"):
		return "moor"
	if zone.id.contains("forest"):
		return "forest"
	return "grass" if zone.kind == "route" else "town"

## Called by Router after any battle that ran over this overworld.
func on_battle_finished(result: Dictionary) -> void:
	encounters.after_battle()
	if str(result.get("result", "")) == "lose":
		_rode_in = false  # the whiteout warp is not a ride home
	if zone and zone.music != "":
		Audio.play_music(zone.music, 0.4)

func _after_battle(result: Dictionary) -> void:
	if result.get("result") == "lose":
		await ScriptRunner.start(self, [{"do": "whiteout"}])  # one whiteout, shared with trainer battles
	elif Encounters.autosave_after(result):
		Game.autosave()  # the catch is done and nothing is half-played: bank it
	if str(result.get("result", "")) == "win" and LangLessons.say_it_offer(Game.data, Langs.code_for(str(zone.id), ZoneIndex.get_index()), Settings.languages_on(), Game.rng.roll()):
		await ScriptRunner.start(self, [{"do": "say_it"}])  # "Say it": one quick word, never required

func interact(p: Vector2i) -> void:
	Audio.interaction(self, p)
	if await DeepScene.interact(self, p):  # a lever in a Deep Place
		return
	if await Forage.interact(self, p):  # a forage prop or a crafting bench
		return
	if await CreatureJobsScene.interact(self, p):  # a job spot for the lead creature
		return
	if await HomeBase.interact(self, p):  # the trophy shelf, a garden plot or a visitor
		return
	if await HomeExtrasScene.interact(self, p):  # souvenirs, plaque boards, garden visitors
		return
	if await Noticeboard.interact(self, p):
		return
	if await RewildScene.interact(self, p):  # a marked spot on a rewilding site
		return
	if await PostBox.interact(self, p):  # post from Kit (or just a post box)
		return
	if await FishingScene.interact(self, p):  # open water and a rod
		return
	if await CrabbingScene.interact(self, p):  # a harbour wall and a crabbing kit
		return
	if await TrailsScene.interact(self, p):  # a paper on a table, a trail's dig spot
		return
	if await ExamineScene.interact(self, p):  # a look-closer spot in a room
		return
	if await LooksMirror.interact(self, p):  # a mirror: the Wardrobe, hair included
		return
	var s := zone.sign_at(p)
	if not s.is_empty():
		if s.get("kind", "") == "radio":  # the Shipping Forecast, then Today's Walk (which may pay a weather bounty)
			var outlook := Forecast.outlook(Forecast.current_weather(), Game.data.weather_until - Game.data.world_minutes() if Game.data.weather != "" else -1, Forecast.area_table(str(s.get("areas", [""])[0])))
			await say(Forecast.for_radio(s, Forecast.current_weather(), Game.data.day_count) + outlook + Trade.money_box(Game.data, str(Game.data.zone_id)) + TodaysWalk.radio_lines(Game.data, Game.dex, Game.items))
		elif str(s.get("plaque", "")) != "":  # a heritage plaque: read it, and the first time it goes in the Gazetteer
			await say([str(s.text)], _sign_title(s))
			var res := Gazetteer.record(Game.data, str(s.plaque))
			Bus.flag_changed.emit(Gazetteer.flag_key(str(s.plaque)), true)  # a quest step may have wanted it read
			Game.quest_news.plaque_read(res, str(s.get("title", "")))
			if str(s.get("theme", "")) == PoetsCorner.THEME:  # a plaque on the arts counts for Poets' Corner too (4.5)
				Game.quest_news.poets_corner(PoetsCorner.record(Game.data, str(s.plaque)))
		else:
			await say(_sign_lines(s) + KeeperIntel.door_line(str(zone.id), Game.data, str(s.get("text", "")), Game.chart))
		return
	var n := npc_at(p)
	if n == null and zone.tile_at(p) == "counter":
		n = npc_at(p + GridMotion.dir_vec(player.facing))  # talk across a shop or Sanctuary counter
	if n and n.has_method("interact"):
		await n.interact(player)
	elif follower and follower.is_at(p):
		await follower.talk()

## A sign's lines, with the local language beside the English where the sign carries it (see Langs).
func _sign_lines(s: Dictionary) -> Array:
	var idx := ZoneIndex.get_index()
	var r := Langs.sign_lines(s, str(zone.id), Settings.languages_on(), idx)
	if str(r[1]) != "":
		Langs.note_text(Game.data, Langs.code_for(str(zone.id), idx), str(r[1]))
		var gloss := LangLessons.sign_gloss(Game.data, Langs.code_for(str(zone.id), idx), str(r[1]))
		if gloss != "":  # words you've learnt from a teacher, picked out on the sign
			return r[0] + [gloss]
	return r[0]

func _sign_title(s: Dictionary) -> String:
	var idx := ZoneIndex.get_index()
	var on := Settings.languages_on()
	var loc := Langs.local_for(s, str(zone.id), on, idx)
	if loc != "":
		Langs.note_text(Game.data, Langs.code_for(str(zone.id), idx), loc)
	return Langs.sign_title(s, str(zone.id), on, idx)

func open_pause() -> void:
	Audio.sfx("confirm")
	var r = await Router.open_menu("pause")
	if r is Dictionary and r.has("fly"):  # flight from the map, after the Moot
		await _fly_to(str(r.fly))

## The Fly key out on the overworld: same rules as the Map's Fly button (Champion, nothing else going on).
func try_fly() -> void:
	if Game.data.flag("champion") != true or Router.busy or player.moving:
		return
	Audio.sfx("confirm")
	var town = await Router.open_menu("travel:fly")
	if town != null and str(town) != "":
		await _fly_to(str(town))

func _fly_to(town: String) -> void:
	var a := Travel.fly_arrival(town)
	var here = Game.data.flag("last_town")
	var info := {"from": str(here) if here else "", "to": town}
	player.set_bike(false)
	_rode_in = false
	TrainerStats.add(Game.data, "flights")
	var scene: bool = await Journey.depart(self, "fly", info)
	if not scene:
		Audio.sfx("raven_caw")
	await Router.goto_zone(str(a.zone), a.pos, "down")
	if scene:
		await Journey.arrive(self, "fly", info)

## Shows lines in the dialogue box (or prints them if the UI isn't there yet).
func say(lines: Array, who := "") -> void:
	if not ResourceLoader.exists("res://ui/dialogue_box.tscn"):
		for l in lines:
			print("SAY: ", l)
		return
	var was := Router.busy
	Router.busy = true
	var box: Node = load("res://ui/dialogue_box.tscn").instantiate()
	add_child(box)
	for l in lines:
		await box.show_text(str(l), who)
	box.queue_free()
	Router.busy = was

## Deep Places: shove the crate at `p` one tile on and rebuild the scenery (the player then steps into its place).
func push_crate(p: Vector2i, dir: Vector2i) -> void:
	DeepPlace.push(zone, deep_crates, p, dir)
	deep_pressed = deep_pressed or not DeepPlace.press_plates(Game.data, zone, deep_crates, player.grid_pos).is_empty()
	Audio.sfx("scramble")
	rebuild_scenery()

## The zone's gates, floods and crates changed: re-apply them and rebuild the meshes.
func rebuild_scenery() -> void:
	DeepPlace.apply(Game.data, zone, deep_crates)
	if _zone_node:
		_zone_node.queue_free()
	_build_zone_node()
