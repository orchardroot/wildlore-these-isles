class_name Leases
extends RefCounted
## The Enclosure's leases. After the credits Vane's company sells its leases off at the Exchange, one real tract at a
## time (data/leases/<id>.json, the contract is in docs/leases.md). You win one at auction against rivals whose
## behaviour depends on your guild side, pay a weekly upkeep through the post, and owning it opens a gap in the anchor
## zone's border into a new cul-de-sac zone. You then commission the land's stages with money: each takes one in-game
## season to settle, reshapes the lease zone (Rewild's looks) and lets its returning creatures in.
##
## Closed land is a run of fence tiles across the gap, with a "Private land, Enclosure Ltd" sign (apply()); the gap
## itself is cut into the anchor's border once, when the zone is parsed (shape()), so the validator and the bot see a
## normal edge and the lease zone is reachable like any other.
##
## State is plain flags, absent on an old save:
##   lease_<id>            {since, paid, next, arrears, due}  present only while you hold it
##   lease_tries_<id>      auctions you have sat through for it (seeds the rivals, so a reload can't re-roll them)
##   rewild_lease_<id>     the land's stage, 0..3 (Rewild.stage), kept even if the lease is lost
##   leases_post           {mail [{k, l, day, a}]}
## All sums are STERLING whole pounds as the data authors them; the lease's nation decides the money (Wallet).
## Nothing here makes money: bids, upkeep and stages are only ever taken. Pure logic, no autoloads.

const DIR := "res://data/leases/"
const POST_PATH := "res://data/leases_post.json"
const FLAG_PREFIX := "lease_"
const TRIES_PREFIX := "lease_tries_"
const POST_FLAG := "leases_post"
const SEASON := 30            # in-game days a stage takes to settle
const WEEK := 7
const MAX_CATCH_UP := 120     # days of upkeep settled in one go
const WARN_WEEKS := 3         # missed weeks before the final notice
const FORFEIT_WEEKS := 6      # missed weeks before the Enclosure takes it back
const STEP_PCT := 0.05        # an auction step, of the reserve
const MIN_STEP := 100
const BIG_STEPS := 3          # the "bold bid" jumps this many steps
const STAGE_PCT := 0.08       # of the reserve, times the stage you are commissioning (1, 2, 3)
const TRUST_DISCOUNT := 0.9   # the Trust's friendly valuation for a member
const TRUST_STAGE_CAP := 1    # a Trust member's land is managed for the shoot, not rewilded past this
const LOST_KEEP := 12
const MAIL_KEEP := 10
const SIDES := ["north", "south", "east", "west"]
const OPPOSITE := {"north": "south", "south": "north", "east": "west", "west": "east"}
const DEFAULT_GAP := 3
const MAX_DIG := 24           # tiles a gap may be dug inward to meet the walkable land
const KINDS := ["grouse_moor", "forestry", "estate", "foreshore", "quarry", "hill_farm", "deer_forest", "bog",
	"clay_works", "glen", "fen", "cutaway_bog"]

static var _all: Array = []
static var _by_id: Dictionary = {}
static var _post: Dictionary = {}

static func all() -> Array:
	if _all.is_empty():
		_all = []
		_by_id = {}
		for f in DirAccess.get_files_at(DIR):
			if not f.ends_with(".json"):
				continue
			var raw: Variant = JsonUtil.read(DIR + f)
			if raw is Dictionary and str(raw.get("id", "")) != "":
				_all.append(raw)
				_by_id[str(raw.id)] = raw
		_all.sort_custom(func(a, b): return str(a.id) < str(b.id))
	return _all

static func get_lease(id: String) -> Dictionary:
	all()
	return _by_id.get(id, {})

static func post_text() -> Dictionary:
	if _post.is_empty():
		var d: Variant = JsonUtil.read(POST_PATH)
		_post = d if d is Dictionary else {"letters": {}, "talk": {}}
	return _post

static func talk(key: String) -> String:
	return str(post_text().get("talk", {}).get(key, ""))

## The leases whose gap is cut into this zone.
static func anchored(zone_id: String) -> Array:
	return all().filter(func(l): return str(l.get("anchor", "")) == zone_id)

static func in_zone(zone_id: String) -> Dictionary:
	for l in all():
		if str(l.get("zone", "")) == zone_id:
			return l
	return {}

static func nation_of(id: String) -> String:
	return str(get_lease(id).get("nation", "england"))

static func cur_of(id: String) -> String:
	return Wallet.currency_of_nation(nation_of(id))

static func _i(d: Dictionary, k: String) -> int:
	var v: Variant = d.get(k, 0)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0

# --- state --------------------------------------------------------------------------------

static func key_of(id: String) -> String:
	return FLAG_PREFIX + id

static func flag_key(id: String) -> String:
	return key_of(id)

static func state(data: GameStateData, id: String) -> Dictionary:
	var v: Variant = data.flag(key_of(id))
	return v if v is Dictionary else {}

static func is_owned(data: GameStateData, id: String) -> bool:
	return not state(data, id).is_empty()

static func owned(data: GameStateData) -> Array:
	var out := []
	for l in all():
		if is_owned(data, str(l.id)):
			out.append(str(l.id))
	return out

static func tries(data: GameStateData, id: String) -> int:
	return _i({"n": data.flag(TRIES_PREFIX + id)}, "n")

static func stage(data: GameStateData, id: String) -> int:
	return Rewild.stage(data, site_id(id))

static func stage_cap(data: GameStateData) -> int:
	return TRUST_STAGE_CAP if Guilds.is_member(data, "trust") else Rewild.WILD

static func site_id(id: String) -> String:
	return "lease_" + id

static func pending(data: GameStateData, id: String) -> bool:
	return _i(state(data, id), "due") > 0

static func arrears(data: GameStateData, id: String) -> int:
	return _i(state(data, id), "arrears")

## What the ranger on the land says, by how far it has come back.
static func ranger_line(data: GameStateData, id: String) -> String:
	var lines: Array = get_lease(id).get("ranger", [])
	if lines.is_empty():
		return "Thank you for the land."
	return str(lines[clampi(stage(data, id), 0, lines.size() - 1)])

## Why this lease can't be bid for right now ("" when it can).
static func unavailable(data: GameStateData, id: String) -> String:
	var l := get_lease(id)
	if l.is_empty():
		return "There is no such lot."
	if is_owned(data, id):
		return "You hold it already."
	var gate := str(l.get("unlock_flag", ""))
	if gate != "" and data.flag(gate) != true:
		return "The Enclosure isn't selling yet. Lord Vane's lot still has something to say first."
	return ""

# --- money --------------------------------------------------------------------------------

static func _local(gbp: int, id: String) -> int:
	return Wallet.localise(gbp, cur_of(id))

static func reserve_of(id: String) -> int:
	return _i(get_lease(id), "reserve")

static func upkeep_of(id: String) -> int:
	return _i(get_lease(id), "upkeep")

## What a stage costs to commission: the next one up, in sterling.
static func stage_cost(data: GameStateData, id: String) -> int:
	return roundi(float(reserve_of(id)) * STAGE_PCT * float(stage(data, id) + 1))

# --- the auction --------------------------------------------------------------------------

## A fixed die roll in 0..1 for this lease, attempt and purpose.
static func _u(id: String, attempt: int, salt: String) -> float:
	var h := ("%s|%d|%s" % [id, attempt, salt]).hash()
	h = ((h ^ (h >> 16)) * 0x45d9f3b) & 0xFFFFFFFF
	h = ((h ^ (h >> 16)) * 0x45d9f3b) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 65536.0

static func step_of(id: String) -> int:
	return maxi(MIN_STEP, roundi(float(_local(reserve_of(id), id)) * STEP_PCT / float(MIN_STEP)) * MIN_STEP)

## The rivals for this sitting: [{name, ceiling, bold}], ceilings in the lease's money. Who turns up, and how hard
## they bid, depends on your guild side: the Ramblers have the Trust against them, a Trustee has the Trust on side
## (no bid, and a friendly valuation), anyone else gets the Trust at an ordinary appetite.
static func rivals_for(data: GameStateData, id: String, attempt: int) -> Array:
	var l := get_lease(id)
	var res := float(_local(reserve_of(id), id))
	var out := []
	out.append({"name": "The Enclosure's liquidator", "bold": false,
		"ceiling": roundi(res * (1.05 + 0.30 * _u(id, attempt, "liq")))})
	match str(l.get("kind", "")):
		"grouse_moor", "estate", "deer_forest":
			out.append({"name": "A shooting syndicate", "bold": true,
				"ceiling": roundi(res * (1.0 + 0.55 * _u(id, attempt, "syn")))})
		"forestry":
			out.append({"name": "A timber investment fund", "bold": true,
				"ceiling": roundi(res * (1.0 + 0.50 * _u(id, attempt, "fund")))})
		_:
			out.append({"name": "A man from a development company", "bold": true,
				"ceiling": roundi(res * (1.0 + 0.45 * _u(id, attempt, "dev")))})
	if bool(l.get("trust_wants", false)) and not Guilds.is_member(data, "trust"):
		var lo := 1.7 if Guilds.is_member(data, "ramblers") else 1.25
		var span := 0.45 if Guilds.is_member(data, "ramblers") else 0.30
		out.append({"name": "The Heritage Trust", "bold": Guilds.is_member(data, "ramblers"),
			"ceiling": roundi(res * (lo + span * _u(id, attempt, "trust")))})
	return out

## Opens a sitting: the lot comes up at the reserve (a Trustee gets the Trust's friendly valuation). {} if you can't.
## The attempt counter is saved at once, so walking out and coming back faces fresh bidders and a reload faces the same.
static func auction_open(data: GameStateData, id: String) -> Dictionary:
	if unavailable(data, id) != "":
		return {}
	var attempt := tries(data, id)
	data.set_flag(TRIES_PREFIX + id, attempt + 1)
	var res := _local(reserve_of(id), id)
	if Guilds.is_member(data, "trust") and bool(get_lease(id).get("trust_wants", false)):
		res = roundi(float(res) * TRUST_DISCOUNT / float(MIN_STEP)) * MIN_STEP
	return {"id": id, "cur": cur_of(id), "reserve": res, "step": step_of(id), "bid": 0, "by": "", "over": false,
		"won": false, "price": 0, "round": 0, "rivals": rivals_for(data, id, attempt), "notes": []}

## The least you may bid now.
static func min_bid(a: Dictionary) -> int:
	return int(a.reserve) if int(a.bid) == 0 else int(a.bid) + int(a.step)

## You bid `min_bid + extra_steps` steps. The rivals answer: the keenest who still can raises, the rest drop out as
## they hit their ceilings; if nobody can the hammer falls and the lot is yours (and paid for). Returns "" or why not.
static func bid(a: Dictionary, data: GameStateData, extra_steps := 0) -> String:
	if bool(a.over):
		return "The hammer has fallen."
	var amount := min_bid(a) + maxi(0, extra_steps) * int(a.step)
	if not Wallet.can_afford(data, amount, str(a.cur)):
		return "You'd need %s to bid that." % Wallet.fmt(amount, str(a.cur))
	a.bid = amount
	a.by = "you"
	a.round = int(a.round) + 1
	a.notes = []
	var best: Dictionary = {}
	for r in a.rivals:
		if bool(r.get("out", false)):
			continue
		if int(r.ceiling) < amount + int(a.step):
			r["out"] = true
			a.notes.append("%s drops out." % r.name)
		elif best.is_empty() or int(r.ceiling) > int(best.ceiling):
			best = r
	if best.is_empty():
		return _hammer(a, data, true)
	var raise_to := mini(int(best.ceiling), amount + int(a.step) * (2 if bool(best.bold) else 1))
	a.bid = raise_to
	a.by = str(best.name)
	a.notes.append("%s bids %s." % [best.name, Wallet.fmt(raise_to, str(a.cur))])
	return ""

static func pass_lot(a: Dictionary, data: GameStateData) -> String:
	if bool(a.over):
		return "The hammer has fallen."
	a.notes = []
	return _hammer(a, data, false)

static func _hammer(a: Dictionary, data: GameStateData, yours: bool) -> String:
	a.over = true
	a.won = yours
	if not yours:
		a.notes.append("Sold to %s for %s." % [a.by if str(a.by) != "you" else "the room", Wallet.fmt(int(a.bid), str(a.cur))])
		return ""
	var id := str(a.id)
	if not Wallet.spend(data, int(a.bid), str(a.cur)):
		a.won = false
		return "You'd need %s to bid that." % Wallet.fmt(int(a.bid), str(a.cur))
	a.price = int(a.bid)
	var l := get_lease(id)
	Economist.note(data, "winners_curse", {"text": str(l.get("name", id)),
		"over": roundi(100.0 * (float(a.bid) / maxf(1.0, float(a.reserve)) - 1.0))})
	data.set_flag(key_of(id), {"since": data.day_count, "paid": Wallet.in_sterling(int(a.bid), str(a.cur)),
		"next": data.day_count + WEEK, "arrears": 0, "due": 0})
	data.flags.erase(TRIES_PREFIX + id)
	Standing.add(data, str(l.get("nation", "england")), 5)
	_mail(data, "welcome", id, data.day_count, int(a.bid))
	a.notes.append("Sold to you for %s. The Enclosure's solicitor shakes your hand as though it hurts." % Wallet.fmt(int(a.bid), str(a.cur)))
	return ""

# --- rewilding the land --------------------------------------------------------------------

## Why you can't commission the next stage ("" when you can).
static func commission_blocked(data: GameStateData, id: String) -> String:
	if not is_owned(data, id):
		return "It isn't yours."
	if stage(data, id) >= Rewild.WILD:
		return "It is as wild as it is going to get."
	if pending(data, id):
		return "The last stage is still settling. Land doesn't do next-day delivery."
	if arrears(data, id) > 0:
		return "Clear the upkeep first. The contractors read the post."
	if stage(data, id) >= stage_cap(data):
		return "The Heritage Trust manages your land for the shoot while you are a Trustee. Resign to let it go wild."
	return ""

static func commission(data: GameStateData, id: String) -> String:
	var why := commission_blocked(data, id)
	if why != "":
		return why
	var cur := cur_of(id)
	var cost := _local(stage_cost(data, id), id)
	if not Wallet.spend(data, cost, cur):
		return "You'd need %s for the contractors." % Wallet.fmt(cost, cur)
	var st := state(data, id)
	st["due"] = data.day_count
	st["spent"] = _i(st, "spent") + Wallet.in_sterling(cost, cur)
	data.set_flag(key_of(id), st)
	return ""

## Stages that have seen a full season move on. Returns the lease ids that changed.
static func settle(data: GameStateData) -> Array:
	var out := []
	for id in owned(data):
		var st := state(data, id)
		var due := _i(st, "due")
		if due > 0 and data.day_count >= due + SEASON:
			st["due"] = 0
			data.set_flag(key_of(id), st)
			data.set_flag(Rewild.flag_key(site_id(id)), mini(Rewild.WILD, stage(data, id) + 1))
			_mail(data, "stage", id, data.day_count, stage(data, id))
			out.append(id)
	return out

## A Rewild-shaped site for the lease zone, so Rewild.apply reshapes it and lets the returning creatures in.
static func rewild_site(l: Dictionary) -> Dictionary:
	var rw: Dictionary = l.get("rewild", {})
	if rw.is_empty():
		return {}
	return {"id": site_id(str(l.id)), "zone": str(l.zone), "rect": rw.get("rect", [0, 0, 0, 0]),
		"biome": str(rw.get("biome", "")), "encounters": rw.get("encounters", []), "tasks": []}

static func rewild_sites_in(zone_id: String) -> Array:
	var out := []
	for l in all():
		if str(l.get("zone", "")) == zone_id:
			var s := rewild_site(l)
			if not s.is_empty():
				out.append(s)
	return out

# --- upkeep and the post -------------------------------------------------------------------

## The days pass: weekly upkeep is taken from the purse (the other purse at the tourist rate if short), a missed week
## is a letter, six missed weeks and the Enclosure takes the land back (the stage stays). Also settles stages.
static func tick(data: GameStateData, day: int) -> Array:
	var out := []
	for id in owned(data):
		var st := state(data, id)
		var steps := 0
		while day >= _i(st, "next") and steps < MAX_CATCH_UP / WEEK + 1:
			steps += 1
			var due_day := _i(st, "next")
			st["next"] = due_day + WEEK
			var cur := cur_of(id)
			var cost := _local(upkeep_of(id), id)
			var paid: Dictionary = Wallet.pay(data, cost, cur, Wallet.shop_rate(data, cur))
			if bool(paid.get("ok", false)):
				st["arrears"] = 0
				_mail(data, "upkeep", id, due_day, cost)
			else:
				st["arrears"] = _i(st, "arrears") + 1
				if _i(st, "arrears") >= FORFEIT_WEEKS:
					data.flags.erase(key_of(id))
					_mail(data, "forfeit", id, due_day, cost)
					out.append(id)
					st = {}
					break
				_mail(data, "final" if _i(st, "arrears") >= WARN_WEEKS else "arrears", id, due_day, cost)
		if not st.is_empty():
			data.set_flag(key_of(id), st)
	out.append_array(settle(data))
	return out

static func _post_st(data: GameStateData, create: bool) -> Dictionary:
	var v: Variant = data.flag(POST_FLAG)
	if not (v is Dictionary):
		if not create:
			return {}
		v = {}
		data.set_flag(POST_FLAG, v)
	var p: Dictionary = v
	if not (p.get("mail") is Array):
		p["mail"] = []
	return p

## Queues a letter. One of each kind per lease waits at a time: a newer one replaces the older.
static func _mail(data: GameStateData, kind: String, id: String, day: int, amount: int) -> void:
	var m: Array = _post_st(data, true).mail
	for i in range(m.size() - 1, -1, -1):
		if str(m[i].k) == kind and str(m[i].l) == id:
			m.remove_at(i)
	m.append({"k": kind, "l": id, "day": day, "a": amount})
	while m.size() > MAIL_KEEP:
		m.remove_at(0)

static func letters_waiting(data: GameStateData) -> Array:
	var v: Variant = data.flag(POST_FLAG)
	if not (v is Dictionary) or not (v.get("mail") is Array):
		return []
	return (v.mail as Array).duplicate(true)

## Takes the waiting post out of the box: the lines for the textbox.
static func collect_letters(data: GameStateData) -> Array:
	var got := letters_waiting(data)
	if got.is_empty():
		return []
	_post_st(data, true).mail = []
	var out := []
	for m in got:
		out.append_array(letter_lines(m, data))
	return out

## `data` fills {mx} {player} (Mr / Ms / Mx and your name, see Looks); without it the solicitors write to Sir or Madam.
static func letter_lines(m: Dictionary, data: GameStateData = null) -> Array:
	var t: Dictionary = post_text().get("letters", {}).get(str(m.k), {})
	if t.is_empty():
		return []
	var l := get_lease(str(m.l))
	var cur := cur_of(str(m.l))
	var fill := func(s: String) -> String:
		return s.replace("{lease}", str(l.get("name", "the land"))).replace("{amount}", Wallet.fmt(int(m.get("a", 0)), cur)) \
			.replace("{stage}", Rewild.stage_name(int(m.get("a", 0)))).replace("{day}", str(int(m.get("day", 0)))) \
			.replace("{mx} {player}", "Sir or Madam" if data == null else "%s %s" % [Looks.pronoun(data, "Mx"), data.player_name])
	var out := ["A letter from %s." % fill.call(str(t.get("from", "")))]
	for s in t.get("text", []):
		out.append(fill.call(str(s)))
	return out

# --- the gap in the anchor's border ---------------------------------------------------------

static func gap_of(l: Dictionary) -> Dictionary:
	var g: Dictionary = l.get("gap", {})
	return {"at": _i(g, "at"), "width": maxi(1, _i(g, "width") if g.has("width") else DEFAULT_GAP), "offset": _i(g, "offset")}

## The tiles of the lease's gap on the anchor's border, in lane order.
static func border_tiles(z: ZoneData, l: Dictionary) -> Array:
	var side := str(l.get("side", ""))
	var g := gap_of(l)
	var out := []
	var first: int = int(g.at) - int(g.width) / 2
	for o in int(g.width):
		var i := first + o
		match side:
			"north": out.append(Vector2i(i, 0))
			"south": out.append(Vector2i(i, z.height - 1))
			"west": out.append(Vector2i(0, i))
			"east": out.append(Vector2i(z.width - 1, i))
	return out

static func _inward(side: String) -> Vector2i:
	match side:
		"north": return Vector2i(0, 1)
		"south": return Vector2i(0, -1)
		"west": return Vector2i(1, 0)
	return Vector2i(-1, 0)

## Called as the anchor zone is parsed: registers the edge into the lease zone and cuts the gap. The gap is a track
## of the lease's width from the border, dug inward until it meets land the spawn can walk to (so every anchor needs
## only a position along its border). Never fails loudly here; the problems land in parse_errors for the validator.
static func shape(z: ZoneData) -> void:
	for l in anchored(z.id):
		var side := str(l.get("side", ""))
		if side not in SIDES or z.edges.has(side):
			z.parse_errors.append("lease %s: %s edge of '%s' is not free" % [l.get("id", "?"), side, z.id])
			continue
		z.edges[side] = {"to": str(l.zone), "offset": _i(gap_of(l), "offset"), "lease": str(l.id)}
		_dig(z, l)

static func _dig(z: ZoneData, l: Dictionary) -> void:
	var side := str(l.side)
	var inward := _inward(side)
	var lane := border_tiles(z, l)
	if lane.is_empty() or not z.in_bounds(lane[0]) or not z.in_bounds(lane[lane.size() - 1]):
		z.parse_errors.append("lease %s: the gap is off the %s border of '%s'" % [l.get("id", "?"), side, z.id])
		return
	var seen: Dictionary = z.reachable(z.spawn) if z.walkable(z.spawn) else {}
	var mid: Vector2i = lane[lane.size() / 2]
	var depth := -1
	for k in range(1, MAX_DIG + 1):
		var p: Vector2i = mid + inward * k
		if not z.in_bounds(p):
			break
		if seen.has(p):
			depth = k
			break
	if depth < 0:
		z.parse_errors.append("lease %s: the gap in '%s' meets no land the spawn can reach within %d tiles" % [l.get("id", "?"), z.id, MAX_DIG])
		return
	var level: int = z.height_at(mid + inward * depth)
	var dug := {}
	for t in lane:
		for k in range(0, depth + 1):
			var p: Vector2i = t + inward * k
			if z.tiles[p.y][p.x] in ["building", "door"]:
				z.parse_errors.append("lease %s: the gap in '%s' runs into a building at %d,%d" % [l.get("id", "?"), z.id, p.x, p.y])
				return
			dug[p] = true
	for p in dug:
		if z.tiles[p.y][p.x] in ZoneData.RAIL_TILES:  # a track across a railway is a level crossing, the line stays whole
			z.tiles[p.y][p.x] = "level_crossing"
			z.chars[p.y][p.x] = "&"
			continue
		z.tiles[p.y][p.x] = "path"
		z.chars[p.y][p.x] = "#"
		z.heights[p.y][p.x] = level
		z.blocked.erase(p)
	for i in range(z.props.size() - 1, -1, -1):  # nothing stands in the track
		var pr: Dictionary = z.props[i]
		if str(pr.get("type", "")) != "building" and dug.has(Vector2i(int(pr.get("x", -1)), int(pr.get("y", -1)))):
			z.props.remove_at(i)

## As the overworld loads the anchor zone: unowned land is fenced across the gap with the Enclosure's sign; owned
## land is the open track the parse left. Call after the zone is parsed, before it is built.
static func apply(data: GameStateData, z: ZoneData) -> void:
	for l in anchored(z.id):
		if is_owned(data, str(l.id)) or not z.edges.has(str(l.get("side", ""))):
			continue
		var lane := border_tiles(z, l)
		if lane.is_empty() or not z.in_bounds(lane[0]) or not z.in_bounds(lane[lane.size() - 1]):
			continue
		for t in lane:
			z.tiles[t.y][t.x] = "fence"
			z.chars[t.y][t.x] = "F"
		var at: Vector2i = lane[lane.size() / 2] + _inward(str(l.side))
		z.signs.append({"x": at.x, "y": at.y, "title": "Private land",
			"text": "PRIVATE LAND. Enclosure Ltd. No public right of way. Keepers patrol. (Lot for sale at the Exchange.)"})
		z.blocked[at] = true

# --- the validator --------------------------------------------------------------------------

## Problems with data/leases and the zones they name. `zones` is ZoneData.load_all() (the edge and gap already
## shaped in), `dex` the creature dex.
static func problems(zones: Dictionary, dex: Dex) -> Array:
	var e := []
	var seen_ids := {}
	var seen_gaps := {}
	for l in all():
		var id := str(l.get("id", ""))
		var tag := "lease %s: " % id
		if seen_ids.has(id):
			e.append(tag + "duplicate id")
		seen_ids[id] = true
		for k in ["name", "nation", "kind", "anchor", "side", "zone", "blurb", "unlock_flag"]:
			if str(l.get(k, "")) == "":
				e.append(tag + "missing '%s'" % k)
		if not Standing.is_nation(str(l.get("nation", ""))):
			e.append(tag + "unknown nation '%s'" % l.get("nation", ""))
		if str(l.get("kind", "")) not in KINDS:
			e.append(tag + "unknown kind '%s'" % l.get("kind", ""))
		if _i(l, "reserve") < 1000 or _i(l, "upkeep") < 1:
			e.append(tag + "needs a reserve (at least 1000) and an upkeep")
		if _i(l, "upkeep") * 52 > _i(l, "reserve"):
			e.append(tag + "a year's upkeep costs more than the lease")
		for t in [str(l.get("blurb", "")), str(l.get("name", ""))]:
			if t.contains("—"):
				e.append(tag + "no em-dashes in player-facing text")
		var side := str(l.get("side", ""))
		var anchor_id := str(l.get("anchor", ""))
		var zid := str(l.get("zone", ""))
		if not zones.has(anchor_id):
			e.append(tag + "anchor zone '%s' does not exist" % anchor_id)
			continue
		var anchor: ZoneData = zones[anchor_id]
		if anchor.kind == "interior":
			e.append(tag + "anchor '%s' must be an outdoor zone" % anchor_id)
		var raw: Variant = JsonUtil.read("res://data/zones/%s.json" % anchor_id)
		if raw is Dictionary and raw.get("edges", {}).has(side):
			e.append(tag + "the %s edge of '%s' is already used" % [side, anchor_id])
		var gk := "%s|%s" % [anchor_id, side]
		if seen_gaps.has(gk):
			e.append(tag + "shares the %s edge of '%s' with lease %s" % [side, anchor_id, seen_gaps[gk]])
		seen_gaps[gk] = id
		if not zones.has(zid):
			e.append(tag + "zone '%s' does not exist" % zid)
			continue
		var z: ZoneData = zones[zid]
		if z.kind == "interior":
			e.append(tag + "zone '%s' must be outdoors" % zid)
		if z.edges.size() != 1 or not z.edges.has(OPPOSITE.get(side, "")):
			e.append(tag + "zone '%s' must have exactly one edge, the %s, back to '%s' (a cul-de-sac)" % [zid, OPPOSITE.get(side, "?"), anchor_id])
		else:
			var back: Dictionary = z.edges[OPPOSITE[side]]
			if str(back.get("to", "")) != anchor_id:
				e.append(tag + "zone '%s' edge goes to '%s', not the anchor" % [zid, back.get("to", "")])
			if _i(back, "offset") != -_i(gap_of(l), "offset"):
				e.append(tag + "the back edge needs offset %d" % -_i(gap_of(l), "offset"))
		for w in z.warps:
			var tz: String = str(w.get("to", ""))
			if not zones.has(tz) or zones[tz].kind != "interior":
				e.append(tag + "zone '%s' has a warp to '%s' which is not an interior (no shortcuts)" % [zid, tz])
		var rw: Dictionary = l.get("rewild", {})
		if rw.is_empty():
			e.append(tag + "needs a 'rewild' block (biome, rect, encounters)")
		else:
			if Rewild.looks(str(rw.get("biome", ""))).size() != 4:
				e.append(tag + "rewild biome '%s' has no four looks in data/rewild.json" % rw.get("biome", ""))
			var r: Array = rw.get("rect", [])
			if r.size() != 4 or int(r[0]) < 0 or int(r[1]) < 0 or int(r[0]) + int(r[2]) > z.width or int(r[1]) + int(r[3]) > z.height:
				e.append(tag + "rewild rect is outside the zone")
			var encs: Array = rw.get("encounters", [])
			if encs.size() != 3:
				e.append(tag + "rewild needs three encounter lists (stages 1 to 3)")
			for stage_list in encs:
				for en in stage_list:
					if not dex.has(str(en.get("species", ""))):
						e.append(tag + "returning creature '%s' does not exist" % en.get("species", ""))
		if (l.get("ranger", []) as Array).size() != 4:
			e.append(tag + "needs four ranger lines, one per stage")
		var plaques := 0
		for s in z.signs:
			if str(s.get("plaque", "")) != "":
				plaques += 1
		if plaques < 2:
			e.append(tag + "zone '%s' needs at least two plaques on the land's history" % zid)
	var post: Dictionary = post_text().get("letters", {})
	for k in ["welcome", "upkeep", "arrears", "final", "forfeit", "stage"]:
		if not post.has(k):
			e.append("leases_post: no letter '%s'" % k)
	return e
