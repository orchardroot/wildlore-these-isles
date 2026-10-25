extends SceneTree
## Sprite generator. Usage:
##   godot --headless --path . -s res://tools/spritegen.gd -- [id ...] [--sheets] [--scale=N] [--no-write]
##   ... -- [id ...] --pairs=/abs/out.png [--first=N] [--skip=M]   fronts beside backs
##       (N species in dex order after the first M) to check back views
## No ids renders every recipe in art/recipes/. --sheets also writes the contact sheets
## docs/screens/t4-creatures.png and t4-chars.png. Output is deterministic.

const Creature = preload("res://tools/spritegen/creature.gd")
const Character = preload("res://tools/spritegen/character.gd")
const Placeholders = preload("res://tools/spritegen/placeholders.gd")
const Sheets = preload("res://tools/spritegen/sheets.gd")

const ORDER := ["spikkin", "bramblehog", "thornsow", "holtling", "rillotter", "spatelord", "kindlet", "emberdrey", "pyredrey", "scuttlet", "warrender", "pipkin", "redbreast", "croakle", "hootlet", "binfox", "dipling", "gritling", "wispet", "roachroo", "snowhare", "cooplet", "strutcoo", "grizzlet", "raidtail", "chipgull", "pierlord", "pepperling", "sootwing", "bobbin", "shuttlecog", "starlet", "murmurant", "minkshade", "sphagnet", "peatmonarch", "bufomire", "natterjack", "duneskink", "pupplash", "greyhaul", "puffling", "clownbill", "dolphlet", "bayrunner", "pinchkin", "clawcastle", "cragchough", "kitelet", "forkwing", "kidgruff", "billgruff", "prismite", "martling", "pinewraith", "slatelet", "quarrion", "tapknock", "coblynn", "tylwyth", "afanc", "gwyllgi", "brockling", "brockmoor", "flittermouse", "zigzlet", "adderking", "elverlet", "severnshock", "swiftlet", "stormswift", "petrelash", "loaghtan", "ddraig", "dozelet", "hazeldoze", "cranelet", "levelcrane", "sulisa", "pixling", "pixiedell", "foalmoor", "tormane", "bodminax", "baskling", "baskarr", "tinnet", "cassiterix", "thornwyn", "barnling", "hushwing", "glowmite", "lanternis", "wessexwyrm", "greenman", "leveret", "gealhare", "fawnlet", "stagmor", "megalorn", "parrlet", "bradan", "pooka", "bansheen", "selklet", "selkie", "merrow", "cluricaun", "crexling", "corncrake", "gannetling", "plungebeak", "gentlet", "burrenbloom", "connie", "connemarr", "sikawhistle", "pincray", "horselet", "horseshoe", "ternlet", "polartern", "kerryspot", "stalklet", "heronarch", "rooklet", "rookery", "moolet", "dextera", "morrigan", "basaltling", "causewarden", "rivetling", "samsonian", "flaxling", "linenwisp", "fionnling", "finnmacool", "pollanet", "enbarr", "stoatlet", "ermine", "wildkit", "highlynx", "caperling", "capercaillie", "ptarmlet", "ptarmigan", "coolet", "heilan", "eaglet", "goldeneyrie", "ospret", "lochosprey", "midgie", "midgeswarm", "orcalet", "orcaird", "buntling", "snowbunting", "calfrein", "reindeer", "thistlet", "thistlord", "kelpie", "brownie", "minchman", "haarling", "railspark", "cusith", "nessie", "volet", "ratty", "stagbeet", "stagmajor", "parakit", "squawkster", "moldiwarp", "tunneller", "herdlet", "herdwick", "peregrin", "stoopfalcon", "jetling", "jetwhitby", "cutlet", "steelheart", "legionette", "centurion", "bittling", "boomern", "barkdeer", "glisglis", "churrjar", "sarsenite", "tubemole", "shuck", "lambton", "herne", "bran"]
const CHAR_ORDER := ["player_a", "player_b", "prof_garside", "kit", "keeper_maud", "mum", "villager_1", "villager_2", "villager_3", "villager_4", "villager_5", "villager_6", "sanctuary_nurse", "shopkeeper", "hiker", "birdwatcher", "angler", "jogger", "warden_grunt", "rail_guard", "sailor", "bev", "vane", "pryce", "keeper_ray", "keeper_eluned", "keeper_rhys", "dr_hughes", "harpist", "tour_guide", "student", "farmer", "choir_singer", "surfer", "rugby_player", "keeper_morwen", "keeper_declan", "keeper_nuala", "kerrigan", "ashcombe", "hurler", "fiddler", "sean_nos_singer", "tin_miner", "druid", "poet", "currach_rower", "festival_goer", "keeper_ruairi", "keeper_isla", "strachan", "piper", "ceilidh_caller", "shinty_player", "ghillie", "shipwright", "hillwalker", "fisher", "keeper_hester", "wind_aelwen", "wind_fergus", "wind_aoife", "wind_wilf", "ravenmaster", "steelworker", "fell_runner", "fisherman_north", "canal_boater", "commuter", "lamplighter", "astronomer", "night_nurse", "fox_watcher"]
const CREATURE_RECIPES := "res://art/recipes/creatures"
const CHAR_RECIPES := "res://art/recipes/chars"
const CREATURE_OUT := "res://art/sprites/creatures"
const CHAR_OUT := "res://art/sprites/chars"

func _initialize() -> void:
	var ids: Array = []
	var sheets := false
	var preview := ""
	var cpreview := ""
	var pairs := ""
	var first := 0
	var skip := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pairs="):
			pairs = a.substr(8)
		elif a.begins_with("--skip="):
			skip = int(a.substr(7))
		elif a.begins_with("--first="):
			first = int(a.substr(8))
		elif a.begins_with("--cpreview="):
			cpreview = a.substr(11)
		elif a.begins_with("--preview="):
			preview = a.substr(10)
		elif a == "--sheets":
			sheets = true
		elif not a.begins_with("--"):
			ids.append(a)
	var count := 0
	_save(Placeholders.creature_sheet(), CREATURE_OUT + "/_placeholder_front.png")
	_save(Placeholders.creature_sheet(), CREATURE_OUT + "/_placeholder_back.png")
	_save(Placeholders.creature_icon(), CREATURE_OUT + "/_placeholder_icon.png")
	_save(Placeholders.char_sheet(), CHAR_OUT + "/_placeholder.png")
	for id in list_recipes(CREATURE_RECIPES):
		if ids.size() > 0 and not (id in ids):
			continue
		var r := Creature.render(load_recipe(CREATURE_RECIPES, id))
		_save(r.front, "%s/%s_front.png" % [CREATURE_OUT, id])
		_save(r.back, "%s/%s_back.png" % [CREATURE_OUT, id])
		_save(r.icon, "%s/%s_icon.png" % [CREATURE_OUT, id])
		var recipe := load_recipe(CREATURE_RECIPES, id)
		for sex in ["m", "f"]:  # the sheets for each sex of a dimorphic species (see Creature.apply_dimorph)
			var sr := Creature.apply_dimorph(recipe, sex)
			if sr.is_empty():
				continue
			var d := Creature.render(sr)
			_save(d.front, "%s/%s_%s.png" % [CREATURE_OUT, id, sex])
			_save(d.back, "%s/%s_%s_back.png" % [CREATURE_OUT, id, sex])
			_save(d.icon, "%s/%s_%s_icon.png" % [CREATURE_OUT, id, sex])
		count += 1
	for id in list_recipes(CHAR_RECIPES):
		if ids.size() > 0 and not (id in ids):
			continue
		_save(Character.render(load_recipe(CHAR_RECIPES, id)), "%s/%s.png" % [CHAR_OUT, id])
		count += 1
	if cpreview != "":
		_save(Sheets.chars(ids, 3 if ids.size() > 1 else 8, 4 if ids.size() > 1 else 1), cpreview)
	if pairs != "":
		var pids: Array = ids
		if first > 0:
			pids = _ordered(list_recipes(CREATURE_RECIPES), ORDER).slice(skip, skip + first)
		elif pids.is_empty():
			pids = _ordered(list_recipes(CREATURE_RECIPES), ORDER)
		_save(Sheets.pairs(pids, 2, 4), pairs)
	if preview != "":
		_save(Sheets.preview(ids, 3), preview)
	if sheets:
		_save(Sheets.creatures(_ordered(list_recipes(CREATURE_RECIPES), ORDER), "front"), "res://docs/screens/t4-creatures.png")
		_save(Sheets.creatures(_ordered(list_recipes(CREATURE_RECIPES), ORDER), "back"), "res://docs/screens/t4-creatures-back.png")
		_save(Sheets.creatures(_ordered(list_recipes(CREATURE_RECIPES), ORDER), "icon"), "res://docs/screens/t4-icons.png")
		_save(Sheets.chars(_ordered(list_recipes(CHAR_RECIPES), CHAR_ORDER)), "res://docs/screens/t4-chars.png")
	print("spritegen: rendered %d recipe(s)" % count)
	quit(0)

static func list_recipes(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".json"):
			out.append(f.get_basename())
	out.sort()
	return out

static func load_recipe(dir_path: String, id: String) -> Dictionary:
	var f := FileAccess.open("%s/%s.json" % [dir_path, id], FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		push_error("spritegen: bad recipe " + id)
		return {}
	return data

static func _save(img: Image, path: String) -> void:
	var err := img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("spritegen: cannot save %s (%d)" % [path, err])

static func _ordered(ids: Array, order: Array) -> Array:
	var out: Array = []
	for id in order:
		if id in ids:
			out.append(id)
	for id in ids:
		if not (id in out):
			out.append(id)
	return out
