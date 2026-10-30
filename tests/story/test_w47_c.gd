extends TestCase
## Wave 47 C: residents with wants (Wants), errands (Errands) and the front-room traders.

func _first_trade() -> Dictionary:
	return Wants.all()[0]

func test_data_loads_and_is_sizeable() -> void:
	Wants.reset()
	assert_true(Wants.all().size() >= 140, "about 160 trades")
	assert_true(Wants.traders().size() >= 40, "about 45 front-room traders")
	assert_true(Errands.quests().size() >= 35, "about 40 errands")

func test_data_validates() -> void:
	var zones := ZoneData.load_all()
	var items := ItemDB.load_default()
	assert_eq(Wants.check(zones, items), [])
	assert_eq(Errands.check(zones, items), [])

func test_hook_is_cheap_noop_for_strangers() -> void:
	var h := FakeStoryHost.new()
	var cmds := [{"do": "say", "text": "hi"}]
	assert_eq(ScriptHooks.wrap("testbed", "nobody", cmds, h.data), cmds)

func test_ask_once_a_day_when_you_have_nothing() -> void:
	var t := _first_trade()
	var h := FakeStoryHost.new()
	h.zone = t.zone
	await Commands.new(h, t.npc).run([])
	assert_true(str(h.said).contains(str(t.ask).substr(0, 20)), "the ask is voiced")
	h.said.clear()
	await Commands.new(h, t.npc).run([])
	assert_false(str(h.said).contains(str(t.ask).substr(0, 20)), "but not twice in a day")

func test_swap_takes_wants_gives_gift_and_closes() -> void:
	var t := _first_trade()
	var h := FakeStoryHost.new()
	h.zone = t.zone
	h.data.bag[t.wants.item] = int(t.wants.n) + 1
	h.choices = [0]
	var money := h.data.money
	await Commands.new(h, t.npc).run([])
	assert_eq(int(h.data.bag.get(t.wants.item, 0)), 1, "paid the n wanted")
	if t.gives.has("item"):
		assert_true(int(h.data.bag.get(t.gives.item, 0)) >= 1)
	else:
		assert_eq(h.data.money, money + int(t.gives.money))
	if not bool(t.get("repeat", false)):
		assert_true(h.data.flag("tr_%s_done" % t.id) == true)
		assert_false(Wants.is_open(h.data, t))

func test_declining_costs_nothing() -> void:
	var t := _first_trade()
	var h := FakeStoryHost.new()
	h.zone = t.zone
	h.data.bag[t.wants.item] = int(t.wants.n)
	h.choices = [1]
	await Commands.new(h, t.npc).run([])
	assert_eq(int(h.data.bag.get(t.wants.item, 0)), int(t.wants.n))
	assert_true(Wants.is_open(h.data, t))

func test_full_bag_does_not_eat_the_goods() -> void:
	var t: Dictionary = {"id": "x", "wants": {"item": "peas", "n": 1}, "gives": {"item": "carrots", "n": 1}}
	var h := FakeStoryHost.new()
	h.data.bag = {"peas": 1, "carrots": Bag.MAX_STACK}
	assert_eq(Wants.pay(h.data, t), "")
	assert_eq(int(h.data.bag.peas), 1)

func test_trader_offers_the_shop() -> void:
	var tr: Dictionary = Wants.traders()[0]
	var h := FakeStoryHost.new()
	h.zone = tr.zone
	h.choices = [0]
	await Commands.new(h, tr.npc).run([])
	assert_true(str(h.log).contains("shop:" + str(tr.shop)), "the shop menu opens")

func test_every_shop_item_is_buyable() -> void:
	var db := ItemDB.load_default()
	for tr in Wants.traders():
		var s: Dictionary = db.shops[tr.shop]
		assert_true(s.stock.size() >= 3, tr.shop)
		for id in s.stock:
			assert_true(db.get_item(id).price > 0, "%s %s has a price" % [tr.shop, id])

func test_errand_runs_start_to_reward() -> void:
	Errands.reset()
	var q: Dictionary = Errands.quests()[0]
	var h := FakeStoryHost.new()
	h.choices = [0]
	h.zone = q.start.zone
	await Commands.new(h, q.start.npc).run([])
	assert_eq(Quests.status(h.data, q), Quests.ACTIVE)
	var money := h.data.money
	for i in q.steps.size():
		var s: Dictionary = q.steps[i]
		h.zone = s.zone
		await Commands.new(h, s.npc).run([])
		if i < q.steps.size() - 1:
			assert_eq(Quests.status(h.data, q), Quests.ACTIVE)
	assert_eq(Quests.status(h.data, q), Quests.DONE)
	assert_eq(h.data.money, money + int(q.reward_money))
	assert_true(int(h.data.bag.get(q.reward_item.item, 0)) >= 1)

func test_errand_steps_need_order() -> void:
	Errands.reset()
	var q: Dictionary = Errands.quests()[0]
	var h := FakeStoryHost.new()
	h.data.set_flag(q.start_flag, true)
	var last: Dictionary = q.steps[q.steps.size() - 1]
	h.zone = last.zone
	await Commands.new(h, last.npc).run([])
	assert_false(h.data.flag(last.flag) == true, "the last step waits for the first")

func test_errand_flags_count_as_settable() -> void:
	var s := Quests.all_settable()
	var q: Dictionary = Errands.quests()[0]
	assert_true(s.has(q.start_flag) and s.has(q.done_flag))

func test_no_em_dashes_in_text() -> void:
	for t in Wants.all():
		assert_false((str(t.ask) + str(t.thanks)).contains("—"), t.id)
