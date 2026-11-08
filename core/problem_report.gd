class_name ProblemReport
extends RefCounted
## The report key (F9): what a report holds and how it is written to user://reports/<date_time>/ as shot.png,
## info.json and save.json. Pure apart from the file writes; ui/report_key.gd gathers the live facts.
## Never touches the save slots: save.json is a copy of the in-memory game, in the save system's own format.

const DIR := "user://reports"
const LOG_LINES := 6
const NOTE_MAX := 200
## info.json's fields, in order, with what they hold when the game can't say.
const FIELDS := {
	"version": "", "reported_at": "", "platform": "", "dev_session": false,
	"scene": "", "menus": [], "zone": "", "zone_name": "", "tile": null, "facing": "",
	"weather": "", "clock": "", "time_of_day": "", "day": 0, "play_seconds": 0.0, "play_time": "",
	"battle": null, "dialogue": "", "note": "",
}

static func folder_name(dt: Dictionary) -> String:
	return "%04d-%02d-%02d_%02d-%02d-%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]

## A folder under `root` for a report made at `dt` that isn't taken yet (not created here).
static func new_folder(root: String, dt: Dictionary) -> String:
	var base := root.path_join(folder_name(dt))
	var path := base
	var n := 2
	while DirAccess.dir_exists_absolute(path):
		path = "%s_%d" % [base, n]
		n += 1
	return path

static func creature_brief(c: Creature) -> Dictionary:
	return {"species": str(c.species.get("id", "")), "name": c.display_name(), "level": c.level,
		"hp": c.hp, "max_hp": c.max_hp(), "status": c.status}

## Both sides of a battle (who is out, their hp) and the last few lines the box showed.
static func battle_brief(b: Battle, lines: Array) -> Dictionary:
	var sides := []
	for side in [Battle.PLAYER, Battle.FOE]:
		var out := []
		for i in b.parties[side].size():
			var c: Dictionary = creature_brief(b.parties[side][i])
			c["out"] = i in b.active[side]
			out.append(c)
		sides.append(out)
	return {"kind": b.kind, "double": b.double, "weather": b.weather, "over": b.over,
		"player": sides[0], "foe": sides[1], "log": lines.slice(maxi(0, lines.size() - LOG_LINES))}

## The open menus, bottom first, by their Router names (a scene the Router doesn't know keeps its file name).
static func menu_names(scene_paths: Array, menus: Dictionary) -> Array:
	var by_path := {}
	for k in menus:
		by_path[menus[k]] = k
	return scene_paths.map(func(p): return by_path.get(p, str(p).get_file().get_basename()))

## The part of a typing-out line that is on screen (`visible` as Label.visible_characters, -1 for all of it).
static func shown_text(text: String, visible: int) -> String:
	return text if visible < 0 else text.left(visible)

static func play_time(secs: float) -> String:
	var s := int(secs)
	return "%dh %02dm %02ds" % [s / 3600, s / 60 % 60, s % 60]

static func tidy_note(text: String) -> String:
	return " ".join(text.strip_edges().split("\n", false)).left(NOTE_MAX)

## info.json from the gathered facts: every field present, a tile as [x, y], the clock as HH:MM.
static func info(facts: Dictionary) -> Dictionary:
	var out := FIELDS.duplicate(true)
	for k in out:
		if facts.has(k):
			out[k] = facts[k]
	if out.tile is Vector2i:
		out.tile = [out.tile.x, out.tile.y]
	if facts.get("clock") is int:
		out.clock = GameClock.text(facts.clock)
		out.time_of_day = str(facts.get("time_of_day", GameClock.phase(facts.clock)))
	out.play_time = play_time(float(out.play_seconds))
	return out

## Writes the report into `dir` (made if need be). `shot` may be null (a headless run has no picture).
static func write(dir: String, report: Dictionary, save: Dictionary, shot: Image) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return err
	if shot != null and not shot.is_empty():
		err = shot.save_png(dir.path_join("shot.png"))
	var e2 := _write_json(dir.path_join("info.json"), report)
	var e3 := _write_json(dir.path_join("save.json"), SaveSystem.payload_of(save))
	for e in [err, e2, e3]:
		if e != OK:
			return e
	return OK

## Adds the player's one-line note to a report already written.
static func add_note(dir: String, note: String) -> Error:
	var path := dir.path_join("info.json")
	var d = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not (d is Dictionary):
		return ERR_FILE_NOT_FOUND
	d["note"] = tidy_note(note)
	return _write_json(path, d)

static func _write_json(path: String, d: Dictionary) -> Error:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(d, "\t", false))
	var err := f.get_error()
	f.close()
	return err
