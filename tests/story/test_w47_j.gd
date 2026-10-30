extends TestCase
## Wave 47 J: the cross-wiring pass. Chapbooks and curios in trades and peddlers, the runtime consumers that read
## the w47_a / w47_d item files, and the one-offer-per-talk cap in ScriptHooks.wrap.

func _items() -> ItemDB:
	return ItemDB.load_default()

func _kind(items: ItemDB, id: String) -> String:
	return str(items.get_item(id).get("kind", ""))

func test_trades_give_chapbooks_and_use_curios() -> void:
	Wants.reset()
	var items := _items()
	var chaps := 0
	var curios := 0
	for t in Wants.all():
		var g: Dictionary = t.gives
		var w: Dictionary = t.wants
		if g.has("item") and _kind(items, str(g.item)) == "chapbook":
			chaps += 1
			assert_true(items.has(str(g.item)))
		if (g.has("item") and _kind(items, str(g.item)) == "curio") or _kind(items, str(w.item)) == "curio":
			curios += 1
		assert_false(str(t.ask).contains("—"))
	assert_true(chaps >= 12, "chapbook trades: %d" % chaps)
	assert_true(curios >= 20, "curio trades: %d" % curios)
	assert_eq(Wants.check(ZoneData.load_all(), items), [])

func test_chapbook_trades_are_fair() -> void:
	var items := _items()
	for t in Wants.all():
		if t.gives.has("item") and _kind(items, str(t.gives.item)) == "chapbook":
			var paid := int(items.get_item(str(t.wants.item)).get("price", 0)) * int(t.wants.n)
			var got := int(items.get_item(str(t.gives.item)).get("price", 0))
			assert_true(paid * 10 >= got * 6, "%s: pay %d for %d" % [t.id, paid, got])

func test_six_peddlers_stock_chapbooks_and_charms() -> void:
	var items := _items()
	var seen := {}
	var n := 0
	for z in ["birmingham_home3", "glastonbury_home3", "bath_home4", "galway_home_bad", "kerry_muckross", "harris_weaver"]:
		var shop: Dictionary = items.shops["home_" + z]
		var books := 0
		var charms := 0
		for id in shop.stock:
			assert_true(items.has(str(id)))
			match _kind(items, str(id)):
				"chapbook": books += 1
				"charm": charms += 1
		assert_true(books >= 5 and books <= 7, "%s books %d" % [z, books])
		assert_true(charms >= 1 and charms <= 2, "%s charms %d" % [z, charms])
		var key := ",".join(shop.stock.duplicate())
		assert_false(seen.has(key), "no two peddlers alike")
		seen[key] = true
		n += 1
	assert_eq(n, 6)

func test_search_finds_curios_and_chapbooks() -> void:
	assert_eq(Search.curio_ids().size(), 60)
	assert_eq(Search.chapbook_ids().size(), 60)
	var z := ZoneData.load_id("macc_home")
	var data := GameStateData.new()
	var curio := false
	var book := false
	for i in 4000:
		var s := Search.stash(z, {"type": "bookshelf", "x": i % 60, "y": i / 60}, data, i)
		if s.has("curio"):
			curio = true
			assert_true(_items().has(str(s.curio)))
		if s.has("item") and _kind(_items(), str(s.item)) == "chapbook":
			book = true
	assert_true(curio, "a search yields a curio")
	assert_true(book, "a search yields a chapbook")

func test_poi_caches_find_curios() -> void:
	var ids := Poi.curio_ids()
	assert_eq(ids.size(), 60)
	var n := 0
	for p in Poi.all():
		if bool(p.get("curio", false)):
			n += 1
			assert_true(_items().has(Poi.curio_for(p, ids)))
	assert_true(n >= 1, "some caches hold a curio")

func test_trump_prizes_include_chapbooks() -> void:
	assert_eq(Trumps.chapbook_ids().size(), 60)
	var books := 0
	var regions := Trumps.album(GameStateData.new())
	for g in regions:
		var pz := Trumps.prize(str(g.region))
		if pz.kind == "chapbook":
			books += 1
			assert_true(_items().has(str(pz.item)))
	assert_true(books >= 1, "a region pays a chapbook (%d regions)" % regions.size())

# ---- one offer per talk

var FZ := ""
var FN := ""

## A real interior resident who plays Trumps and has no other business, so every hook can be made to qualify.
func _pick_resident() -> void:
	Wants.all()
	Errands._build()
	KeeperIntel._lookup()
	Poi.all()
	var idx := ZoneIndex.get_index()
	for zid in idx.zones:
		if str(idx.zones[zid].get("kind", "")) != "interior":
			continue
		var zd := ZoneData.load_id(str(zid))
		if zd == null:
			continue
		for n in zd.npcs:
			var k := "%s|%s" % [zid, n.id]
			if Trumps.plays(str(zid), str(n.id)) and not Wants._by_npc.has(k) and not Wants._traders.has(k) and not Errands._index.has(k) \
					and not KeeperIntel._index.has(k) and not Poi._mentions.has(k):
				FZ = str(zid)
				FN = str(n.id)
				return

func _fake_resident(h: FakeStoryHost) -> Dictionary:
	_pick_resident()
	assert_true(FZ != "", "found a Trumps player to dress up")
	var trade := {"id": "tr_w47j", "zone": FZ, "npc": FN, "wants": {"item": "potatoes", "n": 1}, "gives": {"money": 50}, "ask": "Spuds?", "thanks": "Ta.", "repeat": false}
	Wants._by_npc[FZ + "|" + FN] = [trade]
	Wants._by_id["tr_w47j"] = trade
	Wants._traders[FZ + "|" + FN] = {"zone": FZ, "npc": FN, "shop": "home_bath_home4", "line": "Have a browse."}
	Errands._build()
	Errands._index[FZ + "|" + FN] = [{"q": Errands.quests()[0], "role": -1}]
	KeeperIntel._lookup()[FZ + "|" + FN] = [KeeperIntel.ids()[0], 0]
	var poi: Dictionary = Poi.all().filter(func(p): return not p.get("mentioned_by", {}).is_empty())[0]
	Poi._mentions[FZ + "|" + FN] = [poi]
	h.data.set_flag(Trumps.FLAG_STARTER, true)
	h.data.bag["potatoes"] = 2
	return trade

func _cleanup() -> void:
	for d in [Wants._by_npc, Wants._traders, Errands._index, KeeperIntel._index, Poi._mentions]:
		d.erase(FZ + "|" + FN)
	Wants._by_id.erase("tr_w47j")

func _prompts(cmds: Array) -> Array:
	var out := []
	for c in cmds:
		if c.get("do", "") == "choice":
			out.append(str(c.text))
		if c.has("then"):
			out.append_array(_prompts(c.then))
	return out

func test_one_offer_prompt_per_talk() -> void:
	var h := FakeStoryHost.new()
	var trade := _fake_resident(h)
	var base := [{"do": "say", "text": "Hello."}]
	var out := ScriptHooks.wrap(FZ, FN, base, h.data)
	assert_eq(_prompts(out).size(), 1, "one prompt: %s" % [_prompts(out)])
	assert_eq(_prompts(out)[0], "Help them out?", "errand first")
	assert_true(str(out).contains("Keeper") or out.size() > 3, "the one-off lines still appear")
	# no errand: the trade comes next
	Errands._index.erase(FZ + "|" + FN)
	out = ScriptHooks.wrap(FZ, FN, base, h.data)
	assert_eq(_prompts(out).size(), 1)
	assert_true(_prompts(out)[0].begins_with("Give them"), "trade second")
	# no wants met: the shop
	h.data.bag.erase("potatoes")
	out = ScriptHooks.wrap(FZ, FN, base, h.data)
	assert_eq(_prompts(out), ["Have a look?"], "shop third")
	assert_true(str(out).contains("Spuds?"), "the unmet ask is a line, not a prompt")
	# no shop: Trumps is all that is left
	Wants._traders.erase(FZ + "|" + FN)
	out = ScriptHooks.wrap(FZ, FN, base, h.data)
	assert_eq(_prompts(out), ["Fancy a game of Trumps?"], "Trumps last")
	_cleanup()
	assert_eq(trade.id, "tr_w47j")

func test_strangers_untouched() -> void:
	var h := FakeStoryHost.new()
	var cmds := [{"do": "say", "text": "hi"}]
	assert_eq(ScriptHooks.wrap("testbed", "nobody", cmds, h.data), cmds)
