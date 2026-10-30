extends TestCase
## Wave 47 B: papers on tables and treasure trails (core/letters.gd, data/letters/*.json).

static var _cache: Dictionary = {}
var _zones: Dictionary:
	get:
		if _cache.is_empty():
			_cache = ZoneData.load_all()
		return _cache

func _data() -> GameStateData:
	return GameStateData.new()

func test_every_file_validates() -> void:
	var errs := Letters.errors(_zones, ItemDB.load_default())
	assert_eq(errs.size(), 0, "letter errors: %s" % str(errs.slice(0, 5)))

func test_volume_and_trails() -> void:
	assert_true(Letters.all().size() >= 180, "about 180 papers or more")
	var trails := Letters.all().filter(func(p): return Letters.has_trail(p))
	assert_true(trails.size() >= 40, "about 40 papers start a trail")

func test_every_region_has_four_papers() -> void:
	var regions := {}
	for f in JsonUtil.list_json(Letters.DIR):
		var n: int = JsonUtil.read(f).papers.size()
		regions[f.get_file().get_basename()] = n
	for zid in _zones:
		var r := str((_zones[zid] as ZoneData).region)
		if r != "" and r != "dev":
			assert_true(int(regions.get(r, 0)) >= 4, "region %s has 4+ papers" % r)

func test_trail_tiles_are_bare_ground_in_bounds() -> void:
	for p in Letters.all():
		if not Letters.has_trail(p):
			continue
		var z: ZoneData = _zones[str(p.trail.zone)]
		var t := Letters.dig_tile(z, p.trail)
		assert_true(t != Letters.NONE and z.in_bounds(t), "%s has a dig tile" % str(p.id))
		assert_true(Letters.diggable(z, t))

func test_paper_goes_on_first_table() -> void:
	var p: Dictionary = Letters.all()[0]
	var z: ZoneData = _zones[str(p.zone)]
	var t := Letters.prop_for(z)
	assert_true(t != Letters.NONE)
	var first := Vector2i.ZERO
	for pr in z.props:
		if str(pr.type) in Letters.TABLES:
			first = Vector2i(int(pr.x), int(pr.y))
			break
	assert_eq(t, first)
	assert_eq(Letters.at(str(p.zone))[0].id, p.id)

func test_reading_is_once() -> void:
	var d := _data()
	var p: Dictionary = Letters.all()[0]
	var r1 := Letters.read(d, p)
	assert_true(r1.first)
	assert_eq(r1.lines[0], str(p.title))
	var r2 := Letters.read(d, p)
	assert_false(r2.first)
	assert_eq(r2.lines, ["You've read this one."])
	assert_eq(TrainerStats.get_count(d, "papers_read"), 1)
	assert_eq(Letters.read_count(d), 1)

func test_trail_marks_and_reward_once() -> void:
	var d := _data()
	var items := ItemDB.load_default()
	var p: Dictionary = {}
	for q in Letters.all():
		if Letters.has_trail(q) and q.trail.reward.has("item"):
			p = q
			break
	assert_false(p.is_empty())
	assert_eq(Letters.marks(d).size(), 0)
	Letters.read(d, p)
	assert_eq(Letters.marks(d).size(), 1)
	assert_eq(Letters.marks(d)[0].at, p.trail.zone)
	assert_eq(MapLogic.marks(d, {}).filter(func(m): return m.kind == "trail").size(), 1)
	var iid := str(p.trail.reward.item)
	var before := int(d.bag.get(iid, 0))
	var res := Letters.dig(d, p, items)
	assert_true(res.gave)
	assert_eq(int(d.bag.get(iid, 0)), before + int(p.trail.reward.get("n", 1)))
	assert_eq(Letters.marks(d).size(), 0, "the ? goes once dug")
	var again := Letters.dig(d, p, items)
	assert_false(again.gave)
	assert_eq(int(d.bag.get(iid, 0)), before + int(p.trail.reward.get("n", 1)), "paid once")

func test_money_reward() -> void:
	var d := _data()
	var p: Dictionary = {}
	for q in Letters.all():
		if Letters.has_trail(q) and q.trail.reward.has("money"):
			p = q
			break
	var m := d.money
	Letters.read(d, p)
	Letters.dig(d, p, ItemDB.load_default())
	assert_eq(d.money, m + int(p.trail.reward.money))

func test_no_dashes_and_unique_zones() -> void:
	var zones := {}
	for p in Letters.all():
		assert_false(zones.has(p.zone), "one paper per room: %s" % str(p.zone))
		zones[p.zone] = true
		for l in p.lines:
			assert_false("—" in str(l) or "–" in str(l), str(p.id))

func test_almanac_page_sprouts_after_reading() -> void:
	var d := _data()
	assert_false(Almanac.sprouted(d, "papers"))
	Letters.read(d, Letters.all()[0])
	assert_true(Almanac.sprouted(d, "papers"))
	assert_true(Almanac.pages(d).any(func(pg): return pg.id == "papers"))
