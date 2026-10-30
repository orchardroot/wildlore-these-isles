extends MenuBase
## The world map (pause menu "Map"). setup("") for the interactive map: a cursor hops between visited towns
## and an info panel says what is there. setup("species:<id>") rings that creature's habitats instead.

var view: MapView

var _can_fly := false      # the Champion can fly
var _asking := false       # "Fly here?" is up for the cursor's town
var _panel: PanelContainer
var _name_label: Label
var _lines_label: Label
var _ask_label: Label
var _objective_town := ""
var _route_label: Label
var _objective_panel: Control  # the "Where next?" strip along the bottom; the town panel stays above it

func _build() -> void:
	set_title("The Isles")
	set_hints([["cancel", "Back"]])
	view = MapView.new()
	view.framed = true
	view.zoom = 2.4
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(view)

func setup(arg: String) -> void:
	if arg.begins_with("quest:"):  # from the Journal: ring where the quest's current step is
		_show_quest(arg.substr(6))
		return
	var species_mode := arg.begins_with("species:")
	if species_mode:
		var sp := Game.dex.get_species(arg.substr(8))
		if not sp.is_empty():
			set_title("Where to find " + str(sp.name))
			view.highlight = habitat_zones(str(sp.id))
	var here = Game.data.flag("last_town")
	var towns: Dictionary = Travel.world_map().get("towns", {})
	if here and towns.has(str(here)):
		view.centre = Vector2(float(towns[str(here)].x), float(towns[str(here)].y))
	header_right.text = "You are near " + Travel.town_name(str(here)) if here else ""
	if not species_mode:
		view.marks = MapLogic.marks(Game.data, Tournament.today(Game.data) if Tournament.open_to(Game.data) else {})
		_can_fly = Game.data.flag("champion") == true
		_show_objective()
		_build_panel()
		_select(MapLogic.start_town(Game.data))
		_show_route()
		view.resized.connect(_place_panel)
		if _can_fly:
			var fly := make_button("Fly", _fly)
			fly.focus_mode = Control.FOCUS_NONE  # the cursor owns the arrows, not button focus
			fly.position = Vector2(20, 14)
			content.add_child(fly)
	view.queue_redraw()

func _build_panel() -> void:
	_panel = UIKit.panel(Color("1d2230"), 14)
	_panel.custom_minimum_size = Vector2(400, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_panel.add_child(col)
	_name_label = UIKit.label("", 34, UIKit.GOLD)
	col.add_child(_name_label)
	_lines_label = UIKit.label("", 22)
	_lines_label.custom_minimum_size = Vector2(372, 0)
	_lines_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lines_label)
	_route_label = UIKit.label("", 20, UIKit.GOLD)
	_route_label.custom_minimum_size = Vector2(372, 0)
	_route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_route_label)
	_ask_label = UIKit.label("Fly here?", 26, UIKit.HEATHER)
	col.add_child(_ask_label)
	content.add_child(_panel)

## Moves the cursor to a visited town ("" for none) and refreshes the panel and hints.
func _select(town: String) -> void:
	_asking = false
	view.cursor = town
	view.named_unvisited = MapLogic.named_unvisited(Game.data, _objective_town)
	if town != "":
		var t: Dictionary = Travel.world_map().towns[town]
		view.centre = Vector2(float(t.x), float(t.y))
		var i := MapLogic.info(Game.data, town)
		_name_label.text = i.name
		_lines_label.text = "\n".join(MapLogic.info_lines(i))
	_panel.visible = town != ""
	_refresh_ask()
	_place_panel()
	view.queue_redraw()

func _flyable(town: String) -> bool:
	return _can_fly and town != "" and MapLogic.can_fly_to(Game.data, _here(), town)

## The town you are standing in (the overworld's zone), as the flight list sees it.
func _here() -> String:
	if Router.overworld and is_instance_valid(Router.overworld) and Router.overworld.get("zone") != null:
		return Router.overworld.zone.town_id
	var l = Game.data.flag("last_town")
	return str(l) if l else ""

## The "Fly here?" line and the hint bar for the current state.
func _refresh_ask() -> void:
	var hints: Array = [["=Arrows", "Pick a town", "kbd"], ["=D-pad", "Pick a town", "pad"]]
	if _asking:
		hints = [["confirm", "Yes, fly"], ["cancel", "No"]]
	else:
		if _flyable(view.cursor):
			hints.append(["confirm", "Fly here"])
		if _can_fly:
			hints.append(["fly", "Fly list"])
		if _routable(view.cursor):
			hints.append(["run", "Clear route" if _routed(view.cursor) else "Route"])
		hints.append(["cancel", "Back"])
	_ask_label.visible = _asking
	set_hints(hints)

## The panel sits on whichever side of the map the cursor isn't.
func _place_panel() -> void:
	if _panel == null or view.cursor == "":
		return
	var t: Dictionary = Travel.world_map().towns[view.cursor]
	var sp := view.screen_pos(Vector2(float(t.x), float(t.y)))
	_panel.reset_size()
	var left := sp.x > view.size.x * 0.5
	var y := 96.0
	if _objective_panel != null and _panel.get_parent() == _objective_panel.get_parent():
		var strip_top: float = _panel.get_parent().size.y - 12.0 - _objective_panel.get_combined_minimum_size().y
		y = minf(y, strip_top - _panel.size.y - 8.0)
	_panel.position = Vector2(20 if left else view.size.x - _panel.size.x - 20, y)
	view.compass_left = not left

## Rings the "Where next?" town (or spot) in gold and says what it is along the bottom.
func _show_objective() -> void:
	var o := MenuLogic.next_objective(Game.data, Game.dex.core_ids().size())
	if o.is_empty():
		return
	_objective_town = str(o.get("town", ""))
	view.objective = objective_point(o)
	var p := UIKit.panel(Color("1d2230e6"), 12)
	p.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	p.offset_left = 16
	p.offset_right = -16
	p.offset_bottom = -12
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UIKit.label(("Still to do: " if o.get("postgame", false) else "Where next? ") + str(o.get("text", "")), 24)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	content.add_child(p)
	_objective_panel = p
	_place_panel.call_deferred()

## The Journal's "Show on map": the current step's place ringed in gold, the map centred on it, the step below.
func _show_quest(id: String) -> void:
	var q := Quests.get_quest(id)
	var step := Quests.current_step(Game.data, q)
	set_title(str(q.get("title", "Quest")))
	var idx := ZoneIndex.get_index()
	var z := Quests.map_zone(str(step.get("zone", "")), idx)
	var pos: Vector2 = idx.zones.get(z, {}).get("pos", Vector2(-1, -1))
	view.objective = pos
	if pos.x >= 0:
		view.centre = pos
	header_right.text = str(idx.zones.get(z, {}).get("name", ""))
	var p := UIKit.panel(Color("1d2230e6"), 12)
	p.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	p.offset_left = 16
	p.offset_right = -16
	p.offset_bottom = -12
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UIKit.label(str(step.get("text", "")), 24)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	content.add_child(p)
	view.queue_redraw()

## Where an objective sits on the map: its "map" point, else its town or place; (-1, -1) if neither.
static func objective_point(o: Dictionary) -> Vector2:
	var m := Travel.world_map()
	var at: Array = o.get("map", [])
	if at.size() == 2:
		return Vector2(float(at[0]), float(at[1]))
	var t := str(o.get("town", ""))
	var src: Dictionary = m.get("towns", {}).get(t, m.get("places", {}).get(t, {}))
	return Vector2(float(src.x), float(src.y)) if not src.is_empty() else Vector2(-1, -1)

func _unhandled_input(event: InputEvent) -> void:
	if _locked or _panel == null:
		return
	if event.is_action_pressed("run") and _routable(view.cursor):
		get_viewport().set_input_as_handled()
		_toggle_route(view.cursor)
		return
	if _can_fly and event.is_action_pressed("fly"):
		get_viewport().set_input_as_handled()
		_fly()
		return
	if event.is_action_pressed("confirm") and view.cursor != "":
		get_viewport().set_input_as_handled()
		if _asking:
			Audio.sfx("confirm")
			close({"fly": view.cursor})  # the same result the Fly list gives
		elif _flyable(view.cursor):
			Audio.sfx("confirm")
			_asking = true
			_refresh_ask()
		return
	for key in MapLogic.DIRS:
		if event.is_action_pressed("move_" + key):
			get_viewport().set_input_as_handled()
			_step(MapLogic.DIRS[key])
			return

## Jumps the cursor to the nearest visited town that way, if there is one.
func _step(dir: Vector2) -> void:
	var pos := MapLogic.visited_positions(Game.data)
	if view.cursor == "" or not pos.has(view.cursor):
		return
	var n := MapLogic.nearest(pos[view.cursor], pos, dir, view.cursor)
	if n != "":
		Audio.sfx("cursor")
		_select(n)

func _on_cancel() -> void:
	if _asking:
		_asking = false
		_refresh_ask()
		return
	close(null)

## You can route to any town but the one you stand in.
func _routable(town: String) -> bool:
	return town != "" and town != _here() and _asking == false

func _routed(town: String) -> bool:
	return str(Game.data.flag("route_to")) == town

## "Route here": store the destination, draw the way; the same town again clears it.
func _toggle_route(town: String) -> void:
	if _routed(town):
		Game.data.flags.erase("route_to")
		Audio.sfx("cancel")
	else:
		Game.data.set_flag("route_to", town)
		Audio.sfx("confirm")
	_show_route()
	_refresh_ask()

## Draws the stored route (if any) and says how long it is and how you go, in the panel.
func _show_route() -> void:
	var to := str(Game.data.flag("route_to")) if Game.data.flag("route_to") else ""
	var path: Array = ZoneGraph.route(ZoneGraph.shared(), Game.data.zone_id, to, Game.data) if to != "" else []
	view.route = MapLogic.route_points(path, ZoneIndex.get_index().zones)
	view.queue_redraw()
	if _route_label == null:
		return
	if to == "":
		_route_label.text = ""
	elif path.is_empty():
		_route_label.text = "No way to %s from here yet." % Travel.town_name(to)
	else:
		_route_label.text = "To %s, %d zone%s: %s." % [Travel.town_name(to), path.size() - 1, "" if path.size() == 2 else "s", ZoneGraph.summary(ZoneGraph.shared(), path)]
	_place_panel()

func _fly() -> void:
	if _locked:
		return
	var town = await open_child("travel:fly")
	if town != null and str(town) != "":
		close({"fly": str(town)})

## Zones whose wild encounter tables include this species (the truth, rather than the dex's habitat notes).
static var _habitats: Dictionary = {}  # species id -> zone ids, built once

static func habitat_zones(species_id: String) -> Array:
	if _habitats.is_empty():
		var all := ZoneData.load_all()
		for zid in all:
			for kind in all[zid].encounters:
				for e in all[zid].encounters[kind]:
					var sp := str(e.get("species", ""))
					if not _habitats.has(sp):
						_habitats[sp] = []
					if zid not in _habitats[sp]:
						_habitats[sp].append(zid)
	return _habitats.get(species_id, [])
