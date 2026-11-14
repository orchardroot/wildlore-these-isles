class_name Trades
extends RefCounted
## The trainer's six Trades: Rambler, Trader, Cook, Angler, Naturalist and Local. No points to spend: each level (1 to 5)
## is read straight off a Stats counter or existing state, so old saves land wherever they have already earned.
## Each level brings a friendly title; a few levels bring a small perk. Pure logic (no autoload names).
##
## INTEGRATOR HOOK (Trader perks): in Trade.sell_price, multiply the result by Trades.sell_mult(data) and round, e.g.
##   return roundi(base_sell * Trades.sell_mult(data))
## It tops selling up by 5% (Trader 3) or 10% (Trader 5), so selling stays well under the buying price.

const IDS := ["rambler", "trader", "cook", "angler", "naturalist", "local"]
const NAMES := {"rambler": "Rambler", "trader": "Trader", "cook": "Cook", "angler": "Angler",
	"naturalist": "Naturalist", "local": "Local"}
## Counter (TrainerStats key), what it counts in a sentence, and the amounts that reach levels 2 to 5.
## Angler's counter is added by the fishing session: until then it simply reads 0.
const SOURCE := {
	"rambler": {"key": "steps", "unit": "steps walked", "at": [2000, 10000, 30000, 80000]},
	"trader": {"key": "goods_sold", "unit": "pounds of goods sold", "at": [500, 3000, 12000, 40000]},
	"cook": {"key": "dishes_cooked", "unit": "dishes cooked", "at": [5, 25, 75, 200]},
	"angler": {"key": "fish_caught", "unit": "fish landed", "at": [5, 25, 80, 200]},
	"naturalist": {"unit": "Fieldbook entries", "at": [10, 40, 100, 200]},
	"local": {"unit": "", "at": [1, 2, 3, 4]},   # the best standing tier in any nation
}
const TITLES := {
	"rambler": ["Dawdler", "Stroller", "Rambler", "Fell Walker", "Long-Distance Legend"],
	"trader": ["Window Shopper", "Hagglers' Apprentice", "Market Regular", "Wheeler-Dealer", "Pillar of the Exchange"],
	"cook": ["Toast Burner", "Kettle Botherer", "Handy in a Kitchen", "Proper Cook", "Kitchen Legend"],
	"angler": ["Bent Pin Beginner", "Bank Sitter", "Float Watcher", "Seasoned Angler", "Old Hand at the Water"],
	"naturalist": ["Curious", "Notebook Carrier", "Field Naturalist", "Keen Recorder", "Garside's Equal"],
	"local": ["Stranger", "Known Face", "Regular", "Local", "Pillar of the Community"],
}
## Perks: id -> [trade, level it comes at, what it does]. Only perks that really do something are listed.
const PERKS := {
	"rambler_repel": ["rambler", 2, "Lavender Sachets last a quarter longer."],
	"rambler_repel_more": ["rambler", 4, "Lavender Sachets last half as long again."],
	"trader_early": ["trader", 2, "You hear the trade news two days before anyone else."],
	"trader_haggle": ["trader", 3, "Shopkeepers pay 5% more for your goods."],
	"trader_pannier": ["trader", 3, "A bigger pannier: your pack takes 15 more of a trade good."],
	"trader_credit": ["trader", 4, "Credit at the markets: a hall will advance you a quarter of an order's worth."],
	"trader_haggle_more": ["trader", 5, "Shopkeepers pay 10% more for your goods."],
	"trader_pitch": ["trader", 5, "A pitch of your own on market day: your first twelve of a good sell with no glut."],
	"cook_second": ["cook", 2, "Every sixth dish you cook makes a second portion."],
	"cook_second_more": ["cook", 4, "Every fourth dish you cook makes a second portion."],
	"naturalist_sky": ["naturalist", 3, "The weather brings out its favourites a touch more."],
	"naturalist_sky_more": ["naturalist", 5, "The weather brings out its favourites rather more."],
}
const SKY_FLAG := "trade_sky"   # what Encounters reads (a flag dict only): 0, 0.15 or 0.3. Kept up to date by refresh()

static func level(data: GameStateData, trade_id: String) -> int:
	if not SOURCE.has(trade_id):
		return 1
	var amount := _amount(data, trade_id)
	var lv := 1
	for need in SOURCE[trade_id].at:
		if amount >= int(need):
			lv += 1
	return lv

static func _amount(data: GameStateData, trade_id: String) -> int:
	match trade_id:
		"naturalist":
			return FieldbookGoals.caught_count(data)
		"local":
			var best := 0
			for n in Standing.NATIONS:
				best = maxi(best, Standing.tier(data, n))
			return best
	return TrainerStats.get_count(data, str(SOURCE[trade_id].key))

static func title(data: GameStateData, trade_id: String) -> String:
	return TITLES.get(trade_id, ["?"])[level(data, trade_id) - 1]

## How much more to do for the next level (0 at the top).
static func to_next(data: GameStateData, trade_id: String) -> int:
	var lv := level(data, trade_id)
	if lv >= 5 or not SOURCE.has(trade_id):
		return 0
	return maxi(0, int(SOURCE[trade_id].at[lv - 1]) - _amount(data, trade_id))

static func has_perk(data: GameStateData, perk_id: String) -> bool:
	if not PERKS.has(perk_id):
		return false
	return level(data, str(PERKS[perk_id][0])) >= int(PERKS[perk_id][1])

## Steps a sachet runs for, with the Rambler perks.
static func repel_steps(data: GameStateData, base: int) -> int:
	var guild := Guilds.repel_bonus(data, base)   # the Ramblers
	if has_perk(data, "rambler_repel_more"):
		return base + base / 2 + guild
	if has_perk(data, "rambler_repel"):
		return base + base / 4 + guild
	return base + guild

## Selling top-up for the Trader perks (see the integrator hook above).
static func sell_mult(data: GameStateData) -> float:
	var guild := Guilds.sell_bonus(data)   # the Traders' Guild
	if has_perk(data, "trader_haggle_more"):
		return 1.10 + guild
	return (1.05 if has_perk(data, "trader_haggle") else 1.0) + guild

## Extra room in the pack for a trade good (the Trader's bigger pannier). The real Trader's Pannier still takes it to 99.
static func carry_bonus(data: GameStateData) -> int:
	return 15 if has_perk(data, "trader_pannier") else 0

## Extra portions for the dish just counted (call after dishes_cooked has gone up): a fixed rhythm, not luck.
static func extra_portions(data: GameStateData) -> int:
	var every := 4 if has_perk(data, "cook_second_more") else (6 if has_perk(data, "cook_second") else 0)
	if every == 0:
		return 0
	return 1 if TrainerStats.get_count(data, "dishes_cooked") % every == 0 else 0

## The Naturalist's extra pull for rarer weather (0, 0.15 or 0.3).
static func sky_boost(data: GameStateData) -> float:
	var guild := Guilds.sky_bonus(data)   # the Naturalists
	if has_perk(data, "naturalist_sky_more"):
		return 0.3 + guild
	return (0.15 if has_perk(data, "naturalist_sky") else 0.0) + guild

## Keeps the one perk the encounter roll reads from plain flags up to date (called on entering a zone).
static func refresh(data: GameStateData) -> void:
	var b := sky_boost(data)
	if float(data.flag(SKY_FLAG) if data.flag(SKY_FLAG) != null else 0.0) != b:
		data.set_flag(SKY_FLAG, b)

## The perks earned so far, as sentences.
static func perk_lines(data: GameStateData, trade_id: String) -> Array:
	var out := []
	for p in PERKS:
		if PERKS[p][0] == trade_id and has_perk(data, p):
			out.append(str(PERKS[p][2]))
	return out

## A one-line progress note for the Trades page.
static func progress_text(data: GameStateData, trade_id: String) -> String:
	var src: Dictionary = SOURCE.get(trade_id, {})
	if trade_id == "local":
		return "best standing in any nation"
	var n := _amount(data, trade_id)
	var more := to_next(data, trade_id)
	var s := "%s %s" % [TrainerStats._n(n), src.get("unit", "")]
	return s + (", %s to go" % TrainerStats._n(more) if more > 0 else ", the top")
