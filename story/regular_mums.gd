class_name RegularMums
extends RefCounted
## The favour-5 scene at Mum's (see Regulars.mums_visitor): a few lines every Regular shares (data/regulars.json
## `mums_shared`: "before" then "after"), the Regular's own `mums` lines between them, a flask of tea for the road, and
## then they go home (Regulars.complete "mums"). {name}, {short} and {town} are filled in here; {player} by Commands.
## Lines beginning "Mum: " are Mum's; "Name: " is the visitor; anything else is narration.

const KEEPSAKE := "flask_of_tea"

static func shared() -> Dictionary:
	var d = JsonUtil.read(Regulars.PATH)
	return d.get("mums_shared", {}) if d is Dictionary else {}

## The town a Regular calls home, as the map names it.
static func town_name(r: Dictionary) -> String:
	var z = JsonUtil.read("res://data/zones/%s.json" % str(r.get("zone", r.get("home", ""))))
	return str(z.get("name", str(r.get("home", "")))) if z is Dictionary else str(r.get("home", ""))

static func lines_for(r: Dictionary) -> Array:
	var sh := shared()
	var out := []
	out.append_array(sh.get("before", []))
	out.append_array(r.get("mums", []))
	out.append_array(sh.get("after", []))
	var town := town_name(r)
	return out.map(func(l): return str(l).replace("{name}", str(r.name)).replace("{short}", Regulars.short_name(r)).replace("{town}", town))

static func run(cmd: Commands, r: Dictionary) -> void:
	var host = cmd.host
	var data: GameStateData = host.data
	var first := Regulars.short_name(r)
	for l in lines_for(r):
		var t := str(l)
		var who := ""
		if t.begins_with("Mum: "):
			who = "Mum"
			t = t.substr(5)
		elif t.begins_with(first + ": "):
			who = str(r.name)
			t = t.substr(first.length() + 2)
		await host.say(who, cmd._sub(t))
	data.bag[KEEPSAKE] = int(data.bag.get(KEEPSAKE, 0)) + 1
	await host.sfx("item")
	await host.say("", "Mum puts a flask of tea in your hand on the way past. %s is sent home with a Tupperware." % first)
	Regulars.complete(data, str(r.id), "mums")
