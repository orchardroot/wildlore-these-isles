class_name Parish
extends Node
## The parish in play: listens on the Bus for catches, wins, foraging and arrivals, moves jobs on (see Jobs),
## awards the small bits of standing (a named trainer beaten, a first visit to a town) and shows the news as
## toasts once you're back on the overworld. Lives under the Game autoload (added by connect_bus), so the pure
## logic in Jobs and Standing never has to name an autoload.

const SEEN_PREFIX := "standing_seen_"   # first visit to a town counted
const CHECK_EVERY := 1.0                # visit jobs: how often to look at where you are, the hour and the sky

var _game: Node
var _kind := "wild"
var _news: Array = []   # [header, text] waiting for the overworld
var _toast: ParishToast
var _acc := 0.0

static func connect_bus(game: Node) -> Parish:
	var p := Parish.new()
	p.name = "Parish"
	p._game = game
	game.add_child(p)
	var bus := game.get_node("/root/Bus")
	bus.battle_started.connect(func(kind: String): p._kind = kind)
	bus.battle_ended.connect(p._on_battle_ended)
	bus.creature_caught.connect(p._on_caught)
	bus.zone_entered.connect(p._on_zone_entered)
	if bus.has_signal("foraged"):
		bus.foraged.connect(p._on_foraged)
	return p

func _data() -> GameStateData:
	return _game.data

## Queues a toast (shown once no battle or fade is running).
func news(header: String, text: String) -> void:
	if text != "":
		_news.append([header, text])

func standing(nation: String, n: int) -> void:
	news("Standing", Parish.standing_line(_data(), nation, n))

## Adds standing and returns the toast: a new tier's line, or on the very first point in a nation a one-off "Someone
## in England has noticed you" so the player learns standing exists. Later points stay quiet until the next tier.
static func standing_line(data: GameStateData, nation: String, n: int) -> String:
	var before := Standing.points(data, nation)
	var line := Standing.add(data, nation, n)
	if line != "" or before > 0 or Standing.points(data, nation) <= 0:
		return line
	var where := ("on the " if nation == "mann" else "in ") + Standing.name_of(nation)
	return "Someone %s has noticed you. Help out and they'll count you as one of their own." % where

func _on_battle_ended(result: Dictionary) -> void:
	if str(result.get("result", "")) != "win" or bool(result.get("exhibition", false)):
		return  # a County Show or Open Moot bout: re-enterable all day, so it earns no standing
	var d := _data()
	if _kind == "wild":
		_ready_news(Jobs.note_win(d, d.zone_id))
	else:
		standing(Standing.nation_for_zone(d.zone_id), Standing.FOR_TRAINER)
	_finish_auto()

func _on_caught(species_id: String) -> void:
	_ready_news(Jobs.note_catch(_data(), species_id, _game.dex))
	_finish_auto()

func _on_foraged(zone_id: String) -> void:
	_ready_news(Jobs.note_forage(_data(), zone_id))

func _on_zone_entered(zone_id: String) -> void:
	var d := _data()
	var z: Dictionary = ZoneIndex.get_index().zones.get(zone_id, {})
	if str(z.get("kind", "")) == "town" and d.flag(SEEN_PREFIX + zone_id) != true:
		d.set_flag(SEEN_PREFIX + zone_id, true)
		standing(Standing.nation_for_zone(zone_id), Standing.FOR_FIRST_VISIT)
	Markets.sync(d)  # the markets notice new Stones, story turns and rewilding from today
	news("Euros", Wallet.take_welcome_line(d))  # an old save loaded in Ireland: the one-off conversion
	_check_visits()

## Jobs that just became ready to hand in (forage, visit; bring and show are checked at the board).
func _ready_news(slots: Array) -> void:
	for i in slots:
		var j := Jobs.get_job(str(Jobs.slot(_data(), i).get("id", "")))
		if j.is_empty() or str(j.step.type) in Jobs.AUTO:
			continue
		news("Job ready", "%s. Hand it in at any noticeboard in %s." % [str(j.title), Standing.name_of(str(j.nation))])

## Catch and beat jobs pay out the moment they're done.
func _finish_auto() -> void:
	for i in Jobs.auto_ready(_data(), _game.dex):
		var r := Jobs.complete(_data(), i, _game.items)
		news("Job done", Parish.reward_text(r, _game.items))
		news("Standing", str(r.get("tier_line", "")))

## "Count the bats: £450, 2 Sloes and 3 standing in Wales."
static func reward_text(r: Dictionary, items: ItemDB) -> String:
	var bits := [Wallet.fmt(int(r.get("money", 0)), str(r.get("cur", Wallet.GBP)))]
	for id in r.get("got", {}):
		var nm := str(items.get_item(str(id)).get("name", str(id).capitalize()))
		bits.append("%d %s" % [int(r.got[id]), nm] if int(r.got[id]) > 1 else nm)
	if str(r.get("recipe", "")) != "":
		bits.append("a recipe for " + str(r.recipe))
	if int(r.get("standing", 0)) > 0:
		bits.append("%d standing in %s" % [int(r.standing), Standing.name_of(str(r.get("nation", "")))])
	var list: String = bits[0] if bits.size() == 1 else ", ".join(bits.slice(0, bits.size() - 1)) + " and " + str(bits.back())
	return "%s: %s" % [str(r.get("title", "")), list]

func _check_visits() -> void:
	var d := _data()
	if not Jobs.active(d).any(func(a): return str(a[2].step.type) == "visit"):
		return
	_ready_news(Jobs.note_visit(d, d.zone_id, GameClock.phase(d.clock_minutes), Forecast.current_weather()))

func _process(delta: float) -> void:
	_acc += delta
	if _acc < CHECK_EVERY:
		return
	_acc = 0.0
	var router := get_node_or_null("/root/Router")
	if router == null or router.busy or router.overworld == null or not is_instance_valid(router.overworld):
		return
	_check_visits()
	if _news.is_empty() or DisplayServer.get_name() == "headless":
		_news.clear()
		return
	if _toast == null or not is_instance_valid(_toast):
		_toast = ParishToast.new()
		add_child(_toast)
	for m in _news:
		_toast.show_news(m[0], m[1])
	_news.clear()
