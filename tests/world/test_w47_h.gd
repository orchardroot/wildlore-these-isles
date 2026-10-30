extends TestCase
## Wave 47 H: question marks on the map (Poi): placement, den restock, camp once, stone once, cache once, marks, hook.

func _poi(kind: String) -> Dictionary:
	for p in Poi.all():
		if str(p.kind) == kind:
			return p
	return {}

func test_data_is_valid_and_wide() -> void:
	var errs := Poi.check(ZoneData.load_all(), Dex.load_default(), ItemDB.load_default())
	assert_eq(errs.size(), 0, str(errs.slice(0, 3)))
	assert_true(Poi.all().size() >= 100, "about 120 pois")
	for k in Poi.KINDS:
		assert_true(not _poi(k).is_empty(), k + " exists")

func test_placement_is_deterministic_and_standable() -> void:
	var z := ZoneData.load_id(str(Poi.all()[0].zone))
	var a := Poi.tile(z, Poi.all()[0])
	assert_eq(a, Poi.tile(z, Poi.all()[0]))
	assert_true(z.walkable(a))

func test_den_restocks_after_fourteen_days() -> void:
	var d := GameStateData.new()
	var p := _poi("den")
	assert_false(Poi.done(d, p))
	d.day_count = 10
	Poi.mark_done(d, p)
	assert_true(Poi.done(d, p))
	d.day_count = 23
	assert_true(Poi.done(d, p))
	d.day_count = 24
	assert_false(Poi.done(d, p), "back after 14 days")

func test_camp_stone_cache_are_once() -> void:
	for k in ["camp", "stone", "cache"]:
		var d := GameStateData.new()
		var p := _poi(k)
		assert_false(Poi.done(d, p))
		Poi.mark_done(d, p)
		d.day_count += 400
		assert_true(Poi.done(d, p), k + " stays done")

func test_den_fights_use_the_table_plus_three() -> void:
	var p := _poi("den")
	var z := ZoneData.load_id(str(p.zone))
	var f := Poi.den_fights(z, Rng.new(7))
	assert_eq(f.size(), 3)
	assert_eq(f, Poi.den_fights(z, Rng.new(7)), "seeded")
	var lows := Poi.table(z).map(func(e): return int(e.get("min", 5)))
	for x in f:
		assert_true(int(x.level) >= int(lows.min()) + Poi.DEN_BOOST)
	assert_false(Poi.table(z).any(func(e): return str(e.species) == str(p.species)), "resident is a stranger here")

func test_camp_trainers_and_strongbox() -> void:
	var p := _poi("camp")
	var z := ZoneData.load_id(str(p.zone))
	var ts := Poi.camp_trainers(z, p, {})
	assert_true(ts.size() >= 2 and ts.size() <= 3)
	var late := Poi.camp_trainers(z, p, {"moot_won": true})
	assert_true(int(late[0].party[0].level) >= 94, "scaled by par")
	assert_true(int(Poi.strongbox(z, p, {}).money) > 0)

func test_stone_training_boost_is_capped() -> void:
	var dex := Dex.load_default()
	var c := Creature.create(dex.get_species("connie"), 5, Rng.new(1), MoveDB.load_default())
	assert_eq(Poi.train(c, "lore"), 4)
	assert_eq(int(c.training.lore), 4)
	c.training["atk"] = 99
	assert_eq(Poi.train(c, "atk"), 1, "stat cap")

func test_marks_need_knowing_and_change_when_done() -> void:
	var d := GameStateData.new()
	var p := {}
	for q in Poi.all():
		if str(q.get("at", "")) != "":
			p = q
			break
	assert_eq(Poi.marks(d).size(), 0)
	d.set_flag(Poi.seen_key(p))
	var m := Poi.marks(d)
	assert_eq(m.size(), 1)
	assert_false(m[0].done)
	Poi.mark_done(d, p)
	assert_true(Poi.marks(d)[0].done)
	assert_true(Poi.close_enough(Vector2i(10, 10), Vector2i(16, 4)))
	assert_false(Poi.close_enough(Vector2i(10, 10), Vector2i(17, 10)))

func test_hook_adds_one_mention_once() -> void:
	var p := {}
	for q in Poi.all():
		if q.has("mentioned_by"):
			p = q
			break
	assert_false(p.is_empty(), "some residents mention places")
	var d := GameStateData.new()
	var base := [{"do": "say", "who": "X", "text": "hi"}]
	var m: Dictionary = p.mentioned_by
	var out := Poi.hook(str(m.zone), str(m.npc), base, d)
	assert_true(out.size() > base.size())
	d.set_flag(Poi.seen_key(p))
	var again := Poi.hook(str(m.zone), str(m.npc), base, d)
	assert_true(again.size() < out.size(), "known places are not repeated")
	assert_eq(Poi.hook("nowhere", "nobody", base, d), base)

func test_no_em_dashes_in_files() -> void:
	for f in DirAccess.get_files_at(Poi.DIR):
		assert_false("—" in FileAccess.get_file_as_string(Poi.DIR + "/" + f), f)
