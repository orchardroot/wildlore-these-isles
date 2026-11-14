class_name DeedsSim
extends RefCounted
## Plays the Deeds against their own rules to check nothing prints money (a MarketSim-style harness; the test and
## tools use it). The best honest day: every input bought at the CHEAPEST region's price (the goods are hard-won
## fish, so this is generous), a full store, the best tier, a manager and every day an average one. Pure logic.

## Net sterling per in-game day for a Deed at a tier, with inputs valued at the cheapest regional buy price. `ups` are
## the upgrades held (DeedChoices); `temper` is the manager's temperament ("" for the plain average, 1.15). The
## monthly matters are in, answered the best way each time (DeedChoices.ask_net_per_day).
static func net_per_day(data: GameStateData, id: String, tier: int, managed: bool, ups: Array = [], temper := "") -> float:
	var deed := Deeds.get_deed(id)
	var st := {"owned": true, "tier": tier, "store": {}, "till": 0, "rates_due": 0, "manager": "npc" if managed else "",
		"last_day": data.day_count, "coll": data.day_count, "paid": 0, "accrue": 0, "bill": data.day_count + 7, "stmt": data.day_count + 30, "log": []}
	data.set_flag(Deeds.FLAG_PREFIX + id, st)
	var fx := DeedChoices.fx_for(id, ups, temper if managed else "")
	var cost := 0.0
	var units := 0.0
	for inp in deed.inputs:
		var eff := DeedChoices.use_of(int(inp.per_day), float(fx.use))
		units += int(inp.per_day)   # the sold units stay the plain day's; the stock a fryer eats extra is only cost
		cost += eff * cheapest_buy(str(inp.item))
	var o: Dictionary = deed.output
	var infl := Deeds.inflation(data)
	var raw := (float(o.base) + float(o.per_input) * units) * float(deed.tiers[tier].mult) * infl * Deeds.band_scale(data) * float(fx.takings)
	if managed and temper == "":
		raw *= Deeds.MANAGER_BONUS
	raw = maxf(0.0, raw - float(fx.upkeep) * infl)
	return raw * (1.0 - float(deed.rates) - float(fx.rates)) - cost + DeedChoices.ask_net_per_day(data, id)

static func cheapest_buy(item_id: String) -> float:
	var base := float(Trade.base_price(item_id))
	var best := base * 99.0
	for g in Trade.config().get("groups", {}):
		best = minf(best, base * Trade.regional(item_id, str(g)))
	return best

## Total sterling outlay to hold `tier` (the Deed at today's price plus every tier up to it) and the `ups` on top.
static func outlay(data: GameStateData, id: String, tier: int, ups: Array = []) -> float:
	var deed := Deeds.get_deed(id)
	var total := float(Deeds.price(data, id))
	for t in range(1, tier + 1):
		total += float(deed.tiers[t].cost) * Deeds.inflation(data)
	for u in ups:
		total += float(DeedChoices.cost(data, id, DeedChoices.get_upgrade(id, str(u))))
	return total

## Days to earn back the outlay at a tier. The test insists this never drops under a fortnight... of play.
static func payback_days(data: GameStateData, id: String, tier: int, managed: bool, ups: Array = []) -> float:
	var net := net_per_day(data, id, tier, managed, ups)
	return outlay(data, id, tier, ups) / maxf(0.001, net) if net > 0.0 else 9999.0

## Days for one upgrade to pay for itself on top of the tier it sits on: its price over the extra net it brings.
static func upgrade_payback(data: GameStateData, id: String, tier: int, managed: bool, up_id: String, ups: Array = []) -> float:
	var up := DeedChoices.get_upgrade(id, up_id)
	var gain := net_per_day(data, id, tier, managed, ups + [up_id]) - net_per_day(data, id, tier, managed, ups)
	return float(DeedChoices.cost(data, id, up)) / gain if gain > 0.0 else 9999.0
