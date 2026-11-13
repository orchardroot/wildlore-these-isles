extends TestCase
## Battle quality-of-life: battle speed, type effectiveness hints, catch odds, cursor memory and move descriptions.

const TMP := "user://test_settings_qol_battle.json"

var _items := ItemDB.load_default()

func _flow(party: Array, foes: Array, data := GameStateData.new(), opts := {}) -> BattleFlow:
	data.party = party
	return BattleFlow.new(data, Fixtures.dex(), Fixtures.moves(), Fixtures.chart(), _items, Rng.new(7), foes, opts, FakeBattleUI.new())

# --- battle speed ------------------------------------------------------------------------------------------------

func test_battle_speed_defaults_to_normal_for_old_settings_files() -> void:
	var saved_path := Settings.path
	var saved_speed: String = Settings.battle_speed
	Settings.path = TMP
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	f.store_string(JSON.stringify({"text_speed": "fast"}))  # written before battle speed existed
	f.close()
	Settings.battle_speed = "fastest"
	Settings.load_settings()
	assert_eq(Settings.battle_speed, "fastest", "a missing key keeps the current value")
	Settings.battle_speed = "normal"
	f = FileAccess.open(TMP, FileAccess.WRITE)
	f.store_string(JSON.stringify({"battle_speed": "ludicrous"}))
	f.close()
	Settings.load_settings()
	assert_eq(Settings.battle_speed, "normal", "unknown speeds fall back to normal")
	assert_eq(Settings.battle_time_scale(), 1.0)
	Settings.battle_speed = "fast"
	Settings.save_settings()
	Settings.battle_speed = "normal"
	Settings.load_settings()
	assert_eq(Settings.battle_speed, "fast", "saved and loaded")
	assert_true(Settings.battle_time_scale() > 1.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	Settings.path = saved_path
	Settings.battle_speed = saved_speed
	Settings.load_settings()

func test_new_settings_default_battle_speed_is_normal() -> void:
	var s: Node = load("res://core/settings.gd").new()
	assert_eq(s.battle_speed, "normal")
	assert_eq(s.battle_time_scale(), 1.0)
	s.free()

func test_battle_scene_speeds_up_time_and_always_restores_it() -> void:
	var saved_speed: String = Settings.battle_speed
	Settings.battle_speed = "fastest"
	Engine.time_scale = 1.0
	var scene: Node = load("res://battle_ui/battle_scene.tscn").instantiate()
	scene.apply_speed()  # what _ready does first
	assert_near(Engine.time_scale, Settings.BATTLE_SPEEDS["fastest"], 0.0001, "sped up while the battle is open")
	scene.restore_speed()
	assert_near(Engine.time_scale, 1.0, 0.0001, "restored before the battle reports back")
	scene.apply_speed()
	scene._exit_tree()  # freed mid-battle (whiteout, scene change...): still restored
	assert_near(Engine.time_scale, 1.0, 0.0001, "restored on leaving the tree")
	scene.free()
	Settings.battle_speed = saved_speed

# --- type effectiveness in the move picker ------------------------------------------------------------------

func test_effectiveness_labels() -> void:
	assert_eq(MoveText.effectiveness_label(2.0), "Super effective")
	assert_eq(MoveText.effectiveness_label(4.0), "Super effective")
	assert_eq(MoveText.effectiveness_label(1.0), "")
	assert_eq(MoveText.effectiveness_label(0.5), "Not very effective")
	assert_eq(MoveText.effectiveness_label(0.25), "Not very effective")
	assert_eq(MoveText.effectiveness_label(0.0), "No effect")

func _types_where(attacker: String, want: float) -> String:
	var chart := Fixtures.chart()
	for t in ["kin", "hedgerow", "brook", "tide", "hearth", "gale", "storm", "frost", "stone", "bog", "iron", "urban", "fae", "spirit", "brawn", "night"]:
		if chart.effectiveness(attacker, [t]) == want:
			return t
	return ""

func test_effectiveness_text_singles() -> void:
	var mv := {"type": "kin", "category": "physical", "power": 40}
	var chart := Fixtures.chart()
	assert_eq(MoveText.versus(mv, [{"name": "A", "types": ["spirit"], "known": true}], chart), "No effect")
	assert_eq(MoveText.versus(mv, [{"name": "A", "types": ["stone"], "known": true}], chart), "Not very effective")
	assert_eq(MoveText.versus(mv, [{"name": "A", "types": ["kin"], "known": true}], chart), "", "neutral says nothing")
	assert_eq(MoveText.versus(mv, [{"name": "A", "types": ["spirit"]}], chart), "No effect", "a first meeting is judged too")
	var se := _types_where("hedgerow", 2.0)
	assert_eq(MoveText.versus({"type": "hedgerow", "category": "special", "power": 40}, [{"name": "A", "types": [se], "known": true}], chart), "Super effective")
	var status := {"type": "kin", "category": "status", "power": 0}
	assert_eq(MoveText.versus(status, [{"name": "A", "types": ["spirit"], "known": true}], chart), "", "status moves get no tag")

func test_effectiveness_text_doubles() -> void:
	var mv := {"type": "kin", "category": "physical", "power": 40}
	var chart := Fixtures.chart()
	var ghost := {"name": "Ghosty", "types": ["spirit"], "known": true}
	var rock := {"name": "Rocky", "types": ["stone"], "known": true}
	var plain := {"name": "Plain", "types": ["kin"], "known": true}
	assert_eq(MoveText.versus(mv, [ghost, ghost.merged({"name": "Boo"}, true)], chart), "No effect", "same answer for both: said once")
	assert_eq(MoveText.versus(mv, [ghost, rock], chart), "No effect on Ghosty, not very effective on Rocky")
	assert_eq(MoveText.versus(mv, [plain, rock], chart), "Not very effective on Rocky")
	assert_eq(MoveText.versus(mv, [ghost, rock.merged({"name": "Third"}, true)], chart), "No effect on Ghosty, not very effective on Third")
	assert_eq(MoveText.versus(mv, [plain, plain.merged({"name": "Other"}, true)], chart), "")

func test_flow_hint_covers_a_first_meeting() -> void:
	var me := Fixtures.creature("kindlet", 10)
	var foe := Fixtures.creature("spikkin", 5)
	var slot := 0
	var mv := Fixtures.moves().get_move(me.moves[slot].id)
	var mult := Fixtures.chart().effectiveness(str(mv.type), foe.types())
	var fresh := _flow([me], [foe])  # never seen: the cue is there all the same
	var cues: Array = fresh.move_hint(me, slot)
	assert_eq(cues.size(), 1)
	assert_eq(cues[0].kind, MoveText.cue_kind(mult))
	assert_eq(cues[0].words, MoveText.cue_words(mult))
	var d := GameStateData.new()
	d.mark_seen("spikkin")
	assert_eq(_flow([me], [foe], d).move_hint(me, slot), cues, "seen or not, the same words")
	var d2 := GameStateData.new()
	d2.mark_caught("spikkin")
	assert_true(_flow([me], [foe], d2).is_caught_species("spikkin"))
	assert_false(fresh.is_caught_species("spikkin"), "seen is not caught")

func test_cue_kinds_and_words() -> void:
	assert_eq(MoveText.cue_kind(4.0), "up2")
	assert_eq(MoveText.cue_kind(2.0), "up1")
	assert_eq(MoveText.cue_kind(1.0), "even")
	assert_eq(MoveText.cue_kind(0.5), "dn1")
	assert_eq(MoveText.cue_kind(0.25), "dn2")
	assert_eq(MoveText.cue_kind(0.0), "none")
	assert_eq(MoveText.cue_words(2.0), "Super effective x2")
	assert_eq(MoveText.cue_words(4.0), "Super effective x4")
	assert_eq(MoveText.cue_words(1.0), "Normal hit")
	assert_eq(MoveText.cue_words(0.5), "Not very effective x1/2")
	assert_eq(MoveText.cue_words(0.25), "Not very effective x1/4")
	assert_eq(MoveText.cue_words(0.0), "No effect")
	assert_eq(MoveText.cue_words(0.5, true), "x1/2")

func test_cues_single_double_and_status() -> void:
	var chart := Fixtures.chart()
	var mv := {"type": "kin", "category": "physical", "power": 40}
	var ghost := {"name": "Ghosty", "types": ["spirit"]}
	var rock := {"name": "Rocky", "types": ["stone"]}
	var plain := {"name": "Plain", "types": ["kin"]}
	assert_eq(MoveText.cues(mv, [plain], chart), [{"kind": "even", "words": "Normal hit", "who": ""}], "a plain hit is marked too")
	assert_eq(MoveText.cues(mv, [ghost, ghost.merged({"name": "Boo"}, true)], chart).size(), 1, "same for both: said once")
	var two := MoveText.cues(mv, [ghost, rock], chart)
	assert_eq(two.size(), 2)
	assert_eq([two[0].kind, two[0].who, two[1].kind, two[1].words], ["none", "Ghosty", "dn1", "x1/2"])
	assert_eq(MoveText.cues({"type": "kin", "category": "status", "power": 0}, [ghost], chart), [], "status moves say nothing")
	assert_eq(MoveText.cues(mv, [], chart), [])

func test_matchup_line_for_a_move_description() -> void:
	var chart := Fixtures.chart()
	var line := MoveText.matchup_line({"type": "hearth", "category": "special", "power": 40}, chart)
	assert_true(line.begins_with("Strong against Hedgerow"), line)
	assert_true(line.contains("Weak against Brook"), line)
	assert_true(MoveText.matchup_line({"type": "kin", "category": "physical", "power": 40}, chart).contains("No effect on Spirit"))
	assert_eq(MoveText.matchup_line({"type": "hearth", "category": "status", "power": 0}, chart), "")

func test_move_rows_carry_cues_and_the_footer_the_matchup() -> void:
	var me := Fixtures.creature("kindlet", 10)
	var foe := Fixtures.creature("spikkin", 5)
	var f := _flow([me], [foe])
	var rows := BattleMenus.move_rows(me, Fixtures.moves(), "clear", func(i: int) -> Array: return f.move_hint(me, i))
	var damaging := 0
	for i in me.moves.size():
		var mv := Fixtures.moves().get_move(me.moves[i].id)
		if int(mv.get("power", 0)) > 0 and str(mv.get("category", "")) != "status":
			damaging += 1
			assert_true(rows[i].has("cues"), "damaging move %d says how it lands" % i)
		else:
			assert_false(rows[i].has("cues"), "status move %d says nothing" % i)
	assert_true(damaging > 0)
	assert_false(BattleMenus.move_rows(me, Fixtures.moves())[0].has("cues"), "no cue function, no cues")
	var text := BattleMenus.move_footer(me, 0, Fixtures.moves(), "", "clear", Fixtures.chart())
	assert_true(text.split("\n").size() >= 2)

# --- catch odds ---------------------------------------------------------------------------------------------

func test_catch_bands() -> void:
	assert_eq(MoveText.catch_band(0.02), "Long shot")
	assert_eq(MoveText.catch_band(0.19), "Long shot")
	assert_eq(MoveText.catch_band(0.2), "Worth a try")
	assert_eq(MoveText.catch_band(0.49), "Worth a try")
	assert_eq(MoveText.catch_band(0.5), "Good odds")
	assert_eq(MoveText.catch_band(1.0), "Good odds")

func test_snares_in_the_bag_carry_their_odds() -> void:
	var me := Fixtures.creature("kindlet", 10)
	var foe := Fixtures.creature("spikkin", 5)
	var d := GameStateData.new()
	d.bag = {"wicker_snare": 2, "cup_of_tea": 1}
	var f := _flow([me], [foe], d)
	for e in f.battle_items():
		if e.kind == "snare":
			var want := Catching.chance(foe, str(_items.get_item(e.id).snare), f.battle.time)
			assert_near(float(e.odds), want, 0.0001, "odds for " + e.id)
		else:
			assert_false(e.has("odds"), "only snares have odds")

# --- cursor memory ------------------------------------------------------------------------------------------

func test_menu_cursor_memory_outlives_the_battle() -> void:
	BattleMenus.forget_cursors()
	var a := BattleMenus.new()
	a.remember("moves", 3)
	a.remember("command", 1)
	a.free()
	BattleMenus.new_battle()
	var b := BattleMenus.new()
	assert_eq(b.recall("moves"), 3, "the move cursor carries over")
	assert_eq(b.recall("command"), 0, "each battle opens on Fight")
	b.free()
	BattleMenus.forget_cursors()

# --- move descriptions --------------------------------------------------------------------------------------

func test_every_move_has_a_description() -> void:
	var db := Fixtures.moves()
	for id in db.ids():
		var mv := db.get_move(id)
		var t := MoveText.describe(mv)
		assert_true(t.length() > 8, "description for " + id)
		assert_false(t.contains("—"), "no em-dashes: " + id)
		if mv.category == "status":
			assert_false(t.contains("No damage"), "status moves say what they do: " + id)

func test_descriptions_match_the_effect() -> void:
	assert_eq(MoveText.describe({"category": "status", "effect": {"id": "status", "status": "asleep"}}),
		"Puts the foe to sleep: it can't move for 1 to 3 turns.")
	assert_eq(MoveText.describe({"category": "status", "effect": {"id": "stat", "target": "self", "stat": "def", "stages": 1}}),
		"Raises the user's Defence by one stage.")
	assert_eq(MoveText.describe({"category": "status", "effect": {"id": "stat", "target": "foe", "stat": "acc", "stages": -1}}),
		"Lowers the foe's Accuracy by one stage.")
	assert_eq(MoveText.describe({"category": "physical", "power": 80, "effect": {"id": "status", "status": "stung", "chance": 20}}),
		"A physical hit. 20% chance to sting the foe (loses 1/8 of its HP each turn).")
	assert_eq(MoveText.describe({"category": "special", "power": 65, "effect": {"id": "stat", "target": "foe", "stat": "spd", "stages": -1}}),
		"A special hit. Also lowers the foe's Speed by one stage.")
	assert_eq(MoveText.describe({"category": "special", "power": 40, "priority": 1, "target": "all_foes", "effect": {"id": "none"}}),
		"A special hit. Usually strikes first. Hits both foes in a double battle, a bit weaker.")
	assert_eq(MoveText.describe({"category": "physical", "power": 40, "effect": {"id": "none"}, "desc": "Custom."}), "Custom.")
