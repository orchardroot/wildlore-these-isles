class_name Arcade
extends RefCounted
## The seaside arcade: a change counter (pounds to 2p coins, with a daily cap), a 2p coin pusher, a claw grabber and
## penny falls. Pure seeded logic (no autoload names); ui/arcade_screen.gd draws it and the story command
## {"do": "arcade"} runs the counter. Coins and prize tokens have NO cash value and nothing here pays pounds out,
## so the arcade can't print money (see ArcadeSim and tests/minigames/test_arcade.gd). Prizes are soft-toy key items.
## In Britain these are Category D machines (penny falls, coin pushers, claw grabbers), which is why children may play.

const PATH := "res://data/arcade.json"
const COINS_PER_POUND := 50       # a pound of 2p coins is fifty of them
const DAILY_POUNDS := 5           # the most change the counter hands out a real day
const CLAW_COST := 20             # coins (40p) a go
const PUSHER_FLOAT := 8           # coins already sitting on the shelf
const TOKENS_PER_TOY := 12
const PITY := 4                   # misses in a row after which the claw grips for certain, if you lined it up
const GUTTER := 15.0              # percent of shoved coins that miss the tray
const LANES := 5
const FLAG_COINS := "arcade_coins"
const FLAG_TOKENS := "arcade_tokens"
const FLAG_DAY := "arcade_day"
const FLAG_BOUGHT := "arcade_bought"
const FLAG_MISS := "arcade_claw_miss"

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JsonUtil.read(PATH)
		_cfg = d if d is Dictionary else {"towns": {}}
	return _cfg

static func town(id: String) -> Dictionary:
	return cfg().get("towns", {}).get(id, {})

static func towns() -> Array:
	return cfg().get("towns", {}).keys()

static func _n(d: GameStateData, key: String) -> int:
	var v: Variant = d.flag(key)
	return int(v) if (v is int or v is float) else 0

# ---- the change counter

static func coins(d: GameStateData) -> int:
	return _n(d, FLAG_COINS)

static func tokens(d: GameStateData) -> int:
	return _n(d, FLAG_TOKENS)

## Pounds of change already bought today (a new real day starts again at 0).
static func bought_today(d: GameStateData) -> int:
	return _n(d, FLAG_BOUGHT) if str(d.flag(FLAG_DAY)) == Calendar.today_key() else 0

static func pounds_left(d: GameStateData) -> int:
	return maxi(0, DAILY_POUNDS - bought_today(d))

## Pounds to 2p coins. {ok, coins, line}. Refuses past the daily cap or the purse, taking nothing.
static func buy(d: GameStateData, pounds: int) -> Dictionary:
	if pounds < 1:
		return {"ok": false, "coins": 0, "line": "Not much of a transaction, that."}
	if pounds > pounds_left(d):
		return {"ok": false, "coins": 0, "line": "That's your limit for today. Change is rationed here so nobody spends the rent on penny falls. Come back tomorrow."}
	if not Purse.take(d, pounds):
		return {"ok": false, "coins": 0, "line": "You haven't got the pound%s." % ("" if pounds == 1 else "s")}
	var n := pounds * COINS_PER_POUND
	d.set_flag(FLAG_DAY, Calendar.today_key())
	d.set_flag(FLAG_BOUGHT, bought_today(d) + pounds)
	d.set_flag(FLAG_COINS, coins(d) + n)
	return {"ok": true, "coins": n, "line": "%d two-pence pieces, in a cup that has seen things." % n}

static func spend(d: GameStateData, n: int) -> bool:
	if n < 0 or coins(d) < n:
		return false
	d.set_flag(FLAG_COINS, coins(d) - n)
	return true

static func win_coins(d: GameStateData, n: int) -> void:
	if n > 0:
		d.set_flag(FLAG_COINS, coins(d) + n)

static func win_tokens(d: GameStateData, n: int) -> void:
	if n > 0:
		d.set_flag(FLAG_TOKENS, tokens(d) + n)

# ---- the coin pusher

static func pusher_new() -> Dictionary:
	return {"pile": PUSHER_FLOAT}

## The moving shelf's centre (0 to 1) at `t` seconds: a triangle wave, so it never jumps.
static func shelf_pos(t: float, easy: bool) -> float:
	var period := 5.0 if easy else 3.2
	var p := fposmod(t / period, 1.0)
	return 1.0 - absf(2.0 * p - 1.0)

## Half-width of the sweet spot around the shelf where a coin makes the pile move.
static func window(easy: bool) -> float:
	return 0.25 if easy else 0.14

## One coin dropped at `x` (0 to 1) at time `t`. In the sweet spot it shoves the pile: {1, 2, 2 or 3} coins off
## the front, never more than was already there (the coin you just dropped lands behind the shove). Elsewhere it
## just joins the pile, now and then nudging one over. {sweet, out, token}.
static func pusher_drop(st: Dictionary, x: float, t: float, easy: bool, rng: Rng) -> Dictionary:
	var pile: int = st.pile
	var sweet := absf(x - shelf_pos(t, easy)) <= window(easy)
	var out := 0
	var pushed := 0
	var token := false
	if sweet:
		pushed = mini(int(rng.pick([1, 2, 2, 3])), pile)
		for i in pushed:
			if not rng.chance(GUTTER):  # some coins go down the side gutter, as they do
				out += 1
		token = rng.chance(6.0)
	elif rng.chance(20.0):
		pushed = mini(1, pile)
		out = pushed
	st.pile = pile - pushed + 1
	return {"sweet": sweet, "out": out, "token": token}

# ---- penny falls

static func falls_new(rng: Rng) -> Dictionary:
	var ledge: Array = []
	var tip: Array = []
	for i in LANES:
		ledge.append(0)
		tip.append(rng.roll_int(8, 14))
	return {"ledge": ledge, "tip": tip}

## A coin into lane `lane`. When a ledge tips it falls: four coins in every five come back (the house keeps a
## fifth), and now and then a prize token. {out, token, fell}.
static func falls_drop(st: Dictionary, lane: int, rng: Rng) -> Dictionary:
	lane = clampi(lane, 0, LANES - 1)
	st.ledge[lane] += 1
	if st.ledge[lane] < st.tip[lane]:
		return {"out": 0, "token": false, "fell": false}
	var out := int(st.ledge[lane] * 4 / 5)
	st.ledge[lane] = 0
	st.tip[lane] = rng.roll_int(8, 14)
	return {"out": out, "token": rng.chance(15.0), "fell": true}

# ---- the claw

## Half-width (0 to 1 across the cabinet) within which the claw closes on a toy.
static func claw_reach(easy: bool) -> float:
	return 0.09 if easy else 0.06

## The claw lowered at `x` over toys at `slots`. {reached, won, slot, line}. A claw only ever grips weakly: about
## one go in three even lined up (easier play: two in five), and after PITY misses in a row it holds for certain.
static func claw_play(x: float, slots: Array, miss_streak: int, easy: bool, rng: Rng) -> Dictionary:
	var best := 0
	for i in slots.size():
		if absf(x - float(slots[i])) < absf(x - float(slots[best])):
			best = i
	if absf(x - float(slots[best])) > claw_reach(easy):
		return {"reached": false, "won": false, "slot": best, "line": "It closes on nothing. Hopeful, but nothing."}
	var grip := 40.0 if easy else 32.0
	if miss_streak >= PITY or rng.chance(grip):
		return {"reached": true, "won": true, "slot": best, "line": "A grip, a rise, a wobble... and it holds!"}
	return {"reached": true, "won": false, "slot": best, "line": "It had it, lifted it, then dropped it. Claws are honest about their weakness."}

static func miss_streak(d: GameStateData) -> int:
	return _n(d, FLAG_MISS)

## Books a claw result on the save (the miss streak) and, on a win, the toy. Returns the toy id or "".
static func claw_result(d: GameStateData, res: Dictionary, town_id: String, rng: Rng) -> String:
	if bool(res.won):
		d.set_flag(FLAG_MISS, 0)
		var id := prize_for(town_id, rng)
		if id != "":
			Bag.new(d.bag).add(id, 1)
			TrainerStats.add(d, "arcade_toys")
		return id
	if bool(res.reached):
		d.set_flag(FLAG_MISS, miss_streak(d) + 1)
	return ""

static func prize_for(town_id: String, rng: Rng) -> String:
	var toys: Array = town(town_id).get("toys", [])
	return str(rng.pick(toys)) if not toys.is_empty() else ""

# ---- the prize counter

## Twelve tokens for a toy the player doesn't have yet. Returns the item id, or "" when not enough tokens or
## every toy on this counter is already in the bag.
static func redeem(d: GameStateData, town_id: String) -> String:
	if tokens(d) < TOKENS_PER_TOY:
		return ""
	for id in town(town_id).get("toys", []):
		if int(d.bag.get(str(id), 0)) <= 0:
			d.set_flag(FLAG_TOKENS, tokens(d) - TOKENS_PER_TOY)
			Bag.new(d.bag).add(str(id), 1)
			TrainerStats.add(d, "arcade_toys")
			return str(id)
	return ""
