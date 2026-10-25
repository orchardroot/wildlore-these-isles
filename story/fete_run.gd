class_name FeteRun
extends RefCounted
## The `fete` story command: {"do": "fete", "event": "cheese", "who": "Hill Steward"}. Offers the event, plays it on
## ui/fete_screen.gd and pays out through Fete (a small prize any day, a bigger one on the real date).

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func play(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("event", ""))
	var e := Fete.event(id)
	var who := str(c.get("who", e.get("who", "Steward")))
	if e.is_empty():
		push_warning("FeteRun: no fete event '%s'" % id)
		return
	var today := Calendar.today()
	var real := Fete.real_day(id, today.x, today.y, Calendar.year())
	if real:
		await host.say(who, "And it's the real day today, so the prize is the proper one.")
	var j: int = await host.choice("Have a go at %s?" % str(e.name).to_lower(), ["Yes", "Not now"])
	if j != 0:
		await host.say(who, "Take your time. The hill, bog and field aren't going anywhere.")
		return
	var res = await host.open_menu("fete:" + id)
	if not (res is Dictionary) or bool(res.get("quit", false)):
		await host.say(who, "Walked off mid-event? We'll say you were called away.")
		return
	if not bool(res.get("won", false)):
		await host.say(who, "Not this time. %s Have another go." % str(res.get("summary", "")))
		return
	var out := Fete.win(data, id, real)
	await host.say(who, str(e.won))
	if bool(out.first):
		await host.say(str(e.plaque.title), str(e.plaque.text))
	if int(out.prize) > 0:
		var paid := Wallet.earn_here(data, int(out.prize), host.zone_id())
		await host.sfx("item")
		await host.say("", "The prize: %s." % Wallet.fmt(int(paid.amount), str(paid.cur)))
	else:
		await host.say(who, "You've had today's prize already. The glory is free, though.")
