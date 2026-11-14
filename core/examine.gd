class_name Examine
extends RefCounted
## Look-closer spots in rooms (a zone's "examine" list, see ZoneData.examine_at): facing the tile and pressing confirm
## reads the text, and may give a find once: an item, a few coins, a flag, a piece of case evidence. Pure logic, no
## autoloads; ExamineScene shows it.

const MONEY_FLAG := "money"

## The once-only flag for a spot: its own "flag", else ex_<zone>_<x>_<y>.
static func found_flag(zone_id: String, ex: Dictionary) -> String:
	var f := str(ex.get("flag", ""))
	return f if f != "" else "ex_%s_%d_%d" % [zone_id, int(ex.x), int(ex.y)]

## The flag a piece of case evidence is recorded under (the Casebook reads these).
static func evidence_flag(evidence_id: String) -> String:
	return "case_evidence_" + evidence_id

## Whether a spot has anything to give (an item, coins, evidence or a flag to set).
static func has_find(ex: Dictionary) -> bool:
	return ex.has("find") or int(ex.get("money", 0)) > 0 or str(ex.get("evidence", "")) != "" or str(ex.get("flag", "")) != ""

## Reads a spot: applies the find (once) and returns {lines, gave: bool}. `items` is the ItemDB (or null in tests).
static func read(data: GameStateData, zone_id: String, ex: Dictionary, items) -> Dictionary:
	var lines: Array = []
	var need := str(ex.get("needs", ""))
	var flag := found_flag(zone_id, ex)
	var done := ZoneData.flag_on(data.flag(flag))
	for l in ex.get("text", []):
		lines.append(str(l))
	if done or not has_find(ex) or (need != "" and not ZoneData.has_key(data, need)):
		return {"lines": lines, "gave": false}
	var gave := false
	var f = ex.get("find")
	if f is Dictionary and str(f.get("item", "")) != "":
		var id := str(f.item)
		var n := maxi(1, int(f.get("n", 1)))
		data.bag[id] = mini(Bag.MAX_STACK, int(data.bag.get(id, 0)) + n)
		var it: Dictionary = items.get_item(id) if items != null and items.has(id) else {}
		var nm := str(it.get("name", id))
		lines.append("You found %d x %s." % [n, nm] if n > 1 else "You found %s." % str(it.get("one", nm)))
		if str(it.get("kind", "")) == Search.CURIO_KIND:  # a curio found in the field is a curio for the Curios page too
			if not ZoneData.flag_on(data.flag(Search.FOUND_PREFIX + id)):
				lines.append("A new one for the Curios page.")
			data.set_flag(Search.FOUND_PREFIX + id, true)
			TrainerStats.add(data, "curios_found")
		gave = true
	var m := int(ex.get("money", 0))
	if m > 0:
		data.money += m
		lines.append("You find %s in loose change." % Wallet.fmt(m))
		gave = true
	var ev := str(ex.get("evidence", ""))
	if ev != "":
		data.set_flag(evidence_flag(ev), true)
		Casebook.collect(data, ev)
		lines.append("That might be evidence. It goes in your Casebook.")
		gave = true
	data.set_flag(flag, true)
	return {"lines": lines, "gave": gave}
