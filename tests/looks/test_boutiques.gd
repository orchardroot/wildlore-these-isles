extends TestCase
## The boutiques (4.6): every wear item draws, every shop stocks real items at sensible prices, every boutique has a
## door, a keeper and a line about what you're wearing, and the compliments only ask for things that can be worn.

const MIN_PRICE := 120
const MAX_PRICE := 2400

func _wear() -> Array:
	return JsonUtil.read("res://data/items/wear.json")

func _boutiques() -> Array:
	var out := []
	for f in DirAccess.get_files_at("res://data/shops"):
		if f.begins_with("boutique_") and f.ends_with(".json"):
			out.append(JsonUtil.read("res://data/shops/" + f))
	return out

func test_sixty_plus_wear_items_all_valid() -> void:
	var items := _wear()
	assert_true(items.size() >= 60, "60+ wear items, got %d" % items.size())
	for it in items:
		assert_eq(it.kind, "wear", it.id)
		assert_true(it.slot in Looks.SLOTS, "%s slot" % it.id)
		assert_true(Looks.valid_delta(it.look), "%s look delta is drawable" % it.id)
		assert_true(str(it.desc).length() > 20, "%s has its one-line fact" % it.id)
		assert_false("—" in str(it.desc) + str(it.name), "%s: no em-dashes" % it.id)

func test_no_duplicate_ids_and_no_clash_with_other_items() -> void:
	var seen := {}
	for it in _wear():
		assert_false(seen.has(it.id), "duplicate wear id %s" % it.id)
		seen[it.id] = true
	var db := ItemDB.load_default()
	var wear_count := 0
	for id in db.ids():
		if str(db.get_item(id).get("kind", "")) == "wear":
			wear_count += 1
	assert_eq(wear_count, seen.size(), "the only wear items are wear.json's (a clash would drop one)")

func test_prices_in_range() -> void:
	for it in _wear():
		assert_true(int(it.price) >= MIN_PRICE and int(it.price) <= MAX_PRICE, "%s costs %d" % [it.id, int(it.price)])

func test_every_slot_has_something_to_buy() -> void:
	var slots := {}
	for it in _wear():
		slots[it.slot] = true
	for s in Looks.SLOTS:
		assert_true(slots.has(s), "something for the %s slot" % s)

func test_fourteen_boutiques_with_real_stock() -> void:
	var db := ItemDB.load_default()
	var shops := _boutiques()
	assert_eq(shops.size(), 14, "fourteen boutiques")
	var stocked := {}
	for sh in shops:
		assert_true(db.shops.has(sh.id), "%s is loaded as a shop" % sh.id)
		assert_true(sh.stock.size() >= 8, "%s has a decent rail" % sh.id)
		var seen := {}
		for id in sh.stock:
			assert_true(db.has(id), "%s stocks %s" % [sh.id, id])
			assert_eq(str(db.get_item(id).get("kind", "")), "wear", "%s: %s is clothing" % [sh.id, id])
			assert_false(seen.has(id), "%s lists %s twice" % [sh.id, id])
			seen[id] = true
			stocked[id] = true
	for it in _wear():
		assert_true(stocked.has(it.id), "%s is sold somewhere" % it.id)

func test_each_boutique_has_a_door_a_keeper_and_a_wearing_line() -> void:
	var zone_for := {}
	for sh in _boutiques():
		var city := str(sh.id).trim_prefix("boutique_")
		var zid := city + "_boutique"
		if not FileAccess.file_exists("res://data/zones/%s.json" % zid):
			zid = {"stornoway": "stornoway_tweed", "lerwick": "lerwick_wool"}.get(city, "")
		assert_true(zid != "" and FileAccess.file_exists("res://data/zones/%s.json" % zid), "%s has a room" % sh.id)
		var z: Dictionary = JsonUtil.read("res://data/zones/%s.json" % zid)
		var keeper := {}
		for n in z.npcs:
			if str(n.get("script", "")) == city + "_boutique_keeper":
				keeper = n
		assert_false(keeper.is_empty(), "%s has its keeper" % zid)
		var dlg: Dictionary = JsonUtil.read("res://data/dialogue/%s.json" % zid)
		var lines: Array = dlg.get(city + "_boutique_keeper", [])
		var text := JSON.stringify(lines)
		assert_true(("\"id\":\"%s\"" % sh.id) in text, "%s script opens its shop" % zid)
		assert_true("\"if_wearing\"" in text and "{worn_" in text, "%s keeper remarks on what you wear" % zid)
		# a town door leads in, and the way back is the door tile's front step
		if z.id.ends_with("_boutique"):
			var town: Dictionary = JsonUtil.read("res://data/zones/%s.json" % city)
			var door := {}
			for w in town.warps:
				if str(w.to) == zid:
					door = w
			assert_false(door.is_empty(), "%s has a door in %s" % [zid, city])
			assert_eq(str(town.rows[int(door.y)][int(door.x)]), "D", "%s's warp is on a door tile" % zid)
			assert_eq(str(z.warps[0].to), city)
			assert_eq(int(z.warps[0].tx), int(door.x))
			assert_eq(int(z.warps[0].ty), int(door.y) + 1)
		zone_for[city] = zid
	assert_eq(zone_for.size(), 14)

func test_compliments_ask_for_wearable_things() -> void:
	var db := ItemDB.load_default()
	var found := 0
	for f in DirAccess.get_files_at("res://data/dialogue"):
		if not f.ends_with(".json"):
			continue
		var d = JsonUtil.read("res://data/dialogue/" + f)
		if typeof(d) != TYPE_DICTIONARY:
			continue
		for script in d:
			found += _count_wearing(d[script], db)
	assert_true(found >= 12 + 14 * 5, "a dozen compliments plus the keepers' lines, got %d" % found)

func _count_wearing(node: Variant, db: ItemDB) -> int:
	var n := 0
	if typeof(node) == TYPE_ARRAY:
		for c in node:
			n += _count_wearing(c, db)
	elif typeof(node) == TYPE_DICTIONARY:
		if node.has("if_wearing"):
			n += 1
			var spec = node.if_wearing
			for k in (spec if typeof(spec) == TYPE_ARRAY else [spec]):
				var ok: bool = str(k) in Looks.SLOTS or (db.has(str(k)) and str(db.get_item(str(k)).get("kind", "")) == "wear")
				assert_true(ok, "if_wearing '%s' is a slot or a wear item" % k)
		for key in ["then", "else"]:
			if node.has(key):
				n += _count_wearing(node[key], db)
	return n

func test_if_wearing_condition() -> void:
	var db := ItemDB.load_default()
	var d := GameStateData.new()
	assert_false(Commands.wearing(d, "hat"), "nothing on")
	assert_eq(Looks.wear(d, "flat_cap_yorkshire", db), "")
	assert_true(Commands.wearing(d, "hat"), "a slot, filled")
	assert_false(Commands.wearing(d, "coat"))
	assert_true(Commands.wearing(d, "flat_cap_yorkshire"), "an item id")
	assert_false(Commands.wearing(d, "donegal_tweed_cap"))
	assert_true(Commands.wearing(d, ["coat", "flat_cap_yorkshire"]), "any of a list")
	Looks.take_off(d, "hat")
	assert_false(Commands.wearing(d, "flat_cap_yorkshire"))

func test_worn_name_for_the_keepers() -> void:
	var db := ItemDB.load_default()
	var d := GameStateData.new()
	assert_eq(Looks.worn_name(d, "coat", db), "")
	Looks.wear(d, "waxed_jacket_green", db)
	assert_eq(Looks.worn_name(d, "coat", db), "Waxed jacket")

func test_every_item_changes_the_picture() -> void:
	# a delta that matches the bare recipe would be a pointless purchase
	var db := ItemDB.load_default()
	var d := GameStateData.new()
	var bare := Looks.recipe(d, db)
	for it in _wear():
		var r := Looks.preview(d, it.id, db)
		assert_true(r != bare, "%s shows when worn" % it.id)

func test_new_vocabulary_renders() -> void:
	var Character = load("res://tools/spritegen/character.gd")
	for h in ["sou_wester", "tam", "boater"]:
		var img: Image = Character.render({"id": "t", "build": "adult", "palette": {"skin": "#f2c9a0", "hair": "#4a2e22", "top": "#2f8c9a", "bottom": "#3a4a7a", "shoes": "#f2f0ea", "hat": "#e8c030"}, "hair": "short", "hat": h})
		assert_eq(img.get_size(), Vector2i(96, 192), h)
	for a in ["tweed_jacket", "smock"]:
		var img2: Image = Character.render({"id": "t", "build": "adult", "palette": {"skin": "#f2c9a0", "hair": "#4a2e22", "top": "#2f8c9a", "accent": "#6a6a4a", "accent2": "#c86a3a"}, "hair": "short", "accessories": [a]})
		assert_eq(img2.get_size(), Vector2i(96, 192), a)
