class_name Bag
extends RefCounted
## The player's items. Wraps an item_id -> count dictionary (the one saved in game state) so changes stick.

var store: Dictionary

func _init(items: Dictionary) -> void:
	store = items

func count(id: String) -> int:
	return int(store.get(id, 0))

const MAX_STACK := 99

## Adds up to n, never past MAX_STACK. Returns how many were actually added.
func add(id: String, n := 1) -> int:
	var room := maxi(0, MAX_STACK - count(id))
	var added := clampi(n, 0, room)
	if added > 0:
		store[id] = count(id) + added
	return added

func remove(id: String, n := 1) -> bool:
	if n < 1 or count(id) < n:
		return false
	var left := count(id) - n
	if left > 0:
		store[id] = left
	else:
		store.erase(id)
	return true

func items_of_kind(kind: String, item_db: ItemDB) -> Array:
	var out := []
	for id in store:
		if count(id) > 0 and item_db.get_item(id).get("kind", "") == kind:
			out.append(id)
	return out

func use_on(id: String, c: Creature, item_db: ItemDB, move_db: MoveDB = null) -> Dictionary:
	var item := item_db.get_item(id)
	if item.is_empty() or count(id) < 1:
		return {"ok": false, "text": "You don't have any."}
	if str(item.get("kind", "")) == "evo":
		# evolution items: the caller does the evolving (it has the Dex); the item is used up only if it works
		var to := Progression.evolution_target_with_item(c, id)
		if to == "":
			return {"ok": false, "text": "%s doesn't react to it." % c.display_name()}
		remove(id)
		return {"ok": true, "text": "", "evolve_to": to}
	if str(item.get("kind", "")) == Chapbooks.KIND:  # a book you keep: the caller runs the learn/forget prompt
		var mv := Chapbooks.move_of(item)
		var st := Chapbooks.status(c, mv, move_db if move_db != null else MoveDB.load_default())
		if st != Chapbooks.CAN:
			return {"ok": false, "text": "%s already knows it." % c.display_name() if st == Chapbooks.KNOWS else "%s can't learn that." % c.display_name()}
		return {"ok": true, "text": "", "learn": mv, "keep": true}
	var r := ItemEffects.apply(item, c)
	if r.ok:
		remove(id)
		if str(item.get("kind", "")) == "heal":  # food shared outside battle: a little friendship too
			Bond.add(c, Bond.FEED)
			r["text"] = "%s %s enjoyed sharing it." % [r.text, c.display_name()]
	return r

## Gives a charm from the bag to hold. Whatever it held before goes back in the bag.
func give_charm(id: String, c: Creature) -> Dictionary:
	if not Charms.is_charm(id):
		return {"ok": false, "text": "That isn't something to hold."}
	if count(id) < 1:
		return {"ok": false, "text": "You don't have any."}
	if c.held == id:
		return {"ok": false, "text": "%s is already holding one." % c.display_name()}
	var old := c.held
	remove(id)
	if old != "":
		add(old)
	c.held = id
	if old != "":
		return {"ok": true, "text": "%s swapped its %s for the %s." % [c.display_name(), Charms.name_of(old), Charms.name_of(id)]}
	return {"ok": true, "text": "%s is now holding the %s." % [c.display_name(), Charms.name_of(id)]}

## Takes its charm back into the bag.
func take_charm(c: Creature) -> Dictionary:
	if c.held == "":
		return {"ok": false, "text": "%s isn't holding anything." % c.display_name()}
	var id := c.held
	add(id)
	c.held = ""
	return {"ok": true, "text": "You took the %s from %s." % [Charms.name_of(id), c.display_name()]}
