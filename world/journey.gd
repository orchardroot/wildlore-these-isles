class_name Journey
extends RefCounted
## Travel scenes: a few seconds of the trip when you take the train, a ferry or Bran's Raven (Settings:
## "Travel scenes" On, Short or Off). Off, and always for the playtest bot, nothing plays and travel is
## exactly what it always was. Journeys never decide where you land: the caller still warps to the usual
## Travel.*_arrival tile, between depart() (which ends on a black screen) and arrive().
##
## The train, On: the train you catch pulls in to the platform and you step aboard, then the view from the
## carriage window, then the train standing at the other end as you step off. Short: just the window.
## The ferry and the Raven are a single scene each (JourneyScene), shorter when Short.

const MODES := ["on", "short", "off"]
const KINDS := ["train", "ferry", "fly"]
## How long the scene itself runs, in seconds.
const SCENE := {
	"train": {"on": 2.6, "short": 2.2},
	"ferry": {"on": 6.0, "short": 2.6},
	"fly": {"on": 4.8, "short": 2.4},
}
const BOARD_MAX := 4.0      # the longest the train you catch may take to pull in (usually about 3 s)
const BOARD_TYPICAL := 2.8
const BOARD_STEP := 0.4     # walking up to the train and in
const STEP_OFF := 0.45      # and off again at the other end
const FADE := 0.25
const BOARD_REACH := 4.5    # further than this from the train and you don't walk to it, you just get on
## Towns whose scenery isn't their nation's usual (see JourneyScene.SCHEMES).
const SCHEME_TOWNS := {
	"london": "city", "manchester": "city", "birmingham": "city", "liverpool": "city", "glasgow": "city",
	"newcastle": "city", "sheffield": "city", "cardiff": "city", "edinburgh": "city",
	"buxton": "moor", "whitby": "moor", "keswick": "moor", "lancaster": "moor", "york": "lowland",
	"penzance": "coast", "st_davids": "coast", "aberystwyth": "coast", "holyhead": "coast", "douglas": "coast",
	"kirkwall": "coast", "portree": "highland", "cairnryan": "coast", "dingle": "coast", "bushmills": "coast",
	"aberdeen": "coast",
}
const NATION_SCHEMES := {"england": "lowland", "wales": "wales", "scotland": "highland", "northern_ireland": "ireland", "ireland": "ireland"}

## "on", "short" or "off". The playtest bot (Engine meta "autopilot") never sees a scene.
static func mode() -> String:
	if Engine.has_meta("autopilot"):
		return "off"
	return Settings.travel_scenes if Settings.travel_scenes in MODES else "on"

static func scene_seconds(kind: String, m: String) -> float:
	return float(SCENE.get(kind, {}).get(m, 0.0))

## Roughly how long the whole journey takes, fades and all (0 when scenes are off).
static func total_seconds(kind: String, m: String) -> float:
	if m == "off":
		return 0.0
	var t := scene_seconds(kind, m) + FADE * 4.0  # out, in and out round the scene, in at the other end
	if kind == "train" and m == "on":
		t += BOARD_TYPICAL + BOARD_STEP + STEP_OFF
	return t

## The scenery for a journey's destination: a JourneyScene.SCHEMES key.
static func scheme_for(town: String) -> String:
	if SCHEME_TOWNS.has(town) or Overseas.name_of(town) != "":
		return SCHEME_TOWNS.get(town, "coast")
	var nation := str(Travel.world_map().get("towns", {}).get(town, {}).get("nation", ""))
	return NATION_SCHEMES.get(nation, "lowland")

## Would depart() play a scene over this overworld? Never when scenes are off or for the playtest bot.
static func will_play(ow: Node) -> bool:
	return mode() != "off" and ow != null and is_instance_valid(ow) and ow.is_inside_tree()

## Plays the way out: `kind` is "train", "ferry" or "fly"; info holds "from" and "to" (towns), and for a ferry
## "route" and "card". Returns false at once, having done nothing, when scenes are off; true when a scene
## played, with the screen left black for the warp. Writes info.skipped. Never saves and always ends.
static func depart(ow: Node, kind: String, info: Dictionary) -> bool:
	if not will_play(ow):
		return false
	var m := mode()
	Router.busy = true
	var js := JourneyScene.new()
	js.setup(kind, info, m)
	js.phase = Game.phase()
	var w = ow.get("weather")
	js.weather = str(w) if w != null else "clear"
	js.sprite_id = str(Game.data.flags.get("player_sprite", "player_a")) if Game.data else "player_a"
	js.look = Looks.recipe(Game.data, Game.items) if Game.data else {}  # the look you chose (4.6)
	Router.add_child(js)
	if kind == "train" and m == "on":
		await _board(ow, js)
	await Router.fade_out(FADE)
	js.play_now()
	if not js.done:
		await Router.fade_in(FADE)
		if not js.done:
			await js.finished
		await Router.fade_out(FADE)
	info["skipped"] = js.skipped
	js.queue_free()
	if kind == "train" and m == "on" and not js.skipped and "arrival_scene" in ow:
		ow.arrival_scene = "train"  # the next zone loads with a train standing at the platform
	return true

## After the warp: steps off the train standing at the platform (the player is hidden until then), or hears
## the Raven off. Always leaves the player visible and exactly on the arrival tile.
static func arrive(ow: Node, kind: String, info: Dictionary) -> void:
	if ow == null or not is_instance_valid(ow) or not ow.is_inside_tree():
		return
	var was := Router.busy
	Router.busy = true
	var p: Node3D = ow.get("player")
	if kind == "fly":
		Audio.sfx("raven_caw")
	if p != null and not p.visible:
		var home := p.position
		var traffic = ow.get("traffic")
		if traffic != null and traffic.at_platform() and not info.get("skipped", false):
			var mid: Vector2 = traffic.train_middle()
			var from := Vector3(mid.x, home.y, mid.y)
			if from.distance_to(home) <= BOARD_REACH:
				p.position = home.lerp(from, 0.7)
				p.visible = true
				Audio.sfx("door")
				var tw := ow.create_tween()
				tw.tween_property(p, "position", home, STEP_OFF)
				await tw.finished
		if is_instance_valid(p):
			p.position = home
			p.visible = true
	Router.busy = was

## The train you catch pulls in; when it stands at the platform you walk up to it and get on.
static func _board(ow: Node, js: JourneyScene) -> void:
	var traffic = ow.get("traffic")
	if traffic == null or not traffic.call_at_station():
		return
	var tree := ow.get_tree()
	var t := 0.0
	while t < BOARD_MAX and not js.skipped and not traffic.at_platform():
		await tree.process_frame
		t += ow.get_process_delta_time()
	if js.skipped or not traffic.at_platform():
		return
	var p: Node3D = ow.get("player")
	if p == null:
		return
	var mid: Vector2 = traffic.train_middle()
	var to := Vector3(mid.x, p.position.y, mid.y)
	if to.distance_to(p.position) <= BOARD_REACH:
		var tw := ow.create_tween()
		tw.tween_property(p, "position", p.position.lerp(to, 0.7), BOARD_STEP)
		await tw.finished
	p.visible = false
	Audio.sfx("door")
