extends TestCase

const E := {"t_skim": {"name": "Test skim", "move": "rill_shot", "types": ["brook"], "zone": "macclesfield", "where": "here", "good": 5, "master": 9, "unit": "bounces", "master_name": "Nan", "field": ""},
	"t_dart": {"name": "Test darts", "move": "drench", "types": [], "zone": "macclesfield", "where": "pub", "good": 100, "master": 60, "lower_better": true, "unit": "darts", "master_name": "Dai", "field": ""}}

func test_rosettes_climb_and_unlock_once() -> void:
	PartyPieces._cache = E.duplicate(true)
	var d := GameStateData.new()
	var r := PartyPieces.record(d, "t_skim", 2)
	assert_eq(r.rosette, 1)
	assert_false(r.unlocked)
	r = PartyPieces.record(d, "t_skim", 6)
	assert_eq(r.rosette, 2)
	assert_true(r.unlocked)
	assert_true(PartyPieces.unlocked(d, "t_skim"))
	r = PartyPieces.record(d, "t_skim", 7)
	assert_eq(r.rosette, 0)
	assert_false(r.unlocked)
	var m := d.money
	r = PartyPieces.record(d, "t_skim", 9)
	assert_eq(r.rosette, 3)
	assert_eq(d.money, m + PartyPieces.GOLD_PRIZE)
	assert_eq(TrainerStats.get_count(d, "masters_beaten"), 1)
	r = PartyPieces.record(d, "t_skim", 12)
	assert_eq(d.money, m + PartyPieces.GOLD_PRIZE, "the prize is once only")
	assert_eq(int(d.pieces.t_skim.plays), 5)
	assert_eq(float(d.pieces.t_skim.best), 12.0)

func test_lower_is_better() -> void:
	PartyPieces._cache = E.duplicate(true)
	var d := GameStateData.new()
	PartyPieces.record(d, "t_dart", 150)
	assert_eq(PartyPieces.rosette(d, "t_dart"), 1)
	PartyPieces.record(d, "t_dart", 90)
	assert_eq(PartyPieces.rosette(d, "t_dart"), 2)
	PartyPieces.record(d, "t_dart", 120)
	assert_eq(float(d.pieces.t_dart.best), 90.0)
	PartyPieces.record(d, "t_dart", 59)
	assert_eq(PartyPieces.rosette(d, "t_dart"), 3)

func test_unknown_game_is_ignored_and_save_round_trips() -> void:
	PartyPieces._cache = E.duplicate(true)
	var d := GameStateData.new()
	assert_eq(PartyPieces.record(d, "nope", 5).rosette, 0)
	PartyPieces.record(d, "t_skim", 6)
	var back := GameStateData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())), Fixtures.dex())
	assert_eq(PartyPieces.rosette(back, "t_skim"), 2)
	assert_eq(typeof(back.pieces.t_skim.plays), TYPE_INT)
	var junk := GameStateData.from_dict({"pieces": {"a": 5, "b": {"rosette": 9, "plays": -3}}}, Fixtures.dex())
	assert_eq(PartyPieces.rosette(junk, "b"), 3)
	assert_false(junk.pieces.has("a"))

func test_problems_flag_bad_entries() -> void:
	PartyPieces._cache = E.duplicate(true)
	var db := MoveDB.from_array([{"id": "rill_shot", "name": "x", "type": "brook", "piece": "t_skim"}, {"id": "drench", "name": "y", "type": "brook"}])
	var p := PartyPieces.problems(db)
	assert_eq(p.size(), 1, str(p))  # drench lacks the piece key

func test_real_data_is_clean_and_covers_every_type() -> void:
	PartyPieces._cache = {}
	var db := MoveDB.load_default()
	var p := PartyPieces.problems(db)
	assert_eq(p.size(), 0, str(p))
	var seen := {}
	for id in PartyPieces.ids():
		var e := PartyPieces.entry(id)
		assert_true(db.has(str(e.move)), id)
		assert_eq(str(db.get_move(str(e.move)).get("piece", "")), id)
		for t in e.types:
			seen[t] = int(seen.get(t, 0)) + 1
	for t in ["bog", "brawn", "brook", "fae", "frost", "gale", "hearth", "hedgerow", "iron", "kin", "night", "spirit", "stone", "storm", "tide", "urban"]:
		assert_true(int(seen.get(t, 0)) >= 2, "type %s has two pieces" % t)
	for g in ["walling", "skimming", "caber", "crabbing"]:
		assert_true(str(PartyPieces.entry(g).field) != "", g)

func test_almanac_page_always_there() -> void:
	assert_true("pieces" in Almanac.ORDER)
	assert_true(Almanac.MENUS.has("pieces") and Almanac.NAMES.has("pieces"))
