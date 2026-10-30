class_name TrumpsRun
extends RefCounted
## The `trumps` story command (the hook in Trumps adds it; no dialogue file names it).
##   {"do": "trumps", "give": "starter"}   Mum hands over the first five cards
##   {"do": "trumps", "npc": "<id>"}        a game against that resident, once a real day
## The game itself is ui/trumps_screen.gd (menu "trumps:<zone>:<npc>"); this pays out: their held card the first time
## you win, then a few pounds. A walked-out game still uses up the day.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func run(c: Dictionary) -> void:
	var data: GameStateData = host.data
	Trumps.use_dex(host.dex)
	if str(c.get("give", "")) == "starter":
		var five := Trumps.give_starter(data)
		var names := five.map(func(s): return str(host.dex.get_species(str(s)).get("name", s)))
		await host.sfx("item")
		await host.say("", "Five Trumps cards: %s." % ", ".join(names))
		return
	var zone: String = host.zone_id()
	var npc := str(c.get("npc", cmd.npc_id))
	data.set_flag(Trumps.day_key(zone, npc), DailyKey.stamp(data))
	var res = await host.open_menu("trumps:%s:%s" % [zone, npc])
	if not (res is Dictionary) or bool(res.get("quit", false)):
		await host.say("", "You gather your cards up. Mid-game. Bit rude, but they'll live.")
		return
	var won := bool(res.get("won", false))
	var paid := Trumps.settle(data, zone, npc, won)
	if not won:
		await host.say("", "You lose this one. Nothing wagered, nothing lost, and they do enjoy it.")
		return
	if str(paid.card) != "":
		var nm := str(host.dex.get_species(str(paid.card)).get("name", paid.card))
		await host.sfx("item")
		await host.say("", "You win their %s card. It joins your pack." % nm)
	if int(paid.money) > 0:
		var p := Wallet.earn_here(data, int(paid.money), zone)
		await host.sfx("item")
		await host.say("", "%s for the winner." % Wallet.fmt(int(p.amount), str(p.cur)))
