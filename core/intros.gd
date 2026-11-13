class_name Intros
extends RefCounted
## Gentle introductions (4.0): each system says one short line the first time you meet it, and never again. The
## "Hints" setting turns them all off. Seen cards are flags (intro_<id>), so old saves default to "not seen"; a save
## that is already well under way when it first meets this is treated as a veteran and told nothing. Pure logic.

const FLAG := "intro_"
const INIT := "intro_init"
const VETERAN_SECONDS := 1800.0   # half an hour of play: you have worked the basics out already

const TEXT := {
	"pedia": "The Fieldbook fills as you see and catch creatures. Run changes the filter, and Rumours hint at where to look.",
	"bag": "Everything you carry lives here, in pockets. Pick an item to use it on your team.",
	"party": "Your team of six, in battle order. Pick a creature to see its moves, or to change places.",
	"ark": "The Ark keeps the creatures that don't fit in your team. Visit a nurse to bring one back.",
	"map": "Places you have visited are marked here, with a hint of where the story points next.",
	"quests": "The Journal keeps your quests and the plaques you have read. Left and right change tab.",
	"stats": "Your tallies, your standing with the six nations and your Trades. Left and right turn the page.",
	"almanac": "The Almanac gathers every page of your book. New ones appear as you find your feet.",
	"shop": "Buy or sell here. Prices change from place to place, so a bargain may be a few towns away.",
	"jobs": "Noticeboard jobs pay money and earn standing with the nation that posted them. Three at a time.",
	"craft": "Recipes turn what you have foraged into food and gear. Pick one you have the ingredients for.",
	"society": "A Building Society lends money and keeps savings. Interest runs monthly, so read the APR first.",
	"deed": "A Deed is a business of your own. Keep it stocked, collect the till, and mind the council rates.",
	"market": "The price board shows what this market wants today. Trade goods sell at that price.",
	"pairing": "Two fond creatures can leave a basket. It hatches once you have walked enough steps.",
	"battle_wild": "Weaken a wild creature first, then throw a Snare from the Bag to catch it.",
	"battle_keeper": "A Keeper's creatures can't be caught. Win by tiring out their whole team.",
	"types": "Types decide fights: Hearth beats Hedgerow beats Brook beats Hearth. Menu in a fight shows the whole chart.",
	"typechart": "Sixteen types. Pick one to see what it hits hard, what it can't hurt, and what hits it back.",
}
## Menu name (as the Router knows it) to the card it shows.
const MENUS := {"pedia": "pedia", "bag": "bag", "party": "party", "ark": "ark", "map": "map", "quests": "quests",
	"stats": "stats", "almanac": "almanac", "shop": "shop", "jobs": "jobs", "craft": "craft", "society": "society",
	"deed": "deed", "market": "market", "pairing": "pairing", "typechart": "typechart"}

## The card for `id` if Hints are on and it has not been shown ("" otherwise); showing it marks it seen.
static func take(d: GameStateData, id: String, enabled: bool) -> String:
	if not enabled or not TEXT.has(id):
		return ""
	if d.flag(INIT) == null:
		d.set_flag(INIT, true)
		if d.play_seconds > VETERAN_SECONDS:
			for k in TEXT:
				d.set_flag(FLAG + k, true)
	if d.flag(FLAG + id) == true:
		return ""
	d.set_flag(FLAG + id, true)
	return str(TEXT[id])

static func for_menu(d: GameStateData, menu: String, enabled: bool) -> String:
	return take(d, str(MENUS[menu]), enabled) if MENUS.has(menu) else ""
