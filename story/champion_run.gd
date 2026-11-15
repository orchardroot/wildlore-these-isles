class_name ChampionRun
extends RefCounted
## The Walkers' League in the field (see RouteChampions). Two hooks:
##  - `first_win(cmd, id)`: called by Commands after a champion's first fight is won; dates it and announces any title
##    the win brings (a title is announced once, so an old save is told of all it has the next time it meets one).
##  - the `rchamp` story command, {"do": "rchamp", "id": "<trainer id>", "intro": [lines], "win": "line", "tired": "line"}:
##    a beaten champion offers a rematch. Once a real week; the team follows the season and the weather of the day; it
##    is fought at the player's par; the prize is only paid for a win, and a win is what uses the week up (so a loss
##    costs only the usual whiteout, and can be tried again).

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func _weather() -> String:
	var w := str(host.current_weather()) if host.has_method("current_weather") else str(host.data.weather)
	return w if w != "" else "clear"

## After a champion's first win: the date, then any new title.
func first_win(id: String) -> void:
	if not RouteChampions.note_first_win(host.data, id):
		return
	await titles()

## Announces titles earned and not yet told: the rank, the keepsake that waits on the shelf at home.
func titles() -> void:
	for t in RouteChampions.take_new_titles(host.data):
		var k: Dictionary = t.get("keepsake", {})
		await host.sfx("item")
		await host.say("", "%d champions of the roads beaten. The Walkers' League makes you a %s." % [int(t.at), str(t.name)])
		await host.say("", "Put by for you: %s. Mum will have it on the shelf at home before you can say \"signposted\"." % str(k.get("name", "a keepsake")))

func run(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("id", ""))
	var champ := RouteChampions.get_champion(id)
	var t := StoryData.trainer(id)
	if champ.is_empty() or t.is_empty() or not RouteChampions.beaten(data, id):
		return
	var who := str(t.name)
	if not RouteChampions.rematch_open(data, id):
		await host.say(who, cmd._sub(str(c.get("tired", "Not twice in a week. Come back on Monday."))))
		return
	var season := Calendar.season_today()
	var weather := _weather()
	await host.say("", RouteChampions.team_note(champ, season, weather, host.dex))
	if await host.choice("A rematch with %s? Once a week, at your level." % who, ["Yes, a rematch", "Not today"]) != 0:
		await host.say(who, "Another day, then. The road isn't going anywhere.")
		return
	for line in c.get("intro", []):
		await host.say(who, cmd._sub(str(line)))
	var def := RouteChampions.rematch_def(champ, t, season, weather, data.flags)
	var result: Dictionary = await cmd._fight(def)
	match str(result.get("result", "")):
		"win":
			RouteChampions.record_rematch(data, id)
			cmd._set_flag(RouteChampions.WEEK_PREFIX + id, RouteChampions.week_now())  # so the host hears of it too
			await host.say(who, cmd._sub(str(c.get("win", "Well walked."))))
		"lose":
			await cmd.whiteout()
			cmd._ended = true
