class_name Motion
extends RefCounted
## How a creature moves (wave 48 A). Pure: no autoloads. A species picks a style from an optional "motion" key in its
## JSON, then from words in its id/sprite/name, then from its types. The battle actor, the follower and the portraits
## all read the same style, so a Wisp hovers everywhere and a Bramble thumps everywhere.

const STYLES := ["hover", "hop", "slither", "sway", "bob", "pulse", "stomp", "flutter", "drift"]

## Id or name fragments that decide the style before types do (the shape of the animal, not its element).
const WORDS := {
	"slither": ["eel", "snake", "serpent", "adder", "worm", "wyrm", "lamprey", "naga", "knot"],
	"pulse": ["jelly", "medusa", "squid", "octo", "anemone", "blob", "slime"],
	"flutter": ["moth", "bee", "wasp", "fly", "bat", "swift", "wren", "finch", "sprite", "pixie", "butterfly", "dragonfly", "midge", "gnat"],
	"hop": ["frog", "toad", "hare", "rabbit", "bunny", "newt", "cricket", "flea", "snail", "puck", "hopper", "leveret"],
	"hover": ["wisp", "will", "ghost", "spectre", "kite", "owl", "gull", "hawk", "eagle", "lantern", "jenny", "banshee", "phantom"],
	"stomp": ["golem", "giant", "ogre", "troll", "bull", "boar", "ox", "rhino", "elephant", "titan", "cairn", "colossus", "hulk", "bear", "mammoth"],
	"drift": ["mist", "fog", "cloud", "haar", "smoke", "ember", "shade", "shadow", "sea_"],
	"sway": ["reed", "willow", "fern", "tree", "thistle", "bramble", "briar", "rush", "oak", "ent", "flower", "heather", "gorse", "moss"],
}

## Fallback by first type.
const BY_TYPE := {
	"gale": "flutter", "spirit": "hover", "fae": "flutter", "night": "drift", "storm": "hover", "frost": "drift",
	"tide": "sway", "brook": "bob", "bog": "slither", "hedgerow": "sway", "stone": "stomp", "iron": "stomp",
	"brawn": "stomp", "hearth": "bob", "kin": "hop", "urban": "bob",
}

## Per style numbers used by CreatureActor: lift (how high it floats), amp (idle travel), speed, shadow breathing.
const PARAMS := {
	"hover": {"lift": 0.28, "amp": 0.1, "speed": 2.0}, "hop": {"lift": 0.0, "amp": 0.34, "speed": 1.0},
	"slither": {"lift": 0.0, "amp": 0.14, "speed": 1.8}, "sway": {"lift": 0.0, "amp": 0.07, "speed": 1.3},
	"bob": {"lift": 0.0, "amp": 0.07, "speed": 2.4}, "pulse": {"lift": 0.16, "amp": 0.09, "speed": 2.8},
	"stomp": {"lift": 0.0, "amp": 0.05, "speed": 0.9}, "flutter": {"lift": 0.3, "amp": 0.06, "speed": 9.0},
	"drift": {"lift": 0.18, "amp": 0.2, "speed": 0.8},
}

static func style_for(species: Dictionary) -> String:
	var forced := str(species.get("motion", ""))
	if forced in STYLES:
		return forced
	for key in ["id", "sprite"]:
		var id := str(species.get(key, "")).to_lower()
		for style in WORDS:
			for w in WORDS[style]:
				if _has_word(id, w):
					return style
	var types: Array = species.get("types", [])
	if not types.is_empty():
		return str(BY_TYPE.get(str(types[0]), "bob"))
	return "bob"

## A whole `_` token, or a long word at either end of the id ("wyrm" in "fenwyrm", "moth" in "mothling").
static func _has_word(id: String, w: String) -> bool:
	if id == w or id.begins_with(w + "_") or id.ends_with("_" + w):
		return true
	return w.length() >= 4 and (id.begins_with(w) or id.ends_with(w))

static func params(style: String) -> Dictionary:
	return PARAMS.get(style, PARAMS["bob"])

## Idle offset and squash at time t: returns {"pos": Vector2 (x, y in world units), "squash": Vector2, "shadow": float}.
static func idle(style: String, t: float, phase := 0.0) -> Dictionary:
	var p := params(style)
	var amp: float = p.amp
	var s: float = p.speed
	var lift: float = p.lift
	var x := 0.0
	var y := lift
	var sq := Vector2.ONE
	var tt := t + phase
	match style:
		"hover":
			y += sin(tt * s) * amp
		"hop":
			var c := fposmod(tt * s, 2.2)  # a hop, then a rest
			if c < 0.6:
				var k := c / 0.6
				y = sin(k * PI) * amp
				sq = Vector2(1.0 - 0.06 * sin(k * PI), 1.0 + 0.1 * sin(k * PI))
			elif c < 0.8:  # landing squash
				var k2 := (c - 0.6) / 0.2
				sq = Vector2(1.0 + 0.12 * sin(k2 * PI), 1.0 - 0.14 * sin(k2 * PI))
		"slither":
			x = sin(tt * s) * amp
			sq = Vector2(1.0 + cos(tt * s) * 0.05, 1.0 - cos(tt * s) * 0.03)
		"sway":
			x = sin(tt * s) * amp
			sq = Vector2(1.0 - sin(tt * s) * 0.02, 1.0 + sin(tt * s * 2.0) * 0.015)
		"bob":
			y += absf(sin(tt * s)) * amp
		"pulse":
			var b := sin(tt * s)
			y += b * amp
			sq = Vector2(1.0 - b * 0.07, 1.0 + b * 0.1)
		"stomp":
			var c2 := fposmod(tt * s, 2.4)
			if c2 < 0.25:  # a heavy shift of weight
				var k3 := c2 / 0.25
				sq = Vector2(1.0 + 0.05 * sin(k3 * PI), 1.0 - 0.06 * sin(k3 * PI))
				y = 0.0
		"flutter":
			y += sin(tt * s) * amp
			x = sin(tt * s * 0.7) * amp * 0.5
		"drift":
			x = sin(tt * s) * amp
			y += sin(tt * s * 0.6) * amp * 0.5
	# the shadow shrinks and fades a touch as the creature rises
	var rise := maxf(0.0, y - lift) + lift * 0.6
	return {"pos": Vector2(x, y), "squash": sq, "shadow": clampf(1.0 - rise * 0.9, 0.5, 1.0)}

## Which lunge a style uses in battle: "dash", "swoop", "strike", "charge" or "leap".
static func lunge_kind(style: String) -> String:
	match style:
		"hover", "flutter", "drift": return "swoop"
		"slither": return "strike"
		"stomp": return "charge"
		"hop": return "leap"
	return "dash"
