class_name SaveSystem
extends RefCounted
## Versioned JSON saves. Writes go to a temp file then get renamed into place; the previous save is kept as .bak.

const VERSION := 2
const DEFAULT_DIR := "user://saves"
const SLOTS := ["auto", "1", "2", "3"]

static func slot_path(slot: String, dir := DEFAULT_DIR) -> String:
	return dir.path_join(slot + ".json")

static func save(slot: String, data: Dictionary, dir := DEFAULT_DIR) -> Error:
	DirAccess.make_dir_recursive_absolute(dir)
	var path := slot_path(slot, dir)
	var payload := payload_of(data)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(payload, "\t"))
	var err := f.get_error()
	f.close()
	if err != OK or _read(tmp) == null:
		DirAccess.remove_absolute(tmp)
		return err if err != OK else ERR_FILE_CORRUPT
	# Only a readable save earns the .bak slot; a corrupt one must never push out a good backup.
	if _read(path) != null:
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path)

## What a save file holds for this game state: a deep copy without the "_" scratch keys, stamped with the version.
static func payload_of(data: Dictionary) -> Dictionary:
	var payload := {}
	for k in data:
		if not str(k).begins_with("_"):
			payload[k] = data[k]
	payload = payload.duplicate(true)
	payload["version"] = VERSION
	if not payload.has("saved_at"):
		payload["saved_at"] = Time.get_unix_time_from_system()
	return payload

static func load_slot(slot: String, dir := DEFAULT_DIR) -> Dictionary:
	var path := slot_path(slot, dir)
	var data = _read(path)
	if data == null:
		data = _read(path + ".bak")
		if data == null:
			return {}
		data["_recovered"] = true
	var v := int(data.get("version", 0))
	if v > VERSION:
		return {"_too_new": true, "version": v}
	return migrate(data)

static func migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 0))
	while v < VERSION:
		match v:
			0:
				data = _v0_to_v1(data)
			1:
				data = _v1_to_v2(data)
		v += 1
		data["version"] = v
	return data

static func list_slots(dir := DEFAULT_DIR) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".json"):
			out.append(f.get_basename())
	out.sort()
	return out

## What the save and load screens show for a slot: {slot, exists, ok, zone_id, player_name, play_seconds, badges, saved_at}.
## exists && !ok means the file is there but unreadable (shown as "Damaged").
static func slot_info(slot: String, dir := DEFAULT_DIR) -> Dictionary:
	var path := slot_path(slot, dir)
	var info := {"slot": slot, "exists": FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"),
		"ok": false, "zone_id": "", "player_name": "", "play_seconds": 0.0, "badges": 0, "saved_at": 0.0}
	if not info.exists:
		return info
	var d := load_slot(slot, dir)
	if d.is_empty() or d.has("_too_new"):
		return info
	info.ok = true
	info.zone_id = str(d.get("zone_id", ""))
	info.player_name = str(d.get("player_name", ""))
	info.play_seconds = float(d.get("play_seconds", 0.0))
	var b = d.get("badges", [])
	info.badges = b.size() if b is Array else 0
	info.saved_at = float(d.get("saved_at", 0.0))
	return info

static func slot_infos(dir := DEFAULT_DIR) -> Array:
	return SLOTS.map(func(s): return slot_info(s, dir))

## The readable slot saved most recently, or "" if there are none.
static func newest_slot(dir := DEFAULT_DIR) -> String:
	var best := ""
	var best_t := -1.0
	for info in slot_infos(dir):
		if info.ok and float(info.saved_at) > best_t:
			best_t = float(info.saved_at)
			best = info.slot
	return best

## Pre-release saves had no version field and nothing else changed.
static func _v0_to_v1(data: Dictionary) -> Dictionary:
	return data

## v0.1 saves: saved_at added; the old [0,0] Sanctuary default becomes the spawn marker [-1,-1].
static func _v1_to_v2(data: Dictionary) -> Dictionary:
	if not data.has("saved_at"):
		data["saved_at"] = 0.0
	var ls = data.get("last_sanctuary", {})
	if not (ls is Dictionary) or not ls.has("zone"):
		ls = {"zone": "macclesfield", "pos": [-1, -1]}
	var lp = ls.get("pos", [-1, -1])
	if not (lp is Array) or lp.size() != 2 or (int(lp[0]) == 0 and int(lp[1]) == 0):
		ls["pos"] = [-1, -1]
	data["last_sanctuary"] = ls
	# v0.2 story checks badges through flags; a v0.1 Brook Stone must count (Bev's bike) and open chapter 2
	var flags = data.get("flags", {})
	if not (flags is Dictionary):
		flags = {}
	var badges = data.get("badges", [])
	for b in (badges if badges is Array else []):
		flags["badge_" + str(b)] = true
	if "brook" in (badges if badges is Array else []):
		flags["ch2_started"] = true
	data["flags"] = flags
	return data

static func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else null
