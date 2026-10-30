extends TestCase
## Know your Keeper (KeeperIntel): types, what bites, gossip, the hook and the hall door.

var chart := TypeChart.load_default()

func test_every_keeper_has_types_and_something_that_bites() -> void:
	for k in KeeperIntel.ids():
		assert_true(KeeperIntel.team(str(k)).size() >= 3, "%s has a team" % k)
		assert_true(KeeperIntel.types(str(k)).size() >= 1, "%s leans on something" % k)
		var b := KeeperIntel.beats(str(k), chart)
		assert_true(b.size() >= 1 and b.size() <= 3, "%s has 1 to 3 types that bite" % k)
		for t in b:
			assert_true(str(t) in chart.types, "%s is a real type" % t)
			var n := 0
			for sp in KeeperIntel.team(str(k)):
				if chart.effectiveness(str(t), KeeperIntel._species_types(str(sp))) > 1.0:
					n += 1
			assert_true(n >= 1, "%s really bites %s" % [t, k])

func test_known_cases() -> void:
	assert_eq(KeeperIntel.beats("isla", chart)[0], "stone")
	assert_true("storm" in KeeperIntel.beats("maud", chart))
	assert_true("brook" in KeeperIntel.types("maud"))
	assert_eq(KeeperIntel.id_of_trainer("keeper_ray_rematch"), "ray")
	assert_eq(KeeperIntel.id_of_trainer("side_isla"), "")

func test_gossip_ids_exist_and_no_em_dashes() -> void:
	for k in KeeperIntel.ids():
		var g := KeeperIntel.gossip(str(k))
		assert_eq(g.size(), 4, "%s has four lines" % k)
		for e in g:
			var z = JsonUtil.read("res://data/zones/%s.json" % e.zone)
			assert_true(z is Dictionary, "zone %s exists" % e.zone)
			var ok := false
			for n in z.get("npcs", []):
				if str(n.get("id", "")) == str(e.npc):
					ok = true
			assert_true(ok, "npc %s in %s" % [e.npc, e.zone])
			assert_false(str(e.line).contains("—"), "no em-dash")
			assert_false(str(e.line).contains("–"), "no en-dash")

func test_hook_adds_once_and_reveals_a_member() -> void:
	var d := GameStateData.new()
	var g: Dictionary = KeeperIntel.gossip("maud")[0]
	var base := [{"do": "say", "who": "", "text": "Hello."}]
	assert_eq(KeeperIntel.hook("macclesfield", "x", base, d), base, "strangers unchanged")
	assert_eq(KeeperIntel.team_known(d, "maud").size(), 0)
	var out := KeeperIntel.hook(str(g.zone), str(g.npc), base, d)
	assert_eq(out.size(), 3)
	assert_eq(out[1].text, g.line)
	d.set_flag(str(out[2].flag), true)
	assert_eq(KeeperIntel.hook(str(g.zone), str(g.npc), base, d), base, "once")
	assert_eq(KeeperIntel.team_known(d, "maud").size(), 1)
	assert_eq(KeeperIntel.hints(d, "maud").size(), 1)
	d.set_flag("trainer_keeper_maud", true)
	assert_eq(KeeperIntel.team_known(d, "maud").size(), 3, "beaten shows all")

func test_door_line_on_every_hall() -> void:
	var d := GameStateData.new()
	for k in KeeperIntel.ids():
		var hall := str(KeeperIntel.KEEPERS[k][2])
		var z = JsonUtil.read("res://data/zones/%s.json" % hall)
		var hit := 0
		for s in z.get("signs", []):
			var l := KeeperIntel.door_line(hall, d, str(s.get("text", "")), chart)
			if not l.is_empty():
				hit += 1
				assert_true(str(l[0]).contains("moves bite"))
				assert_true(str(l[0]).contains(KeeperIntel.name_of(str(k))))
		assert_true(hit >= 1, "%s hall has a sign that carries the line" % k)
	assert_eq(KeeperIntel.door_line("buxton", d, "Keeper", chart), [])

func test_has_bite() -> void:
	assert_true(KeeperIntel.has_bite(["kin", "storm"], ["storm", "frost"]))
	assert_false(KeeperIntel.has_bite(["kin"], ["storm"]))
