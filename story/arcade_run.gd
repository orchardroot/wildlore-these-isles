class_name ArcadeRun
extends RefCounted
## The `arcade` story command: the change counter at a seaside arcade.
##   {"do": "arcade", "town": "blackpool", "who": "Change Counter"}
## Change (pounds to 2p coins, capped a day), the machines (ui/arcade_screen.gd), the prize counter (tokens for a
## soft toy) and a true line or two. Rules live in Arcade.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func run(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var town := str(c.get("town", host.zone_id()))
	var who := str(c.get("who", "Change Counter"))
	var info := Arcade.town(town)
	if info.is_empty():
		push_warning("ArcadeRun: no arcade '%s'" % town)
		return
	await host.say(who, "%s. Pounds in, two-pence pieces out. You have %d coin%s and %d prize token%s." % [str(info.name), Arcade.coins(data), "" if Arcade.coins(data) == 1 else "s", Arcade.tokens(data), "" if Arcade.tokens(data) == 1 else "s"])
	while true:
		var left := Arcade.pounds_left(data)
		var opts := ["Change: £1", "Change: £5 (a day's limit)", "Play the machines", "Prize counter (%d tokens a toy)" % Arcade.TOKENS_PER_TOY, "About these machines", "Leave"]
		var i: int = await host.choice("%d of your £%d change left today." % [left, Arcade.DAILY_POUNDS], opts)
		match i:
			0, 1:
				var r := Arcade.buy(data, 1 if i == 0 else Arcade.DAILY_POUNDS)
				await host.say(who, str(r.line))
				if bool(r.ok):
					await host.sfx("item")
			2:
				if Arcade.coins(data) <= 0:
					await host.say(who, "Not a coin on you. Change first, then fun.")
				else:
					await host.open_menu("arcade:" + town)
			3:
				var id := Arcade.redeem(data, town)
				if id != "":
					await host.sfx("item")
					await host.say("", "%s hands over %s." % [who, _item_name(host, id)])
				elif Arcade.tokens(data) < Arcade.TOKENS_PER_TOY:
					await host.say(who, "Twelve tokens a toy. Tokens come out of the pusher and the falls now and then.")
				else:
					await host.say(who, "You've had every toy on this counter. The shelf is bare and so is my dignity.")
			4:
				await host.say(who, str(info.blurb))
				await host.say(who, str(Arcade.cfg().get("category_d", "")))
				await host.say(who, "Coins and tokens are worth nothing outside, so they can't be cashed in. That's how you know it's an arcade and not a bank.")
			_:
				await host.say(who, "Mind the gulls on your way out.")
				return

func _item_name(h, id: String) -> String:
	return str(h.items.get_item(id).get("one", id))
